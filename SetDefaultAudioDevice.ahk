; http://www.daveamenta.com/2011-05/programmatically-or-command-line-change-the-default-sound-playback-device-in-windows-7/
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#NoTrayIcon
#SingleInstance, Ignore
#Persistent

IniRead, StartupMessage, config.cfg, DEBUG, StartupMessage, 0
IniRead, aWaitCompleteMessage, config.cfg, DEBUG, WaitCompleteMessage, 0
IniRead, aExitingMessage, config.cfg, DEBUG, ExitingMessage, 0
GLOBAL WaitCompleteMessage := aWaitCompleteMessage
GLOBAL ExitingMessage := aExitingMessage

If(StartupMessage="1")
{
    SetTimer, StartupMessageDebug, -500
}

IniRead, aStartupDelay, config.cfg, DELAYS, StartupDelay, 5000
GLOBAL StartupDelay := aStartupDelay

IniRead, aDefaultAudioDevice, config.cfg, DEVICE, DefaultDeviceToSet, Speakers (Realtek(R) Audio)
GLOBAL DefaultAudioDevice := aDefaultAudioDevice

IniRead, aPreTimerDelay, config.cfg, DELAYS, PreTimerDelay, 250
GLOBAL PreTimerDelay := aPreTimerDelay

IniRead, aCloseAppDelay, config.cfg, DELAYS, CloseAppDelay, 6000
GLOBAL CloseAppDelay := aCloseAppDelay

Sleep, %StartupDelay%

Devices := {}
IMMDeviceEnumerator := ComObjCreate("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")

; IMMDeviceEnumerator::EnumAudioEndpoints
; eRender = 0, eCapture, eAll
; 0x1 = DEVICE_STATE_ACTIVE
DllCall(NumGet(NumGet(IMMDeviceEnumerator+0)+3*A_PtrSize), "UPtr", IMMDeviceEnumerator, "UInt", 0, "UInt", 0x1, "UPtrP", IMMDeviceCollection, "UInt")
ObjRelease(IMMDeviceEnumerator)

; IMMDeviceCollection::GetCount
DllCall(NumGet(NumGet(IMMDeviceCollection+0)+3*A_PtrSize), "UPtr", IMMDeviceCollection, "UIntP", Count, "UInt")
Loop % (Count)
{
    ; IMMDeviceCollection::Item
    DllCall(NumGet(NumGet(IMMDeviceCollection+0)+4*A_PtrSize), "UPtr", IMMDeviceCollection, "UInt", A_Index-1, "UPtrP", IMMDevice, "UInt")

    ; IMMDevice::GetId
    DllCall(NumGet(NumGet(IMMDevice+0)+5*A_PtrSize), "UPtr", IMMDevice, "UPtrP", pBuffer, "UInt")
    DeviceID := StrGet(pBuffer, "UTF-16"), DllCall("Ole32.dll\CoTaskMemFree", "UPtr", pBuffer)

    ; IMMDevice::OpenPropertyStore
    ; 0x0 = STGM_READ
    DllCall(NumGet(NumGet(IMMDevice+0)+4*A_PtrSize), "UPtr", IMMDevice, "UInt", 0x0, "UPtrP", IPropertyStore, "UInt")
    ObjRelease(IMMDevice)

    ; IPropertyStore::GetValue
    VarSetCapacity(PROPVARIANT, A_PtrSize == 4 ? 16 : 24)
    VarSetCapacity(PROPERTYKEY, 20)
    DllCall("Ole32.dll\CLSIDFromString", "Str", "{A45C254E-DF1C-4EFD-8020-67D146A850E0}", "UPtr", &PROPERTYKEY)
    NumPut(14, &PROPERTYKEY + 16, "UInt")
    DllCall(NumGet(NumGet(IPropertyStore+0)+5*A_PtrSize), "UPtr", IPropertyStore, "UPtr", &PROPERTYKEY, "UPtr", &PROPVARIANT, "UInt")
    DeviceName := StrGet(NumGet(&PROPVARIANT + 8), "UTF-16")    ; LPWSTR PROPVARIANT.pwszVal
    DllCall("Ole32.dll\CoTaskMemFree", "UPtr", NumGet(&PROPVARIANT + 8))    ; LPWSTR PROPVARIANT.pwszVal
    ObjRelease(IPropertyStore)

    ObjRawSet(Devices, DeviceName, DeviceID)
}
ObjRelease(IMMDeviceCollection)
; Return






; Send, {F3}
; F1:: SetDefaultEndpoint( GetDeviceID(Devices, "Speakers (Focusrite USB Audio)") )
; F2:: SetDefaultEndpoint( GetDeviceID(Devices, "Headphones") )
; F3:: SetDefaultEndpoint( GetDeviceID(Devices, "Speakers (Realtek(R) Audio)") )
Process, Wait, FxSound.exe

If(WaitCompleteMessage="1")
{
    MsgBox, , SET DEFAULT AUDIO DEVICE DEBUG, Waiting for FXSOUND.EXE completed and now it exists!`n, 25
}
Sleep, %PreTimerDelay%
SetTimer, CloseApp, %CloseAppDelay%
SetDefaultEndpoint( GetDeviceID(Devices, DefaultAudioDevice) )
Return

SetDefaultEndpoint(DeviceID)
{
    IPolicyConfig := ComObjCreate("{870af99c-171d-4f9e-af0d-e63df40c2bc9}", "{F8679F50-850A-41CF-9C72-430F290290C8}")
    DllCall(NumGet(NumGet(IPolicyConfig+0)+13*A_PtrSize), "UPtr", IPolicyConfig, "UPtr", &DeviceID, "UInt", 0, "UInt")
    ObjRelease(IPolicyConfig)
}

GetDeviceID(Devices, Name)
{
    For DeviceName, DeviceID in Devices
        If (InStr(DeviceName, Name))
            Return DeviceID
}


Return
CloseApp:
If(ExitingMessage="1")
{
    MsgBox, , SET DEFAULT AUDIO DEVICE DEBUG, EXITING AFTER THIS MESSAGE IS DISMISSED (AUTO DISMISS IN 25 SECONDS)!`n, 25
}
ExitApp
Return


StartupMessageDebug:
MsgBox, , SET DEFAULT AUDIO DEVICE DEBUG, Startup Message Fired!`n`n DELAY CHECKS: `n`n StartupDelay: %StartupDelay%`n PreTimerDelay: %PreTimerDelay%`n PreTimerDelay: %PreTimerDelay%`n CloseAppDelay: %CloseAppDelay%, 25
Return