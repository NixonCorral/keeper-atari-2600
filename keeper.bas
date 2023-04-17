    include 6lives.asm
    set romsize 4k
    set kernel_options no_blank_lines ; no_blank_lines means we lose missile0
    set optimization speed
    set optimization inlinerand
    set tv ntsc

__Start_Restart
    ; clear playfield
    pfclear

    ; clear audio
    AUDV0 = 0 : AUDV1 = 0

    ;  Clears all normal variables (we don't clear z because it's used for the RNG) and the extra 9.
    a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
    j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
    s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0
    var0 = 0 : var1 = 0 : var2 = 0 : var3 = 0 : var4 = 0
    var5 = 0 : var6 = 0 : var7 = 0 : var8 = 0

    ;***************************************************************
    ;  Var for reset switch that allows us to prevent constant
    ;  resets if the switch is held for multiple frames

    dim _Bit0_Reset_Restrainer = r

    ; background color
    COLUBK = $01
    ; two-pixel wide ball and normal, single-color batariBasic playfield
    CTRLPF = $11
    scorecolor = $9E
    ; reset score
    score = 0

    ;```````````````````````````````````````````````````````````````
    ;  Ball direction bits.
    ;
    dim _BitOp_Ball_Dir = h
    dim _Bit0_Ball_Dir_Up = h
    dim _Bit1_Ball_Dir_Down = h
    dim _Bit2_Ball_Dir_Left = h
    dim _Bit3_Ball_Dir_Right = h
    dim _Bit4_Ball_Hit_UD = h

    ;```````````````````````````````````````````````````````````````
    ;  Allows speed and angle adjustments to the ball.
    ;
    dim _B_Y = bally.i
    dim _B_X = ballx.j

    dim rand16 = z

    ; determines playfield shape
    dim _playfield_shape = p

    dim _ball_vel_x = c
    dim _ball_vel_y = d


    ;***************************************************************
    ;
    ;  Defines the edges of the playfield for the ball. If the
    ;  ball is a different size, you'll need to adjust the numbers.
    ;
    const _B_Edge_Top = 2
    const _B_Edge_Bottom = 88
    const _B_Edge_Left = 2
    const _B_Edge_Right = 160

    ;***************************************************************
    ; variables that count the number of frames since the two
    ; raindrops hit the planet. used for playing short hit sounds
    dim _collision_countdown_0 = t
    dim _collision_countdown_1 = u

    ;***************************************************************
    ; starting positions for ball

    ballx = 71
    bally = 40
    ballheight = 2

    ;***************************************************************
    ;
    ;  Ballx starting direction is random. It will either go left
    ;  or right.
    ;
    _Bit2_Ball_Dir_Left{2} = 1 : _Bit3_Ball_Dir_Right{3} = 0

    temp5 = rand : if temp5 < 128 then _Bit2_Ball_Dir_Left{2} = 0 : _Bit3_Ball_Dir_Right{3} = 1


    ;***************************************************************
    ;
    ;  Bally starting direction is random as well.
    ;
    _Bit1_Ball_Dir_Down{1} = 1 : _Bit0_Ball_Dir_Up{0} = 0

    if temp5 < 128 then _Bit1_Ball_Dir_Down{1} = 0 : _Bit0_Ball_Dir_Up{0} = 1

    ; require the fire button to be pressed to start the game
    dim _game_started = w

    ; variable for the ball speed increase
    dim _ratio = k.l
    _ratio = 0.51
    dim _ratio_increases = v
    _ratio_increases = 0

    ; variable for time since fire was pressed
    dim _fire_time = e
    _fire_time = 0
    dim _fire_time_late = q
    _fire_time_late = 40

    ; variable for counting how long since you lost a life
    dim _life_loss_counter = f
    _life_loss_counter = 0

    dim _life_loss_reset = g
    g = 0

    ; initiate lives to 3 and use the compact spacing
    dim lives_compact = 1
    lives = 96

    ; set lives sprite to a little heart
 lives:
   %00010000
   %00111000
   %01111100
   %11111110
   %11111110
   %01101100
   %00000000
   %00000000
end

 ; Xs are playfield color (green) and dots are background color (black)
 playfield:
................................ 
................................
................................
................................
................................
................................
................................
................................
................................
................................
................................
end

gameloop
    if lives < 32 then goto gameover_loop
    ; reset game state when new life starts
    if _life_loss_reset > 0 then ballx = 71 : bally = 40 : _ratio = 0.25 : _ratio_increases = 0 : _fire_time = 0 : _life_loss_reset = 0
    ;***************************************************************
    ; these values are set to 4 when either raindrop collides with
    ; the planet and count down each frame to zero. When they are
    ; non-zero, a hit sound plays. Since the system runs at 60fps,
    ; these sounds are quite short.
    if _collision_countdown_0 > 0 then _collision_countdown_0 = _collision_countdown_0 - 1
    if _collision_countdown_1 > 0 then _collision_countdown_1 = _collision_countdown_1 - 1
    if _collision_countdown_0 > 0 || _collision_countdown_1 > 0 then AUDC0 = 14 : AUDV0 = 8 : AUDF0 = 31 : goto __Skip_Quiet
    AUDV0 = 0
__Skip_Quiet 

    ; color of player 0 (player character) and missile 0
    COLUP0 = $CA
    ; color of player 1 (raindrop on left/right) and missile 1 (raindrop on top/bottom)
    COLUP1 = $BF
    ; color of playfield and ball
    COLUPF = $AA
    ; missile 1 is two pixels wide and there is only one of them
    NUSIZ1 = $10
    ; color of lives indicator
    lifecolor = $FF
    drawscreen

    ; don't just start the game until the player presses the button
    if joy0fire then _game_started = 1
    if _game_started = 0 then goto gameloop

    ;***************************************************************
    ;
    ;  Clears screen without clearing var44 through var47 (bottom line), is more cycle-efficient than pfclear apparently
    ;
    var0 = 0 : var1 = 0 : var2 = 0 : var3 = 0 : var4 = 0 : var5 = 0
    var6 = 0 : var7 = 0 : var8 = 0 : var9 = 0 : var10 = 0 : var11 = 0
    var12 = 0 : var13 = 0 : var14 = 0 : var15 = 0 : var16 = 0 : var17 = 0
    var18 = 0 : var19 = 0 : var20 = 0 : var21 = 0 : var22 = 0 : var23 = 0
    var24 = 0 : var25 = 0 : var26 = 0 : var27 = 0 : var28 = 0 : var29 = 0
    var30 = 0 : var31 = 0 : var32 = 0 : var33 = 0 : var34 = 0 : var35 = 0
    var36 = 0 : var37 = 0 : var38 = 0 : var39 = 0 : var40 = 0 : var41 = 0
    var42 = 0 : var43 = 0

    ; use joystick location to determine playfield shape, represented here as a phone keypad position
    if !joy0fire then _fire_time = 0 : goto _Pf_5
    _fire_time = _fire_time + 1
    if joy0left && joy0up then goto _Pf_1
    if joy0up && !joy0left && !joy0right then goto _Pf_2
    if joy0up && joy0right then goto _Pf_3
    if joy0left && !joy0up && !joy0down then goto _Pf_4
    if !joy0left && !joy0right && !joy0down && !joy0up then goto _Pf_5
    if joy0right && !joy0up && !joy0down then goto _Pf_6
    if joy0left && joy0down then goto _Pf_7
    if joy0down && joy0right then goto _Pf_9
    goto _Pf_8

    goto gameloop

_Pf_1
 playfield:
XXXXXXXXX....................... 
X...............................
X...............................
................................
................................
................................
................................
................................
................................
................................
................................
end
 goto _End_Pf

_Pf_2
 playfield:
.........XXXXXXXXXXXXXX......... 
................................
................................
................................
................................
................................
................................
................................
................................
................................
................................
end
 goto _End_Pf

_Pf_3
 playfield:
.......................XXXXXXXXX
...............................X
...............................X
................................
................................
................................
................................
................................
................................
................................
................................
end
 goto _End_Pf

_Pf_4
 playfield:
................................
................................
................................
X...............................
X...............................
X...............................
X...............................
X...............................
................................
................................
................................
end
 goto _End_Pf

_Pf_5
 playfield:
................................
................................
................................
................................
................................
................................
................................
................................
................................
................................
................................
end
 goto _End_Pf

_Pf_6
 playfield:
................................
................................
................................
...............................X
...............................X
...............................X
...............................X
...............................X
................................
................................
................................
end
 goto _End_Pf

_Pf_7
 playfield:
................................
................................
................................
................................
................................
................................
................................
................................
X...............................
X...............................
XXXXXXXXX.......................
end
 goto _End_Pf

_Pf_8
 playfield:
................................
................................
................................
................................
................................
................................
................................
................................
................................
................................
.........XXXXXXXXXXXXXX.........
end
 goto _End_Pf

_Pf_9
 playfield:
................................
................................
................................
................................
................................
................................
................................
................................
...............................X
...............................X
.......................XXXXXXXXX
end
 goto _End_Pf

_End_Pf

    ; Ball is on screen within the bounds of the keeper
    if bally > _B_Edge_Top + 6 && bally < _B_Edge_Bottom - 6 && ballx > _B_Edge_Left + 17 && ballx < _B_Edge_Right - 17 then goto __Ball_In_Play
    ; Ball has hit the edge of the screen, causing a loss of life
    if bally <= _B_Edge_Top || bally >= _B_Edge_Bottom then lives = lives - 32 : goto __Life_Loss
    if ballx <= _B_Edge_Left || ballx >= _B_Edge_Right then lives = lives - 32 : goto __Life_Loss

    if !_Bit0_Ball_Dir_Up{0} then goto __Skip_Dead_Ball_Up
    _B_Y = _B_Y - 0.50
__Skip_Dead_Ball_Up
    if !_Bit1_Ball_Dir_Down{1} then goto __Skip_Dead_Ball_Down
    _B_Y = _B_Y + 0.50
__Skip_Dead_Ball_Down
    if !_Bit2_Ball_Dir_Left{2} then goto __Skip_Dead_Ball_Left
    _B_X = _B_X - 0.50
__Skip_Dead_Ball_Left
    if !_Bit3_Ball_Dir_Right{3} then goto __Skip_Dead_Ball_Right
    _B_X = _B_X + 0.50
__Skip_Dead_Ball_Right
    goto gameloop

__Ball_In_Play
   ;***************************************************************
   ;
   ;  Clears ball hits.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Clears the up/down ball/playfield hit bit.
   ;
   _Bit4_Ball_Hit_UD{4} = 0



   ;***************************************************************
   ;
   ;  Ball up check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if ball isn't moving up.
   ;
   if !_Bit0_Ball_Dir_Up{0} then goto __Skip_Ball_Up

   ;```````````````````````````````````````````````````````````````
   ;  Changes direction if hitting the edge.
   ;
   if bally <= _B_Edge_Top then goto __Reverse_Ball_Up

   ;```````````````````````````````````````````````````````````````
   ;  Changes direction if a playfield pixel is in the way.
   ;
   temp5 = (ballx-18)/4

   temp6 = (bally-2)/8

   if temp5 < 34 then if pfread(temp5,temp6) then _Bit4_Ball_Hit_UD{4} = 1 : goto __Reverse_Ball_Up

   ;```````````````````````````````````````````````````````````````
   ;  Moves ball up and skips the rest of this section.
   ;
   _B_Y = _B_Y - _ratio : goto __Skip_Ball_Up

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Reverses direction.
   ;
__Reverse_Ball_Up

   ;```````````````````````````````````````````````````````````````
   ;  Mixes things up a bit to keep the ball from getting caught
   ;  in a pattern.
   ;
   _B_Y = _B_Y + 0.130

   temp5 = rand : if temp5 < 128 then _B_Y = _B_Y + 0.130

   ;```````````````````````````````````````````````````````````````
   ; Increases speed if fire time was too early. Decreases if it was on time
   ;

    if _fire_time >= _fire_time_late && _ratio_increases < 5 then _ratio_increases = _ratio_increases + 1 : _ratio = _ratio + 0.25 : goto __Skip_Slow_Up
    if _fire_time < _fire_time_late && _ratio_increases >= 1 then _ratio_increases = _ratio_increases - 1 : _ratio = _ratio - 0.25
__Skip_Slow_Up
    

   ;```````````````````````````````````````````````````````````````
   ;  Reverses the direction bits.
   ;
   _Bit0_Ball_Dir_Up{0} = 0 : _Bit1_Ball_Dir_Down{1} = 1

   score = score + 1

__Skip_Ball_Up



   ;***************************************************************
   ;
   ;  Ball down check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if ball isn't moving down.
   ;
   if !_Bit1_Ball_Dir_Down{1} then goto __Skip_Ball_Down

   ;```````````````````````````````````````````````````````````````
   ;  Changes direction if hitting the edge.
   ;
   if bally >= _B_Edge_Bottom then goto __Reverse_Ball_Down

   ;```````````````````````````````````````````````````````````````
   ;  Changes direction if a playfield pixel is in the way.
   ;
   temp5 = (ballx-18)/4

   temp6 = (bally+1)/8

   if temp5 < 34 then if pfread(temp5,temp6) then _Bit4_Ball_Hit_UD{4} = 1 : goto __Reverse_Ball_Down

   ;```````````````````````````````````````````````````````````````
   ;  Moves ball down and skips the rest of this section.
   ;
   _B_Y = _B_Y + _ratio : goto __Skip_Ball_Down

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Reverses direction.
   ;
__Reverse_Ball_Down

   ;```````````````````````````````````````````````````````````````
   ;  Mixes things up a bit to keep the ball from getting caught
   ;  in a pattern.
   ;
   _B_Y = _B_Y - 0.261

   temp5 = rand : if temp5 < 128 then _B_Y = _B_Y - 0.261

   ;```````````````````````````````````````````````````````````````
   ; Increases speed if fire time was too early. Decreases if it was on time
   ;

    if _fire_time >= _fire_time_late && _ratio_increases < 5 then _ratio_increases = _ratio_increases + 1 : _ratio = _ratio + 0.25 : goto __Skip_Slow_Down
    if _fire_time < _fire_time_late && _ratio_increases >= 1 then _ratio_increases = _ratio_increases - 1 : _ratio = _ratio - 0.25
__Skip_Slow_Down

   ;```````````````````````````````````````````````````````````````
   ;  Reverses the direction bits.
   ;
   _Bit0_Ball_Dir_Up{0} = 1 : _Bit1_Ball_Dir_Down{1} = 0

   score = score + 1

__Skip_Ball_Down



   ;***************************************************************
   ;
   ;  Ball left check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if ball isn't moving left.
   ;
   if !_Bit2_Ball_Dir_Left{2} then goto __Skip_Ball_Left

   ;```````````````````````````````````````````````````````````````
   ;  Changes direction if hitting the edge.
   ;
   if ballx <= _B_Edge_Left then goto __Reverse_Ball_Left

   ;```````````````````````````````````````````````````````````````
   ;  Changes direction if a playfield pixel is in the way.
   ;
   temp5 = (bally)/8

   temp6 = (ballx-19)/4

   if temp6 < 34 then if pfread(temp6,temp5) then goto __Reverse_Ball_Left

   ;```````````````````````````````````````````````````````````````
   ;  Moves ball left and skips the rest of this section.
   ;
   _B_X = _B_X - _ratio : goto __Skip_Ball_Left

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Reverses direction.
   ;
__Reverse_Ball_Left

   ;```````````````````````````````````````````````````````````````
   ;  Reverses up/down bits if there was an up or down hit.
   ;
   if _Bit4_Ball_Hit_UD{4} then _Bit0_Ball_Dir_Up{0} = !_Bit0_Ball_Dir_Up{0} : _Bit1_Ball_Dir_Down{1} = !_Bit1_Ball_Dir_Down{1}

   ;```````````````````````````````````````````````````````````````
   ;  Mixes things up a bit to keep the ball from getting caught
   ;  in a pattern.
   ;
   _B_X = _B_X + 0.388

   temp5 = rand : if temp5 < 128 then _B_X = _B_X + 0.388

   ;```````````````````````````````````````````````````````````````
   ; Increases speed if fire time was too early. Decreases if it was on time
   ;

    if _fire_time >= _fire_time_late && _ratio_increases < 5 then _ratio_increases = _ratio_increases + 1 : _ratio = _ratio + 0.25 : goto __Skip_Slow_Left
    if _fire_time < _fire_time_late && _ratio_increases >= 1 then _ratio_increases = _ratio_increases - 1 : _ratio = _ratio - 0.25
__Skip_Slow_Left

   ;```````````````````````````````````````````````````````````````
   ;  Reverses the direction bits.
   ;
   _Bit2_Ball_Dir_Left{2} = 0 : _Bit3_Ball_Dir_Right{3} = 1

    score = score + 1

__Skip_Ball_Left



   ;***************************************************************
   ;
   ;  Ball right check.
   ;
   ;```````````````````````````````````````````````````````````````
   ;  Skips this section if ball isn't moving right.
   ;
   if !_Bit3_Ball_Dir_Right{3} then goto __Skip_Ball_Right

   ;```````````````````````````````````````````````````````````````
   ;  Changes direction if hitting the edge.
   ;
   if ballx >= _B_Edge_Right then goto __Reverse_Ball_Right

   ;```````````````````````````````````````````````````````````````
   ;  Changes direction if a playfield pixel is in the way.
   ;
   temp5 = (bally)/8

   temp6 = (ballx-16)/4

   if temp6 < 34 then if pfread(temp6,temp5) then goto __Reverse_Ball_Right

   ;```````````````````````````````````````````````````````````````
   ;  Moves ball right and skips the rest of this section.
   ;
   _B_X = _B_X + _ratio : goto __Skip_Ball_Right

   ;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
   ;```````````````````````````````````````````````````````````````
   ;  Reverses direction.
   ;
__Reverse_Ball_Right

   ;```````````````````````````````````````````````````````````````
   ;  Reverses up/down bits if there was an up or down hit.
   ;
   if _Bit4_Ball_Hit_UD{4} then _Bit0_Ball_Dir_Up{0} = !_Bit0_Ball_Dir_Up{0} : _Bit1_Ball_Dir_Down{1} = !_Bit1_Ball_Dir_Down{1}

   ;```````````````````````````````````````````````````````````````
   ;  Mixes things up a bit to keep the ball from getting caught
   ;  in a pattern.
   ;
   _B_X = _B_X - 0.513

   temp5 = rand : if temp5 < 128 then _B_X = _B_X - 0.513

   ;```````````````````````````````````````````````````````````````
   ; Increases speed if fire time was too early. Decreases if it was on time
   ;

    if _fire_time >= _fire_time_late && _ratio_increases < 5 then _ratio_increases = _ratio_increases + 1 : _ratio = _ratio + 0.25 : goto __Skip_Slow_Right
    if _fire_time < _fire_time_late && _ratio_increases >= 1 then _ratio_increases = _ratio_increases - 1 : _ratio = _ratio - 0.25
__Skip_Slow_Right

   ;```````````````````````````````````````````````````````````````
   ;  Reverses the direction bits.
   ;
   _Bit2_Ball_Dir_Left{2} = 1 : _Bit3_Ball_Dir_Right{3} = 0

   score = score + 1

__Skip_Ball_Right

    ;***************************************************************
    ;
    ;  Reset switch check and end of main loop.
    ;
    ;  Any Atari 2600 program should restart when the reset  
    ;  switch is pressed. It is part of the usual standards
    ;  and procedures.
    ;
    ;```````````````````````````````````````````````````````````````
    ;  Turns off reset restrainer bit and jumps to beginning of
    ;  main loop if the reset switch is not pressed.
    ;
    if !switchreset then _Bit0_Reset_Restrainer{0} = 0 : goto gameloop

    ;```````````````````````````````````````````````````````````````
    ;  Jumps to beginning of main loop if the reset switch hasn't
    ;  been released after being pressed.
    ;
    if _Bit0_Reset_Restrainer{0} then goto gameloop

    ;```````````````````````````````````````````````````````````````
    ;  Restarts the program.
    ;
    goto __Start_Restart

__Life_Loss
    drawscreen
    ; do an annoying buzzing sound for a second when you die
    AUDC0 = 2 : AUDV0 = 8 : AUDF0 = 0
    _life_loss_counter = _life_loss_counter + 1
    if _life_loss_counter = 61 then _life_loss_counter = 0 : _life_loss_reset = 1 : goto gameloop
    goto __Life_Loss

gameover_loop
    drawscreen
    ; mute the annoying buzzer
    AUDC0 = 0 : AUDV0 = 0 : AUDF0 = 0
    if joy0fire || switchreset then goto __Start_Restart
    goto gameover_loop