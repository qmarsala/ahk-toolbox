#Persistent
#SingleInstance force
#Warn, ClassOverwrite

SetWorkingDir, %A_ScriptDir%
clippy := new ClipboardManager()
Menu, ClipHistoryMenu, Add
return

;todo: optionally save clip history to file for persited history 

class ClipboardManager {
    __New() {
        this.clipHistory := []
        this.menuCreated := false
        this.truncateSize := 25
        this.maxHistory := 5
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
        this.menuCreated := true
    }

    PasteClipFromHistory(index) {
        clipSave := ClipboardAll
        Clipboard := this.clipHistory[index]
        this.PasteClipboard()
        Clipboard := clipSave
    }

    _processIncomingClipboardData(command) {
        if (this.clipHistory.Count() >= this.maxHistory) {
            this.clipHistory.Remove(this.clipHistory.MinIndex())
        }
        
        Clipboard := ""
        Send, %command%
        ClipWait
        this.clipHistory.Push(Clipboard)
    }

    _createCleanMenu() {
        if (this.menuCreated) {
            Menu, ClipHistoryMenu, DeleteAll
            this.menuCreated := false
        }
    }

    _getClipSummary(clip) {
        clipSummary := clip
        clipSummary := RegexReplace(clipSummary, "^\s+")
        clipSummary := RegexReplace(clipSummary, "\s+$")
        if (StrLen(clipSummary) > this.truncateSize) {
            clipSummary := SubStr(clipSummary, 1, this.truncateSize - 3) "..."
        }
        return clipSummary
    }

    _buildMenuItems() {
        for i, clip in this.clipHistory {
            clipSummary := this._getClipSummary(clip)
            Menu, ClipHistoryMenu, Add, %clipSummary%, MenuHandler
        }
        this.menuCreated := true
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
