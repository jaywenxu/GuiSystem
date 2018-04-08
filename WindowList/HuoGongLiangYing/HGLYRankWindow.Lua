-- 火攻梁营排行窗口
-- @Author: XieXiaoMei
-- @Date:   2017-06-12 14:59:57
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-06-01 09:48:30

local HGLYRankWindow = UIWindow:new
{
	windowName  = "HGLYRankWindow",
	
	m_RankList = {},
	m_SelMemberID = 0,

	m_LeftTime      = 0,
	m_TimerCallBack = nil,

	m_RankListUpCallBack = nil,
	m_BanlanceCallBack = nil,
}

local HGLYRankCell = require( "GuiSystem.WindowList.HuoGongLiangYing.HGLYRankCell" )

local this = HGLYRankWindow

------------------------------------------------------------
function HGLYRankWindow:Init()
	Debugger.Log("HGLYRankWindow:Init()")
end

function HGLYRankWindow:OnAttach( obj )

	UIWindow.OnAttach(self,obj)

	self:InitUI()

	self:SubscribeEvts()

	self:ShowBanlance()
	self:SetCDTimer()
	
	if self.bShowBanlance then
		self.bShowBanlance = false
		self:OnBanlanceEvt()
	end
end

function HGLYRankWindow:InitUI()
	local controls = self.Controls
	local scrollView = controls.m_ScrollView

	local listView = scrollView:GetComponent(typeof(EnhancedListView))
	listView.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
	listView.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)
	controls.listView = listView

	local listScroller = scrollView:GetComponent(typeof(EnhancedScroller))
	controls.listScroller = listScroller

	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_ShareBtn.onClick:AddListener(handler(self, self.OnBtnShareClicked))
	controls.m_ExitBtn.onClick:AddListener(handler(self, self.OnBtnExitClicked))
end


function HGLYRankWindow:OnDestroy()
	self:UnSubscribeEvts()

	self:StopCDTimer()

	UIWindow.OnDestroy(self)

	table_release(self)
end


function HGLYRankWindow:Hide()
	UIWindow.Hide(self)

	self:StopCDTimer()
end


-- 监听事件
function HGLYRankWindow:SubscribeEvts()

	self.m_RankListUpCallBack = handler(self, self.OnRankListUpEvt)
	rktEventEngine.SubscribeExecute( EVENT_FIREDESTROY_UPDATE_RANK, 0, 0, self.m_RankListUpCallBack )

	self.m_BanlanceCallBack = handler(self, self.OnBanlanceEvt)
	rktEventEngine.SubscribeExecute( EVENT_FIREDESTROY_BANLANCE, 0, 0, self.m_BanlanceCallBack )
end 

-- 去除事件监听
function HGLYRankWindow:UnSubscribeEvts()

	rktEventEngine.UnSubscribeExecute( EVENT_FIREDESTROY_UPDATE_RANK , 0, 0, self.m_RankListUpCallBack )
	self.m_RankListUpCallBack = nil

	rktEventEngine.UnSubscribeExecute( EVENT_FIREDESTROY_BANLANCE , 0, 0, self.m_BanlanceCallBack )
	self.m_BanlanceCallBack = nil
end


-- 显示窗口
function HGLYRankWindow:ShowWindow(leftTime)
	UIWindow.Show(self, true)

	self.m_LeftTime = leftTime

	if leftTime > 0 then
		IGame.FireDestroyEctype:RequestRank()
	end

	if not self:isLoaded() then
		return 
	end

	self:ShowBanlance()
	self:SetCDTimer()
end

-- 显示结算
function HGLYRankWindow:ShowBanlance()
	local data = IGame.FireDestroyEctype:GetResult()
	local bShow = not isTableEmpty(data)

	local controls = self.Controls
	local banlanceGo = controls.m_Banlance.gameObject
	banlanceGo.gameObject:SetActive(bShow)

	if not bShow then
		return 
	end

	local rType = data.resultType
	controls.m_WinTitle.gameObject:SetActive(rType == 1 or rType == 2) --胜利
	controls.m_LostTitle.gameObject:SetActive(rType == 0) --失败
	controls.m_FirstWinImg.gameObject:SetActive(rType == 2) --首胜

	local reason = data.reason  -- 无奖励原因
	local bHasAwards = reason == 0
	controls.m_Awards.gameObject:SetActive(bHasAwards)
	controls.m_NoAwardsTxt.gameObject:SetActive(not bHasAwards)
	
	if bHasAwards then
		controls.m_ContributeTxt.text = data.contribute
		controls.m_ExpTxt.text = data.exp
	else
		local str = ""
		if reason == 1 then
			str = "已达到本日最大次数，不能获得奖励"
		elseif reason == 2 then
			str = "本场战斗贡献不满50，不能获得奖励"
		end
		controls.m_NoAwardsTxt.text = str
	end
end

-- 设置倒计时
function HGLYRankWindow:SetCDTimer()
	local timerTxt = self.Controls.m_LeftTimeTxt

	if self.m_LeftTime < 1 then
		timerTxt.text = ""
		return
	end

	timerTxt.text = GetCDTime(self.m_LeftTime, 3)

	self.m_TimerCallBack = function() --倒计时timer
		self.m_LeftTime = self.m_LeftTime - 1
		if self.m_LeftTime < 0 then
			self:StopCDTimer()
			return
		end

		timerTxt.text = GetCDTime(self.m_LeftTime, 3)
	end

	rktTimer.SetTimer(self.m_TimerCallBack, 1000, -1, "HGLY fight time down")
end

-- 停止休息室倒计时timer
function HGLYRankWindow:StopCDTimer()
	if nil ~= self.m_TimerCallBack then
		rktTimer.KillTimer(self.m_TimerCallBack)
		self.m_TimerCallBack = nil
	end
end

-- 排行列表数据更新
function HGLYRankWindow:OnRankListUpEvt()
	self.m_RankList = IGame.FireDestroyEctype:GetRank() or {}

	local controls = self.Controls
	controls.listView:SetCellCount( #self.m_RankList , true )
end

-- 结算事件
function HGLYRankWindow:OnBanlanceEvt(_, _, _)
	
	if not self:isLoaded() then
		self.bShowBanlance = true
		return 
	end
	
	self:OnRankListUpEvt()

	self:ShowBanlance()
end

-- EnhancedListView 一行被“创建”时的回调
function HGLYRankWindow:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView)

	self:CreateCellItems(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function HGLYRankWindow:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function HGLYRankWindow:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end

--- 刷新列表
function HGLYRankWindow:CreateCellItems( listcell )	
	local item = HGLYRankCell:new({})
	item:Attach(listcell.gameObject)
end

--- 刷新列表
function HGLYRankWindow:RefreshCellItems( listcell, on )	
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
	item:SetCellData(idx, self.m_RankList[idx], 1)

end

-- cell被选中事件
function HGLYRankWindow.OnItemCellSelected(memberID)
	this.m_SelMemberID = memberID

end

-- 退出按钮按下事件
function HGLYRankWindow:OnBtnCloseClicked()
	self:Hide()
end

-- 分享按钮按下事件
function HGLYRankWindow:OnBtnShareClicked()
	print("OnBtnShareClicked")

end

-- 退出战场按钮按下事件
function HGLYRankWindow:OnBtnExitClicked()
	IGame.FireDestroyEctype:RequestLeaveMap()
end

return HGLYRankWindow