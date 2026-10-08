-- lib/nmxt.lua
-- Shared helpers for bridging a midi-daemon route to a Non-Mixer-XT strip
-- over OSC (see https://github.com/Stazed/non-mixer-xt/blob/main/OSC.md).
--
-- Not loaded automatically -- each route does:
--   local nmxt_lib = dofile("/absolute/path/to/routes.d/lib/nmxt.lua")
-- (mlua has no `debug` library here, so a route can't locate its own file
-- to derive a relative path; the dofile path must be hardcoded per
-- deployment. See the comment above the dofile() call in this project's
-- VolumePanMuteControl.lua for the exact path used by each install type.)
--
-- Non-Mixer-XT quirks this library works around:
--  * It identifies a controller ("peer") by the `name` argument of
--    /signal/hello, not by source address or port -- a second /signal/hello
--    with the same name overwrites the first peer's address. All routes in
--    this daemon therefore register under ONE shared CONTROLLER_NAME below,
--    so they collapse into a single Non-Mixer-XT peer instead of each
--    route's hello silently stealing the others' registration.
--  * Feedback is a broadcast: when a connected signal changes, Non-Mixer-XT
--    sends the new value, at the destination path from /signal/connect, to
--    EVERY registered peer -- not just the one that asked to be connected.
--    This only matters if you register peers at different URLs; since every
--    route here shares one peer (above), each strip's feedback is written
--    to a destination path that only that strip connected, so there's
--    nothing else to receive it.
--  * There is no suppression of self-echo: a value this daemon pushes to
--    Non-Mixer-XT gets broadcast straight back once the feedback timer
--    ticks. c.feedback() is only ever wired to on_osc() in the calling
--    route, not back into c.push_*(), so that echo is harmless -- it just
--    re-applies the same value instead of looping.
local M = {}

local CONTROLLER_NAME = "midi-daemon"

-- Non-Mixer-XT paths may contain spaces (encoded as %20) and literal
-- parentheses, e.g. "/strip/Guitar/Gain/Gain%20(dB)".
local function pct_encode(s)
    return (s:gsub(" ", "%%20"))
end

-- Build a Non-Mixer-XT signal path: /strip/<strip>/<module>/<param>
function M.path(strip, module_name, param)
    return "/strip/" .. pct_encode(strip) .. "/" .. pct_encode(module_name) .. "/" .. pct_encode(param)
end

-- Create a controller bound to one strip's Volume (Gain), Mute (Gain), and
-- optionally Pan (Mono Pan) signals. Feedback destination paths are built
-- from the global ROUTE_NAME (set by the daemon before the route script
-- runs, and visible here too since dofile() shares the caller's Lua state)
-- so midi-daemon's OSC dispatcher -- which routes by "/<route-name>/..."
-- prefix -- delivers them back to this route. `opts`:
--   addr       Non-Mixer-XT OSC target, "host:port" (default "127.0.0.1:9500")
--   strip      Non-Mixer-XT strip name, e.g. "Guitar" (required)
--   hello_port UDP port Non-Mixer-XT should push feedback to -- this must be
--              a port midi-daemon is actually listening on, i.e. the shared
--              osc_receive_port from config.toml (default 9000)
--   has_pan    whether this strip has a Pan plugin inserted in Non-Mixer-XT
--              (default false -- most strips don't have one by default)
function M.new(opts)
    local addr  = opts.addr or "127.0.0.1:9500"
    local strip = assert(opts.strip, "nmxt.new: opts.strip is required")
    local route = assert(ROUTE_NAME, "nmxt.new: global ROUTE_NAME is not set")
    local hello_port = opts.hello_port or 9000

    local c = {
        addr = addr,
        volume_src = M.path(strip, "Gain", "Gain (dB)"),
        mute_src   = M.path(strip, "Gain", "Mute"),
        pan_src    = opts.has_pan and M.path(strip, "Mono Pan", "Pan") or nil,

        volume_fb = "/" .. route .. "/nmxt/volume",
        mute_fb   = "/" .. route .. "/nmxt/mute",
        pan_fb    = opts.has_pan and ("/" .. route .. "/nmxt/pan") or nil,
    }

    -- Register as a controller and subscribe to feedback for this strip's
    -- signals. Safe to call repeatedly (e.g. every on_startup): Non-Mixer-XT
    -- treats a repeated /signal/hello with the same name+url, and a repeated
    -- /signal/connect for the same pair, as a no-op.
    function c.hello()
        send_osc(addr, "/signal/hello", CONTROLLER_NAME, "osc.udp://127.0.0.1:" .. tostring(hello_port))
        send_osc(addr, "/signal/connect", c.volume_fb, c.volume_src)
        send_osc(addr, "/signal/connect", c.mute_fb, c.mute_src)
        if c.pan_src then
            send_osc(addr, "/signal/connect", c.pan_fb, c.pan_src)
        end
    end

    -- Cancel this strip's subscriptions. Does not remove the shared
    -- controller peer itself (other routes/strips may still be using it).
    function c.goodbye()
        send_osc(addr, "/signal/disconnect", c.volume_fb, c.volume_src)
        send_osc(addr, "/signal/disconnect", c.mute_fb, c.mute_src)
        if c.pan_src then
            send_osc(addr, "/signal/disconnect", c.pan_fb, c.pan_src)
        end
    end

    -- Push local state to Non-Mixer-XT. `volume` is already 0..1, matching
    -- Non-Mixer-XT's normalized range directly; `pan` is converted from the
    -- route's internal -1..1 range; `mute` is a Lua boolean.
    function c.push_volume(v) send_osc(addr, c.volume_src, v) end
    function c.push_mute(m)   send_osc(addr, c.mute_src, m and 1.0 or 0.0) end
    function c.push_pan(p)
        if c.pan_src then send_osc(addr, c.pan_src, (p + 1.0) / 2.0) end
    end

    -- If `address` is this controller's feedback address for Volume, Mute,
    -- or Pan, returns the parameter name and the value converted back into
    -- the route's internal units. Otherwise returns nil (not a message for
    -- this controller -- the caller's on_osc should ignore it).
    function c.feedback(address, value)
        if address == c.volume_fb then
            return "volume", value
        elseif address == c.mute_fb then
            return "mute", value >= 0.5
        elseif c.pan_fb and address == c.pan_fb then
            return "pan", value * 2.0 - 1.0
        end
        return nil
    end

    return c
end

return M
