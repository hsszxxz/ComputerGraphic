--矩阵类
Mat ={}
function Mat:new(data)
    local mat = 
    {
        data = data,
        rowNum = #data,
        colNum = #data[1]
    }
    return setmetatable(mat,{__index = Mat})
end


function Mat:setIdentity()--单位矩阵
    local result ={}
    for i =1,self.rowNum do
        result[i] ={}
        for j =1,self.colNum do
            if i == j then
                result[i][j] = 1
            else
                result[i][j] = 0
            end
        end
    end
    return Mat:new(result)
end

function Mat:transpose()--转置矩阵
    local result ={}
    for i =1,self.colNum do
        result[i] ={}
        for j =1,self.rowNum do
            result[i][j] = self.data[j][i]
        end
    end
    return Mat:new(result)
end

function Mat:mul(mat)--矩阵相乘
    if self.colNum ~= mat.rowNum then
        error("矩阵维度不匹配")
    end
    local result ={}
    for i =1,self.rowNum do
        result[i] ={}
        for j =1,mat.colNum do
            local sum =0;
            for k =1,self.colNum do
                sum = sum + self.data[i][k] * mat.data[k][j]
            end
            result[i][j] = sum
        end
    end
    return Mat:new(result)
end
function Mat:add(mat)--矩阵相加
    local result ={}
    for i =1,self.rowNum do
        result[i] ={}
        for j =1,self.colNum do
            result[i][j] = self.data[i][j] + mat.data[i][j]
        end
    end
    return Mat:new(result)
end
function Mat:sub(mat)--矩阵相减
    local result ={}
    for i =1,self.rowNum do
        result[i] ={}
        for j =1,self.colNum do
            result[i][j] = self.data[i][j] - mat.data[i][j]
        end
    end
    return Mat:new(result)
end
function Mat:mulScalar(scalar)--矩阵数乘
    local result ={}
    for i =1,self.rowNum do
        result[i] ={}
        for j =1,self.colNum do
            result[i][j] = self.data[i][j] * scalar
        end
    end
    return Mat:new(result)
end
function Mat:divScalar(scalar)--矩阵数除
    local result ={}
    for i =1,self.rowNum do
        result[i] ={}
        for j =1,self.colNum do
            result[i][j] = self.data[i][j] / scalar
        end
    end
    return Mat:new(result)
end
function Mat:getMinor (row ,col)--求子矩阵
    local result ={}
    local rowIndex =1
    local colIndex =1
    for i=1, self.rowNum do
        if (i ~= row) then
            result[rowIndex] = {}
            colIndex = 1
            for j=1, self.colNum do
                if (j ~= col) then
                    result[rowIndex][colIndex] = self.data[i][j]
                    colIndex = colIndex + 1
                end
            end
            rowIndex = rowIndex + 1
        end
    end
    return Mat:new(result)
end

function Mat:cofactor(row,col)--计算代数余子式
    local met = self:getMinor(row,col)
    return met:calculateDeterminant()*((row+col-2)%2 == 0 and 1 or -1)
end

function Mat:calculateDeterminant()--计算行列式
    if (self.rowNum ==1 and self.colNum==1) then
        return self.data[1][1]
    end
    --递归
    local result = 0
    for i=self.colNum, 1,-1 do
        result = result + self.data[1][i] *self:cofactor(1,i)
    end
    return result
end

function Mat:adjugate() --计算伴随矩阵
    local result = {}
    for i=1, self.rowNum do
        result[i] = {}
        for j=1, self.colNum do
            result[i][j] = self:cofactor(i,j)
        end
    end
    return Mat:new(result)
end

function Mat:inverse()--计算逆矩阵
    local det = self:calculateDeterminant()
    if (det == 0) then
        error("矩阵不可逆")
    end
    local adj = self:adjugate()
    return adj:divScalar(det)
end

function Mat:threeDRotateX(angleX)
    return Mat:new({
        {1,0,0},
        {0,math.cos(angleX),-math.sin(angleX)},
        {0,math.sin(angleX),math.cos(angleX)}})
end 
function Mat:threeDRotateY(angleY)
    return Mat:new({
        {math.cos(angleY),0,math.sin(angleY)},
        {0,1,0},
        {-math.sin(angleY),0,math.cos(angleY)}})
end
function Mat:threeDRotateZ(angleZ)
    return Mat:new({  
        {math.cos(angleZ),-math.sin(angleZ),0},
        {math.sin(angleZ),math.cos(angleZ),0},
        {0,0,1} })
end
return Mat