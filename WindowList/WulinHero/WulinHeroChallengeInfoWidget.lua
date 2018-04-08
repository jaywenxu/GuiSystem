-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    zjc
-- 日  期:    2017-10-13
-- 描  述:    武林英雄 战斗记录信息
-------------------------------------------------------------------

local WulinHeroChallengeClass = require( "GuiSystem.WindowList.WulinHero.WulinHeroChallengeCell" )



local WulinHeroChallengeInfoWidget = UIControl:new
{
	windowName = "WulinHeroChallengeInfoWidget",
}

local this = WulinHeroChallengeInfoWidget


function WulinHeroChallengeInfoWidget:Attach(obj)
	UIControl.Attach(self, obj)
	
	self.Controls.ChallengeList = self.Controls.m_ChallengeList:GetComponent(typeof(EnhancedListView))
	self.callbackCreateItemList = function(goCell) self:OnGetCellView(goCell) end
	self.Controls.ChallengeList.onGetCellView:AddListener(self.callbackCreateItemList)
	
	self.callbackOnCellViewVisiable = function(goCell) self:OnCellViewVisiable(goCell) end
	self.Controls.ChallengeList.onCellViewVisiable:AddListener(self.callbackOnCellViewVisiable)
	
	self.Controls.scroller =  self.Controls.m_ChallengeList:GetComponent(typeof(EnhancedScroller))

	self.calbackCloseBtnClick = function() self:OnCloseBtnClick() end
	self.Controls.m_CloseChallengebtn.onClick:AddListener( self.calbackCloseBtnClick )
	return self
end


function WulinHeroChallengeInfoWidget:OnCloseBtnClick()
	UIManager.WulinHeroWindow:SetChallengeInfoWdiget(false)
end

-- item 被选中
function WulinHeroChallengeInfoWidget:OnItemCellSelected(itemCell ,on)
	if not on then
		return
	end

end

--- 刷新列表
function WulinHeroChallengeInfoWidget:RefreshCellItems( objCell )	
	
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

function WulinHeroChallengeInfoWidget:isLoaded()
	return self.transform ~= nil
end

-- 重新加载
function WulinHeroChallengeInfoWidget:ReloadData()
	if not self:isLoaded() then
		return
	end

	local nCellCount = IGame.WulinHeroClient:GetFightReportCount()
	if self.Controls.ChallengeList.CellCount == nCellCount then
		self.Controls.scroller:RefreshActiveCellViews()
	else
		self.Controls.ChallengeList:SetCellCount( nCellCount , true )
	end
end

-- 当一个cell被创建
function WulinHeroChallengeInfoWidget:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView)
	
	local item = WulinHeroChallengeClass:new()
	item:Attach(goCell)
end

-- 刷新
function WulinHeroChallengeInfoWidget:OnRefreshCellView( goCell )
	self:RefreshCellItems(goCell)
end

-- 单元可见时的回调
function WulinHeroChallengeInfoWidget:OnCellViewVisiable( goCell )

	self:RefreshCellItems( goCell )
end

function WulinHeroChallengeInfoWidget:OnDestroy()
	UIControl.OnDestroy(self)
end

return this