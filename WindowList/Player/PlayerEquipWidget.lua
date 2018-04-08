------------------------------------------------------------
-- PackWindow 的子窗口,不要通过 UIManager 访问
-- 装备界面包裹窗口
------------------------------------------------------------

local CommonGoodCellClass = require( "GuiSystem.WindowList.CommonWindow.CommonGoodCell" )

local PlayerEquipWidget = UIControl:new
{
	windowName = "PlayerEquipWidget",
	m_CurSelsctEquipPlace = 0,
	m_dis = nil,
	m_totalScore = 0,
	tmpGoodsUid = {},
	m_showAniOver = false,
}

local this = PlayerEquipWidget   -- 方便书写
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
		BackgroundImageInfo ={
			BackgroundImage = AssetPath.TextureGUIPath.."RawImage/Common_zd_beijing.png"  ,   --  背景图片路径
			BackgroundImageUV = Vector4.New( 0 , 0 , 0.60476 , 0.91111 );
	
		
		},
		BackgroundImageInfo ={
			[0]=
			{
				BackgroundImage = AssetPath.TextureGUIPath.."RawImage/Common_zd_beijing.png"  ,   --  背景图片路径
				UVs ={
					Vector4.New( 0.04286 , 0 ,  0.614583 , 0.91111 )
				} 
			}
		
		},
		
        BackgroundColor = Color.black ,
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
function PlayerEquipWidget:Attach( obj )
	UIControl.Attach(self,obj)

    self.callback_OnEntityPartAttached = handler( self , self.OnEntityPartAttached )

	self.Controls.m_HeroRawImage = self.Controls.HeroRawImage:GetComponent(typeof(RawImage))
	-- 点击装备
	for i = PERSON_EQUIPPLACE_WEAPON, PERSON_EQUIPPLACE_SHOES do
		self.Controls["m_EquipTrans"..(i+1)] = self.transform:Find("EquipGrid/Player_Equip_Cell ("..tostring(i+1)..")")
		self.Controls["m_EquipTransObj"..(i+1)] = CommonGoodCellClass:new()
		self.Controls["m_EquipTransObj"..(i+1)]:Attach(self.Controls["m_EquipTrans"..(i+1)].gameObject)
		self.Controls["m_EquipTransObj"..(i+1)]:SetNullEquipBg(i+1)
		self.Controls["m_EquipTransObj"..(i+1)]:SetItemCellSelectedCallback( function(on) self:OnEquipSelected(on, i) end )
	end
	self.Controls.m_HeroRawImage.gameObject:SetActive(false)
	-- 注册模型事件
	UIFunction.AddEventTriggerListener(self.Controls.m_HeroRawImage,EventTriggerType.Drag,function(eventData) self:DragModel(eventData) end)
	UIFunction.AddEventTriggerListener(self.Controls.m_HeroRawImage,EventTriggerType.PointerClick,function(eventData) self:OnClickModel(eventData) end)
	--self:OnEquipSelected(true, 1)
	return self
end

------------------------------------------------------------
function PlayerEquipWidget:OnDestroy()
	rktTimer.KillTimer(self.PlayShowShowAni)
	UIControl.OnDestroy(self)
end

-- 点击某件装备
function PlayerEquipWidget:OnEquipSelected(on, equipPlace)
	if not on then
		return
	end
	
    local equipPart = GetHero():GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
    local forgePart = GetHero():GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart or not forgePart:IsLoad() then
		return
	end
	local entity = IGame.EntityClient:Get(equipPart:GetGoodsUIDByPos(equipPlace + 1))
	if not entity then
		return
	end

	self.m_CurSelsctEquipPlace = equipPlace
	--UIManager.ForgeWindow:OnEquipSelected(on, equipPlace)
	--UIManager.EquipTooltipsWindow:Show(true)
    --UIManager.EquipTooltipsWindow:SetEquipGoods(entity, false)
	local subInfo = {
		bShowBtn = 1,
		bShowCompare = false,
		bRightBtnType = 5,
		bRightBtnRedDot = false,
	}
	UIManager.EquipTooltipsWindow:Show(true)
    UIManager.EquipTooltipsWindow:SetEntity(entity, subInfo)
	--IGame.SkepClient:RequestUnEquip(index2lua(equipPlace))
end

function PlayerEquipWidget:GetSelsctEquipPlace()
	return self.m_CurSelsctEquipPlace
end

--点击模型
function PlayerEquipWidget:OnClickModel(eventData)
	local pressPosition =  eventData.pressPosition
	local CurrentPosition =  eventData.position
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_PLAYER)
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


--拖动英雄模型
function  PlayerEquipWidget:DragModel(eventData)
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_PLAYER)
	if nil ~= entityView then
		entityView.transform:Rotate(-Vector3.up *eventData.delta.x * 30.0 * Time.deltaTime, UnityEngine.Space.Self);
	end
end

function PlayerEquipWidget:TimerPlayShowShowAniOver()
	self.m_showAniOver =true
end

function PlayerEquipWidget:OnEntityPartAttached( args )
    if nil ~= args and nil ~= self.callback_OnEntityPartAttached and args:GetInteger("bodyPart") == EntityBodyPart.Skeleton then
        local entityView = rkt.EntityView.GetEntityView( args:GetString( "EntityId" , "" ) )
        if nil ~= entityView then
    	    entityView:UnregisterEvent(EntityViewEvent.OnEntityPartAttached, self.callback_OnEntityPartAttached)
        end
        self:modelLoadCallBack()
    end
end


--展示英雄模型
function  PlayerEquipWidget:ShowHeroModel(show)
	if true == show then 
		if nil == self.Controls.m_HeroRawImage or self.m_pEntityView ~= nil then 
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
		param.CamPosition = PLAYER_ROLE_CAMERA_POS[nVocation]
		param.backLoadOverCallBack = 	function() self.Controls.m_HeroRawImage.gameObject:SetActive(true) end
		param.CameraRotate = PLAYER_ROLE_CAMERA_ROTATE[nVocation]
		local success = dis:Create(param)
		if true == success  then
			local pPos = Vector3.zero
            local entityView = rkt.EntityView.CreateEntityView( GUI_ENTITY_ID_PLAYER, GUIENTITY_VIEW_PARTS, pPos , UNITY_LAYER_NAME.EntityGUI )
	        if not entityView then
		        return nil
	        end

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
		
		local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_PLAYER)
		if nil ~= entityView then
			entityView:Destroy()
		end
		
		if nil ~= self.m_dis then
			self.m_dis:Destroy()
			self.Controls.m_HeroRawImage.gameObject:SetActive(false)
		end

		UIFunction.RemoveEventTriggerListener(self.Controls.m_HeroRawImage,EventTriggerType.Drag,function(eventData) PlayerEquipWidget:DragModel(eventData) end)
		-- UIFunction.RemoveEventTriggerListener(self.Controls.m_HeroRawImage,EventTriggerType.PointerClick,function(eventData) PlayerEquipWidget:OnClickModel(eventData) end)
	end
	
	
end

function PlayerEquipWidget:PlayShowStandAni()
	
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_PLAYER)
	entityView:SetString( EntityPropertyID.StandAnim ,PLAYER_ROLE_SHOW_ANI )	
	local effectContext = rkt.EntitySkillEffectContext.New()
	effectContext.BodyPart = EntityBodyPart.Skeleton
	effectContext.AnimName = PLAYER_ROLE_SHOW_ANI
	effectContext.RevertToStandAnim = true
	entityView:PlayExhibit(effectContext)

end




function PlayerEquipWidget:modelLoadCallBack()
	rktTimer.SetTimer(function() PlayerEquipWidget:PlayShowStandAni() end,100,1,"")
	self.m_showAniOver = true

			
end

-- 加载数据
function PlayerEquipWidget:ReloadData()
	local equipPart = GetHero():GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	
	for i = PERSON_EQUIPPLACE_WEAPON, PERSON_EQUIPPLACE_SHOES do
		self.Controls["m_EquipTransObj"..(i+1)]:SetItemInfo(equipPart:GetGoodsUIDByPos(i + 1))
	end

	PlayerEquipWidget:ShowHeroModel(true)
	-- 计算装备评分
	--PlayerEquipWidget:GetEquipTotalScore()
end

function PlayerEquipWidget:GetEquipTotalScore()
	local equipPart = GetHero():GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	
	for i = PERSON_EQUIPPLACE_WEAPON, PERSON_EQUIPPLACE_SHOES do
		-- local imageControl = self.Controls["m_Equip"..(i + 1)].gameObject.transform:Find("Image"):GetComponent(typeof(Image))
		local itemControl = self.Controls["m_Equip"..(i + 1)].gameObject.transform:Find("Item")
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
					local placeScore = math.floor(equipScore/10)
					self.m_totalScore = placeScore
				end
			end
		end
	end
	self.Controls.m_EquipScore.text = self.m_totalScore
	
end

-- 清除某个格子图片
-- equipPlace 从1开始
function PlayerEquipWidget:ClearCell(equipPlace)
	if not equipPlace or  equipPlace < PERSON_EQUIPPLACE_WEAPON + 1 or equipPlace > PERSON_EQUIPPLACE_SHOES + 1 then
		return
	end
	local equipPart = GetHero():GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	
	self.Controls["m_EquipTransObj"..equipPlace]:SetItemInfo(equipPart:GetGoodsUIDByPos(equipPlace))
end

-- 设置某个格子图片
-- equipPlace 从1开始
function PlayerEquipWidget:SetCell(equipPlace)
	if equipPlace < PERSON_EQUIPPLACE_WEAPON + 1 or equipPlace > PERSON_EQUIPPLACE_SHOES + 1 then
		return
	end
	local equipPart = GetHero():GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end

	self.Controls["m_EquipTransObj"..equipPlace]:SetItemInfo(equipPart:GetGoodsUIDByPos(equipPlace))
end

return this