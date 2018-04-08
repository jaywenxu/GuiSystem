
--/******************************************************************
---** 文件名:	XianShiCell.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-10-24
--** 版  本:	1.0
--** 描  述:	限时活动元素
--** 应  用:  
--******************************************************************/

local nHuoGongID  = 15
local nGaoChangID = 24

local tNormalTxtColor   = Color.New(0, 0.7, 0)
local tStartedTxtColor  = Color.New(1, 0.48, 0)

------------------------------------------------------------
local XianShiCell = UIControl:new
{
	windowName = "XianShiCell",
	huodong_id = 0, 
	selected_callback = nil,
}

------------------------------------------------------------
function XianShiCell:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.callback_OnButtonClick = function() self:OnButtonClick() end
	self.Controls.m_Join.onClick:AddListener(self.callback_OnButtonClick)
	self.callback_OnSelectChanged = function(on) self:OnSelectChanged(on) end
	
    self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))
    self.Controls.ItemToggle.onValueChanged:AddListener(self.callback_OnSelectChanged)

	return self
end

function XianShiCell:OnButtonClick()
		
	if UIManager.HuoDongWindow:isShow() then
		UIManager.HuoDongWindow:Hide()
	end
	
	IGame.ActivityManager:ExecEntryFunc(self.huodong_id)
end

function XianShiCell:GetPreStartCtrl()
	return {true, true, false, false}
end

function XianShiCell:GetStartCtrl()
	return {true, true, false, false}
end

function XianShiCell:GetEndCtrl(tHuoDong)
	local nMaxTimes = tHuoDong:GetMaxTimes()
	if nMaxTimes == -1 then
		return {false, true, true, false}
	else
		return {false, false, true, true}
	end
end

function XianShiCell:GetFinishCtrl(tHuoDong)
	return {false, false, true, true}
end

function XianShiCell:SetCtrlStatus(tHuoDong)	

	local tPlayerStatus = 
	{
		[HUODONG_PLAYERSTATUS.COMPLETE] = handler(self, self.GetFinishCtrl),
	}

	local tSystemStatus = 
	{
		[ACT_STATE.PRE_START] = handler(self, self.GetPreStartCtrl),
		[ACT_STATE.STARTED] = handler(self, self.GetStartCtrl),
		[ACT_STATE.ENDED] = handler(self, self.GetEndCtrl),
	}	
	local nPlayerStatus = tHuoDong:GetPlayerStatus()
	local rProcFunc = tPlayerStatus[nPlayerStatus]
	
	if not rProcFunc then
		local nSystemStatus = tHuoDong:GetSystemStatus()
		rProcFunc = tSystemStatus[nSystemStatus]
	end
	
	if not rProcFunc then
		return
	end
	
	local tStatus = rProcFunc(tHuoDong)
	
	local controls = self.Controls
	controls.m_Join.gameObject:SetActive(tStatus[1])
	controls.m_StartTime.gameObject:SetActive(tStatus[2])
	controls.m_StatusTxt.gameObject:SetActive(tStatus[3])
	controls.m_Times.gameObject:SetActive(tStatus[4])
end

function XianShiCell:SetJoinBtnEnable(bEnable)	
	self.clickEnable = bEnable
	local controls = self.Controls
	local callback = function()
		UIFunction.SetComsAndChildrenGray(controls.m_Join , not bEnable)
		UIFunction.SetButtonClickState(controls.m_Join, bEnable)
	end
	
	UIFunction.SetComsAndChildrenGray(controls.m_Join , not bEnable, callback)
end

function XianShiCell:SetTimeInfo(nTimeID)
	if 0 == nTimeID then
		return
	end
	
	local TimeInfo = IGame.rktScheme:GetSchemeInfo(ACTIVITYTIME_CSV, nTimeID)
	if not TimeInfo then
		return
	end
	
	local controls = self.Controls
	local tStartTime = split_string(TimeInfo.StartTime,":",tostring)
	local tEndTime = split_string(TimeInfo.EndTime,":",tostring)
	
	local str = tStartTime[1]..":"..tStartTime[2].."-"..tEndTime[1]..":"..tEndTime[2]
	controls.m_StartTime.text = tostring(str)
	controls.m_StartTime.color = tNormalTxtColor
end

function XianShiCell:SetPreStartTime(nTimeID)
	if 0 == nTimeID then
		return
	end
	
	local TimeInfo = IGame.rktScheme:GetSchemeInfo(ACTIVITYTIME_CSV, nTimeID)
	if not TimeInfo then
		return
	end
	
	local controls = self.Controls
	local tStartTime = split_string(TimeInfo.PreStartTime,":",tostring)
	local tEndTime = split_string(TimeInfo.StartTime,":",tostring)
	
	local str = tStartTime[1]..":"..tStartTime[2].."-"..tEndTime[1]..":"..tEndTime[2]
	controls.m_StartTime.text = tostring(str)
	controls.m_StartTime.color = tNormalTxtColor
end

function XianShiCell:SetPreStart(tHuoDong)
	if not tHuoDong then
		return
	end
	
	local nHuoDongID = tHuoDong:GetActID()
	local nTimeID = tHuoDong:GetTimeID()
	
	if nHuoDongID == nHuoGongID then
		self:SetPreStartTime(nTimeID)
	elseif nHuoDongID == nGaoChangID then
		self:SetPreStartTime(nTimeID)
	else
		self:SetTimeInfo(nTimeID)
	end
	
	self:SetJoinBtnEnable(false)
end

function XianShiCell:SetStarted()
	
    local controls = self.Controls
    controls.m_StartTime.text = tostring("进行中")
	controls.m_StartTime.color = tStartedTxtColor
	--恢复按钮
	self:SetJoinBtnEnable(true)
end

function XianShiCell:SetFinished()
	
	self.Controls.m_StatusTxt.text = tostring("已完成")	
end

function XianShiCell:SetEnded(tHuoDong)
	
	self.Controls.m_StatusTxt.text = tostring("已结束")	
	
	--TODO: 有次数显示次数
	local nMaxTimes = tHuoDong:GetMaxTimes()
	
	--TODO: 无次数显示时间
	if nMaxTimes == -1 then
		local nHuoDongID = tHuoDong:GetActID()
		local nTimeID = tHuoDong:GetTimeID()
		if nHuoDongID == nHuoGongID then
			self:SetPreStartTime(nTimeID)
		elseif nHuoDongID == nGaoChangID then
			self:SetPreStartTime(nTimeID)
		else
			self:SetTimeInfo(nTimeID)
		end
	end
end

function XianShiCell:SetStatusProc(tHuoDong)
	local nStatus = tHuoDong.status
	local tPlayerStatusFunc = 
	{
		[HUODONG_PLAYERSTATUS.COMPLETE] = handler(self, self.SetFinished),
	}
	local tSystemStatusFunc = 
	{
		[ACT_STATE.ENDED] = handler(self, self.SetEnded),
		[ACT_STATE.STARTED] = handler(self, self.SetStarted),
		[ACT_STATE.PRE_START] = handler(self, self.SetPreStart),
	}
	
	local nPlayerStatus = tHuoDong:GetPlayerStatus()
	local tProcFunc = tPlayerStatusFunc[nPlayerStatus]
	
	if not tProcFunc then
		local nSystemStatus = tHuoDong:GetSystemStatus()
		tProcFunc = tSystemStatusFunc[nSystemStatus]
	end
	
	if not tProcFunc then
		return
	end
	
	tProcFunc(tHuoDong)
end

function XianShiCell:SetStatus(tHuoDong)	
	self:SetCtrlStatus(tHuoDong)
	self:SetStatusProc(tHuoDong)
end

function XianShiCell:SetTimesInfo(tHuoDong)
	
	local str = ""
    local nJoinTimes = tHuoDong:GetCurTimes()
    local nMaxTimes  = tHuoDong:GetMaxTimes()

	if -1 == nMaxTimes then
		str = ""
	else
		str = "次数: "..tostring(nJoinTimes).."/"..tostring(nMaxTimes)
	end
	
	self.Controls.m_Times.text = tostring(str)
end

function XianShiCell:SetItemCellInfo(obj_huodong, bFocus)	
	
	--设置活动ID
	self.huodong_id = obj_huodong:GetActID()
	
	--获取界面配置
	local ActInfo = IGame.rktScheme:GetSchemeInfo(ACTIVITYWINDOW_CSV, self.huodong_id)
	if not ActInfo then
		print("找不到界面信息配置！ ActID: ", self.huodong_id)
		return
	end
	
	--设置活动名称
	self.Controls.m_Name.text = tostring(obj_huodong:GetName())
	
	--设置Icon
	UIFunction.SetImageSprite(self.Controls.m_Icon, AssetPath.TextureGUIPath..ActInfo.IconID)
		
	--设置推荐标识	
	self.Controls.m_IsRecommend.gameObject:SetActive(obj_huodong:IsRecommend())
		
	--设置组队标识
	UIFunction.SetImageSprite(self.Controls.m_TeamType, HuoDongTypePath[obj_huodong.join_type])
	
	--设置状态标识
	self:SetStatus(obj_huodong)
	
	--设置活动次数
	self:SetTimesInfo(obj_huodong)

	self.Controls.ItemToggle.isOn = bFocus
end

function XianShiCell:SetSelectCallback( func_cb )
	self.selected_calback = func_cb
end

function XianShiCell:OnDestroy()
	self.selected_calback = nil
	UIControl.OnDestroy(self)
end

function XianShiCell:OnRecycle()
	
	self.Controls.ItemToggle.onValueChanged:RemoveListener(self.callback_OnSelectChanged)
	self.Controls.m_Join.onClick:RemoveListener(self.callback_OnButtonClick)
		
	self.selected_calback = nil
	
	UIControl.OnRecycle(self)
end

function XianShiCell:SetToggleGroup(toggleGroup)
    self.Controls.ItemToggle.group = toggleGroup
end

function XianShiCell:OnSelectChanged(on)
	if not on then
		return
	end
	
	IGame.ActivityList:SetFocusID(self.huodong_id)
	if nil ~= self.selected_calback then
		self.selected_calback(self.huodong_id)
	end
end

return XianShiCell



