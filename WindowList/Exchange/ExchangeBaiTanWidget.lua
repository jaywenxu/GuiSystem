--/******************************************************************
--** 文件名:	ExchangeBaiTanWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-09
--** 版  本:	1.0
--** 描  述:	交易窗口-摆摊窗口
--** 应  用:  
--******************************************************************/

local ExchangeBaiTanWidget = UIControl:new
{
	windowName 	= "ExchangeBaiTanWidget",
	
	m_CurChildWindowType = nil,			-- 当前显示的子窗口类型:ExchangeBaiTanChildWindowType(string)
	
	m_BaiTanBuyWidget = nil,			-- 摆摊购买部件:BaiTanBuyWidget
	m_BaiTanSellWidget = nil,			-- 摆摊出售部件:BaiTanSellWidget
	
	m_ArrSubscribeEvent = {},			-- 绑定的事件集合:table(string, function())
}

function ExchangeBaiTanWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	
	self.onTabButtonClick1 = function() self:OnTabButtonClick(ExchangeBaiTanChildWindowType.BUY) end
	self.onTabButtonClick2 = function() self:OnTabButtonClick(ExchangeBaiTanChildWindowType.SELL) end
	self.onTabButtonClick3 = function() self:OnTabButtonClick(ExchangeBaiTanChildWindowType.GONGSHI) end
	
	self.Controls.m_ButtonGouMai.onClick:AddListener(self.onTabButtonClick1)
	self.Controls.m_ButtonChuShou.onClick:AddListener(self.onTabButtonClick2)
	self.Controls.m_ButonGongShi.onClick:AddListener(self.onTabButtonClick3)
	
	-- 事件绑定
	self:SubscribeEvent()

	self:RefreshRedDot()
end


-- 窗口销毁
function ExchangeBaiTanWidget:OnDestroy()
	-- 移除事件的绑定
    self:UnSubscribeEvent()
    
	-- 清除数据
	self:CleanData()
    
    UIControl.OnDestroy(self)
	
	table_release(self)
end

-- 事件绑定
function ExchangeBaiTanWidget:SubscribeEvent()
	
	self.m_ArrSubscribeEvent = 
	{
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_UI_EVENT_ON_LAST_SMALL_TYPE_ITEM_CREATE_SUCC,
			f = function(event, srctype, srcid) self:HandleUI_LastSmallTypeItemCreateSucc() end,
		},
		
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_UI_EVENT_BIG_TYPE_ITEM_CLICK,
			f = function(event, srctype, srcid, bigTypeId, smallTypeId) self:HandleUI_BigTypeItemClick(bigTypeId, smallTypeId) end,
		},
		
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_UI_EVENT_SMALL_TYPE_ITEM_CLICK,
			f = function(event, srctype, srcid, bigTypeId, smallTypeId) self:HandleUI_SmallTypeItemClick(bigTypeId, smallTypeId) end,
		},
		
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCAHNGE_UI_EVENT_LEVEL_ITEM_CLICK,
			f = function(event, srctype, srcid, levelId) self:HandleUI_LevelItemClick(levelId) end,
		},
		
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_NET_EVENT_ON_QUERY_SMALL_TYPE_TOTAL_SELL_STATE,
			f = function(event, srctype, srcid, msgUseType) self:HandleNet_OnQuerySmallTypeTotalSellState(msgUseType) end,
		},
		
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_NET_EVENT_ON_PLAYER_STALL_DATA,
			f = function(event, srctype, srcid) self:HandleNet_OnPlayerStallData() end,
		},
		
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_NET_EVENT_ON_COLLECT_DATA,
			f = function(event, srctype, srcid) self:HandleNet_OnCollectData() end,
		},
		
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_NET_EVENT_ON_PAGE_DATA,
			f = function(event, srctype, srcid, pageIdx, pageCnt) self:HandleNet_OnPageData(pageIdx, pageCnt) end,
		},
		
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_UI_EVENT_SELECT_BUY_GOODS,
			f = function(event, srctype, srcid, pageIdx, pageCnt) self:HandleUI_SelectBuyGoods(pageIdx, pageCnt) end,
		},
		
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_UI_EVENT_CHANGE_QUERY_PAGE,
			f = function(event, srctype, srcid, dstPageIdx) self:HandleUI_QueryPageChange(dstPageIdx) end,
		},
		
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_UI_EVENT_CHANGE_QUERY_GOODS,
			f = function(event, srctype, srcid, goodsCfgId, goodsQuality) self:HandleUI_ChangeQueryGoods(goodsCfgId, goodsQuality) end,
		},
		
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_UI_EVENT_COLLECT_STALL_CHANGE,
			f = function(event, srctype, srcid) self:HandleUI_CollectStallChange() end,
		},
		
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_NET_EVENT_ON_PUT_GOODS,
			f = function(event, srctype, srcid) self:HandleNet_OnPutGoods() end,
		},
		
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_NET_EVENT_ON_BUY_STALL,
			f = function(event, srctype, srcid, buySucc, leftNum) self:HandleNet_OnBuyStall(buySucc, leftNum) end,
		},
		
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_NET_EVENT_ON_STALL_DATA_NOTICE,
			f = function(event, srctype, srcid) self:HandleNet_OnStallDataNotice() end,
		},
		
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_NET_EVENT_ON_DOWN_GOODS,
			f = function(event, srctype, srcid) self:HandleNet_OnDownGoods() end,
		},
		
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_UI_EVENT_SELL_STALL_ITEM_SELECTED,
			f = function(event, srctype, srcid, stallId) self:HandleUI_SellStallItemSelected(stallId) end,
		},
		
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_UI_EVENT_SELL_PACKET_CELL_SELECTED,
			f = function(event, srctype, srcid, stallId) self:HandleUI_SellPacketCellSelected(stallId) end,
		},
		
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_UI_EVENT_CHANGE_BAITAN_TAB,
			f = function(event, srctype, srcid, tabType) self:HandleUI_ChangeBaiTanTab(tabType) end,
		},
		
		{
			e = MSG_MODULEID_EXCHANGE, s = SOURCE_TYPE_SYSTEM, i = EXCHANGE_UI_EVENT_CONFRIM_SEARCH_GOODS,
			f = function(event, srctype, srcid, searchData) self:HandleUI_ConfirmSearchGoods(searchData) end,
		},

		{
			e = EVENT_UI_REDDOT_UPDATE, s = SOURCE_TYPE_SYSTEM, i = REDDOT_UI_EVENT_EXCHANGE,
			f = function(event, srctype, srcid, searchData) self:RefreshRedDot(searchData) end,
		},
	}
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.SubscribeExecute(v.e, v.s, v.i, v.f)
	end
	
end

-- 移除事件的绑定
function ExchangeBaiTanWidget:UnSubscribeEvent()
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.UnSubscribeExecute(v.e, v.s, v.i, v.f)
	end
	
end	

-- 显示窗口
function ExchangeBaiTanWidget:ShowWidget()
	
	UIControl.Show(self)
	--self.transform.gameObject:SetActive(true)

	-- 指定要跳到出售界面,并打开上架界面
	if ExchangeWindowPresetDataMgr.m_DstSelectedPacketItemUid ~= nil then
		local entity = IGame.EntityClient:Get(ExchangeWindowPresetDataMgr.m_DstSelectedPacketItemUid)
		
		-- 变更子窗口
		self:ChangeChildWindow(ExchangeBaiTanChildWindowType.SELL)
		
		ExchangeWindowPresetDataMgr:PresetPutData(entity.m_uid, nil)
		IGame.ExchangeClient:RequestQueryEntityReferencePrice(entity)
	-- 打开界面购买指定的商品
	elseif ExchangeWindowPresetDataMgr.m_DstBuyGoodsCfgId ~= nil then
		-- 变更子窗口
		self:ChangeChildWindow(ExchangeBaiTanChildWindowType.BUY)
	else 
		if ExchangeWindowPresetDataMgr.m_NetHandleCtrlType == ExchangeWindowNetHandleControlType.HANDLE_TYPE_CAHENG_TAB_GONGSHI then
			-- 变更子窗口
			self:ChangeChildWindow(ExchangeBaiTanChildWindowType.GONGSHI)
		else 
			-- 变更子窗口
			self:ChangeChildWindow(ExchangeBaiTanChildWindowType.BUY)
		end
		
		ExchangeWindowPresetDataMgr:PresetNetHandleCtrlType(nil)
	end
	
end

-- 隐藏窗口
function ExchangeBaiTanWidget:HideWidget()
	
	UIControl.Hide(self, false)
	--self.transform.gameObject:SetActive(false)
	
end

-- 变更子窗口
-- @childTab:要显示的子窗口的页签类型:ExchangeBaiTanChildWindowType(string)
-- @customAction:自定义的附加行为:function
function ExchangeBaiTanWidget:ChangeChildWindow(childTab, customAction)
	
	self.m_CurChildWindowType = childTab
	
	-- 先判断子窗口是否创建了，如果没有创建的就动态创建出来
	-- 如果子窗口已经创建了，就更新子界面
	if (childTab == ExchangeBaiTanChildWindowType.BUY and self.m_BaiTanBuyWidget == nil) or
	   (childTab == ExchangeBaiTanChildWindowType.SELL and self.m_BaiTanSellWidget == nil) or 
	   (childTab == ExchangeBaiTanChildWindowType.GONGSHI and self.m_BaiTanBuyWidget == nil) then
		-- 创建子窗口
		self:CreateChildWindow(childTab, customAction)
	else 
		if childTab == ExchangeBaiTanChildWindowType.BUY then
			self.m_BaiTanBuyWidget:ShowWidget(true)

			if self.m_BaiTanSellWidget ~= nil then
				self.m_BaiTanSellWidget:HideWidget()
			end
		elseif childTab == ExchangeBaiTanChildWindowType.GONGSHI then
			self.m_BaiTanBuyWidget:ShowWidget(false)
			
			if self.m_BaiTanSellWidget ~= nil then
				self.m_BaiTanSellWidget:HideWidget()
			end
		elseif childTab == ExchangeBaiTanChildWindowType.SELL then
			self.m_BaiTanSellWidget:ShowWidget()
			
			if self.m_BaiTanBuyWidget ~= nil then
				self.m_BaiTanBuyWidget:HideWidget()
			end
		end
		
		if customAction ~= nil then
			customAction()
		end
	end
	
	-- 更新页签选中的显示
	self:UpdateTheTabSelectedShow()
		
end

-- 创建子窗口
-- @childTab:子窗口的页签类型:ExchangeBaiTanChildWindowType(string) 
-- @customAction:自定义的附加行为:function
function ExchangeBaiTanWidget:CreateChildWindow(childTab, customAction)
	
	-- 子窗口预制体路径判断
	local prefabPath = nil 
	if childTab == ExchangeBaiTanChildWindowType.BUY or childTab == ExchangeBaiTanChildWindowType.GONGSHI then
		prefabPath = GuiAssetList.Exchange.BaiTanBuyWidget
	elseif childTab == ExchangeBaiTanChildWindowType.SELL then
		prefabPath = GuiAssetList.Exchange.BaiTanSellWidget
	end
	
	rkt.GResources.FetchGameObjectAsync( prefabPath ,
		function ( path , obj , ud )
			if nil == obj then 
				uerror("prefab is nil : " .. path )
				return
			end
	        if tolua.isnull( obj ) then
	            rkt.GResources.RecycleGameObject( obj )
	            uerror("prefab is nil : " .. path )
	            return
	        end

			if childTab == ExchangeBaiTanChildWindowType.BUY or childTab == ExchangeBaiTanChildWindowType.GONGSHI then
				self.m_BaiTanBuyWidget = require("GuiSystem.WindowList.Exchange.BaiTanBuyWidget"):new()
				self.m_BaiTanBuyWidget:Attach(obj)
			elseif childTab == ExchangeBaiTanChildWindowType.SELL then
				self.m_BaiTanSellWidget = require("GuiSystem.WindowList.Exchange.BaiTanSellWidget"):new()
				self.m_BaiTanSellWidget:Attach(obj)
			end
			
			obj.transform:SetParent(self.Controls.m_TfChildWidgetNode.transform, false)
			
			-- 变更子窗口
			self:ChangeChildWindow(childTab, customAction)
			
		end , nil, AssetLoadPriority.GuiNormal )
end

-- 收到查询小类型物品总体出售状态回包
-- @msgUseType:消息使用类型:number(EXCHANGE_NET_MSG_USE_TYPE)
function ExchangeBaiTanWidget:HandleNet_OnQuerySmallTypeTotalSellState(msgUseType)
	
	if not self.transform.gameObject.activeInHierarchy then
		return
	end

	-- 跳到购买
	if msgUseType == EXCHANGE_NET_MSG_USE_TYPE.CAHENG_FOR_BUY then
		self:ChangeChildWindow(ExchangeBaiTanChildWindowType.BUY)
		return
	end
	
	-- 跳到公示
	if msgUseType == EXCHANGE_NET_MSG_USE_TYPE.CHANGE_FOR_GONGSHI then
		self:ChangeChildWindow(ExchangeBaiTanChildWindowType.GONGSHI)
		return
	end
	
	self.m_BaiTanBuyWidget:HandleNet_OnQuerySmallTypeTotalSellState(msgUseType)
	
end

-- 收到玩家摊位数据回包处理
function ExchangeBaiTanWidget:HandleNet_OnPlayerStallData()
	
	if not self.transform.gameObject.activeInHierarchy then
		return
	end
	
	self:ChangeChildWindow(ExchangeBaiTanChildWindowType.SELL)
	
end

-- 收到玩家收藏数据回包处理
function ExchangeBaiTanWidget:HandleNet_OnCollectData()
	
	if not self.transform.gameObject.activeInHierarchy then
		return
	end
	
	self.m_BaiTanBuyWidget:HandleNet_OnCollectData()
	
end

-- 收到页数据回包处理
-- @pageIdx:当前页编号
-- @pageCnt:总页数
function ExchangeBaiTanWidget:HandleNet_OnPageData(pageIdx, pageCnt)
	
	if not self.transform.gameObject.activeInHierarchy then
		return
	end
	
	self.m_BaiTanBuyWidget:HandleNet_OnPageData(pageIdx, pageCnt)
	
end

-- 选中购买物品的处理
-- @stallId:摊位id:long
function ExchangeBaiTanWidget:HandleUI_SelectBuyGoods(stallId)
	
	self.m_BaiTanBuyWidget:HandleUI_SelectBuyGoods(stallId)
	
end

-- 查询页变动处理
-- @dstPageIdx:要查询的页:number
function ExchangeBaiTanWidget:HandleUI_QueryPageChange(dstPageIdx)
	
	self.m_BaiTanBuyWidget:HandleUI_QueryPageChange(dstPageIdx)
	
end

-- 变更查询的产品处理
-- @goodsCfgId:商品配置id:number
-- @goodsQuality:商品品质:number
function ExchangeBaiTanWidget:HandleUI_ChangeQueryGoods(goodsCfgId, goodsQuality)
	
	self.m_BaiTanBuyWidget:HandleUI_ChangeQueryGoods(goodsCfgId, goodsQuality)
	
end

-- 摊位收藏变动处理
function ExchangeBaiTanWidget:HandleUI_CollectStallChange()
	
	self.m_BaiTanBuyWidget:HandleUI_CollectStallChange()
	
end

-- 上架物品回包事件处理
function ExchangeBaiTanWidget:HandleNet_OnPutGoods()
	
	if not self.transform.gameObject.activeInHierarchy then
		return
	end
	
	self.m_BaiTanSellWidget:HandleNet_OnPutGoods()
	
end


-- 下架物品回包事件处理
function ExchangeBaiTanWidget:HandleNet_OnDownGoods()
	
	if not self.transform.gameObject.activeInHierarchy then
		return
	end
	
	self.m_BaiTanSellWidget:HandleNet_OnDownGoods()
	
end

-- 出售界面摊位选中事件处理
-- @stallId:摊位id:long
function ExchangeBaiTanWidget:HandleUI_SellStallItemSelected(stallId)
	
	self.m_BaiTanSellWidget:HandleUI_SellStallItemSelected(stallId)
	
end

-- 出售界面摆摊背包格子选中处理
-- @entityUid:选中的实体uid:long
function ExchangeBaiTanWidget:HandleUI_SellPacketCellSelected(entityUid)
	
	self.m_BaiTanSellWidget:HandleUI_SellPacketCellSelected(entityUid)
	
end

-- 摆摊页签变动处理
-- @tabType:页签类型:ExchangeBaiTanChildWindowType
function ExchangeBaiTanWidget:HandleUI_ChangeBaiTanTab(tabType)
	
	-- 公示有些特殊，改页签的时候也执行的查询功能
	if tabType == ExchangeBaiTanChildWindowType.GONGSHI then
		local exchangeClient = IGame.ExchangeClient
		self:ChangeChildWindow(tabType, function() 
			
			self.m_BaiTanBuyWidget:HandleNet_OnPageData(exchangeClient.m_CurGoodsQueryPageIdx, exchangeClient.m_CurGoodsQueryPageCnt) 
			
		end )
	else 
		self:ChangeChildWindow(tabType)
	end
	
	
end

-- 摆摊页签变动处理
-- @searchData:搜索数据:BaiTanFuzzySearchData
function ExchangeBaiTanWidget:HandleUI_ConfirmSearchGoods(searchData)
	
	self.m_BaiTanBuyWidget:HandleUI_ConfirmSearchGoods(searchData)
	
end

-- 收到购买商品回包处理
-- @buySucc:购买是否成功
-- @leftNum:剩余数量:number
function ExchangeBaiTanWidget:HandleNet_OnBuyStall(buySucc, leftNum)
	
	if not self.transform.gameObject.activeInHierarchy then
		return
	end
	
	self.m_BaiTanBuyWidget:HandleNet_OnBuyStall(buySucc, leftNum)
	
end

-- 收到摊位数据通知处理
function ExchangeBaiTanWidget:HandleNet_OnStallDataNotice()
	
	if not self.transform.gameObject.activeInHierarchy then
		return
	end
	
	if self.m_BaiTanBuyWidget.transform.gameObject.activeInHierarchy then
		self.m_BaiTanBuyWidget:HandleNet_OnStallDataNotice()
	elseif self.m_BaiTanSellWidget.transform.gameObject.activeInHierarchy then
		IGame.ExchangeClient:CheckStallRedDot()

		self.m_BaiTanSellWidget:HandleNet_OnStallDataNotice()
	end
	
end

-- 当最后一个小类型图标创建成功的事件处理
function ExchangeBaiTanWidget:HandleUI_LastSmallTypeItemCreateSucc()
	
	self.m_BaiTanBuyWidget:OnLastSmallTypeItemCreateSucc()
	
end

-- 大类型图标的点击行为处理
-- @bigTypeId:点击的大类型id:number
-- @smallTypeId:点击的小类型id:number
function ExchangeBaiTanWidget:HandleUI_BigTypeItemClick(bigTypeId, smallTypeId)
	
	self.m_BaiTanBuyWidget:HandleUI_BigTypeItemClick(bigTypeId, smallTypeId)
	
end	

-- 小类型图标的点击行为处理
-- @bigTypeId:点击的大类型id:number
-- @smallTypeId:点击的小类型id:number
function ExchangeBaiTanWidget:HandleUI_SmallTypeItemClick(bigTypeId, smallTypeId)
	
	self.m_BaiTanBuyWidget:HandleUI_SmallTypeItemClick(bigTypeId, smallTypeId)
	
end

-- 等级图标点击事件广播处理
-- @levelId:等级id:number
function ExchangeBaiTanWidget:HandleUI_LevelItemClick(levelId)
	
	self.m_BaiTanBuyWidget:HandleUI_LevelItemClick(levelId)
	
end

-- 摆摊红点更新
function ExchangeBaiTanWidget:RefreshRedDot(_, _, _, evtData)
	local redDotObjs = 
	{
		["出售"] = self.Controls.m_ButtonChuShou
	}

	SysRedDotsMgr.RefreshRedDot(redDotObjs, "Exchange", evtData)

end


-- 更新页签选中的显示
function ExchangeBaiTanWidget:UpdateTheTabSelectedShow()
	
	self:SetTabSelectedState(self.Controls.m_ButtonGouMai, self.m_CurChildWindowType == ExchangeBaiTanChildWindowType.BUY)
	self:SetTabSelectedState(self.Controls.m_ButtonChuShou, self.m_CurChildWindowType == ExchangeBaiTanChildWindowType.SELL)
	self:SetTabSelectedState(self.Controls.m_ButonGongShi, self.m_CurChildWindowType == ExchangeBaiTanChildWindowType.GONGSHI)
	
end

function ExchangeBaiTanWidget:SetTabSelectedState(tab, on)
	
	tab.transform:Find("Image_On").gameObject:SetActive(on)
	tab.transform:Find("Image_On").transform.localScale = Vector3.New(1,1,1)
	tab.transform:Find("Image_Off").gameObject:SetActive(not on)
	
end


-- 页签按钮点击行为
-- @childTab:页签的类型:ExchangeBaiTanChildWindowType(string) 
function ExchangeBaiTanWidget:OnTabButtonClick(childTab)
	
	-- 相同标签或在隐藏的不用响应
	if self.m_CurChildWindowType == childTab then 
		return
	end

	-- 请求小数据类型-跳到购买
	if childTab == ExchangeBaiTanChildWindowType.BUY then
		IGame.ExchangeClient:RequestQueryCollectData(ExchangeWindowNetHandleControlType.HANDLE_TYPE_CHANGE_TAB_COLLECT)
		
		return
	end
	
	-- 请求小数据类型-跳到公示
	if childTab == ExchangeBaiTanChildWindowType.GONGSHI then
		IGame.ExchangeClient:RequestQueryGoodsPageData(0, 0, 1, E_GoodState_Publicity, ExchangeWindowNetHandleControlType.HANDLE_TYPE_CAHENG_TAB_GONGSHI)
		
		return
	end

	-- 请求出售数据
	if childTab == ExchangeBaiTanChildWindowType.SELL then
		IGame.ExchangeClient:RequestPlayerStallData(false)
		return
	end
	
end


function ExchangeBaiTanWidget:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end


-- 清除数据
function ExchangeBaiTanWidget:CleanData()
	
	self.Controls.m_ButtonGouMai.onClick:RemoveListener(self.onTabButtonClick1)
	self.Controls.m_ButtonChuShou.onClick:RemoveListener(self.onTabButtonClick2)
	self.Controls.m_ButonGongShi.onClick:RemoveListener(self.onTabButtonClick3)
	self.onTabButtonClick1 = nil
	self.onTabButtonClick2 = nil
	self.onTabButtonClick3 = nil
	
end

return ExchangeBaiTanWidget