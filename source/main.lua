import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

class("Ball").extends(playdate.graphics.sprite)

function Ball:init()
  Ball.super.init(self)

  radius = 5
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

ball = Ball()
ball:add()

function playdate.update()
  playdate.graphics.sprite.update()
end
