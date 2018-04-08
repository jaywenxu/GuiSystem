-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    zjc
-- 日  期:    2017/12/36
-- 版  本:    1.0
-- 描  述:   武林英雄结算界面
-------------------------------------------------------------------

local WulinHeroFightResultWindow = UIWindow:new
{
	windowName = "WulinHeroFightResultWindow",
	mSelfRank = 0,
	mUpRank = 0,
	mbSucceed = 0,
	mPrizeExp = 0,
	mTimes = 0,
}

local this = WulinHeroFightResultWindow   -- 方便书写

function WulinHeroFightResultWindow:Init()
	self.callBackLeaveTimer = function() self:OnLeaveTimer() end
end

function WulinHeroFightResultWindow:OnAttach(obj)
	UIWindow.OnAttach(self,obj)
	
	self.Controls.m_ConfirmBtn.onClick:AddListener( handler(self,self.ConfirmButtonCallback) )
	
	self:RefeshData()
	return self
end

-- 隐藏窗体
function WulinHeroFightResultWindow:Hide( destory )
    
	rktTimer.KillTimer( self.callBackLeaveTimer )
	-- 销毁定时器
	UIWindow.Hide(self, destory)
end

function WulinHeroFightResultWindow:OnDestroy()
	self:ClearData()
	UIWindow.OnDestroy(self)
end

function WulinHeroFightResultWindow:ClearData()
	self.mSelfRank = 0
	self.mUpRank = 0
	self.mbSucceed = 0
	self.mPrizeExp = false	
end

function WulinHeroFightResultWindow:HideWindow()
	self:ClearData()
	self:Hide()
end

-- 确定按钮
function WulinHeroFightResultWindow:ConfirmButtonCallback()
	-- 已经回城
	if IGame.EntityClient:GetMapID() == IGame.EntityClient:GetZoneID() then
		self:HideWindow()
		return
	end
	-- 还在副本则返回地图
	GameHelp.PostServerRequest( "RequestForceGoBace()" )
	self:HideWindow()
end

function WulinHeroFightResultWindow:RefeshData()
	if not self:isLoaded() then
		return
	end
	self.Controls.m_TimerText.text = GetCDTime(self.mTimes, 3, 2)
	self.Controls.m_RankText.text = self.mSelfRank
	self.Controls.m_UpRankText.text = self.mUpRank
	self.Controls.m_PrizeExpText.text = self.mPrizeExp
	if self.mbSucceed == 1 then
		-- self.Controls.m_UpRankText.gameObject:SetActive(true)
		-- self.Controls.m_UpFlag.gameObject:SetActive(true)
		local fightPath = AssetPath.CommonPlayTexturePath.."WulinHero_jiesuan_sheng_2.png"
		UIFunction.SetImageSprite(self.Controls.m_FightResultImg , fightPath)	
		UIFunction.SetImageGray(self.Controls.m_FightResultBg, false)
	else
		-- self.Controls.m_UpRankText.gameObject:SetActive( false )
		-- self.Controls.m_UpFlag.gameObject:SetActive( false )
		local fightPath = AssetPath.CommonPlayTexturePath.."WulinHero_jiesuan_shibai_3.png"
		UIFunction.SetImageSprite(self.Controls.m_FightResultImg , fightPath)	
		UIFunction.SetImageGray(self.Controls.m_FightResultBg, true)
	end
end

-- 显示信息
function WulinHeroFightResultWindow:ShowFightResult(nRank, upRank, nPrizeExp, nSucceedFlag, nTimes )
	uerror( "WulinHeroFightResultWindow:ShowFightResult ".. nRank .. " " .. upRank .. " " ..nPrizeExp .. " " ..nSucceedFlag )
	self.mSelfRank = nRank
	self.mUpRank = upRank
	self.mbSucceed = nSucceedFlag
	self.mPrizeExp = nPrizeExp
	self.mTimes = nTimes-1
	self:RefeshData()
	rktTimer.KillTimer( self.callBackLeaveTimer )
	rktTimer.SetTimer( self.callBackLeaveTimer , 1000 , -1 , "WulinHeroFightResultWindow:OnLeaveTimer()" )
end

function WulinHeroFightResultWindow:OnLeaveTimer()
	if not self:isLoaded() then
		return
	end
	self.mTimes = self.mTimes - 1
	self.Controls.m_TimerText.text = GetCDTime(self.mTimes, 3, 2)
	if self.mTimes <= 0 then
		rktTimer.KillTimer( self.callBackLeaveTimer )
	end
end

return WulinHeroFightResultWindow
