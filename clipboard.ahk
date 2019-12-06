#Persistent
#SingleInstance force
#Warn, ClassOverwrite

SetWorkingDir, %A_ScriptDir%
clippy := new ClipboardManager()
Menu, ClipHistoryMenu, Add
return

;todo: read existing clip history from working dir 

class ClipboardManager {
    __New() {
        this.menuCreated := false
        this.truncateSize := 25
        this.nextIndex := 1
        this.totalClips := 0
    }

    SaveClip() {
        this._processIncomingClipboardData("^c")
    }

    SaveCut() {
        this._processIncomingClipboardData("^x")
    }

    ShowClipHistory() { 
        this._createCleanMenu()
        this._buildMenuItems()
        Menu, ClipHistoryMenu, Show
    }

    Paste() {
        menuPrompted := this._checkForMenuRequest()
        if (!menuPrompted) {
            this.PasteClipboard()
        }
    }

    PasteClipboard() {
        Send, ^v
    }

    PasteClipFromHistory(index) {
        clipSave := ClipboardAll
        clipPath := A_WorkingDir "\" index ".clip"
        FileRead, Clipboard, *c %clipPath%
        this.PasteClipboard()
        Clipboard := clipSave
    }

    _processIncomingClipboardData(command) {
        if (this.nextIndex > 5) {
            this.nextIndex := 1
        }
        
        Clipboard := ""
        Send, %command%
        ClipWait
        clipPath := A_WorkingDir "\" this.nextIndex ".clip"
        FileAppend, %ClipboardAll%, %clipPath%
        this.nextIndex := this.nextIndex + 1
        if (this.totalClips < 5)
        {
            this.totalClips := this.totalClips + 1
        }
    }

    _createCleanMenu() {
        if (this.menuCreated) {
            Menu, ClipHistoryMenu, DeleteAll
            this.menuCreated := false
        }
    }

    _buildMenuItems() {
        i := 1
        while (i <= this.totalClips) {
            clipSummary := this._getClipSummary(i)
            Menu, ClipHistoryMenu, Add, %clipSummary%, MenuHandler
            i := i + 1
        }
        this.menuCreated := true
    }

    _getClipSummary(index) {
        clipSave := ClipboardAll
        clipPath := A_WorkingDir "\" index ".clip"
        FileRead, Clipboard, *c %clipPath%
        if (!(DllCall("IsClipboardFormatAvailable", "uint", 1) && DllCall("IsClipboardFormatAvailable", "uint", 13)))
        {
            return "binary data (" index ") ..."
        }

        clipSummary := Clipboard
        clipSummary := RegexReplace(clipSummary, "^\s+")
        clipSummary := RegexReplace(clipSummary, "\s+$")
        if (StrLen(clipSummary) > this.truncateSize) {
            clipSummary := SubStr(clipSummary, 1, this.truncateSize - 3) "..."
        }
        Clipboard := clipSave
        return clipSummary
    }

    _checkForMenuRequest() {
        keyState := GetKeyState("LControl", P)
        now := A_TickCount
        while (keyState == 1) {
            if (A_TickCount - now > 500)
            {
                this.ShowClipHistory()
                return true
            }
            keyState := GetKeyState("LControl", P)
        }
        return false
    }
}

MenuHandler:
    clippy.PasteClipFromHistory(A_ThisMenuItemPos)
return

$^x::
    clippy.SaveCut()
return

$^c::
    clippy.SaveClip()
return

$^v::
    clippy.Paste()
return
