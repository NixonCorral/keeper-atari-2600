# *Keeper* for the Atari Video Computer System

*Keeper* is a single-player ballgame wherein the object is to keep the ball within the bounds of the screen using the eponymous Keeper, which is a reflective barrier. It uses standard joystick controls.

The Keeper is split into eight chunks, which form a perimeter around the ball. However, only one chunk may be activated at a time. You may activate a chunk by pointing in any direction with the joystick and pressing the fire button. This will reflect the ball and keep it in play. However, the Keeper has one flaw: it is most effective when activated immediately before the ball makes contact with it (within one twelfth of a second before contact, to be exact). If you activate it in that window of time, the ball will slow down (or at least not speed up if it is already at the starting speed). If not, the ball will speed up. The ball speed caps out after five speed increases and can always be slowed back down by nailing the timing of the next hit.

A single point is awarded for each time the ball collides with the Keeper, regardless of whether or not the timing constraint was met. If you fail to keep the ball within the Keeper and it touches the edge of the screen, you will lose a life. You have three lives with which to shoot for your next high score.

*Keeper* features two gameplay modes whose fundamentals are the same but that do vary slightly. They can be toggled by holding the Select switch on your Atari VCS or emulator.

Game Mode 1 is the default mode. It features a small ball. It also features Trackers, which follow the ball and hug the Keeper at all times. This makes it easier to determine when the ball is about to be at the edge of the Keeper, since it will be invisible most of the time.

Game Mode 2 features a larger ball and does not have Trackers. Consider trying this more challenging mode when you have mastered Game Mode 1.

If you wish to play this game, please download the latest binary from the Releases section. The easiest way to run it would be to use the [Stella Emulator](https://stella-emu.github.io/). If you want a more faithful experience, you could also load it onto a [Harmony Cartridge](https://harmony.atariage.com/Site/Harmony.html) or perhaps run it on a [MiSTer](https://mister-devel.github.io/MkDocs_MiSTer/) setup for analog video output.

Bear in mind that the file size is four (4) kilobytes, so please make sure you have enough room on your storage device.
