# XCapsLock

[![PayPal](https://img.shields.io/badge/paypal-donate-blue.svg)][PM]

it displays keyboard capslock status.

[![Image of Guna][S1]][S1]


if you want to change about displaying, you should change the following in the middle of the code.

```
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
```

[S1]:https://raw.githubusercontent.com/poucotm/Links/master/image/xcapslock/xcapslock.jpg "enlarge"
[PM]:https://www.paypal.me/poucotm/1.0 "PayPal"


