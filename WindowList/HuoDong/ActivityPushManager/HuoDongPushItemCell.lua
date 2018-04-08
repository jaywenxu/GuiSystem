--/******************************************************************
---** 文件名:	HuoDongWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-02-28
--** 版  本:	1.0
--** 描  述:	活动窗口
--** 应  用:  
--******************************************************************/

local tNormalTxtColor = Color.New(0.32, 0.48, 0.6)
local tFocusTxtColor  = Color.New(0.8,0.48, 0.26)

local HuoDongPushItemCell = UIControl:new
{
	windowName = "HuoDongPushItemCell",
	m_SelectFunc = nil,
	m_nCurHuoDongID = 0,
	m_nCurTimeID = 0,
}

function HuoDongPushItemCell:Attach(obj)
	UIControl.Attach(self, obj)
	
	self.callbackSwitch = function(on) self:OnSwitchChanged(on) end
	self.Controls.m_PushSwitch.onValueChanged:AddListener(self.callbackSwitch)
	
	self.m_SelectCallback = function(on) self:OnSelectChanged(on) end
	self.m_ItemToggle = self.transform:GetComponent(typeof(Toggle))
	self.m_ItemToggle.onValueChanged:AddListener(self.m_SelectCallback)

	return self
end

function HuoDongPushItemCell:SetToggleGroup(tGroup)
	self.m_ItemToggle.group = tGroup
end

function HuoDongPushItemCell:SetSelectCallback(func_cb)
	self.m_SelectFunc = func_cb
end

function HuoDongPushItemCell:SetItemCellInfo(obj, bFocus)
	
	self.Controls.m_Name.text = tostring(obj:GetName())

	--设置活动时间
	self.m_nCurHuoDongID = obj:GetActID()
	self.m_nCurTimeID = obj:GetTimeID()
	local TimeCfg = IGame.rktScheme:GetSchemeInfo(ACTIVITYTIME_CSV, self.m_nCurTimeID)
	if not TimeCfg then
		print("找不到时间信息配置！ TimeID: ", self.m_nCurTimeID)
		return false
	end		
	
	local StartTime = split_string(TimeCfg.StartTime,":",tostring)
	local EndTime   = split_string(TimeCfg.EndTime,":",tostring)
	local TimeInfo = StartTime[1]..":"..StartTime[2].."-"..EndTime[1]..":"..EndTime[2]
	self.Controls.m_Time.text = tostring(TimeInfo)
	
	--设置活动周期
	if obj.is_timelimit then
		self.Controls.m_Type.text = tostring("限时")	
	else
		self.Controls.m_Type.text = tostring("全天")	
	end	
	
	--设置活动人数
	self.Controls.m_Team.text = tostring(obj.join_type)	
	
	--设置聚焦
	self.m_ItemToggle.isOn = bFocus
end

function HuoDongPushItemCell:OnSwitchChanged(on)

	self.Controls.m_SwitchON.gameObject:SetActive(on)
	self.Controls.m_SwitchOFF.gameObject:SetActive(not on)
end

function HuoDongPushItemCell:OnSelectChanged(on)
		
	local tColor = ((on and tFocusTxtColor) or tNormalTxtColor)
	self:SetTxtsColor(tColor)
	
	if self.m_SelectFunc then
		self.m_SelectFunc(self.m_nCurHuoDongID, self.m_nCurTimeID, on)
	end
end

function HuoDongPushItemCell:SetTxtsColor(color)
	local texts = self.transform:GetComponentsInChildren(typeof(Text))
	for i = 0 , texts.Length - 1 do 
		texts[i].color = color
	end
end

function HuoDongPushItemCell:OnRecycle()
	
	self:SetTxtsColor(tNormalTxtColor)	
		
	self.Controls.m_PushSwitch.onValueChanged:RemoveListener(self.callbackSwitch)
	self.m_ItemToggle.onValueChanged:RemoveListener(self.m_SelectCallback)
	
	self.m_ItemToggle.group = nil
	self.m_ItemToggle.isOn  = false

	self.callbackSwitch = nil
	self.m_SelectCallback = nil
end

function HuoDongPushItemCell:OnDestroy()	
	UIControl.OnDestroy(self)
end

return HuoDongPushItemCell



