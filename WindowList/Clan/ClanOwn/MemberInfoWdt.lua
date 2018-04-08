-- 帮会成员信息界面
-- @Author: XieXiaoMei
-- @Date:   2017-04-18 09:36:19
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-13 16:51:23

local MemberInfoWdt = UIControl:new
{
	windowName      = "MemberInfoWdt",

	m_Member 	= nil,
}

-------------------------------------------------------------------------------
-- 初始化
function MemberInfoWdt:Attach( obj )
	UIControl.Attach(self,obj)

	local btnHandlers = 
	{
		["m_AppointBtn"] = self.OnBtnAppointClicked,
		["m_DismissBtn"] = self.OnBtnDismissClicked,
		["m_SendMsglBtn"] = self.OnBtnSendMsgClicked,
		["m_AddAsFriendBtn"] = self.OnBtnAddAsFriendClicked,
		--["m_AstrictSpeakBtn"] = self.OnBtnAstrictSpeakClicked,
		["m_LookAtInfoBtn"] = self.OnBtnLookAtInfoClicked,
		["m_LookAtMDBtn"] = self.OnBtnLookAtMengDaoClicked,
	}
	local controls = self.Controls
	for k, v in pairs(btnHandlers) do
		self:AddListener(controls[k], "onClick", v, self)
	end

	-- 点击ScrollView外的区域全部将本窗口隐藏
	UIFunction.AddEventTriggerListener( self.Controls.m_UpCloseBtn , EventTriggerType.PointerClick , function( eventData ) self:OnBtnCloseClicked(eventData) end )
	UIFunction.AddEventTriggerListener( self.Controls.m_DownCloseBtn , EventTriggerType.PointerClick , function( eventData ) self:OnBtnCloseClicked(eventData) end )
	UIFunction.AddEventTriggerListener( self.Controls.m_RightCloseBtn , EventTriggerType.PointerClick , function( eventData ) self:OnBtnCloseClicked(eventData) end )
	UIFunction.AddEventTriggerListener( self.Controls.m_ScrollCloseBtn , EventTriggerType.PointerClick , function( eventData ) self:OnBtnCloseClicked(eventData) end )
	UIFunction.AddEventTriggerListener( self.Controls.m_LeftCloseBtn , EventTriggerType.PointerClick , function( eventData ) self:OnBtnCloseClicked(eventData) end )
end

-------------------------------------------------------------------------------
-- 显示
function MemberInfoWdt:Show( bringTop , onLoaded, data)
	UIControl.Show(self, bringTop , onLoaded)

	local controls = self.Controls

	local btn = controls["m_DismissBtn"]
	local bHasPopedom = IGame.ClanClient:HasKickPopedom(data.nIdentity)
	btn.gameObject:SetActive(bHasPopedom)

	btn = controls["m_AppointBtn"]
	bHasPopedom = IGame.ClanClient:HasAppointPopedom(data.nIdentity)
	btn.gameObject:SetActive(bHasPopedom)

	--btn = controls["m_AstrictSpeakBtn"]
	--bHasPopedom = IGame.ClanClient:HasBanRemarksPopedom(data.nIdentity)
	--btn.gameObject:SetActive(bHasPopedom)

	btn = controls["m_AddAsFriendBtn"]
	local bWasFriend = IGame.FriendClient:IsFriend(data.dwPDBID)
	btn.gameObject:SetActive(not bWasFriend)

	self.m_Member = data
end

-------------------------------------------------------------------------------
-- 隐藏
function MemberInfoWdt:Hide(destroy)
	UIControl.Hide(self, destroy)

	self.m_Member = nil
end

-------------------------------------------------------------------------------
-- 关闭按钮按下事件
function MemberInfoWdt:OnBtnCloseClicked(eventData)
	self:Hide()

	rkt.UIAndTextHelpTools.PassThroughPointerClickEvent( eventData )
end

-------------------------------------------------------------------------------
-- 任命按钮按下事件
function MemberInfoWdt:OnBtnAppointClicked()
	UIManager.ClanPositionChgWindow:ShowWindow(self.m_Member)

	self:Hide()
end

-------------------------------------------------------------------------------
-- 开除按钮按下事件
function MemberInfoWdt:OnBtnDismissClicked()
	if not self.m_Member then
		return
	end
	
	local clanID = self.m_Member.dwPDBID
	local data = {}
	data.content = string.format("确定将<color=#C59502>%s</color>请离帮会吗？", self.m_Member.szName)
	data.confirmCallBack = function ( )
		IGame.ClanClient:KickRequest(clanID)
	end
	UIManager.ConfirmPopWindow:ShowDiglog(data)

	self:Hide()
end


-------------------------------------------------------------------------------
-- 发送消息按钮按下事件
function MemberInfoWdt:OnBtnSendMsgClicked()
	UIManager.FriendEmailWindow:OnPrivateChat(self.m_Member.dwPDBID)
end

-------------------------------------------------------------------------------
-- 添加好友按钮按下事件
function MemberInfoWdt:OnBtnAddAsFriendClicked()
	IGame.FriendClient:OnRequestAddFriend(self.m_Member.dwPDBID)
end
-------------------------------------------------------------------------------
-- 禁言/取消禁言按钮按下事件
function MemberInfoWdt:OnBtnAstrictSpeakClicked()
	--IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "暂未实现")
end
-------------------------------------------------------------------------------
-- 查看信息按钮按下事件
function MemberInfoWdt:OnBtnLookAtInfoClicked()
	IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "暂未实现")
end

-------------------------------------------------------------------------------
-- 查看梦岛按钮按下事件
function MemberInfoWdt:OnBtnLookAtMengDaoClicked()
	IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "暂未实现")
end

-------------------------------------------------------------------------------

return MemberInfoWdt


