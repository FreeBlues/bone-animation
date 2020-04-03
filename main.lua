
--# Main
-- BoneMesh
-- 本项目结合 Bones 和 MeshTest 以及 BoneTest 三个项目的代码，使用 mesh 模型作为矩阵变换对象
-- 2020.02.22 需解决无法递归显示各骨骼部件的问题

function setup()
    -- craft scene 初始化
    craftSceneInit()
    objectsInit()
    
    -- 使用 lovntArray 数组中加载好的模型对象初始化 robot
    robot = Robot(objectArray)
    -- 初始化动作数据
    dat = DoActionThread(robot)

    -- 使用 OrbitViewer 组件，设置镜头参数，提供旋转，移动，放大功能
    scene.camera:add(OrbitViewer, vec3(0,0,0),5, 10, 5)
end

-- 把 轴向角(angle,x,y,z)转换为四元数(w,x,y,z)
function axis2quat(a,x,y,z)
    local w = math.cos(math.rad(a)/2)
    local x = math.sin(math.rad(a)/2)*x
    local y = math.sin(math.rad(a)/2)*y
    local z = math.sin(math.rad(a)/2)*z
    return quat(w,x,y,z)
end

function update(dt)
    dat:run()
    scene:update(dt)
end

function draw()
    update(DeltaTime)

    -- 绘制 craft 模型    
    scene:draw()
    -- 绘制坐标轴
    scene.debug:line(vec3(0,0,0),vec3(1,0,0),color(255,0,0,255))  
    scene.debug:line(vec3(0,0,0),vec3(0,1,0),color(0,255,0,255))   
    scene.debug:line(vec3(0,0,0),vec3(0,0,1),color(255,255,0,255))  
    
    -- 准备 mesh 模型的绘制环境参数设置
    perspective()
    -- background()
    
    -- 根据 craft 的镜头参数来设置 mesh 的镜头参数
    local scp = scene.camera.position
    local x,y,z = scp.x, scp.y, scp.z
    camera(x,y,z,0,0,0, 0,1,0)
    
    -- 调用 Robot 类对象的 drawSelf 方法
    robot:drawSelf()   
end

function objectsInit()
    
    -- 只运行一次：创建14个数据文件：Model1.txt ~ Model14.txt
    for k=1,14 do
        -- saveText(asset.."Model"..k..".txt", "")
    end
    
    objectArray = {}   
    objectArray[1] = LoadObject("Documents:body", 1)
    objectArray[2] = LoadObject("Documents:body", 2)  
    objectArray[3] = LoadObject("Documents:head", 3)   
    objectArray[4] = LoadObject("Documents:left_top",4)   
    objectArray[5] = LoadObject("Documents:left_bottom",5)   
    objectArray[6] = LoadObject("Documents:right_top",6)   
    objectArray[7] = LoadObject("Documents:right_bottom",7)   
    objectArray[8] = LoadObject("Documents:right_leg_top",8)   
    objectArray[9] = LoadObject("Documents:right_leg_bottom",9)   
    objectArray[10] = LoadObject("Documents:left_leg_top",10)   
    objectArray[11] = LoadObject("Documents:left_leg_bottom",11)   
    objectArray[12] = LoadObject("Documents:left_foot", 12)   
    objectArray[13] = LoadObject("Documents:right_foot", 13) 
    
    floor = LoadObject("Documents:floor", 14)
end

function craftSceneInit()
    -- Create a new craft scene
    scene = craft.scene()
    
    -- 设置使用天空盒
    local sunny = readText(asset.builtin.Environments.Night)
    local env = craft.cubeTexture(json.decode(sunny))
    scene.sky.material.envMap = env
    scene.sky.eulerAngles = vec3(0,180,0)
    scene.camera.z = -10
    scene.camera.eulerAngles = vec3(0,0,0)
    scene.camera.position = vec3(0,0,0)
    
    -- 设置场景的一些基本参数
    -- scene.sun.active = false
    -- scene.sky.active = false
    -- Move the main camera
    scene.camera.position = vec3(0, -10, -10)
    
    -- 场景本身光照
    scene.sun:get(craft.light).intensity = 0.8
    scene.sun.position = vec3(0, -10, 0)
    scene.sun.rotation = quat.eulerAngles(45,0,45)
    scene.ambientColor = color(88, 107, 222, 255)
end



--# Robot
Robot = class()

function Robot:init(objectArray)   
    self.lowest = math.huge
    self.lowestForDraw = {}
    self.lowestForDrawTemp = {}
    
    self.bRoot = BodyPart(0,0,0,objectArray[1],1,self)
    self.bBody = BodyPart(0,0.938,0,objectArray[2],2,self)
    self.bHead = BodyPart(0,1,0,objectArray[3],3,self)
    
    self.bLeftTop = BodyPart(0.107,0.938,0,objectArray[4],4,self)
    self.bLeftBottom = BodyPart(0.105,0.707,-0.033,objectArray[5],5,self)
    self.bRightTop = BodyPart(-0.107,0.938,0,objectArray[6],6,self)
    self.bRightBottom = BodyPart(-0.105,0.707,-0.033,objectArray[7],7,self)
    
    self.bRightLegTop = BodyPart(-0.068,0.6,0.02,objectArray[8],8,self)
    self.bRightLegBottom = BodyPart(-0.056,0.312,0,objectArray[9],9,self)
    self.bLeftLegTop = BodyPart(0.068,0.6,0.02,objectArray[10],10,self)
    self.bLeftLegBottom = BodyPart(0.056,0.312,0,objectArray[11],11,self)
    
    local leftFootLowest = {{0.068,0.0,0.113},{0.068,0,-0.053}}
    local rightFootLowest = {{-0.068,0.0,0.113},{-0.068,0,-0.053}}
    self.bLeftFoot = BodyPart(0.068,0.038,0.033,objectArray[12],12,self,true,leftFootLowest)
    self.bRightFoot = BodyPart(-0.068,0.038,0.033,objectArray[13],13,self,true,rightFootLowest)
    print("robot ",self.bRightFoot.lowestDots[1][1])
    self.bpArray = {}
    self.bpArray[1] = self.bRoot 
    self.bpArray[2] = self.bBody
    self.bpArray[3] = self.bHead
    self.bpArray[4] = self.bLeftTop
    self.bpArray[5] = self.bLeftBottom
    self.bpArray[6] = self.bRightTop
    self.bpArray[7] = self.bRightBottom
    self.bpArray[8] = self.bRightLegTop
    self.bpArray[9] = self.bRightLegBottom 
    self.bpArray[10] = self.bLeftLegTop 
    self.bpArray[11] = self.bLeftLegBottom 
    self.bpArray[12] = self.bLeftFoot 
    self.bpArray[13] = self.bRightFoot
    
    -- 建立各部件的层次结构
    self.bRoot:addChild(self.bBody) 
      
    self.bBody:addChild(self.bHead)
    self.bBody:addChild(self.bLeftTop)
    self.bBody:addChild(self.bRightTop)
    self.bBody:addChild(self.bLeftLegTop)         
    self.bBody:addChild(self.bRightLegTop)
    
    self.bLeftTop:addChild(self.bLeftBottom)

    self.bRightTop:addChild(self.bRightBottom)

    self.bRightLegTop:addChild(self.bRightLegBottom)
    self.bLeftLegTop:addChild(self.bLeftLegBottom)
    
    self.bLeftLegBottom:addChild(self.bLeftFoot)
    self.bRightLegBottom:addChild(self.bRightFoot)
    
    self.finalMatrixForDrawArray = {matrix()}
    self.finalMatrixForDrawArrayTemp = {matrix()}   
    for i=1,#self.bpArray,1 do
        self.finalMatrixForDrawArray[i] = matrix()
        self.finalMatrixForDrawArrayTemp[i] = matrix()             
    end
    
    -- 级联计算每个子骨骼在父骨骼坐标系中的原始坐标，并且将平移信息记录进矩阵
    self.bRoot:initFatherMatrix()
    -- 层次级联更新骨骼矩阵的方法真实的平移信息，相对于世界坐标系
    self.bRoot:updateBone()
    -- 层次级联计算子骨骼初始情况下在世界坐标系中的变换矩阵的逆矩阵
    self.bRoot:CalMWorldInitInver()
end

function Robot:calLowest()
		self.lowest=math.huge
		self.bRoot:calLowest()
end

function Robot:updateState()
    self.bRoot:updateBone()    
end

function Robot:backToInit()
    self.bRoot:backToInit()
end

function Robot:flushDrawData()
    for k,bp in ipairs(self.bpArray) do
        bp:copyMatrixForDraw()
    end
    self.lowestForDraw = self.lowest
end

function Robot:drawSelf()
    -- 生成各部位的最终用变换矩阵 modelMatrix
    for i=1,#self.bpArray do
        for j=1,16 do
        self.finalMatrixForDrawArrayTemp[i][j] = self.finalMatrixForDrawArray[i][j]            
        end
    end
    
    self.lowestForDrawTemp=self.lowestForDraw;
    modelMatrix(modelMatrix():translate(0, -self.lowestForDrawTemp, 0))

    -- 使用 BodyPart 的 drawSelf 方法，从根骨骼部件开始绘制
    self.bRoot:drawSelf(self.finalMatrixForDrawArrayTemp)
    -- popMatrix()
end

--# BodyPart
BodyPart = class()

-- 当前存在两个问题：1 BodyPart:drawSelf() 中矩阵的设置错误；2 Robot:drawSelf() 中只绘制了 bRoot，没有循环绘制它的 child 节点
-- 新问题：矩阵参数如何传递到 lovnt:drawSelf()

function BodyPart:init(fx,fy,fz,lovnt,index,robot,lowestFlag,lowestDots)
    self.index = index
    self.object = lovnt
    self.object.e.position = vec3(fx,fy,fz)
    self.object.e.active = true
    self.fx = fx
    self.fy = fy
    self.fz = fz
    self.robot = robot
    self.father = nil
    self.mFather = matrix()
    self.mWorld = matrix()
    self.mFatherInit = matrix()
    self.mWorldInitInver = matrix()
    self.finalMatrix = matrix()
    self.lowestFlag = lowestFlag
    self.lowestDots = lowestDots    
    self.childs = {}
    -- bRoot 不显示
    if self.index == 1 then self.object.e.active = false end
end

function BodyPart:calLowest()
    if self.lowestFlag == true then
        -- print("ll ",self.lowestDots[1][1])           
        for k,p in ipairs(self.lowestDots) do
            -- print("p ",p[1])
            local pqc=vec4(p[1],p[2],p[3],1);--该点的初始坐标
            local resultP=vec4(0,0,0,1); --用于存储变化后的点的坐标
            local resultP = self.finalMatrix * pqc

            if resultP[2]<self.robot.lowest then
                -- 如果该点y坐标小于当前模型最低点y坐标
                -- print("low ", self.robot.lowest)
                self.robot.lowest = resultP[2]; --更新机器人模型的最低点y坐标
            end
        end
    end
    for k,bc in ipairs(self.childs) do
        bc:calLowest()
    end
end

function BodyPart:copyMatrixForDraw()
    for i=1,16,1 do
        self.robot.finalMatrixForDrawArray[self.index][i] = self.finalMatrix[i]
    end
end

function BodyPart:drawSelf(tempMatrixArray)
    -- 若加载模型存在，则绘制：1 其本身节点，2 其所有子节点
    if self.object ~= nil and self.index~=1 then
        pushMatrix()
        -- 这里更新用于 mesh 的矩阵运动数据 === 需要修改
        -- print("m1 ",modelMatrix())
        modelMatrix(tempMatrixArray[self.index])
        -- print("m2 ",modelMatrix())
        -- 绘制 loadObjVerNorTex 模型：包括 craft 和 mesh
        self.object:drawSelf()
        popMatrix()
    end
    for k,bc in ipairs(self.childs) do
        bc:drawSelf(tempMatrixArray) 
    end 
end

function BodyPart:initFatherMatrix()
    local tx,ty,tz = self.fx,self.fy,self.fz
    if self.father ~= nil then
        tx = self.fx - self.father.fx
        ty = self.fy - self.father.fy
        tz = self.fz - self.father.fz
    end

    -- 计算各骨骼模型其父骨骼空间的变换矩阵
    self.mFather = matrix()
    self.mFather = self.mFather:translate(tx,ty,tz)
    for i=1,16,1 do
        self.mFatherInit[i] = self.mFather[i]
    end

    -- 更新所有子节点
    for k,bc in ipairs(self.childs) do
        bc:initFatherMatrix()
    end
end

function BodyPart:CalMWorldInitInver()
    -- 对 self.mWorld 求逆
    self.mWorldInitInver = self.mWorld:inverse()
    -- 更新所有子节点    
    for k,bc in ipairs(self.childs) do
        bc:CalMWorldInitInver()     
    end
end

function BodyPart:updateBone()
    if self.father ~= nil then
        -- Codea 使用列矩阵，矩阵要左乘
        self.mWorld = self.mFather * self.father.mWorld
        -- self.robot.bpArray[self.index].object.e.position = self.mWorld *self.robot.bpArray[self.index].object.e.position 
    else
        for i=1,16,1 do
            self.mWorld[i] = self.mFather[i]
        end
    end
    
    -- 计算每个骨骼部件的最终变换矩阵
    self:calFinalMatrix()
    -- 更新所有子节点   
    for k,bc in ipairs(self.childs) do
        bc:updateBone()
    end     
end

-- 计算得到最终的变换矩阵
function BodyPart:calFinalMatrix()
    -- Codea 使用列矩阵，矩阵要左乘
    self.finalMatrix = self.mWorldInitInver * self.mWorld
end

function BodyPart:backToInit()
    for i=1,16,1 do
        self.mFather[i] = self.mFatherInit[i]
    end
    
    -- 更新所有子节点    
    for k,bc in ipairs(self.childs) do
        bc:backToInit()
    end             
end

function BodyPart:translate(x,y,z)
    -- mesh 模型根据 DoActionThread 中的平移数据实时进行设置
    self.mFather = self.mFather:translate(x,y,z)
    
    -- craft 模型根据 DoActionThread 中的平移数据实时进行设置
    -- 分析这两种写法的区别
    -- self.lovnt.e.position = m * self.lovnt.e.position
    self.robot.bpArray[self.index].object.e.position = vec3(x,y,z)
end

function BodyPart:rotate(a,x,y,z)
    -- mesh 模型根据 DoActionThread 中的旋转数据实时进行设置
    self.mFather = self.mFather:rotate(a,x,y,z)

    -- craft 模型根据 DoActionThread 中的旋转数据实时进行设置
    local q = axis2quat(a,x,y,z)
    self.robot.bpArray[self.index].object.e.rotation = q
end

-- 添加子骨骼
function BodyPart:addChild(child)
    table.insert(self.childs, child)
    -- self.childs[#self.childs+1] = child
    child.father = self
end



--# LoadObject
LoadObject = class()

function LoadObject:init(objPath,id)

    self.e = scene:entity()
    -- self.e.position = vec3(0,0,0)
    -- self.e.scale = vec3(10,10,10)
    self.e.model = craft.model(objPath)
    self.e.material = craft.material(asset.builtin.Materials.Standard)
    -- self.e.material.map = readImage("Dropbox:face1")
    self.e.active = true
    self.id = id
    self.m = self:model2mesh(self.e.model, self.id)
    -- self.m.vertices = self.e.model.positions
    -- self.m.texCoords = self.e.model.uvs
    -- self.m.normals = self.e.model.normals
    -- self.m.colors = self.e.colors

    self.m:setColors(255,255,255,255)
    self.m.texture = readImage(asset.builtin.Blocks.Ice)
    ---[[ 使用OpenGLES3.0 教程中9_1 的 shader
    self.m.shader = shader(s.v3,s.f3)
    -- m.shader = shader(s.v2,s.f2)
    self.m.shader.modelMatrix = matrix()
    self.m.shader.viewMatrix = matrix()
    self.m.shader.projectionMatrix = matrix()    

    -- m.shader.modelMatrix=m.shader.modelMatrix:rotate(50, 	0,	1, 	0)
    self.m.shader.uCamera = vec3(0,5,1)
    self.m.shader.uLightLocation = vec3(100,103,103)
    self.m.shader.sTexture = self.m.texture    
end

function LoadObject:model2mesh(model,id)
    local m = mesh()
    local indices = model.indices    
    local vb = m:buffer("position")
    local tb = m:buffer("texCoord")
    local nb = m:buffer("normal")
    local cb = m:buffer("color")
    local vt,tt,nt,ct = {{}},{{}},{{}},{{}}
    vb:resize(#indices)
    tb:resize(#indices)
    nb:resize(#indices)
    cb:resize(#indices)

    -- 根据部件 id 读取对应模型数据文件    
    local str = readText(asset.."Model"..id..".txt")
    
    -- 若首次执行数据文件为空串，则写入数据文件
    if str == "" then       
        for k=1,#indices do
            vb[k] = model.positions[model.indices[k]]
            tb[k] = model.uvs[model.indices[k]]
            nb[k] = model.normals[model.indices[k]]
            cb[k] = model.colors[model.indices[k]]
            -- 把vec3，vec2 用户数据类型元素分解转换为普通表元素
            vt[k] = {vb[k].x, vb[k].y, vb[k].z}
            tt[k] = {tb[k].x, tb[k].y}
            nt[k] = {nb[k].x, nb[k].y, nb[k].z}
            ct[k] = {cb[k].x, cb[k].y, cb[k].z}
        end
        local modelString = json.encode({vt,tt,nt,ct})
        saveText(asset.."Model"..id..".txt", modelString)
    else
        local t = json.decode(str)   
        vt,tt,nt,ct = t[1], t[2], t[3], t[4]              
        print("t ", #t[3][2], t[1][1][1])
        -- 重组
        for k = 1,#vt do
            vb[k] = vec3(vt[k][1], vt[k][2], vt[k][3])
            tb[k] = vec2(tt[k][1], tt[k][2])
            nb[k] = vec3(nt[k][1], nt[k][2], nt[k][3])
            cb[k] = vec3(ct[k][1], ct[k][2], ct[k][3])
        end        
    end    
    
    print("indices: ", #indices, type(id), id)
    return m
end


function LoadObject:update(dt)

end

function LoadObject:drawSelf()    
    -- 绘制 mesh 模型
    self.m:draw()    
end

s = {
v3 =[[#version 300 es
uniform mat4 modelViewProjection; //总变换矩阵
uniform mat4 modelMatrix; //变换矩阵
uniform mat4 viewMatrix; //变换矩阵
uniform mat4 projectionMatrix; //变换矩阵
uniform vec3 uLightLocation;	//光源位置
uniform vec3 uCamera;	//摄像机位置
in vec3 position;  //顶点位置
in vec3 normal;    //顶点法向量
in vec2 texCoord;    //顶点纹理坐标
//用于传递给片元着色器的变量
out vec4 ambient;
out vec4 diffuse;
out vec4 specular;
out vec2 vTextureCoord;  
//定位光光照计算的方法
void pointLight(					//定位光光照计算的方法
  in vec3 iNormal,				//法向量
  inout vec4 ambient,			//环境光最终强度
  inout vec4 diffuse,				//散射光最终强度
  inout vec4 specular,			//镜面光最终强度
  in vec3 lightLocation,			//光源位置
  in vec4 lightAmbient,			//环境光强度
  in vec4 lightDiffuse,			//散射光强度
  in vec4 lightSpecular			//镜面光强度
){
  ambient=lightAmbient;			//直接得出环境光的最终强度  
  vec3 normalTarget=position+iNormal;	//计算变换后的法向量
  vec3 newNormal=(modelMatrix*vec4(normalTarget,1)).xyz-(modelMatrix*vec4(position,1)).xyz;
  newNormal=normalize(newNormal); 	//对法向量规格化
  //计算从表面点到摄像机的向量
  vec3 eye= normalize(uCamera-(modelMatrix*vec4(position,1)).xyz);  
  //计算从表面点到光源位置的向量vp
  vec3 vp= normalize(lightLocation-(modelMatrix*vec4(position,1)).xyz);  
  vp=normalize(vp);//格式化vp
  vec3 halfVector=normalize(vp+eye);	//求视线与光线的半向量    
  float shininess=30.0;			//粗糙度，越小越光滑
  float nDotViewPosition=max(0.0,dot(newNormal,vp)); 	//求法向量与vp的点积与0的最大值

  diffuse = lightDiffuse*nDotViewPosition;				//计算散射光的最终强度
  float nDotViewHalfVector=dot(newNormal,halfVector);	//法线与半向量的点积 
  float powerFactor=max(0.0,pow(nDotViewHalfVector,shininess)); 	//镜面反射光强度因子
  specular=lightSpecular*powerFactor;    			//计算镜面光的最终强度
}


void main()     
{ 
// mat4 modelViewProject = projectionMatrix*(viewMatrix* modelMatrix);
    gl_Position = modelViewProjection * vec4(position,1); //根据总变换矩阵计算此次绘制此顶点位置  

   // 存放环境光、散射光、镜面反射光的临时变量      
   vec4 ambientTemp, diffuseTemp, specularTemp;   
    pointLight(normalize(normal),ambientTemp,diffuseTemp,specularTemp,uLightLocation,vec4(0.15,0.15,0.15,1.0),vec4(0.59,0.59,0.59,1.0),vec4(0.4,0.4,0.4,1.0));
   
   ambient=ambientTemp;
   diffuse=diffuseTemp;
   specular=specularTemp;
   vTextureCoord = texCoord;//将接收的纹理坐标传递给片元着色器
}      
]],

f3 = [[#version 300 es 
precision mediump float;
uniform sampler2D sTexture;//纹理内容数据
//接收从顶点着色器过来的参数
in vec4 ambient;
in vec4 diffuse;
in vec4 specular;
in vec2 vTextureCoord;
out vec4 fragColor;

void main()                         
{    
   //将计算出的颜色给此片元
   vec4 finalColor=texture(sTexture, vTextureCoord);    
   //给此片元颜色值
   fragColor = finalColor*ambient+finalColor*specular+finalColor*diffuse;

}   
]],

v51 = [[#version 300 es
//真正带光照绘制的顶点着色器
uniform mat4 uMVPMatrix; //总变换矩阵
uniform mat4 uMMatrix; //变换矩阵
uniform vec3 uLightLocation;	//光源位置
uniform vec3 uCamera;	//摄像机位置
in vec3 aPosition;  //顶点位置
in vec3 aNormal;    //顶点法向量
//用于传递给片元着色器的变量
out vec4 ambient;
out vec4 diffuse;
out vec4 specular;
out vec4 vPosition;
 
void pointLight(				//定位光光照计算的方法
  in vec3 normal,				//法向量
  inout vec4 ambient,			//环境光最终强度
  inout vec4 diffuse,			//散射光最终强度
  inout vec4 specular,			//镜面光最终强度
  in vec3 lightLocation,		//光源位置
  in vec4 lightAmbient,			//环境光强度
  in vec4 lightDiffuse,			//散射光强度
  in vec4 lightSpecular			//镜面光强度
){
  ambient=lightAmbient;			//直接得出环境光的最终强度  
  vec3 normalTarget=aPosition+normal;	//计算变换后的法向量
  vec3 newNormal=(uMMatrix*vec4(normalTarget,1)).xyz-(uMMatrix*vec4(aPosition,1)).xyz;
  newNormal=normalize(newNormal); 	//对法向量规格化
  //计算从表面点到摄像机的向量
  vec3 eye= normalize(uCamera-(uMMatrix*vec4(aPosition,1)).xyz);  
  //计算从表面点到光源位置的向量vp
  vec3 vp= normalize(lightLocation-(uMMatrix*vec4(aPosition,1)).xyz);  
  vp=normalize(vp);//格式化vp
  vec3 halfVector=normalize(vp+eye);//求视线与光线的半向量    
  float shininess=50.0;				//粗糙度，越小越光滑
  float nDotViewPosition=max(0.0,dot(newNormal,vp)); 	//求法向量与vp的点积与0的最大值
  diffuse=lightDiffuse*nDotViewPosition;				//计算散射光的最终强度
  float nDotViewHalfVector=dot(newNormal,halfVector);	//法线与半向量的点积 
  float powerFactor=max(0.0,pow(nDotViewHalfVector,shininess));//镜面反射光强度因子
  specular=lightSpecular*powerFactor;//计算镜面光的最终强度
}

void main()     
{ 
   gl_Position = uMVPMatrix*vec4(aPosition,1); //根据总变换矩阵计算此次绘制此顶点位置  
   pointLight(normalize(aNormal),ambient,diffuse,specular,uLightLocation,vec4(0.1,0.1,0.1,1.0),vec4(0.7,0.7,0.7,1.0),vec4(0.3,0.3,0.3,1.0));
   vPosition=uMMatrix*vec4(aPosition,1);
} 
]],

f51 = [[#version 300 es
precision mediump float;			//设置默认精度
uniform sampler2D sTexture;		//纹理内容数据
in vec4 ambient;				//接收从顶点着色器传递过来的环境光参数
in vec4 diffuse;					//接收从顶点着色器传递过来的散射光参数
in vec4 specular;				//接收从顶点着色器传递过来的镜面光参数
in vec4 vPosition;  				//接收从顶点着色器传递过来的片元位置
out vec4 fragColor;
uniform highp mat4 uMVPMatrixGY; //光源位置处虚拟摄像机观察及投影组合矩阵
void main(){
   //将片元的位置投影到光源处虚拟摄像机的近平面上
   vec4 gytyPosition=uMVPMatrixGY * vec4(vPosition.xyz,1);
   gytyPosition=gytyPosition/gytyPosition.w;	//进行透视除法
   float s=gytyPosition.s+0.5;				//将投影后的坐标换算为纹理坐标
   float t=gytyPosition.t+0.5;
   vec4 finalColor=vec4(0.8,0.8,0.8,1.0); 		//物体本身的颜色
   if(s>=0.0&&s<=1.0&&t>=0.0&&t<=1.0){	//若纹理坐标在合法范围内则考虑投影贴图
   vec4 projColor=texture(sTexture,vec2(s,t));	//对投影纹理图进行采样
   vec4 specularTemp=projColor*specular;	//计算投影贴图对镜面光的影响
   vec4 diffuseTemp=projColor*diffuse;		//计算投影贴图对散射光的影响
   fragColor=finalColor*ambient+finalColor*specularTemp+finalColor*diffuseTemp;//计算最终片元颜色
   }else {//计算最终片元颜色
       fragColor = finalColor*ambient+finalColor*specular+finalColor*diffuse;
    }
}]],}



--# DoActionThread
DoActionThread = class()

function DoActionThread:init(robot)
    self.currActionIndex = 1
    self.currStep = 1
    self.robot = robot
    self.actionGenerator = ActionGenerator()
    self.currAction = self.actionGenerator.acArray[self.currActionIndex]
end

-- 需要把 run 放在 draw 或 update 中循环执行，生成动作之间的插值数据
function DoActionThread:run()

    self.robot:backToInit()
    if self.currStep >= self.currAction.totalStep then
        self.currActionIndex =  (self.currActionIndex+1)%(#self.actionGenerator.acArray)
        self.currAction = self.actionGenerator.acArray[self.currActionIndex+1]
        self.currStep = 1
    end

    for k,ad in ipairs(self.currAction.data) do
        -- 插值计算中间帧的平移，旋转坐标数据
        local partIndex, aType = ad[1],ad[2]
        local frameStep = self.currStep/self.currAction.totalStep
        if aType == 0 then
            local xStart,yStart,zStart = ad[3],ad[4],ad[5]
            local xEnd,yEnd,zEnd = ad[6],ad[7],ad[8]
            local currX = xStart+(xEnd-xStart)* frameStep
            local currY = yStart+(yEnd-yStart)* frameStep
            local currZ = zStart+(zEnd-zStart)* frameStep
            self.robot.bpArray[partIndex]:translate(currX,currY,currZ)
        elseif aType == 1 then
            local startAngle,endAngle = ad[3],ad[4]
            local currAngle = startAngle+(endAngle-startAngle)* frameStep
            local x,y,z = ad[5],ad[6],ad[7]
            self.robot.bpArray[partIndex]:rotate(currAngle,x,y,z)
        end
    end
    self.robot:updateState()
    self.robot:calLowest()
    self.robot:flushDrawData()
    self.currStep = self.currStep+1
end



--# ActionGenerator
ActionGenerator = class()

function ActionGenerator:init()
    self.count = 20
    self.acArray = {}
    self.acArray[1] = Action()
    self.acArray[2] = Action()
    self.acArray[3] = Action()
    self.acArray[4] = Action()
    local i = 1  
    
    self.acArray[1].totalStep = self.count
    self.acArray[1].data = {
    --{body编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {1+i,0,0,0,0,0,0,0},
    --{body编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {1+i,1,10,10,1,0,0},
    --{leftTop编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {3+i,1,-70,0,0.948,0,0.316},
    --{rightTop编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {5+i,1,-70,0,-0.948,0,0.316},
    --{leftTopDown编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值  旋转轴向量XYZ}
    {4+i,1,-80,-80,0.948,0,0.316},
    --{rightTopDown编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值  旋转轴向量XYZ}
    {6+i,1,80,80,-0.948,0,0.316},
    --{右大腿编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {7+i,1,-50,0,1,0,0},
    --{左大腿编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {9+i,1,20,0,1,0,0},
    --{左小腿编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {10+i,1,0,90,1,0,0},
    --{左脚编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值, 旋转轴向量XYZ}
    {11+i,1,10,0,1,0,0},}
    
    self.acArray[2].totalStep = self.count
    self.acArray[2].data = {
    --{body编号, 动作类型（0-平移 1-旋转）,起始角度值, 结束角度值, 旋转轴向量XYZ}
    {1+i,0,0,0,0,0,0,0},
    --{body编号, 动作类型（0-平移 1-旋转）,起始角度值, 结束角度值, 旋转轴向量XYZ}
    {1+i,1,10,10,1,0,0},
    --{leftTop编号, 动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {3+i,1,0,70,0.948,0,0.316},
    --{rightTop编号,  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {5+i,1,0,70,-0.948,0,0.316}, 
    --{leftTopDown编号, 动作类型（0-平移 1-旋转）,起始角度值, 结束角度值, 旋转轴向量XYZ}
    {4+i,1,-80,-80,0.948,0,0.316},
    --{rightTopDown编号, 动作类型（0-平移 1-旋转）,起始角度值, 结束角度值, 旋转轴向量XYZ}
    {6+i,1,80,80,-0.948,0,0.316},
    --{右大腿编号,  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {7+i,1,0,20,1,0,0},
    --{左大腿编号,  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {9+i,1,0,-50,1,0,0},
    --{左小腿编号,  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {10+i,1,90,0,1,0,0},
    --{右脚编号,  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {12+i,1,0,10,1,0,0},}
    
    self.acArray[3].totalStep = self.count
    self.acArray[3].data = {
    --{body编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {1+i,0,0,0,0,0,0,0},
    --{body编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {1+i,1,10,10,1,0,0},
    --{leftTop编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {3+i,1,70,0,0.948,0,0.316},
    --{rightTop编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {5+i,1,70,0,-0.948,0,0.316},
    --{leftTopDown编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {4+i,1,-80,-80,0.948,0,0.316},
    --{rightTopDown编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {6+i,1,80,80,-0.948,0,0.316},
    --{右大腿编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {7+i,1,20,0,1,0,0},
    --{左大腿编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {9+i,1,-50,0,1,0,0},
    --{右小腿编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {8+i,1,0,90,1,0,0},
    --{右脚编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {12+i,1,10,0,1,0,0},}
    
    self.acArray[4].totalStep = self.count
    self.acArray[4].data = {
    --{body编号,  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {1+i,0,0,0,0,0,0,0},
    --{body编号,  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {1+i,1,10,10,1,0,0},
    --{leftTop编号,  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {3+i,1,0,-70,0.948,0,0.316},
    --{rightTop编号,  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {5+i,1,0,-70,-0.948,0,0.316},
    --{leftTopDown编号, 动作类型（0-平移 1-旋转）,起始角度值, 结束角度值, 旋转轴向量XYZ}
    {4+i,1,-80,-80,0.948,0,0.316},
    --{rightTopDown编号, 动作类型（0-平移 1-旋转）,起始角度值, 结束角度值, 旋转轴向量XYZ}
    {6+i,1,80,80,-0.948,0,0.316},
    --{右大腿编号,  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {7+i,1,0,-50,1,0,0},
    --{左大腿编号,  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {9+i,1,0,20,1,0,0},
    --{右小腿编号,  动作类型（0-平移 1-旋转）起始角度值  结束角度值   旋转轴向量XYZ}
    {8+i,1,90,0,1,0,0},
    --{左脚编号  动作类型（0-平移 1-旋转）起始角度值  结束角度值, 旋转轴向量XYZ}    
    {11+i,1,0,10,1,0,0},}
    
end

--# Action
Action = class()

function Action:init()
    self.data = {{},{},{},{},{},{},{},{},{},{}}
    self.totalStep = 0
end


