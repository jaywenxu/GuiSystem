
-----------------------------外观界面英雄展示部分----------------------------
local HeroDisplayWidget = UIControl:new
{ 
    windowName = "HeroDisplayWidget",
	
	m_showAniOver = false,
	m_Camera = nil,
}

local this = HeroDisplayWidget


--展示英雄模型的配置
local param = {
        layer = "EntityGUI", -- 所在层
        Name = "ObjectDisplayEquipPlayer" ,
        Position = Vector3.New( 2000 , 1000 , 0 ) ,
        RTWidth = 1180 , -- RenderTexture 宽
        RTHeight = 984, -- RenderTexture 高
        CullingMask = {"EntityGUI"},  -- 裁减列表，填 layer 的名称即可
        CamPosition = Vector3.New( 0.14 , 1.3 , 2.7 ) ,   -- 相机位置
        FieldOfView = 45 ,  -- 视野角度
		
		BackgroundImageInfo =
		{	
			[0] = 
			{
				BackgroundImage = AssetPath.TextureGUIPath.."RawImage/Common_zd_beijing.png", --背景图片（texture）
				
				UVs = 
				{   
					Vector4.New( 0 , 0 , 0.614583 , 0.91111),
				} ,
				name = "GameObject"	,
		
			},

		},
	    BackgroundColor = Color.black ,
	    CameraRotate = Vector3.New(6.84,-180,0) ,
	    CameraLight = true ,
        mirror = true ,
        mirrorScale = 0.15 ,
    }

function HeroDisplayWidget:Attach( obj )
	UIControl.Attach(self,obj)
	
	self.Controls.m_HeroRawImage = self.Controls.HeroRawImage:GetComponent(typeof(RawImage))
	self.callbackTimerPlayShowShowAniOver = function()self:TimerPlayShowShowAniOver() end
	self.callback_OnEntityPartAttached = handler( self , self.OnEntityPartAttached )
	-- 注册模型事件
	UIFunction.AddEventTriggerListener(self.Controls.m_HeroRawImage,EventTriggerType.Drag,function(eventData) self:DragModel(eventData) end)
	--[[UIFunction.AddEventTriggerListener(self.Controls.m_HeroRawImage,EventTriggerType.PointerClick,function(eventData) self:OnClickModel(eventData) end)--]]
end

--换装接口， 只提供一个类型参数，本方法做解析换装
function HeroDisplayWidget:ChangePart(nType)
	
end

function HeroDisplayWidget:OnEntityPartAttached( args )
    if nil ~= args and nil ~= self.callback_OnEntityPartAttached and args:GetInteger("bodyPart") == EntityBodyPart.Skeleton then
        local entityView = rkt.EntityView.GetEntityView( args:GetString( "EntityId" , "" ) )
        if nil ~= entityView then
    	    entityView:UnregisterEvent(EntityViewEvent.OnEntityPartAttached, self.callback_OnEntityPartAttached)
        end
        self:modelLoadCallBack()
    end
end

--展示英雄模型
function  HeroDisplayWidget:ShowHeroModel(show)
	if true == show then 
		local _entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_DRESS )
		if nil == self.Controls.m_HeroRawImage or _entityView ~= nil then 
			return
		end
	
		local dis = rktObjectDisplayInGUI:new()
		self.m_Camera = dis
		
		self.m_dis = dis
		local pHero = IGame.EntityClient:GetHero()
		if not pHero then
			return
		end
		-- 默认装备,以后有换装了改掉
		local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)
		self.Vocation = nVocation
		param.CamPosition = BAG_ROLE_CAMERA_POS[nVocation]
		
		param.CameraRotate = BAG_ROLE_CAMERA_ROTATE[nVocation]
		local success = dis:Create(param)
		UnityEngine.Object.DontDestroyOnLoad(dis.m_GameObject)
		if true == success  then
			local pPos = Vector3.zero
            local entityView = rkt.EntityView.CreateEntityView( GUI_ENTITY_ID_DRESS, GUIENTITY_VIEW_PARTS, pPos , UNITY_LAYER_NAME.EntityGUI )
	        if not entityView then
		        return nil
	        end
			entityView.transform.localRotation = Vector3.zero
            entityView:SetFloat( EntityPropertyID.ShadowPlaneOffset , -200.0 )
			IGame.EntityFactory:SetSkeleton(entityView, pHero:GetResID(), true)
			--=========================================================================
--			self:Recover()
			--=========================================================================
		
			--这里可以直接从模型层中获取数据， 直接显示默认效果，恢复默认的时候重新显示就行				TODO

			local nWeaponResID = GameHelp:GetDefaultAppearance(EntityBodyPart.RWeaponPart).nResID
			local nBodyMeshResID = GameHelp:GetDefaultAppearance(EntityBodyPart.BodyMesh).nResID
			local nFaceMeshResID = GameHelp:GetDefaultAppearance(EntityBodyPart.FaceMesh).nResID
			local nHairMeshResID = GameHelp:GetDefaultAppearance(EntityBodyPart.HairMesh).nResID
		
			local tmpCurAppearInfo = IGame.AppearanceClient:GetHeroCurAppearInfo()
			if tmpCurAppearInfo then
				-- 武器资源ID
				if tmpCurAppearInfo.nWaepID and tmpCurAppearInfo.nWaepID > 0 then
					local pAppearScheme = IGame.rktScheme:GetSchemeInfo(APPEARANCE_CSV,tmpCurAppearInfo.nWaepID)
					if pAppearScheme and pAppearScheme.nResID and pAppearScheme.nResID > 0 then
						nWeaponResID = pAppearScheme.nResID
					end
				end
				-- 衣服资源ID
				if tmpCurAppearInfo.nClothID and tmpCurAppearInfo.nClothID > 0 then
					local pAppearScheme = IGame.rktScheme:GetSchemeInfo(APPEARANCE_CSV,tmpCurAppearInfo.nClothID)
					if pAppearScheme and pAppearScheme.nResID and pAppearScheme.nResID > 0 then
						nBodyMeshResID = pAppearScheme.nResID
					end
				end
				-- 脸部资源ID
				if tmpCurAppearInfo.nFacialID and tmpCurAppearInfo.nFacialID > 0 then
					local pAppearScheme = IGame.rktScheme:GetSchemeInfo(APPEARANCE_CSV,tmpCurAppearInfo.nFacialID)
					if pAppearScheme and pAppearScheme.nResID and pAppearScheme.nResID > 0 then
						nFaceMeshResID = pAppearScheme.nResID
					end
				end
				-- 发型资源ID
				if tmpCurAppearInfo.nHairID and tmpCurAppearInfo.nHairID > 0 then
					local pAppearScheme = IGame.rktScheme:GetSchemeInfo(APPEARANCE_CSV,tmpCurAppearInfo.nHairID)
					if pAppearScheme and pAppearScheme.nResID and pAppearScheme.nResID > 0 then
						nHairMeshResID = pAppearScheme.nResID
					end
				end
				-- 坐骑资源ID			
				--[[if tmpCurAppearInfo.nRideID and tmpCurAppearInfo.nRideID > 0 then
					local pAppearScheme = IGame.rktScheme:GetSchemeInfo(APPEARANCE_CSV,tmpCurAppearInfo.nRideID)
					if pAppearScheme and pAppearScheme.nResID and pAppearScheme.nResID > 0 then
						nHorseMeshResID = pAppearScheme.nResID
					end
				end--]]
			end
				---先留着，设置坐骑    										 TODO
        --[[
            IGame.EntityFactory:SetPartMesh(entityView,EntityBodyPart.BodyMesh,nBodyMeshResID,true)
            IGame.EntityFactory:SetPartMesh(entityView,EntityBodyPart.FaceMesh,nFaceMeshResID,true)
            IGame.EntityFactory:SetPartMesh(entityView,EntityBodyPart.HairMesh,nHairMeshResID,true)--]]
--			IGame.EntityFactory:SetPartMesh(entityView,EntityBodyPart.HorsePart,nHorseMeshResID,true)
--[[			self.HairColor = tmpCurAppearInfo.nColor
			if self.HairColor then
				if self.HairColor > 0 then
					local color = Color:New()
					color:FromHexadecimal(self.HairColor)
					local colorVec3 = Vector3.New(color.r,color.g,color.b)
					entityView:SetVector3(EntityPropertyID.HairColor, colorVec3)
				end
			end
			self.HairColor = entityView:GetVector3(EntityPropertyID.HairColor)--]]
			
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
		
		local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_DRESS)
		if nil ~= entityView then 
			entityView:Destroy()	
		end
		
		if nil ~= self.m_dis then
			self.m_dis:Destroy()
		end
		
		
		UIFunction.RemoveEventTriggerListener(self.Controls.m_HeroRawImage,EventTriggerType.Drag,function(eventData) HeroDisplayWidget:DragModel(eventData) end)
		-- UIFunction.RemoveEventTriggerListener(self.Controls.m_HeroRawImage,EventTriggerType.PointerClick,function(eventData) PersonEquipSkepWidget:OnClickModel(eventData) end)
	end	
end

--恢复默认的接口			TODO
function HeroDisplayWidget:Recover()
	
	local nVocation = self.Vocation
	local defaultRecord = IGame.rktScheme:GetSchemeInfo(APPEARDEFAULT_CSV, nVocation)
	if not defaultRecord then
		return
	end
	
	local nWeaponResID = GameHelp:GetDefaultAppearance(EntityBodyPart.RWeaponPart).nResID
	local nBodyMeshResID = GameHelp:GetDefaultAppearance(EntityBodyPart.BodyMesh).nResID
	local nFaceMeshResID = GameHelp:GetDefaultAppearance(EntityBodyPart.FaceMesh).nResID
	local nHairMeshResID = GameHelp:GetDefaultAppearance(EntityBodyPart.HairMesh).nResID	
	
	local nColor = nil
	local nWeapAppearID = defaultRecord.weaponAppearID
		
	local tmpCurAppearInfo = IGame.AppearanceClient:GetHeroCurAppearInfo()
	if tmpCurAppearInfo then
		-- 武器资源ID
		if tmpCurAppearInfo.nWaepID and tmpCurAppearInfo.nWaepID > 0 then
			nWeapAppearID = tmpCurAppearInfo.nWaepID
		end
		-- 衣服资源ID
		if tmpCurAppearInfo.nClothID and tmpCurAppearInfo.nClothID > 0 then
			local pAppearScheme = IGame.rktScheme:GetSchemeInfo(APPEARANCE_CSV,tmpCurAppearInfo.nClothID)
			if pAppearScheme and pAppearScheme.nResID and pAppearScheme.nResID > 0 then
				nBodyMeshResID = pAppearScheme.nResID
			end
		end
		-- 脸部资源ID
		if tmpCurAppearInfo.nFacialID and tmpCurAppearInfo.nFacialID > 0 then
			local pAppearScheme = IGame.rktScheme:GetSchemeInfo(APPEARANCE_CSV,tmpCurAppearInfo.nFacialID)
			if pAppearScheme and pAppearScheme.nResID and pAppearScheme.nResID > 0 then
				nFaceMeshResID = pAppearScheme.nResID
			end
		end
		-- 发型资源ID
		if tmpCurAppearInfo.nHairID and tmpCurAppearInfo.nHairID > 0 then
			local pAppearScheme = IGame.rktScheme:GetSchemeInfo(APPEARANCE_CSV,tmpCurAppearInfo.nHairID)
			if pAppearScheme and pAppearScheme.nResID and pAppearScheme.nResID > 0 then
				nHairMeshResID = pAppearScheme.nResID
			end
		end
		-- 坐骑资源ID
		--[[if tmpCurAppearInfo.nRideID and tmpCurAppearInfo.nRideID > 0 then
			local pAppearScheme = IGame.rktScheme:GetSchemeInfo(APPEARANCE_CSV,tmpCurAppearInfo.nRideID)
			if pAppearScheme and pAppearScheme.nResID and pAppearScheme.nResID > 0 then
				nHorseMeshResID = pAppearScheme.nResID
			end
		end--]]
		
		if tmpCurAppearInfo.nColor > 0 then
			nColor = tmpCurAppearInfo.nColor
		end
	end
	local pWeaponScheme = IGame.rktScheme:GetSchemeInfo(APPEARANCE_CSV,nWeapAppearID)
	
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_DRESS )
	if pWeaponScheme then
		-- 左手武器
		if pWeaponScheme.nLeftWeapResID and pWeaponScheme.nLeftWeapResID > 0 then
			IGame.EntityFactory:SetWeapon(entityView,pWeaponScheme.nLeftWeapResID,false,true)
		end
		-- 右手武器
		if pWeaponScheme.nRightWeapResID and pWeaponScheme.nRightWeapResID > 0 then
			IGame.EntityFactory:SetWeapon(entityView,pWeaponScheme.nRightWeapResID,true,true)
		end
	end
	
	IGame.EntityFactory:SetPartMesh(entityView,EntityBodyPart.BodyMesh,nBodyMeshResID,true)
	IGame.EntityFactory:SetPartMesh(entityView,EntityBodyPart.FaceMesh,nFaceMeshResID,true)
	IGame.EntityFactory:SetPartMesh(entityView,EntityBodyPart.HairMesh,nHairMeshResID,true)
--			IGame.EntityFactory:SetPartMesh(entityView,EntityBodyPart.HorsePart,nHorseMeshResID,true)
	if nColor then
		local color = Color:New()
		color:FromHexadecimal(nColor)
		local colorVec3 = Vector3.New(color.r,color.g,color.b)
		self:ChangeHairColor(colorVec3)
	else
		local colorVec3 = Vector3.New(0,0,0)
		self:ChangeHairColor(colorVec3)
	end
end

--改变发色接口	,  nColor --Vector3 RGB空间
function HeroDisplayWidget:ChangeHairColor(nColor)
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_DRESS)
	if not entityView then return end
	entityView:SetVector3(EntityPropertyID.HairColor, nColor)
end

------------------------------------------------------------------------------------------
function  HeroDisplayWidget:DragModel(eventData)
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_DRESS)
	if nil ~= entityView then
		entityView.transform:Rotate(-Vector3.up *eventData.delta.x * 30.0 * Time.deltaTime, UnityEngine.Space.Self);
	end
end

function HeroDisplayWidget.GetBodyPart(nPartID)
	
end

--点击模型
function HeroDisplayWidget:OnClickModel(eventData)
	local pressPosition =  eventData.pressPosition
	local CurrentPosition =  eventData.position
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_DRESS)
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
	entityView:SetString( EntityPropertyID.StandAnim ,PLAYER_ROLE_SHOW_ANI )	
	local effectContext = rkt.EntitySkillEffectContext.New()
	effectContext.BodyPart = EntityBodyPart.Skeleton
	effectContext.AnimName = PLAYER_ROLE_ONCLICK_ANI
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

function HeroDisplayWidget:TimerPlayShowShowAniOver()
	self.m_showAniOver =true
end

function HeroDisplayWidget:PlayShowStandAni()
	
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_DRESS)
	if entityView == nil then
		return
	end
	entityView:SetString( EntityPropertyID.StandAnim ,PLAYER_ROLE_SHOW_ANI )	
	local effectContext = rkt.EntitySkillEffectContext.New()
	effectContext.BodyPart = EntityBodyPart.Skeleton
	effectContext.AnimName = PLAYER_ROLE_SHOW_ANI
	effectContext.RevertToStandAnim = true
	entityView:PlayExhibit(effectContext)

end

function HeroDisplayWidget:modelLoadCallBack()
	rktTimer.SetTimer(function() HeroDisplayWidget:PlayShowStandAni() end,100,1,"")
	self.m_showAniOver = true		
end

--[[--向左旋转英雄模型
function  HeroDisplayWidget:LeftRotateModel()
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_DRESS)
	if nil ~= entityView then
		entityView.transform:Rotate(-Vector3.up * -2 * 30.0 * Time.deltaTime, UnityEngine.Space.Self);
	end
end

--像右旋转模型
function HeroDisplayWidget:RigthRotateModel()
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_DRESS)
	if nil ~= entityView then
		entityView.transform:Rotate(-Vector3.up * 2 * 30.0 * Time.deltaTime, UnityEngine.Space.Self);
	end
end--]]

return this
