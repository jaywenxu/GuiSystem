---------------------------灵兽系统技能Item---------------------------------------
local PetSkillItem = UIControl:new
{
	windowName = "PetSkillItem",
	m_Index = 0,					--对应的灵兽技能在槽里的索引
	m_UID = -1,						--所属的实体UID
	m_SkillID = -1,					--技能ID
	m_IsLock = true,				--是否解锁
	m_AddShow = false,				--是否是显示加状态
	m_selected_calback = nil, 		--点击回调
	m_ShowEffect = false, 			--是否显示选中效果
	m_ShowLevel = true,				--是否显示等级
}

function PetSkillItem:Attach(obj)
	UIControl.Attach(self,obj)	
	--注册点击事件
	self.callback_OnSelectChanged = function(on) self:OnSelectChanged(on) end
	self.Controls.m_Toggle.onValueChanged:AddListener(self.callback_OnSelectChanged)
end

-------------------------------------------------------------------
-- 设置选中时回调函数	
-- @param func_cb : 回调函数
-------------------------------------------------------------------
function PetSkillItem:SetSelectCallback(func_cb)
	self.m_selected_calback = func_cb
end	

--设置是否交互
function PetSkillItem:SetInteractable(interactable)
	self.Controls.m_Toggle.interactable = interactable
end

--设置UID
function PetSkillItem:SetUID(uid)
	self.m_UID = uid
end

--设置索引
function PetSkillItem:SetIndex(nIndex, uid)
	self.m_Index = nIndex
	self.m_UID = uid
end

--设置等级显示
function PetSkillItem:SetLevel(showLevel,level)
	self.m_ShowLevel = showLevel
	self.Controls.m_LevelText.gameObject:SetActive(showLevel)
	if not showLevel then return end
	self.Controls.m_LevelText.text = tostring(level)
end

--根据技能ID设置显示
function PetSkillItem:SetViewByID(skillID,level)
	self.m_SkillID = skillID
	if not level then
		level = 1
	end
	
	--根据ID获得技能表数据
	local skillRecord = IGame.rktScheme:GetSchemeInfo(PETSKILLBOOK_CSV, skillID, level)
	if not skillRecord then return end
	self:SetIcon(skillRecord.SkillIcon)
	self:SetQuality(AssetPath_PetSkillQuality[skillRecord.SkillQuality])
	self:SetLevel(self.m_ShowLevel,level)
	self.m_AddShow = false
	self.Controls.m_Add.gameObject:SetActive(false)
	self.Controls.m_Lock.gameObject:SetActive(false)
end

--设置阵灵ID显示
function PetSkillItem:SetZhenLinViewByID(skillID, level)
	self.m_SkillID = skillID
	if not level then
		level = 1
	end
	
	local skillRecord = IGame.rktScheme:GetSchemeInfo(PETZHENCFG_CSV, skillID, level)
	self:SetIcon(skillRecord.Icon)
	self:SetLevel(false,level)
end

--设置Icon
function PetSkillItem:SetIcon(path)
	if not self.Controls.m_SkillIcon.gameObject.activeInHierarchy then
		self.Controls.m_SkillIcon.gameObject:SetActive(true)
	end
	if self.Controls.m_Add.gameObject.activeInHierarchy then
		self.m_AddShow = false
		self.Controls.m_Add.gameObject:SetActive(false)
	end
	UIFunction.SetImageSprite(self.Controls.m_SkillIcon, AssetPath.TextureGUIPath..path)
end

--设置技能品质
function PetSkillItem:SetQuality(path)
	if not self.Controls.m_Quality.gameObject.activeInHierarchy then
		self.Controls.m_Quality.gameObject:SetActive(true)
	end
	UIFunction.SetImageSprite(self.Controls.m_Quality, path)
end

--设置是否解锁
function PetSkillItem:SetLock(nLock)
	if nLock then
		self:Clear()
	end
	self.Controls.m_Lock.gameObject:SetActive(nLock)
end

--设置加号图片显示
function PetSkillItem:SetAddImg(nLock)
	self:Clear()
	self.m_AddShow = nLock
	self.Controls.m_Add.gameObject:SetActive(nLock)
end

--设置背景,图片
function PetSkillItem:SetBG(nPath)
	UIFunction.SetImageSprite(self.Controls.m_BG, AssetPath.TextureGUIPath..nPath)
end

--设置是否显示选中效果
function PetSkillItem:SetShowSelectEffect(nShow)
	self.m_ShowEffect = nShow
end

--设置toggle组
function PetSkillItem:SetToggleGroup(toggleGroup)
	self.Controls.m_Toggle.group = toggleGroup
end

--清空显示
function PetSkillItem:Clear()
	self.m_SkillID = -1
	self.m_AddShow = false
    self.Controls.m_LevelText.text = ""
	self.Controls.m_Add.gameObject:SetActive(false)
	self.Controls.m_SkillIcon.gameObject:SetActive(false)
	self.Controls.m_Quality.gameObject:SetActive(false)
	self.Controls.m_Lock.gameObject:SetActive(false)
	self.Controls.m_Select.gameObject:SetActive(false)
end

--切换回调
function PetSkillItem:OnSelectChanged(on)
	if self.m_ShowEffect then
		if not on then
			self.Controls.m_Select.gameObject:SetActive(false)
		else
			self.Controls.m_Select.gameObject:SetActive(true)
		end
	end
	if nil ~= self.m_selected_calback then 
		if on then
			self.m_selected_calback(self.m_Index,self)
		end
	end
end

-- 设置是否显示遮罩
function PetSkillItem:SetShowZheZhao(flag)
    
    self.Controls.m_picZheZhao.gameObject:SetActive(flag)
end

--选中
function PetSkillItem:SetFocus(on)
	self.Controls.m_Toggle.isOn = on
end

return PetSkillItem