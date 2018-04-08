--/******************************************************************
---** 文件名:	TameWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	何水大(765865368@qq.com)
--** 日  期:	2017-11-01
--** 版  本:	1.0
--** 描  述:	玩家技能窗口——生活技能——驯马界面
--** 应  用:  
--******************************************************************/

local RideGoodsItem = require("GuiSystem.WindowList.PlayerSkill.RideGoodsItem")

local TameWidget = UIControl:new
{
	windowName 	= "MiningWidget",
	m_curLevel = 0, -- 当前技能等级
	m_goodsItem = {},
	m_firsShow = true,
	m_RideID = 0,
	m_lock = true,
}


function TameWidget:Attach(obj)
	
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
	
	self.m_Group = controls.m_GoodsGroup:GetComponent(typeof(ToggleGroup))
	
	for i = 1, 5 do 
		self.m_goodsItem[i] = RideGoodsItem:new()	
		self.m_goodsItem[i]:SetGroup(self.m_Group)
		self.m_goodsItem[i]:Attach(controls["m_Goods" .. i].gameObject)
	end
	
	self:SubscribeEvent()
	
	self:UpdateWidget()
end

-- 更新窗口
function TameWidget:UpdateWidget()
	local hero = GetHero() 
    if not hero then 
        return 
    end
    
	local skillPart = hero:GetEntityPart(ENTITYPART_PERSON_LIFESKILL)
    if not skillPart then
        return
    end
	local skillLevel = skillPart:GetLifeSkillLevel(emTame)
	
	local curCfg = IGame.rktScheme:GetSchemeInfo(LIFESKILLS_CSV, emTame, skillLevel)
	if not curCfg then
		return
	end
	
	local controls = self.Controls
	
	self.m_curLevel = skillLevel
	controls.m_TextLevelM.text = "当前等级: " .. skillLevel .. "级"
	controls.m_TextLevelR.text = skillLevel
	
	local nextLevel = skillLevel + 1
	local nextCfg = IGame.rktScheme:GetSchemeInfo(LIFESKILLS_CSV, emTame, nextLevel)
	
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
		controls.m_TextNextLevelGet.text = "下级: " .. string_unescape_newline(nextCfg.LevelDesc)
		
	else -- 技能已满级
		controls.m_CanUpgrade.gameObject:SetActive(false)
		controls.m_CannotUpgrade.gameObject:SetActive(true)
		
		-- 技能描述
		controls.m_TextDesc.text = curCfg.Desc
		
		-- 技能等级描述
		controls.m_TextNextLevelGet.text = ""
	end
	
	-- 技能等级描述
	controls.m_TextCurrentLevelGet.text = "当前: " .. string_unescape_newline(curCfg.LevelDesc)
	
	-- 显示可获得的物品
	local tempConfig = IGame.rktScheme:GetSchemeTable(LIFESKILLTAME_CSV)
	local config = {}
	for k, v in pairs(tempConfig) do
		table.insert(config, v)
	end

	table.sort(config, function (a, b) return a.ID < b.ID end)
	local count = 0
	for _, oneCfg in pairs(config) do
		count = count + 1
		if skillLevel >= oneCfg.Level or IGame.RideClient:IsHaveTheRide(oneCfg.ID) then
			self.m_goodsItem[count]:UpdateItem(oneCfg.ID, false)
		else
			self.m_goodsItem[count]:UpdateItem(oneCfg.ID, true)
		end
		
		if self.m_firsShow then
			self.m_goodsItem[count]:SetFocus(true, true)
			self.m_firsShow = false
		end
		
		self.m_goodsItem[count]:Show()
	end
end

function TameWidget:OnDestroy()
	self:UnSubscribeEvent()
	-- 清除数据
	self:CleanData()
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function TameWidget:CleanData()
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
function TameWidget:OnAddBangGongButtonClick()
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
function TameWidget:OnAddYinBiButtonClick()
	
	UIManager.ShopWindow:OpenShop(2415)
	
end

-- 升级按钮的点击行为
function TameWidget:OnUpgradeButtonClick()
	IGame.LifeSkillClient:CheckLifeSkillAndUpgrade(emTame, self.m_curLevel)
end

-- 前往驯马的点击行为
function TameWidget:OnGoToButtonClick()
	if IGame.LifeSkillClient:GoToTame(self.m_RideID) then
		UIManager.PlayerSkillWindow:Hide()
	end
end

-- 事件绑定
function TameWidget:SubscribeEvent()
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
			e = MSG_MODULEID_LIFESKILL, s = SOURCE_TYPE_SYSTEM, i = SKILL_UI_EVENT_LIFESKILL_RIDESELECT,
			f = function(event, srctype, srcid, eventData) self:OnRideSelect(eventData) end,
		},
	}
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.SubscribeExecute(v.e, v.s, v.i, v.f)
	end
end

-- 移除事件的绑定
function TameWidget:UnSubscribeEvent()
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.UnSubscribeExecute(v.e, v.s, v.i, v.f)
	end
	
end

-- 更新银币
function TameWidget:UpdateYinBi()
	local nextLevel = self.m_curLevel + 1
	local nextCfg = IGame.rktScheme:GetSchemeInfo(LIFESKILLS_CSV, emTame, nextLevel)
	
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
function TameWidget:RefreshRecordData(eventData)
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

-- 坐骑选中事件
function TameWidget:OnRideSelect(eventData)
	self.m_RideID = eventData.rideID
end

return TameWidget