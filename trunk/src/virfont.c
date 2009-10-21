#include <stdio.h>
#define MSIZE 2000
#define SIZE 20
int L;char s1[SIZE],s2[SIZE],n[SIZE];char *p,*q;
char* match(char *s,char *p) {
	char buf[SIZE],*q,*r,*x;
	q=strchr(p,'*');*q++=0;
	if(strbeg(s,p)==0) return NULL;
	r=s+strlen(p);strcpy(buf,r);x=strchr(buf,0)-strlen(q);
	if(strcmp(x,q)) return NULL;
	*x=0;return strdup(buf);
}

char *replace_star(char *s,char *p) {
	char buf[SIZE],*q;
	q=strchr(p,'*');strcpy(buf,q+1);strcpy(q,s);strcat(q,buf);return p;
}


int main(int argc, char *argv[])
{
	char buf[MSIZE];
	if(argc<2) {fputs("Usage: VIRFONT fontname<virfont.cfg\nPurpose: Fake specified font with another font.",stderr);exit(1);}
	strcpy(n,argv[1]);
    while(gets(buf)) 
		if(buf[0]>='A'||buf[0]=='*') {
			p=strchr(buf,'=');L=p-buf;strcpy(s2,p+1);*p=0;strcpy(s1,buf);//puts(s1);puts(s2);
			if(strcmp(s1,n)==0) {strcpy(n,s2);} else if(q=match(n,s1)) {strcpy(n,replace_star(q,s2));}
		}
	puts(n);
	return 0;
}
