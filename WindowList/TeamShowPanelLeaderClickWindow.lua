 --主界面点击队长头像出来的点击菜单窗口
------------------------------------------------------------
local TeamShowPanelLeaderClickWindow = UIWindow:new
{
	windowName = "TeamShowPanelLeaderClickWindow" ,
	m_dwPDBID = nil,
	m_index =nil,
	m_enterType = nil,
	m_haveDoEnable =false
}

local EnterType=
{
	EnterType_Main_UI =1,
	EnterType_Team_UI =2,
	
}

local EveryMemberPos = 
{
	Vector3.New(474.23,-266.7,0),
	Vector3.New(474.23,-374,0),
	Vector3.New(474.23,-475.3,0),
	Vector3.New(474.23,-492.3,0),

}

local TeamUIPos=
{
	Vector3.New(489,-405,0),
	Vector3.New(847, -405,0),
	Vector3.New(1270, -405,0),
	Vector3.New(1636, -405,0),

}
------------------------------------------------------------
function TeamShowPanelLeaderClickWindow:Init()

end
------------------------------------------------------------
function TeamShowPanelLeaderClickWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.callbackOnClosePanelButtonClick = function(eventData) self:OnClosePanelButtonClick(eventData) end
	UIFunction.AddEventTriggerListener(self.Controls.m_ClosePanelButton, EventTriggerType.PointerClick, self.callbackOnClosePanelButtonClick)

	--发送消息
	self.callbackOnClickSendMsgFun = function() self:OnClickSendMsgFun() end
	self.Controls.m_SendMessageButton.onClick:AddListener(self.callbackOnClickSendMsgFun)
	--添加好友
	self.callBackOnClickAddFriendFun = function() self:OnClickAddFriend()end
	self.Controls.m_AddFriendButton.onClick:AddListener(self.callBackOnClickAddFriendFun)
	--召唤跟随
	self.callBackOnClickPleaseFollowFun = function() self:OnClickFollow() end
	self.Controls.m_CallFollowButton.onClick:AddListener(self.callBackOnClickPleaseFollowFun)
	--查看信息
	self.callbackOnClickLookInfo = function() self:OnClickLookInfo() end
	self.Controls.m_CheckInfoButton.onClick:AddListener(self.callbackOnClickLookInfo)

	--提升队长
	self.callBackOnPromotedLeaderButtonClick = function() self:OnPromotedLeaderButtonClick() end
	self.Controls.m_PromotedLeaderButton.onClick:AddListener(self.callBackOnPromotedLeaderButtonClick)
	
	--请离队伍
	self.callBackOnRemovememberButtonClick = function() self:OnRemovememberButtonClick() end
	self.Controls.m_RemovememberButton.onClick:AddListener(self.callBackOnRemovememberButtonClick)
	--查看梦岛
	self.OnClickLookDream = function() self:LookDream() end
	self.Controls.m_CheckDreamIslandButton.onClick:AddListener(function() self:OnClickLookDream() end)
	
	--离开队伍
	if self.Controls.m_leaveBtn ~= nil then 
		self.OnClickLeaveTeam = function() self:OnClickLeaveTeamFun() end
		self.Controls.m_leaveBtn.onClick:AddListener(self.OnClickLeaveTeam)
	end
    
    -- 发送坐标
    if self.Controls.m_SendPosBtn ~= nil then 
        self.OnClickSendPos = function() self:OnClickSendPosToTeamChannel() end 
        self.Controls.m_SendPosBtn.onClick:AddListener(self.OnClickSendPos)
    end
		
	self.callbackOnEnable = function() self:OnEnable() end
	self.unityBehaviour.onEnable:AddListener(self.callbackOnEnable) 
	
	self.callbackOnDisable = function() self:OnDisable() end
	self.unityBehaviour.onDisable:AddListener(self.callbackOnDisable) 
	if self.m_haveDoEnable == false then 
		self:OnEnable()
	end
	self.transform.gameObject:SetActive(true)
	return self
end


function TeamShowPanelLeaderClickWindow:OnClickLeaveTeamFun()
	--向服务器发送离开队伍的消息
	IGame.TeamClient:LeaveTeam()
	self:Hide(false)
end

function TeamShowPanelLeaderClickWindow:OnClickSendPosToTeamChannel()
    
	local pHero = IGame.EntityClient:GetHero()
	if pHero == nil then
		return
	end
	local pos = pHero:GetPosition()
	local mapID = IGame.EntityClient:GetMapID()

	local mapInfo = IGame.rktScheme:GetSchemeInfo(MAPINFO_CSV, mapID )				--获取对应mapID的地图信息
	local name = mapInfo.szName														--当前地图名称
	local x = math.floor(pos.x)
	local y = math.floor(pos.y)
	local z = math.floor(pos.z)
	local textSend = "<herf><color="..Chat_MapLocaltion_Color..">"..name.."<"..x.."，"..z.."></color><fun>"
	textSend = textSend.."ZC_moveto("..mapID..","..x..","..y..","..z..",3)</fun></herf>"
    
	IGame.ChatClient:sendChatMessage(ChatChannel_Team, textSend)
    
    self:Hide(false)
end

function TeamShowPanelLeaderClickWindow:InitInfo(dbID,Index,EnterType)
	self.m_dwPDBID = dbID
	self.m_index = Index
	self.m_enterType = EnterType
end

function TeamShowPanelLeaderClickWindow:OnDisable()
	self.m_haveDoEnable =false
end

--发送消息
function TeamShowPanelLeaderClickWindow:OnClickSendMsgFun()
	UIManager.FriendEmailWindow:OnPrivateChat(self.m_dwPDBID)
	self:Hide(false)
end


function TeamShowPanelLeaderClickWindow:OnEnable()
	self.m_haveDoEnable = true
	local team = IGame.TeamClient:GetTeam()
	if nil == team or self.m_index ==nil then
		return
	end
	
    if self.m_dwPDBID == GetHero():GetNumProp(CREATURE_PROP_PDBID) then 
        self.Controls.m_SendMessageButton.gameObject:SetActive(false)
        self.Controls.m_AddFriendButton.gameObject:SetActive(false)
        self.Controls.m_CallFollowButton.gameObject:SetActive(false)
        self.Controls.m_CheckInfoButton.gameObject:SetActive(false)
        self.Controls.m_PromotedLeaderButton.gameObject:SetActive(false)
        self.Controls.m_RemovememberButton.gameObject:SetActive(false)
        self.Controls.m_CheckDreamIslandButton.gameObject:SetActive(false)       
        self.Controls.m_leaveBtn.gameObject:SetActive(true)
        self.Controls.m_SendPosBtn.gameObject:SetActive(true)
    else 
        self.Controls.m_SendMessageButton.gameObject:SetActive(true)
        self.Controls.m_AddFriendButton.gameObject:SetActive(true)
        self.Controls.m_CallFollowButton.gameObject:SetActive(true)
        self.Controls.m_CheckInfoButton.gameObject:SetActive(true)
        self.Controls.m_PromotedLeaderButton.gameObject:SetActive(true)
        self.Controls.m_RemovememberButton.gameObject:SetActive(true)
        self.Controls.m_CheckDreamIslandButton.gameObject:SetActive(true)  
        self.Controls.m_leaveBtn.gameObject:SetActive(false)  
        self.Controls.m_SendPosBtn.gameObject:SetActive(false)
    	local MyIsleader = GetHero():IsTeamCaptain()
        if MyIsleader == true then 
            self.Controls.m_changeLeaderTrs.gameObject:SetActive(true)
            self.Controls.m_pleaseLeveTrs.gameObject:SetActive(true)
            self.Controls.m_followTrs.gameObject:SetActive(false)      
        else
            self.Controls.m_changeLeaderTrs.gameObject:SetActive(false)
            self.Controls.m_pleaseLeveTrs.gameObject:SetActive(false)
            self.Controls.m_followTrs.gameObject:SetActive(false) 
   			if team:GetCaptain() == self.m_dwPDBID  then 
				self.Controls.m_leaveBtn.gameObject:SetActive(true)
			else
				self.Controls.m_leaveBtn.gameObject:SetActive(false)
			end
        end
    end 
    
--[[	local MyIsleader = GetHero():IsTeamCaptain()
	if MyIsleader == true then 
		self.Controls.m_changeLeaderTrs.gameObject:SetActive(true)
		self.Controls.m_pleaseLeveTrs.gameObject:SetActive(true)
		self.Controls.m_followTrs.gameObject:SetActive(false)
        self.Controls.m_SendPosBtn.gameObject:SetActive(false)
		if 	self.Controls.m_leaveBtn ~= nil then 
			self.Controls.m_leaveBtn.gameObject:SetActive(false)
		end
	else
		self.Controls.m_changeLeaderTrs.gameObject:SetActive(false)
		self.Controls.m_pleaseLeveTrs.gameObject:SetActive(false)
		self.Controls.m_followTrs.gameObject:SetActive(false)
        self.Controls.m_SendPosBtn.gameObject:SetActive(false)
		if 	self.Controls.m_leaveBtn ~= nil then 
			local teamLeaderID = team:GetCaptain()
			if teamLeaderID == self.m_dwPDBID  then 
				self.Controls.m_leaveBtn.gameObject:SetActive(true)
			else
				self.Controls.m_leaveBtn.gameObject:SetActive(false)
			end

		end
	end--]]
    
	if self.m_enterType == EnterType.EnterType_Main_UI then 
        if self.m_index > 0 and self.m_index < 5 then 
            self.Controls.m_BgTrs.anchoredPosition = EveryMemberPos[self.m_index]
        end 
	else
        if self.m_index > 0 and self.m_index < 5 then 
            self.Controls.m_BgTrs.anchoredPosition = TeamUIPos[self.m_index]
        end
	end
	
end
----------------------------------------------------------
--添加好友
function TeamShowPanelLeaderClickWindow:OnClickAddFriend()
	IGame.FriendClient:OnRequestAddFriend(self.m_dwPDBID)
	self:Hide()
end

----------------------------------------------------------
--召唤跟随
function TeamShowPanelLeaderClickWindow:OnClickFollow()
	IGame.TeamClient:InviteFollowCaptain()
end

-------------------------------------------------------
--查看信息
function TeamShowPanelLeaderClickWindow:OnClickLookInfo()
	IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "查看角色暂未开发")
end
-----------------------------------------------------------
--查看梦岛
function TeamShowPanelLeaderClickWindow:LookDream()
	IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "梦岛系统暂未开发")
end

------------------------------------------------------------
function TeamShowPanelLeaderClickWindow:OnPromotedLeaderButtonClick() 
	IGame.TeamClient:AppointCaptain(self.m_dwPDBID)
	self:Hide(false)
end
------------------------------------------------------------
--开除队员
function TeamShowPanelLeaderClickWindow:OnRemovememberButtonClick() 
	IGame.TeamClient:KickoutMember(self.m_dwPDBID)
	self:Hide(false)
end
------------------------------------------------------------
function TeamShowPanelLeaderClickWindow:OnDestroy()
	self.m_dwPDBID = nil
	self.m_index = nil
	self.m_enterType = nil
	self.m_haveDoEnable = false
	--self.Controls.m_ClosePanelButton.onClick:RemoveListener(self.callbackOnClosePanelButtonClick)
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------
function TeamShowPanelLeaderClickWindow:OnClosePanelButtonClick(eventData)
	self:Hide()
	rkt.UIAndTextHelpTools.PassThroughPointerClickEvent( eventData )
end
------------------------------------------------------------
return TeamShowPanelLeaderClickWindow