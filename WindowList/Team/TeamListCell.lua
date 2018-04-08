--组队平台申请按钮
------------------------------------------------------------
local TeamListCell = UIControl:new
{
	windowName = "TeamListCell" ,
	m_dwPDBID = nil, 					--玩家的dwPDBID
	m_teamID  = nil,
}
------------------------------------------------------------
function TeamListCell:Attach( obj )
	UIControl.Attach(self,obj)
	
	--print(obj.name)
	self.callbackOnApplyButtonClick = function() self:OnApplyButtonClick() end
	self.Controls.m_ApplyButton.onClick:AddListener(self.callbackOnApplyButtonClick)
	return self
end


function TeamListCell:OnRecycle()
	self.Controls.m_ApplyButton.onClick:RemoveListener(self.callbackOnApplyButtonClick)
	UIControl.OnRecycle(self)
end


--队伍成员改变
function TeamListCell:TeamMemberChange()
	
	
end

--队伍成员改变监听
function TeamListCell:Register()
		
end

--队伍成员改变注销监听
function TeamListCell:UnRegister()
	
end

------------------------------------------------------------
function TeamListCell:RefreshCellUI(info)

	if info == nil then 
		return 
	end
	self.m_dwPDBID = info.dwPDBID
    if info.nTeamTargetID then 
        local item = IGame.rktScheme:GetSchemeInfo(TEAMTARGET_CSV, info.nTeamTargetID)
        if nil ~= item then 
            self.Controls.m_EventNameText.text = item.ActivityName
        end
    end
--	self:UnRegister()
	self.m_teamID = info.nTeamID
--	self:Register()
	self.Controls.m_PlayerNameText.text = info.szName
	self.Controls.m_LevelText.text = info.nLevel
	self.Controls.m_profession.text =GameHelp.GetVocationName(info.nVocation) 
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

function TeamListCell:OnDestroy()
	
	self.Controls.m_ApplyButton.onClick:RemoveListener(self.callbackOnApplyButtonClick)
	UIControl.OnDestroy(self)
end
------------------------------------------------------------
--申请入队
function TeamListCell:OnApplyButtonClick() 
	--print(self.transform.gameObject.name)
	local myTeam = IGame.TeamClient:GetTeam()
	
	if myTeam ~= nil and myTeam:GetTeamID() ~= 0 then 
		IGame.ChatClient:addSystemTips(TipType_Operate,InfoPos_ActorUnder,"你已经在队伍中" )
		return
	end
	IGame.TeamClient:RequestJoin(self.m_dwPDBID)
end
------------------------------------------------------------
return TeamListCell
