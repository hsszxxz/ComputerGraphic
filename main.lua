local model
Vector = require("VectorOperation")
Mat = require("MatrixOperation")
MVPMat = require("MVPTransfer")
Render = require("Renderer")
Texture = require("TextureProcess")
local prevMouseX, prevMouseY = 0, 0
local isRender = false -- 是否开启光栅化
local isTexture = false --是否使用贴图
local texture;

local hexInput ={
    text = "FFFFFF",
    active = false,
    x=30,y=10,width=60,height=20,
}
local color={1,1,1}

function love.load()
    local objfile = love.filesystem.newFile("Assets/test.obj")
    local font = love.graphics.newFont("Assets/STFANGSO.TTF", 16)
    love.graphics.setFont(font)

    texture = love.image.newImageData("Assets/texture.png")

    model = require("ModelLoad").loadObj(objfile)
    MVPMat.width=love.graphics.getWidth()
    MVPMat.height =love.graphics.getHeight()
    prevMouseX, prevMouseY = love.mouse.getPosition()
    Render:init()
    ShadowMap:init()
end

function love.update()
    local dir = MVPMat.center:normalize()
    if love.keyboard.isDown("w") then
         MVPMat.camera =MVPMat.camera:add(dir:mul(-0.02))
    end
    if love.keyboard.isDown("s") then
        MVPMat.camera =MVPMat.camera:add(dir:mul(0.02))
    end
    if love.keyboard.isDown("a") then
        MVPMat.camera =MVPMat.camera:add(dir:cross(MVPMat.up):normalize():mul(-0.02))
    end
    if love.keyboard.isDown("d") then
        MVPMat.camera =MVPMat.camera:add(dir:cross(MVPMat.up):normalize():mul(0.02))
    end
    if love.mouse.isDown(2) then
        local dx,dy = love.mouse.getPosition()
        MVPMat.center = MVPMat.center:ThreeDRotate(0.005*(prevMouseY-dy),0.005*(dx-prevMouseX),0)
        prevMouseX, prevMouseY = dx, dy
    end
    if love.mouse.isDown(3) then
        local dx,dy = love.mouse.getPosition()
        MVPMat.roateX = MVPMat.roateX + 0.005*(dy-prevMouseY)
        MVPMat.roateY = MVPMat.roateY + 0.005*(prevMouseX-dx)
        prevMouseX, prevMouseY = dx, dy
    end
end

function love.mousepressed(x, y, button)
    if button ==2 or button==3 then
        prevMouseX, prevMouseY = love.mouse.getPosition()
    end
    if button==1 and x>=hexInput.x and x<=hexInput.x+hexInput.width and y>=hexInput.y and y<=hexInput.y+hexInput.height then
        hexInput.active = true
    end
end

local function updateColor()
    if #hexInput.text == 6 then
        local r = tonumber(hexInput.text:sub(1,2),16)/255
        local g = tonumber(hexInput.text:sub(3,4),16)/255
        local b = tonumber(hexInput.text:sub(5,6),16)/255
        color = {r,g,b}
    end
end

function love.keypressed(key)
    if hexInput.active and key=="backspace" then
        hexInput.text = hexInput.text:sub(1,-2)
    end
    if hexInput.active and key=="return" then
        updateColor()
    end
    if key =="e" then
        isRender = not isRender
        Render:SetShader("RasterizeShader")
    end
    if key =="m" then
        Render:SetShader("RasterizeMSAAShader")
    end
    if key =="b" then
        Render:SetShader("Blinn-PhongShader")
    end
    if key =="t" then
        isTexture = not isTexture
        if isTexture then
            Texture:loadImage(texture)
        else
            Texture:unloadImage()
        end
    end
    if key =="f" then
        local objfile = love.filesystem.newFile("Assets/testShadow2.obj")
        model = require("ModelLoad").loadObj(objfile)
        Render:SetShader("Blinn-PhongShadowShader")
    end
end

function love.wheelmoved(x,y)
    MVPMat.scale = MVPMat.scale + y*0.1
    MVPMat.scale = math.max(0.1,MVPMat.scale)
end

local function drawInputBox(inputBox)
    love.graphics.setColor(0.9,0.9,0.9)
    love.graphics.rectangle("fill",inputBox.x,inputBox.y,inputBox.width,inputBox.height)
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("line",inputBox.x,inputBox.y,inputBox.width,inputBox.height)
    if (inputBox.active) then
        love.graphics.setColor(0.7,0.7,1)
        love.graphics.rectangle("line",inputBox.x,inputBox.y,inputBox.width,inputBox.height)
    end
    love.graphics.setColor(0,0,0)
    love.graphics.print(inputBox.text,inputBox.x+3,inputBox.y+2)
end
local function drawTiShi()
    love.graphics.print("WASD:移动",35,40)
    love.graphics.print("鼠标右键:旋转摄像机",35,60)
    love.graphics.print("鼠标中键:旋转目标物体",35,80)
    love.graphics.print("鼠标滚轮:放缩目标物体",35,100)
    love.graphics.print("E:开启/关闭光栅化",35,120)
    love.graphics.print("M:MSAA抗锯齿普通光栅化",35,140)
    love.graphics.print("B:Blinn-Phong模型",35,160)
    love.graphics.print("T:开启/关闭贴图",35,180)
    love.graphics.print("F:有阴影的Blinn-Phong模型",35,200)
end

function love.textinput(t)
    if hexInput.active then
        if #hexInput.text < 6 and string.match(t,"%x") then
            hexInput.text = hexInput.text..t
        end
    end
end

function love.draw()
    drawTiShi()
    drawInputBox(hexInput)
    love.graphics.setColor(color)
    Render:clear()
    for i, face in ipairs(model.faces) do
        local v1, normal1,vt1 = model.vertices[face[1].v],model.normals[face[1].vn],model.texcoords[face[1].vt]
        local v2, normal2,vt2 = model.vertices[face[2].v],model.normals[face[2].vn],model.texcoords[face[2].vt]
        local v3, normal3,vt3 = model.vertices[face[3].v],model.normals[face[3].vn],model.texcoords[face[3].vt]
        local point1Vertex =MVPMat:MVPTransfer(v1,normal1,vt1)
        local point2Vertex =MVPMat:MVPTransfer(v2,normal2,vt2)
        local point3Vertex =MVPMat:MVPTransfer(v3,normal3,vt3)
        if (face[4] ~=nil) then
            local v4,normal4,vt4 = model.vertices[face[4].v],model.normals[face[4].vn],model.texcoords[face[4].vt]
            local point4Vertex =MVPMat:MVPTransfer(v4,normal4,vt4)
            if isRender then
                Render:vert({point1Vertex,point2Vertex,point3Vertex})
                Render:frag({acolor = color})
                Render:vert({point1Vertex,point3Vertex,point4Vertex})
                Render:frag({acolor = color})
            else
                local x1,y1 = point1Vertex.positionInScreen.components[1],point1Vertex.positionInScreen.components[2]
                local x2,y2 = point2Vertex.positionInScreen.components[1],point2Vertex.positionInScreen.components[2]
                local x3,y3 = point3Vertex.positionInScreen.components[1],point3Vertex.positionInScreen.components[2]
                local x4,y4 = point4Vertex.positionInScreen.components[1],point4Vertex.positionInScreen.components[2]
                local quad ={x1,y1,x2,y2,x3,y3,x4,y4}
                love.graphics.polygon("line",quad)
            end
        else
            if (isRender) then
                Render:vert({point1Vertex,point2Vertex,point3Vertex})
                Render:frag({acolor = color})
            end
        end
    end
    if isRender then
        Render:present()
    end
end

