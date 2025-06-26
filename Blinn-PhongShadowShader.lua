Render = require("Renderer")
Vector = require("VectorOperation")
MVPTransfer = require("MVPTransfer")
ShadowMap = require("ShadowMap")

local mode = {}
mode.Light ={postion = Vector:new(4,4,7),intensity = 40, ambientColor = Vector:new(1,1,1,1)}
mode.DiffuseCoefficient = 3
mode.SpecularCoefficient = 5
mode.AmbientCoefficient = 0.05

mode.camera = Vector:new(0,0,0)

local vertextShadow1,vertextShadow2,vertextShadow3

local function ShadowInit()
    
    local ver1Prim =Render.vertexts[1].primVertex
    local ver2Prim =Render.vertexts[2].primVertex
    local ver3Prim =Render.vertexts[3].primVertex 

    mode.camera = MVPTransfer.camera
    ShadowMap.Light = mode.Light

    vertextShadow1 = ShadowMap:TransferViewToLight(ver1Prim)
    vertextShadow2 = ShadowMap:TransferViewToLight(ver2Prim)
    vertextShadow3 = ShadowMap:TransferViewToLight(ver3Prim)
    ShadowMap:ShadowMapZrenderer(vertextShadow1,vertextShadow2,vertextShadow3)
    
end

local function BlinnPhong(x,y,parameter)
    local a,b,c = parameter.GPoint(x,y)
    
    if a<0 or b<0 or c<0 then
        return nil
    end

    local acolor = Vector:new({parameter.acolor[1],parameter.acolor[2],parameter.acolor[3],1})

    local vertext1 = Render.vertexts[1]
    local vertext2 = Render.vertexts[2]
    local vertext3 = Render.vertexts[3]
    local ShadowValue = 1

    local vertext = vertext1.positionInWorld:mul(a):add(vertext2.positionInWorld:mul(b)):add(vertext3.positionInWorld:mul(c))
    local normal = vertext1.normal:mul(a):add(vertext2.normal:mul(b)):add(vertext3.normal:mul(c)):normalize()

    local LightPos = mode.Light.postion
    local LightIntensity = mode.Light.intensity
    local distance = math.sqrt((vertext.components[1]-LightPos.components[1])^2+(vertext.components[2]-LightPos.components[2])^2+(vertext.components[3]-LightPos.components[3])^2)
    local light = LightPos:sub(vertext):normalize()--从顶点指向光源
    local diffuse =mode.DiffuseCoefficient * (LightIntensity/distance^2) *math.max(0,normal:dot(light))

    local view = mode.camera:sub(vertext):normalize() --从顶点指向相机
    local h = light:add(view):normalize() --半程向量，角平分线
    local specular =mode.SpecularCoefficient * (LightIntensity/distance^2) *(math.max(0,normal:dot(h)))^180

    local ambient = mode.AmbientCoefficient * (LightIntensity/distance^2)

    local vertextShadow = vertextShadow1.positionInScreen:mul(a):add(vertextShadow2.positionInScreen:mul(b)):add(vertextShadow3.positionInScreen:mul(c))
    local Lightx = math.floor(vertextShadow.components[1])
    local Lighty =math.floor(vertextShadow.components[2])
    local Lightz = vertextShadow.components[3]

    if (Lightx >=1 and Lightx <= ShadowMap.width and Lighty >=1 and Lighty <= ShadowMap.height) then
        if (ShadowMap.zBuffer[Lighty][Lightx]~=nil and ShadowMap.zBuffer[Lighty][Lightx]+0.5< Lightz) then
            ShadowValue =0.5
        end
    end

    acolor = acolor:mul(diffuse):add(acolor:mul(specular)):add(mode.Light.ambientColor:mul(ambient))
    acolor = acolor:mul(ShadowValue)
    return acolor.components
end
local Shader = {vert = nil, fragInit =ShadowInit,frag = BlinnPhong}
return Shader