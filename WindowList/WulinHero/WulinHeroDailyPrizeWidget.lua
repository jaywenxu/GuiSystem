-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    zjc
-- 日  期:    2017-10-13
-- 描  述:    武林英雄每日奖励界面
-------------------------------------------------------------------

local WulinHeroDailyPrizeClass = require( "GuiSystem.WindowList.WulinHero.WulinHeroDailyPrizeCell" )



local WulinHeroDailyPrizeWidget = UIControl:new
{
	windowName = "WulinHeroDailyPrizeWidget",
}

local this = WulinHeroDailyPrizeWidget


function WulinHeroDailyPrizeWidget:Attach(obj)
	UIControl.Attach(self, obj)
	
	self.Controls.AttackActorList = self.Controls.m_DailyRankPrizeList:GetComponent(typeof(EnhancedListView))
	self.callbackCreateItemList = function(goCell) self:OnGetCellView(goCell) end
	self.Controls.AttackActorList.onGetCellView:AddListener(self.callbackCreateItemList)
	
	self.callbackOnCellViewVisiable = function(goCell) self:OnCellViewVisiable(goCell) end
	self.Controls.AttackActorList.onCellViewVisiable:AddListener(self.callbackOnCellViewVisiable)
	
	self.Controls.scroller =  self.Controls.m_DailyRankPrizeList:GetComponent(typeof(EnhancedScroller))

	self.calbackCloseBtnClick = function() self:OnCloseBtnClick() end
	self.Controls.m_CloseDailyPrizeBtn.onClick:AddListener( self.calbackCloseBtnClick )
	return self
end


function WulinHeroDailyPrizeWidget:OnCloseBtnClick()
	UIManager.WulinHeroWindow:SetDailyRankPrizeWdiget(false)
end

-- item 被选中
function WulinHeroDailyPrizeWidget:OnItemCellSelected(itemCell ,on)
	if not on then
		return
	end

end

--- 刷新列表
function WulinHeroDailyPrizeWidget:RefreshCellItems( objCell )	
	
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

function WulinHeroDailyPrizeWidget:isLoaded()
	return self.transform ~= nil
end

-- 重新加载
function WulinHeroDailyPrizeWidget:ReloadData()
	if not self:isLoaded() then
		return
	end
	local pTmpTable = IGame.rktScheme:GetSchemeTable(WULINHERODAILYRANKPRIZE_CSV)
	local nCellCount = table_count(pTmpTable)
	if self.Controls.AttackActorList.CellCount == nCellCount then
		self.Controls.scroller:RefreshActiveCellViews()
	else
		self.Controls.AttackActorList:SetCellCount( nCellCount , true )
	end
end

-- 当一个cell被创建
function WulinHeroDailyPrizeWidget:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView)
	
	local item = WulinHeroDailyPrizeClass:new()
	item:Attach(goCell)
end

-- 刷新
function WulinHeroDailyPrizeWidget:OnRefreshCellView( goCell )
	self:RefreshCellItems(goCell)
end

-- 单元可见时的回调
function WulinHeroDailyPrizeWidget:OnCellViewVisiable( goCell )

	self:RefreshCellItems( goCell )
end

function WulinHeroDailyPrizeWidget:OnDestroy()
	UIControl.OnDestroy(self)
end

return this