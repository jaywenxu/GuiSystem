---------------------------灵兽系统属性滑动条Item---------------------------------------
local PetPropSliderItem = UIControl:new
{
	windowName = "PetPropSliderItem",
}

function PetPropSliderItem:Attach(obj)
	UIControl.Attach(self,obj)	
	self.Slider = self.Controls.m_Slider.gameObject:GetComponent(typeof(Slider))
end

--初始化值
function PetPropSliderItem:InitView(nName, nCurValue, nMaxValue)
	self:SetPropName(nName)
	self:SetPropValue(nCurValue, nMaxValue)
end

--设置属性名字
function PetPropSliderItem:SetPropName(nName)
	self.Controls.m_PropNameText.text = nName
end

--设置属性值
function PetPropSliderItem:SetPropValue(nCurValue, nMaxValue)
	if not nCurValue or not nMaxValue then return end
	self.Slider.value = nCurValue / nMaxValue
	self.Controls.m_PropValueText.text = string.format("%d/%d", nCurValue, nMaxValue)	
end

--设置前置背景图片
function PetPropSliderItem:SetForgroudImage(imagePath)
	UIFunction.SetImageSprite(self.Controls.m_ForgroundImage, imagePath)
end

return PetPropSliderItem