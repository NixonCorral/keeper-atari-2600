    ;***************************************************************
    ;
    ;  Keeper
    ;  Game by Clayton Anderson
    ;
    ;```````````````````````````````````````````````````````````````
    ;
    ;  Instructions:
    ;
    ;  A ball appears in the middle of the screen. You must press in
    ;  one of the eight joystick directions and press the fire button
    ;  to make the corresponding chunk of the Keeper appear. It will
    ;  reflect the ball. If you do so within 6 frames of collision,
    ;  the ball will reduce in speed. If you do so outside this window,
    ;  it will increase in speed. It will only increase up to five times,
    ;  and it cannot be reduced beyond its initial speed. Points are
    ;  earned for every time the ball is successfully deflected. You
    ;  are given three lives, which are lost if you allow the ball to go
    ;  out of bounds. If you lose all three, it's Game Over.
    ;  
    ;  There are two game modes that can be toggled using the Select switch.
    ;  Further details on these modes can be found in the README.
    ;
    ;```````````````````````````````````````````````````````````````
    ;
    ;  Warning:
    ;
    ;  An unfortunate reality of working with batari Basic is that
    ;  a huge amount of its reference material is hosted on randomterrain.com.
    ;  It has been an indispensable resource for me for 2600 development, and I
    ;  have given credit below when code has been copied from example programs
    ;  found on the Random Terrain website. However, said website has, at the 
    ;  bottom of EVERY page, a bizarre "In Case You Didn't Know" section
    ;  espousing a laundry list of anti-science beliefs. It's weird and sucks!
    ;  Of course, I do not endorse those claims whatsoever.
    ;
    ;```````````````````````````````````````````````````````````````
    ;
    ;  The latest release of the batari Basic can be found here:
    ;  https://github.com/batari-Basic/batari-Basic
    ;
    ;***************************************************************

    include 6lives.asm
    set romsize 4k
    set kernel_options no_blank_lines ; no_blank_lines means we lose missile0
    set optimization speed
    set optimization inlinerand
    set tv ntsc

    ; clear the game mode var on initial boot but not on reset per Atari best practice
    b = 0

__Start_Restart
    ; clear playfield
    pfclear

    ; clear audio
    AUDV0 = 0 : AUDV1 = 0

    ;  Clears all normal variables and the extra 9.
    ;  We don't clear z because it's used for the RNG, and we don't clear b
    ;  because it's used for game mode select, which should not change on reset.
    a = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
    j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
    s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0
    var0 = 0 : var1 = 0 : var2 = 0 : var3 = 0 : var4 = 0
    var5 = 0 : var6 = 0 : var7 = 0 : var8 = 0

    ;***************************************************************
    ;  Var for reset switch that allows us to prevent constant
    ;  resets if the switch is held for multiple frames

    dim _Bit0_Reset_Restrainer = r

    ; background color (black)
    COLUBK = $01
    ; two-pixel wide ball and normal, single-color batariBasic playfield
    CTRLPF = $11
    scorecolor = $9E
    ; reset score
    score = 0

    ;```````````````````````````````````````````````````````````````
    ;  Ball direction bits handled with one var.
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

    ;***************************************************************
    ;
    ;  Defines the edges of the playfield for the ball.
    ;  This is technically incorrect for big ball mode (Mode 2), but
    ;  it does not affect gameplay.
    ;
    const _B_Edge_Top = 2
    const _B_Edge_Bottom = 88
    const _B_Edge_Left = 2
    const _B_Edge_Right = 160

    ;***************************************************************
    ;  variables that count how long to play sound effects when the ball
    ;  starts going faster or slower
    ;
    dim _speed_up_countdown = t
    dim _speed_down_countdown = u

    ;  starting positions and size for ball
    ballx = (rand&31) + 60
    bally = 35
    ballheight = 2

    ;***************************************************************
    ;
    ;  Ballx starting direction is random. It will either go left
    ;  or right.
    ;
    _Bit2_Ball_Dir_Left{2} = 1 : _Bit3_Ball_Dir_Right{3} = 0

    temp5 = rand : if temp5 < 128 then _Bit2_Ball_Dir_Left{2} = 0 : _Bit3_Ball_Dir_Right{3} = 1

    ;  Bally starting direction is random as well.
    _Bit1_Ball_Dir_Down{1} = 1 : _Bit0_Ball_Dir_Up{0} = 0

    if temp5 < 128 then _Bit1_Ball_Dir_Down{1} = 0 : _Bit0_Ball_Dir_Up{0} = 1

    ; require the fire button to be pressed to start the game
    dim _game_started = w

    ; variable for the ball speed increase
    dim _ratio = k.l
    _ratio = 0.51

    ; counts the number of times the ball speed has been increased
    dim _ratio_increases = v

    ; variable for time since fire was pressed
    dim _fire_time = e
    const _fire_time_late = 5

    ; variable for time since fire was released (so players can't spam)
    dim _fire_release_time = a

    ; variables for which game mode we're on and how long it's been since we pushed select
    dim _Mode_Val = b
    dim _Select_Counter = m

    ; best practice dictates that if mode select is open for 30 seconds or so, return to Idle state
    dim _Mode_Select_Idle_Frames = c
    dim _Mode_Select_Idle_Seconds = d

    ; variable for counting how long since you lost a life
    dim _life_loss_counter = f
    _life_loss_counter = 0

    ; initiate lives to 3 and use the compact spacing
    ; lives vars are used by the 6lives minikernel included above
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
end

    ;  Defines shape of player0 sprite.
    player0:
    %11111111
end

    ;  Defines shape of player1 sprite.
    player1:
    %1
    %1
    %1
    %1
    %1
    %1
    %1
end

gameloop
    
    ; *************************************************************
    ;  a couple sprites need to be redefined each time because the mode select
    ;  routine fucks them up (and I don't know how to fix that lol)

    ;  Defines shape of player0 sprite.
    player0:
    %11111111
end

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

    ; two little paddle-like objects track the ball in Mode 1
    ; so it is easier to tell when it is near the barrier
    if _Mode_Val & 1 then goto __Skip_Trackers
    player0x = ballx - 4
    if _Bit1_Ball_Dir_Down{1} then player0y = 80 else player0y = 8
    if _Bit3_Ball_Dir_Right{3} then player1x = 133 else player1x = 14
    player1y = bally + 3
    goto __Skip_Offscreen_Trackers
__Skip_Trackers
    ; Trackers do not appear in Mode 2
    player0y = 200
    player1y = 200
__Skip_Offscreen_Trackers

    ; if they're mashing that select switch you better do what they say
    if switchselect then goto __Select_Mode

    ; *********************************************************************
    ;  lives are represented in increments of 32 for some computer-related reasons
    ;  that you can probably guess, or at least I hope so, since I don't know the specifics
    ;
    if lives < 32 then goto gameover_loop

    ; reset game state when new life starts
    if _life_loss_counter > 60 then ballx = (rand&31) + 60 : bally = 35 : _ratio = 0.51 : _ratio_increases = 0 : _fire_time = 0 : _life_loss_counter = 0

    ; we only want one of the sounds to be playing at once, specifically the one that most recently started
    if _speed_down_countdown >= _speed_up_countdown then _speed_up_countdown = 0
    if _speed_up_countdown > _speed_down_countdown then _speed_down_countdown = 0

    ; decrease value of hit sound counters every frame until they stop playing
    if _speed_up_countdown > 0 then _speed_up_countdown = _speed_up_countdown - 1 : AUDC0 = 7 : AUDV0 = 4 : AUDF0 = _speed_up_countdown else AUDV0 = 0
    if _speed_down_countdown > 0 then _speed_down_countdown = _speed_down_countdown - 1 : AUDC1 = 10 : AUDV1 = 4 : AUDF1 = 30 - _speed_down_countdown else AUDV1 = 0

    ; color of playfield and ball (blue)
    COLUPF = $AA
    ; color of player (and missile) 1 (grayish)
    COLUP0 = $0A
    ; color of player (and missile) 2 (grayish)
    COLUP1 = $0A
    ; color of lives indicator (yellow)
    lifecolor = $FF

    if _Mode_Val < 1 then goto __Skip_Mode_2
    ; four-pixel wide/tall ball and normal, single-color batariBasic playfield
    CTRLPF = $21
    ballheight = 4
    goto __Skip_Mode_1
__Skip_Mode_2
    ; two-pixel wide/tall ball and normal, single-color batariBasic playfield
    CTRLPF = $11
    ballheight = 2
__Skip_Mode_1

    drawscreen

    ; don't just start the game until the player presses the button
    if joy0fire then _game_started = 1
    if _game_started = 0 then goto gameloop

    ; use joystick location to determine playfield shape, represented here as a phone keypad position
    if joy0fire then goto __Select_Pf
    _fire_release_time = _fire_release_time + 1

    ; `````````````````````````````````````````````````````````````````````````````
    ;  fire button needs to be released for at least five frames for it to count
    ;  this is effectively a spam-prevention mechanism. the barrier chunk will still
    ;  appear, but it may still speed up the ball.
    ; 
    if _fire_release_time > 12 then _fire_time = 0 : goto _Pf_5 else _fire_time = _fire_time + 1 : goto _Pf_5
    

    ; `````````````````````````````````````````````````````````````````````````````
    ;  this is where we determine which chunk of the Keeper is active (if any).
    ;  if the fire button is pressed and the joystick is also pressed in any direction,
    ;  the corresponding edge/corner of the keeper will appear and be active.

__Select_Pf
    _fire_time = _fire_time + 1
    _fire_release_time = 0
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
 pfclear
    var12 = %10000000
    var16 = %10000000
    var20 = %10000000
    var24 = %10000000
    var28 = %10000000

 ; same as
 /* playfield:
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
end */
 goto _End_Pf

_Pf_5
 pfclear
 goto _End_Pf

_Pf_6
 pfclear
    var15 = %10000000
    var19 = %10000000
    var23 = %10000000
    var27 = %10000000
    var31 = %10000000

 ; same as
 /* playfield:
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
end */
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
 pfclear
                     var35 = %10000000
                     var39 = %10000000
 var42 = %00000001 : var43 = %11111111
 ; same as
 /* playfield:
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
end */
 goto _End_Pf

_End_Pf

    ; Ball is on screen within the bounds of the keeper
    if bally > _B_Edge_Top + 6 && bally < _B_Edge_Bottom - 6 && ballx > _B_Edge_Left + 17 && ballx < _B_Edge_Right - 17 then goto __Ball_In_Play

    ; Ball has hit the edge of the screen, causing a loss of life
    if bally <= _B_Edge_Top || bally >= _B_Edge_Bottom then lives = lives - 32 : goto __Life_Loss
    if ballx <= _B_Edge_Left || ballx >= _B_Edge_Right then lives = lives - 32 : goto __Life_Loss

    ; Ball is heading to the edge of the screen but is not there yet

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

   ;```````````````````````````````````````````````````````````````
   ;  This section deals with detecting the ball's collision with the
   ;  Keeper (the playfield). This was lifted HEAVILY from the
   ;  Collision Prevention example program at Random Terrain.
   ;  https://www.randomterrain.com/atari-2600-memories-batari-basic-commands.html#collision
   ;
   ;  My additions are detecting whether or not the Keeper was activated
   ;  in the last 6 frames (and speeding up or slowing down the ball accordingly),
   ;  as well as incrementing the score on each hit.

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

   temp6 = (bally-2-_Mode_Val-_Mode_Val)/8

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

    if _fire_time >= _fire_time_late + _ratio_increases && _ratio_increases < 5 then _ratio_increases = _ratio_increases + 1 : _ratio = _ratio + 0.25 : _speed_up_countdown = 30 : goto __Skip_Slow_Up
    if _fire_time < _fire_time_late + _ratio_increases && _ratio_increases >= 1 then _ratio_increases = _ratio_increases - 1 : _ratio = _ratio - 0.25 : _speed_down_countdown = 30
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

    if _fire_time >= _fire_time_late + _ratio_increases && _ratio_increases < 5 then _ratio_increases = _ratio_increases + 1 : _ratio = _ratio + 0.25 : _speed_up_countdown = 30 : goto __Skip_Slow_Down
    if _fire_time < _fire_time_late + _ratio_increases && _ratio_increases >= 1 then _ratio_increases = _ratio_increases - 1 : _ratio = _ratio - 0.25 : _speed_down_countdown = 30
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

    if _fire_time >= _fire_time_late + _ratio_increases && _ratio_increases < 5 then _ratio_increases = _ratio_increases + 1 : _ratio = _ratio + 0.25 : _speed_up_countdown = 30 : goto __Skip_Slow_Left
    if _fire_time < _fire_time_late + _ratio_increases && _ratio_increases >= 1 then _ratio_increases = _ratio_increases - 1 : _ratio = _ratio - 0.25 : _speed_down_countdown = 30
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

   ; ball is two pixels wider in mode 2, so add that var here twice and save a variable
   temp6 = (ballx-16+_Mode_Val+_Mode_Val)/4

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

    if _fire_time >= _fire_time_late + _ratio_increases && _ratio_increases < 5 then _ratio_increases = _ratio_increases + 1 : _ratio = _ratio + 0.25 : _speed_up_countdown = 30 : goto __Skip_Slow_Right
    if _fire_time < _fire_time_late + _ratio_increases && _ratio_increases >= 1 then _ratio_increases = _ratio_increases - 1 : _ratio = _ratio - 0.25 : _speed_down_countdown = 30
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
    ; do an annoying buzzing sound for a second when you die, then start again minus a life
    AUDC0 = 2 : AUDV0 = 8 : AUDF0 = 0
    _life_loss_counter = _life_loss_counter + 1
    if _life_loss_counter = 61 then goto gameloop
    ; in the off chance they hit the select switch during this routine, honor it
    if switchselect then goto __Select_Mode
    ; same with reset
    if !switchreset then _Bit0_Reset_Restrainer{0} = 0 : goto __Life_Loss
    if _Bit0_Reset_Restrainer{0} then goto __Life_Loss
    goto __Start_Restart

    ;```````````````````````````````````````````````````````````````
    ;  This section handles mode select. There are only two modes, 
    ;  and the only difference in them is that the ball is bigger
    ;  in the second mode. Because it uses the same collision data
    ;  as the small ball, though, it is a bit harder.
    ;
    ;  Some of this logic was lifted from the Random Terrain Select
    ;  Switch example.
    ;
    ;  https://www.randomterrain.com/atari-2600-memories-batari-basic-commands.html#switchselect
    ;

__Select_Mode
    ; mute audio for edge case where Select switch is pressed during gameplay
    AUDC0 = 0 : AUDV0 = 0 : AUDF0 = 0
    ; color of player (and missile) 1
    COLUP0 = $0A
    ; color of lives indicator
    lifecolor = $FF
    ; reset game state and display ball
    ballx = 60 : bally = 35 : _ratio = 0.51 : _ratio_increases = 0 : _fire_time = 0 : _life_loss_counter = 0 : lives = 96 : score = 0
    drawscreen
    ;```````````````````````````````````````````````````````````````
    ; Show mode select indicator (player0 in our case)
    ;
    player0x = 80
    player0y = 30

    if _Mode_Val > 0 then goto __Skip_One

    ; displays tracker not currently in use for mode selection number
    player1y = bally + 3

    ;  Defines shape of player0 sprite (a one)
    player0:
    %11111110
    %00010000
    %00010000
    %00010000
    %10010000
    %01010000
    %00110000
end
    ; two-pixel wide/tall ball and normal, single-color batariBasic playfield
    CTRLPF = $11
    ballheight = 2

    goto __Skip_Two

__Skip_One

    ;  moves Tracker off screen
    player1y = 200
    ;  Defines shape of player0 sprite (a two)
    player0:
    %11111110
    %10000000
    %10000000
    %11111110
    %00000010
    %00000010
    %11111110
end
    CTRLPF = $21
    ballheight = 4

__Skip_Two

    if !switchselect then _Select_Counter = 0 : goto __Skip_Mode_Switch

    ;```````````````````````````````````````````````````````````````
    ;  Adds one to the select counter.
    ;
    _Select_Counter = _Select_Counter + 1

    ;```````````````````````````````````````````````````````````````
    ;  Skips this section if select counter value is less than 30.
    ;
    if _Select_Counter < 30 then goto __Skip_Mode_Switch

    _Select_Counter = 0

    ;```````````````````````````````````````````````````````````````
    ;  Toggles Mode
    ;
    _Mode_Val = _Mode_Val ^ 1

__Skip_Mode_Switch

    ;```````````````````````````````````````````````````````````````
    ;  Per Atari 2600 Standards and Procedures, Select Mode should exit
    ;  after 30 seconds or so and return to the idle state.
    ;
    ;  https://www.randomterrain.com/atari-2600-memories-standards-and-procedures.html#leaving_game_select
    ;
    _Mode_Select_Idle_Frames = _Mode_Select_Idle_Frames + 1
    if _Mode_Select_Idle_Frames > 59 then _Mode_Select_Idle_Frames = 0 : _Mode_Select_Idle_Seconds = _Mode_Select_Idle_Seconds + 1
    if _Mode_Select_Idle_Seconds > 29 then _Mode_Select_Idle_Frames = 0 : _Mode_Select_Idle_Seconds = 0 : _game_started = 0 : goto gameloop

    ; fire should start the game with the current settings according
    ; to Atari 2600 best development practices.
    if joy0fire then goto __Start_Restart

    ;***************************************************************
    ;
    ;  Reset switch check and end of mode select loop.
    ;
    ;  Any Atari 2600 program should restart when the reset  
    ;  switch is pressed. It is part of the usual standards
    ;  and procedures.
    ;
    ;```````````````````````````````````````````````````````````````
    ;  Turns off reset restrainer bit and jumps to beginning of
    ;  main loop if the reset switch is not pressed.
    ;
    if !switchreset then _Bit0_Reset_Restrainer{0} = 0 : goto __Select_Mode

    ;```````````````````````````````````````````````````````````````
    ;  Jumps to beginning of main loop if the reset switch hasn't
    ;  been released after being pressed.
    ;
    if _Bit0_Reset_Restrainer{0} then goto __Select_Mode

    ;```````````````````````````````````````````````````````````````
    ;  Restarts the program.
    ;
    goto __Start_Restart

gameover_loop
    drawscreen
    ; mute the annoying buzzer
    AUDC0 = 0 : AUDV0 = 0 : AUDF0 = 0
    ; wait for a button press to return to gameplay.
    if joy0fire then goto __Start_Restart
    ; alternatively, a new mode can be selected.
    if switchselect then goto __Select_Mode
    ; reset check
    if !switchreset then _Bit0_Reset_Restrainer{0} = 0 : goto gameover_loop
    if _Bit0_Reset_Restrainer{0} then goto gameover_loop
    goto __Start_Restart