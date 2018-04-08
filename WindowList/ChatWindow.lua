-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017/02/19
-- 版  本:    1.0
-- 描  述:    滴答窗口
-------------------------------------------------------------------

local ChatWindow = UIWindow:new
{
	windowName = "ChatWindow",
	m_ToggleChannel = {
		[1] = {ChatChannel_World,	"世界频道"},		-- 世界
		[2] = {ChatChannel_Tribe,	"帮会频道"},		-- 帮会
		[3] = {ChatChannel_Team,	"队伍频道"},		-- 队伍
		[4] = {ChatChannel_Current,	"附近频道"},		-- 附近
		[5] = {ChatChannel_System,	"系统频道"},		-- 系统
		[6] = {ChatChannel_Voice,	"主播频道"},		-- 主播
	},
	m_CurShowChannel = ChatChannel_World,
	m_CurIndex = 1,
	m_RecordState = 0, -- 语音发送状态，0：初始状态  1：按下状态（开始录音）  2：已超时状态（结束录音但是没抬手）
	m_RichMsgMap = {},
	m_ChannelRedDotFlg = {},
	m_MaxRichNum = 2,
}

local RecordLen = 0
local this = ChatWindow					-- 方便书写
local zero = int64.new("0")

------------------------------------------------------------
function ChatWindow:Init()
	self.ChannelToggleContainer = require("GuiSystem.WindowList.Chat.ChannelToggleContainer")
	self.ChatMessageWidget = require("GuiSystem.WindowList.Chat.ChatMessageWidget")
	self.EmojiWidget =  require("GuiSystem.WindowList.Chat.ChatEmojiWidget")
	
	self.m_TimeHanderRecord = function() self:OnRecordTimer() end
end

------------------------------------------------------------
function ChatWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	
	self.ChannelToggleContainer:Attach( self.Controls.channelToggleContainer.gameObject )
	self.ChatMessageWidget:Attach( self.Controls.chatMessageWidget.gameObject )
	self.EmojiWidget:Attach(self.Controls.emojiWidget.gameObject)
	
	
	--关闭滴答消息窗口按钮
    --self.Controls.m_MaskButton.onClick:AddListener(function() self:OnBtnCloseClick() end)
    self.Controls.m_FoldButton.onClick:AddListener(function() self:OnBtnCloseClick() end)
	
	--点击发送按钮
    self.Controls.m_SendButton.onClick:AddListener(function() self:OnSendButtonClick() end)
	
	--点击设置按钮
    self.Controls.m_ConfigButton.onClick:AddListener(function() self:OnConfigButtonClick() end)
	
	--点击喇叭按钮
    self.Controls.m_SpeakerButton.onClick:AddListener(function() self:OnSpeakerButtonClick() end)
	
	--点击语音输入按钮
    self.Controls.m_MicrophoneBtn.onClick:AddListener(function() self:OnMicrophoneBtnClick() end)
	
	--点击打字输入按钮
    self.Controls.m_KeyboardBtn.onClick:AddListener(function() self:OnKeyboardBtnClick() end)
	
	--点击表情按钮
    self.Controls.ChatEmojiButton.onClick:AddListener(function() self:OnEmojiButtonClick() end)
	--点击历史按钮
    self.Controls.ChatHistoryButton.onClick:AddListener(function() self:OnHistoryButtonClick() end)
	--点击加入帮会
    self.Controls.m_JoinClanBtn.onClick:AddListener(function() self:OnJoinClanBtnClick() end)
	--点击好友按钮
    self.Controls.m_FriendButton.onClick:AddListener(function() self:OnFriendBtnClick() end)
	--点击好友按钮
    self.Controls.m_BubbleButton.onClick:AddListener(function() self:OnBubbleBtnClick() end)
	
	self.Controls.DOTweener = self.Controls.m_tween:GetComponent(typeof(DG.Tweening.DOTweenAnimation))
	self.calbackDOTweener = function() self:WindowShowOrHideByPalce() end
	self.Controls.DOTweener.onStepComplete:AddListener(self.calbackDOTweener)

	--打开富文本动画处理
	self.InputTweener = self.Controls.m_AnimationParent:GetComponent(typeof(DG.Tweening.DOTweenAnimation))
	self.OpenRichTextWinCB = function() self:OnOpenRichTextWin() end
	self.CloseRichTextWinCB = function() self:OnCloseRichTextWin() end
	rktEventEngine.SubscribeExecute(EVENT_CHAT_OPENRICHTEXTWINDOW, SOURCE_TYPE_SYSTEM, 0,self.OpenRichTextWinCB)			--订阅打开富文本事件
	rktEventEngine.SubscribeExecute(EVENT_CHAT_CLOSERICHTEXTWINDOW, SOURCE_TYPE_SYSTEM, 0,self.CloseRichTextWinCB)			--订阅关闭富文本事件


	self.calbackKeyboardBtnDownClick = function(eventData) self:OnKeyboardBtnDownClick(eventData) end
	UIFunction.AddEventTriggerListener(self.Controls.ChatChannelSpeaker,EventTriggerType.PointerDown,self.calbackKeyboardBtnDownClick)

	self.calbackKeyboardBtnUpClick = function(eventData) self:OnKeyboardBtnUpClick(eventData) end
	UIFunction.AddEventTriggerListener(self.Controls.ChatChannelSpeaker,EventTriggerType.PointerUp,self.calbackKeyboardBtnUpClick)

	self.calbackKeyboardBtnDragClick = function(eventData) self:OnKeyboardBtnDragClick(eventData) end
	UIFunction.AddEventTriggerListener(self.Controls.ChatChannelSpeaker,EventTriggerType.Drag,self.calbackKeyboardBtnDragClick)
	
	self.ChatMessageWidget:ReloadChannel()
	
	self.Controls.KeyBoardGrid.gameObject:SetActive(true)
	self.Controls.VoiceGrid.gameObject:SetActive(false)
	self:SubscribeEvts()
	self:RefreshRedDot()
    return self
end

function ChatWindow:Show( bringTop )
	if self:isLoaded() then
		rktEventEngine.SubscribeExecute(EVENT_CHAT_OPENRICHTEXTWINDOW, SOURCE_TYPE_SYSTEM, 0,self.OpenRichTextWinCB)			--订阅打开富文本事件
		rktEventEngine.SubscribeExecute(EVENT_CHAT_CLOSERICHTEXTWINDOW, SOURCE_TYPE_SYSTEM, 0,self.CloseRichTextWinCB)			--订阅关闭富文本事件
	end
	UIWindow.Show(self, bringTop)
end

function ChatWindow:Hide(destory)
	rktEventEngine.UnSubscribeExecute(EVENT_CHAT_OPENRICHTEXTWINDOW, SOURCE_TYPE_SYSTEM, 0,self.OpenRichTextWinCB)
	rktEventEngine.UnSubscribeExecute(EVENT_CHAT_CLOSERICHTEXTWINDOW, SOURCE_TYPE_SYSTEM, 0,self.CloseRichTextWinCB)
	UIWindow.Hide(self, destory)
end

function ChatWindow:OnDestroy()
	rktEventEngine.UnSubscribeExecute(EVENT_CHAT_OPENRICHTEXTWINDOW, SOURCE_TYPE_SYSTEM, 0,self.OpenRichTextWinCB)
	rktEventEngine.UnSubscribeExecute(EVENT_CHAT_CLOSERICHTEXTWINDOW, SOURCE_TYPE_SYSTEM, 0,self.CloseRichTextWinCB)
	self.m_CurShowChannel = ChatChannel_World
	self:UnSubscribeEvts()
	UIWindow.OnDestroy(self)
end

------------------------------------------------------------
function ChatWindow:OnMicrophoneBtnClick()
	self.Controls.KeyBoardGrid.gameObject:SetActive(false)
	self.Controls.VoiceGrid.gameObject:SetActive(true)
end

function ChatWindow:OnKeyboardBtnClick()
	self.Controls.KeyBoardGrid.gameObject:SetActive(true)
	self.Controls.VoiceGrid.gameObject:SetActive(false)
end

------------------------------------------------------------
function ChatWindow:OnKeyboardBtnDownClick(eventData)
	if self.m_CurShowChannel == ChatChannel_Team then
		local pHero = GetHero()
			if not pHero then
			return
		end
		if pHero:GetTeamID() ~= 0 then
			
		else
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你目前不在队伍中，不能使用队伍语音频道")
			return
		end
	end
	UIManager.SpeechNoticeWindow:Show(true)
	UIManager.SpeechNoticeWindow:SetCallBackFunc(IGame.ChatClient.CallBackSendVoiceChatMessage)
	UIManager.SpeechNoticeWindow:OnBtnDownClick(eventData)
end

function ChatWindow:OnKeyboardBtnUpClick(eventData)
	UIManager.SpeechNoticeWindow:OnBtnUpClick(eventData)
end

function ChatWindow:OnKeyboardBtnDragClick(eventData)
	UIManager.SpeechNoticeWindow:OnBtnDragClick(eventData)
end

------------------------------------------------------------
--窗口显示
function ChatWindow:ShowOrHide()
	if not self:isShow()then
		if not self:isLoaded() then
			self:Show(true)
			DelayExecuteEx(100,function ()
				ChatWindow:MoveInWindow()
			end)
			
			return
		end
		self:Show()
		ChatWindow:MoveInWindow()
	else
		self:OnBtnCloseClick()
	end
end

function ChatWindow:WindowShowOrHideByPalce()
	local Position = self.Controls.m_tween.gameObject.transform.localPosition
	if Position.x == -902 then
		self:Hide()
	end
end

------------------------------------------------------------
--窗口显示
function ChatWindow:MoveInWindow()
	if not self:isLoaded() then
		DelayExecuteEx(100,function ()
				ChatWindow:MoveInWindow()
			end)
		return
	end
	
	self.Controls.m_tween.transform:DOKill(false)

	self.Controls.DOTweener:DORestartById(1)
	self:RefreshRedDot()
	self:RedDotShowOrHide(self.m_CurShowChannel,false)
	self.ChatMessageWidget:ReloadChannel()
end

--------------------------------------------------------------------------------
--关闭窗口按钮回调函数
function ChatWindow:OnBtnCloseClick()
	UIManager.RichTextWindow:Hide()
	UIManager.ChatHistoryWindow:Hide()
	UIManager.SpeakerSendWindow:OnBtnCloseClick()
	self.Controls.m_tween.transform:DOKill(false)
	local beginPosition = self.Controls.m_tween.gameObject.transform.localPosition
	self.Controls.DOTweener:DOPlayBackwardsById(1)
end

function ChatWindow:CheckCanInput(txt)
	local ChatInputFieldText = txt or self.Controls.ChatInputField:GetComponent(typeof(InputField)).text
	
	if utf8.len(ChatInputFieldText) > MAX_CHAT_MSG_CNT then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "文字输入已达上限！不能继续输入！")
		return false
	else
		return true
	end
end

function ChatWindow:InsertInputText(txt)
	if not txt then
		return
	end
	local ChatInputFieldText = self.Controls.ChatInputField:GetComponent(typeof(InputField)).text..txt or ""
	if not self:CheckCanInput(ChatInputFieldText) then
		return
	end
	self.Controls.ChatInputField:GetComponent(typeof(InputField)).text = ChatInputFieldText
end

function ChatWindow:InsertRichText(ShowText,RichText,CanRepeatFlg)
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

function ChatWindow:RefreshRichMsgMap()
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
	return RichCnt
end

function ChatWindow:SetInputText(txt)
	if not txt and not self:CheckCanInput(txt) then
		return
	end
	if self.Controls.ChatInputField then
		self.Controls.ChatInputField:GetComponent(typeof(InputField)).text = txt
	end
end

function ChatWindow:GetRichMapCnt()
	return table_count(self.m_RichMsgMap)
end

function ChatWindow:OnSendButtonClick()
	local ChatInputFieldText = self.Controls.ChatInputField:GetComponent(typeof(InputField)).text
	if ChatInputFieldText == "" then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请输入聊天内容")
		return
	end
	
	ChatInputFieldText = GameHelp.ChatGuoLv(ChatInputFieldText)
    -- client gm command
    if string.sub( ChatInputFieldText , 1 , 4 ) == "--gm" then
        require("test.GMCommand")
        LuaEval( string.sub( ChatInputFieldText , 5 ) )
        return
    end

	local MsgText = ChatInputFieldText

	cLog("[聊天-打印追踪]OnSendButtonClick1 "..tostringEx(MsgText),"red")
	local RichMapCnt = self:RefreshRichMsgMap()
	if RichMapCnt > 2 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "最多只能展示两个物品或装备")
		return
	end
	if RichMapCnt > 0 then
		for KeyStr,RichStr in pairs(self.m_RichMsgMap) do
			MsgText = string.gsub( MsgText , KeyStr , RichStr )
		end
	elseif RichMapCnt == 0 then
		MsgText = ChatInputFieldText
	end
	cLog("[聊天-打印追踪]OnSendButtonClick2 "..tostringEx(MsgText),"red")
	if MsgText == "" or self.m_CurShowChannel == ChatChannel_System then
		return
	end
	if self.m_CurShowChannel == ChatChannel_Tribe then
		local clanID = GetHero():GetNumProp(CREATURE_PROP_CLANID)
		--local clan = nil
		if not clanID or clanID == 0 then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你还没有加入帮会，无法发送帮会信息！")
			return
		end
	end
	if self.m_CurShowChannel == ChatChannel_Team then
		local pTeam = IGame.TeamClient:GetTeam()
		if pTeam == nil or pTeam:GetTeamID() == INVALID_TEAM_ID then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你还没有加入队伍，无法发送队伍信息！")
			return
		end
	end
	local SendFlg = false
	if string.sub(MsgText, 1, 1) == ':' then                                         --判断是不是"："号，发送系统命令
        IGame.ChatClient:sendSystemCommand(MsgText)
    else
        MsgText = StringFilter.Filter( MsgText , '*' )
		SendFlg = IGame.ChatClient:sendChatMessage(self.m_CurShowChannel,MsgText)
    end
	if SendFlg then
		UIManager.ChatHistoryWindow:InsertMsg(ChatInputFieldText)
	end
	self.Controls.ChatInputField:GetComponent(typeof(InputField)).text = ""
	self.m_RichMsgMap = {}
	UIManager.RichTextWindow:Hide()
	UIManager.ChatHistoryWindow:Hide()
--	print("[ChatWindow]OnSendButtonClick===m_CurShowChannel=",self.m_CurShowChannel,"MsgText=",MsgText)
end

--------------------------------------------------------------------------------
--点击设置按钮
function ChatWindow:OnConfigButtonClick()
	UIManager.ChatSettingWindow:ShowOrHide()
end

--------------------------------------------------------------------------------
--点击喇叭按钮
function ChatWindow:OnSpeakerButtonClick()
	self:OnBtnCloseClick()
	UIManager.SpeakerSendWindow:ShowOrHide()
end

--------------------------------------------------------------------------------
--点击Emoji按钮
function ChatWindow:OnEmojiButtonClick()
	UIManager.RichTextWindow:ShowOrHide(self) -- 调富文本窗口
end

--------------------------------------------------------------------------------
--点击历史记录按钮
function ChatWindow:OnHistoryButtonClick()
	UIManager.ChatHistoryWindow:ShowOrHide()
end

function ChatWindow:OnJoinClanBtnClick()
	local clan = IGame.ClanClient:GetClan()
	if not clan then
		UIManager.ClanNoneWindow:ShowWindow(nil,true)
	else
		uerror("[ChatWindow:OnJoinClanBtnClick]有帮会还显示加入帮会按钮，你逗我？")
	end	
end
------------------------------------------------------------
-- 点击好友按钮
function ChatWindow:OnFriendBtnClick()
	UIManager.FriendEmailWindow:Show(true)
end

function ChatWindow:OnBubbleBtnClick()
	self.ChatMessageWidget:JumpToBottom()
	--self.ScrollRect.verticalNormalizedPosition = 0
end

function ChatWindow:RefreshKeyBoardGrid()
	self.Controls.KeyBoardGrid.gameObject:SetActive(true)
	self.Controls.VoiceGrid.gameObject:SetActive(false)
	self.Controls.m_ClanApplyPanel.gameObject:SetActive(false)
	self.Controls.m_InputUnableText.gameObject:SetActive(false)
    -- 帮会频道   
	if self.m_CurShowChannel == ChatChannel_Tribe then
		local clanID = GetHero():GetNumProp(CREATURE_PROP_CLANID)
		-- 没有帮会
		if not clanID or clanID == 0 then
            self.Controls.m_JoinClanText:GetComponent(typeof(Text)).text = "当前没有帮会"
            self.Controls.m_JoinClanBtn.gameObject:SetActive(true)
			self.Controls.m_ClanApplyPanel.gameObject:SetActive(true)
			self.Controls.KeyBoardGrid.gameObject:SetActive(false)
			self.Controls.VoiceGrid.gameObject:SetActive(false)
            self.Controls.m_InputUnableText.gameObject:SetActive(false)
		end
	elseif self.m_CurShowChannel == ChatChannel_Team then   -- 队伍频道
		local teamID = GetHero():GetTeamID()
        -- 没有队伍
		if teamID == INVALID_TEAM_ID then
            self.Controls.m_JoinClanText:GetComponent(typeof(Text)).text = "当前没有队伍"
            self.Controls.m_JoinClanBtn.gameObject:SetActive(false)
			self.Controls.m_ClanApplyPanel.gameObject:SetActive(true)
			self.Controls.KeyBoardGrid.gameObject:SetActive(false)
			self.Controls.VoiceGrid.gameObject:SetActive(false)
            self.Controls.m_InputUnableText.gameObject:SetActive(false)
		end
    elseif self.m_CurShowChannel == ChatChannel_System then -- 系统频道
		self.Controls.m_ClanApplyPanel.gameObject:SetActive(false)
		self.Controls.KeyBoardGrid.gameObject:SetActive(false)
		self.Controls.VoiceGrid.gameObject:SetActive(false)
		self.Controls.m_InputUnableText.gameObject:SetActive(true)
	end
end

-- 标签变化
function ChatWindow:OnToggleChanged(on, index)
	if not on then
		return
	end
	
	if self.m_ToggleChannel[index][1] == self.m_CurShowChannel then -- 相同标签不用响应
		return
	end
	
	self.m_CurShowChannel = self.m_ToggleChannel[index][1]
	self.m_CurIndex = index
	self:RedDotShowOrHide(self.m_CurShowChannel,false)
	--IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "当前频道是 : "..self.m_ToggleChannel[index][2])
	self.ChatMessageWidget:ReloadChannel()
	self:RefreshKeyBoardGrid()
end

function ChatWindow:MsgArrived(Channel)
	if not self:isShow() then
		return
	end
	if self.m_CurShowChannel == Channel then
		self.ChatMessageWidget:RefreshMsgContainer()
	else
		--self:RedDotShowOrHide(Channel,true)
	end
end

--------------------------------------------------------------------------------
function ChatWindow:RedDotShowOrHide(Channel,State)
	--self.m_ChannelRedDotFlg[Channel] = State
	if not self:isShow() then
		return
	end
	local ToggleIndex = self:GetToggleIndexByChannel(Channel)
	self.ChannelToggleContainer:RedDotShowOrHide(ToggleIndex,State)
end

function ChatWindow:RefreshRedDot()
	for key,v in pairs(self.m_ChannelRedDotFlg) do
		--self:RedDotShowOrHide(key,v)
	end
end

--------------------------------------------------------------------------------
function ChatWindow:GetToggleIndexByChannel(Channel)
	for index,ToggleInfo in pairs(self.m_ToggleChannel) do
		if ToggleInfo[1] == Channel then
			return index
		end
	end
end

function ChatWindow:GetCurShowChannel()
	return self.m_CurShowChannel
end


function ChatWindow:OnJoinSuccessEvt(_, _, _, evtData)
	
	print("<color=green> ChatWindow:OnJoinSuccessEvt 成功加入帮派</color>")
	if self:isShow() and self.m_ToggleChannel[self.m_CurIndex][1] == ChatChannel_Tribe then
		self:RefreshKeyBoardGrid()
	end
end

function ChatWindow:OnUpdateProp(_, _, _, evtData)
	
	print("<color=green> ChatWindow:OnJoinSuccessEvt 成功加入帮派</color>")
	if self:isShow() and self.m_ToggleChannel[self.m_CurIndex][1] == ChatChannel_Tribe then
		self:RefreshKeyBoardGrid()
	end
end

function ChatWindow:RefreshRedDot()
	local flag = SysRedDotsMgr.GetSysFlag("MainMidBottom", "好友")
	UIFunction.ShowRedDotImg(self.Controls.m_FriendButton.transform, flag, true)
end


function ChatWindow:SubscribeEvts()--[[
	-- 成员加入帮会
	self.m_OnJoinSuccessCallBack = handler(self, self.OnJoinSuccessEvt)
	rktEventEngine.SubscribeExecute( EVENT_JOIN_SUCCESS, SOURCE_TYPE_CLAN, 0, self.m_OnJoinSuccessCallBack )--]]
	-- 成员加入帮会
	self.callback_OnUpdateProp = handler(self, self.OnUpdateProp)
	rktEventEngine.SubscribeExecute(EVENT_ENTITY_UPDATEPROP, SOURCE_TYPE_PERSON, 0, self.callback_OnUpdateProp)
	rktEventEngine.SubscribeExecute(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM,REDDOT_UI_EVENT_MAIN_MID_BOTTOM, self.RefreshRedDot, self)
end

function ChatWindow:UnSubscribeEvts()
	--rktEventEngine.UnSubscribeExecute( EVENT_JOIN_SUCCESS , SOURCE_TYPE_CLAN, 0, self.m_OnJoinSuccessCallBack )
	rktEventEngine.UnSubscribeExecute(EVENT_ENTITY_UPDATEPROP, SOURCE_TYPE_PERSON, 0, self.callback_OnUpdateProp)
	rktEventEngine.UnSubscribeExecute(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM,REDDOT_UI_EVENT_MAIN_MID_BOTTOM, self.RefreshRedDot, self)	
	self.callback_OnUpdateProp = nil
end

--------------------------------------------------------------------------------------------------------
--打开富文本面板
function ChatWindow:OnOpenRichTextWin()
	if self:isShow() then
		self.InputTweener:DORestart(false)
	end
end

--关闭富文本面板
function ChatWindow:OnCloseRichTextWin()
	if self:isShow() then
		self.InputTweener:DOPlayBackwards()
	end
end

return this







