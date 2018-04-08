--/******************************************************************
--** 文件名:    LifeSkillCookCostItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    何水大(765865368@qq.com)
--** 日  期:    2017-12-01
--** 版  本:    1.0
--** 描  述:    生活技能烹饪物品素材的图标脚本
--** 应  用:  
--******************************************************************/

local COLOR_BLACK = "597993"
local COLOR_GREEN = "10A41B"
local COLOR_RED = "E4595A"


local LifeSkillCookCostItem = UIControl:new
{
    windowName = "LifeSkillCookCostItem",
	m_group = nil,
	m_CostGoodsID = 0, -- 烹饪素材ID
	m_CostNum = 0, -- 素材数量
}

function LifeSkillCookCostItem:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	self.onItemClick = function(isOn) self:OnItemClick(isOn) end
	
	local controls = self.Controls
	controls.m_toggle.group = self.m_group
	controls.m_toggle.onValueChanged:AddListener(self.onItemClick )
	
	self.onBuyButtonClick = function() self:OnBuyButtonClick() end
	controls.m_ButtonBuy.onClick:AddListener(self.onBuyButtonClick)
	
	self:SubscribeEvent()
end

-- 更新物品信息
-- @goodsID:物品ID
function LifeSkillCookCostItem:UpdateItem(goodsID, costNum)
	self.m_CostGoodsID = goodsID
	self.m_CostNum = costNum
	
	local goodsScheme = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodsID)
	if not goodsScheme then
		uerror("没有找到物品配置id: " .. goodsID )
		return
	end
	
	UIFunction.SetImageSprite(self.Controls.m_GoodsIcon, AssetPath.TextureGUIPath..goodsScheme.lIconID1)
	UIFunction.SetImageSprite(self.Controls.m_QualityIcon, AssetPath.TextureGUIPath..goodsScheme.lIconID2)
	
	self:SetCostNum()
end

-- 技能图标的点行为
function LifeSkillCookCostItem:OnItemClick(state)
	if state == true then 
		rktEventEngine.FireExecute(MSG_MODULEID_LIFESKILL, SOURCE_TYPE_SYSTEM, SKILL_UI_EVENT_LIFESKILL_COOKCOSTITEM_CLICK, {costGoodsID = self.m_CostGoodsID, costNum = self.m_CostNum})
	end
end

function LifeSkillCookCostItem:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	self:UnSubscribeEvent()
	UIControl.OnDestroy(self)
	
end

function LifeSkillCookCostItem:SetGroup(group)
	self.m_group = group
end

-- 清除数据
function LifeSkillCookCostItem:CleanData()
	self.Controls.m_toggle.onValueChanged:RemoveListener(self.onItemClick )
	self.onItemClick = nil
	
	self.Controls.m_ButtonBuy.onClick:RemoveListener(self.onBuyButtonClick)
	self.onBuyButtonClick = nil
end

-- 设置焦点
function LifeSkillCookCostItem:SetFocus(on)
	self.Controls.m_toggle.isOn = on
end

-- 设置素材数量
function LifeSkillCookCostItem:SetCostNum()
	local controls = self.Controls
	local costNmum = self.m_CostNum
	local haveNum = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET):GetGoodNum(self.m_CostGoodsID)
	if haveNum < costNmum then
		controls.m_TextNum.color = UIFunction.ConverRichColorToColor(COLOR_RED)
		controls.m_ButtonBuy.gameObject:SetActive(true)
	else
		controls.m_TextNum.color = UIFunction.ConverRichColorToColor(COLOR_BLACK)
		controls.m_ButtonBuy.gameObject:SetActive(false)
	end
	controls.m_TextNum.text = tostring(costNmum) .. "/" .. haveNum
end

-- 事件绑定
function LifeSkillCookCostItem:SubscribeEvent()
	self.m_ArrSubscribeEvent = 
	{
		{
			e = EVENT_SKEP_ADD_GOODS, s = SOURCE_TYPE_SKEP, i = 0,
			f = function(event, srctype, srcid) self:SetCostNum() end,
		},
		{
			e = EVENT_SKEP_REMOVE_GOODS, s = SOURCE_TYPE_SKEP, i = 0,
			f = function(event, srctype, srcid) self:SetCostNum() end,
		},
		
	}
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.SubscribeExecute(v.e, v.s, v.i, v.f)
	end
end

-- 移除事件的绑定
function LifeSkillCookCostItem:UnSubscribeEvent()
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.UnSubscribeExecute(v.e, v.s, v.i, v.f)
	end
	
end

-- 技能图标的点行为
function LifeSkillCookCostItem:OnBuyButtonClick()
	local subInfo = {
		bShowBtnType	= 2, 	--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
		bBottomBtnType	= 1,
		ScrTrans = self.transform,	-- 源预设
	}
	UIManager.GoodsTooltipsWindow:SetGoodsInfo(self.m_CostGoodsID, subInfo ) 
end

return LifeSkillCookCostItem