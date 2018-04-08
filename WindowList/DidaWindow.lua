-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017/02/19
-- 版  本:    1.0
-- 描  述:    滴答窗口
-------------------------------------------------------------------
local DidaItemCellClass = require( "GuiSystem.WindowList.Dida.DidaItemCell" )
------------------------------------------------------------
local DidaWindow = UIWindow:new
{
	windowName = "DidaWindow",
    m_needRefresh = false ,
}


local this = DidaWindow					-- 方便书写

------------------------------------------------------------
function DidaWindow:Init()
	
end
------------------------------------------------------------
function DidaWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	
	-- Cell 事件
	self.Controls.listViewDida = self.Controls.didaCellList:GetComponent(typeof(EnhancedListView))
	self.callback_OnGetCellView = function(goCell) self:OnGetCellView(goCell) end
	self.Controls.listViewDida.onGetCellView:AddListener(self.callback_OnGetCellView)
	self.callback_OnCellViewVisiable = function(goCell) self:OnCellViewVisiable(goCell) end
	self.Controls.listViewDida.onCellViewVisiable:AddListener(self.callback_OnCellViewVisiable)
	
	self.Controls.scrollerDida = self.Controls.didaCellList:GetComponent(typeof(EnhancedScroller))
	self.Controls.DidaToggleGroup = self.Controls.didaCellList:GetComponent(typeof(ToggleGroup))

	--关闭滴答消息窗口按钮
    self.Controls.m_Close.onClick:AddListener(function() self:OnBtnCloseClick() end)
	
	--一键清空滴答消息按钮
    self.Controls.m_ClearBtn.onClick:AddListener(function() self:OnBtnClearClick() end)
	
	-- 设置最大行数
	self.Controls.listViewDida:SetCellCount( IGame.DidaClassManager:GetMessageDidaCnt() , true )

	self.Controls.scrollerDida:JumpToDataIndex( 0 , 0 , 0 , true , EnhancedScroller.TweenType.easeOutQuad , 0.2 , nil)

    if self.m_needRefresh then
        self:RefreshDidaWindow()
        self.m_needRefresh = false
    end
end

------------------------------------------------------------
------------------------------------------------------------
-- 窗口销毁
function DidaWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

--------------------------------------------------------------------------------
-- 设置最大行数
function DidaWindow:SetCellCnt(CellCount)
    if not self:isShow() then
        return
    end
	self.Controls.listViewDida:SetCellCount( CellCount , true )
end

--------------------------------------------------------------------------------
-- 创建物品格子
function DidaWindow:CreateCellItems( listcell )
	print("[DidaWindow]CreateCellItems")
	local item = DidaItemCellClass:new({})
	item:Attach(listcell.gameObject)
	self:RefreshCellItems(listcell)
end

--------------------------------------------------------------------------------
--- 刷新物品格子内容
function DidaWindow:RefreshCellItems( listcell )
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	local item = behav.LuaObject
	if item == nil then
		uerror("DidaWindow:RefreshCellItems item为空")
		return
	end	
	if nil ~= item and item.windowName == "DidaItemCell" then
		local DidaObj = IGame.DidaClassManager:GetObjByIndex(listcell.dataIndex + 1)
		local ContentText	= ""
		local TitleText		= ""
		local Sequence		= ""
		if(DidaObj ~= nil)then
			ContentText = DidaObj:GetProperty("ContentText")
			TitleText   = DidaObj:GetProperty("TitleText")
			Sequence	= DidaObj:GetProperty("Sequence")
		end
		item:SetDidaSeq(Sequence)
		item:SetTitleText(TitleText)
		item:SetContentText(ContentText)
	end
end

--------------------------------------------------------------------------------
-- EnhancedListView 一行可见时的回调
function DidaWindow:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end

--------------------------------------------------------------------------------
-- EnhancedListView 一行被“创建”时的回调
function DidaWindow:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView )
	self:CreateCellItems(listcell)
end

--------------------------------------------------------------------------------
-- EnhancedListView 一行强制刷新时的回调
function DidaWindow:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

--------------------------------------------------------------------------------
--刷新滴答窗口内容
function DidaWindow:RefreshDidaWindow()
	if not self:isShow()then
		UIManager.MainMidBottomWindow:RefreshDidaBtn()
		return
	end
    if not self:isLoaded() then
        self.m_needRefresh = true
        return
    end
	local DidaCnt = IGame.DidaClassManager:GetMessageDidaCnt()
	self.Controls.listViewDida:SetCellCount( DidaCnt , true )
	if DidaCnt == 0 then
		self:OnBtnCloseClick()
	end
end

--------------------------------------------------------------------------------
--关闭滴答窗口按钮回调函数
function DidaWindow:OnBtnCloseClick()
	IGame.DidaClassManager:ClearInvalidDida()
	self:Hide()
	local CellCnt = IGame.DidaClassManager:GetMessageDidaCnt()
	if(CellCnt == 0)then
		UIManager.MainMidBottomWindow.Controls.m_DidaButton.gameObject:SetActive(false)
	end
end

--------------------------------------------------------------------------------
--一键清空
function DidaWindow:OnBtnClearClick()
	IGame.DidaClassManager:RemoveAllMessageDida()
	self:RefreshDidaWindow()
end

return DidaWindow







