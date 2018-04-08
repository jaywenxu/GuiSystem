SceneRoleInfoWindow = UIWindow:new
{
	windowName = "SceneRoleInfoWindow",
	m_entity = nil,
}

function SceneRoleInfoWindow:OnAttach(obj)
	UIWindow.OnAttach(self, obj, UIManager._MainHUDLayer)
	self.OnClicklookBtn = function() self:OnClickLookInfo() end
	self.Controls.m_lookInfoBtn.onClick:AddListener(handler(self, self.OnClicklookBtn))
	UIFunction.AddEventTriggerListener(self.Controls.m_CloseButton , EventTriggerType.PointerClick , function( eventData ) self:OnCloseButtonClick(eventData) end ) 

	self:RefreshUI()
end

function SceneRoleInfoWindow:_ShowWindow(m_entity)
	self.m_entity = m_entity
	UIWindow.Show(self)
	if self:isLoaded() then 
		self:RefreshUI()
	end
end

function SceneRoleInfoWindow:RefreshUI()
	if self.m_entity == nil then 
		return
	end
	
	local level = self.m_entity:GetNumProp(CREATURE_PROP_LEVEL)
	local name  = self.m_entity:GetName()
	local nVocation = self.m_entity:GetNumProp(CREATURE_PROP_VOCATION)
	local currentBlood =  self.m_entity:GetNumProp(CREATURE_PROP_CUR_HP)
	local maxBlood =  self.m_entity:GetNumProp(CREATURE_PROP_MAX_HP)
	local faceID = self.m_entity:GetNumProp(CREATURE_PROP_FACEID)
	
	local fightVal = self.m_entity:GetPower()
	
	UIFunction.SetHeadImage(self.Controls.playHeadIcon,faceID)
	self.Controls.playerNameText.text = name
	self.Controls.playerLevelText.text = tostring(level)
	self.Controls.fightVal.text = tostring(fightVal)
	self.Controls.m_bloodImage.fillAmount = currentBlood / maxBlood
	
end

function SceneRoleInfoWindow:OnClickLookInfo()
	local pdbID =self.m_entity:GetNumProp(CREATURE_PROP_PDBID) 
	UIManager.RoleViewWindow:SetViewInfo(pdbID)
	local RoleViewBtnTable = {1,2,3,4,5,6,7,8,9,10,11,12,13,17}
	UIManager.RoleViewWindow:SetButtonLayoutTable(RoleViewBtnTable)
end


function SceneRoleInfoWindow:OnCloseButtonClick(eventData)
	self:Hide()
	rkt.UIAndTextHelpTools.PassThroughPointerClickEvent( eventData )
end

return SceneRoleInfoWindow