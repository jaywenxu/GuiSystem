-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017/03/07
-- 版  本:    1.0
-- 描  述:    聊天配置窗口
-------------------------------------------------------------------

	
local SpeakerSendWindow = UIWindow:new
{
	windowName = "SpeakerSendWindow",
	m_RichMsgMap = {},
	m_MaxRichNum = 2,
}
local LaBaGoodId = 2122


local this = SpeakerSendWindow					-- 方便书写

------------------------------------------------------------
function SpeakerSendWindow:Init()
	self:InitCallbacks()
end
------------------------------------------------------------
function SpeakerSendWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)


	self.OnHistoryBtnClickCB = function() self:OnHistoryBtnClick() end 
	self.OnEmojiBtnClickCB = function() self:OnEmoJiBtnClick() end
	self.Controls.m_HistoryBtn.onClick:AddListener(function() self:OnHistoryBtnClickCB() end)
	self.Controls.m_EmojiBtn.onClick:AddListener(function() self:OnEmojiBtnClickCB() end)
	
	--关闭窗口按钮
    self.Controls.m_Close.onClick:AddListener(function() self:OnBtnCloseClick() end)

    UIFunction.AddEventTriggerListener( self.Controls.m_CloseButton , EventTriggerType.PointerClick , function( eventData ) self:OnCloseButtonClick(eventData) end )

	--m_AddGoodsBtn
    self.Controls.m_AddGoodsBtn.onClick:AddListener(function() self:OnAddGoodsBtnClick() end)
	
	--发送按钮
    self.Controls.m_SendButton.onClick:AddListener(function() self:OnSendButtonClick() end)
	
	--to VoiceGrid按钮
    self.Controls.m_ToRecordBtn.onClick:AddListener(function() self:OnToRecordBtnClick() end)
	
	--to KeyboardGrid按钮
    self.Controls.m_ToKeyboardBtn.onClick:AddListener(function() self:OnToKeyboardBtnClick() end)
	
	
	self.calbackKeyboardBtnDownClick = function(eventData) self:OnKeyboardBtnDownClick(eventData) end
	UIFunction.AddEventTriggerListener(self.Controls.m_RecordBtn,EventTriggerType.PointerDown,self.calbackKeyboardBtnDownClick)

	self.calbackKeyboardBtnUpClick = function(eventData) self:OnKeyboardBtnUpClick(eventData) end
	UIFunction.AddEventTriggerListener(self.Controls.m_RecordBtn,EventTriggerType.PointerUp,self.calbackKeyboardBtnUpClick)

	self.calbackKeyboardBtnDragClick = function(eventData) self:OnKeyboardBtnDragClick(eventData) end
	UIFunction.AddEventTriggerListener(self.Controls.m_RecordBtn,EventTriggerType.Drag,self.calbackKeyboardBtnDragClick)
	
	
	self.callbackOnInputFieldValueChanged = function() self:OnInputFieldValueChanged() end
	self.Controls.m_InputField:GetComponent(typeof(InputField)).onValueChanged:AddListener(self.callbackOnInputFieldValueChanged)
	self.Controls.ChatInputField = self.Controls.m_InputField
	
	self.Controls.m_KeyboardGrid.gameObject:SetActive(true)
	self.Controls.m_VoiceGrid.gameObject:SetActive(false)

	self.Controls.m_InputField:GetComponent(typeof(InputField)).characterLimit = LOUDSPEAKER_MAX_MESSAGE

	self.Controls.m_lastLengthText.text = "还可输入"..tostring(LOUDSPEAKER_MAX_MESSAGE).."字"
    self:Refresh()
end

function SpeakerSendWindow:Refresh()
    if not self:isLoaded() then
        return
    end

	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	local UID = packetPart:GetGoodsUIDByGoodsID(LaBaGoodId)
	if UID == nil or UID == -1 then
		self.Controls.m_LaBaNum.text = "<color=#FF0000>0</color>"
		return
	end
	
	local entity = IGame.EntityClient:Get(UID)
	if entity and EntityClass:IsLeechdom(entity:GetEntityClass()) then
		local totalNum = entity:GetNumProp(GOODS_PROP_QTY)
		self.Controls.m_LaBaNum.text = totalNum
	end
end

---------------------------------------------------------------
--对话输入框值输入变化
function SpeakerSendWindow:OnInputFieldValueChanged()
	local length  = utf8.len(self.Controls.m_InputField:GetComponent(typeof(InputField)).text)
	local lastLength = LOUDSPEAKER_MAX_MESSAGE - length
	self.Controls.m_lastLengthText.text = "还可输入"..tostring(lastLength).."字"
end
------------------------------------------------------------
function SpeakerSendWindow:OnKeyboardBtnDownClick(eventData)
	IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "点下录音按钮")
	UIManager.SpeechNoticeWindow:Show(true)
	UIManager.SpeechNoticeWindow:SetCallBackFunc(UIManager.SpeakerSendWindow.SetInputFieldText)
	UIManager.SpeechNoticeWindow:OnBtnDownClick(eventData)
end

function SpeakerSendWindow:OnKeyboardBtnUpClick(eventData)
	UIManager.SpeechNoticeWindow:OnBtnUpClick(eventData)
--[[
	-- 电脑测试代码
	local recordData = {}
	recordData.speech = "电脑测试"
	recordData.time = 12
	recordData.url = "http://store2.aiwaya.cn/amr58df6bcbbd42f20c64bd8596.amr"
	SpeakerSendWindow.SetInputFieldText(recordData)--]]
end

function SpeakerSendWindow:OnKeyboardBtnDragClick(eventData)
	UIManager.SpeechNoticeWindow:OnBtnDragClick(eventData)
end

function SpeakerSendWindow:OnAddGoodsBtnClick()
	UIManager.ShopWindow:OpenShop(LaBaGoodId)
end
------------------------------------------------------------
--点击关闭按钮
function SpeakerSendWindow:OnBtnCloseClick()
	if not self:isLoaded() then
		return
	end
	self.Controls.m_InputField:GetComponent(typeof(InputField)).text = ""
	self:Hide()
end
------------------------------------------------------------
function SpeakerSendWindow:OnCloseButtonClick( eventData )
    self:OnBtnCloseClick()
    rkt.UIAndTextHelpTools.PassThroughPointerClickEvent( eventData )
end
------------------------------------------------------------
--点击关闭按钮
function SpeakerSendWindow:ShowOrHide()
	if self:isShow() then
		self.Controls.m_InputField:GetComponent(typeof(InputField)).text = ""
		self:Hide()
	else
		UIManager.SpeakerSendWindow:Show(true)
        UIManager.SpeakerSendWindow:Refresh()
	end
end

function SpeakerSendWindow:OnSendButtonClick()
	local UID = IGame.SkepClient:GetSkeepGoodsUID(LaBaGoodId)
	if not UID or UID == -1 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "需要消耗喇叭道具")
		return
	end
	local entity = IGame.EntityClient:Get(UID)
	if entity and EntityClass:IsLeechdom(entity:GetEntityClass()) then
		local totalNum = entity:GetNumProp(GOODS_PROP_QTY)
		if totalNum < 1 then
			return
		end
	end
	local SpeakText = self.Controls.m_InputField:GetComponent(typeof(InputField)).text
	if SpeakText == "" then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请先输入你要发送的文字！")
		return
	end
	local HisText = SpeakText
	SpeakText = GameHelp.ChatGuoLv(SpeakText)
	
	local RichMapCnt = self:RefreshRichMsgMap()
	if RichMapCnt > 2 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "最多只能展示两个物品或装备")
		return
	end
	if RichMapCnt > 0 then
		for KeyStr,RichStr in pairs(self.m_RichMsgMap) do
			SpeakText = string.gsub( SpeakText , KeyStr , RichStr )
		end
	end
	
	IGame.ChatClient:SendSpeakerMessage(1, SpeakText)
	
	UIManager.ChatHistoryWindow:InsertMsg(HisText,1)
	self:OnBtnCloseClick()
end

function SpeakerSendWindow.SetInputFieldText(recordData)
	SpeakerSendWindow.Controls.m_InputField:GetComponent(typeof(InputField)).text = recordData.speech or ""
end

------------------------------------------------------------
--点击“切换至语音输入”按钮
function SpeakerSendWindow:OnToRecordBtnClick()
	self.Controls.m_KeyboardGrid.gameObject:SetActive(false)
	self.Controls.m_VoiceGrid.gameObject:SetActive(true)
end

------------------------------------------------------------
--点击“切换至键盘输入”按钮
function SpeakerSendWindow:OnToKeyboardBtnClick()
	self.Controls.m_KeyboardGrid.gameObject:SetActive(true)
	self.Controls.m_VoiceGrid.gameObject:SetActive(false)
end

-- 添加新物品事件
function SpeakerSendWindow:OnEventAddGoods()
	if not self:isShow() then
		return
	end
	self:Refresh()
end

-- 删除物品事件
function SpeakerSendWindow:OnEventRemoveGoods()
	self:OnEventAddGoods()
end

-- 订阅事件
function SpeakerSendWindow:SubscribeWinExecute()
	rktEventEngine.SubscribeExecute(EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
end

-- 取消订阅事件
function SpeakerSendWindow:UnSubscribeWinExecute()
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
end

-- 初始化全局回调函数
function SpeakerSendWindow:InitCallbacks()
	self.callback_OnEventAddGoods = function(event, srctype, srcid, eventdata) self:OnEventAddGoods(eventdata) end
	self.callback_OnEventRemoveGoods = function(event, srctype, srcid, eventdata) self:OnEventRemoveGoods(eventdata) end
end

--历史记录按钮点击
function SpeakerSendWindow:OnHistoryBtnClick()
	UIManager.ChatHistoryWindow:ShowOrHide()
	UIManager.ChatHistoryWindow:SetClickCallback(handler(self, self.SetInputText)) 
end

--表情按钮点击
function SpeakerSendWindow:OnEmoJiBtnClick()
	UIManager.RichTextWindow:SetTogglesVisible({"表情","宠物","定位","物品","摆摊","文字表情"}, true)
	UIManager.RichTextWindow:ShowOrHide(self)-- 调富文本窗口
end

function SpeakerSendWindow:CheckCanInput(txt)
	local ChatInputFieldText = txt or self.Controls.ChatInputField:GetComponent(typeof(InputField)).text
	
	if utf8.len(ChatInputFieldText) > MAX_CHAT_MSG_CNT then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "文字输入已达上限！不能继续输入！")
		return false
	else
		return true
	end
end

function SpeakerSendWindow:InsertInputText(txt)
	if not txt then
		return
	end
	local ChatInputFieldText = self.Controls.ChatInputField:GetComponent(typeof(InputField)).text..txt or ""
	if not self:CheckCanInput(ChatInputFieldText) then
		return
	end
	self.Controls.ChatInputField:GetComponent(typeof(InputField)).text = ChatInputFieldText
end

function SpeakerSendWindow:InsertRichText(ShowText,RichText,CanRepeatFlg)
	if not ShowText and not RichText and not self:CheckCanInput() then
		return
	end
	local RichMapCnt = self:RefreshRichMsgMap()
	if RichMapCnt < self.m_MaxRichNum then
		if not CanRepeatFlg and self.m_RichMsgMap["<"..ShowText..">"] ~= nil then
			local index = 1
			local ShowTextTmp = ShowText.."1"
			for i=1,self.m_MaxRichNum do
				if self.m_RichMsgMap[ShowTextTmp] ~= nil then
					index = index + 1
					ShowTextTmp = ShowText..index
				end
			end
			ShowText = ShowTextTmp
		end
		self.m_RichMsgMap["<"..ShowText..">"] = RichText
	else
		if not CanRepeatFlg or (CanRepeatFlg and self.m_RichMsgMap["<"..ShowText..">"] == nil) then
				IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "单条消息物品展示已达上限！不能继续添加！")
			return
		end
	end
	local ChatInputFieldText = self.Controls.ChatInputField:GetComponent(typeof(InputField)).text or ""
	self.Controls.ChatInputField:GetComponent(typeof(InputField)).text = ChatInputFieldText.."<"..ShowText..">"
end

function SpeakerSendWindow:RefreshRichMsgMap()
	local ChatInputFieldText = self.Controls.ChatInputField:GetComponent(typeof(InputField)).text or ""
	if ChatInputFieldText == "" then
		self.m_RichMsgMap = {}
		return 0
	end
	local RichCnt = 0
	local RichMsgMap = {}
	for ShowText,RichText in pairs(self.m_RichMsgMap) do
		local StrTmp,StrCnt = string.gsub(ChatInputFieldText,ShowText,"")
		if StrCnt > 0 then
			RichMsgMap[ShowText] = RichText
			RichCnt = RichCnt + StrCnt
		end
	end
	self.m_RichMsgMap = RichMsgMap
	cLog("===="..(RichCnt),"red")
	return RichCnt
end

function SpeakerSendWindow:SetInputText(txt)
	if not txt and not self:CheckCanInput(txt) then
		return
	end
	self.Controls.ChatInputField:GetComponent(typeof(InputField)).text = txt
end
return this







