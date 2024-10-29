;
; -----------------------------------------------------------------------------
; Copyright (c) 2014-2024 All rights reserved
; -----------------------------------------------------------------------------
; Author : yongchan jeon (Kris) poucotm@gmail.com
; File   : xcpu.ahk
; Create : 2024-08-06 10:45:29
; Editor : sublime text3, tab size (3)
; -----------------------------------------------------------------------------

#NoEnv
#Persistent
#SingleInstance force

;  —————————————————————————————————————————————————————————————————————————————
;  Functions  ——————————————————————————————————————————————————————————————————

FullScreen()
{
	WinGet, WID, ID, A
	WinGetPos,,, W, H, ahk_id %WID%
	If (W >= A_ScreenWidth && H >= A_ScreenHeight)
		Return True
	Else
		Return False
}

Explorer_GetSelection()
{
	WinGetClass, WinClass, % "ahk_id" . hWnd := WinExist("A")
	if !(WinClass ~= "Progman|WorkerW|(Cabinet|Explore)WClass")
		Return
	ShellWindows := ComObjCreate("Shell.Application").Windows
	If (WinClass ~= "Progman|WorkerW")
		ShellFolderView := ShellWindows.FindWindowSW(0, 0, SWC_DESKTOP := 8, 0, SWFO_NEEDDISPATCH := 1).Document
	Else {
		for w in ShellWindows
			If (hWnd = w.HWND && ShellFolderView := w.Document)
				Break
	}
	Return ShellFolderView.SelectedItems
}

;  ————————————————————————————————————————————————————————————————————————————— ;;*
;  MAIN  ———————————————————————————————————————————————————————————————————————

CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

Menu, Tray, NoStandard
Menu, Tray, Add, XCAPSLOCK, README
Menu, Tray, Add
Menu, Tray, Add, Exit, CLEANUP

global TCAP
CapsLockWindow()

global WNDHOOK
WNDHOOK := WinHook.Event.Add(3, 3, "WinFocused")

SetTimer, DispCapsLock, 1000

; Clean up for exit
OnExit, CLEANUP

Return

; DispCapsLock —————————————————————————————————————————————

DispCapsLock:
	If (FullScreen()) {
		WinHide, CAPS
	} Else {
		GetKeyState, CAPSSTATE, CapsLock, T
		If (CAPSSTATE == "D")
			WinShow, CAPS
		Else
			WinHide, CAPS
	}
	WinRestore, CAPS
	WinSet, AlwaysOnTop, On, CAPS
	Return

WinFocused(hWEH, EVT, WID, OID, CID, THR, SEC)
{
	WinGet, EXE, ProcessName, ahk_id %WID%
	WinGetClass, CLS, ahk_id %WID%
	If (EXE == "Explorer.EXE" && (CLS == "Progman" || CLS == "WorkerW")) {
		SetTimer, ShowXCAP, 1000
	}
}

ShowXCAP:
	SetTimer, ShowXCAP, Off
	If (Explorer_GetSelection().Count == 0) {
		WinActivate, ahk_class Shell_TrayWnd
	}
	Return

; CapsLockWindow —————————————————————————————————————————

CapsLockWindow()
{
	PX := 150, TO :=  -2, FS := "s18", BG := "eeeeee"
	SysGet, MonitorWorkArea, MonitorWorkArea
	WX := PX
	WY := MonitorWorkAreaBottom + TO
	Gui  CAPS:+LastFound -Caption +ToolWindow +hwndhMain
	Gui, CAPS:Margin, 10, 10
	Gui, CAPS:Color, %BG%
	Gui, CAPS:Font, %FS% c00a0ff bold, Ubuntu Condensed
	Gui, CAPS:Add, Text, xm ym 0x200 vTCAP, % "🔠"
	Gui, CAPS:Show, AutoSize, CAPS
	WinSet, AlwaysOnTop, On, CAPS
	WinSet, TransColor, %BG%, CAPS
	WinMove, CAPS,, WX, WY
	WinHide, CAPS
}

; class WinHook ——————————————————————————————————————————

class WinHook
{
	class Shell
	{
		Add(Func, wTitle:="", wClass:="", wExe:="", Event:=0)
		{
			if !WinHook.Shell.Hooks
			{
				WinHook.Shell.Hooks := {}, WinHook.Shell.Events := {}
				DllCall("RegisterShellHookWindow", UInt, A_ScriptHwnd)
				MsgNum := DllCall("RegisterWindowMessage", Str, "SHELLHOOK")
				OnMessage(MsgNum, ObjBindMethod(WinHook.Shell, "Message"))
			}
			if !IsObject(Func)
				Func := Func(Func)
			WinHook.Shell.Hooks.Push({Func: Func, Title: wTitle, Class: wClass, Exe: wExe, Event: Event})
			WinHook.Shell.Events[Event] := true
			return WinHook.Shell.Hooks.MaxIndex()
		}
		Remove(Index)
		{
			WinHook.Shell.Hooks.Delete(Index)
			WinHook.Shell.Events[Event] := {}	; delete and rebuild Event list
			For key, Hook in WinHook.Shell.Hooks
				WinHook.Shell.Events[Hook.Event] := true
		}
		Report(ByRef Obj:="")
		{
			Obj := WinHook.Shell.Hooks
			For key, Hook in WinHook.Shell.Hooks
				Display .= key "|" Hook.Event "|" Hook.Func.Name "|" Hook.Title "|" Hook.Class "|" Hook.Exe "`n"
			return Trim(Display, "`n")
		}
		Deregister()
		{
			DllCall("DeregisterShellHookWindow", UInt, A_ScriptHwnd)
			WinHook.Shell.Hooks := "", WinHook.Shell.Events := ""
		}
		Message(Event, Hwnd)  ; Private Method
		{
			DetectHiddenWindows, On
			If (WinHook.Shell.Events[Event] or WinHook.Shell.Events[0])
			{
				WinGetTitle, wTitle, ahk_id %Hwnd%
				WinGetClass, wClass, ahk_id %Hwnd%
				WinGet, wExe, ProcessName, ahk_id %Hwnd%
				for key, Hook in WinHook.Shell.Hooks
					if ((Hook.Title = wTitle or Hook.Title = "") and (Hook.Class = wClass or Hook.Class = "") and (Hook.Exe = wExe or Hook.Exe = "") and (Hook.Event = Event or Hook.Event = 0))
						return Hook.Func.Call(Hwnd, wTitle, wClass, wExe, Event)
			}
		}
	}
	class Event
	{
		Add(eventMin, eventMax, eventProc, idProcess := 0, WinTitle := "")
		{
			if !WinHook.Event.Hooks
			{
				WinHook.Event.Hooks := {}
				static CB_WinEventProc := RegisterCallback(WinHook.Event.Message)
				OnExit(ObjBindMethod(WinHook.Event, "UnHookAll"))
			}
			hWinEventHook := DllCall("SetWinEventHook"
				, "UInt",	eventMin						; UINT eventMin
				, "UInt",	eventMax						; UINT eventMax
				, "Ptr" ,	0x0							; HMODULE hmodWinEventProc
				, "Ptr" ,	CB_WinEventProc			; WINEVENTPROC lpfnWinEventProc
				, "UInt" ,	idProcess					; DWORD idProcess
				, "UInt",	0x0							; DWORD idThread
				, "UInt",	0x0|0x2)  					; UINT dwflags, OutOfContext|SkipOwnProcess
			if !IsObject(eventProc)
				eventProc := Func(eventProc)
			WinHook.Event.Hooks[hWinEventHook] := {eventMin: eventMin, eventMax: eventMax, eventProc: eventProc, idProcess: idProcess, WinTitle: WinTitle}
			return hWinEventHook
		}
		Report(ByRef Obj:="")
		{
			Obj := WinHook.Event.Hooks
			For hWinEventHook, Hook in WinHook.Event.Hooks
				Display .= hWinEventHook "|" Hook.eventMin "|" Hook.eventMax "|" Hook.eventProc.Name "|" Hook.idProcess "|" Hook.WinTitle "`n"
			return Trim(Display, "`n")
		}
		UnHook(hWinEventHook)
		{
				DllCall("UnhookWinEvent", "Ptr", hWinEventHook)
				WinHook.Event.Hooks.Delete(hWinEventHook)
		}
		UnHookAll()
		{
			for hWinEventHook, Hook in WinHook.Event.Hooks
				DllCall("UnhookWinEvent", "Ptr", hWinEventHook)
			WinHook.Event.Hooks := "", CB_WinEventProc := ""
		}
		Message(event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime)  ; 'Private Method
		{
			DetectHiddenWindows, On
			Hook := WinHook.Event.Hooks[hWinEventHook := this] ; this' is hidden param1 because method is called as func
			WinGet, List, List, % Hook.WinTitle
			Loop % List
				if  (List%A_Index% = hwnd)
					return Hook.eventProc.Call(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime)
		}
	}
}

;  —————————————————————————————————————————————————————————————————————————————
;  CLEANUP  ————————————————————————————————————————————————————————————————————

README:
	Return

CLEANUP:
	WinHook.Event.UnHook(WNDHOOK)
	ExitApp
