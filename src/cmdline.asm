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
szRun	    db  256 dup (?)
szArgs	    db  256 dup (?)

_ProcDlgMain    PROTO   :DWORD,:DWORD,:DWORD,:DWORD

        .data
;szDlgTitle  db  'ÃüÁîÐÐ²ÎÊý£º',0
szOpt      db '/c ',0
szCmd	    db '4nt.exe ',20 dup (0)

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

start:
    invoke GetModuleHandle, NULL ; provides the instance handle
    mov hInstance, eax

    invoke lstrcpy,ADDR szRun,ADDR szCmd
    invoke GetCommandLine        ; provides the command line address
    mov pCmdLine, eax
    ;invoke MessageBox,0,eax,ADDR szDlgTitle,MB_OK
    invoke GetArgs,pCmdLine
    invoke TrimStr,eax
    invoke lstrcpy,ADDR szArgs,eax
    mov dl,szArgs
    cmp dl,0
    je @F
    invoke lstrcat,ADDR szRun,ADDR szOpt
    invoke SepArgs,ADDR szArgs
    invoke lstrcat,ADDR szRun,ADDR szArgs
    @@:
    
    ;invoke MessageBox,0,pCmdLine,ADDR szDlgTitle,MB_OK
    ;invoke MessageBox,0,ADDR szRun,ADDR szDlgTitle,MB_OK
    invoke shell,ADDR szRun

    invoke ExitProcess,eax       ; cleanup & return to operating system
;********************************************************************
        end start

