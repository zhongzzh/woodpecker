Option Explicit

Dim shell, fso, root, quote, command, candidates, candidate, launched
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

root = fso.GetParentFolderName(WScript.ScriptFullName)
shell.CurrentDirectory = root
quote = Chr(34)
launched = False

If fso.FileExists(root & "\.venv\Scripts\pythonw.exe") Then
    command = quote & root & "\.venv\Scripts\pythonw.exe" & quote
    On Error Resume Next
    shell.Run command & " -m pipeline.launcher", 0, False
    launched = (Err.Number = 0)
    Err.Clear
    On Error GoTo 0
Else
    candidates = Array("pyw.exe -3", "pythonw.exe", "python.exe")
    For Each candidate In candidates
        On Error Resume Next
        shell.Run candidate & " -m pipeline.launcher", 0, False
        launched = (Err.Number = 0)
        Err.Clear
        On Error GoTo 0
        If launched Then Exit For
    Next
End If

If Not launched Then
    MsgBox "Python 3.10 or newer was not found. Install Python with Tcl/Tk enabled, then try again.", 16, "Woodpecker"
End If
