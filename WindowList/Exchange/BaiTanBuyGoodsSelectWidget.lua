--/******************************************************************
--** 文件名:    BaiTanBuyGoodsSelectWidget.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-21
--** 版  本:    1.0
--** 描  述:    摆摊窗口-购买窗口
--** 应  用:  
--******************************************************************/

local BaiTanBuyGoodsItem = require("GuiSystem.WindowList.Exchange.BaiTanBuyGoodsItem")

local BaiTanBuyGoodsSelectWidget = UIControl:new
{
    windowName = "BaiTanBuyGoodsSelectWidget",
	
	m_ShowForCollect = false,			-- 是否在收藏下显示的标识:boolean
	m_CurPageIdx = 0,					-- 当前页索引:number
	m_MaxPageCnt = 0,					-- 最大页数量:number
	m_CurSelectedStallId = nil,			-- 当前选中的摊位id:long
	m_ScroDragBeginPosY = 0,			-- 滚动视图拖到开始的坐标Y:number
	
	m_ListStallData = {},				-- 当前的摊位数据列表:table(ExchangeBillBaseInfo)
	m_ArrBaiTanBuyGoodsItem = {},		-- 购买图标的实例脚本:table(BaiTanBuyGoodsItem)
}

function BaiTanBuyGoodsSelectWidget:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	self.onButtonLastPageClick = function() self:OnButtonLastPageClick() end
	self.onButtonNextPageClick = function() self:OnButtonNextPageClick() end
	self.onButtonBuyClick = function() self:OnButtonBuyClick() end
	self.Controls.m_ButtonLastPage.onClick:AddListener(self.onButtonLastPageClick)
	self.Controls.m_ButtonNextPage.onClick:AddListener(self.onButtonNextPageClick)
	self.Controls.m_ButtonBuy.onClick:AddListener(self.onButtonBuyClick)
	
	self.onBeginDrag = function( eventData ) self:OnScroDragBegin(eventData) end
	self.onEndDrag = function( eventData ) self:OnScroDragEnd(eventData) end
	UIFunction.AddEventTriggerListener(self.Controls.m_TfScroBaiTanBuyGoodsItem, EventTriggerType.BeginDrag, self.onBeginDrag)
	UIFunction.AddEventTriggerListener(self.Controls.m_TfScroBaiTanBuyGoodsItem, EventTriggerType.EndDrag, self.onEndDrag )
	
	for itemIdx = 1, 8 do
		local tfItem = self.Controls[string.format("m_TfBaiTanBuyGoodsItem%d", itemIdx)]
		self.m_ArrBaiTanBuyGoodsItem[itemIdx] = BaiTanBuyGoodsItem:new()
		self.m_ArrBaiTanBuyGoodsItem[itemIdx]:Attach(tfItem.gameObject)
	end
	
end

-- 收藏显示
function BaiTanBuyGoodsSelectWidget:ShowForCollect()
	
	--self.transform.gameObject:SetActive(true)
	UIControl.Show(self)
	
	self.m_ShowForCollect = true
	self.m_MaxPageCnt = IGame.ExchangeClient:CalcCollectPageCnt()
	
	-- 变更收藏的页
	self:ChangeCollectPage(1)
	
end

	
-- 隐藏窗口
function BaiTanBuyGoodsSelectWidget:HideWidget()
	
	UIControl.Hide(self, false)
	
	--self.transform.gameObject:SetActive(false)
	
end

-- 变更收藏的页
-- @pageIdx:页编号
function BaiTanBuyGoodsSelectWidget:ChangeCollectPage(pageIdx)
	
	self.m_CurPageIdx = pageIdx
	self.m_CurSelectedStallId = nil
	self.m_MaxPageCnt = IGame.ExchangeClient:CalcCollectPageCnt()
	
	local havePageData = self.m_MaxPageCnt > 0
	self.Controls.m_TfNotCollectNode.gameObject:SetActive(not havePageData)
	self.Controls.m_TfNotGoodsNode.gameObject:SetActive(false)
	self.Controls.m_TfHaveGoodsNode.gameObject:SetActive(havePageData)
	
	if not havePageData then
		return
	end

	if self.m_CurPageIdx > self.m_MaxPageCnt then
		self.m_CurPageIdx = self.m_MaxPageCnt
	elseif(self.m_CurPageIdx < 1) then
		self.m_CurPageIdx = 1
	end
	
	self.m_ListStallData = IGame.ExchangeClient:GetCollectPageData(self.m_CurPageIdx)
	self.Controls.m_TfBuyButton.gameObject:SetActive(true)
	self.Controls.m_TfTipGongShi.gameObject:SetActive(false)
	
	-- 更新页导向元素的显示
	self:UpdatePageGuideElementShow()
	-- 更新商品图标的显示
	self:UpdateGoodsItemShow()
	
end

-- 在收藏页够买了物品的处理
function BaiTanBuyGoodsSelectWidget:UpdateCollectPageForBuy()
	
	-- 变更收藏的页
	self:ChangeCollectPage(self.m_CurPageIdx )
	
end

-- 收到购买商品回包处理
-- @buySucc:购买是否成功
-- @leftNum:剩余数量:number
function BaiTanBuyGoodsSelectWidget:HandleNet_OnBuyStall(buySucc, leftNum)
	
	if self.m_ShowForCollect then
		-- 变更收藏的页
		self:ChangeCollectPage(self.m_CurPageIdx )
	else 
		-- 订单太久或已卖完，要重新刷当前页
		if not buySucc or leftNum < 1 then
			rktEventEngine.FireExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCHANGE_UI_EVENT_CHANGE_QUERY_PAGE, self.m_CurPageIdx)
		else 
			-- 更新商品图标的显示
			self:UpdateGoodsItemShow()
			--IGame.ExchangeClient:RequestQueryGoodsPageData(self.m_CurSelectedGoodsCfgId, self.m_CurSelectedGoodsQuality, self.m_CurPageIndex, self.m_GoodsStateType)
		end
	end
	
end

-- 页查询的显示
-- @pageIdx:当前页编号
-- @pageCnt:总页数
-- @showForBuy:是否在购买下显示:boolean
function BaiTanBuyGoodsSelectWidget:ShowForPageQuery(pageIdx, pageCnt, showForBuy)
	
	self.transform.gameObject:SetActive(true)
	self.m_ShowForCollect = false
	self.m_CurPageIdx = pageIdx
	self.m_MaxPageCnt = pageCnt
	self.m_CurSelectedStallId = nil
	
	local havePageData = pageCnt > 0
	self.Controls.m_TfNotCollectNode.gameObject:SetActive(false)
	self.Controls.m_TfNotGoodsNode.gameObject:SetActive(not havePageData)
	self.Controls.m_TfHaveGoodsNode.gameObject:SetActive(havePageData)
	
	if pageIdx == 0 then
		self.Controls.m_TextNoGoodsTips.text = "暂无公示物品"
	else
		self.Controls.m_TextNoGoodsTips.text = "暂无该类道具出售"
	end
	
	if not havePageData then
		return
	end
	
	self.m_ListStallData = IGame.ExchangeClient:GetAllShopStallData()
	self.Controls.m_TfBuyButton.gameObject:SetActive(showForBuy)
	self.Controls.m_TfTipGongShi.gameObject:SetActive(not showForBuy)
	
	-- 更新页导向元素的显示
	self:UpdatePageGuideElementShow()
	-- 更新商品图标的显示
	self:UpdateGoodsItemShow()
	
end

-- 选中要购买物品处理
-- @stallId:摊位id:long
function BaiTanBuyGoodsSelectWidget:HandleUI_SelectBuyGoods(stallId)

	self.m_CurSelectedStallId = stallId

	-- 更新商品图标的显示
	self:UpdateGoodsItemShow()

end	

-- 收藏的摊位变动处理
function BaiTanBuyGoodsSelectWidget:HandleUI_CollectStallChange()

	-- 在收藏窗口显示的时候，会影响页
	if self.m_ShowForCollect then
		self.m_MaxPageCnt = IGame.ExchangeClient:CalcCollectPageCnt()
		
		local havePageData = self.m_MaxPageCnt > 0
		self.Controls.m_TfNotCollectNode.gameObject:SetActive(not havePageData)
		self.Controls.m_TfNotGoodsNode.gameObject:SetActive(false)
		self.Controls.m_TfHaveGoodsNode.gameObject:SetActive(havePageData)
		
		if not havePageData then
			return
		end
		
		if self.m_CurPageIdx > self.m_MaxPageCnt then
			self.m_CurPageIdx = self.m_MaxPageCnt
		end
		
		self.m_ListStallData = IGame.ExchangeClient:GetCollectPageData(self.m_CurPageIdx)
		
		-- 更新页导向元素的显示
		self:UpdatePageGuideElementShow()
	end
	
	-- 更新商品图标的显示
	self:UpdateGoodsItemShow()
	
end

-- 收到摊位数据通知处理
function BaiTanBuyGoodsSelectWidget:HandleNet_OnStallDataNotice()
	
	-- 更新商品图标的显示
	self:UpdateGoodsItemShow()
	
end


-- 更新页导向元素的显示
function BaiTanBuyGoodsSelectWidget:UpdatePageGuideElementShow()
	
	self.Controls.m_TextPageInfo.text = string.format("%d/%d", self.m_CurPageIdx, self.m_MaxPageCnt)
	
	UIFunction.SetImageGray(self.Controls.m_ImageLastPage, self.m_CurPageIdx <= 1)
	UIFunction.SetImageGray(self.Controls.m_ImageNextPage, self.m_CurPageIdx >= self.m_MaxPageCnt)
	
end

-- 更新商品图标的显示
function BaiTanBuyGoodsSelectWidget:UpdateGoodsItemShow()
	
	local dataCnt = #self.m_ListStallData
	for itemIdx = 1, 8 do
		local item = self.m_ArrBaiTanBuyGoodsItem[itemIdx]
		local itemNeedShow = itemIdx <= dataCnt 
		
		item.transform.gameObject:SetActive(itemNeedShow)
		if itemNeedShow then
			local data = self.m_ListStallData[itemIdx]
			local isSelected = data.seq == self.m_CurSelectedStallId
			item:UpdateItem(data, isSelected)
		end
	end
	
end

-- 跳到上一页
function BaiTanBuyGoodsSelectWidget:TurnLastPage()
	
	if self.m_CurPageIdx <= 1 then
		return
	end
		
	if self.m_ShowForCollect then
		self:ChangeCollectPage(self.m_CurPageIdx - 1)
	else
		rktEventEngine.FireExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCHANGE_UI_EVENT_CHANGE_QUERY_PAGE, self.m_CurPageIdx - 1)
	end
	
end

-- 跳到下一页
function BaiTanBuyGoodsSelectWidget:TurnNextPage()
	
	if self.m_CurPageIdx >= self.m_MaxPageCnt then
		return
	end
		
	if self.m_ShowForCollect then
		self:ChangeCollectPage(self.m_CurPageIdx + 1)
	else
		rktEventEngine.FireExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCHANGE_UI_EVENT_CHANGE_QUERY_PAGE, self.m_CurPageIdx + 1)
	end
	
end

-- 滚动视图滚动开始执行的行为
function BaiTanBuyGoodsSelectWidget:OnScroDragBegin( eventData )
 
	self.m_ScroDragBeginPosY = eventData.position.y
	
end



-- 滚动视图滚动结束执行的行为
function BaiTanBuyGoodsSelectWidget:OnScroDragEnd( eventData )
 
	local dragStride = eventData.position.y - self.m_ScroDragBeginPosY
	
	-- 上一页
	if dragStride < -200 then
		-- 跳到上一页
		-- self:TurnLastPage()
		return
	end
	
	-- 下一页
	if dragStride > 200 then
		-- 跳到下一页
		-- self:TurnNextPage()
		return
	end
	
end

-- 上一页按钮的点击行为
function BaiTanBuyGoodsSelectWidget:OnButtonLastPageClick()
	
	-- 跳到上一页
	self:TurnLastPage()
	
end

-- 下一页按钮的点击行为
function BaiTanBuyGoodsSelectWidget:OnButtonNextPageClick()
	
	-- 跳到下一页
	self:TurnNextPage()
	
end

-- 购买按钮的点击行为
function BaiTanBuyGoodsSelectWidget:OnButtonBuyClick()
	
	-- 未选中物品
	if self.m_CurSelectedStallId == nil then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请先选中要购买的商品！")
		return
	end
	
	local stallData = nil
	if self.m_ShowForCollect then
		stallData = IGame.ExchangeClient:GetCollectStallData(self.m_CurSelectedStallId)
	else 
		stallData = IGame.ExchangeClient:GetShopStallData(self.m_CurSelectedStallId)
	end
	
	if not stallData then
		return
	end

	-- 公示期间的物品不能购买
	if stallData.btState == E_GoodState_Publicity then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "公示期间的商品不可购买！")
		return
	end
	
	UIManager.ExchangeBuyConfirmWindow:ShowWindow(self.m_CurSelectedStallId, self.m_ShowForCollect)
	
end


function BaiTanBuyGoodsSelectWidget:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function BaiTanBuyGoodsSelectWidget:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function BaiTanBuyGoodsSelectWidget:CleanData()
	
	self.Controls.m_ButtonLastPage.onClick:RemoveListener(self.onButtonLastPageClick)
	self.Controls.m_ButtonNextPage.onClick:RemoveListener(self.onButtonNextPageClick)
	self.Controls.m_ButtonBuy.onClick:RemoveListener(self.onButtonBuyClick)
	
	self.onButtonLastPageClick = nil
	self.onButtonNextPageClick = nil
	self.onButtonBuyClick = nil
	self.onBeginDrag = nil
	self.onEndDrag = nil

	self.m_CurSelectedStallId = nil
	
end

return BaiTanBuyGoodsSelectWidget