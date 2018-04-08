--/******************************************************************
--** 文件名:	RideWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	何水大(765865368@qq.com)
--** 日  期:	2017-12-08
--** 版  本:	1.0
--** 描  述:	外观窗口-坐骑子窗口
--** 应  用:  
--******************************************************************/

-- 坐骑获得途径
local RideGetType = 
{
	System = 0, -- 系统送的
	Tame = 1, -- 驯马
	Buy = 2, -- 购买
}

local RideItem = require("GuiSystem.WindowList.Appearance.Ride.RideItem")

local RideWidget = UIControl:new
{
	windowName = "RideWidget",
	
	m_ArrSubscribeEvent = {},		-- 绑定的事件集合:table(string, function())
	
	m_CurrentRideID = 0, -- 当前选中的坐骑ID
	
	m_RideInfo = {},
	m_RideConfig = {},
	m_firstShow = true, -- 初次显示
	
	m_SelectRideID = 0, -- 当前选中的坐骑ID
	m_CurResID = 0, -- 当前坐骑模型ID
}

function RideWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	
	self.m_firstShow = true
	
	self.m_RideConfig = {}
	local cfg = IGame.rktScheme:GetSchemeTable(RIDE_CSV)
		
	if not cfg then
		uerror("【坐骑系统】RideSkin.csv为空")
		return
	end
	
	for k, v in pairs(cfg) do
		table.insert(self.m_RideConfig, v)
	end
	
	table.sort(self.m_RideConfig, function (a, b)
			if a.Index < b.Index then
				return true
			end
			return a.RideID < b.RideID
		end)
	
	local controls = self.Controls
	
	self.Group = controls.m_RideListScroller:GetComponent(typeof(ToggleGroup))
	--绑定EnhanceScroller事件
	self.DragListView = controls.m_RideListScroller:GetComponent(typeof(EnhancedListView))
	self.callBackOnGetCellView = function(objCell) self:OnGetCellView(objCell) end
	self.enhanceListView = controls.m_RideListScroller:GetComponent(typeof(EnhancedListView))
	self.callBackTargetTeamCellVis = function(objCell) self:OnGetSkillItemVisiable(objCell) end
	self.enhanceScroller = controls.m_RideListScroller:GetComponent(typeof(EnhancedScroller))
	if self.enhanceListView ~= nil then 
		self.enhanceListView.onGetCellView:AddListener(self.callBackOnGetCellView)
		self.enhanceListView.onCellViewVisiable:AddListener(self.callBackTargetTeamCellVis)
	end
	
	self.onButtonTameClick = function() self:OnButtonTameClick() end
	controls.m_ButtonTame.onClick:AddListener(self.onButtonTameClick)
	
	self.onButtonBuyClick = function() self:OnButtonBuyClick() end
	controls.m_ButtonBuy.onClick:AddListener(self.onButtonBuyClick)
	
	self.onButtonMountClick = function() self:OnButtonMountClick() end
	controls.m_ButtonMount.onClick:AddListener(self.onButtonMountClick)
	controls.m_ButtonDisMount.onClick:AddListener(self.onButtonMountClick)
	
	-- 事件绑定
	self:SubscribeEvent()
end

--EnhancedListView 创建实体回调
function RideWidget:OnGetCellView(objCell)
	local item = RideItem:new()
	local enhancedCell = objCell:GetComponent(typeof(EnhancedListViewCell))
	enhancedCell.onRefreshCellView = handler(self, self.OnGetSkillItemVisiable)
	item:SetGroup(self.Group)
	item:Attach(objCell)
end

--EnhancedListView 创建实体可见
function RideWidget:OnGetSkillItemVisiable(objCell)
	local viewCell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))
	local behav = objCell:GetComponent(typeof(UIWindowBehaviour))
	if nil ~= behav then
		local item = behav.LuaObject
		local schemeId = self.m_RideConfig[viewCell.cellIndex+1].RideID
		item:UpdateItem(schemeId)
		
		if self.m_firstShow then
			if viewCell.dataIndex == 0 then
				item:SetFocus(true)
				self.m_firstShow = false
			end
		else
			item:SetFocus(self.m_CurrentRideID == schemeId)
		end
	end	
end

function RideWidget:UpdateRideItemShow()

	local count =-1
	count = self.DragListView.CellCount
	local cfgCount = #self.m_RideConfig
	if cfgCount ~= count then 
		self.enhanceListView:SetCellCount(cfgCount, true )	
	else
		self.enhanceScroller:RefreshActiveCellViews()
	end

end

-- 窗口销毁
function RideWidget:OnDestroy()
    -- 移除事件的绑定
    self:UnSubscribeEvent()
	local controls = self.Controls
	controls.m_ButtonTame.onClick:RemoveListener(self.onButtonTameClick)
	self.onButtonTameClick = nil

	controls.m_ButtonBuy.onClick:RemoveListener(self.onButtonBuyClick)
	self.onButtonBuyClick = nil

	controls.m_ButtonMount.onClick:RemoveListener(self.onButtonMountClick)
	controls.m_ButtonDisMount.onClick:RemoveListener(self.onButtonMountClick)
	self.onButtonMountClick = nil
	
	self.m_CurResID = 0
	
    UIControl.OnDestroy(self)
end

function RideWidget:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

-- 事件绑定
function RideWidget:SubscribeEvent()
	
	self.m_ArrSubscribeEvent = 
	{
		{
			e = ENTITYPART_CREATURE_RIDE, s = SOURCE_TYPE_SYSTEM, i = RIDE_UI_EVENT_RIDE_ITEM_CLICK,
			f = function(event, srctype, srcid, rideId) self:HandleUI_RideItemClick(rideId) end,
		},
		{
			e = ENTITYPART_CREATURE_RIDE, s = SOURCE_TYPE_SYSTEM, i = RIDE_UI_EVENT_RIDE_STATE,
			f = function(event, srctype, srcid, rideId) self:SetRideState(rideId) end,
		},
		{
			e = ENTITYPART_CREATURE_RIDE, s = SOURCE_TYPE_SYSTEM, i = RIDE_UI_EVENT_RIDE_NUM,
			f = function(event, srctype, srcid, rideID) self:RideNumChange(rideID) end,
		},
		{
			e = EVENT_CION_YUANBAO, s = SOURCE_TYPE_COIN, i = 0,
			f = function(event, srctype, srcid) self:OnZuanShiChange() end,
		},
	}
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.SubscribeExecute(v.e, v.s, v.i, v.f)
	end
	
	self:InitModelEvts()
end

-- 移除事件的绑定
function RideWidget:UnSubscribeEvent()
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.UnSubscribeExecute(v.e, v.s, v.i, v.f)
	end
	
	self:RemoveModelEvts()
end

-- 显示窗口
function RideWidget:ShowWindow()
	
	UIControl.Show(self)
	self:UpdateRideItemShow()
end

-- 隐藏窗口
function RideWidget:HideWindow()
	
	UIControl.Hide(self, false)
	
end

function RideWidget:ShowRideDetail(rideId)
	self.m_CurrentRideID = rideId
	
	local scheme = IGame.rktScheme:GetSchemeInfo(RIDE_CSV, rideId)
	if not scheme then
		uerror("RideWidget:HandleUI_RideItemClick，坐骑ID不存在，id:" .. rideId)
		return
	end
	
	local controls = self.Controls
	controls.m_TextPro.text = string_unescape_newline(scheme.ProDes)
	controls.m_TextDesc.text = string_unescape_newline(scheme.Desc)
	
	local ridePart = IGame.RideClient:GetHeroRidePart()
    if not ridePart then
        return
    end
	
	local rideInfo = ridePart:GetRidelInfo()
	if not rideInfo then
		return
	end
	
	self.m_SelectRideID = rideId
	
	controls.m_TextSource.gameObject:SetActive(false)
	controls.m_ButtonBuy.gameObject:SetActive(false)
	controls.m_ButtonMount.gameObject:SetActive(false)
	controls.m_ButtonDisMount.gameObject:SetActive(false)
	controls.m_ButtonTame.gameObject:SetActive(false)
	
	-- 设置星星
	for i = 1, 5 do
		controls["m_Star" .. i].gameObject:SetActive(false)
	end
	
	local quality = scheme.Quality
	for i = 1, quality do
		controls["m_Star" .. i].gameObject:SetActive(true)
	end
	
	-- 设置坐骑模型
	self:ShowMonsterModel(rideId, scheme.ResourceID)
	
	local isHave = table_indexof_match(rideInfo.m_SkinTable, function( v ) return rideId == v.m_SerialNO end)
	-- 已经拥有坐骑
	if isHave then
		if rideInfo.m_SerialNoUsing == rideId and RIDE_STATE_MOUNT == rideInfo.m_RideState then
			controls.m_ButtonDisMount.gameObject:SetActive(true)
		else
			controls.m_ButtonMount.gameObject:SetActive(true)
		end
		return
	else
		-- 判断坐骑能不能捕捉
		if scheme.GetType == RideGetType.Tame then
			local skillLevel = -1
			local hero = GetHero() 
			if hero then 
				local skillPart = hero:GetEntityPart(ENTITYPART_PERSON_LIFESKILL)
				if skillPart then
					skillLevel = skillPart:GetLifeSkillLevel(emTame)
				end
			end
			
			local tameCfg = IGame.rktScheme:GetSchemeTable(LIFESKILLTAME_CSV)
			local canTame = false
			for k, v in pairs(tameCfg) do
				if rideId == v.ID then
					canTame = skillLevel >= v.Level
					break
				end
			end
			
			if canTame then
				controls.m_ButtonTame.gameObject:SetActive(true)
				return
			end
		elseif scheme.GetType == RideGetType.Buy then
			local zuanshi = GetHero():GetCurrency(emCoinClientType_YuanBao)
			local needMoney = scheme.Money

			if zuanshi < needMoney then
				controls.m_TextMoney.text = string.format("<color=#e4595a>%d</color>", needMoney)
			else
				controls.m_TextMoney.text = needMoney
			end
			controls.m_ButtonBuy.gameObject:SetActive(true)
			return
		end
	end
	
	controls.m_TextSource.text = scheme.Source
	controls.m_TextSource.gameObject:SetActive(true)
end

function RideWidget:HandleUI_RideItemClick(rideId)
	self:ShowRideDetail(rideId)
end

-- 设置坐骑状态（上下马）
function RideWidget:SetRideState(rideID)
	if self.m_SelectRideID ~= rideID then
		return
	end
	
	local ridePart = IGame.RideClient:GetHeroRidePart()
    if not ridePart then
        return
    end
	
	local rideInfo = ridePart:GetRidelInfo()
	if not rideInfo then
		return
	end
	
	if rideInfo.m_SerialNoUsing == rideID and RIDE_STATE_MOUNT == rideInfo.m_RideState then
		self.Controls.m_ButtonDisMount.gameObject:SetActive(true)
		self.Controls.m_ButtonMount.gameObject:SetActive(false)
	else
		self.Controls.m_ButtonDisMount.gameObject:SetActive(false)
		self.Controls.m_ButtonMount.gameObject:SetActive(true)
	end
end

function RideWidget:OnButtonTameClick()
	if IGame.LifeSkillClient:GoToTame(self.m_SelectRideID) then
		UIManager.AppearanceWindow:Hide()
	end
end
	
function RideWidget:OnButtonBuyClick()
	local rideID = self.m_SelectRideID
	if IGame.RideClient:IsHaveTheRide(rideID) then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你已经拥有这个坐骑")
		return
	end
	
	local scheme = IGame.rktScheme:GetSchemeInfo(RIDE_CSV, rideID)
	if not scheme then
		uerror("RideWidget:HandleUI_RideItemClick，坐骑ID不存在，id:" .. rideID)
		return
	end
	
	local needMoney = scheme.Money
	if GameHelp:DiamondNotEnoughSwitchRecharge(needMoney) then
		return
	end
	
	local callBack = function()
		GameHelp.PostServerRequest(string.format("RequestRide_Buy(%d)", rideID))
	end
	
	local data = 
	{
		content = string.format("是否花费<color=#008000>%d</color>钻石购买[%s]？", needMoney, scheme.Name),
		confirmBtnTxt = "确定",
		cancelBtnTxt = "取消",
		confirmCallBack = callBack,
	}	
	
	UIManager.ConfirmPopWindow:ShowDiglog(data)
end

function RideWidget:OnButtonMountClick()
	local curRideID = IGame.RideClient:GetCurrentRideID()
	if self.m_SelectRideID == curRideID then
		IGame.RideClient:OnRequestMount()
	else
		IGame.RideClient:ChangeRide(self.m_SelectRideID)
	end
end

function RideWidget:RideNumChange(rideID)
	self:UpdateRideItemShow()
	
	if rideID == self.m_SelectRideID then
		self:ShowRideDetail(rideID)
	end
end

-- 设置坐骑模型
function RideWidget:ShowMonsterModel(nRideID, nResourceID)
	if nResourceID == self.m_CurResID then
		return
	end
	
	self.m_CurResID = nResourceID
	
	local tPostionCfg = gRideWinModelCfg[nRideID]
	
	if self.m_ModelObject then
		self.m_ModelObject:Destroy()
	end
	
	local param = {}
	param.entityClass = tEntity_Class_Monster
    param.layer = "UI"
    param.Name = "RideModel"
	param.Position = Vector3.New(tPostionCfg.ModelPosition[1], tPostionCfg.ModelPosition[2], tPostionCfg.ModelPosition[3])
	param.localScale  =  Vector3.New(tPostionCfg.ModelScale[1], tPostionCfg.ModelScale[2], tPostionCfg.ModelScale[3])
	param.rotate = Vector3.New(tPostionCfg.Rotation[1], tPostionCfg.Rotation[2], tPostionCfg.Rotation[3])
	param.MoldeID =  nResourceID
	param.ParentTrs = self.Controls.m_RideModel.transform
	param.UID = GUI_ENTITY_ID_RIDE
	
	self.m_ModelObject = UICharacterHelp:new()
	self.m_ModelObject:Create(param)
end

function RideWidget:InitModelEvts()
	
	self.m_OnDragModel = function(eventData) self:OnDragModel(eventData) end
	UIFunction.AddEventTriggerListener(self.Controls.m_RideModel, EventTriggerType.Drag, self.m_OnDragModel)
	
	self.m_OnClickModel = function(eventData) self:OnClickModel(eventData) end
	UIFunction.AddEventTriggerListener(self.Controls.m_RideModel, EventTriggerType.PointerClick, self.m_OnClickModel)
end

function RideWidget:RemoveModelEvts()
	UIFunction.RemoveEventTriggerListener(self.Controls.m_RideModel, EventTriggerType.Drag, self.m_OnDragModel)
	self.m_OnDragModel = nil
	
	UIFunction.RemoveEventTriggerListener(self.Controls.m_RideModel, EventTriggerType.PointerClick, self.m_OnClickModel)
	self.m_OnClickModel = nil
end

function RideWidget:OnDragModel(eventData)
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_RIDE)
	if nil ~= entityView then
		entityView.transform:Rotate(-Vector3.up *eventData.delta.x * 30.0 * Time.deltaTime, UnityEngine.Space.Self);
	end
end

function RideWidget:OnClickModel(eventData)
	local pressPosition =  eventData.pressPosition
	local CurrentPosition =  eventData.position
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_RIDE)
	if nil == entityView then 
		return
	end
	local X = math.abs(pressPosition.x - CurrentPosition.x)
	local Y = math.abs(pressPosition.y - CurrentPosition.y)
	if  X > 0.1 or Y >0.1 then 
		return
	end

	local effectContext = rkt.EntitySkillEffectContext.New()
	effectContext.BodyPart = EntityBodyPart.Skeleton
	effectContext.AnimName = "rest"
	effectContext.RevertToStandAnim = true
	effectContext.EventLayerMask = AnimationEventLayer.TableToMask( {1} )
	entityView:PlayExhibit(effectContext)
end

function RideWidget:OnZuanShiChange()
	self:ShowRideDetail(self.m_CurrentRideID)
end

return RideWidget