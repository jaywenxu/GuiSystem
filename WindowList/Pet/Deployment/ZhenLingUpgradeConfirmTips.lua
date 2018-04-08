
-----------------------------灵兽阵灵升级确认界面------------------------------
local ZhenLingUpgradeConfirmTips = UIControl:new
{
	windowName = "ZhenLingUpgradeConfirmTips",
	
	m_CurZhenFaIndex = -1,
	m_CurZhenLingIndex = -1,
}

function ZhenLingUpgradeConfirmTips:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.UpgradeBtnClickCB = function() self:OnUpgradeBtnClick() end
	self.Controls.m_UpgradeBtn.onClick:AddListener(self.UpgradeBtnClickCB)
	
	self.BoLiBtnClickCB = function() self:OnBoLiBtnClick() end
	self.Controls.m_BoLiBtn.onClick:AddListener(self.BoLiBtnClickCB)
	
	self.Controls.m_CloseBtn.onClick:AddListener(function() self:Hide() end)
	
	--回包消息处理函数
	self.OnMsgRereshCB = function() self:RefreshView(self.m_CurZhenFaIndex, self.m_CurZhenLingIndex) end
end

function ZhenLingUpgradeConfirmTips:Show()
	rktEventEngine.SubscribeExecute(EVENT_PET_UPGRADEZHENLING, SOURCE_TYPE_PET, 0, self.OnMsgRereshCB)
	
	
	UIControl.Show(self)
end

function ZhenLingUpgradeConfirmTips:Hide( destroy )
	self.m_CurZhenFaIndex = -1
	self.m_CurZhenLingIndex = -1
	
	rktEventEngine.UnSubscribeExecute(EVENT_PET_UPGRADEZHENLING, SOURCE_TYPE_PET, 0, self.OnMsgRereshCB)
	UIControl.Hide(self, destroy)
end

function ZhenLingUpgradeConfirmTips:OnDestroy()
	self.m_CurZhenFaIndex = -1
	self.m_CurZhenLingIndex = -1
	
	rktEventEngine.UnSubscribeExecute(EVENT_PET_UPGRADEZHENLING, SOURCE_TYPE_PET, 0, self.OnMsgRereshCB)
	UIControl.OnDestroy(self)
end

--打开本升级界面
function ZhenLingUpgradeConfirmTips:OpenUpgradePage(zhenFaIndex, slotIndex)
	self.m_CurZhenFaIndex = zhenFaIndex
	self.m_CurZhenLingIndex = slotIndex
	self:RefreshView(zhenFaIndex, slotIndex)
	self:Show()
end

--刷新界面
function ZhenLingUpgradeConfirmTips:RefreshView(zhenFaIndex, slotIndex)
	local cfg = IGame.PetClient:GetZhenLingSlotCfg(zhenFaIndex, slotIndex)
	local record = IGame.rktScheme:GetSchemeInfo(PETZHENCFG_CSV, cfg.id, cfg.lv)
	local goodsRecord = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, cfg.id)    
	if not record or not goodsRecord then return end
	
	UIFunction.SetImageSprite(self.Controls.m_ZhenLingIcon, AssetPath.TextureGUIPath..goodsRecord.lIconID1)
	UIFunction.SetImageSprite(self.Controls.m_QualityImg, AssetPath.TextureGUIPath..goodsRecord.lIconID2)
	self.Controls.m_ZhenLingName.text = (record.Name or "").." "..(record.Level or 1).."级"
	self.Controls.m_ZhenLingLevel.text = record.Level or 1
	self.Controls.m_ZhenLingDesText.text = record.Desc or ""
	
    self.Controls.m_ZhenLingNextLevelDes.text = record.EffectDesc or ""
    
    local nextRecord = IGame.rktScheme:GetSchemeInfo(PETZHENCFG_CSV, cfg.id, cfg.lv + 1)
    if not nextRecord then
		self:SetIsMaxLevel(true)
	else
		self:SetIsMaxLevel(false)
		UIFunction.SetImageSprite(self.Controls.m_CostQuality, AssetPath.TextureGUIPath.. goodsRecord.lIconID2)
		UIFunction.SetImageSprite(self.Controls.m_CostIcon, AssetPath.TextureGUIPath..goodsRecord.lIconID1)
		self.Controls.m_CostNameText.text = "<color=#" .. AssetPath_GoodsQualityColor[goodsRecord.lBaseLevel] .. ">" .. goodsRecord.szName .. "</color>"
		local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
		if not packetPart then
			return
		end
		local haveNum = packetPart:GetGoodNum(cfg.id)
		self:SetCostHaveNum(haveNum, nextRecord.UpgradeUseNum)
	end
end

--设置技能消耗物品数量
function ZhenLingUpgradeConfirmTips:SetCostHaveNum(haveNum, needNum)
	if(haveNum < needNum) then
		self.Controls.m_CostNumText.text = string.format("<color=red>%d</color>/%d", haveNum, needNum)
		self.CanUpgrade = false
	else
		self.Controls.m_CostNumText.text = string.format("%d/%d", haveNum, needNum)
		self.CanUpgrade = true
	end	
end

--设置是否满级
function ZhenLingUpgradeConfirmTips:SetIsMaxLevel(isMaxLevel)
	self.Controls.m_UpgradeWidget.gameObject:SetActive(not isMaxLevel)
	self.Controls.m_MaxLevelWidget.gameObject:SetActive(isMaxLevel)
end

--点击升级按钮回调事件
function ZhenLingUpgradeConfirmTips:OnUpgradeBtnClick()
	if not self.CanUpgrade then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "升级物品不足")
		return
	end

	local zhenfaIndex = self.m_CurZhenFaIndex - 1
	GameHelp.PostServerRequest("RequestSpirit_Upgrade(" .. zhenfaIndex .. "," .. self.m_CurZhenLingIndex ..")")
end

--点击剥离按钮回调事件
function ZhenLingUpgradeConfirmTips:OnBoLiBtnClick()
	local zhenfaIndex = self.m_CurZhenFaIndex - 1
	GameHelp.PostServerRequest("RequestPetSpirit_Boli(" .. zhenfaIndex .. "," .. self.m_CurZhenLingIndex ..")")
	self:Hide()
end

return ZhenLingUpgradeConfirmTips