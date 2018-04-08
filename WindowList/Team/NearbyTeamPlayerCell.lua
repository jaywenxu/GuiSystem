--组队系统 附近玩家项
------------------------------------------------------------
local NearbyTeamPlayerCell =  UIControl:new
{
	windowName = "NearbyTeamPlayerCell" ,
	m_Entity = nil,
}
------------------------------------------------------------
function NearbyTeamPlayerCell:Attach( obj )
	UIControl.Attach(self,obj)
	
	self.callbackOnInviteButtonClick = function() self:OnInviteButtonClick() end
	self.Controls.m_InviteButton.onClick:AddListener(self.callbackOnInviteButtonClick)
	
	return self
end
------------------------------------------------------------
function NearbyTeamPlayerCell:OnDestroy()
	self.Controls.m_InviteButton.onClick:RemoveListener(self.callbackOnInviteButtonClick)
	UIControl.OnDestroy(self)
end

function NearbyTeamPlayerCell:OnRecycle()
	self.Controls.m_InviteButton.onClick:RemoveListener(self.callbackOnInviteButtonClick)
	UIControl.OnRecycle(self)
end
------------------------------------------------------------
function NearbyTeamPlayerCell:RefreshCell(nameText,levelText,prefession,headID)
	self.Controls.m_PlayerNameText.text = nameText
	self.Controls.m_LevelText.text = levelText
	UIFunction.SetHeadImage(self.Controls.m_PlayerImage,headID)
	self.Controls.m_prefessionText.text =  GameHelp.GetVocationName(prefession)
	
end

------------------------------------------------------------
function NearbyTeamPlayerCell:OnInviteButtonClick()
	--[[local myTeam = IGame.TeamClient:GetTeam()
	if myTeam:GetTeamID() == 0 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你当前无队伍")
		return
	end--]]
	if self.m_Entity ~= nil then
		IGame.TeamClient:InvitedJoin(self.m_Entity:GetNumProp(CREATURE_PROP_PDBID))
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你发出了组队邀请")
	end
end
------------------------------------------------------------
return NearbyTeamPlayerCell