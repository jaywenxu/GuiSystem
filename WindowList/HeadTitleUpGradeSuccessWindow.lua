-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    许文杰
-- 日  期:    2017/11/29
-- 版  本:    1.0
-- 描  述:    头衔晋级成功展示窗口
-------------------------------------------------------------------
------------------------------------------------------------
local HeadTitleUpGradeSuccessWindow = UIWindow:new
{
	windowName = "HeadTitleUpGradeSuccessWindow",
	m_headID = nil,
	m_rawImage = nil,
	m_pEntityView = nil,
	m_dis = nil,
}
--展示英雄模型的配置
local param = {
        layer = "EntityGUI", -- 所在层
        Name = "ObjectDisplayEquipPlayer" ,
        Position = Vector3.New( 1000 , 1000 , 0 ) ,
        RTWidth = 1095 , -- RenderTexture 宽
        RTHeight = 954, -- RenderTexture 高
        CullingMask = {"EntityGUI"},  -- 裁减列表，填 layer 的名称即可
        CamPosition = Vector3.New( 0.14 , 1.3 , 2.7 ) ,   -- 相机位置
        FieldOfView = 45 ,  -- 视野角度
		BackgroundColor = Color.black ,
		BackgroundImageInfo ={
			[0]=
			{
				BackgroundImage = AssetPath.TextureGUIPath.."RawImage/login_beijing_1.png"  ,   --  背景图片路径
				UVs ={
					Vector4.New( 0.20625 , 0.050925 , 0.7765625 , 0.93426 )
				} 
			}
		
		},
		
	
		CameraRotate = Vector3.New(6.84,-180,0) ,
        CameraLight = true ,
        mirror = true ,
        mirrorScale = 0.15 ,
    }

local this = HeadTitleUpGradeSuccessWindow		-- 方便书写

------------------------------------------------------------
function HeadTitleUpGradeSuccessWindow:Init()
	
end
------------------------------------------------------------
function HeadTitleUpGradeSuccessWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.callBackOnAnimalOver = function() self:OnClickModelAniModelOver() end
	self.callBackPlayNextAni = function() self:ShowNextAni() end
	self.callbackClosingBtnClick = function() self:OnClickConfirmBtn() end
	self.Controls.m_confirmBtn.onClick:AddListener(self.callbackClosingBtnClick)
	self.m_rawImage = self.Controls.m_heroRawImage:GetComponent(typeof(RawImage))
	self:RefreshUI()
end

------------------------------------------------------------
------------------------------------------------------------
-- 窗口销毁
function HeadTitleUpGradeSuccessWindow:OnDestroy()
	self.m_headID = nil
	self.m_rawImage = nil
	self.m_dis = nil
	UIWindow.OnDestroy(self)
	
end

--显示UI
function HeadTitleUpGradeSuccessWindow:ShowUI(headID)
	self.m_headID = headID
	self:Show()
	if self:isLoaded() then 
		self:RefreshUI()
	end
end

--刷新界面
function HeadTitleUpGradeSuccessWindow:RefreshUI()
	UIFunction.SetCellHeadTitle(self.m_headID,self.Controls.m_headTrs,self.Controls,nil)
	self:ShowHeroModel(true)
end


--展示英雄模型
function HeadTitleUpGradeSuccessWindow:ShowHeroModel(show)
	if true == show then 
		if nil == self.m_rawImage or self.m_dis ~= nil then 
			return
		end
	
		local dis = rktObjectDisplayInGUI:new()
		self.m_aniMalOver = false
		self.m_dis = dis
		
		local pHero = IGame.EntityClient:GetHero()
		if not pHero then
			return
		end
		-- 默认装备,以后有换装了改掉
		local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)
		self.m_nvocation = nVocation
		param.CamPosition = HEADTITLE_ROLE_MODEL_POS[nVocation]
		param.backLoadOverCallBack = function() self.m_rawImage.gameObject:SetActive(true) end
		param.CameraRotate = HEADTITLE_ROLE_MODEL_ROTATE[nVocation]
		local success = dis:Create(param)
		UnityEngine.Object.DontDestroyOnLoad(dis.m_GameObject)
		if true == success  then
			local pPos = Vector3.zero
            local entityView = rkt.EntityView.CreateEntityView( GUI_ENTITY_ID_HEAD, GUIENTITY_VIEW_PARTS, pPos , UNITY_LAYER_NAME.EntityGUI )
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

			dis:AttachRawImage(self.m_rawImage,true)
		end
	else
		
		local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_HEAD)
		if nil ~= entityView then
			entityView:Destroy()
			self.m_pEntityView = nil
		end
		
		if nil ~= self.m_dis then
			self.m_dis:Destroy()
			self.m_dis = nil
            self.m_rawImage.gameObject:SetActive(false)
		end

	--	UIFunction.RemoveEventTriggerListener(self.Controls.m_rawImage,EventTriggerType.Drag,function(eventData) HeadTitleUpGradeSuccessWindow:DragModel(eventData) end)
	end
end


function HeadTitleUpGradeSuccessWindow:PlayShowStandAni()
	
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_HEAD)
	entityView:SetString( EntityPropertyID.StandAnim ,SELECT_ROLE_SHOW_ANI )	
	local effectContext = rkt.EntitySkillEffectContext.New()
	effectContext.BodyPart = EntityBodyPart.Skeleton
	effectContext.AnimName = SELECT_ROLE_BORN_ANI
	effectContext.RevertToStandAnim = false
	entityView:PlayExhibit(effectContext)
	rktTimer.SetTimer(self.callBackPlayNextAni,SELECT_ROLE_MODEL_ANI1_TIME[self.m_nvocation ],1,"")
end


function HeadTitleUpGradeSuccessWindow:ShowNextAni()
	local entityView =  rkt.EntityView.GetEntityView(GUI_ENTITY_ID_HEAD)
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

function HeadTitleUpGradeSuccessWindow:OnClickModelAniModelOver()
	self.m_aniMalOver = true
end



function HeadTitleUpGradeSuccessWindow:modelLoadCallBack()
	--self:PlayShowStandAni()
	self.m_showAniOver = true		
end


function HeadTitleUpGradeSuccessWindow:ClearData()
	self:ShowHeroModel(false)
	self.m_headID = nil
	self.m_pEntityView = nil
	self.m_dis = nil
	self.m_aniMalOver =false
end

function HeadTitleUpGradeSuccessWindow:OnDestroy()
	self:ClearData()
	UIWindow.OnDestroy(self)
end

function HeadTitleUpGradeSuccessWindow:OnClickConfirmBtn()
	self:ClearData()
	self:Hide()
end


return HeadTitleUpGradeSuccessWindow







