--/******************************************************************
---** 文件名:	HuoDongWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-03-17
--** 版  本:	1.0
--** 描  述:	活跃度任务
--** 应  用:  
--******************************************************************/

local ActiveTaskItemClass = require("GuiSystem.WindowList.HuoDong.ActivityDegree.ActiveTaskItem")

local ActiveTaskWidget = UIControl:new
{
	windowName = "ActiveTaskWidget",
	m_ActiveDegree = nil,
	m_nCurFocusID = 0,
}

function ActiveTaskWidget:Attach(obj)
	UIControl.Attach(self,obj)	
		
	self.Controls.LimitList = self.Controls.m_ItemList:GetComponent(typeof(EnhancedListView))
	self.callbackCreateActivityList = function(goCell) self:OnGetCellView(goCell) end
	self.Controls.LimitList.onGetCellView:AddListener(self.callbackCreateActivityList)
	
	self.callbackOnCellViewVisiable = function(goCell) self:OnCellViewVisiable(goCell) end
	self.Controls.LimitList.onCellViewVisiable:AddListener(self.callbackOnCellViewVisiable)
	
	self.m_TlgGroup = self.Controls.m_ItemList:GetComponent(typeof(ToggleGroup))
	self.m_ActiveDegree = IGame.ActivityList:GetActiveDegreeManager()
	
	self.Controls.LimitList:SetCellCount( self.m_ActiveDegree:GetListCount() , true )
	return self
end

-- 创建奖励列表
function ActiveTaskWidget:onCreateRewardList(listcell)
	
	local item = ActiveTaskItemClass:new({})
	item:Attach(listcell.gameObject)
	item:SetToggleGroup(self.m_TlgGroup)
	item:SetSelectCallback(handler(self, self.OnValueChanged))
end

--- 刷新列表
function ActiveTaskWidget:RefreshCellItems( listcell )
		
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		uerror("Error： UI Window Behaviour")
		return
	end
	
	local itemIndex = listcell.dataIndex  + 1	
	local HuoDongObj = self.m_ActiveDegree:GetElement(itemIndex)
	if HuoDongObj == nil then
		print("can't get activity object! index: "..itemIndex)
		return
	end
	
	local item = behav.LuaObject
	if item == nil then
		uerror("RewardBackWdt:RefreshCellItems item为空")
		return
	end
	
	local bFocus = (self.m_nCurFocusID == HuoDongObj:GetActID())
	
	if nil ~= item and item.windowName == "ActiveTaskItem" then 
		item:SetItemCellInfo(HuoDongObj, bFocus)
	end
end

-- EnhancedListView 一行被“创建”时的回调
function ActiveTaskWidget:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView)
	self:onCreateRewardList(listcell)
	
end

-- EnhancedListView 一行强制刷新时的回调
function ActiveTaskWidget:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function ActiveTaskWidget:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

function ActiveTaskWidget:ReloadData()
	self.Controls.LimitList:SetCellCount(self.m_ActiveDegree:GetListCount() , true )
end

function ActiveTaskWidget:OnValueChanged(id, on)
	if not on then
		return
	end
	
	self.m_nCurFocusID = id
end

function ActiveTaskWidget:OnDestroy()	
	UIControl.OnDestroy(self)
end

return ActiveTaskWidget
