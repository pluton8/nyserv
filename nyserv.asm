;«««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««
;                            NewYear Service 2.0
;     Прога-сервис, которая показывает сколько дней/часов/чмс осталось до
;       наступления Нового Года.
;     Все замЫчания, вопросы и предложения по проге присылайте на мой мыл:
;       plutonpluton@mail.ru
;                                                    (c) by Pluton, Odessa, 2006
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.386
.model flat, stdcall
option casemap: none

include ..\include\windows.inc
include ..\include\kernel32.inc
include ..\include\advapi32.inc
include ..\include\gdi32.inc
include ..\include\user32.inc
include ..\include\masm32.inc
include ..\include\debug.inc
include ..\macros\macros.asm
includelib ..\lib\kernel32.lib
includelib ..\lib\advapi32.lib
includelib ..\lib\gdi32.lib
includelib ..\lib\user32.lib
includelib ..\lib\masm32.lib
includelib ..\lib\debug.lib

.const
  crBkgnd equ 000000ffh         ; цвет фона окна
  ;crText equ 00000000h          ; цвет фонта
  TimerID equ 800
  TimerRefreshID equ 801
  milliseconds equ 20000        ; через сколько миллисекунд окно закроется
  reftime equ 500               ; время обновления

.data
  szName db "NewYear Service 2.0", 0
  ServiceTable dd offset szName, offset NYServ, 0, 0
  szClassName db "NYclass2", 0
  szfmt db "%lx", 0
  szdsk db 'Winlogon', 0
  table db 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
  szNY db "до Нового Года", 13, 10, "осталось ", 0
  szDays db "%s%lu дней", 0
  szHours db "%s%lu часов", 0
  szHMS db "%s%lu:%lu:%lu", 0
  szEOpen db "Не могу открыть SCM", 0
  szECreate db "Не могу установить сервис", 0
  szEOpenS db "Не могу открыть сервис", 0
  szEDelete db "Не могу удалить сервис", 0
  szHelp db "NewYear Service 2.0", 0dh, 0ah
         db "     Programmed by Pluton, Odessa, 2006", 0dh, 0ah
         db "Показывает сколько осталось дней до", 0dh, 0ah
         db "ближайшего Нового Года", 0dh, 0ah
         db "Параметры:", 0dh, 0ah
         db "/s - установить сервис", 0dh, 0ah
         db "/d - удалить сервис", 0dh, 0ah
         db "/? - этот хелп", 0
  crText COLORREF 0

.data?
  ServStatus SERVICE_STATUS <>
  ssh SERVICE_STATUS_HANDLE ?
  hInstance HMODULE ?
  buf db 252 dup (?)  ; <|  две части
  buf2 db 4 dup (?)   ; <|  одного буфера
  cmdline LPSTR ?
;  hTimer HANDLE ?
  sch SC_HANDLE ?
  schs SC_HANDLE ?
  hMWnd HWND ?

.code

Handler proto :DWORD
WndProc proto :DWORD, :DWORD, :DWORD, :DWORD

GetNumParameters proc uses ebx edx
  xor eax, eax  ; колво параметров
  ;inc eax
  xor edx, edx  ; флаг. есть ли кавычки
  mov ebx, cmdline  ; указатель на параметры
@b1:
  cmp byte ptr [ebx], 0
  je @endproc
  cmp byte ptr [ebx], '"'
  jne @l1
    test edx, edx
    je @c1
      dec edx
      jmp @l1
    @c1:
      inc edx
  @l1:
  cmp byte ptr [ebx], ' '
  jne @l2
    test edx, edx
    jne @l2
      inc eax
  @l2:
  inc ebx
  jmp @b1
@endproc:
  ret
GetNumParameters endp

start:
  invoke GetModuleHandle, NULL
  mov hInstance, eax
  invoke GetCommandLine
  mov cmdline, eax
  invoke lstrlen, cmdline
  ;int 3
  mov edx, dword ptr cmdline
  add edx, eax
  dec edx
  ;mov edx, [edx]
  .if byte ptr [edx] == " "
    mov byte ptr [edx], 0
  .endif
  ;dec edx
  call GetNumParameters
  ;invoke wsprintf, addr buf, addr szfmt, eax
  ;invoke MessageBox, NULL, addr buf, NULL, MB_OK
  ;invoke MessageBox, NULL, cmdline, NULL, MB_OK
  .if eax == 1
    invoke lstrlen, cmdline
    ;int 3
    mov edx, dword ptr cmdline
    add edx, eax
    dec edx
    mov dl, byte ptr [edx]
    .if dl == 's'
      invoke GetModuleFileName, hInstance, addr buf, 256
      ;invoke MessageBox, NULL, addr buf, NULL, MB_OK
      invoke OpenSCManager, NULL, NULL, SC_MANAGER_CREATE_SERVICE
      .if eax != NULL
        mov sch, eax
        invoke CreateService, sch, addr szName, addr szName, \
          DELETE or SERVICE_INTERROGATE or SERVICE_PAUSE_CONTINUE or \
          SERVICE_START or SERVICE_STOP or SERVICE_QUERY_STATUS or \
          SERVICE_QUERY_CONFIG, SERVICE_WIN32_OWN_PROCESS or \
          SERVICE_INTERACTIVE_PROCESS, SERVICE_AUTO_START, \
          SERVICE_ERROR_NORMAL, addr buf, NULL, NULL, NULL, NULL, NULL
        .if eax != NULL
          invoke CloseServiceHandle, eax
        .else
          invoke MessageBox, NULL, addr szECreate, addr szName, MB_OK or \
            MB_ICONERROR
        .endif
        invoke CloseServiceHandle, sch
      .else
        invoke MessageBox, NULL, addr szEOpen, addr szName, MB_OK or \
          MB_ICONERROR
      .endif
    .elseif dl == 'd'
      invoke OpenSCManager, NULL, NULL, DELETE
      .if eax != NULL
        mov sch, eax
        invoke OpenService, sch, addr szName, DELETE or SERVICE_STOP
        .if eax != NULL
          mov schs, eax
          invoke ControlService, schs, SERVICE_CONTROL_STOP, addr ServStatus
          invoke DeleteService, schs
          .if eax == NULL
            invoke MessageBox, NULL, addr szEDelete, addr szName, MB_OK or \
              MB_ICONERROR
          .endif
          invoke CloseServiceHandle, schs
        .else
          invoke MessageBox, NULL, addr szEOpenS, addr szName, MB_OK or \
            MB_ICONERROR
        .endif
        invoke CloseServiceHandle, sch
      .else
        invoke MessageBox, NULL, addr szEOpen, addr szName, MB_OK or \
          MB_ICONERROR
      .endif
    .elseif dl == '?'
      invoke MessageBox, NULL, addr szHelp, addr szName, MB_OK or \
        MB_ICONWARNING or MB_SERVICE_NOTIFICATION
    .endif
    ;and edx, 000000ffh
    ;invoke wsprintf, addr buf, addr szfmt, edx
    ;invoke MessageBox, NULL, addr buf, NULL, MB_OK
  .endif
  ;PrintStringByAddr eax
;  invoke MessageBox, NULL, addr szHelp, addr szName, MB_OK or \
;    MB_ICONWARNING or MB_SERVICE_NOTIFICATION
  invoke StartServiceCtrlDispatcher, addr ServiceTable
  call GetLastError
  push eax
  call ExitProcess
  ret

NYServ proc dwArgc: DWORD, lpszArgv: DWORD
; dwArgc - количество аргументов
; lpszArgv - указатель на массив указателей на строки-аргументы
  local wcex: WNDCLASSEX
  local msg: MSG
  local hWnd: HWND
  ;local ws: HWINSTA
  
  mov ServStatus.dwServiceType, SERVICE_WIN32_OWN_PROCESS
  mov ServStatus.dwCurrentState, SERVICE_RUNNING
  mov ServStatus.dwControlsAccepted, SERVICE_CONTROL_STOP or \
    SERVICE_CONTROL_CONTINUE or SERVICE_CONTROL_SHUTDOWN
  mov ServStatus.dwWin32ExitCode, 0;ERROR_SERVICE_SPECIFIC_ERROR;NO_ERROR
  mov ServStatus.dwServiceSpecificExitCode, 0
  mov ServStatus.dwCheckPoint, 0
  mov ServStatus.dwWaitHint, 1
  
  invoke RegisterServiceCtrlHandler, addr szName, addr Handler
  mov ssh, eax
  invoke SetServiceStatus, ssh, addr ServStatus
  
  ;invoke GetProcessWindowStation
  ;mov ws, eax
  ;invoke GetUserObjectInformation, ws, UOI_NAME, addr buf, 100, NULL
  ;invoke MessageBox, NULL, addr buf, addr szName, MB_OK or MB_ICONWARNING or MB_SERVICE_NOTIFICATION
; ------------------------------------------------------------------------------
  invoke OpenDesktop, addr szdsk, 0, FALSE, GENERIC_ALL                  ;<|
  invoke SetThreadDesktop, eax                                           ;<|
; это нужно раскомментировать чтобы окно появилось на десктопе винлогона ---/
; пишем чего нам надо
; ------------------------------------------------------------------------------
  ;invoke Sleep, 5000
  invoke GetModuleHandle, NULL
  mov hInstance, eax
  
  mov wcex.cbSize, sizeof WNDCLASSEX
  mov wcex.style, CS_HREDRAW or CS_VREDRAW or CS_GLOBALCLASS
  mov wcex.lpfnWndProc, offset WndProc
  mov wcex.cbClsExtra, NULL
  mov wcex.cbWndExtra, NULL
  m2m wcex.hInstance, hInstance
  invoke LoadIcon, NULL, IDI_APPLICATION
  mov wcex.hIcon, eax
  mov wcex.hIconSm, eax
  invoke LoadCursor, NULL, IDC_ARROW
  mov wcex.hCursor, eax
  invoke CreateSolidBrush, crBkgnd
  mov wcex.hbrBackground, eax;COLOR_BTNFACE + 1
  mov wcex.lpszMenuName, NULL
  mov wcex.lpszClassName, offset szClassName
  
  invoke RegisterClassEx, addr wcex
  invoke CreateWindowEx, WS_EX_LAYERED or WS_EX_TOPMOST, addr szClassName, \
    NULL, WS_POPUP, 100, 420, 850, 300, NULL, NULL, hInstance, NULL
  mov hWnd, eax
  mov hMWnd, eax
  invoke ShowWindow, eax, SW_SHOWNOACTIVATE
  invoke UpdateWindow, hWnd
  
  .while TRUE
    invoke GetMessage, addr msg, NULL, 0, 0
  .break .if (!eax)
    invoke TranslateMessage, addr msg
    invoke DispatchMessage, addr msg
  .endw
;  invoke ExitProcess, msg.wParam
;  ret

; ------------------------------------------------------------------------------
  mov ServStatus.dwCurrentState, SERVICE_CONTROL_STOP
  invoke SetServiceStatus, ssh, addr ServStatus
  ret
NYServ endp

dwordtoa proc uses ebx esi edi \
dwValue:DWORD, lpBuffer: LPSTR
; result => edx
  ;int 3
  mov eax, dwValue
  mov edi, [lpBuffer]
  test eax,eax
  jnz @@d2a1
zero:
  mov edx, 00000030h
  jmp @@dtaexit
@@d2a1:
  ;jns pos
  ;mov byte ptr [edi],'-'
  ;neg eax
  ;add edi, 1
;pos:
  mov ecx, 3435973837 ; CCCCCCCD
  mov esi, edi
  .while (eax > 0)
    mov ebx, eax
    mul ecx
    shr edx, 3
    mov eax,edx
    lea edx,[edx*4+edx]
    add edx,edx
    sub ebx,edx
    add bl,'0'
    mov [edi],bl
    add edi, 1
  .endw
  mov byte ptr [edi], 0       ; terminate the string
  ; We now have all the digits, but in reverse order.
;  .while (esi < edi)
;    sub edi, 1
;    mov al, [esi]
;    mov ah, [edi]
;    mov [edi], al
;    mov [esi], ah
;    add esi, 1
;  .endw
@@dtaexit:
  ret
dwordtoa endp

Handler proc fdwControl: DWORD
  inc ServStatus.dwCheckPoint
  .if (fdwControl == SERVICE_CONTROL_STOP) || (fdwControl == SERVICE_CONTROL_SHUTDOWN)
    invoke SendMessage, hMWnd, WM_CLOSE, 0, 0
    mov ServStatus.dwCurrentState, SERVICE_CONTROL_STOP
    ;invoke MessageBox, NULL, addr szName, addr szName, MB_OK or MB_SERVICE_NOTIFICATION
  .elseif fdwControl == SERVICE_CONTROL_CONTINUE
    mov ServStatus.dwCurrentState, SERVICE_CONTROL_CONTINUE
  ;.elseif fdwControl == SERVICE_CONTROL_INTERROGATE
;    
  .endif
  invoke SetServiceStatus, ssh, addr ServStatus
;  invoke MessageBox, NULL, addr szName, addr szName, MB_OK or MB_SERVICE_NOTIFICATION
  ret
Handler endp

PaintProc proc uses edx ebx \
hWnd: HWND
  local time: SYSTEMTIME
  local ps: PAINTSTRUCT
  local hdc: HDC
  local days: DWORD
  local holdfont: HFONT
  local rect: RECT
  ;local crold: COLORREF
  invoke GetLocalTime, addr time
  ;mov time.wMonth, 12
  ;mov time.wDay, 13
  ;mov time.wYear, 2008
  ;mov time.wHour, 22
  invoke BeginPaint, hWnd, addr ps
  mov hdc, eax
  
  mov days, 0
  xor eax, eax
  ;xor edx, edx
  ;xor ebx, ebx
  ;int 3
  mov ax, time.wYear
  and eax, 00000003h
  ;mov ax, 2008
  ;mov bl, 4
  ;PrintDec eax
  ;PrintDec ebx
  ;PrintDec edx
  ;div bx
  ;PrintDec eax
  ;PrintDec ebx
  ;PrintDec edx
  .if al == 0
    inc byte ptr [table + 1]
  .endif
  
  mov dx, 12
  sub dx, time.wMonth
@@loop1:
  ;PrintHex days
  test dx, dx
  jz @@end_loop1
  ;invoke DebugBreak
  xor ebx, ebx
  mov bx, 12
  sub bx, dx
  ;PrintHex ebx
  add ebx, offset table
  ;PrintHex ebx
  ;mov ebx, [ebx]
  xor eax, eax
  mov al, byte ptr [ebx]
  ;PrintHex ebx
  add days, eax 
  ;PrintHex days
  dec dx
  jnz @@loop1
  ;PrintHex days
  
@@end_loop1:
  ;xor ebx, ebx
  mov bx, time.wDay
  mov eax, offset table
  add ax, time.wMonth
  dec ax
  mov al, byte ptr [eax]
  sub al, bl
  cbw
  cwde
  add days, eax
  ;PrintHex days
  
  .if byte ptr [table + 1] == 29
    dec byte ptr [table + 1]
  .endif
  
  invoke CreateFont, 120, 0, 0, 0, FW_BLACK, FALSE, FALSE, FALSE, \
    RUSSIAN_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, \
    DEFAULT_QUALITY, DEFAULT_PITCH or FF_SCRIPT, NULL
  invoke SelectObject, hdc, eax
  mov holdfont, eax
  
  ;xor eax, eax
  xor edx, edx
  ;xor ebx, ebx
  mov eax, days
  mov ebx, 255
  mul bx
  mov ebx, 365
  div bx
  ;int 3
  ;mov ah, 255
  ;sub ah, al
  ;int 3
  sub al, 255
  neg al
  ;and eax, 000000ffh
  mov ah, al
  ;shl eax, 8
  ;mov al, ah
  mov crText, eax
  ;PrintDec crText
  ;mov crText, 00ffffffh
  
  invoke SetTextColor, hdc, crText
  ;mov crold, eax
  invoke SetBkMode, hdc, TRANSPARENT
  invoke GetClientRect, hWnd, addr rect
  invoke lstrcpy, addr buf, addr szNY
  .if days != 0
    ;int 3
    ;dec days
    invoke dwordtoa, days, addr buf2
    xor ebx, ebx
    .if byte ptr [buf2+1] != '1'
      .if byte ptr [buf2] == '1'
        inc ebx
      .elseif (byte ptr [buf2] >= '2') && (byte ptr [buf2] <= '4')
        inc ebx
        inc ebx
      .endif
    .endif
    ;push edx
    invoke wsprintf, addr buf, addr szDays, addr buf, days
    ;mov edx, days
    ;and edx, 0000000fh
    invoke lstrlen, addr buf
    ;pop edx
    .if bl == 1
      sub eax, 3
      mov dword ptr buf[eax], 000FCEDE5h
      mov dword ptr buf[21], 2020FFF1h
    .elseif bl == 2
      sub eax, 2
      mov word ptr buf[eax], 00FFh
    .endif
  .else
    xor ebx, ebx
    mov bx, time.wHour
    sub bx, 24
    neg bx
    .if ebx > 6
      invoke wsprintf, addr buf, addr szHours, addr buf, ebx
    .else
      xor edx, edx
      mov dx, 60
      sub dx, time.wSecond
      push edx
      mov dx, 60
      sub dx, time.wMinute
      push edx
      push ebx
      push offset buf
      push offset szHMS
      push offset buf
      call wsprintf
      add esp, 24
    .endif
    ;invoke wsprintf, addr buf
  .endif
  invoke lstrlen, addr buf
  mov ebx, eax
  invoke DrawText, hdc, addr buf, ebx, addr rect, DT_CENTER; or DT_WORDBREAK
  invoke SelectObject, hdc, holdfont
  invoke DeleteObject, eax
  
  invoke EndPaint, hWnd, addr ps
  ret
PaintProc endp

WndProc proc \
hWnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM
  .if uMsg == WM_DESTROY
    ;int 3
;    invoke dwordtoa, 18, addr buf
;    invoke MessageBox, NULL, addr buf, addr szName, MB_OK or MB_SERVICE_NOTIFICATION
    invoke GetClassLong, hWnd, GCL_HBRBACKGROUND
;    .if eax != NULL
    invoke DeleteObject, eax
;    .endif
    invoke KillTimer, hWnd, TimerRefreshID
    invoke PostQuitMessage, NULL
  ;.elseif uMsg==WM_CREATE
  ;invoke wsprintf, addr buf, addr szfmt,  eax
  ;invoke MessageBox, NULL, addr buf, addr szName, MB_OK or MB_SERVICE_NOTIFICATION
  .elseif uMsg == WM_PAINT
    invoke PaintProc, hWnd
  .elseif uMsg == WM_CREATE
    invoke SetLayeredWindowAttributes, hWnd, crBkgnd, 0, LWA_COLORKEY
    invoke SetTimer, hWnd, TimerID, milliseconds, NULL
    ;mov hTimer, eax
    invoke SetTimer, hWnd, TimerRefreshID, reftime, NULL
  .elseif uMsg == WM_TIMER
    mov eax, wParam
    switch wParam
      case TimerID
        invoke KillTimer, hWnd, TimerID
        PrintError
        invoke PostMessage, hWnd, WM_DESTROY, 0, 0
      case TimerRefreshID
        invoke InvalidateRect, hWnd, NULL, TRUE
    endsw
  .else
    invoke DefWindowProc, hWnd, uMsg, wParam, lParam
    ret
  .endif
  xor eax, eax
  ret
WndProc endp
end start
