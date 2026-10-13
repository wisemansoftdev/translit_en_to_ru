; =============================================================================
;  Translit RU for Windows -- type Latin letters, get Russian (translit.ru rules)
;  Requires AutoHotkey v2 (https://www.autohotkey.com)
;
;  Toggle on/off:  Ctrl+Alt+T   (or left-click the tray icon)
;
;  Works like translit.ru itself: every letter appears immediately, and when
;  the next letter forms a combination (s+h -> ш, y+a -> я, ...) the previous
;  Cyrillic letter is replaced. Keys are read by their physical position
;  (US QWERTY), so it works whatever Windows keyboard layout is active.
; =============================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
KeyHistory 0
ListLines false
SendMode "Input"

START_ENABLED := true

; ---------------------------------------------------------------- the rules --
; Letter -> Cyrillic when typed on its own.
DIRECT := Map(
    "a", "а", "b", "б", "v", "в", "g", "г", "d", "д", "e", "е",
    "z", "з", "i", "и", "k", "к", "l", "л", "m", "м", "n", "н",
    "o", "о", "p", "п", "r", "р", "s", "с", "t", "т", "u", "у",
    "f", "ф", "h", "х", "x", "х", "c", "ц", "w", "щ", "q", "я",
    "y", "ы", "j", "й"
)

; COMBOS[previous][next letter] := [replacement, new previous]
; "previous" is what the last typed unit can still turn into.
COMBOS := Map(
    "s",  Map("h", ["ш", "sh"]),
    "sh", Map("h", ["щ", ""]),
    "c",  Map("h", ["ч", ""]),
    "z",  Map("h", ["ж", ""]),
    "y",  Map("a", ["я", ""], "u", ["ю", ""], "o", ["ё", ""]),
    "j",  Map("a", ["я", ""], "u", ["ю", ""], "o", ["ё", ""], "e", ["э", ""])
)

; Physical key (scan code, US QWERTY position) -> Latin letter.
LETTER_SC := Map(
    0x10, "q", 0x11, "w", 0x12, "e", 0x13, "r", 0x14, "t", 0x15, "y",
    0x16, "u", 0x17, "i", 0x18, "o", 0x19, "p",
    0x1E, "a", 0x1F, "s", 0x20, "d", 0x21, "f", 0x22, "g", 0x23, "h",
    0x24, "j", 0x25, "k", 0x26, "l",
    0x2C, "z", 0x2D, "x", 0x2E, "c", 0x2F, "v", 0x30, "b", 0x31, "n",
    0x32, "m"
)
SC_QUOTE := 0x28   ; '  -> ь
SC_3     := 0x04   ; Shift+3 (#) -> ъ
SC_EQUAL := 0x0D   ; Shift+= (+) -> separator

; One step of the transliteration. Pure function -- no side effects.
;   prev, prevUpper : what the previous unit can still become, and its case
;   letter, isUpper : the Latin letter just typed (lowercase) and its case
; Returns {erase: 0|1, text: Cyrillic to type, prev: ..., prevUpper: ...}
Step(prev, prevUpper, letter, isUpper) {
    if (prev != "" && COMBOS.Has(prev) && COMBOS[prev].Has(letter)) {
        r := COMBOS[prev][letter]
        ; the FIRST letter of a combination decides its case: Sh/SH -> Ш
        return {erase: 1, text: CaseOf(r[1], prevUpper), prev: r[2], prevUpper: prevUpper}
    }
    nextPrev := COMBOS.Has(letter) ? letter : ""   ; s, c, z, y, j may combine later
    return {erase: 0, text: CaseOf(DIRECT[letter], isUpper), prev: nextPrev, prevUpper: isUpper}
}

CaseOf(s, upper) => upper ? StrUpper(s) : s

; ---------------------------------------------------------------- the state --
gPrev := ""        ; what the last typed letter can still combine into
gPrevUpper := false
gHwnd := 0         ; window it was typed in

ResetState(*) {
    global gPrev, gPrevUpper
    gPrev := "", gPrevUpper := false
}

OnLetter(letter, shifted, *) {
    global gPrev, gPrevUpper, gHwnd
    hwnd := WinExist("A")
    if (hwnd != gHwnd)
        ResetState()
    isUpper := (shifted != GetKeyState("CapsLock", "T"))
    r := Step(gPrev, gPrevUpper, letter, isUpper)
    if r.erase
        Send("{BS}")
    SendText(r.text)
    gPrev := r.prev, gPrevUpper := r.prevUpper, gHwnd := hwnd
}

OnSoftSign(*) {
    ResetState()
    SendText(GetKeyState("CapsLock", "T") ? "Ь" : "ь")
}

OnHardSign(*) {
    ResetState()
    SendText(GetKeyState("CapsLock", "T") ? "Ъ" : "ъ")
}

; "+" : if a combination is pending, end it without typing anything
; (s+hodit -> сходит); otherwise just type "+".
OnPlus(*) {
    global gPrev, gHwnd
    if (gPrev != "" && WinExist("A") = gHwnd)
        ResetState()
    else
        SendText("+")
}

; ------------------------------------------------------------- the hotkeys --
; Hotkeys without modifiers fire only when Ctrl/Alt/Win are NOT held, so
; Ctrl+C, Alt+F4, Win+E etc. pass straight through untouched.
for sc, letter in LETTER_SC {
    name := "SC" Format("{:03X}", sc)
    Hotkey(name, OnLetter.Bind(letter, false))
    Hotkey("+" name, OnLetter.Bind(letter, true))
}
Hotkey("SC" Format("{:03X}", SC_QUOTE), OnSoftSign)        ; '  (Shift+' still types ")
Hotkey("+SC" Format("{:03X}", SC_3), OnHardSign)           ; #  (plain 3 still types 3)
Hotkey("+SC" Format("{:03X}", SC_EQUAL), OnPlus)           ; +  (plain = still types =)

; Clicking somewhere moves the caret -- forget the pending combination.
Hotkey("~*LButton", ResetState)
Hotkey("~*RButton", ResetState)
Hotkey("~*MButton", ResetState)

; Any other key (Space, Backspace, arrows, digits, punctuation, Ctrl+...)
; also ends a pending combination. Our own Send/SendText output is ignored
; ("I" option), and keys don't get blocked ("V").
gWatcher := InputHook("L0 V I")
gWatcher.KeyOpt("{All}", "N")
gWatcher.OnKeyDown := OnAnyKeyDown
gWatcher.Start()

OnAnyKeyDown(ih, vk, sc) {
    if A_IsSuspended
        return
    ; modifiers on their own (Shift for a capital, Caps Lock, ...) don't count
    static MODIFIER_VK := Map(0x10,1, 0x11,1, 0x12,1, 0x14,1, 0x90,1, 0x91,1,
                              0xA0,1, 0xA1,1, 0xA2,1, 0xA3,1, 0xA4,1, 0xA5,1, 0x5B,1, 0x5C,1)
    if MODIFIER_VK.Has(vk)
        return
    if HandledByUs(sc)
        return
    ResetState()
}

; Will one of the hotkeys above take care of this key press?
HandledByUs(sc) {
    if (GetKeyState("Ctrl") || GetKeyState("Alt") || GetKeyState("LWin") || GetKeyState("RWin"))
        return false
    shift := GetKeyState("Shift")
    if LETTER_SC.Has(sc)
        return true
    if (sc = SC_QUOTE)
        return !shift
    if (sc = SC_3 || sc = SC_EQUAL)
        return shift
    return false
}

; -------------------------------------------------------- on/off + tray icon --
ICON_ON  := A_ScriptDir "\translit-on.ico"
ICON_OFF := A_ScriptDir "\translit-off.ico"
STARTUP_LINK := A_Startup "\Translit RU.lnk"
MENU_ENABLED := "Enabled`tCtrl+Alt+T"
MENU_STARTUP := "Start with Windows"

#SuspendExempt
^!t::Toggle()
#SuspendExempt false

SetEnabled(on) {
    ResetState()
    Suspend(!on)
    if FileExist(on ? ICON_ON : ICON_OFF)
        TraySetIcon(on ? ICON_ON : ICON_OFF, , true)
    A_IconTip := "Translit RU: " (on ? "ON" : "OFF") "  (Ctrl+Alt+T)"
    if on
        A_TrayMenu.Check(MENU_ENABLED)
    else
        A_TrayMenu.Uncheck(MENU_ENABLED)
}

Toggle(*) {
    SetEnabled(A_IsSuspended)
    ToolTip("Translit RU: " (A_IsSuspended ? "OFF" : "ON"))
    SetTimer(() => ToolTip(), -900)
}

ToggleStartup(*) {
    if FileExist(STARTUP_LINK) {
        FileDelete(STARTUP_LINK)
        A_TrayMenu.Uncheck(MENU_STARTUP)
    } else {
        FileCreateShortcut(A_AhkPath, STARTUP_LINK, A_ScriptDir, '"' A_ScriptFullPath '"',
                           "Translit RU", ICON_ON)
        A_TrayMenu.Check(MENU_STARTUP)
    }
}

; Windows doesn't let a normal program type into programs running as
; administrator. This restarts Translit RU elevated so it can.
RunAsAdmin(*) {
    if A_IsAdmin {
        MsgBox("Translit RU is already running as administrator.", "Translit RU")
        return
    }
    try Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"')
    catch
        return
    ExitApp()
}

ShowRules(*) {
    rules := "
(
a  b  v  g  d  e  z  i  k  l  m  n  o  p  r  s  t  u  f  h/x  c
а  б  в  г  д  е  з  и  к  л  м  н  о  п  р  с  т  у  ф   х   ц

ch → ч     sh → ш     shh / w → щ     zh → ж
ya / ja / q → я     yu / ju → ю     yo / jo → ё
je → э     y → ы     j → й

'  → ь        #  (Shift+3) → ъ
+  (Shift+=) → don't combine, e.g. s+hodit → сходит

The case of the first letter decides: Sh / SH → Ш.
Ctrl / Alt / Win shortcuts are never changed.
)"
    MsgBox(rules, "Translit RU — rules")
}

tray := A_TrayMenu
tray.Delete()
tray.Add(MENU_ENABLED, Toggle)
tray.Add(MENU_STARTUP, ToggleStartup)
tray.Add()
tray.Add("Show rules", ShowRules)
tray.Add("Run as administrator", RunAsAdmin)
tray.Add()
tray.Add("Exit", (*) => ExitApp())
tray.Default := MENU_ENABLED
tray.ClickCount := 1
if FileExist(STARTUP_LINK)
    tray.Check(MENU_STARTUP)

SetEnabled(START_ENABLED)
