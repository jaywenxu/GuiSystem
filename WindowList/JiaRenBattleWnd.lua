--JiaRenBattleWnd.lua------------------------------------------------------------
-- 版  权:	(C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:	何荣德
-- 日  期:	2017.12.20
-- 版  本:	1.0
-- 描  述:	假人战场目标窗口
-------------------------------------------------------------------

local JiaRenBattleWnd = UIControl:new
{
	windowName      = "JiaRenBattleWnd",
}

-- 初始化
function JiaRenBattleWnd:Attach( obj )
	
	UIControl.Attach(self,obj)
	
	obj:SetActive(false)
	
	self.Controls.m_RankListBtn.onClick:AddListener(handler(self, self.OnBtnRankList))
    
    self.pEventUpdate= function(nEventID, nSrctype, nSrcID, tActorBattleInfo) self:OnEventUpdate(tActorBattleInfo) end
	rktEventEngine.SubscribeExecute( EVENT_JIARENBATTLE_ACTOR_INFO_UPDATE, 0, 0, self.pEventUpdate)
end

-- 设置排名
function JiaRenBattleWnd:OnEventUpdate(tActorBattleInfo)
    self.Controls.m_PointsText.text = tActorBattleInfo.nPoints
	self.Controls.m_RankText.text = tActorBattleInfo.nRankIdx
end

-- 打开排行榜
function JiaRenBattleWnd:OnBtnRankList()
	GameHelp.PostServerRequest("RequestJiaRenBattleEctypeRank()")	
end

return JiaRenBattleWnd
------------------------------------------------------------

