local model = {}
function model.new(vertices,normals,texcoords,faces)
    local obj = {
        vertices = vertices,
        normals = normals,
        texcoords = texcoords,
        faces = faces,
    }
    setmetatable(obj,{__index = model})
    return obj
end
function model.loadObj(file)
    local vertices = {}
    local normals = {}
    local texcoords = {}
    local faces = {}
    if not file then
        error("无法打开文件："..file)
    end
    for line in file:lines() do
        --移除首尾空白字符
        line = line:gsub("^[\t\r\n%s]+", ""):gsub("[\t\r\n%s]+$", "")
        if line:match("^[vV]%s") then
            local x,y,z = line:match("v ([%-%d%.]+) ([%-%d%.]+) ([%-%d%.]+)")
            table.insert(vertices,{x=tonumber(x),y=tonumber(y),z=tonumber(z),f=1})
        elseif line:match("^vn%s") then
            local nx,ny,nz = line:match("vn ([%-%d%.]+) ([%-%d%.]+) ([%-%d%.]+)")
            table.insert(normals,{tonumber(nx),tonumber(ny),tonumber(nz)})
            
        elseif line:match("^vt%s") then
            local u,v = line:match("vt ([%-%d%.]+) ([%-%d%.]+)")
            table.insert(texcoords,{tonumber(u),tonumber(v)})

        elseif line:match("^[fF]%s") then
            local face ={}
            for v in line:gmatch("%s+([^%s]+)") do
                local vIdx,vtIdx,vnIdx = v:match("(%d+)/?(%d*)/?(%d*)")
                table.insert(face,{
                    v = tonumber(vIdx),
                    vt =vtIdx ~="" and tonumber(vtIdx) or nil,
                    vn =vnIdx ~="" and tonumber(vnIdx) or nil
                })
            end
            table.insert(faces,face)
        end
    end
    file:close()
    return model.new(vertices,normals,texcoords,faces)
    
end
--MVPMat = require("MVPTransfer")
--local mo = model.loadObj(io.open("Assets/test.obj"))
return model
