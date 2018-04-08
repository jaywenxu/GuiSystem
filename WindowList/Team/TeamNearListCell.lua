--组队平台申请按钮
------------------------------------------------------------
local TeamNearListCell = UIControl:new
{
	windowName = "TeamNearListCell" ,
	m_dwPDBID = nil, 					--玩家的dwPDBID
}
------------------------------------------------------------
function TeamNearListCell:Attach( obj )
	UIControl.Attach(self,obj)
	
	--print(obj.name)
	self.callbackOnApplyButtonClick = function() self:OnApplyButtonClick() end
	self.Controls.m_ApplyButton.onClick:AddListener(self.callbackOnApplyButtonClick)
	
	return self
end

function TeamNearListCell:OnRecycle()
		self.Controls.m_ApplyButton.onClick:RemoveListener(self.callbackOnApplyButtonClick)
		UIControl.OnRecycle(self)
end

------------------------------------------------------------
function TeamNearListCell:RefreshCellUI(info)
	if info == nil then 
		return 
	end
	self.m_dwPDBID = info.dwPDBID
	local item = IGame.rktScheme:GetSchemeInfo(HUODONGWINDOW_CSV, info.nTeamTargetID)
	self.Controls.m_PlayerNameText.text = info.szName
	self.Controls.m_LevelText.text = info.nLevel
	self.Controls.m_profession.text = GameHelp.GetVocationName(info.nVocation) 
	UIFunction.SetHeadImage(self.Controls.m_PlayerImage,info.nFaceID) 
	local peopleCount = self.Controls.m_NumofPeoplePanel.childCount

	for i =1,peopleCount do 
		local obj = self.Controls.m_NumofPeoplePanel:GetChild(i-1)
		local HightLightObj = obj:Find("HasPlayerImage")
		if i>info.nMemberCount then 
			HightLightObj.gameObject:SetActive(false)
		else
			HightLightObj.gameObject:SetActive(true)
		end
	end
	
	if peopleCount == info.nMemberCount then 
		self.Controls.m_ApplyButton.gameObject:SetActive(false)
	else
		self.Controls.m_ApplyButton.gameObject:SetActive(true)
	end

end

function TeamNearListCell:OnDestroy()
	
	self.Controls.m_ApplyButton.onClick:RemoveListener(self.callbackOnApplyButtonClick)
	UIControl.OnDestroy(self)
end
------------------------------------------------------------
function TeamNearListCell:OnApplyButtonClick() 

	IGame.TeamClient:RequestJoin(self.m_dwPDBID,0)
end
------------------------------------------------------------
return TeamNearListCell
