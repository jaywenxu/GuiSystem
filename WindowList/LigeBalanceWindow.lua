-------------------------------------------------------------------
-- @Author: XieXiaoMei
-- @Date:   2017-08-07 11:49:12
-- @Vers:	1.0
-- @Desc:	领地战结算窗口
-------------------------------------------------------------------

local LigeBalanceWindow = UIWindow:new
{
	windowName  = "LigeBalanceWindow",
		
	m_LogbuchCells = {},-- 战况cell列表
	m_RankList = {},	-- 贡献排行列表

	m_RanksUpCallBack = nil,    
	m_RankReqStartIdx = 0, 		 -- 贡献排行索引

	m_RanksReqFlag = -1, 	 -- 排行表请求标记
	m_RanksCellLoadFlag = false, 	 -- 排行表请求标记
	m_LogbuchesLoadFlag = false, -- 战况加载标记
}

local HGLYRankCell = require( "GuiSystem.WindowList.HuoGongLiangYing.HGLYRankCell" )
local LigeBalceLogCell = require("GuiSystem.WindowList.LigeanceFight.LigeBalceLogCell")

local LigeanceEctype = IGame.LigeanceEctype

local this = LigeBalanceWindow

------------------------------------------------------------
function LigeBalanceWindow:Init()
	Debugger.Log("LigeBalanceWindow:Init()")
end

--------------------------------------------------------------------------------
-- 初始化
function LigeBalanceWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	self:InitUI()

	self:SubscribeEvts()
end

--------------------------------------------------------------------------------
-- 初始化UI
function LigeBalanceWindow:InitUI()
	local controls = self.Controls
 
	local toggles = {controls.m_LigeLogTgl, controls.m_ContRankTgl}
	self.m_ContentWidgets = {controls.m_LigeLogbuch, controls.m_ContriRank}

	for i, tgl in ipairs(toggles) do
		tgl.onValueChanged:AddListener(function (on)
			if not on then return end
			self:OnTglTitleChanged(i)
		end)
	end
	
	local ranklistView = controls.m_ContRankSV:GetComponent(typeof(EnhancedListView))
	local listScroller = ranklistView:GetComponent(typeof(EnhancedScroller))
	listScroller.scrollerScrolled = function(scroller, vector, pos) -- 列表滚动事件，每帧调用
		if vector.y < 0 then -- normalize坐标值（1是顶部，0代表底部）
			self:RequestRanks()
		end
	end
	controls.rankScroller = listScroller

	ranklistView.onGetCellView:AddListener(function(goCell) self:OnRankGetCellView(goCell) end)
	ranklistView.onCellViewVisiable:AddListener(function(goCell) self:OnRankCellViewVisible(goCell) end)
	controls.ranklistView = ranklistView
	
	controls.m_ExitBtn.onClick:AddListener(handler(self, self.OnBtnExitClicked))

	self:OnTglTitleChanged(1)

	self:ShowBanlance()
end

--------------------------------------------------------------------------------
-- 销毁界面
function LigeBalanceWindow:OnDestroy()
	self:UnSubscribeEvts()

	self:DestroyLogbuchCells()

	UIWindow.OnDestroy(self)

	table_release(self)
end

--------------------------------------------------------------------------------
-- 监听事件
function LigeBalanceWindow:SubscribeEvts()
	self.m_RankUpCallBack = handler(self, self.OnRanksUpdateEvt)
	rktEventEngine.SubscribeExecute( EVENT_LIGE_FIGHT_RANK_UP , 0, 0, self.m_RankUpCallBack )
end

-- 去除事件监听
function LigeBalanceWindow:UnSubscribeEvts()
	rktEventEngine.UnSubscribeExecute( EVENT_LIGE_FIGHT_RANK_UP , 0, 0, self.m_RankUpCallBack )
end

--------------------------------------------------------------------------------
-- 显示窗口
function LigeBalanceWindow:ShowWindow()
	UIWindow.Show(self, true)

	if not self:isLoaded() then
		return 
	end

	self:ShowBanlance()
end
--------------------------------------------------------------------------------
-- 显示结算
function LigeBalanceWindow:ShowBanlance()
	local controls = self.Controls

	local s = LigeanceEctype:GetBalancedAward()
	if s == 0 then
		s = "由于贡献不达标，无法获得战功"
	end
	controls.m_AwdTxt.text = s
end

--------------------------------------------------------------------------------
-- 显示战况信息
function LigeBalanceWindow:ShowLogbuches()
	print("ShowLogbuches")

	if self.m_LogbuchesLoadFlag then
		return
	end

	local content = self.Controls.m_LigeLogContent
	
	local warList = IGame.Ligeance:GetWarList() or {}
	local ligeances = IGame.Ligeance:GetLigeanceData()

	for id, data in pairs(warList) do
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.ClanLigeance.LigeBalceLogCell , 
	   	function( path , obj , ud )
			if nil ~= obj then
				obj.transform:SetParent(content, false)
				obj.gameObject.name = "LigeBalanceLogbuchCell-"..id
			
				local cell = LigeBalceLogCell:new({})
				cell:Attach(obj)
				cell:SetData(data, ligeances[data.nID])

				self.m_LogbuchCells[id] = cell
			end
		end, nil, AssetLoadPriority.GuiNormal )
	end 

	self.m_LogbuchesLoadFlag = true -- 战况表加载标记
end

------------------------------------------------------------
-- 销毁时间段元素
function LigeBalanceWindow:DestroyLogbuchCells()
	for i, v in pairs(self.m_LogbuchCells) do
		v:Recycle() --回收
	end
	self.m_LogbuchCells = {}
end

--------------------------------------------------------------------------------
-- 标题Toggle切换回调
function LigeBalanceWindow:OnTglTitleChanged(idx)
	print("tgl idx:", idx)
	for b, wdt in pairs(self.m_ContentWidgets) do
		wdt.gameObject:SetActive(b == idx)
	end

	if idx == 1 then
		self:ShowLogbuches()
	else
		self:ShowRanks()
	end
end

--------------------------------------------------------------------------------
-- 显示排行榜
function LigeBalanceWindow:ShowRanks()
	print("ShowRanks")
	if self.m_RanksReqFlag ~= -1 then
		return 
	end

	self:RequestRanks()
end

--------------------------------------------------------------------------------
-- 排行数据更新
function LigeBalanceWindow:OnRanksUpdateEvt(_, _, _, count)
	cLog("OnRanksUpdateEvt", "green")

	self.m_RankReqStartIdx = self.m_RankReqStartIdx + count or 20 

	self.m_RankList = LigeanceEctype:GetRankList()
	print("self.m_RankList:", tableToString(self.m_RankList))

	self.Controls.ranklistView:SetCellCount( #self.m_RankList, false )

	if not self.m_RanksCellLoadFlag then
		self.m_RanksCellLoadFlag = true
		self.Controls.rankScroller:ReloadData()
	else
	    -- 非第一次进入，保持原先位置不变，只刷新当前界面活动的元素
		self.Controls.rankScroller:Resize(true)	
		self.Controls.rankScroller:RefreshActiveCellViews()
	end
end


--------------------------------------------------------------------------------
-- 请求排行数据
local prevReqTime = 0
function LigeBalanceWindow:RequestRanks()
	-- if self.m_RankReqStartIdx == self.m_RankReqFlag and os.clock() - prevReqTime < 60 then
	if self.m_RankReqStartIdx == self.m_RanksReqFlag then
		print("已经请求过了")
		return
	end

	if LigeanceEctype:IsRankReqEnd() then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "已到排行榜底部!")
	else
		LigeanceEctype:Request_Rank(self.m_RankReqStartIdx)
	end
	
	-- prevReqTime = os.clock()
	self.m_RanksReqFlag = self.m_RankReqStartIdx
end

--------------------------------------------------------------------------------
-- 排行创建时
function LigeBalanceWindow:OnRankGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = function (listcell)
		local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
		self:RefreshRankCellView(listcell)
	end

	local item = HGLYRankCell:new({})
	item:Attach(goCell.gameObject)
end

--------------------------------------------------------------------------------
-- EnhancedListView 一行可见时的回调
function LigeBalanceWindow:OnRankCellViewVisible( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshRankCellView( listcell )
end

--------------------------------------------------------------------------------
--- 刷新列表
function LigeBalanceWindow:RefreshRankCellView( listcell, on )	
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	local item = behav.LuaObject
	if item == nil then
		uerror("HGLYRankCell 为空")
		return
	end

	local idx = listcell.dataIndex + 1

	local rank = self.m_RankList[idx]
	local data = 
	{
		nDBID = rank.nDBID,
		szName = rank.szName,
		nCtri = rank.nScore,
		nKill = rank.nKill,
		nHelp = rank.nHelp,
		nCure = rank.nCure,
		
		-- ClanID = rank.nClanID,
		-- Honour = rank.nHonour,
	}
	item:SetCellData(idx, data, 2)
end

--------------------------------------------------------------------------------
-- 退出战场按钮按下事件
function LigeBalanceWindow:OnBtnExitClicked()
	print("退出战场")
	LigeanceEctype:Request_LeaveEctype()
	
	self:Hide(true)
	UIManager.LigeanceFightWindow:Hide(true)
	UIManager.LigeanceEntryWindow:Hide(true)

	IGame.Ligeance:ClearWarList()
end

return LigeBalanceWindow