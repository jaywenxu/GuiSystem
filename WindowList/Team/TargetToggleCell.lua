--组队目标
------------------------------------------------------------
local TargetToggleCell = UIControl:new
{
	windowName = "TargetToggleCell" ,
	m_targetID = 0,
    m_reqServerTime = nil,
}
------------------------------------------------------------
function TargetToggleCell:Attach( obj )

	self.OnClick =function(on) self:OnClickToggle(on) end
	UIControl.Attach(self,obj)
	self.Controls.m_toggle.onValueChanged:AddListener(self.OnClick)

	return self
end

function TargetToggleCell:SetToggleGroup(group)
	self.Controls.m_toggle.group = group
end

function TargetToggleCell:Refresh(name,targetID,currentTargetID)
	self.Controls.m_name.text = name
	self.m_targetID = targetID
	if targetID == currentTargetID then 
		if self.Controls.m_toggle.isOn == true then 
			self:OnClickToggle(true)
		end
		self.Controls.m_toggle.isOn =true
	end
end

function TargetToggleCell:OnRecycle()
	self.Controls.m_toggle.onValueChanged:RemoveListener(self.OnClick)
	UIControl.OnRecycle(self)
end

-- 卸载
function TargetToggleCell:OnDestroy()
    
    self.Controls.m_toggle.onValueChanged:RemoveListener(self.OnClick)
    UIControl.OnDestroy(self)
end 


function TargetToggleCell:OnClickToggle(on)
       
    if not on then 
        self.Controls.m_name.color = Color.New(0.34,0.48, 0.59)         
        return 
    end  
    
    self.Controls.m_name.color = Color.New(0.78,0.47, 0.26)     
    local cur_time = Time.realtimeSinceStartup
    if self.m_reqServerTime and cur_time - self.m_reqServerTime < 1 then 
        local eventdata = {}
        eventdata.nTeamTargetID = self.m_targetID	
        rktEventEngine.FireEvent(EVENT_TEAM_QUERY_BY_TARGET, SOURCE_TYPE_TEAM, 0, eventdata) 
        return 
    end 
    
    self.m_reqServerTime = cur_time
    IGame.TeamClient:QueryTeamByTarget(self.m_targetID)
    UIManager.TeamWindow.WidgetConfigInfo[1].widgetScript.currentTargetID = self.m_targetID
end
return TargetToggleCell