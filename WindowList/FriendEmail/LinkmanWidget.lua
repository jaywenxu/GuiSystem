-- 单个联系人的详细信息和操作
-- @Author: LiaoJunXi
-- @Date:   2017-07-27 11:26:21
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-27 12:05:08

local LinkmanWidget = UIControl:new
{
	windowName = "LinkmanWidget",
	m_FriendClient = nil,
	m_SelIdx = 0,
	m_ID = 0,
	
	m_UpdateListCallBack = nil,
	m_RefreshUICallback = nil,
}

local this = LinkmanWidget

function LinkmanWidget:Attach( obj )
	UIControl.Attach(self, obj)
	self.m_FriendClient = IGame.FriendClient
	self:SubscribeEvts()
	self:InitUI()
end

function LinkmanWidget:InitUI()
	local controls = self.Controls
	
	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_BackBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_DeleteBtn.onClick:AddListener(handler(self, self.OnBtnDeleteClicked))
	if nil ~= controls.m_BlackBtn then
		controls.m_BlackBtn.onClick:AddListener(handler(self, self.OnBtnBlackClicked))
	end
	if nil ~= controls.m_InviteForClanBtn then
		controls.m_InviteForClanBtn.onClick:AddListener(handler(self, self.OnInviteForClanClicked))
	end
	if nil ~= controls.m_ApplyForClanBtn then
		controls.m_ApplyForClanBtn.onClick:AddListener(handler(self, self.OnApplyForClanClicked))
	end
	if nil ~= controls.m_InviteForTeamBtn then
		controls.m_InviteForTeamBtn.onClick:AddListener(handler(self, self.OnInviteForTeamClicked))
	end
	if nil ~= controls.m_ApplyForTeamBtn then
		controls.m_ApplyForTeamBtn.onClick:AddListener(handler(self, self.OnApplyForTeamClicked))
	end
	if nil ~= controls.m_ApplyForFriendBtn then
		controls.m_ApplyForFriendBtn.onClick:AddListener(handler(self, self.OnApplyFriendClicked))
	end
	if nil ~= controls.m_ClearEnemyBtn then
		controls.m_ClearEnemyBtn.onClick:AddListener(handler(self, self.OnClearEnemyClicked))
	end
end

function LinkmanWidget:SetRefreshUICallback( func_cb )
	self.m_RefreshUICallback = func_cb
end

function LinkmanWidget:SubscribeEvts()
	self.m_UpdateListCallBack = handler(self, self.OnUpdateListCallBack)
	rktEventEngine.SubscribeExecute( EVENT_FRIEND_UPDATELIST, SOURCE_TYPE_FRIEND, 0, self.m_UpdateListCallBack)
end

function LinkmanWidget:UnSubscribeEvts()
	rktEventEngine.UnSubscribeVote(EVENT_FRIEND_UPDATELIST , SOURCE_TYPE_FRIEND, 0, self.m_UpdateListCallBack)
end

--[[struct tagFriendInfo
{
	DWORD           m_version;                          // 数据版本号
	int             m_pdbid;                            // 玩家角色ID	
	WORD            m_faceID;                           // 玩家头像ID
	BYTE			m_vocation;							// 玩家职业ID
	tchar           m_name[MAX_PERSONNAME_LEN];         // 玩家的名字
	DWORD			m_power;							// 玩家战斗力
	int				m_level;							// 玩家等级
	BYTE            m_business[MAX_BUSINESSICON_QTY];   // 业务图标
	BYTE			m_btHeadTitleID;					// 玩家头衔
	DWORD			clanID;								// 取帮会ID
	tchar			m_szClanName[CLAN_NAME_LEN];		// 帮会名
	BYTE			m_btOnline;							// 是否在线
	BYTE			byFriendDivideRelation;				// 好友之间的关系(分组)
	BYTE			byFriendPowerRelation;				// 好友之间的权限关系
	DWORD			dwContactTime;						// 最近联系时间
}--]]
function LinkmanWidget:SetLinkmanData(idx, data)
	local controls = self.Controls

	controls.m_JobTxt.text = GameHelp.GetVocationName(data.m_vocation)
	controls.m_NameTxt.text = data.m_name
	controls.m_LevTxt.text = data.m_level

	print(controls.m_JobTxt.text.." say: data.m_faceID = "..data.m_faceID)
	if PERSON_VOCATION_LINGXIN == data.m_vocation then
		data.m_faceID = 2
	elseif data.m_faceID == 31 then
		data.m_faceID = 1
	end
	UIFunction.SetHeadImage(controls.m_AvatarIcon,data.m_faceID)
	
	self.m_SelIdx = idx
	self.m_ID = data.m_pdbid
end

function LinkmanWidget:OnBtnCloseClicked()
	self:Hide()
end

function LinkmanWidget:OnBtnDeleteClicked()
	--print("LinkmanWidget:OnBtnDeleteClicked")
	if self.m_ID > 0 then
		self.m_FriendClient:OnRequestDeleteFriend(self.m_ID)
		self:Hide()
	end
end

function LinkmanWidget:OnBtnBlackClicked()
	--print("LinkmanWidget:OnBtnBlackClicked")
	if self.m_ID > 0 then
		self.m_FriendClient:OnRequestAddBlack(self.m_ID)
		self:Hide()
	end
end

function LinkmanWidget:OnInviteForTeamClicked()
	IGame.TeamClient:InvitedJoin(self.m_ID)
	self:Hide()
end

function LinkmanWidget:OnApplyForTeamClicked()
	IGame.TeamClient:RequestJoin(self.m_ID)
	self:Hide()
end


function LinkmanWidget:OnInviteForClanClicked()
	IGame.ClanClient:InviteRequest(self.m_ID)
	self:Hide()
end

function LinkmanWidget:OnApplyForClanClicked()
	local playerInfo = self.m_FriendClient:GetPlayerInfo(self.m_ID)
	--print("LinkmanWidget:OnApplyForClanClicked"..playerInfo.m_pdbid)
	if playerInfo then
		--print("LinkmanWidget:OnApplyForClanClicked"..playerInfo.clanID)
		IGame.ClanClient:JoinRequest(playerInfo.clanID)
	end
	self:Hide()
end

function LinkmanWidget:OnApplyFriendClicked()
	self.m_FriendClient:OnRequestAddFriend(self.m_ID)
	self:Hide()
end

function LinkmanWidget:OnClearEnemyClicked()
	if self.m_ID > 0 then
		self.m_FriendClient:OnDeleteAllEnemy()
		self:Hide()
	end
end

function LinkmanWidget:OnUpdateListCallBack()
	if nil ~= self.m_RefreshUICallback then
		self.m_RefreshUICallback()
		self:Hide()
	end
end

function LinkmanWidget:OnRecycle()
	UIControl.OnRecycle(self)
	self:UnSubscribeEvts()
	self.m_RefreshUICallback = nil
	self.m_UpdateListCallBack = nil	
	table_release(self)
end

function LinkmanWidget:OnDestroy()
	self:UnSubscribeEvts()
	self.m_RefreshUICallback = nil
	self.m_UpdateListCallBack = nil	
	
	UIControl.OnDestroy(self)
	table_release(self)
end

return LinkmanWidget