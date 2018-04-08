--/******************************************************************
---** 文件名:	ExchangeWindowTool.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-21
--** 版  本:	1.0
--** 描  述:	存放交易界面用到的一些与ExchangeClient数据无关的方法
--** 应  用:  
--******************************************************************/

require("GuiSystem.WindowList.Exchange.ExchangeWindowDefine")

ExchangeWindowTool = {}

-- 获取模糊搜索匹配到的数据
-- @searchName:要搜索的名称:string
-- return:模糊搜索数据列表:table(BaiTanFuzzySearchData) or nil
function ExchangeWindowTool.GetFuzzySearchNameResultData(searchName)
	
	local listAllGoodsScheme = IGame.rktScheme:GetSchemeTable(EXCHANGE_GOODS_CSV)
	if not listAllGoodsScheme then
		return nil
	end
	
	local listSearchResult = {}
	local haveFindOneMatchGoods = false
	for k,v in pairs(listAllGoodsScheme) do
		if searchName == v.name or string.find(v.name, searchName) ~= nil then
			if v.class == GOODS_CLASS_EQUIPMENT then -- 装备
				for qk,qv in pairs(v.color) do
					local fuzzyData  = BaiTanFuzzySearchData:new()
					fuzzyData.m_BigTypeId = v.class
					fuzzyData.m_SmallTypeId = v.subClass
					fuzzyData.m_GoodsCfgId = v.goodsID
					fuzzyData.m_Quality = qv
					fuzzyData.m_SearchName = v.name
					
					table.insert(listSearchResult, fuzzyData)
					haveFindOneMatchGoods = true
				end
			else 
				local leechdomScheme = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, v.goodsID)
				if leechdomScheme then
					local fuzzyData  = BaiTanFuzzySearchData:new()
					fuzzyData.m_BigTypeId = v.class
					fuzzyData.m_SmallTypeId = v.subClass
					fuzzyData.m_GoodsCfgId = v.goodsID
					fuzzyData.m_Quality = leechdomScheme.lBaseLevel
					fuzzyData.m_SearchName = v.name
					
					table.insert(listSearchResult, fuzzyData)
					haveFindOneMatchGoods = true
				end	
			end
		end
	end

	if not haveFindOneMatchGoods then 
		return nil
	end

	return listSearchResult
	
end

-- 获取精度搜索数据
-- @searchName:要搜索的名称:string
-- return:搜索结果数据:BaiTanFuzzySearchData or nil
function ExchangeWindowTool.GetSearchNameResultData(searchName)
	
	local listAllGoodsScheme = IGame.rktScheme:GetSchemeTable(EXCHANGE_GOODS_CSV)
	if not listAllGoodsScheme then
		return nil
	end
	
	local scheme = nil
	for k,v in pairs(listAllGoodsScheme) do
		if v.name == searchName then
			scheme = v
			break
		end
	end
	
	if scheme == nil then
		return nil
	end
	
	local fuzzyData  = BaiTanFuzzySearchData:new()
	fuzzyData.m_BigTypeId = scheme.class
	fuzzyData.m_SmallTypeId = scheme.subClass
	fuzzyData.m_GoodsCfgId = scheme.goodsID
	fuzzyData.m_SearchName = scheme.name

	-- 装备的品质为最低上架品质
	if 	scheme.class == GOODS_CLASS_EQUIPMENT then
		for clrIdx = 1, #scheme.color do
			fuzzyData.m_Quality = scheme.color[clrIdx]
			break
		end
	else 
		local leechdomScheme = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, scheme.goodsID)
		if leechdomScheme then
			fuzzyData.m_Quality = leechdomScheme.lBaseLevel
		end
	end

	return fuzzyData
	
end

-- 获取所有的搜索类型数据
-- return:搜索类型数据列表:table(SearchTypeData)
function ExchangeWindowTool.GetAllSearchTypeData()
	local listAllGoodsScheme = IGame.rktScheme:GetSchemeTable(EXCHANGE_GOODS_CSV)
	if not listAllGoodsScheme then
		return nil
	end
	
	local listAllTypeData = {}
	-- 存所有的类型数据
	for k,v in pairs(listAllGoodsScheme) do
		local typeData = listAllTypeData[v.class]
		
		if typeData == nil then
			typeData = SearchTypeData:new()
			typeData.m_BigTypeId = v.class
			typeData.m_BigTypeName = v.className
			typeData.m_CanShowOnGongShi = false
			typeData.m_CanShowOnBuy = true
			
			listAllTypeData[v.class] = typeData
		end
		
		if v.subClass > 0 and typeData.m_ArrSmallTypeName[v.subClass] == nil then
			typeData.m_ArrSmallTypeId[v.subClass] = v.subClass
			typeData.m_ArrSmallTypeName[v.subClass] = v.subClassName
			typeData.m_ArrSmallTypeCanGongShi[v.subClass] = false
		end
		
		-- 公示状态要不要显示判断
		for kg,vg in pairs(v.isPublicity) do
			if vg ~= 0 then
				typeData.m_CanShowOnGongShi = true
				
				if v.subClass > 0 then
					typeData.m_ArrSmallTypeCanGongShi[v.subClass] = true
				end
				
				break
			end
		end
	end

	-- 排序大类型
	local tableSortBigType = {}
	for k,v in pairs(listAllTypeData) do
		table.insert(tableSortBigType, k)
	end
	
	table.sort(tableSortBigType)
	
	local listAllTypeDataSort = {}
	for dataIdx = 1, #tableSortBigType do
		local bigTypeId = tableSortBigType[dataIdx]
		local data = listAllTypeData[bigTypeId]
		
		-- 排序小类型
		local tableSortSmallType = {}
		for k,v in pairs(data.m_ArrSmallTypeId) do
			table.insert(tableSortSmallType, v)
		end
		
		table.sort(tableSortSmallType)
		
		local listAllSmallIdSort = {}
		local listAllSmallNameSort = {}
		for subIdx = 1, #tableSortSmallType do
			local smallTypeId = tableSortSmallType[subIdx]
			local smallTypeName = data.m_ArrSmallTypeName[subIdx]
			
			table.insert(listAllSmallIdSort, smallTypeId)
			table.insert(listAllSmallNameSort, smallTypeName)
		end
		
		data.m_ArrSmallTypeId = listAllSmallIdSort
		data.m_ArrSmallTypeName = listAllSmallNameSort
		
		table.insert(listAllTypeDataSort, data)
	end
	
	return listAllTypeDataSort
	
end

-- 获取小类型所有的等级数据
-- @bigTypeId:要找的大类型id:number
-- @smallTypeId:要找的等级对应的小类型id:number
-- return:等级数据列表:table(SearchSmallTypeLevelData) or nil
function ExchangeWindowTool.GetSmallTypeAllLevelData(bigTypeId, smallTypeId)

	local listAllGoodsScheme = IGame.rktScheme:GetSchemeTable(EXCHANGE_GOODS_CSV)
	if not listAllGoodsScheme then
		return nil
	end
	
	local listLevelData = nil
	for k,v in pairs(listAllGoodsScheme) do
		if v.class == bigTypeId and v.subClass == smallTypeId then
			if not listLevelData then
				listLevelData = {}
			end
			
			local levelData = listLevelData[v.level]

			if levelData == nil and v.level > 0 then
				levelData = SearchSmallTypeLevelData:new()
				levelData.m_LevelId = v.level
				levelData.m_LeftLevel = v.leftLevel
				levelData.m_RightLevel = v.rightLevel
				levelData.m_LevelName = v.levelName
				
				listLevelData[v.level] = levelData
			end
		end
	end
	
	if not listLevelData then
		return nil
	end
	
	-- 排序
	local tableSortData = {}
	for k,v in pairs(listLevelData) do
		table.insert(tableSortData, k)
	end
	
	table.sort(tableSortData)
	local listLevelDataSort = {}
	for dataIdx = 1, #tableSortData do
		local levelId = tableSortData[dataIdx]
		local levelData = listLevelData[levelId]
		
		table.insert(listLevelDataSort, levelData)
	end
	
	return listLevelDataSort
	
end

-- 获取小类型的介绍数据
-- @bigTypeId:大类型id:number
-- @smallTypeId:小类型id:number
-- @levelId:等级id:number
-- @onlyGongShi:是否只显示公示的标识:boolean
-- return:介绍数据列表:table(IntroItemData)
function ExchangeWindowTool.GetSmallTypeRowIntroData(bigTypeId, smallTypeId, levelId, onlyGongShi)
	
	local listAllGoodsScheme = IGame.rktScheme:GetSchemeTable(EXCHANGE_GOODS_CSV)
	if not listAllGoodsScheme then
		return {}
	end
	
	-- 筛选要显示的商品
	local listGoodsScheme = {} -- table(sortNo, IntroItemData)
	for k,v in pairs(listAllGoodsScheme) do
		if v.class == bigTypeId and v.subClass == smallTypeId then
			if bigTypeId == GOODS_CLASS_EQUIPMENT then  -- 装备
				if levelId == v.level then
					for ke,va in pairs(v.color) do
						local canShow = true
						
						-- 公示判断
						if onlyGongShi then
							canShow = false
							for kg, vg in pairs(v.isPublicity) do
								if vg == va then
									canShow = true
									break
								end
							end
						end
						
						if canShow then
							local introData = IntroItemData:new()
							introData.m_SortNo = v.index * 10 + va
							introData.m_Quality = va
							introData.m_GoodsScheme = v
							
							listGoodsScheme[introData.m_SortNo] = introData	
						end
					end
				end
			else
				local canShow = true
				
				-- 公示判断
				if onlyGongShi then
					canShow = false
					for kg, vg in pairs(v.isPublicity) do
						if vg > 0 then
							canShow = true
							break
						end
					end
				end
				
				if canShow then
					local introData = IntroItemData:new()
					introData.m_SortNo = v.index * 10
					introData.m_Quality = 0
					introData.m_GoodsScheme = v
					
					listGoodsScheme[introData.m_SortNo] = introData
				end
			end
		end
	end

	-- 排序
	local tableSortGoods = {} -- table(sortNo)
	for k,v in pairs(listGoodsScheme) do
		table.insert(tableSortGoods, v.m_SortNo)
	end
		
	table.sort(tableSortGoods)
	
	-- 数据整理
	local listRowIntroData = {}
	local tableIdx = 1
	local tableDataIdx = 1
	for dataIdx = 1, #tableSortGoods do
		local sortNo = tableSortGoods[dataIdx]
		local introData = listGoodsScheme[sortNo]
		
		if not listRowIntroData[tableIdx] then
			listRowIntroData[tableIdx] = {}
		end
		
		listRowIntroData[tableIdx][tableDataIdx] = introData
		
		tableDataIdx = tableDataIdx + 1
		if tableDataIdx > 2 then
			tableIdx = tableIdx + 1
			tableDataIdx = 1
		end
	end

	return listRowIntroData
	
end

-- 检查玩家在指定分类下对应的等级id
-- return:等级id:number
function ExchangeWindowTool.CheckPlayerLevelId()
	
	local listLevelData = ExchangeWindowTool.GetSmallTypeAllLevelData(GOODS_CLASS_EQUIPMENT, 1)
	if not listLevelData then
		return 0
	end
	
	local hero = GetHero()
	if not hero then
		return bigTypeId, smallTypeId, levelId
	end
	
	local heroLevel = hero:GetNumProp(CREATURE_PROP_LEVEL)
	local secondLevelId = nil
	for k,v in pairs(listLevelData) do
		if secondLevelId == nil then
			secondLevelId = v.m_LevelId
		end
		
		if heroLevel >= v.m_LeftLevel and heroLevel <= v.m_RightLevel then
			return v.m_LevelId
		end
	end
	
	return secondLevelId
	
end

-- 加载搜索记录数据
-- return:搜索记录数据列表:table(BaiTanFuzzySearchData)
function ExchangeWindowTool.LoadSearchRecord()
	
	local listSearchRecord = {}
	--PlayerPrefs.DeleteKey(SEARCH_RECORD_CACHE_NAME)
	local recordStr = PlayerPrefs.GetString(SEARCH_RECORD_CACHE_NAME) 
	if recordStr == nil or recordStr == "" then
		return listSearchRecord
	end
	
	local strLen = #recordStr
	local searchData = nil
	local lastStr = ""
	local propertyIdx = 1
	for charIdx = 1, strLen do
		if searchData == nil then
			searchData = BaiTanFuzzySearchData:new()
			searchData.m_LastSearchTime = Time.realtimeSinceStartup - charIdx * 0.1
			propertyIdx = 1
			lastStr = ""
			table.insert(listSearchRecord, searchData)
		end
		
		local char = string.sub(recordStr, charIdx, charIdx)
		
		if char == ' ' or char == '^' then -- 空格或^表示变换字段
			if propertyIdx == 1 then
				searchData.m_BigTypeId = tonumber(lastStr)
			elseif propertyIdx == 2 then
				searchData.m_SmallTypeId = tonumber(lastStr)
			elseif propertyIdx == 3 then
				searchData.m_GoodsCfgId = tonumber(lastStr)
			elseif propertyIdx == 4 then
				searchData.m_Quality = tonumber(lastStr)
			elseif propertyIdx == 5 then
				searchData.m_SearchName = lastStr
			end
			
			-- ^表示新的记录
			if char == '^' then
				searchData = nil
			else 
				lastStr = ""
				propertyIdx = propertyIdx + 1
			end
		else 
			lastStr = lastStr .. char
		end
	end
	
	return listSearchRecord
	
end

-- 缓存搜索记录
-- @listSearchRecord:搜索记录列表:table(BaiTanFuzzySearchData)
function ExchangeWindowTool.CacheSearchRecord(listSearchRecord)
	
	local tableSort = {}
	local tableSortTime = {}
	
	-- 排序,最大的时间显示在最前面
	for k,v in pairs(listSearchRecord) do
		table.insert(tableSort, -v.m_LastSearchTime)
		tableSortTime[-v.m_LastSearchTime] = v
	end

	table.sort(tableSort)
	
	local str = ""
	for dataIdx = 1, #tableSort do
		local recordTime = tableSort[dataIdx]
		local recordData = tableSortTime[recordTime]
		
		str = str .. string.format("%s %s %s %s %s^", recordData.m_BigTypeId, recordData.m_SmallTypeId, 
			recordData.m_GoodsCfgId, recordData.m_Quality, recordData.m_SearchName)
	end
	
	--[[for k,v in pairs(listSearchRecord) do
		str = str .. string.format("%s %s %s %s %s^", v.m_BigTypeId, v.m_SmallTypeId, v.m_GoodsCfgId, v.m_Quality, v.m_SearchName)
	end
	--]]
	PlayerPrefs.SetString(SEARCH_RECORD_CACHE_NAME, str)
	PlayerPrefs.Save()
	
end

-- 点击实体图标
-- @entity:实体:Equipment ...
-- @tfItem:图标变换:Transform
function ExchangeWindowTool.ClickEntityItem(entity, tfItem)
	
	if not entity then
		return
	end
	
	local cfgId = entity:GetNumProp(GOODS_PROP_GOODSID)
	local entityClass = entity:GetEntityClass()
	if EntityClass:IsEquipment(entityClass) then
		local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, cfgId)
		if not schemeInfo then
			return
		end
		
		-- 武学
		if schemeInfo.GoodsSubClass == EQUIPMENT_SUBCLASS_BATTLEBOOK then
			UIManager.WuXueDetailWindow:ShowForOther(entity.m_uid)
		else 
			local subInfo = {
				bShowBtn = 0,
				bShowCompare = true,
				bRightBtnType = 3,
			}
			UIManager.EquipTooltipsWindow:Show(true)
            UIManager.EquipTooltipsWindow:SetEntity(entity, subInfo)
		end
	else
		local subInfo = {
			bShowBtnType	= 0, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
			ScrTrans = tfItem,	-- 源预设
		}
		UIManager.GoodsTooltipsWindow:Show(true)
        UIManager.GoodsTooltipsWindow:SetGoodsInfo(cfgId, subInfo )
	end
end

-- 判断物品是否可以上架
-- @entity:物品实例
-- return:是否可以上架:boolean
function ExchangeWindowTool.CheckGoodsCanPut(entity)
	
	if not entity then
		return false 
	end

	local isBind = entity:GetNumProp(GOODS_PROP_NO_BIND_QTY) < 1
	if isBind then
		return false
	end

	local cfgId = entity:GetNumProp(GOODS_PROP_GOODSID)
	local goodsScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_GOODS_CSV, cfgId)
	if not goodsScheme then
		return false
	end
	
	-- 装备要判断品质
	if EntityClass:IsEquipment(entity:GetEntityClass()) then
		local nQuality  = entity:GetNumProp(EQUIP_PROP_QUALITY)
		for k,v in pairs(goodsScheme.color) do
			if v == nQuality then
				return true
			end
		end
		
		return false
	end
	
	return true
	
end

-- 获取第一个匹配的搜索类型数据	
-- return:大类型id:number
--		 :小类型id:number
--		 :等级id:number
--[[function ExchangeWindowTool.GetTheFirstMatchSearchTypeData()
	
	local bigTypeId = 0
	local smallTypeId = 0
	local levelId = 0
	
	local listBigTypeData = ExchangeWindowTool.GetAllSearchTypeData()
	if not listBigTypeData then
		return bigTypeId, smallTypeId, levelId
	end
	
	for k,v in pairs(listBigTypeData) do
		bigTypeId = v.m_BigTypeId
		
		if #v.m_ArrSmallTypeId < 1 then
			smallTypeId = 0
		else
			for sk,sv in pairs(v.m_ArrSmallTypeId) do
				smallTypeId = sv
				break
			end
		end
		
		break
	end
	
	-- 装备分类
	if bigTypeId == GOODS_CLASS_EQUIPMENT then
		-- 等级id
		local hero = GetHero()
		if not hero then
			return bigTypeId, smallTypeId, levelId
		end
		
		local heroLevel = hero:GetNumProp(CREATURE_PROP_LEVEL)
		levelId = ExchangeWindowTool.CheckPlayerLevelId(bigTypeId, smallTypeId, heroLevel)
	end

	-- 道具分类
	if bigTypeId == GOODS_CLASS_LEECHDOM then
		levelId = 0
	end
	
	return bigTypeId, smallTypeId, levelId
	
end--]]

-- 获取装备名字颜色的字符串
-- @quality:品质:number
-- @addition:附加属性数量:number
-- return:16进制的颜色
function ExchangeWindowTool.GetEquipNameColorStr(quality, additional)
	
	local signColor = DColorDef.getNameColor(1,quality,additional)
	return string.sub(signColor, 1, #signColor-2)
	
end

-- 获取实体的名字颜色
-- @entity:实体:Equipment ...
-- return:16进制的颜色名
function ExchangeWindowTool.GetEntityNameColorStr(entity)

	local cfgId = entity:GetNumProp(GOODS_PROP_GOODSID)

	-- 装备
	if EntityClass:IsEquipment(entity:GetEntityClass()) then
		local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, cfgId)
		if not schemeInfo then
			return "FFFFFF"
		end
		
		local nQuality  = entity:GetNumProp(EQUIP_PROP_QUALITY)
		local nAdditionalPropNum = entity:GetAdditionalPropNum()
	        
		-- 武学书
		if schemeInfo.GoodsSubClass == EQUIPMENT_SUBCLASS_BATTLEBOOK then
			local battleBookInfo = entity:GetBattleBookProp()
			if battleBookInfo then
				nQuality = battleBookInfo.quality or 1
			end
			
			nAdditionalPropNum = 0
			local battleBookScheme = IGame.rktScheme:GetSchemeInfo(BATTLE_BOOK_UPGRADE_CSV, cfgId, battleBookInfo.level)
			if battleBookScheme then
				for i,v in pairs(battleBookScheme.Property) do
					nAdditionalPropNum = nAdditionalPropNum + 1
				end
			end
		end
		
		return ExchangeWindowTool.GetEquipNameColorStr(nQuality, nAdditionalPropNum)
	end

	-- 物品
	if EntityClass:IsLeechdom(entity:GetEntityClass()) then
		local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, cfgId)
		if not schemeInfo then
			return "FFFFFF"
		end
		
		return UIFunction.GetQualityHexadecimalColor(schemeInfo.lBaseLevel)
	end
	
	return "FFFFFF"
	
end

-- 设置实体的文本名字
-- @entity:实体:Equipment ...
-- @text:文本组件:Text
-- @isLeechdomDefault:道具是否要使用默认颜色:boolean
function ExchangeWindowTool.SetEntityTextLabel(entity, text, isLeechdomDefault)
	
	local cfgId = entity:GetNumProp(GOODS_PROP_GOODSID)
	
	-- 装备
	if EntityClass:IsEquipment(entity:GetEntityClass()) then
		
		local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, cfgId)
		if not schemeInfo then
			return
		end
		
		local nQuality  = entity:GetNumProp(EQUIP_PROP_QUALITY)
		local nAdditionalPropNum = entity:GetAdditionalPropNum()
	        
		-- 武学书
		if schemeInfo.GoodsSubClass == EQUIPMENT_SUBCLASS_BATTLEBOOK then
			text.text = schemeInfo.szName
			text.color = UIFunction.ConverRichColorToColor(ExchangeWindowTool.GetEntityNameColorStr(entity))
			
			return
		end
		
		text.text = GameHelp.GetEquipName(nQuality, nAdditionalPropNum, schemeInfo.szName)
		text.color = UIFunction.ConverRichColorToColor(ExchangeWindowTool.GetEntityNameColorStr(entity))

		return 
	end

	-- 物品
	if EntityClass:IsLeechdom(entity:GetEntityClass()) then
		local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, cfgId)
		if not schemeInfo then
			return
		end

		text.text = schemeInfo.szName
		
		if isLeechdomDefault then
			text.color = UIFunction.ConverRichColorToColor("15424C")
		else 
			text.color = UIFunction.GetQualityColor(schemeInfo.lBaseLevel)
		end
	
		return
	end
	
end	

-- 设置商品的图标和背景图
-- @imageIcon:图标组件:Image
-- @imageBg:底框组件:Image
-- @goodsCfgId:商品配置id:number
-- @quality:商品品质:number
-- @attrNum:商品属性数量:number
function ExchangeWindowTool.SetGoodsIconAndBg(imageIcon, imageBg, goodsCfgId, quality, attrNum)
	
	local goodsScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_GOODS_CSV, goodsCfgId)
	if not goodsScheme then
		return
	end
	
	-- 装备
	if goodsScheme.class == GOODS_CLASS_EQUIPMENT  then
		local equipScheme = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, goodsCfgId)
		if not equipScheme then
			return
		end
		
		local bgPath = GameHelp.GetEquipImageBgPath(quality, attrNum)
		if not bgPath then
			return
		end
		
		UIFunction.SetImageSprite(imageIcon, AssetPath.TextureGUIPath..equipScheme.IconIDNormal)
		UIFunction.SetImageSprite(imageBg, bgPath)
		
		return
	end

	local leechdomScheme = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodsCfgId)
	if not leechdomScheme then
		return
	end
	
	UIFunction.SetImageSprite(imageIcon, AssetPath.TextureGUIPath..leechdomScheme.lIconID1)
	UIFunction.SetImageSprite(imageBg, AssetPath.TextureGUIPath..leechdomScheme.lIconID2)
	
end

-- 获取商品带颜色格式的名称
-- @goodsCfgId:商品配置id:number
-- @quality:商品品质:number
-- @attrNum:商品属性数量:number
-- return:带颜色的名字:string
function ExchangeWindowTool.GetGoodsColorFormateName(goodsCfgId, quality, attrNum)
	
	local goodsScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_GOODS_CSV, goodsCfgId)
	if not goodsScheme then
		return
	end
	
	local colorStr = UIFunction.GetQualityHexadecimalColor(qualityType)
	local cfgName = goodsScheme.name
	
	-- 装备
	if goodsScheme.class == GOODS_CLASS_EQUIPMENT  then
		local equipScheme = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, goodsCfgId)
		if not equipScheme then
			return
		end
		
		cfgName = GameHelp.GetEquipName(quality, attrNum, equipScheme.szName)
		colorStr = ExchangeWindowTool.GetEquipNameColorStr(quality, attrNum)
	else 
		local leechdomScheme = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodsCfgId)
		if leechdomScheme ~= nil then
			colorStr = UIFunction.GetQualityHexadecimalColor(leechdomScheme.lBaseLevel)
		end
	end
	
	return string.format("<color=#%s>%s</color>", colorStr, cfgName)
	
end

-- 设置商品的名字文本
-- @text:文本组件:Text
-- @goodsCfgId:商品配置id:number
-- @quality:商品品质:number
-- @attrNum:商品属性数量:number
-- @isLeechdomDefault:道具是否要使用默认颜色:boolean
-- @isCut:是否截断
function ExchangeWindowTool.SetGoodsNameLabel(text, goodsCfgId, quality, attrNum, isLeechdomDefault, isCut)
	
	local goodsScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_GOODS_CSV, goodsCfgId)
	if not goodsScheme then
		return
	end
	
	-- 装备
	if goodsScheme.class == GOODS_CLASS_EQUIPMENT  then
		local equipScheme = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, goodsCfgId)
		if not equipScheme then
			return
		end
		
		local szNameTemp = GameHelp.GetEquipName(quality, attrNum, equipScheme.szName)
		if isCut then
			if utf8.len(szNameTemp) > 6 then
				szNameTemp = utf8.sub(szNameTemp, 1, 7)
				szNameTemp = szNameTemp .. "..."
			end
		end
		text.text = szNameTemp
		
		text.color = UIFunction.ConverRichColorToColor(ExchangeWindowTool.GetEquipNameColorStr(quality, attrNum))
		
		return
	end

	local leechdomScheme = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodsCfgId)
	if not leechdomScheme then
		return
	end
	
	local szNameTemp = leechdomScheme.szName
	if isCut then
		if utf8.len(szNameTemp) > 6 then
			szNameTemp = utf8.sub(szNameTemp, 1, 7)
			szNameTemp = szNameTemp .. "..."
		end
	end
	text.text = szNameTemp

	
	text.color = UIFunction.GetQualityColor(leechdomScheme.lBaseLevel)
	
end

-- 设置商品的数量文本
-- @text:数量文本组件:Text
-- @goodsCfgId:商品配置id:number
-- @num:商品数量:number
function ExchangeWindowTool.SetGoodsNumLabel(text, goodsCfgId, num)
	
	local goodsScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_GOODS_CSV, goodsCfgId)
	if not goodsScheme then
		return
	end

	-- 装备
	if goodsScheme.class == GOODS_CLASS_EQUIPMENT  then
		text.text = ""
		return
	end
	
	if num <= 1 then
		text.text = ""
	else 
		text.text = string.format("%d", num)
	end
	
end

-- 计算装备的推荐价格
-- @equipCfgId:装备配置表id:number
-- @quality:装备品质:number
-- @attrNum:装备属性数量:number
-- return:返回装备的价格
function ExchangeWindowTool.CalcEquipSuggetPrice(equipCfgId, quality, attrNum)
	
	local listAllEquipPriceCfg = IGame.rktScheme:GetSchemeTable(EXCHANGE_EQUIP_CSV)
	if not listAllEquipPriceCfg then
		uerror("没有装备价格配置表！")
		return
	end
	
	for k,v in pairs(listAllEquipPriceCfg) do
		if v.goodsID == equipCfgId and v.nColor == quality and attrNum >= v.minProNum and attrNum <= v.maxProNum then
			return v.nPrice
		end
	end
	
	return 0
end









