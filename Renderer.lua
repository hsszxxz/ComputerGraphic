Render = {
    width = nil,
    height = nil,
    imageData = nil,
    frameBuffer = nil,
    zBuffer = nil
}

Vector = require("VectorOperation")
Mat = require("MatrixOperation")
Shader = require("Blinn-PhongShading")
MVPMat = require("MVPTransfer")
ShadowMap = require("ShadowMap")

function Render:init()
    self.width = love.graphics.getWidth()
    self.height = love.graphics.getHeight()
    self.imageData = love.image.newImageData(self.width, self.height)
    self.frameBuffer = {}
    self.zBuffer = {}
    for y = 1, self.height do
        self.frameBuffer[y] = {}
        self.zBuffer[y] = {}
        for x = 1, self.width do
            self.frameBuffer[y][x] = {0, 0, 0, 0} -- 初始化为黑色
            self.zBuffer[y][x] = math.huge -- 初始化为负无穷大
        end
    end
    Shader.camera = MVPMat.camera
end

function Render:SetzBuffer(x,y,z,color)
    if x >= 1 and x <= self.width and y >= 1 and y <= self.height then
        if (color[4]~=nil and self.frameBuffer[y][x][4] ~=nil and self.frameBuffer[y][x][4]<color[4]) then 
            self.frameBuffer[y][x][4] = color[4]
        end
        if Render.zBuffer[y][x] ==nil or z <Render.zBuffer[y][x]then
            Render.zBuffer[y][x] = z
            Render:setPixel(x,y,color)
        end
    end
end

function Render:setPixel(x,y,color)
    if (color[4]~=nil and self.frameBuffer[y][x][4] ~=nil and self.frameBuffer[y][x][4]>color[4]) then 
        color[4] = self.frameBuffer[y][x][4]
    end
    self.frameBuffer[y][x] = color
end

function Render:clear()
    for y = 1, self.height do
        for x = 1, self.width do
            self.frameBuffer[y][x] = {0, 0, 0, 0} -- 初始化为黑色
            self.zBuffer[y][x] = math.huge -- 初始化为负无穷大
        end
    end
    isShadow = false
end

function Render:present()
    for y = 1, self.height do
        for x = 1, self.width do
            local color = self.frameBuffer[y][x]
            self.imageData:setPixel(x-1,y-1, color[1], color[2], color[3],color[4])
        end
    end
    local image = love.graphics.newImage(self.imageData)
    love.graphics.draw(image, 0, 0)
end

local function MSAAFunc(x,y,GPoint)
    local samplePoints = {
        {x=0.25, y=0.25},
        {x=0.75, y=0.25},
        {x=0.25, y=0.75},
        {x=0.75, y=0.75}
    }
    local alpha =0
    for i=1, 4 do
        local sampleX = x + samplePoints[i].x
        local sampleY = y + samplePoints[i].y
        local a,b,c = GPoint(sampleX,sampleY)
        if (a>=0 and b>=0 and c>=0) then
            alpha = alpha + 1
        end
    end
    return alpha
end

local function TextureFunc(a,b,c,Ver1uvComponents,Ver2uvComponents,Ver3uvComponents,alpha)
    local acolor
    local u,v = a*Ver1uvComponents[1]+b*Ver2uvComponents[1]+c*Ver3uvComponents[1],
                    a*Ver1uvComponents[2]+b*Ver2uvComponents[2]+c*Ver3uvComponents[2]
    acolor = Texture:GetColor(u,v)
    acolor.components[4] = alpha/4
    return acolor
end

local function ShadowFunc(a,b,c,vertextShadow1,vertextShadow2,vertextShadow3)
    local vertextShadow = vertextShadow1.positionInScreen:mul(a):add(vertextShadow2.positionInScreen:mul(b)):add(vertextShadow3.positionInScreen:mul(c))
    local Lightx = math.floor(vertextShadow.components[1])
    local Lighty =math.floor(vertextShadow.components[2])
    local Lightz = vertextShadow.components[3]
    local ShadowValue = 1
    if (Lightx >=1 and Lightx <= ShadowMap.width and Lighty >=1 and Lighty <= ShadowMap.height) then
        if (ShadowMap.zBuffer[Lighty][Lightx]~=nil and ShadowMap.zBuffer[Lighty][Lightx]+0.5< Lightz) then
            ShadowValue =0.5
        end
    end
    return ShadowValue
end

local function ShadowInit(ver1Prim,ver2Prim,ver3Prim)
    local vertextShadow1 = ShadowMap:TransferViewToLight(ver1Prim)
    local vertextShadow2 = ShadowMap:TransferViewToLight(ver2Prim)
    local vertextShadow3 = ShadowMap:TransferViewToLight(ver3Prim)
    ShadowMap:ShadowMapZrenderer(vertextShadow1,vertextShadow2,vertextShadow3)
    return vertextShadow1,vertextShadow2,vertextShadow3
end

local function BulinFunc(a,b,c,vertext1,vertext2,vertext3,acolor,alpha,Shadow,vertextShadow1,vertextShadow2,vertextShadow3)
    local ShadowValue = 1
    local vertext = vertext1.positionInWorld:mul(a):add(vertext2.positionInWorld:mul(b)):add(vertext3.positionInWorld:mul(c))
    local normal = vertext1.normal:mul(a):add(vertext2.normal:mul(b)):add(vertext3.normal:mul(c)):normalize()
    if (Shadow) then
        ShadowValue = ShadowFunc(a,b,c,vertextShadow1,vertextShadow2,vertextShadow3)
    end
    acolor = Shader:Shading(vertext,normal,acolor)
    acolor = acolor:mul(ShadowValue)
    acolor.components[4] = alpha/4
    return acolor
end

function Render: rasterizeTriangle(vertext1,vertext2,vertext3,color,MSAA,Blinn,texture,Shadow)

    local x1,x2,x3 = vertext1.positionInScreen.components[1],vertext2.positionInScreen.components[1],vertext3.positionInScreen.components[1]
    local y1,y2,y3 = vertext1.positionInScreen.components[2],vertext2.positionInScreen.components[2],vertext3.positionInScreen.components[2]
    local z1,z2,z3 = vertext1.positionInScreen.components[3],vertext2.positionInScreen.components[3],vertext3.positionInScreen.components[3]

    local vertextShadow1
    local vertextShadow2
    local vertextShadow3

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

    if (Shadow) then
        vertextShadow1,vertextShadow2,vertextShadow3 = ShadowInit(vertext1.primVertex,vertext2.primVertex,vertext3.primVertex)
    end
    for x = minX, maxX do
        for y = minY, maxY do
            local alpha = 0
            local a,b,c = GPoint(x,y)
            if (MSAA) then
                alpha =MSAAFunc(x,y,GPoint)
            else
                if (a>=0 and b>=0 and c>=0) then
                    alpha = 4
                end
            end
            if alpha>0 then
                local z = a*z1+b*z2+c*z3
                local acolor
                if (texture) then
                    acolor = TextureFunc(a,b,c,vertext1.uv.components,vertext2.uv.components,vertext3.uv.components,alpha)
                else
                    acolor = Vector:new({color[1],color[2],color[3],alpha/4})
                end
                if Blinn then
                    acolor = BulinFunc(a,b,c,vertext1,vertext2,vertext3,acolor,alpha,Shadow,vertextShadow1,vertextShadow2,vertextShadow3)        
                end
                Render:SetzBuffer(x,y,z,acolor.components)
            end
        end
    end
end

function Render:rasterizeQuad(vertext1,vertext2,vertext3,vertext4,color,MSAA,Blinn,texture,Shadow)
    Render:rasterizeTriangle(vertext1,vertext2,vertext3,color,MSAA,Blinn,texture,Shadow)
    Render:rasterizeTriangle(vertext1,vertext3,vertext4,color,MSAA,Blinn,texture,Shadow)
end

return Render