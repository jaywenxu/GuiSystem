-- 好友系统设置
-- @Author: LiaoJunXi
-- @Date:   2017-07-27 20:36:21
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-27 21:05:08

local FriendSettingDialog = UIControl:new
{
	windowName = "FriendSettingDialog",
	m_FriendClient,
	
	m_Toggles = {}
}

local KeyToggles = 
{
	["拒绝陌生人聊天"] = 1,
	["拒绝所有人聊天"]  = 2,
	["拒绝任何人加好友"]  = 3,
	["加好友需要验证"]  = 4,
}

function FriendSettingDialog:Attach( obj )
	UIControl.Attach(self, obj)
	self.m_FriendClient = IGame.FriendClient
	self:InitUI()
end

function FriendSettingDialog:InitUI()
	local controls = self.Controls
	
	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_BackBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	
	self.m_Toggles = {
		controls.m_VerifyTgl,
		controls.m_RefBeFriendTgl,
		controls.m_RefAllMsgTgl,
		controls.m_RefStrangeTgl,
	}
	
	local m_mySetting = self.m_FriendClient:GetFriendSetting()
	for i=1, 4 do
		local tgl = self.m_Toggles[i]
		tgl.onValueChanged:AddListener(function (on)
			self:OnTogglesChanged(i, on)
		end)
	end
	if nil ~= m_mySetting and #m_mySetting > 3 then
		for i=1, 4 do
			local tgl = self.m_Toggles[i]
			tgl.isOn = m_mySetting[i]
		end
	end
end

function FriendSettingDialog:OnDestroy()	
	UIControl.OnDestroy(self)
	table_release(self)
end

function FriendSettingDialog:OnRecycle()	
	UIControl.OnRecycle(self)
	table_release(self)
end

function FriendSettingDialog:OnBtnCloseClicked()
	self:Hide()
end

function FriendSettingDialog:OnTogglesChanged(idx, on)
	--print("FriendSettingDialog:OnTogglesChanged+".. tostring(on))
	local val = on and 1 or 0
	local m_mySetting = self.m_FriendClient:GetFriendSetting()
	--print("OnTogglesChanged:val=".. val)
	if m_mySetting ~= nil then
		local record = m_mySetting[idx]
		--print("OnTogglesChanged.record=".. tostring(record))
		if record ~= on then
			self.m_FriendClient:SetFriendSetting(idx, val)
			self.m_FriendClient:OnRequestFriendSetting(idx, val)
		end
	end
end

return FriendSettingDialog