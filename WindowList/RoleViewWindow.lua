-- 角色查看窗口
------------------------------------------------------------
local RoleViewWindow = UIWindow:new
{
	windowName = "RoleViewWindow",
	m_dwPDBID  = 0,             -- 当前查看角色的PDBID
    m_RoleInfo = nil,           -- 当前查看角色的缓存信息
    m_needRefreshRoleInfo = false,   -- 当前查看角色是否需要刷新显示内容
	m_dwClanID = 0,                  -- ?
	m_WaitingResp = false,		-- 正处于等待请求响应并获取回复的状态
	m_ButtonLayout = {},
	m_ButtonItems = {},
	
	m_RefreshUICallback = nil,
}

local UIContainer = require( "GuiSystem.UIContainer" )
local RoleViewWindowLayout = {}
------------------------------------------------------------
function RoleViewWindow:Init()
	RoleViewWindowLayout = {
		[1]  = { ["BtnTip"] = "添加好友",	["BtnFunc"] = handler(self, self.OnAddFriendClick) },
		[2]  = { ["BtnTip"] = "查看信息",	["BtnFunc"] = handler(self, self.OnViewInfoClick) },
		[3]  = { ["BtnTip"] = "申请入帮",	["BtnFunc"] = handler(self, self.OnApplyClanClick) },
		[4]  = { ["BtnTip"] = "邀请入帮",	["BtnFunc"] = handler(self, self.OnInviteClanClick) },
		[5]  = { ["BtnTip"] = "申请入队",	["BtnFunc"] = handler(self, self.OnApplyTeamClick), ["ShowFunc"] = handler(self, self.ChechHaveTeam) },
		[6]  = { ["BtnTip"] = "邀请入队",	["BtnFunc"] = handler(self, self.OnInviteTeamClick) },
		[7]  = { ["BtnTip"] = "私   聊",	["BtnFunc"] = handler(self, self.OnPrivateChatClick) },
		[8]  = { ["BtnTip"] = "进入梦岛",	["BtnFunc"] = handler(self, self.OnEnterDreamIslandClick) },
		[9]  = { ["BtnTip"] = "切   磋",	["BtnFunc"] = handler(self, self.OnStudyClick) },
		[10] = { ["BtnTip"] = "举   报",	["BtnFunc"] = handler(self, self.OnReportClick) },
		[11] = { ["BtnTip"] = "加入黑名单",	["BtnFunc"] = handler(self, self.OnBlacklistClick) },
		[12] = { ["BtnTip"] = "邀请同乘",	["BtnFunc"] = handler(self, self.OnInviteRideClick) },
		[13] = { ["BtnTip"] = "添加好友",	["BtnFunc"] = handler(self, self.OnAddFriendClick),	["ShowFunc"] = handler(self, self.Check,false)  },
		[14] = { ["BtnTip"] = "文字表情",	["BtnFunc"] = handler(self, self.OnFunnyWordBtnClick), ["ShowFunc"] = handler(self, self.Check,false)   },
		[15] = { ["BtnTip"] = "删   除",	["BtnFunc"] = handler(self, self.OnBtnDeleteClicked) },
		[16] = { ["BtnTip"] = "清空仇敌",	["BtnFunc"] = handler(self, self.OnClearEnemyClicked) },
		[17] = { ["BtnTip"] = "请求同乘",	["BtnFunc"] = handler(self, self.OnRequestRideClick) },
	 }
end
------------------------------------------------------------
function RoleViewWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	---------------------------------------------------------------------------------------------------
	self.Controls.m_FlowerBtn.onClick:AddListener(function() self:OnFlowerBtnClick() end)
	
    UIFunction.AddEventTriggerListener(self.Controls.m_CloseButton , EventTriggerType.PointerClick , function( eventData ) self:OnCloseButtonClick(eventData) end ) 

    if self:isShow() then
        if self.m_needRefreshRoleInfo then
			-- 异步加载完成在数据获取之后
            self:RefreshViewInfo()
        end
		
		if self.m_WaitingResp then
			-- kit:未设置完正确的数据前，不允许查看
			self:Hide()
		end
    end
	---------------------------------------------------------------------------------------------------
end
------------------------------------------------------------
function RoleViewWindow:Hide( destroy )
    UIWindow.Hide(self,destroy)
    self.m_needRefreshRoleInfo = false
	self.m_WaitingResp = false
end
------------------------------------------------------------
function RoleViewWindow:OnDestroy()
	UIWindow.OnDestroy(self)
    self.m_dwPDBID = 0
    self.m_RoleInfo = nil
    self.m_needRefreshRoleInfo = false
	self.m_WaitingResp = false
	self.m_ButtonLayout = {}
	self.m_ButtonItems = {}
	self.m_RefreshUICallback = nil
end

function RoleViewWindow:Check(state)
	return state
end
------------------------------------------------------------

------------------------------------------------------------------------------------
-------------------------------------动态按钮事件-----------------------------------
------------------------------------------------------------------------------------

-- 清空仇敌
function RoleViewWindow:OnClearEnemyClicked()
	IGame.FriendClient:OnDeleteAllEnemy()
	self:Hide()
end

-- 删除联系人
function RoleViewWindow:OnBtnDeleteClicked()
	if self.m_dwPDBID > 0 then
		IGame.FriendClient:OnRequestDeleteFriend(self.m_dwPDBID)
		self:Hide()
	end
end

-- 申请帮会按钮
function RoleViewWindow:OnApplyClanClick()
	-- dwClanID 帮会id
	
	IGame.ClanClient:JoinRequest(self.m_RoleInfo.nClanID)
	self:Hide()
end

-- 邀请帮会按钮
function RoleViewWindow:OnInviteClanClick()
	-- 玩家ID
	IGame.ClanClient:InviteRequest(self.m_dwPDBID)
	self:Hide()
end

-- 申请入队按钮
function RoleViewWindow:OnApplyTeamClick()
	-- todo
	IGame.TeamClient:RequestJoin(self.m_dwPDBID)
	self:Hide()
end

-- 邀请入队按钮
function RoleViewWindow:OnInviteTeamClick()
	-- 
	IGame.TeamClient:InvitedJoin(self.m_dwPDBID)
	self:Hide()
end

function RoleViewWindow:ChechHaveTeam()
	return true
end

-- 私聊
function RoleViewWindow:OnPrivateChatClick()
	UIManager.FriendEmailWindow:OnPrivateChat(self.m_dwPDBID)
	self:Hide()
end

-- 进入梦岛
function RoleViewWindow:OnEnterDreamIslandClick()
	-- todo
	IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "梦岛系统暂未开发")
end

-- 切磋
function RoleViewWindow:OnStudyClick()
	-- todo
	IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "切磋系统暂未开发")
end

-- 查看信息
function RoleViewWindow:OnViewInfoClick()
	-- todo
	IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "查看角色暂未开发")
end

-- 举报
function RoleViewWindow:OnReportClick()
	-- todo
	IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "举报功能暂未开发")
end

-- 黑名单
function RoleViewWindow:OnBlacklistClick()
	IGame.FriendClient:OnRequestAddBlack(self.m_dwPDBID)
	self:Hide()
end

-- 请求同乘
function RoleViewWindow:OnRequestRideClick()
	IGame.RideClient:RequestRideLift(self.m_dwPDBID, 2)
	self:Hide()
end

-- 邀请同乘
function RoleViewWindow:OnInviteRideClick()
	IGame.RideClient:RequestRideLift(self.m_dwPDBID, 1)
	self:Hide()
end

-- 添加好友
function RoleViewWindow:OnAddFriendClick()
	print("RoleViewWindow:OnAddFriendClick = "..self.m_dwPDBID)
	IGame.FriendClient:OnRequestAddFriend(self.m_dwPDBID)
	self:Hide()
end

-- 文字表情
function RoleViewWindow:OnFunnyWordBtnClick()
	UIManager.RichTextWindow:SetCWidgetType(7)
	UIManager.RichTextWindow:ShowOrHide(UIManager.ChatWindow)
	UIManager.RichTextWindow.RichTextFunnyWordWidget:SetTargetName(self.m_RoleInfo.szRoleName)
	self:Hide()
end

------------------------------------------------------------------------------------
-------------------------------------固定按钮事件-----------------------------------
------------------------------------------------------------------------------------
-- 送花
function RoleViewWindow:OnFlowerBtnClick()
   -- todo
	IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "送花功能暂时未开发")
end

function RoleViewWindow:OnCloseButtonClick( eventData )
    self:Hide()
    rkt.UIAndTextHelpTools.PassThroughPointerClickEvent( eventData )
end

------------------------------------------------------------------------------------
-------------------------------------数据和流程-------------------------------------
------------------------------------------------------------------------------------
-- 在Window:Show(true)后直接设置要查看的角色的PDBID,这意味着一定要从服务器获得对应人物的数据
function RoleViewWindow:SetViewInfo(dwPDBID)
	self.m_dwPDBID = dwPDBID
	IGame.ObserverPlayerManager:RequestPlayerInfo(dwPDBID)
	self.m_WaitingResp = true
end

-- 设置按钮数据,调用 SetViewInfo 后或者在调用UpdateViewInfo前，必须立刻设置
-- @param tLayout       : 要传入的按钮表，结构：
-- local tLayout = {1,2,3,} 按钮编号

function RoleViewWindow:SetButtonLayoutTable(tLayout)-- {1,2}
	self.m_ButtonLayout = {}
	for key,v in ipairs(tLayout) do
		if RoleViewWindowLayout[v] then
			table.insert(self.m_ButtonLayout,RoleViewWindowLayout[v])
		end
	end
end

function RoleViewWindow:SetPDBID(dwPDBID)
	print("RoleViewWindow:SetPDBID = "..dwPDBID)
	self.m_dwPDBID = dwPDBID
end

-- 服务器返回或者其他模块直接传来对应人物的数据(表),后者数据一定在UI异步载入完成前传入,前者未必
function RoleViewWindow:UpdateViewInfo(roleTable)
	cLog('RoleViewWindow:UpdateViewInfo  '..tostringEx(roleTable),"red")
    self.m_RoleInfo = roleTable
	self.m_WaitingResp = false
    if not self:isLoaded() then
        self.m_needRefreshRoleInfo = true
        return
    end
    self:RefreshViewInfo()
end
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
-------------------------------------显示  界面-------------------------------------
------------------------------------------------------------------------------------
function RoleViewWindow:RefreshViewInfo()
	if not self:isLoaded() then
		return
	end
    self.m_needRefreshRoleInfo = false

    local roleTable = self.m_RoleInfo
    if nil == roleTable then
        self:Hide()
        return
	else
		if self:isShow() then
			-- kit:未设置完正确的数据前，不允许查看
			self:Hide()
		end
    end
    
	local pHero = IGame.EntityClient:GetHero()
	if pHero == nil then 
        self:Hide()
		return
	end 
	
	-- 头像
	local nFaceId = roleTable.nFaceID
	-- 等级
	local nLevel  = roleTable.nLevel
	-- 名字
	local szRoleName  = roleTable.szRoleName
	-- 职业
	local nVocation = roleTable.nVocation
	-- 队伍ID
	local nTeamID   = roleTable.nTeamID
	-- 帮会ID
	local nClanID   = roleTable.nClanID
	-- 头衔ID
	local nHeadTitleID   = roleTable.nHeadTitleID
	
	self.Controls.m_LevelName.text = nLevel
	self.Controls.m_PlayerName.text = szRoleName
	cLog("RoleViewWindow:RefreshViewInfo   "..tostringEx(nFaceId))
	UIFunction.SetHeadImage(self.Controls.m_HeadImg, nFaceId)
	if nHeadTitleID == 0 then
		self.Controls.m_titleHeadTrs.gameObject:SetActive(false)
	else
		self.Controls.m_titleHeadTrs.gameObject:SetActive(true)
		UIFunction.SetCellHeadTitle(nHeadTitleID, self.Controls.m_titleHeadTrs, self.Controls)
	end
	
	
	self:RefreshBtnLayout()
	self:Show()
end

function RoleViewWindow:RefreshBtnLayout()
	if isTableEmpty(self.m_ButtonLayout) then
		return
	end
	
	local count = #self.m_ButtonLayout
	print("当前按钮数据数量="..count)
	self:HideBtns(count)
	local GuiRootPrefabPath = "Assets/AssetFolder/GUIAsset/Prefabs/"
	for i=1, count do
		local btn = self.m_ButtonItems[i]
		if not btn then
			local bShow = true
			if self.m_ButtonLayout[i].ShowFunc then
				bShow = self.m_ButtonLayout[i].ShowFunc()
			end
			if bShow then
				rkt.GResources.FetchGameObjectAsync( GuiRootPrefabPath .. "Player/RoleBtnTemplate.prefab",	
					function ( path , obj , ud )
						local controls = self.Controls
						
						obj.transform:SetParent(controls.m_ButtonWidget.transform)
						obj.transform.localScale = Vector3.New(1,1,1)
						obj.name = "RoleButton-"..i
						
						btn = UIContainer:new({})
						btn:Attach(obj)
						btn.windowName = "RoleButton"
						table.insert(self.m_ButtonItems,i,btn)
						
						-- 刷新Btn
						self:RefreshBtn(i, btn)
					end ,
				i , AssetLoadPriority.GuiNormal )
			end
		else
			self:RefreshBtn(i, btn)
		end
	end
end

function RoleViewWindow:HideBtns(count)
	for i,btn in pairs(self.m_ButtonItems) do
		if i > count then
			btn.transform.gameObject:SetActive(false)
		end
	end
	
	--[[table_remove_match(self.m_ButtonItems,function (b)
		return tolua.isnull( b )
	end)--]]
end

function RoleViewWindow:RefreshBtn(idx, btn)
	if not btn then btn = self.m_ButtonItems[idx] end
	local btnData = self.m_ButtonLayout[idx]
	-- 装配按钮
	-- btn:SetData(idx, self.m_ButtonLayout[idx])
	if btn and btnData then
		btn:RemoveAllListeners()
		btn.Controls.m_RoleButton.onClick:AddListener(btnData.BtnFunc)
		btn.Controls.m_ButtonTip.text = tostring(btnData.BtnTip)
		btn.transform.gameObject:SetActive(true)
		if idx >= #self.m_ButtonLayout then
			self:Show()
		end
	end
end
------------------------------------------------------------------------------------

return RoleViewWindow