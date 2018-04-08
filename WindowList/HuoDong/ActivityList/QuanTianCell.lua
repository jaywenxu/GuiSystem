--/******************************************************************
---** 文件名:	HuoDongWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-02-28
--** 版  本:	1.0
--** 描  述:	活动窗口
--** 应  用:  
--******************************************************************/

local FUMOTOU_GOODS_ID  = 2028
local CANBAOTU_GOODS_ID = 2029

------------------------------------------------------------
local QuanTianCell = UIControl:new
{
	windowName = "QuanTianCell",
	huodong_id = 0, 
	selected_callback = nil,
}

local tPlayerStatus = 
{
	[HUODONG_PLAYERSTATUS.COMPLETE] = {false, true}
}

local tSystemStatus = 
{
	[ACT_STATE.PRE_START] = {false,true},
	[ACT_STATE.STARTED] = {true,false},
	[ACT_STATE.ENDED] = {true,false},
}

------------------------------------------------------------
function QuanTianCell:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.callback_OnButtonClick = function() self:OnButtonClick() end
	self.Controls.m_Join.onClick:AddListener(self.callback_OnButtonClick)
	self.callback_OnSelectChanged = function(on) self:OnSelectChanged(on) end
	
    self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))
    self.Controls.ItemToggle.onValueChanged:AddListener(self.callback_OnSelectChanged)

	return self
end

function QuanTianCell:OnButtonClick()
		
	if UIManager.HuoDongWindow:isShow() then
		UIManager.HuoDongWindow:Hide()
	end
	
	IGame.ActivityManager:ExecEntryFunc(self.huodong_id)
end

function QuanTianCell:SetCtrlStatus(tHuoDong)	
		
	local nPlayerStatus = tHuoDong:GetPlayerStatus()
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
	controls.m_StatusTxt.gameObject:SetActive(tStatus[2])
end

function QuanTianCell:SetTimeInfo(nTimeID)
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
	controls.m_StatusTxt.text = tostring(str)

end

function QuanTianCell:SetPreStart(tHuoDong)
	
	local nTimeID = tHuoDong:GetTimeID()
	self:SetTimeInfo(nTimeID)
	
end

function QuanTianCell:SetStarted()
	
end

function QuanTianCell:SetFinished()
	self.Controls.m_StatusTxt.text = tostring("已完成")	
end

function QuanTianCell:SetStatusProc(tHuoDong)	
	local tPlayerStatusFunc = 
	{
		[HUODONG_PLAYERSTATUS.COMPLETE] = handler(self, self.SetFinished),
	}

	local tSystemStatusFunc = 
	{
		[ACT_STATE.PRE_START] = handler(self, self.SetPreStart),
		[ACT_STATE.STARTED] =  handler(self, self.SetStarted),
		[ACT_STATE.ENDED] =  handler(self, self.SetStarted),
	}
	
	local nPlayerStatus = tHuoDong:GetPlayerStatus()
	local tStatus = tPlayerStatusFunc[nPlayerStatus]
	
	if not tStatus then
		local nSystemStatus = tHuoDong:GetSystemStatus()
		tStatus = tSystemStatusFunc[nSystemStatus]
	end
	
	if not tStatus then
		return
	end
	
	tStatus(tHuoDong)
end

function QuanTianCell:SetStatusImage(tHuoDong)	
	
	self:SetCtrlStatus(tHuoDong)
	self:SetStatusProc(tHuoDong)
end

function QuanTianCell:SetCanBaoTuTimes()
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	local ownNum = packetPart:GetGoodNum(CANBAOTU_GOODS_ID)
	
	self.Controls.m_Times.text = tostring("拥有: "..tostring(ownNum))
end

function QuanTianCell:SetFuMoTouTimes()
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	local ownNum = packetPart:GetGoodNum(FUMOTOU_GOODS_ID)
	
	self.Controls.m_Times.text = tostring("拥有: "..tostring(ownNum))
end

function QuanTianCell:SetChuangGongTimes(tHuoDong)
	
	local nCurTimes = tHuoDong:GetCurTimes()
	local nTimes1 = math.floor(nCurTimes/HUODONG_TIMES_OFFSET)
	local nTimes2 = nCurTimes - nTimes1 * HUODONG_TIMES_OFFSET
	
	local nMaxTimes1 = math.floor(tHuoDong.nMaxTimes/HUODONG_TIMES_OFFSET)
	local nMaxTimes2 = math.fmod(tHuoDong.nMaxTimes, HUODONG_TIMES_OFFSET)
	
	local str = "传功: "..nTimes1.."/"..nMaxTimes1.."\n被传: "..nTimes2.."/"..nMaxTimes2
	self.Controls.m_Times.text = tostring(str)
end

function QuanTianCell:SetDefaultTimes(tHuoDong)
	local str = ""
    local nJoinTimes = tHuoDong:GetCurTimes()
    local nMaxTimes  = tHuoDong:GetMaxTimes()
	if tHuoDong.nMaxTimes ~= -1 then
		str = "次数: "..tostring(nJoinTimes).."/"..tostring(nMaxTimes)
	end
	
	self.Controls.m_Times.text = tostring(str)	
end

function QuanTianCell:SetTimesInfo(tHuoDong)
	
	local tProcFunc = 
	{
		[6] = handler(self, self.SetCanBaoTuTimes),  --藏宝图活动
		[21] = handler(self, self.SetFuMoTouTimes), --伏魔骰活动
		[26] = handler(self, self.SetChuangGongTimes), --帮会传功
	}
	
	local nHuoDongID = tHuoDong:GetActID()
	if not tProcFunc[nHuoDongID] then
		self:SetDefaultTimes(tHuoDong)
	else
		tProcFunc[nHuoDongID](tHuoDong)
	end
end

function QuanTianCell:SetItemCellInfo(tHuoDong, bFocus)	
	--设置活动ID
	self.huodong_id = tHuoDong:GetActID()
	
	--获取界面配置
	local ActInfo = IGame.rktScheme:GetSchemeInfo(ACTIVITYWINDOW_CSV, self.huodong_id)
	if not ActInfo then
		print("找不到界面信息配置！ ActID: "..self.huodong_id)
		return
	end
	
	--设置活动名称
	self.Controls.m_Name.text = tostring(tHuoDong:GetName())
	
	--设置Icon
	UIFunction.SetImageSprite(self.Controls.m_Icon, AssetPath.TextureGUIPath..ActInfo.IconID)
		
	--设置推荐标识
	self.Controls.m_IsRecommend.gameObject:SetActive(tHuoDong:IsRecommend())
	
	--设置组队标识
	UIFunction.SetImageSprite(self.Controls.m_TeamType, HuoDongTypePath[tHuoDong.join_type])
	
	--设置状态标识
	self:SetStatusImage(tHuoDong)
	
	--设置活动次数
	self:SetTimesInfo(tHuoDong)
	
	self.Controls.ItemToggle.isOn = bFocus
end

function QuanTianCell:SetSelectCallback( func_cb )
	self.selected_calback = func_cb
end

function QuanTianCell:OnDestroy()
	self.selected_calback = nil
	UIControl.OnDestroy(self)
end

function QuanTianCell:OnRecycle()
	
	self.Controls.ItemToggle.onValueChanged:RemoveListener(self.callback_OnSelectChanged)
	self.Controls.m_Join.onClick:RemoveListener(self.callback_OnButtonClick)
	
	self.Controls.ItemToggle.group = nil
	self.Controls.ItemToggle.isOn  = false
	self.selected_calback = nil
	
	UIControl.OnRecycle(self)
end

function QuanTianCell:SetToggleGroup(toggleGroup)
    self.Controls.ItemToggle.group = toggleGroup
end

function QuanTianCell:OnSelectChanged(on)
	--设置聚焦图片
	if not on then
		return
	end
	
	IGame.ActivityList:SetFocusID(self.huodong_id)
	if nil ~= self.selected_calback then
		self.selected_calback(self.huodong_id)
	end
end

return QuanTianCell



