Render = require("Renderer")

local function rasterizeTriangle(x,y,parameter)
    local a,b,c =parameter.GPoint(x,y)
    if (a>=0 and b>=0 and c>=0) then
        local acolor = Vector:new({parameter.acolor[1],parameter.acolor[2],parameter.acolor[3],1})
        return acolor.components
    end
end
local Shader = {vert = nil, fragInit = nil,frag = rasterizeTriangle}
return Shader
