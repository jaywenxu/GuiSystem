
-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    zjc
-- 日  期:    2017-10-13
-- 描  述:    武林英雄主界面
-------------------------------------------------------------------

local titleImagePath = AssetPath.TextureGUIPath.."WulinHero/WulinHero_huashanlunjian.png"
local nMaxAttackCnt = 5
------------------------------------------------------------
local WulinHeroWindow = UIWindow:new
{
	windowName = "WulinHeroWindow" ,
	m_todayCanAttackCnt = 0,  -- 今日可参与次数
	
}
local this = WulinHeroWindow   -- 方便书写

------------------------------------------------------------ 
function WulinHeroWindow:Init()
	self.WunlinHeroAttackWidget = require("GuiSystem.WindowList.WulinHero.WulinHeroAttackWidget")
	self.WulinHeroRankPrizeWidget = require("GuiSystem.WindowList.WulinHero.WulinHeroRankPrizeWidget")
	self.WulinHeroDailyRankPrizeWidget = require("GuiSystem.WindowList.WulinHero.WulinHeroDailyPrizeWidget")
	self.WulinHeroChallengeInfoWidget = require("GuiSystem.WindowList.WulinHero.WulinHeroChallengeInfoWidget")
end
------------------------------------------------------------
function WulinHeroWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.callback_OnHideBtnClick = function () self:Hide() end
--[[	-- 加载通用窗口
	UIWindow.AddCommonWindowToThisWindow(self, true, titleImagePath, self.callback_OnHideBtnClick)
	self:SetFullScreen() -- 设置为全屏界面--]]
	
	self.WunlinHeroAttackWidget:Attach( self.Controls.m_AttackActorWidget.gameObject )
	self.WulinHeroRankPrizeWidget:Attach( self.Controls.m_RankPrizeWidget.gameObject )
	self.WulinHeroDailyRankPrizeWidget:Attach( self.Controls.m_DailyRankPrizeWidget.gameObject )
	self.WulinHeroChallengeInfoWidget:Attach( self.Controls.m_ChallengeInfoWidget.gameObject )

	self.Controls.m_CloseBtn.onClick:AddListener( self.callback_OnHideBtnClick )
	
	-- 每日排名奖励
	self.calbackDailyPrizeClick = function() self:OnDailyPrizeClick() end
	self.Controls.m_DailyPrizeBtn.onClick:AddListener( self.calbackDailyPrizeClick )
	
	-- 规则说明
	self.calbackRuleDescriptionClick = function() self:OnRuleDescriptionClick() end
	self.Controls.m_RuleDescriptionBtn.onClick:AddListener( self.calbackRuleDescriptionClick )
	
	-- 战绩
	self.callbackBattleHistoryClick = function() self:OnBattleHistoryClick() end
	self.Controls.m_BattleHistoryBtn.onClick:AddListener( self.callbackBattleHistoryClick )

	-- 奖励预览
	self.calbackPreviewPrizeClick = function() self:OnPreviewPrizeClick() end
	self.Controls.m_PreviewPrizeBtn.onClick:AddListener( self.calbackPreviewPrizeClick )
	
	-- 积分商城
	self.calbackJinfenShopClick = function() self:OnJinfenShopClick() end
	self.Controls.m_JifenShopBtn.onClick:AddListener( self.calbackJinfenShopClick )
	
	-- 刷新选择擂台玩家
	self.calbackRefeshClick = function() self:OnRefeshAttackClick() end
	self.Controls.m_RefeshBtn.onClick:AddListener( self.calbackRefeshClick )	
	
	-- 刷新自己的信息
	self:UpdateSelfInfo()
    return self
end

------------------------------------------------------------
function WulinHeroWindow:OnDestroy()
	if self.WunlinHeroAttackWidget then
		self.WunlinHeroAttackWidget:OnDestroy()
	end
	if self.WulinHeroRankPrizeWidget then
		self.WulinHeroRankPrizeWidget:OnDestroy()
	end
	if self.WulinHeroDailyRankPrizeWidget then
		self.WulinHeroDailyRankPrizeWidget:OnDestroy()
	end	
	if self.WulinHeroChallengeInfoWidget then
		self.WulinHeroChallengeInfoWidget:OnDestroy()
	end
	UIWindow.OnDestroy(self)
end

------------------------------------------------------------
-- 每日奖励按钮响应
function WulinHeroWindow:OnDailyPrizeClick()
	if self.WulinHeroDailyRankPrizeWidget:isShow() then
		return
	end
	self:RefeshDailyRankPrize()
end

------------------------------------------------------------
-- 规则说明
function WulinHeroWindow:OnRuleDescriptionClick()
	self:HideOtherWidget()
	UIManager.CommonGuideWindow:ShowWindow(3)
end

------------------------------------------------------------
-- 挑战记录
function WulinHeroWindow:OnBattleHistoryClick()
	if self.WulinHeroChallengeInfoWidget:isShow() then
		return
	end
	if not IGame.WulinHeroClient:GetLoadState() then
		IGame.WulinHeroClient:RequestReport()
	else
		self:RefeshChallengeInfo()
	end
end

------------------------------------------------------------
-- 奖励预览
function WulinHeroWindow:OnPreviewPrizeClick()
	if self.WulinHeroRankPrizeWidget:isShow() then
		return
	end
	GameHelp.PostServerRequest( "RequestWulinHeroRankData()" )
end

--------------------------------------------------------------------------
-- 隐藏其他界面
function WulinHeroWindow:HideOtherWidget()
	if self.WulinHeroRankPrizeWidget:isShow() then
		self:SetRankPrizeWidgetVisable(false)
	end
	if self.WulinHeroDailyRankPrizeWidget:isShow() then
		self:SetDailyRankPrizeWdiget(false)
	end
	if self.WulinHeroChallengeInfoWidget:isShow() then
		self:SetChallengeInfoWdiget(false)
	end
end

------------------------------------------------------------
-- 打开积分商店
function WulinHeroWindow:OnJinfenShopClick()
	-- npc id 为4打开论剑积分商店
	self:HideOtherWidget()
	IGame.ChipExchangeClient:OpenChipExchangeShop(1,0,2)
end

------------------------------------------------------------
-- 刷新攻击的玩家
function WulinHeroWindow:OnRefeshAttackClick()
	IGame.WulinHeroClient:RequestChangePlay()
end

------------------------------------------------------------
-- 刷新今日可参与次数
function WulinHeroWindow:UpdateTodayAttackCount(nCount)
	if self:isLoaded() then
		self.Controls.m_TodayAttackCnt.text = "今日剩余挑战次数："..nCount.."/"..nMaxAttackCnt
	end
end

----------------------------------------------------------------------
-- 刷新当前刷新消费
function WulinHeroWindow:UpdateRefeshConst( szCoin )
	if self:isLoaded() then
		self.Controls.m_RefeshCost.text = szCoin
	end
end

----------------------------------------------------------------------
-- 刷新当前刷新消费
function WulinHeroWindow:UpdateCurRefeshCost(nRefeshCount)
	
	if nRefeshCount > WULINHERO_REFESH_MAX_NUM then
		nRefeshCount = WULINHERO_REFESH_MAX_NUM
	end
	local pScheme = IGame.rktScheme:GetSchemeInfo( WULINHEROREFESHCOST_CSV, nRefeshCount )
	if not pScheme or not pScheme.nCostType then
		self:UpdateRefeshConst(0)
		return
	end
	local pHero = GetHero()
	if not pHero then
		return
	end
	-- 钻石
	if pScheme.nCostType == 1 then
		if pHero:GetActorYuanBao() < pScheme.nCostValue then
			self:UpdateRefeshConst( "<color=red>" .. pScheme.nCostValue.. "</color>" )
		else
			self:UpdateRefeshConst( pScheme.nCostValue.. "" )
		end
	-- 银两
	elseif pScheme.nCostType == 2 then
		if pHero:GetYinLiangNum() < pScheme.nCostValue then
			self:UpdateRefeshConst( "<color=red>" .. pScheme.nCostValue.. "</color>" )
		else
			self:UpdateRefeshConst( pScheme.nCostValue )
		end
	-- 银币
	elseif pScheme.nCostType == 3 then
		if pHero:GetYinBiNum() < pScheme.nCostValue then
			self:UpdateRefeshConst( "<color=red>" .. pScheme.nCostValue.. "</color>" )
		else
			self:UpdateRefeshConst( pScheme.nCostValue )
		end
	end
end

-- 刷新自己的信息
function WulinHeroWindow:UpdateSelfInfo()
	local pAttackInfo = IGame.WulinHeroClient:GetSelfAttackInfo()
	if not pAttackInfo then
		return
	end
	
	-- 等级
	self.Controls.m_MyRankText.text = pAttackInfo.nRank
	
	-- 当前等级获得的论剑积分
	local nLunJianValue = IGame.WulinHeroClient:GetDailyLunJianValue(pAttackInfo.nRank)
	self.Controls.m_LunJianPrizeValue.text = nLunJianValue
	
	self:UpdateTodayAttackCount(pAttackInfo.nFightCount)
	
	self:UpdateCurRefeshCost(pAttackInfo.nRefeshCount+1)
end

----------------------------------------------------------------------
-- 刷新武林英雄界面信息
function WulinHeroWindow:RefeshWulinHeroInfo()
	if self:isLoaded() then	
		self:UpdateSelfInfo()
		self.WunlinHeroAttackWidget:ReloadData()
	end
end

-- 刷新武林英雄界面信息
function WulinHeroWindow:UpdateWulinHeroInfo(nRefeshCount)
	if self:isLoaded() then	
		self.WunlinHeroAttackWidget:ReloadData()
		self:UpdateCurRefeshCost( nRefeshCount +1 )
	end
end

-------------------------------------------------------------------------
-----------------------------排行奖励信息--------------------------------
------------------------------------------------------------------------
function WulinHeroWindow:GetMainHeroHighestRank()
	return self.MainHeroHighestRank
end
--------------------------------------------------------------------------
-- 获取奖励状态信息
function WulinHeroWindow:GetMainHeroPrizeFlag()
	return self.nPrizeFlag
end

function WulinHeroWindow:SetRankPrizeWidgetVisable(bVisable)
	if bVisable then
		self:HideOtherWidget()
		self.WulinHeroRankPrizeWidget:Show()
	else
		self.WulinHeroRankPrizeWidget:Hide()
	end
end
function WulinHeroWindow:RefeshWulinHeroRankPrize()
	if self:isLoaded() then	
		self.WulinHeroRankPrizeWidget:ReloadData()
		self:SetRankPrizeWidgetVisable(true)
	end
end
--------------------------------------------------------------------------
-- 更新排行榜奖励信息
function WulinHeroWindow:UpdateRankData(HighestRank,nPrizeFlag)
	self.MainHeroHighestRank = HighestRank
	self.nPrizeFlag = nPrizeFlag
	
	self:RefeshWulinHeroRankPrize()
end

------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------

---------------------------- 每日排行奖励信息 --------------------------------
function WulinHeroWindow:RefeshDailyRankPrize()
	if self:isLoaded() then	
		self.WulinHeroDailyRankPrizeWidget:ReloadData()
		self:SetDailyRankPrizeWdiget(true)
	end
end
function WulinHeroWindow:SetDailyRankPrizeWdiget(bVisable)
	if bVisable then
		self:HideOtherWidget()
		self.WulinHeroDailyRankPrizeWidget:Show()
	else
		self.WulinHeroDailyRankPrizeWidget:Hide()
	end
end
--------------------------------------------------------------------------

---------------------------- 战斗记录信息 --------------------------------
function WulinHeroWindow:RefeshChallengeInfo()
	if self:isLoaded() then	
		self:SetChallengeInfoWdiget(true)
		self.WulinHeroChallengeInfoWidget:ReloadData()
	end
end
function WulinHeroWindow:SetChallengeInfoWdiget(bVisable)
	if bVisable then
		self:HideOtherWidget()
		self.WulinHeroChallengeInfoWidget:Show()
	else
		self.WulinHeroChallengeInfoWidget:Hide()
	end
end
--------------------------------------------------------------------------

--------------------------------------------------------------------------
return this
