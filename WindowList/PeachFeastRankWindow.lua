
--------------------------------------------------------------------------------
-- 版  权:    (C)深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    lj.zhou
-- 日  期:    2017.06.27
-- 版  本:    1.0
-- 描  述:    蟠桃盛宴排行榜窗口 
--------------------------------------------------------------------------------

local RankItemClass = require("GuiSystem.WindowList.HuoDong.PeachFeast.PeachFeastRankCell")

PeachFeastRankWindow = UIWindow:new
{
	windowName = "PeachFeastRankWindow",
	m_RankList = {},
}

function PeachFeastRankWindow:OnAttach(obj)
	UIWindow.OnAttach(self, obj)
	
	local controls = self.Controls
	local scrollView = controls.m_ItemList
	
	controls.m_WindowBtn.onClick:AddListener(handler(self, self.OnCloseClick))
	
	local listView = scrollView:GetComponent(typeof(EnhancedListView))
	listView.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
	listView.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)
	
	self.m_listView = listView
	
	self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))
		
	self:SubscribeEvts()
	
	self:InitData()
	
end

function PeachFeastRankWindow:OnEnable()
		
	self:InitData()
	
end

function PeachFeastRankWindow:InitData()
	
	GameHelp.PostSocialRequest("RequestPeachFeastRank()")
	
end

function PeachFeastRankWindow:SubscribeEvts()
	
	-- 排行榜列表更新
	self.m_UpdateRankList = function () self:UpdateRankList() end
	rktEventEngine.SubscribeExecute(EVENT_PEACHFEAST_LIST_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.m_UpdateRankList )
		
end

function PeachFeastRankWindow:UnSubscribeEvts()
	
	rktEventEngine.UnSubscribeExecute(EVENT_PEACHFEAST_LIST_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.m_UpdateRankList )
	self.m_UpdateRankList = nil

end

function PeachFeastRankWindow:UpdateRankList()
    if not self:isShow() then
        return
    end

	local nRankCount = IGame.PanTaoClient:GetRankListCount()
	self.m_listView:SetCellCount( nRankCount , true )
end


-- EnhancedListView 一行被创建时的回调
function PeachFeastRankWindow:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))

	listcell.onRefreshCellView = handler(self, self.OnRefreshCellView)

	self:CreateCellItems(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function PeachFeastRankWindow:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function PeachFeastRankWindow:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end

-- 创建元素
function PeachFeastRankWindow:CreateCellItems(listcell)
	
	local item = RankItemClass:new({})
	item:Attach(listcell.gameObject)

	self:RefreshCellItems(listcell) 
end

function PeachFeastRankWindow:RefreshCellItems(listcell)
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		uerror("Error： UI Window Behaviour")
		return
	end
	
	local item = behav.LuaObject
	if item == nil then
		uerror("RewardBackWdt:RefreshCellItems item为空")
		return
	end
	
	local idx = listcell.dataIndex + 1
	local ItemData = IGame.PanTaoClient:GetRankData(idx)
	if nil == ItemData then
		return
	end
	
	if nil ~= item and item.windowName == "PeachFeastRankItem" then 
		item:SetItemInfo(idx, ItemData)
	end
	
end

function PeachFeastRankWindow:OnCloseClick()
	self:Hide()
end

function PeachFeastRankWindow:Destory()
	self:UnSubscribeEvts()
end

return PeachFeastRankWindow






