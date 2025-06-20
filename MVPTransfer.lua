Vector = require("VectorOperation")
Mat = require("MatrixOperation")
MVPMat = {}
MVPMat.camera=Vector:new(0,0,5); --相机位置
MVPMat.center = Vector:new(0,0,100); --相机方向
MVPMat.up = Vector:new(0,1,0) --相机上方向
MVPMat.width =1080
MVPMat.height =720
MVPMat.scale = 1
MVPMat.roateX = 0
MVPMat.roateY = 0
MVPMat.roateZ = 0

local l = -1
local r = 1
local b = -1
local t = 1
local n = 1
local f = -1

Vertext = {}
function Vertext:new(posInWorld,posInScreen,Normal,UV,PrimVertex)
    local obj = {positionInWorld = posInWorld,positionInScreen = posInScreen,normal = Normal,uv =UV,primVertex = PrimVertex}
    setmetatable(obj,{__index = Vertext})
    return obj
end

local function lookat(eye,center,up)
    local z = center:normalize()
    local x = (up:cross(z)):normalize()
    local y = (z:cross(x)):normalize()
    local Minv = Mat:new({
    {x.components[1],x.components[2],x.components[3],0},
    {y.components[1],y.components[2],y.components[3],0},
    {z.components[1],z.components[2],z.components[3],0},
    {0,0,0,1}})
    local T = Mat:new({
        {1,0,0,-eye.components[1]},
        {0,1,0,-eye.components[2]},
        {0,0,1,-eye.components[3]},
        {0,0,0,1}
    })
    return Minv:mul(T)
end
local function ViewPort()
    local T = Mat: new(
    {
        {MVPMat.width/2*MVPMat.scale,0,0,MVPMat.width/2},
        {0,MVPMat.height/2*MVPMat.scale,0,MVPMat.height/2},
        {0,0,1,0},
        {0,0,0,1}
    })
    return T
end
local function RoateObject(x,y,z)
    local result = Mat:threeDRotateZ(z):mul(Mat:threeDRotateY(y)):mul(Mat:threeDRotateX(x))
    return Mat:new({
        {result.data[1][1],result.data[1][2],result.data[1][3],0},
        {result.data[2][1],result.data[2][2],result.data[2][3],0},
        {result.data[3][1],result.data[3][2],result.data[3][3],0},
        {0,0,0,1}})
end
local function ProjectionNDC(scale)
    local S = Mat:new(
    {
        {2/(r-l),0,0,-(r+l)*scale/2},
        {0,2/(t-b),0,-(t+b)*scale/2},
        {0,0,2/(n-f),-(f+n)*scale/2},
        {0,0,0,scale}
    })
    return S
end
local function PerspectiveProjection()
    local n = n*MVPMat.scale
    local f = f *MVPMat.scale
    local PT = Mat: new(
       {
        {n,0,0,0},
        {0,n,0,0},
        {0,0,n+f,-n*f},
        {0,0,1,0}
       } 
    )
    return PT
end

function MVPMat: MVPTransfer(vertex,normal,uv)
    local resultWolrd =
    lookat(MVPMat.camera,MVPMat.center,MVPMat.up):mul(      --相机变换
    RoateObject(MVPMat.roateX,MVPMat.roateY,MVPMat.roateZ)):
    mul( Mat:new({{vertex.x,vertex.y,vertex.z,vertex.f}}):transpose())
    resultWolrd = resultWolrd:divScalar(resultWolrd.data[4][1])

    local resultScreen = 
    ViewPort():mul(  --视口变换
    --ProjectionNDC(1)):mul(--归一化
    PerspectiveProjection()):mul(
    ProjectionNDC(1)):mul(
    resultWolrd) 

    resultScreen = resultScreen:divScalar(resultScreen.data[4][1])

    local resultVertex = Vertext:new(
        Vector:new(resultWolrd.data[1][1],resultWolrd.data[2][1],resultWolrd.data[3][1]),
        Vector:new(resultScreen.data[1][1],resultScreen.data[2][1],resultScreen.data[3][1]),
        Vector:new(normal),
        Vector:new(uv),
        Vector:new({vertex.x,vertex.y,vertex.z,vertex.f})
    )
    return resultVertex 
end

function MVPMat:MVPTranserAccordingToCamera(vertex,camera,center,up)
    local resultWolrd =
    lookat(camera,center,up):mul(      --相机变换
    RoateObject(MVPMat.roateX,MVPMat.roateY,MVPMat.roateZ)):
    mul( Mat:new({{vertex.components[1],vertex.components[2],vertex.components[3],vertex.components[4]}}):transpose())
    resultWolrd = resultWolrd:divScalar(resultWolrd.data[4][1])

    local resultScreen = 
    ViewPort():mul(  --视口变换
    ProjectionNDC(4*MVPMat.scale)):mul(resultWolrd)--归一化   

    resultScreen = resultScreen:divScalar(resultScreen.data[4][1])

    local resultVertex = Vertext:new(
        Vector:new(resultWolrd.data[1][1],resultWolrd.data[2][1],resultWolrd.data[3][1]),
        Vector:new(resultScreen.data[1][1],resultScreen.data[2][1],resultScreen.data[3][1])
    )
    return resultVertex
end

return MVPMat