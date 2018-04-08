
------------------------------------------------------------
-- 创建单元,不要通过 UIManager 访问
-- 任务对话弹窗
------------------------------------------------------------

------------------------------------------------------------
local TaskElementToggleCell = UIControl:new
{
	windowName = "TaskElementToggleCell",
--[[	m_taskid = 0,
	m_taskname = "",
	m_tasklevel = 0,
	m_taskworthness = 0,
	m_taskacceptnpc = 0,
	m_tasksztype = "",
	m_tasksymol = 0,
	m_tasktype = 0,--]]
	m_taskInfo = nil,
	m_taskBtnType = 1,  -- 1 :已接任务  2:可接任务
	m_index = 1,
}

local this = TaskElementToggleCell   -- 方便书写


------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function TaskElementToggleCell:Attach( obj )
	UIControl.Attach(self,obj)
	
	self.callbackToggleChange = function( on ) self:OnToggleChange(on) end 
    self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))
    self.Controls.ItemToggle.onValueChanged:AddListener( self.callbackToggleChange )
	
	return self
end

function TaskElementToggleCell:OnDestroy()
	self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callbackToggleChange )
	UIControl.OnDestroy(self)
end
function TaskElementToggleCell:OnRecycle()
	self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callbackToggleChange )
end

-----------------------------------------------------------
-- 设置父窗口
function TaskElementToggleCell:SetParentWindow(win)
	self.m_ParentWindow = win
end

-----------------------------------------------------------
-- toggle 组
function TaskElementToggleCell:SetToggleGroup( toggleGroup )
    self.Controls.ItemToggle.group = toggleGroup
end

function TaskElementToggleCell:SetToggleState(state)
	self.Controls.ItemToggle.isOn = state
end

-----------------------------------------------------------
-- 响应toggle点击
function TaskElementToggleCell:SetItemInfo(taskInfo,taskBtnType,index)

	if not taskInfo then
		return
	end
	self.m_taskInfo = taskInfo
	self.m_taskBtnType = taskBtnType
	self.m_index = index
	self.Controls.titleText.text = "<color=#517880>"..tostring(self.m_taskInfo.taskname).."</color>" 
	if self.m_index == 1 then
		self:SetToggleState(true)
	end
end

-----------------------------------------------------------
-- 响应toggle点击
function TaskElementToggleCell:OnToggleChange(on)
	
	if not on then
		self.Controls.titleText.text = "<color=#517880>"..tostring(self.m_taskInfo.taskname).."</color>"
		return
	else
		self.Controls.titleText.text = "<color=#935923>"..tostring(self.m_taskInfo.taskname).."</color>"
	end
	if not self.m_taskInfo then
		return
	end
	UIManager.MainTaskWindow:ShowCurTaskDescription(self.m_taskInfo,self.m_taskBtnType)
end

------------------------------------------------------------

return this