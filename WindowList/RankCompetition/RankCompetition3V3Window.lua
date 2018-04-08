local RankCompetition3V3Window = UIWindow:new
{
	windowName        = "RankCompetition3V3Window",
	
	m_Presenter = nil,
	m_HeroCells = {},
	m_EnemyCells = {},
	
	m_OnBattlersDataCallBack = nil,
	m_TweenFader = nil,
}

require("GuiSystem.WindowList.RankCompetition.RankCompetitionPresenter")
local RankCompeteBattlerCell = require(RankCompetitionPresenter.RootPath .. "RankCompeteBattlerCell")

function RankCompetition3V3Window:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.m_Presenter = RankCompetitionPresenter
	
	self:InitUI()
	self:ShowUI()
end

function RankCompetition3V3Window:InitUI()
	local controls = self.Controls
	for i = 1, 3 do
		local cell = RankCompeteBattlerCell:new({})
		table.insert(self.m_HeroCells, cell:Attach(controls["RedHero-"..i]))
	end
	for i = 1, 3 do
		local cell = RankCompeteBattlerCell:new({})
		table.insert(self.m_EnemyCells, cell:Attach(controls["BlueHero-"..i]))
	end
end

function RankCompetition3V3Window:ShowUI()
	for i,cell in ipairs(self.m_HeroCells) do
		cell:SetCellData(i, self.m_Presenter:GetHeroData(i))
	end
	for i,cell in ipairs(self.m_EnemyCells) do
		cell:SetCellData(i, self.m_Presenter:GetEnemyData(i))
	end
end