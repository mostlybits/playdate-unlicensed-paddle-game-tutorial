import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

gfx = playdate.graphics

class("Ball").extends(gfx.sprite)

function Ball:init()
  Ball.super.init(self)

  self.xSpeed = 5

  radius = 5
  local ballImage = gfx.image.new(2 * radius, 2 * radius)
  gfx.pushContext(ballImage)
  gfx.fillCircleAtPoint(radius, radius, radius)
  gfx.popContext()
  self:setImage(ballImage)

  self:moveTo(200, 120)
end

function Ball:update()
  if self.x + self.xSpeed >= 400 then
    self.xSpeed *= -1
  elseif self.x + self.xSpeed <= 0 then
    self.xSpeed *= -1
  end
  
  self:moveBy(self.xSpeed, 0)
end

ball = Ball()
ball:add()

function playdate.update()
  gfx.sprite.update()
end
