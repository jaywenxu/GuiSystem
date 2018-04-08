--/******************************************************************
---** 文件名:	WuXueControlWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-06
--** 版  本:	1.0
--** 描  述:	玩家技能窗口-武学窗口-操作窗口
--** 应  用:  
--******************************************************************/

local UpgradeSkillMatItem = require("GuiSystem.WindowList.PlayerSkill.UpgradeSkillMatItem")
local WuXueControlAttrItem = require("GuiSystem.WindowList.PlayerSkill.WuXueControlAttrItem")

local WuXueUpgradeAttr = {}
function WuXueUpgradeAttr:new()
	return 
	{
		m_AttrId = 0,		-- 属性id
		m_CurAttrVal = 0,	-- 当前属性值
		m_NextAttrVal = 0,	-- 下一级属性值
		m_ActiveLevel = 0,	-- 属性激活等级
		m_SortIdx = 0,		-- 排序编号
	}
end

local WuXueControlWidget = UIControl:new
{
	windowName 	= "WuXueControlWidget",
	
	m_WuXueId = 0,						-- 当前要操作的武学id:number
	m_MiJiId = 0,						-- 当前要操作的秘籍id:number
	
	m_MatItem1 = nil,					-- 升级材料图标1:UpgradeSkillMatItem
	m_MatItem2 = nil,					-- 升级材料图标2:UpgradeSkillMatItem
	
	m_ListWuXueControlAttrItem = {},	-- 武学操作界面属性图标列表:table(WuXueControlAttrItem)
}


function WuXueControlWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	
	self.m_MatItem1 = UpgradeSkillMatItem:new()
	self.m_MatItem2 = UpgradeSkillMatItem:new()
	self.m_MatItem1:Attach(self.Controls.m_TfMatItem1.gameObject)
	self.m_MatItem2:Attach(self.Controls.m_TfMatItem2.gameObject)
	
	for itemIdx = 1, 6 do
		local attrItem = WuXueControlAttrItem:new()
		local obj = self.Controls[string.format("m_TfWuXueControlAttrItem%d", itemIdx)].gameObject
		attrItem:Attach(obj)
		
		table.insert(self.m_ListWuXueControlAttrItem, attrItem)
	end
	
	self.onJiHuoButtonClick = function() self:OnJiHuoButtonClick() end
	self.onUpgradeButtonClick = function() self:OnUpgradeButtonClick() end
	self.Controls.m_ButtonJiHuo.onClick:AddListener(self.onJiHuoButtonClick)
	self.Controls.m_ButtonUpgrade.onClick:AddListener(self.onUpgradeButtonClick)
	
end

-- 窗口每次被打开时，被调用的行为
-- @wuXueId:要操作的武学id:number
-- @miJiId:要操作的秘籍id:number
function WuXueControlWidget:OnWidgetShow(wuXueId, miJiId)

	-- 更新窗口
	self:UpdateWidget(wuXueId, miJiId)

end

-- 更新窗口
-- miJiId有效的时候，表示在升级秘籍
-- @wuXueId:要操作的武学id:number
-- @miJiId:要操作的秘籍id:number
function WuXueControlWidget:UpdateWidget(wuXueId, miJiId)
	
	self.m_WuXueId = wuXueId
	self.m_MiJiId = miJiId
	
	if self.m_MiJiId > 0 then
		-- 秘籍的更新
		self:UpdateForMiJi()
	else 
		-- 武学的更新
		self:UpdateForWuXue()
	end
	
end

-- 武学的更新
function WuXueControlWidget:UpdateForWuXue()
	
	local studyPart = GetHeroEntityPart(ENTITYPART_PERSON_STUDYSKILL)
	if not studyPart then
		return
	end
	
	local actScheme = IGame.rktScheme:GetSchemeInfo(BATTLEBOOK_ACTIVATION_CSV, self.m_WuXueId)
	if not actScheme then
		return
	end
	
	local wuXueLevel = studyPart:GetWuXueLevel(self.m_WuXueId)
	local wuXueScheme = IGame.rktScheme:GetSchemeInfo(BATTLEBOOK_UPGRADE_CSV, self.m_WuXueId, wuXueLevel)
	local nextWuXueScheme = IGame.rktScheme:GetSchemeInfo(BATTLEBOOK_UPGRADE_CSV, self.m_WuXueId, wuXueLevel + 1)
	if not wuXueScheme and wuXueLevel > 0 then
		return
	end
	
	local isLevelMax = nextWuXueScheme == nil
	self.Controls.m_TfCanUpgradeNode.gameObject:SetActive(not isLevelMax)
	self.Controls.m_TfCantUpgradeNode.gameObject:SetActive(isLevelMax)
	
	local listUpgradeAttr = self:AdjustWuXueUpgradeAttr(self.m_WuXueId, wuXueLevel)
	
	-- 更新属性的显示
	self:UpdateAttrShow(listUpgradeAttr)

	self.Controls.m_ButtonJiHuo.gameObject:SetActive(wuXueLevel < 1)
	self.Controls.m_ButtonUpgrade.gameObject:SetActive(wuXueLevel > 0)
	self.Controls.m_TfMiJiIconNode.gameObject:SetActive(false)
	self.Controls.m_TfWuXueIconNode.gameObject:SetActive(true)
	self.Controls.m_TfCostMatNode.gameObject:SetActive(false)
	
	self.Controls.m_TextName.text = actScheme.Name
	self.Controls.m_TextLevel.text = string.format("%d", wuXueLevel)
	self.Controls.m_TextDesc.text = actScheme.Desc
	
	
	-- 升级材料
	if nextWuXueScheme ~= nil and nextWuXueScheme.NeedGoodsID1 > 0 then
		self.Controls.m_TfCostMatNode.gameObject:SetActive(true)
		
		-- 更新一个材料
		self:UpdateOneMat(self.m_MatItem1, nextWuXueScheme.NeedGoodsID1, nextWuXueScheme.NeedGoodsNum1)
		-- 更新一个材料
		self:UpdateOneMat(self.m_MatItem2, nextWuXueScheme.NeedGoodsID2 or 0, nextWuXueScheme.NeedGoodsNum2 or 0)
	else 
		self.Controls.m_TfCostMatNode.gameObject:SetActive(false)
	end
	
	local canUse = self:CheckUpOrJihuoBtn(wuXueLevel + 1)
	local str = nil
	if canUse == false then 
		self.Controls.m_TextUpgradeCondition.text = string.format("<color=#E4595AFF>需要所有秘籍达到%d级</color>", wuXueLevel + 1)
	else
		self.Controls.m_TextUpgradeCondition.text = string.format("<color=#597993FF>需要所有秘籍达到%d级</color>", wuXueLevel + 1)
	end
	
	UIFunction.SetImageSprite(self.Controls.m_ImageWuXueIcon, AssetPath.TextureGUIPath..actScheme.Icon)	
	UIFunction.SetImageSprite(self.Controls.m_ImageWuXueQuality,GuiAssetList.WuxueQualityBg[actScheme.Quality])
	
end

--检查是否可以升级或者激活
function WuXueControlWidget:CheckUpOrJihuoBtn(needLevel)
	local wuXueScheme = IGame.rktScheme:GetSchemeInfo(BATTLEBOOK_ACTIVATION_CSV, self.m_WuXueId)
	if not wuXueScheme then
		uerror("没有找到对应的武学解锁表, id:%d", self.m_CurSelectedWuXueId)
		return false
	end
	local studyPart = GetHeroEntityPart(ENTITYPART_PERSON_STUDYSKILL)
	if not studyPart then
		return false
	end
	for i=1,5 do 
		local miJiId = wuXueScheme[string.format("Slot%dID", i)]
		if miJiId > 0 then 
			local miJiLv = studyPart:GetWuXueSlotLevel(miJiId)
			if miJiLv < needLevel then 
				return false
			end
		end
		
	end
	return true
end

-- 秘籍的更新
function WuXueControlWidget:UpdateForMiJi()
	
	local studyPart = GetHeroEntityPart(ENTITYPART_PERSON_STUDYSKILL)
	if not studyPart then
		return
	end
	
	local actScheme = IGame.rktScheme:GetSchemeInfo(BATTLEBOOK_ACTIVATION_CSV, self.m_WuXueId)
	if not actScheme then
		return
	end
	
	local miJiLevel = studyPart:GetWuXueSlotLevel(self.m_MiJiId)
	local miJiScheme = IGame.rktScheme:GetSchemeInfo(BATTLEBOOK_SLOTUPGRADE_CSV, self.m_MiJiId, miJiLevel)
	local nextMiJiScheme = IGame.rktScheme:GetSchemeInfo(BATTLEBOOK_SLOTUPGRADE_CSV, self.m_MiJiId, miJiLevel + 1)
	if not miJiScheme and miJiLevel > 0 then
		uerror("mijiScheme is nil")
		return
	end
	
	local isLevelMax = nextMiJiScheme == nil
	self.Controls.m_TfCanUpgradeNode.gameObject:SetActive(not isLevelMax)
	self.Controls.m_TfCantUpgradeNode.gameObject:SetActive(isLevelMax)
	
	local listUpgradeAttr = self:AdjustMiJiUpgradeAttr(self.m_MiJiId, miJiLevel)
	
	-- 更新属性的显示
	self:UpdateAttrShow(listUpgradeAttr)
	

	self.Controls.m_ButtonJiHuo.gameObject:SetActive(miJiLevel < 1)
	self.Controls.m_ButtonUpgrade.gameObject:SetActive(miJiLevel > 0)
	self.Controls.m_TfMiJiIconNode.gameObject:SetActive(true)
	self.Controls.m_TfWuXueIconNode.gameObject:SetActive(false)
	
	self.Controls.m_TextLevel.text = string.format("%d", miJiLevel)

	-- 秘籍信息获取
	local miJiName = ""
	local miJiIcon = ""
	local miJiDesc = ""
	local miJiQuality = ""
	for miJiIdx = 1, 5 do
		local cfgId = actScheme[string.format("Slot%dID", miJiIdx)]
		if cfgId == self.m_MiJiId then
			miJiName = actScheme[string.format("Slot%dName", miJiIdx)]
			miJiIcon = actScheme[string.format("Slot%dIcon", miJiIdx)]
			miJiDesc = actScheme[string.format("Slot%dDesc", miJiIdx)]
			miJiQuality = actScheme[string.format("Slot%dFrame", miJiIdx)]
			break
		end
	end
	
	-- 升级材料
	if nextMiJiScheme~= nil and  (nextMiJiScheme.UpgradeGoodsID1 > 0 or nextMiJiScheme.UpgradeGoodsID2 > 0) then
		self.Controls.m_TfCostMatNode.gameObject:SetActive(true)
		
		-- 更新一个材料
		self:UpdateOneMat(self.m_MatItem1, nextMiJiScheme.UpgradeGoodsID1, nextMiJiScheme.UpgradeGoodsNum1)
		-- 更新一个材料
		self:UpdateOneMat(self.m_MatItem2, nextMiJiScheme.UpgradeGoodsID2, nextMiJiScheme.UpgradeGoodsNum2)
	else 
		self.Controls.m_TfCostMatNode.gameObject:SetActive(false)
	end
	
	self.Controls.m_TextName.text = miJiName
	self.Controls.m_TextDesc.text = miJiDesc
	
	
	self.Controls.m_TextUpgradeCondition.text = ""
	UIFunction.SetImageSprite(self.Controls.m_ImageMiJiIcon, AssetPath.TextureGUIPath..miJiIcon)	
	UIFunction.SetImageSprite(self.Controls.m_ImageMiJiQuality, AssetPath.TextureGUIPath..miJiQuality)	
	
end

-- 整理武学技能升级属性
-- @wuXueId:武学id:number
-- @wuXueLevel:武学等级:number
-- return:属性信息:table(WuXueUpgradeAttr)
function WuXueControlWidget:AdjustWuXueUpgradeAttr(wuXueId, wuXueLevel)
	
	-- 整理升级属性
	return self:AdjustUpgradeAttr(BATTLEBOOK_UPGRADE_CSV, wuXueId, wuXueLevel, 6)
	
end


-- 整理秘籍技能升级属性
-- @miJiId:秘籍id:number
-- @miJiLevel:秘籍等级:number
-- return:属性信息:table(WuXueUpgradeAttr)
function WuXueControlWidget:AdjustMiJiUpgradeAttr(miJiId, miJiLevel)
	
	-- 整理升级属性
	return self:AdjustUpgradeAttr(BATTLEBOOK_SLOTUPGRADE_CSV, miJiId, miJiLevel, 4)
	
end

-- 整理升级属性
-- @schemeName:配置名称:string
-- @id:要处理的武学或秘籍id:number
-- @level:要处理的武学或秘籍的等级:number
-- @attrCnt:属性数量:number
-- return:属性信息:table(WuXueUpgradeAttr)
function WuXueControlWidget:AdjustUpgradeAttr(schemeName, id, level, attrCnt)
	
	local listAllUpScheme = IGame.rktScheme:GetSchemeTable(schemeName)
	if not listAllUpScheme then
		return {}
	end
	
	local idMulFactor = 100000
	local tableSort = {}
	for k,v in pairs(listAllUpScheme) do
		table.insert(tableSort, v.ID * idMulFactor + v.Level)
	end

	table.sort(tableSort)

	local tableAttr = {}
	for cfgIdx = 1, #tableSort do
		local tmpVal = tableSort[cfgIdx]
		local tmpId  = math.floor(tmpVal/idMulFactor)
		local tmpLv = tmpVal - tmpId * idMulFactor

		if tmpId == id and tmpLv >= level then
			local scheme = IGame.rktScheme:GetSchemeInfo(schemeName, tmpId, tmpLv)
			if scheme then
				for attrIdx = 1, attrCnt do 
					local tmpAttrId = scheme[string.format("PropType%d", attrIdx)]
					local tmpAttrVal = scheme[string.format("PropValue%d", attrIdx)]
					if tmpAttrId > 0 then
						if tableAttr[attrIdx] == nil then
							local upgradeAttr = WuXueUpgradeAttr:new()
							upgradeAttr.m_AttrId = tmpAttrId
							upgradeAttr.m_SortIdx = attrIdx
							
							if tmpLv - level == 1 then -- 下一级便激活
								upgradeAttr.m_CurAttrVal = 0
								upgradeAttr.m_NextAttrVal = tmpAttrVal
								upgradeAttr.m_ActiveLevel = tmpLv
							elseif level == tmpLv then -- 当前等级
								upgradeAttr.m_CurAttrVal = tmpAttrVal
							else -- 需要解锁
								upgradeAttr.m_NextAttrVal = tmpAttrVal
								upgradeAttr.m_ActiveLevel = tmpLv
							end
							
							tableAttr[attrIdx] = upgradeAttr
						else 
							local upgradeAttr = tableAttr[attrIdx]
							if tmpLv - level == 1 then -- 下一级
								upgradeAttr.m_NextAttrVal = tmpAttrVal
							end
						end
					end
				end
			end
		end
	end
	
	return tableAttr
	
end

-- 更新属性的显示
-- @listUpgradeAttr:属性升级数据列表:table(WuXueUpgradeAttr)
function WuXueControlWidget:UpdateAttrShow(listUpgradeAttr)

	local tableSort = {}
	local tableSortKey = {}
	for k,v in pairs(listUpgradeAttr) do
		tableSort[v.m_SortIdx] = v
	end
	
	local attrCnt = #tableSort
	for itemIdx = 1, #self.m_ListWuXueControlAttrItem do
		local item = self.m_ListWuXueControlAttrItem[itemIdx]
		local itemNeedShow = itemIdx <= attrCnt
		
		item.transform.gameObject:SetActive(itemNeedShow)
		if itemNeedShow then
			item:UpdateItem(tableSort[itemIdx])
		end
		
	end
	
end

-- 更新一个材料
-- @matItem:材料图标:UpgradeSkillMatItem
-- @matId:材料id:number
-- @needCnt:需要数量:number
function WuXueControlWidget:UpdateOneMat(matItem, matId, needCnt)
	
	matItem.transform.gameObject:SetActive(matId > 0)
	
	if matId > 0 then
		matItem:UpdateItem(matId, needCnt, true)
	end
	
end

-- 激活按钮的点击行为
function WuXueControlWidget:OnJiHuoButtonClick()
	
	local studyPart = GetHeroEntityPart(ENTITYPART_PERSON_STUDYSKILL)
	if not studyPart then
		return
	end
	
	if self.m_MiJiId > 0 then
		studyPart:RequestUpgradeBattleBookSlot(self.m_MiJiId)
	else 
		studyPart:RequestRequestUpgradeBattleBookNew(self.m_WuXueId)
	end
	
end

-- 升级按钮点击行为
function WuXueControlWidget:OnUpgradeButtonClick()
	
	local studyPart = GetHeroEntityPart(ENTITYPART_PERSON_STUDYSKILL)
	if not studyPart then
		return
	end
	
	if self.m_MiJiId > 0 then
		studyPart:RequestUpgradeBattleBookSlot(self.m_MiJiId)
	else 
		studyPart:RequestRequestUpgradeBattleBookNew(self.m_WuXueId)
	end
	
end

-- 收到玩家真气查询回包处理
function WuXueControlWidget:HandleNet_PlayerZhenQiRes()
	
	if self.m_MiJiId > 0 then
		-- 秘籍的更新
		self:UpdateForMiJi()
	else 
		-- 武学的更新
		self:UpdateForWuXue()
	end
	
end

function WuXueControlWidget:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function WuXueControlWidget:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function WuXueControlWidget:CleanData()

	self.Controls.m_ButtonJiHuo.onClick:RemoveListener(self.onJiHuoButtonClick)
	self.Controls.m_ButtonUpgrade.onClick:RemoveListener(self.onUpgradeButtonClick)
	self.onJiHuoButtonClick = nil
	self.onUpgradeButtonClick = nil
	
end

return WuXueControlWidget