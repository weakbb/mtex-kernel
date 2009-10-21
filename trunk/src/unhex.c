#include <stdio.h>
#define MSIZE 2000
int hval(char c)
{
	if(c>='0' && c<='9') return c-'0';
	if(c>='a' && c<='f') return c-'a'+10;
	if(c>='A' && c<='F') return c-'A'+10;
	return -1;
}
int tex_hex(char *p)
{
	int c1,c2;
	return (p[0]=='^' && p[1]=='^' && (c1=hval(p[2]))>=0 && (c2=hval(p[3]))>=0) ? c1*16+c2 : -1;
}

void unhex(char *s,char *r)
{
	int i,v;
	while(*s) {
		v=tex_hex(s);
		if(v<0) {*r++=*s++;} else {*r++=v;s+=4;}
	}
	*r=0;
}

int main(int argc, char *argv[])
{
	char buf[MSIZE],res[MSIZE];//puts(tabs[0]);puts(tabs[2]);
    while(gets(buf)) {unhex(buf,res);puts(res);puts("\n");}
	return 0;
}
