--组队申请列表项
------------------------------------------------------------
local TeamApplyListCell = UIControl:new
{
	windowName = "TeamApplyListCell" ,

	dwBuildingSN = nil,
}
------------------------------------------------------------
function TeamApplyListCell:Attach( obj )
	UIControl.Attach(self,obj)
	
	self.callBackOnAgreeButtonClick = function() self:OnAgreeButtonClick() end
	self.Controls.m_AgreeButton.onClick:AddListener(self.callBackOnAgreeButtonClick)
	
	self.callBackOnDisagreeButtonClick = function() self:OnDisagreeButtonClick() end
	self.Controls.m_DisagreeButton.onClick:AddListener(self.callBackOnDisagreeButtonClick)--]]
	
	return self
end

function TeamApplyListCell:RefreshCellUI(info)

	if info == nil or nil == info.personContext then 
		return
	end
	self.dwBuildingSN = info.dwBuildingSN
	self.Controls.m_PlayerNameText.text = info.personContext.szName
	self.Controls.m_playerLevel.text = info.personContext.nNumProp[CREATURE_PROP_LEVEL]
	self.Controls.m_playerProfession.text = GameHelp.GetVocationName(info.personContext.nNumProp[CREATURE_PROP_VOCATION])
	UIFunction.SetHeadImage(self.Controls.m_headImage,info.personContext.nNumProp[CREATURE_PROP_FACEID] )
end

------------------------------------------------------------
function TeamApplyListCell:OnDestroy()
	self.Controls.m_AgreeButton.onClick:RemoveListener(self.callBackOnAgreeButtonClick)
	self.Controls.m_DisagreeButton.onClick:RemoveListener(self.callBackOnDisagreeButtonClick)
	UIControl.OnDestroy(self)
end

--[[------------------------------------------------------------
function TeamApplyListCell.CreateItem(parentTransform)
	local item = TeamApplyListCell:new()
	rkt.GResources.FetchGameObjectAsync(GuiAssetList.TeamApplyListCell,
		function (path , obj , ud)
		if nil == obj then
			print("Failed to Load the object")
			return
		else
			obj.transform:SetParent(parentTransform,false)	
			item:Attach(obj)
		end
	end,
	nil, AssetLoadPriority.GuiNormal )
	return item
end--]]
--同意申请按钮按下
function TeamApplyListCell:OnRecycle()

	self.Controls.m_AgreeButton.onClick:RemoveListener(self.callBackOnAgreeButtonClick)
	self.Controls.m_DisagreeButton.onClick:RemoveListener(self.callBackOnDisagreeButtonClick)
	UIControl.OnRecycle(self)
end

------------------------------------------------------------
--同意申请按钮按下
function TeamApplyListCell:OnAgreeButtonClick()
	IGame.TeamClient:luaRequestRespond(self.dwBuildingSN, EBuildFlowResult_Agree)
	UIManager.TeamApplyListWindow:Remove()
end

------------------------------------------------------------
--不同意申请按钮按下
function TeamApplyListCell:OnDisagreeButtonClick() 
    IGame.TeamClient:luaRequestRespond(self.dwBuildingSN, EBuildFlowResult_Disagree)
    UIManager.TeamApplyListWindow:Remove()
end
------------------------------------------------------------
return TeamApplyListCell