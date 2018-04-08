------------------------------------------------------------
local TeamGoalActiveCell =  UIControl:new
{
	windowName = "TeamGoalActiveCell" ,
	m_Name = nil,
	m_LowLevel = nil,
	m_HighLevel = nil,
	m_callbackOnClick = nil,
	m_activeID = nil,
	m_toggle = nil,
}
------------------------------------------------------------
function TeamGoalActiveCell:Attach( obj )
	UIControl.Attach(self,obj)
	self.toggleChanged = function(on) self:OnToggleChanged(on) end
	return self
end

------------------------------------------------------------

function TeamGoalActiveCell:SetName(name)
	self.Controls.m_activeName.text = name
	self.Controls.m_inactiveName.text = name
	
end

function TeamGoalActiveCell:OnRecycle()
	self.m_activeID =nil
	self.m_toggle.onValueChanged:RemoveListener(self.toggleChanged)
	UIControl.OnRecycle(self)
end

function TeamGoalActiveCell:SetLabelAcvtive(state)
	self.Controls.m_activeName.gameObject:SetActive(state)
		self.Controls.m_inactiveName.gameObject:SetActive(not state)
end

function TeamGoalActiveCell:SetActiveID(activeID)
	self.m_activeID = activeID
	self.m_toggle = self.transform:GetComponent(typeof(Toggle))
	if self.m_toggle.isOn ==true then 
		self:SetLabelAcvtive(true)
	else
		self:SetLabelAcvtive(false)
	end
	if self.m_toggle ~= nil then 
		self.m_toggle.onValueChanged:AddListener(self.toggleChanged)
	end
end

function TeamGoalActiveCell:OnToggleChanged(on)
	if true == on then 
		UIManager.TeamGoalsWindow:GotoCurrentActiveID(self.m_activeID )
		self:SetLabelAcvtive(true)
	else
		self:SetLabelAcvtive(false)
	end
end

------------------------------------------------------------
return TeamGoalActiveCell

