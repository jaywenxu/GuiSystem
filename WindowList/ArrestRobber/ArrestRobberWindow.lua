-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    何荣德
-- 日  期:    2017/12/18
-- 版  本:    1.0
-- 描  述:    缉拿大盗窗口
-------------------------------------------------------------------
local titleImagePath = AssetPath.TextureGUIPath.."ActivityBoss/ActivityBoss_zuduichengfa.png"

local ArrestRobberWindow = UIWindow:new
{
    windowName	= "ArrestRobberWindow"
}

function ArrestRobberWindow:OnAttach( obj )
	UIWindow.OnAttach(self, obj)
	
	UIWindow.AddCommonWindowToThisWindow(self, true, titleImagePath, function() self:OnBackBtnClick() end, nil, function() self:SetFullScreen() end, true)
	
	self:InitArrestRobberWdt()
end

function ArrestRobberWindow:InitArrestRobberWdt()
	local tArrestRobberWdtClass = require("GuiSystem.WindowList.ArrestRobber.ArrestRobberWdt")
	tArrestRobberWdtClass:Attach(self.Controls.m_ArrestRobberWdt.gameObject)
	tArrestRobberWdtClass:Show()
end

function ArrestRobberWindow:OnBackBtnClick()
	self:Hide()
end

return ArrestRobberWindow