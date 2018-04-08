--/******************************************************************
--** 文件名:    LifeSkillCookGoodsItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    何水大(765865368@qq.com)
--** 日  期:    2017-11-17
--** 版  本:    1.0
--** 描  述:    生活技能烹饪物品的图标脚本
--** 应  用:  
--******************************************************************/

local LifeSkillCookGoodsItem = UIControl:new
{
    windowName = "LifeSkillCookGoodsItem",
	m_goodsID = 0, -- 物品ID
	m_group = nil,
	m_TuiJian = false,
}

function LifeSkillCookGoodsItem:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	self.onItemClick = function(isOn) self:OnItemClick(isOn) end
	
	local controls = self.Controls
	controls.m_toggle.group = self.m_group
	controls.m_toggle.onValueChanged:AddListener(self.onItemClick )
	
	self:SubscribeEvent()
end

-- 更新物品信息
-- @goodsID:物品ID
function LifeSkillCookGoodsItem:UpdateItem(goodsID)
	self.m_goodsID = goodsID
	
	local goodsScheme = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodsID)
	if not goodsScheme then
		uerror("LifeSkillCookGoodsItem:UpdateItem, 没有找到物品配置id: " .. goodsID )
		return
	end
	
	UIFunction.SetImageSprite(self.Controls.m_GoodsIcon, AssetPath.TextureGUIPath..goodsScheme.lIconID1)
	UIFunction.SetImageSprite(self.Controls.m_QualityIcon, AssetPath.TextureGUIPath..goodsScheme.lIconID2)
	
	local cookScheme = IGame.rktScheme:GetSchemeInfo(LIFESKILLCOOK_CSV, goodsID)
	if not cookScheme then
		return
	end
	
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end
	
	local skillPart = pHero:GetEntityPart(ENTITYPART_PERSON_LIFESKILL)
    if not skillPart then
        return
    end		
	local skillLevel = skillPart:GetLifeSkillLevel(emFishing)
	
	if table_count(cookScheme.TuiJian) < 2 then
		self.Controls.m_TuiJianIcon.gameObject:SetActive(false)
		self.m_TuiJian = false
		return
	end
	
	if skillLevel >= cookScheme.TuiJian[1] and skillLevel <= cookScheme.TuiJian[2] then
		self.Controls.m_TuiJianIcon.gameObject:SetActive(true)
		self.m_TuiJian = true
	else
		self.Controls.m_TuiJianIcon.gameObject:SetActive(false)
		self.m_TuiJian = false
	end
end

-- 技能图标的点行为
function LifeSkillCookGoodsItem:OnItemClick(state)
	if state == true then 
		rktEventEngine.FireExecute(MSG_MODULEID_LIFESKILL, SOURCE_TYPE_SYSTEM, SKILL_UI_EVENT_LIFESKILL_COOKITEM_CLICK, self.m_goodsID)
	end
end

function LifeSkillCookGoodsItem:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	self:UnSubscribeEvent()
	UIControl.OnDestroy(self)
	
end

function LifeSkillCookGoodsItem:SetGroup(group)
	self.m_group = group
end

-- 清除数据
function LifeSkillCookGoodsItem:CleanData()

	self.Controls.m_toggle.onValueChanged:RemoveListener(self.onItemClick )
	self.onItemClick = nil
	
end

-- 设置焦点
function LifeSkillCookGoodsItem:SetFocus(on)
	self.Controls.m_toggle.isOn = on
end

-- 是否是推荐药
function LifeSkillCookGoodsItem:IsTuiJian()
	return self.m_TuiJian
end

-- 事件绑定
function LifeSkillCookGoodsItem:SubscribeEvent()
	
	self.m_ArrSubscribeEvent = 
	{
		{
			e = ENTITYPART_PERSON_LIFESKILL, s = SOURCE_TYPE_SYSTEM, i = SKILL_UI_EVENT_LIFESKILL_UPGRADE,
			f = function(event, srctype, srcid, skillId) self:OnLifeSkillUpgrade(skillId) end,
		},
	}
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.SubscribeExecute(v.e, v.s, v.i, v.f)
	end
	
end

-- 移除事件的绑定
function LifeSkillCookGoodsItem:UnSubscribeEvent()
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.UnSubscribeExecute(v.e, v.s, v.i, v.f)
	end
	
end

-- 技能升级事件
function LifeSkillCookGoodsItem:OnLifeSkillUpgrade(skillId)
	if skillId == emFishing and self.m_goodsID ~= 0 then
		self:UpdateItem(self.m_goodsID)
	end
end

return LifeSkillCookGoodsItem