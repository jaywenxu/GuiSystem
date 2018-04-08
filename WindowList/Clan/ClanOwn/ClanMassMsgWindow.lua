-- 帮派群发消息界面
-- @Author: XieXiaoMei
-- @Date:   2017-04-18 09:36:19
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-07 10:04:42

local ClanMassMsgWindow = UIWindow:new
{
	windowName        = "ClanMassMsgWindow",
}

------------------------------------------------------------
function ClanMassMsgWindow:Init()
end


function ClanMassMsgWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	local controls = self.Controls
	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_BackBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_ExpressionBtn.onClick:AddListener(handler(self, self.OnBtnExpressionClicked))
	controls.m_VoiceBtn.onClick:AddListener(handler(self, self.OnBtnVoiceClicked))
	controls.m_KeyboardBtn.onClick:AddListener(handler(self, self.OnBtnKeyboardClicked))
	controls.m_ConfirmBtn.onClick:AddListener(handler(self, self.OnBtnConfirmClicked))
	
	self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))

	local inputField = controls.m_ChatInput:GetComponent(typeof(InputField))
	inputField.onValueChanged:AddListener(handler(self, self.OnInputFieldChanged))
 	controls.inputField = inputField

 	local recordBtn = controls.m_RecordBtn
 	local voiceBtnDownCallback = handler(self, self.OnBtnRecordDownClicked)
	UIFunction.AddEventTriggerListener(recordBtn, EventTriggerType.PointerDown, voiceBtnDownCallback)

 	local voiceBtnUpCallback = handler(self, self.OnBtnRecordUpClicked)
	UIFunction.AddEventTriggerListener(recordBtn, EventTriggerType.PointerUp, voiceBtnUpCallback)

	local voiceBtnDragCallback = handler(self, self.OnBtnRecordDragClicked)
	UIFunction.AddEventTriggerListener(recordBtn, EventTriggerType.Drag, voiceBtnDragCallback)
	
	self:InitUI()
	
	self:OnInputFieldChanged()
end

function ClanMassMsgWindow:Show()
	UIWindow.Show(self)

	if self:isLoaded() then
		self.Controls.inputField.text = ""
	end
	
end

function ClanMassMsgWindow:OnEnable()
	self:InitUI()
end

function ClanMassMsgWindow:InitUI()
	local clanClient = IGame.ClanClient
	local clan = clanClient:GetClan()
	if not clan then
		return 
	end

	local getClanAttr = function (key)
		return clanClient:GetClanData(key)
	end
	
	local nCurMailTimes = getClanAttr(emClanProp_MailTimes)
	local nMaxMailTimes = IGame.ClanClient:GetClanConfig(CLAN_CONFIG.MASS_MAIL_LIMIT)
	
	local szTxt = nCurMailTimes.."/"..nMaxMailTimes
	self.Controls.m_MailTimes.text = tostring(szTxt)
end

-- 关闭按钮事件
function ClanMassMsgWindow:OnBtnCloseClicked()
	if UIManager.RichTextWindow:isShow() then
		UIManager.RichTextWindow:Hide()
	end

	self:Hide()
end

-- 表情按钮事件
function ClanMassMsgWindow:OnBtnExpressionClicked()
	UIManager.RichTextWindow:SetTogglesVisible({"表情", "文字表情"}, true)
	UIManager.RichTextWindow:ShowOrHide(self)-- 调富文本窗口
end
---------------------------------------------------------------
--富文本窗口调用函数
-- 插入普通文本
function ClanMassMsgWindow:InsertInputText(text)
	self:OnFaceInputed(text)
end

-- 插入富文本
function ClanMassMsgWindow:InsertRichText()

end

-- 设置内容
function ClanMassMsgWindow:SetInputText(text)
	local inputField = self.Controls.inputField
	inputField.text = text
end
---------------------------------------------------------------
function ClanMassMsgWindow:OnFaceInputed(text)
	cLog("OnFaceInputed", "red")
	print("RichText:", text)

	local inputField = self.Controls.inputField
	inputField.text = inputField.text .. text

end

-- 按键按钮事件
function ClanMassMsgWindow:OnBtnKeyboardClicked()
	self:SwitchInputOpPnl(false)
end

-- 语音按钮事件
function ClanMassMsgWindow:OnBtnVoiceClicked()
	self:SwitchInputOpPnl(true)
end


-- 录音按钮抬起事件
function ClanMassMsgWindow:OnBtnRecordUpClicked(evtData)
	print("record up")

	UIManager.SpeechNoticeWindow:OnBtnUpClick(evtData)
end


-- 录音按钮按下事件
function ClanMassMsgWindow:OnBtnRecordDownClicked(evtData)
	UIManager.SpeechNoticeWindow:Show(true)
	UIManager.SpeechNoticeWindow:SetCallBackFunc(function ( )print("发送语音")end)
	UIManager.SpeechNoticeWindow:OnBtnDownClick(evtData)
end

-- 录音按钮拖拽事件
function ClanMassMsgWindow:OnBtnRecordDragClicked(evtData)
	UIManager.SpeechNoticeWindow:OnBtnDragClick(evtData)
end

-- 切换输入面板
function ClanMassMsgWindow:SwitchInputOpPnl(bVoiceOp)
	local controls = self.Controls
	controls.m_KeyboardOp.gameObject:SetActive(not bVoiceOp)
	controls.m_VoiceOp.gameObject:SetActive(bVoiceOp)
end


-- 确定按钮事件
function ClanMassMsgWindow:OnBtnConfirmClicked()
	local txt = self.Controls.inputField.text
	if IsNilOrEmpty(txt) then
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请先输入邮件内容") 
		return 
	end
     
    if StringFilter.FilterKeyWord(txt) then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "邮件内容含有屏蔽字，请重新输入！") 
		return
	end
	
	local nCurMailTimes = IGame.ClanClient:GetClanData(emClanProp_MailTimes)
	local nMaxMailTimes = tonumber(IGame.ClanClient:GetClanConfig(CLAN_CONFIG.MASS_MAIL_LIMIT))
	if nCurMailTimes >= nMaxMailTimes then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "今日群发邮件次数已达上限")
		return
	end
		
	IGame.ClanClient:SendGroupEmailRequest(txt)	

	self:Hide()
end

-- 输入框输入事件
function ClanMassMsgWindow:OnInputFieldChanged()
	local controls = self.Controls
	local inputField = controls.inputField
	local leftLen = inputField.characterLimit - inputField:GetInputWordsLength()
	controls.m_InputLeftTxt.text = string.format("还可编辑%d个字",  math.floor(leftLen * 0.5)) 
end

return ClanMassMsgWindow
------------------------------------------------------------

