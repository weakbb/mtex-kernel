;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        .386
        .model flat, stdcall
        option casemap :none   ; case sensitive
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
include     windows.inc
include     user32.inc
include     kernel32.inc
include     comctl32.inc
include     comdlg32.inc
include     masm32.inc
include     advapi32.inc

includelib  user32.lib
includelib  kernel32.lib
includelib  comctl32.lib
includelib  comdlg32.lib
includelib  masm32.lib
includelib  advapi32.lib

include    my.inc
;includelib my.lib
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ICO_MAIN    equ     1000
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        .data?
hInstance   dd  ?
dRetCode    dd  ?
pCmdLine    dd  ?
szRun	    db  256 dup (?)
hKey             dd  ?
lpcbData         dd  ?
lpType           dd  ?
szBuff           db  256 dup(?)
lpdwDisp    dd  ?


_ProcDlgMain    PROTO   :DWORD,:DWORD,:DWORD,:DWORD

        .data
;szDlgTitle  db  'ÃüÁîÐÐ²ÎÊý£º',0
szCmd	    db 'yap.exe ',20 dup (0)
szREGSZ          db  'REG_SZ',0
szTestKey        db  'Software\MiK\MiKTeX\CurrentVersion\Yap\Settings',0
szEditor         db  'Editor',0
szChkAssoc       db  'Check Associations',0
szTexEdt	 db  'TEX-EDT.exe %l "%f"',0
foundYap         dd  0
checkAssoc       dd  0

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        .code


shellx proc lpfilename:DWORD

    LOCAL xc :DWORD         ; exit code

    .data
      st_info STARTUPINFO <0>
      pr_info PROCESS_INFORMATION <0>
      sa_info SECURITY_ATTRIBUTES <0,NULL,TRUE>
    .code

    mov st_info.wShowWindow,SW_MAXIMIZE
    invoke GetStartupInfo,ADDR st_info
    invoke CreateProcess,NULL,lpfilename,ADDR sa_info,ADDR sa_info,
                         TRUE,CREATE_NEW_CONSOLE,NULL,NULL,
                         ADDR st_info,
                         ADDR pr_info

    invoke WaitForSingleObject,pr_info.hProcess,INFINITE
    cmp eax,WAIT_OBJECT_0
    jne @F
    invoke CloseHandle,pr_info.hProcess
    @@:
    invoke CloseHandle,pr_info.hThread
    ret

shellx endp



GetArgs proc s:DWORD
      mov ebx,s
      mov dl,32 ;' '
      cmp byte ptr [ebx],34 ;'"'
      jne Scan
      mov dl,34 ;'"'
      inc ebx
    Scan:
      mov al,[ebx]
      cmp al,0
      je Done2
      cmp al,dl
      je Done1
      inc ebx
      jmp Scan
    Done1:
      inc ebx
    Done2:
      return ebx
GetArgs endp

SepArgs proc s:DWORD
      mov ebx,s
      mov si, "::"
      mov di, " ^"
    Loop1:
      mov al,[ebx]
      cmp al,0
      je Done1
      cmp [ebx],si
      jne @F
      mov [ebx],di
      @@:
      inc ebx
      jmp Loop1
    Done1:
      ret
SepArgs endp

TrimStr proc s:DWORD
      mov ebx,s
    @@:
      mov al,[ebx]
      cmp al,0
      je @F
      cmp al,' '
      jne @F
      inc ebx
      jmp @B
    @@:
      return ebx
TrimStr endp




start:
    invoke GetModuleHandle, NULL ; provides the instance handle
    mov hInstance, eax

    invoke lstrcpy,ADDR szRun,ADDR szCmd
    invoke GetCommandLine        ; provides the command line address
    mov pCmdLine, eax
    ;invoke MessageBox,0,eax,ADDR szDlgTitle,MB_OK
    invoke GetArgs,pCmdLine
    invoke lstrcat,ADDR szRun,eax
    @@:




;    invoke MessageBox,0,ADDR szTexEdt,ADDR szDlgTitle,MB_OK

      INVOKE     RegOpenKeyEx, HKEY_CURRENT_USER, addr szTestKey, 0,\
                 KEY_WRITE or KEY_READ, addr hKey
      .if eax == ERROR_SUCCESS
         mov     foundYap,1
         mov     lpcbData, 254
      INVOKE     RegQueryValueEx, hKey, addr szEditor, 0, addr szREGSZ, addr szBuff, addr lpcbData
      .else
         mov     foundYap,0
      INVOKE     RegCreateKeyEx, HKEY_CURRENT_USER, addr szTestKey, 0, addr szREGSZ, 0,\
                 KEY_WRITE or KEY_READ, 0, addr hKey, addr lpdwDisp
      .endif

	 mov     lpcbData, 4
      INVOKE     RegSetValueEx, hKey, addr szChkAssoc, 0, REG_DWORD, addr checkAssoc, lpcbData

      INVOKE     lstrlen, addr szTexEdt
         mov     lpcbData, eax
      INVOKE     RegSetValueEx, hKey, addr szEditor, 0, REG_SZ, addr szTexEdt, lpcbData
  
    invoke shellx,ADDR szRun
    mov dRetCode,eax

	mov eax,foundYap
	.if eax == 1
      INVOKE     lstrlen, addr szBuff
         mov     lpcbData, eax
      INVOKE     RegSetValueEx, hKey, addr szEditor, 0, REG_SZ, addr szBuff, lpcbData
	.endif


    mov eax,dRetCode
    invoke ExitProcess,eax       ; cleanup & return to operating system
;********************************************************************
        end start

