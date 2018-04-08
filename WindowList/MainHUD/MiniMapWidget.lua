-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    邓元豪
-- 日  期:    2017/03/04
-- 版  本:    1.0
-- 描  述:    小地图控制
-------------------------------------------------------------------
require("rkt.MapControl")
-------------------------------------------------------------------
local MiniMapWidget = UIControl:new
{
    windowName = "MiniMapWidget" ,
	m_hero = nil, 						--主角实体缓存
	
	RemoveList = {},					--针对异步加载刷新问题，待删除列表
}

local selfScale = 0.68					--小地图自身icon缩放比
local NPCDefaultScale = 0.8				--小地图Npc icon默认缩放比
------------------------------------------------------------
function MiniMapWidget:Attach( obj )
	UIControl.Attach(self,obj)

    local ctrls = self.Controls
    self:AddListener( ctrls.MinimapButton , "onClick" , self.OnMinimapButtonClick , self )
    self:AddListener( ctrls.BranchingButton , "onClick" , self.OnBranchingButtonClick , self )
    self:AddListener( self.unityBehaviour , "onEnable" , self.OnEnable , self )
    ctrls.m_MiniMapControl = ctrls.m_MiniMapBg:GetComponent(typeof(rkt.MapControl))

	rktEventEngine.SubscribeExecute( EVENT_AFTER_ENTER_GAMESTATE , 0 , 0 , self.OnAfterEnterGameState , self )
    rktEventEngine.SubscribeExecute( EVENT_ENTITYVIEW_CREATED , SOURCE_TYPE_PERSON , 0 , self.OnPersonCreated , self )
    rktEventEngine.SubscribeExecute( EVENT_ENTITYVIEW_CREATED , SOURCE_TYPE_MONSTER , 0 , self.OnMonsterCreated , self )
    rktEventEngine.SubscribeExecute( EVENT_ENTITY_DESTROYENTITY , SOURCE_TYPE_PERSON , 0 , self.OnEntityDestroyed , self )
    rktEventEngine.SubscribeExecute( EVENT_ENTITY_DESTROYENTITY , SOURCE_TYPE_MONSTER , 0 , self.OnEntityDestroyed , self )
	rktEventEngine.SubscribeExecute( EVENT_TARGET_HIT_ZERO_HP , SOURCE_TYPE_MONSTER , 0 , self.OnTargetHitZeroHP , self )

	--刷新单个小地图打点， 供阵营转换使用 EVENT_MINIMAP_UPDATE
	rktEventEngine.SubscribeExecute( EVENT_MINIMAP_UPDATE , SOURCE_TYPE_PERSON , 0 , self.OnUpdateIcon , self )

	rktTimer.SetTimer(slot( self.OnTimerUpdatePositionText , self ), 100, -1, "MiniMapWidget:OnTimerUpdatePositionText")

	self:OnEnable()
end


------------------------------------------------------------
function MiniMapWidget:OnDestroy()
	self.m_hero = nil
	if self.RemoveList then
		self.RemoveList = nil
	end
	UIControl.OnDestroy(self)
	rktEventEngine.UnSubscribeExecute( EVENT_AFTER_ENTER_GAMESTATE , 0 , 0 , self.OnAfterEnterGameState , self )
    rktEventEngine.UnSubscribeExecute( EVENT_ENTITYVIEW_CREATED , SOURCE_TYPE_PERSON , 0 , self.OnPersonCreated , self )
    rktEventEngine.UnSubscribeExecute( EVENT_ENTITYVIEW_CREATED , SOURCE_TYPE_MONSTER , 0 , self.OnMonsterCreated , self )
    rktEventEngine.UnSubscribeExecute( EVENT_ENTITY_DESTROYENTITY , SOURCE_TYPE_PERSON , 0 , self.OnEntityDestroyed , self )
    rktEventEngine.UnSubscribeExecute( EVENT_ENTITY_DESTROYENTITY , SOURCE_TYPE_MONSTER , 0 , self.OnEntityDestroyed , self )
	rktEventEngine.UnSubscribeExecute( EVENT_TARGET_HIT_ZERO_HP , SOURCE_TYPE_MONSTER , 0 , self.OnTargetHitZeroHP , self )
	rktEventEngine.UnSubscribeExecute( EVENT_MINIMAP_UPDATE , SOURCE_TYPE_MONSTER , 0 , self.OnUpdateIcon , self )
	rktTimer.KillTimer( slot( self.OnTimerUpdatePositionText , self ) )
end
------------------------------------------------------------
--初始化地图
function MiniMapWidget:InitMap()
    if nil == self.Controls.m_MiniMapControl then
        return
    end

	--加载MapInfo.csv文件，获取当前场景地图配置信息
	local mapID = IGame.EntityClient:GetMapID()										--获取当前地图ID
	local mapInfo = IGame.rktScheme:GetSchemeInfo(MAPINFO_CSV, mapID )				--获取对应mapID的地图信息
	if not mapInfo then
		return
	end
	local path = AssetPath.MapImgTexturePath..mapInfo.mapPath							--地图ID信息
	UIFunction.SetRawImageSprite(self.Controls.m_MiniMapBg:GetComponent(typeof(UnityEngine.UI.RawImage)), path)			--设置地图背景图片
	self.Controls.MapName.text = mapInfo.szName												--设置当前地图名称

	local minPos = Vector2.New(mapInfo.LBPosition[1],mapInfo.LBPosition[2])
    local maxPos = Vector2.New(mapInfo.RTPosition[1],mapInfo.RTPosition[2])

	local localRectTransform = self.Controls.m_MiniMapControl:GetComponent(typeof(RectTransform))
	local localMapRectTransform = self.Controls.m_Map:GetComponent(typeof(RectTransform))
    local mapRectSize = localMapRectTransform.rect.size
	localRectTransform.sizeDelta  = Vector2.New( mapRectSize.x * ( maxPos.x - minPos.x ) / mapInfo.MiniMapScaleX , mapRectSize.y * ( maxPos.y - minPos.y ) / mapInfo.MiniMapScaleY );

    self.Controls.m_MiniMapControl:SetMapBounds( minPos , maxPos )
end
------------------------------------------------------------
function MiniMapWidget:OnPersonCreated( eventid , eventsrc , srcid , evtdata )
    if nil == self.Controls.m_MiniMapControl then
        return
    end
    if GetHeroUID() == evtdata.uidEntity then
        return
    end
    local person = IGame.EntityClient:Get( evtdata.uidEntity )
    if nil == person then
        return
    end
    local iconPath = self:GetPersonIconPath( person )
    if nil == iconPath then
        return
    end
    self:SetEntityIcon( person:GetUID() , iconPath , selfScale)
end
------------------------------------------------------------
function MiniMapWidget:OnMonsterCreated( eventid , eventsrc , srcid , evtdata)
    local monster = IGame.EntityClient:Get(evtdata.uidEntity)
	if not self.m_hero then
		self.m_hero = GetHero()
	end
    if nil == monster or nil == self.m_hero then
        return
    end
	
	local pkPart = self.m_hero:GetEntityPart(ENTITYPART_PERSON_PKMODE)
	
	if not pkPart then return end 
	
	local canAttack = pkPart:CanAttack(monster)

	local npcScale = NPCDefaultScale
    local iconPath, scale = self:GetMonsterIconPath( monster , canAttack, true)
	npcScale = scale
    if nil == iconPath then
        return
    end
    self:SetEntityIcon( monster:GetUID() , iconPath , npcScale)
end
------------------------------------------------------------
function MiniMapWidget:OnEntityDestroyed( eventid , eventsrc , srcid , evtdata )
    self:RemoveEntityIcon( evtdata.uidEntity )
end
------------------------------------------------------------
function MiniMapWidget:OnTargetHitZeroHP( eventid , eventsrc , srcid , msg)
    self:RemoveEntityIcon( msg.uidEntity )
end
------------------------------------------------------------
function MiniMapWidget:OnUpdateIcon(eventid , eventsrc , srcid , entity, canAttack)
	if entity then
		self:RefreshIconByEntityAndAttack(entity, canAttack)
	end
end
---------------------------------------------------------------
function MiniMapWidget:GetPersonIconPath( entity )
	if not self.m_hero then
		self.m_hero = GetHero()
	end
	
	if not self.m_hero then return nil, selfScale end
	local pkPart = self.m_hero:GetEntityPart(ENTITYPART_PERSON_PKMODE)
	
	if not pkPart then return nil, selfScale end 
	
	local canAttack = pkPart:CanAttack(entity)
	
	if entity == self.m_hero then 
		return nil, selfScale						--自己
	end
	
	local dbid = entity:GetNumProp(CREATURE_PROP_PDBID)
	
	if canAttack then
		return AssetPath.MapTexturePath .. "map_dian_difang.png", selfScale							--敌方玩家,紫色
	else
		local dbID = entity:GetNumProp(CREATURE_PROP_PDBID)
		local myTeam = IGame.TeamClient:GetTeam()
		if myTeam ~= nil then 
			if myTeam:IsTeammate(dbID) then 
				return AssetPath.MapTexturePath .. "map_dian_youfang.png", selfScale						--队友，蓝色
			else
				return AssetPath.MapTexturePath .. "map_dian_duiyou.png", selfScale							--普通玩家，绿色
			end
		end	
		return AssetPath.MapTexturePath .. "map_dian_duiyou.png", selfScale							--普通玩家，绿色
	end
end

--去除是否可攻击判定
function MiniMapWidget:GetPersonIconPathByAttack(entity, canAttack)
	if not self.m_hero then
		self.m_hero = GetHero()
	end
	
	if not self.m_hero then return nil, selfScale end
	
	if entity == self.m_hero then 
		return nil, selfScale						--自己
	end
	
	if canAttack then
		return AssetPath.MapTexturePath .. "map_dian_difang.png", selfScale							--敌方玩家,紫色
	else
		local dbID = entity:GetNumProp(CREATURE_PROP_PDBID)
		local myTeam = IGame.TeamClient:GetTeam()
		if myTeam ~= nil then 
			if myTeam:IsTeammate(dbID) then 
				return AssetPath.MapTexturePath .. "map_dian_youfang.png", selfScale						--队友，蓝色
			else
				return AssetPath.MapTexturePath .. "map_dian_duiyou.png", selfScale							--普通玩家，绿色
			end
		end	
		return AssetPath.MapTexturePath .. "map_dian_duiyou.png", selfScale							--普通玩家，绿色
	end
end

------------------------------------------------------------
function MiniMapWidget:GetMonsterIconPath( monster , canAttack, ignoreAttack)
    local schemeInfo = monster:GetScheme()
    if nil == schemeInfo then
        return nil,NPCDefaultScale
    end
	
	--优先检测配置的图片
	if schemeInfo.MiniMapIcon then
		if schemeInfo.MiniMapIcon == "-1" then
			return nil,NPCDefaultScale
		end
		if schemeInfo.MiniMapIcon ~= "" then
			if not schemeInfo.MiniMapIconScale or schemeInfo.MiniMapIconScale == 0 then
				--uerror("怪物地图图标缩放异常，monster表中怪物异常ID：" .. schemeInfo.lMonsterID)
			end
			local scale = schemeInfo.MiniMapIconScale
			if scale == 0 then
				scale = 1
			end
			return AssetPath.MapTexturePath .. schemeInfo.MiniMapIcon, scale
		end
	end
	
	local selType = schemeInfo.lSelectType
	if selType == MONSTER_SELECTTYPE_GUARD or selType == MONSTER_SELECTTYPE_SUMMON or selType == MONSTER_SELECTTYPE_PAWN then
		return nil,NPCDefaultScale
	end

	if not ignoreAttack then
		if not canAttack then
			return AssetPath.MapTexturePath .. "map_dian_NPC.png",NPCDefaultScale
		else
			return AssetPath.MapTexturePath .. "map_dian_guawu.png",NPCDefaultScale
		end
	else					--初始化赋值
		local selType = schemeInfo.lSelectType
		if selType == MONSTER_SELECTTYPE_NPCSAFE then
			return AssetPath.MapTexturePath .. "map_dian_NPC.png",NPCDefaultScale
		elseif selType == MONSTER_SELECTTYPE_GENERAL
			or selType == MONSTER_SELECTTYPE_POLISH 
			or selType == MONSTER_SELECTTYPE_BOSS 
			or selType == MONSTER_SELECTTYPE_NPCATTACK 
			or selType == MONSTER_SELECTTYPE_RARE
			or selType == MONSTER_SELECTTYPE_MAX 
		then
			return AssetPath.MapTexturePath .. "map_dian_guawu.png",NPCDefaultScale
		elseif selType == MONSTER_SELECTTYPE_GUARD or selType == MONSTER_SELECTTYPE_SUMMON or selType == MONSTER_SELECTTYPE_PAWN then
			return nil,NPCDefaultScale
		else
			return nil,NPCDefaultScale
		end
	end
end
------------------------------------------------------------
function MiniMapWidget:SetEntityIcon( uid , iconPath , nScale)
    rkt.GResources.FetchGameObjectAsync( GuiAssetList.NpcMinimapCell ,
        function( path , obj , ud )
            if nil == obj then
                return
            end
            if nil == self.transform then
                rkt.GResources.RecycleGameObject(obj)
                return
            end
			
			if self.RemoveList and self.RemoveList[uid] and self.RemoveList[uid] == true then
				self.RemoveList[uid] = false
				 rkt.GResources.RecycleGameObject( obj )
				return
			end
			
            rkt.UserDataComponent.Attach(obj).LongValue = uid
            obj.transform:SetParent( self.Controls.m_OtherIcons , false )
			local imgComponent = obj:GetComponent(typeof(Image))
			local rectTrans = obj:GetComponent(typeof(RectTransform))
            UIFunction.SetImageSprite( imgComponent , iconPath , function() 
					imgComponent:SetNativeSize()
					rectTrans.sizeDelta = Vector2.New(rectTrans.sizeDelta.x * nScale, rectTrans.sizeDelta.y * nScale)
					 self.Controls.m_MiniMapControl:AddEntityIcon( uid , obj.transform )
				end)
        end , nil , AssetLoadPriority.GuiNormal )
end
------------------------------------------------------------
function MiniMapWidget:RemoveEntityIcon( uid )
    if nil == self.Controls.m_MiniMapControl then
        return
    end

    self.Controls.m_MiniMapControl:RemoveEntityIcon( uid )
    local icon = rkt.UserDataComponent.FindChildByLongValue( self.Controls.m_OtherIcons , uid )
    if nil ~= icon then
		self.RemoveList[uid] = false
        rkt.GResources.RecycleGameObject( icon.gameObject )
    end
end

------------------------------------------------------------
-- 显示/隐藏小地图窗口打点
-- @param uid : 角色uid
-- @param visible : 显示还是隐藏
function MiniMapWidget:VisibleEntityIcon(uid, visible)

    if nil == self.Controls.m_MiniMapControl then
        return
    end

    self.Controls.m_MiniMapControl:VisibleEntityIcon( uid , visible)

end


------------------------------------------------------------
--加载NPC Image
function MiniMapWidget:InitEntityIcons()
    if nil == self.Controls.m_MiniMapControl then
        return
    end
    self.Controls.m_MiniMapControl:RemoveAllEntityIcons()
    CoreUtility.RecycleChildren( self.Controls.m_OtherIcons.gameObject , false )
 	local entities = IGame.EntityClient:GetAllCreature()
    for i , entity in ipairs(entities) do
		self:RefreshIconByEntityInfo(entity)
    end
end

--刷新person打点
function MiniMapWidget:RefreshPersonIcon()
	--[[local iconPath = nil
	local scale = 1
	local entities = IGame.EntityClient:GetAllCreature()
	for i , entity in ipairs(entities) do
		iconPath = nil
		scale = 1
		local entityClass = entity:GetEntityClass()

		if EntityClass:IsPerson( entityClass ) and entity:GetUID() ~= heroUID then
			iconPath, scale = self:GetPersonIconPath( entity )
			if nil ~= iconPath then
				local uid = entity:GetUID()
				self:RemoveEntityIcon(uid , iconPath )
				self:SetEntityIcon( uid , iconPath ,scale)
			end
		end
    end--]]
end

--刷新怪物打点
function MiniMapWidget:RefreshMonsterIcon()
	--[[local iconPath = nil
	local scale = 1
	if not self.m_hero then
		self.m_hero = GetHero()
	end
	local pkPart = self.m_hero:GetEntityPart(ENTITYPART_PERSON_PKMODE)
	
	if not pkPart then return end 
	local entities = IGame.EntityClient:GetAllCreature()
	for i , entity in ipairs(entities) do
		iconPath = nil
		scale = 1
		local entityClass = entity:GetEntityClass()

		if EntityClass:IsMonster( entityClass )then
			local canAttack = pkPart:CanAttack(entity)
		
			iconPath, scale = self:GetMonsterIconPath( entity , canAttack)
			if nil ~= iconPath then
				local uid = entity:GetUID()
				self:RemoveEntityIcon(uid , iconPath )
				self:SetEntityIcon( uid , iconPath ,scale)
			end
		end
    end--]]
end

--刷新单个Icon信息
function MiniMapWidget:RefreshIconByEntityInfo(entity)
	if not self.transform  then
		return
	end
	local heroUID = GetHeroUID()
	local entityClass = entity:GetEntityClass()
	local iconPath = nil
	local scale = 1
	if EntityClass:IsPerson( entityClass ) and entity:GetUID() ~= heroUID then
		iconPath, scale = self:GetPersonIconPath( entity )
	elseif EntityClass:IsMonster( entityClass ) then
		if not self.m_hero then
			self.m_hero = GetHero()
		end
		local pkPart = self.m_hero:GetEntityPart(ENTITYPART_PERSON_PKMODE)
	
		if not pkPart then return end 
	
		local canAttack = pkPart:CanAttack(entity)
		
		iconPath, scale = self:GetMonsterIconPath( entity , canAttack)
	end
	if nil ~= iconPath then
		local uid = entity:GetUID()
		self:RemoveEntityIcon(uid , iconPath )
		self:SetEntityIcon( uid , iconPath ,scale)
	end
end

--定向刷新单个icon信息
function MiniMapWidget:RefreshIconByEntityAndAttack(entity, canAttack)
	
	if not self.transform  then
		return
	end
	local heroUID = GetHeroUID()
	local entityClass = entity:GetEntityClass()
	local iconPath = nil
	local scale = 1
	if EntityClass:IsPerson( entityClass ) and entity:GetUID() ~= heroUID then
		iconPath, scale = self:GetPersonIconPathByAttack( entity , canAttack)
	elseif EntityClass:IsMonster( entityClass ) then
		if canAttack == nil then canAttack = false end
		iconPath, scale = self:GetMonsterIconPath( entity , canAttack)
	end
	if nil ~= iconPath then
		local uid = entity:GetUID()

		self.RemoveList[uid] = true
		self:RemoveEntityIcon(uid , iconPath )
		self:SetEntityIcon( uid , iconPath ,scale)
	end
end

------------------------------------------------------------
--小地图背景按钮被按下
function MiniMapWidget:OnMinimapButtonClick()
	--显示创建场景地图窗体
	UIManager.SceneMapWindow:Show(true)
end
------------------------------------------------------------
--分线按钮被按下
function MiniMapWidget:OnBranchingButtonClick()
	local nMapID = IGame.EntityClient:GetMapID()
    local pMapSchemeInfo = IGame.rktScheme:GetSchemeInfo(MAPINFO_CSV, nMapID)
    if not pMapSchemeInfo then
		return
	end
    
    UIManager.SublineWindow:Show(true, pMapSchemeInfo.lGroupMapID)
end
------------------------------------------------------------
--坐标信息改变
function MiniMapWidget:OnTimerUpdatePositionText()
	local player = IGame.EntityClient:GetHero()
	if player == nil then
		return
	end
    if nil == self.Controls.mapPosText then
        return
    end
	local pos = player:GetPosition()
	local x = math.floor(pos.x)
	local z = math.floor(pos.z)
	self.Controls.mapPosText.text =  "("..tostring(x)..","..tostring(z)..")"
end

function MiniMapWidget:GetSublineTxt()
	local nCurMapID = IGame.EntityClient:GetMapID()
    
    local pMapSchemeInfo = IGame.rktScheme:GetSchemeInfo(MAPINFO_CSV, nCurMapID)
    if not pMapSchemeInfo then
		return ""
	end
    
    local tConfig = MIRROR_MAP_LIST[pMapSchemeInfo.lGroupMapID]
    if not tConfig then
        return ""
    end    
    
    if #tConfig == 0 then
        return
    end
    
    local idx = 0
    for i = 1, #tConfig do
        if tConfig[i] == nCurMapID then
            idx = i
            break
        end
        
    end
    
    return "分线"..idx
end

function MiniMapWidget:UpdateSublineTxt()    
    self.Controls.m_SublineName.text = self:GetSublineTxt()
end
------------------------------------------------------------
--切换场景调用
function MiniMapWidget:OnAfterEnterGameState( eventid , srctype , srcid , stateType )
    if stateType ~= GameStateType.Running then
        return
    end
	self:InitMap()
    self:InitEntityIcons()
    self:UpdateSublineTxt()
end	
------------------------------------------------------------
function MiniMapWidget:OnEnable() 
	self:InitMap()
    self:InitEntityIcons()
    self:UpdateSublineTxt()
end
------------------------------------------------------------
return MiniMapWidget





