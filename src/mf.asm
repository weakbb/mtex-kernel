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

includelib  user32.lib
includelib  kernel32.lib
includelib  comctl32.lib
includelib  comdlg32.lib
includelib  masm32.lib

include    my.inc
;includelib my.lib
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ICO_MAIN    equ     1000
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        .data?
hInstance   dd  ?
pCmdLine    dd  ?
szRun	    db  1024 dup (?)

_ProcDlgMain    PROTO   :DWORD,:DWORD,:DWORD,:DWORD

        .data
;szDlgTitle  db  'ÃüÁîÐÐ²ÎÊý£º',0
szCmd	    db 'mf-nowin.exe ',1024 dup (0)

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        .code

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

SlashStr proc s:DWORD
      mov ebx,s
    @@:
      mov al,[ebx]
      cmp al,0
      je @F

      .IF al=='/'
      mov al,'\'
      mov [ebx],al
      .ENDIF

      inc ebx
      jmp @B
    @@:
      return ebx
SlashStr endp

shellx proc lpcmdline:DWORD

    LOCAL xc :DWORD         ; exit code
    LOCAL hRead:DWORD 
    LOCAL hWrite:DWORD
	LOCAL hStdOut:DWORD
	LOCAL buffer[1024]:byte
	LOCAL bytesRead:DWORD
	LOCAL bytesWrite:DWORD
	
    .data
      st_info STARTUPINFO <0>
      pr_info PROCESS_INFORMATION <0>
      sa_info SECURITY_ATTRIBUTES <0,NULL,TRUE>
    .code

	invoke GetStdHandle,STD_OUTPUT_HANDLE
	mov hWrite,eax
	invoke GetStdHandle,STD_INPUT_HANDLE
	mov hRead,eax
	
	;;invoke CreatePipe,addr hRead,addr hWrite,addr sa_info,NULL
    ; .if eax!=NULL 
		mov st_info.cb,sizeof STARTUPINFO 
		invoke GetStartupInfo,addr st_info 
		mov eax,hRead
		mov st_info.hStdInput,eax
		mov eax, hWrite 
		mov st_info.hStdOutput,eax 
		mov st_info.hStdError,eax 
		mov st_info.dwFlags, STARTF_USESHOWWINDOW+ STARTF_USESTDHANDLES 
		mov st_info.wShowWindow,SW_SHOW ;SW_HIDE
	; .endif
    invoke GetStartupInfo,ADDR st_info
    invoke CreateProcess,NULL,lpcmdline,ADDR sa_info,ADDR sa_info,
                         TRUE,NULL,NULL,NULL,   ;CREATE_NEW_CONSOLE
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




start:
    invoke GetModuleHandle, NULL ; provides the instance handle
    mov hInstance, eax

    invoke lstrcpy,ADDR szRun,ADDR szCmd
    invoke GetCommandLine        ; provides the command line address
    mov pCmdLine, eax
    ;invoke MessageBox,0,eax,ADDR szDlgTitle,MB_OK
    invoke GetArgs,pCmdLine
    mov pCmdLine, eax
    ;invoke SlashStr,pCmdLine
    invoke lstrcat,ADDR szRun,pCmdLine

    
    ;invoke MessageBox,0,pCmdLine,ADDR szDlgTitle,MB_OK
    ;invoke MessageBox,0,ADDR szRun,ADDR szDlgTitle,MB_OK
    invoke shellx,ADDR szRun

    invoke ExitProcess,0       ; cleanup & return to operating system
;********************************************************************
        end start

