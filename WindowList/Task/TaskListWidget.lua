	
------------------------------------------------------------
-- MainTaskWindow 的子窗口,不要通过 UIManager 访问
-- 任务对话弹窗
------------------------------------------------------------

-- 任务类型 
-- 1：主线任务
-- 2：日常
-- 3：节日活动
-- 4：支线任务
-- 5：外传

local TaskElementToggleCellClass = require( "GuiSystem.WindowList.Task.TaskElementToggleCell" )

------------------------------------------------------------
local TaskListWidget = UIControl:new
{
	windowName = "TaskListWidget",
	m_taskType = 1,
	
	
	-- 便签列表
	m_TaskAvailableNodeList = {
	},
	-- 可接任务列表
	m_TaskAvailableList = {
		-- [1] = {  }  -- 主线任务列表
		-- [2] = {  }  -- 支线任务列表
	},

	mianLine = 1,		-- 主线任务
	dailyLine = 2,		-- 日常任务
	festivalLine = 3,	-- 节日任务
	branchLine = 4,		-- 支线任务
	otherLine	= 5,	-- 外传任务
	
	taskTitleName = 
	{
		[1] = "主线任务",
		[2] = "日常任务",
		[3] = "节日任务",
		[4] = "支线任务",
		[5] = "外传任务",
	},
		
}

local this = TaskListWidget   -- 方便书写


------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function TaskListWidget:Attach( obj )
	UIControl.Attach(self,obj)
	
	-- self.Controls.AcceptedTaskToggleGroup 
	-- self.Controls.AcceptableTaskToggleGroup
	self.Controls.AcceptedToggleGroup = self.Controls.AcceptedTaskToggleGroup.transform:GetComponent(typeof(ToggleGroup))
	self.Controls.AcceptableToggleGroup = self.Controls.AcceptableTaskToggleGroup.transform:GetComponent(typeof(ToggleGroup))
	
	-- 可接任务
	self.callbackAvailableTaskToggle1 = function(on) self:OnAvailableToggleChanged(on, self.mianLine) end
	self.callbackAvailableTaskToggle2 = function(on) self:OnAvailableToggleChanged(on, self.branchLine) end
	self.callbackAvailableTaskToggle3 = function(on) self:OnAvailableToggleChanged(on, self.dailyLine) end
	self.callbackAvailableTaskToggle4 = function(on) self:OnAvailableToggleChanged(on, self.festivalLine) end
	self.callbackAvailableTaskToggle5 = function(on) self:OnAvailableToggleChanged(on, self.otherLine) end
	
	self.Controls.availableMainToggle = self.Controls.AcceptableTaskToggleGroup.transform:Find("MainTask_MainTaskListToggle"..self.mianLine):GetComponent(typeof(Toggle))
	self.Controls.availableBranchToggle = self.Controls.AcceptableTaskToggleGroup.transform:Find("MainTask_MainTaskListToggle"..self.branchLine):GetComponent(typeof(Toggle))
	self.Controls.availableDailyToggle = self.Controls.AcceptableTaskToggleGroup.transform:Find("MainTask_MainTaskListToggle"..self.dailyLine):GetComponent(typeof(Toggle))
	self.Controls.availableFestivalToggle = self.Controls.AcceptableTaskToggleGroup.transform:Find("MainTask_MainTaskListToggle"..self.festivalLine):GetComponent(typeof(Toggle))
	self.Controls.availablOtherToggle = self.Controls.AcceptableTaskToggleGroup.transform:Find("MainTask_MainTaskListToggle"..self.otherLine):GetComponent(typeof(Toggle))
	
	

	self.Controls.availableMainToggle.onValueChanged:AddListener(self.callbackAvailableTaskToggle1)
	self.Controls.availableBranchToggle.onValueChanged:AddListener(self.callbackAvailableTaskToggle2)
	self.Controls.availableDailyToggle.onValueChanged:AddListener(self.callbackAvailableTaskToggle3)
	self.Controls.availableFestivalToggle.onValueChanged:AddListener(self.callbackAvailableTaskToggle4)
	self.Controls.availablOtherToggle.onValueChanged:AddListener(self.callbackAvailableTaskToggle5)
	
	-- 已接任务
	self.callbackAcceptedTaskToggle1 = function(on) self:OnAcceptedToggleChanged(on, self.mianLine) end
	self.callbackAcceptedTaskToggle2 = function(on) self:OnAcceptedToggleChanged(on, self.branchLine) end
	self.callbackAcceptedTaskToggle3 = function(on) self:OnAcceptedToggleChanged(on, self.dailyLine) end
	self.callbackAcceptedTaskToggle4 = function(on) self:OnAcceptedToggleChanged(on, self.festivalLine) end
	self.callbackAcceptedTaskToggle5 = function(on) self:OnAcceptedToggleChanged(on, self.otherLine) end
	
	self.Controls.acceptedMainToggle = self.Controls.AcceptedTaskToggleGroup.transform:Find("MainTask_MainTaskListToggle"..self.mianLine):GetComponent(typeof(Toggle))
	self.Controls.acceptedBranchToggle = self.Controls.AcceptedTaskToggleGroup.transform:Find("MainTask_MainTaskListToggle"..self.branchLine):GetComponent(typeof(Toggle))
	self.Controls.acceptedDailyToggle = self.Controls.AcceptedTaskToggleGroup.transform:Find("MainTask_MainTaskListToggle"..self.dailyLine):GetComponent(typeof(Toggle))
	self.Controls.acceptedFestivalToggle = self.Controls.AcceptedTaskToggleGroup.transform:Find("MainTask_MainTaskListToggle"..self.festivalLine):GetComponent(typeof(Toggle))
	self.Controls.acceptedOtherToggle = self.Controls.AcceptedTaskToggleGroup.transform:Find("MainTask_MainTaskListToggle"..self.otherLine):GetComponent(typeof(Toggle))

	self.Controls.acceptedMainToggle.onValueChanged:AddListener(self.callbackAcceptedTaskToggle1)
	self.Controls.acceptedBranchToggle.onValueChanged:AddListener(self.callbackAcceptedTaskToggle2)
	self.Controls.acceptedDailyToggle.onValueChanged:AddListener(self.callbackAcceptedTaskToggle3)
	self.Controls.acceptedFestivalToggle.onValueChanged:AddListener(self.callbackAcceptedTaskToggle4)
	self.Controls.acceptedOtherToggle.onValueChanged:AddListener(self.callbackAcceptedTaskToggle5)
	
	-- 隐藏所有控件
	for i= 1,5 do
		-- 可接任务
		self.Controls.AcceptableTaskToggleGroup.transform:Find("MainTask_MainTaskList"..i).gameObject:SetActive(false)
		self.Controls.AcceptableTaskToggleGroup.transform:Find("MainTask_MainTaskListToggle"..i).gameObject:SetActive(false)
		self.Controls.AcceptedTaskToggleGroup.transform:Find("MainTask_MainTaskList"..i).gameObject:SetActive(false)
		self.Controls.AcceptedTaskToggleGroup.transform:Find("MainTask_MainTaskListToggle"..i).gameObject:SetActive(false)
	end
	self:InitTaskTitleName()
	return self 
end


-- 先初始化
function TaskListWidget:InitTaskTitleName()
	for i = 1, 5 do
		self.Controls["m_AcceptedText"..i].text = "<color=#4f7e99>"..self.taskTitleName[i].."</color>"
		self.Controls["m_AcceptableText"..i].text = "<color=#4f7e99>"..self.taskTitleName[i].."</color>"
	end
end

function TaskListWidget:OnDestroy()
	

end
-----------------------------------------------------------
-- 先初始化结构表
function TaskListWidget:InitTask(win)
	
end
-----------------------------------------------------------
-- 设置父窗口
function TaskListWidget:SetParentWindow(win)
	self.m_ParentWindow = win
end
-----------------------------------------------------------
-- 已接任务列表
function TaskListWidget:OnAcceptedToggleChanged(on,nIndex)
	
	local pTaskListObject = self.Controls.AcceptedTaskToggleGroup.transform:Find("MainTask_MainTaskList"..nIndex).gameObject
	local pToggleObject = self.Controls.AcceptedTaskToggleGroup.transform:Find("MainTask_MainTaskListToggle"..nIndex).gameObject
	local pPlusObject = pToggleObject.transform:Find("Checkmark_Plus").gameObject
	local pMinusObject = pToggleObject.transform:Find("Checkmark_Minus").gameObject
	if on then
		pTaskListObject:SetActive(true)
		pPlusObject:SetActive(false)
		pMinusObject:SetActive(false)
		self.Controls["m_AcceptedText"..nIndex].text = "<color=#af4131>"..self.taskTitleName[nIndex].."</color>"
		-- 默认选择第一个
		local nObjCount = pTaskListObject.transform.childCount
		if nObjCount >= 1 then
			local listCell = pTaskListObject.transform:GetChild(0)
			local behav = listCell:GetComponent(typeof(UIWindowBehaviour))
			if nil == behav then
				return
			end
			local item = behav.LuaObject
			if item == nil then
				uerror("TaskListWidget:OnAcceptedToggleChanged item为空")
				return
			end
			item:SetToggleState(true)
		end
	else
		pTaskListObject:SetActive(false)
		pPlusObject:SetActive(false)
		pMinusObject:SetActive(false)
		self.Controls["m_AcceptedText"..nIndex].text = "<color=#4f7e99>"..self.taskTitleName[nIndex].."</color>"
	end
end
-----------------------------------------------------------
-- 可接任务列表
function TaskListWidget:OnAvailableToggleChanged(on,nIndex)

	local pTaskListObject = self.Controls.AcceptableTaskToggleGroup.transform:Find("MainTask_MainTaskList"..nIndex).gameObject
	local pToggleObject = self.Controls.AcceptableTaskToggleGroup.transform:Find("MainTask_MainTaskListToggle"..nIndex).gameObject
	local pPlusObject = pToggleObject.transform:Find("Checkmark_Plus").gameObject
	local pMinusObject = pToggleObject.transform:Find("Checkmark_Minus").gameObject
	if on then
		pTaskListObject:SetActive(true)
		pPlusObject:SetActive(false)
		pMinusObject:SetActive(false)
		self.Controls["m_AcceptableText"..nIndex].text = "<color=#af4131>"..self.taskTitleName[nIndex].."</color>"
		-- 默认选择第一个
		local nObjCount = pTaskListObject.transform.childCount
		if nObjCount >= 1 then
			local listCell = pTaskListObject.transform:GetChild(0)
			local behav = listCell:GetComponent(typeof(UIWindowBehaviour))
			if nil == behav then
				return
			end
			local item = behav.LuaObject
			if item == nil then
				uerror("TaskListWidget:OnAvailableToggleChanged item为空")
				return
			end
			item:SetToggleState(true)
		end
	else
		pTaskListObject:SetActive(false)
		pPlusObject:SetActive(false)
		pMinusObject:SetActive(false)
		self.Controls["m_AcceptableText"..nIndex].text = "<color=#4f7e99>"..self.taskTitleName[nIndex].."</color>"
	end
end

-- 显示隐藏可接已接任务
function TaskListWidget:ShowOrHideTaskArea(toggleIndex,bShow)
	
	if toggleIndex == 1 then
		self.Controls.taskAcceptedScrollView.gameObject:SetActive(bShow)
	elseif toggleIndex == 2 then
		self.Controls.taskAvailableScrollView.gameObject:SetActive(bShow)
	end
end

-----------------------------------------------------------
-- 显示已接任务，隐藏可接任务
function TaskListWidget:ShowAcceptedTask()
	self.Controls.taskAcceptedScrollView.gameObject:SetActive(true)
	self.Controls.taskAvailableScrollView.gameObject:SetActive(false)
end

-----------------------------------------------------------
-- 显示可接任务，隐藏已接任务
function TaskListWidget:ShowAvailableTask()
	self.Controls.taskAcceptedScrollView.gameObject:SetActive(false)
	self.Controls.taskAvailableScrollView.gameObject:SetActive(true)
end

-----------------------------------------------------------
-- 显示任务信息
function TaskListWidget:ShowTaskInfo()
	--uerror("TaskListWidget:ShowTaskInfo")
--[[	if self.m_taskType == self.taskAcceptedType then
		self:ShowAcceptedTask()
	elseif self.m_taskType == self.taskAvailableType then
		self:ShowAvailableTask()
	end--]]
end

-----------------------------------------------------------
-- 选择任务类型，已接or可接
function TaskListWidget:SelectTaskType(nTaskType)
	
	if self.m_taskType == nTaskType then
		return
	end
	if nTaskType == UIManager.MainTaskWindow.taskAcceptedType or nTaskType == UIManager.MainTaskWindow.taskAvailableType then
		self.m_taskType = nTaskType
	end
end

-----------------------------------------------------------
-- 更新已接任务列表
function TaskListWidget:RefeshAcceptedTasks()

	-- 回收任务表
	for i = 1,5 do
		local pTaskList = self.Controls.AcceptedTaskToggleGroup.transform:Find("MainTask_MainTaskList"..i)
		if pTaskList and pTaskList.transform  then
			nCount = pTaskList.transform.childCount
			if nCount >= 1 then
				local tmpTable = {}
				for i = 1, nCount, 1 do
					table.insert(tmpTable,pTaskList.transform:GetChild(i-1).gameObject)
				end
				for i, v in pairs(tmpTable) do
					rkt.GResources.RecycleGameObject(v)
				end
			end
			self.Controls.AcceptedTaskToggleGroup.transform:Find("MainTask_MainTaskList"..i).gameObject:SetActive(false)
			self.Controls.AcceptedTaskToggleGroup.transform:Find("MainTask_MainTaskListToggle"..i).gameObject:SetActive(false)
		end
		
	end
	
	self.m_taskType = UIManager.MainTaskWindow.taskAcceptedType
	self:ShowTaskInfo()	
	-- 是否有可接任务
	local pAeecptedList = IGame.TaskSick:GetAcceptedTaskList()
	if not pAeecptedList then
		return
	end
	local bShow = false
	for i, v in pairs(pAeecptedList) do
		
		local taskType = v.tasktype
		if not self.Controls.AcceptedTaskToggleGroup.transform:Find("MainTask_MainTaskList"..taskType) then
			uerror("MainTask_MainTaskList"..taskType.." can not found!")
			return
		end
		local pToggleGroup = self.Controls.AcceptedTaskToggleGroup.transform:Find("MainTask_MainTaskList"..taskType).transform:GetComponent(typeof(ToggleGroup))
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.MainTaskListElementCell ,
		function ( path , obj , ud )
    		if nil == self.Controls.AcceptedTaskToggleGroup.transform:Find("MainTask_MainTaskList"..taskType).gameObject then   -- 判断U3D对象是否已经被销毁
    			rkt.GResources.RecycleGameObject(obj)
    			return
    		end
    		obj.transform:SetParent(self.Controls.AcceptedTaskToggleGroup.transform:Find("MainTask_MainTaskList"..taskType),false)
    		local itemtask = TaskElementToggleCellClass:new({})
    		itemtask:Attach(obj)
    		itemtask:SetToggleGroup( pToggleGroup )
    		itemtask:SetItemInfo(v,self.m_taskType, i)
		end , i , AssetLoadPriority.GuiNormal )
		if bShow == false then
			self.Controls.AcceptedTaskToggleGroup.transform:Find("MainTask_MainTaskList"..taskType).gameObject:SetActive(true)
			self:ShowCurTaskDescription(v,self.m_taskType)
			self:OnAcceptedToggleChanged(true,taskType)
			bShow = true
		end
		self.Controls.AcceptedTaskToggleGroup.transform:Find("MainTask_MainTaskListToggle"..taskType).gameObject:SetActive(true)
	end
	
	if bShow == false then
		self:ShowCurTaskDescription()
	end
	
end

-----------------------------------------------------------
-- 更新可接任务列表
function TaskListWidget:RefeshAvailableTasks()
	-- 回收任务表
	for i = 1,5 do
		local pTaskList = self.Controls.AcceptableTaskToggleGroup.transform:Find("MainTask_MainTaskList"..i)
		if pTaskList and pTaskList.transform  then
			nCount = pTaskList.transform.childCount
			if nCount >= 1 then
				local tmpTable = {}
				for i = 1, nCount, 1 do
					table.insert(tmpTable,pTaskList.transform:GetChild(i-1).gameObject)
				end
				for i, v in pairs(tmpTable) do
					rkt.GResources.RecycleGameObject(v)
				end
			end
			self.Controls.AcceptableTaskToggleGroup.transform:Find("MainTask_MainTaskList"..i).gameObject:SetActive(false)
			self.Controls.AcceptableTaskToggleGroup.transform:Find("MainTask_MainTaskListToggle"..i).gameObject:SetActive(false)
		end
	end
	
	self.m_taskType = UIManager.MainTaskWindow.taskAvailableType
	
	local bShow = false
	-- 是否有可接任务
	local pAvailableList = IGame.TaskSick:GetAvailableTaskList()
	if not pAvailableList then
		return
	end
	
	for i, v in pairs(pAvailableList) do
		
		local taskType = v.tasktype
		if not self.Controls.AcceptableTaskToggleGroup.transform:Find("MainTask_MainTaskList"..taskType) then
			uerror("MainTask_MainTaskList"..taskType.." can not found!")
			return
		end
		local pToggleGroup = self.Controls.AcceptableTaskToggleGroup.transform:Find("MainTask_MainTaskList"..taskType).transform:GetComponent(typeof(ToggleGroup))
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.MainTaskListElementCell ,
		function ( path , obj , ud )
			if nil == self.Controls.AcceptableTaskToggleGroup.transform:Find("MainTask_MainTaskList"..taskType).gameObject then   -- 判断U3D对象是否已经被销毁
				rkt.GResources.RecycleGameObject(obj)
				return
			end
			obj.transform:SetParent(self.Controls.AcceptableTaskToggleGroup.transform:Find("MainTask_MainTaskList"..taskType),false)
			local itemtask = TaskElementToggleCellClass:new({})
			itemtask:Attach(obj)
			itemtask:SetToggleGroup( pToggleGroup )
			itemtask:SetItemInfo(v,self.m_taskType,i)
		end , i , AssetLoadPriority.GuiNormal )
		if bShow == false then
			self.Controls.AcceptableTaskToggleGroup.transform:Find("MainTask_MainTaskList"..taskType).gameObject:SetActive(true)
			self:ShowCurTaskDescription(v,self.m_taskType)
			self:OnAvailableToggleChanged(true,taskType)
			bShow = true
		end
		self.Controls.AcceptableTaskToggleGroup.transform:Find("MainTask_MainTaskListToggle"..taskType).gameObject:SetActive(true)
	end
	if bShow == false then
		self:ShowCurTaskDescription()
	end
end
-----------------------------------------------------------
-- 描述界面显示当前列表
function TaskListWidget:ShowCurTaskDescription(taskInfo,nTaskType)
	self.m_ParentWindow:ShowCurTaskDescription(taskInfo,nTaskType)
end

------------------------------------------------------------

return this