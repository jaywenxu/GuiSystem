--/******************************************************************
--** 文件名:    BaiTanBuyBigTypeItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-19
--** 版  本:    1.0
--** 描  述:    交易窗口-摆摊部件-搜索部件-大类型图标
--** 应  用:  
--******************************************************************/

local BaiTanBuySmallTypeItem = require("GuiSystem.WindowList.Exchange.BaiTanBuySmallTypeItem")

local BaiTanBuyBigTypeItem = UIControl:new
{
    windowName = "BaiTanBuyBigTypeItem",
	
	m_IsSmallTypeItemOnCreate = false,		-- 是否在创建小图标期间:boolean
	m_IsInUnfold = false,					-- 是否在展开状态的标识:boolean
	m_ShowForGongShi = false,				-- 是否在公示下显示的标识:boolean
	m_IsInSelected = false,					-- 是否在选中的标识:boolean
	
	m_BigTypeData = nil,					-- 大类型数据:SearchTypeData
	m_ListSmallTypeItem = {},				-- 所有的小类型图标实例脚本:table(BaiTanBuySmallTypeItem)
}

local BIG_TYPE_BTN_HEIGHT = 103					-- 大图标按钮的高度:number
local SMALL_TYPE_BTN_HEIGHT = 89.5				-- 小图标按钮的高度:number
local SMALL_TYPE_BTN_LAYOUT_SPACE = 1.5			-- 小图标的间距:number
local BIG_TYPE_BTN_DIST_TO_SMALL_LAYOUT = 4		-- 大图标与第一个小图标的间距:number
local SMALL_TYPE_BTN_TO_BIG_TYPE = 12			-- 小图标与下一个大图标的间距

function BaiTanBuyBigTypeItem:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	self.onItemClick = function() self:OnItemClick() end
	self.Controls.m_ButtonBigType.onClick:AddListener(self.onItemClick)
	
end

-- 更新图标
-- @theSelectedBigTypeId:当前选中的大类型id:number
-- @theSelectedSmallTypeId:当前选中的小类型id:number
-- @widgetInFlod:窗口是否在收拢状态:boolean
-- @showForGongShi:是否在公示下显示的标识:boolean
function BaiTanBuyBigTypeItem:UpdateItem(theSelectedBigTypeId, theSelectedSmallTypeId, widgetInFlod, showForGongShi)
	
	local bigTypeData = self.m_BigTypeData
	
	self.m_IsInSelected = theSelectedBigTypeId == bigTypeData.m_BigTypeId
	self.m_IsInUnfold = not widgetInFlod and self.m_IsInSelected
	self.m_ShowForGongShi = showForGongShi
	
	-- 如果不显示，就直接隐藏
	if (self.m_ShowForGongShi and not bigTypeData.m_CanShowOnGongShi) or 
		(not self.m_ShowForGongShi and not bigTypeData.m_CanShowOnBuy) then
			
		self.transform.gameObject:SetActive(false)
		
		return 
	end
	
	self.transform.gameObject:SetActive(true)
	
	-- 状态状态
	if self.m_IsInSelected then
		UIFunction.SetImageSprite(self.Controls.m_ImageBgBigType, AssetPath.TextureGUIPath.."Common_frame/Common_button_biaoqianye_2.png")
		self.Controls.m_TextBigTypeName.color = UIFunction.ConverRichColorToColor("AD4534")
	else 
		UIFunction.SetImageSprite(self.Controls.m_ImageBgBigType, AssetPath.TextureGUIPath.."Common_frame/Common_button_biaoqianye_1.png")
		self.Controls.m_TextBigTypeName.color = UIFunction.ConverRichColorToColor("597993")
	end

	self.Controls.m_TextBigTypeName.text = bigTypeData.m_BigTypeName
	
	-- 小图标更新
	local itemIdx = 1
	for k,v in pairs(bigTypeData.m_ArrSmallTypeId) do
		
		local smallTypeItem = self.m_ListSmallTypeItem[itemIdx]
		local smallTypeName = bigTypeData.m_ArrSmallTypeName[v]
		local isSelected = self.m_IsInSelected and theSelectedSmallTypeId == v
		local canShow = not self.m_ShowForGongShi or (self.m_ShowForGongShi and bigTypeData.m_ArrSmallTypeCanGongShi[v])
		
		smallTypeItem.transform.gameObject:SetActive(canShow)
		
		if canShow then
			smallTypeItem:UpdateItem(bigTypeData.m_BigTypeId, v, smallTypeName, isSelected)
		end
		
		itemIdx = itemIdx + 1
	end
	
	-- 更新图标的高度
	self:UpdateItemHeight()
	
end

-- 创建所有的小图标
-- @bigTypeData:大类型数据:SearchTypeData
function BaiTanBuyBigTypeItem:CreateAllSmallTypeItem(bigTypeData)

	if self.m_IsSmallTypeItemOnCreate then
		return
	end

	local smallTypeCnt = 0
	for k,v in pairs(bigTypeData.m_ArrSmallTypeName) do
		smallTypeCnt = smallTypeCnt + 1
	end

	self.m_BigTypeData = bigTypeData
	self.m_IsSmallTypeItemOnCreate = true

	-- 没有小分类
	if smallTypeCnt < 1 then
		rktEventEngine.FireExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCHANGE_UI_EVENT_ON_LAST_SMALL_TYPE_ITEM_CREATE_SUCC)
		return
	end
	
	for typeIdx = 1, #bigTypeData.m_ArrSmallTypeName do
		self.m_ListSmallTypeItem[typeIdx] = BaiTanBuySmallTypeItem:new()
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.Exchange.BaiTanBuySmallTypeItem,
		function ( path , obj , ud )

			local isLastSmallTypeItem = typeIdx == #bigTypeData.m_ArrSmallTypeName
			
			obj.transform:SetParent(self.Controls.m_TfLayoutBaiTanBuySmallTypeItem.transform, false)
			self.m_ListSmallTypeItem[typeIdx]:Attach(obj)
			self.m_ListSmallTypeItem[typeIdx]:UpdateItem(bigTypeData.m_ArrSmallTypeName[typeIdx])
			
			if isLastSmallTypeItem then
				rktEventEngine.FireExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCHANGE_UI_EVENT_ON_LAST_SMALL_TYPE_ITEM_CREATE_SUCC)
			end
			
			end , nil, AssetLoadPriority.GuiNormal )	
	end
	
end

-- 计算图标高度
-- @smallTypeCnt:小分类数量:number
--[[function BaiTanBuyBigTypeItem:CalcItemHeight(smallTypeCnt)
	
	local typeHeight = BIG_TYPE_BTN_HEIGHT
	
	if smallTypeCnt > 0 then
		typeHeight = typeHeight + BIG_TYPE_BTN_DIST_TO_SMALL_LAYOUT
		typeHeight = typeHeight + SMALL_TYPE_BTN_HEIGHT * smallTypeCnt
		typeHeight = typeHeight + SMALL_TYPE_BTN_LAYOUT_SPACE * (smallTypeCnt - 1)
		typeHeight = typeHeight + SMALL_TYPE_BTN_TO_BIG_TYPE
	end

	self.m_OnExpandItemHeight = typeHeight
	self.m_NoExpandItemHeight = BIG_TYPE_BTN_HEIGHT
	
end--]]

-- 计算图标的高度
-- return:图标加上子小图标的总高度
function BaiTanBuyBigTypeItem:CalcItemHeight()
	
	-- 公示下如果不显示，就直接返回0 或 购买下如果不显示，就直接返回0
	if (self.m_ShowForGongShi and not self.m_BigTypeData.m_CanShowOnGongShi) or 
		(not self.m_ShowForGongShi and not self.m_BigTypeData.m_CanShowOnBuy) then
		return 0
	end
	
	local typeHeight = BIG_TYPE_BTN_HEIGHT
	local bigTypeData = self.m_BigTypeData
	local smallTypeShowCnt = 0
	
	-- 要显示的小类型数量判断
	if self.m_ShowForGongShi then
		for k,v in pairs(bigTypeData.m_ArrSmallTypeId) do
			if bigTypeData.m_ArrSmallTypeCanGongShi[v] then
				smallTypeShowCnt = smallTypeShowCnt + 1
			end
		end
	else 
		smallTypeShowCnt = #self.m_ListSmallTypeItem
	end
	
	-- 展开状态
	if self.m_IsInUnfold and smallTypeShowCnt > 0 then
		typeHeight = typeHeight + BIG_TYPE_BTN_DIST_TO_SMALL_LAYOUT
		typeHeight = typeHeight + SMALL_TYPE_BTN_HEIGHT * smallTypeShowCnt
		typeHeight = typeHeight + SMALL_TYPE_BTN_LAYOUT_SPACE * (smallTypeShowCnt - 1)
		typeHeight = typeHeight + SMALL_TYPE_BTN_TO_BIG_TYPE
	end
	
	return typeHeight
	
end

-- 更新图标的高度
function BaiTanBuyBigTypeItem:UpdateItemHeight()
	
	self.Controls.m_TfLayoutBaiTanBuySmallTypeItem.gameObject:SetActive(self.m_IsInUnfold)
	
	local oriSize = self.Controls.m_TfRoot.sizeDelta
	
	oriSize.y = self:CalcItemHeight()
	self.Controls.m_TfRoot.sizeDelta = oriSize
	
end

-- 大类型图标的点击行为
function BaiTanBuyBigTypeItem:OnItemClick()

	local smallTypeId = 0
	local tableSort = {}
	for k,v in pairs(self.m_BigTypeData.m_ArrSmallTypeId) do
		if self.m_ShowForGongShi then
			if self.m_BigTypeData.m_ArrSmallTypeCanGongShi[v]  then
				table.insert(tableSort, v)
			end
		else
			table.insert(tableSort, v)
		end
	end
	
	for typeIdx = 1, #tableSort do
		smallTypeId = tableSort[1]
	end
	
	rktEventEngine.FireExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCHANGE_UI_EVENT_BIG_TYPE_ITEM_CLICK, self.m_BigTypeData.m_BigTypeId, smallTypeId)
	
end

function BaiTanBuyBigTypeItem:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function BaiTanBuyBigTypeItem:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function BaiTanBuyBigTypeItem:CleanData()
	
	self.Controls.m_ButtonBigType.onClick:RemoveListener(self.onItemClick)
	self.onItemClick = nil
	
end

return BaiTanBuyBigTypeItem