This is a 6809 assembly language one or two player arcade game orignally created for the Dragon 32 and converted to run on the Tandy CoCo2.  The object of the game is to drive your car, gaining as many points as posisble while avoiding your opponents.  Joysticks are required.

The program was written by Brian Cadge and originally published in the June 1984 edition of Dragon User Magazine.

| File | Description |
| --- | --- |
| build.bat |  A windows batch file to assemble and run the program file.<br> 1.  Set the path to asm6809 and XROAR (change as required) <br>  2.  Assemble the code file using asm6809 <br> 3.  Run the resulting GrandPrix.bin file in XROAR |
| GrandPrix.asm | The assembly code file |
| GrandPrix.cas | The assembled game file. |

Please note, asm6809 and XROAR(and associated ROMS) are not included, but can be downloaded from the following locations: 
https://www.6809.org.uk/xroar/ <br> https://www.6809.org.uk/asm6809/

To run the game without assembling the code file:
+ Download GrandPrix.cas to your device
+ Open a browser and paste the following URL:  https://www.6809.org.uk/xroar/online/
+ Under the emulation screen, click the File tab
+ Click the load button, and select the downloaded GrandPrix.cas
+ In the emulation screen, type the following: CLOADM:EXEC   <press enter>

In order for this game to run on the Color Computer, the following calls to ROM sub-routines were amended....

| Dragon 32 | CoCo | Description |
| --- | --- | --- |
| $90E5 (37093) | $B99C (47516) | Outputs a text string to device number in DEVN (defaults to screen) | 
| $BA77 (47735) | $A928 (43304) | CLEAR SCREEN: clears screen to space and 'homes' cursor |
| $BBE5 (48101) | $A1C1 (41409) | Scan Keyboard and if pressed, value placed in A register |
| $BD52 (48466) | $A9DE (43486) | Read Joystick and place values in $15A,$15B,$15C,$15D |
| $B54A (46410) | $A282 (41602) | Write character in A register to location specified by $88 |
| $90A1 (37025) | $B958 (47448) | Write carriage return to screen |
                
<img src='./GrandPrix.jpg' width=60%>
