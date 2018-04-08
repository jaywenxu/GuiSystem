local NearbyTeamPlayerCellClass = require("GuiSystem.WindowList.Team.NearbyTeamPlayerCell")

--组队系统 附近玩家总项
------------------------------------------------------------
local NearPlayerTotalCell =  UIControl:new
{
	windowName = "NearPlayerTotalCell" ,
	m_leftPlayer = nil,
	m_rightPlayer = nil,
}
------------------------------------------------------------
function NearPlayerTotalCell:Attach( obj )
	UIControl.Attach(self,obj)
	return self
end


function NearPlayerTotalCell:InitLeftPlayer(leftName,leftLevel,leftProfession,leftHeadId,entity)
	self.m_leftPlayer = NearbyTeamPlayerCellClass:new()
	self.m_leftPlayer:Attach(self.Controls.m_leftPlayer.gameObject)
	self.m_leftPlayer:RefreshCell(leftName,leftLevel,leftProfession,leftHeadId)
	self.m_leftPlayer.m_Entity = entity
end

function NearPlayerTotalCell:InitRightPlayer(leftName,leftLevel,leftProfession,leftHeadId,entity)
	self.m_rightPlayer = NearbyTeamPlayerCellClass:new()
	self.m_rightPlayer:Attach(self.Controls.m_rightPlayer.gameObject)
	self.m_rightPlayer:RefreshCell(leftName,leftLevel,leftProfession,leftHeadId)
	self.m_rightPlayer.m_Entity = entity
end

function NearPlayerTotalCell:ShowRightPlayer(state)
	self.Controls.m_rightPlayer.gameObject:SetActive(state)
end

function NearPlayerTotalCell:OnRecycle()
	if self.m_rightPlayer ~= nil then 
		self.m_rightPlayer:OnRecycle()
	end
	
	self.m_leftPlayer:OnRecycle()
	UIControl.OnRecycle(self)
end
------------------------------------------------------------
--------------------------------------------------------
return NearPlayerTotalCell