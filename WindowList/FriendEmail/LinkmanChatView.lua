-- 好友系统界面内的联系人聊天视图
-- @Author: LiaoJunXi
-- @Date:   2017-07-26 12:25:45
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-28 16:10:45

-- 自定义成员
------------------------------------------------------------
local LinkmanChatView = UIControl:new
{
	windowName = "LinkmanChatView",
	
	m_ChatItemCellLua = nil,
	-- m_EmojiLua = nil,
	
	calbackKeyboardBtnDownClick = nil,
	calbackKeyboardBtnUpClick = nil,
	calbackKeyboardBtnDragClick = nil,
	
	m_CurLinkman = nil,
	
	m_RichMsgMap = {},
	m_MaxRichNum = 2,
	
	m_RequestToChatCallBack = nil,
	m_ChatMsgCallBack = nil,
	m_Refreshed = false,
	m_Padding = 0
}

local RecordLen = 0
local this = LinkmanChatView					-- 方便书写
local zero = int64.new("0")
local ContentSizeFitter = require("UnityEngine.UI.ContentSizeFitter")

local CELL_ITEM_COUNT_IN_LINE = 1       -- 一行五个物品格子
local CELL_ROW_COUNT_IN_PAGE = 4        -- 一页有几行
local TextMaxLength = 320               -- 文本最大长度
local CellGapY = 50						-- Y轴间距 
local TextHigh = 20						-- 一行文本预留高度
local TextTopHeight = 20	
local voiceHeight = 50
local cellHeight = 130
local NameTextHigh = 50		-- 名字高度
local CellSpace = 30		-- Cell 间隔
------------------------------------------------------------

-- 公用方法
------------------------------------------------------------
function LinkmanChatView:Init()
	--self.m_TimeHanderRecord = function() self:OnRecordTimer() end
end

function LinkmanChatView:Attach( obj )
	UIControl.Attach(self,obj)
	
	self:InitUI()
	self:SubscribeEvts()
end

function LinkmanChatView:OnDestroy()
	self:UnSubscribeEvts()
	self.m_RequestToChatCallBack = nil
	self.m_ChatMsgCallBack = nil
	
	UIWindow.OnDestroy(self)
	table_release(self)
end

function LinkmanChatView:OnRecycle()
	UIControl.OnRecycle(self)
	self:UnSubscribeEvts()
	self.m_RequestToChatCallBack = nil
	self.m_ChatMsgCallBack = nil	
	
	table_release(self)
end
------------------------------------------------------------

-- 初始化
------------------------------------------------------------
function LinkmanChatView:InitUI()
	local controls = self.Controls
	
	self.m_ChatItemCellLua = require( "GuiSystem.WindowList.Chat.ChatItemCell" )
	-- self.m_EmojiLua = require("GuiSystem.WindowList.Chat.ChatEmojiWidget")
	
	-- self.m_EmojiLua:Attach(controls.m_EmojiWidget.gameObject)
	
	--点击发送按钮
    controls.m_SendButton.onClick:AddListener(function() self:OnSendButtonClick() end)
	--点击语音输入按钮
    controls.m_MicrophoneBtn.onClick:AddListener(function() self:OnMicrophoneBtnClick() end)
	--点击打字输入按钮
    controls.m_KeyboardBtn.onClick:AddListener(function() self:OnKeyboardBtnClick() end)
	--点击表情按钮
    controls.m_EmojiButton.onClick:AddListener(function() self:OnEmojiButtonClick() end)
	--点击历史按钮
    controls.m_HistoryButton.onClick:AddListener(function() self:OnHistoryButtonClick() end)
	--点击清空按钮
    controls.m_ClearButton.onClick:AddListener(function() self:ClearChatMsg() end)
	
	-- 按下麦克风按钮，对着话筒说话
	self.calbackKeyboardBtnDownClick = function(eventData) self:OnKeyboardBtnDownClick(eventData) end
	UIFunction.AddEventTriggerListener(controls.ChatChannelSpeaker,EventTriggerType.PointerDown,self.calbackKeyboardBtnDownClick)
	-- 抬起麦克风按钮，点击发送
	self.calbackKeyboardBtnUpClick = function(eventData) self:OnKeyboardBtnUpClick(eventData) end
	UIFunction.AddEventTriggerListener(controls.ChatChannelSpeaker,EventTriggerType.PointerUp,self.calbackKeyboardBtnUpClick)
	-- 滑动取消录音
	self.calbackKeyboardBtnDragClick = function(eventData) self:OnKeyboardBtnDragClick(eventData) end
	UIFunction.AddEventTriggerListener(controls.ChatChannelSpeaker,EventTriggerType.Drag,self.calbackKeyboardBtnDragClick)
	
	controls.KeyBoardGrid.gameObject:SetActive(true)
	controls.VoiceGrid.gameObject:SetActive(false)
	
	-- 支持滑动的消息列表裁剪区域和消息item
	local scrollView  = controls.m_ChatCellList
	local listView = scrollView:GetComponent(typeof(EnhanceDynamicSizeListView))
	if listView ~= nil then
		listView.onGetCellView:AddListener(handler(self, self.OnGetCellView))
		listView.onCellViewVisiable:AddListener(self.OnCellViewVisiable)
		controls.listView = listView
	end
	
	local scrollerChat = scrollView:GetComponent(typeof(EnhancedScroller))
	if scrollerChat ~= nil then controls.scrollerChat = scrollerChat end
	
	controls.chatToggleGroup = controls.listView:GetComponent(typeof(ToggleGroup))
	controls.scrollerChat.scrollerScrollingChanged = handler(self, self.MessageListViewScrollingChanged)
	
	controls.rectChat = scrollView:GetComponent(typeof(UnityEngine.UI.ScrollRect))
	
	-- 输入框
	controls.m_ChatInputField = self.Controls.ChatInputField:GetComponent(typeof(InputField))
	
	-- 富文本样式
	controls.richTextTemplate = controls.listView.CellViewPrefab.
	transform:Find("OtherCell/Grid/Content/TextMsgBG/Content_BG_Black/Content_HyperText"):GetComponent(typeof(Text))
	controls.richTextTemplate_Sys = controls.listView.CellViewPrefab.
	transform:Find("SysTemCell/Content_BG_White/Content_HyperText"):GetComponent(typeof(Text))
	
	--self.Controls.m_VoiceTog.onValueChanged:AddListener(function(on) self:OnVoiceToggleClick(on) end)
	
	--self.m_TimeHanderJump = function() self:OnTimerJump() end
	
	-- self:Reload()
	
    return self
end

--function LinkmanChatView:OnVoiceToggleClick(on)
	--print("LinkmanChatView:OnVoiceToggleClick(".. on ..")")
	-- local Channel = UIManager.ChatWindow:GetCurShowChannel()
	--UIManager.MainMidBottomWindow.MainChatWidget:SetVoiceAutoPlayByChannel(on,0)
--end

function LinkmanChatView:SetCurLinkmanData(data)
	--print("LinkmanChatView:SetCurLinkmanData(".. data.m_pdbid ..")")
	if data ~= nil then
		self.m_CurLinkman = data
		self:Reload()
	end
end

function LinkmanChatView:SubscribeEvts()
	--print("LinkmanChatView:SubscribeEvts")
	self.m_RequestToChatCallBack = handler(self, self.OnRequestToChat)
	self.m_ChatMsgCallBack = handler(self, self.MsgArrived)
	rktEventEngine.SubscribeExecute(EVENT_FRIEND_REQUESTCHAT, SOURCE_TYPE_FRIEND, 0, self.m_RequestToChatCallBack)
	rktEventEngine.SubscribeExecute(EVENT_FRIEND_CHATMSGARRIVED, SOURCE_TYPE_FRIEND, 0, self.m_ChatMsgCallBack)
end

function LinkmanChatView:UnSubscribeEvts()
	rktEventEngine.UnSubscribeVote(EVENT_FRIEND_REQUESTCHAT , SOURCE_TYPE_FRIEND, 0, self.m_RequestToChatCallBack)
	rktEventEngine.UnSubscribeVote(EVENT_FRIEND_CHATMSGARRIVED , SOURCE_TYPE_FRIEND, 0, self.m_ChatMsgCallBack)
end
------------------------------------------------------------

-- 按钮方法
------------------------------------------------------------
-- 点击Microphone按钮
function LinkmanChatView:OnMicrophoneBtnClick()
	--print("LinkmanChatView:OnMicrophoneBtnClick")
	self.Controls.KeyBoardGrid.gameObject:SetActive(false)
	self.Controls.VoiceGrid.gameObject:SetActive(true)
end

-- 点击Keyboard按钮
function LinkmanChatView:OnKeyboardBtnClick()
	self.Controls.KeyBoardGrid.gameObject:SetActive(true)
	self.Controls.VoiceGrid.gameObject:SetActive(false)
end

-- 点击Emoji按钮
function LinkmanChatView:OnEmojiButtonClick()
	UIManager.RichTextWindow:ShowOrHide(self)-- 调富文本窗口
end

-- 点击History按钮
function LinkmanChatView:OnHistoryButtonClick()
	UIManager.ChatHistoryWindow:ShowOrHide()
	UIManager.ChatHistoryWindow:SetClickCallback(handler(self, self.SetInputText)) 
end

-- 点击Send按钮(发送文字消息)
function LinkmanChatView:OnSendButtonClick()
	--print("LinkmanChatView:OnSendButtonClick(".. self.m_CurLinkman.m_pdbid ..")")
	local ChatInputFieldText = self.Controls.ChatInputField:GetComponent(typeof(InputField)).text

	local MsgText = ChatInputFieldText
	
	-- 富文本
	local RichMapCnt = self:GetRichMapCnt()
	--print("OnSendButtonClick.RichMapCnt = "..RichMapCnt)
	if RichMapCnt > 0 then
		-- 字符替换，例如<屠龙刀>=<prop123>，<微笑>=<#Smile>，前者在聊天框显示，后者发给Server
		--PrintTable(self.m_RichMsgMap)
		for KeyStr,RichStr in pairs(self.m_RichMsgMap) do
			MsgText = string.gsub( MsgText , KeyStr , RichStr )
		end
	elseif RichMapCnt == 0 then
		MsgText = ChatInputFieldText
	end
	--print("发给服务器的聊天内容："..MsgText)
	
	--私聊频道
	if nil == MsgText or "" == MsgText or nil == self.m_CurLinkman then
		return
	end
	IGame.FriendClient:OnRequestSendChatMsg(self.m_CurLinkman.m_pdbid, MsgText)
	
	--插入历史
	UIManager.ChatHistoryWindow:InsertMsg(ChatInputFieldText)
	
	--刷新
	self.Controls.ChatInputField:GetComponent(typeof(InputField)).text = ""
	self.m_RichMsgMap = {}
	UIManager.RichTextWindow:Hide()
	UIManager.ChatHistoryWindow:Hide()
end

-- 发送语音消息
function LinkmanChatView:SendVoiceChatMessage(recordData)
	local text = recordData.speech
	local wVoiceLen = recordData.time or 0
	local szUrlText = recordData.url or ""
	
	-- 检查内容不是空字符串
	if text == nil or text == "" then		
		uerror("字符串为空！your text is wrong!  text = "..text)
		return
	end
	
	local chatText,FunText = RichTextHelp.AsysSerText(text,50)
	chatText = string.gsub(chatText, "<color=#FF0000>", "")
	chatText = string.gsub(chatText, "</color>", "")
	-- 检查消息长度
	local len = utf8.len(chatText)
	if len > MAX_CHAT_VOICE_MSG_LENGTH then
		uerror("你的消息过长！text is too long!")
		return
	end
	
	local msg = {}
	--msg.wVoiceLen = wVoiceLen
	if wVoiceLen ~= 0 then
		local TextTable = {}
		TextTable.szUrlText = szUrlText
		TextTable.text		= text
		TextTable.wVoiceLen = wVoiceLen
		msg.szText			= tableToString(TextTable)
	else
		msg.szText 			= text
	end
	IGame.FriendClient:OnRequestSendChatMsg(self.m_CurLinkman.m_pdbid, msg.szText)
end
------------------------------------------------------------

-- 录音回调
------------------------------------------------------------
function LinkmanChatView:OnKeyboardBtnDownClick(eventData)
	IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "点下录音按钮")
	UIManager.SpeechNoticeWindow:Show(true)
	UIManager.SpeechNoticeWindow:SetCallBackFunc(self.SendVoiceChatMessage)
	UIManager.SpeechNoticeWindow:OnBtnDownClick(eventData)
end

function LinkmanChatView:OnKeyboardBtnUpClick(eventData)
	UIManager.SpeechNoticeWindow:OnBtnUpClick(eventData)
end

function LinkmanChatView:OnKeyboardBtnDragClick(eventData)
	UIManager.SpeechNoticeWindow:OnBtnDragClick(eventData)
end
------------------------------------------------------------

-- 输入表情
------------------------------------------------------------
function LinkmanChatView:CheckCanInput()
	local ChatInputFieldText = self.Controls.ChatInputField:GetComponent(typeof(InputField)).text
	
	if string.len(ChatInputFieldText) > MAX_CHAT_MSG_CNT then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "文字输入已达上限！不能继续输入！")
		return false
	else
		return true
	end
end

-- 表情输入后回调这个方法
function LinkmanChatView:InsertInputText(txt)
	if not txt and not self:CheckCanInput() then
		return
	end
	local ChatInputFieldText = self.Controls.ChatInputField:GetComponent(typeof(InputField)).text or ""
	self.Controls.ChatInputField:GetComponent(typeof(InputField)).text = ChatInputFieldText..txt
end

function LinkmanChatView:SetInputText(txt)
	if not txt and not self:CheckCanInput() then
		return
	end
	self.Controls.ChatInputField:GetComponent(typeof(InputField)).text = txt
end
------------------------------------------------------------

-- 插入富文本（通过对字符释义，显示一个表情或者"<道具>"支持点击显示物品信息,，外部调用一次插入一个富文本）
------------------------------------------------------------
function LinkmanChatView:GetRichMapCnt()
	return table_count(self.m_RichMsgMap)
end

-- 富文本界面调用了这个方法，ShowText是表的key，RichText是表的value用于发给Sever识别和客户端解析
function LinkmanChatView:InsertRichText(ShowText,RichText,CanRepeatFlg)
	if not ShowText and not RichText and not self:CheckCanInput() then
		return
	end
	--print("ShowText = "..ShowText)
	--print("RichText = "..RichText)
	--print("CanRepeatFlg = "..tostring(CanRepeatFlg))
	
	local RichMapCnt = self:GetRichMapCnt()
	--print("RichMapCnt = "..RichMapCnt)
	if RichMapCnt < self.m_MaxRichNum then
		-- ?
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
		-- 存储在表m_RichMsgMap
		self.m_RichMsgMap["<"..ShowText..">"] = RichText
	else
		-- 不能输入或者对应key不存在
		if not CanRepeatFlg or (CanRepeatFlg and self.m_RichMsgMap["<"..ShowText..">"] == nil) then
				IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "单条消息物品展示已达上限！不能继续添加！")
			return
		end
	end
	--PrintTable(self.m_RichMsgMap)
	local ChatInputFieldText = self.Controls.ChatInputField:GetComponent(typeof(InputField)).text or ""
	self.Controls.ChatInputField:GetComponent(typeof(InputField)).text = ChatInputFieldText.."<"..ShowText..">"
end
------------------------------------------------------------

-- 消息处理
------------------------------------------------------------
-- 消息返回
function LinkmanChatView:MsgArrived(event, srctype, srcid, nLinkman_id)
	--print("LinkmanChatView:MsgArrived("..nLinkman_id..")")
	if not self.m_CurLinkman then
		print("<color=white>table filed[self.m_CurLinkman] has not inited! make be func<self:SetCurLinkmanData()>has not called！</color>")
		return
	end
	if self.m_CurLinkman.m_pdbid == nLinkman_id then
		self:RefreshMsgContainer()
	else
		self:RedDotShowOrHide(nLinkman_id,true)
	end
end

-- 刷新红点
function LinkmanChatView:RedDotShowOrHide(nLinkman_id,State)
	--print("LinkmanChatView:RedDotShowOrHide("..nLinkman_id..").State="..tostring(State))
	if not isTableEmpty(UIManager.FriendEmailWindow.m_TabWidgets) then
		local m_LinkmanCeil = UIManager.FriendEmailWindow.m_TabWidgets[1]:GetCell(nLinkman_id)
		if m_LinkmanCeil ~= nil then
			m_LinkmanCeil:ShowOrHideRedDot(State)
		else
			uerror("LinkmanChatView try to get cell fail!")
		end
	end
end
------------------------------------------------------------

-- Cell和ScrollView通用方法
--------------------------------------------------------------------------------
-- EnhancedListView 一行可见时的回调
function LinkmanChatView:OnCellViewVisiable( goCell ) 
	if nil ~= goCell then
		local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
		self:RefreshCellItems( listcell )
	end
end

-- EnhancedListView 一行被“创建”时的回调
function LinkmanChatView:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView )
	self:CreateCellItems(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function LinkmanChatView:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- 设置最大行数
function LinkmanChatView:SetCellCnt(CellCount)
	self.Controls.listView:SetCellCount( CellCount , true )
end

-- 创建滴答格子
function LinkmanChatView:CreateCellItems( listcell )
	local item = self.m_ChatItemCellLua:new({})
	item:Attach(listcell.gameObject)
	self:RefreshCellItems(listcell)
end
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--- 刷新格子内容
function LinkmanChatView:RefreshCellItems( listcell )
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	local item = behav.LuaObject
	if item == nil then
		uerror("FriendMessageWidget:RefreshCellItems item为空")
		return
	end
	if nil ~= item and item.windowName == "ChatItemCell" then
		local playerID = self.m_CurLinkman.m_pdbid
		local ChatInfo = IGame.FriendClient:GetOneChatInfo(playerID, listcell.dataIndex + 1)
		if not ChatInfo then
			return
		end
		local richText = item:GetRichText(ChatInfo)
		if nil == richText then
			uerror("【ChatMessageWidget】RefreshCellItems ：Cell can not fetch richText ："..tostring(listcell.dataIndex + 1) 
			.. "and playerID = "..tostring(playerID))
			return
		end
		local fitter = richText:GetComponent(typeof(ContentSizeFitter))
		local richRect = richText:GetComponent(typeof(RectTransform))
		
		if fitter ~= nil then
			if ChatInfo.maxHeight == nil or ChatInfo.szSenderName == nil then
				--print("chat info is not visualized!")
				IGame.FriendClient:SetVisualData(playerID, ChatInfo)
			end
			if ChatInfo.chatCellHeight <= ChatInfo.maxHeight then	-- 
				if ChatInfo.wVoiceLen and ChatInfo.wVoiceLen ~= 0 then -- 语音消息
					fitter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained -- Unconstrained
					richRect.sizeDelta =  Vector2.New(TextMaxLength,ChatInfo.chatCellHeight)
				else
					fitter.horizontalFit = ContentSizeFitter.FitMode.PreferredSize -- PreferredSize
					richRect.sizeDelta =  Vector2.New(ChatInfo.chatCellWidth,ChatInfo.chatCellHeight)
				end
			else
				fitter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained -- Unconstrained
				richRect.sizeDelta =  Vector2.New(ChatInfo.chatCellWidth,ChatInfo.chatCellHeight)
			end
		end
		
		if ChatInfo == nil then
			item:SetContentText("")
			return
		end
		item:SetCellData(ChatInfo)
		item:SetChatSeq(listcell.dataIndex + 1)
	end
end
--------------------------------------------------------------------------------

-- 聊天窗口
--------------------------------------------------------------------------------
function LinkmanChatView:CalcChatCellHeight( msgList )
	if nil == msgList then
		return
	end
	local template = self.Controls.richTextTemplate
	if nil == template then
		return
	end

	for i , v in ipairs(msgList) do
		self:Chat_CalcChatTextHeight(template,msgList[i])		-- 计算文本大小
		--print("高度 ",v.chatCellHeight,"ab",(v.chatCellHeight + NameTextHigh + CellSpace + CellGapY))
		-- 设置Cell的高度
		--print(debug.traceback("<color=white>v.timeHeight = "..v.timeHeight..",v.alignment = "..tostring(v.alignment).."</color>"))
--[[		if v.alignment then
			if i-2 >= 0 then
				if v.wVoiceLen and v.wVoiceLen ~= 0  then
					--self.Controls.listView:SetCellHeight( v.chatCellHeight + v.timeHeight + 15 + NameTextHigh + CellSpace + CellGapY + voiceHeight , i - 2 )
					self.Controls.listView:SetCellHeight( v.chatCellHeight + v.timeHeight + NameTextHigh + CellSpace + CellGapY + voiceHeight , i - 1 )
				else
					--self.Controls.listView:SetCellHeight( v.chatCellHeight + v.timeHeight + 15 + NameTextHigh + CellSpace + CellGapY , i - 2 )
					self.Controls.listView:SetCellHeight( v.chatCellHeight + v.timeHeight + NameTextHigh + CellSpace + CellGapY , i - 1 )
				end
			end
		else--]]
			if v.wVoiceLen and v.wVoiceLen ~= 0  then
				--if i-2 >= 0 and v.timeHeight > 0 then
					--self.Controls.listView:SetCellHeight( v.chatCellHeight + v.timeHeight + NameTextHigh + CellSpace + CellGapY + voiceHeight , i - 2 )
				--end
				self.Controls.listView:SetCellHeight( v.chatCellHeight + v.timeHeight + NameTextHigh + CellSpace + CellGapY + voiceHeight , i - 1 )
			else
				--[[if i-2 >= 0 and v.timeHeight > 0 then
					self.Controls.listView:SetCellHeight( v.chatCellHeight + v.timeHeight + NameTextHigh + CellSpace + CellGapY , i - 2 )
				end
				if i-2 >= 0 and v.timeHeight <= 0 then
					if msgList[i-1] and msgList[i-1].timeHeight > 0 then
						self.Controls.listView:SetCellHeight( v.chatCellHeight + v.timeHeight - 5 + NameTextHigh + CellSpace + CellGapY , i - 2 )
					end
				end--]]
				self.Controls.listView:SetCellHeight( v.chatCellHeight + v.timeHeight + NameTextHigh + CellSpace + CellGapY , i - 1 )
			end
--		end
	end
end

-- 计算文本的矩形大小
function LinkmanChatView:Chat_CalcChatTextHeight(TextComponent,msgTable)
	if not msgTable.timeHeight then
		msgTable.timeHeight = GetValuable(IsNilOrEmpty(msgTable.szTime), 0, 80)
	end
	if nil ~= msgTable.chatCellHeight then
		return
	end
	local Content = ""
	if msgTable.wVoiceLen and msgTable.wVoiceLen ~= 0  then
		local TextTable = stringToTable(msgTable.szText)
		Content = tostring(TextTable.text)
	else
		Content = tostring(msgTable.szText)
	end
	local Rect = rkt.UIAndTextHelpTools.GetRichTextSize(TextComponent,Content)
	msgTable.chatCellHeight = Rect.y
	msgTable.chatCellWidth  = Rect.x
end

-- 刷新聊天窗口
function LinkmanChatView:RefreshMsgContainer()
	--print("LinkmanChatView:RefreshMsgContainer+"..self.m_CurLinkman.m_pdbid)
	
	if not self:isShow() then
		return
	end

	local m_LinkmanIdx = self.m_CurLinkman.m_pdbid
	
	local msgList = IGame.FriendClient:GetChatMsg(m_LinkmanIdx)	
	local PlayerMsgCnt = #msgList
	self.m_Refreshed = true
	--print("LinkmanChatView:RefreshMsgContainer+PlayerMsgCnt="..PlayerMsgCnt)
	
	self.Controls.listView:SetCellCount( PlayerMsgCnt , true )
	self:CalcChatCellHeight(msgList)
	
	self.Controls.scrollerChat:Resize(true)
	self:JumpToBottom(true, PlayerMsgCnt)
end

function LinkmanChatView:BubbleShowOrHide(State)
	if State then
		--self.Controls.Bubble.gameObject:SetActive(true)
	else
		self.Controls.Bubble.gameObject:SetActive(false)
	end
end

function LinkmanChatView:MessageListViewScrollingChanged( scroller , scrolling )
	local verticalNormalizedPosition = self.Controls.rectChat.verticalNormalizedPosition
	if verticalNormalizedPosition <= 0 then
		--隐藏新信息到达
		self:BubbleShowOrHide(false)
	end
end

-- 跳转到聊天框底部
function LinkmanChatView:JumpToBottom(needReload, PlayerMsgCnt)
	local verticalNormalizedPosition = self.Controls.rectChat.verticalNormalizedPosition	
	
	local chatCellListHight = self.Controls.m_ChatCellList:GetComponent(typeof(RectTransform)).rect.height	-- 聊天框高度
	local contentHight = self.Controls.rectChat.content.rect.height		-- 信息内容高度
	
	if contentHight >= chatCellListHight then
		if needReload then
			if verticalNormalizedPosition <= 0.1 then
				self.Controls.scrollerChat:JumpToDataIndex( 
				PlayerMsgCnt-1 , 0 , 0 , true , 
				EnhancedScroller.TweenType.immediate , 0.2 , 
				function() self.Controls.scrollerChat:Resize(false) end)
				needReload = false	
			else
				--显示新信息到达
				self:BubbleShowOrHide(true)
			end
		else
			self.Controls.scrollerChat:JumpToDataIndex(
			PlayerMsgCnt-1 , 0 , 0 , true , 
			EnhancedScroller.TweenType.linear , 0.02, 
			function() self.Controls.scrollerChat:Resize(false) end )
		end
	end
	
	if needReload then self.Controls.scrollerChat:Resize(true) end
end

function LinkmanChatView:OnTimerJump()
	--print("LinkmanChatView:OnTimerJump")
	--rktTimer.KillTimer( self.m_TimeHanderJump )
	--IGame.FriendClient:UpdateNativeHistory(playerID)
	
	if not self:isShow() then
		return
	end
	local playerID = self.m_CurLinkman.m_pdbid
	
	local PlayerMsgCnt =  #IGame.FriendClient:GetChatMsg(playerID)
	local chatCellListHight = self.Controls.m_ChatCellList.rect.height	-- 聊天框高度
	local contentHight = self.Controls.rectChat.content.rect.height		-- 信息内容高度
	if contentHight >= chatCellListHight then
		if self.verticalNormalizedPosition <= 0.3 then
			self.Controls.scrollerChat:JumpToDataIndex( 
			PlayerMsgCnt-1 , 0 , 0 , true , 
			EnhancedScroller.TweenType.immediate , 0.2 , nil)
		else
			--显示新信息到达
			self:BubbleShowOrHide(true)
		end
	end
end
--------------------------------------------------------------------------------

-- 初始化和重载人
--------------------------------------------------------------------------------
-- 开始和某人聊天
function LinkmanChatView:RequestToChat(playerID)
	--print("LinkmanChatView:RequestToChat+"..playerID)
	local playerInfo = IGame.FriendClient:GetPlayerInfo(playerID)
	if playerInfo then
		self.Controls.m_TalkWithLabel.text = "与"..playerInfo.m_name
	end
	
	-- 获得聊天状态
	if IGame.FriendClient.m_chatFlag[playerID] == nil then
		--print("LinkmanChatView:OnRequestToChat+"..playerID)
		IGame.FriendClient:OnRequestToChat(playerID)
		return
	end
	
	self:RefreshChatUI(playerID)
end

function LinkmanChatView:OnRequestToChat(event, srctype, srcid, playerID)
	--print("LinkmanChatView:OnRequestToChat+"..playerID)
	self:RefreshChatUI(playerID)
end

function LinkmanChatView:RefreshChatUI(playerID)
	--print("LinkmanChatView:RefreshChatUI+"..playerID)
	if self.m_Refreshed then
		self.m_Refreshed = false
		return
	end
	IGame.FriendClient:UpdateNativeHistory(playerID)
	
	if not self:isShow() then
		return
	end
	local msgList = IGame.FriendClient:GetChatMsg(playerID)
	local PlayerMsgCnt = #msgList
	--print("<color=yellow>PlayerMsgCnt = "..PlayerMsgCnt.."</color>")
	
	self.Controls.listView:SetCellCount( PlayerMsgCnt , false )
	self:CalcChatCellHeight(msgList)
	
	self.Controls.scrollerChat:ReloadData()
	--self.Controls.scrollerChat:RefreshActiveCellViews()
	self.Controls.scrollerChat:Resize(true)
	
	self:JumpToBottom(false, PlayerMsgCnt)
end

-- 载入和某玩家的聊天界面
function LinkmanChatView:Reload()
	local m_LinkmanIdx = self.m_CurLinkman.m_pdbid
	--print( debug.traceback("LinkmanChatView:Reload") )

	if not self.Controls.m_ChatInputField then
		self.Controls.m_ChatInputField = self.Controls.ChatInputField:GetComponent(typeof(InputField))
	end
	self.Controls.m_ChatInputField.enabled = true
	if not self.Controls.rectChat then
		self.Controls.rectChat = self.Controls.m_ChatCellList:GetComponent(typeof(UnityEngine.UI.ScrollRect))
	end
	self.Controls.rectChat.verticalNormalizedPosition = 0
	
	--self.Controls.m_VoiceTog.gameObject:SetActive(true)
	self.Controls.m_ChatCellList.gameObject:SetActive(true)
	
	if not self.m_RequestToChatCallBack then
		uerror("LinkmanChatView:Not init SubscribeEvts!")
		self:SubscribeEvts()
	end

	self:RequestToChat(m_LinkmanIdx)
end

-- 清空聊天记录
function LinkmanChatView:ClearChatMsg()
	if not self.m_CurLinkman then
		return
	end
	
	local confirmDelegation = function ()
		IGame.FriendClient:ClearChatMsg(self.m_CurLinkman.m_pdbid)
		self:RefreshChatUI(self.m_CurLinkman.m_pdbid)
	end
	local data = 
	{
		content = "是否要清空和<color=#597993>"..self.m_CurLinkman.m_name.."</color>的聊天记录？",
		confirmBtnTxt = "清空",
		cancelBtnTxt = "取消",
		confirmCallBack = confirmDelegation
	}
	UIManager.ConfirmPopWindow:ShowDiglog(data)
end
--------------------------------------------------------------------------------

return this