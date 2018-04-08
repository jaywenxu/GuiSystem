-------------------------------------------------------------------
-- 版  权:	(C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:	HaoWei
-- 日  期:	2017.8.25
-- 版  本:	1.0
-- 描  述:	辅助操作界面
-------------------------------------------------------------------
local SettingTipPage = UIControl:new
{
	windowName = "SettingTipPage",
}

local this = SettingTipPage

----------------------------------------------------------------
function SettingTipPage:Attach( obj )
	UIControl.Attach(self, obj)

	self.Controls.m_KnowBtn.onClick:AddListener(function() self:Hide() end)
	self.Controls.m_BGMaskBtn.onClick:AddListener(function() self:Hide() end)
	
	self.m_ContentRawimg = self.Controls.m_ContentImg:GetComponent(typeof(RawImage))
	
	--防止再次打开没有关闭界面的情况
	self.HideCB = function() self:Hide() end
	
end


function SettingTipPage:Show()
	rktEventEngine.SubscribeExecute(EVENT_SETTING_CLOSEWINDOW, 0, 0, self.HideCB)
	UIControl.Show(self)
end


function SettingTipPage:Hide()
	UIControl.Hide(self)
end

function SettingTipPage:OnDestroy()
	rktEventEngine.UnSubscribeExecute(EVENT_SETTING_CLOSEWINDOW, 0, 0, self.HideCB)
	self.HideCB = nil
	UIControl.OnDestroy(self)
	table_release(self)
end

--打开本tip界面
function SettingTipPage:OpenPage(path)
	--设置相关,   回调中显示可以防止显示图片跳跃
	UIFunction.SetRawImageSprite(self.m_ContentRawimg, AssetPath.TextureGUIPath .. path, function() self:Show() end)
end

return this