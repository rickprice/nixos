{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE LambdaCase #-}
{-# OPTIONS_GHC -Wno-missing-signatures -Wno-type-defaults #-}

import Data.Ratio
import XMonad
import XMonad.StackSet qualified as W
import XMonad.Config.Desktop (desktopLayoutModifiers)
import XMonad.Actions.SpawnOn
import XMonad.Actions.UpdatePointer
import XMonad.Actions.Warp
import XMonad.Actions.DynamicWorkspaceGroups as ADWG
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.InsertPosition
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Hooks.StatusBar
import XMonad.Hooks.UrgencyHook
import XMonad.Layout.GridVariants
import XMonad.Layout.Magnifier
import XMonad.Layout.MultiColumns
import XMonad.Layout.NoBorders (noBorders, smartBorders)
import XMonad.Layout.ToggleLayouts
import XMonad.Util.EZConfig
import XMonad.Util.NamedActions
import XMonad.Util.Loggers
import XMonad.Util.NamedScratchpad
import XMonad.Util.SpawnOnce
import qualified XMonad.Util.ExtensibleState as XS

-- =============================================================================
-- CONSTANTS
-- =============================================================================

myModMask = mod4Mask

myTerminal    = "wezterm"
myBrowser     = "google-chrome-stable --new-window https://www.google.com"
myFileManager = "pcmanfm"

mySystemMonitor = "gnome-system-monitor"
myCalculator    = "gnome-calculator"
myScreenLock    = "xscreensaver-command -lock"
myFixScreens    = "autorandr --change"

myNormalBorderColor  = "#dddddd"
myFocusedBorderColor = "#FFB53A"

workspaceFocusKey = "M-d "
workspaceMoveKey  = "M-S-d "
appRunKey         = "M-a "

leftScreen  = 0
rightScreen = 1

-- Tamara workspace dimensions
tWorkspaceDisplayPrefix = "TP"
tWorkspaceKeyPrefix     = Just "t"
tDesktops               = 7
tDesktopPanes           = 1

-- =============================================================================
-- WORKSPACE MANAGEMENT
-- =============================================================================

tWorkspaces    = workspaceNames tWorkspaceDisplayPrefix tDesktops tDesktopPanes
tWorkspaceKeys = wsKeys tWorkspaceKeyPrefix tWorkspaceDisplayPrefix tDesktops tDesktopPanes

myExtraWorkspaces = ["IM", "MAIL", "SCRATCH", "NSP"]
myWorkspaces      = tWorkspaces ++ myExtraWorkspaces

showDesktop :: String -> X ()
showDesktop = windows . W.greedyView

moveFocusedWindowToDesktop :: String -> X ()
moveFocusedWindowToDesktop = windows . W.shift

workspacePanelTuples desktops 1            = [(x, Nothing) | x <- [1 .. desktops]]
workspacePanelTuples desktops desktopPanes = [(x, Just y)  | x <- [1 .. desktops], y <- [1 .. desktopPanes]]

workspaceNames prefix desktops desktopPanes =
    map (desktopNameFromTuple prefix) (workspacePanelTuples desktops desktopPanes)

wsKeys keyPrefix windowPrefix desktops desktopPanes =
    workspaceShowDesktopKeys    keyPrefix windowPrefix desktops desktopPanes
    ++ workspaceMoveFocusedKeys keyPrefix windowPrefix desktops desktopPanes

workspaceShowDesktopKeys keyPrefix windowPrefix desktops desktopPanes =
    map (desktopShowDesktopKeymapFromTuple keyPrefix windowPrefix) (workspacePanelTuples desktops desktopPanes)

workspaceMoveFocusedKeys keyPrefix windowPrefix desktops desktopPanes =
    map (desktopMoveFocusedKeyFromTuple keyPrefix windowPrefix) (workspacePanelTuples desktops desktopPanes)

desktopNameFromTuple :: Show a => String -> (a, Maybe a) -> String
desktopNameFromTuple p (x, Nothing) = p ++ show x
desktopNameFromTuple p (x, Just y)  = p ++ show x ++ show y

fixPrefix = maybe "" (++ " ")

desktopKeyMapFromTuple p (x, Nothing) = fixPrefix p ++ show x
desktopKeyMapFromTuple p (x, Just y)  = fixPrefix p ++ show x ++ " " ++ show y

desktopShowDesktopKeymapFromTuple keyPrefix windowPrefix t =
    let ws = desktopNameFromTuple windowPrefix t
    in (workspaceFocusKey ++ desktopKeyMapFromTuple keyPrefix t, addName ("Focus " ++ ws) $ showDesktop ws)

desktopMoveFocusedKeyFromTuple keyPrefix windowPrefix t =
    let ws = desktopNameFromTuple windowPrefix t
    in (workspaceMoveKey ++ desktopKeyMapFromTuple keyPrefix t, addName ("Move to " ++ ws) $ moveFocusedWindowToDesktop ws)

-- =============================================================================
-- WORKSPACE GROUPS
-- =============================================================================

setupWorkspaceGroups :: X ()
setupWorkspaceGroups = do
    ADWG.addRawWSGroup "Tamara1"   [(leftScreen, "TP11"), (rightScreen, "TP13")]
    ADWG.addRawWSGroup "Tamara2"   [(leftScreen, "TP21"), (rightScreen, "TP22")]
    ADWG.addRawWSGroup "Messaging" [(leftScreen, "IM"),   (rightScreen, "MAIL")]

powerkeys :: Int -> X ()
powerkeys key = case key of
    1 -> ADWG.viewWSGroup "Tamara1"
    2 -> ADWG.viewWSGroup "Tamara2"
    3 -> ADWG.viewWSGroup "Messaging"
    4 -> showDesktop "SCRATCH"
    _ -> return ()

-- =============================================================================
-- LAYOUTS
-- =============================================================================

myLayouts = toggleLayouts (noBorders Full) (smartBorders (multiColumn ||| mainGrid ||| magnifyLayout mainGrid))
  where
    magnifyLayout    = magnifiercz 1.4
    orientation      = XMonad.Layout.GridVariants.L
    masterRows       = 2
    masterColumns    = 2
    masterPortion    = 2 / 3
    slaveAspectRatio = 16 / 10
    resizeIncrement  = 5 / 100
    mainGrid         = SplitGrid orientation masterRows masterColumns masterPortion slaveAspectRatio resizeIncrement
    multiColumn      = multiCol [1] 1 0.01 (-0.5)

-- =============================================================================
-- MANAGE HOOKS
-- =============================================================================

myManageHook :: ManageHook
myManageHook =
    composeAll
        [ manageSpawn
        , manageDocks
        , customInsertPosition
        , resource  =? "trayer"    --> doIgnore
        , className =? "meteo-qt"  --> doFloat
        , className =? "discord"   --> doShift "IM"
        , className =? "Slack"     --> doShift "IM"
        , className =? "thunderbird" --> doShift "MAIL"
        , isDialog                 --> doFloat
        ]

customInsertPosition :: ManageHook
customInsertPosition = do
    w <- ask
    dpy <- liftX $ asks display
    wmClass <- liftX $ io $ do
        wmClassAtom <- internAtom dpy "WM_CLASS" False
        getWindowProperty8 dpy wmClassAtom w
    wmTransientFor <- liftX $ io $ do
        wmTransientForAtom <- internAtom dpy "WM_TRANSIENT_FOR" False
        getWindowProperty32 dpy wmTransientForAtom w
    isDialogWindow <- isDialog
    case (wmClass, wmTransientFor, isDialogWindow) of
        (Just _, Nothing, False) -> insertPosition End Newer
        _                        -> idHook

-- =============================================================================
-- STATUS BAR
-- =============================================================================

newtype HideEmptyWS = HideEmptyWS Bool deriving (Read, Show)

instance ExtensionClass HideEmptyWS where
    initialValue = HideEmptyWS True

toggleHideEmptyWS :: X ()
toggleHideEmptyWS = XS.modify (\(HideEmptyWS b) -> HideEmptyWS (not b))

myXmobarPP :: X PP
myXmobarPP = do
    HideEmptyWS hideEmpty <- XS.get
    return $ def
        { ppSep             = magenta " • "
        , ppTitleSanitize   = xmobarStrip
        , ppCurrent         = wrap " " "" . xmobarBorder "Top" "#8be9fd" 2
        , ppHidden          = \ws -> if ws == "NSP" then "" else lowWhite . wrap " " "" $ ws
        , ppHiddenNoWindows = \ws -> if hideEmpty || ws == "NSP" then "" else lowWhite . wrap " " "" $ ws
        , ppUrgent          = red . wrap (yellow "!") (yellow "!")
        , ppOrder           = \case { (ws:l:_) -> [ws, l]; _ -> [] }
        , ppExtras          = [logTitles formatFocused formatUnfocused]
        }
  where
    formatFocused   = wrap (white "[") (white "]") . magenta  . ppWindow
    formatUnfocused = wrap (lowWhite "[") (lowWhite "]") . blue . ppWindow

    ppWindow :: String -> String
    ppWindow = xmobarRaw . (\w -> if null w then "untitled" else w) . shorten 30

    blue, lowWhite, magenta, red, white, yellow :: String -> String
    magenta  = xmobarColor "#ff79c6" ""
    blue     = xmobarColor "#bd93f9" ""
    white    = xmobarColor "#f8f8f2" ""
    yellow   = xmobarColor "#f1fa8c" ""
    red      = xmobarColor "#ff5555" ""
    lowWhite = xmobarColor "#bbbbbb" ""

-- =============================================================================
-- KEY BINDINGS
-- =============================================================================

spawnKey key desc program = (appRunKey ++ key, addName desc $ spawn program)

workspaceKeys key ws =
    [ (workspaceFocusKey ++ key, addName ("Focus " ++ ws)   $ showDesktop ws)
    , (workspaceMoveKey  ++ key, addName ("Move to " ++ ws) $ moveFocusedWindowToDesktop ws)
    ]

dynamicScratchPadKeys key name =
    [ ("M-S-" ++ key, addName ("Assign to scratchpad " ++ name) $ withFocused $ toggleDynamicNSP name)
    , ("M-"   ++ key, addName ("Show scratchpad "      ++ name) $ dynamicNSPAction name)
    ]

dynamicWorkspaceGroupKeys key group =
    [ ("M-"   ++ key, addName ("View group " ++ group) $ ADWG.viewWSGroup group)
    , ("M-S-" ++ key, addName ("Save group " ++ group) $ ADWG.addCurrentWSGroup group)
    ]

viewGroupKeys keys group =
    [ ("M-s " ++ keys, addName ("View group " ++ group) $ ADWG.viewWSGroup group) ]

warpMouseKeys =
    [ ("M-C-w", addName "Warp mouse to screen 0" $ warpToScreen 0 (1 % 2) (1 % 2))
    , ("M-C-e", addName "Warp mouse to screen 1" $ warpToScreen 1 (1 % 2) (1 % 2))
    ]

myCustomKeys =
    [ ("M-p",        addName "Run application (dmenu)"      $ spawn "dmenu_run")
    , ("M-f",        addName "Toggle fullscreen"             $ sendMessage ToggleLayout)
    , ("M-S-h",      addName "Toggle hide empty workspaces"  toggleHideEmptyWS)
    , ("M-S-<Enter>",addName "Open terminal"                 $ spawn myTerminal)
    , spawnKey "b" "Browser"        myBrowser
    , spawnKey "f" "File manager"   myFileManager
    , spawnKey "p" "System monitor" mySystemMonitor
    , spawnKey "c" "Calculator"     myCalculator
    , ("<XF86Calculator>", addName "Calculator"    $ spawn myCalculator)
    , ("<XF86PowerOff>",  addName "Shutdown"      $ spawn "systemctl poweroff")
    , ("M-<F2>",           addName "Browser"       $ spawn myBrowser)
    , ("M-<F3>",           addName "File manager"  $ spawn myFileManager)
    , ("C-M-'",            addName "Screen lock"   $ spawn myScreenLock)
    , spawnKey "l" "Screen lock" myScreenLock
    , spawnKey "z" "Fix screens" myFixScreens

    , ("M-1", addName "Power key 1" $ powerkeys 1)
    , ("M-2", addName "Power key 2" $ powerkeys 2)
    , ("M-3", addName "Power key 3" $ powerkeys 3)
    , ("M-4", addName "Power key 4" $ powerkeys 4)
    ]

    ++ workspaceKeys "i" "IM"
    ++ workspaceKeys "m" "MAIL"
    ++ workspaceKeys "s" "SCRATCH"
    ++ workspaceKeys "n" "NSP"

    ++ dynamicScratchPadKeys "[" "dyn1"
    ++ dynamicScratchPadKeys "]" "dyn2"

    ++ dynamicWorkspaceGroupKeys "/" "modslash"

    ++ viewGroupKeys "t t" "Tamara1"
    ++ viewGroupKeys "t 1" "Tamara1"
    ++ viewGroupKeys "t 2" "Tamara2"
    ++ viewGroupKeys "c"   "Messaging"

myNewStyleKeys = tWorkspaceKeys ++ myCustomKeys ++ warpMouseKeys

-- =============================================================================
-- STARTUP
-- =============================================================================

myStartupHook :: X ()
myStartupHook = do
    setupWorkspaceGroups
    spawn "killall pasystray; sleep 15; pasystray"
    spawnOnce "killall udiskie; udiskie --tray"
    spawn myFixScreens
    spawnOnce "nm-applet"
    spawnOnce "xscreensaver --no-splash"
    spawnOnce "trayer --monitor primary --edge top --align right --SetDockType true --SetPartialStrut true --expand true --widthtype request --transparent true --alpha 0 --tint 0xffffff --height 21 --iconspacing 2"
    spawnOnOnce "TP11" myBrowser
    setWMName "LG3D"

-- =============================================================================
-- MAIN
-- =============================================================================

main :: IO ()
main = xmonad $ withUrgencyHook NoUrgencyHook
    $ setEwmhActivateHook doAskUrgent
    . ewmh
    . ewmhFullscreen
    . docks
    . withEasySB (statusBarProp "xmobar" myXmobarPP) defToggleStrutsKey
    $ addDescrKeys ((myModMask, xK_F1), xMessage)
        (\c -> mkNamedKeymap c myNewStyleKeys)
        def
            { terminal           = myTerminal
            , modMask            = myModMask
            , layoutHook         = avoidStruts $ smartBorders $ desktopLayoutModifiers myLayouts
            , manageHook         = manageDocks <+> myManageHook
            , startupHook        = myStartupHook
            , normalBorderColor  = myNormalBorderColor
            , focusedBorderColor = myFocusedBorderColor
            , workspaces         = myWorkspaces
            , logHook            = updatePointer (0.5, 0.5) (0, 0)
            }
