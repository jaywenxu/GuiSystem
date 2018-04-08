
----------------------------------------------------------------
---------------------------------------------------------------
-- 主界面中间下部分分窗口
-- 包含：聊天、好友
---------------------------------------------------------------
------------------------------------------------------------

local MainMidBottomWindow = UIWindow:new
{
	windowName = "MainMidBottomWindow" ,
	mNeedUpDate = false,
	m_bSubEvent = false,
	m_tameUID = nil, -- 当前驯马UID
}

local this = MainMidBottomWindow   -- 方便书写
------------------------------------------------------------
function MainMidBottomWindow:Init()
   
	self.MainChatWidget = require("GuiSystem.WindowList.MainHUD.MainChatWidget")
	self.MainChatWidget:Init()
	self.MainVoiceInputWidget = require("GuiSystem.WindowList.MainHUD.MainVoiceInputWidget")
	self.MainVoiceInputWidget:Init()
	self:InitCallbacks()
end
------------------------------------------------------------
function MainMidBottomWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj,UIManager._MainHUDLayer)

	self.MainChatWidget:Attach(self.Controls.chatWight.gameObject )
	self.MainVoiceInputWidget:Attach(self.Controls.MainVoiceInputWidget.gameObject )
	
	self.Controls.m_DidaButton.onClick:AddListener(function() self:OnDidaButtonClick() end)
	self.Controls.m_ChatButton.onClick:AddListener(function() self:OnChatButtonClick() end)
	self.Controls.m_ChatSettingBtn.onClick:AddListener(function() self:OnChatSettingBtnClick() end)
	self.Controls.m_friendButton.onClick:AddListener(function() self:OnFriendBtnClick() end)
	
	self.Controls.m_ExpSlider = self.transform:Find("ExpSlider"):GetComponent(typeof(Slider))
	
	self.Controls.m_RedPacketBtn.gameObject:SetActive(false)
	self.Controls.m_RedPacketBtn.onClick:AddListener(function() self:OnClickRedPacketBtn() end)
	
	self.Controls.m_FishBtn.gameObject:SetActive(false)
	self.Controls.m_FishBtn.onClick:AddListener(function() self:OnClickFishBtn() end)
	
	self.Controls.m_TameBtn.gameObject:SetActive(false)
	self.Controls.m_TameBtn.onClick:AddListener(function() self:OnClickTameBtn() end)

	if not self.m_bSubEvent then
		self:SubscribeWinExecute()
	end
	if self.mNeedUpDate then
		self.mNeedUpDate = false
		self:Refesh()
	end
	self:RefreshEXPInfo()
	self:RefreshDidaBtn()

	self:RefreshRedDot()
	uerror("调试查BUG create MainMidBottomWindow")
    return self
end



function MainMidBottomWindow:Test()
	self.MainChatWidget:Test()
end

function MainMidBottomWindow:OnExecuteEventCreatTeam(eventdata)
	self.MainVoiceInputWidget:Refresh()
	
end

function MainMidBottomWindow:OnExecuteEventLeaveTeam(eventdata)
	self.MainVoiceInputWidget:Refresh()
end

function MainMidBottomWindow:InitCallbacks()
	self.callback_OnExecuteEventCreatTeam = function (_, _, _, eventdata) self:OnExecuteEventCreatTeam(eventdata)	end
	self.callback_OnExecuteEventLeaveTeam = function (_, _, _, eventdata) self:OnExecuteEventLeaveTeam(eventdata)	end
	-- 属性更新事件
	self.callback_OnExecuteEventUpdateProp = function(event, srctype, srcid, msg) self:OnExecuteEventUpdateProp(msg) end	
	self.callback_OnEventShowNewPacket = function(event, srctype, srcid, repacket) self:OnEventShowNewPacket( repacket ) end
	
	-- 显示钓鱼UI事件
	self.callback_ShowFishUI = function(event, srctype, srcid, isShow) self:ShowFishUI(isShow) end
end

-- 注册窗口事件
function MainMidBottomWindow:SubscribeWinExecute()
	if self.m_bSubEvent then
		return
	end
	if not GetHero() then
		return
	end
	rktEventEngine.SubscribeExecute( EVENT_TEAM_CREATETEAM , SOURCE_TYPE_TEAM , 0 , self.callback_OnExecuteEventCreatTeam)
	rktEventEngine.SubscribeExecute( EVENT_TEAM_QUITTEAM , SOURCE_TYPE_TEAM , 0 , self.callback_OnExecuteEventLeaveTeam)
	rktEventEngine.SubscribeExecute( EVENT_ENTITY_UPDATEPROP , SOURCE_TYPE_PERSON , GetHero():GetUID() , self.callback_OnExecuteEventUpdateProp)
	rktEventEngine.SubscribeExecute( EVENT_ENTITY_UPDATEPROP , SOURCE_TYPE_PERSON , tEntity_Class_Person , self.callback_OnExecuteEventUpdateProp)
	
	rktEventEngine.SubscribeExecute(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM,REDDOT_UI_EVENT_MAIN_MID_BOTTOM, self.RefreshRedDot, self)
	
	rktEventEngine.SubscribeExecute(MSG_MODULEID_REDENVELOP, SOURCE_TYPE_SYSTEM, EVENT_RED_PACKET_NEW, self.callback_OnEventShowNewPacket)
	
	-- 显示钓鱼UI事件事件
	rktEventEngine.SubscribeExecute(ENTITYPART_CREATURE_SKILL, SOURCE_TYPE_SYSTEM, SKILL_UI_EVENT_LIFESKILL_SHOW_FISHUI, self.callback_ShowFishUI)
	
	self.m_bSubEvent = true
end

-- 注销窗口事件
function MainMidBottomWindow:UnSubscribeWinExecute()
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_CREATETEAM , SOURCE_TYPE_TEAM , 0 , self.callback_OnExecuteEventCreatTeam)
	rktEventEngine.UnSubscribeExecute(EVENT_TEAM_QUITTEAM, SOURCE_TYPE_TEAM,0, self.RefreshRedDot, self)	
	rktEventEngine.UnSubscribeExecute( EVENT_ENTITY_UPDATEPROP , SOURCE_TYPE_PERSON , GetHero():GetUID() , self.callback_OnExecuteEventUpdateProp)
	rktEventEngine.UnSubscribeExecute( EVENT_ENTITY_UPDATEPROP , SOURCE_TYPE_PERSON , tEntity_Class_Person , self.callback_OnExecuteEventUpdateProp)
	rktEventEngine.UnSubscribeExecute(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM,REDDOT_UI_EVENT_MAIN_MID_BOTTOM, self.RefreshRedDot, self)	
	
	rktEventEngine.UnSubscribeExecute(MSG_MODULEID_REDENVELOP, SOURCE_TYPE_SYSTEM, EVENT_RED_PACKET_NEW, self.callback_OnEventShowNewPacket)
	
	-- 显示钓鱼UI事件事件
	rktEventEngine.UnSubscribeExecute(ENTITYPART_CREATURE_SKILL, SOURCE_TYPE_SYSTEM, SKILL_UI_EVENT_LIFESKILL_SHOW_FISHUI, self.callback_ShowFishUI)
	
	self.m_bSubEvent = false
end

------------------------------------------------------------
-- 点击消息滴答按钮
function MainMidBottomWindow:OnDidaButtonClick()
	IGame.DidaClassManager:ClearInvalidDida()
	IGame.DidaClassManager:SetAllRead()
	IGame.DidaClassManager:MessageDidaNoReadCntInit()
	self:RefreshDidaBtn()
	UIManager.DidaWindow:Show(true)
    UIManager.DidaWindow:RefreshDidaWindow()
end

------------------------------------------------------------
-- 点击频道聊天按钮
function MainMidBottomWindow:OnChatButtonClick()
	UIManager.ChatWindow:ShowOrHide()
end
------------------------------------------------------------

-- 点击聊天设置按钮
function MainMidBottomWindow:OnChatSettingBtnClick()
	UIManager.ChatSettingWindow:ShowOrHide()
end

------------------------------------------------------------
-- 点击聊天设置按钮
function MainMidBottomWindow:OnFriendBtnClick()
	--dofile("D:/LW20170101/Bin/LWClient/LuaScript/Lua/Client/111.lua")
	UIManager.FriendEmailWindow:Show(true)
end

--------------------------------------------------------------------------------
--刷新滴答提示按钮
function MainMidBottomWindow:RefreshDidaBtn()
	if not self:isLoaded() then
		return
	end
	local MessageDidaNoReadCnt = IGame.DidaClassManager:GetMessageDidaNoReadCnt()
	if MessageDidaNoReadCnt > 0 then
		self.Controls.m_CellCnt.text = MessageDidaNoReadCnt
		self.Controls.CellCntBg.gameObject:SetActive(true)
	else
		self.Controls.CellCntBg.gameObject:SetActive(false)
	end
	
	local DidaCnt = IGame.DidaClassManager:GetMessageDidaCnt()
	if DidaCnt > 0 then
		self.Controls.m_DidaButton.gameObject:SetActive(true)
	else
		self.Controls.m_DidaButton.gameObject:SetActive(false)
	end
end


-- 刷新经验、血量等
function MainMidBottomWindow:RefreshEXPInfo()
	local hero = GetHero()
	if not hero then
		return
	end
	
	local curExp = hero:GetNumProp(CREATURE_PROP_EXP)
	local nextExp = 9999
	local scheme = IGame.rktScheme:GetSchemeInfo(UPGRADE_CSV, hero:GetNumProp(CREATURE_PROP_LEVEL))
	if scheme then
		nextExp = scheme.NextExp
	end

	self.Controls.m_ExpSlider.value = curExp / nextExp
end

function MainMidBottomWindow:OnExecuteEventUpdateProp(msg)
	if not msg or type(msg) ~= "table" or not msg.nPropCount or msg.nPropCount == 0  then
		return
	end
	for i = 1, msg.nPropCount do
		if msg.propData[i].nPropID == CREATURE_PROP_EXP or msg.propData[i].nPropID == CREATURE_PROP_LEVEL then
			self:RefreshEXPInfo()
			return
		end
		if msg.propData[i].nPropID == CREATURE_PROP_CLANID or msg.propData[i].nPropID == CREATURE_PROP_TEAMID then
			self.MainVoiceInputWidget:Refresh()
		end
	end
end

-- 刷新红点显示
function MainMidBottomWindow:RefreshRedDot(_, _, _, evtData)
	local redDotObjs = 
	{
		["好友"] = self.Controls.m_friendButton
	}

	if not evtData then
		for name, obj in pairs(redDotObjs) do
			local flag = SysRedDotsMgr.GetSysFlag("MainMidBottom", name)
			UIFunction.ShowRedDotImg(obj.transform, flag, true)
		end
	else
		local obj = redDotObjs[evtData.layout]
		if obj then
			UIFunction.ShowRedDotImg(obj.transform, evtData.flag, true)
		end
	end

end


-- 红包点击按钮
function MainMidBottomWindow:OnClickRedPacketBtn()
	local newPacketInfo = self.m_currentPacketInfo
	if  newPacketInfo == nil  then 
		return
	end
	IGame.RedEnvelopClient:OnRequestOpenRedenvelop(newPacketInfo.btType,newPacketInfo.dwSerial)
	
	IGame.RedEnvelopClient:RemoveCurrentRedPacket()
end

-- 显示红包按钮事件
function MainMidBottomWindow:OnEventShowNewPacket(repacket)
	self.m_currentPacketInfo = repacket
	if repacket then
		self.Controls.m_RedPacketBtn.gameObject:SetActive(true)
	else
		self.Controls.m_RedPacketBtn.gameObject:SetActive(false)
	end
end

-- 钓鱼按钮点击事件
function MainMidBottomWindow:OnClickFishBtn()
	if IGame.LifeSkillClient:OnRequestFish() then
		self.Controls.m_FishBtn.gameObject:SetActive(false)
	end
end

-- 显示钓鱼UI
function MainMidBottomWindow:ShowFishUI(isShow)
	self.Controls.m_FishBtn.gameObject:SetActive(isShow)
end

-- 驯马按钮点击事件
function MainMidBottomWindow:OnClickTameBtn()
	if IGame.LifeSkillClient:RequestTame() then
		self:ShowTameBtn(false)
	end
end

-- 显示驯马按钮
function MainMidBottomWindow:ShowTameBtn(isShow)
	self.Controls.m_TameBtn.gameObject:SetActive(isShow)
end

------------------------------------------------------------
return this
