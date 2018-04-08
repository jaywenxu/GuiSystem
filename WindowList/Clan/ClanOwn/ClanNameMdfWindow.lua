-- 帮派名称修改界面
-- @Author: XieXiaoMei
-- @Date:   2017-04-18 09:36:19
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-07 19:51:28

local ClanNameMdfWindow = UIWindow:new
{
	windowName        = "ClanNameMdfWindow",

	m_modifyCost	  = 0
}

------------------------------------------------------------
function ClanNameMdfWindow:Init()
end


function ClanNameMdfWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	local controls = self.Controls
	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_BackBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_ConfirmBtn.onClick:AddListener(handler(self, self.OnBtnConfirmClicked))

	local inputField = controls.m_NameInput:GetComponent(typeof(InputField))
 	controls.inputField = inputField

 	local cost = IGame.ClanClient:GetClanConfig(CLAN_CONFIG.MODIFY_NAME_COST) or 0
 	controls.m_CostTxt.text = "消耗钻石：" .. cost

 	self.m_modifyCost = tonumber(cost)
end

-- 关闭按钮事件
function ClanNameMdfWindow:OnBtnCloseClicked()
	self:Hide()
end

-- 确认按钮事件
function ClanNameMdfWindow:OnBtnConfirmClicked()
	local txt = self.Controls.inputField.text
	
	-- 检查帮会名字是否合法
	if not IGame.ClanClient:CheckClanName(txt) then
		return
	end

	local selfSilver = IGame.EntityClient:GetHero():GetActorYuanBao()
	if selfSilver < self.m_modifyCost then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你的钻石不足！")
		return 
	end

	IGame.ClanClient:ModifyClanNameRequest(txt)
end


return ClanNameMdfWindow
------------------------------------------------------------

