#include <stdio.h>
#include <io.h>
#include <string.h>
#include <fcntl.h>
#define SIZE 10000

int fh,file_size;char buf[SIZE];int cmd_no;
//char cmd_list[5][10]={"tex","latex","context","pdftex","pdflatex"};
char *usage="Usage:TEX_CMD tex_file ==) Auto check what command should be used to compile tex_file.";
char *cmds[]={"?","tex","latex","pdftex","pdflatex","luatex","lualatex","xetex","xelatex","omega","lambda","uptex","uplatex","ntstex","ntslatex","latex209","context"};
enum {_UNKNOWN=0,_TEX,_LATEX,_PDFTEX,_PDFLATEX,_LUATEX,_LUALATEX,_XETEX,_XELATEX,_OMEGA,_LAMBDA,_UPTEX,_UPLATEX,_NTSTEX,_NTSLATEX,_LATEX209,_CONTEXT,_END};

char *Lstrstr(char *s,char *b) {
	char tmp[SIZE];int n,i;
	n=strlen(b);
	for(i=0;i<n;i++) {tmp[i*2]=b[i];tmp[i*2+1]='\0';}
	for(i=0;i<file_size;i++) {
		if (memcmp(s+i,tmp,n*2)==0) return s+i;
	}
	return NULL;
}

int test_cmd(char *s)  {
	char *p;int latex=0,i=0;
	p=strstr(s,"%&");
	if(p==s) {
	  	p=p+2;
		for (i=1;i<_END;i++) {if (strstr(p,cmds[i])==p) return i;}
	}
    p=strstr(s,"\\documentstyle");if(p) return _LATEX209;
    p=strstr(s,"\\documentclass");if(p) {latex=1;};
    p=Lstrstr(s,"\\documentclass");if(p) {latex=1;};
    p=strstr(s,"{fontspec}");if(p && latex) return _XELATEX;
    p=strstr(s,"{xunicode}");if(p && latex) return _XELATEX;
    p=strstr(s,"{xltxtra}");if(p && latex) return _XELATEX;
    p=strstr(s,"{zhspacing}");if(p && latex) return _XELATEX;
    p=strstr(s,"{xeCJK}");if(p && latex) return _XELATEX;
    p=strstr(s,"{xCJK}");if(p && latex) return _XELATEX;
    p=strstr(s,"{xCCT}");if(p && latex) return _XELATEX;
    p=strstr(s,"{omega}");if(p && latex) return _LAMBDA; 		
    p=strstr(s,"\\ocp");if(p) return _OMEGA+latex;
    p=Lstrstr(s,"\\ocp");if(p) return _OMEGA+latex;
    p=strstr(s,"{gastex}");if(p && latex) return _LATEX;
    p=strstr(s,"{prosper}");if(p && latex) return _LATEX;
    p=strstr(s,"{prosper}");if(p && latex) return _LATEX;
		
		
    p=strstr(s,"{attachfile}");if(p && latex) return _PDFLATEX;
    p=strstr(s,"{mdwslides}");if(p && latex) return _PDFLATEX;
    p=strstr(s,"{pdfslide}");if(p && latex) return _PDFLATEX;
    p=strstr(s,"{pdfwin}");if(p && latex) return _PDFLATEX;
    p=strstr(s,"{pdfscreen}");if(p && latex) return _PDFLATEX;
    p=strstr(s,"{pdftricks}");if(p && latex) return _PDFLATEX;
    p=strstr(s,"{ttfucs}");if(p && latex) return _PDFLATEX;    
    p=strstr(s,"\\usepackage{pdf");if(p && latex) return _PDFLATEX;
    p=strstr(s,"[pdftex");if(p && latex) return _PDFLATEX; 		
    p=strstr(s,"\\pdfliteral");if(p) return _PDFTEX+latex;
	p=strstr(s,"\\directlua");if(p) return _LUATEX+latex;
    p=strstr(s,"\\latelua");if(p) return _LUATEX+latex;
    p=strstr(s,"\\lua");if(p) return _LUATEX+latex;
    p=strstr(s,"\\starttext");if(p) return _CONTEXT;
    p=strstr(s,"\\usemodule");if(p) return _CONTEXT;
    p=strstr(s,"\\setup");if(p && !latex) return _CONTEXT;
    p=strstr(s,"\\define");if(p && !latex) return _CONTEXT;
    p=strstr(s,"\\place");if(p && !latex) return _CONTEXT;
    p=strstr(s,"\\XeTeX");if(p) return _XETEX+latex;
    p=strstr(s,"\\pdf");if(p) return _PDFTEX+latex;
//    p=strstr(s,"\\XeTeX");if(p) return _XETEX+latex;
//    p=strstr(s,"\\XeTeX");if(p) return _XETEX+latex;
    p=strstr(s,"upsch");if(p) return _UPTEX+latex;
    p=strstr(s,"uptch");if(p) return _UPTEX+latex;
    p=strstr(s,"upjpn");if(p) return _UPTEX+latex;
    p=strstr(s,"upkor");if(p) return _UPTEX+latex;
    p=strstr(s,"\\documentclass{ujarticle}");if(p) return _UPLATEX;
    p=strstr(s,"\\documentclass{ujbook}");if(p) return _UPLATEX;
    p=strstr(s,"\\documentclass{ujreport}");if(p) return _UPLATEX;
    p=strstr(s,"\\documentclass{utarticle}");if(p) return _UPLATEX;
    p=strstr(s,"\\documentclass{utbook}");if(p) return _UPLATEX;
    p=strstr(s,"\\documentclass{utreport}");if(p) return _UPLATEX;
    return _TEX+latex;
}

int main(int argc, char *argv[])
{
    if(argc<2) {puts(usage);return 0;}
    if(fh=open(argv[1],_O_RDONLY)) {
		file_size=read(fh,buf,SIZE);
		cmd_no=test_cmd(buf);
		close(fh);
	}
	puts(cmds[cmd_no]);
    //~ switch(cmd_no) {
    //~ case 1: puts("tex");break;
    //~ case 2: puts("latex");break;
    //~ case 3: puts("context");break;
    //~ }
    exit(cmd_no);
}
