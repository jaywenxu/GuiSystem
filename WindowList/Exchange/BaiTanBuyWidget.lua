--/******************************************************************
---** 文件名:	BaiTanBuyWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-09
--** 版  本:	1.0
--** 描  述:	交易窗口-摆摊窗口-购买窗口
--** 应  用:  
--******************************************************************/

local BaiTanBuyLevelItem = require("GuiSystem.WindowList.Exchange.BaiTanBuyLevelItem")
local BaiTanBuySearchWidget = require("GuiSystem.WindowList.Exchange.BaiTanBuySearchWidget")
local BaiTanBuyIntroSelectWidget = require("GuiSystem.WindowList.Exchange.BaiTanBuyIntroSelectWidget")
local BaiTanBuyGoodsSelectWidget = require("GuiSystem.WindowList.Exchange.BaiTanBuyGoodsSelectWidget")


local BaiTanBuyWidget = UIControl:new
{
	windowName 	= "BaiTanBuyWidget",

	m_GoodsStateType = 0,					-- 商品状态类型:number(ExchangeGoodState)
	m_ShowForBuy = false,					-- 是否在购买状态下显示的标识:boolean
	
	m_CurSelectedBigTypeId = 0,				-- 当前选中的大类型id:number
	m_CurSelectedSmallTypeId = 0,			-- 当前选中的小类型id:number
	m_CurSelectedLevelId = 0,				-- 当前选中的等级id:number
	m_CurSelectedGoodsCfgId = 0,			-- 当前选中的商品配置id:number
	m_CurSelectedGoodsQuality = 0,			-- 当前选中的商品品质:number
	m_CurPageIndex = 0,						-- 当前页索引:number
	
	m_DstSelectedBigTypeId = 0,				-- 打算选中的大类型id(需要等待协议回包):number
	m_DstSelectedSmallTypeId = 0,			-- 打算选中的小类型id(需要等待协议回包):number
	m_DstSelectedLevelId = 0,				-- 打算选中的等级id(需要等待协议回包):number
	
	m_LayoutBaiTanBuyLevelItem = nil,		-- 等级选择图标的布局脚本:VerticalLayoutGroup
	m_BaiTanBuySearchWidget = nil,			-- 搜索窗口:BaiTanBuySearchWidget
	m_BaiTanBuyIntroSelectWidget = nil,		-- 介绍选择窗口:BaiTanBuyIntroSelectWidget
	m_BaiTanBuyGoodsSelectWidget = nil,		-- 摆摊商品选择窗口:BaiTanBuyGoodsSelectWidget
	
	m_ListBaiTanBuyLevelItem = {},			-- 等级选择图标列表:table(BaiTanBuyLevelItem)
}

function BaiTanBuyWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	
	self.m_BaiTanBuySearchWidget = BaiTanBuySearchWidget:new()
	self.m_BaiTanBuyIntroSelectWidget = BaiTanBuyIntroSelectWidget:new()
	self.m_BaiTanBuyGoodsSelectWidget = BaiTanBuyGoodsSelectWidget:new()
	
	self.m_LayoutBaiTanBuyLevelItem = self.Controls.m_TfLayoutBaiTanBuyLevelItem.gameObject:GetComponent("VerticalLayoutGroup")
	
	self.onHideLevelSelectButtonClick = function() self:OnHideLevelSelectButtonClick() end
	self.onPopLevelSelectButtonClick = function() self:OnPopLevelSelectButtonClick() end
	self.Controls.m_ButtonHideLevelSelect.onClick:AddListener(self.onHideLevelSelectButtonClick)
	self.Controls.m_ButtonPopLevelSelect.onClick:AddListener(self.onPopLevelSelectButtonClick)
	
	self.m_BaiTanBuySearchWidget:Attach(self.Controls.m_TfBaiTanBuySearchWidget.gameObject)
	self.m_BaiTanBuyIntroSelectWidget:Attach(self.Controls.m_TfBaiTanBuyIntroSelectWidget.gameObject)
	self.m_BaiTanBuyGoodsSelectWidget:Attach(self.Controls.m_TfBaiTanBuyGoodsSelectWidget.gameObject)
	
end

-- 显示窗口
-- @showForBuy:是否用来显示购买的标识:boolean
function BaiTanBuyWidget:ShowWidget(showForBuy)
	
	UIControl.Show(self)
	
	self.m_ShowForBuy = showForBuy
	if showForBuy then
		self.m_GoodsStateType = E_GoodState_OnShelf
	else 
		self.m_GoodsStateType = E_GoodState_Publicity
	end
	
	-- 指定了要购买的物品
	if ExchangeWindowPresetDataMgr.m_DstBuyGoodsCfgId ~= nil then
		-- 初始化有指定购买物品的时的默认选中类型
		self:InitTheDefaultSelectedTypeForCustomGoodsId(ExchangeWindowPresetDataMgr.m_DstBuyGoodsCfgId)
	else 
		-- 初始化默认选中的类型
		self:InitTheDefaultSelectedType()
	end
	
	-- 设置等级箭头的旋转
	self:SetLevelArrowRot(0)

	self.m_BaiTanBuySearchWidget:ShowWidget(self.m_CurSelectedBigTypeId, self.m_CurSelectedSmallTypeId, true, not showForBuy)
	self.m_BaiTanBuyIntroSelectWidget:Hide()
	
	if self.m_ShowForBuy then
		if ExchangeWindowPresetDataMgr.m_DstBuyGoodsCfgId ~= nil then
			self.m_BaiTanBuyGoodsSelectWidget:ShowForPageQuery(1, IGame.ExchangeClient.m_CurGoodsQueryPageCnt, true)
			ExchangeWindowPresetDataMgr:PresetDestBuyGoodsCfgId(nil)
		else 
			self.m_BaiTanBuyGoodsSelectWidget:ShowForCollect()
		end
	else 
		self.m_BaiTanBuyGoodsSelectWidget:ShowForPageQuery(1, 0, false)
	end
	
	-- 更新等级选择的显示
	self:UpdateLevelSelectShow()

end

-- 隐藏部件
function BaiTanBuyWidget:HideWidget()
	
	UIControl.Hide(self, false)
	
end

-- 收到查询小类型物品总体出售状态回包
-- @msgUseType:消息使用类型:number(EXCHANGE_NET_MSG_USE_TYPE)
function BaiTanBuyWidget:HandleNet_OnQuerySmallTypeTotalSellState(msgUseType)

	self.m_CurSelectedBigTypeId = self.m_DstSelectedBigTypeId
	self.m_CurSelectedSmallTypeId = self.m_DstSelectedSmallTypeId
	self.m_CurSelectedLevelId = self.m_DstSelectedLevelId
	self.m_CurSelectedGoodsCfgId = 0
	self.m_CurSelectedGoodsQuality = 0
	
	if msgUseType == EXCHANGE_NET_MSG_USE_TYPE.CHANGE_BIG_TYPE then
		self.m_BaiTanBuySearchWidget:UpdateWidgetShow(self.m_CurSelectedBigTypeId, self.m_CurSelectedSmallTypeId, true, not self.m_ShowForBuy)
	else
		self.m_BaiTanBuySearchWidget:UpdateWidgetShow(self.m_CurSelectedBigTypeId, self.m_CurSelectedSmallTypeId, false, not self.m_ShowForBuy)
	end

	-- 我的收藏不需要显示小类型出售状态界面
	if self.m_CurSelectedBigTypeId == SEARCH_TYPE_MINE_COLLECT_ID then
		self.m_BaiTanBuyIntroSelectWidget:HideWidget()
		self.m_BaiTanBuyGoodsSelectWidget:ShowForCollect()
	else 
		self.m_BaiTanBuyIntroSelectWidget:ShowWidget(self.m_CurSelectedBigTypeId, self.m_CurSelectedSmallTypeId, self.m_CurSelectedLevelId, self.m_ShowForBuy)
		self.m_BaiTanBuyGoodsSelectWidget:HideWidget()
	end
	
	-- 更新等级选择的显示
	self:UpdateLevelSelectShow()
	
end

-- 收到页数据回包处理
-- @pageIdx:当前页编号
-- @pageCnt:总页数
function BaiTanBuyWidget:HandleNet_OnPageData(pageIdx, pageCnt)

	-- 所有公示
	if self.m_DstSelectedBigTypeId == SEARCH_TYPE_ALL_GONGSHI_ID then
		self.m_CurSelectedBigTypeId = self.m_DstSelectedBigTypeId
		self.m_BaiTanBuySearchWidget:UpdateWidgetShow(self.m_CurSelectedBigTypeId, self.m_CurSelectedSmallTypeId, true, not self.m_ShowForBuy)
	end

	self.m_CurPageIndex = pageIdx

	self.m_BaiTanBuyIntroSelectWidget:HideWidget()
	self.m_BaiTanBuyGoodsSelectWidget:ShowForPageQuery(pageIdx, pageCnt, self.m_ShowForBuy)
	
	-- 更新等级选择的显示
	self:UpdateLevelSelectShow()

end

-- 选中要购买物品的处理
-- @stallId:要购买的摊位id:long
function BaiTanBuyWidget:HandleUI_SelectBuyGoods(stallId)
	
	self.m_BaiTanBuyGoodsSelectWidget:HandleUI_SelectBuyGoods(stallId)
	
end

-- 大分类图标点击行为处理
-- @bigTypeId:大分类id:number
-- @smallTypeId:小分类id:number
function BaiTanBuyWidget:HandleUI_BigTypeItemClick(bigTypeId, smallTypeId)
	
	self.m_DstSelectedBigTypeId = bigTypeId 
	self.m_DstSelectedSmallTypeId = smallTypeId 
	self.m_DstSelectedLevelId = self.m_CurSelectedLevelId 
	local levelId = self.m_CurSelectedLevelId 
	
	-- 已选中的大类型，收拢大类型
	if self.m_CurSelectedBigTypeId == bigTypeId then
		self.m_DstSelectedSmallTypeId = self.m_CurSelectedSmallTypeId
		self.m_BaiTanBuySearchWidget:SwitchFoldState()
	else 
		self.m_BaiTanBuySearchWidget:FoldOrUnfoldBigType(false)
	end

	-- 道具没有等级id
	if bigTypeId == GOODS_CLASS_LEECHDOM then
		levelId = 0
	end
	
	-- 我的收藏要请求收藏数据
	if bigTypeId == SEARCH_TYPE_MINE_COLLECT_ID then
		IGame.ExchangeClient:RequestQueryCollectData()
		return
	end
	
	-- 所有公示
	if bigTypeId == SEARCH_TYPE_ALL_GONGSHI_ID then
		self.m_CurSelectedGoodsCfgId = 0
		IGame.ExchangeClient:RequestQueryGoodsPageData(0, 0, 1, E_GoodState_Publicity)
		return
	end
	
	IGame.ExchangeClient:RequestQuerySmallTypeTotalSellState(bigTypeId, smallTypeId, levelId, self.m_GoodsStateType, EXCHANGE_NET_MSG_USE_TYPE.CHANGE_BIG_TYPE)
	
end

-- 小分类图标点击行为处理
-- @bigTypeId:大分类id:number
-- @smallTypeId:小分类id:number
function BaiTanBuyWidget:HandleUI_SmallTypeItemClick(bigTypeId, smallTypeId)
	
	self.m_DstSelectedBigTypeId = bigTypeId 
	self.m_DstSelectedSmallTypeId = smallTypeId 
	self.m_DstSelectedLevelId = self.m_CurSelectedLevelId 

	local levelId = self.m_CurSelectedLevelId 
	
	-- 道具没有等级id
	if bigTypeId == GOODS_CLASS_LEECHDOM then
		levelId = 0
	end
	
	IGame.ExchangeClient:RequestQuerySmallTypeTotalSellState(bigTypeId, smallTypeId, levelId, self.m_GoodsStateType, EXCHANGE_NET_MSG_USE_TYPE.CHANGE_SMALL_TYPE)

end

-- 查询页变动处理
-- @dstPageIdx:要查询的页:number
function BaiTanBuyWidget:HandleUI_QueryPageChange(dstPageIdx)
	
	IGame.ExchangeClient:RequestQueryGoodsPageData(self.m_CurSelectedGoodsCfgId, self.m_CurSelectedGoodsQuality, dstPageIdx, self.m_GoodsStateType)

end

-- 收到摊位数据通知处理
function BaiTanBuyWidget:HandleNet_OnStallDataNotice()
	
	self.m_BaiTanBuyGoodsSelectWidget:HandleNet_OnStallDataNotice()

end

-- 摆摊页签变动处理
-- @searchData:搜索数据:BaiTanFuzzySearchData
function BaiTanBuyWidget:HandleUI_ConfirmSearchGoods(searchData)
	
	self.m_CurSelectedBigTypeId = searchData.m_BigTypeId
	self.m_CurSelectedSmallTypeId = searchData.m_SmallTypeId
	
	-- 装备要设置等级id
	if searchData.m_BigTypeId == GOODS_CLASS_EQUIPMENT then
		local goodsScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_GOODS_CSV, searchData.m_GoodsCfgId)
		if goodsScheme then
			self.m_CurSelectedLevelId = goodsScheme.level
		end
	end
	
	
	self.m_BaiTanBuySearchWidget:FoldOrUnfoldBigType(false)
	self.m_BaiTanBuySearchWidget:UpdateWidgetShow(searchData.m_BigTypeId , searchData.m_SmallTypeId, true, false)
	-- 更新等级选择的显示
	self:UpdateLevelSelectShow()
	
	rktEventEngine.FireExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCHANGE_UI_EVENT_CHANGE_QUERY_GOODS, 
		searchData.m_GoodsCfgId, searchData.m_Quality)
	
end

-- 变更查询的产品处理
-- @goodsCfgId:商品配置id:number
-- @goodsQuality:商品品质:number
function BaiTanBuyWidget:HandleUI_ChangeQueryGoods(goodsCfgId, goodsQuality)
	
	self.m_CurSelectedGoodsCfgId = goodsCfgId
	self.m_CurSelectedGoodsQuality = goodsQuality
	
	self.m_BaiTanBuyIntroSelectWidget:ChangeTheSelectedIntroItem(goodsCfgId, goodsQuality)	
	
	IGame.ExchangeClient:RequestQueryGoodsPageData(goodsCfgId, goodsQuality, 1, self.m_GoodsStateType)	
		
end

-- 收到玩家收藏数据回包处理
function BaiTanBuyWidget:HandleNet_OnCollectData()
	
	self:HandleNet_OnQuerySmallTypeTotalSellState(EXCHANGE_NET_MSG_USE_TYPE.CHANGE_BIG_TYPE)
	
end

-- 收到购买商品回包处理
-- @buySucc:购买是否成功
-- @leftNum:剩余数量:number
function BaiTanBuyWidget:HandleNet_OnBuyStall(buySucc, leftNum)

	self.m_BaiTanBuyGoodsSelectWidget:HandleNet_OnBuyStall(buySucc, leftNum)

end


-- 等级图标点击事件广播处理
-- @levelId:等级id:number
function BaiTanBuyWidget:HandleUI_LevelItemClick(levelId)

	-- 已经选中了要购买的物品的时候，切换等级是切换其他等级的同物品
	if self.m_CurSelectedGoodsCfgId > 0 then
		self.m_CurSelectedLevelId = levelId
		
		local dstGoodsScheme = nil
		local goodsScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_GOODS_CSV, self.m_CurSelectedGoodsCfgId)
		local listAllGoodsScheme = IGame.rktScheme:GetSchemeTable(EXCHANGE_GOODS_CSV)
		if not listAllGoodsScheme or not goodsScheme then
			return nil
		end
		
		for k,v in pairs(listAllGoodsScheme) do
			if v.class == goodsScheme.class and v.subClass == goodsScheme.subClass and v.level == levelId and v.other == goodsScheme.other then
				dstGoodsScheme = v
				break
			end
		end
		
		if dstGoodsScheme ~= nil then
			IGame.ExchangeClient:RequestQueryGoodsPageData(dstGoodsScheme.goodsID, self.m_CurSelectedGoodsQuality, 1, self.m_GoodsStateType)
		end 
	else 
		self.m_DstSelectedBigTypeId = self.m_CurSelectedBigTypeId 
		self.m_DstSelectedSmallTypeId = self.m_CurSelectedSmallTypeId 
		self.m_DstSelectedLevelId = levelId
	
		IGame.ExchangeClient:RequestQuerySmallTypeTotalSellState(self.m_DstSelectedBigTypeId, self.m_DstSelectedSmallTypeId, self.m_DstSelectedLevelId,
			self.m_GoodsStateType, EXCHANGE_NET_MSG_USE_TYPE.CHANGE_LEVEL_ID)
	end
	
end

-- 收藏的摊位变动处理
function BaiTanBuyWidget:HandleUI_CollectStallChange()
	
	self.m_BaiTanBuyGoodsSelectWidget:HandleUI_CollectStallChange()
	
end

-- 初始化默认选中的类型
function BaiTanBuyWidget:InitTheDefaultSelectedType()
	
	if self.m_ShowForBuy then 
		self.m_CurSelectedBigTypeId = SEARCH_TYPE_MINE_COLLECT_ID
	else 
		self.m_CurSelectedBigTypeId = SEARCH_TYPE_ALL_GONGSHI_ID
	end
	
	if self.m_CurSelectedLevelId == nil or self.m_CurSelectedLevelId < 1 then
		self.m_CurSelectedLevelId = ExchangeWindowTool.CheckPlayerLevelId()
	end
	
end

-- 初始化有指定购买物品的时的默认选中类型
-- @goodsCfgId:商品配置id:number
function BaiTanBuyWidget:InitTheDefaultSelectedTypeForCustomGoodsId(goodsCfgId)
	
	local goodsScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_GOODS_CSV, goodsCfgId)
	if not goodsScheme then
		uerror("找不到要购买的物品的商品id [%d] !", goodsCfgId)
		
		-- 初始化默认选中的类型
		self:InitTheDefaultSelectedType();
		return
	end
	
	self.m_CurSelectedBigTypeId = goodsScheme.class
	self.m_CurSelectedSmallTypeId = goodsScheme.subClass
	
	if goodsScheme.class == GOODS_CLASS_EQUIPMENT then
		self.m_CurSelectedLevelId = goodsScheme.level
	else 
		self.m_CurSelectedLevelId = ExchangeWindowTool.CheckPlayerLevelId()
	end
end

-- 当最后一个小类型图标创建成功的事件处理
function BaiTanBuyWidget:OnLastSmallTypeItemCreateSucc()
	
	self.m_BaiTanBuySearchWidget:OnLastSmallTypeItemCreateSucc()
	
end

-- 更新等级选择的显示
function BaiTanBuyWidget:UpdateLevelSelectShow()
	
	if self.m_CurSelectedBigTypeId == SEARCH_TYPE_MINE_COLLECT_ID or self.m_CurSelectedBigTypeId == GOODS_CLASS_LEECHDOM then
		self.Controls.m_TfLevelSelectNode.gameObject:SetActive(false)
		return
	end
	
	local listLevelData = ExchangeWindowTool.GetSmallTypeAllLevelData(self.m_CurSelectedBigTypeId, self.m_CurSelectedSmallTypeId)
	if not listLevelData or #listLevelData < 1 then
		self.Controls.m_TfLevelSelectNode.gameObject:SetActive(false)
		return
	end

	local curSelectedLevelData = nil
	for k,v in pairs(listLevelData) do
		if v.m_LevelId == self.m_CurSelectedLevelId then
			curSelectedLevelData = v
		end
	end
	
	if curSelectedLevelData == nil then
		uerror("摆摊等级id有问题!!!")
		return
	end

	self.Controls.m_TfLevelSelectNode.gameObject:SetActive(true)
	self.Controls.m_TfDropLevelSelect.gameObject:SetActive(false)
	self.Controls.m_TextCurLevelSelected.text = string.format("%d~%d级", curSelectedLevelData.m_LeftLevel, curSelectedLevelData.m_RightLevel)

	-- 创建和更新等级选择图标
	self:CreateAndUpdateLevelSelectItem(listLevelData)
	-- 设置等级箭头的旋转
	self:SetLevelArrowRot(0)

end

-- 创建和更新等级选择图标
-- @listLevelData:等级段数据列表:table(SearchSmallTypeLevelData)
function BaiTanBuyWidget:CreateAndUpdateLevelSelectItem(listLevelData)
	
	local dataCnt = #listLevelData
	local itemCnt = #self.m_ListBaiTanBuyLevelItem
	
	-- 如果数量不足，创建新的图标
	for creatIdx = itemCnt, dataCnt-1 do
		local goInst = rkt.GResources.InstantiateGameObject(self.Controls.m_TfTemplateBaiTanBuyLevelItem.gameObject)
		goInst.transform:SetParent(self.Controls.m_TfLayoutBaiTanBuyLevelItem.transform)
		goInst.transform.localScale = Vector3.one
		
		local item = BaiTanBuyLevelItem:new()
		item:Attach(goInst)
		
		table.insert(self.m_ListBaiTanBuyLevelItem, item)	
	end
	
	itemCnt = #self.m_ListBaiTanBuyLevelItem
	
	-- 更新图标
	for itemIdx = 1, itemCnt do
		local itemNeedShow = itemIdx <= dataCnt
		local item = self.m_ListBaiTanBuyLevelItem[itemIdx]
		
		item.transform.gameObject:SetActive(itemNeedShow)
		if itemNeedShow then
			local levelData = listLevelData[itemIdx]
			item:UpdateItem(levelData)
		end
	end
	
	-- 自适应背景图
	local bgOriSize = self.Controls.m_TfBgLevelSelect.sizeDelta
	bgOriSize.y = 68 * itemCnt + 27
	self.Controls.m_TfBgLevelSelect.sizeDelta = bgOriSize
	
end

-- 设置等级箭头的旋转
-- @angleZ:Z轴旋转
function BaiTanBuyWidget:SetLevelArrowRot(angleZ)
	
	local qua = Quaternion.identity
	qua.eulerAngles = Vector3.New(0, 0, angleZ)
	self.Controls.m_TfPopLevelArrow.transform.localRotation = qua
	
end


-- 等级选择弹出按钮点击行为
function BaiTanBuyWidget:OnPopLevelSelectButtonClick()
	
	self.Controls.m_TfDropLevelSelect.gameObject:SetActive(true)
	
	-- 设置等级箭头的旋转
	self:SetLevelArrowRot(180)

end

-- 等级选择隐藏按钮点击行为
function BaiTanBuyWidget:OnHideLevelSelectButtonClick()

	self.Controls.m_TfDropLevelSelect.gameObject:SetActive(false)	
	
	-- 设置等级箭头的旋转
	self:SetLevelArrowRot(0)
	
end

function BaiTanBuyWidget:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function BaiTanBuyWidget:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function BaiTanBuyWidget:CleanData()
	
	self.Controls.m_ButtonHideLevelSelect.onClick:RemoveListener(self.onHideLevelSelectButtonClick)
	self.Controls.m_ButtonPopLevelSelect.onClick:RemoveListener(self.onPopLevelSelectButtonClick)
	self.onHideLevelSelectButtonClick = nil
	self.onPopLevelSelectButtonClick = nil
	
end


return BaiTanBuyWidget