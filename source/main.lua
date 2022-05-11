import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

gfx = playdate.graphics

class("Ball").extends(gfx.sprite)

function Ball:init()
  Ball.super.init(self)

  self.xSpeed = 5
  self.ySpeed = 6

  radius = 5
  local ballImage = gfx.image.new(2 * radius, 2 * radius)
  gfx.pushContext(ballImage)
  gfx.fillCircleAtPoint(radius, radius, radius)
  gfx.popContext()
  self:setImage(ballImage)
  self:setCollideRect(0, 0, self:getSize())

  self:moveTo(200, 120)
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

ball = Ball()
ball:add()

leftWall = gfx.sprite.addEmptyCollisionSprite(-5, 0, 5, 240)
leftWall:add()

rightWall = gfx.sprite.addEmptyCollisionSprite(400, 0, 5, 240)
rightWall:add()

topWall = gfx.sprite.addEmptyCollisionSprite(0, -5, 400, 5)
topWall:add()

bottomWall = gfx.sprite.addEmptyCollisionSprite(0, 240, 400, 5)
bottomWall:add()

function playdate.update()
  gfx.sprite.update()
end
