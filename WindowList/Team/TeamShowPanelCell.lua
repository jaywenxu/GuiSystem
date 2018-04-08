--组队显示窗口单元项，在主界面显示
------------------------------------------------------------
local TeamShowPanelCell =  UIControl:new
{
	windowName = "TeamShowPanelCell" ,
	m_dbID = nil,
	m_currentState =nil,
	m_index = 0,
}
------------------------------------------------------------
function TeamShowPanelCell:Attach( obj )
	UIControl.Attach(self,obj)
	self.Controls.slider = self.Controls.m_bloodSlider:GetComponent(typeof(Slider))
	self.callbackOnButtonClick = function() self:OnButtonClick() end
	self.Controls.m_Button.onClick:AddListener(self.callbackOnButtonClick)
	
	return self
end


function TeamShowPanelCell:SetCellIndex(index)
	self.m_index = index
end

function TeamShowPanelCell:ChangeToLeader(State)
	self.Controls.m_leaderFlag.gameObject:SetActive(State)
end

function TeamShowPanelCell:ChangeOldLeader(info)
	if nil == info then 
		return
	end
	if self.m_dbID~= nil then 
		if info.dwOldCaptain == self.m_dbID then 
			self:ChangeToLeader(false)
			
		elseif info.dwNewCaptain == self.m_dbID then 
			self:ChangeToLeader(true)
		end
	end
		
end
--STeamMemberInfo
function TeamShowPanelCell:InitCell(member)
	
	if member ~= nil then           
		self.m_dbID = member.dwPDBID
		self.Controls.m_PlayerNameText.text = member.szName
		self.Controls.m_PlayerLevelText.text = tostring(member.nLevel)
		UIFunction.SetHeadImage(self.Controls.m_PlayerHeadImage,member.nFaceID)
		UIFunction.SetImageSprite(self.Controls.m_vocation,GuiAssetList.gProfessionIcon[member.nVocation])
        member.nCurHP = member.nCurHP or 0
        member.nMaxHP = member.nMaxHP or 1
		local currentHpPercent = member.nCurHP/member.nMaxHP
		self.Controls.slider.value = currentHpPercent        
		self:CellRefeshFollowState(member.bFollowCaptain or false)
        self:ChangeToLeader(member.bCaptainFlag or false)
		self.transform.gameObject:SetActive(true)
		local entity = IGame.EntityClient:GetByPDBID(member.dwPDBID)
		local entityView =nil
		if nil ~= entity then 
			entityView = entity:GetEntityView()	
		end

		local create = (entityView ~= nil and entityView.transform ~= nil)
		self:ChangeTeammatePosState(create)
	else
		self.transform.gameObject:SetActive(false)
	end

end
-- 获取当前的cell的DBID
function TeamShowPanelCell:GetCellDBID()
	return self.m_dbID or 0
end

-- 更新跟随状态信息
function TeamShowPanelCell:CellRefeshFollowState(bFollow)
	self.Controls.m_followState.gameObject:SetActive(bFollow)
end

--更新队友血量
function TeamShowPanelCell:RefreshHp(curHp,MaxHp)
	local currentHpPercent = curHp/MaxHp
	self.Controls.slider.value = currentHpPercent
end

------------------------------------------------------------
function TeamShowPanelCell:OnDestroy()
	self.Controls.m_Button.onClick:RemoveListener(self.callbackOnButtonClick)
	UIControl.OnDestroy(self)
end
------------------------------------------------------------
function TeamShowPanelCell:OnButtonClick() 
	local nPDBID = GetHero():GetNumProp(CREATURE_PROP_PDBID)
	--当玩家头像被点击时，创建点击面板 队长点击面板和队员点击面板不一样
	UIManager.TeamShowPanelLeaderClickWindow:InitInfo(self.m_dbID,self.m_index,1)
	UIManager.TeamShowPanelLeaderClickWindow:Show(true)
	
end

-- 因为是异步加载的问题需要这样重新设置回去
function  TeamShowPanelCell:RealGrayState()
	if self.m_dbID == nil then 
		return
	end
	UIFunction.SetImageGray(self.Controls.m_bloodImage,not self.m_currentState)
	UIFunction.SetImageGray(self.Controls.m_PlayerHeadImage,not self.m_currentState)
	UIFunction.SetImageGray(self.Controls.m_vocation,not self.m_currentState)
end


--修改人物所在位置描述
function TeamShowPanelCell:ChangeTeammatePosState(state)
	self.m_currentState = state
	self.SetGrayFun = function() self:RealGrayState() end
	self.Controls.m_zhezhao.gameObject:SetActive(not state)
end
------------------------------------------------------------
return TeamShowPanelCell