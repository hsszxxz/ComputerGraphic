Texture ={}
Vector = require("VectorOperation")
function Texture:loadImage (img)
    Texture.img = img
    Texture.width = img:getWidth()
    Texture.height = img:getHeight()
end
function Texture:unloadImage()
    Texture.img = nil
end

local function LerpColor(r1,g1,b1,a1,r2,g2,b2,a2,t)
    local r = r1 + (r2-r1)*t
    local g = g1 + (g2-g1)*t
    local b = b1 + (b2-b1)*t
    local a = a1 + (a2-a1)*t
    return r,g,b,a
end

function Texture: GetColor(u,v)
    local width,height = Texture.width,Texture.height
    local xP =math.min(math.max(u*(width-1),0),width-1)
    local x = math.min(math.max(math.floor(xP),0),width-1)
    local x1 = math.min(x+1,width-1)
    
    local yP =math.min(math.max(v*(height-1),0),height-1)
    local y = math.min(math.max(math.floor(yP),0),height-1)
    local y1 = math.min(y+1,height-1)

    --双线性插值
    local xL = (xP -x)/(x1-x)
    local yL = (yP -y)/(y1-y)

    local r1,g1,b1,a1 = Texture.img:getPixel(x,y)
    local r2,g2,b2,a2 = Texture.img:getPixel(x1,y)
    local r3,g3,b3,a3 = Texture.img:getPixel(x,y1)
    local r4,g4,b4,a4 = Texture.img:getPixel(x1,y1)

    local rx,gx,bx,ax = LerpColor(r1,g1,b1,a1,r2,g2,b2,a2,xL)
    local ry,gy,by,ay = LerpColor(r3,g3,b3,a3,r4,g4,b4,a4,xL)
    local r,g,b,a = LerpColor(rx,gx,bx,ax, ry,gy,by,ay,yL)
    return Vector:new({r,g,b,a})
end
return Texture