
------------------------------------------------------------
-- MainHUDWindow 的子窗口,不要通过 UIManager 访问
-- 任务对话弹窗
------------------------------------------------------------

------------------------------------------------------------
local TaskTeamWdiget = UIControl:new
{
	windowName = "TaskTeamWdiget",
	toggleType = 
	{
		taskToggle = 1,
		teamToggle = 2,
	},
	curToggle = 0,
}

local this = TaskTeamWdiget   -- 方便书写


------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function TaskTeamWdiget:Attach( obj )
	UIControl.Attach(self,obj)
	
	self.callback_OnTaskToggle = function(on) self:OnToggleChanged(on, self.toggleType.taskToggle) end
	self.callback_OnTeamToggle = function(on) self:OnToggleChanged(on, self.toggleType.teamToggle) end
	
	self.Controls.ToggleGroup = self.Controls.container.gameObject.transform:Find( "Toggles" ) -- :GetComponent(typeof(ToggleGroup))
	self.Controls.TaskToggle = self.Controls.ToggleGroup.transform:Find("TaskToggle"):GetComponent(typeof(Toggle))
	self.Controls.TeamToggle = self.Controls.ToggleGroup.transform:Find("TeamToggle"):GetComponent(typeof(Toggle))
	self.Controls.TaskToggle.onValueChanged:AddListener(self.callback_OnTaskToggle)
	self.Controls.TeamToggle.onValueChanged:AddListener(self.callback_OnTeamToggle)
	
	return self
end

function TaskTeamWdiget:OnDestroy()
	

end

-----------------------------------------------------------
-- 设置父窗口
function TaskTeamWdiget:SetParentWindow(win)
	self.m_ParentWindow = win
end

function TaskTeamWdiget:OnToggleChanged(on,toggleType)
	
	if not on then
		return
	end

	if self.curToggle == toggleType then
		-- 已经显示任务窗口，则不再显示
		if toggleType == self.toggleType.taskToggle and UIManager.MainTaskWindow:isShow()then
			return
		else 
			
		end
	end
	
	self.curToggle = toggleType
	
	-- 显示任务窗口，更新任务信息
	if toggleType == self.toggleType.taskToggle then
		UIManager.MainTaskWindow:Show()
		UIManager.MainTaskWindow:RefeshTaskInfo()
	end
end



------------------------------------------------------------

return this