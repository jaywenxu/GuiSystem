--------------------------------------------------------------------------------
-- 版  权:    (C)深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    lj.zhou
-- 日  期:    2017.06.27
-- 版  本:    1.0
-- 描  述:    蟠桃盛宴排行榜窗口 
--------------------------------------------------------------------------------

local BtnImagePath = 
{
	rank = GuiAssetList.GuiRootTexturePath.."Activity/feast_paiming.png",
	join = GuiAssetList.GuiRootTexturePath.."Activity/feast_rubang.png",
}

local PeachFeastWindow = UIWindow:new
{
	windowName = "PeachFeastWindow",
}

function PeachFeastWindow:OnAttach(obj)
	UIWindow.OnAttach(self, obj, UIManager._MainHUDLayer)
	
	self.Controls.m_RankBtn.onClick:AddListener(handler(self, self.RankBtnClicked))
	
	self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))
	
	self:SubscribeEvts()

	self:InitUI()
		
	self:InitData()
	
end

function PeachFeastWindow:InitData()
	
	GameHelp.PostSocialRequest("RequestPeachFeastClanData()")
end

function PeachFeastWindow:OnEnable()
	
	self:InitUI()
	
	self:InitData()
end

function PeachFeastWindow:InitUI()
		
	local controls = self.Controls
	
	controls.m_RankTxt.text = tostring(0)
	controls.m_Score.text   = tostring(0)

	local clan = IGame.ClanClient:GetClan()
	if not clan then
		UIFunction.SetImageSprite(controls.m_BtnImage, BtnImagePath.join)
	else
		UIFunction.SetImageSprite(controls.m_BtnImage, BtnImagePath.rank)
	end
end

function PeachFeastWindow:RefreshUI(eventData)
	
	local controls = self.Controls
	
	local rank = eventData.rank
	controls.m_RankTxt.text = tostring(rank)
	
	local score = eventData.score
	controls.m_Score.text = tostring(score)
			
end

function PeachFeastWindow:SubscribeEvts()
	
	-- 排行榜列表更新
	self.m_UpdateRankData = function (_, _, _, evtData) self:UpdateRankData(evtData) end
	rktEventEngine.SubscribeExecute(EVENT_PEACHFEAST_CALN_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.m_UpdateRankData )
	
	-- 成功加入帮会
	self.m_OnJoinClanSuccess = handler(self, self.OnJoinSuccessEvt)
	rktEventEngine.SubscribeExecute(EVENT_JOIN_SUCCESS, SOURCE_TYPE_CLAN, 0, self.m_OnJoinClanSuccess)
	
	-- 退出帮会
	self.m_QuitClanCallback = handler(self, self.OnQuitClan)
	rktEventEngine.SubscribeExecute(EVENT_CLAN_QUIT, SOURCE_TYPE_CLAN, 0, self.m_QuitClanCallback)
	
end

function PeachFeastWindow:UnSubscribeEvts()
	
	rktEventEngine.UnSubscribeExecute(EVENT_PEACHFEAST_CALN_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.m_UpdateRankData )
	self.m_UpdateRankData = nil
	
	rktEventEngine.UnSubscribeExecute( EVENT_JOIN_SUCCESS, SOURCE_TYPE_CLAN, 0, self.m_OnJoinClanSuccess )
	self.m_OnJoinClanSuccess = nil
	
	rktEventEngine.UnSubscribeExecute( EVENT_CLAN_QUIT, SOURCE_TYPE_CLAN, 0, self.m_QuitClanCallback )
	self.m_QuitClanCallback = nil

end

function PeachFeastWindow:UpdateRankData(eventData)
	
	local RankData = eventData
	self:RefreshUI(RankData)
end

function PeachFeastWindow:OnJoinSuccessEvt(eventData)
	
	self:InitUI()
	
	self:InitData()
	
end

function PeachFeastWindow:OnQuitClan(eventData)
	
	self:InitUI()
	
end

function PeachFeastWindow:RankBtnClicked()
	
	local clan = IGame.ClanClient:GetClan()
	if not clan then
		UIManager.ClanNoneWindow:Show()
	else
		UIManager.PeachFeastRankWindow:Show()
	end
	
end

return PeachFeastWindow