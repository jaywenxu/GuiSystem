--/******************************************************************
--** 文件名:    LifeSkillItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    何水大(765865368@qq.com)
--** 日  期:    2017-11-01
--** 版  本:    1.0
--** 描  述:    生活技能列表Item
--** 应  用:  
--******************************************************************/

local LifeSkillItem = UIControl:new
{
    windowName = "LifeSkillItem",
	m_group = nil,
	m_SkillID = 0, -- 技能ID
}

function LifeSkillItem:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	self.onItemClick = function(isOn) self:OnItemClick(isOn) end
	
	local controls = self.Controls
	controls.m_toggle.group = self.m_group
	controls.m_toggle.onValueChanged:AddListener(self.onItemClick )

	
end

-- 更新图标
-- @actScheme:生活技能配置
function LifeSkillItem:UpdateItem(skillID)
	self.m_SkillID = skillID
	local scheme = IGame.rktScheme:GetSchemeInfo(LIFESKILLS_CSV, skillID, 1)
	
	local hero = GetHero() 
    if not hero then 
        return 
    end
    
	local skillPart = hero:GetEntityPart(ENTITYPART_PERSON_LIFESKILL)
    if not skillPart then
        return
    end
	
	local controls = self.Controls
	local skillLevel = skillPart:GetLifeSkillLevel(scheme.ID)
	
	controls.m_TextSkillName.text = scheme.Name
	controls.m_TextSkillLevel.text = skillLevel
	
	controls.m_TfTipCanUpgrade.gameObject:SetActive(canUpgrade)
	UIFunction.SetImageSprite(controls.m_ImageSkillIcon, AssetPath.TextureGUIPath..scheme.Icon)
	
	-- 如果技能没有等级，不要显示等级UI
	local nextScheme = IGame.rktScheme:GetSchemeInfo(LIFESKILLS_CSV, skillID, 2)
	if skillLevel == 1 and not nextScheme then
		controls.m_ShowLevel.gameObject:SetActive(false)
	end
end

-- 技能图标的点行为
function LifeSkillItem:OnItemClick(state)
	if state == true then 
		rktEventEngine.FireExecute(ENTITYPART_PERSON_LIFESKILL, SOURCE_TYPE_SYSTEM, SKILL_UI_EVENT_LIFESKILL_ITEM_CLICK, self.m_SkillID)
	end

end


function LifeSkillItem:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function LifeSkillItem:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end


function LifeSkillItem:SetGroup(group)
	self.m_group = group
end

-- 清除数据
function LifeSkillItem:CleanData()

	self.Controls.m_toggle.onValueChanged:RemoveListener(self.onItemClick )
	self.onItemClick = nil
	
end

-- 设置焦点
function LifeSkillItem:SetFocus(on)
	self.Controls.m_toggle.isOn = on
end

return LifeSkillItem