--用于组队界面我的队伍面板的控制
------------------------------------------------------------
local MyTeamRoleCellClass = require("GuiSystem.WindowList.Team.MyTeamRoleCell")

------------------------------------------------------------
local MyTeamWidget = UIControl:new
{
	windowName = "MyTeamWidget" ,
	m_RoleCellList = {},			--保存了角色cell

	m_haveDoEnable = false,
}


--展示英雄模型的配置
local param = {
        layer = "EntityGUI",                                -- 所在层
        Name = "ObjectDisplayEquipPlayer" ,
        Position = Vector3.New( 1000 , 1000 , 0 ) ,
        RTWidth = 1660 ,                                    -- RenderTexture 宽
        RTHeight = 724,                                     -- RenderTexture 高
        CullingMask = {"EntityGUI"},                        -- 裁减列表，填 layer 的名称即可
        CamPosition = Vector3.New( 0.14 , 1.3 , 2.7 ) ,     -- 相机位置
        FieldOfView = 0,                                    -- 视野角度
		BackgroundColor = Color.black ,
		BackgroundImageInfo =
		{	
			[0] = 
			{
				BackgroundImage = AssetPath.TextureGUIPath.."CommonBigFrame/Common_zd_shangceng.png", --背景图片（texture）
				Vertices =
				{
					Vector4.New( -1, -1 , 1 , 1 )	
				},
				UVs = 
				{   
					Vector4.New(0 , 0 , 1 , 1 ),
				} ,
				name = "GameObject"	,
				isSliced =true,
				isSprite =true,
				zValue = -1,
			},
			[1]=
			{
				BackgroundImage = AssetPath.TextureGUIPath.."Team/Team_beijing.png"  ,   --  背景图片路径
				Vertices =
				{
					Vector4.New( -1 , -1 , -0.5 , 1 ),	
					Vector4.New( -0.5 , -1 , 0 , 1 ),	
					Vector4.New( 0 , -1 , 0.5 , 1 )	,
					Vector4.New( 0.5 , -1 , 1, 1 )	,
				},
				isSliced = false,
				isSprite =true
			}	
		},

		CameraRotate = Vector3.New(6.84,-180,0) ,
        CameraLight = true ,	
    }

------------------------------------------------------------
function MyTeamWidget:Attach( obj )
    
	UIControl.Attach(self,obj)
    
	--修改队伍目标
	self.callbackOnTeamGoalsButtonClick = function() self:OnTeamGoalsButtonClick() end
	self.Controls.m_TeamGoalsButton.onClick:AddListener(self.callbackOnTeamGoalsButtonClick)
	
	-- 召唤跟随
	self.callbackOnCallFollowButtonClick = function() self:OnCallFollowButtonClick() end
	self.Controls.m_CallFollowButton.onClick:AddListener(self.callbackOnCallFollowButtonClick)
	
	-- 取消跟随
	self.callbackOnCancelCallFollowButtonClick = function() self:OnCancelCallFollowButtonClick() end
	self.Controls.m_CancelCallFollowButton.onClick:AddListener(self.callbackOnCancelCallFollowButtonClick)
	
	-- 跟随队长
	self.callbackFollowCaptainButtonClick = function() self:OnFollowButtonCaptainClick() end
	self.Controls.m_followBtn.onClick:AddListener(self.callbackFollowCaptainButtonClick)
	
	-- 喊话
	self.callbackOnTalkButtonClick = function() self:OnTalkButtonClick() end
	self. Controls.m_TalkButton.onClick:AddListener(self.callbackOnTalkButtonClick)
    
	-- 申请
	self.callbackOnApplyButtonClick = function() self:OnApplyButtonClick() end
	self.Controls.m_ApplyButton.onClick:AddListener(self.callbackOnApplyButtonClick)
    
	-- 离开队伍
	self.callbackOnLeaveRankButtonClick = function() self:OnLeaveRankButtonClick() end
	self.Controls.m_LeaveRankButton.onClick:AddListener(self.callbackOnLeaveRankButtonClick)
	
    -- 解散队伍
	--self.callbackOnBreakRankButtonClick = function() self:OnBreakRankButtonClick() end
	--self.Controls.m_BreakRankButton.onClick:AddListener(self.callbackOnBreakRankButtonClick)
    
	self.callbackOnDisable = function() self:OnDisable() end
	self.unityBehaviour.onDisable:AddListener(self.callbackOnDisable)
    
	self.callbackOnEnable = function() self:OnEnable() end
	self.unityBehaviour.onEnable:AddListener(self.callbackOnEnable) 
    
	self.Controls.HeroRawImage = self.Controls.m_HeroRawImage:GetComponent(typeof(RawImage))
	
	--创建4个RoleCell
	for i = 1,4 do
		local item  = MyTeamRoleCellClass:new({})
		local trs = self.Controls.teamPanel:GetChild(i-1)
		item:Attach(trs.gameObject)
		item:InitIndex(i)
		item:SetClickClass(self)
		self.m_RoleCellList[i] = item
	end
--	self.RoleClickControl = TeamClickControl:new() 
	--self.RoleClickControl:Attach(self.Controls.m_TipsControl.gameObject)
	
	--自动匹配toggle
	self.Controls.m_AutomatchToogle.isOn = false
	self.AutoMatchTeam = function(on) self:OnAutoMatchTogChange(on) end
	self.Controls.m_AutomatchToogle.onValueChanged:AddListener(self.AutoMatchTeam)

	if not self.m_haveDoEnable then 
		self:OnEnable()
	end

	return self
end


function MyTeamWidget:InitModelCamear()
end

-- 创建模型渲染纹理？？
function MyTeamWidget:CreatModelRenderTexture()
    
    local dis = rktObjectDisplayInGUI:new()
    self.m_dis = dis
    local success = dis:Create(param)
    if success == true then 
        UnityEngine.Object.DontDestroyOnLoad(dis.m_GameObject)
        dis:AttachRawImage(self.Controls.HeroRawImage,true)
    else
        self.m_dis = nil
    end
end

-- 取消匹配
function MyTeamWidget:CancelAutoMatch()
   
     local hero = GetHero()
    if not hero then return end 
    
    -- 获取当前匹配目标
    local nCurMatchTarget = IGame.TeamClient:GetTeamTargetID()
    if not nCurMatchTarget or nCurMatchTarget <= 0 then 
        return   
    end
    IGame.TeamClient:ReqCancelAutoMatchTeam(emQMT_Team)   
end

-- 响应自动匹配toggle改变事件
function MyTeamWidget:OnAutoMatchTogChange(on)
	
    local team = IGame.TeamClient:GetTeam()	
    if team == nil then 
        self.Controls.m_AutomatchToogle.isOn =false
        return 
    end 
    
    local target_id, match_lv_lower, match_lv_upper = IGame.TeamClient:GetHeroTeamTargetInfo()
    if on and target_id == 0 then 
        self.Controls.m_AutomatchToogle.isOn =false
        if gAutoMatchTeamTip[6] then 
            IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, gAutoMatchTeamTip[6])
        end         
        return
    end
    
    if on then  
        if IGame.TeamClient:HeroIsAutoMatchingTeam() then 
            return
        end         
        if not IGame.TeamClient:CheckCanAutoMatchTeam(emQMT_Team, target_id, match_lv_lower, match_lv_upper) then 
            self.Controls.m_AutomatchToogle.isOn =false
            return
        end
        IGame.TeamClient:ReqAutoMatchTeam(emQMT_Team, target_id, match_lv_lower, match_lv_upper)
    else 
        if not IGame.TeamClient:HeroIsAutoMatchingTeam() then 
            return
        end 
        self:CancelAutoMatch()
    end 	
end

--监听队伍消息
function MyTeamWidget:SubscribeEvent()		
	
	local team = IGame.TeamClient:GetTeam()
    if team == nil then return end 
    
	self.teamID = team:GetTeamID()
    
	--队伍成员改变
	self.MemberChange =  function(event, srctype, srcid, eventData) self:OnMemberChange(event, srctype, srcid, eventData) end 
	rktEventEngine.SubscribeExecute( EVENT_TEAM_MEMBERCHANGE , SOURCE_TYPE_TEAM , self.teamID , self.MemberChange)
	rktEventEngine.SubscribeExecute( EVENT_TEAM_SYNCMEMBER_TOALLTEAM , SOURCE_TYPE_TEAM , self.teamID , self.MemberChange)

	--加入队伍
	self.JoinTeam = function(event, srctype, srcid, eventData) self:OnJoinTeam(event, srctype, srcid, eventData) end 
	rktEventEngine.SubscribeExecute( EVENT_TEAM_JOINTEAM , SOURCE_TYPE_TEAM , self.teamID , self.JoinTeam)
    
	--离开队伍
	self.LeaveTeam = function(event, srctype, srcid, eventData) self:OnLeaveTeam(event, srctype, srcid, eventData) end 
	rktEventEngine.SubscribeExecute( EVENT_TEAM_LEAVETEAM , SOURCE_TYPE_TEAM , self.teamID , self.LeaveTeam)
    
	--队长改变
	self.changeCaptain = function(event, srctype, srcid, eventData) self:OnEventChangeCaptain(eventData) end 
	rktEventEngine.SubscribeExecute( EVENT_TEAM_CAPTAIN , SOURCE_TYPE_TEAM , self.teamID , self.changeCaptain)
	
	--更新队伍目标
	self.UpdateTeamTarget = function(event, srctype, srcid, eventData) self:OnUpdateTeamTarget(event, srctype, srcid, eventData) end 
	rktEventEngine.SubscribeExecute( EVENT_TEAM_UPDATE_TARGET , SOURCE_TYPE_TEAM , self.teamID , self.UpdateTeamTarget)
    
	--队伍自动匹配状态改变
	self.AutoMatchStateChangeEvent = function(event, srctype, srcid,eventData) self:AutoMatchEvent(eventData) end
	rktEventEngine.SubscribeExecute( EVENT_TEAM_MATCHSTATE_UPDATE , SOURCE_TYPE_TEAM , 0  , self.AutoMatchStateChangeEvent)
    
	self.RequestTeamFun = function(event, srctype, srcid, eventData) self:GetRequest(event, srctype, srcid, eventData) end
	rktEventEngine.SubscribeExecute( EVENT_TEAM_BUILDFLOW_REQUEST , SOURCE_TYPE_TEAM , 0, 	self.RequestTeamFun)	
    
    -- 队员等级刷新
    self.UpdateMemberLv = function(event, srctype, srcid, eventData) self:OnUpdateMemberLv(eventData) end 
    rktEventEngine.SubscribeExecute( EVENT_TEAM_MEMBERLEVEL_UPDATE , SOURCE_TYPE_TEAM , self.teamID, 	self.UpdateMemberLv)
    
    -- 队员修为刷新
    self.UpdateMemberXW = function(event, srctype, srcid, eventData) self:OnUpdateMemberXW(eventData) end 
    rktEventEngine.SubscribeExecute( EVENT_TEAM_MEMBERXIUWEI_UPDATE , SOURCE_TYPE_TEAM , self.teamID, 	self.UpdateMemberXW)  

    -- 跟随状态刷新
    self.UpdateFollowState = function(event, srctype, srcid, eventData) self:OnUpdateFollowState(eventData) end
    rktEventEngine.SubscribeExecute( EVENT_TEAM_SYNC_FOLLOWSTATE , SOURCE_TYPE_TEAM , self.teamID, 	self.UpdateFollowState)   
end

--注销队伍消息
function MyTeamWidget:UnSubscribeEvent()    
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_MEMBERCHANGE ,            SOURCE_TYPE_TEAM , self.teamID , self.MemberChange)
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_JOINTEAM ,                SOURCE_TYPE_TEAM , self.teamID , self.JoinTeam)
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_LEAVETEAM ,               SOURCE_TYPE_TEAM , self.teamID , self.LeaveTeam)
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_CAPTAIN ,                 SOURCE_TYPE_TEAM , self.teamID , self.changeCaptain)
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_UPDATE_TARGET ,           SOURCE_TYPE_TEAM , self.teamID , self.UpdateTeamTarget)	
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_SYNCMEMBER_TOALLTEAM ,    SOURCE_TYPE_TEAM , self.teamID , self.MemberChange)
    rktEventEngine.UnSubscribeExecute( EVENT_TEAM_MEMBERLEVEL_UPDATE ,      SOURCE_TYPE_TEAM , self.teamID,  self.UpdateMemberLv)
    rktEventEngine.UnSubscribeExecute( EVENT_TEAM_MEMBERXIUWEI_UPDATE ,     SOURCE_TYPE_TEAM , self.teamID,  self.UpdateMemberXW)    
    rktEventEngine.UnSubscribeExecute( EVENT_TEAM_SYNC_FOLLOWSTATE ,        SOURCE_TYPE_TEAM , self.teamID,  self.UpdateFollowState)     
    
    rktEventEngine.UnSubscribeExecute( EVENT_TEAM_BUILDFLOW_REQUEST ,       SOURCE_TYPE_TEAM , 0, 	         self.RequestTeamFun)
    rktEventEngine.UnSubscribeExecute( EVENT_TEAM_MATCHSTATE_UPDATE ,       SOURCE_TYPE_TEAM , 0 ,           self.AutoMatchStateChangeEvent)
end

function MyTeamWidget:GetRequest(event, srctype, srcid, eventData)
    
    if not self:isLoaded() or not self:isShow() then 
        return
    end 
    
	self:CheckTeamRedDot()
	self:OnApplyButtonClick()	
end

--
function MyTeamWidget:AutoMatchEvent(eventData)
    
    self:RefreshAutoMatchUI()
end

-- 队员等级刷新
function MyTeamWidget:OnUpdateMemberLv(eventData)
    
    if not eventData then return end 
    self:RefreshUIMember(eventData.dwPDBID)
end 

-- 队员修为刷新
function MyTeamWidget:OnUpdateMemberXW(eventData)
    
    if not eventData then return end 
    self:RefreshUIMember(eventData.dwPDBID)
end 

-- 更新跟随状态
function MyTeamWidget:OnUpdateFollowState(eventData)
    
    if not eventData then return end 
    
    if GetHero() and GetHero():GetNumProp(CREATURE_PROP_PDBID) == eventData.dwPDBID then
        local bCaptain = IGame.TeamClient:IsTeamCaptain(GetHero():GetNumProp(CREATURE_PROP_PDBID))
        self:RefreshLeaderUI(bCaptain)   
    end
end 

function MyTeamWidget:RefreshUI()
       
	local myTeam = IGame.TeamClient:GetTeam()
	if nil == myTeam then 
		return
	end    
    
    local member_list = myTeam:GetMemberList()   
    if not member_list or not next(member_list) then 
        return
    end 
    
    for idx = 1, TEAM_MEMBER_MAXCOUNT do 
        self.m_RoleCellList[idx]:OnUpdate(nil,self.m_dis.m_GameObject.transform)  
    end 
    
    -- 先显示队长
    local index = 1 
    for k, memberInfo in pairs(member_list) do 
        if memberInfo.bCaptainFlag then 
            self.m_RoleCellList[index]:OnUpdate(memberInfo,self.m_dis.m_GameObject.transform)    
            break
        end
    end 
    
    -- 再显示队员
    for k, memberInfo in pairs(member_list) do 
        if not memberInfo.bCaptainFlag then 
            index = index + 1
            self.m_RoleCellList[index]:OnUpdate(memberInfo,self.m_dis.m_GameObject.transform)   
        end
    end 

--[[    if index < TEAM_MEMBER_MAXCOUNT then 
        for idx = index+1, TEAM_MEMBER_MAXCOUNT do          
            self.m_RoleCellList[idx]:OnUpdate(nil,self.m_dis.m_GameObject.transform)     
        end    
    end--]]
        
    local bCaptain = IGame.TeamClient:IsTeamCaptain(GetHero():GetNumProp(CREATURE_PROP_PDBID))
	self:RefreshAutoMatchUI()
	self:RefreshLeaderUI(bCaptain)
	self:RefreshTeamGolas()
end

--刷新自动匹配界面
function MyTeamWidget:RefreshAutoMatchUI()
    
	local myTeam = IGame.TeamClient:GetTeam()
    if myTeam == nil then return end 
    
    local autoMatch = IGame.TeamClient:HeroIsAutoMatchingTeam()
    self.Controls.m_AutomatchToogle.isOn = autoMatch
    
    local teamCout = table.getn(myTeam.m_listMemberInfo)
	for k,v in pairs(self.m_RoleCellList ) do 
		if k >  teamCout and autoMatch then 
			v:ShowAutoTips(true)
		else
			v:ShowAutoTips(false)
		end
	end
end

--刷新队伍目标
function MyTeamWidget:RefreshTeamGolas()
    
	local myTeam = IGame.TeamClient:GetTeam()
    local eventData = {}
    if myTeam == nil then 
        eventData.nTeamTargetID, eventData.nLowLv, eventData.nHighLv = 0, 1, 150
    else 
        eventData.nTeamTargetID, eventData.nLowLv, eventData.nHighLv = IGame.TeamClient:GetHeroTeamTargetInfo()
    end 

    self:OnUpdateTeamTarget(nil, nil, nil, eventData)
end

function MyTeamWidget:RefreshUIMember(dbid)

	local myTeam = IGame.TeamClient:GetTeam()
	local info = myTeam:GetMemberInfo(dbid)
    if info == nil then return end 
    
	local cell = nil
	for k,v in pairs(self.m_RoleCellList) do
		if v.m_dbID == dbid or v.m_dbID == nil then 
			cell = v
			break
		end
	end
	if cell ~= nil then 
		cell:OnUpdate(info,self.m_dis.m_GameObject.transform)
	end
	
end


---刷新队长UI
function MyTeamWidget:RefreshLeaderUI(bCaptain)

	self.Controls.m_autoMatch.gameObject:SetActive(bCaptain)
	self.Controls.m_talkAndApply.gameObject:SetActive(bCaptain)
	self. Controls.m_TeamGoalsButton.gameObject:SetActive(bCaptain)
	self:RefreshFollowState(bCaptain, CommonApi:IsTrainFollow())
end

---刷新follow信息
function MyTeamWidget:RefreshFollowState(bCaptain,bFollow)
	
	if bCaptain then
		self.Controls.m_CallFollowButton.gameObject:SetActive(true)
		self.Controls.m_CancelCallFollowButton.gameObject:SetActive(true)
		self.Controls.m_followBtn.gameObject:SetActive(false)
	else
		self.Controls.m_CallFollowButton.gameObject:SetActive(false)
		if bFollow then
			self.Controls.m_followBtn.gameObject:SetActive(false)
			self.Controls.m_CancelCallFollowButton.gameObject:SetActive(true)
		else
			self.Controls.m_followBtn.gameObject:SetActive(true)
			self.Controls.m_CancelCallFollowButton.gameObject:SetActive(false)
		end
	end
end

--更新队伍目标
function MyTeamWidget:OnUpdateTeamTarget(event, srctype, srcid, eventData)
	    
	if eventData == nil then
		return
	end
	
    local name = "全部"
	if eventData.nTeamTargetID > 0 then 
        local target_scheme = IGame.rktScheme:GetSchemeInfo(TEAMTARGET_CSV, eventData.nTeamTargetID)
        if target_scheme then 
            name = target_scheme.ActivityName   
        end
    end 

	self:UpdateTeamGoalsText(name,eventData.nLowLv,eventData.nHighLv)
end

function MyTeamWidget:OnDestroy()
	self.Controls.m_TeamGoalsButton.onClick:RemoveListener(self.callbackOnTeamGoalsButtonClick)
	self.Controls.m_CancelCallFollowButton.onClick:RemoveListener(self.callbackOnCancelCallFollowButtonClick)
	self.Controls.m_TalkButton.onClick:RemoveListener(self.callbackOnTalkButtonClick)	
	self.Controls.m_ApplyButton.onClick:RemoveListener(self.callbackOnApplyButtonClick)
	self.Controls.m_LeaveRankButton.onClick:RemoveListener(self.callbackOnLeaveRankButtonClick)
	self.Controls.m_BreakRankButton.onClick:RemoveListener(self.callbackOnBreakRankButtonClick)
	self.unityBehaviour.onEnable:RemoveListener(self.callbackOnEnable) 
	self.unityBehaviour.onDisable:RemoveListener(self.callbackOnDisable) 
	self.m_RoleCellList={}
	UIControl.OnDestroy(self)
end

--队伍成员改变
function MyTeamWidget:OnMemberChange(event, srctype, srcid, eventData)
	local dwJoinPDBID = eventData.dwJoinPDBID
	local team = IGame.TeamClient:GetTeam()
	self:RefreshUIMember(eventData.dwJoinPDBID)
end 

--加入队伍
-------------------------------------------------------------
function MyTeamWidget:OnJoinTeam(event, srctype, srcid, eventData) 
    
	local dwJoinPDBID = eventData.dwJoinPDBID
	local team = IGame.TeamClient:GetTeam()
    if team == nil then return end 
    
	self:RefreshUIMember(eventData.dwJoinPDBID)
  
	if team:IsMemberFull() then 
		self:CancelAutoMatch()
		for k,v in pairs(self.m_RoleCellList) do
			v:ShowAutoTips(false)
		end
	end
end 

-------------------------------------------------------------
--成员离开队伍
function MyTeamWidget:OnLeaveTeam(event, srctype, srcid, eventData) 
    
    if not eventData or not GetHero() or eventData.dwLeavePDBID == GetHero():GetNumProp(CREATURE_PROP_PDBID) then return end 
    
	self:RefreshUI()
end 

--队长改变
-------------------------------------------------------------
function MyTeamWidget:OnEventChangeCaptain(eventData) 
    
	if not GetHero():IsTeamCaptain() then 
		UIManager.MainLeftCenterWindow:SetTeamRedDot(false)
	end
    
	self:CheckTeamRedDot()
	self:RefreshUI()
end 

--更新队伍目标
------------------------------------------------------------
function MyTeamWidget:UpdateTeamGoalsText(goalName, goalFromLevel, goalToLevel)
	self.Controls.m_GoalNameText.text = goalName
	self.Controls.m_GoalLevelText.text = tostring(goalFromLevel).." - "..tostring(goalToLevel)
end


--队伍目标按钮按下
function MyTeamWidget:OnTeamGoalsButtonClick()

	local confirmDelegation =function() self:CancelAutoMatch() end
	if IGame.TeamClient:GetHeroAutoMatchType() == emQMT_Team then 
		local data = 
		{
			content = "取消自动匹配后才可选择目标，是否取消自动匹配？",
			confirmCallBack = confirmDelegation,
		}	
		UIManager.ConfirmPopWindow:ShowDiglog(data)
		return
	end
	UIManager.TeamGoalsWindow:Show(true)
end

-- 召唤跟随按钮按下
function MyTeamWidget:OnCallFollowButtonClick()
	IGame.TeamClient:InviteFollowCaptain()
end

-- 取消召唤跟随按钮按下
function MyTeamWidget:OnCancelCallFollowButtonClick()
	local pHero = GetHero()
	if not pHero then
		return
	end
	if IGame.TeamClient:IsTeamCaptain(pHero:GetNumProp(CREATURE_PROP_PDBID)) then
		IGame.TeamClient:CancelTeamFollowCaptain()
	else
		CommonApi:CancelFollow()
	end
end

-- 跟随队长按钮按下
function MyTeamWidget:OnFollowButtonCaptainClick()
    
	IGame.TeamClient:FollowCaptain(true)
end

--喊话按钮按下
function MyTeamWidget:OnTalkButtonClick() 
    
    local TargetID, nLowLv, nHighLv = IGame.TeamClient:GetHeroTeamTargetInfo()
	UIManager.TeamTalkWindow:InitUI(self.Controls.m_GoalNameText.text, nLowLv, nHighLv)
	UIManager.TeamTalkWindow:Show(true)
end

--申请按钮按下
function MyTeamWidget:OnApplyButtonClick()
    
	if self.transform.gameObject.activeInHierarchy then 
		UIManager.TeamApplyListWindow:Show(true)
	end	
end

--离开队伍按钮被按下
function MyTeamWidget:OnLeaveRankButtonClick()

	IGame.TeamClient:LeaveTeam()	
end

--解散队伍按钮按下
function MyTeamWidget:OnBreakRankButtonClick() 

end

-- 检查显示组队请求红点提示
function MyTeamWidget:CheckTeamRedDot()
	
    if not self:isLoaded() or not self:isShow() then 
        return
    end 
	
	local teamRequestInfo = IGame.TeamClient:GetRequestPersonInfo()	
	if not GetHero or not GetHero():IsTeamCaptain() or not teamRequestInfo or not next(teamRequestInfo) then 
		self.Controls.m_redDot.gameObject:SetActive(false)
		return 
	end
	
    UIManager.TeamApplyListWindow:Show(true)
    self.Controls.m_redDot.gameObject:SetActive(true)    
end

function MyTeamWidget:OnUpdateCell(pMemberInfo)
	if not UIManager.TeamWindow:isShow() then
		return
	end
	if pMemberInfo ~= nil and pMemberInfo.nIndex<= 4 then
		self.m_RoleCellList[pMemberInfo.nIndex]:OnUpdate(pMemberInfo)
	end 
end

function MyTeamWidget:OnEnable() 
    
	if self.m_haveDoEnable == true then
		return
	end
    self.m_haveDoEnable =true
    
	self:CreatModelRenderTexture()	
	self:RefreshUI()
	self:CheckTeamRedDot()
	self:SubscribeEvent()
end

function MyTeamWidget:OnDisable() 
    
	self.m_haveDoEnable = false
	self:UnSubscribeEvent()
	if self.m_dis ~=nil then 
		self.m_dis:Destroy()
	end
end

function MyTeamWidget:OnDestroy() 
    
	self.m_haveDoEnable = false
	self:UnSubscribeEvent()
	if self.m_dis ~=nil then 
		self.m_dis:Destroy()
	end
end

return MyTeamWidget