-- 休息室界面
-- 显示前后2个小时内的所有活动
-- @Author: XieXiaoMei
-- @Date:   2017-06-07 14:38:44
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-16 16:39:17

local LoungeWindow = UIWindow:new
{
	windowName      = "LoungeWindow",
	m_TimesCfg   	= {},	--时间段活动配置表
	m_ActID			= 0,	--活动ID
	m_ActData		= nil,

	m_IsNewAct   	= false, --是否是新活动，需创建界面cell
	m_TimesCell     = {},	 --时间段cell表

	m_LoungeUpdateCallback = nil, --休息室更新回调
}

local LoungeCell = require("GuiSystem.WindowList.Lounge.LoungeCell")

------------------------------------------------------------
function LoungeWindow:Init()
end

-- 附加初始化
function LoungeWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	local controls = self.Controls
	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_RefreshBtn.onClick:AddListener(handler(self, self.OnBtnRefreshClicked))

	self.m_LoungeUpdateCallback = handler(self, self.OnLoungeUpdateEvt)
	rktEventEngine.SubscribeExecute(EVENT_LOUNGE_UPDATE, 0, 0, self.m_LoungeUpdateCallback)
	
	self:RefreshUI()
end

-- 销毁窗口
function LoungeWindow:OnDestroy()
	rktEventEngine.UnSubscribeExecute( EVENT_LOUNGE_UPDATE , 0 , 0 , self.m_LoungeUpdateCallback )

	self:DestroyCells()

	UIWindow.OnDestroy(self)

	table_release(self)
end

-- 显示窗口
function LoungeWindow:ShowWindow(actID, bringTop)
	local data = IGame.OpeningActivitiesMgr:ActivityAt(actID)
	if isTableEmpty(data) then
		return
	end
	self.m_ActData = data

	self.m_IsNewAct = (self.m_ActID == 0) or (actID ~= self.m_ActID)
	self.m_ActID  = actID

	UIWindow.Show(self, bringTop)

	if self:isLoaded() then
		self:RefreshUI()
	end
end

-- 休息室更新事件回调
function LoungeWindow:OnLoungeUpdateEvt(_, _, _, actID)
	if not self:isShow() then
		return
	end
	self:ShowWindow(actID)
end

-- 刷新界面
function LoungeWindow:RefreshUI()
	self:DestroyCells()

	self:SetTitleDesc()

	self:LoadTimesCfg()
	self:CreateCells()
end

-- 设置标题描述
function LoungeWindow:SetTitleDesc()
	local actWndCfg = IGame.rktScheme:GetSchemeInfo(ACTIVITYWINDOW_CSV, self.m_ActID)
	if isTableEmpty(actWndCfg) then
		uerror("actWndCfg can't equaly nil! actID:" .. self.m_ActID)
		return
	end

	local controls = self.Controls
	controls.m_TitleTxt.text = string.format("%s报名", actWndCfg.Name)
	controls.m_ActDescTxt.text = actWndCfg.ActDesc
end

-- 加载全部时间段配置
function LoungeWindow:LoadTimesCfg()
	local timeID = self.m_ActData.timeID

	local allTimesCfg = {}
	local timesCfg = IGame.rktScheme:GetSchemeTable( ACTIVITYTIME_CSV )
	local timeCfg = timesCfg[tostring(timeID)]
	if isTableEmpty(timeCfg) then
		uerror("timeCfg can't equaly nil! timeID:" .. timeID)
		return
	end


	local startWeek  = timeCfg.StartWeek
	local endWeek  = timeCfg.EndWeek
	local todayTimesCfg = {}
	for i, v in pairs(timesCfg) do
		if tonumber(v.ActID) == self.m_ActID and  -- 拿到当天的活动time条目
		 startWeek == v.StartWeek and
		 endWeek == v.EndWeek then
			table.insert(todayTimesCfg, v)
		end
	end

	local startTime = split_string(timeCfg.StartTime, ":")
	local startHour = tonumber(startTime[1])

	for i, v in pairs(todayTimesCfg) do -- 拿到前后一个小时的活动time条目
		local startTime = split_string(v.StartTime, ":")
		local hour = tonumber(startTime[1])
		if hour >= startHour - 1 and hour <= startHour + 1 then
			table.insert(allTimesCfg, v)
		end
	end

	table.sort(allTimesCfg, function (a, b) -- 按照时间排序，从早到晚
		local timeA = split_string(a.StartTime, ":")
		local timeB = split_string(b.StartTime, ":")
		local hourA = tonumber(timeA[1])
		local hourB = tonumber(timeB[1])
		return hourA < hourB or 
			(hourA == hourB and 
			tonumber(timeA[2]) < tonumber(timeB[2]))
	end)

	self.m_TimesCfg = allTimesCfg
end

-- 创建时间段元素
function LoungeWindow:CreateCells()
	local content = self.Controls.m_Content

	for i, v in ipairs(self.m_TimesCfg) do
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.LoungeCell , 
	   	function( path , obj , ud )
			if nil ~= obj then
				obj.transform:SetParent(content, false)
			
				local cell = LoungeCell:new({})
				cell:Attach(obj)
				cell:SetData(v, i, self.m_ActData.timeID)

				self.m_TimesCell[v.TimeID] = cell
			end
		end, nil, AssetLoadPriority.GuiNormal )
	end 
end

-- 重加载时间段元素
function LoungeWindow:ReloadCells()
	for i, v in ipairs(self.m_TimesCfg) do
		local cell = self.m_TimesCell[v.TimeID]
		cell:SetData(v, i, self.m_ActData.timeID)
	end
end

-- 销毁时间段元素
function LoungeWindow:DestroyCells()
	for i, v in pairs(self.m_TimesCell) do
		v:Recycle() --回收
	end
	self.m_TimesCell = {}
end

------------------------------------------------------------

-- 刷新按钮回调
function LoungeWindow:OnBtnRefreshClicked()
	GameHelp.PostServerRequest("RequestReadyRoom_ActorNum()")	
end

--  关闭按钮回调
function LoungeWindow:OnBtnCloseClicked()
	self:Hide()
end


return LoungeWindow