
------------------------------------------------------------
-- 创建任务追踪单元,不要通过 UIManager 访问
-- 任务追踪
------------------------------------------------------------

------------------------------------------------------------
local TaskTrackerElementCell = UIControl:new
{
	windowName = "TaskTrackerElementCell",
	-- contentText
	-- timeText
	m_trackInfo = nil,				 -- { [1] = 标题颜色 , [2] = 标题 , [3] = {} , }
	m_funlist = nil,
	
	--m_headLine = "",				  -- 标题
	--m_msg = "",						  -- 内容
	m_content = "",						-- 内容
	m_taskID = nil,
	m_TimerCallBack,				-- 倒计时定时器
	m_LeftTime,						-- 剩余时间（秒）
	
	m_timer = -1,					--精确计时时刻变量
}

local this = TaskTrackerElementCell   -- 方便书写


------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function TaskTrackerElementCell:Attach( obj )
	UIControl.Attach(self,obj)

	self.callbackToggleChange = function( on ) self:OnToggleChange(on) end 
    self.Controls.ItemToggle = self.Controls.Clickable.transform:GetComponent(typeof(Toggle))
    self.Controls.ItemToggle.onValueChanged:AddListener( self.callbackToggleChange )
	
	return self
end

function TaskTrackerElementCell:OnDestroy()
	self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callbackToggleChange )
	UIControl.OnDestroy(self)
	self:StopTimer()
end

-----------------------------------------------------------
-- 设置父窗口
function TaskTrackerElementCell:SetParentWindow(win)
	self.m_ParentWindow = win
end

-----------------------------------------------------------
-- toggle 组
function TaskTrackerElementCell:SetToggleGroup( toggleGroup )
    self.Controls.ItemToggle.group = toggleGroup
end

-----------------------------------------------------------
function TaskTrackerElementCell:UpdateItemInfo(taskid, trackerInfo)
	self.m_trackInfo = trackerInfo
	self.Controls.contentText.text = ""
	local txt,remainTime = IGame.TaskSick:GetShowText(trackerInfo)
	if txt then
		self.Controls.contentText.text = txt
		self.m_content = txt
	end
	
	if remainTime then
		self.m_LeftTime = remainTime
		self.m_timer = luaGetTickCount()
		self:SetReMainTime()
	end
end

-- 显示剩余时间,settimer直接计时会有误差产生,故废弃, 预留
--[[function TaskTrackerElementCell:SetReMainTime()
	self.m_TimerCallBack = function() --倒计时timer
		self.m_LeftTime = self.m_LeftTime - 1
		if self.m_LeftTime < 0 then
			self:StopTimer()
			return
		end
		self.Controls.contentText.text = self.m_content .. "<color=#1CFA13>" .. GetCDTime(self.m_LeftTime,7,2) .. "</color>"
	end
	rktTimer.SetTimer(self.m_TimerCallBack, 1000, -1, "TaskTrackerElementCell")
end--]]

-- 显示剩余时间,修改为精确计时
function TaskTrackerElementCell:SetReMainTime()
	self.m_TimerCallBack = function() --倒计时timer
		local curTime = luaGetTickCount()
		local passTime = curTime - self.m_timer		
		self.m_timer = curTime
		self.m_LeftTime = self.m_LeftTime - passTime / 1000
		if self.m_LeftTime < 0 then
			self:StopTimer()
			return
		end
		self.Controls.contentText.text = self.m_content .. "<color=#1CFA13>" .. GetCDTime(self.m_LeftTime,7,2) .. "</color>"
	end
	rktTimer.SetTimer(self.m_TimerCallBack, 30, -1, "TaskTrackerElementCell")
end

-- 关闭定时器
function TaskTrackerElementCell:StopTimer()
	if self.m_TimerCallBack ~= nil then
		self.m_timer = -1
		rktTimer.KillTimer(self.m_TimerCallBack)
		self.m_TimerCallBack = nil
	end
end

-----------------------------------------------------------
-- 响应toggle点击
function TaskTrackerElementCell:OnToggleChange(on)
	if on == false then
		return
	end
    
	IGame.TaskSick:ClickOnResponse( self.m_trackInfo )
end

function TaskTrackerElementCell:OnRecycle()
	self:StopTimer()
	self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callbackToggleChange )
	UIControl.OnRecycle(self)
	table_release(self)
end
------------------------------------------------------------

return this