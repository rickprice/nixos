-- VolumePanMuteControl.lua
-- Bidirectional OSC ↔ MIDI bridge for channel volume, pan, and mute.
-- Each instance of this route controls exactly one mixer strip; this
-- deployment has one copy per strip (VolumePanMuteControlGuitarix.lua,
-- …Piano.lua, …Vocals.lua, …Metronome.lua), with the strip's own MIDI CC
-- numbers and (optionally) its Non-Mixer-XT strip name set via that route's
-- own [section] in config.toml. All four copies are byte-identical — the
-- filename is what makes each one its own ALSA port pair and OSC address
-- prefix; config.toml is what makes it control a specific strip.
--
-- OSC parameters (address prefix = /<this-file's-name>, e.g.
-- /VolumePanMuteControlGuitarix):
--   .../volume  <float 0–1>    — channel volume (0=silent, 1=full)
--   .../pan     <float -1–1>   — stereo pan (−1=left, 0=center, 1=right)
--   .../mute    <bool|int 0|1> — mute (1=muted, 0=unmuted)
--
-- Subscription (TouchOSC / Lemur):
--   .../subscribe [port [timeout_secs]]
--
-- Default MIDI CCs (override per-strip in config.toml):
--   volume → CC  7  (MIDI Channel Volume)
--   pan    → CC 10  (MIDI Pan; 0=left, 64=center, 127=right)
--   mute   → CC 118 (no universal MIDI mute standard; configure to suit your DAW)
--
-- Optional Non-Mixer-XT bridge (see routes.d/lib/nmxt.lua and
-- https://github.com/Stazed/non-mixer-xt/blob/main/OSC.md): set
-- config.nmxt_strip to the Non-Mixer-XT strip name this route should also
-- drive. Volume/Pan/Mute changes from MIDI or OSC are pushed to Non-Mixer-XT,
-- and changes made directly in Non-Mixer-XT's own GUI flow back out to MIDI
-- and any subscribed OSC controller, same as a hardware CC would. Disabled
-- (nil) by default -- Non-Mixer-XT integration is opt-in per route.
-- config.nmxt_pan only matters if config.nmxt_strip is set, and must stay
-- false unless this strip actually has a Pan plugin inserted in Non-Mixer-XT
-- (most strips don't by default -- see the OSC.md link above).

-- ROUTES_DIR is set by the daemon to this install's actual routes
-- directory, so this works unmodified regardless of routes_dir (see
-- "Sharing code between routes" in the midi-daemon project's README.md).
local nmxt_lib = dofile(ROUTES_DIR .. "/lib/nmxt.lua")

local CHANNEL = config.channel or 1

local VOLUME_CHANNEL    = config.volume_channel    or CHANNEL
local VOLUME_CONTROLLER = config.volume_controller or 7    -- CC 7 = MIDI Channel Volume

local PAN_CHANNEL       = config.pan_channel       or CHANNEL
local PAN_CONTROLLER    = config.pan_controller    or 10   -- CC 10 = MIDI Pan

local MUTE_CHANNEL      = config.mute_channel      or CHANNEL
local MUTE_CONTROLLER   = config.mute_controller   or 118  -- no universal MIDI mute CC

local volume = 1.0   -- 0–1, default full
local pan    = 0.0   -- −1–1, default center
local muted  = false

local nmxt = config.nmxt_strip and nmxt_lib.new({
    addr       = config.nmxt_osc_addr,
    strip      = config.nmxt_strip,
    has_pan    = config.nmxt_pan or false,
    -- Must match the daemon's actual OSC receive port (config.toml's
    -- top-level osc_receive_port, default 9000) so Non-Mixer-XT's feedback
    -- lands on a socket midi-daemon is really listening on. Per-route
    -- `config` tables aren't merged with that global default, so if you
    -- ever change it, also set osc_receive_port under this route's own
    -- [section] in config.toml.
    hello_port = config.osc_receive_port,
}) or nil

local function send_volume_cc()
    send({ type = "cc", channel = VOLUME_CHANNEL, controller = VOLUME_CONTROLLER,
           value = math.floor(volume * 127.0 + 0.5) })
end

local function send_pan_cc()
    -- OSC −1..1 → MIDI 0..127 (pan=0 → CC 64, the MIDI center)
    send({ type = "cc", channel = PAN_CHANNEL, controller = PAN_CONTROLLER,
           value = math.floor((pan + 1.0) / 2.0 * 127.0 + 0.5) })
end

local function send_mute_cc()
    send({ type = "cc", channel = MUTE_CHANNEL, controller = MUTE_CONTROLLER,
           value = muted and 127 or 0 })
end

-- Push the current value of `param` ("Volume"/"Pan"/"Mute") to any OSC
-- controller subscribed via /<ROUTE_NAME>/subscribe. Needed only for
-- Non-Mixer-XT-originated changes: those arrive on an address outside the
-- osc.params table below, so midi-daemon's normal "set() then notify
-- subscribers via get()" dispatch never runs for them.
local function notify_subscribers(param, value)
    send_osc("/" .. ROUTE_NAME .. "/" .. param, value)
end

-- Restore volume/pan/mute from the last session and re-send the CCs so
-- connected hardware/DAW reflects the restored values immediately.
function on_startup()
    local state = load_state()
    if state.volume ~= nil then volume = state.volume; send_volume_cc() end
    if state.pan    ~= nil then pan    = state.pan;    send_pan_cc()    end
    if state.muted  ~= nil then muted  = state.muted;  send_mute_cc()   end

    if nmxt then
        nmxt.hello()
        nmxt.push_volume(volume)
        nmxt.push_pan(pan)
        nmxt.push_mute(muted)
    end
end

-- Called on graceful shutdown (SIGTERM / systemctl stop).
function on_shutdown()
    save_state({ volume = volume, pan = pan, muted = muted })
    if nmxt then nmxt.goodbye() end
end

-- Non-Mixer-XT feedback (e.g. a fader dragged in its own GUI) arrives here,
-- not through osc.params below -- apply it locally and fan it back out to
-- MIDI + OSC subscribers, but never push it back to Non-Mixer-XT (it
-- already knows; that would just be a harmless but pointless round-trip).
function on_osc(msg)
    if not nmxt then return end
    local param, value = nmxt.feedback(msg.address, msg.args[1])
    if param == "volume" then
        volume = value
        send_volume_cc()
        notify_subscribers("Volume", volume)
        log(string.format("Volume (from Non-Mixer-XT): %.3f", volume))
    elseif param == "pan" then
        pan = value
        send_pan_cc()
        notify_subscribers("Pan", pan)
        log(string.format("Pan (from Non-Mixer-XT): %.3f", pan))
    elseif param == "mute" then
        muted = value
        send_mute_cc()
        notify_subscribers("Mute", muted and 1 or 0)
        log(muted and "Muted (from Non-Mixer-XT)" or "Unmuted (from Non-Mixer-XT)")
    end
end

function init()
    return {
        inputs  = {"midi"},
        outputs = {"midi"},
        osc = {
            params = {
                Volume = {
                    set = function(v)
                        volume = math.max(0.0, math.min(1.0, v))
                        send_volume_cc()
                        if nmxt then nmxt.push_volume(volume) end
                        log(string.format("Volume: %.3f", volume))
                    end,
                    get = function() return volume end,
                    -- Incoming CC 7 (0–127) scaled linearly to OSC range 0.0–1.0
                    midi = {
                        { type = "cc", channel = VOLUME_CHANNEL,
                          controller = VOLUME_CONTROLLER, scale = {0.0, 1.0} },
                    },
                },
                Pan = {
                    set = function(v)
                        pan = math.max(-1.0, math.min(1.0, v))
                        send_pan_cc()
                        if nmxt then nmxt.push_pan(pan) end
                        log(string.format("Pan: %.3f", pan))
                    end,
                    get = function() return pan end,
                    -- Incoming CC 10 (0–127) scaled linearly to OSC range −1.0–1.0
                    midi = {
                        { type = "cc", channel = PAN_CHANNEL,
                          controller = PAN_CONTROLLER, scale = {-1.0, 1.0} },
                    },
                },
                Mute = {
                    set = function(v)
                        muted = (v ~= 0 and v ~= false)
                        send_mute_cc()
                        if nmxt then nmxt.push_mute(muted) end
                        log(muted and "Muted" or "Unmuted")
                    end,
                    get = function() return muted and 1 or 0 end,
                    -- Incoming CC value ≥ 64 → muted (1), < 64 → unmuted (0)
                    midi = {
                        { type = "cc", channel = MUTE_CHANNEL,
                          controller = MUTE_CONTROLLER, threshold = 64 },
                    },
                },
            },
        },
    }
end
