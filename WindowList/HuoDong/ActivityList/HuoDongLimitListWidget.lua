--/******************************************************************
---** 文件名:	HuoDongWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-03-01
--** 版  本:	1.0
--** 描  述:	限时活动窗口
--** 应  用:  
--******************************************************************/

local HuoDongItemCellClass = require("GuiSystem.WindowList.HuoDong.ActivityList.XianShiCell")

local LimitListWidget = UIControl:new
{
	windowName	= "LimitListWidget",
	m_TimeLimitManager = nil,
	m_Scroller = nil,
}

function LimitListWidget:Attach(obj, TlgGroup, tItemSelectCB)
	UIControl.Attach(self, obj)
	
	self:InitControls()
	self:InitData(TlgGroup, tItemSelectCB)
end

function LimitListWidget:InitData(TlgGroup, tItemSelectCB)
	
	self.m_TogglrGroup = TlgGroup
	self.m_OnItemSelected = tItemSelectCB
	self.m_TimeLimitManager = IGame.ActivityList:GetTimeLimitManager()
	self.m_Scroller:SetCellCount(0, true)

end

function LimitListWidget:InitControls()
	
	self.m_Scroller = self.Controls.m_ItemList:GetComponent(typeof(EnhancedListView))
	self.m_Scroller.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
	self.m_Scroller.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)	
end

function LimitListWidget:CreateCellItem(listcell)
	
	local item = HuoDongItemCellClass:new({})
	
	item:Attach(listcell.gameObject)	
	item:SetToggleGroup(self.m_TogglrGroup)
	item:SetSelectCallback(self.m_OnItemSelected)
	
	self:RefreshCellItems(listcell)
end
--- 刷新列表
function LimitListWidget:RefreshCellItems( listcell )
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		uerror("Error： UI Window Behaviour")
		return
	end
	
	local item = behav.LuaObject
	if item == nil then
		uerror("LimitListWidget:RefreshCellItems item为空")
		return
	end
	
	local idx = listcell.dataIndex + 1
	local HuoDongObj = self.m_TimeLimitManager:GetElement(idx)
	if nil == HuoDongObj then
		return
	end
	
	local bFocus = (HuoDongObj:GetActID() == IGame.ActivityList:GetFocusID())
	if nil ~= item and item.windowName == "XianShiCell" then 
		item:SetItemCellInfo(HuoDongObj, bFocus)
	end
end

-- EnhancedListView 一行被“创建”时的回调
function LimitListWidget:OnGetCellView(goCell)
	
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler(self, self.OnRefreshCellView)
	
	self:CreateCellItem(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function LimitListWidget:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function LimitListWidget:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end

function LimitListWidget:ReloadData()	
	
	local nCount = self.m_TimeLimitManager:GetListCount()
	self.m_Scroller:SetCellCount(nCount, true)
end

return LimitListWidget