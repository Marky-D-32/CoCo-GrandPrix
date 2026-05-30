

                ORG $6D60

                ;*********************
                ;Setup game parameters
                ;*********************
ResetGame       LDA   #$03                  ;Number of lives allowed per game
                STA   NumLives
                CLR   ScreenScr             ;Clear game screen score
                CLR   ScreenScr+1
                CLR   ScreenScr+2
                CLR   ScreenScr+3
                CLR   ScreenScr+4
                LDA   #$FA                  ;Speed of car
                STA   CarSpeed
                CLR   $0113                 ;Reset system timer
                LDX   #$2328                ;The amount of time game should go on for
                STX   $008D                 ;Countdown facility - duration of game
ResetGame_1     LDX   #$090F                ;Screen Position of 1st competitor car
                STX   CompCar1Pos
                LDA   #$08                  ;Position of car being driven (row based)   ;6D82
                STA   CarPosition
                CLR   CrashMarker           ;Clear Crash marker
                LDX   #$0E0A                ;Screen position of 2nd competitor car
                STX   CompCar2Pos
                LDX   #$140B                ;Screen position of 3rd competitor car
                STX   CompCar3Pos
                LDX   #$1A0E                ;Screen position of 4th competitor car
                STX   CompCar4Pos

                ;Set to semi graphics 24
                LDA   #$E5
                STA   $FF22
                STA   $FFC0
                STA   $FFC3
                STA   $FFC5
                STA   $FFC8
                STA   $FFCB

                ;************************************
                ;Create background - RED + blue track
                ;************************************
                LDA   #$FF                  ;Red
                LDX   #$0800                ;Start top left hand corner
ClearScrn_1     STA   ,X+                   ;write red value
                CMPX  #$2000                ;Bottom of screen?
                BCS   ClearScrn_1           ;No

                LDX   #$0800                ;Start top left hand corner
                LDA   #$AA                  ;Blue
ClearScrn_2     LDB   #$0A                  ;Offset for blue track
ClearScrn_3     STA   B,X                   ;write blue value
                INCB                        ;increase offset
                CMPB  #$16                  ;written $16 characters
                BCS   ClearScrn_3           ;no
                LEAX  32,X                  ;move down 1 row
                CMPX  #$2000                ;Bottom of screen?
                BCS   ClearScrn_2           ;no

                ;**************
                ;Main Game Loop
                ;**************
MainLoop        JSR   UpdateScore           ;Increase score + write to screen
                JSR   EngineSnd             ;Play engine sound

                LDA   $0113                 ;Only allow car to move every two system timer cycles??
                CMPA  #$02
                BCS   ML_2

                JSR   ReadJoysticks         ;Read joysticks - move car \adjust speed accordingly
                TST   CrashMarker           ;Has car crashed into another car?
                LBNE  CarCrash              ;Yes
ML_2            BSR   Delay                 ;Slow down based on speed of car     ;$6DEF

                ;Move competitor cars
                LDY   #CompCar1Pos
                LDB   #$04                  ;There are 4 of them to move
ML_4            LDX   ,Y                    ;Get position of car
                JSR   DrawCar               ;Draw it
                LEAX  32,X                  ;Move position down one row
                CMPX  #$2020                ;Has car reached bottom of screen?
                BCS   ML_3                  ;No
                LDX   #$05C0                ;Yes - reset position of car to stop of screen
                JSR   SetCarPos             ;Random Number to A register?
                LEAX  A,X                   ;Adjust new position of car
ML_3            STX   ,Y                    ;Store new position of car
                LEAY  2,Y                   ;Get next car position
                DECB                        ;move next car
                BNE   ML_4
                LDX   $008D                 ;Get game timer value
                BNE   MainLoop              ;not zero - continue game
                LBRA  GameEnd               ;End game

                ;***************************
                ;Delay based on speed of car
                ;***************************
Delay           LDA   CarSpeed              ;Get speed of car
                INCA
                LDB   #$0A
                MUL                         ;Generate delay amount
                TFR   D,X
Delay_1         LEAX  -1,X                  ;Decease delay counter
                BNE   Delay_1
                RTS

                ***************
                ;Read Joysticks
                ;**************
ReadJoysticks   PSHS  A,B,X,Y               ;6E29
                CLR   $0113
                JSR   $A9DE                 ;Read Joystick and update
                TST   CurrentPlayer         ;Which player is playing?
                BEQ   JS_1                  ;Player 1
                LDA   $015C                 ;Player 2 - transfer left joystck values to right joystick
                STA   $015A
                LDA   $015D
                STA   $015B
JS_1            LDA   $015A                 ;Right Joystick X value
                CMPA  #$0A                  ;Going Left?
                BHI   JS_2                  ;No - Check if going right
                TST   CarPosition           ;Check point of car
                BEQ   JS_2                  ;Car position is far left?
                DEC   CarPosition           ;No - move car left
                BRA   JS_3
JS_2            CMPA  #$35                  ;Going Right ?
                BCS   JS_3                  ;No
                LDA   CarPosition           ;Get position of car
                CMPA  #$09                  ;Car position is far right?
                BEQ   JS_3                  ;Yes
                INC   CarPosition           ;No - move car right
JS_3            LDX   #$198A                ;Far left position of driving car
                LDA   CarPosition           ;Get row position of driving car
                LEAX  A,X                   ;Adjust

                ;Erase left side of car graphic?
                TSTA
                BEQ   JS_4                  ;Car is on far left hand side - do no erase

                LDA   #$AA                  ;Blue graphic
                LDB   #$0E                  ;Height if car
                PSHS  X
JS_5            STA   -1,X                  ;Draw the blue graphic
                LEAX  32,X                  ;go down to next row
                DECB                        ;decrease count
                BNE   JS_5                  ;not finished
                PULS  X

                ;Erase right side of car graphic?
JS_4            LDA   CarPosition           ;Get position of car
                CMPA  #$09                  ;Far right hand side?
                BEQ   JS_6                  ;Yes - do not erase

                LDA   #$AA                  ;Blue graphic
                LDB   #$0E                  ;Height of car
                PSHS  X
JS_7            STA   3,X                   ;Draw the blue graphic
                LEAX  32,X                  ;go down to next row
                DECB                        ;decrease count
                BNE   JS_7                  ;not finished
                PULS  X

JS_6            BSR   CheckCrash            ;Check if car has crash into competitor
                JSR   DrawCar
                LDA   $015B                 ;Right Joystick Y Value
                CMPA  #$0A                  ;Is UP position?
                BHI   JS_8                  ;No - check down
                TST   CarSpeed              ;Is car going at fastest speed?
                BEQ   JS_8                  ;Yes - next check
                DEC   CarSpeed              ;Increase speed of car (decrease delay)
JS_8            CMPA  #$35                  ;Is is DOWN psotion ;6EA7
                BCS   JS_Exit               ;No - Exit Joystick check
                LDA   CarSpeed              ;Get speed of car
                CMPA  #$FF                  ;Is car going as slow as possible?
                BEQ   JS_Exit               ;Yes
                INC   CarSpeed              ;No decraese speed of car (increase delay)
JS_Exit         PULS  A,B,X,Y,PC            ;Return to main loop

                ;**************************
                ;Draw Car Graphic on Screen
                ;**************************
DrawCar         PSHS  A,B,X,Y
                LDB   #$0F                  ;Height of car graphic
                LDY   #CarGraphic           ;Get location of car graphic
DCLoop1         LDA   ,Y+                   ;Get car graphic - 1st col
                STA   ,X                    ;Draw it
                LDA   ,Y+                   ;get car graphic - 2nd column
                STA   1,X                   ;draw it
                LDA   ,Y+                   ;get car graphic - 3rd column
                STA   2,X                   ;draw it
                LEAX  32,X                  ;move down screen
                DECB                        ;decrease height count
                BNE   DCLoop1               ;repeat for next row
                PULS  A,B,X,Y,PC

                ;***************
                ;Check for Crash
                ;***************
CheckCrash      LDA   ,X                    ;Get graphic byte top left hand corner
                CMPA  #$AA                  ;Is it Blue (track colour)
                BEQ   CC1                   ;Yes - move to next check
                STA   CrashMarker           ;Store graphic in CrashMarker
                RTS                         ;Return

CC1             LDA   2,X                   ;Get graphic byte top right hand corner
                CMPA  #$AA                  ;Is it Blue (track colour)
                BEQ   CC2                   ;Yes - move to next check
                STA   CrashMarker           ;Store graphic in CrashMarker
                RTS                         ;return

CC2             LDA   $01E0,X               ;Get graphic byte bottom left hand corner
                CMPA  #$AA                  ;Is it Blue (track colour)
                BEQ   CC3                   ;Yes - move to next check
                STA   CrashMarker           ;Store graphic in CrashMarker
                RTS

CC3             LDA   $01E2,X               ;Get graphic byte bottom right hand coner
                CMPA  #$AA                  ;It is Blue (track colour)?
                BEQ   CC4                   ;Yes Exit
                STA   CrashMarker           ;Store graphic in CrashMarker
                RTS
CC4             RTS

                ;****************************
                ;Car has crashed - play sound
                ;****************************
CarCrash        PSHS  A,X
                LDA   #$3F
                STA   $FF23
                CLR   $00B2
                LDX   #$B798
CC_2            LDA   ,X+
                BSR   CC_1
                LDA   ,X+
                BSR   CC_1
                DEC   $00B2
                BNE   CC_2
                LDA   #$37
                STA   $FF23
                PULS  A,X

                ;Game end check
                DEC   NumLives              ;Decrease number of lives left
                LBEQ  GameEnd               ;If 0, end the game
                LDA   #$FA                  ;reset speed of car
                STA   CarSpeed              ;save
                CLR   $0113                 ;reset system timer
                LBRA  ResetGame_1

                ;Sound routine helper
CC_1            ANDA  $00B2
                STA   $FF20
                LDA   #$C8
CC_3            DECA
                BNE   CC_3
                RTS

                ;*************************************
                ;Psuedo random number generator
                ;Input Reg A: base position of car
                ;Output Reg A: new row position of car
                ;*************************************
SetCarPos       PSHS  B,X,Y
                LDX   $0145                 ;USR Address table
                LEAX  3,X                   ;Add 3
                STX   $0145                 ;Store
                TFR   X,D
                MUL                         ;create new number
                MUL                         ;create new number
SCP_1           CMPA  #$09
                BLS   SCP_2
                SUBA  #$09
                BRA   SCP_1
SCP_2           ADDA  #$0A
                PULS  B,X,Y,PC

                ;**********************************
                ;Increase Score and write to screen
                ;**********************************
UpdateScore     PSHS  A,B,X,Y               ;Save register values
                LDX   #ScreenScr+4          ;Point to last digit of score
US_2            LDA   ,X                    ;Get it
                INCA                        ;increase score by 1
                STA   ,X                    ;store It
                CMPA  #$0A                  ;have we reached 10?
                BCS   US_1                  ;No
                CLRA                        ;Yes - set value to 0
                BSR   WriteScore            ;write it to screen
                CLR   ,X                    ;clear digit
                LEAX  -1,X                  ;move to next digit
                BRA   US_2                  ;repeat check
US_1            LDA   ,X                    ;Get value of current digit
                BSR   WriteScore            ;write it to the screen
                CMPX  #ScreenScr            ;Have we written all digit?
                BEQ   US_Exit               ;Yes
                LEAX  -1,X                  ;No - move to next digit
                BRA   US_1                  ;write to screen
US_Exit         PULS  A,B,X,Y,PC

                ;*********************
                ;Write score to screen
                ;*********************
WriteScore      PSHS  A,B,X,Y
                LDB   #$0C                  ;Number of bytes that make each number ?
                MUL                         ;multiple by number to be drawn
                ADDD  #NumberGraphics       ;point to number graphic to be drawn
                PSHS  A,B
                LEAY  $8E88,X               ;88 is screen offset position
                TFR   Y,D
                LDA   #$02                  ;each digit is two bytes wide
                MUL
                LDY   #$0940                ;Base position
                LEAY  B,Y                   ;offset for digit being drawn
                PULS  A,B                   ;get graphic data location
                TFR   D,X
                LDB   #$06                  ;Height of characters
WriteScore_1    LDA   ,X+                   ;Get first byte
                STA   ,Y                    ;draw on screen
                LDA   ,X+                   ;get seconf byte
                STA   1,Y                   ;draw on screen
                LEAY  32,Y                  ;move down 1 row
                DECB                        ;decrease count
                BNE   WriteScore_1          ;repeat
                PULS  A,B,X,Y,PC

                ;*****************
                ;Welcome Text data
                ;*****************
WelcomeText     FCB /      WELCOME TO GRANDPRIX/
                FCB $0D,$0D,$0D,$0D                     ;Carriage returns
NumPlayersTXT   FCB /  NUMBER OF PLAYERS (1 OR 2) ?/
                FCB $00

PlayerText      FCB /            PLAYER /
                FCB $00

PlayerGameOver  FCB /        GAMEOVER PLAYER /
                FCB $00

AnotherGameTxt  FCB /     ANOTHER GAME (Y/N) ??/

ScoreTxt        FCB $2F,$4E,$29,$20,$3F,$3F,$00
                FCB /SCORES:/
                FCB $0D,$00

                ;************************************
                ;START - Display Initial Welcome Page
                *************************************
Welcome         JSR   $A928                 ;Clear Screen and Home curnor
                LDX   #$0480                ;Position to write text
                STX   <$88                  ;set for $B99C
                LDX   #Player1Scr           ;Clear player scores
Welcome1        CLR   ,X+
                CMPX  #NumberGraphics
                BCS   Welcome1
                LDX   #WelcomeText-1        ;Point to wlecome text
                JSR   $B99C                 ;Write Text to Screen
                CLR   CurrentPlayer         ;Reset current player number
Welcome2        JSR   $A1C1                 ;Scan Keyboard
                CMPA  #$31                  ;1 player selected
                BEQ   Welcome4
                CMPA  #$32                  ;2 players selected
                BNE   Welcome2
                LDA   #$01                  ;2 players selected - set to 1
                STA   NumPlayers            ;store
                BRA   Welcome3
Welcome4        CLR   NumPlayers            ;1 player selected - set to 0

Welcome3        JSR   $A928                 ;Clear Screen and Home Cursor
                LDX   #$0500
                STX   <$88
                LDX   #PlayerText-1         ;Point to text
                JSR   $B99C                 ;Write text to screen
                LDA   CurrentPlayer         ;Get current player "number"
                ADDA  #$31                  ;Convert to ASCII value
                JSR   $A282                 ;Write current player number to screen
                BSR   Wait
                JMP   ResetGame

                ;******************************
                ;End of game for current player
                ;******************************
GameEnd         JSR   $A928                 ;Clear Screen and Home Cursor
                LDX   #$0500                ;Position to write text
                STX   <$88                  ;set for $B99C
                LDX   #PlayerGameOver-1     ;TODO  Added -1 to match Original $6FFE "GAME OVER PLAYER "
                JSR   $B99C                 ;Write text to screen
                LDA   CurrentPlayer         ;Get current player "number"
                ADDA  #$31                  ;Convert to ASCII value
                JSR   $A282                 ;Write current player number to screen
                LDX   #$0400
                STX   <$88
                LDX   #ScreenScr            ;Get score
                BSR   DisplayPlyScr         ;display it
                BSR   PlayerScore           ;write it to either player1 or player2 score
                BSR   Wait
                LDA   NumPlayers            ;Get Number of players that were selected to play
                CMPA  CurrentPlayer         ;Compare with current player number
                BEQ   GameEnd2              ;Same - so finish
                INC   CurrentPlayer         ;Increase current player number
                BRA   Welcome3              ;Second player to play

                ;*********************
                ;Both players finsihed
                ;*********************
GameEnd2        JSR   $A928                 ;Clear Screen and home cursor 70B8
                LDX   #$0440                ;Position to write text
                STX   <$88                  ;set for B99C
                LDX   #ScoreTxt+6           ;"Scores:"  TODO ScoreText+6 ??
                JSR   $B99C                 ;Write text to screen
                LDX   #Player1Scr           ;Point to player 1 score
                BSR   DisplayPlyScr         ;Display to screen
                JSR   $B958                 ;Carriage Return
                LDX   #Player2Scr           ;Get Player 2 score
                BSR   DisplayPlyScr         ;Display to screen
                JSR   $B958                 ;Carriage Return
                JSR   $B958                 ;Carriage Return
                LDX   #AnotherGameTxt-1     ;TODO  Added -1 to match Orignal  $7017
                JSR   $B99C                 ;Write text to screen
GameEnd3        JSR   $A1C1                 ;Scan Keyboard
                CMPA  #$59                  ;"Y"
                LBEQ  Welcome
                CMPA  #$4E                  ;"N"
                BNE   GameEnd3
                RTS

                ;************************
                ;Wait for a second or two
                ;************************
Wait            PSHS  A,X
                LDA   #$03                  ;Loop 3 times
Wait1           LDX   #$FFFF
Wait2           LEAX  -1,X                  ;count down
                BNE   Wait2                 ;repeat count down
                DECA
                BNE   Wait1
                PULS  A,X,PC

                ;*************************************
                ;Display player score to text screen
                ;Input Reg X - location on score data
                ;*************************************
DisplayPlyScr   PSHS  A,B,X,Y
                LDB   #$05                  ;Number of digits
DPS1            LDA   ,X+                   ;Get 1st number
                ADDA  #$30                  ;convert to ascii equivalent
                JSR   $A282                 ;Output character in A reg
                DECB                        ;decrease count
                BNE   DPS1                  ;loop if required
                PULS  A,B,X,Y,PC

                ;**************************************************
                ;Copy current "in game" score to appropriate player
                ;**************************************************
PlayerScore     PSHS  A,B,X,Y
                LDY   #ScreenScr            ;Point to current player score
                LDA   CurrentPlayer         ;Get current player "in play"
                BNE   PS1                   ;If 0 then player 1
                LDX   #Player1Scr           ;Point to player 1 score
                BRA   PS2
PS1             LDX   #Player2Scr           ;Point to player 2 score
PS2             LDB   #$05                  ;number of digits in score
PS3             LDA   ,Y+                   ;get current player score digit
                STA   ,X+                   ;copy to player 1 or 2
                DECB                        ;move to next digit
                BNE   PS3                   ;not fisnihed
                PULS  A,B,X,Y,PC

                ;*****************
                ;Play Engine Sound
                ;*****************
EngineSnd       PSHS  A,B,X,Y
                LDA   #$3F
                STA   $FF23
                LDA   #$80
                STA   $FF20
                BSR   ESnd1
                CLR   $FF20
                BSR   ESnd1
                LDA   #$37
                STA   $FF23
                PULS  A,B,X,Y,PC

ESnd1           LDB   #$64
ESnd2           DECB
                BNE   ESnd2
                RTS

                ;*********
                ;Game Data
                **********
CarGraphic      FCB $AA,$AA,$AA
                FCB $AA,$55,$AA
                FCB $AA,$55,$AA
                FCB $A6,$55,$9A
                FCB $A5,$55,$5A
                FCB $A6,$41,$9A
                FCB $AA,$41,$AA
                FCB $AA,$41,$AA
                FCB $96,$41,$96
                FCB $96,$55,$96
                FCB $95,$55,$56
                FCB $96,$55,$96
                FCB $96,$55,$96
                FCB $AA,$55,$AA
                FCB $AA,$AA,$AA

                ;Onscreen score
ScreenScr       FCB $00,$02,$08,$00,$00

                ;Player 1 score
Player1Scr      FCB $00,$02,$08,$00,$00

                ;Player 2 score
Player2Scr      FCB $00,$00,$00,$00,$00

                ;Number data to display on semi24 screen
NumberGraphics  FCB $F5,$5F             ;0
                FCB $DF,$D7
                FCB $DF,$77
                FCB $DD,$F7
                FCB $D7,$F7
                FCB $F5,$5F

                FCB $F5,$FF             ;1
                FCB $DD,$FF
                FCB $FD,$FF
                FCB $FD,$FF
                FCB $FD,$FF
                FCB $D5,$5F

                FCB $F5,$5F             ;2
                FCB $DF,$F7
                FCB $FF,$F7
                FCB $F5,$5F
                FCB $DF,$FF
                FCB $D5,$57

                FCB $F5,$5F             ;3
                FCB $DF,$F7
                FCB $FF,$5F
                FCB $FF,$F7
                FCB $DF,$F7
                FCB $F5,$5F

                FCB $FF,$7F             ;4
                FCB $FD,$7F
                FCB $F7,$7F
                FCB $DF,$7F
                FCB $D5,$57
                FCB $FF,$7F

                FCB $D5,$57             ;5
                FCB $DF,$FF
                FCB $D5,$5F
                FCB $FF,$F7
                FCB $DF,$F7
                FCB $F5,$5F

                FCB $F5,$5F             ;6
                FCB $DF,$FF
                FCB $D5,$5F
                FCB $DF,$F7
                FCB $DF,$F7
                FCB $F5,$5F

                FCB $D5,$57             ;7
                FCB $FF,$F7
                FCB $FF,$DF
                FCB $FF,$7F
                FCB $FD,$FF
                FCB $FD,$FF
                FCB $F5,$5F

                FCB $DF,$F7             ;8
                FCB $F5,$5F
                FCB $DF,$F7
                FCB $DF,$F7
                FCB $F5,$5F
                FCB $F5,$5F

                FCB $DF,$F7             ;9
                FCB $DF,$F7
                FCB $F5,$57
                FCB $FF,$F7
                FCB $F5,$5F
                FCB $FF,$00,$00
				
;Game Variables
CarPosition     FCB 0
CarSpeed        FCB 0
NumPlayers      FCB 0
CurrentPlayer   FCB 0
CrashMarker     FCB 0
NumLives        FCB 0
CompCar1Pos     FDB 0
CompCar2Pos     FDB 0
CompCar3Pos     FDB 0
CompCar4Pos     FDB 0
