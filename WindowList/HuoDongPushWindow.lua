--/******************************************************************
---** 文件名:	HuoDongPushWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-02-22
--** 版  本:	1.0
--** 描  述:	活动推送设置窗口
--** 应  用:  
--******************************************************************/

local HuoDongPushItemCellClass = require( "GuiSystem.WindowList.HuoDong.ActivityPushManager.HuoDongPushItemCell" )

local HuoDongPushWindow = UIWindow:new
{
	windowName = "HuoDongPushWindow",
	m_PushSettingMgr = nil,
	m_ItemToggleGroup = nil,
	m_nFocusHuoDongID = 0,
	m_nFocusTimeID = 0,
}

function HuoDongPushWindow:OnAttach(obj)
	UIWindow.OnAttach(self,obj)	
	
	self.callbackCloseClick = function() self:OnCloseClick() end
	self.Controls.m_Close.onClick:AddListener(self.callbackCloseClick)
	
	self.Controls.ActivityList = self.Controls.m_ItemList:GetComponent(typeof(EnhancedListView))
	self.Controls.ActivityList.onGetCellView:AddListener(handler(self, self.OnGetCellView))
	self.Controls.ActivityList.onCellViewVisiable:AddListener(handler(self, self.OnCellViewVisiable))
	
	self.m_ItemToggleGroup = self.Controls.m_ItemList:GetComponent(typeof(ToggleGroup))
	
	self.m_PushSettingMgr = IGame.ActivityList:GetPushSettingMgr()
	self.Controls.ActivityList:SetCellCount( self.m_PushSettingMgr:GetListCount() , true )
end

-- 创建活动列表
function HuoDongPushWindow:CreateListItem(listcell)	
	
	local item = HuoDongPushItemCellClass:new({})
	
	item:Attach(listcell.gameObject)
	item:SetToggleGroup(self.m_ItemToggleGroup)
	item:SetSelectCallback(handler(self, self.OnSelectChanged))
	
end

--- 刷新列表
function HuoDongPushWindow:RefreshCellItems( listcell )	
	
	local idx = listcell.dataIndex  + 1
	local HuoDongObj = self.m_PushSettingMgr:GetElement(idx)
	if HuoDongObj == nil then
		print("can't get activity object! index: "..idx)
		return
	end
	
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		print("can't get UIWindowBehaviour")
		return
	end
	
	local bFocus = (self.m_nFocusHuoDongID == HuoDongObj:GetActID()) and (self.m_nFocusTimeID == HuoDongObj:GetTimeID())
	local item = behav.LuaObject
	if nil ~= item and item.windowName == "HuoDongPushItemCell" then
		item:SetItemCellInfo(HuoDongObj, bFocus)
	end			
end

-- EnhancedListView 一行被“创建”时的回调
function HuoDongPushWindow:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView )
	self:CreateListItem(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function HuoDongPushWindow:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function HuoDongPushWindow:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

function HuoDongPushWindow:OnSelectChanged(id, time_id, on)
	if not on then
		return
	end
	
	self.m_nFocusHuoDongID = id
	self.m_nFocusTimeID = time_id
end

function HuoDongPushWindow:OnCloseClick()
	self:Hide()
end

return HuoDongPushWindow



