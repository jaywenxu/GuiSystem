
------------------------------------------------------------
-- MainTaskWindow 的子窗口,不要通过 UIManager 访问
-- 任务对话弹窗
------------------------------------------------------------

------------------------------------------------------------

local TaskPrizeGridCellClass = require( "GuiSystem.WindowList.Task.TaskPrizeGridCell" )

local TaskDescriptionWidget = UIControl:new
{
	windowName = "TaskDescriptionWidget",
	m_curTaskType = 0,
	m_curTaskInfo = nil,
	m_curTaskID = 0,
	m_curAcceptNPC,
	m_rewardCellObj = {},
	m_prizeCell = {},
}

local this = TaskDescriptionWidget   -- 方便书写

function TaskDescriptionWidget:Init()

end

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function TaskDescriptionWidget:Attach( obj )
	UIControl.Attach(self,obj)
	
	self.Controls.AcceptButton.onClick:AddListener(function() self:OnAcceptButtonClick() end)
	self.Controls.GiveUpButton.onClick:AddListener(function() self:OnGiveUpButtonClick() end)
	self.Controls.GoToButton.onClick:AddListener(function() self:GoToButtonClick() end)
	
	for i = 1,6 do
		local rewardCellObj = self.Controls.m_rewardGrid.transform:Find("MainTaskWin_RewardGoods_Cell" .. i).gameObject
		rewardCellObj:SetActive(false)
		self.m_prizeCell[i] = TaskPrizeGridCellClass:new()
		self.m_prizeCell[i]:Attach(rewardCellObj)
		self.m_rewardCellObj[i] = rewardCellObj
	end
	
	return self
end

function TaskDescriptionWidget:OnDestroy()
	

end

-----------------------------------------------------------
-- 设置父窗口
function TaskDescriptionWidget:SetParentWindow(win)
	self.m_ParentWindow = win
end

-----------------------------------------------------------
-- 接受任务
function TaskDescriptionWidget:OnAcceptButtonClick()
	if self.m_curAcceptNPC == nil or self.m_curAcceptNPC <= 0 then
		return
	end
	
	toNpc(self.m_curAcceptNPC)
	self.m_ParentWindow:Hide()
end

-----------------------------------------------------------
-- 放弃任务
function TaskDescriptionWidget:OnGiveUpButtonClick()
	if self.m_curTaskID  <= 0 then
		return
	end
	GameHelp.PostServerRequest("RequestDeleteTaskEx("..self.m_curTaskID..")") 
	self.m_ParentWindow:Hide()
end

-- 立即前往
function TaskDescriptionWidget:GoToButtonClick()
	local trackerInfo = IGame.TaskSick:GetTaskTracker(self.m_curTaskID)	
	IGame.TaskSick:ClickOnResponse(trackerInfo)
	
	self.m_ParentWindow:Hide()
end

-----------------------------------------------------------
-- 初始化数据
function TaskDescriptionWidget:InitCurTask()
	
	self.m_curTaskID = 0
	self.m_curTaskType = 0
	self.m_curTaskInfo = nil
	self.Controls.TaskTitle.text = ""
	self.Controls.TaskDescription.text = ""
	self.Controls.TaskReward.text = ""
	self.Controls.AcceptButton.transform.gameObject:SetActive(false)
	self.Controls.GiveUpButton.transform.gameObject:SetActive(false)
	self.Controls.GoToButton.transform.gameObject:SetActive(false)
	
	self:hidePrizeIcon()
end

-- 隐藏所有的奖励图标
function TaskDescriptionWidget:hidePrizeIcon()
	for i = 1,6 do
		local rewardCellObj = self.Controls.m_rewardGrid.transform:Find("MainTaskWin_RewardGoods_Cell" .. i).gameObject
		rewardCellObj:SetActive(false)
	end
end
	
-----------------------------------------------------------
-- 显示当前任务描述信息
function TaskDescriptionWidget:ShowCurTaskDescription(taskinfo,nTaskType)
	
	self:InitCurTask()
	if not taskinfo then
		return
	end
	GameHelp.PostServerRequest("RequestTaskDesc("..taskinfo.taskid..")")
	self.m_curTaskType = nTaskType
	self.m_taskInfo = taskinfo
	if self.m_curTaskType == UIManager.MainTaskWindow.taskAcceptedType then
		self.Controls.GoToButton.transform.gameObject:SetActive(true)
		self.Controls.GiveUpButton.transform.gameObject:SetActive(true)
		if taskinfo.allow_delete then
			self.Controls.GiveUpButton.interactable = true
			UIFunction.SetAllComsGray(self.Controls.GiveUpButton.gameObject,false)
		else
			self.Controls.GiveUpButton.interactable = false
			UIFunction.SetAllComsGray(self.Controls.GiveUpButton.gameObject,true)
		end
		
	elseif self.m_curTaskType == UIManager.MainTaskWindow.taskAvailableType then
		self.Controls.AcceptButton.transform.gameObject:SetActive(true)
	end
end

function TaskDescriptionWidget:ShowDisplayTaskDesc(taskDescInfo)
	self.m_curTaskID = taskDescInfo.id
	self.m_curAcceptNPC = taskDescInfo.accept_npc
	self.Controls.TaskTitle.text = taskDescInfo.aim
	self.Controls.TaskDescription.text = taskDescInfo.description
	local taskPrize = taskDescInfo.prize_array
	local exp = taskDescInfo.prize_exp or 0
	local yinbi = taskDescInfo.yinbi or 0
	local yinliang = taskDescInfo.yinliang or 0
	
	self:hidePrizeIcon()
	-- 显示经验、银币、银两奖励
	local i = 1
	if exp > 0 then
		self.m_rewardCellObj[i]:SetActive(true)
		self.m_prizeCell[i]:SetPrizeInfoEx(9001,exp)
		i = i + 1
	end
	
	if yinbi > 0 then
		self.m_rewardCellObj[i]:SetActive(true)
		self.m_prizeCell[i]:SetPrizeInfoEx(9004,yinbi)
		i = i + 1
	end
	
	if yinliang > 0 then
		self.m_rewardCellObj[i]:SetActive(true)
		self.m_prizeCell[i]:SetPrizeInfoEx(9003,yinliang)
		i = i + 1
	end
	
	if taskPrize == nil or taskPrize == "" then
		return
	end
	
	-- 显示物品奖励
	local tPrize = split_string(taskPrize,";",tonumber)
	for k,v in pairs(tPrize) do
		if (k + i - 1) > 6 then
			return
		end
		self.m_rewardCellObj[k + i - 1]:SetActive(true)
		self.m_prizeCell[ k + i - 1]:SetPrizeInfo(v)
	end
end
------------------------------------------------------------

return this