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
        if (this.menuCreated) {
            Menu, ClipHistoryMenu, DeleteAll
            this.menuCreated := false
        }
        for i, clip in this.clipHistory {
            if (StrLen(clip) > this.truncateSize) {
                clipSummary := SubStr(clip, 1, this.truncateSize - 3) "..."
            } else {
                clipSummary := clip
            }
            Menu, ClipHistoryMenu, Add, %clipSummary%, MenuHandler
        }
        
        this.menuCreated := true
        Menu, ClipHistoryMenu, Show
    }

    Paste() {
        keyState := GetKeyState("LControl", P)
        now := A_TickCount
        while (keyState == 1) {
            if (A_TickCount - now > 500)
            {
                this.ShowClipHistory()
                return
            }
            keyState := GetKeyState("LControl", P)
        }
        this.PasteLastClip()
    }

    PasteLastClip() {
        this.PasteClip(this.clipHistory.MaxIndex())
    }

    PasteClip(index) {
        if (!DllCall("IsClipboardFormatAvailable", "uint", 1))
        {
            Send, ^v
            return
        }

        this.PasteClipText(index)
    }

    PasteClipText(index) {
        clipSave := ClipboardAll
        Clipboard := this.clipHistory[index]
        Send, ^v
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
}

MenuHandler:
    clippy.PasteClipText(A_ThisMenuItemPos)
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