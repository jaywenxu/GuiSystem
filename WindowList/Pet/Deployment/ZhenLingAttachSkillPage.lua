
-----------------------------灵兽阵真灵附体技能页面------------------------------
local ZhenLingAttachSkillPage = UIControl:new
{
	windowName = "ZhenLingAttachSkillPage",
	
	SkillID = -1,										--技能书ID

}



function ZhenLingAttachSkillPage:Attach(obj)
	UIControl.Attach(self,obj)
	self.BtnClickCB = function() self:OnBtnClick() end
	self.Controls.m_AttachBtn.onClick:AddListener(self.BtnClickCB)
	
	
	self.HideCB = function() self:Hide() end
	UIFunction.AddEventTriggerListener(self.Controls.m_BGMask,  EventTriggerType.PointerClick, self.HideCB)
end

function ZhenLingAttachSkillPage:Show()
	UIControl.Show(self)
end

function ZhenLingAttachSkillPage:Hide( destroy )
	UIControl.Hide(self, destroy)
end

function ZhenLingAttachSkillPage:OnDestroy()
	UIFunction.RemoveEventTriggerListener(self.Controls.m_BGMask,  EventTriggerType.PointerClick, self.HideCB)
	UIControl.OnDestroy(self)
end


--点击附体按钮回调事件
function ZhenLingAttachSkillPage:OnBtnClick()

end

return ZhenLingAttachSkillPage