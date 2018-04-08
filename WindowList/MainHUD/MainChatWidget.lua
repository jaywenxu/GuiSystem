------------------------------------------------------------
-- MainMidBottomWindow 的子窗口,不要通过 UIManager 访问
-- LWClient/LuaScript/Lua/GuiSystem/WindowList/MainHUD/MainChatWidget.lua
-- 频道切换Toggle窗口
------------------------------------------------------------
--uerror("--------MainChatWidget-------------")
local MainChatItemCellClass = require( "GuiSystem.WindowList.MainHUD.MainChatItemCell" )

MainChatWidgetMsgMax	= 20
-- 主界面聊天信息小窗口新消息在最上头还是在最下头
MAIN_CHAT_WIDGET_NEW_MSG_UP		= 1  -- 0:下头  1:上头

local MainChatWidget = UIControl:new
{
	windowName = "MainChatWidget",
	m_ChatMsgTable = {},
	m_VoiceAutoPlaySetting	= {
		{Channel = ChatChannel_Team,	Flg = true},	-- 队伍频道
		{Channel = ChatChannel_Tribe,	Flg = true},	-- 帮会频道
		{Channel = ChatChannel_World,	Flg = false},	-- 世界频道
		{Channel = ChatChannel_Current,	Flg = false},	-- 附近频道
	},
	m_MainHUDShowSetting	= {
		{Channel = ChatChannel_World,	Flg = true},	-- 世界频道
		{Channel = ChatChannel_Team,	Flg = true},	-- 队伍频道
		{Channel = ChatChannel_Tribe,	Flg = true},	-- 帮会频道
		{Channel = ChatChannel_Current,	Flg = true},	-- 附近频道
		{Channel = ChatChannel_System,	Flg = true},	-- 系统频道
	},
	m_AutoPlayVoiceMsgList = {},
	m_PlayingFlg = 0,	-- 播放列表 0：没有播放  1：正在播放
}

local ChannelName = {
	[ChatChannel_World] 	= "#505",
	[ChatChannel_Tribe]		= "#502",
	[ChatChannel_Team]		= "#501",
	[ChatChannel_System]	= "#503",
	[ChatChannel_Current]	= "#504",
	[1000]					= "#506",
}
local this = MainChatWidget   -- 方便书写

function MainChatWidget:Init()
	self.m_ChatMsgTable = {}
	self.m_AutoPlayVoiceMsgList = {}
	self.m_PlayingFlg = 0
end

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function MainChatWidget:Attach( obj )
	UIControl.Attach(self,obj)
	self:InitVoiceAutoPlay()
	-- Cell 事件
	self.Controls.listViewChat = self.Controls.chatCellList:GetComponent(typeof(EnhancedListView))
	self.callback_OnGetCellView = function(goCell) self:OnGetCellView(goCell) end
	self.Controls.listViewChat.onGetCellView:AddListener(self.callback_OnGetCellView)
	self.callback_OnCellViewVisiable = function(goCell) self:OnCellViewVisiable(goCell) end
	self.Controls.listViewChat.onCellViewVisiable:AddListener(self.callback_OnCellViewVisiable)
	
	self.Controls.scrollerChat = self.Controls.chatCellList:GetComponent(typeof(EnhancedScroller))
	self.Controls.ChatToggleGroup = self.Controls.chatCellList:GetComponent(typeof(ToggleGroup))
	
	self.Controls.rectChat = self.Controls.chatCellList:GetComponent(typeof(UnityEngine.UI.ScrollRect))
	self.Controls.richTextTemplate = self.Controls.listViewChat.CellViewPrefab.transform:GetComponent(typeof(Text))
	
	--点击展开按钮
	self.calbackMainChatWinButton1 = function() self:OnMainChatWinButton1Click() end
    self.Controls.m_MainChatWinButton1.onClick:AddListener(self.calbackMainChatWinButton1)
	self.Controls.m_MainChatWinButton1.gameObject:SetActive(true)
	
	--点击收缩按钮
	self.calbackMainChatWinButton2 = function() self:OnMainChatWinButton2Click() end
    self.Controls.m_MainChatWinButton2.onClick:AddListener(self.calbackMainChatWinButton2)
	self.Controls.m_MainChatWinButton2.gameObject:SetActive(false)
	self:OnMainChatWinButton2Click()
	return self
end

------------------------------------------------------------
function MainChatWidget:OnDestroy()
	UIControl.OnDestroy(self)
end

function MainChatWidget:InitVoiceAutoPlay()
	local DataStr = PlayerPrefs.GetString("ChatSettingData")
	if DataStr == nil or DataStr == "" then
		return
	end
	local ChatSettingInfo = split_string(DataStr,"&&")
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end
	if pHero:GetName() ~= ChatSettingInfo[1] then
		return
	end
    -- 聊天配置
    local tPrefs = stringToTable(ChatSettingInfo[2])
    if tPrefs ~= nil and table_count(tPrefs) == table_count(self.m_MainHUDShowSetting) then
        local is_same = true
        for i, j in pairs(tPrefs) do
            local is_exist = false
            for k,v in pairs(self.m_MainHUDShowSetting) do
                if j.Channel == v.Channel then
                    is_exist = true
                    break
                end
            end
            if is_exist == false then
                uerror(0,"聊天频道枚举顺序有变动，不从ChatSettingData里面取")
                is_same = false
                break
            end
        end
        if is_same == true then
            self.m_MainHUDShowSetting = tPrefs
        end
    end
    
	self.m_VoiceAutoPlaySetting = stringToTable(ChatSettingInfo[3])
end

--------------------------------------------------------------------------------
-- 设置最大行数
function MainChatWidget:SetCellCnt(CellCount)
	self.Controls.listViewChat:SetCellCount( CellCount , true )
end

--------------------------------------------------------------------------------
-- 创建滴答格子
function MainChatWidget:CreateCellItems( listcell )
	local item = MainChatItemCellClass:new({})
	item:Attach(listcell.gameObject)
	self:RefreshCellItems(listcell)
end

--------------------------------------------------------------------------------
--- 刷新物品格子内容
function MainChatWidget:RefreshCellItems( listcell )
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	local item = behav.LuaObject
	if item == nil then
		uerror("MainChatWidget:RefreshCellItems item为空")
		return
	end
	if nil ~= item and item.windowName == "MainChatItemCell" then
		local index = listcell.dataIndex + 1
		local text,FunText,color = self:BuildShowText(index)
		if text == nil then
			item:SetContentText("")
			return
		end
		item:SetContentText(text)
		item:SetPlayerDBID(self:GetDBID(index))
		item:SetFunText(FunText)
		--item:SetFunTextColor(color)
	end
end

--------------------------------------------------------------------------------
-- EnhancedListView 一行可见时的回调
function MainChatWidget:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end

--------------------------------------------------------------------------------
-- EnhancedListView 一行被“创建”时的回调
function MainChatWidget:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView)
	self:CreateCellItems(listcell)
end

--------------------------------------------------------------------------------
-- EnhancedListView 一行强制刷新时的回调
function MainChatWidget:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

function MainChatWidget:ReloadMsgContainer()
	local Channel = UIManager.ChatWindow:GetCurShowChannel()
	local ChannelMsgCnt = table.getn(self.m_ChatMsgTable)
	self.Controls.listViewChat:SetCellCount( ChannelMsgCnt , true )
	local chatCellListHight = self.Controls.chatCellList.rect.height	-- 聊天框高度
	local contentHight = self.Controls.rectChat.content.rect.height		-- 信息内容高度
	if contentHight >= chatCellListHight then
		self.Controls.scrollerChat:JumpToDataIndex( ChannelMsgCnt-1 , 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0.2 , nil)
	end
end


function MainChatWidget:Test()
	local ChannelMsgCnt = table.getn(self.m_ChatMsgTable)
	self.Controls.scrollerChat:JumpToDataIndex( ChannelMsgCnt-1 , 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0.2 , nil)
end

function MainChatWidget:CalcChatCellHeight( msgList )
	if nil == msgList then
		return
	end
	local template = self.Controls.richTextTemplate
	if nil == template then
		return
	end
	for i , v in ipairs(msgList) do
		if nil == v.chatMainCellHeight then
			local Content = self:BuildShowText(i)
			local height = Mathf.Max(rkt.UIAndTextHelpTools.GetRichTextSize(template,Content).y,25)
			v.chatMainCellHeight = height + 6
			v.chatMainCellWidth= rkt.UIAndTextHelpTools.GetRichTextSize(template,Content).x
		end
		self.Controls.listViewChat:SetCellHeight( v.chatMainCellHeight, i - 1 )
	end
end

--------------------------------------------------------------------------------
--刷新聊天窗口
function MainChatWidget:RefreshMsgContainer()
	if not self:isLoaded() or not self:isShow() then
		return
	end
	local Channel = UIManager.ChatWindow:GetCurShowChannel()
	local ChannelMsgCnt = table.getn(self.m_ChatMsgTable)
	local verticalNormalizedPosition = self.Controls.rectChat.verticalNormalizedPosition
	self.Controls.listViewChat:SetCellCount( ChannelMsgCnt , true )
	self:CalcChatCellHeight(self.m_ChatMsgTable)
	self.Controls.scrollerChat:Resize(true)	
	self.Controls.scrollerChat:ReloadData()
	local chatCellListHight = self.Controls.chatCellList.rect.height	-- 聊天框高度
	local contentHight = self.Controls.rectChat.content.rect.height		-- 信息内容高度
	local needReload = true
	if contentHight >= chatCellListHight then
		if MAIN_CHAT_WIDGET_NEW_MSG_UP == 1 then
			if verticalNormalizedPosition-1 <= 0.1 then
				self.Controls.scrollerChat:JumpToDataIndex( 0 , 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0.2 , function() self.Controls.scrollerChat:Resize(false) end)
				--needReload = false			
			end
		else
			if verticalNormalizedPosition <= 0.1 then
				self.Controls.scrollerChat:JumpToDataIndex( ChannelMsgCnt-2 , 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0.2 , function() self.Controls.scrollerChat:Resize(false) end)
				needReload = false			
			end
		end
	end
	if needReload then
		self.Controls.scrollerChat:Resize(true)		
	end	
end


function MainChatWidget:MsgArrived(msgTable)
	if not msgTable then
		uerror("[MainChatWidget]MsgArrived msgTable 为空")
		return
	end
	if self:IsChannelShow(msgTable.byChannel) then
		if MainChatWidgetMsgMax <= table.getn(self.m_ChatMsgTable) then
			if MAIN_CHAT_WIDGET_NEW_MSG_UP == 1 then
				table.remove(self.m_ChatMsgTable,MainChatWidgetMsgMax)
			else
				table.remove(self.m_ChatMsgTable,1)
			end
		end
		if MAIN_CHAT_WIDGET_NEW_MSG_UP == 1 then
			table.insert(self.m_ChatMsgTable,1,msgTable)
		else
			table.insert(self.m_ChatMsgTable,msgTable)
		end
		self:RefreshMsgContainer()
	end
	if self:IsChannelPlay(msgTable.byChannel) and msgTable.wVoiceLen and msgTable.wVoiceLen > 0 then
		self:AddVoiceMsg(msgTable)
	end
end


function MainChatWidget:AddVoiceMsg(msgTable)
	if self.m_PlayingFlg == 1 then  -- 正在播放
		table.insert(self.m_AutoPlayVoiceMsgList,msgTable)
	else
		self.m_PlayingFlg = 1
		GameHelp.PlayRecord(self.m_fileID,function() self:callBack_PlayEnd() end)
	end
end

function MainChatWidget:callBack_PlayEnd()
	if table.getn(self.m_AutoPlayVoiceMsgList) == 0 then
		self.m_PlayingFlg = 0
	else
		if self.m_AutoPlayVoiceMsgList[1] then
			local TextTable = stringToTable(v.szText)
			local url = tostring(TextTable.fileID)
			GameHelp.PlayRecord(url,function() self:callBack_PlayEnd() end)
			table.remove(self.m_ChatMsgTable,1)
		else
			self.m_PlayingFlg = 0
		end
	end
end

function MainChatWidget:GetDBID(index)
	return self.m_ChatMsgTable[index].dwSenderDBID
end

function MainChatWidgetOpenView(m_PlayerDBID)
    UIManager.RoleViewWindow:SetViewInfo(m_PlayerDBID)
	local RoleViewBtnTable = {1,2,3,4,5,6,7,8,9,10,11,13,14}
	UIManager.RoleViewWindow:SetButtonLayoutTable(RoleViewBtnTable)
	UIManager.RoleViewWindow:Show(true)
end

--<herf><color=#FF0000>倚天屠龙刀</color><fun>test(string)</fun></herf>
function MainChatWidget:BuildShowText(index)
	if index == nil or self.m_ChatMsgTable[index] == nil then
		uerror("[MainChatWidget]BuildShowText 传入的index参数有误 index = ",index)
		return
	end
	local MsgInfo = self.m_ChatMsgTable[index]
	if MsgInfo.byChannel == nil then
		uerror("[MainChatWidget]BuildShowText 传入的 消息频道 为空 MsgInfo.byChannel = ",MsgInfo.byChannel)
		return
	end
	if ChannelName[MsgInfo.byChannel] == nil then
        uerror("[MainChatWidget]BuildShowText 传入的 消息频道 有误 MsgInfo.byChannel = ",MsgInfo.byChannel)
		return
	end
	local Content = ""
	if MsgInfo.wVoiceLen and MsgInfo.wVoiceLen ~= 0 then
		local TextTable = stringToTable(MsgInfo.szText)
		Content = tostring(TextTable.text)
	elseif MsgInfo.bIsRedPacket and MsgInfo.bIsRedPacket == true then
		local len = utf8.len(MsgInfo.szText)
		Content = MsgInfo.szText
		if len > 10 then
			local szShowText = utf8.sub(Content,1,11)
			Content = szShowText .. "..."
		end
	else
		Content = tostring(MsgInfo.szTextOld)	
	end
	local SenderName = ""
	local ChannelTmp = ChatChannel_System
	if MsgInfo.byChannel == ChatChannel_System then
		SenderName = ""
		if MsgInfo.dwSenderDBID == 1 then
			ChannelTmp = 1000
		end
	else
		ChannelTmp = MsgInfo.byChannel
		if MsgInfo.dwSenderDBID == 0 then
			SenderName = ""
		else
			SenderName = "<herf>["..MsgInfo.szSenderName.."]:<fun>GameHelp.PersonOpenView("..MsgInfo.dwSenderDBID..")</fun></herf>"
		end
	end
	if MsgInfo.dwSenderDBID ~= 0 and MsgInfo.dwSenderDBID ~= 1 then
		Content = GameHelp:FilterKeyWord(Content,Chat_Filter_Continuity_Number)
	end
	local chatText = ""
	local FullText_FunText = "#505<color="..Chat_Person_Name_Color..">"..SenderName.."</color><color="..Chat_Main_Channel_Color[MsgInfo.byChannel]..">"..Content.."</color>"
	local FullText_ChatText = "<color="..Chat_Person_Name_Color..">"..SenderName.."</color><color="..Chat_Main_Channel_Color[MsgInfo.byChannel]..">"..Content.."</color>"
	if MsgInfo.bIsRedPacket and MsgInfo.bIsRedPacket == true then
		local FullText_FunText = "#505<color="..Chat_Person_Name_Color..">"..SenderName.."</color>"
		local FullText_ChatText = "<color="..Chat_Person_Name_Color..">"..SenderName.."</color>"
		local chatText1,FunText,maxHeight1 = RichTextHelp.AsysSerText(FullText_FunText,50)
		local chatText2,FunText2,maxHeight2 = RichTextHelp.AsysSerText(FullText_ChatText,50)
		chatText = "<quad "..Chat_Channel_Image_Size.." emoji="..ChannelName[ChannelTmp].."/>"..chatText2.."<color=red>[红包]</color><color="..Chat_Main_Channel_Color[MsgInfo.byChannel]..">"..Content.."</color>"
		if MsgInfo.dwSenderDBID ~= 0 and MsgInfo.dwSenderDBID ~= 1 then
			--chatText = GameHelp:FilterKeyWord(chatText,Chat_Filter_Continuity_Number)
		end
		--chatText = GameHelp:FilterKeyWord(chatText,Chat_Filter_Continuity_Number)
		return chatText,FunText,Chat_Main_Channel_Color[MsgInfo.byChannel]
	end
	local chatText1,FunText,maxHeight1 = RichTextHelp.AsysSerText(FullText_FunText,50)
	local chatText2,FunText2,maxHeight2 = RichTextHelp.AsysSerText(FullText_ChatText,50)
	chatText = "<quad "..Chat_Channel_Image_Size.." emoji="..ChannelName[ChannelTmp].."/>"..chatText2
	if MsgInfo.dwSenderDBID ~= 0 and MsgInfo.dwSenderDBID ~= 1 then
		--chatText = GameHelp:FilterKeyWord(chatText,Chat_Filter_Continuity_Number)
	end
	--chatText = GameHelp:FilterKeyWord(chatText,Chat_Filter_Continuity_Number)
	return chatText,FunText,Chat_Main_Channel_Color[MsgInfo.byChannel]
end

------------------------------------------------------------
--点击首页显示开关
function MainChatWidget:SetMainHUDShowSetting(on,i)
	self.m_MainHUDShowSetting[i].Flg = on
	self:SaveData()
end

------------------------------------------------------------
--获得首页显示开关状态
function MainChatWidget:GetMainHUDShowSetting(i)
	return self.m_MainHUDShowSetting[i].Flg
end

------------------------------------------------------------
--点击自动播放语音开关
function MainChatWidget:SetVoiceAutoPlaySetting(on,i)
	self.m_VoiceAutoPlaySetting[i].Flg = on
	self:SaveData()
end

function MainChatWidget:SetVoiceAutoPlayByChannel(on, Channel)
	for i, ChannelInfo in pairs(self.m_VoiceAutoPlaySetting) do
		if ChannelInfo.Channel == Channel then
			ChannelInfo.Flg = on
			self:SaveData()
		end
	end
end
------------------------------------------------------------
--获得自动播放语音开关状态
function MainChatWidget:GetVoiceAutoPlaySetting(i)
	return self.m_VoiceAutoPlaySetting[i].Flg
end

------------------------------------------------------------
--存储聊天设置数据
function MainChatWidget:SaveData()
	local DataString = GetHero():GetName().."&&"..tostringEx(self.m_MainHUDShowSetting).."&&"..tostringEx(self.m_VoiceAutoPlaySetting)
	PlayerPrefs.SetString("ChatSettingData", DataString)
end

function MainChatWidget:OnMainChatWinButton1Click()
	self.Controls.m_MainChatWinButton1.gameObject:SetActive(false)
	self.Controls.m_MainChatWinButton2.gameObject:SetActive(true)
	local width = self.transform.sizeDelta.x
	local Hight = Chat_Main_Popo_High_Max
	local vector2 = Vector2.New(width, Hight)
	self.transform.sizeDelta = vector2
end

function MainChatWidget:OnMainChatWinButton2Click()
	self.Controls.m_MainChatWinButton1.gameObject:SetActive(true)
	self.Controls.m_MainChatWinButton2.gameObject:SetActive(false)
	local width = self.transform.sizeDelta.x
	local Hight = Chat_Main_Popo_High_Min
	local vector2 = Vector2.New(width, Hight)
	self.transform.sizeDelta = vector2
	self.Controls.scrollerChat:JumpToDataIndex( 0 , 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0.2 , function() self.Controls.scrollerChat:Resize(true) end)
end

function MainChatWidget:IsChannelShow(Channel)
	for i, ChannelInfo in pairs(self.m_MainHUDShowSetting) do
		if ChannelInfo.Channel == Channel then
			return ChannelInfo.Flg
		end
	end
	return nil
end

------------------------------------------------------------
function MainChatWidget:IsChannelPlay(Channel)
	for i, ChannelInfo in pairs(self.m_VoiceAutoPlaySetting) do
		if ChannelInfo.Channel == Channel then
			return ChannelInfo.Flg
		end
	end
	return nil
end

return this