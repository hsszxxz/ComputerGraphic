Render = require("Renderer")

local function rasterizeTriangleMSAA(x,y,parameter)
    
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
        local a,b,c = parameter.GPoint(sampleX,sampleY)
        if (a>=0 and b>=0 and c>=0) then
            alpha = alpha + 1
        end
    end
    if alpha>0 then
        local acolor = Vector:new({parameter.acolor[1],parameter.acolor[2],parameter.acolor[3],alpha/4})
        return acolor.components
    end
end
local Shader = {vert = nil, fragInit = nil,frag = rasterizeTriangleMSAA}
return Shader