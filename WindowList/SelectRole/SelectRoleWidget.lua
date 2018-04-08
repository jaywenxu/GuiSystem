-----------------------------------------------------------
-- SelectRoleWindow 的子窗口,不要通过 UIManager 访问
-- 选择角色组件
------------------------------------------------------------
-- local CreateRoleCellClass = require( "GuiSystem.WindowList.SelectRole.CreateRoleCell" )
-- local SelectRoleCellClass = require( "GuiSystem.WindowList.SelectRole.SelectRoleCell" )
------------------------------------------------------------
local SelectRoleWidget = UIControl:new
{
    windowName = "SelectRoleWidget",
	-- 创建角色的cell列表
	--CreateCellList = {},
	-- 已经有的角色列表
	--SelectCellList = {},
	
	--m_RoleCellList = {},
	
	m_RoleName = {},
	m_disModel = nil,
	m_bg = nil,
	m_currentNovation = nil,
	-- 显示顺序
	ShowSort = {  -- 顺序，职业ID
	[0] = 0,
	[1] = 3,
	[2] = 1,
	[3] = 2,
	},
	
	-- 显示顺序
	ItemCellSort = { -- 职业ID,按钮
	[0] = 1,
	[1] = 3,
	[2] = 4,
	[3] = 2,
	},
	m_aniMalOver = false,
	m_nvocation = 0
}

local this = SelectRoleWidget   -- 方便书写
local createUid =1


--展示英雄模型的配置
local param = {
        layer = "EntityGUI", -- 所在层
        Name = "ObjectDisplayEquipPlayer" ,
        Position = Vector3.New( 1000 , 1000 , 0 ) ,
        RTWidth = 1300 , -- RenderTexture 宽
        RTHeight = 1080, -- RenderTexture 高
        CullingMask = {"EntityGUI"},  -- 裁减列表，填 layer 的名称即可
        CamPosition = Vector3.New( 0.14 , 1.3 , 2.7 ) ,   -- 相机位置
        FieldOfView = 48 ,  -- 视野角度
		BackgroundColor = Color.black ,
		BackgroundImageInfo ={
			[0]=
			{
				BackgroundImage = AssetPath.TextureGUIPath.."RawImage/login_beijing_1.png"  ,   --  背景图片路径
				UVs ={
					Vector4.New( 0.083 , 0 , 0.76041 , 1)
				} 
			}
		
		},
		CameraRotate = Vector3.New(6.84,-180,0) ,
        CameraLight = true ,
        mirror = true ,
        mirrorScale = 0.15 ,
    }

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
-- RoleCellList 列表
--JiantouTop : (UnityEngine.UI.Button)
--JiantouBottom : (UnityEngine.UI.Button)
------------------------------------------------------------
function SelectRoleWidget:Attach( obj )
	UIControl.Attach(self,obj)
	self.Controls.GoodsToggleGroup = self.Controls.RoleCellList:GetComponent(typeof(ToggleGroup))

	self.VocationLevelText = {}
	self.VocationLevelText[0] = self.Controls.VocationLevelText0
	self.VocationLevelText[1] = self.Controls.VocationLevelText1
	self.VocationLevelText[2] = self.Controls.VocationLevelText2
	self.VocationLevelText[3] = self.Controls.VocationLevelText3
	self.VocationButton = {}
	self.VocationButton[0] = self.Controls.VocationButton0
	self.VocationButton[1] = self.Controls.VocationButton1
	self.VocationButton[2] = self.Controls.VocationButton2
	self.VocationButton[3] = self.Controls.VocationButton3
	self.callBackOnAnimalOver = function() self:OnClickModelAniModelOver() end
	self.callBackPlayNextAni = function() self:ShowNextAni() end
	self.callbackVocationButtonClick0 = function() self:OnVocationButtonClick(self.ShowSort[0]) end
	self.callbackVocationButtonClick1 = function() self:OnVocationButtonClick(self.ShowSort[1]) end
	self.callbackVocationButtonClick2 = function() self:OnVocationButtonClick(self.ShowSort[2]) end
	self.callbackVocationButtonClick3 = function() self:OnVocationButtonClick(self.ShowSort[3]) end
	self.callback_OnEntityPartAttached = handler( self , self.OnEntityPartAttached )
	   
	self.Controls.VocationButton0.onClick:AddListener( self.callbackVocationButtonClick0 )
	self.Controls.VocationButton1.onClick:AddListener( self.callbackVocationButtonClick1 )
	self.Controls.VocationButton2.onClick:AddListener( self.callbackVocationButtonClick2 )
	self.Controls.VocationButton3.onClick:AddListener( self.callbackVocationButtonClick3 )
	
	self.callbackOnEnable = function() self:OnEnable() end
	self.unityBehaviour.onEnable:AddListener(self.callbackOnEnable) 
	self.callbackOnDisable = function() self:OnDisable() end
	self.unityBehaviour.onDisable:AddListener(self.callbackOnDisable) 
	self.Controls.m_HeroRawImage = self.Controls.HeroRawImage:GetComponent(typeof(RawImage))
	UIFunction.AddEventTriggerListener(self.Controls.m_HeroRawImage,EventTriggerType.Drag,function(eventData) SelectRoleWidget:DragModel(eventData) end)
	UIFunction.AddEventTriggerListener(self.Controls.m_HeroRawImage,EventTriggerType.PointerClick,function(eventData) SelectRoleWidget:OnClickModel(eventData) end)
	self.Controls.m_HeroRawImage.gameObject:SetActive(false)
	return self
end


--点击模型
function SelectRoleWidget:OnClickModel(eventData)
	local pressPosition =  eventData.pressPosition
	local CurrentPosition =  eventData.position
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_SELECTROLE)
	if nil == entityView then 
		return
	end
	local X = math.abs(pressPosition.x - CurrentPosition.x)
	local Y = math.abs(pressPosition.y - CurrentPosition.y)
	if  X > 0.1 or Y > 0.1 then 
		return
	end
	
	if entityView then
		-- todo: 调用动作、光效接口
		local effectContext = rkt.EntitySkillEffectContext.New()
		effectContext.BodyPart = EntityBodyPart.Skeleton
		effectContext.AnimName = SELECT_ROLE_ONCLICK_ANI
		effectContext.RevertToStandAnim = true
		if self.m_aniMalOver == true then 
			entityView:PlayExhibit(effectContext)
			self.m_aniMalOver =false
			rktTimer.SetTimer(self.callBackOnAnimalOver,SELECT_ROLE_MODEL_ANI2_TIME[self.m_nvocation ],1,"")
		end
	end
end


------------------------------------------------------------
function SelectRoleWidget:OnEntityPartAttached( args )
       if nil ~= args and nil ~= self.callback_OnEntityPartAttached and args:GetInteger("bodyPart") == EntityBodyPart.Skeleton then
        local entityView = rkt.EntityView.GetEntityView( args:GetString( "EntityId" , "" ) )
        if nil ~= entityView then
    	    entityView:UnregisterEvent(EntityViewEvent.OnEntityPartAttached, self.callback_OnEntityPartAttached)
        end
        self:CreatRoleCallBack()
    end
end
------------------------------------------------------------

function SelectRoleWidget:OnClickModelAniModelOver()
	self.m_aniMalOver = true
end


--拖动英雄模型
function  SelectRoleWidget:DragModel(eventData)
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_SELECTROLE)
	if nil ~= entityView then
		entityView.transform:Rotate(-Vector3.up *eventData.delta.x * 30.0 * Time.deltaTime, UnityEngine.Space.Self);
	end
end

function SelectRoleWidget:OnDestroy()
	self.unityBehaviour.onEnable:RemoveListener(self.callbackOnEnable) 
	self.unityBehaviour.onDisable:RemoveListener(self.callbackOnDisable) 
	self:ShowHeroModel(false)
	self.m_currentNovation =nil
end

function SelectRoleWidget:SetParentWindow(win)
	self.m_ParentWindow = win
end

-- 回收
function SelectRoleWidget:RecycleGameObject()
	
	local cellList = self.Controls.grid
	if not cellList.transform  then
		return
	end
	local nCount = cellList.transform.childCount
	if nCount >= 1 then
		local tmpTable = {}
		for i = 1, nCount, 1 do
			table.insert(tmpTable,cellList.transform:GetChild(i-1).gameObject)
		end
		for i, v in pairs(tmpTable) do
			rkt.GResources.RecycleGameObject(v)
		end
	end
end

function SelectRoleWidget:CreateAllCellItems()
	self:RecycleGameObject()
	self.m_RoleCellList = {}
	local cellList = self.Controls.grid
	if not cellList.transform  then
		return
	end
	for i= 1, PERSON_VOCATION_MAX - 1 do
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.SelectRoleCell ,
		function ( path , obj , ud )
			if nil == cellList.gameObject then   -- 判断U3D对象是否已经被销毁
				rkt.GResources.RecycleGameObject(obj)
				return
			end
			obj.transform:SetParent(cellList.transform,false)
			local item = SelectRoleCellClass:new({})
			item:Attach(obj)
			item:SetToggleGroup( this.Controls.GoodsToggleGroup )
			item:SetParentWidget(thisSelf)
			item:ClearInfo()
			item:SetItemCellSelectedCallback( SelectRoleWidget.OnSelectItemCellSelected )
			self.m_RoleCellList[i] = item
			end , nil , AssetLoadPriority.GuiNormal )
	end
	
end
------------------------------------------------------------
--- 刷新角色数据内容
function SelectRoleWidget:RefreshCellItemsEx()

	local cellList = self.Controls.grid
	if not cellList.transform  then
		return
	end
	local nCount = cellList.transform.childCount
	if nCount <= 0 or not self.m_RoleCellList or table_count(self.m_RoleCellList) <= 0 then
		self:CreateAllCellItems()
	end
	
	for i, itemClass in pairs(self.m_RoleCellList) do 
		itemClass:ClearInfo()
	end
	local actorlist = IGame.FormManager:GetActorList()
	if actorlist ~= nil then
		for i, v in pairs(actorlist) do
			local nVocation = v.nProfession
			if nVocation >= PERSON_VOCATION_ZHENWU or nVocation <= PERSON_VOCATION_XUANZONG then
				self.m_RoleCellList[ self.ItemCellSort[nVocation] ]:UpdateItemInfo(v)
			end
		end
	end

end

------------------------------------------------------------
function SelectRoleWidget.OnSelectItemCellSelected(itemCell,pWidget,on)
	if not on then
		return
	end
	if itemCell == nil or pWidget == nil then
		return
	end
	pWidget.m_ParentWindow:SetCurActorName(itemCell:GetPlayerName())
end


------------------------------------------------------------
--- 刷新角色数据内容
function SelectRoleWidget:RefreshCellItems()

	for i = PERSON_VOCATION_ZHENWU,PERSON_VOCATION_XUANZONG do
		self.Controls["LevelBg"..i].gameObject:SetActive(false)
		self.VocationLevelText[i].text = ""
	end
	self.m_RoleName = {}
	local actorlist = IGame.FormManager:GetActorList()
	local nClickVocation = 0
	local bSecect = false
	local lastActorName = PlayerPrefs.GetString(gLastUserInfo.LastActorName) or ""
	if actorlist ~= nil then
		for i, v in pairs(actorlist) do
			local nVocation = v.nProfession
			if nVocation >= PERSON_VOCATION_ZHENWU or nVocation <= PERSON_VOCATION_XUANZONG then
				if bSecect == false then
					nClickVocation = nVocation
					self.m_nvocation = nVocation
					if v.szActorName == lastActorName then
						bSecect = true
					end
				end
				local nIndex = self.ItemCellSort[nVocation] -1
				self.Controls["LevelBg"..nIndex].gameObject:SetActive(true)
				self.VocationLevelText[nIndex].text = tostring(v.nLevel)
				self.m_RoleName[nVocation] = tostring(v.szActorName)
			end
		end
	end
	self:OnVocationButtonClick(nClickVocation)
end

------------------------------------------------------------
function SelectRoleWidget:OnVocationButtonClick(nVocation)
	-- 已经创建角色
	if self.m_RoleName == nil then
		self.m_RoleName = {}
	end
	local nIndex = self.ItemCellSort[nVocation] -1
	self:IsSelect(nIndex)
	local nCurRoleName = self.m_RoleName[nVocation] or ""
	self.m_ParentWindow:UpdateCurRole(nVocation,tostring(nCurRoleName))
	self:ShowHeroModel(true,nVocation)
end

------------------------------------------------------------
function SelectRoleWidget:ChangeCamer()
	self:setSceCameraToOrthoGragphic()

end

-- 将场景摄像机的透视改为正交
function SelectRoleWidget:setSceCameraToOrthoGragphic()
	--[[local cameraFrame = rkt.CameraFrameFreedom.New()
	local vocation = self.m_currentNovation
	cameraFrame.Position = SELECT_ROLE_CAMERA_POSITION[vocation]
	cameraFrame.Rotation = SELECT_ROLE_CAMERA_ROTATE[vocation]
	rktMainCamera.SetCameraFrame(cameraFrame,false)
    local mainCam = rkt.CameraController.mainCamera
	if nil ~= mainCam then
		--mainCam.orthographic = true
		--mainCam.farClipPlane = 20
		--mainCam.nearClipPlane = -10
        mainCam.nearClipPlane = 0.5
        mainCam.farClipPlane = 50
	end--]]
end

function SelectRoleWidget:OnEnable()
	if self.m_bg ~= nil then 
		self.m_bg:SetActive(true)
	end
end


function SelectRoleWidget:OnDisable()
	SelectRoleWidget:DeleteCurShowModel()
	if self.m_bg ~=nil then 
		self.m_bg:SetActive(false)	
	end
end

function SelectRoleWidget:DeleteBg()
	if self.m_bg ~=nil then 
		 UnityEngine.Object.Destroy( self.m_bg)
	end
end

--刷新角色模型
function SelectRoleWidget:DeleteCurShowModel()
	if nil ~= self.m_disModel then
		self.m_disModel:Destroy()
		self.m_currentNovation = nil
		self.m_aniMalOver = true
	end
end

--展示模型
function SelectRoleWidget:ShowHeroModel(show,nVocation)
	if true == show  then 
		if  self.m_dis == nil  then 
			param.CamPosition = SELECT_ROLE_CAMERA_POSITION[nVocation]
			param.backLoadOverCallBack =
			function() 
				self.Controls.HeroRawImage.gameObject:SetActive(true)
			end
			param.CameraRotate = SELECT_ROLE_CAMERA_ROTATE[nVocation]
			local dis = rktObjectDisplayInGUI:new()
			local success = dis:Create(param)
			UnityEngine.Object.DontDestroyOnLoad(dis.m_GameObject)
			self.m_dis = dis
		end
		self:createHeroModel(nVocation,self.m_dis.m_GameObject.transform)
	else
		
		
		self.m_aniMalOver = true
		--删除rendertexture
		if nil ~= self.m_dis then
			self.m_dis:Destroy()
			self.m_dis = nil
            self.Controls.HeroRawImage.gameObject:SetActive(false)
		end
		--删除模型
		if nil ~= self.m_disModel then 
			self.m_disModel:Destroy()
			self.m_disModel = nil
		end
	
		--移除监听
		UIFunction.RemoveEventTriggerListener(self.Controls.HeroRawImage,EventTriggerType.Drag,function(eventData) SelectRoleWidget:DragModel(eventData) end)
		UIFunction.RemoveEventTriggerListener(self.Controls.HeroRawImage,EventTriggerType.PointerClick,function(eventData) SelectRoleWidget:OnClickModel(eventData) end)
	end
end


function SelectRoleWidget:AttachRawImage()
	if nil == self.Controls.m_HeroRawImage   then 
		return
	end
	if self.m_disModel == nil then 
		return
	end
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_SELECTROLE)
	if not entityView then
		return nil
	end
	entityView:SetFloat( EntityPropertyID.ShadowPlaneOffset , -200.0 )
	self.m_dis:AttachRawImage(self.Controls.m_HeroRawImage,true)

	
end

--透视摄像机显示的方式创建模型
function SelectRoleWidget:createHeroModel(nVocation,parentTrs)
	if nVocation == self.m_currentNovation then 
		return
	end

	self.m_aniMalOver = false
	local actorlist = IGame.FormManager:GetActorList()	
	local formatData = nil
	for i ,data in pairs(actorlist) do
		if data.nProfession == nVocation then
			formatData = data.formatData
			break
		end
	end
	
	self:DeleteCurShowModel()	
	self.m_currentNovation = nVocation
	local disModel = UICharacterHelp:new()
	local param = {}
	param.ParentTrs = parentTrs
	param.formInfo = formatData
	param.entityClass = tEntity_Class_Person
    param.layer = UNITY_LAYER_NAME.EntityGUI  -- 角色所在层
    param.Name = "heroModel" -- or "DiaglogModel"   --角色实例名字	
    param.Position =  Vector3.New(0,0,0)
	param.localScale  =  Vector3.New(1,1,1) --因为使用canvas去绘制模型
	param.rotate = Vector3.New(0,0,0)	--模型旋转角度
	param.MoldeID =  gEntityVocationLiteRes[nVocation]			--模型ID
	param.UID = GUI_ENTITY_ID_SELECTROLE	-- UID
	param.animalName = SELECT_ROLE_SHOW_ANI
	param.nVocation = nVocation
	param.callBack = function() self:CreatRoleCallBack(nVocation) end
	self.m_disModel = disModel
	local characterHelp =  disModel:Create(param)
	
end


function SelectRoleWidget:CreatRoleCallBack()
	self:AttachRawImage()
	self:PlayShowAni()
end


--播放角色动作
function SelectRoleWidget:PlayShowAni()
	rktTimer.KillTimer(self.callBackPlayNextAni)
	rktTimer.KillTimer(self.callBackOnAnimalOver)
	local entityView =  rkt.EntityView.GetEntityView(GUI_ENTITY_ID_SELECTROLE)
	if nil == entityView then 
		return
	end 
	if  entityView then
		-- todo: 调用动作、光效接口
		local effectContext = rkt.EntitySkillEffectContext.New()
		effectContext.BodyPart = EntityBodyPart.Skeleton
		effectContext.AnimName = SELECT_ROLE_BORN_ANI
		effectContext.RevertToStandAnim = false
		entityView:PlayExhibit(effectContext)
		local Obj = entityView:GetBodyPart( effectContext.BodyPart)
		rktTimer.SetTimer(self.callBackPlayNextAni,SELECT_ROLE_MODEL_ANI1_TIME[self.m_nvocation ],1,"")

	end

end

function SelectRoleWidget:ShowNextAni()
	local entityView =  rkt.EntityView.GetEntityView(GUI_ENTITY_ID_SELECTROLE)
	if nil == entityView then 
		return
	end 
	if  entityView then
		-- todo: 调用动作、光效接口
		local effectContext = rkt.EntitySkillEffectContext.New()
		effectContext.BodyPart = EntityBodyPart.Skeleton
		effectContext.AnimName = SELECT_ROLE_ONCLICK_ANI
		effectContext.transitionDuration = 0.1
		effectContext.RevertToStandAnim = true
		entityView:PlayExhibit(effectContext)
		rktTimer.SetTimer(self.callBackOnAnimalOver,SELECT_ROLE_MODEL_ANI2_TIME[self.m_nvocation ],1,"")
	end
	
end

-- 被选中
function SelectRoleWidget:IsSelect(nIndex)
	
	if not nIndex then
		return
	end
	for i = 0, 3 do
		if i == nIndex then
			self.Controls["SelectImage"..i].gameObject:SetActive(true)
		else
			self.Controls["SelectImage"..i].gameObject:SetActive(false)
		end
	end
end

return this