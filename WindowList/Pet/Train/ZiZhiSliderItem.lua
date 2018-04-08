
---------------------------灵兽系统展示界面---------------------------------------
local ZiZhiSliderItem = UIControl:new
{
	windowName = "ZiZhiSliderItem",
}

function ZiZhiSliderItem:Attach(obj)
	UIControl.Attach(self,obj)
end

--设置名字
function ZiZhiSliderItem:SetTitleLabel(nTitle)
	self.Controls.m_TitleText.text = nTitle
end

--设置滑动条文字，及值
function ZiZhiSliderItem:SetTextAndValue(nCur, nMax)
	local curStr = tostring(nCur)
	local maxStr = tostring(nMax)
	self.Controls.m_ValueText.text = curStr .. "/" .. maxStr
	self.Controls.m_Slider.value = nCur / nMax
end


return ZiZhiSliderItem
