
----------------------------------------------------------------
---------------------------------------------------------------
-- 主界面左边中间部分窗口
-- 包含：任务追踪信息，组队信息
---------------------------------------------------------------
------------------------------------------------------------
local MainLeftCenterWindow = UIWindow:new
{
	windowName = "MainLeftCenterWindow" ,
	mNeedUpDate = false,
	m_cureTaskType = 0,
	toggleType = 
	{		
		taskToggle = 1,
		teamToggle = 2,
	},
	curToggle = 0,
	MyTeam = nil,						--我的队伍
	m_haveDoEnable =false,
}

local this = MainLeftCenterWindow   -- 方便书写
local TeamWindowClass = require("GuiSystem.WindowList.TeamWindow")
------------------------------------------------------------
function MainLeftCenterWindow:Init()
   
	self.TaskTrackerWidget = require("GuiSystem.WindowList.Task.TaskTrackerWidget")
    self.TeamPanelWidget = require("GuiSystem.WindowList.Team.TeamPanelWidget")
	self.TeamShowPanelWindowClass = require("GuiSystem.WindowList.TeamShowPanelWindow")
	self.WarWnd = require("GuiSystem.WindowList.WarWnd")
	self.WarWnd:Init()
end
------------------------------------------------------------
function MainLeftCenterWindow:OnAttach( obj )

	UIWindow.OnAttach(self,obj,UIManager._MainHUDLayer)
    
	self.unityBehaviour.onEnable:AddListener(function() self:OnEnable() end) 
	self.unityBehaviour.onDisable:AddListener(function() self:OnDisable() end) 
	self.TaskTrackerWidget:Attach( self.Controls.m_TaskTrackerWidget.gameObject )
	self.TeamPanelWidget:Attach( self.Controls.m_TeamPanelWidget.gameObject )
	self.WarWnd:Attach( self.Controls.m_WarWnd.gameObject )
	self.ToggleChangeTask =  function(isOn) self:OnToggleChangeTask(isOn, self.toggleType.taskToggle) end
 	self.ToggleChangeTeam = function(isOn) self:OnToggleChangeTeam(isOn, self.toggleType.teamToggle) end
	self.callback_OnTaskToggle = function(isOn) self:OnTaskToggleChanged() end
	self.callback_OnTeamToggle = function(isOn) self:OnTeamToggleChanged() end
	self.Controls.ToggleGroup = self.Controls.m_Container.gameObject.transform:Find( "Toggles" )
	UIFunction.AddEventTriggerListener(self.Controls.m_taskEventTrriger,EventTriggerType.PointerClick,self.callback_OnTaskToggle)
	UIFunction.AddEventTriggerListener(self.Controls.m_teamEventTrriger,EventTriggerType.PointerClick,self.callback_OnTeamToggle)
	self.Controls.TaskToggle.onValueChanged:AddListener(self.ToggleChangeTask)
	self.Controls.TeamToggle.onValueChanged:AddListener(self.ToggleChangeTeam)
	
	-- 打开按钮
	self.calbackOpenClick = function() self:OnOpenButtonClick() end
	self.Controls.m_OpenButton.onClick:AddListener( self.calbackOpenClick )
	
	-- 关闭按钮
	self.calbackCloseClick = function() self:OnCloseButtonClick() end
	self.Controls.m_CloseButton.onClick:AddListener( self.calbackCloseClick )
	
	if self.mNeedUpDate then
		self.mNeedUpDate = false
		self:NeedUpdate()
	end
	self.RequestTeamFun = function() self:CheckTeamRedDot() end
	rktEventEngine.SubscribeExecute( EVENT_TEAM_BUILDFLOW_REQUEST , SOURCE_TYPE_TEAM , 0, 	self.RequestTeamFun)
	self.InviteTeamFun = function(event, srctype, srcid, eventData) self:InviteTeam(eventData) end
	rktEventEngine.SubscribeExecute( EVENT_TEAM_BUILDFLOW_INVITED , SOURCE_TYPE_TEAM , 0, 	self.InviteTeamFun)
	self.LeaderChange =function() self:CheckTeamRedDot() end
	rktEventEngine.SubscribeExecute( EVENT_TEAM_CAPTAIN , SOURCE_TYPE_TEAM , 0, 	self.LeaderChange)
	
	self:CheckTeamRedDot()
	if self.m_haveDoEnable == false then 
		self:OnEnable()
	end
    
    self.QuitTeam = function(event, srctype, srcid, eventData) self:OnQuitTeam(event, srctype, srcid, eventData) end 
	rktEventEngine.SubscribeExecute( EVENT_TEAM_QUITTEAM , SOURCE_TYPE_TEAM , 0, self.QuitTeam)
    
    self.CreateTeam = function(event, srctype, srcid, eventData) self:OnCreateTeam(event, srctype, srcid, eventData) end 
	rktEventEngine.SubscribeExecute( EVENT_TEAM_CREATETEAM , SOURCE_TYPE_TEAM , 0 , self.CreateTeam)
   
	if self.m_cureTaskType > 0 then
		self:ShowWarWnd(self.m_cureTaskType)
	end
	return self
end

function MainLeftCenterWindow:RefreshTeamCount()

    if not self:isLoaded() then return end 
    
    local myTeam = IGame.TeamClient:GetTeam()
    local teamCount = ""
    if myTeam and myTeam:GetTeamID() ~= INVALID_TEAM_ID then 
        teamCount =string.format("(%s/4)", myTeam:GetMemberCount())  
    end
    self.Controls.m_teamCount.text = teamCount
end

function MainLeftCenterWindow:RegisterTeamEvent()
	local team = IGame.TeamClient:GetTeam()
	if team == nil then 
		return
	end
	local teamId = team:GetTeamID()
	--加入队伍
	self.JoinTeam = function(event, srctype, srcid, eventData) self:RefreshTeamCount() end 
	rktEventEngine.SubscribeExecute( EVENT_TEAM_JOINTEAM , SOURCE_TYPE_TEAM , teamId , self.JoinTeam)
	
	--队员离开
    self.TeamMemberLeaveEvent = function(event, srctype, srcid, eventData) self:RefreshTeamCount() end
	rktEventEngine.SubscribeExecute( EVENT_TEAM_LEAVETEAM , SOURCE_TYPE_TEAM , teamId , self.TeamMemberLeaveEvent)
end

function MainLeftCenterWindow:UnRegisterEvent()

	--加入队伍
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_JOINTEAM , SOURCE_TYPE_TEAM , teamId , self.JoinTeam)
	
	--队员离开
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_LEAVETEAM , SOURCE_TYPE_TEAM , teamId , self.TeamMemberLeaveEvent)
end

-- 主角退队
function MainLeftCenterWindow:OnQuitTeam()
	self:RefreshTeamCount()
	self:UnRegisterEvent()
end

-- 主角入队
function MainLeftCenterWindow:OnCreateTeam()
	self.Controls.TeamToggle.isOn = true
	self:RefreshTeamCount()
	self:RegisterTeamEvent()
end


function MainLeftCenterWindow:OnEnable()
    
	local myTeam = IGame.TeamClient:GetTeam()
    self:RefreshTeamCount()

	self.m_haveDoEnable = true
	self:CheckTeamRedDot()
	if self.Controls.TaskToggle.isOn == true then 
		self:OnToggleChangeTask(true)
	else
		self.curToggle = toggleType
		
		if not myTeam or myTeam:GetTeamID() == INVALID_TEAM_ID then
			--显示组队面板
			self.Controls.m_TeamPanelWidget.gameObject:SetActive(true)
		else
			self.Controls.m_TeamPanelWidget.gameObject:SetActive(false)
			UIManager.TeamShowPanelWindow:Show()			
		end
	end
end

function MainLeftCenterWindow:OnDisable()

end
------------------------------------------------------------
------------------------------------------------------------
function MainLeftCenterWindow:OnDestroy()
	self.m_haveDoEnable = false
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_BUILDFLOW_REQUEST , SOURCE_TYPE_TEAM , 0,self.RequestTeamFun)
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_BUILDFLOW_INVITED , SOURCE_TYPE_TEAM , 0,self.InviteTeamFun)
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_QUITTEAM , SOURCE_TYPE_TEAM , 0, self.QuitTeam)
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_CREATETEAM , SOURCE_TYPE_TEAM , 0 , self.CreateTeam)
   	UIWindow.OnDestroy(self)
end

function MainLeftCenterWindow:InviteTeam(eventData)
	local info = eventData
	UIManager.TeamInvitedRespondWindow:InitInfo(info)
	UIManager.TeamInvitedRespondWindow:Show()
end

function MainLeftCenterWindow:CheckTeamRedDot()
    
    if not self:isLoaded() or not self:isShow() then 
        return
    end 
    
	local teamRequestInfo = IGame.TeamClient:GetRequestPersonInfo()	
	if not teamRequestInfo or table_count(teamRequestInfo) < 1 or not GetHero():IsTeamCaptain() then 
		self:SetTeamRedDot(false)
		return 
	end

    self:SetTeamRedDot(true)
end

function MainLeftCenterWindow:SetTeamRedDot(State)
	self.m_teamHaveRedDot = State
	if self:isLoaded() then
		self.Controls.m_teamRedDot.gameObject:SetActive(State)
	end
end

--任务Toggle变换
function MainLeftCenterWindow:OnToggleChangeTask(isOn,toggleType)
	if isOn == false then
		return
	end
	self.TeamShowPanelWindowClass:Hide()
	--[[if self.curToggle == toggleType then
		-- 已经显示任务窗口，则不再显示
		if toggleType == self.toggleType.taskToggle and UIManager.MainTaskWindow:isShow()then
			return
		end
	end
	--]]
	self.curToggle = toggleType
	
	-- 显示任务窗口，更新任务信息
	if toggleType == self.toggleType.taskToggle then
		
		--隐藏组队面板
		self.Controls.m_TeamPanelWidget.gameObject:SetActive(false)
		self:ShowUpTabWidgetByType(self.m_cureTaskType)
	end
end

--队伍TOGGLE变换
function MainLeftCenterWindow:OnToggleChangeTeam(isOn,toggleType)
	if isOn == false then
		UIManager.TeamShowPanelWindow:Hide()
		self.Controls.m_TeamPanelWidget.gameObject:SetActive(false)
		
	elseif toggleType == self.toggleType.teamToggle then
		self.Controls.m_TaskTrackerWidget.gameObject:SetActive(false)
		self.Controls.m_WarWnd.gameObject:SetActive(false)
		self.curToggle = toggleType
		local MyTeam = IGame.TeamClient:GetTeam()
		if MyTeam:GetTeamID() == INVALID_TEAM_ID then
			--显示组队面板
			self.Controls.m_TeamPanelWidget.gameObject:SetActive(true)
			self:OnTeamToggleChanged()
		else
			self.Controls.m_TeamPanelWidget.gameObject:SetActive(false)
			UIManager.TeamShowPanelWindow:Show()			
		end		
	end
end

-- 显示战场界面
function MainLeftCenterWindow:ShowWarWnd(nWarType)
	self:ShowUpTabWidgetByType(nWarType)
end

-- 隐藏战场界面
function MainLeftCenterWindow:HideWarWnd(nWarType)
	
	if not self.Controls.TaskToggle then
		return
	end
	
	if self.WarWnd:GetWarType() ~= nWarType then
		return
	end
	self:ShowUpTabWidgetByType(0)	
end

function MainLeftCenterWindow:ShowUpTabWidgetByType(widgetType)

	self.m_cureTaskType = widgetType
	
	if not self.Controls.TaskToggle then
		return
	end
	
	self.Controls.TaskToggle.isOn = true
	self.Controls.TeamToggle.isOn = false
	if widgetType == 0 then 
		self.TaskTrackerWidget:Show()
		self.WarWnd:Hide()
		self.Controls.m_TaskTextOff.text = "任务"
		self.Controls.m_TaskText.text = "任务"
	else
		self.TaskTrackerWidget:Hide()
		self.WarWnd:Show(widgetType)
		self.Controls.m_TaskTextOff.text = "目标"
		self.Controls.m_TaskText.text = "目标"
	end	
end

-- 显示任务跟踪list
function MainLeftCenterWindow:ShowTask()
	if self:isLoaded() then 
		self.Controls.TaskToggle.isOn = true
	end
	
end

function MainLeftCenterWindow:ShowWindow()
end

------------------------------------------------------------
-- 需要刷新
function MainLeftCenterWindow:NeedUpdate()
	self.TaskTrackerWidget:UpdateAllTaskTracker()
end

------------------------------------------------------------
-- 展开
function MainLeftCenterWindow:OnOpenButtonClick()
	
	self.Controls.m_Container.gameObject:SetActive(true)
	self.Controls.m_OpenButton.gameObject:SetActive(false)
--[[	if self.curToggle == self.toggleType.taskToggle then 
		self:OnToggleChangeTask(true,self.toggleType.taskToggle)
		self:OnToggleChangeTeam(false,self.toggleType.teamToggle)
	else
		self:OnToggleChangeTask(false,self.toggleType.taskToggle)
		self:OnToggleChangeTeam(true,self.toggleType.teamToggle)
	end--]]
end

------------------------------------------------------------
-- 收起
function MainLeftCenterWindow:OnCloseButtonClick()
	
	self.Controls.m_Container.gameObject:SetActive(false)
	self.Controls.m_OpenButton.gameObject:SetActive(true)
	if self.curToggle == self.toggleType.taskToggle then
		UIManager.MainTaskWindow:Hide()
	else
		UIManager.TeamShowPanelWindow:Hide()
	end
end
------------------------------------------------------------
--当任务面板Toogle被按下
function MainLeftCenterWindow:OnTaskToggleChanged(isOn,toggleType)

	UIManager.MainTaskWindow:Show()
	UIManager.MainTaskWindow:RefeshTaskInfo()
end

------------------------------------------------------------
-- 更新所有任务追踪列表
function MainLeftCenterWindow:UpdateAllTaskTracker()
	
	if self:isLoaded() then
		self.TaskTrackerWidget:UpdateAllTaskTracker()
	else
		self.mNeedUpDate = true
	end
end

------------------------------------------------------------
-- 更新任务追踪列表
function MainLeftCenterWindow:UpdateTaskTracker(nTaskID, taskTrackerInfo, nCRC, accept)
	if self.TaskTrackerWidget then
		self.TaskTrackerWidget:UpdateTaskTracker(nTaskID, taskTrackerInfo, nCRC, accept)
		self:ShowTask()
	end
end

------------------------------------------------------------
-- 删除任务追踪信息
function MainLeftCenterWindow:DeleteTaskTracker(nTaskID)
	if self.TaskTrackerWidget then
		self.TaskTrackerWidget:DeleteTaskTracker(nTaskID)
	end
end

------------------------------------------------------------
--当组队面板Toogle被按下
--第一个参数：当前Toogle是否被激活
--第二个参数：toogleType类型
function MainLeftCenterWindow:OnTeamToggleChanged()

	UIManager.TeamWindow:Show()
end
------------------------------------------------------------


return this
