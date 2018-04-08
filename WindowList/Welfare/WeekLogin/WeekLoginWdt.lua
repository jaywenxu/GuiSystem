--******************************************************************
--** 文件名:	WeekLoginWdt.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-06-01
--** 版  本:	1.0
--** 描  述:	七天登录礼包
--** 应  用:  
--******************************************************************

local WeekLoginRewardClass = require("GuiSystem.WindowList.Welfare.WeekLogin.WeekLoginReward")

local WeekLoginWdt = UIControl:new
{
	windowName = "WeekLoginWdt",
}

function WeekLoginWdt:Attach(obj)
	UIControl.Attach(self, obj)
    
    self:CreateTimer()
    
    self:InitRewardCtrl()
    
end

function WeekLoginWdt:CreateTimer()
    self.m_CDTimerCallBack = handler(self, self.CountDownTimer)
    rktTimer.SetTimer(self.m_CDTimerCallBack, 1000, -1, "week login")
end

function WeekLoginWdt:DestroyTimer()
    if self.m_CDTimerCallBack then
		rktTimer.KillTimer(self.m_CDTimerCallBack)
		self.m_CDTimerCallBack = nil
	end
end

function WeekLoginWdt:SubControlExecute()
	self.m_OnListUpdate = handler(self, self.OnListUpdate)
	rktEventEngine.SubscribeExecute(EVENT_WEEK_LOGIN_LIST_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.m_OnListUpdate)
end

function WeekLoginWdt:UnSubControlExecute()
	rktEventEngine.UnSubscribeExecute( EVENT_WEEK_LOGIN_LIST_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.m_OnListUpdate)
	self.m_OnListUpdate = nil
end

function WeekLoginWdt:InitRewardCtrl()
    local controls = self.Controls
    local tReward = 
    {
        controls.m_Reward1,
        controls.m_Reward2,
        controls.m_Reward3,
        controls.m_Reward4,
        controls.m_Reward5,
        controls.m_Reward6,
        controls.m_Reward7,
    }
    
    for i = 1, #tReward do
		local item = WeekLoginRewardClass:new({})
		item:Attach(tReward[i].gameObject)
        item:SetItemInfo(i)
	end
end

function WeekLoginWdt:CountDownTimer()
    -- 刷新倒计时
    
end

function WeekLoginWdt:SetRewardInfo(i, tCell)
    local behav = tCell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
    
	local item = behav.LuaObject
	if not item then
		uerror("WeekLoginWdt:SetRewardInfo item为空")
		return
	end
	
	item:SetItemInfo(i)
end

function WeekLoginWdt:OnListUpdate()
    local controls = self.Controls
    local tReward = 
    {
        controls.m_Reward1,
        controls.m_Reward2,
        controls.m_Reward3,
        controls.m_Reward4,
        controls.m_Reward5,
        controls.m_Reward6,
        controls.m_Reward7,
    }
    
    for i = 1, #tReward do
        self:SetRewardInfo(i, tReward[i])
	end
end

function WeekLoginWdt:OnDestroy()
    
    self:DestroyTimer()
    
    UIControl.Destroy(self)
end

return WeekLoginWdt