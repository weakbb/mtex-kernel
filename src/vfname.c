#include <stdio.h>
#include <io.h>
#include <fcntl.h>
#include <ctype.h>
#define SIZE 200

int fh;char buf[SIZE];

void vf_show(char *s) 
{	int i,flag;
	for(i=flag=0;i<SIZE-2 && flag<2;i++) {
		if(flag==0 && s[i]>=4 && s[i]<9 && isalpha(s[i+1]) && isalpha(s[i+2])) flag=1;
		else if(flag==1 && isalnum(s[i])) putchar(s[i]);
		else if(flag==1 && s[i]<4) flag=2;
	}
}

int main(int argc, char *argv[])
{
	if(argc<2) {puts("Usage:VFNAME vf_file ==) Show the real name of virtual font");return 0;}
	if(fh=open(argv[1],_O_RDONLY)) {_read(fh,buf,SIZE);vf_show(buf);close(fh);}
	return 0;
}
