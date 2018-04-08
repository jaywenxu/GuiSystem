--/******************************************************************
---** 文件名:	CookWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	何水大(765865368@qq.com)
--** 日  期:	2017-11-01
--** 版  本:	1.0
--** 描  述:	玩家技能窗口——生活技能——烹饪界面
--** 应  用:  
--******************************************************************/

-- Item脚本
local TypeCookGoodsItemLua= require("GuiSystem.WindowList.PlayerSkill.TypeCookGoodsItem")
-- Item预设
local TypeCookGoodsItemUI = GuiAssetList.LifeSkills.TypeCookGoodsItem

local LifeSkillNormalGoodsItem = require("GuiSystem.WindowList.PlayerSkill.LifeSkillNormalGoodsItem")

local BeginCookWidget = require("GuiSystem.WindowList.PlayerSkill.BeginCookWidget")

local COLOR_BLACK = "597993"
local COLOR_GREEN = "10A41B"
local COLOR_RED = "E4595A"

local CookWidget = UIControl:new
{
	windowName 	= "CookWidget",
	m_CookTypeItem = {},
	m_config = {},
	m_Group = nil,
	m_ArrSubscribeEvent = {},		-- 绑定的事件集合:table(string, function())
	m_CookGoods = nil, -- 烹饪物品
	m_CostGoods = nil, -- 烹饪材料
	m_bSetFirstToggle = true, -- 初始化时选择第一个物品
	m_CookGoodsID = 0, -- 被烹饪物品ID
	m_CostGoodsID = 0, -- 烹饪素材ID
	m_CostNum = 0, -- 素材数量
	m_BeginCookWidget = nil, -- 开始烹饪界面
}


function CookWidget:Attach(obj)
	
	UIControl.Attach(self,obj)

	local controls = self.Controls
	
	self.m_BeginCookWidget = BeginCookWidget:new()
	self.m_BeginCookWidget:Attach(controls.m_BeginCookWidget.gameObject)
	
	self.m_Group = controls.m_GoodsGroup:GetComponent(typeof(ToggleGroup))
	
	self.onGoToButtonClick = function() self:OnGoToButtonClick() end
	controls.m_ButtonGoTo.onClick:AddListener(self.onGoToButtonClick)
	
	self.onBuyButtonClick = function() self:OnBuyButtonClick() end
	controls.m_ButtonBuy.onClick:AddListener(self.onBuyButtonClick)
	
	self.m_CookGoods = LifeSkillNormalGoodsItem:new()
	self.m_CookGoods:Attach(controls.m_CookGoods.gameObject)
	
	self.m_CostGoods = LifeSkillNormalGoodsItem:new()
	self.m_CostGoods:Attach(controls.m_CostGoods.gameObject)
	
	self:GetCookType()
	
	self:SubscribeEvent()
	
	self:UpdateWidget()
end

-- 更新窗口
function CookWidget:UpdateWidget()
	self:CreateCookGoods()
end

function CookWidget:OnDestroy()
	self:UnSubscribeEvent()
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
end

-- 清除数据
function CookWidget:CleanData()
	local controls = self.Controls
	controls.m_ButtonGoTo.onClick:RemoveListener(self.onGoToButtonClick)
    self.onGoToButtonClick = nil
	
	controls.m_ButtonBuy.onClick:RemoveListener(self.onBuyButtonClick)
	self.onBuyButtonClick = nil
	
	UIControl.OnRecycle(self)
end

function CookWidget:GetCookType()
	local cfg = IGame.rktScheme:GetSchemeTable(LIFESKILLCOOK_CSV)
	if not cfg then
		uerror("生活技能：LifeSkillCook.csv 不存在！")
	end
	local newTab = {}
	for _, v in pairs (cfg) do
		newTab[v.Type] = v.Type
	end
	
	table.sort(newTab)
	self.m_config = newTab
end

-- 创建烹饪类型Item
function CookWidget:CreateCookTypeItem(parentTf, cellList, type)
	rkt.GResources.FetchGameObjectAsync(TypeCookGoodsItemUI, 
   	function( path , obj , ud )
		if nil ~= obj then
			obj.transform:SetParent(parentTf, false)
		
			local cell = TypeCookGoodsItemLua:new({})
			cell:SetGroup(self.m_Group)
			cell:Attach(obj)
			cell:SetData(type, self.m_bSetFirstToggle)
			self.m_bSetFirstToggle = false
			cellList[type] = cell
		end
	end, nil, AssetLoadPriority.GuiNormal )
end

-- 创建烹饪物品
function CookWidget:CreateCookGoods()
	for _, type in pairs (self.m_config) do
		local item = self.m_CookTypeItem[type]
		if not item then
			self:CreateCookTypeItem(self.Controls.m_CookGoodsList, self.m_CookTypeItem, type)
		else
			item:SetData(type, self.m_bSetFirstToggle)
		end
	end
end

-- 点击烹饪物品事件
function CookWidget:HandleUI_LifeSkillCookItemClick(goodsId)
	local goodsCfg = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodsId)
	local cookCfg = IGame.rktScheme:GetSchemeInfo(LIFESKILLCOOK_CSV, goodsId)
	if not goodsCfg or not cookCfg then
		uerror("LifeSkillCook.csv或Leechdom.csv配置错误！没有物品ID：" .. goodsId)
		return
	end
	
	local tempBills = stringToTable(cookCfg.CostGoods)
	if table_count(tempBills) == 0 then
		uerror("LifeSkillCook.csv 菜单配置错误！烹饪物品ID：" .. goodsId)
		return
	end
	
	table.sort(tempBills)
	for k, v in pairs(tempBills) do
		self.m_CostGoodsID = k
		self.m_CostNum = v
		break
	end
	
	local costCfg = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, self.m_CostGoodsID)
	if not costCfg then
		uerror("Leechdom.csv 配置错误！物品不存在，ID：" .. self.m_CostGoodsID)
		return
	end
	
	self.m_CookGoodsID = goodsId
	
	
	self.m_CookGoods:UpdateItem(goodsId)
	self.m_CostGoods:UpdateItem(self.m_CostGoodsID)
	
	local controls = self.Controls
	
	local heroLevel = 0
	local hero = GetHero() 
    if hero then 
        heroLevel = hero:GetNumProp(CREATURE_PROP_LEVEL)
    end

	if heroLevel < goodsCfg.lAllowLevel then
		controls.m_TextUseLevel.color = UIFunction.ConverRichColorToColor(COLOR_RED)
	else
		controls.m_TextUseLevel.color = UIFunction.ConverRichColorToColor(COLOR_GREEN)
	end
	-- 使用等级
	controls.m_TextUseLevel.text = "使用等级: " .. goodsCfg.lAllowLevel .."级"
	
	-- 物品描述
	controls.m_TextDesc.text = string_unescape_newline(goodsCfg.szDesc)
	
	-- 素材名字
	local costColor = DColorDef.getNameColor(0, costCfg.lBaseLevel)
	controls.m_TextCostName.text = string.format("<color=#%s>" .. costCfg.szName .. "</color>", costColor)
	
	-- 设置素材数量
	self:SetCostNum()
	
	-- 烹饪物品名字
	local cookColor = DColorDef.getNameColor(0, goodsCfg.lBaseLevel)
	controls.m_TextName.text = string.format("<color=#%s>" .. goodsCfg.szName .. "</color>", cookColor)
end

-- 事件绑定
function CookWidget:SubscribeEvent()
	self.m_ArrSubscribeEvent = 
	{
		{
			e = MSG_MODULEID_LIFESKILL, s = SOURCE_TYPE_SYSTEM, i = SKILL_UI_EVENT_LIFESKILL_COOKITEM_CLICK,
			f = function(event, srctype, srcid, goodsId) self:HandleUI_LifeSkillCookItemClick(goodsId) end,
		},
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
function CookWidget:UnSubscribeEvent()
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.UnSubscribeExecute(v.e, v.s, v.i, v.f)
	end
	
end

-- 烹饪按钮的点击行为
function CookWidget:OnGoToButtonClick()
	
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end
	
	-- 战斗状态判断
	local pPKModePart = pHero:GetEntityPart(ENTITYPART_PERSON_PKMODE)
	if not pPKModePart then
		return
	end
	
	if pPKModePart:GetPKState() == EPK_Person_Battle then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "战斗状态下无法进行生产")
		return
	end
	
	-- 死亡状态
	if pHero:IsDead() then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "死亡状态下无法进行生产")
		return
	end
	
	local haveNum = pHero:GetEntityPart(ENTITYPART_PERSON_PACKET):GetGoodNum(self.m_CostGoodsID)
	if haveNum < self.m_CostNum then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "原材料不足")
		return
	end
	
	self.m_BeginCookWidget:ShowUI(self.m_CookGoodsID, self.m_CostGoodsID)
end

function CookWidget:OnBuyButtonClick()
	local subInfo = {
		bShowBtnType	= 2, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
		ScrTrans = self.Controls.m_NodeTips.transform,	-- 源预设
	}
    UIManager.GoodsTooltipsWindow:SetGoodsInfo(self.m_CostGoodsID, subInfo )
end

-- 设置素材数量
function CookWidget:SetCostNum()
	local controls = self.Controls
	local costNmum = self.m_CostNum
	local haveNum = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET):GetGoodNum(self.m_CostGoodsID)
	if haveNum < costNmum then
		controls.m_TextCostNum.text = string.format("<color=#%s>%d</color>/%d", COLOR_RED, haveNum, costNmum)
		controls.m_ButtonBuy.gameObject:SetActive(true)
	else
		controls.m_TextCostNum.text = string.format("<color=#%s>%d</color>/%d", COLOR_BLACK, haveNum, costNmum)
		controls.m_ButtonBuy.gameObject:SetActive(false)
	end
end

function CookWidget:OnEnable()
	self:SubscribeEvent()
end

function CookWidget:OnDisable()
	self:UnSubscribeEvent()
end

return CookWidget