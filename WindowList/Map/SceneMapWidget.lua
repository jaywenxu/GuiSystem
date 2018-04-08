--场景地图的组件
------------------------------------------------------------
require("rkt.MapControl")
local NPCListNavItem = require("GuiSystem.WindowList.Map.NPCListNavItem")    --加载npcItem模块
local NPCIconItem = require("GuiSystem.WindowList.Map.NPCIconItem")    --加载npcItem模块

------------------------------------------------------------
local SceneMapWidget = UIControl:new
{
    windowName = "SceneMapWidget" ,
    needInitMap = true ,
	updateInterval = 0.1,						 --地图坐标信息更新时间间隔
	
	npcListContentOriginPos,					 --右边npc列表最初位置信息
	
	listItemTable = {},							 --右边npc列表的实例
	listImageItemTable = {},					 --左边npc的实例
	m_selectItem = nil,							--当前选中nPC
	m_NpcImgActList = {}, 						 --活动的服务器下发的NPC图标列表
}
------------------------------------------------------------
function SceneMapWidget:Attach( obj )
	UIControl.Attach(self,obj)
    
	self:Setting()
	
	self:SubscribeExec()
end
------------------------------------------------------------
function SceneMapWidget:OnDestroy()
	UIControl.OnDestroy(self)

    rktTimer.KillTimer( slot( self.OnPositionTextChanged , self ) )

	self:UnSubscribeExec()
	self.m_selectItem = nil
    self.needInitMap = true

end
------------------------------------------------------------
function SceneMapWidget:SubscribeExec()
	rktEventEngine.SubscribeExecute( EVENT_AFTER_ENTER_GAMESTATE , 0 , 0 , self.OnAfterEnterGameState , self )
	rktEventEngine.SubscribeExecute( EVENT_SCENE_MAP_NPC_RVM , 0 , 0 , self.OnRmvActNpcImg , self )
	rktEventEngine.SubscribeExecute( EVENT_SCENE_MAP_NPC_LIST , 0 , 0 , self.OnInitActNpcImgs , self )
	rktEventEngine.SubscribeExecute( EVENT_SCENE_MAP_NPC_MOVING , 0 , 0 , self.OnUpMovingNpcImgs , self )
end

------------------------------------------------------------
function SceneMapWidget:UnSubscribeExec()
	rktEventEngine.UnSubscribeExecute( EVENT_AFTER_ENTER_GAMESTATE , 0 , 0 , self.OnAfterEnterGameState , self )
	rktEventEngine.UnSubscribeExecute( EVENT_SCENE_MAP_NPC_RVM , 0 , 0 , self.OnRmvActNpcImg , self )
	rktEventEngine.UnSubscribeExecute( EVENT_SCENE_MAP_NPC_LIST , 0 , 0 , self.OnInitActNpcImgs , self )
	rktEventEngine.UnSubscribeExecute( EVENT_SCENE_MAP_NPC_MOVING , 0 , 0 , self.OnUpMovingNpcImgs , self )
end
------------------------------------------------------------
function SceneMapWidget:Setting()
    self.Controls.m_MapControl = self.Controls.imageRectTransform:GetComponent(typeof(rkt.MapControl))
    self:AddListener( self.Controls.m_MapControl , "onClick" , self.OnMapButtonClick , self )
    self:AddListener( self.unityBehaviour , "onEnable" , self.OnEnable , self )
    self:AddListener( self.unityBehaviour , "onDisable" , self.OnDisable , self )

	self.npcListContentOriginPos = self.Controls.m_NPCScrollRect.content.localPosition

    self.needInitMap = true

    if self:isShow() then
        self:OnEnable()
    end
end
------------------------------------------------------------
--初始化操作
function SceneMapWidget:InitMap()
	self.needInitMap = false

	for i = 1,table.maxn(self.listItemTable) do
		self.listItemTable[i]:RecycleItem()
	end
	
	for i = 1,table.maxn(self.listImageItemTable) do
		self.listImageItemTable[i]:RecycleItem()
	end

	self:RmvAllActiveNpcDots()

	self.listItemTable = {}
	self.listImageItemTable = {}

	
	--加载MapInfo.csv文件，获取当前场景地图配置信息
	local mapID = IGame.EntityClient:GetMapID()										--获取当前地图ID
	local mapInfo = IGame.rktScheme:GetSchemeInfo(MAPINFO_CSV, mapID )				--获取对应mapID的地图信息
	local path = AssetPath.MapImgTexturePath..mapInfo.mapPath							--地图ID信息
	print("世界地图 mapID：", mapID, " mapPath:", mapInfo.mapPath)
	UIFunction.SetRawImageSprite(self.Controls.imageRectTransform:GetComponent(typeof(UnityEngine.UI.RawImage)), path)			--设置地图背景图片
	local name = mapInfo.szName														--当前地图名称
	self.Controls.m_MapNameText.text = name											--设置当前地图名称

    local minPos = Vector2.New( mapInfo.LBPosition[1] , mapInfo.LBPosition[2] )
    local maxPos = Vector2.New( mapInfo.RTPosition[1] , mapInfo.RTPosition[2] )

    self.Controls.m_MapControl:SetMapBounds( minPos , maxPos )

	--初始化所有NPC角色
	self:InitNpcImage(mapID,self.lbPosV2)
	self:InitNPCList(mapID)
end
------------------------------------------------------------
--地图点击设置点击logo
function SceneMapWidget:SetClickLogo(position)
	local pos = self.Controls.m_MapControl:SceneCoordinateToUI(position)
	self.Controls.m_ClickIcon.gameObject:SetActive(true)
	self.Controls.m_ClickIcon.localPosition = pos
end
------------------------------------------------------------
--地图点击事件
function SceneMapWidget:OnMapButtonClick(position)
	local ptSrc = GetHero():GetPosition()
    local res_src , src_pos = rktNavMesh.SamplePosition( ptSrc , 2 , rktNavMesh.WalkableAndWaterAreaMask )
    print( "minimap find path : " , tostring(ptSrc) , tostring(src_pos) )
    if not res_src then
        IGame.ChatClient:addSystemTips(TipType_Operate,InfoPos_ActorUnder, "当前位置无法导航")
        return
    end
    local target = Vector3.New(position.x,500,position.z)
	local res , hitInfo = Physics.Raycast( target , Vector3.down , nil , 1000 , rktNavUtility.SampleNavPathRaycastLayerMask ) --向position正下方发射射线，检测地形高度
	if res then
        target = hitInfo.point
    else
        target = Vector3.New(position.x,ptSrc.y,position.z)
	end

    local res1 , valid_pos = rktNavMesh.SamplePosition( target , 20 , rktNavMesh.WalkableAndWaterAreaMask ) -- 尝试20次，以找到一个合适的点
    if not res1 then
        IGame.ChatClient:addSystemTips(TipType_Operate,InfoPos_ActorUnder, "该位置不可到达")
        return
    end
    
    --print( "导航网格采样最近的点: " .. tostring( target ) .. " , " .. tostring(res) .. " , " .. tostring(valid_pos) )

	local res2 = rktNavMesh.TestPath( ptSrc, valid_pos , 10 )
	if not res2 then
		IGame.ChatClient:addSystemTips(TipType_Operate,InfoPos_ActorUnder, "该位置不可到达")
		return
	end
	IGame.ItemVisitorController:VisitGround( valid_pos , true, true,true)
	rktMainCamera.FollowEntity()	--将相机慢慢移动到角色的身后

	self:SetClickLogo(valid_pos)
end
------------------------------------------------------------
--初始化NPC Image位置信息（通过CSV配置表获取）
--mapID 地图ID
function SceneMapWidget:InitNpcImage(mapID)
	
	for i = 1,table.maxn(self.listImageItemTable) do
		self.listImageItemTable[i]:DestroyItem()
	end
	self.listImageItemTable = {}
	
	local npcInfo = IGame.Navigation:GetCurMapNavigationList(mapID)
	if nil == npcInfo then
		return
	end
	
    local mapCtrl = self.Controls.m_MapControl
	for k,v in pairs(npcInfo) do
		for i,j in pairs(v) do
			if j.nShowIcon ~= nil and j.nShowIcon == 1 then
				local pos = mapCtrl:SceneCoordinateToUI(j.ptPos)
				local parentTransform = self.Controls.m_OtherIcon.transform
				local item = NPCIconItem.CreateItem(parentTransform, j, pos)
				table.insert(self.listImageItemTable,item)
			end
		end
	end
end
------------------------------------------------------------
--初始化场景地图NPC列表
function SceneMapWidget:InitNPCList(mapID)

	for i = 1,table.maxn(self.listItemTable) do
		self.listItemTable[i]:DestroyItem()
	end
	
	self.listItemTable = {}
	
	local npcInfo = IGame.Navigation:GetCurMapNavigationList(mapID)
	
	if nil == npcInfo then
		return
	end

	local parentTransform = self.Controls.m_MapNPCList.transform
	local sortNpcList = {} 
	for k,v in pairs(npcInfo) do -- 对Npc进行排序
		for i,j in pairs(v) do
			if j.nShortCut ~= nil and j.nShortCut == 1 then
				sortNpcList[i] = j
			end
		end
	end

	for i, npc in ipairs(sortNpcList) do
		local item = NPCListNavItem.CreateItem(npc, parentTransform)
		table.insert(self.listItemTable,item)
	end
end
		
------------------------------------------------------------

--初始化活动的NPC列表（静态和动态的）
function SceneMapWidget:OnInitActNpcImgs( eventid , srctype , srcid )
	local posList = IGame.MapEntityPos:GetPosList()
	self:InitActNpcByList(posList)

	local movingPosList = IGame.MapEntityPos:GetMovingPosList()
	self:InitActNpcByList(movingPosList)
end

------------------------------------------------------------
-- 更新移动的NPC图标表
function SceneMapWidget:OnUpMovingNpcImgs( eventid , srctype , srcid )
	local movingPosList = IGame.MapEntityPos:GetMovingPosList()
	self:InitActNpcByList(movingPosList)
end

------------------------------------------------------------
--更新活动NPC通过列表
function SceneMapWidget:InitActNpcByList(npcPosList)
    local mapCtrl = self.Controls.m_MapControl
	for i, v in pairs(npcPosList) do
		v.nSerial = i
		local pos = mapCtrl:SceneCoordinateToUI(v)
		if self.m_NpcImgActList[i] then
			self.m_NpcImgActList[i]:UpdateItemPos(pos)
		else
			self:AddActNpcImg(v, pos)
		end
	end
end
------------------------------------------------------------
--增加一个场景地图活动的NPC
function SceneMapWidget:AddActNpcImg(info, pos)
	local actNpc = --重构结构
	{
		nType 	 		= info.nLayerType,
		nMapEntityPosID = info.nIcon,
		szName 			= info.strName,
		nHP 			= info.nHP,
		nHPMax 			= info.nHPMax,
	}

	local parentTransform = self.Controls.m_OtherIcon_dyn.transform
	local item = NPCIconItem.CreateItem(parentTransform, actNpc, pos, true)
	self.m_NpcImgActList[info.nSerial] = item
end
------------------------------------------------------------
-- 删除所有的活动的NPC点
function SceneMapWidget:RmvAllActiveNpcDots()
	for k, v in pairs(self.m_NpcImgActList) do
		v:RecycleItem()
	end
	self.m_NpcImgActList = {}	
end
------------------------------------------------------------
-- 删除单个活动的NPC
function SceneMapWidget:OnRmvActNpcImg( eventid , srctype , srcid , serialID )
	local item = self.m_NpcImgActList[serialID]
	if item then
		item:RecycleItem()
	end
	self.m_NpcImgActList[serialID] = nil
end

------------------------------------------------------------
--地图坐标更新
function SceneMapWidget:OnPositionTextChanged()
	local player = IGame.EntityClient:GetHero()
	if player == nil then
		return
	end
	local pos = player:GetPosition()
	local x = math.floor(pos.x)
	local z = math.floor(pos.z)
	
	self.Controls.m_PositionText.text = "("..tostring(x)..","..tostring(z)..")"
end
------------------------------------------------------------
function SceneMapWidget:OnEnable()
	self.Controls.m_NPCScrollRect.content.localPosition = self.npcListContentOriginPos
    if self.needInitMap then
       	self:InitMap()
    end
    rktTimer.SetTimer( slot( self.OnPositionTextChanged , self ) , 100 , -1 , "SceneMapWidget:OnPositionTextChanged" )
end

function SceneMapWidget:OnDisable()
    rktTimer.KillTimer( slot( self.OnPositionTextChanged , self ) )
	IGame.MapEntityPos:KillTimerMoving()
	self:RmvAllActiveNpcDots()
end

------------------------------------------------------------
--切换场景后重置地图
function SceneMapWidget:OnAfterEnterGameState( eventid , srctype , srcid , stateType )
    if stateType == GameStateType.Running then
        self.needInitMap = true
        if self:isShow() then
	        self:InitMap()
        end
    end
end	

------------------------------------------API------------------------------------------------------

------------------------------------------------------------
-- 去往指定npc，与npc对话
function SceneMapWidget:GotoChatWithNpc(navigation,item)
	
	local ptSrc = GetHero():GetPosition()
	local mapID = navigation.mapid
	local pos = navigation.ptPos
	local npcid = navigation.nMonsterID
	
	if item ~= nil then 
		if self.m_selectItem ~= nil then 
			self.m_selectItem:SetSelectImageActive(false)
		end
		self.m_selectItem = item
	end

	--访问npc位置
	if npcid and npcid > 0 then
		--先判断npc的位置点是否路径合法，如果合法就触发npc对话，否则就找到一个合法的路径点走过去
		local _path , _status = rktNavMesh.FindValidPath( ptSrc, pos )
		if nil ~= _path then
			CommonApi:TalkWithMapNPC(mapID, pos.x, pos.y, pos.z, npcid)
		else	
			--如果NPC配置是一个非法点，就寻找npc附近的一个点走过去
			self:GoToPos(ptSrc , pos)
		end

		local sceneWdt = UIManager.SceneMapWindow:GetSceneWidget()
		if sceneWdt then
			sceneWdt:SetClickLogo(pos)
		end
	end
end

------------------------------------------------------------
--走向地图的一个点
--ptSrc 起始点
--ptDes 终止点
function SceneMapWidget:GoToPos(ptSrc , ptDes)
	local res1 , valid_pos = rktNavMesh.SamplePosition( ptDes , 20 ) -- 尝试20次，以找到一个合适的点
	if not res1 then
		IGame.ChatClient:addSystemTips(TipType_Operate,InfoPos_ActorUnder, "该位置不可到达")
		return
	end
	local path , status = rktNavMesh.FindValidPath( ptSrc, valid_pos )
	if nil == path then
		IGame.ChatClient:addSystemTips(TipType_Operate,InfoPos_ActorUnder, "该位置不可到达")
		return
	end
	IGame.ItemVisitorController:VisitGround( valid_pos , true, true)

	self:SetClickLogo(valid_pos)
end
------------------------------------------------------------

------------------------------------------------------------
--画一个圈
function SceneMapWidget:drawCircle(RectTransform,DrwaLineWidth,LineColor,Position,Radius,PointNum)
	if RectTransform ==nil then 
		return
	end
	local drawCircle = RectTransform:GetComponent(typeof(DrawCircle))
	if nil == drawCircle then 
		drawCircle = RectTransform.gameObject:AddComponent(typeof(DrawCircle))
	end
	local uiPosition = nil
	--从世界坐标转换场景坐标
	if self.Controls.m_MapControl ~=nil then 
		uiPosition = self.Controls.m_MapControl:SceneCoordinateToUI(Position)
	end
	if nil == uiPosition then 
		return
	end
	drawCircle:DrawCurrentCircle(DrwaLineWidth,LineColor,uiPosition,Radius,PointNum)

end
------------------------------------------------------------

------------------------------------------------------------
--画一个危险区的圈
--ShowState 显示还是隐藏
--isSaftyCircle 是否是安全区的圈
--DrwaLineWidth 圈的宽度
-- LineColor 圈的颜色
-- Position 圈的中心点位置
--Radius	圈的半径
--PointNum 圈的点数量 越大越圆

function SceneMapWidget:DrawCircle(ShowState,isSaftyCircle,DrwaLineWidth,LineColor,Position,Radius,PointNum)
	
	if self.transform == nil then 
		return
	end
	
	if PointNum == nil then 
		PointNum = 60	
	end
	
	
	if isSaftyCircle == true then 
		if ShowState ==true then 
			self:drawCircle(self.Controls.m_safetyCircle,DrwaLineWidth,LineColor,Position,Radius,PointNum)
			self.Controls.m_safetyCircle.gameObject:SetActive(true)
			
		else
			self.Controls.m_safetyCircle.gameObject:SetActive(false)
		end
		
	else
		if ShowState == true then 
			self:drawCircle(self.Controls.m_dangerCircle,DrwaLineWidth,LineColor,Position,Radius,PointNum)
			self.Controls.m_dangerCircle.gameObject:SetActive(true)
		else
			self.Controls.m_dangerCircle.gameObject:SetActive(false)
		end
				
	end

end
------------------------------------------------------------

return SceneMapWidget