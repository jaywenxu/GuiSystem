--/******************************************************************
--** 文件名:    ExchangeWindowDefine.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-20
--** 版  本:    1.0
--** 描  述:    交易窗口使用到的相关定义类
--** 应  用:  
--******************************************************************/

SEARCH_TYPE_MINE_COLLECT_ID = 90						-- 搜索类型，我的收藏对应的大类型id:number
SEARCH_TYPE_ALL_GONGSHI_ID = 91							-- 搜索类型，所有公示对应的大类型id:number
MAX_SEARCH_RECORD_SAVE_NUM = 12							-- 最大的搜索记录保存数量:number
SEARCH_RECORD_CACHE_NAME = "SEARCH_RECORD_CACHE_NAME"	-- 搜索记录的缓存名称:string

-- 交易界面右边的页签类型
ExchangeWindowRightTabType = 
{
	TAB_TYPE_BAITAN = "RIGHT_TAB_BAITAN",	-- 摆摊
	TAB_TYPE_PAIMAI = "RIGHT_TAB_PAIMAI",	-- 拍卖
}

-- 交易界面网络回调类型,不想改协议了，客户端本地存这个回调处理类型
ExchangeWindowNetHandleControlType =
{
	HANDLE_TYPE_SHOW_COLLECT = "HANDLE_TYPE_SHOW_COLLECT",				-- 用来显示收藏
	HANDLE_TYPE_CAHENG_TAB_GONGSHI = "HANDLE_TYPE_CAHENG_TAB_GONGSHI",	-- 用来变更公示页签
	HANDLE_TYPE_CHANGE_TAB_COLLECT = "HANDLE_TYPE_CHANGE_TAB_COLLECT",	-- 用来变更收藏页签
}

-- 交易界面网络消息使用类型
EXCHANGE_NET_MSG_USE_TYPE = 
{
	SHOW_WINDOW = 1,			-- 打开界面			
	CAHENG_FOR_BUY = 2,			-- 跳到购买
	CHANGE_FOR_GONGSHI = 3,		-- 跳到公示
	CHANGE_BIG_TYPE = 4,		-- 变更大类型
	CHANGE_SMALL_TYPE = 5,		-- 变更小类型
	CHANGE_LEVEL_ID = 6,		-- 变更登记id
}

-- 交易摆摊界面的子窗口类型
ExchangeBaiTanChildWindowType = 
{
	BUY = "BUY",			-- 购买
	SELL = "SELL",			-- 出售
	GONGSHI = "GONGSHI",	-- 公示
}

SearchTypeData = {}
function SearchTypeData:new()

	return 
	{
		m_BigTypeId = 0,						-- 大类型id:number
		m_BigTypeName = "",						-- 大类型名称:string
		m_CanShowOnBuy = false,					-- 是否可以在购买下显示的标识:boolean
		m_CanShowOnGongShi = false,				-- 是否可以在公示下显示的标识:boolean
		m_ArrSmallTypeId = {},					-- 所有的小类型id:table(number)
		m_ArrSmallTypeName = {},				-- 所有的小类型名称:table(string)
		m_ArrSmallTypeCanGongShi = {},			-- 所有的小类型是否可公示状态:table(boolean)
	}
	
end

SearchSmallTypeLevelData = {}
function SearchSmallTypeLevelData:new()
	
	return 
	{
		m_LevelId = 0,				-- 等级id:number
		m_LevelName = nil,			-- 等级名称:string
		m_LeftLevel = 0,			-- 等级区间最小等级:number
		m_RightLevel = 0,			-- 等级区间最大等级:number
	}
	
end

IntroItemData = {}
function IntroItemData:new()
	
	return 
	{
		m_SortNo = 0,				-- 排序编号:number
		m_Quality = 0,				-- 品质:number
		m_GoodsScheme = nil,		-- 商品配置表:ExchangeGoodsCfg
	}
	
end

BaiTanFuzzySearchData = {}
function BaiTanFuzzySearchData:new()
	
	return 
	{
		m_LastSearchTime = 0,		-- 最近一次搜索的时间:number
		m_BigTypeId = 0,			-- 大类型id:number
		m_SmallTypeId = 0,			-- 小类型id:number
		m_GoodsCfgId = 0,			-- 物品配置id:number
		m_Quality = 0,				-- 物品品质:number
		m_SearchName = "",			-- 搜索名称:string
	}
	
end


-- 搜索类型数据
--[[SearchTypeData = CObject:new
{
	m_BigTypeId = 0,						-- 大类型id:number
	m_BigTypeName = "",						-- 大类型名称:string
	m_CanShowOnBuy = false,					-- 是否可以在购买下显示的标识:boolean
	m_CanShowOnGongShi = false,				-- 是否可以在公示下显示的标识:boolean
	m_ArrSmallTypeId = {},					-- 所有的小类型id:table(number)
	m_ArrSmallTypeName = {},				-- 所有的小类型名称:table(string)
	m_ArrSmallTypeCanGongShi = {},			-- 所有的小类型是否可公示状态:table(boolean)
}

-- 搜索小类型的等级数据
SearchSmallTypeLevelData = CObject:new
{
	m_LevelId = 0,				-- 等级id:number
	m_LevelName = nil,			-- 等级名称:string
	m_LeftLevel = 0,			-- 等级区间最小等级:number
	m_RightLevel = 0,			-- 等级区间最大等级:number
}

-- 介绍图标的数据
IntroItemData = CObject:new
{
	m_SortNo = 0,				-- 排序编号:number
	m_Quality = 0,				-- 品质:number
	m_GoodsScheme = nil,		-- 商品配置表:ExchangeGoodsCfg
}

-- 摆摊搜索记录数据
BaiTanFuzzySearchData = CObject:new
{
	m_LastSearchTime = 0,		-- 最近一次搜索的时间:number
	m_BigTypeId = 0,			-- 大类型id:number
	m_SmallTypeId = 0,			-- 小类型id:number
	m_GoodsCfgId = 0,			-- 物品配置id:number
	m_Quality = 0,				-- 物品品质:number
	m_SearchName = "",			-- 搜索名称:string
}
--]]