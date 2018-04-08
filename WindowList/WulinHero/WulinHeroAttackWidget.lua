-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    zjc
-- 日  期:    2017-10-13
-- 描  述:    武林英雄列表界面
-------------------------------------------------------------------

local WulinHeroActorCellClass = require( "GuiSystem.WindowList.WulinHero.WulinHeroActorCell" )



local WulinHeroAttackWidget = UIControl:new
{
	windowName = "WulinHeroAttackWidget",
}

local this = WulinHeroAttackWidget


function WulinHeroAttackWidget:Attach(obj)
	UIControl.Attach(self, obj)
	
	self.Controls.AttackActorList = self.Controls.m_AttackActorList:GetComponent(typeof(EnhancedListView))
	self.callbackCreateItemList = function(goCell) self:OnGetCellView(goCell) end
	self.Controls.AttackActorList.onGetCellView:AddListener(self.callbackCreateItemList)
	
	self.callbackOnCellViewVisiable = function(goCell) self:OnCellViewVisiable(goCell) end
	self.Controls.AttackActorList.onCellViewVisiable:AddListener(self.callbackOnCellViewVisiable)
	
	self.Controls.scroller =  self.Controls.m_AttackActorList:GetComponent(typeof(EnhancedScroller))
	self.Controls.ItemToggleGroup =  self.Controls.m_AttackActorList:GetComponent(typeof(ToggleGroup))
	
	self.jumpToEndCallBack = function() self:OnJumpToEnd() end
	self:ReloadData()
	return self
end

function WulinHeroAttackWidget:OnJumpToEnd()
	self.rectScroll = self.Controls.scroller.transform:GetComponent(typeof(UnityEngine.UI.ScrollRect)) 
	self.rectScroll.horizontalNormalizedPosition = 1
end

-- item 被选中
function WulinHeroAttackWidget:OnItemCellSelected(itemCell ,on)
	if not on then
		return
	end

end

--- 刷新列表
function WulinHeroAttackWidget:RefreshCellItems( objCell )	
	
	if not objCell then 
		return
	end
	local behav = objCell:GetComponent(typeof(UIWindowBehaviour))
	if nil ~= behav then 
		local item = behav.LuaObject
		if nil ~= item then 
			local viewCell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))
			local itemIndex = viewCell.cellIndex
			item:UpdateItemCellInfo(itemIndex)
		end
	end
end

function WulinHeroAttackWidget:isLoaded()
	return self.transform ~= nil
end

-- 重新加载
function WulinHeroAttackWidget:ReloadData()
	if not self:isLoaded() then
		return
	end
	local nCellCount = IGame.WulinHeroClient:GetAttackActorCount()
	if self.Controls.AttackActorList.CellCount == nCellCount then
		self.Controls.scroller:RefreshActiveCellViews()
	else
		self.Controls.AttackActorList:SetCellCount( nCellCount , true )
	end
	rktTimer.SetTimer(self.jumpToEndCallBack,100,1,"WulinHeroAttackWidget:ReloadData")
end

-- 当一个cell被创建
function WulinHeroAttackWidget:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView)
	
	local item = WulinHeroActorCellClass:new()
	item:Attach(goCell)
end

-- 刷新
function WulinHeroAttackWidget:OnRefreshCellView( goCell )
	self:RefreshCellItems(goCell)
end

-- 单元可见时的回调
function WulinHeroAttackWidget:OnCellViewVisiable( goCell )

	self:RefreshCellItems( goCell )
end

function WulinHeroAttackWidget:OnDestroy()
	UIControl.OnDestroy(self)
end

return this