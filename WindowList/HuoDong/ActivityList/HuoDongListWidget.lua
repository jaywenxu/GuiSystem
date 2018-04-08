--/******************************************************************
---** 文件名:	HuoDongWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-03-01
--** 版  本:	1.0
--** 描  述:	活动窗口
--** 应  用:  
--******************************************************************/
local QuanTianRowClass = require("GuiSystem.WindowList.HuoDong.ActivityList.QuanTianRow")
local CELL_ITEM_COUNT_IN_LINE = 3  --列表列数

local AllListWidget = UIControl:new
{
	windowName	= "AllListWidget",
	m_AllDayManager = nil,
}

function AllListWidget:Attach(obj)
	UIControl.Attach(self, obj)
	
	self.Controls.ActivityList = self.Controls.m_ItemList:GetComponent(typeof(EnhancedListView))
	self.callbackCreateActivityList = function(goCell) self:OnGetCellView(goCell) end
	self.Controls.ActivityList.onGetCellView:AddListener(self.callbackCreateActivityList)
	
	self.callbackOnCellViewVisiable = function(goCell) self:OnCellViewVisiable(goCell) end
	self.Controls.ActivityList.onCellViewVisiable:AddListener(self.callbackOnCellViewVisiable)
	
	self.m_AllDayManager = IGame.ActivityList:GetAllDayManager()
	
	self.Controls.ActivityList:SetCellCount(0, true)
	return self
end

function AllListWidget:SetParentData(SettingData)
	self.m_TogglrGroup = SettingData.TglGroup
	self.m_OnItemSelected = SettingData.ItemSelectedCallBack
end

-- 创建活动列表
function AllListWidget:onCreateLimitList(listcell)
	
	local item = QuanTianRowClass:new({})
	item:Attach(listcell.gameObject, self.m_TogglrGroup, self.m_OnItemSelected)		
end

--- 刷新列表
function AllListWidget:RefreshCellItems( listcell )	
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if not behav then
		uerror("Error：UI Window Behaviour")
		return
	end
	
	local item = behav.LuaObject
	if not item then
		uerror("LimitListWidget:RefreshCellItems item为空")
		return
	end
	
	if item.windowName ~= "QuanTianRow" then 
		return
	end
	
	item:RefreshCellItems()
end

function AllListWidget:ReloadData()
	local nCount = math.ceil(self.m_AllDayManager:GetListCount() / CELL_ITEM_COUNT_IN_LINE)
	self.Controls.ActivityList:SetCellCount(nCount , true)
end

-- EnhancedListView 一行被“创建”时的回调
function AllListWidget:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler(self , self.OnRefreshCellView)
	self:onCreateLimitList(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function AllListWidget:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function AllListWidget:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

return AllListWidget


