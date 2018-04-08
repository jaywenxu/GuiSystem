--组队系统附近队伍组件
------------------------------------------------------------
local TeamTotalPlaerCellClass = require("GuiSystem.WindowList.Team.NearPlayerTotalCell")
local NearTeamCellClass = require("GuiSystem.WindowList.Team.TeamNearListCell")


------------------------------------------------------------
local NearbyTeamWidget =  UIControl:new
{
	windowName = "NearbyTeamWidget" ,
	m_TeamListView = nil,
	m_PlayerListView = nil,
	m_lastClickTime = 0,
    m_bHaveDone  = false,
}
local clickIndexTime = 3
------------------------------------------------------------
function NearbyTeamWidget:Attach( obj )
	UIControl.Attach(self,obj)
	
	self.m_TeamListView =  self.Controls.m_TeamListScroller:GetComponent(typeof(EnhancedListView))
	self.m_PlayerListView = self.Controls.m_PlayerListScroller:GetComponent(typeof(EnhancedListView))
	
	--附近队伍
	self.callBackTeamListViewGetCell = function(objCell) self:OnGetNearTeamCellView(objCell) end
	self.callBackTeamListViewVisable = function(objCell) self:OnVisiableNearTeam(objCell) end	
	self.m_TeamListView.onGetCellView:AddListener(self.callBackTeamListViewGetCell)
	self.m_TeamListView.onCellViewVisiable:AddListener(self.callBackTeamListViewVisable)
	
	--附近玩家
	self.callBackOnPlayerListGetCellView = function(objCell) self:OnGetPlayerListCellView(objCell) end
	self.m_PlayerListView.onGetCellView:AddListener(self.callBackOnPlayerListGetCellView)

	--附近玩家 附近队伍标签
	self.callbackOnNearTeamButtonClick = function(on) self:OnNearTeamButtonClick(on) end
	self.Controls.m_nearTeamToggle.onValueChanged:AddListener(self.callbackOnNearTeamButtonClick)
	self.callbackOnNearPlayerButtonClick = function(on) self:OnNearPlayerButtonClick(on) end
	self.Controls.m_nearPlayerToggle.onValueChanged:AddListener(self.callbackOnNearPlayerButtonClick)

	--创建队伍按钮
	self.callBackOnCreateTeamButtonClick = function() self:OnCreateTeamButtonClick() end
	self.Controls.m_CreateTeamButton.onClick:AddListener(self.callBackOnCreateTeamButtonClick)
	
	--刷新按钮
	self.OnClickRefreshBtn = function() self:OnClickRefreshTeam() end
	self.Controls.m_RefreshButton.onClick:AddListener(self.OnClickRefreshBtn)
	
	self.callbackOnEnable = function() self:OnEnable() end
	self.unityBehaviour.onEnable:AddListener(self.callbackOnEnable) 
	
	self.callbackOnDisable = function() self:OnDisable() end
	self.unityBehaviour.onDisable:AddListener(self.callbackOnDisable) 
	self.Controls.m_nearTeamToggle.isOn =true
	self.Controls.m_TeamListScroller.gameObject:SetActive(true)
	self.Controls.m_PlayerListScroller.gameObject:SetActive(false)
	self:Register()
	IGame.TeamClient:QueryAroundTeam()
	self:InitNearPlayer()
	self:OnEnable()
	
	return self
end

function NearbyTeamWidget:Register()
	self.NearTeamEvent = function(event, srctype, srcid,gesture) self:GetNearTeamEvent() end
	rktEventEngine.SubscribeExecute( EVENT_TEAM_QUERY_AROUND_TEAM , SOURCE_TYPE_TEAM , 0 , self.NearTeamEvent)
end
	
function NearbyTeamWidget:GetNearTeamEvent()
		self:InitScroll()
end

--附近队伍被创建
function NearbyTeamWidget:OnGetNearTeamCellView(objCell)
	local nearTeam = NearTeamCellClass:new({})
	nearTeam:Attach(objCell)
end




--附近队伍可见
function NearbyTeamWidget:OnVisiableNearTeam(objCell)
	local viewCell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))
	local behav = objCell:GetComponent(typeof(UIWindowBehaviour))
	if nil ~= behav then
		local item = behav.LuaObject	
		local teamArr = IGame.TeamClient:GetAroundTeamList()
		local info = teamArr[viewCell.cellIndex+1] 
		
		item:RefreshCellUI(info)
	end
end


function NearbyTeamWidget:InitScroll()
	local nearTeam = IGame.TeamClient:GetAroundTeamList()
	if nearTeam == nil then 
		self.m_TeamListView:SetCellCount( 0 , true )
	else
		local Cout = table.getn(nearTeam)
		self.m_TeamListView:SetCellCount( Cout , true )
	end

	
end
------------------------------------------------------------
function NearbyTeamWidget:OnDestroy()
	UIControl.OnDestroy(self)
end
------------------------------------------------------------
function NearbyTeamWidget:OnNearTeamButtonClick(on)
	self.Controls.m_TeamListPanel.gameObject:SetActive(true)
	self.Controls.m_PlayerListPanel.gameObject:SetActive(false)
    
    self.Controls.m_txtNearPlayer.color = Color.New(0.34,0.48, 0.59)   
    self.Controls.m_txtNearTeam.color = Color.New(0.78,0.47, 0.26)  
end
------------------------------------------------------------

function NearbyTeamWidget:OnNearPlayerButtonClick(on) 
	self.Controls.m_PlayerListPanel.gameObject:SetActive(true)
	self.Controls.m_TeamListPanel.gameObject:SetActive(false)
    
    self.Controls.m_txtNearTeam.color = Color.New(0.34,0.48, 0.59)   
    self.Controls.m_txtNearPlayer.color = Color.New(0.78,0.47, 0.26)      
end

------------------------------------------------------------
function NearbyTeamWidget:OnCreateTeamButtonClick()
    
	local team = IGame.TeamClient:GetTeam()
    if team == nil then return end 
    
	local teamID = team:GetTeamID()
	if teamID == INVALID_TEAM_ID then 
		--向服务器发送创建队伍的申请消息，默认TargetID 为0，等级为1-100级
		IGame.TeamClient:CreateTeam()
	else
		IGame.ChatClient:addSystemTips(TipType_Operate,InfoPos_ActorUnder,"你已经在队伍中" )
	end

end


function NearbyTeamWidget:InitNearPlayer()
	self.playerEntitys = EntityWorld:GetClassEntitys(tEntity_Class_Person)
	self.playerEntitysWithoutPlayerUID = {}
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end
	local UID = pHero:GetUID()
	for i = 1,table.maxn(self.playerEntitys) do
		if self.playerEntitys[i]:GetUID() ~= UID and self.playerEntitys[i]:GetNumProp(CREATURE_PROP_TEAMID) == 0 then
			table.insert(self.playerEntitysWithoutPlayerUID, self.playerEntitys[i])
		end
	end
	if table.maxn( self.playerEntitysWithoutPlayerUID) <= 0 then
		self.m_PlayerListView:SetCellCount( 0 , true )
	else
		if table.maxn(self.playerEntitysWithoutPlayerUID) % 2 == 0 then
			self.m_PlayerListView:SetCellCount( table.maxn(self.playerEntitysWithoutPlayerUID) / 2 , true )
		else
			self.m_PlayerListView:SetCellCount( table.maxn(self.playerEntitysWithoutPlayerUID) / 2 + 1 , true )
		end
	end		
end

------------------------------------------------------------
function NearbyTeamWidget:OnGetPlayerListCellView(objCell)
	
	local viewCell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))

	if viewCell.cellIndex < 0 then
		return
	end

	
	local index = viewCell.cellIndex * 2 + 1  --+1表示viewCell索引从0开始，而entity从1开始								
	local leftName = self.playerEntitysWithoutPlayerUID[index]:GetName()				
	local leftLevel = self.playerEntitysWithoutPlayerUID[index]:GetNumProp(CREATURE_PROP_LEVEL)	
	local leftHeadId = self.playerEntitysWithoutPlayerUID[index]:GetNumProp(CREATURE_PROP_FACEID)	
	local leftProfession = self.playerEntitysWithoutPlayerUID[index]:GetNumProp(CREATURE_PROP_VOCATION)	
	
	local teamTotalItem = TeamTotalPlaerCellClass:new()
	teamTotalItem:Attach(objCell)
	teamTotalItem:InitLeftPlayer(leftName,leftLevel,leftProfession,leftHeadId,self.playerEntitysWithoutPlayerUID[index])
	
	if index + 1 <= table.maxn(self.playerEntitysWithoutPlayerUID) then
		teamTotalItem:ShowRightPlayer(true)
		local rightName = self.playerEntitysWithoutPlayerUID[index + 1]:GetName()		
		local rightLevel = self.playerEntitysWithoutPlayerUID[index + 1]:GetNumProp(CREATURE_PROP_LEVEL)
		local RightHeadId = self.playerEntitysWithoutPlayerUID[index + 1]:GetNumProp(CREATURE_PROP_FACEID)	
		local RightProfession = self.playerEntitysWithoutPlayerUID[index + 1]:GetNumProp(CREATURE_PROP_VOCATION)	
		teamTotalItem:InitRightPlayer(rightName,rightLevel,RightProfession,RightHeadId,self.playerEntitysWithoutPlayerUID[index + 1])
	else
		teamTotalItem:ShowRightPlayer(false)
	end
	
end


--附近玩家可见
function NearbyTeamWidget:OnPlayerCellVisiable(objCell)
end


--刷新面板重新获取
function NearbyTeamWidget:OnClickRefreshTeam()
	if self.Controls.m_nearTeamToggle.isOn == true then 
		--这样才会重新刷新每个Cell的内容
		self.m_TeamListView:SetCellCount( 0 , true )
		IGame.TeamClient:QueryAroundTeam()

	else
		self.m_PlayerListView:SetCellCount( 0 , true )
		self:InitNearPlayer()
		
	end
end
------------------------------------------------------------
function NearbyTeamWidget:OnEnable() 
    
    if not self.m_bHaveDone then 
        self:OnClickRefreshTeam()
        local MyTeam = IGame.TeamClient:GetTeam()
        if MyTeam:GetTeamID() ~= INVALID_TEAM_ID then 
            self.Controls.m_creatTeamObj.gameObject:SetActive(false)
        else
            self.Controls.m_creatTeamObj.gameObject:SetActive(true)
        end
        self:OnNearTeamButtonClick(true) 
        self.m_bHaveDone = true
	end 
end
------------------------------------------------------------
function NearbyTeamWidget:OnDisable() 
	
    self.m_bHaveDone = false
end
------------------------------------------------------------
return NearbyTeamWidget
