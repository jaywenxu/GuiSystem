--JRBattleRankWindow.lua------------------------------------------------------------
-- 版  权:	(C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:	何荣德
-- 日  期:	2017.12.20
-- 版  本:	1.0
-- 描  述:	假人战场排行榜窗口
-------------------------------------------------------------------

local JRBattleRankWindow = UIWindow:new
{
	windowName  = "JRBattleRankWindow",
	m_tRankList = {},
    m_nBattleState = 1,
    m_nSelfRank = 1,
}

local JRBattleRankCell = require( "GuiSystem.WindowList.JiaRenBattle.JRBattleRankCell" )

local this = JRBattleRankWindow

function JRBattleRankWindow:OnAttach( obj )

	UIWindow.OnAttach(self,obj)

	self:InitUI()

    self:ShowRankList()
	self:ShowBanlance()
end

function JRBattleRankWindow:InitUI()
    self:AdjustUI()
    
	local controls = self.Controls
	local scrollView = controls.m_ScrollView

	local listView = scrollView:GetComponent(typeof(EnhancedListView))
	listView.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
	listView.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)
	controls.listView = listView

	local listScroller = scrollView:GetComponent(typeof(EnhancedScroller))
	controls.listScroller = listScroller

	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_ExitBtn.onClick:AddListener(handler(self, self.OnBtnExitClicked))
end

function JRBattleRankWindow:AdjustUI()
	local controls = self.Controls
	local scrollView = controls.m_ScrollView
    
    if self.m_nBattleState > 2 then
        local oldSizeDelta = scrollView.gameObject.transform.sizeDelta
        scrollView.gameObject.transform.sizeDelta = Vector2.New(oldSizeDelta.x, 605)
        scrollView.gameObject.transform.localPosition = Vector3.New(-5.7, -67, 0)
        controls.m_ScrollTitle.gameObject.transform.localPosition = Vector3.New(-5.7, 272, 0)
        
        local ScrollBg = controls.m_ScrollBg.gameObject
        oldSizeDelta = ScrollBg.transform.sizeDelta
        ScrollBg.transform.sizeDelta = Vector2.New(oldSizeDelta.x, 689)
        ScrollBg.transform.localPosition = Vector3.New(-2, -17, 0)
        
        -- 淡入控制
        local canvasGroup = self.transform:GetComponent(typeof(UnityEngine.CanvasGroup))
        canvasGroup.alpha = 0
        local TweenAnim = self.transform:GetComponent(typeof(DG.Tweening.DOTweenAnimation))
        TweenAnim:DORestart(true)
    end        
end

-- 显示窗口 nBattleState战场状态 1开始倒计 2进行中 3结束胜利 4结束失败
function JRBattleRankWindow:ShowWindow(tRankList, nBattleState, nSelfRank)
	UIWindow.Show(self, true)
    local bRankUpdate = (tostringEx(self.m_tRankList) ~= tostringEx(tRankList))
    self.m_tRankList = tRankList
    self.m_nBattleState = nBattleState
    self.m_nSelfRank = nSelfRank

	if not self:isLoaded() then
		return 
	end
    
    self:AdjustUI()
    
    if bRankUpdate then
        self:ShowRankList()
    end
	self:ShowBanlance()
end

-- 排行列表数据更新
function JRBattleRankWindow:ShowRankList()
	local controls = self.Controls
	controls.listView:SetCellCount( #self.m_tRankList , true )
end

-- 显示结算
function JRBattleRankWindow:ShowBanlance()
	local bShow = self.m_nBattleState > 2

	local controls = self.Controls
	controls.m_CloseBtn.gameObject:SetActive(not bShow)

	if not bShow then
		return 
	end
    
    controls.m_RankImg.gameObject:SetActive(self.m_nBattleState < 3) --未结束
	controls.m_WinTitle.gameObject:SetActive(self.m_nBattleState == 3) --胜利
	controls.m_LostTitle.gameObject:SetActive(self.m_nBattleState == 4) --失败
end

-- EnhancedListView 一行被“创建”时的回调
function JRBattleRankWindow:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView)

	self:CreateCellItems(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function JRBattleRankWindow:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function JRBattleRankWindow:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end

--- 刷新列表
function JRBattleRankWindow:CreateCellItems( listcell )	
	local item = JRBattleRankCell:new({})
	item:Attach(listcell.gameObject)
end

--- 刷新列表
function JRBattleRankWindow:RefreshCellItems( listcell, on )	
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	local item = behav.LuaObject
	if item == nil then
		uerror("JRBattleRankCell 为空")
		return
	end

	local idx = listcell.dataIndex + 1
	item:SetCellData(idx, self.m_tRankList[idx], self.m_nSelfRank == idx)
end

-- 退出按钮按下事件
function JRBattleRankWindow:OnBtnCloseClicked()
	self:Hide()
end

-- 退出战场按钮按下事件
function JRBattleRankWindow:OnBtnExitClicked()
	GameHelp.PostServerRequest("RequestForceGoBace()")
    self:Hide()
end

return JRBattleRankWindow