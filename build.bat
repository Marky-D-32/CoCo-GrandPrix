SET XROARPATH=C:\Users\Marky\Documents\Emulators\Dragon32\apps\xroar-1.6.3-w64
SET ASMPATH=C:\Users\Marky\Documents\Emulators\Dragon32\apps\asm6809-2.12-w64

SET path=%XROARPATH%;%ASMPATH%

asm6809.exe --exec 28732 --coco GrandPrix.asm -o GrandPrix.bin -l GrandPrix.lst

xroar.exe -default-machine coco -rompath %XROARPATH% -run GrandPrix.bin