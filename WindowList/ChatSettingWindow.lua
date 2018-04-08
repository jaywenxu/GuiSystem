-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017/03/07
-- 版  本:    1.0
-- 描  述:    聊天配置窗口
-------------------------------------------------------------------

	
local ChatSettingWindow = UIWindow:new
{
	windowName = "ChatSettingWindow",

}


local this = ChatSettingWindow					-- 方便书写

------------------------------------------------------------
function ChatSettingWindow:Init()
end
------------------------------------------------------------
function ChatSettingWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
--[[	for i=1,4 do
		self.Controls["VoiceAutoPlay"..i].onValueChanged:AddListener(function(on) self:OnVoiceAutoPlayToggleClick(on, i) end)
	end--]]
	for i=1,5 do
		self.Controls["MainHUDShow"..i].onValueChanged:AddListener(function(on) self:OnMainHUDShowToggleClick(on, i) end)
	end

--[[	for i=1,4 do
		local Flg = UIManager.MainMidBottomWindow.MainChatWidget:GetVoiceAutoPlaySetting(i)
		self.Controls["VoiceAutoPlay"..i].isOn = Flg
	end--]]
	for i=1,5 do
		local Flg = UIManager.MainMidBottomWindow.MainChatWidget:GetMainHUDShowSetting(i)
		self.Controls["MainHUDShow"..i].isOn = Flg
	end
	
	--关闭窗口按钮
    self.Controls.m_Close.onClick:AddListener(function() self:OnBtnCloseClick() end)
	
    return self
end

------------------------------------------------------------
--点击自动播放语音开关
function ChatSettingWindow:OnVoiceAutoPlayToggleClick(on, i)
	print("OnVoiceAutoPlayToggleClick on on on ",on)
	UIManager.MainMidBottomWindow.MainChatWidget:SetVoiceAutoPlaySetting(on,i)
end

------------------------------------------------------------
--点击首页显示开关
function ChatSettingWindow:OnMainHUDShowToggleClick(on, i)
	print("OnMainHUDShowToggleClick on = ",on)
	UIManager.MainMidBottomWindow.MainChatWidget:SetMainHUDShowSetting(on,i)
end

------------------------------------------------------------
--点击关闭按钮
function ChatSettingWindow:OnBtnCloseClick()
	self:Hide()
end


------------------------------------------------------------
--刷新窗口
function ChatSettingWindow:Refresh()
	if not self:isLoaded() then
		return
	end
	for i=1,5 do
		local Flg = UIManager.MainMidBottomWindow.MainChatWidget:GetMainHUDShowSetting(i)
		self.Controls["MainHUDShow"..i].isOn = Flg
	end
end

------------------------------------------------------------
--开关窗口
function ChatSettingWindow:ShowOrHide()
	if self:isShow() then
		self:Hide()
	else
		self:Show(true,function ()
			self:Refresh()
		end)
	end
end





return ChatSettingWindow







