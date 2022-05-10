import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

class("Ball").extends(playdate.graphics.sprite)

function Ball:init()
  Ball.super.init(self)

  print("I am a ball")
end

ball = Ball()

function playdate.update()
end
