-- 搜索玩家，并添加好友
-- @Author: LiaoJunXi
-- @Date:   2017-07-27 17:50:21
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-27 18:05:08

local FriendExplorerDialog = UIControl:new
{
	windowName = "FriendExplorerDialog",
	m_CurInputContent = "",
	
	m_NameInputer = nil,
	m_FriendClient = nil,
	m_SearchEvtCallBack = nil,
	m_Friend = nil
}

local this = FriendExplorerDialog

function FriendExplorerDialog:Attach( obj )
	UIControl.Attach(self, obj)	
	
	self:InitUI()
	self:SubscribeEvts()
	
	self.m_FriendClient = IGame.FriendClient
end

function FriendExplorerDialog:OnDestroy()	
	UIControl.OnDestroy(self)
	self:UnSubscribeEvts()
	table_release(self)
end

function FriendExplorerDialog:OnRecycle()	
	UIControl.OnRecycle(self)
	self:UnSubscribeEvts()
	table_release(self)
end

function FriendExplorerDialog:InitUI()
	local controls = self.Controls
	
	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_CancelBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_SearchBtn.onClick:AddListener(handler(self, self.OnBtnSearchClicked))
	controls.m_AddBtn.onClick:AddListener(handler(self, self.OnBtnAddClicked))
	controls.m_BackBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))	
	controls.m_BackgroundBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	
	self.m_NameInputer = controls.m_NameInputField:GetComponent(typeof(InputField))
end

function FriendExplorerDialog:OnBtnCloseClicked()
	self.Controls.m_SearchPanel.gameObject:SetActive(true)
	self.Controls.m_FriendPanel.gameObject:SetActive(false)
	
	self:Hide()
end

function FriendExplorerDialog:OnBtnSearchClicked()
	self.m_CurInputContent = self.m_NameInputer.text
	local txt = self.m_CurInputContent
	
	if txt ~= nil and txt ~= "" and txt ~= "输入玩家名字或ID" then
		local n = tonumber(txt);
		if n == nil then
			self.m_FriendClient:OnRequestSearchPlayer(0,self.m_CurInputContent)
		else
			self.m_FriendClient:OnRequestSearchPlayer(n,self.m_CurInputContent)
		end
	end
end

function FriendExplorerDialog:SubscribeEvts()
	self.m_SearchEvtCallBack = handler(self, self.OnSearchEvtCallBack)
	rktEventEngine.SubscribeExecute( EVENT_FRIEND_SEARCHFOR_NEWFRIEND, SOURCE_TYPE_FRIEND, 0, self.m_SearchEvtCallBack)
end

function FriendExplorerDialog:UnSubscribeEvts()
	rktEventEngine.UnSubscribeVote(EVENT_FRIEND_SEARCHFOR_NEWFRIEND , SOURCE_TYPE_FRIEND, 0, self.m_SearchEvtCallBack)	
end

-- 设置ceil数据到显示
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
function FriendExplorerDialog:OnSearchEvtCallBack(event, srctype, srcid, data)
	self.m_Friend = data
	self.m_NameInputer.text = ""
	
	if self.m_Friend ~= nil then
		local controls = self.Controls
		
		controls.m_SearchPanel.gameObject:SetActive(false)
		controls.m_FriendPanel.gameObject:SetActive(true)
		
		controls.m_TitleTxt.text = ""
		if UIFunction.SetCellHeadTitle(data.m_btHeadTitleID, controls.m_Title, controls) then
			local pos = Vector3.New(183, 55.7, 0)
			controls.m_NameTxt.transform.localPosition = pos
		else
			local pos = Vector3.New(95, 55.7, 0)
			controls.m_NameTxt.transform.localPosition = pos
		end
		controls.m_NameTxt.text = data.m_name
		controls.m_LevTxt.text = data.m_level .. "级"
		controls.m_JobTxt.text = GameHelp.GetVocationName(data.m_vocation)
		
		print("data.m_faceID = "..data.m_faceID)
--[[		if PERSON_VOCATION_LINGXIN == data.m_vocation then
			data.m_faceID = 2
		elseif data.m_faceID == 31 then
			data.m_faceID = 1
		end--]]
		UIFunction.SetHeadImage(controls.m_AvatarIcon,data.m_faceID)
		controls.m_AvatarIcon:SetNativeSize()
	end
end

function FriendExplorerDialog:OnBtnAddClicked()
	self:OnBtnCloseClicked()
	
	if self.m_Friend ~= nil then
		self.m_FriendClient:OnRequestAddFriend(self.m_Friend.m_pdbid)
		--IGame.ChatClient:addSystemTips(TipType_Operate,InfoPos_ActorUnder,"已向对方发送好友请求，请等待对方确认。")
	end
end

return FriendExplorerDialog