-- 向量类
Vector = {}
Mat = require("MatrixOperation")
function Vector:new(...)
    local components = {...}
    if #components == 1 and type(components[1]) == "table" then
        components = components[1]
    end
    local obj = { components = components }
    setmetatable(obj, { __index = Vector })
    return obj
end

-- 向量加法
function Vector:add(other)
    local result = {}
    for i = 1, #self.components do
        result[i] = self.components[i] + other.components[i]
    end
    return Vector:new(result)
end

-- 向量减法
function Vector:sub(other)
    local result = {}
    for i = 1, #self.components do
        result[i] = self.components[i] - other.components[i]
    end
    return Vector:new(result)
end

-- 标量乘法
function Vector:mul(scalar)
    local result = {}
    for i = 1, #self.components do
        result[i] = self.components[i] * scalar
    end
    return Vector:new(result)
end

-- 点积
function Vector:dot(other)
    local sum = 0
    for i = 1, #self.components do
        sum = sum + self.components[i] * other.components[i]
    end
    return sum
end

-- 叉积 (3D向量)
function Vector:cross(other)
    if #self.components ~= 3 then error("Cross product only for 3D vectors") end
    local a, b = self.components, other.components
    return Vector:new(
        a[2]*b[3] - a[3]*b[2],
        a[3]*b[1] - a[1]*b[3],
        a[1]*b[2] - a[2]*b[1]
    )
end

-- 向量长度
function Vector:length()
    return math.sqrt(self:dot(self))
end

-- 单位化
function Vector:normalize()
    local len = self:length()
    if len == 0 then return self end
    return self:mul(1 / len)
end

function Vector:TwoDRotate(angle)
    if (#self.components ~= 2) then error("Rotation only for 2D vectors") end
    local a = self.components
    local cos = math.cos(angle)
    local sin = math.sin(angle)
    return Vector:new(
        a[1]*cos - a[2]*sin,
        a[1]*sin + a[2]*cos 
    )
end

function Vector:ThreeDRotate(angleX,angleY,angleZ)
    if (#self.components ~= 3) then error("Rotation only for 3D vectors") end
    local xMat = Mat:threeDRotateX(angleX)
    local yMat = Mat:threeDRotateY(angleY)
    local zMat = Mat:threeDRotateZ(angleZ)
    local a = self.components
    local result = zMat:mul(yMat):mul(xMat):mul(Mat:new({{a[1]},{a[2]},{a[3]}}))
    return Vector:new({result.data[1][1],result.data[2][1],result.data[3][1]})
end
return Vector