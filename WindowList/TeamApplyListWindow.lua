--组队申请列表窗口
------------------------------------------------------------
local TeamApplyListCellClass = require("GuiSystem.WindowList.Team.TeamApplyListCell")
------------------------------------------------------------
local TeamApplyListWindow = UIWindow:new
{
	windowName = "TeamApplyListWindow" ,
	m_currentCount = nil,
	m_haveDoEnable =false
}

------------------------------------------------------------
function TeamApplyListWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.enhanceListView = self.Controls.m_ApplyList:GetComponent(typeof(EnhancedListView))
	
	self.CallBackGetCell = function(obj) self:GetRequestCell(obj) end
	self.enhanceListView.onGetCellView:AddListener(self.CallBackGetCell)
	
	self.CallBackVisiableCell =function(obj) self:GetRequestCellVisable(obj) end
	self.enhanceListView.onCellViewVisiable:AddListener(self.CallBackVisiableCell)
	
	self.callBackOnCloseButtonClick = function() self:OnCloseButtonClick() end
	self.Controls.m_CloseButton.onClick:AddListener(self.callBackOnCloseButtonClick)
	
	self.callBackOnClearListButtonClick =  function() self:OnClearListButtonClick() end
	self.Controls.m_ClearListButton.onClick:AddListener(self.callBackOnClearListButtonClick)
    
    self.callBackOnClickBG = function() self:OnCloseButtonClick() end
    self.Controls.m_btnBG.onClick:AddListener(self.callBackOnClickBG)
    
			--申请请求
	self.BuildFlowRequest = function(event, srctype, srcid, eventData) self:BuildRequest(eventData) end
	self.callbackOnEnable = function() self:OnEnable() end
	self.unityBehaviour.onEnable:AddListener(self.callbackOnEnable) 
	self.unityBehaviour.onDisable:AddListener(function() self:OnDisable() end)
	if self.m_haveDoEnable == false then 
		self:OnEnable()
	end
		
	return self
end

function TeamApplyListWindow:BuildRequest(eventData)
	local teamRequestInfo = IGame.TeamClient:GetRequestPersonInfo()	
	local count = 0
	if nil ~= teamRequestInfo then 
		count = table_count(teamRequestInfo)
	end
	self.enhanceListView:SetCellCount( count , true )
	self.m_currentCount = count
end

function TeamApplyListWindow:GetRequestCell(objCell)
	local itemClass = TeamApplyListCellClass:new({})
	itemClass:Attach(objCell)
end

function TeamApplyListWindow:GetRequestCellVisable(obj)
	local viewCell = obj.transform:GetComponent(typeof(EnhancedListViewCell))
	local behav = obj:GetComponent(typeof(UIWindowBehaviour))
	local teamRequestInfo = IGame.TeamClient:GetRequestPersonInfo()	
	if nil ~= behav then
		local item = behav.LuaObject	
		local Info = teamRequestInfo[viewCell.cellIndex+1]
        if Info then 
            item:RefreshCellUI(Info)
        end
	end
end

------------------------------------------------------------
function TeamApplyListWindow:OnEnable()
	self.m_haveDoEnable  =true
	local teamRequestInfo = IGame.TeamClient:GetRequestPersonInfo()	
	local count = 0
	if nil ~= teamRequestInfo then 
		count = table_count(teamRequestInfo)
	end
	self.enhanceListView:SetCellCount( count , true )
	self.m_currentCount = count

	rktEventEngine.SubscribeExecute( EVENT_TEAM_BUILDFLOW_REQUEST , SOURCE_TYPE_TEAM , 0 , self.BuildFlowRequest)	
end

function TeamApplyListWindow:Remove()
	local teamRequestInfo = IGame.TeamClient:GetRequestPersonInfo()	
	local count = 0
	if nil ~= teamRequestInfo then 
		count = table_count(teamRequestInfo)
	end
	self.enhanceListView:SetCellCount( count , true )
	self.m_currentCount = count
	if self.m_currentCount == 0 then 
		self:CheckRedDot()
	end
end

function TeamApplyListWindow:OnDestroy()
	self.m_haveDoEnable =false
	UIWindow.OnDestroy(self)
end

function TeamApplyListWindow:OnDisable()
	self.m_haveDoEnable =false
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_BUILDFLOW_REQUEST , SOURCE_TYPE_TEAM , 0 , self.BuildFlowRequest)	
end

function TeamApplyListWindow:CheckRedDot()
	UIManager.TeamApplyListWindow:Hide(false)
	UIManager.MainLeftCenterWindow:CheckTeamRedDot()
	UIManager.TeamWindow.WidgetConfigInfo[2].widgetScript:CheckTeamRedDot()
end
------------------------------------------------------------
function TeamApplyListWindow:OnCloseButtonClick()
	UIManager.TeamApplyListWindow:Hide()
	UIManager.MainLeftCenterWindow:CheckTeamRedDot()
end
------------------------------------------------------------
--清空所有申请列表
function TeamApplyListWindow:OnClearListButtonClick()
	self.m_currentCount = 0
	self.enhanceListView:SetCellCount( 0 , true )
	IGame.TeamClient:luaRefuseAllRequest()
	self:CheckRedDot()
end
------------------------------------------------------------
return  TeamApplyListWindow