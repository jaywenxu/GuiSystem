------------------------------------------------------------
-- ChatWindow 的子窗口,不要通过 UIManager 访问
-- 频道切换Toggle窗口
------------------------------------------------------------
local ContentSizeFitter = require("UnityEngine.UI.ContentSizeFitter")
------------------------------------------------------------
local ChatItemCellClass = require( "GuiSystem.WindowList.Chat.ChatItemCell" )

local ChatMessageWidget = UIControl:new
{
	windowName = "ChatMessageWidget",
	-- 频道选项卡列表
	ToggleList = {},
	m_NewMsgCnt = 0,
}

local this = ChatMessageWidget   		-- 方便书写
local CELL_ITEM_COUNT_IN_LINE = 1       -- 一行五个物品格子
local CELL_ROW_COUNT_IN_PAGE = 4        -- 一页有几行
local TextMaxLength = 320               -- 文本最大长度
local CellGapY = 40						-- Y轴间距 
local TextHigh = 20						-- 一行文本预留高度
local TextTopHeight = 20	
local voiceHeight = 50
local cellHeight = 120
local NameTextHigh = 50		-- 名字高度
local CellSpace = 20		-- Cell 间隔


------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function ChatMessageWidget:Attach( obj )
	UIControl.Attach(self,obj)
	
	-- Cell 事件
	self.Controls.listViewChat = self.Controls.chatCellList:GetComponent(typeof(EnhanceDynamicSizeListView))
	self.callback_OnGetCellView = function(goCell) self:OnGetCellView(goCell) end
	self.Controls.listViewChat.onGetCellView:AddListener(self.callback_OnGetCellView)
	self.callback_OnCellViewVisiable = function(goCell) self:OnCellViewVisiable(goCell) end
	self.Controls.listViewChat.onCellViewVisiable:AddListener(self.callback_OnCellViewVisiable)
	
	self.Controls.scrollerChat = self.Controls.chatCellList:GetComponent(typeof(EnhancedScroller))
	self.Controls.ChatToggleGroup = self.Controls.chatCellList:GetComponent(typeof(ToggleGroup))
	
	self.Controls.scrollerChat.scrollerScrollingChanged = ChatMessageWidget.MessageListViewScrollingChanged
	
	self.Controls.rectChat = self.Controls.chatCellList:GetComponent(typeof(UnityEngine.UI.ScrollRect))
	
	self.Controls.m_chatInputPanel = self.Controls.chatInputPanel:GetComponent(typeof(InputField))

	self.Controls.richTextTemplate = self.Controls.listViewChat.CellViewPrefab.transform:Find("OtherCell/TextMsgBG/Content_BG_Black/Content_HyperText"):GetComponent(typeof(Text))

	self.Controls.richTextTemplate_Sys = self.Controls.listViewChat.CellViewPrefab.transform:Find("SysTemCell/Content_BG_White/Content_HyperText"):GetComponent(typeof(Text))
	
	self.Controls.m_VoiceTog.onValueChanged:AddListener(function(on) self:OnVoiceToggleClick(on, i) end)
	-- m_VoiceTog
	self.m_TimeHanderJump = function() self:OnTimerJump() end
	return self
end

function ChatMessageWidget:OnVoiceToggleClick(on)
	local Channel = UIManager.ChatWindow:GetCurShowChannel()
	UIManager.MainMidBottomWindow.MainChatWidget:SetVoiceAutoPlayByChannel(on,Channel)
end

--------------------------------------------------------------------------------
function ChatMessageWidget:OnDestroy()
	UIControl.OnDestroy(self)
end

--------------------------------------------------------------------------------
-- 设置最大行数
function ChatMessageWidget:SetCellCnt(CellCount)
    if not self:isShow() then
        return
    end
    self.Controls.listViewChat:SetCellCount( CellCount , true )
end

--------------------------------------------------------------------------------
-- 创建滴答格子
function ChatMessageWidget:CreateCellItems( listcell )
	local item = ChatItemCellClass:new({})
	item:Attach(listcell.gameObject)
	self:RefreshCellItems(listcell)
end

--------------------------------------------------------------------------------
--- 刷新物品格子内容
function ChatMessageWidget:RefreshCellItems( listcell )
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	local item = behav.LuaObject
	if item == nil then
		uerror("ChatMessageWidget:RefreshCellItems item为空")
		return
	end
	if nil ~= item and item.windowName == "ChatItemCell" then
		
		local CurShowChannel = UIManager.ChatWindow:GetCurShowChannel()
		local ChatInfo = IGame.ChatClient:GetOneChatInfo(CurShowChannel,listcell.dataIndex + 1)
		local richText = item:GetRichText(ChatInfo)
		if nil == richText then
			uerror("【ChatMessageWidget】RefreshCellItems ：Cell找不到 richText ："..tostring(listcell.dataIndex + 1))
			return
		end
		local fitter = richText:GetComponent(typeof(ContentSizeFitter))
		local richRect = richText:GetComponent(typeof(RectTransform))
		
		if fitter ~= nil then
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
				richRect.sizeDelta =  Vector2.New(TextMaxLength,ChatInfo.chatCellHeight)
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
-- EnhancedListView 一行可见时的回调
function ChatMessageWidget:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end

--------------------------------------------------------------------------------
-- EnhancedListView 一行被“创建”时的回调
function ChatMessageWidget:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView )
	self:CreateCellItems(listcell)
end

--------------------------------------------------------------------------------
-- EnhancedListView 一行强制刷新时的回调
function ChatMessageWidget:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

function ChatMessageWidget.MessageListViewScrollingChanged( scroller , scrolling )
	local verticalNormalizedPosition = ChatMessageWidget.Controls.rectChat.verticalNormalizedPosition
	if verticalNormalizedPosition <= 0 then
		--隐藏新信息到达
		ChatMessageWidget:BubbleShowOrHide(false)
	end
end

function ChatMessageWidget:CalcChatCellHeight( msgList )
	if nil == msgList then
		return
	end
	local template = self.Controls.richTextTemplate
	if nil == template then
		return
	end

	for i , v in ipairs(msgList) do
		if v.byChannel == ChatChannel_System or v.dwSenderDBID == 0 or v.dwSenderDBID == 1 then -- 系统消息
			template = self.Controls.richTextTemplate_Sys
		else
			template = self.Controls.richTextTemplate
		end
		
		Chat_CalcChatTextHeight(template,msgList[i])		-- 计算文本大小
--		print("高度 ",v.chatCellHeight,"ab",(v.chatCellHeight + NameTextHigh + CellSpace + CellGapY))
		-- 设置Cell的高度
		if v.byChannel == ChatChannel_System or v.dwSenderDBID == 0 or v.dwSenderDBID == 1 then -- 系统消息
			self.Controls.listViewChat:SetCellHeight( v.chatCellHeight + CellSpace, i - 1 )
		elseif v.wVoiceLen and v.wVoiceLen ~= 0  then
			self.Controls.listViewChat:SetCellHeight( v.chatCellHeight + NameTextHigh + CellSpace + CellGapY + voiceHeight , i - 1 )
		else
			self.Controls.listViewChat:SetCellHeight( v.chatCellHeight + NameTextHigh + CellSpace + CellGapY , i - 1 )
		end
	end
end

-----------------------------------------------------------
-- 计算文本的矩形大小
function Chat_CalcChatTextHeight(TextComponent,msgTable)
	if nil ~= msgTable.chatCellHeight then
		return
	end
	local Content = ""
	if msgTable.wVoiceLen and msgTable.wVoiceLen ~= 0  then
		local TextTable = stringToTable(msgTable.szText)
		if not TextTable then
			uerror("Chat_CalcChatTextHeight TextTable is nil !")
			return
		end
		Content = tostring(TextTable.text)
	else
		Content = tostring(msgTable.szText)
	end
	local richRect = TextComponent.transform:GetComponent(typeof(RectTransform))
	--richRect.sizeDelta =  Vector2.New(TextMaxLength,0)
	local Rect = rkt.UIAndTextHelpTools.GetRichTextSize(TextComponent,Content)
	local fiter = TextComponent.transform:GetComponent(typeof(ContentSizeFitter))
	msgTable.chatCellHeight = Rect.y
	msgTable.chatCellWidth  = Rect.x
end

-----------------------------------------------------------
function ChatMessageWidget:ReloadChannel()
	--[[	if not self:isLoaded() then
		return
	end
	--]]
	local Channel = UIManager.ChatWindow:GetCurShowChannel()
	if UIManager.MainMidBottomWindow.MainChatWidget:IsChannelPlay(Channel) then
		self.Controls.m_VoiceTog.isOn = true
	else
		self.Controls.m_VoiceTog.isOn = false
	end
	if Channel == ChatChannel_System then
		self.Controls.m_SystemTips.gameObject:SetActive(true)
		self.Controls.m_VoiceTog.gameObject:SetActive(false)
		self.Controls.m_chatInputPanel.enabled = false
	else
		self.Controls.m_SystemTips.gameObject:SetActive(false)
		self.Controls.m_VoiceTog.gameObject:SetActive(true)
		self.Controls.m_chatInputPanel.enabled = true
	end
	self:BubbleShowOrHide(false)
	ChatMessageWidget.Controls.rectChat.verticalNormalizedPosition = 0
	self.Controls.clanApplyPanel.gameObject:SetActive(false)
	self.Controls.chatCellList.gameObject:SetActive(true)
	local ChannelMsgCnt = IGame.ChatClient:GetChannelMsgCnt(Channel)
	self.Controls.listViewChat:SetCellCount( ChannelMsgCnt , true )
	local msgList = IGame.ChatClient:GetChannelAllMsg(Channel)
	self:CalcChatCellHeight(msgList)	
	self.Controls.scrollerChat:ReloadData()
	DelayExecuteEx(100,function ()
				self:JumpToBottom()
			end)
end

function ChatMessageWidget:JumpToBottom()
	local Channel = UIManager.ChatWindow:GetCurShowChannel()
	local ChannelMsgCnt = IGame.ChatClient:GetChannelMsgCnt(Channel)
	local chatCellListHight = self.Controls.chatCellList.rect.height	-- 聊天框高度
	local contentHight = self.Controls.rectChat.content.rect.height		-- 信息内容高度
	if contentHight >= chatCellListHight then
		self.Controls.scrollerChat:JumpToDataIndex( ChannelMsgCnt-1 , 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0.2, function() self.Controls.scrollerChat:Resize(false) end )
	end
end

--------------------------------------------------------------------------------
--刷新聊天窗口
function ChatMessageWidget:RefreshMsgContainer()
	if not self:isShow() then
		return
	end

	local Channel = UIManager.ChatWindow:GetCurShowChannel()
	local ChannelMsgCnt = IGame.ChatClient:GetChannelMsgCnt(Channel)
	local verticalNormalizedPosition = self.Controls.rectChat.verticalNormalizedPosition
	--print("ChatMessageWidget:ReloadChannel=改Cell 个数=ChannelMsgCnt=",ChannelMsgCnt)
	self.Controls.listViewChat:SetCellCount( ChannelMsgCnt , true )
	--print("ChatMessageWidget:ReloadChannel=开始重载Cell=ChannelMsgCnt=",ChannelMsgCnt)
	local msgList = IGame.ChatClient:GetChannelAllMsg(Channel)
	self:CalcChatCellHeight(msgList)
	self.Controls.scrollerChat:Resize(true)	
	--print("ChatMessageWidget:ReloadChannel=结束重载Cell==")
	local chatCellListHight = self.Controls.chatCellList.rect.height	-- 聊天框高度
	local contentHight = self.Controls.rectChat.content.rect.height		-- 信息内容高度
	local needReload = true
	if contentHight >= chatCellListHight then
		if verticalNormalizedPosition <= 0.1 then
			self:BubbleShowOrHide(false)
			self.Controls.scrollerChat:JumpToDataIndex( ChannelMsgCnt-1 , 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0.2 , function() self.Controls.scrollerChat:Resize(false) end)
			needReload = false	
		else
			--显示新信息到达
			self.m_NewMsgCnt = self.m_NewMsgCnt + 1
			self.Controls.BubbleText.text = self.m_NewMsgCnt.."条未读消息"
			self:BubbleShowOrHide(true)
		end
	end
	if needReload then
		self.Controls.scrollerChat:Resize(true)		
	end	
end

function ChatMessageWidget:BubbleShowOrHide(State)
	if State then
		self.Controls.Bubble.gameObject:SetActive(true)
	else
		self.m_NewMsgCnt = 0
		self.Controls.Bubble.gameObject:SetActive(false)
	end
end

function ChatMessageWidget:OnTimerJump()
	print("OnTimerJump")
	rktTimer.KillTimer( self.m_TimeHanderJump )
	
	local ChannelMsgCnt = IGame.ChatClient:GetChannelMsgCnt(Channel)
	local chatCellListHight = self.Controls.chatCellList.rect.height	-- 聊天框高度
	local contentHight = self.Controls.rectChat.content.rect.height		-- 信息内容高度
	if contentHight >= chatCellListHight then
		if self.verticalNormalizedPosition <= 0.3 then
			self.Controls.scrollerChat:JumpToDataIndex( ChannelMsgCnt-1 , 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0.2 , nil)
		else
			--显示新信息到达
			self.m_NewMsgCnt = self.m_NewMsgCnt + 1
			self.Controls.BubbleText.text = self.m_NewMsgCnt.."条未读消息"
			self:BubbleShowOrHide(true)
		end
	end
	--self.Controls.scrollerChat:JumpToDataIndex( ChannelMsgCnt-1 , 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0 , nil)
end

return this