
-----------------------------灵兽阵灵槽------------------------------
local PetZhenFaProp = UIControl:new
{
	windowName = "PetZhenFaProp",

	m_Index = -1, 				--当前索引
}

function PetZhenFaProp:Attach(obj)
	UIControl.Attach(self,obj)
	
end

--设置索引
function PetZhenFaProp:SetIndex(index)
	self.m_Index = index
end

--设置显示
function PetZhenFaProp:SetText(text)
	self.Controls.m_Text.text = text
end

return PetZhenFaProp