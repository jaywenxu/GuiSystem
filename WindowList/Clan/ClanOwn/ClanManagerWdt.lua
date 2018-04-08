-- 帮派名称修改界面
-- @Author: XieXiaoMei
-- @Date:   2017-04-18 09:36:19
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-25 16:49:40

local ClanManagerWdt = UIControl:new
{
	windowName        = "ClanManagerWdt",
}

------------------------------------------------------------
function ClanManagerWdt:Init()
end

function ClanManagerWdt:Attach( obj )
	UIControl.Attach(self,obj)

	local controls = self.Controls

	self.transform.gameObject:SetActive(false)

	controls.m_ManagePnlBtn.onClick:AddListener(handler(self, self.OnBtnManagePnlClicked))

	--controls.m_MergeClanBtn.onClick:AddListener(handler(self, self.OnBtnMergeClanClicked))

	controls.m_SettingsBtn.onClick:AddListener(handler(self, self.OnBtnSettingsClicked))
	
	controls.m_MassMsgBtn.onClick:AddListener(handler(self, self.OnBtnMassMsgClicked))

	controls.m_ApplyListBtn.onClick:AddListener(handler(self, self.OnBtnApplyListClicked))

	rktEventEngine.SubscribeExecute(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM,REDDOT_UI_EVENT_CLAN_MANAGER, self.RefreshRedDot, self)

	self:RefreshRedDot()
end

function ClanManagerWdt:OnDestroy()
	rktEventEngine.UnSubscribeExecute(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM,REDDOT_UI_EVENT_CLAN_MANAGER, self.RefreshRedDot, self)

	UIControl.OnDestroy(self)	
end


function ClanManagerWdt:Show()
	UIControl.Show(self)
	
	self:RefreshPopedoms()
end

function ClanManagerWdt:RefreshPopedoms()
	local controls = self.Controls

	local isHasPopedom = handler(IGame.ClanClient, IGame.ClanClient.HasPopedom)

	--local bHasPepedom = isHasPopedom(emClanPopedom_AcceptMember) -- 是否有合并帮会权限
	--controls.m_MergeClanBtn.gameObject:SetActive(bHasPepedom)

	bHasPepedom = isHasPopedom(emClanPopedom_AcceptSetting) -- 是否招人设置权限
	controls.m_SettingsBtn.gameObject:SetActive(bHasPepedom)

	bHasPepedom = isHasPopedom(emClanPopedom_MassMsg) -- 是否群发消息权限
	controls.m_MassMsgBtn.gameObject:SetActive(bHasPepedom)
	
	bHasPepedom = isHasPopedom(emClanPopedom_AcceptMember)
	controls.m_ManageClanBtn.gameObject:SetActive(bHasPepedom)
end


-- 刷新红点显示
function ClanManagerWdt:RefreshRedDot()
	local flag = SysRedDotsMgr.GetSysFlag("ClanManager", "帮会申请")
	UIFunction.ShowRedDotImg(self.Controls.m_ApplyListBtn.transform, flag)
end


-- 帮派管理面板按钮回调
function ClanManagerWdt:OnBtnManagePnlClicked()
	self:Hide()
end

-- 帮会合并按钮回调
function ClanManagerWdt:OnBtnMergeClanClicked()
	IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "暂不实现")
end


-- 设置按钮回调
function ClanManagerWdt:OnBtnSettingsClicked()
	UIManager.ClanSettingsWindow:Show(true)
end

-- 群发消息按钮回调
function ClanManagerWdt:OnBtnMassMsgClicked()
	UIManager.ClanMassMsgWindow:Show(true)
end

-- 申请列表按钮回调
function ClanManagerWdt:OnBtnApplyListClicked()
	UIManager.ClanApplyListWindow:Show(true)
end


return ClanManagerWdt
------------------------------------------------------------