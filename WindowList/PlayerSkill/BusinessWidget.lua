--/******************************************************************
---** 文件名:	BusinessWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	何水大(765865368@qq.com)
--** 日  期:	2017-11-01
--** 版  本:	1.0
--** 描  述:	玩家技能窗口——生活技能——经商界面
--** 应  用:  
--******************************************************************/

local BusinessWidget = UIControl:new
{
	windowName 	= "BusinessWidget",
	m_curLevel = 0, -- 当前技能等级
}


function BusinessWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	local controls = self.Controls
	self.onUpgradeButtonClick = function() self:OnUpgradeButtonClick() end
	self.onAddYinBiButtonClick = function() self:OnAddYinBiButtonClick() end
	controls.m_ButtonUpgrade.onClick:AddListener(self.onUpgradeButtonClick)
	controls.m_ButtonAddYinBi.onClick:AddListener(self.onAddYinBiButtonClick)
	
	self.onAddBangGongButtonClick = function() self:OnAddBangGongButtonClick() end
	controls.m_ButtonAddBangGong.onClick:AddListener(self.onAddBangGongButtonClick)

	self:SubscribeEvent()
	self:UpdateWidget()
end

-- 更新窗口
function BusinessWidget:UpdateWidget()
	local hero = GetHero() 
    if not hero then 
        return 
    end
    
	local skillPart = hero:GetEntityPart(ENTITYPART_PERSON_LIFESKILL)
    if not skillPart then
        return
    end
	local skillLevel = skillPart:GetLifeSkillLevel(emBusiness)
	
	local curCfg = IGame.rktScheme:GetSchemeInfo(LIFESKILLS_CSV, emBusiness, skillLevel)
	if not curCfg then
		return
	end
	
	local controls = self.Controls
	
	self.m_curLevel = skillLevel
	controls.m_TextLevelM.text = "当前等级: " .. skillLevel .. "级"
	
	local nextLevel = skillLevel + 1
	local nextCfg = IGame.rktScheme:GetSchemeInfo(LIFESKILLS_CSV, emBusiness, nextLevel)
	
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
		
		-- 技能等级描述
		controls.m_TextNextLevelGet.text = "下一等级：" .. nextCfg.LevelDesc
		
	else -- 技能已满级
		controls.m_CanUpgrade.gameObject:SetActive(false)
		controls.m_CannotUpgrade.gameObject:SetActive(true)
		
		-- 技能描述
		controls.m_TextDesc.text = curCfg.Desc
		-- 技能等级描述
		controls.m_TextNextLevelGet.text = ""
	end
	
	-- 技能等级描述
	controls.m_TextCurrentLevelGet.text = "当前效果：" .. curCfg.LevelDesc
end

function BusinessWidget:OnDestroy()
	self:UnSubscribeEvent()
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function BusinessWidget:CleanData()
	local controls = self.Controls
	controls.m_ButtonUpgrade.onClick:RemoveListener(self.onUpgradeButtonClick)
	controls.m_ButtonAddYinBi.onClick:RemoveListener(self.onAddYinBiButtonClick)

	self.onUpgradeButtonClick = nil
	self.onAddYinBiButtonClick = nil
	
	controls.m_ButtonAddBangGong.onClick:RemoveListener(self.onAddBangGongButtonClick)
	self.onAddBangGongButtonClick = nil
end

-- 添加按钮的点击行为
function BusinessWidget:OnAddBangGongButtonClick()
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
function BusinessWidget:OnAddYinBiButtonClick()
	
	UIManager.ShopWindow:OpenShop(2415)
	
end

-- 升级按钮的点击行为
function BusinessWidget:OnUpgradeButtonClick()
	IGame.LifeSkillClient:CheckLifeSkillAndUpgrade(emBusiness, self.m_curLevel)
end

-- 事件绑定
function BusinessWidget:SubscribeEvent()
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
	}
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.SubscribeExecute(v.e, v.s, v.i, v.f)
	end
end

-- 移除事件的绑定
function BusinessWidget:UnSubscribeEvent()
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.UnSubscribeExecute(v.e, v.s, v.i, v.f)
	end
	
end

-- 更新银币
function BusinessWidget:UpdateYinBi()
	local nextLevel = self.m_curLevel + 1
	local nextCfg = IGame.rktScheme:GetSchemeInfo(LIFESKILLS_CSV, emBusiness, nextLevel)
	
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
		controls.m_TextCostYinBi.text = GameHelp:GetMoneyText(costYinBi)
		UIFunction.SetImageSprite(controls.m_IconCost, currencyIconPath)
		UIFunction.SetImageSprite(controls.m_IconHave, currencyIconPath)
	end
end

-- 更新帮贡
function BusinessWidget:RefreshRecordData(eventData)
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

return BusinessWidget