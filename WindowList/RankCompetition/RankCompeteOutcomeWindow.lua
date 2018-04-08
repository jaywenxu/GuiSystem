-- 段位赛3v3的结算窗口
-- @Author: LiaoJunXi
-- @Date:   2017-12-25 09:36:57
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-12-30 12:22:48

local RankCompeteOutcomeWindow = UIWindow:new
{
	windowName        = "RankCompeteOutcomeWindow",
	
	m_Presenter = nil,
	m_HeroOutcomeCells = {}, 
	m_EnemyOutcomeCells = {}, 
	m_SelOutcomeIdx = 1, --当前选择格
	
	m_OnOutcomeDataCallBack = nil,
	m_TweenFader = nil,
	
	m_Attached = false,
	m_Responded = false,
	m_Appeared = false
}

require("GuiSystem.WindowList.RankCompetition.RankCompetitionPresenter")
local RankCompeteOutcomeCell = require(RankCompetitionPresenter.RootPath .. "RankCompeteOutcomeCell")

-- 调用界面
function RankCompeteOutcomeWindow:Show(bringTop)
	UIWindow.Show(self, bringTop)
	self.m_SelOutcomeIdx = 1
	IGame.RankCompeteClient:SendRequestForOutcomeData()
	if not self:isLoaded() then
		self:SubscribeEvts()
		return
	end
	if self.m_Responded then
		self:Appear()
	end
end

function RankCompeteOutcomeWindow:SubscribeEvts()
	self.m_OnOutcomeDataCallBack = handler(self, self.OnOutcomeDataResponse)
	rktEventEngine.SubscribeExecute( EVENT_RANK_OUTCOME, SOURCE_TYPE_RANK, 0, self.m_OnOutcomeDataCallBack )
end

function RankCompeteOutcomeWindow:UnSubscribeEvts()
	rktEventEngine.UnSubscribeExecute( EVENT_RANK_OUTCOME , SOURCE_TYPE_RANK, 0, self.m_OnOutcomeDataCallBack )
	self.m_OnOutcomeDataCallBack = nil
end

-- 销毁窗口
function RankCompeteOutcomeWindow:OnDestroy()
	self:UnSubscribeEvts()
	UIWindow.OnDestroy(self)

	table_release(self)
end

function RankCompeteOutcomeWindow:OnOutcomeDataResponse()
	self.m_Responded = true
	if self.m_Attached then
		self:Appear()
	end
end

function RankCompeteOutcomeWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.m_Presenter = RankCompetitionPresenter
	self.m_Attached = true
	self:InitUI()
	if self.m_Responded then self:Appear() end
end

function RankCompeteOutcomeWindow:InitUI()
	local controls = self.Controls
	
	self.m_TweenFader = self.transform:GetComponent(typeof(DOTweenAnimation))
	
	controls.m_QuitBtn.onClick:AddListener(function() self:OnClickQuitBtn() end)
	controls.m_ShareBtn.onClick:AddListener(function() self:OnClickShareBtn() end)
end

function RankCompeteOutcomeWindow:Appear()
	self:RefreshUI()
	if self.m_TweenFader and not self.m_Appeared then
		self.m_TweenFader:DORestart(true)
		self.m_Appeared = true
	end
end

function RankCompeteOutcomeWindow:RefreshUI()
	if not self:isShow() then
		return
	end
	self:RefreshInfo()
	self:RefreshCells()
end

function RankCompeteOutcomeWindow:RefreshCells()
	local nCellDataList = self.m_Presenter:GetCompeteHeroOutcomeList()
	if not nCellDataList then return end
	local nCount = #nCellDataList
	local controls = self.Controls
	
	-- 刷新蓝方格子
	for i=1, nCount do
		local cell = self.m_HeroOutcomeCells[i]
		if not cell then
			local obj = controls["m_BlueOutcomeCell ("..i..")"]
			cell = RankCompeteOutcomeCell:new({})
			cell:Attach(obj)
			table.insert(self.m_HeroOutcomeCells,i,cell)
			
			cell:SetSelectCallback(handler(self, self.OnItemCellSelected))
			cell:Show()
			self:RefreshOutcomeCell(i, cell, true)
		else
			cell:Show()
			self:RefreshOutcomeCell(i, cell, true)
		end
	end
	
	nCellDataList = self.m_Presenter:GetCompeteEnemyOutcomeList()
	if not nCellDataList then return end
	local nCount = #nCellDataList
	-- 刷新蓝方格子
	for i=1, nCount do
		local cell = self.m_EnemyOutcomeCells[i]
		if not cell then
			local obj = controls["m_RedOutcomeCell ("..i..")"]
			cell = RankCompeteOutcomeCell:new({})
			cell:Attach(obj)
			table.insert(self.m_EnemyOutcomeCells,i,cell)
			
			cell:SetSelectCallback(handler(self, self.OnItemCellSelected))
			cell:Show()
			self:RefreshOutcomeCell(i, cell, false)
		else
			cell:Show()
			self:RefreshOutcomeCell(i, cell, false)
		end
	end
end

function RankCompeteOutcomeWindow:RefreshOutcomeCell(idx, cell, isHero)
	if not cell then 
		cell = GetValuable(isHero, self.m_HeroOutcomeCells[idx], self.m_EnemyOutcomeCells[idx]) 
	end
	local mData = GetValuable(isHero, self.m_Presenter:GetCompeteHeroOutcomeData(idx), 
	self.m_Presenter:GetCompeteEnemyOutcomeData(idx))
	cell:SetCellData(idx, mData)
	
	if self.m_SelOutcomeIdx == 0 then
		self.m_SelOutcomeIdx = 1
	end
	if idx == self.m_SelOutcomeIdx then
		self:OnItemCellSelected(idx)
	end
end

function RankCompeteOutcomeWindow:OnItemCellSelected(idx)
	self.m_SelOutcomeIdx = idx
end

function RankCompeteOutcomeWindow:RefreshInfo()
	local controls = self.Controls
	controls.m_HeroName.text = IGame.EntityClient:GetHero():GetName()
	UIFunction.SetHeadImage(controls.m_AvatarIcon,IGame.EntityClient:GetHero():GetNumProp(CREATURE_PROP_FACEID))
	controls.m_AvatarIcon:SetNativeSize()
	controls.m_ScroeValue.text = "+"..self.m_Presenter:GetRankAddScroe()
	controls.m_ReputationValue.text = "+"..self.m_Presenter:GetRankAddReputation()
end

function RankCompeteOutcomeWindow:OnClickQuitBtn()
	self.m_Responded = false
	self:Hide()
	--......
end

function RankCompeteOutcomeWindow:OnClickShareBtn()
	
end

return RankCompeteOutcomeWindow