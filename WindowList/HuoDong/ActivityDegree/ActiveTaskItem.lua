--/******************************************************************
---** 文件名:	HuoDongWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-03-17
--** 版  本:	1.0
--** 描  述:	活跃度任务列表
--** 应  用:  
--******************************************************************/

local ActiveTaskItem = UIControl:new
{
	windowName = "ActiveTaskItem",
	huodong_id = 0,
	m_callback = nil,
}

local tPlayerStatus = 
{
	[HUODONG_PLAYERSTATUS.COMPLETE] = {false, false, true},
}

local tSystemStatus = 
{
	[ACT_STATE.PRE_START] = {false, true, false},
	[ACT_STATE.STARTED] = {true, false, false},
	[ACT_STATE.ENDED] = {true, false, false},
}

function ActiveTaskItem:Attach(obj)
	UIControl.Attach(self,obj)	
	
	self.callback_OnButtonClick = function() self:OnButtonClick() end
	self.Controls.m_Join.onClick:AddListener(self.callback_OnButtonClick)
	
	self.m_SelectCallback = function(on) self:OnValueChanged(on) end
	self.m_ItemToggle = self.transform:GetComponent(typeof(Toggle))
	self.m_ItemToggle.onValueChanged:AddListener(self.m_SelectCallback)
	
	return self
end

function ActiveTaskItem:OnButtonClick()
			
	if UIManager.HuoDongWindow:isShow() then
		UIManager.HuoDongWindow:Hide()
	end
	
	IGame.ActivityManager:ExecEntryFunc(self.huodong_id)
end

function ActiveTaskItem:SetToggleGroup(tlgGroup)
    self.m_ItemToggle.group = tlgGroup
end

function ActiveTaskItem:SetSelectCallback(func_CB)
	self.m_callback = func_CB
end

function ActiveTaskItem:SetCtrlStatus(tHuoDong)
	local nPlayerStatus = tHuoDong:GetActiveStatus()
	local tStatus = tPlayerStatus[nPlayerStatus]
	
	if not tStatus then
		local nSystemStatus = tHuoDong:GetSystemStatus()
		tStatus = tSystemStatus[nSystemStatus]
	end
	
	if not tStatus then
		return
	end	
				
	local controls = self.Controls
	controls.m_Join.gameObject:SetActive(tStatus[1])
	controls.m_StartTime.gameObject:SetActive(tStatus[2])	
	controls.m_Finish.gameObject:SetActive(tStatus[3])
end

function ActiveTaskItem:SetPreStart(tHuoDong)
	
	local nTimeID = tHuoDong:GetTimeID()
	if nTimeID == 0 then
		return
	end
	
	local tTimeCfg = IGame.rktScheme:GetSchemeInfo(ACTIVITYTIME_CSV, nTimeID)
	if not tTimeCfg then
		return
	end
	
	self.Controls.m_StartTime.text = tostring(tTimeCfg.StartTime)	
end

function ActiveTaskItem:SetStatusProc(tHuoDong)
	local tProcFunc = 
	{
		[ACT_STATE.PRE_START] = handler(self, self.SetPreStart),
	}
	
	local nStatus = tHuoDong:GetSystemStatus()
	if not tProcFunc[nStatus] then
		return
	end
	
	tProcFunc[nStatus](tHuoDong)
end

function ActiveTaskItem:SetStatusImage(tHuoDong)
	self:SetCtrlStatus(tHuoDong)
	self:SetStatusProc(tHuoDong)
end

function ActiveTaskItem:SetItemCellInfo(huodong, bFocus)	
	local id = huodong:GetActID()
	self.huodong_id = id
	
	--获取界面配置
	local ActInfo = IGame.rktScheme:GetSchemeInfo(ACTIVITYWINDOW_CSV, id)
	if nil == ActInfo then
		print("找不到界面信息配置！ ActID: "..id)
		return nil
	end
	
	local nActiveTimes = huodong:GetActiveTimes()
    local nMaxTimes    = huodong:GetMaxActiveTimes()
	
	local controls = self.Controls
	controls.m_ActiveDesc.text = tostring(huodong:GetName())
	controls.m_ActiveValue.text = tostring(huodong:GetActiveValue())
	local str = tostring(nActiveTimes).."/"..tostring(nMaxTimes)
	controls.m_CurTimes.text = tostring(str)

	--设置活动Icond
	UIFunction.SetImageSprite(controls.m_Icon, AssetPath.TextureGUIPath..ActInfo.IconID)
	
	self:SetStatusImage(huodong)
	self.m_ItemToggle.isOn = bFocus
end

function ActiveTaskItem:OnValueChanged(on)
	if self.m_callback then
		self.m_callback(self.huodong_id, on)
	end
end

function ActiveTaskItem:OnRecycle()
	
	self.Controls.m_Join.onClick:RemoveListener(self.callback_OnButtonClick)
	self.m_ItemToggle.onValueChanged:RemoveListener(self.m_SelectCallback)
	self.huodong_id = 0
	
	self.m_ItemToggle.group = nil
	self.m_ItemToggle.isOn = false
	self.callback_OnButtonClick = nil
end

function ActiveTaskItem:OnDestroy()
	UIControl.OnDestroy(self)
end

return ActiveTaskItem