-- 好友系统窗口
-- @Author: LiaoJunXi
-- @Date:   2017-07-26 12:25:45
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-26 12:50:45

-- 功能点（需求）：
-- 显示 背景+按钮->标题（包括ICON）
-- 左侧功能
-- (OK)一、通用：1.实现->2个tgl，2.单个个好友格信息，3.默认选中TGL=最近，4.默认选中第一个好友，保留上一次选中信息（最近or联系人+选中的对象格）（2h）
-- (OK)二、联系人：1.好友在线数量（标签），2.再开收起动画和遮罩，对应栏图标变化，3。三个分类，默认打开第一个(2h)
-- (OK)三、点击头像：1.根据好友分类配置不同功能入口标签。(1h)
-- (OK)四、添加好友：1.搜索界面，2.搜索到目标（添加），3未搜索到目标（弹出提示）（1h）,4.好友设置勾选效果
-- 右侧聊天功能
-- 点击清空；使用聊天功能模块（8h）

local FriendWidget = UIControl:new
{
	windowName = "FriendWidget",
	
	m_TabToggles = {}, --联系人分类标签（最近和联系人两种）
	m_LinkmanToggles = {}, --联系人具体分类标签（好友，仇敌，黑名单）
	m_ToggleArrows = {}, --联系人分类标签 箭头标志
	
	m_SelLefTabIdx = 0, --当前左侧选择的联系人标签类别Id
	m_SelLinkmanTabIdx = 0, --当前左侧选择的联系人标签详细类别Id
	m_SelLinkmanIdx = 0, -- 当前选中并展示聊天(友好度)内容的联系人Id
	
	m_JumpToIdx = 1,	
	
	m_ViewPos_Original = { -5.5, -46, 0 }, -- 好友列表视图初始(最近标签)位置
	
	m_ViewPos_Friend = {-5.5, -12, 0}, -- 好友列表视图打开好友标签时位置
	m_ViewPos_Enemy = {-5.5, -80, 0}, -- 好友列表视图打开仇人标签时位置
	m_ViewPos_Blacklist = {-5.5, -150, 0}, -- 好友列表视图打开黑名单标签时位置
	
	m_ViewScope_Recently = {493.5,654},
	m_ViewScope_LinkmanList = {493.5,442},
	
	m_ViewPosList = {},
	
	m_EnemyTab_TopPos = {-5, 32, 0}, -- 好友列表仇人标签顶部所在位置
	m_EnemyTab_BottomPos = {-5, -408, 0}, -- 好友列表仇人标签底部所在位置
	m_BlacklistTab_TopPos = {-5, -39, 0},
	m_BlacklistTab_BottomPos = {-5, -478, 0},
	
	m_LinkmanList = {}, --当前展示的联系人Data列表
	m_LinkmanItems = {}, --当前展示的联系人Item列表
	
	m_FriendOnlineCount = 0, -- 在线好友的数量
	m_FriendCount = 0, -- 当前好友的数量
	m_EnemyOnlineCount = 0,
	m_EnemyCount = 0,
	m_BlackOnlineCount = 0,
	m_BlackCount = 0,
	
	m_LinkmanBoards = {}, -- 点击头像，打开该联系人详细信息的面板，有四种
	m_LinkmanBoardLuaScripts = {}, -- 对应联系人详细信息面板的lua脚本实例
	
	-- m_EventHandler = {},
	
	m_FriendExplorerLua = nil,
	m_FriendSettingLua = nil,
	m_LinkmanChatViewLua = nil,
	m_FriendBeApplyListLua = nil,
	
	m_FriendClient = nil,
	
	m_RefreshUICallback = nil,
	m_IsSystolic = false
}

local TabToggles = 
{
	["Recently"] = 1,
	["All"]  = 2 ,
}

local LinkmanToggles = 
{
	["Friend"] = 1,
	["Enemy"]  = 2 ,
	["Blacklist"] = 3
}

local Relation =
{
	["Stranger"] = 1,
	["Friend"] = 2,
	["Enemy"]  = 3,
	["Blacklist"] = 4
}

local this = FriendWidget
local LinkmanCeil = require( "GuiSystem.WindowList.FriendEmail.LinkmanCeil" )
local LinkmanChatView = require( "GuiSystem.WindowList.FriendEmail.LinkmanChatView" )

------------------------------------------公共重载方法开始------------------------------------------
function FriendWidget:Attach( obj )
	UIControl.Attach(self, obj)
	
	self:InitUI()
	
	self:SubscribeEvts()
	
	self.m_FriendClient = IGame.FriendClient
	
	self.m_TabToggles[TabToggles.Recently].isOn = true
end

function FriendWidget:OnDestroy()
	self:UnSubscribeEvts()
	self.m_RefreshUICallback = nil
	self:OnLuaInstanceRecycle()
	
	UIControl.OnDestroy(self)	
	table_release(self)
end

function FriendWidget:OnRecycle()
	UIControl.OnRecycle(self)
	self:UnSubscribeEvts()
	self.m_RefreshUICallback = nil
	self:OnLuaInstanceRecycle()
	
	table_release(self)
end

function FriendWidget:OnLuaInstanceRecycle()
	self.m_LinkmanChatViewLua = nil
	self.m_FriendExplorerLua = nil
	self.m_FriendSettingLua = nil
	self.m_LinkmanChatViewLua = nil
	self.m_FriendBeApplyListLua = nil
end

function FriendWidget:Hide(destory)
	UIControl.Hide(self)
end

function FriendWidget:InitUI()
	local controls = self.Controls
	
	-- init scrollView
	local scrollView  = controls.m_FriendList
	local listView = scrollView:GetComponent(typeof(EnhancedListView))
	listView.onGetCellView:AddListener(handler(self, self.OnGetCellView))
	listView.onCellViewVisiable:AddListener(handler(self, self.OnCellRefreshVisible))
	controls.listView = listView
	controls.scrollView = scrollView
	controls.scrollRect = scrollView:GetComponent(typeof(RectTransform))
	
	local listScroller = scrollView:GetComponent(typeof(EnhancedScroller))
	controls.listScroller = listScroller
	
	-- init linkman chat-view
	self.m_LinkmanChatViewLua = LinkmanChatView:new({})
	self.m_LinkmanChatViewLua:Attach(controls.m_LinkmanChatView.gameObject)

	-- ToggleGroup for Linkman ceils
	controls.listTglGroup  = controls.m_ViewPort:GetComponent(typeof(ToggleGroup))
	
	-- BtnFunc for <add> and <setting>
	controls.m_AddFriendBtn.onClick:AddListener(handler(self, self.OnBtnAddFriendClicked))
	controls.m_SettingBtn.onClick:AddListener(handler(self, self.OnBtnSettingClicked))
	controls.m_ApplicantsBtn.onClick:AddListener(handler(self, self.OnBtnApplicantsClicked))
	
	-- ToggleFunc for <Recently> and <All>
	self.m_TabToggles = {
		controls.m_RecentlyTgl,
		controls.m_AllTgl
	}
	for i=1, 2 do
		local tgl = self.m_TabToggles[i]
		tgl.onValueChanged:AddListener(function (on)
			self:OnTogglesChanged(i, on)
		end)
	end
	
	-- ToggleFunc for <Friend>, <Enemy> and <Blacklist>
	self.m_LinkmanToggles = {
		controls.m_FriendTgl,
		controls.m_EnemyTgl,
		controls.m_BlackTgl
	}
	for i=1, 3 do
		local tgl = self.m_LinkmanToggles[i]
		tgl.onValueChanged:AddListener(function (on)
			self:OnLinkmanTogglesChanged(i, on)
		end)
		
		self.m_ToggleArrows[i] = tgl.transform:Find("Arrow"):GetComponent(typeof(UnityEngine.UI.Image))
	end
	
	-- ScrollView positions, select one after tab changed
	self.m_ViewPosList = {
		self.m_ViewPos_Friend,
		self.m_ViewPos_Enemy,
		self.m_ViewPos_Blacklist
	}
	
	-- Linkman info and action board
	self.m_LinkmanBoards = {
		controls.m_StrangerBoard,
		controls.m_FriendBoard,
		controls.m_EnemyBoard,
		controls.m_BlackerBoard
	}
end

function FriendWidget:SubscribeEvts()
	self.m_RefreshUICallback = handler(self, self.RefreshUI)
	rktEventEngine.SubscribeExecute( EVENT_FRIEND_UPDATELIST, SOURCE_TYPE_FRIEND, 0, self.m_RefreshUICallback)
end

function FriendWidget:UnSubscribeEvts()
	rktEventEngine.UnSubscribeVote(EVENT_FRIEND_UPDATELIST , SOURCE_TYPE_FRIEND, 0, self.m_RefreshUICallback)
end
------------------------------------------公共重载方法结束------------------------------------------

-- 刷新UI
function FriendWidget:RefreshUI()
	self:ShowApplyRedDot(self.m_FriendClient.m_BeAddFlag)
	if self.m_SelLefTabIdx == 0 then
		self.m_SelLefTabIdx = TabToggles.Recently
	end
	--刷新Recent列表
	if self.m_SelLefTabIdx == TabToggles.Recently then
		self:OnRecentListUIRefurbish()
	elseif self.m_SelLefTabIdx == TabToggles.All then
		if self.m_SelLinkmanTabIdx == LinkmanToggles.Friend then
			self:OnFriendListUIRefurbish()
		elseif self.m_SelLinkmanTabIdx == LinkmanToggles.Enemy then
			self:OnEnemyListUIRefurbish()
		else
			self:OnBlackListUIRefurbish()
		end
	end
end

function FriendWidget:ShowRecentlyRedDot(flag)
	if not self:isLoaded() then
		return
	end
	UIFunction.ShowRedDotImg(self.m_TabToggles[TabToggles.Recently].transform,flag)
end

function FriendWidget:ShowApplyRedDot(flag)
	if not self:isLoaded() then
		return
	end
	local controls = self.Controls
	UIFunction.ShowRedDotImg(controls.m_ApplicantsBtn.transform,flag)
end

-- <最近>和<联系人>之间切换tab
function FriendWidget:OnTogglesChanged(idx, on)
	if on and self.m_SelLefTabIdx ~= idx then
		if self.m_SelLefTabIdx ~= 0 then
			self:SwitchTab(idx)
		else
			self:SetAsRecentlyLayout()
			self:RefreshUI()
		end
	end
end

function FriendWidget:ShowOrHideItems(flag)
	if #self.m_LinkmanItems > 0 then
		for i=0, #self.m_LinkmanItems do
			if self.m_LinkmanItems[i] and self.m_LinkmanItems[i].transform then
				if not flag then
					self.m_LinkmanItems[i]:Disappear()
				else
					self.m_LinkmanItems[i]:Appear()
				end
			end
		end
	end
end

-- <好友><仇人><黑名单>之间切换tab
function FriendWidget:OnLinkmanTogglesChanged(idx, on)
	print("<color=yellow>idx = "..idx..",on = "..tostring(on)..", and self.m_SelLinkmanTabIdx = "..self.m_SelLinkmanTabIdx.."</color>")
	print("before: self.m_IsSystolic = "..tostring(self.m_IsSystolic))
	if on and self.m_IsSystolic and self.m_SelLinkmanTabIdx ~= idx then
		self.m_IsSystolic = false
	end
	if on and self.m_SelLinkmanTabIdx ~= idx then
		if self.m_SelLinkmanTabIdx ~= 0 then
			self:SwitchLinkmanTab(idx)
		end
	elseif on and self.m_SelLinkmanTabIdx == idx then
		if not self.m_IsSystolic then
			--local listView = self.Controls.listView
			self:ResetLinkmanViewTabPosition()
			self:ShowOrHideItems(false)
			self:ShowSystolicArrow(idx)
		else
			self.m_IsSystolic = false
			if self.m_SelLinkmanTabIdx ~= 0 then
				self:SwitchLinkmanTab(idx)
			end
		end
	end
	print("affter: self.m_IsSystolic = "..tostring(self.m_IsSystolic))
end

function FriendWidget:ShowSystolicArrow(idx)
	UIFunction.SetImageSprite(self.m_ToggleArrows[idx], AssetPath.TextureGUIPath.."Common_frame/Common_fenglan_shousuo.png")
end

function FriendWidget:ResetLinkmanViewTabPosition()
	self.m_LinkmanToggles[LinkmanToggles.Enemy].transform.localPosition = 
	Vector3.New(self.m_EnemyTab_TopPos[1], self.m_EnemyTab_TopPos[2], self.m_EnemyTab_TopPos[3])
	
	self.m_LinkmanToggles[LinkmanToggles.Blacklist].transform.localPosition = 
	Vector3.New(self.m_BlacklistTab_TopPos[1], self.m_BlacklistTab_TopPos[2], self.m_BlacklistTab_TopPos[3])
	
	self.m_IsSystolic = true
end

function FriendWidget:OnLinkmanViewPositioning(idx)
	if self.m_ViewPosList[idx] ~= nil then
		local pos = Vector3.New(self.m_ViewPosList[idx][1], self.m_ViewPosList[idx][2], self.m_ViewPosList[idx][3])
		self.Controls.listView.transform.localPosition = pos
	end
	
	if idx == LinkmanToggles.Friend then
		local pos_1 = Vector3.New(self.m_EnemyTab_BottomPos[1], self.m_EnemyTab_BottomPos[2], self.m_EnemyTab_BottomPos[3])
		self.m_LinkmanToggles[LinkmanToggles.Enemy].transform.localPosition = pos_1
		
		local pos_2 = Vector3.New(self.m_BlacklistTab_BottomPos[1], self.m_BlacklistTab_BottomPos[2], self.m_BlacklistTab_BottomPos[3])
		self.m_LinkmanToggles[LinkmanToggles.Blacklist].transform.localPosition = pos_2
	elseif idx == LinkmanToggles.Enemy then
		self.m_LinkmanToggles[LinkmanToggles.Enemy].transform.localPosition = 
		Vector3.New(self.m_EnemyTab_TopPos[1], self.m_EnemyTab_TopPos[2], self.m_EnemyTab_TopPos[3])

		self.m_LinkmanToggles[LinkmanToggles.Blacklist].transform.localPosition = 
		Vector3.New(self.m_BlacklistTab_BottomPos[1], self.m_BlacklistTab_BottomPos[2], self.m_BlacklistTab_BottomPos[3])
	elseif idx == LinkmanToggles.Blacklist then
		self.m_LinkmanToggles[LinkmanToggles.Enemy].transform.localPosition = 
		Vector3.New(self.m_EnemyTab_TopPos[1], self.m_EnemyTab_TopPos[2], self.m_EnemyTab_TopPos[3])

		self.m_LinkmanToggles[LinkmanToggles.Blacklist].transform.localPosition = 
		Vector3.New(self.m_BlacklistTab_TopPos[1], self.m_BlacklistTab_TopPos[2], self.m_BlacklistTab_TopPos[3])
	end
end

function FriendWidget:SwitchTab(idx)
	self:ResetListView()
	
	local listView = self.Controls.listView
	
	self.m_SelLefTabIdx = idx
	
	if idx == TabToggles.Recently then
		self:SetAsRecentlyLayout()
	else
		if self.m_SelLinkmanTabIdx == 0 then self.m_SelLinkmanTabIdx = 1 end
		self:SetAsLinkmanListLayout()
	end
	self:RefreshUI()
end

function FriendWidget:SetAsRecentlyLayout()
	self:ShowOrHideItems(true)
	self.m_IsSystolic = false
	
	self.Controls.listView.transform.localPosition = 
	Vector3.New(self.m_ViewPos_Original[1],self.m_ViewPos_Original[2],self.m_ViewPos_Original[3])
		
	self.Controls.scrollRect.sizeDelta = Vector2.New(self.m_ViewScope_Recently[1], self.m_ViewScope_Recently[2])
		
	self.Controls.m_LinkmanTglGroup.gameObject:SetActive(false)
end

function FriendWidget:SetAsLinkmanListLayout()
	self.Controls.scrollRect.sizeDelta = Vector2.New(self.m_ViewScope_LinkmanList[1], self.m_ViewScope_LinkmanList[2])
		
	self.Controls.m_LinkmanTglGroup.gameObject:SetActive(true)
	self:OnLinkmanViewPositioning(self.m_SelLinkmanTabIdx)
end

function FriendWidget:SwitchLinkmanTab(idx)
	self:ShowOrHideItems(true)
	self:ResetListView()
	
	self.m_SelLinkmanTabIdx = idx
	self:RefreshUI()
	
	self:OnLinkmanViewPositioning(idx)
end

------ 获取列表请求的回调事件 ------
-- 最近类型
function FriendWidget:OnRecentListUIRefurbish()
	if nil ~= self.m_FriendClient.GetLastList then
		self.m_LinkmanList = self.m_FriendClient:GetLastList()
		if nil ~= self.m_LinkmanList then
			print("FriendWidget:On RecentList UI Refurbish + cnt=" .. #self.m_LinkmanList)
		end
	end
		
	self:ReloadLinkmanListUI()
end

-- Friend类型
function FriendWidget:OnFriendListUIRefurbish()
	self:OnFriendOnlineCount();
	
	self.m_EnemyCount = #self.m_FriendClient:GetEnemyList(true)
	self.m_EnemyOnlineCount = self.m_FriendClient:GetEnemyOnlineCount()
	self.Controls.m_EnemyTglTxt.text = "<color=#1BA2F4>" .. self.m_EnemyOnlineCount .. "</color>/" .. self.m_EnemyCount
	
	self.m_BlackCount = #self.m_FriendClient:GetBlackList(true)
	self.m_BlackOnlineCount = self.m_FriendClient:GetBlackOnlineCount()
	self.Controls.m_BlackTglTxt.text = "<color=#1BA2F4>" .. self.m_BlackOnlineCount .. "</color>/" .. self.m_BlackCount	
	
	self:ReloadLinkmanListUI()
end

function FriendWidget:OnFriendOnlineCount()
	self.m_LinkmanList = self.m_FriendClient:GetFriendList()
	print("FriendWidget:OnFriendListUIRefurbish+cnt=" .. #self.m_LinkmanList)
	
	self.m_FriendCount = #self.m_LinkmanList
	self.m_FriendOnlineCount = self.m_FriendClient:GetFriendOnlineCount()
	self.Controls.m_FriendTglTxt.text = "<color=#1BA2F4>" .. self.m_FriendOnlineCount .. "</color>/" .. self.m_FriendCount
end

-- Enemy类型
function FriendWidget:OnEnemyListUIRefurbish()
	self.m_LinkmanList = self.m_FriendClient:GetEnemyList()
	
	self.m_EnemyCount = #self.m_LinkmanList
	self.m_EnemyOnlineCount = self.m_FriendClient:GetEnemyOnlineCount()
	self.Controls.m_EnemyTglTxt.text = "<color=#1BA2F4>" .. self.m_EnemyOnlineCount .. "</color>/" .. self.m_EnemyCount
	
	self.m_FriendCount = #self.m_FriendClient:GetFriendList(true)
	self.m_FriendOnlineCount = self.m_FriendClient:GetFriendOnlineCount()
	self.Controls.m_FriendTglTxt.text = "<color=#1BA2F4>" .. self.m_FriendOnlineCount .. "</color>/" .. self.m_FriendCount
	
	self.m_BlackCount = #self.m_FriendClient:GetBlackList(true)
	self.m_BlackOnlineCount = self.m_FriendClient:GetBlackOnlineCount()
	self.Controls.m_BlackTglTxt.text = "<color=#1BA2F4>" .. self.m_BlackOnlineCount .. "</color>/" .. self.m_BlackCount	
		
	self:ReloadLinkmanListUI()
end
--------------------------------------

-- Black类型
function FriendWidget:OnBlackListUIRefurbish()
	self.m_LinkmanList = self.m_FriendClient:GetBlackList()
	
	self.m_BlackCount = #self.m_LinkmanList
	self.m_BlackOnlineCount = self.m_FriendClient:GetBlackOnlineCount()
	self.Controls.m_BlackTglTxt.text = "<color=#1BA2F4>" .. self.m_BlackOnlineCount .. "</color>/" .. self.m_BlackCount	

	self.m_FriendCount = #self.m_FriendClient:GetFriendList(true)
	self.m_FriendOnlineCount = self.m_FriendClient:GetFriendOnlineCount()
	self.Controls.m_FriendTglTxt.text = "<color=#1BA2F4>" .. self.m_FriendOnlineCount .. "</color>/" .. self.m_FriendCount
	
	self.m_EnemyCount = #self.m_FriendClient:GetEnemyList(true)
	self.m_EnemyOnlineCount = self.m_FriendClient:GetEnemyOnlineCount()
	self.Controls.m_EnemyTglTxt.text = "<color=#1BA2F4>" .. self.m_EnemyOnlineCount .. "</color>/" .. self.m_EnemyCount
	
	self:ReloadLinkmanListUI()
end

-- 重置列表视图
function FriendWidget:ResetListView()
	local controls = self.Controls
	if nil ~= controls.listTglGroup then
		controls.listTglGroup:SetAllTogglesOff()
	end
	self.m_SelLinkmanIdx = 0
end

-- 刷新联系人列表
function FriendWidget:ReloadLinkmanListUI()
	self:ResetListView()

	local listView = self.Controls.listView
	local cnt = #self.m_LinkmanList
	print("FriendWidget:ReloadLinkmanListUI+cnt=" .. cnt)
	
	if not self:isShow() then
		--return
	end
	if listView and not self.m_IsSystolic then
		listView:SetCellCount( cnt , true )
		--listView:ReloadData()
	else
		cLog("FriendWidget:ReloadLinkmanListUI- self.Controls.listView is nil","red")
	end

	if cnt < 1 then
		self:HideTalkBox()
	else
		if not self.m_IsSystolic then
			self:ShowTalkBox()
			self:SelectCell(1)
		end
	end

	--controls.m_EmptyWarn.gameObject:SetActive(cnt < 1)
	
	UIManager.FriendEmailWindow:RefreshRedDot()
end

function FriendWidget:HideTalkBox()
	if self.m_LinkmanChatViewLua ~= nil and self.m_LinkmanChatViewLua.Hide ~= nil then
		self.m_LinkmanChatViewLua:Hide()
	end
end

function FriendWidget:ShowTalkBox()
	if self.m_LinkmanChatViewLua ~= nil and self.m_LinkmanChatViewLua.Show ~= nil then
		self.m_LinkmanChatViewLua:Show()
	end
end

-- EnhancedListView 一行被“创建”时的回调
function FriendWidget:OnGetCellView( goCell )	
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler(self, self.OnCellRefreshVisible)
	self:CreateCellItems(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function FriendWidget.OnCellRefreshVisible( goCell )
	if goCell.GetComponent == nil then
		return
	end
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	this:RefreshCellItems(listcell)
end

-- 创建条目
function FriendWidget:CreateCellItems( listcell )
	local item = LinkmanCeil:new({})
	item:Attach(listcell.gameObject)
	item:SetToggleGroup(self.Controls.listTglGroup)
	item:SetSelectCallback(handler(self, self.OnItemCellSelected))
	item:SetAvatarCallback(handler(self, self.OnItemAvatarSelected))
	self:RefreshCellItems(listcell)

	local idx = listcell.dataIndex + 1
	self.m_LinkmanItems[idx] = item

	if self.m_JumpToIdx == idx then
		local idx = self.m_JumpToIdx
		self.m_JumpToIdx = 0

		rktTimer.SetTimer( function ()
			self:SelectCell(idx)
		end, 200 , 1 , "SelectCell" )
	end
end

--- 刷新列表
function FriendWidget:RefreshCellItems( listcell )
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	
	local item = behav.LuaObject
	if item ~= nil and item.windowName == "LinkmanCeil" then
		local idx = listcell.dataIndex + 1
		item:SetCellData(idx, self.m_LinkmanList[idx])

		item:SetToggleIsOn(idx == self.m_SelLinkmanIdx)
		
		--[[if self.m_IsSystolic then
			item:Disappear()
		else
			item:Appear()
		end--]]
	end
end

-- 选中某条目
function FriendWidget:SelectCell(idx)
	if self.m_LinkmanList[idx] and self.m_LinkmanItems[idx] then
		self.m_LinkmanItems[idx]:SetToggleIsOn(true)
		self.Controls.listScroller:JumpToDataIndex(idx-1, 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0.2 , nil)
		-- self:OnItemCellSelected(idx)
	end
end

-- 获取某条目
function FriendWidget:GetCell(data_id)
	local idx = 0
	if data_id > 0 and self.m_LinkmanList ~= nil then
		local count = #self.m_LinkmanList
		for i=1,count do
			if nil ~= self.m_LinkmanList[i] and self.m_LinkmanList[i].m_pdbid == data_id then
				idx = i
			end
		end
	end
	if idx > 0 and self.m_LinkmanItems ~= nil then
		return self.m_LinkmanItems[idx]
	end
	return nil
end

-- 选中ceil事件
function FriendWidget:OnItemCellSelected(idx)
	if idx == self.m_SelLinkmanIdx then
		return
	end
	
	local data = self.m_LinkmanList[idx]
	if data == nil then
		self.m_SelLinkmanIdx = 0
		return
	end
	self.m_SelLinkmanIdx = idx
	local nBlack = self.m_FriendClient:IsBlack(data.m_pdbid)
	-- 根据点击的ceil刷新右侧聊天信息
	self.m_LinkmanChatViewLua:SetCurLinkmanData(data)
	
	local nContainer = self.m_LinkmanChatViewLua.Controls.m_ChatCellList.transform:Find("Container")
	if nContainer then print("enter") nContainer.gameObject:SetActive(not nBlack) end
	
	if nil ~= self.m_LinkmanList then
		local count = #self.m_LinkmanList
		for i=1,count do
			if nil ~= self.m_LinkmanList[i] and self.m_LinkmanList[i].m_pdbid ~= data.m_pdbid then
				if self.m_LinkmanItems and self.m_LinkmanItems[i] then
					self.m_LinkmanItems[i]:ShowOrHideRedDot(not self.m_LinkmanList[i].hasRead)
				end
			end
		end
	end
end
--[[local Relation =
{
	["Stranger"] = 1,
	["Friend"] = 2,
	["Enemy"]  = 3,
	["Blacklist"] = 4
}--]]
-- 选中头像框
function FriendWidget:OnItemAvatarSelected(idx)
	-- 更新好友列表，获得最新变动
	if not self.m_LinkmanList or #self.m_LinkmanList == 0 then
		if self.m_SelLefTabIdx == TabToggles.Recently then
			self.m_LinkmanList = self.m_FriendClient:GetLastList()
		elseif self.m_SelLefTabIdx == TabToggles.All then
			if self.m_SelLinkmanTabIdx == LinkmanToggles.Friend then
				self.m_LinkmanList = self.m_FriendClient:GetFriendList()
			elseif self.m_SelLinkmanTabIdx == LinkmanToggles.Enemy then
				self.m_LinkmanList = self.m_FriendClient:GetEnemyList()
			else
				self.m_LinkmanList = self.m_FriendClient:GetBlackList()
			end
		end
	end
	-- 获得联系人数据
	local data = self.m_LinkmanList[idx]
	if data == nil then
		self.m_SelLinkmanIdx = 0
		return
	end
	
	--self.m_SelLinkmanIdx = idx
	
	-- 确定关系
	local nRoleBtnTable = {}
	
	if data.byFriendDivideRelation == GROUP_ID_ENEMY then
		nRoleBtnTable = {4,3,9,2,10,6,11,5,8,1,15,16}
	elseif data.byFriendDivideRelation == GROUP_ID_BLACKLIST then
		nRoleBtnTable = {1,15}
	elseif data.byFriendDivideRelation == GROUP_ID_STRANGER then
		nRoleBtnTable = {4,3,9,2,10,6,11,5,8,1,15}
	else -- 好友
		nRoleBtnTable = {4,3,9,2,10,6,11,5,8,15}
	end
	
	-- 获得队伍ID
	local team = IGame.TeamClient:GetTeam()
	local nTeamID = GetValuable(not team, 0, team:GetTeamID())

	-- 人物数据
	local roleTable = { ["nFaceID"] = data.m_faceID, ["nLevel"] = data.m_level, ["szRoleName"] = data.m_name,
						["nVocation"] = data.m_vocation, ["nTeamID"] = nTeamID, ["nClanID"] = data.clanID,
						["nHeadTitleID"] = data.m_btHeadTitleID }
	
	-- 设置角色面板数据
	UIManager.RoleViewWindow:SetPDBID(data.m_pdbid)
    UIManager.RoleViewWindow:SetButtonLayoutTable(nRoleBtnTable)
	
	-- 显示角色面板
	UIManager.RoleViewWindow:Show(true)
	UIManager.RoleViewWindow:UpdateViewInfo(roleTable)
end

-- 点击添加好友
function FriendWidget:OnBtnAddFriendClicked()
	if not self.m_FriendExplorerLua then
		self.m_FriendExplorerLua = require( "GuiSystem.WindowList.FriendEmail.FriendExplorerDialog" )
		if self.m_FriendExplorerLua ~= nil then
			self.m_FriendExplorerLua:Attach(self.Controls.m_FriendExplorer.gameObject)
		else
			print("file is not exist!")
		end
	end
	
	self.m_FriendExplorerLua:Show()
end

-- 点击好友功能设置
function FriendWidget:OnBtnSettingClicked()
	if not self.m_FriendSettingLua then
		self.m_FriendSettingLua = require( "GuiSystem.WindowList.FriendEmail.FriendSettingDialog" )
		self.m_FriendSettingLua:Attach(self.Controls.m_FriendSetting.gameObject)
	end
	
	self.m_FriendSettingLua:Show()
end

function FriendWidget:OnBtnApplicantsClicked()
	if not self.m_FriendBeApplyListLua then
		self.m_FriendBeApplyListLua = require( "GuiSystem.WindowList.FriendEmail.FriendApplicantsView" )
		self.m_FriendBeApplyListLua:Attach(self.Controls.m_FriendApplicants.gameObject)
	end
	self.m_FriendBeApplyListLua:Show()
end

return FriendWidget