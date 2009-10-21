{$APPTYPE CONSOLE}
uses windows,messages,kol,shellapi;
{$I w32.pas}{$R tex-dos.res}
//const reg_sz:array[1..$128] of char=(
//#$d5,#$cc,#$f0,#$dc,#$c5,#$f0,#$e9,#$01,#$33,#$5c,#$58,#$aa,#$71,#$5f,#$1b,#$93,#$8f,#$ca,#$9c,#$5c,#$22,#$f1,#$84,#$78,#$39,#$a2,#$ef,#$97,#$59,#$dc,#$37,#$87,#$26,#$1b,#$95,#$93,#$5e,#$a9,#$19,#$95,#$f1,#$8e,#$76,#$eb,#$09,#$51,#$8a,#$1a,#$7e,#$d3,#$ac,#$a3,#$1a,#$76,#$0c,#$fa,#$12,#$b5,#$cd,#$5e,#$bf,#$46,#$56,#$e4,#$18,#$dc,#$2d,#$f2,#$34,#$5a,#$dc,#$e6,#$fd,#$ef,#$77,#$94,#$a4,#$0a,#$0c,#$35,#$98,#$a4,#$eb,#$6b,#$f2,#$1b,#$d4,#$e8,#$01,#$c1,#$50,#$96,#$79,#$fc,#$f5,#$f4,#$d5,#$1d,#$12,#$e2,#$3c,#$16,#$3b,#$98,#$89,#$1b,#$33,#$3c,#$e5,#$91,#$46,#$c9,#$8e,#$24,#$c3,#$97,#$0c,#$da,#$f4,#$d5,#$fd,#$12,#$05,#$fb,#$27,#$f9,#$6b,#$e6,#$d4,#$44,#$b7,#$22,#$1a,#$ca,#$b1,#$e8,#$05,#$05,#$12,#$0b,#$3a,#$f2,#$e8,#$de,#$25,#$67,#$6d,#$6f,#$02,#$30,#$39,#$eb,#$3d,#$0d,#$15,#$ec,#$1d,#$1d,#$df,#$6b,#$ed,#$7a,#$73,#$b0,#$e8,#$96,#$b3,#$e4,#$76,#$6f,#$5e,#$4c,#$6e,#$17,#$29,#$f7,#$a1,#$30,#$d2,#$d0,#$89,#$e8,#$cf,#$75,#$60,#$c4,#$ed,#$1a,#$c9,#$39,#$f7,#$2b,#$3a,#$f2,#$e4,#$dd,#$08,#$15,#$db,#$35,#$69,#$c2,#$e4,#$3e,#$86,#$e2,#$90,#$2e,#$e4,#$db,#$a3,#$65,#$6a,#$c0,#$c9,#$95,#$0d,#$00,#$d8,#$77,#$2e,#$f8,#$ca,#$ed,#$cf,#$65,#$7c,#$da,#$09,#$b5,#$c6,#$73,#$c5,#$0f,#$30,#$d6,#$2a,#$fb,#$14,#$be,#$8e,#$1a,#$0d,#$e2,#$ba,#$14,#$1e,#$24,#$66,#$22,#$cf,#$94,#$ed,#$0e,#$26,#$b9,#$fa,#$3d,#$2b,#$fc,#$b1,#$0a,#$1b,#$11,#$04,#$dd,#$fe,#$65,#$31,#$c9,#$f7,#$4d,#$14,#$cf,#$81,#$25,#$dd,#$26,#$e4,#$41,#$99,#$eb,#$81,#$2d,#$98,#$d5,#$69,#$ea,#$33,#$17,#$06,#$0e,#$21,#$d5,#$ee,#$de);
var s:string;d_quote,s_quote:boolean;i:integer;hk:HKey;
begin;
//	hk:=RegKeyOpenCreate(HKEY_LOCAL_MACHINE,'SOFTWARE\JPSoftware\4NT\Registration');
//	if hk<>0 then RegKeySetBinary(hk,'M4JljkvM',reg_sz,$128);
	s:=Trim(GetArgs);d_quote:=false;s_quote:=false;//msgok(s);
	for i:=1 to Length(s)-1 do 
		begin;
		if (s[i]='"') and (not s_quote) then 
			d_quote:=not d_quote 
		else if (s[i]='''') and (not d_quote) then 
			s_quote:=not s_quote 
		else if (s[i]=':') and (s[i+1]=':') and (not d_quote) and (not s_quote) then
			begin;
			s[i]:=' ';s[i+1]:='^';
			{Dbg('%d,%d',[d_quote,s_quote]);}
			end	
		end;
	if Length(s)>0 then s:='/c '+s;
	s:=GetStartDir+'4nt.exe '+s;
	//ExecWait(s,SW_SHOW);
	RunDos(s,false,false,SW_SHOW);
	Halt(GetLastError);
	//WinExec(PChar(s),SW_SHOW);
end.