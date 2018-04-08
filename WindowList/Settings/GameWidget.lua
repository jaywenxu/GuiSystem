-- 设置-游戏窗口
-- @Author: XieXiaoMei
-- @Date:   2017-05-23 19:45:00
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-13 12:29:00

local GameWidget = UIControl:new
{
	windowName = "GameWidget",
}

local this = GameWidget
----------------------------------------------------------------
function GameWidget:Attach( obj )
	UIControl.Attach(self, obj)

	self:InitUI()
end

function GameWidget:OnDestroy()
	UIControl.OnDestroy(self)

	table_release(self)
end


function GameWidget:InitUI()
	local controls = self.Controls

	local tglsNameFuncs = {
		["m_RejectTeamAskTgl"] 		= self.OnTglRejectTeamAskChg,
		["m_AutoRespTeamFollTgl"]	= self.OnTglAutoRespTeamFollChg,
		["m_FrieMsgPushTgl"]		= self.OnTglFriendsMsgPushChg,
		["m_GenSynthesisTgl"]		= self.OnTglGemMsgPushChg,
	}

	controls.m_GenSynthesisTgl.isOn = GetGemAutoUseDiamond() == 1
	controls.m_FrieMsgPushTgl.isOn = GetSendFriendMsg() == 1

	for name, func in pairs(tglsNameFuncs) do
		local tgl = controls[name]
		tgl.onValueChanged:AddListener(handler(self, func))
	end

	controls.m_RejectTeamAskTgl.isOn = GetTeamInviteReject() == 1
	controls.m_AutoRespTeamFollTgl.isOn = GetTeamFollowAutoResp() == 1

	
	local btnsNameFuncs = {
		["m_NotificationBtn"] = self.OnBtnNotificationClk,
		["m_ServersBtn"]      = self.OnBtnServersClk,
		["m_ShareBtn"]        = self.OnBtnShareClk,
		["m_AssociatedBtn"]   = self.OnBtnAssociatedClk,
		["m_QRCode"]          = self.OnBtnQRCodeClk,
	}
	for name, func in pairs(btnsNameFuncs) do
		local btn = controls[name]
		btn.onClick:AddListener(handler(self, func))
	end
end

-------------------------------------------------------------------
--需求取消
function GameWidget:OnTglRejectTeamAskChg(on)
	print("拒绝组队")
	IGame.TeamClient:SetRefuseJoinTeam(on)-- 设置组队模块标志
	SetTeamInviteReject(on and 1 or 0)	-- 保存
end

function GameWidget:OnTglAutoRespTeamFollChg(on)
	print("自动响应组队跟随")

	SetTeamFollowAutoResp(on and 1 or 0)
end

function GameWidget:OnTglFriendsMsgPushChg(on)
	print("好友消息推送")
	if on then 
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "需要开启设备\"通知\"功能权限，方可接受推送消息")
	end
	SetSendFriendMsg(on and 1 or 0)
end

--宝石合成自动消耗钻石
function GameWidget:OnTglGemMsgPushChg(on)
	print("宝石合成自动消耗钻石")
	SetGemAutoUseDiamond(on and 1 or 0)
end
-------------------------------------------------------------------

function GameWidget:OnBtnNotificationClk()
	print("公告")
end

function GameWidget:OnBtnServersClk()
	print("客服")
end

function GameWidget:OnBtnShareClk()
	print("分享")
end

function GameWidget:OnBtnAssociatedClk()
	print("关联")
end

function GameWidget:OnBtnQRCodeClk()
	print("扫码")
end

function GameWidget:OnBtnCloseClicked()
	self:Hide()
end

-------------------------------------------------------------------

return GameWidget