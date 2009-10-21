{$APPTYPE console}
program test;
uses windows,messages,kol,shellapi; {$I w32.pas}
var Bmp:PBitmap;d,x1,x2,y1,y2:integer;

var x,y:integer;c:TColor;


procedure CropBmp;
begin;
end;

const usage='本工具用于辅助裁减图片中多余的空白，可配合IrfanView、XnView等软件自动完成图片的裁减。'+CR
+'虽然这些软件都有图片裁减功能，但需要您自己指定裁减后的区域；而另一些软件则需要用鼠标手动裁减，很不方便对图片进行批处理。'
+'因此，[mhb]开发该工具，4DOS批处理程序 cropbmp.btm 是一个应用例子。'+CR
+'命令格式：bmpcrop f.bmp [d]'+CR
+'==)检测文件f.bmp中的边缘空白区域，并将结果以格式"Crop=x,y,w,h"存入文件bmpcrop.sav中。';
procedure Help;
begin;
  writeln(usage);halt(1);
end;

begin;
if ParamCount=0 then Help;
Bmp:=NewBitmap(0,0);
Bmp.LoadFromFile(ParamStr(1));

{CropBmp;}
with bmp^ do
  begin
  x1:=Width;x2:=0;y1:=Height;y2:=0;c:=DIBPixels[x1-1,y1-1];
  for x:=0 to Width-1 do
    begin;
    for y:=0 to y1-1 do
      if not (DIBPixels[x,y]=c) then begin;y1:=y;break;end;
    for y:=Height-1  downto y2+1 do
      if not (DIBPixels[x,y]=c) then begin;y2:=y;break;end;
    end;
  for y:=0 to Height-1 do
    begin;
    for x:=0 to x1-1 do
      if not (DIBPixels[x,y]=c) then begin;x1:=x;break;end;
    for x:=Width-1  downto x2+1 do
      if not (DIBPixels[x,y]=c) then begin;x2:=x;break;end;
    end;
  end;


d:=Str2Int(ParamStr(2));
x1:=x1-d;x2:=x2+d;y1:=y1-d;y2:=y2+d;
if x1<0 then x1:=0;
if y1<0 then y1:=0;
if x2>=bmp.Width then x2:=bmp.Width-1;
if y2>=bmp.Height then y2:=bmp.Height-1;

StrSaveToFile('bmpcrop.sav',Format('Width=%d'+CR+'Height=%d'+CR+'Bits=%d'+CR+'Crop=%d,%d,%d,%d',
[bmp.Width,bmp.Height,bmp.BitsPerPixel,x1,y1,x2-x1+1,y2-y1+1]));
end.
