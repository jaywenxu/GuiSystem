------------------------------------------------------------
-- ForgeWindow 的子窗口,不要通过 UIManager 访问
-- 镶嵌配置中心
------------------------------------------------------------
local ForgeSettingSchemeCenter = CObject:new
{
	m_GemPropMap = {},				-- 宝石信息表
	m_GemTypeMap_KeyGemID = {},		-- 宝石类型表 (以宝石ID为Key)
	m_GemTypeMap_KeyGemLv = {},		-- 宝石类型表 (以宝石Lv为Key)
	m_GemLvMap_KeyGemID = {},		-- 宝石等级表 (以宝石ID为Key)
    m_GemPropIDMap_KeyGemType = {}, -- 宝石属性ID表 (以宝石Type为Key)
	
	m_GemIDList = {},				-- 宝石ID表 (以宝石ID为Key)
	m_bLoadedCsv = false,			-- 是否已加载配置
}

local this = ForgeSettingSchemeCenter   -- 方便书写
local zero = int64.new("0")

function ForgeSettingSchemeCenter:Init()
	self:LoadedEquipGemPropCsv()
end


function ForgeSettingSchemeCenter:LoadedEquipGemPropCsv()
	if self.m_bLoadedCsv then
		return true
	end
	
	local tEquipGemProp = IGame.rktScheme:GetSchemeTable(EQUIPGEMPROP_CSV)
	if not tEquipGemProp then
		return false
	end
	local pHero = GetHero()
	if pHero == nil then
		return
	end

	local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)	-- 获取职业
	for i,v in pairs(tEquipGemProp) do
		if v.nVocation == 10000 or nVocation == v.nVocation then
			local Key = tostring(v.nGoodID)..tostring(v.nVocation)
			self.m_GemPropMap[Key] = v		-- 填充宝石信息表
			
			local nGemType = v.nGemType
			local nGemLv = v.nGemLv
			local nGemID = v.nGoodID

			self.m_GemTypeMap_KeyGemID[nGemType] = self.m_GemTypeMap_KeyGemID[nGemType] or {}
			self.m_GemTypeMap_KeyGemID[nGemType][nGemID] = nGemLv
			
			self.m_GemTypeMap_KeyGemLv[nGemType] = self.m_GemTypeMap_KeyGemLv[nGemType] or {}
			self.m_GemTypeMap_KeyGemLv[nGemType][nGemLv] = nGemID
			
			self.m_GemLvMap_KeyGemID[nGemLv] = self.m_GemLvMap_KeyGemID[nGemLv] or {}
			self.m_GemLvMap_KeyGemID[nGemLv][nGemID] = nGemType
            
            local typeKey = tostring(nGemType)..tostring(v.nVocation)
            self.m_GemPropIDMap_KeyGemType[typeKey] = v.nPropID
			
			self.m_GemIDList[nGemID] = 1
		end
		
	end
end

function ForgeSettingSchemeCenter:GetGemProp(GemGoodID,nVocation)
	local Key = tostring(GemGoodID)..tostring(nVocation)
	local GemProp = self.m_GemPropMap[Key]
	if GemProp then
		return GemProp
	end
	
	Key = tostring(GemGoodID)..tostring(10000)
	GemProp = self.m_GemPropMap[Key]
	return GemProp
end

function ForgeSettingSchemeCenter:GetGemType_KeyGemID(nGemType)
	return self.m_GemTypeMap_KeyGemID[nGemType]
end

function ForgeSettingSchemeCenter:GetGemType_KeyGemLv(nGemType)
	return self.m_GemTypeMap_KeyGemLv[nGemType]
end

function ForgeSettingSchemeCenter:GetGemLv_KeyGemLv(nGemLv)
	return self.m_GemLvMap_KeyGemID[nGemLv]
end

function ForgeSettingSchemeCenter:IsGemByID(GoodID)
	return self.m_GemIDList[GoodID] == 1
end

function ForgeSettingSchemeCenter:GetGemPropID_KeyGemType_KeyVocation(nGemType, nVocation)
    local Key = tostring(nGemType)..tostring(nVocation)
	local GemPropID = self.m_GemPropIDMap_KeyGemType[Key]
	if GemPropID then
		return GemPropID
	end
	
	Key = tostring(nGemType)..tostring(10000)
	GemPropID = self.m_GemPropIDMap_KeyGemType[Key]
	return GemPropID
end










return this