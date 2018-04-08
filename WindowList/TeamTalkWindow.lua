--组队系统中喊话窗口
---------------------------------------------------------------
local TeamTalkWindow = UIWindow:new
{
	windowName = "TeamTalkWindow" ,
	
	m_HistoryList = {},					--喊话历史记录列表
	m_HistoryListStartIndex = 1,		--列表开始索引
	m_HistoryListEndIndex = 1,			--列表结束索引
	m_HistoryListMaxLength = 10,		--列表最大长度
	m_golsName = nil,
	m_fromLevel = nil,
	m_RichMsgMap = {},
	m_toLevel = nil,
	m_MaxRichNum = 4,
}
---------------------------------------------------------------
function TeamTalkWindow:Init()
		
end
---------------------------------------------------------------
function TeamTalkWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	
	self.callbackOnCloseButtonClick = function() self:OnCloseButtonClick() end
	self.Controls.m_CloseButton.onClick:AddListener(self.callbackOnCloseButtonClick)

	self.callbackOnTeamChannelButtonClick = function() self:OnTeamChannelButtonClick() end
	self.Controls.m_TeamChannelButton.onClick:AddListener(self.callbackOnTeamChannelButtonClick)
	
	self.callbackOnSocietyChannelButtonClick = function() self:OnSocietyChannelButtonClick() end
	self.Controls.m_SocietyChannelButton.onClick:AddListener(self.callbackOnSocietyChannelButtonClick)
	
	self.callbackOnHistoryButtonClick  = function() self:OnHistoryButtonClick() end
	self.Controls.m_HistoryButton.onClick:AddListener(self.callbackOnHistoryButtonClick)
	
	self.callbackOnDialogInputFieldValueChanged = function() self:OnDialogInputFieldValueChanged() end
	self.Controls.m_DialogInputField:GetComponent(typeof(InputField)).onValueChanged:AddListener(self.callbackOnDialogInputFieldValueChanged)
	self.Controls.m_faceBtn.onClick:AddListener(function() self:OnClickFaceBtn() end)

	self.unityBehaviour.onEnable:AddListener(function() self:OnEnable() end) 
	
	self:OnEnable()
	--self.callbackInputFieldonSubmit = function(charToValidate) self:OnSubmit(charToValidate) end
	--self.m_DialogInputField:GetComponent(typeof(InputField)).onValidateInput = self.callbackInputFieldonSubmit
	
	return self
end

function TeamTalkWindow:OnClickFaceBtn()
	UIManager.RichTextWindow:ShowOrHide(self)	-- 调富文本窗口
end
---------------------------------------------------------------
--富文本窗口调用函数
-- 插入普通文本
function TeamTalkWindow:InsertInputText(text)
	self:SortFace(text)
end


-- 插入富文本（通过对字符释义，显示一个表情或者"<道具>"支持点击显示物品信息,，外部调用一次插入一个富文本）
------------------------------------------------------------
function TeamTalkWindow:GetRichMapCnt()
	return table_count(self.m_RichMsgMap)
end

function TeamTalkWindow:InsertRichText(ShowText,RichText,CanRepeatFlg)
	if not ShowText and not RichText and not self:CheckCanInput() then
		return
	end
	local RichMapCnt = self:GetRichMapCnt(self.m_RichMsgMap)
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

	local ChatInputFieldText = self.Controls.m_DialogInputField:GetComponent(typeof(InputField)).text or ""
	self.Controls.m_DialogInputField:GetComponent(typeof(InputField)).text = ChatInputFieldText.."<"..ShowText..">"
end


-- 设置内容
function TeamTalkWindow:SetInputText(text)
	if self:CheckCanInput() == true then 
		local inputFiled = self.Controls.m_DialogInputField:GetComponent(typeof(InputField))
		inputFiled.text = text
	end
end
---------------------------------------------------------------
---------------------------------------------------------------
function TeamTalkWindow:OnDestroy()

	--self.Controls.m_CloseButton.onClick:RemoveListener(self.callbackOnCloseButtonClick)
	--self.Controls.m_TeamChannelButton.onClick:RemoveListener(self.callbackOnTeamChannelButtonClick)
	--self.Controls.m_SocietyChannelButton.onClick:RemoveListener(self.callbackOnSocietyChannelButtonClick)
	--self.Controls.m_HistoryButton.onClick:RemoveListener(self.callbackOnHistoryButtonClick)
	
	UIWindow.OnDestroy(self)
end
---------------------------------------------------------------
function TeamTalkWindow:OnCloseButtonClick() 
	UIManager.TeamTalkWindow:Hide()
	UIManager.RichTextWindow:Hide()
end
---------------------------------------------------------------
--向组队频道发送消息
function TeamTalkWindow:OnTeamChannelButtonClick() 
	local text = self.Controls.m_DialogInputField:GetComponent(typeof(InputField)).text
	if nil == text or "" == text then
		return
	end
	local MsgText = text
	local RichMapCnt = self:GetRichMapCnt()
	if RichMapCnt > 0 then
		for KeyStr,RichStr in pairs(self.m_RichMsgMap) do
			MsgText = string.gsub( MsgText , KeyStr , RichStr )
		end
	elseif RichMapCnt == 0 then
		MsgText = text
	end
		
	self.m_RichMsgMap={}

	IGame.ChatClient:sendChatMessage(ChatChannel_World, MsgText)
	UIManager.TeamTalkHistoryWindow:AddAnInfo(text)
--	self:OnCloseButtonClick() 
end


--UI初始化
function TeamTalkWindow:InitUI(golasName,fromLevel,toLevel)
	self.m_golsName =  golasName
	self.m_fromLevel = fromLevel
	self.m_toLevel = toLevel
end

function TeamTalkWindow:OnEnable()
	local inputFiled =  self.Controls.m_DialogInputField:GetComponent(typeof(InputField))
	inputFiled.text = ""
end

---------------------------------------------------------------
--向帮会频道发送消息
function TeamTalkWindow:OnSocietyChannelButtonClick() 
	local inputFiled =  self.Controls.m_DialogInputField:GetComponent(typeof(InputField))
	if nil == inputFiled then
		return 
		 
	end
	local text =inputFiled.text
	if nil == text or "" == text then
		return
	end	
	local clan = IGame.ClanClient:GetClan()
	if nil == clan then 
		IGame.ChatClient:addSystemTips(TipType_Operate,InfoPos_ActorUnder,"你还未加入帮会" )
		return
	end
	
	local MsgText = text
	local RichMapCnt = self:GetRichMapCnt()
	if RichMapCnt > 0 then
		for KeyStr,RichStr in pairs(self.m_RichMsgMap) do
			MsgText = string.gsub( MsgText , KeyStr , RichStr )
		end
	elseif RichMapCnt == 0 then
		MsgText = text
	end
		
	self.m_RichMsgMap={}

	
	UIManager.TeamTalkHistoryWindow:AddAnInfo(MsgText)
	local team = IGame.TeamClient:GetTeam()
	local teamID = team:GetTeamID()
	local funStr = string.format("IGame.TeamClient:RequestJoin(%s,%s)",teamID,1)
	
	local textSend=string.format("%s<herf><color=#10a41c> [申请入队] </color><fun>%s</fun></herf>",MsgText,funStr)
	IGame.ChatClient:sendChatMessage(ChatChannel_Tribe, textSend)
	IGame.ChatClient:addSystemTips(TipType_Operate,InfoPos_ActorUnder,"喊话消息已经发送" )
	inputFiled.text=""
	self:OnCloseButtonClick() 
end
---------------------------------------------------------------
--历史记录
function TeamTalkWindow:OnHistoryButtonClick()
	--self:PrintAllInfoFromHistoryList()
	UIManager.TeamTalkHistoryWindow:Show(true)
	if UIManager.TeamTalkHistoryWindow.transform ~= nil then
		UIManager.TeamTalkHistoryWindow:ShowHistory()
	end
end

function TeamTalkWindow:CheckCanInput()
	local length  = utf8.len(self.Controls.m_DialogInputField:GetComponent(typeof(InputField)).text)
	if 30  < length then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "文字输入已达上限！不能继续输入！")
		return false
	else
		return true
	end
end

function TeamTalkWindow:SortFace(text)
	if self:CheckCanInput() == true then 
		local inputFiled = self.Controls.m_DialogInputField:GetComponent(typeof(InputField))
		inputFiled.text = inputFiled.text .. text
	end
end

---------------------------------------------------------------
--对话输入框值输入变化
function TeamTalkWindow:OnDialogInputFieldValueChanged()
	local length  = utf8.len(self.Controls.m_DialogInputField:GetComponent(typeof(InputField)).text)
	local lastLength = 30 - length
	self.Controls.m_LetterCountText.text = "还剩"..tostring(lastLength).."个字"
	
end
---------------------------------------------------------------
--function TeamTalkWindow:OnSubmit(charToValidate) 

--end


return TeamTalkWindow