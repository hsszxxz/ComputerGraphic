ShadowMap = 
{
    width = nil,
    height = nil,
    zBuffer = nil,
    Light = nil
}

Vector = require("VectorOperation")
Mat = require("MatrixOperation")
MVPMat = require("MVPTransfer")

function ShadowMap:init()
    self.width = love.graphics.getWidth()
    self.height = love.graphics.getHeight()
    self.zBuffer = {}
    for y = 1, self.height do
        self.zBuffer[y] = {}
        for x = 1, self.width do
            self.zBuffer[y][x] = math.huge -- 初始化为无穷大
        end
    end
end

function ShadowMap:clear()
    for y = 1, self.height do
        for x = 1, self.width do
            self.zBuffer[y][x] = math.huge
        end
    end
end

function ShadowMap:SetzBuffer(x,y,z)
    if x >= 1 and x <= self.width and y >= 1 and y <= self.height then 
        if ShadowMap.zBuffer[y][x] ==nil or z <ShadowMap.zBuffer[y][x]then
            ShadowMap.zBuffer[y][x] = z
        end
    end
end

function ShadowMap:TransferViewToLight(vertex)
   return MVPMat:MVPTranserAccordingToCamera(vertex,self.Light.postion,Vector:new(0,0,0):sub(self.Light.postion),MVPMat.up:mul(1))
end

function ShadowMap: ShadowMapZrenderer(vertext1,vertext2,vertext3)
    local x1,x2,x3 = vertext1.positionInScreen.components[1],vertext2.positionInScreen.components[1],vertext3.positionInScreen.components[1]
    local y1,y2,y3 = vertext1.positionInScreen.components[2],vertext2.positionInScreen.components[2],vertext3.positionInScreen.components[2]
    local z1,z2,z3 = vertext1.positionInScreen.components[3],vertext2.positionInScreen.components[3],vertext3.positionInScreen.components[3]

    local minX = math.floor(math.min(x1,x2,x3))
    local maxX = math.floor(math.max(x1,x2,x3))
    local minY = math.floor(math.min(y1,y2,y3))
    local maxY = math.floor(math.max(y1,y2,y3))

    local function GPoint(x,y)--克莱姆法则求解重心坐标
        local a = ((x-x3)*(y2-y3)-(y-y3)*(x2-x3))/((x1-x3)*(y2-y3)-(y1-y3)*(x2-x3))
        local b = ((x-x1)*(y3-y1)-(y-y1)*(x3-x1))/((x2-x1)*(y3-y1)-(y2-y1)*(x3-x1))
        local c = 1-a-b
        return a,b,c
    end

    for x = minX, maxX do
        for y = minY, maxY do
            local a,b,c = GPoint(x,y)
            if (a>=0 and b>=0 and c>=0) then
                local z = a*z1+b*z2+c*z3
                ShadowMap:SetzBuffer(x,y,z)
            end
        end
    end
end


return ShadowMap
