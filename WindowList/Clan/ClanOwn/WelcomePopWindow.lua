-- 迎新界面弹框
-- @Author: XieXiaoMei
-- @Date:   2017-05-18 19:36:19
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-07 20:13:46

local WelcomePopWindow = UIWindow:new
{
	windowName        = "WelcomePopWindow",
	m_MemberID = 0,
	m_MemberName = "",
	m_SendMoney = 1,
}

local this = WelcomePopWindow
this.WndLoading = false -- 窗口加载状态
this.WaitingShow = false -- 等待显示状态

------------------------------------------------------------
function WelcomePopWindow:Init()
end

function WelcomePopWindow:Show(bringTop)
	if self:isShow() or this.WndLoading or this.WaitingShow then
		return
	end

	this.WndLoading = true

	UIWindow.Show(self, bringTop)

	local data = IGame.ClanClient:PopClanGiftMsg()
	self.m_MemberID = data.dwRecvPDBID
	self.m_MemberName = data.szRecvName
	self.m_SendMoney = data.dwMoney

	if not self:isLoaded() then
		return
	end

	self:SetTips()
end

function WelcomePopWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	local controls = self.Controls
	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_CancelBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_ConfirmBtn.onClick:AddListener(handler(self, self.OnBtnConfirmClicked))

	self:SetTips()
end


function WelcomePopWindow:SetTips()
	local tips = self.Controls.m_TipsTxt

	local s = "<color=green>%s</color>入帮成功，你确定要给他打赏<color=green>%d</color>银币(需要消耗<color=green>%d</color>银两)作为迎新礼吗？"
	tips.text = string.format(s, self.m_MemberName, self.m_SendMoney, self.m_SendMoney)
end


-- 关闭按钮事件
function WelcomePopWindow:OnBtnCloseClicked()
	self:HandleConfirmMsg(false)
end

-- 确认按钮事件
function WelcomePopWindow:OnBtnConfirmClicked()
	self:HandleConfirmMsg(true)
end

-- 确认按钮事件
function WelcomePopWindow:HandleConfirmMsg(isConfirm)
	local bNotWarnAgain = self.Controls.m_NoWarnAgainTgl.isOn
	IGame.ClanClient:ConfirmDispatchGift(self.m_MemberID, bNotWarnAgain, isConfirm)
	
	self:Hide(bNotWarnAgain)

	if not bNotWarnAgain then -- 未设置不再提醒
		self:CheckAndShowMsgs()
	end
	
end

-- 检测和显示迎新列表的的消息
function WelcomePopWindow:CheckAndShowMsgs()
	if IGame.ClanClient:HasClanGiftMsg() then
		rktTimer.SetTimer(function () --400ms后再显示下一条消息
			this.WaitingShow = false
			this:Show(true)
		end, 400, 1, "WelcomePopWindow delay show timer")

		this.WaitingShow = true -- 设置为等待显示中
	end
end

function WelcomePopWindow:OnDestroy()
	self.m_MemberID = 0
	self.m_MemberName = ""
	self.m_SendMoney = 1

	this.WndLoading = false
	this.WaitingShow = false

	UIWindow.OnDestroy(self)
end

function WelcomePopWindow:Hide()
	UIWindow.Hide(self)

	this.WndLoading = false
	this.WaitingShow = false
end

return WelcomePopWindow
------------------------------------------------------------

