--/******************************************************************
--** 文件名:	BaiTanBuySearchWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-19
--** 版  本:	1.0
--** 描  述:	交易窗口-摆摊窗口-搜索部件
--** 应  用:  
--******************************************************************/

local BaiTanBuyBigTypeItem = require("GuiSystem.WindowList.Exchange.BaiTanBuyBigTypeItem")

local BaiTanBuySearchWidget = UIControl:new
{
    windowName = "BaiTanBuySearchWidget",
	
	m_IsInFold = false,					-- 是否在收起状态的标识:boolean
	m_ShowForGongShi = false,			-- 是否在公示下显示的标识:boolean
	
	m_CurSelectedBigTypeId = 0,			-- 当前选中的大类型id:number
	m_CurSelectedSmallTypeId = 0,		-- 当前选中的小分类id:number
	m_BigTypeItemCreateSuccCnt = 0,		-- 大图标创建成功的数量:number
	m_IsBigTypeOnCreate = false,		-- 是否在创建大图标期间的标识:boolean
	m_ScroBaiTanBuyBigTypeItem = nil,	-- 类型图标的滚动脚本:ScrollRect
	m_LayoutBaiTanBuyBigTypeItem = nil,	-- 类型图标布局脚本:VerticalLayoutGroup
	
	m_ListBigTypeData = {},				-- 大类型图标数据列表:table(SearchTypeData)
	m_ListBigTypeItem = {},				-- 大类型图标列表脚本:table(BaiTanBuyBigTypeItem)
}

local BIG_TYPE_ITEM_DIST = 1				-- 大类型图标之间的距离:number
local SCRO_TYPE_ITEM_HEIGHT = 734.1			-- 滚动视图的高度:number
	
function BaiTanBuySearchWidget:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	self.m_ListBigTypeData = ExchangeWindowTool.GetAllSearchTypeData()
	
	-- 要插入一个我的收藏
	local allGongShi = SearchTypeData:new()
	allGongShi.m_BigTypeId = SEARCH_TYPE_ALL_GONGSHI_ID
	allGongShi.m_BigTypeName = "所有公示"
	allGongShi.m_CanShowOnBuy = false
	allGongShi.m_CanShowOnGongShi = true
	
	local mineCollect = SearchTypeData:new()
	mineCollect.m_BigTypeId = SEARCH_TYPE_MINE_COLLECT_ID
	mineCollect.m_BigTypeName = "我的收藏"
	mineCollect.m_CanShowOnBuy = true
	mineCollect.m_CanShowOnGongShi = true
	
	table.insert(self.m_ListBigTypeData, 1, mineCollect)
	table.insert(self.m_ListBigTypeData, 1, allGongShi)
	
	self.m_ScroBaiTanBuyBigTypeItem = self.Controls.m_TfScroBaiTanBuyBigTypeItem.gameObject:GetComponent("ScrollRect")
	self.m_LayoutBaiTanBuyBigTypeItem = self.Controls.m_TfLayoutBaiTanBuyBigTypeItem.gameObject:GetComponent("VerticalLayoutGroup")
	
	self.onSearchButtonClick = function() self:OnSearchButtonClick() end
	self.Controls.m_ButtonSearch.onClick:AddListener(self.onSearchButtonClick)
	
	-- 创建大类型图标
	self:CreateTheBigTypeItem()
	
end

-- 显示窗口
-- @bigType:当前选中的大类型:number
-- @smallType:当前选中的小类型:number
-- @needResetScroPos:是否需要重置滚动位置的标识:boolean
-- @showForGongShi:是否在公示下显示的标识:boolean
function BaiTanBuySearchWidget:ShowWidget(bigType, smallType, needResetScroPos, showForGongShi)
	
	self.m_IsInFold = false
	self.m_ShowForGongShi = showForGongShi
	
	-- 更新窗口的显示
	self:UpdateWidgetShow(bigType, smallType, needResetScroPos, self.m_ShowForGongShi)
	
end

-- 收拢或展开大类型
-- @needFold:是否需要收起:boolean
function BaiTanBuySearchWidget:FoldOrUnfoldBigType(needFold)
	
	self.m_IsInFold = needFold
	
end

-- 切换收拢状态
function BaiTanBuySearchWidget:SwitchFoldState()
	
	if self.m_IsInFold then
		self.m_IsInFold = false
	else 
		self.m_IsInFold = true
	end
	
	--更新窗口的显示
	self:UpdateWidgetShow(self.m_CurSelectedBigTypeId, self.m_CurSelectedSmallTypeId, true, self.m_ShowForGongShi)
	
end


-- 更新窗口的显示
-- @bigType:当前选中的大类型:number
-- @smallType:当前选中的小类型:number
-- @needResetScroPos:是否需要重置滚动位置的标识:boolean
-- @showForGongShi:是否在公示下显示的标识:boolean
function BaiTanBuySearchWidget:UpdateWidgetShow(bigType, smallType, needResetScroPos, showForGongShi)
	
	self.m_CurSelectedBigTypeId = bigType
	self.m_CurSelectedSmallTypeId = smallType
	self.m_ShowForGongShi = showForGongShi
	
	if self.m_BigTypeItemCreateSuccCnt == #self.m_ListBigTypeData and #self.m_ListBigTypeData > 0 then
		-- 更新大类型图标的显示
		self:UpdateTheBigTypeShow()
		-- 更新类型图标节点的大小
		self:UpdateTypeItemNodeSize()
	end
	
	if needResetScroPos then
		self.m_ScroBaiTanBuyBigTypeItem.verticalNormalizedPosition = 1
	end

	self.Controls.m_SearchNode.gameObject:SetActive(not showForGongShi)

end

-- 更新大类型图标的显示
function BaiTanBuySearchWidget:UpdateTheBigTypeShow()
	
	for typeIdx = 1, #self.m_ListBigTypeItem do
		local typeData = self.m_ListBigTypeData[typeIdx]
		local typeItem = self.m_ListBigTypeItem[typeIdx]
		
		typeItem:UpdateItem(self.m_CurSelectedBigTypeId, self.m_CurSelectedSmallTypeId, self.m_IsInFold, self.m_ShowForGongShi)
	end
	
end

-- 创建大类型图标
function BaiTanBuySearchWidget:CreateTheBigTypeItem()
	
	if self.m_IsBigTypeOnCreate then
		return
	end

	self.m_IsBigTypeOnCreate = true
	
	for typeIdx = 1, #self.m_ListBigTypeData do
		self.m_ListBigTypeItem[typeIdx] = BaiTanBuyBigTypeItem:new()
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.Exchange.BaiTanBuyBigTypeItem,
		function ( path , obj , ud )

			local isLastBigTypeItem = typeIdx == #self.m_ListBigTypeData
			
			obj.transform:SetParent(self.Controls.m_TfLayoutBaiTanBuyBigTypeItem.transform, false)
			self.m_ListBigTypeItem[typeIdx]:Attach(obj)
			self.m_ListBigTypeItem[typeIdx]:CreateAllSmallTypeItem(self.m_ListBigTypeData[typeIdx], isLastBigTypeItem)
			
		end , i, AssetLoadPriority.GuiNormal )	
	end
end

-- 更新类型图标节点的大小
function BaiTanBuySearchWidget:UpdateTypeItemNodeSize()

	local contentSize = self.Controls.m_TfScroContent.sizeDelta
	local typeItemCnt = #self.m_ListBigTypeItem
	
	if typeItemCnt > 0 then
		contentSize.y = 0
		contentSize.y = contentSize.y + BIG_TYPE_ITEM_DIST * (typeItemCnt - 1)
		
		for k,v in pairs(self.m_ListBigTypeItem) do
			contentSize.y = contentSize.y + v:CalcItemHeight()
		end
	end
		
	if contentSize.y < SCRO_TYPE_ITEM_HEIGHT then
		contentSize.y = SCRO_TYPE_ITEM_HEIGHT	
	end
	
	self.Controls.m_TfScroContent.sizeDelta = contentSize
	
end

-- 当最后一个小类型图标创建成功的事件处理
function BaiTanBuySearchWidget:OnLastSmallTypeItemCreateSucc()
	
	self.m_BigTypeItemCreateSuccCnt = self.m_BigTypeItemCreateSuccCnt + 1
	
	-- 所有类型图标创建成功
	if self.m_BigTypeItemCreateSuccCnt == #self.m_ListBigTypeData then
		-- 更新部件的显示
		self:UpdateWidgetShow(self.m_CurSelectedBigTypeId, self.m_CurSelectedSmallTypeId, true, self.m_ShowForGongShi)
	end
	
	self.m_ScroBaiTanBuyBigTypeItem.verticalNormalizedPosition = 1
	
end

-- 搜索按钮的点击行为
function BaiTanBuySearchWidget:OnSearchButtonClick()
	
	UIManager.ExchangeSearchWindow:Show(true)
	
end

function BaiTanBuySearchWidget:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function BaiTanBuySearchWidget:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function BaiTanBuySearchWidget:CleanData()
	
	self.Controls.m_ButtonSearch.onClick:RemoveListener(self.onSearchButtonClick)
	self.onSearchButtonClick = nil
	
end


return BaiTanBuySearchWidget