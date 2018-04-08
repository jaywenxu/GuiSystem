--/******************************************************************
---** 文件名:	UpgradeSkillInfoWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-05
--** 版  本:	1.0
--** 描  述:	玩家技能窗口-技能升级信息窗口
--** 应  用:  
--******************************************************************/

local UpgradeSkillInfoWidget = UIControl:new
{
	windowName 	= "UpgradeSkillInfoWidget",
	
	m_TheSelectedSkillId = 0,			-- 当前选中的技能ID:number
	m_UpgradeSkillMatItem = nil,		-- 升级材料图标对应的脚本:UpgradeSkillMatItem
}

function UpgradeSkillInfoWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	
	self.onLearnButtonClick = function() self:OnLearnButtonClick() end
	self.onUpgradeButtonClick = function() self:OnUpgradeButtonClick() end
	self.onAddButtonClick = function() self:OnAddButtonClick() end
	self.Controls.m_ButtonLearn.onClick:AddListener(self.onLearnButtonClick)
	self.Controls.m_ButtonUpgrade.onClick:AddListener(self.onUpgradeButtonClick)
	self.Controls.m_ButtonAdd.onClick:AddListener(self.onAddButtonClick)

	self.m_UpgradeSkillMatItem = require("GuiSystem.WindowList.PlayerSkill.UpgradeSkillMatItem")
	self.m_UpgradeSkillMatItem:Attach(self.Controls.m_TfUpgradeSkillMatItem.gameObject)
	
end

-- 显示窗口
function UpgradeSkillInfoWidget:ShowWindow()
	
	UIControl.Show(self)
	--self.transform.gameObject:SetActive(true)
	
end

-- 更新窗口
-- @SkillId:技能id number
function UpgradeSkillInfoWidget:UpdateWindow(skillId)
	
	self.m_TheSelectedSkillId = skillId
	
	local hero = GetHero()
	if not hero then
		return
	end
	
	local skillPart = hero:GetEntityPart(ENTITYPART_CREATURE_SKILL)
	if not skillPart then
		return
	end
	
	local heroLevel = hero:GetNumProp(CREATURE_PROP_LEVEL)
	local skillTotalLv = skillPart:GetTotalSkillLevel(skillId)
    local skillOriginalLv = skillPart:GetOriginalSkillLevel(skillId)
	if skillTotalLv < 1 then
		self:UpdateForNotLearnSkill(heroLevel)
	else 
		self:UpdateForHadLearnSkill(skillTotalLv, skillOriginalLv, heroLevel)
	end
	
	self.Controls.m_ButtonUpgrade.gameObject:SetActive(skillTotalLv > 0)
	self.Controls.m_ButtonLearn.gameObject:SetActive(skillTotalLv < 1)
	
end

-- 未学习的技能的显示处理
-- @heroLevel:玩家等级:number
function UpgradeSkillInfoWidget:UpdateForNotLearnSkill(heroLevel)
	
	local skillScheme = IGame.rktScheme:GetSchemeInfo(SKILL_CSV, self.m_TheSelectedSkillId, 1, 1)
	local skillUpdateScheme = IGame.rktScheme:GetSchemeInfo(SKILLUPDATE_CSV, self.m_TheSelectedSkillId, 1)
	if not skillUpdateScheme or not skillScheme then
		return 
	end
	
	-- 冷却时间计算
	local freezeScheme = IGame.rktScheme:GetSchemeInfo(FREEZE_CSV, EFreeze_ClassID_Skill, skillScheme.CoolDown)
	local coolTime = 0
	if(freezeScheme) then
		coolTime = freezeScheme.Time / 1000
	end
	
	self.Controls.m_TfCurLvSkillEffNode.gameObject:SetActive(false)
	self.Controls.m_TfNextLvSkillEffNode.localPosition = Vector3.New(0, 205, 0)
	
	-- 需要等级
	if heroLevel >= skillUpdateScheme.NeedLevel then
		self.Controls.m_TextNextSkillCondition.text = string.format("<color=#FF7800FF>需要角色等级：%d</color>", skillUpdateScheme.NeedLevel) --  UIFunction.ConverRichColorToColor("01519c")
	else
		self.Controls.m_TextNextSkillCondition.text = string.format("<color=#E4595AFF>需要角色等级：%d</color>", skillUpdateScheme.NeedLevel)
	end
	
	self.Controls.m_TextSkillLevel.text = string.format("<color=#FD0505FF>未学会</color>")
	self.Controls.m_TextSkillName.text = skillUpdateScheme.Name
	self.Controls.m_TextSkillDesc.text = skillUpdateScheme.CommonDesc
	if skillUpdateScheme.IsShowColdTime == true then
		self.Controls.m_TextCoolTime.text = string.format("冷却时间：<color=#FF7800FF>%.1fs</color>", coolTime)
		self.Controls.m_TextCoolTime.gameObject:SetActive(true)
	else
		self.Controls.m_TextCoolTime.gameObject:SetActive(false)
	end

	if skillUpdateScheme.IsShowSkillDistance ==true then 
		self.Controls.m_TextCastDistance.text = string.format("施展距离：<color=#FF7800FF>%.1fm</color>", skillScheme.AttackDistance)
		self.Controls.m_TextCastDistance.gameObject:SetActive(true)
	else
		self.Controls.m_TextCastDistance.gameObject:SetActive(false)
	end

	self.Controls.m_TextNextSkillEff.text = skillUpdateScheme.LevelDesc 
	
	if skillUpdateScheme.AutoLearn == true then -- 自动学会
		self:UpdageForAutoLearn(skillUpdateScheme)
	else -- 需要消耗学习
		self:UpdateSkillCostShow(skillUpdateScheme)
	end

end

-- 自动学习的显示
-- @skillUpdateScheme:技能升级配置:SkillUpdate
function UpgradeSkillInfoWidget:UpdageForAutoLearn(skillUpdateScheme)
	
	self.Controls.m_TfMaxLevelNode.gameObject:SetActive(false)
	self.Controls.m_TfCostUpgradeNode.gameObject:SetActive(false)	
	self.Controls.m_TfLevelUpgradeNode.gameObject:SetActive(true)
	self.Controls.m_TextAutoLearnLevel.text = string.format("角色等级%d级学会", skillUpdateScheme.NeedLevel)
	
end

-- 已学习的技能的显示处理
-- @skillLv:当前技能等级:number
-- @heroLevel:玩家等级:number
function UpgradeSkillInfoWidget:UpdateForHadLearnSkill(skillTotalLv, skillOriginalLv, heroLevel)
	self.Controls.m_TfLevelUpgradeNode.gameObject:SetActive(false)
	local skillScheme = IGame.rktScheme:GetSchemeInfo(SKILL_CSV, self.m_TheSelectedSkillId, skillTotalLv, 1)
    if not skillScheme then
        uerror("UpgradeSkillInfoWidget:UpdateForHadLearnSkill could not find skill config, id = "..self.m_TheSelectedSkillId..", level = "..skillTotalLv)
        return
    end
    
	local skillUpdateScheme = IGame.rktScheme:GetSchemeInfo(SKILLUPDATE_CSV, self.m_TheSelectedSkillId, skillTotalLv)
	if not skillUpdateScheme then
        uerror("UpgradeSkillInfoWidget:UpdateForHadLearnSkill could not find skill update config, id = "..self.m_TheSelectedSkillId..", level = "..skillTotalLv)
		return
	end

	-- 冷却时间计算
	local freezeScheme = IGame.rktScheme:GetSchemeInfo(FREEZE_CSV, EFreeze_ClassID_Skill, skillScheme.CoolDown)
	local coolTime = 0
	if(freezeScheme) then
		coolTime = freezeScheme.Time / 1000
	end
	
	self.Controls.m_TfCurLvSkillEffNode.gameObject:SetActive(true)
	self.Controls.m_TfNextLvSkillEffNode.localPosition = Vector3.New(0, 60, 0)
	
	self.Controls.m_TextSkillLevel.text = string.format("%d级", skillTotalLv)
	self.Controls.m_TextSkillName.text = skillUpdateScheme.Name
	self.Controls.m_TextSkillDesc.text = skillUpdateScheme.CommonDesc
	if skillUpdateScheme.IsShowColdTime == true then
		self.Controls.m_TextCoolTime.text = string.format("冷却时间：<color=#FF7800FF>%.1fs</color>", coolTime)
		self.Controls.m_TextCoolTime.gameObject:SetActive(true)
	else
		self.Controls.m_TextCoolTime.gameObject:SetActive(false)
	end

	if skillUpdateScheme.IsShowSkillDistance == true then 
		self.Controls.m_TextCastDistance.text = string.format("施展距离：<color=#FF7800FF>%.1fm</color>", skillScheme.AttackDistance)
		self.Controls.m_TextCastDistance.gameObject:SetActive(true)
	else
		self.Controls.m_TextCastDistance.gameObject:SetActive(false)
	end
	self.Controls.m_TextCurSkillEff.text = skillUpdateScheme.LevelDesc 
	
	local skillTotalNextUpdateScheme = IGame.rktScheme:GetSchemeInfo(SKILLUPDATE_CSV, self.m_TheSelectedSkillId, skillTotalLv + 1)
    local skillOriginalNextUpdateScheme = IGame.rktScheme:GetSchemeInfo(SKILLUPDATE_CSV, self.m_TheSelectedSkillId, skillOriginalLv + 1)

	-- 技能满级
	if not skillOriginalNextUpdateScheme or not skillTotalNextUpdateScheme or skillOriginalLv >= skillUpdateScheme.OriginalMaxLevel then 
		self.Controls.m_TfNextLvSkillEffNode.gameObject:SetActive(false)
		self.Controls.m_TfMaxLevelNode.gameObject:SetActive(true)
		self.Controls.m_TfCostUpgradeNode.gameObject:SetActive(false)
		
		return
	end
	
	-- 需要等级
	if heroLevel >= skillOriginalNextUpdateScheme.NeedLevel then
		self.Controls.m_TextNextSkillCondition.text = string.format("<color=#FF7800FF>需要角色等级：%d</color>", skillOriginalNextUpdateScheme.NeedLevel) --  UIFunction.ConverRichColorToColor("01519c")
	else
		self.Controls.m_TextNextSkillCondition.text = string.format("<color=#E4595AFF>需要角色等级：%d</color>", skillOriginalNextUpdateScheme.NeedLevel)
	end
	
	self.Controls.m_TfNextLvSkillEffNode.gameObject:SetActive(true)
	self.Controls.m_TfMaxLevelNode.gameObject:SetActive(false)
	self.Controls.m_TfCostUpgradeNode.gameObject:SetActive(true)
	self.Controls.m_TextNextSkillEff.text = skillTotalNextUpdateScheme.LevelDesc 
	
	self:UpdateSkillCostShow(skillOriginalNextUpdateScheme)
	
end

-- 更新技能消耗显示
-- @skillUpdateScheme:技能升级配置:SkillUpdate
function UpgradeSkillInfoWidget:UpdateSkillCostShow(skillUpdateScheme)
	
	local hero = GetHero()
	if not hero then
		return
	end
	
	local upCostMat = skillUpdateScheme.NeedGoodsID > 0
	self.Controls.m_TfCostYinBiNode.gameObject:SetActive(not upCostMat)
	self.Controls.m_TfCostMatNode.gameObject:SetActive(upCostMat)

	if upCostMat then -- 消耗材料
		self.m_UpgradeSkillMatItem:UpdateItem(skillUpdateScheme.NeedGoodsID, skillUpdateScheme.NeedGoodsNum)	
	else -- 消耗银币
		local haveYinBi = hero:GetCurrency(emCoinClientType_YinBi)
		local haveYinLiang = hero:GetCurrency(emCoinClientType_YinLiang)
		local haveCurrency = haveYinBi

		-- 货币图标处理
		local currencyIconPath =AssetPath_CurrencyIcon[3]
		if haveYinBi < 1 then
			currencyIconPath = AssetPath_CurrencyIcon[2]
			haveCurrency = haveYinLiang
		end
	
		-- 货币文本颜色处理
		if haveYinBi < skillUpdateScheme.NeedSilver and haveYinBi > 0 then
			self.Controls.m_TextCurrencyValueHave.color = UIFunction.ConverRichColorToColor("e4595a")
		elseif haveYinLiang < skillUpdateScheme.NeedSilver and haveYinBi < 1 then
			self.Controls.m_TextCurrencyValueHave.color = UIFunction.ConverRichColorToColor("e4595a")
		else 
			self.Controls.m_TextCurrencyValueHave.color = UIFunction.ConverRichColorToColor("597993")
		end

		self.Controls.m_TextCurrencyValueCost.text = string.format("%s",GameHelp:GetMoneyText(skillUpdateScheme.NeedSilver) )
		self.Controls.m_TextCurrencyValueHave.text = string.format("%s", GameHelp:GetMoneyText(haveCurrency))
		self.Controls.m_TfTipCostYinLiang.gameObject:SetActive(haveYinBi < skillUpdateScheme.NeedSilver)
		
		UIFunction.SetImageSprite(self.Controls.m_ImageCurrencyIconCost, currencyIconPath)
		UIFunction.SetImageSprite(self.Controls.m_ImageCurrencyIconHave, currencyIconPath)
	end
	
end

-- 隐藏窗口
function UpgradeSkillInfoWidget:HideWindow()
	
	UIControl.Hide(self, false)
	--self.transform.gameObject:SetActive(false)
	
end

-- 升级按钮的点击行为
function UpgradeSkillInfoWidget:OnUpgradeButtonClick()
	
	local hero = GetHero()
	if not hero then
		return
	end
	
	local studyPart = hero:GetEntityPart(ENTITYPART_PERSON_STUDYSKILL)
	if not studyPart then
		return
	end
	
	studyPart:RequestUpgradeSkill(self.m_TheSelectedSkillId)
	
end

-- 学习按钮的点击行为
function UpgradeSkillInfoWidget:OnLearnButtonClick()
	
	local hero = GetHero()
	if not hero then
		return
	end
	
	local studyPart = hero:GetEntityPart(ENTITYPART_PERSON_STUDYSKILL)
	if not studyPart then
		return
	end
	
	studyPart:RequestUpgradeSkill(self.m_TheSelectedSkillId)
	
end

-- 添加按钮的点击行为
function UpgradeSkillInfoWidget:OnAddButtonClick()
	
	UIManager.ShopWindow:OpenShop(2415)
	
end


function UpgradeSkillInfoWidget:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function UpgradeSkillInfoWidget:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function UpgradeSkillInfoWidget:CleanData()

	self.Controls.m_ButtonLearn.onClick:RemoveListener(self.onLearnButtonClick)
	self.Controls.m_ButtonUpgrade.onClick:RemoveListener(self.onUpgradeButtonClick)
	self.Controls.m_ButtonAdd.onClick:RemoveListener(self.onAddButtonClick)
	self.onLearnButtonClick = nil
	self.onUpgradeButtonClick = nil
	self.onAddButtonClick = nil
	
end

return UpgradeSkillInfoWidget