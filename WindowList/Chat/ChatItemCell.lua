-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017/02/15
-- 版  本:    1.0
-- 描  述:    滴答Cell
-------------------------------------------------------------------
require("GuiSystem.WindowList.Clan.ClanSysDef")
local ContentSizeFitter = require("UnityEngine.UI.ContentSizeFitter")

--聊天富文本协议--------------------------------------------------------
--FF0000 为颜色的rgb值比如ffffff------------
--[herf] 为关键字--------
--倚天屠龙刀为你要显示的内容若要显示为[倚天屠龙刀]则写[倚天屠龙刀]
--test为方法，string为参数当点击倚天屠龙刀时

--为此类型 <herf><color=#FF0000>倚天屠龙刀</color><fun>test(string)</fun></herf>


local ChatItemCell = UIControl:new
{
    windowName = "ChatItemCell" ,
	ChatSeq = nil,
	m_fileID = "",
	m_PlayerDBID = 0,
	m_PlayerName = "",
	FunText = {}
}

----------------------------------

--[[FunPosItem = {
	startPos = 0,
	endPos =0,
	fun = "",
}--]]

-------------------------------
local ChannelName = {
	[ChatChannel_World]		= "【世界】",
	[ChatChannel_Tribe]		= "【帮会】",
	[ChatChannel_Team]		= "【队伍】",
	[ChatChannel_System]	= "【系统】",
	[ChatChannel_Current]	= "【附近】",
}
local mName = "【聊天Cell】，"

------------------------------------------------------------
function ChatItemCell:Attach( obj )
	UIControl.Attach(self,obj)
	self.Controls.BackImageRect = self.Controls.BackGround:GetComponent(typeof(RectTransform))
	self.Controls.RichText = self.Controls.chatElementContent.transform:GetComponent(typeof(rkt.RichText))
	self.Controls.RichText_My = self.Controls.chatElementContent_My.transform:GetComponent(typeof(rkt.RichText))
	self.Controls.RichText_Sys = self.Controls.chatElementContent_S.transform:GetComponent(typeof(rkt.RichText))
	self.Controls.RichTextRect = self.Controls.chatElementContent:GetComponent(typeof(RectTransform))
	self.callback_RichTextClick = function(text,beginIndex,endIndex) self:OnBtnChatTextOnClick(text,beginIndex,endIndex,self.FunText) end
	self.Controls.RichText.onClick:AddListener(self.callback_RichTextClick)
	self.Controls.RichText_My.onClick:AddListener(self.callback_RichTextClick)
	self.Controls.RichText_Sys.onClick:AddListener(self.callback_RichTextClick)
	
	self.callback_OnVoicePlayBtnClick = function() self:OnVoicePlayBtnClick() end
	self.Controls.m_VoicePlayBtn1.onClick:AddListener(self.callback_OnVoicePlayBtnClick)
	self.Controls.m_VoicePlayBtn2.onClick:AddListener(self.callback_OnVoicePlayBtnClick)
	self.callback_OnRedPacketButtonClick = function() self:OnRedPacketButtonClick() end
	self.Controls.m_RedPacketButton.onClick:AddListener(self.callback_OnRedPacketButtonClick)
	self.Controls.m_RedPacketButton_My.onClick:AddListener(self.callback_OnRedPacketButtonClick)
	
	self.callback_OnIconBtnClick = function() self:OnIconBtnClick() end
	self.Controls.m_IconBtn.onClick:AddListener(self.callback_OnIconBtnClick)
	return self
end

------------------------------------------------------------
--点击聊天表情
function ChatItemCell:OnBtnChatTextOnClick(text,beginIndex,endIndex,FunText)
	--print("点击富文本="..tostring(FunText))
	RichTextHelp.OnClickAsysSerText(beginIndex,endIndex,FunText)
end

-- 点击语音播放
function ChatItemCell:OnVoicePlayBtnClick()
	--IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "Lua开始播放录音 ID:" .. tostring(self.m_fileID))
	GameHelp.PlayRecord(self.m_fileID)
end

-- 点击红包
function ChatItemCell:OnRedPacketButtonClick()
	cLog("点击红包")
	if self.FuncRedPacket then
		LuaEval(self.FuncRedPacket)
	end
end

function ChatItemCell:OnIconBtnClick()
	local ChatSeq = self.ChatSeq
	local PlayerDBID = self.m_PlayerDBID
    UIManager.RoleViewWindow:SetViewInfo(PlayerDBID)
	local RoleViewBtnTable = {1,2,3,4,5,6,7,8,9,10,11,13,14}
    UIManager.RoleViewWindow:SetButtonLayoutTable(RoleViewBtnTable)
	--UIManager.RoleViewWindow:Show(true)
end
------------------------------------------------------------
--设置标题
function ChatItemCell:SetTitleText(Text)
	self.Controls.m_Chat_Title.text = tostring(Text)
end

--暂时是只改变高度的
function ChatItemCell:SetImageSize(size)
	local width = self.Controls.BackImageRect.rect.width
	self.Controls.BackImageRect.sizeDelta = Vector2.New(size.y,width)
end

------------------------------------------------------------
--设置Cell数据
function ChatItemCell:SetCellData(ChatMsgInfo)
	ChatMsgInfo.szText = StringFilter.Filter( ChatMsgInfo.szText , '*' )
	--print( "<color=cyan>设置Cell数据 "..tostringEx(ChatMsgInfo).."</color>")
	self.m_PlayerDBID = ChatMsgInfo.dwSenderDBID
	self.m_PlayerName = ChatMsgInfo.szSenderName
	
	--print("富文本方法="..tostring(ChatMsgInfo.FunText))
	self.FunText = ChatMsgInfo.FunText
	if ChatMsgInfo.byChannel == ChatChannel_System or ChatMsgInfo.dwSenderDBID == 0 or ChatMsgInfo.dwSenderDBID == 1 then -- 系统消息
		self.Controls.m_OtherCell.gameObject:SetActive(false)
		self.Controls.m_SelfCell.gameObject:SetActive(false)
		self.Controls.m_SystemCell.gameObject:SetActive(true)
		local SysNamePath = ""
		
		if ChatMsgInfo.dwSenderDBID == 1 then
			SysNamePath = AssetPath.TextureGUIPath.."ChatFace/506.png"
		else
			SysNamePath = AssetPath.TextureGUIPath.."ChatFace/503.png"
		end
		UIFunction.SetImageSprite( self.Controls.m_SysName , SysNamePath )
		
		self.Controls.chatElementContent_S.text = tostring(ChatMsgInfo.szText)
		return
	end
	
	local szClanPositionStrs = ""
	if ChatMsgInfo.byChannel == ChatChannel_Tribe then
		if ChatMsgInfo.nClanIdentity and emClanIdentity_Member ~= ChatMsgInfo.nClanIdentity then
			szClanPositionStrs = "<color=blue> ["..ClanSysDef.ClanPositionStrs[ChatMsgInfo.nClanIdentity].."]</color>"  or ""
		end
	end
	
	if GetHero():GetNumProp(CREATURE_PROP_PDBID) == ChatMsgInfo.dwSenderDBID then  -- 我自己的
		self.Controls.m_OtherCell.gameObject:SetActive(false)
		self.Controls.m_SelfCell.gameObject:SetActive(true)
		self.Controls.m_SystemCell.gameObject:SetActive(false)
		self.Controls.NameText_My.text = "<color=#FF7800>"..ChatMsgInfo.szSenderName.."</color>"..szClanPositionStrs
		-- add by jx.liao 2017.8.18
		if nil ~= ChatMsgInfo.szTime then
			if ChatMsgInfo.timeHeight > 0 then
				self.Controls.m_Time_My.gameObject:SetActive(true)
				self.Controls.m_Time_My.text = ChatMsgInfo.szTime
			else
				self.Controls.m_Time_My.gameObject:SetActive(false)
			end
		end
		----------
		if ChatMsgInfo.wVoiceLen and ChatMsgInfo.wVoiceLen ~= 0 then
			self.Controls.m_TextMsgBG_My.gameObject:SetActive(false)
			self.Controls.m_VoiceMsgBG_My.gameObject:SetActive(true)
			self.Controls.m_RedPacketBG_My.gameObject:SetActive(false)
			local TextTable = stringToTable(ChatMsgInfo.szText)
			self.m_fileID = TextTable.fileID
			self.Controls.chatElementContent_My_V.text = tostring(TextTable.text)
			self.Controls.m_VoiceTime_My.text = ChatMsgInfo.wVoiceLen.." 秒"
		elseif ChatMsgInfo.bIsRedPacket and ChatMsgInfo.bIsRedPacket == true then
			self.Controls.m_TextMsgBG_My.gameObject:SetActive(false)
			self.Controls.m_VoiceMsgBG_My.gameObject:SetActive(false)
			self.Controls.m_RedPacketBG_My.gameObject:SetActive(true)
			local len = utf8.len(ChatMsgInfo.szText)
			local szShowText = ChatMsgInfo.szText
			if len > 10 then
				szShowText = utf8.sub(ChatMsgInfo.szText,1,11)
				szShowText = szShowText .. "..."
			end
			
			self.Controls.chatElementContent_My_R.text = tostring(szShowText)
			self.FuncRedPacket = ChatMsgInfo.FuncRedPacket
		else
			self.Controls.m_TextMsgBG_My.gameObject:SetActive(true)
			self.Controls.m_VoiceMsgBG_My.gameObject:SetActive(false)
			self.Controls.m_RedPacketBG_My.gameObject:SetActive(false)
			self.Controls.chatElementContent_My.text = tostring(ChatMsgInfo.szText)
		end
		UIFunction.SetHeadImage(self.Controls.PlayerHead_My,GetHero():GetNumProp(CREATURE_PROP_FACEID))
		local level = GetHero():GetNumProp(CREATURE_PROP_LEVEL)
		self.Controls.m_PlayerLevelText.text = tostring(level)
		-- add by jx.liao 2017.8.18
		if nil ~= ChatMsgInfo.m_level then
			self.Controls.m_PlayerLevelText.text = "<color=#4D6577>"..ChatMsgInfo.m_level.."</color>"
		end
		return
	end
	
	-- 别人的
	self.Controls.m_OtherCell.gameObject:SetActive(true)
	self.Controls.m_SelfCell.gameObject:SetActive(false)
	self.Controls.m_SystemCell.gameObject:SetActive(false)
	----------
	-- add by jx.liao 2017.8.9
	if ChannelName[ChatMsgInfo.byChannel] == nil then
		ChannelName[ChatMsgInfo.byChannel] = ""
	end
	
	self.Controls.NameText.text = ChannelName[ChatMsgInfo.byChannel].." <color=#3e5663>"..ChatMsgInfo.szSenderName.."</color>"..szClanPositionStrs
	
	if nil ~= ChatMsgInfo.szTime then
		if ChatMsgInfo.timeHeight > 0 then
			self.Controls.m_Time.gameObject:SetActive(true)
			self.Controls.m_Time.text = ChatMsgInfo.szTime
		else
			self.Controls.m_Time.gameObject:SetActive(false)
		end
	end
	
	if ChatMsgInfo.wVoiceLen and ChatMsgInfo.wVoiceLen ~= 0 then
		self.Controls.m_VoiceMsgBG.gameObject:SetActive(true)
		self.Controls.m_TextMsgBG.gameObject:SetActive(false)
		self.Controls.m_RedPacketBG.gameObject:SetActive(false)
		local TextTable = stringToTable(ChatMsgInfo.szText)
		self.m_fileID = TextTable.fileID
		self.Controls.chatElementContent_V.text = tostring(TextTable.text)
		self.Controls.m_VoiceTime.text = ChatMsgInfo.wVoiceLen.." 秒"	
	elseif ChatMsgInfo.bIsRedPacket and ChatMsgInfo.bIsRedPacket == true then
		self.Controls.m_VoiceMsgBG.gameObject:SetActive(false)
		self.Controls.m_TextMsgBG.gameObject:SetActive(false)
		self.Controls.m_RedPacketBG.gameObject:SetActive(true)
		local len = utf8.len(ChatMsgInfo.szText)
		local szShowText = ChatMsgInfo.szText
		if len > 10 then
			szShowText = utf8.sub(ChatMsgInfo.szText,1,11)
			szShowText = szShowText .. "..."
		end
		self.Controls.chatElementContent_R.text = tostring(szShowText)
		self.FuncRedPacket = ChatMsgInfo.FuncRedPacket
	else
		self.Controls.m_VoiceMsgBG.gameObject:SetActive(false)
		self.Controls.m_TextMsgBG.gameObject:SetActive(true)
		self.Controls.m_RedPacketBG.gameObject:SetActive(false)
		self.Controls.chatElementContent.text = tostring(ChatMsgInfo.szText)
	end
	UIFunction.SetHeadImage(self.Controls.PlayerHead,ChatMsgInfo.byFaceID)
	self.Controls.m_OtherPlayerLevelText.text = tostring(ChatMsgInfo.byLevel)
	-- add by jx.liao 2017.8.9
	if nil ~= ChatMsgInfo.m_level then
		self.Controls.m_OtherPlayerLevelText.text = "<color=#4D6577>"..ChatMsgInfo.m_level.."</color>"
	end
end

------------------------------------------------------------
-- 设置内容
function ChatItemCell:SetContentText(Text)
	local chatText = ""
	self.Controls.chatElementContent.text = tostring(Text)	
end

------------------------------------------------------------
-- 设置滴答唯一序列号
function ChatItemCell:SetChatSeq(Sequence)
	self.ChatSeq = Sequence
end

------------------------------------------------------------
function ChatItemCell:OnDestroy()
	UIControl.OnDestroy(self)
end

function ChatItemCell:OnRecycle()
	self.Controls.RichText.onClick:RemoveListener(self.callback_RichTextClick)
	self.Controls.RichText_My.onClick:RemoveListener(self.callback_RichTextClick)
	self.Controls.m_VoicePlayBtn1.onClick:RemoveListener(self.callback_OnVoicePlayBtnClick)
	self.Controls.m_VoicePlayBtn2.onClick:RemoveListener(self.callback_OnVoicePlayBtnClick)
	
	self.Controls.m_RedPacketButton.onClick:RemoveListener(self.callback_OnRedPacketButtonClick)
	self.Controls.m_RedPacketButton_My.onClick:RemoveListener(self.callback_OnRedPacketButtonClick)
	
	self.Controls.m_IconBtn.onClick:RemoveListener(self.callback_OnIconBtnClick)
end

function ChatItemCell:GetRichText(ChatInfo)
	if nil == ChatInfo then
		return
	end
	if GetHero():GetNumProp(CREATURE_PROP_PDBID) == ChatInfo.dwSenderDBID then
		if ChatInfo.wVoiceLen and ChatInfo.wVoiceLen ~= 0 then -- 语音消息
			return self.Controls.chatElementContent_My_V
		else
			return self.Controls.chatElementContent_My
		end
	end
	if ChatInfo.wVoiceLen and ChatInfo.wVoiceLen ~= 0 then -- 语音消息
		return self.Controls.chatElementContent_V
	else
		return self.Controls.chatElementContent
	end
end

function ChatItemCell:GetRichTextRect(ChatInfo)
	local richText = self:GetRichText(ChatInfo.dwSenderDBID)
	if nil ~= richText then 
		return	richText:GetComponent(typeof(RectTransform))
	end
	return nil
end

function ChatItemCell:GetContentSizeFitter(ChatInfo)
	if GetHero():GetNumProp(CREATURE_PROP_PDBID) == ChatInfo.dwSenderDBID then
		
		return self.Controls.chatElementContent_My:GetComponent(typeof(ContentSizeFitter))
	end
	return self.Controls.chatElementContent:GetComponent(typeof(ContentSizeFitter))
end


return ChatItemCell




