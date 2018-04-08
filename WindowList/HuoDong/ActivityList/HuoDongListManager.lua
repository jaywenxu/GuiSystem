--/******************************************************************
---** 文件名:	HuoDongWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-03-16
--** 版  本:	1.0
--** 描  述:	活动列表模块
--** 应  用:  
--******************************************************************/

local ActivityManagerWdt = UIControl:new
{
	windowName	= "ActivityManagerWdt",
}

function ActivityManagerWdt:Attach( obj )
	UIControl.Attach(self, obj)
	
	self:InitSubWdts()
	
	self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))
			
	self.Controls.m_CalenderBtn.onClick:AddListener(handler(self, self.OnCalenderBtnClick))
	
	self.Controls.m_PushSettingBtn.onClick:AddListener(handler(self, self.OnPushBtnClick))

	self:SetListFocus(1)
	
	return self
end

function ActivityManagerWdt:InitSubWdts()
	
	local ToggleGroup = self.transform.gameObject:GetComponent(typeof(ToggleGroup))
	local CellSelectedChanged = function(ID) self:ItemSelectChanged(ID) end
	
	local SettingData = 
	{
		TglGroup = ToggleGroup,
		ItemSelectedCallBack = CellSelectedChanged,
	}
	
	-- 限时列表管理
	self.m_TimeLimitList = require( "GuiSystem.WindowList.HuoDong.ActivityList.HuoDongLimitListWidget")
	self.m_TimeLimitList:Attach(self.Controls.m_TimeLimitList.gameObject, ToggleGroup, CellSelectedChanged)
	
	-- 全天列表
	self.m_AllDayList = require( "GuiSystem.WindowList.HuoDong.ActivityList.HuoDongListWidget")
	self.m_AllDayList:SetParentData(SettingData)
	self.m_AllDayList:Attach(self.Controls.m_AllDayList.gameObject)
	
	-- 活动描述
	self.m_RewardDesc = require("GuiSystem.WindowList.HuoDong.ActivityList.HuoDongDescWidget")
	self.m_RewardDesc:Attach(self.Controls.m_RewardDesc.gameObject)
	
end

function ActivityManagerWdt:OnEnable()
	self:SetListFocus(1)
	self.m_AllDayList:ReloadData()
end

function ActivityManagerWdt:ItemSelectChanged(UniqueID)
	
	self.m_RewardDesc:SetActDesc(UniqueID)
end

function ActivityManagerWdt:OnCalenderBtnClick()
	UIManager.HuoDongCalenderWindow:Show()
end

function ActivityManagerWdt:OnPushBtnClick()
	UIManager.HuoDongPushWindow:Show()
end

function ActivityManagerWdt:ReloadActivityList()
	self.m_AllDayList:ReloadData()
	self.m_TimeLimitList:ReloadData()
end

function ActivityManagerWdt:SetListFocus(idx)
	
	local HuoDong = IGame.ActivityList:GetAllDayManager():GetElement(idx)
	if nil == HuoDong then
		return 
	end
	
	local ID = HuoDong:GetActID()
	IGame.ActivityList:SetFocusID(ID)
	self.m_RewardDesc:SetActDesc(ID)
end

function ActivityManagerWdt:OnDestroy()
        
	UIControl.OnDestroy(self)
end

return ActivityManagerWdt



