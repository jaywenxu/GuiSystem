--*****************************************************************
--** 文件名:	BossWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-12-11
--** 版  本:	1.0
--** 描  述:	首领活动窗口
--** 应  用:  
--******************************************************************
local titleImagePath = AssetPath.TextureGUIPath.."Activity/Activity_yewaishouling.png"
local nGuideID = 33

local BossWindow = UIWindow:new
{
	windowName	= "BossWindow",
}

function BossWindow:OnAttach(obj)
	UIWindow.OnAttach(self, obj)
	
	UIWindow.AddCommonWindowToThisWindow(self, true, titleImagePath, function() self:OnBackBtnClick() end, nil, function() self:SetFullScreen() end, true)
	
	self:InitBossWdt()
	
	self:InitCtrlData()
end

function BossWindow:InitBossWdt()
	local tBossWdtClass = require("GuiSystem.WindowList.HuoDong.Boss.BossWdt")
	tBossWdtClass:Attach(self.Controls.m_BossWdt.gameObject)
	tBossWdtClass:Show()
end

function BossWindow:InitCtrlData()
	
	self.Controls.m_GuideBtn.onClick:AddListener(handler(self, self.OnGuideClick))
	self.Controls.m_GotoBtn.onClick:AddListener(handler(self, self.OnGotoClick))
end

function BossWindow:OnBackBtnClick()
	self:Hide()
end

function BossWindow:OnGuideClick()
	UIManager.CommonGuideWindow:ShowWindow(nGuideID)
end

function BossWindow:OnGotoClick()
	   
	self:Hide()
    
	if UIManager.HuoDongWindow:isShow() then
		UIManager.HuoDongWindow:Hide()
	end
    
	local nConfigID = 4
	UIManager.SublineWindow:Show(true, nConfigID)
end

return BossWindow