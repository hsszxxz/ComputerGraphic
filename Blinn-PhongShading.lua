Vector = require("VectorOperation")
MVPTransfer = require("MVPTransfer")
Shader = {}
Shader.Light ={postion = Vector:new(4,4,7),intensity = 30, ambientColor = Vector:new(1,1,1,1)}
Shader.DiffuseCoefficient = 3
Shader.SpecularCoefficient = 5
Shader.AmbientCoefficient = 0.05
Shader.camera = Vector:new(0,0,0)

function Shader:Shading(vertex,normal,color)
    local LightPos = self.Light.postion
    local LightIntensity = self.Light.intensity
    local distance = math.sqrt((vertex.components[1]-LightPos.components[1])^2+(vertex.components[2]-LightPos.components[2])^2+(vertex.components[3]-LightPos.components[3])^2)
    local light = LightPos:sub(vertex):normalize()--从顶点指向光源
    local diffuse =self.DiffuseCoefficient * (LightIntensity/distance^2) *math.max(0,normal:dot(light))

    local view = self.camera:sub(vertex):normalize() --从顶点指向相机
    local h = light:add(view):normalize() --半程向量，角平分线
    local specular =self.SpecularCoefficient * (LightIntensity/distance^2) *(math.max(0,normal:dot(h)))^180

    local ambient = self.AmbientCoefficient * (LightIntensity/distance^2)

    local result = color:mul(diffuse):add(color:mul(specular)):add(self.Light.ambientColor:mul(ambient))
    return result
end

return Shader