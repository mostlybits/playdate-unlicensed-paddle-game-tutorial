import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

gfx = playdate.graphics

screenWidth = playdate.display.getWidth()
screenHeight = playdate.display.getHeight()

bounceSound = playdate.sound.synth.new(playdate.sound.kWaveSine)
bounceSound:setADSR(0.1, 0.1, 0.1, 0)

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
      bounceSound:playNote("G4", 1, 0.2)
      self.xSpeed *= -1
    end

    if collisions[i].normal.y ~= 0 then
      bounceSound:playNote("G4", 1, 0.2)
      self.ySpeed *= -1
    end
  end
end

ball = Ball()
ball:add()

leftWall = gfx.sprite.addEmptyCollisionSprite(-5, 0, 5, screenHeight)
leftWall:add()

rightWall = gfx.sprite.addEmptyCollisionSprite(screenWidth, 0, 5, screenHeight)
rightWall:add()

topWall = gfx.sprite.addEmptyCollisionSprite(0, -5, screenWidth, 5)
topWall:add()

bottomWall = gfx.sprite.addEmptyCollisionSprite(0, screenHeight, screenWidth, 5)
bottomWall:add()

function playdate.update()
  gfx.sprite.update()
end
