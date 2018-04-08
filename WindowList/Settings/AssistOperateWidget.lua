-------------------------------------------------------------------
-- 版  权:	(C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:	HaoWei
-- 日  期:	2017.8.25
-- 版  本:	1.0
-- 描  述:	辅助操作界面
-------------------------------------------------------------------
local AssistOperateWidget = UIControl:new
{
	windowName = "AssistOperateWidget",
}

local this = AssistOperateWidget

--TODO,      提示图片
local InstructionPath = {
	"Setting/RawImage/Setting_board_dantizhiliao.png",
	"Setting/RawImage/Setting_board_fuhuojineng.png",
}

function AssistOperateWidget:Attach( obj )
	UIControl.Attach(self, obj)
	
	self.TipPage = require("GuiSystem.WindowList.Settings.SettingTipPage"):new()
	self.TipPage:Attach(self.Controls.m_TipPage.gameObject)
	
	
	self.CureTipBtnClickCB = function() self:OnTipBtnClick(1) end
	self.Controls.m_CureTipBtn.onClick:AddListener(self.CureTipBtnClickCB)
	self.ResTipBtnClickCB = function() self:OnTipBtnClick(2) end
	self.Controls.m_ResTipBtn.onClick:AddListener(self.ResTipBtnClickCB)
	self.Controls.m_CloseBtn.onClick:AddListener(function() self:Hide() end)
	self.Controls.m_MaskBtn.onClick:AddListener(function() self:Hide() end)
	
	self.HideCB = function() self:Hide() end
end


function AssistOperateWidget:Show()
	rktEventEngine.SubscribeExecute(EVENT_SETTING_CLOSEWINDOW, 0,0, self.HideCB)
	UIControl.Show(self)
end


function AssistOperateWidget:Hide()
	self:SaveSetting()
	UIControl.Hide(self)
end

function AssistOperateWidget:OnDestroy()
	rktEventEngine.UnSubscribeExecute(EVENT_SETTING_CLOSEWINDOW, 0, 0, self.HideCB)
	self.HideCB = nil
	UIControl.OnDestroy(self)
	table_release(self)
end
----------------------------------------------------------------
--界面设置
function AssistOperateWidget:OpenAssistWidget()
	self:Show()
	
	--数据设置
	local showHeadIcon = PlayerPrefs_GetBool("CureShowCureHeadIcon", false)				
	local curePriority = PlayerPrefs.GetInt("CurePriority", 0)						--   0-队长， 1-真武
	local resShowHeadIcon = PlayerPrefs_GetBool("ResShowHeadIcon", false)				
	local resPriority = PlayerPrefs.GetInt("ResPriority", 0)						--   0-队长， 1-真武
	
	if not showHeadIcon then
		self.Controls.m_CureHeadIconTgl.isOn = false
	else
		self.Controls.m_CureHeadIconTgl.isOn = true
	end
	
	if curePriority == 0 then
		self.Controls.m_CureCaptainFirstTgl.isOn = true
	else
		self.Controls.m_CureZhenWuFirstTgl.isOn = true
	end
	
	if not resShowHeadIcon then
		self.Controls.m_ResShowHeadIconTgl.isOn = false
	else
		self.Controls.m_ResShowHeadIconTgl.isOn = true
	end
	
	if resPriority == 0 then 
		self.Controls.m_ResCaptainFirstTgl.isOn = true
	else
		self.Controls.m_ResZhenWuFirstTgl.isOn = true
	end
end

--界面设置保存
function AssistOperateWidget:SaveSetting()
	if self.Controls.m_CureHeadIconTgl.isOn then
		PlayerPrefs_SetBool("CureShowCureHeadIcon", true)
	else
		PlayerPrefs_SetBool("CureShowCureHeadIcon", false)
	end
	
	if self.Controls.m_CureCaptainFirstTgl.isOn then
		PlayerPrefs.SetInt("CurePriority", 0)
	else
		PlayerPrefs.SetInt("CurePriority", 1)
	end
	
	if self.Controls.m_ResShowHeadIconTgl.isOn then
		PlayerPrefs_SetBool("ResShowHeadIcon", true)
	else
		PlayerPrefs_SetBool("ResShowHeadIcon", false)
	end
	
	if self.Controls.m_ResCaptainFirstTgl.isOn then
		PlayerPrefs.SetInt("ResPriority", 0)
	else
		PlayerPrefs.SetInt("ResPriority", 1)
	end
end
-- index: 1-Cure, 2-Resurrection
function AssistOperateWidget:OnTipBtnClick(index)
	local path = InstructionPath[index]
	self.TipPage:OpenPage(path)
end


return this