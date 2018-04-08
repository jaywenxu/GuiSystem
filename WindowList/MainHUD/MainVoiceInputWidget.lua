------------------------------------------------------------
-- MainMidBottomWindow 的子窗口,不要通过 UIManager 访问
-- 频道切换Toggle窗口
------------------------------------------------------------
local MainVoiceInputWidget = UIControl:new
{
	windowName = "MainVoiceInputWidget",
	m_VoiceChannelList = {
		ChatChannel_World,
		--ChatChannel_Tribe,
		--ChatChannel_Team,
	},
	m_ShowState = 1, -- 显示状态 1：单个    2： 全部
	m_SpeakDownTime = 0,
}
local ChannelImage = {
	[ChatChannel_Team] = AssetPath.TextureGUIPath.."Main_mainUI/Main_zhan_dui.png",
	[ChatChannel_Tribe] = AssetPath.TextureGUIPath.."Main_mainUI/Main_zhan_bang.png",
	[ChatChannel_World] = AssetPath.TextureGUIPath.."Main_mainUI/Main_zhan_shi.png",
}
local ChannelCallBackFunc = {
	[ChatChannel_Team]	= IGame.ChatClient.CallBackSendTeamVoiceChatMessage,
	[ChatChannel_Tribe] = IGame.ChatClient.CallBackSendClanVoiceChatMessage,
	[ChatChannel_World] = IGame.ChatClient.CallBackSendWorldVoiceChatMessage,
}
local this = MainVoiceInputWidget   -- 方便书写

function MainVoiceInputWidget:Init()
	
end

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function MainVoiceInputWidget:Attach( obj )
	UIControl.Attach(self,obj)

	--点击展开按钮
	self.calbackExpandBtnClick = function() self:OnExpandBtnClick() end
    self.Controls.m_ExpendBtn.onClick:AddListener(self.calbackExpandBtnClick)
	self.Controls.m_ExpendBtn.gameObject:SetActive(true)
	
    self.Controls.m_FoldBtn.onClick:AddListener(self.calbackExpandBtnClick)
	self.Controls.m_FoldBtn.gameObject:SetActive(false)
	
	self.callBackSpeakerBtnUpClick = function(eventData) self:OnBtnUpClick(eventData) end
	self.callBackSpeakerBtnDragClick = function(eventData) self:OnBtnDragClick(eventData) end
	
	for i=1,3 do
		self["SpeakerBtn"..i] = self.Controls.m_VoiceinputGrid.transform:Find("SpeakerBtn"..i)
		self["SpeakerBtnImage"..i] = self["SpeakerBtn"..i].transform:Find("GameObject"):GetComponent(typeof(Image))
		self.callBackSpeakerBtnDownClick = function(eventData) self:OnSpeakerBtnDownClick(eventData,i) end
		UIFunction.AddEventTriggerListener(self["SpeakerBtn"..i],EventTriggerType.PointerDown,self.callBackSpeakerBtnDownClick)
		UIFunction.AddEventTriggerListener(self["SpeakerBtn"..i],EventTriggerType.PointerUp,self.callBackSpeakerBtnUpClick)
		UIFunction.AddEventTriggerListener(self["SpeakerBtn"..i],EventTriggerType.Drag,self.callBackSpeakerBtnDragClick)
		
		self.callBackSpeakerBtnClick = function(eventData) self:OnSpeakerBtnClick(eventData,i) end
		UIFunction.AddEventTriggerListener(self["SpeakerBtn"..i],EventTriggerType.PointerClick,self.callBackSpeakerBtnClick)
	end
	self:Refresh()
	return self
end

------------------------------------------------------------
function MainVoiceInputWidget:SetVoiceChannelList(List)
	self.m_VoiceChannelList = List
end

------------------------------------------------------------
function MainVoiceInputWidget:InsertVoiceChannel(Channel)
	for key,v in ipairs(self.m_VoiceChannelList) do
		if Channel == v then
			return
		end
	end
	table.insert(self.m_VoiceChannelList,Channel)
end

------------------------------------------------------------
function MainVoiceInputWidget:RemoveVoiceChannel(Channel)
	for key,v in ipairs(self.m_VoiceChannelList) do
		if Channel == v then
			table.remove(self.m_VoiceChannelList,key)
			break
		end
	end
end
--------------------------------------------------------
-- 判断Unity3D对象是否被加载
function MainVoiceInputWidget:isLoaded()
	return not tolua.isnull( self.transform )
end

------------------------------------------------------------
function MainVoiceInputWidget:Refresh()
	if not self:isLoaded() then
		return
	end
	local pHero = GetHero()
	if not pHero then
		return
	end
	if pHero:GetTeamID() ~= 0 then
		self:InsertVoiceChannel(ChatChannel_Team)
	else
		self:RemoveVoiceChannel(ChatChannel_Team)
	end
	if pHero:GetNumProp(CREATURE_PROP_CLANID) ~= 0 then
		self:InsertVoiceChannel(ChatChannel_Tribe)
	else
		self:RemoveVoiceChannel(ChatChannel_Tribe)
	end
	local VoiceChannelShowList = {}
	local VoiceCnt = 0
	if self.m_ShowState == 1 then		-- 显示单个
		VoiceChannelShowList[1] = self.m_VoiceChannelList[1]
		VoiceCnt = table.getn(VoiceChannelShowList)
		self.Controls.m_Expend.gameObject:SetActive(true)
		self.Controls.m_Fold.gameObject:SetActive(false)
		--local width = self.Controls.m_VoiceinputBG.sizeDelta.x
		--local vector2 = Vector2.New(width, 100+50)
		--self.Controls.m_VoiceinputBG.sizeDelta = vector2
	else
		VoiceChannelShowList = self.m_VoiceChannelList
		VoiceCnt = table.getn(VoiceChannelShowList)
		
		self.Controls.m_Fold.gameObject:SetActive(true)
		self.Controls.m_Expend.gameObject:SetActive(false)
		--local width = self.Controls.m_VoiceinputBG.sizeDelta.x
		--local vector2 = Vector2.New(width, 100*VoiceCnt+50)
		--self.Controls.m_VoiceinputBG.sizeDelta = vector2
	end
	if table.getn(self.m_VoiceChannelList) <= 1 then
		self.Controls.m_VoiceinputBG.gameObject:SetActive(false)
	else
		self.Controls.m_VoiceinputBG.gameObject:SetActive(true)
	end
	for i=1,3 do
		if i <= VoiceCnt then
			UIFunction.SetImageSprite( self["SpeakerBtnImage"..i] , ChannelImage[VoiceChannelShowList[i]] )
			self["SpeakerBtn"..i].gameObject:SetActive(true)
		else
			self["SpeakerBtn"..i].gameObject:SetActive(false)
		end
	end
end

------------------------------------------------------------
function MainVoiceInputWidget:OnSpeakerBtnDownClick(eventData,index)
	self.m_SpeakDownTime = CoreUtility.Now
	UIManager.SpeechNoticeWindow:Show(true)
	UIManager.SpeechNoticeWindow:SetCallBackFunc(ChannelCallBackFunc[self.m_VoiceChannelList[index]])
	UIManager.SpeechNoticeWindow:OnBtnDownClick(eventData)
end

------------------------------------------------------------
function MainVoiceInputWidget:OnSpeakerBtnClick(eventData,index)
	local NowTime = CoreUtility.Now
	if(NowTime - self.m_SpeakDownTime > 0.49)then
		return
	end
	--print("点击了  "..index..type(eventData)..tostringEx(eventData))
	local Channel = self.m_VoiceChannelList[index]
	local VoiceListTmp = {}
	VoiceListTmp[1] = Channel
	for i=1,3 do
		if i ~= index then
			table.insert(VoiceListTmp,self.m_VoiceChannelList[i])
		end
	end
	self.m_VoiceChannelList = VoiceListTmp
	if self.m_ShowState == 1 then
		self.m_ShowState = 2
	else
		self.m_ShowState = 1
	end
	self:Refresh()
end

function MainVoiceInputWidget:OnExpandBtnClick()
	if self.m_ShowState == 1 then
		self.m_ShowState = 2
	else
		self.m_ShowState = 1
	end
	self:Refresh()
end
------------------------------------------------------------
function MainVoiceInputWidget:OnBtnUpClick(eventData)
	--print("点击了  "..type(eventData)..tostringEx(eventData))
	UIManager.SpeechNoticeWindow:OnBtnUpClick(eventData)
end

------------------------------------------------------------
function MainVoiceInputWidget:OnBtnDragClick(eventData)
	--print("点击了  "..type(eventData)..tostringEx(eventData))
	UIManager.SpeechNoticeWindow:OnBtnDragClick(eventData)
end



return this