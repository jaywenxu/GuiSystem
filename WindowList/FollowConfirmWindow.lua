-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    周加财
-- 日  期:    2017/09/13
-- 版  本:    1.0
-- 描  述:    响应队长跟随按钮
-------------------------------------------------------------------

local FollowConfirmTimes = 8
local FollowConfirmWindow = UIWindow:new
{
	windowName        = "FollowConfirmWindow",
	
	m_Content         = "",
	m_CancelBtnTxt    = "取消",
	m_ConfirmBtnTxt   = "接受",
	m_CaptainDBID 	  = 0,
	
	m_ConfirmCallBack = nil,
	m_CancelCallBack  = nil,
	m_Count = 0,
	m_bRequestComfitm = false,
}

----------------------------------------------------------------
function FollowConfirmWindow:Init()
	self.callbackCutDownTimer = function() self:OnCutDownTimer() end
end

function FollowConfirmWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

 	self.Controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
 	self.Controls.m_CancelBtn.onClick:AddListener(handler(self, self.OnBtnCancelClicked))
 	self.Controls.m_ConfirmBtn.onClick:AddListener(handler(self, self.OnBtnConfirmClicked))
	self.Controls.m_AutoTeamFollow.onValueChanged:AddListener(handler(self, self.OnAutoRespTeamFollowChg))

 	self:UpdateUI()
end

function FollowConfirmWindow:UpdateUI()
	if not self:isLoaded() then
		return 
	end
	self.Controls.m_ConfirmBtnTxt.text = "接受("..self.m_Count.."s)"
	self.Controls.m_ContentTxt.text = self.m_Content
	self.Controls.m_AutoTeamFollow.isOn = GetTeamFollowAutoResp() == 1
end

function FollowConfirmWindow:Hide(destroy )
	
	self:ClearData()
	UIWindow.Hide(self,destroy)
end

-- 清楚数据
function FollowConfirmWindow:ClearData()
	self.m_CaptainDBID 	  = 0
	self.m_Count = 0
	self.m_Content = ""
	rktTimer.KillTimer( self.callbackCutDownTimer )
end
-- 响应关闭，即取消
function FollowConfirmWindow:OnBtnCloseClicked()
	self:OnBtnCancelClicked()
end

-- 响应取消
function FollowConfirmWindow:OnBtnCancelClicked()
	rktTimer.KillTimer( self.callbackCutDownTimer )
	if not self.m_bRequestComfitm then
		IGame.TeamClient:FollowCaptain(false,true)
	end
	self.m_bRequestComfitm = true
	self:Hide()
end

function FollowConfirmWindow:OnBtnConfirmClicked()
	rktTimer.KillTimer( self.callbackCutDownTimer )
	if not self.m_bRequestComfitm then
		IGame.TeamClient:FollowCaptain(true,true)
	end
	self.m_bRequestComfitm = true
	self:Hide()
end

-- 获取当前召唤的队长id
function FollowConfirmWindow:GetCurCaptainID()
	return self.m_CaptainDBID
end

-- 倒计时
function FollowConfirmWindow:OnCutDownTimer()
	self.m_Count = self.m_Count - 1
	if self.m_Count < 0 then
		self.m_Count = 0
	end
	if self:isLoaded() then
		self.Controls.m_ConfirmBtnTxt.text = "接受("..self.m_Count.."s)"
	end
	if self.m_Count <= 0 then
		self:OnBtnConfirmClicked()
	end
end

function FollowConfirmWindow:OnAutoRespTeamFollowChg(on)
	SetTeamFollowAutoResp(on and 1 or 0)
end

----------------------------------------------------------------
function FollowConfirmWindow:ShowFollowDialog(data)
	UIWindow.Show(self, true)

	self.m_Content = data.content or ""
	
	self.m_CaptainDBID = data.dwCaptainID

	self.m_Content = data.content

	self.m_Count = FollowConfirmTimes
	self.m_bRequestComfitm = false
	self.m_ConfirmBtnTxt = "接受("..self.m_Count.."s)"
	rktTimer.KillTimer( self.callbackCutDownTimer )
	rktTimer.SetTimer( self.callbackCutDownTimer, 1000, FollowConfirmTimes, "FollowConfirmWindow:ShowFollowDialog")
	self:UpdateUI()
end

return FollowConfirmWindow
