Basic Pong Tutorial - Outline

- Intro
  - Wanted to be a relatively early adopter of the Playdate (got ours last week!)
  - Build something simple to learn the tools
  - Assume people are broadly familiar with programming and able to read SDK docs as needed
  - GIF / video hook
- Disclaimers
  - New to Lua - please correct anything that is wrong
  - Trying out an OO-based approach that Playdate supports, may not scale to more performance-heavy games
- Not using images
- Setup
- Drawing the ball
- Making it move
- Making it collide with walls
- Adding sounds
- Adding paddles
- Moving the paddles
- Tracking the score
  - Mention fonts?
- Winning the game
- Start / restart
- Comments / questions ⭐️
  - Twitter
  - Newsletter
  - GitHub Issues
  - Speculative: Patreon / Discord

Future ideas

- Fonts
- Event system
- Menu screen
- Performance
- ECS / deeper OO patterns
- Deploying to device
  - pdxinfo file
- Distribution

----

## Setup

By the end:
- Playdate SDK installed (delegating to someone else's instructions here)
- Simple build script
- main.lua file with empty update function and basic imports


## Drawing the ball

Now that you can see a blank screen in the simulator, let's make things a bit more interesting with our first sprite. We'll start with the ball.

As I mentioned in the intro, we're going to lean into the basic object-oriented programming (OOP) concepts offered by the Playdate SDK. These aren't strictly necessary and may have performance implications for larger games, but I find that they make code easier to reason about and extend.

Let's go ahead and make a simple `Ball` class in `main.lua` above the `playdate.update` function:

```lua
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
