import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

gfx = playdate.graphics

screenWidth = playdate.display.getWidth()
screenHeight = playdate.display.getHeight()

bounceSound = playdate.sound.synth.new(playdate.sound.kWaveSine)
bounceSound:setADSR(0.1, 0.1, 0.1, 0)

pointSound = playdate.sound.synth.new(playdate.sound.kWaveSine)
pointSound:setADSR(0.25, 0.25, 0.1, 0)

leftScore = 0
rightScore = 0

kLeftWallTag = 1
kRightWallTag = 2

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
    if collisions[i].other:getTag() == kLeftWallTag then
      rightScore += 1
      self:moveTo(screenWidth / 2, screenHeight / 2)
      pointSound:playNote("C5", 1, 0.5)
      return
    elseif collisions[i].other:getTag() == kRightWallTag then
      leftScore += 1
      self:moveTo(screenWidth / 2, screenHeight / 2)
      pointSound:playNote("C5", 1, 0.5)
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

class("Paddle").extends(gfx.sprite)

function Paddle:init(xPosition)
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
  self:setCollideRect(0, 0, self:getSize())

  self:moveTo(xPosition, screenHeight / 2)
end

function Paddle:update()
  if playdate.buttonIsPressed(playdate.kButtonDown) then
    self:moveWithCollisions(self.x, self.y + self.ySpeed)
  end

  if playdate.buttonIsPressed(playdate.kButtonUp) then
    self:moveWithCollisions(self.x, self.y - self.ySpeed)
  end
end

ball = Ball()
ball:add()

leftPaddle = Paddle(10)
leftPaddle:add()

rightPaddle = Paddle(screenWidth - 10)
rightPaddle:add()

leftWall = gfx.sprite.addEmptyCollisionSprite(-5, 0, 5, screenHeight)
leftWall:setTag(kLeftWallTag)
leftWall:add()

rightWall = gfx.sprite.addEmptyCollisionSprite(screenWidth, 0, 5, screenHeight)
rightWall:setTag(kRightWallTag)
rightWall:add()

topWall = gfx.sprite.addEmptyCollisionSprite(0, -5, screenWidth, 5)
topWall:add()

bottomWall = gfx.sprite.addEmptyCollisionSprite(0, screenHeight, screenWidth, 5)
bottomWall:add()

function playdate.update()
  gfx.sprite.update()
  
  gfx.drawTextAligned(leftScore .. " : " .. rightScore, screenWidth / 2, 5, kTextAlignment.center)
end
