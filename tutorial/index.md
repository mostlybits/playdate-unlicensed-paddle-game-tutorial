## Welcome!

The goal of this tutorial is to give you a quick intro to building your first Playdate game. We're going to build an Unlicensed Paddle Game that is legally distinct from Atari's Pong™. (Please don't sue.) By the end, we'll have covered topics like:

- Rendering sprites
- Ball physics
- Controlling a paddle
- Scoring points and winning the game

We'll also touch on some interesting aspects of Lua and adopt an object-oriented style of programming supported by the Playdate SDK.

This tutorial is aimed at folks with at least a bit of programming experience, and maybe even passing familiarity with object-oriented programming in a language like C#, Java, Python, Ruby, JavaScript, etc. If you are looking for something that involves a bit less programming, you might check out [this tutorial](https://devforum.play.date/t/pulp-pong-dev-tutorial/2315/1) for making Pong in the Playdate Pulp game editor.

One final disclaimer before we dive in - I'm brand new to Lua, although I've made a few small games before. If you spot anything in this tutorial that doesn't quite make sense, please [message me on Twitter](https://twitter.com/mostlybits) and I'll update the tutorial.

## Setup

Before we get started, you'll want to make sure you have the Playdate SDK installed for your operating system. Installation and setup is outside the scope of this tutorial, but here are a few resources to help you get started:

- [Playdate SDK download](https://play.date/dev/)
- [Compiling Instructions](https://sdk.play.date/1.11.0/Inside%20Playdate.html#_compiling_a_project)
- [SquidGodDev - VSCode + Windows setup](https://www.youtube.com/watch?v=J0ufxinp7No)

You'll use the SDK to build your game and the included Playdate simulator to open it. Since we'll be doing that a lot in this tutorial, let's speed up the process with a little build script. Here's how to make one:

1. Create a file in your project directory called `build.sh`
2. Run `chmod +x build.sh` to make it executable
3. Add the following code:

```sh
#!/usr/bin/env bash

build_target="unlicensed-paddle-game.pdx"

pdc "source" $build_target
open $build_target
```

Note: This script assumes macOS or Linux. This step is completely optional, so if you're on Windows and not prepared to make your own version, feel free to skip it!

The script uses the `pdc` Playdate compiler to build any code in the `source` folder (starting with `main.lua`) into a target called `unlicensed-paddle-game.pdx`. (PDX is a subtle nod to [Panic's Portland roots](https://en.wikipedia.org/wiki/Portland_International_Airport).) It will then `open` that target in the simulator, which runs your game.

You'll also want to create a folder called `source` with one file in it, `main.lua`:

```sh
mkdir source
touch source/main.lua
```

So far you should have a project that looks like this:

```
/your-folder-name
  build.sh
  /source
    main.lua
```

Let's put something in `main.lua` and run our build script to make sure it all works. The minimum you need for a Playdate game to successfully build is the `playdate.update()` function, which is called right before every frame is rendered.

Add this to `main.lua`:

```lua
function playdate.update()
end
```

If you run the build script now, you'll get a blank screen in the simulator.

<!-- SCREENSHOT HERE -->

Let's make things a bit more interesting with our first sprite! We'll start with the ball.


## Drawing a ball

As mentioned in the intro, we're going to lean into the basic object-oriented programming (OOP) concepts offered by the Playdate SDK. These aren't strictly necessary and may have performance implications for larger games, but I find that they make code easier to reason about and extend.

Let's go ahead and make a simple `Ball` class in `main.lua` above the `playdate.update` function:

```lua
-- import the OOP tools provided by the playdate SDK
import "CoreLibs/object"
-- import the playdate graphics library so we can draw things
import "CoreLibs/graphics"
-- import the playdate sprites library
import "CoreLibs/sprites"

-- register a new global Lua class that inherits from sprite,
-- which will allow it to move, collide with other sprites, etc
class("Ball").extends(playdate.graphics.sprite)

-- initializer function that gets called when a
-- new instance of Ball is created
function Ball:init()
  -- since we inherit from sprite, do any sprite-related initialization
  Ball.super.init(self)

  print("I am a ball")
end

ball = Ball()

function playdate.update()
end
```

Note the `import`s in the first few lines. These 3 imports will be used in basically any Playdate game you make with Lua. (Although if you're not using the OOP tools provided by the SDK, you can skip the first one.)

Run the build script. You should still see a blank screen, but if you open the console, you'll see "I am a ball" as expected.

<!-- SCREENSHOT HERE -->

This isn't very interesting yet - let's actually draw the ball. We'll make our ball a circle, so we need to draw a circle onto the screen and make sure it gets connected up to our sprite correctly.

There are a couple ways we could go about this:

1. Add a `draw` callback to the sprite that draws a circle on every call
2. Draw the circle into an image, then set that image on the sprite

(1) is a little simpler, but we could end up with unnecessary redraw calls in a more complex game. We're going to go down route (2) for this tutorial.

>NOTE: I am not an expert on Playdate performance yet. I borrowed this idea from [this YouTube tutorial](https://www.youtube.com/watch?v=8OCebUVKlb4) recommended in the Playdate SDK docs. Please let me know if this is a very bad decision for some reason. :)

Let's add the code into our `init()` function for drawing the sprite image:

```lua {4-16}
function Ball:init()
  Ball.super.init(self)

  radius = 5
  -- create a new image placeholder that is big enough for the circle's diameter
  local ballImage = playdate.graphics.image.new(2 * radius, 2 * radius)
  -- create a fresh drawing context, just in case other transformations are active
  playdate.graphics.pushContext(ballImage)
  playdate.graphics.fillCircleAtPoint(radius, radius, radius)
  -- reset the drawing context so we don't pollute other calls
  playdate.graphics.popContext()
  -- set the sprite's image to be the circle image we just drew
  self:setImage(ballImage)

  -- move it to the center of the screen so we can see it
  self:moveTo(200, 120)
end
```

We need to do a couple small housekeeping items before the ball will render:

```lua {2,5}
ball = Ball()
ball:add()

function playdate:update()
  playdate.graphics.sprite.update()
end
```

If you re-run the build script, you should now see a ball drawn near the center of the screen. 🎉

A couple things to note before we get too far:

1. In most graphics programming, `(0,0)` represents the top-left of the screen. So drawing our ball at `(200, 120)` means "draw 200 pixels from the left, 120 pixels from the top."

2. We defined `ballImage` as a `local` variable. Variables in Lua are global by default, which makes them accessible across all files in a project. This can be handy in some cases - for example, maybe our paddle AI will want to take the ball's position into account. But there are usually better ways to organize code without using globals. I won't cover that in-depth in this tutorial, but might do a follow-up around using events to decouple components.

   In this case, we don't want to define `ballImage` as a global since nothing outside the sprite constructor should need to access it, so we define it as `local` to limit its scope.

### Tidying up

I don't know about you, but I get tired of typing `playdate.graphics` over and over. Let's create a shortcut since we're going to be using that a lot:

```lua {1,3,9-12,22}
gfx = playdate.graphics

class("Ball").extends(gfx.sprite)

function Ball:init()
  Ball.super.init(self)

  radius = 5
  local ballImage = gfx.image.new(2 * radius, 2 * radius)
  gfx.pushContext(ballImage)
  gfx.fillCircleAtPoint(radius, radius, radius)
  gfx.popContext()
  self:setImage(ballImage)

  self:moveTo(200, 120)
end

ball = Ball()
ball:add()

function playdate.update()
  gfx.sprite.update()
end
```

Normally I'm a fan of expressive variable names, but `gfx` is such a core concept here that I'm okay abbreviating it.

## Making the ball move

When table tennis was invented in 1847, players just sat the ball perfectly still in the middle of the table. If the ball rolled off your side of the table, it exposed your low moral character and you were summarily executed.

A few years later, they decided to add a rule where you were allowed to hit the ball back and forth. It was so much fun they forgot all about the executions.

Let's make our ball move before we get executed.

To start, we'll have it move right forever. Any sprite that has been registered with `add()` will have its `update()` method called by `gfx.sprite.update()`. So let's add an `update()` function to our `Ball` class:

```lua {1-4}
function Ball:update()
  -- move 1 pixel right, 0 pixels down
  self:moveBy(1, 0)
end
```

Rebuild the game and you should see your ball slowly slide off the right side of your screen into oblivion.

We don't have a great way to make the ball turn around yet. We want to have it move right until it gets to the edge, then turn around and go left until it gets to the edge, and so on. We need more than just the ball's position to make this happen - we also need its speed.

Let's change our `init()` function to store an `xSpeed`, then use that value to move the ball:

```lua {4,10}
function Ball:init()
  Ball.super.init(self)

  self.xSpeed = 1

  -- etc
end

function Ball:update()
  self:moveBy(self.xSpeed, 0)
end
```

Rebuild the game again and your ball should still be drifting off into space. Try changing to `self.xSpeed = 5` and watch it drift more quickly. Cool.

Now that we have a speed, we can make the ball turn around when it gets to the edge and go the other direction. Let's try it:

```lua {5,12-16}
function Ball:init()
  Ball.super.init(self)

  -- 1 is too slow :)
  self.xSpeed = 5

  -- etc
end

function Ball:update()
  -- screen width = 400
  if self.x + self.xSpeed >= 400 then
    self.xSpeed *= -1
  elseif self.x + self.xSpeed <= 0 then
    self.xSpeed *= -1
  end

  self:moveBy(self.xSpeed, 0)
end
```

Rebuild the game. You should see the ball moving back and forth between the right and left edges of the screen.

## Making the ball bounce left and right

We made the ball move left and right by turning it around if the next move was going to take it off of the screen. But we can do a little better than that while also setting ourselves up for adding paddles.

Sprites in Lua have built-in collision detection using a method called `moveWithCollisions()`. If a sprite moves into another sprite, it will generate a "collision normal" that tells us which direction we should bounce the current sprite.

The "normal" part of "collision normal" means that it is "normalized" into a unit vector, i.e. it should always have a length of 1 unit. So if something collides and should bounce down and right, it will have a collision normal of `(√2/2, √2/2)`. Using the Pythagorean theorem, the length of this vector would be 1.

Here's the overall approach we're going to take here:

1. Add invisible sprites for the left and right walls
2. Use `moveWithCollisions` on our ball
3. If it collided with the left or right wall, invert the speed

This might be overkill for now, but it will allow us to add the top and bottom walls more easily. And many of the concepts from this section will be used to make the ball bounce off of the paddle, score points, and so on.

Let's add our walls to start:

```lua
ball = Ball()
ball:add()

-- addEmptyCollisionSprite takes 4 arguments - x, y, width, height
-- We start our wall at (-5, 0), then make it 5 pixels wide and
-- 240 pixels tall (the height of the playdate screen)
--
-- We make it 5 pixels wide just in case our ball is moving
-- quickly enough to slip past the wall. You might need to make
-- it even wider for a very fast ball.
leftWall = gfx.sprite.addEmptyCollisionSprite(-5, 0, 5, 240)
leftWall:add()

-- right wall is the same, but starts at the right edge
rightWall = gfx.sprite.addEmptyCollisionSprite(400, 0, 5, 240)
rightWall:add()
```

Now let's use those walls in the update function instead of checking the screen boundaries:

```lua
function Ball:update()
  -- returns actualX, actualY, a list of collisions, and the
  -- length of the set of collisions
  --
  -- actualX and actualY represent where the sprite ended up
  -- after the collisions were applied and it was moved outside
  -- the bounds of any sprites it collided with. But for now
  -- we only care if it needs to bounce or not. :)
  --
  -- We're only going to use the list of collisions right now,
  -- so the convention in Lua is to use _ for unused variables
  local _, _, collisions, _ = self:moveWithCollisions(self.x + self.xSpeed, 0)

  -- In Lua, #collection gives you the length of the object,
  -- similar to collection.length in other languages
  for i = 1, #collisions do
    -- just for testing purposes
    print(collisions[i].normal)
    -- if the ball should bounce horizontally, then invert
    -- its xSpeed
    --
    -- also ~= is "not equals" in Lua, similar to != in
    -- most other languages 
    if collisions[i].normal.x ~= 0 then
      self.xSpeed *= -1
    end
  end
end
```

Rebuild the game and...

Whoops. There's an error in the console:

```
moveWithCollisions() can only be called on a sprite with a valid collide rect (this sprite's collide rect is (0.0, 0.0, 0.0, 0.0))
```

It looks like our ball doesn't know how to collide with anything else.

The default for most games and sprites is using a rectangular collision shape, the "collide rect" from that error message. You may need to experiment with other shapes in future games - many engines also support circle/capsule shapes natively as well - but for now a square is good enough.

The good news is that our sprite already has a size from `setImage`, so we just need to tell it to make its collide rect the same size:

```lua {5}
function Ball:init()
  -- etc

  self:setImage(ballImage)
  self:setCollideRect(0, 0, self:getSize())

  self:moveTo(200, 120)
end
```

Rebuild the game again. You should see the ball bouncing back and forth again, but this time it's hitting an invisible wall instead of checking the screen width. Neat!

Our new `update()` function is a little more complicated than before, so let's break it down:

1. First, we `moveWithCollisions()` by the `xSpeed`
2. Next, we iterate over the list of collisions
3. If any of those collisions tried to push the ball in a horizontal direction (`normal.x`), that means we hit the left or right wall and need to move in the other direction.

If you check the console logs, you'll notice that all of our collision normals are `(1.0, 0.0)` or `(-1.0, 0.0)`. This is because collision normals are perpendicular to the surface being struck to represent that the force is pushing away from the surface. In our case, when the ball strikes the right wall it gets pushed left, so the collision normal is `(-1.0, 0.0)`. When the ball strikes the left wall it gets pushed right, so the collision normal is `(1.0, 0.0)`.

We won't need to do anything more complicated with collision normals for this game, but it's good to know a little bit about how they work!

## Making the ball bounce up and down

Now we're going to get really wild - let's make the ball move in 2 dimensions instead of just 1.

We're going to use the same general approach as last time:

1. Add top and bottom walls
2. Add a `ySpeed` to the ball
3. Move the ball in both `x` and `y` directions on update
4. Handle collisions for both `x` and `y`

First, let's add the walls:

```lua
rightWall = gfx.sprite.addEmptyCollisionSprite(400, 0, 5, 240)
rightWall:add()

topWall = gfx.sprite.addEmptyCollisionSprite(0, -5, 400, 5)
topWall:add()

bottomWall = gfx.sprite.addEmptyCollisionSprite(0, 240, 400, 5)
bottomWall:add()
```

Next, let's add our `ySpeed` and use it:

```lua
function Ball:init()
  Ball.super.init(self)

  self.xSpeed = 5
  self.ySpeed = 6

  -- etc
end

function Ball:update()
  local _, _, collisions, _ = self:moveWithCollisions(self.x + self.xSpeed, self.y + self.ySpeed)

  for i = 1, #collisions do
    if collisions[i].normal.x ~= 0 then
      self.xSpeed *= -1
    end

    if collisions[i].normal.y ~= 0 then
      self.ySpeed *= -1
    end
  end
end
```

Rebuild the game again. Your ball should now be bouncing off of all 4 walls, easy peasy.

### Tidying up

Before we move on - there are a lot of "magic numbers" in our code at this point. Our right wall starts at 400 pixels. Vertical walls are 240 pixels tall. And so on.

But really what we're doing is starting the wall at the right edge of the screen, and making sure it's the same height as the screen. Let's replace those magic numbers with some well-named variables.

```lua
screenWidth = playdate.display.getWidth()
screenHeight = playdate.display.getHeight()

leftWall = gfx.sprite.addEmptyCollisionSprite(-5, 0, 5, screenHeight)
leftWall:add()

rightWall = gfx.sprite.addEmptyCollisionSprite(screenWidth, 0, 5, screenHeight)
rightWall:add()

topWall = gfx.sprite.addEmptyCollisionSprite(0, -5, screenWidth, 5)
topWall:add()

bottomWall = gfx.sprite.addEmptyCollisionSprite(0, screenHeight, screenWidth, 5)
bottomWall:add()
```

You could also change `self:moveTo(200, 120)` to `self:moveTo(screenWidth / 2, screenHeight / 2)` if you are so inclined, but you might want to randomize the starting position later anyway.

## Adding bleeps and bloops

If a tree falls in the forest and no one is around to hear it, does it make a sound?

If a ball bounces off a wall and it doesn't make a sound, is it even a game?

Playdate allows you play back pre-recorded sounds or make simple generated sounds using something called "ADSR":

**Attack** - how fast to go from 0 -> full volume
**Decay** - how fast to go from full volume -> sustain volume
**Sustain** - the volume to hold at until the sound ends
**Release** - how quickly to go from sustain volume -> 0

Here's an image from Wikipedia to help visualize:

![](https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/ADSR_parameter.svg/2560px-ADSR_parameter.svg.png)

We're not going to go deep on this (partially because I'm still learning these things too), but hopefully that's enough to follow along for the rest of the section. At the end of the section, I'll explain how you can use the Playdate Pulp editor to experiment with your own sounds.

For now, our goal is just to play a sound whenever the ball bounces. First, we'll create a new synth instance:

```lua
bounceSound = playdate.sound.synth.new(playdate.sound.kWaveSine)
bounceSound:setADSR(0.1, 0.1, 0.1, 0)
```

Next, we need to actually play this sound on the bounce:

```lua
function Ball:update()
  local _, _, collisions, _ = self:moveWithCollisions(self.x + self.xSpeed, self.y + self.ySpeed)

  for i = 1, #collisions do
    if collisions[i].normal.x ~= 0 then
      -- playNote(pitch, volume, length)
      -- Only pitch is required. Volume defaults to 1, length
      -- defaults to "until you turn it off" :)
      --
      -- Pitch can either be in Hz or the name of a note,
      -- where 440Hz = A4 (the standard orchestral tuning note).
      bounceSound:playNote("G4", 1, 1)
      self.xSpeed *= -1
    end

    if collisions[i].normal.y ~= 0 then
      bounceSound:playNote("G4", 1, 1)
      self.ySpeed *= -1
    end
  end
end
```

There are many different kinds of waveforms we can use here - triangle, square, sawtooth, sine, and more. Each one has a different sound, so feel free to play with the waveforms, ADSR, and notes until you find a sound you like. The sound I picked has a softer, spacier feel, but a sawtooth wave with a shorter attack would sound much sharper.

If you want to play with your own sounds, the [Playdate Pulp](https://play.date/pulp/) editor has a "Sound" section that makes it easy to try things out. You'll need to create an account and login if you don't have one, then click on "Sound" and you should see an editor that looks like this:

<!-- SCREENSHOT HERE -->

The grid in the middle controls the tone, volume, and duration, i.e. the `playNote("G4", 1, 1)` line from above. On the right of the editor, you will see the values from `setADSR` - attack, decay, sustain, and release - and the different types of waves (sine, square, sawtooth, triangle, noise). You can press spacebar to play the sound.

Try adding a note and tweaking it until you find something you like.

## Adding a paddle

Watching the ball bounce is fun and all, but right now this is just a movie with no conflict. Let's add a paddle on the left to make things more interesting.

A few constraints we might want to adopt:

1. Paddles can only move up and down
2. Paddles should not be allowed to move outside the boundaries of the screen
3. Paddles should be a few pixels in from the edge of the screen just for aesthetics

Let's create a new class for our left paddle, similar to `Ball`. By making this a class, we should be able to reuse a lot of the logic for our right paddle when we get there.

```lua
class("Paddle").extends(gfx.sprite)

function Paddle:init()
  -- remember to do this so the parent sprite constructor
  -- can get its bits wired up
  Paddle.super.init(self)

  self.ySpeed = 5

  width = 8
  height = 50
  local paddleImage = gfx.image.new(width, height)
  gfx.pushContext(paddleImage)
  -- (x, y, width, height, corner rounding)
  -- note that we fill at (0,0) rather than (self.x, self.y)
  -- since we are in a new draw context thanks to pushContext
  gfx.fillRoundRect(0, 0, width, height, 2)
  gfx.popContext()
  self:setImage(paddleImage)
  set:setCollideRect(0, 0, self:getSize())

  -- 10 is arbitrary, but looks like a nice little buffer
  self:moveTo(10, screenHeight / 2 - height)
end

paddle = Paddle()
paddle:add()
```

Rebuild your game and you should see a paddle on the left side

Also, bonus! The ball bounces off of the paddle correctly since they are both sprites and we get collisions for free. The ball also plays a bounce sound when it hits the paddle since we made that a property of the ball.

Now that we have a paddle, let's allow it to move. Remember that `gfx.sprite.update()` will call an `update()` function on every sprite that we have called `add()` on to register it. So we can add a `Paddle:update()` function and use that to handle inputs:

```lua
function Paddle:update()
  if playdate.buttonIsPressed(playdate.kButtonDown) then
    self:moveBy(0, self.ySpeed)
  end

  if playdate.buttonIsPressed(playdate.kButtonUp) then
    self:moveBy(0, -self.ySpeed)
  end
end
```

Rebuild the game. You should be able to move your paddle up and down. [Pretty sweet sauce in there, eh Ace?](https://getyarn.io/yarn-clip/88044d50-e660-4605-b921-bf2a87b4d0b8)

## Keeping the paddle on-screen

Our paddle moves, but we have a problem - it can move right off of the screen, with no promise that it will ever return. Let's fix that.

There are a couple ways we could approach this problem:

1. Change to paddle to use `moveWithCollisions` like the ball
2. Prevent the paddle from moving if it would move off-screen

In the first prototype of this game I made, I tried (1) and ran into some quirky physics issues, but it seems like those may have been resolved. We will pursue (1), but know that (2) is a good backup option if you need it. Also if you are seeing unexpected behavior, you might look into [playdate.graphics.sprite:collisionResponse](https://sdk.play.date/1.11.0/Inside%20Playdate.html#c-graphics.sprite.collisionResponse) and try different types of collision responses.

It looks like the default is `freeze`, which means that the sprite will stop moving if it collides with another sprite. That seems okay for our purposes. Even if the ball stops the paddle's movement temporarily, it should bounce away a frame later. We could consider changing the paddle's response later if needed.

Let's update our paddle to `moveWithCollisions` instead of using `moveBy`:

```lua
function Paddle:update()
  if playdate.buttonIsPressed(playdate.kButtonDown) then
    self:moveWithCollisions(self.x, self.y + self.ySpeed)
  end

  if playdate.buttonIsPressed(playdate.kButtonUp) then
    self:moveWithCollisions(self.x, self.y - self.ySpeed)
  end
end
```

Rebuild the game and try moving your paddle around. You should see that it no longer moves off of the top and the bottom of the screen. This is because it is colliding with our invisible walls, the same way that the ball does.

<details>
<summary>If you run into issues with this approach, click here to see how you might tackle (2).</summary>

```lua
-- NOTE: not necessary to make this change, just showing
-- how you could go about it
function Paddle:update()
  if playdate.buttonIsPressed(playdate.kButtonDown) then
    -- when moving down, check if the bottom of the paddle
    -- would move off of the bottom of the screen when
    -- applying the speed
    --
    -- height = 50 and self.y = middle of the paddle
    if self.y + 25 + self.ySpeed < screenHeight then
      self:moveBy(0, self.ySpeed)
    end
  end

  if playdate.buttonIsPressed(playdate.kButtonUp) then
    -- when moving up, check if the top of the paddle
    -- would move off of the top of the screen when
    -- applying the speed
    --
    -- height = 50 and self.y = middle of the paddle
    if self.y - 25 - self.ySpeed > 0 then
      self:moveBy(0, -self.ySpeed)
    end
  end
end
```

Feel free to use this route if you prefer it, although I would recommend changing `height = 50` to `self.height = 50` in the paddle constructor and then using `self.height / 2` instead of the magic number 25 here. :)
</details>
  
## Adding crank controls

Panic went to a lot of trouble to include a crank in the Playdate, and here we are, completely ignoring it, like the hundreds or thousands of hours of engineering effort mean nothing to us.

Let's get our crank on.

The Playdate SDK includes a couple different ways to measure crank inputs:

1. `playdate.getCrankPosition()` - report the absolute position of the crank in degrees from 0 (straight up) to 360 based on clockwise rotation
2. `playdate.getCrankChange()` - report the angle of change in degrees since the last tick

Either one could work for us. If we use `getCrankPosition()`, we'll need to map from 0-180 degrees to a y position. If we use `getCrankChange()`, we can just move the paddle up or down depending on the angle of change.

`getCrankChange()` seems like it will be a tiny bit simpler for this game, so we'll go that direction.

Let's modify our `Paddle:update()` function so that it handles crank changes in addition to up and down on the d-pad:

```lua
function Paddle:update()
  if playdate.buttonIsPressed(playdate.kButtonDown) then
    self:moveWithCollisions(self.x, self.y + self.ySpeed)
  end

  if playdate.buttonIsPressed(playdate.kButtonUp) then
    self:moveWithCollisions(self.x, self.y - self.ySpeed)
  end

  -- returns [change, acceleratedChange], where acceleratedChange
  -- has a multiplier if you are turning the crank really quickly
  local crankChange, _ = playdate.getCrankChange()
  if crankChange ~= 0 then
    self:moveWithCollisions(self.x, self.y + crankChange)
  end
end
```

Rebuild the game. You should be able to control the paddles using the crank wheel in the simulator.

## Adding a second paddle

Part of the goal of creating a paddle class was to make it easy to reuse the behavior. We should be able to add a second paddle pretty easily. The only thing we'll need to do it provide a mechanism for drawing the paddle at a different position on the screen so we don't end up with two directly overlapping paddles.

There are a few ways we could tackle this as well:

1. Pass `xPosition` as an argument to the constructor, i.e. `paddle = Paddle(10)`
2. Pass `side` as an argument to the constructor, i.e. `paddle = Paddle("left")` or `paddle = Paddle("right")`
   - We could also make this constants so we don't have to pass a string, but we can deal with that later

For this tutorial, I'll go with (1) since it's a little simpler, but feel free to explore something like (2) if you would like.

Let's update the `Paddle` constructor to accept and use an `xPosition` argument:

```lua
function Paddle:init(xPosition)
  -- etc

  self:moveTo(xPosition, screenHeight / 2)
end

paddle = Paddle(10)
paddle:add()
```

Rebuild the game. Everything should look the same - that's good! This was a pure refactor, where we made code more extensible without changing any behavior. But this sets us up for easily adding a second paddle.

Let's rename our existing paddle to `leftPaddle` and then add a new `rightPaddle`:

```lua
leftPaddle = Paddle(10)
leftPaddle:add()

rightPaddle = Paddle(screenWidth - 10)
rightPaddle:add()
```

Rebuild the game. You should now see two paddles - one on the left and one on the right. And all it took was 2 lines of code. Classes are pretty sweet.

You'll notice that both paddles move in unison - when you press up, they both move up; when you press down, they both move down. There are a few ways you could make this more interesting, such as having one paddle controlled by AI or by the crank, and so on. Those are outside the scope of this tutorial, but I'm happy to do a follow-up if that is interesting to folks.

## Displaying a score

Next up - let's keep score! Since you're controlling both paddles at the same time right now, you'll have to use your imagination a bit. The good news is that no matter what happens, you're still a winner, just like your parents always said.

Before we actually track the score, let's start by displaying a score at the top of the screen. It will always be `0 : 0` for now, but we'll give ourselves the pieces we need to actually track in the next step.

First, let's add some variables to track the score:

```lua
-- at the top of the file, before the ball class
leftScore = 0
rightScore = 0

class("Ball").extends(gfx.sprite)
```

Then, let's draw the score at the top center of the screen:

```lua
function playdate.update()
  gfx.sprite.update()

  -- drawTextAligned(text, x, y, alignment)
  --
  -- We want to draw at the top-center, so we do
  -- x = screenWidth / 2, then move 5 pixels from the top
  -- for a little buffer.
  --
  -- Note that .. is used for string concatenation in Lua
  gfx.drawTextAligned(leftScore .. " : " .. rightScore, screenWidth / 2, 5, kTextAlignment.center)
end
```

Rebuild the game and you should see `0 : 0` at the top-center of the screen.

### A note on fonts

Curiously, the default Playdate font, Asheville, is not intended to be used as the primary UI font. Here's a note from [Designing for Playdate](https://sdk.play.date/1.11.0/Designing%20for%20Playdate.html#_system_font):

>If our text-drawing APIs aren’t given a font to use, or when they fail to load a font or a character, they will default to the font Asheville 14. This font is specifically meant to communicate to you that something has gone wrong with your text-draw. You should replace Asheville with another font for better legibility.

We're going to keep moving for this tutorial, but you might want to spend more time experimenting with fonts once you complete the tutorial or on your first real game.

## Keeping score

Right now, the ball bounces off of all four walls. We want to keep this behavior for the top and bottom walls, but change it for the left and right walls. If the ball hits the left wall, the right player should score, and vice versa.

As usual, the Playdate SDK is going to help us out a bit here. When sprites collide, we get some information about the `other` sprite we collided with. We can also use a function called `setTag()` on a sprite, then access it later with `getTag()` to figure out what sprite we collided with.

`setTag()` takes an integer, so let's make named constants and then tag our left and right walls with them:

```lua
kLeftWallTag = 1
kRightWallTag = 2

leftWall = gfx.sprite.addEmptyCollisionSprite(-5, 0, 5, screenHeight)
leftWall:setTag(kLeftWallTag)
leftWall:add()

rightWall = gfx.sprite.addEmptyCollisionSprite(screenWidth, 0, 5, screenHeight)
rightWall:setTag(kRightWallTag)
rightWall:add()
```

Next, let's update our collision detection to see if the ball collided with one of these objects:

```lua
function Ball:update()
  local _, _, collisions, _ = self:moveWithCollisions(self.x + self.xSpeed, self.y + self.ySpeed)

  for i = 1, #collisions do
    if collisions[i].other:getTag() == kLeftWallTag then
      rightScore += 1
    elseif collisions[i].other:getTag() == kRightWallTag then
      leftScore += 1
    end

    if collisions[i].normal.x ~= 0 then
      bounceSound:playNote("G4", 1, 0.2)
      self.xSpeed *= -1
    end

    if collisions[i].normal.y ~= 0 then
      bounceSound:playNote("G4", 1, 0.2)
      self.ySpeed *= -1
    end
  end
end
```

Rebuild the game. You should see the scores tick up whenever the left and right walls are hit. More progress!

## Acknowledging the point

We're tracking points now, but the game just keeps going as if nothing happened. To make things more interesting, we want to reset the ball to the center and play a sound when we score.

Resetting the ball should be pretty easy. When we add a point, let's just set the position back to its starting point at the center of the screen:

```lua
function Ball:update()
  local _, _, collisions, _ = self:moveWithCollisions(self.x + self.xSpeed, self.y + self.ySpeed)

  for i = 1, #collisions do
    if collisions[i].other:getTag() == kLeftWallTag then
      rightScore += 1
      -- FYI: You can update the code in init() to this
      -- instead of self:moveTo(200, 120) if you want
      self:moveTo(screenWidth / 2, screenHeight / 2)
      return
    elseif collisions[i].other:getTag() == kRightWallTag then
      leftScore += 1
      self:moveTo(screenWidth / 2, screenHeight / 2)
      return
    end

    if collisions[i].normal.x ~= 0 then
      bounceSound:playNote("G4", 1, 0.2)
      self.xSpeed *= -1
    end

    if collisions[i].normal.y ~= 0 then
      bounceSound:playNote("G4", 1, 0.2)
      self.ySpeed *= -1
    end
  end
end
```

We also `return` after applying the move since we don't want to apply the other collision effects like playing the bounce sound or changing directions right now. (You could make it change directions if you want, though!)

Now it's time to play a sound. We'll continue with the same soundscape for our point sound (`kSineWave`), but make it a little longer since it happens less frequently. We'll also change the tone - since our original note was a `G4`, let's use `C5` for a nice resolution:

```lua
pointSound = playdate.sound.synth.new(playdate.sound.kWaveSine)
pointSound:setADSR(0.25, 0.25, 0.1, 0)

function Ball:update()
  local _, _, collisions, _ = self:moveWithCollisions(self.x + self.xSpeed, self.y + self.ySpeed)

  for i = 1, #collisions do
    if collisions[i].other:getTag() == kLeftWallTag then
      rightScore += 1
      pointSound:playNote("C5", 1, 0.5)
      self:moveTo(screenWidth / 2, screenHeight / 2)
      return
    elseif collisions[i].other:getTag() == kRightWallTag then
      leftScore += 1
      pointSound:playNote("C5", 1, 0.5)
      self:moveTo(screenWidth / 2, screenHeight / 2)
      return
    end

    if collisions[i].normal.x ~= 0 then
      bounceSound:playNote("G4", 1, 0.2)
      self.xSpeed *= -1
    end

    if collisions[i].normal.y ~= 0 then
      bounceSound:playNote("G4", 1, 0.2)
      self.ySpeed *= -1
    end
  end
end
```

Rebuild your game and try it out. You should now see the ball reset and hear a different sound whenever a point is scored.

There's more you could do here if you wanted - playing a "success" sound when the left paddle scores and a "fail" sound when the right paddle scores, reversing the ball direction on each point, and so on. Feel free to try those out!

## Winning the game

Right now, the game continues forever. Even if you walk away until the heat death of the universe, left paddle and right paddle will continue battling for supremacy (assuming that your Playdate is plugged in and the electrical grid has survived that long).

Instead, let's play to 5. You've got a busy life and things to do.

We're going to divide our `playdate.update()` function into two parts:

1. If the game has been won, print a message to the players and accept an input to restart
2. If the game has not been won, show the score and do the normal game loop

NOTE: This is probably the part of the tutorial that I'm most uncertain about at the moment. This definitely works, but it feels clumsy. Let me know if you have ideas for improving this, possibly using something like `playdate.wait()` or `playdate.stop()`.

Let's start by showing some "Game Over" text:

```lua
function isGameOver()
  local winningScore = 5
  return leftScore >= winningScore or rightScore >= winningScore
end

function playdate.update()
  if isGameOver() then
    gfx.drawTextAligned("Good game, pal!", screenWidth / 2, screenHeight / 2, kTextAlignment.center)
  else
    gfx.sprite.update()

    gfx.drawTextAligned(leftScore .. " : " .. rightScore, screenWidth / 2, 5, kTextAlignment.center)
  end
end
```

I made a little helper function called `isGameOver()`. This makes it a little easier to test - I could `return true`, set `winningScore` to 1, and so on. There could also be other game-ending conditions in the future.

Play a game to 5 (or set it to 1 for testing) and you should see that the ball stops moving and our game over message appears. The ball stops moving because we're inside the `if` branch now, so `gfx.sprite.update()` never gets called. We'll fix that momentarily.

## Restarting the game

Right now, you'll see the game over screen forever. Even if you walk away until the heat death of the universe...oh, we did that bit already. Let's keep moving then.

When we're in that `if` branch, the game loop is still running once per frame, but we're not telling it how to handle any inputs. Let's do two things to get our players unstuck:

1. Tell them they can press the Ⓐ button to restart
2. Actually restart the game when they press it

We'll do those both at once:

```lua
function playdate.update()
  if isGameOver() then
    gfx.drawTextAligned("Good game, pal!", screenWidth / 2, screenHeight / 2 - 25, kTextAlignment.center)
    gfx.drawTextAligned("Press Ⓐ to play again", screenWidth / 2, screenHeight / 2, kTextAlignment.center)

    if playdate.buttonIsPressed(playdate.kButtonA) then
      -- this causes isGameOver() to start returning false again
      leftScore = 0
      rightScore = 0
    end
  else
    gfx.sprite.update()

    gfx.drawTextAligned(leftScore .. " : " .. rightScore, screenWidth / 2, 5, kTextAlignment.center)
  end
end
```

Rebuild the game. You should see the new instructions, and pressing Ⓐ should restart the game successfully.

Note that the `25` in `screenHeight / 2 - 25` really is a bit of a magic number. I wanted to draw it on the screen without it overlapping the ball once the ball is reset to the middle. There are other ways you could handle this, such as:

- Not moving the ball back to the center on the final point
- Calling `ball:remove()` when the game ends and adding it back in with `ball:add()` on a restart
- Calling `playdate.clear()` at the beginning of the `if` branch to clear the screen of all sprites before drawing the text

These are all viable choices depending on the game over aesthetic you are going for, but I wanted to keep it simple for now.

## Wrapping Up / Next Steps

This tutorial was a quick, whirlwind intro to making your first Playdate game. We covered a lot of ground - controls, movement, drawing, text, sound effects, collisions, game logic, and more. But there's still plenty more to learn when it comes to making more complex Playdate games.

Here are some other resources we recommend to learn more about making your own Playdate game:

- [Inside Playdate](https://sdk.play.date/)
- [Designing for Playdate](https://sdk.play.date/1.11.0/Designing%20for%20Playdate.html)
- [SquidGodDev's tutorial series](https://www.youtube.com/playlist?list=PLlMPQvEA0GZPp0HQmVadgqgK_Vepxf5H0)
- [Playdate Squad Discord](https://discord.com/invite/zFKagQ2) (unofficial, but some Panic folks hang out in there)

We've been making our own Unlicensed Paddle Game for Playdate, and here are some of the other things we've been diving into:

- Start / menu screens
- Fonts
- Performance tuning
- AI
- Music
- Using events to communicate between objects
- Deeper object-oriented patterns, such as dependency injection, a basic entity component system, and just fewer global variables :)
- Deploying to device
- Distributing on Itch.io

If you are interested in any of these topics or other game-development related topics, here's how to get in touch:

- Message us on Twitter at [@mostlybits](https://twitter.com/mostlybits)
- Sign up for our [weekly newsletter](http://newsletter.mostlybits.co/) where we share interesting finds and fun projects from science, music, games, and more
- Follow us on [Itch.io](https://mostlybits.itch.io/) to stay in the loop on our upcoming games
