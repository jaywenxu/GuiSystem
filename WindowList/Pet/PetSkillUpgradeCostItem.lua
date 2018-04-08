local PetSkillUpgradeCostItem = UIControl:new
{
	windowName = "PetSkillUpgradeCostItem",
	
	m_ShowSelectedEffect = true,					--显示选中图片
	
	valueChange_callback,							--值改变回调
}
local this = PetSkillUpgradeCostItem

function PetSkillUpgradeCostItem:Attach(obj)
	UIControl.Attach(self,obj)	
	
	--注册点击事件
	self.callback_OnSelectChanged = function(on) self:OnSelectChanged(on) end
	self.Controls.m_Toggle.onValueChanged:AddListener(self.callback_OnSelectChanged)
	
	return self
end

--设置物品ID,  初始化显示
function PetSkillUpgradeCostItem:InitView(goodsID)
	local record = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV,goodsID)
	if not record then return end 
	self:SetView(record)
end

--设置icon
function PetSkillUpgradeCostItem:SetView(record)
	UIFunction.SetImageSprite(self.Controls.m_Icon, AssetPath.TextureGUIPath.. record.lIconID1)
	local imageBgPath = AssetPath_GoodsColor[tonumber(record.lBaseLevel)]
	UIFunction.SetImageSprite( self.Controls.m_Quality , imageBgPath )
end

--设置剩余数量
function PetSkillUpgradeCostItem:SetNum(needNum, haveNum)
	if needNum <= haveNum then
		self.Controls.m_NumText.text = string.format("%d/%d", needNum, haveNum)
	else
		self.Controls.m_NumText.text = string.format("%d/<color=red>%d</color>", needNum, haveNum)
	end
end

--选中回调
function PetSkillUpgradeCostItem:OnSelectChanged(on)
	if on then
		if self.m_ShowSelectedEffect then
			self.Controls.m_Select.gameObject:SetActive(true)
		end
		if nil ~= self.m_selected_calback then 
			self.m_selected_calback(self)
		end
	else
		if self.m_ShowSelectedEffect then
			self.Controls.m_Select.gameObject:SetActive(false)
		end
		
		if nil ~= self.m_selected_calback then 
			self.m_selected_calback(self)
		end
	end
end

--设置是否显示选中图片
function PetSkillUpgradeCostItem:SetShowSelectImg(show)
	self.m_ShowSelectedEffect = show
end

return this