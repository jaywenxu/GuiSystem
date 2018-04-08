local TitleListCellClass =  require("GuiSystem.WindowList.Player.TitleListCell")
local TitleToggle =  require("GuiSystem.WindowList.Player.TitleToggleCell")
local TitleWindow = UIWindow:new
{
	windowName = "TitleWindow" ,
}
	
---------------------------------------------------------------
function TitleWindow:Init()

end
---------------------------------------------------------------
function TitleWindow:OnAttach( obj )    
	UIWindow.OnAttach(self,obj)
	-- 称号列表
	self.callBackOnGetCellView = function(objCell) self:OnGetCellView(objCell) end
	local enhanceListView = self.Controls.m_TitleListScroller:GetComponent(typeof(EnhancedListView))
	enhanceListView.onGetCellView:AddListener(self.callBackOnGetCellView)
	self.callBackTargetTeamCellVis = function(objCell) self:OnGetTargetCellTeamVisiable(objCell) end
	enhanceListView.onCellViewVisiable:AddListener(self.callBackTargetTeamCellVis)
	enhanceListView:SetCellCount( 0 , true )
	
	-- 称号分类
	self.LeftListView = self.Controls.m_LeftListScroller:GetComponent(typeof(EnhancedListView))
	self.callbackOnLeftGetCellView = function(objCell) self:OnLeftGetCellView(objCell) end
	self.LeftListView.onGetCellView:AddListener(self.callbackOnLeftGetCellView)
	self.callBackOnRefreshCellView = function(objCell) self:OnRefreshToggleCellView(objCell) end
	self.LeftListView.onCellViewVisiable:AddListener(self.callBackOnRefreshCellView)
	self.Controls.LeftEnhanceGroup = self.Controls.m_toggleGroup:GetComponent(typeof(ToggleGroup))
	self:Show()
	self:OnEnable()
end

function TitleWindow:OnDisable()
	
end

---------------------------------------------------------------
function TitleWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

---------------------------------------------------------------
--关闭按钮
function TitleWindow:OnCloseButtonClick() 
	UIManager.TitleWindow:Hide()
end

---------------------------------------------------------------
--组件启动时调用
function TitleWindow:OnEnable()
	local tTypeTitle = IGame.TitleClient:GetTitleType()
	self.LeftListView:SetCellCount(0, true)
	self.LeftListView:SetCellCount(table.getn(tTypeTitle), true)
	self:SelectType(1)
end

-- 称号右侧列表
function TitleWindow:OnGetCellView(objCell) 
	local item = TitleListCellClass:new()
	item:Attach(objCell)
end

function TitleWindow:OnGetTargetCellTeamVisiable(objCell)
	local viewCell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))
	local behav = objCell:GetComponent(typeof(UIWindowBehaviour))
	if behav then
		local item = behav.LuaObject
		local info = IGame.TeamClient:GetQueryTeam(self.currentTargetID, viewCell.cellIndex+1)
		item:RefreshCellUI(301, 1, false)
	end
end

-- 称号左侧分类
function TitleWindow:OnLeftGetCellView(objCell) 
	local viewCell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))
	if nil == viewCell then 
		return
	end
	local toggleItem = TitleToggle:new()
	toggleItem:Attach(objCell)
	toggleItem:SetToggleGroup(self.Controls.LeftEnhanceGroup)	
end

function TitleWindow:SelectType(nType)
	if self.nSelectType and self.nSelectType == nType then
		return
	end
	local enhanceListView = self.Controls.m_TitleListScroller:GetComponent(typeof(EnhancedListView))
	enhanceListView:SetCellCount(0, true)
	local tTypeTitle = IGame.TitleClient:GetTitleType()
	if tTypeTitle[nType] == nil then
		return
	end
	enhanceListView:SetCellCount(table.getn(tTypeTitle[nType]), true)
end

function TitleWindow:OnRefreshToggleCellView(objCell) 
	local viewCell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))
	local behav = objCell:GetComponent(typeof(UIWindowBehaviour))
	if nil == viewCell then 
		return
	end
	if viewCell.cellIndex < 0 then
		return
	end
	if behav == nil then 
		return
	end
	local nType = viewCell.cellIndex+1
	local szTypeName = IGame.TitleClient:GetTitleTypeName(nType)
	local tTypeTitle = IGame.TitleClient:GetTitleType()
	if tTypeTitle[nType] == nil then
		return
	end
	local item = behav.LuaObject	
	item:Refresh(szTypeName, 0, table.getn(tTypeTitle[nType]), nType)	
end

return TitleWindow
