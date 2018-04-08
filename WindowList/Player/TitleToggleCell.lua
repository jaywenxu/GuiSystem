local TitleToggleCell = UIControl:new
{
	windowName = "TitleToggleCell" ,
}
------------------------------------------------------------
function TitleToggleCell:Attach( obj )
	self.OnClick =function(on) self:OnClickToggle(on) end
	UIControl.Attach(self,obj)
	self.Controls.m_toggle.onValueChanged:AddListener(self.OnClick)
	return self
end

function TitleToggleCell:SetToggleGroup(group)
	self.Controls.m_toggle.group = group
end

function TitleToggleCell:Refresh(szTypeName, nHadNum, nTypeSum, nType)
	self.Controls.m_name.text = szTypeName.."("..nHadNum.."/"..nTypeSum..")"
	self.m_nType = nType
	--if targetID == currentTargetID then 
	--	if self.Controls.m_toggle.isOn == true then 
	--		self:OnClickToggle(true)
	--	end
	--	self.Controls.m_toggle.isOn =true
end

function TitleToggleCell:OnRecycle()
	self.Controls.m_toggle.onValueChanged:RemoveListener(self.OnClick)
	UIControl.OnRecycle(self)
end

-- 卸载
function TitleToggleCell:OnDestroy()
    self.Controls.m_toggle.onValueChanged:RemoveListener(self.OnClick)
    UIControl.OnDestroy(self)
end 

function TitleToggleCell:OnClickToggle(on)
    if not on then 
        self.Controls.m_name.color = Color.New(0.34,0.48, 0.59)         
        return 
    end
    self.Controls.m_name.color = Color.New(0.78,0.47, 0.26)     
    UIManager.TitleWindow:SelectType(self.m_nType)
end
return TitleToggleCell