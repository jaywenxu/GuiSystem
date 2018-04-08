------------------------------------------------------------
-- TooltisWindow 的子窗口,不要通过 UIManager 访问
------------------------------------------------------------
--local CommonGoodCellClass = require( "GuiSystem.WindowList.CommonWindow.CommonGoodCell" )

local EquipTooltipsWidget = UIControl:new
{
    windowName = "EquipTooltipsWidget" ,
	entity = nil,
	m_EntityInfo = {},
	info = nil,
	m_needMove = false,
	m_moveType = "other",
	m_DecomposeStatus = false,
	m_bShowBtn = 1,
	m_EntityType = 1,	-- 1:实体  2:数据
}

local this = EquipTooltipsWidget   -- 方便书写
local zero = int64.new("0")

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function EquipTooltipsWidget:Attach(obj)
	UIControl.Attach(self, obj)
	self.AllWidgets = {}
	
	self.HeadWidget = UIControl:new{windowName = "HeadWidget"}
	self.HeadWidget:Attach(self.Controls.m_Head.gameObject)
	table.insert(self.AllWidgets, self.HeadWidget)

	self.ScoreWidget = UIControl:new{windowName = "ScoreWidget"}
	self.ScoreWidget:Attach(self.Controls.m_Score.gameObject)
	table.insert(self.AllWidgets, self.ScoreWidget)
	
	self.Controls.m_BasicContentText = self.transform:Find("BasicContentText")
	
	--self.Controls.m_AdditionalContentText = self.transform:Find("AdditionalContentText"):GetComponent(typeof(Text))
	
	self.SettingWidget = UIControl:new{windowName = "SettingWidget"}
	self.SettingWidget:Attach(self.Controls.m_Setting.gameObject)
	table.insert(self.AllWidgets, self.SettingWidget)

	self.ShuffleWidget = UIControl:new{windowName = "ShuffleWidget"}
	self.ShuffleWidget:Attach(self.transform:Find("FloatTips_Shuffle_Cell").gameObject)
	table.insert(self.AllWidgets, self.ShuffleWidget)
	
	self.parentOriginPosition = self.transform.parent.transform.localPosition
	self.callback_OnTimerGetHeight = function() self:OnTimerGetHeight() end
	self.parentOriginPosition = self.transform.parent.transform.localPosition
	self.m_chatPosition       = Vector3.New(0, 0, 0)
	
	return self
end

------------------------------------------------------------
function EquipTooltipsWidget:OnDestroy()
	UIControl.OnDestroy(self)
end

-- 设置物品实体
function EquipTooltipsWidget:SetEntity(entity)
	if not entity then
		return
	end
	self.entity = entity
	self.m_EntityType = 1
	local entityClass = entity:GetEntityClass()
	if not EntityClass:IsEquipment(entityClass) then
		return
	end
	local nGoodsID = entity:GetNumProp(GOODS_PROP_GOODSID)
	local pEquipSchemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, nGoodsID)
	if not pEquipSchemeInfo then
		uerror("EquipTooltipsWidget:SetEntity, can not find scheme info. : "..tostringEx(goodsID))
		return
	end
	self:Refresh()
end

-- 设置物品实体
function EquipTooltipsWidget:SetInfo(EquipInfo)
	if not EquipInfo then
		return
	end
	self.m_EntityInfo = EquipInfo
	self.m_EntityType = 2
	local nGoodsID = EquipInfo[PASTER_EQUIP_INFO_KEY_GOODSID]
	local pEquipSchemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, nGoodsID)
	if not pEquipSchemeInfo then
		uerror("EquipTooltipsWidget:SetEntity, can not find scheme info. : "..tostringEx(goodsID))
		return
	end
	self:Refresh()
end

function EquipTooltipsWidget:Refresh()
	self:SetHeadInfo()			-- 窗口头
	self:SetScoreInfo()			-- 评分
	self:SetBasicInfo()			-- 基础属性
	self:SetAdditionalInfo() 	-- 附加属性
	self:SetSettingInfo() 		-- 镶嵌属性
	self:SetShuffleInfo()		-- 洗炼属性
end


-- 窗口头
function EquipTooltipsWidget:SetHeadInfo()
	local widget = self.HeadWidget
	-- 头像背景
	local nQuality = 0
	local nAdditionalPropNum = 0
	local EquipID = 0
	local EquipUID = 0
	local nBind = 0
	local percent = 0
	local nNormalSmeltLv = 0
	local nPCTSmeltLv = 0
	local AdditionalProp = {}
	local schemeInfo = nil
	if self.m_EntityType == 1 then
		local entity = self.entity
		EquipID = entity:GetNumProp(GOODS_PROP_GOODSID)
		-- 头像背景
		nQuality = entity:GetNumProp(EQUIP_PROP_QUALITY)
		nAdditionalPropNum = entity:GetAdditionalPropNum()
		EquipUID = entity:GetUID()
		nBind = entity:GetNumProp(GOODS_PROP_BIND)
		percent = entity:GetAdditionalPercent()
		schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, EquipID)
		if not schemeInfo then
			return
		end
		-- 强化等级
		local forgePart = GetHero():GetEntityPart(ENTITYPART_PERSON_FORGE)
		if not forgePart then
			return
		end
		local HoleProp = forgePart:GetHoleProp(schemeInfo.EquipLoc1)
		if not HoleProp then
			return
		end
		nNormalSmeltLv = HoleProp.bySmeltLv  -- 普通强化等级
		nPCTSmeltLv = HoleProp.byPCTSmeltLv  -- 附加强化等级
	else
		EquipID = self.m_EntityInfo[PASTER_EQUIP_INFO_KEY_GOODSID]
		schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, EquipID)
		if not schemeInfo then
			return
		end
		nQuality = self.m_EntityInfo[PASTER_EQUIP_INFO_KEY_QUALITY]
		nAdditionalPropNum = table_count(self.m_EntityInfo[PASTER_EQUIP_INFO_KEY_PROPTABLE])
		EquipUID = zero
		nBind = self.m_EntityInfo[PASTER_EQUIP_INFO_KEY_BIND]
		for j = 1, MAX_ADDITIONAL_PROP_NUM do 
			local prop = self.m_EntityInfo[PASTER_EQUIP_INFO_KEY_PROPTABLE][j]
			if prop ~= nil then
				local nAddtionnalType = prop.nType
				local nAdditionalValue = prop.nid
				if(CREATURE_PROP_CUR_EQUIP_ENHANCE_PER == nAddtionnalType) then
					percent = percent + nAdditionalValue/10000
				end
			end
		end
	end
	
    -- 头像图片
	local equipImagePath = AssetPath.TextureGUIPath .. schemeInfo.IconIDNormal
	UIFunction.SetImageSprite(widget.Controls.m_Icon, equipImagePath)
	 
	local headBgPath = GameHelp.GetEquipHeadBg(nQuality, nAdditionalPropNum)
	if not headBgPath then
		uerror(" 【装备TIPS】背景图HeadBg找不到  EquipID = "..tostringEx(EquipID)..",nQuality = "..tostringEx(EquipID)..",nAdditionalPropNum = "..tostringEx(nAdditionalPropNum))
		return
	end
	UIFunction.SetImageSprite(widget.Controls.m_headBg,headBgPath)
	local imageBgPath = GameHelp.GetEquipImageBgPath(nQuality, nAdditionalPropNum)
	if not imageBgPath then
		uerror(" 【装备TIPS】背景图ImageBg找不到  EquipID = "..tostringEx(EquipID)..",nQuality = "..tostringEx(EquipID)..",nAdditionalPropNum = "..tostringEx(nAdditionalPropNum))
		return
	end
	UIFunction.SetImageSprite(widget.Controls.m_IconBg, imageBgPath)
	
	-- 已装备标记
	local equipPart = GetHero():GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart then
		return
	end
	
	if equipPart:GetSkepPosByUID(EquipUID) == -1 or EquipUID == zero then
		widget.Controls.m_EquipState.gameObject:SetActive(false)
	else
		widget.Controls.m_EquipState.gameObject:SetActive(true)
	end
	
	-- 绑定标记
	if lua_NumberAndTest(nBind, tGoods_BindFlag_Hold) then
		widget.Controls.m_BindState.gameObject:SetActive(true)
	else
		widget.Controls.m_BindState.gameObject:SetActive(false)
	end
	
	local textColor = DColorDef.getNameColor(1,nQuality,nAdditionalPropNum)
	local roleName  = schemeInfo.szName
	if  nQuality == 4 then
		 roleName = "【神】"..roleName
	end
	
	if nAdditionalPropNum == 7 then 
		roleName = roleName .. " • 绝世"
	end
		
	if nAdditionalPropNum == 8 then 
		roleName = roleName .. " • 逆天"
	end
	
	-- 强化等级
	local forgePart = GetHero():GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	local HoleProp = forgePart:GetHoleProp(schemeInfo.EquipLoc1)
	if not HoleProp then
		return
	end
	
	if nNormalSmeltLv ~= 0 then
		roleName = roleName .. " <color=".. "#0bf200" .. ">+ " .. nNormalSmeltLv .. "</color>"
	end
	-- 物品名称
	widget.Controls.m_EquipName.text = "<color=#" ..textColor.. ">" .. roleName .. "</color>" or ""
	
	-- 显示类型，根据角色性别和职业是否匹配
	local szTypeColor = "dbe6ea"
	if (not CanEquipByVocation(GetHero():GetNumProp(CREATURE_PROP_VOCATION), schemeInfo.AllowVocation))
		or (not CanEquipBySex(GetHero():GetNumProp(CREATURE_PROP_SEX), schemeInfo.AllowSex)) then
		szTypeColor = "e4595a"
	end
	widget.Controls.m_VocationText.text = "<color=#" ..szTypeColor.. ">".. schemeInfo.subType .. "</color>"
	widget.Controls.m_VocationText.gameObject:SetActive(true)
	
	-- 角色等级不满足要求，用红色警告显示
	local szLevelColor = "dbe6ea"
	if GameHelp:GetHeroLevel() < schemeInfo.AllowLevel then
		szLevelColor = "e4595a"
	end
	widget.Controls.m_LevelText.text = "<color=#" .. szLevelColor.. ">等级："..schemeInfo.AllowLevel .. "</color>"
	widget.Controls.m_LevelText.gameObject:SetActive(true)
end


-- 评分
function EquipTooltipsWidget:SetScoreInfo()
	local widget = self.ScoreWidget
	local score = nil
    if self.m_EntityType == 1 then
		local entity = self.entity
		score = entity:ComputeEquipScore()
	else
		score = self.m_EntityInfo[PASTER_EQUIP_INFO_KEY_PINGFEN]
	end
	score = math.floor(score/10)
	widget.Controls.m_ScoreText.text= tostring(score)
end

-- 基础属性
function EquipTooltipsWidget:SetBasicInfo()
	-- 头像背景
	local nQuality = 0
	local nAdditionalPropNum = 0
	local EquipUID = 0
	local nBind = 0
	local percent = 0
	local nNormalSmeltLv = 0
	local nPCTSmeltLv = 0
	local AdditionalProp = {}
	local schemeInfo = {}
	if self.m_EntityType == 1 then
		local entity = self.entity
		EquipID = entity:GetNumProp(GOODS_PROP_GOODSID)
		-- 头像背景
		nQuality = entity:GetNumProp(EQUIP_PROP_QUALITY)
		nAdditionalPropNum = entity:GetAdditionalPropNum()
		EquipUID = entity:GetUID()
		nBind = entity:GetNumProp(GOODS_PROP_BIND)
		percent = entity:GetAdditionalPercent()
		schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, EquipID)
		if not schemeInfo then
			return
		end
		-- 强化等级
		local forgePart = GetHero():GetEntityPart(ENTITYPART_PERSON_FORGE)
		if not forgePart then
			return
		end
		local HoleProp = forgePart:GetHoleProp(schemeInfo.EquipLoc1)
		if not HoleProp then
			return
		end
		nNormalSmeltLv = HoleProp.bySmeltLv  -- 普通强化等级
		nPCTSmeltLv = HoleProp.byPCTSmeltLv  -- 附加强化等级
	else
		EquipID = self.m_EntityInfo[PASTER_EQUIP_INFO_KEY_GOODSID]
		schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, EquipID)
		if not schemeInfo then
			return
		end
		nQuality = self.m_EntityInfo[PASTER_EQUIP_INFO_KEY_QUALITY]
		nAdditionalPropNum = table_count(self.m_EntityInfo[PASTER_EQUIP_INFO_KEY_PROPTABLE])
		EquipUID = zero
		nBind = self.m_EntityInfo[PASTER_EQUIP_INFO_KEY_BIND]
		for j = 1, MAX_ADDITIONAL_PROP_NUM do 
			local prop = self.m_EntityInfo[PASTER_EQUIP_INFO_KEY_PROPTABLE][j]
			if prop ~= nil then
				local nAddtionnalType = prop.nType
				local nAdditionalValue = prop.nid
				if(CREATURE_PROP_CUR_EQUIP_ENHANCE_PER == nAddtionnalType) then
					percent = percent + nAdditionalValue/10000
				end
			end
		end
	end
	
	local contentText = ""
	local pEquipBasePropScheme = IGame.rktScheme:GetSchemeInfo(EQUIPBASEPROP_CSV , EquipID, nQuality, nAdditionalPropNum)
	if not pEquipBasePropScheme then
		return
	end
    local textColor = ""
	local pHero = GetHero()
	if not pHero then
		return
	end
	local nCreatureVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)

    local pNormalSmeltScheme = IGame.rktScheme:GetSchemeInfo(EQUIPNORMALSMELT_CSV , schemeInfo.EquipLoc1, nCreatureVocation, nNormalSmeltLv)
								or IGame.rktScheme:GetSchemeInfo(EQUIPNORMALSMELT_CSV , schemeInfo.EquipLoc1, 10000, nNormalSmeltLv)
	local titleText = nil
	local contentLabel = nil
	local IndexContent =nil
	local IndexTitle = nil
	local ShuXingName = nil
	for i = 1, 6 do
		contentText = nil
		ShuXingName = nil
		local nType = pEquipBasePropScheme["Type"..i]
		local value = pEquipBasePropScheme["Value"..i] 
		local IndexContent = self.Controls.m_BasicContentText:GetChild(i-1)
		local IndexTitle = IndexContent:Find("ContextTitle")
		if IndexContent == nil or IndexTitle == nil then 
			uerror("equiptips basicContent index not enough")
			return
		end
		titleText = IndexTitle:GetComponent(typeof(Text))
		contentLabel = IndexContent:GetComponent(typeof(Text))
		if nType ~= nil and nType ~= 0 then
			local desc = GameHelp.PropertyName[nType]
			ShuXingName = string.format("%-13s", (desc or "未知属性"))
		
			-- 附加属性百分比
            if percent ~= 0 then 
				value = value * (1 + percent)
				value = math.floor(value)
			end
			
			-- 强化增加值
			if pNormalSmeltScheme then
				for k = 1, 4 do 
					local nSmeltType  = pNormalSmeltScheme["wPropID"..k]
					local nSmeltValue = pNormalSmeltScheme["nPropValue"..k]
					if(nType == nSmeltType) then
						value = value + nSmeltValue
					end
				end
			end
			--附加强化百分比
			local nSmeltPercent = 0
			if nPCTSmeltLv ~= 0 then
				local pEquipPctSmelt = IGame.rktScheme:GetSchemeInfo(EQUIPPCTSMELT_CSV, nPCTSmeltLv)
				if pEquipPctSmelt then 
					nSmeltPercent = pEquipPctSmelt.nPercent / 100
					contentText =": "..value.." <color=".. "#0bf200" .. ">+ ".. nSmeltPercent .."%</color>"
				end
			else 
				contentText = ": "..value
			end
		end

		if IsNilOrEmpty(contentText) then 
			contentLabel.gameObject:SetActive(false)
		else
			contentLabel.gameObject:SetActive(true)
			titleText.text = ShuXingName
			contentLabel.text = contentText
		end
	end
	--contentText = string.sub(contentText, 1, -2)


end

-- 附加属性
function EquipTooltipsWidget:SetAdditionalInfo()
	-- 头像背景
	local nQuality = 0
	local nAdditionalPropNum = 0
	local EquipUID = 0
	local nBind = 0
	local percent = 0
	local AdditionalProp = {}
	if self.m_EntityType == 1 then
		local entity = self.entity
		EquipID = entity:GetNumProp(GOODS_PROP_GOODSID)
		-- 头像背景
		nQuality = entity:GetNumProp(EQUIP_PROP_QUALITY)
		nAdditionalPropNum = entity:GetAdditionalPropNum()
		EquipUID = entity:GetUID()
		nBind = entity:GetNumProp(GOODS_PROP_BIND)
		percent = entity:GetAdditionalPercent()
		
		AdditionalProp = entity:GetAllEffectInfo()
	else
		EquipID = self.m_EntityInfo[PASTER_EQUIP_INFO_KEY_GOODSID]
		nQuality = self.m_EntityInfo[PASTER_EQUIP_INFO_KEY_QUALITY]
		AdditionalProp = self.m_EntityInfo[PASTER_EQUIP_INFO_KEY_PROPTABLE]
		nAdditionalPropNum = table_count(AdditionalProp)
		EquipUID = zero
		nBind = self.m_EntityInfo[PASTER_EQUIP_INFO_KEY_BIND]
		for j = 1, MAX_ADDITIONAL_PROP_NUM do 
			local prop = self.m_EntityInfo[PASTER_EQUIP_INFO_KEY_PROPTABLE][j]
			if prop ~= nil then
				local nAddtionnalType = prop.nType
				local nAdditionalValue = prop.nid
				if(CREATURE_PROP_CUR_EQUIP_ENHANCE_PER == nAddtionnalType) then
					percent = percent + nAdditionalValue/10000
				end
			end
		end
	end
	
	
	local text = ""
	local titText = ""
	-- 获取文本颜色值
	local textColor = GameHelp.GetEquipNameColor(nQuality, nAdditionalPropNum)
	for i = 1, MAX_ADDITIONAL_PROP_NUM do
		text = ""
		titText = ""
		local prop = AdditionalProp[i]
		if prop ~= nil then
			local nType = prop.nType
			local value = prop.nid
			local propDesc = IGame.rktScheme:GetSchemeInfo(EQUIPATTACHPROPDESC_CSV, nType)
			if propDesc then 
				local strDesc = propDesc.strDesc 
				local subDesc = propDesc.subDesc
				local nSign   = propDesc.nSign
				local nPercent = propDesc.nPercent 
				local strSign = "" 
				
				if nSign == 0 then 
					strSign = "-"
				elseif nSign == 1 then
					strSign = "+" 
				else  
					strSign = ""
				end
				
				local strPerc = ""
				if nPercent == 1 then 
					value = value / 100
					strPerc = "%"
				end
				
				local specialDesc = ""
				local vocationName = ""
				local nValue = value

				-- 特殊属性
				if GameHelp:IsSpecialProp(nType) then
					-- 多重属性：致命一击;致命伤害  抗致命一击;抗致命伤害
					if nType == CREATURE_PROP_CUR_FATAL_AND_FATAL_PER or nType == CREATURE_PROP_CUR_TOUGH_AND_TOUGH_PER then
						local specialScheme = IGame.rktScheme:GetSchemeInfo(EQUIPSPECIALPROP_CSV, nType, nValue)
						local descTable = split_string(strDesc, ";")
						if specialScheme then 
							local tempTable = {}
							for j = 2, #(specialScheme.DetailItem), 2 do
								table.insert(tempTable, specialScheme.DetailItem[j])
							end
							
							local nSecondValue = math.floor(tempTable[2]/100)
							specialDesc = specialDesc..descTable[1]..strSign..tempTable[1].."，"..descTable[2]..strSign..nSecondValue.."%"
						end
					-- 多重属性：物理、法术伤害增加百分比  物理、法术伤害吸收百分比
					elseif nType == CREATURE_PROP_CUR_P_AND_M_ENHANCE_PER or nType == CREATURE_PROP_CUR_P_AND_M_ABSORB_PER then
						local specialScheme = IGame.rktScheme:GetSchemeInfo(EQUIPSPECIALPROP_CSV, nType, nValue)
						local descTable = split_string(strDesc, ";")
						if specialScheme then 
							local tempTable = {}
							for j = 2, #(specialScheme.DetailItem), 2 do
								table.insert(tempTable, math.floor(specialScheme.DetailItem[j] / 100))
							end
							
							specialDesc = specialDesc..descTable[1]..strSign..tempTable[1].."%，"..descTable[2]..strSign..tempTable[2].."%"
						end
					-- 提升某个技能等级
					elseif nType == CREATURE_PROP_CUR_SKILL_SINGLE then
						local specialScheme = IGame.rktScheme:GetSchemeInfo(EQUIPSPECIALPROP_CSV, nType, value)
						if specialScheme then
							local t = GameHelp:ConvertToDictTable(specialScheme.DetailItem)
							for j = 1, #t do
								local nSkillId = t[j].key
								local nLevel = t[j].value
								local SkillInfo = IGame.rktScheme:GetSchemeInfo(SKILLUPDATE_CSV, nSkillId, nLevel)
								if SkillInfo then
									value = nLevel
									local vocationId = SkillInfo.Voc
									local skillName = SkillInfo.Name
									if vocationId == 0 then 
										vocationName = "真武"..skillName
									elseif vocationId == 1 then 
										vocationName = "灵心"..skillName
									elseif vocationId == 2 then
										vocationName = "天羽"..skillName
									else
										vocationName = "玄宗"..skillName	
									end
								end
							end
						end
					-- 提升全技能等级
					elseif nType == CREATURE_PROP_CUR_SKILL_ALL then
						local specialScheme = IGame.rktScheme:GetSchemeInfo(EQUIPSPECIALPROP_CSV, nType, value)
						if specialScheme then
							local t = GameHelp:ConvertToDictTable(specialScheme.DetailItem)
							local skillId = t[1].key
							local skillLevel = t[1].value
							local voc = IGame.SkillClient:GetSkillVoc(skillId) -- 根据第一个技能来取职业
							value = skillLevel -- 根据第一个技能取等级
							
							if voc == PERSON_VOCATION_ZHENWU then 
								vocationName = "真武"
							elseif voc == PERSON_VOCATION_LINGXIN then 
								vocationName = "灵心"
							elseif voc == PERSON_VOCATION_TIANYU then
								vocationName = "天羽"
							elseif voc == PERSON_VOCATION_XUANZONG then
								vocationName = "玄宗"
							else
								vocationName = "未知"
							end
						end
					end
				end
				
				local desc = strDesc..strSign..value
				if vocationName ~= "" then 
					desc = vocationName..desc
				end 
				
				if specialDesc ~= "" then
					desc =  specialDesc
				end 
				
				local schemeDesc = IGame.rktScheme:GetSchemeInfo(PROPDESC_CSV, prop.descID)
				if schemeDesc then 
					local word = schemeDesc.desc 
					titText =  "【".. word .."】"
					if subDesc ~= "" then
						text = text .. desc..strPerc..subDesc.."\n" 
					else 
						text = text .. desc..strPerc.."\n" 
					end
				else 
					if subDesc ~= "" then
						text = text ..desc..strPerc..subDesc.."\n"
					else 
						text = text ..desc..strPerc.."\n"
					end
				end
			end
		end
		text = string.sub(text, 1, -2)
		local content = self.Controls.m_Additional:GetChild(i-1)
		local titContent = content:Find("Text")
		if IsNilOrEmpty(text) then 
			content.gameObject:SetActive(false)
		
		else
			local contentText = content:GetComponent(typeof(Text))
			local titContentText = titContent:GetComponent(typeof(Text))
			contentText.text = "<color=#"..textColor..">"..text.."</color>"
			titContentText.text = "<color=#"..textColor..">"..titText.."</color>"
			content.gameObject:SetActive(true)
		end
	end
	self.Controls.m_Additional.gameObject:SetActive(false)
	self.Controls.m_Additional.gameObject:SetActive(true)
end

--判断部件的某个槽位孔是否开启
function EquipTooltipsWidget:ChckGemHaveOpen(partID,slotID)
	local nVocation = GetHero():GetNumProp(CREATURE_PROP_VOCATION)	-- 获取职业
	local GemPlaceScheme = IGame.rktScheme:GetSchemeInfo(EQUIPSETTING_CSV , nVocation, partID, slotID)
							or IGame.rktScheme:GetSchemeInfo(EQUIPSETTING_CSV , 10000, partID, slotID)
	local level = GetHero():GetNumProp(CREATURE_PROP_LEVEL)
	if level < GemPlaceScheme.nHeroLV then 
		return false
	else
		return true
	end
	
end

function EquipTooltipsWidget:SetSettingInfo()
	local widget = self.SettingWidget
	local entity = self.entity
	local EquipUID = 0
	local pHero = GetHero()
	if not pHero then
		return
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if self.m_EntityType == 1 then
		widget.transform.gameObject:SetActive(true)
		EquipUID = entity:GetUID()
		local nVocation = GetHero():GetNumProp(CREATURE_PROP_VOCATION)	-- 获取职业
		local equipPart = GetHero():GetEntityPart(ENTITYPART_PERSON_EQUIP)
		if not equipPart then
			return
		end
		
		if equipPart:GetSkepPosByUID(EquipUID) == -1 or EquipUID == zero then
			self.Controls.m_xiangqianTitle.gameObject:SetActive(false)
			widget.transform.gameObject:SetActive(false)
			return
		end

		local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
		if not schemeInfo then
			self.Controls.m_xiangqianTitle.gameObject:SetActive(false)
			widget.transform.gameObject:SetActive(false)
			return
		end
		local equipPlace = schemeInfo.EquipLoc1
		local HoleProp = forgePart:GetHoleProp(equipPlace)
		if not HoleProp then
			return
		end
		local tGemInfo = HoleProp.GemInfo
		local ContentText = ""
		for i=1,6 do
			local SlotTrans = widget.Controls.m_Slots:Find("EmbedSlot ("..i..")")
			local SettedImg = SlotTrans:Find("EmbedImage6")
			local LockImg = SlotTrans:Find("Lock6/image")
			if tGemInfo[i].nGemID == 0 or tGemInfo[i].nGemID == zero then
				local haveOpen = self:ChckGemHaveOpen(equipPlace,i-1)
				if haveOpen == false then 
					SlotTrans.gameObject:SetActive(false)
				else
					ContentText = ContentText.."未镶嵌\n"
					SettedImg.gameObject:SetActive(false)
					SlotTrans.gameObject:SetActive(true)
				end

			else
				local pGoodsInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, tGemInfo[i].nGemID)
				if not pGoodsInfo then
					return
				end
					
				local pGemPropScheme = forgePart.m_SettingCfgCenter:GetGemProp( tGemInfo[i].nGemID, nVocation)
				if not pGemPropScheme then
					return
				end
				local GemName = string.format("%-18s", pGoodsInfo.szName)
				local nGemPropID = pGemPropScheme.nPropID
				local nGemPropNum = pGemPropScheme.nPropNum
				
				ContentText = ContentText..GemName.."  "..GameHelp.PropertyName[nGemPropID].."+"..nGemPropNum.."\n"
				SettedImg.gameObject:SetActive(true)
			end
		end
		widget.Controls.m_ContentText.text = ContentText
		
		self.Controls.m_xiangqianTitle.gameObject:SetActive(true)
	else
		widget.transform.gameObject:SetActive(false)
		self.Controls.m_xiangqianTitle.gameObject:SetActive(false)
	end
end

-- 洗炼
function EquipTooltipsWidget:SetShuffleInfo()
	local widget = self.ShuffleWidget
	local entity = self.entity
	local nConsumeGenNum = 0
	if entity then
		nConsumeGenNum = entity:GetShuffleScore() or 0
		if nConsumeGenNum == 0 then
			widget.transform.gameObject:SetActive(false)
			return
		end
		widget.Controls.m_ContentText.text = "洗炼已消耗洗炼石<color=green>"..nConsumeGenNum.."</color>个"
		widget.transform.gameObject:SetActive(true)
	else
		widget.Controls.m_ContentText.text = ""
		widget.transform.gameObject:SetActive(false)
	end
end


function EquipTooltipsWidget:GetIconBgPath(nQuality, nAdditionalPropNum)
	if  nQuality == 2 then
	if nAdditionalPropNum <= 4 then 
		nAdditionalPropNum = 4
	else 
		nAdditionalPropNum = 5
	end
	elseif nQuality == 3 then 
		if nAdditionalPropNum <= 5 then 
			nAdditionalPropNum = 5
		else 
			nAdditionalPropNum = 6
		end
	elseif nQuality == 4 then
		if nAdditionalPropNum <= 6 then 
			nAdditionalPropNum = 6
		else 
			nAdditionalPropNum = 7
		end	 
	end
	
	if nQuality == 1 then 
		imageBgPath = AssetPath_EquipColor[nQuality]
	else 
		imageBgPath = AssetPath_EquipColor[nQuality.."_"..nAdditionalPropNum]
	end
	
	return imageBgPath
end

-- 没有实体时，装备评分计算方法
function EquipTooltipsWidget:ComputeEquipScore(goodsId, nQuality, attachPropTable)
	local score = 0
	local attachScore = 0
	local basicScore  = 0
	local percent     = 0
	local nAdditionalPropNum = 0
	local addPercent  = false
	if #attachPropTable > 0 then 
	    nAdditionalPropNum = #attachPropTable
	end
    local pEquipBasePropScheme = IGame.rktScheme:GetSchemeInfo(EQUIPBASEPROP_CSV, goodsId, nQuality, nAdditionalPropNum) 
	if not pEquipBasePropScheme then 
		return score
	end
	local propTable = IGame.rktScheme:GetSchemeTable(EQUIPPROPSCORE_CSV)
	if not propTable then
		return score 
	end
	
	-- 技能评分
	local skillScoreTable = IGame.rktScheme:GetSchemeTable(SKILLATTACHPROPSCORE_CSV)
	
	for i = 1, MAX_ADDITIONAL_PROP_NUM do
		local prop = attachPropTable[i]
		if prop ~= nil then
			local nType = prop.nType
			local value = prop.nid
			if nType == CREATURE_PROP_CUR_EQUIP_ENHANCE_PER then 
				percent = percent + value/10000
				addPercent = true
			else
				local pSpecialScoreScheme = IGame.rktScheme:GetSchemeInfo(EQUIPSPECIALPROP_CSV , nType, value)
			    if pSpecialScoreScheme then
					local levelTable = pSpecialScoreScheme.DetailItem
					if levelTable then 
						for k, v in pairs(levelTable) do
							local tValue = v
							local id = k
							if skillScoreTable then 
								if skillScoreTable[tostring(id)] then 
									attachScore = attachScore + tValue * skillScoreTable[tostring(id)].nPropScore
								end
							end
						end
					end
				else 
					if propTable[tostring(nType)] then 
						attachScore = attachScore + value * propTable[tostring(nType)].nScore
					end
				end 	
			end    
		end
	end
	
	for i = 1, 6 do
		local nBaseId = pEquipBasePropScheme["Type"..i]
		local nValue  = pEquipBasePropScheme["Value"..i]
		if propTable[tostring(nBaseId)] then
			if addPercent then 
				basicScore = math.floor(basicScore + nValue*(1 + percent)*propTable[tostring(nBaseId)].nScore)
			else 
				basicScore = basicScore + nValue * propTable[tostring(nBaseId)].nScore 
			end
		end
	end
	
	score = basicScore + attachScore
	return math.floor(score)
end

return this