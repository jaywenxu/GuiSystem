--/******************************************************************
---** 文件名:	FishingWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	何水大(765865368@qq.com)
--** 日  期:	2017-11-01
--** 版  本:	1.0
--** 描  述:	玩家技能窗口——生活技能——钓鱼界面
--** 应  用:  
--******************************************************************/

local LifeSkillNormalGoodsItem = require("GuiSystem.WindowList.PlayerSkill.LifeSkillNormalGoodsItem")

local FishingWidget = UIControl:new
{
	windowName 	= "FishingWidget",
	m_curLevel = 0, -- 当前技能等级
	m_goodsItem = {},
	m_ArrSubscribeEvent = {},
}


function FishingWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	local controls = self.Controls
	self.onUpgradeButtonClick = function() self:OnUpgradeButtonClick() end
	self.onAddYinBiButtonClick = function() self:OnAddYinBiButtonClick() end
	self.onGoToButtonClick = function() self:OnGoToButtonClick() end
	controls.m_ButtonUpgrade.onClick:AddListener(self.onUpgradeButtonClick)
	controls.m_ButtonAddYinBi.onClick:AddListener(self.onAddYinBiButtonClick)
	controls.m_ButtonGoTo.onClick:AddListener(self.onGoToButtonClick)
	
	self.onAddBangGongButtonClick = function() self:OnAddBangGongButtonClick() end
	controls.m_ButtonAddBangGong.onClick:AddListener(self.onAddBangGongButtonClick)
	
	for i = 1, 3 do 
		self.m_goodsItem[i] = LifeSkillNormalGoodsItem:new()
		self.m_goodsItem[i]:Attach(controls["m_Goods" .. i].gameObject)
	end
	
	self:SubscribeEvent()
	self:UpdateWidget()
end

-- 更新窗口
function FishingWidget:UpdateWidget()
	local hero = GetHero() 
    if not hero then 
        return 
    end
    
	local skillPart = hero:GetEntityPart(ENTITYPART_PERSON_LIFESKILL)
    if not skillPart then
        return
    end		
	local skillLevel = skillPart:GetLifeSkillLevel(emFishing)
	
	local curCfg = IGame.rktScheme:GetSchemeInfo(LIFESKILLS_CSV, emFishing, skillLevel)
	if not curCfg then
		return
	end
	
	local controls = self.Controls

	self.m_curLevel = skillLevel
	controls.m_TextLevelM.text = "当前等级: " .. skillLevel .. "级"
	controls.m_TextLevelR.text = skillLevel
	
	local nextLevel = skillLevel + 1
	local nextCfg = IGame.rktScheme:GetSchemeInfo(LIFESKILLS_CSV, emFishing, nextLevel)
	
	-- 技能未满级
	if nextCfg then
		controls.m_CanUpgrade.gameObject:SetActive(true)
		controls.m_CannotUpgrade.gameObject:SetActive(false)
		
		local haveYinBi = hero:GetCurrency(emCoinClientType_YinBi)
		local costYinBi = nextCfg.NeedSilver
		local haveYinLiang = hero:GetCurrency(emCoinClientType_YinLiang)
		local haveCurrency = haveYinBi
		-- 货币图标处理
		local currencyIconPath =AssetPath_CurrencyIcon[3]
		if haveYinBi < 1 then
			currencyIconPath = AssetPath_CurrencyIcon[2]
			haveCurrency = haveYinLiang
		end
	
		if haveCurrency < costYinBi then
			controls.m_TextCostYinBi.color = UIFunction.ConverRichColorToColor("e4595a")
		else
			controls.m_TextCostYinBi.color = UIFunction.ConverRichColorToColor("ffffff")
		end
		controls.m_TextHaveYinBi.text = GameHelp:GetMoneyText(haveCurrency)
		controls.m_TextCostYinBi.text = GameHelp:GetMoneyText(costYinBi)
		UIFunction.SetImageSprite(controls.m_IconCost, currencyIconPath)
		UIFunction.SetImageSprite(controls.m_IconHave, currencyIconPath)
		
		-- 帮贡
		local haveClanContribute = hero:GetClanContribute()
		local costClanContribute = nextCfg.NeedClanContribution
		if haveClanContribute >= costClanContribute then
			controls.m_ButtonAddBangGong.gameObject:SetActive(false)
			controls.m_TextHaveBangGong.color = UIFunction.ConverRichColorToColor("ffffff")
		else
			controls.m_ButtonAddBangGong.gameObject:SetActive(true)
			controls.m_TextHaveBangGong.color = UIFunction.ConverRichColorToColor("e4595a")
		end
		controls.m_TextHaveBangGong.text = haveClanContribute
		controls.m_TextCostBangGong.text = costClanContribute
		
		-- 技能描述
		controls.m_TextDesc.text = nextCfg.Desc
	
	else -- 技能已满级
		controls.m_CanUpgrade.gameObject:SetActive(false)
		controls.m_CannotUpgrade.gameObject:SetActive(true)
		
		-- 技能描述
		controls.m_TextDesc.text = curCfg.Desc
	end
	
	-- 活力值
	local haveVim = hero:GetNumProp(CREATURE_PROP_VIM)
	controls.m_TextHaveVim.text = haveVim
	
	-- 技能等级描述
	controls.m_TextNextLevelGet.text = string_unescape_newline(curCfg.LevelDesc)
	
	-- 显示可获得的物品
	local cfg = IGame.rktScheme:GetSchemeInfo(LIFESKILLFISHING_CSV, skillLevel)
	if not cfg then
		uerror("钓鱼配置文件不存在！")
		return
	end
	
	-- 消耗活力
	controls.m_TextCostVim.text = cfg.CostVim
	
	local showGoodsFunc = function(parmCfg)
		for i = 1, 3 do
			local goodsID = parmCfg["Goods" .. i]
			if 0 ~= goodsID then
				self.m_goodsItem[i]:UpdateItem(goodsID)
				self.m_goodsItem[i]:Show()
			else
				self.m_goodsItem[i]:Hide()
			end
		end
	end
	
	-- 概率和为100表示有奖励，否则取后面技能等级的奖励
	if cfg.Rate1 + cfg.Rate2 + cfg.Rate3 == 100 then
		controls.m_TextGetTips.text = "当前可钓"
		showGoodsFunc(cfg)
	else
		local tempCfg = IGame.rktScheme:GetSchemeTable(LIFESKILLFISHING_CSV)
		local allCfg = {}
		for k, v in pairs(tempCfg) do
			allCfg[v.Level] = v
		end

		for k, v in pairs(allCfg) do
			if v.Level > skillLevel then
				if v.Rate1 + v.Rate2 + v.Rate3 == 100 then
					controls.m_TextGetTips.text = string.format("<color=#E4595A>%d级可钓</color>", v.Level)
					showGoodsFunc(v)
					break
				end
			end
		end
	end
end

function FishingWidget:OnDestroy()
	self:UnSubscribeEvent()
	-- 清除数据
	self:CleanData()
	self:UnSubscribeEvent()
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function FishingWidget:CleanData()
	local controls = self.Controls
	controls.m_ButtonUpgrade.onClick:RemoveListener(self.onUpgradeButtonClick)
	controls.m_ButtonAddYinBi.onClick:RemoveListener(self.onAddYinBiButtonClick)
	controls.m_ButtonGoTo.onClick:RemoveListener(self.onGoToButtonClick)
	self.onUpgradeButtonClick = nil
	self.onAddYinBiButtonClick = nil
    self.onGoToButtonClick = nil
	
	controls.m_ButtonAddBangGong.onClick:RemoveListener(self.onAddBangGongButtonClick)
	self.onAddBangGongButtonClick = nil
end

-- 添加按钮的点击行为
function FishingWidget:OnAddBangGongButtonClick()
	local hero = GetHero()
	if not hero then
		return
	end
	
	local packetPart = hero:GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	
	local banggongID = 9005
	
	local subInfo = 
	{
		bShowBtnType	= 2, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
		ScrTrans = self.Controls.m_NodeTips.transform,	-- 源预设
	}
	
	UIManager.GoodsTooltipsWindow:SetGoodsInfo(banggongID, subInfo)

end

-- 添加按钮的点击行为
function FishingWidget:OnAddYinBiButtonClick()
	UIManager.ShopWindow:OpenShop(2415)
end


-- 升级按钮的点击行为
function FishingWidget:OnUpgradeButtonClick()
	IGame.LifeSkillClient:CheckLifeSkillAndUpgrade(emFishing, self.m_curLevel)
end

-- 前往钓鱼的点击行为
function FishingWidget:OnGoToButtonClick()
	IGame.LifeSkillClient:GotoFish()
end

-- 事件绑定
function FishingWidget:SubscribeEvent()
	self.m_ArrSubscribeEvent = 
	{
		{
			e = EVENT_CION_YINBI, s = SOURCE_TYPE_COIN, i = 0,
			f = function(event, srctype, srcid) self:UpdateYinBi() end,
		},
		{
			e = EVENT_CION_YINLIANG, s = SOURCE_TYPE_COIN, i = 0,
			f = function(event, srctype, srcid) self:UpdateYinBi() end,
		},
		{
			e = EVENT_SYNC_PERSON_RECORD_DATA, s = SOURCE_TYPE_PERSON, i = 0,
			f = function(event, srctype, srcid, eventData) self:RefreshRecordData(eventData) end,
		},
		{
			e = EVENT_ENTITY_UPDATEPROP, s = SOURCE_TYPE_PERSON, i = tEntity_Class_Person,
			f = function(event, srctype, srcid, eventData) self:OnUpdateProp(eventData) end,
		},
	}
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.SubscribeExecute(v.e, v.s, v.i, v.f)
	end
end

-- 移除事件的绑定
function FishingWidget:UnSubscribeEvent()
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.UnSubscribeExecute(v.e, v.s, v.i, v.f)
	end
	
end

-- 更新银币
function FishingWidget:UpdateYinBi()
	local nextLevel = self.m_curLevel + 1
	local nextCfg = IGame.rktScheme:GetSchemeInfo(LIFESKILLS_CSV, emFishing, nextLevel)
	
	-- 技能未满级
	if nextCfg then
		local hero = GetHero()
		if not hero then
			return
		end
		local controls = self.Controls
		
		local haveYinBi = hero:GetCurrency(emCoinClientType_YinBi)
		local costYinBi = nextCfg.NeedSilver
		local haveYinLiang = hero:GetCurrency(emCoinClientType_YinLiang)
		local haveCurrency = haveYinBi
		-- 货币图标处理
		local currencyIconPath =AssetPath_CurrencyIcon[3]
		if haveYinBi < 1 then
			currencyIconPath = AssetPath_CurrencyIcon[2]
			haveCurrency = haveYinLiang
		end
	
		if haveCurrency < costYinBi then
			controls.m_TextCostYinBi.color = UIFunction.ConverRichColorToColor("e4595a")
		else
			controls.m_TextCostYinBi.color = UIFunction.ConverRichColorToColor("ffffff")
		end
		controls.m_TextHaveYinBi.text = GameHelp:GetMoneyText(haveCurrency)
		UIFunction.SetImageSprite(controls.m_IconCost, currencyIconPath)
		UIFunction.SetImageSprite(controls.m_IconHave, currencyIconPath)
	end
end

-- 更新帮贡
function FishingWidget:RefreshRecordData(eventData)
	if ERecordSubID_ClanContribute == eventData.nRecordSubID then
		local nextLevel = self.m_curLevel + 1
		local nextCfg = IGame.rktScheme:GetSchemeInfo(LIFESKILLS_CSV, emLuck, nextLevel)
	
		-- 技能未满级
		if nextCfg then
			local hero = GetHero()
			if not hero then
				return
			end
			
			local controls = self.Controls
			-- 帮贡
			local haveClanContribute = hero:GetClanContribute()
			local costClanContribute = nextCfg.NeedClanContribution
			if haveClanContribute >= costClanContribute then
				controls.m_ButtonAddBangGong.gameObject:SetActive(false)
			else
				controls.m_ButtonAddBangGong.gameObject:SetActive(true)
			end
			if haveClanContribute < costClanContribute then
				controls.m_TextCostBangGong.color = UIFunction.ConverRichColorToColor("e4595a")
			else
				controls.m_TextCostBangGong.color = UIFunction.ConverRichColorToColor("ffffff")
			end
			controls.m_TextHaveBangGong.text = haveClanContribute
		end
	end
end

-- 更新活力
function FishingWidget:OnUpdateProp(eventData)
	if not self:isLoaded() then
		return
	end
	
	if not eventData or type(eventData) ~= "table" or not eventData.nPropCount or eventData.nPropCount == 0  then
		return
	end
	for i = 1, eventData.nPropCount do
		if eventData.propData[i].nPropID == CREATURE_PROP_VIM then
			local haveVim = GetHero():GetNumProp(CREATURE_PROP_VIM)
			self.Controls.m_TextHaveVim.text = haveVim
		end
	end
end

return FishingWidget