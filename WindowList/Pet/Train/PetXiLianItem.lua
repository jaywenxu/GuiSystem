
---------------------------灵兽系统展示界面---------------------------------------
local PetXiLianItem = UIControl:new
{
	windowName = "PetXiLianItem",
}

function PetXiLianItem:Attach(obj)
	UIControl.Attach(self,obj)
end

--设置属性名字
function PetXiLianItem:SetName(nName)
	self.Controls.m_NameText.text = nName
end

--设置原始属性值
function PetXiLianItem:SetOriginValue(nNum)
	self.Controls.m_OriginNumText.text = nNum
end

--设置变化的属性值
function PetXiLianItem:SetDifferentValue(nNum)
	if nNum > 0 then			--上升
		self.Controls.m_ArrowImage.gameObject:SetActive(true)
		UIFunction.SetImageSprite(self.Controls.m_ArrowImage, AssetPath.TextureGUIPath .. "Common_frame/city_tips_shangsheng.png")
		self.Controls.m_DifferentNumText.text = string.format("<color=green>%d</color>", nNum)
	elseif nNum < 0 then		--下降
		self.Controls.m_ArrowImage.gameObject:SetActive(true)
		UIFunction.SetImageSprite(self.Controls.m_ArrowImage, AssetPath.TextureGUIPath .. "Common_frame/city_tips_xiajiang.png")
		self.Controls.m_DifferentNumText.text = string.format("<color=red>%d</color>", math.abs(nNum))
	else
		self.Controls.m_ArrowImage.gameObject:SetActive(false)
		self.Controls.m_DifferentNumText.text = ""
	end
end

--设置箭头     -1:下降   0:不变  1:上升
function PetXiLianItem:SetArrowUp(nOptionNum)
	if nOptionNum == -1 then
		self.Controls.m_ArrowImage.gameObject:SetActive(true)
		UIFunction.SetImageSprite(self.Controls.m_ArrowImage, AssetPath.TextureGUIPath .. "Common_frame/city_tips_xiajiang.png")
	elseif nOptionNum == 1 then
		self.Controls.m_ArrowImage.gameObject:SetActive(true)
		UIFunction.SetImageSprite(self.Controls.m_ArrowImage, AssetPath.TextureGUIPath .. "Common_frame/city_tips_shangsheng.png")
	else
		self.Controls.m_ArrowImage.gameObject:SetActive(false)
	end
end

--忽略变化显示
function PetXiLianItem:ShowDiffrence(nShow)
	self.Controls.m_ArrowImage.gameObject:SetActive(nShow)
	self.Controls.m_DifferentNumText.gameObject:SetActive(nShow)
end

return PetXiLianItem
