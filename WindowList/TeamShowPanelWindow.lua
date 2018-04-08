
	--组队显示窗口，在主界面显示
------------------------------------------------------------

local TeamShowPanelWindow = UIWindow:new
{
	windowName = "TeamShowPanelWindow" ,
	m_teamShowClass,
	TeamPanelWidgetClass,
	MyTeamWidgetClass,
	teamArr={},
	m_teamClickControl=nil,
	m_haveDoEnable =false,
	m_teamID = nil
}

local FollowUIPos =
{
	Vector3.New(116, -390,0),
    Vector3.New(116, -490,0),
    Vector3.New(116, -590,0),
	Vector3.New(116, -690,0),
}

------------------------------------------------------------
function TeamShowPanelWindow:Init()
	self.m_teamShowClass = require("GuiSystem.WindowList.Team.TeamShowPanelCell")
	self.TeamPanelWidgetClass = require("GuiSystem.WindowList.Team.TeamPanelWidget")
	self.MyTeamWidgetClass = require("GuiSystem.WindowList.Team.MyTeamWidget")
end

function TeamShowPanelWindow:RegisterEvent()
	
		--注册队友显示是否在附近的事件 
	rktEventEngine.SubscribeExecute( EVENT_ENTITY_DESTROYENTITY , SOURCE_TYPE_PERSON ,0, self.TeammateChangePosStateFalse,self)
	rktEventEngine.SubscribeExecute( EVENT_ENTITY_CREATEENTITY , SOURCE_TYPE_PERSON , 0, self.TeammateChangePosStateTrue,self)

	self:RegisterTeam()
end

-- 主角入队
function TeamShowPanelWindow:OnCreateTeam(event, srctype, srcid, eventData)
    self:RegisterTeam()
    self:RefeshFollowState()
    self:RefreshUI()
end

-- 主角离队
function TeamShowPanelWindow:OnQuitTeam(event, srctype, srcid, eventData)
	self:UnRegister()
	self:RefeshFollowState()
	self:RefreshUI()
end

function TeamShowPanelWindow:UnRegisterTeammate()
	rktEventEngine.UnSubscribeExecute( EVENT_ENTITY_DESTROYENTITY , SOURCE_TYPE_PERSON , 0, self.TeammateChangePosStateTrue, self)
	rktEventEngine.UnSubscribeExecute( EVENT_ENTITY_CREATEENTITY , SOURCE_TYPE_PERSON , 0, self.TeammateChangePosStateFalse,self)

end

------------------------------------------------------------
function TeamShowPanelWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj,UIManager._MainHUDLayer)	
	for i=1,4 do
		self.teamArr[i] = self.m_teamShowClass:new()
	end
	
	self.teamArr[1]:Attach(self.Controls.m_PlayerOne.gameObject)
	self.teamArr[1]:SetCellIndex(1)
	self.teamArr[2]:Attach(self.Controls.m_PlayerTwo.gameObject)
	self.teamArr[2]:SetCellIndex(2)
	self.teamArr[3]:Attach(self.Controls.m_PlayerThree.gameObject)
	self.teamArr[3]:SetCellIndex(3)
	self.teamArr[4]:Attach(self.Controls.m_PlayerFour.gameObject)
	self.teamArr[3]:SetCellIndex(4)
	
	self.unityBehaviour.onEnable:AddListener(function() self:OnEnable() end) 
	self.unityBehaviour.onDisable:AddListener(function() self:OnDisable() end) 
	--self.m_teamClickControl = self.ClickClass:new()
	--self.m_teamClickControl:Attach(self.Controls.m_clickTrs.gameObject)
	-- 队长召唤跟随
	self.callFollowFun = function() self:OnClickCallFollowBtn() end
	self.Controls.m_CallFollowButton.onClick:AddListener(self.callFollowFun)

	-- 取消召唤跟随
	self.callBackCancelCallFollow = function() self:OnClickCancelCallFollowBtn() end
	self.Controls.m_CancelCallFollowButton.onClick:AddListener(self.callBackCancelCallFollow)
	
	-- 跟随
	self.callBackFollow = function() self:OnClickFollow() end
	self.Controls.m_FollowButton.onClick:AddListener(self.callBackFollow)

	-- 取消跟随
	self.callBackCancelFollow = function() self:OnClickCancelFollow() end
	self.Controls.m_CancelFollowButton.onClick:AddListener(self.callBackCancelFollow)	
	
	self.CreateTeam = function(event, srctype, srcid, eventData) self:OnCreateTeam(event, srctype, srcid, eventData) end 
    rktEventEngine.SubscribeExecute( EVENT_TEAM_CREATETEAM , SOURCE_TYPE_TEAM , 0 , self.CreateTeam)
    
	self.QuitTeam = function(event, srctype, srcid, eventData) self:OnQuitTeam(event, srctype, srcid, eventData) end 	
	rktEventEngine.SubscribeExecute( EVENT_TEAM_QUITTEAM , SOURCE_TYPE_TEAM , 0, self.QuitTeam)
	
	
	for i=1,4 do
		local member =  IGame.TeamClient:GetTeamMemberByIndex(i)
		if member == nil then 
			self.teamArr[i].transform.gameObject:SetActive(false)
		else
			self.teamArr[i].transform.gameObject:SetActive(true)
			self:OnUpdateCell(member)
		end
	
	end
	if self.m_haveDoEnable ==false then 
		self:OnEnable()
	end
	return self
end


function TeamShowPanelWindow:SetCallFollwBtnState(state)
	if not self:isLoaded() then
		return
	end
	self.Controls.m_CancelCallFollowButton.gameObject:SetActive(state)
	self.Controls.m_CallFollowButton.gameObject:SetActive(state)
end

--队员离开
function TeamShowPanelWindow:TeamMemberLeave(eventData)
	if self:isLoaded() then
		if nil ~= eventData then 
			local dbID = eventData.dwLeavePDBID
			local count = #self.teamArr
			local item =nil
			for i=1,count do
				item= self.teamArr[i] 
				if item ~= nil then 
					if item.m_dbID == dbID then 
						item:InitCell(nil)
					end
				end
			end
		end

        self:RefeshFollowState()
	end
end

function TeamShowPanelWindow:HaveMemberJoinTeam(eventData)
    
	local dwJoinPDBID = eventData.dwJoinPDBID
	local team = IGame.TeamClient:GetTeam()
	local memberInfo = team:GetMemberInfo(dwJoinPDBID)
	self:OnUpdateCell(memberInfo)	
end

--检查队长是否是我自己
function TeamShowPanelWindow:TeamCheckLeaderIsMe()
	return GetHero():IsTeamCaptain()
end

-- 成员改变
function TeamShowPanelWindow:MemberChangeEvent(eventData)
    
	local team = IGame.TeamClient:GetTeam()
	local memberInfo = team:GetMemberInfo(eventData.dwPDBID)
	self:OnUpdateCell(memberInfo)
	self:RefeshFollowState()
end

-- 更新队伍成员等级
function TeamShowPanelWindow:SyncMemberLevel(eventData)
    
    if not eventData then return end 
    
	local team = IGame.TeamClient:GetTeam()
    if team == nil then return end
	local memberInfo = team:GetMemberInfo(eventData.dwPDBID)
	self:OnUpdateCell(memberInfo)
end 

-- 更新跟随状态信息
function TeamShowPanelWindow:SyncFollowState(eventData)
	
	if not eventData or not self:isLoaded() then
		return
	end
	local dwPDBID = eventData.dwPDBID or 0
	local bFollowCaptain = eventData.bFollowCaptain or false
	
	self:RefeshFollowState() 
	self:RefeshCellFollowState(dwPDBID,bFollowCaptain)
	
	local bFollow = false
	if not IGame.TeamClient:IsTeamCaptain(dwPDBID) and CommonApi:IsFollowing() then
		bFollow = true
	end
	--现在默认全部设为false了
--	UIManager.MainLeftTopWindow:SyncFollowState(bFollow)
	UIManager.TeamWindow:SyncTeamFollowState(dwPDBID,bFollowCaptain)
end

-- 刷新单个cell 跟随状态信息
function TeamShowPanelWindow:RefeshCellFollowState(dwPDBID,bFollow)
	for i = 1,4 do
		if self.teamArr[i]:GetCellDBID() == dwPDBID then
			self.teamArr[i]:CellRefeshFollowState(bFollow)
			break
		end
	end
end

function TeamShowPanelWindow:OnJoinTeam(event, srctype, srcid, eventData)
	local dwJoinPDBID = eventData.dwJoinPDBID
	local team = IGame.TeamClient:GetTeam()
	local memberInfo = team:GetMemberInfo(dwJoinPDBID)
	self:OnUpdateCell(memberInfo)
end

-- 更新跟随信息
function TeamShowPanelWindow:RefeshFollowState()
	if not self:isLoaded() then
		return
	end

    local my_team = IGame.TeamClient:GetTeam()
    if not my_team or my_team:GetTeamID() == INVALID_TEAM_ID or my_team:GetMemberCount() <= 1 then         
		self.Controls.m_CallFollowButton.gameObject:SetActive(false)
		self.Controls.m_CancelCallFollowButton.gameObject:SetActive(false)
		self.Controls.m_FollowButton.gameObject:SetActive(false)
		self.Controls.m_CancelFollowButton.gameObject:SetActive(false)   
        return
    end 
    
    local count = my_team:GetMemberCount()
    if count > 0 and count < 5 then 
        self.Controls.m_FollowBtnWidget.anchoredPosition = FollowUIPos[count]
    end 

	if self:TeamCheckLeaderIsMe() then 
		self.Controls.m_CallFollowButton.gameObject:SetActive(true)
		self.Controls.m_CancelCallFollowButton.gameObject:SetActive(true)
		self.Controls.m_FollowButton.gameObject:SetActive(false)
		self.Controls.m_CancelFollowButton.gameObject:SetActive(false)
	else 
		self.Controls.m_CallFollowButton.gameObject:SetActive(false)
		self.Controls.m_CancelCallFollowButton.gameObject:SetActive(false)        
		if CommonApi:IsFollowing() then
			self.Controls.m_FollowButton.gameObject:SetActive(false)
			self.Controls.m_CancelFollowButton.gameObject:SetActive(true)
		else
			self.Controls.m_FollowButton.gameObject:SetActive(true)
			self.Controls.m_CancelFollowButton.gameObject:SetActive(false)
		end
	end
end

--根据对长不是我自己来刷新UI
function TeamShowPanelWindow:RefreshUI()
	
    if not self:isLoaded() or not self:isShow() then 
        return
    end 

    local myTeam = IGame.TeamClient:GetTeam()		
    if not myTeam or not GetHero() then return end 
    
    -- 刷新跟随信息状态
    self:RefeshFollowState()
		    
    for k,v in pairs(self.teamArr) do 
        self.teamArr[k].transform.gameObject:SetActive(false)
    end
           
    local list_member = myTeam:GetMemberList()
    -- 先显示队长
    local index = 1
    for k, v in pairs(list_member) do 
        if v.bCaptainFlag then
            self.teamArr[index]:InitCell(v)
            break
        end
    end 
    
    -- 再显示队员
    for k, v in pairs(list_member) do         
        if not v.bCaptainFlag then 
            index = index + 1
            self.teamArr[index]:InitCell(v)
        end
    end 

    if GetHero():IsTeamCaptain() then 
        UIManager.MainLeftTopWindow:SetTeamFlag(true)
    else
        UIManager.MainLeftTopWindow:SetTeamFlag(false)        
        if CommonApi:IsFollowing() then 
            UIManager.MainLeftTopWindow:SyncFollowState(true)
        else 
            UIManager.MainLeftTopWindow:SyncFollowState(false)
        end
    end    
end


--更新队友血量
function TeamShowPanelWindow:OnUpdateTeamHp(eventData)
	if not self:isLoaded() then
		return
	end
    
    if not self.teamArr then return end 
    
	for i=1,4 do 
		if self.teamArr[i] and self.teamArr[i]:GetCellDBID() == eventData.dwPDBID then 
			self.teamArr[i]:RefreshHp(eventData.nCurHP,eventData.nMaxHP)
			break
		end
	end
	
end

-- 队长召唤跟随
function TeamShowPanelWindow:OnClickCallFollowBtn()
	IGame.TeamClient:InviteFollowCaptain()
end

--取消召唤跟随
function TeamShowPanelWindow:OnClickCancelCallFollowBtn()
	
	local pHero = GetHero()
	if not pHero then
		return
	end
	-- 是否是队长
	if not IGame.TeamClient:IsTeamCaptain(pHero:GetNumProp(CREATURE_PROP_PDBID)) then
		return
	end
	-- 取消队员跟随
	IGame.TeamClient:CancelTeamFollowCaptain()
end

-- 队员跟随队长
function TeamShowPanelWindow:OnClickFollow()
	IGame.TeamClient:FollowCaptain(true)
end

-- 取消跟随
function TeamShowPanelWindow:OnClickCancelFollow()
	CommonApi:CancelFollow()
end


function TeamShowPanelWindow:RegisterTeam()
	
	local team = IGame.TeamClient:GetTeam()
	
	if team == nil then 
		return
	end
	
	local teamId = team:GetTeamID()
	self.m_teamID = teamId
	if teamId == INVALID_TEAM_ID then 
		return
	end

	--加入队伍
    self.JoinTeam = function(event, srctype, srcid, eventData) self:HaveMemberJoinTeam(eventData) end 
	rktEventEngine.SubscribeExecute( EVENT_TEAM_JOINTEAM , SOURCE_TYPE_TEAM , teamId , self.JoinTeam)
    
	--队伍成员改变
    self.UpDateMemberEvent =  function(event, srctype, srcid, eventData) self:MemberChangeEvent(eventData) end 
	rktEventEngine.SubscribeExecute( EVENT_TEAM_SYNCMEMBER_TOALLTEAM , SOURCE_TYPE_TEAM , self.teamID , self.UpDateMemberEvent)
    
	--队员离开
    self.TeamMemberLeaveEvent = function(event, srctype, srcid, eventData) self:TeamMemberLeave(eventData) end
	rktEventEngine.SubscribeExecute( EVENT_TEAM_LEAVETEAM , SOURCE_TYPE_TEAM , teamId , self.TeamMemberLeaveEvent)

	--更新队长
    self.SettingAndUpdateLeader = function(event, srctype, srcid, eventData) self:SettingLeader(eventData) end 
	rktEventEngine.SubscribeExecute( EVENT_TEAM_CAPTAIN , SOURCE_TYPE_TEAM , teamId , self.SettingAndUpdateLeader)
    
	-- 更新跟随状态信息
    self.callBackSyncFollowState =  function(event, srctype, srcid, eventData) self:SyncFollowState(eventData) end 
	rktEventEngine.SubscribeExecute( EVENT_TEAM_SYNC_FOLLOWSTATE , SOURCE_TYPE_TEAM , teamId, self.callBackSyncFollowState)
    
    -- 更新队员等级
    self.callBackShncMemLv  = function(event, srctype, srcid, eventData) self:SyncMemberLevel(eventData) end 
	rktEventEngine.SubscribeExecute( EVENT_TEAM_MEMBERLEVEL_UPDATE , SOURCE_TYPE_TEAM , teamId, self.callBackShncMemLv)    
    
    -- 更新队员血量
	self.UpdateTeamHp = function(event, srctype, srcid, eventData) self:OnUpdateTeamHp(eventData) end   
    rktEventEngine.SubscribeExecute(EVENT_TEAM_MEMBERHP_UPDATE,SOURCE_TYPE_TEAM,teamId,self.UpdateTeamHp)   
end

function TeamShowPanelWindow:UnRegister()
	local teamId =self.m_teamID
	if teamId == INVALID_TEAM_ID then 
		uerror("TeamShowPanelWindow teamid = 0")
		return
	end
	--队伍成员改变
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_SYNCMEMBER_TOALLTEAM , SOURCE_TYPE_TEAM , teamId, self.UpDateMemberEvent)
	--队员离开
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_LEAVETEAM , SOURCE_TYPE_TEAM , teamId , self.TeamMemberLeaveEvent)

	--更新队长
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_CAPTAIN , SOURCE_TYPE_TEAM , teamId , self.SettingAndUpdateLeader)
	
	-- 更新跟随状态信息
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_SYNC_FOLLOWSTATE , SOURCE_TYPE_TEAM , teamId, self.callBackSyncFollowState)
	
	--更新队友血量
	rktEventEngine.UnSubscribeExecute(EVENT_TEAM_MEMBERHP_UPDATE,SOURCE_TYPE_TEAM,teamId,self.UpdateTeamHp)
    
	--加入队伍
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_JOINTEAM , SOURCE_TYPE_TEAM , teamId , self.JoinTeam)

    -- 更新队员等级
    rktEventEngine.UnSubscribeExecute( EVENT_TEAM_MEMBERLEVEL_UPDATE , SOURCE_TYPE_TEAM , teamId , self.callBackShncMemLv)
end

------------------------------------------------------------
function TeamShowPanelWindow:OnDestroy()
	self:UnRegister()
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_QUITTEAM , SOURCE_TYPE_TEAM , 0, self.QuitTeam)
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_CREATETEAM , SOURCE_TYPE_TEAM , 0 , self.CreateTeam)
	self:UnRegisterTeammate()
	self.teamArr ={}
	self.m_teamClickControl = nil
	self.m_haveDoEnable =false
	UIWindow.OnDestroy(self)
end

------------------------------------------------------------
--更新队友信息
function TeamShowPanelWindow:OnToAllTeam (event, srctype, srcid, eventData) 
	local dwPDBID = eventData.dwPDBID
	print(dwPDBID)
end 
------------------------------------------------------------

------------------------------------------------------------
function TeamShowPanelWindow:OnUpdateCell(pMemberInfo)
	if nil == pMemberInfo then 
		return
	end
	self:RefreshUI()
end

function TeamShowPanelWindow:SettingLeader(info)
	UIManager.MainLeftCenterWindow:CheckTeamRedDot()
	self:RefreshUI()
end

------------------------------------------------------------
function TeamShowPanelWindow:OnEnable() 
	if self.m_haveDoEnable ==false then 
		self:RegisterEvent()
		UIManager.MainLeftCenterWindow:CheckTeamRedDot()
		self:RefreshUI()
		self.m_haveDoEnable =true
		self:RefeshFollowState()	
	end
end

------------------------------------------------------------
function TeamShowPanelWindow:OnDisable() 
	self.m_haveDoEnable =false
	self:UnRegister()
end

function TeamShowPanelWindow:TeammateChangePosStateFalse(event, srctype, srcid, eventData)
	local UID = eventData.uidEntity
	local member = self:GetMemberByUid(UID)
	if nil ~= member then 
		member:ChangeTeammatePosState(false)
	end
end

--队友位置改变消息
function TeamShowPanelWindow:TeammateChangePosStateTrue(event, srctype, srcid, eventData)
	local UID = eventData.uidEntity
	local member = self:GetMemberByUid(UID)

	if nil ~= member then 

		member:ChangeTeammatePosState(true)
	end
end

--根据UID获取member
function TeamShowPanelWindow:GetMemberByUid(Uid)
    
	local entity = IGame.EntityClient:Get(Uid)
	if entity and EntityClass:IsPerson(entity:GetEntityClass()) then 
		local pdbid = entity:GetNumProp(CREATURE_PROP_PDBID)
        local my_team = IGame.TeamClient:GetTeam()
        if not my_team then return end 
        
		local count = #self.teamArr
		for i=1,count do
			if tostring(self.teamArr[i].m_dbID) == tostring(pdbid) then 
				return self.teamArr[i]
			end
			
		end
	end
	
	return nil
end

------------------------------------------------------------
return TeamShowPanelWindow