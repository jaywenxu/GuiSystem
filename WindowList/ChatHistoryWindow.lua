-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017/03/07
-- 版  本:    1.0
-- 描  述:    聊天历史输入窗口
-------------------------------------------------------------------

	
local ChatHistoryWindow = UIWindow:new
{
	windowName = "ChatHistoryWindow",
	m_HisType = {
		ChatWin			= 1,
		SpeakWin		= 2,
	},
	m_HistoryMsgList 	= {},
	m_CurHisType		= nil,
	m_FriendChatCallback = nil,
}


local this = ChatHistoryWindow					-- 方便书写

------------------------------------------------------------
function ChatHistoryWindow:Init()
	self.m_HistoryMsgList = {}
	self.m_FriendChatCallback = nil
end
------------------------------------------------------------
function ChatHistoryWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	
	--关闭窗口按钮
    self.Controls.m_MaskButton.onClick:AddListener(function() self:Hide() end)
	
	self.ScrollRect = self.Controls.m_ScrollRect:GetComponent(typeof(UnityEngine.UI.ScrollRect))
	for i=1,10 do
		self["ProFusionCell"..i] = self.Controls.m_Grid:Find("ProFusionCell ("..i..")")
		self["ProFusionCellText"..i] = self.Controls.m_Grid:Find("ProFusionCell ("..i..")/Text1"):GetComponent(typeof(Text))
		self["ProFusionCellBtn"..i] = self["ProFusionCell"..i]:GetComponent(typeof(Button))
		self["ProFusionCellBtn"..i].onClick:AddListener(function() self:OnClickCell(i) end)
	end
	self:InitCallbacks()
	self:SubscribeEvent()
	self:RefreshWindow()
    return self
end

------------------------------------------------------------
function ChatHistoryWindow:OnDestroy()
	self:UnsubscribeEvent()
	UIWindow.OnDestroy(self)
end

function ChatHistoryWindow:RefreshWindow()
	if not self:isLoaded() then
		return
	end
	local TypeList = self.m_HistoryMsgList[self.m_CurHisType]
	TypeList = TypeList or {}
	for i=1,10 do
		if TypeList[i] then
			self["ProFusionCellText"..i].text = TypeList[i]
			self["ProFusionCell"..i].gameObject:SetActive(true)
		else
			self["ProFusionCell"..i].gameObject:SetActive(false)
		end
	end
	self.ScrollRect.verticalNormalizedPosition = 0
end

function ChatHistoryWindow:ShowOrHide(HisType)
	self.m_CurHisType = HisType or 1
	if not self:isShow()then
		self:Show(true)
		self:RefreshWindow()
	else
		self:Hide()
		self.m_FriendChatCallback = nil
	end
end

function ChatHistoryWindow:FindMsg(ChatMsg,HisType)
	local TypeList = self.m_HistoryMsgList[HisType]
	TypeList = TypeList or {}
	for i=1,10 do
		if TypeList[i] == ChatMsg then
			return i
		end
	end
	return nil
end
function ChatHistoryWindow:InsertMsg(ChatMsg,HisType)
	HisType = HisType or 1
	local TypeList = self.m_HistoryMsgList[HisType]
	TypeList = TypeList or {}
	local Pos = self:FindMsg(ChatMsg,HisType)
	if Pos then
		table.remove(TypeList,Pos)
	end
	table.insert(TypeList,ChatMsg)
	local Cnt = table.getn(TypeList)
	if Cnt > 10 then
		for i=11,Cnt do
			table.remove(TypeList,i)
		end
	end
	self.m_HistoryMsgList[HisType] = TypeList
end

function ChatHistoryWindow:SetClickCallback(func_cb)
	self.m_FriendChatCallback = func_cb
end

function ChatHistoryWindow:OnClickCell(index)
	local TypeList = self.m_HistoryMsgList[self.m_CurHisType]
	TypeList = TypeList or {}
	if nil == self.m_FriendChatCallback then
		UIManager.ChatWindow:SetInputText(TypeList[index])
	else
		self.m_FriendChatCallback(TypeList[index])
		self.m_FriendChatCallback = nil
	end
	self:Hide()
end

-- 订阅事件
function ChatHistoryWindow:SubscribeEvent()
end

-- 取消订阅事件
function ChatHistoryWindow:UnsubscribeEvent()
end

-- 初始化全局回调函数
function ChatHistoryWindow:InitCallbacks()
end

return this







