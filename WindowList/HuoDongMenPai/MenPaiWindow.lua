-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    方称称
-- 日  期:    2017/06/22
-- 版  本:    1.0
-- 描  述:    门派入侵主界面ICON窗口
-------------------------------------------------------------------

local MenPaiCell = require( "GuiSystem.WindowList.HuoDongMenPai.MenPaiCell" )

local MenPaiWindow = UIWindow:new
{
	windowName = "MenPaiWindow",
	m_cellInfo = {},
}

local this = MenPaiWindow	-- 方便书写

function MenPaiWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	
	local controls = self.Controls
	local scrollView = controls.m_scrollView

	controls.m_closeBtn.onClick:AddListener( handler(self, self.closeCallback) )

	local listView = scrollView:GetComponent(typeof(EnhancedListView))
	listView.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
	listView.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)
	controls.listView = listView
	
	local listScroller = scrollView:GetComponent(typeof(EnhancedScroller))
	controls.listScroller = listScroller

    if nil ~= self.m_cellInfo then
        self:SetData(self.m_cellInfo)
    end
end

--点击
function MenPaiWindow:closeCallback()
	self:hideWindow()
end

-- self.Controls.m_NumTxt.text = num

--隐藏窗口
function MenPaiWindow:hideWindow()
	-- 关闭定时器
	self:Hide()
	GameHelp.PostServerRequest("RequestCloseMenPaiListInfo()")
end

function MenPaiWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

-- EnhancedListView 一行被“创建”时的回调
function MenPaiWindow:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView)
	self:CreateCellItems(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function MenPaiWindow:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function MenPaiWindow:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end

--- 刷新列表
function MenPaiWindow:CreateCellItems( listcell )	
	local item = MenPaiCell:new({})
	item:Attach(listcell.gameObject)
	item:SetParent(self)

	self:RefreshCellItems(listcell)
end

--- 刷新列表
function MenPaiWindow:RefreshCellItems( listcell, on )	
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	local item = behav.LuaObject
	if item == nil then
		uerror("MenPaiWindow 为空")
		return
	end

	local idx = listcell.dataIndex + 1
	item:SetCellData(self.m_cellInfo[idx], idx)

end

function MenPaiWindow:SetData(cellInfo)
	self.m_cellInfo = cellInfo
	if not self:isLoaded() then
        return
    end
	local controls = self.Controls
	controls.listView:SetCellCount( table_count(self.m_cellInfo) , true )
end

return MenPaiWindow