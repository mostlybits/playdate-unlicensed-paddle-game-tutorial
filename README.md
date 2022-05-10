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

One thing to note - we defined `ballImage` as a `local` variable. Variables in Lua are global by default, which makes them accessible across all files in a project. This can be handy in some cases - for example, maybe our paddle AI will want to take the ball's position into account. But there are usually better ways to organize code without using globals. I won't cover that in-depth in this tutorial, but might do a follow-up around using events to decouple components.

In this case, we don't want to define `ballImage` as a global since nothing outside the sprite constructor should need to access it, so we define it as `local` to limit its scope.

## Tidying up

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
