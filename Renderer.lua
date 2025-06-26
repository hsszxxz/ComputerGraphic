Render = {
    width = nil,
    height = nil,
    imageData = nil,
    frameBuffer = nil,
    zBuffer = nil,
    shader = nil,
    vertexts = {},
}

Vector = require("VectorOperation")
Mat = require("MatrixOperation")
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
end

function Render:SetShader(shaderName)
    self.shader = require(shaderName)
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

local function TextureFunc(a,b,c,Ver1uvComponents,Ver2uvComponents,Ver3uvComponents,alpha)
    local acolor
    local u,v = a*Ver1uvComponents[1]+b*Ver2uvComponents[1]+c*Ver3uvComponents[1],
                    a*Ver1uvComponents[2]+b*Ver2uvComponents[2]+c*Ver3uvComponents[2]
    acolor = Texture:GetColor(u,v)
    acolor.components[4] = alpha/4
    return acolor
end


function Render:vert(vertexts)
    if self.shader~=nil and self.shader.vert ~= nil then
        vertexts = self.shader.vert(vertexts)
    end
    self.vertexts = vertexts
end

function Render:frag(parameter)
    local vertext1 = self.vertexts[1]
    local vertext2 = self.vertexts[2]
    local vertext3 = self.vertexts[3]

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

    parameter.GPoint=GPoint
    
    if (self.shader~=nil and self.shader.fragInit~=nil) then
        self.shader:fragInit(parameter)
    end

    for x = minX, maxX do
        for y = minY, maxY do
            
            local a,b,c = GPoint(x,y)
            local z = a*z1+b*z2+c*z3

            if require("TextureProcess").img~= nil then
                local acolor = TextureFunc(a,b,c,vertext1.uv.components,vertext2.uv.components,vertext3.uv.components,1)
                parameter.acolor = acolor.components
            end

            local result = nil
            if (self.shader~=nil and self.shader.frag~=nil) then
                result =self.shader.frag(x,y,parameter)
            end

            if result~=nil then
                Render:SetzBuffer(x,y,z,result)
            end

        end
    end
end


return Render