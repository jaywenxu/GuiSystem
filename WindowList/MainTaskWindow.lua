

-- 任务窗口

------------------------------------------------------------
local MainTaskWindow = UIWindow:new
{
	windowName = "MainTaskWindow" ,
	m_NeedUpdate = false,
	m_CurItemID = 0,
	curToggle = 0,
	toggleType = 
	{
		acceptToggle = 1,
		availableToggle = 2,
	},
	taskAcceptedType = 1,	-- 已接任务类型
	taskAvailableType = 2,	-- 可接任务类型
}


------------------------------------------------------------
function MainTaskWindow:Init()
	self.TaskListWidget = require("GuiSystem.WindowList.Task.TaskListWidget")
	self.TaskDescriptionWidget = require("GuiSystem.WindowList.Task.TaskDescriptionWidget")
end

------------------------------------------------------------
function MainTaskWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	-- UIWindow.AddCommonWindowToThisWindow(self,true,m_titleImagePath,function() self:OnCloseButtonClick() end)
	
	self.TaskListWidget:Attach( self.Controls.mainTaskListWidget.gameObject )
	self.TaskListWidget:SetParentWindow(self)
	self.TaskDescriptionWidget:Attach( self.Controls.mainTaskDescriptionWidget.gameObject )
	self.TaskDescriptionWidget:SetParentWindow(self)
	
	self.callback_OnCloseButtonClick = function() self:OnCloseButtonClick() end
	self.Controls.CloseBtn.onClick:AddListener( self.callback_OnCloseButtonClick )
	
	self.callback_OnAcceptedToggle = function(on) self:OnToggleChanged(on, self.toggleType.acceptToggle) end
	self.callback_OnAvailableToggle = function(on) self:OnToggleChanged(on, self.toggleType.availableToggle) end
	
	self.Controls.ToggleGroup = self.transform:Find( "Common_Toggles" ):GetComponent(typeof(ToggleGroup))
	self.Controls.AcceptedToggle = self.Controls.ToggleGroup.transform:Find("Common_Toggle_Accepted"):GetComponent(typeof(Toggle))
	self.Controls.AvailableToggle = self.Controls.ToggleGroup.transform:Find("Common_Toggle_Available"):GetComponent(typeof(Toggle))
	self.Controls.AcceptedToggle.onValueChanged:AddListener(self.callback_OnAcceptedToggle)
	self.Controls.AvailableToggle.onValueChanged:AddListener(self.callback_OnAvailableToggle)
	
	if self.m_NeedUpdate == true then
		self.m_NeedUpdate = false
		self:OnNeedUpdate()
	end
    return self
end
------------------------------------------------------------
------------------------------------------------------------
function MainTaskWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end
-----------------------------------------------------------
-- 关闭窗口
function MainTaskWindow:OnCloseButtonClick()
	self:ClearInfo()
	self:Hide()
end
-----------------------------------------------------------
-- 清除信息
function MainTaskWindow:ClearInfo()
	self.m_CurItemID = 0
	self.curToggle = 0
end

-- 响应标签
function MainTaskWindow:OnToggleChanged(on, toggleIndex)
	
	if not on then
		self.TaskListWidget:ShowOrHideTaskArea(toggleIndex,false)
		return
	end
	self.TaskListWidget:ShowOrHideTaskArea(toggleIndex,true)
	if self.curToggle == toggleIndex then -- 相同标签不用响应
		return
	end
	
	self.curToggle = toggleIndex
	self:ShowTaskInfo()
end

-- OnAttach 之后需要更新
function MainTaskWindow:OnNeedUpdate()
	self:ShowTaskInfo()
end

-- 显示已经任务信息
function MainTaskWindow:ShowAcceptedTasksInfo()
	self.TaskListWidget:RefeshAcceptedTasks()
end

-- 显示可接任务信息
function MainTaskWindow:ShowAvailableTasksInfo()
	
	self.TaskListWidget:RefeshAvailableTasks()
end

-- 显示当前任务信息
function MainTaskWindow:ShowTaskInfo()
    if not self:isLoaded() then
        self.m_NeedUpdate = true
        return
    end

	-- 显示已经任务
	if not self.curToggle or self.curToggle == 0 then
		self.Controls.AcceptedToggle.isOn = true
		self.curToggle = self.toggleType.acceptToggle
	end
	-- 显示已经任务信息
	if self.curToggle == self.toggleType.acceptToggle then
		self:ShowAcceptedTasksInfo()
	else
	-- 显示可接任务信息
		self:ShowAvailableTasksInfo()
	end
end
-- 刷新任务信息
function MainTaskWindow:RefeshTaskInfo()

	if self:isLoaded() then
		self:ShowTaskInfo()
	else
		self.m_NeedUpdate = true
	end
end

function MainTaskWindow:ShowCurTaskDescription(taskinfo,nTaskType)
	
	self.TaskDescriptionWidget:ShowCurTaskDescription(taskinfo,nTaskType)
end

function MainTaskWindow:ShowDisplayTaskDesc(taskDescInfo)
	self.TaskDescriptionWidget:ShowDisplayTaskDesc(taskDescInfo)
end

return MainTaskWindow
