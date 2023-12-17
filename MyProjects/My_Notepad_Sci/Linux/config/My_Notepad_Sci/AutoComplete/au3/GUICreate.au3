$hGui = GUICreate('My Program', 250, 260)
$iBtn = GUICtrlCreateButton('Start', 10, 10, 120, 22)
$iStatusBar = GUICtrlCreateLabel('StatusBar', 5, 260 - 20, 150, 17)
GUISetState()
While 1
	Switch GUIGetMsg()
		Case $iBtn
			GUICtrlSetData($iStatusBar, 'Done')
		Case -3
			Exit
	EndSwitch
WEnd