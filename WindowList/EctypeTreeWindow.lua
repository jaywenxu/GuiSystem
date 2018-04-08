-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    方称称
-- 日  期:    2017/06/01
-- 版  本:    1.0
-- 描  述:    副本九天连宫窗口
-------------------------------------------------------------------

local EctypeTreeWindow = UIWindow:new
{
	windowName = "EctypeTreeWindow",
}

local this = EctypeTreeWindow   -- 方便书写

function EctypeTreeWindow:Init()
	
end

function EctypeTreeWindow:OnAttach(obj)
	UIWindow.OnAttach(self,obj)
	
	self.Controls.m_waterButton.onClick:AddListener( handler(self,self.WaterButtonCallback) )
	self.Controls.m_prizeButton.onClick:AddListener( handler(self,self.PrizeButtonCallback) )
	return self
end

function EctypeTreeWindow:setBtnFunc( waterFunc , prizeFunc )
	self.m_waterFunc = waterFunc
	self.m_prizeFunc = prizeFunc
end

-- 灌溉按钮点击回调
function EctypeTreeWindow:WaterButtonCallback()
	GameHelp.PostServerRequest("RequestSaveThePrincessEctypeRepairBossClick()")
end

-- 领奖按钮点击回调
function EctypeTreeWindow:PrizeButtonCallback()
	local confirmCallBack = function ( )
		GameHelp.PostServerRequest("RequestSaveThePrincessEctypeConfirm()")
		self:Hide()
	end
	local data = 
	{
		content = "每棵长生树只能领取一次奖励，领取奖励后无法浇灌，确定要现在就领取奖励吗？",
		confirmCallBack = confirmCallBack,
	}	
	UIManager.ConfirmPopWindow:ShowDiglog(data)
	
	
end

function EctypeTreeWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

return EctypeTreeWindow
