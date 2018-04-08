-- 段位赛界面
-- @Author: LiaoJunXi
-- @Date:   2017-04-18 09:36:19
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-08 17:59:16

local RankCompetitionWindow = UIWindow:new
{
	windowName    = "RankCompetitionWindow",
	
	m_OnRankDataCallBack = nil,
	m_TweenFader = nil,
	
	m_Attached = false,
	m_Responded = false,
	m_Appeared = false
}

-- 调用界面
function RankCompetitionWindow:Show(bringTop)
	UIWindow.Show(self, bringTop)
	IGame.RankCompeteClient:SendRequestForHeroData()
	if not self:isLoaded() then
		self:SubscribeEvts()
		return
	end
	if self.m_Responded then
		self:RefreshUI()
	end
end

function RankCompetitionWindow:SubscribeEvts()
	self.m_OnRankDataCallBack = handler(self, self.OnRankDataResponse)
	rktEventEngine.SubscribeExecute( EVENT_RANK_HERODATE, SOURCE_TYPE_RANK, 0, self.m_OnRankDataCallBack )
end

function RankCompetitionWindow:UnSubscribeEvts()
	rktEventEngine.UnSubscribeExecute( EVENT_RANK_HERODATE , SOURCE_TYPE_RANK, 0, self.m_OnRankDataCallBack )
	self.m_OnRankDataCallBack = nil
end

-- 销毁窗口
function RankCompetitionWindow:OnDestroy()
	self:UnSubscribeEvts()
	UIWindow.OnDestroy(self)

	table_release(self)
end

function RankCompetitionWindow:OnRankDataResponse()
	self.m_Responded = true
	if self.m_Attached then
		self:Appear()
	end
end

function RankCompetitionWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.m_Attached = true
	self:InitUI()
	if self.m_Responded then self:Appear() end
end

function RankCompetitionWindow:InitUI()
	local controls = self.Controls
	self.m_TweenFader = self.transform:GetComponent(typeof(DOTweenAnimation))
	-- 按钮事件
	controls.m_RuleBtn.onClick:AddListener(function() self:OnClickRuleBtn() end)
	controls.m_RewardBtn.onClick:AddListener(function() self:OnClickRewardBtn() end)
	controls.m_BillboardBtn.onClick:AddListener(function() self:OnClickBillboardBtn() end)
	controls.m_ReputationBtn.onClick:AddListener(function() self:OnClickReputationBtn() end)
	controls.m_ButtonSingle.onClick:AddListener(function() self:OnClickSingleCompetition() end)
	controls.m_ButtonMulti.onClick:AddListener(function() self:OnClickMultiCompetition() end)
	controls.m_CloseBtn.onClick:AddListener(function() self:OnCloseBtnClicked() end)
end

function RankCompetitionWindow:Appear()
	self:RefreshUI()
	if self.m_TweenFader and not self.m_Appeared then
		self.m_TweenFader:DORestart(true)
		self.m_Appeared = true
	end
end

function RankCompetitionWindow:SwitchUI(matching)
	local controls = self.Controls
	controls.m_UIMyWindow.transform.gameObject:SetActive(not matching)
	controls.m_UIHintWidget.transform.gameObject:SetActive(matching)
end

function RankCompetitionWindow:RefreshUI()
	
end

function RankCompetitionWindow:OnCloseBtnClicked()
	self.m_Responded = false
	self:Hide()
end

function RankCompetitionWindow:OnClickRuleBtn()
	UIManager.CommonGuideWindow:ShowWindow(32)
end

function RankCompetitionWindow:OnClickRewardBtn()
	
end

function RankCompetitionWindow:OnClickBillboardBtn()
	
end

function RankCompetitionWindow:OnClickReputationBtn()
	
end

function RankCompetitionWindow:OnClickSingleCompetition()
	self:SwitchUI(true)
	IGame.RankCompeteClient:SendRequestForSingleMatching()
end

function RankCompetitionWindow:OnClickMultiCompetition()
	self:SwitchUI(true)
	IGame.RankCompeteClient:SendRequestForMultiMatching()
end