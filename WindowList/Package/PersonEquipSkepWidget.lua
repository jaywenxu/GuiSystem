------------------------------------------------------------
-- PackWindow 的子窗口,不要通过 UIManager 访问
-- 装备界面包裹窗口
------------------------------------------------------------

local PersonEquipSkepWidget = UIControl:new
{ 
    windowName = "PersonEquipSkepWidget",
	m_dis = nil,
	m_totalScore = 0,
	tmpGoodsUid = {},
	tmpEquipPlaceScore = {},
	m_showAniOver = false,
}

local this = PersonEquipSkepWidget   -- 方便书写
local zero = int64.new("0")

--展示英雄模型的配置
local param = {
        layer = "EntityGUI", -- 所在层
        Name = "ObjectDisplayEquipPlayer" ,
        Position = Vector3.New( 1000 , 1000 , 0 ) ,
        RTWidth = 1180 , -- RenderTexture 宽
        RTHeight = 984, -- RenderTexture 高
        CullingMask = {"EntityGUI"},  -- 裁减列表，填 layer 的名称即可
        CamPosition = Vector3.New( 0.14 , 1.3 , 2.7 ) ,   -- 相机位置
        FieldOfView = 45 ,  -- 视野角度
		BackgroundColor = Color.black ,
		BackgroundImageInfo ={
			[0]=
			{
				BackgroundImage = AssetPath.TextureGUIPath.."RawImage/Common_zd_beijing.png"  ,   --  背景图片路径
				UVs ={
					Vector4.New( 0 , 0 , 0.614583 , 0.91111 )
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
--m_ButtonView : ButtonView (UnityEngine.UI.Button)
--m_EquipX : PersonPack_Equip_Cell_1 (UnityEngine.UI.Toggle)
------------------------------------------------------------
function PersonEquipSkepWidget:Attach( obj )
	UIControl.Attach(self,obj)

    self.callback_OnEntityPartAttached = handler( self , self.OnEntityPartAttached )

	-- 按钮事件
	self.callback_OnBtnViewClick = function() self:OnBtnViewClick() end
	self.Controls.m_ButtonView.onClick:AddListener(self.callback_OnBtnViewClick)
	self.callback_OnBtnGemClick = function() self:OnBtnGemClick() end
	self.Controls.m_ButtonGem.onClick:AddListener(self.callback_OnBtnGemClick)
	self.Controls.m_HeroRawImage = self.Controls.HeroRawImage:GetComponent(typeof(RawImage))
	self.callbackTimerPlayShowShowAniOver = function()self:TimerPlayShowShowAniOver() end
	-- 点击装备
	for i = PERSON_EQUIPPLACE_WEAPON, PERSON_EQUIPPLACE_SHOES do
		self.Controls["m_Equip"..(i+1)].onValueChanged:AddListener(function(on) self:OnEquipSelected(on, i) end)
	end
    self.Controls.m_HeroRawImage.gameObject:SetActive(false)
	UIFunction.AddEventTriggerListener(self.Controls.m_HeroRawImage,EventTriggerType.Drag,function(eventData) PersonEquipSkepWidget:DragModel(eventData) end)
	UIFunction.AddEventTriggerListener(self.Controls.m_HeroRawImage,EventTriggerType.PointerClick,function(eventData) PersonEquipSkepWidget:OnClickModel(eventData) end)
	return self
end

------------------------------------------------------------
function PersonEquipSkepWidget:OnEntityPartAttached( args )
       if nil ~= args and nil ~= self.callback_OnEntityPartAttached and args:GetInteger("bodyPart") == EntityBodyPart.Skeleton then
        local entityView = rkt.EntityView.GetEntityView( args:GetString( "EntityId" , "" ) )
        if nil ~= entityView then
    	    entityView:UnregisterEvent(EntityViewEvent.OnEntityPartAttached, self.callback_OnEntityPartAttached)
        end
        self:modelLoadCallBack()
    end
end
------------------------------------------------------------
function PersonEquipSkepWidget:OnDestroy()
	rktTimer.KillTimer(self.callbackTimerPlayShowShowAniOver)
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_PACK)
	if nil ~= entityView then 
		entityView:Destroy()	
	end
	
	if nil ~= self.m_dis then
		self.m_dis:Destroy()
	end

	UIFunction.RemoveEventTriggerListener(self.Controls.m_HeroRawImage,EventTriggerType.Drag,function(eventData) PersonEquipSkepWidget:DragModel(eventData) end)
	UIControl.OnDestroy(self)
end
------------------------------------------------------------

-- 点击外观按钮
function PersonEquipSkepWidget:OnBtnViewClick()
	UIManager.ShopWindow:ShowShopWindow(2)
end

-- 点击宝石套装按钮
function PersonEquipSkepWidget:OnBtnGemClick()
	print("gem clicked")
end

-- 点击某件装备
function PersonEquipSkepWidget:OnEquipSelected(on, equipPlace)
	if not on then
		return
	end
	
    local equipPart = GetHero():GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	local entity = IGame.EntityClient:Get(equipPart:GetGoodsUIDByPos(equipPlace + 1))
	if not entity then
		return
	end
	local subInfo = {
		bShowBtn = 1,
		bShowCompare = false,
		bRightBtnType = 1,
	}
	UIManager.EquipTooltipsWindow:Show(true)
    UIManager.EquipTooltipsWindow:SetEntity(entity, subInfo)
end

--点击模型
function PersonEquipSkepWidget:OnClickModel(eventData)
	local pressPosition =  eventData.pressPosition
	local CurrentPosition =  eventData.position
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_PACK)
	if nil == entityView then 
		return
	end
	local X = math.abs(pressPosition.x - CurrentPosition.x)
	local Y = math.abs(pressPosition.y - CurrentPosition.y)
	if  X > 0.1 or Y >0.1 then 
		return
	end
	if self.m_showAniOver == false then 	
		return
	end
	entityView:SetString( EntityPropertyID.StandAnim ,SELECT_ROLE_SHOW_ANI )	
	local effectContext = rkt.EntitySkillEffectContext.New()
	effectContext.BodyPart = EntityBodyPart.Skeleton
	effectContext.AnimName = BAG_ROLE_ONCLICK_ANI
	effectContext.RevertToStandAnim = true
	entityView:PlayExhibit(effectContext)
	self.m_showAniOver  =false
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end
	-- 默认装备,以后有换装了改掉
	local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)
	rktTimer.SetTimer(self.callbackTimerPlayShowShowAniOver ,SELECT_ROLE_MODEL_ANI2_TIME[nVocation],1,"")
end


--拖动英雄模型
function  PersonEquipSkepWidget:DragModel(eventData)
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_PACK)
	if nil ~= entityView then
		entityView.transform:Rotate(-Vector3.up *eventData.delta.x * 30.0 * Time.deltaTime, UnityEngine.Space.Self);
	end
end

function PersonEquipSkepWidget:TimerPlayShowShowAniOver()
	self.m_showAniOver =true
	
end

--展示英雄模型
function  PersonEquipSkepWidget:ShowHeroModel(show)
	if true == show then 
		if nil == self.Controls.m_HeroRawImage or self.m_pEntityView ~= nil or self.m_dis ~= nil then 
			return
		end
	
		local dis = rktObjectDisplayInGUI:new()
	
		self.m_dis = dis
		
		local pHero = IGame.EntityClient:GetHero()
		if not pHero then
			return
		end
		-- 默认装备,以后有换装了改掉
		local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)
		param.CamPosition = BAG_ROLE_CAMERA_POS[nVocation]
		param.backLoadOverCallBack = function() self.Controls.HeroRawImage.gameObject:SetActive(true) end
		param.CameraRotate = BAG_ROLE_CAMERA_ROTATE[nVocation]
		local success = dis:Create(param)
		UnityEngine.Object.DontDestroyOnLoad(dis.m_GameObject)
		if true == success  then
			local pPos = Vector3.zero
            local entityView = rkt.EntityView.CreateEntityView( GUI_ENTITY_ID_PACK, GUIENTITY_VIEW_PARTS, pPos , UNITY_LAYER_NAME.EntityGUI )
	        if not entityView then
		        return nil
	        end
			self.m_pEntityView = entityView
            entityView:SetFloat( EntityPropertyID.ShadowPlaneOffset , -200.0 )

	        IGame.EntityFactory:SetSkeleton(entityView, pHero:GetResID(), true)
			IGame.EntityFactory:SetEntityView(pHero, entityView)
			local body = entityView:GetBodyPart( EntityBodyPart.Skeleton)
			if body == nil then 
				entityView:RegisterEvent(EntityViewEvent.OnEntityPartAttached, self.callback_OnEntityPartAttached)
			else
				self:modelLoadCallBack()
			end

			entityView.transform:SetParent(dis.m_GameObject.transform,false)

			dis:AttachRawImage(self.Controls.m_HeroRawImage,true)
		end
	else
		
		local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_PACK)
		if nil ~= entityView then
			entityView:Destroy()
			self.m_pEntityView = nil
		end
		
		if nil ~= self.m_dis then
			self.m_dis:Destroy()
			self.m_dis = nil
            self.Controls.HeroRawImage.gameObject:SetActive(false)
		end

		UIFunction.RemoveEventTriggerListener(self.Controls.m_HeroRawImage,EventTriggerType.Drag,function(eventData) PersonEquipSkepWidget:DragModel(eventData) end)
	end
end

function PersonEquipSkepWidget:PlayShowStandAni()
	
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_PACK)
	entityView:SetString( EntityPropertyID.StandAnim ,SELECT_ROLE_SHOW_ANI )	
	local effectContext = rkt.EntitySkillEffectContext.New()
	effectContext.BodyPart = EntityBodyPart.Skeleton
	effectContext.AnimName = SELECT_ROLE_SHOW_ANI
	effectContext.RevertToStandAnim = true
	entityView:PlayExhibit(effectContext)
end




function PersonEquipSkepWidget:modelLoadCallBack()
	rktTimer.SetTimer(function() PersonEquipSkepWidget:PlayShowStandAni() end,100,1,"")
	self.m_showAniOver = true		
end

-- 加载数据
function PersonEquipSkepWidget:ReloadData()
	local equipPart = GetHero():GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
    local forgePart = GetHero():GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart or not forgePart:IsLoad() then
		return
	end
	
	for i = PERSON_EQUIPPLACE_WEAPON, PERSON_EQUIPPLACE_SHOES do
		local itemControl = self.Controls["m_Equip"..(i + 1)].gameObject.transform:Find("Item")
		local equipCellToggle = self.Controls["m_Equip"..(i + 1)]:GetComponent(typeof(Toggle))
		local UpGradeControl = self.Controls["m_Equip"..(i + 1)].gameObject.transform:Find("UpGrade")
		local imageBgControl = itemControl:Find("ImageBg"):GetComponent(typeof(Image))
		local packImageControl = itemControl:Find("PackImage"):GetComponent(typeof(Image))
		local entity = IGame.EntityClient:Get(equipPart:GetGoodsUIDByPos(i + 1))
		if entity and EntityClass:IsEquipment(entity:GetEntityClass()) then
			local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
			if not schemeInfo then
				return
			end

	        local nQuality = entity:GetNumProp(EQUIP_PROP_QUALITY)
			local nAdditionalPropNum = entity:GetAdditionalPropNum()
			
			local imageBgPath = GetEquipBgPath(nQuality, nAdditionalPropNum)
			local packImagePath = AssetPath.TextureGUIPath .. schemeInfo.IconIDNormal

			itemControl.gameObject:SetActive(true)
			UIFunction.SetImageSprite(imageBgControl, imageBgPath)
			UIFunction.SetImageSprite(packImageControl, packImagePath)
			self.tmpGoodsUid[i+1] = equipPart:GetGoodsUIDByPos(i + 1)
			
		else
			itemControl.gameObject:SetActive(false)
			equipCellToggle.isOn = false
			UpGradeControl.gameObject:SetActive(false)
		end
	end
	
	PersonEquipSkepWidget:ShowHeroModel(true)
	-- 计算装备评分
	PersonEquipSkepWidget:GetEquipTotalScore()
	self:RefreshRenDot()
	
end

function PersonEquipSkepWidget:RefreshRenDot()
	local forgePart = GetHero():GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart or not forgePart:IsLoad() then
		return
	end
	local EquipUpGradeState = forgePart:GetEquipUpGradeFlg()
	for i = PERSON_EQUIPPLACE_WEAPON, PERSON_EQUIPPLACE_SHOES do
		local UpGradeControl = self.Controls["m_Equip"..(i + 1)].gameObject.transform:Find("UpGrade")
		if EquipUpGradeState[i+1] then
			UpGradeControl.gameObject:SetActive(true)
		else
			UpGradeControl.gameObject:SetActive(false)
		end
	end
end

function PersonEquipSkepWidget:ReOpenHeroModel()
	self:ShowHeroModel(true)
end

function PersonEquipSkepWidget:GetEquipTotalScore()
	local equipPart = GetHero():GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	self.m_totalScore = 0
	for i = PERSON_EQUIPPLACE_WEAPON, PERSON_EQUIPPLACE_SHOES do
		local entity = IGame.EntityClient:Get(equipPart:GetGoodsUIDByPos(i + 1))
		if entity and EntityClass:IsEquipment(entity:GetEntityClass()) then
			-- 强化等级
			local pHero = GetHero()
			local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
			if forgePart then
				local HoleProp = forgePart:GetHoleProp(i)
				if HoleProp then
					local nNormalSmeltLv = HoleProp.bySmeltLv  -- 普通强化等级
					local nCreatureVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)
					local equipScore = entity:ComputeEquipScore()
					local placeScore  = math.floor(equipScore/10) 
					self.m_totalScore = self.m_totalScore + placeScore
					self.tmpEquipPlaceScore[i+1] = placeScore
				end

			end
		else 
			self.tmpEquipPlaceScore[i+1] = 0
		end
	end
	self.Controls.m_EquipScore.text = self.m_totalScore
	
end

-- 清除某个格子图片
-- equipPlace 从1开始
function PersonEquipSkepWidget:ClearCell(equipPlace)
	if equipPlace < PERSON_EQUIPPLACE_WEAPON + 1 or equipPlace > PERSON_EQUIPPLACE_SHOES + 1 then
		return
	end
	-- local itemControl = self.Controls["m_Equip"..(equipPlace + 1)].gameObject.transform:Find("Item")
	local itemControl = self.Controls["m_Equip"..(equipPlace)].gameObject.transform:Find("Item")
	local equipCellToggle = self.Controls["m_Equip"..equipPlace]:GetComponent(typeof(Toggle))
	local UpGradeControl = self.Controls["m_Equip"..(equipPlace)].gameObject.transform:Find("UpGrade")
	local pHero = GetHero()
    local equipPart = pHero:GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	local entity = IGame.EntityClient:Get(self.tmpGoodsUid[equipPlace])
	self.tmpGoodsUid[equipPlace] = 0
	if self.tmpEquipPlaceScore[equipPlace] ~= 0 then 
		self.m_totalScore = self.m_totalScore - self.tmpEquipPlaceScore[equipPlace]
		self.Controls.m_EquipScore.text = self.m_totalScore
		self.tmpEquipPlaceScore[equipPlace] = 0
	end
	itemControl.gameObject:SetActive(false)
	equipCellToggle.isOn =false
	UpGradeControl.gameObject:SetActive(false)
	self:RefreshRenDot()
end

-- 设置某个格子图片
-- equipPlace 从1开始
function PersonEquipSkepWidget:SetCell(equipPlace)
	if equipPlace < PERSON_EQUIPPLACE_WEAPON + 1 or equipPlace > PERSON_EQUIPPLACE_SHOES + 1 then
		return
	end
	
	local equipPart = GetHero():GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	
	local itemControl = self.Controls["m_Equip"..equipPlace].gameObject.transform:Find("Item")
	-- local imageControl = self.Controls["m_Equip"..equipPlace].gameObject.transform:Find("Image"):GetComponent(typeof(Image))
	local imageBgControl = itemControl:Find("ImageBg"):GetComponent(typeof(Image))
	local packImageControl = itemControl:Find("PackImage"):GetComponent(typeof(Image))
	local entity = IGame.EntityClient:Get(equipPart:GetGoodsUIDByPos(equipPlace))
	local equipCellToggle = self.Controls["m_Equip"..equipPlace]:GetComponent(typeof(Toggle))
	self.tmpGoodsUid[equipPlace] = equipPart:GetGoodsUIDByPos(equipPlace)
	if entity and EntityClass:IsEquipment(entity:GetEntityClass()) then
		local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
		if not schemeInfo then
			return
		end
		equipCellToggle.isOn =true

		-- todo: 设计图标配置格式
		local nQuality = entity:GetNumProp(EQUIP_PROP_QUALITY)
		local nAdditionalPropNum = entity:GetAdditionalPropNum()
		
		local imageBgPath = GetEquipBgPath(nQuality, nAdditionalPropNum)
	
		local packImagePath = AssetPath.TextureGUIPath .. schemeInfo.IconIDNormal
		itemControl.gameObject:SetActive(true)
		UIFunction.SetImageSprite(imageBgControl, imageBgPath)
		UIFunction.SetImageSprite(packImageControl, packImagePath)
		
		local pHero = GetHero()
		local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
		if forgePart then
			local HoleProp = forgePart:GetHoleProp(equipPlace)
			if HoleProp then
				local nNormalSmeltLv = HoleProp.bySmeltLv  -- 普通强化等级
				local nCreatureVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)
				local equipScore = entity:ComputeEquipScore()
				local placeScore = math.floor(equipScore/10)
				if self.tmpEquipPlaceScore[equipPlace] ~= 0 then 
					self.m_totalScore = self.m_totalScore - self.tmpEquipPlaceScore[equipPlace]
					self.m_totalScore = self.m_totalScore + placeScore
				else 
					self.m_totalScore = self.m_totalScore + placeScore
				end
				self.tmpEquipPlaceScore[equipPlace]  = placeScore
				
				self.Controls.m_EquipScore.text = self.m_totalScore
			end
		end
	else
		itemControl.gameObject:SetActive(false)
		equipCellToggle.isOn =false
	end
	self:RefreshRenDot()
end

function PersonEquipSkepWidget:UpdateEquipTotalScore(totalScore) 
	self.m_totalScore = totalScore
end

return this