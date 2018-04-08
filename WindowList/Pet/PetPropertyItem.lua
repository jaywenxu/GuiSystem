---------------------------灵兽系统属性Item---------------------------------------
local PetPropertyItem = UIControl:new
{
	windowName = "PetPropertyItem",
}

function PetPropertyItem:Attach(obj)
	UIControl.Attach(self,obj)	
end

--初始化后显示信息
function PetPropertyItem:InitView(nName, nValue)
	self.Controls.m_PropNameText.text = tostring(nName)
	self:SetValue(nValue)
end

--设置属性值
function PetPropertyItem:SetValue(nValue)
	self.Controls.m_PropValueText.text = tostring(nValue)
end

return PetPropertyItem