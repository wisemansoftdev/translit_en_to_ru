# Translit RU for Windows 11

Type Latin letters, get Russian, using translit.ru's rules. This is the
Windows counterpart of the macOS keyboard layout. It's a small
[AutoHotkey v2](https://www.autohotkey.com) script that lives in the
taskbar tray. It isn't a Windows keyboard layout, because Windows layouts
can't express rules like `sch` → `сч`.

Each letter appears as soon as you type it. When the next letter forms a
combination, the previous letter is replaced, the same way translit.ru
works: `s` gives `с`, then `h` turns it into `ш`.

## Rules

| Type | Get | Type | Get |
|---|---|---|---|
| a b v g d e z i k l m n o p r s t u f | а б в г д е з и к л м н о п р с т у ф | h, x | х |
| c | ц | ch | ч |
| sh | ш | shh, w | щ |
| zh | ж | y | ы |
| j | й | je | э |
| ya, ja, q | я | yu, ju | ю |
| yo, jo | ё | `'` | ь |
| `#` (Shift+3) | ъ | `+` (Shift+=) | don't combine, e.g. `s+hodit` → сходит |

The first letter of a combination decides the case, so `Sh` and `SH`
both give `Ш`. When nothing is waiting to combine, `+` types a literal
`+`. Caps Lock works as usual, and with Caps Lock on, `'` and `#` give
`Ь` and `Ъ`.

## Shortcuts and on/off

- **Ctrl+Alt+T** turns it on or off. So does left-clicking the tray icon.
  The blue **RU** icon means on, grey means off.
- Shortcuts that use Ctrl, Alt or Win (Ctrl+C, Alt+Tab, Win+E…) are never
  changed.
- Letters are read by their physical position (US QWERTY), so they work
  whichever Windows layout is active. Digits and punctuation still come
  from the active layout, though. With Hebrew active, for example, the `,`
  key types `ת`. Keep English (US) active while you use it.
- Right-click the tray icon to see the rules, turn **Start with Windows**
  on or off, use **Run as administrator**, or **Exit**.

## Install

1. Unzip the folder anywhere.
2. Double-click **install.cmd**. It does the following:
   - checks for AutoHotkey v2, and if it's missing, offers to install it
     with `winget`
   - copies the script to `%LOCALAPPDATA%\TranslitRU`
   - adds it to your Startup folder
   - starts it
3. Look for the blue **RU** icon in the tray. It may be hidden under the
   `^` arrow. You can drag it onto the taskbar so it's always visible.

If Windows SmartScreen warns about the `.cmd` file, choose **More info →
Run anyway**. You can also right-click `install.ps1` and choose **Run with
PowerShell**.

## Uninstall

Double-click **uninstall.cmd**. It stops the script and removes the
shortcut and the `%LOCALAPPDATA%\TranslitRU` folder. It leaves AutoHotkey
installed; remove that in Settings → Apps if you don't use it for
anything else.

## Limitations

- **Programs running as administrator** (an elevated Terminal, Task
  Manager, some installers) won't receive the typing. This is a Windows
  security rule. Use **Run as administrator** from the tray menu when you
  need it.
- Replacing a letter sends a Backspace. In apps with aggressive
  autocomplete, that Backspace can occasionally remove a suggestion
  instead of the letter.
- Some games' anti-cheat systems block AutoHotkey. Turn it off or exit it
  before gaming.
- A literal `#` can't be typed while it's on. Press Ctrl+Alt+T to switch
  it off for a moment.
