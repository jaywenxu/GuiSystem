-- 轻功气力值窗口

local QingGongStrengthWindow = UIWindow:new
{
	windowName = "QingGongStrengthWindow",
	curStrength = 0,
	maxStrength = 0,
	
}

function QingGongStrengthWindow:Init()
	
end

function QingGongStrengthWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
    
	self:Update(self.curStrength, self.maxStrength)
	
	return self
end

-- 更新
function QingGongStrengthWindow:Update(curStrength, maxStrength)
	self.curStrength = curStrength
	self.maxStrength = maxStrength
		
	if not self:isLoaded() then
		return
	end
	
	if curStrength < 0 then
		curStrength = 0
	end
	
	self.Controls.m_Strength.text = "气力值："..curStrength
	self.Controls.m_Fill.fillAmount = curStrength / maxStrength
end

return QingGongStrengthWindow