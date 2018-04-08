
--商城分页上层Control

local ShopWidget = UIControl:new {
	windowName = "ShopWidget",
	
	tabName = {
		Toggle_1	     = 1,
		Toggle_2    	 = 2,
		Toggle_3    	 = 3,
		Toggle_4    	 = 4,
		Toggle_5    	 = 5,
	},
	
	m_curTab 	= 0,
	m_selectItemIndex 		= 1,			--当前页中选中的item
	m_defaultGoodsID 		= nil,			--对外接口设置的GoodsID
	m_defaultGoodsType		= 1				--对外接口设置的默认类型
}

function ShopWidget:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.GoodsListWidget	= require("GuiSystem.WindowList.Shop.Shop.GoodsListWidget")
	self.GoodsInfo			= require("GuiSystem.WindowList.Shop.Shop.GoodsInfo")
	self.GoodsExpenseInfo	= require("GuiSystem.WindowList.Shop.Shop.GoodsExpenseInfo")
	
	self.GoodsListWidget:Attach(self.Controls.m_GoodsListWidget.gameObject)
	self.GoodsInfo:Attach(self.Controls.m_ChipCurGoodsInfoWidget.gameObject)
	self.GoodsExpenseInfo:Attach(self.Controls.m_ChipCurExpenseWidget.gameObject)
	self.GoodsExpenseInfo:SetParentWidget(self)
	-- 购买按钮事件
	self.callback_BuyBtn = function() self:OnBuyBtnClick() end
	self.Controls.m_BuyBtn.onClick:AddListener(self.callback_BuyBtn)

	self.callback_Toggle_1	= function(on) self:OnToggleChanged(on, self.tabName.Toggle_1) end
	self.Controls.m_Toggle_1.onValueChanged:AddListener(self.callback_Toggle_1)
	
	self.callback_Toggle_2	= function(on) self:OnToggleChanged(on, self.tabName.Toggle_2) end
	self.Controls.m_Toggle_2.onValueChanged:AddListener(self.callback_Toggle_2)
	
	self.callback_Toggle_3	= function(on) self:OnToggleChanged(on, self.tabName.Toggle_3) end
	self.Controls.m_Toggle_3.onValueChanged:AddListener(self.callback_Toggle_3)
	
	self.callback_Toggle_4	= function(on) self:OnToggleChanged(on, self.tabName.Toggle_4) end
	self.Controls.m_Toggle_4.onValueChanged:AddListener(self.callback_Toggle_4)
	
	self.callback_Toggle_5	= function(on) self:OnToggleChanged(on, self.tabName.Toggle_5) end
	self.Controls.m_Toggle_5.onValueChanged:AddListener(self.callback_Toggle_5)
	
	self.RefreshCb = function(_,_,_, plazaID) self:RefreshBuySuccess(plazaID) end			--购买成功刷新事件
	rktEventEngine.SubscribeExecute(EVENT_SHOP_BUYSUCCESS,0,0,self.RefreshCb)
	
	self:InitToggle()
--	self:SetDefaultTab(1)	

	self.JumpToGoodsCB = function(_,_,_,nGoodsID) self:JumpToGood(nGoodsID) end
	self.OnClickItemEvt = function() self:OnClickItem() end
	
	--控制刷新顺序
	self.refreshExpenseBuyBtn = function() self.GoodsExpenseInfo:UpdateBuyBtn(self.m_curTab,self.m_selectItemIndex) end
	rktTimer.SetTimer(self.refreshExpenseBuyBtn, 60, 1,"RefreshExpenseBuyBtn")
	
	self.refreshListEventHandler = function() self:RefeshTabGoodsInfo(self.m_curTab) end
	rktEventEngine.SubscribeExecute(EVENT_PLAZA_LIST_UPDATE,SOURCE_TYPE_PLAZA,0,self.refreshListEventHandler)
end

function ShopWidget:Show()
	UIControl.Show(self)
	
	rktEventEngine.SubscribeExecute(EVENT_SHOP_JUMPTOGOOD,0,0,self.JumpToGoodsCB)
	rktEventEngine.SubscribeExecute(EVENT_SHOP_CLICKGOODSITEM,0,0,self.OnClickItemEvt)
	
	
--	self.m_ToggleControls[1].isOn = true
	if self.m_defaultGoodsID and self.m_defaultGoodsID > 0 then
		self:JumpToGood(self.m_defaultGoodsID)
		--[[local index = IGame.PlazaClient:GetTypeAndIndexByID(self.m_defaultGoodsType,self.m_defaultGoodsID)
		self.GoodsListWidget.m_JumpToGoodsIndex = index

		if self.m_curTab > 0 and self.m_curTab ~= self.m_defaultGoodsType then
			self.m_ToggleControls[self.m_curTab].isOn = false
			self.m_ToggleControls[self.m_defaultGoodsType].isOn = true
		else
			self.m_ToggleControls[self.m_defaultGoodsType].isOn = false
			self.m_ToggleControls[self.m_defaultGoodsType].isOn = true
		end
		
		self.m_defaultGoodsID = nil
		self.m_defaultGoodsType = 1--]]
	else
		self.m_defaultGoodsID = nil
		self.m_defaultGoodsType = 1
		
		for i,data in pairs(self.m_ToggleControls) do
			data.isOn = false
		end
		
		if self.m_curTab > 0 then
			self.m_ToggleControls[self.m_curTab].isOn = false
		end
		
		self.m_ToggleControls[1].isOn = true
	end
end

function ShopWidget:Hide(destroy)
	rktEventEngine.UnSubscribeExecute(EVENT_SHOP_JUMPTOGOOD,0,0,self.JumpToGoodsCB)
	rktEventEngine.UnSubscribeExecute(EVENT_SHOP_CLICKGOODSITEM,0,0,self.OnClickItemEvt)
	UIControl.Hide(self,destroy)
end

function ShopWidget:OnDestroy()
	self.m_curTab = 0
	rktEventEngine.UnSubscribeExecute(EVENT_SHOP_BUYSUCCESS,0,0,self.RefreshCb)
	UIControl.OnDestroy(self)
	
	rktEventEngine.UnSubscribeExecute(EVENT_PLAZA_LIST_UPDATE,SOURCE_TYPE_PLAZA,0,self.refreshListEventHandler)
	rktEventEngine.UnSubscribeExecute(EVENT_SHOP_CLICKGOODSITEM,0,0,self.OnClickItemEvt)
end

-------------------------------------------------------------------
-- 初始化所有toggle组件					这里没必要这样初始化，这里固定是两个toggle,这么写也可以
-------------------------------------------------------------------
function ShopWidget:InitToggle()	
	self.Controls.m_Toggle_1.isOn	= false
	self.Controls.m_Toggle_1.gameObject:SetActive(false)
	
	self.Controls.m_Toggle_2.isOn	= false
	self.Controls.m_Toggle_2.gameObject:SetActive(false)

	self.Controls.m_Toggle_3.isOn	= false
	self.Controls.m_Toggle_3.gameObject:SetActive(false)
	
	self.Controls.m_Toggle_4.isOn	= false
	self.Controls.m_Toggle_4.gameObject:SetActive(false)

	self.Controls.m_Toggle_5.isOn	= false
	self.Controls.m_Toggle_5.gameObject:SetActive(false)

	local tabTable = IGame.PlazaClient:GetTypeGoodsTabList()		--获取配置表中的Tab信息

	self.m_ToggleControls = {
		self.Controls.m_Toggle_1,
		self.Controls.m_Toggle_2,
		self.Controls.m_Toggle_3,
		self.Controls.m_Toggle_4,
		self.Controls.m_Toggle_5
	}
	
	self.m_ToggleTextHightLigt = {
		self.Controls.m_ToggleText_1,
		self.Controls.m_ToggleText_2,
		self.Controls.m_ToggleText_3,
		self.Controls.m_ToggleText_4,
		self.Controls.m_ToggleText_5,
	}
	
	self.m_ToggleText =
	{
		self.Controls.m_ToggleText2_1,
		self.Controls.m_ToggleText2_2,
		self.Controls.m_ToggleText2_3,
		self.Controls.m_ToggleText2_4,
		self.Controls.m_ToggleText2_5,
	}
	
	for i, data in pairs(tabTable) do
		self.m_ToggleControls[i].gameObject:SetActive(true)
		self.m_ToggleTextHightLigt[i].text = data.szName
		self.m_ToggleText[i].text = data.szName
	end
end

-------------------------------------------------------------------
-- 设置默认显示页面
-------------------------------------------------------------------
function ShopWidget:SetDefaultTab(curTabIndex)	
	self.m_ToggleControls[curTabIndex].isOn = true
	self.GoodsListWidget.m_CurrTypeIndex = curTabIndex
	self:RefeshTabGoodsInfo(curTabIndex)
end	
--打开界面的时候默认选中商品
function ShopWidget:JumpToDefaultGoods()
	if nil == self.m_defaultGoodsID or self.m_defaultGoodsID <= 0 then
		return
	end
	
	local index = IGame.PlazaClient:GetTypeAndIndexByID(self.m_defaultGoodsType,self.m_defaultGoodsID)
	self.m_ToggleControls[self.m_defaultGoodsType].isOn = true
	self.GoodsListWidget.m_JumpToGoodsIndex = index
	
--	self.GoodsListWidget.m_itemScriptCache[index]:SetFocus(true)
	
	--跳转后清空数据
	self.m_defaultGoodsID = nil
	self.m_defaultGoodsType = 1
end

-------------------------------------------------------------------
-- Toggle 选中项被改变触发事件
-------------------------------------------------------------------
function ShopWidget:OnToggleChanged(on, curTabIndex)
	if on then 
		self.m_ToggleControls[curTabIndex].transform:Find("ON").gameObject:SetActive(true)
		self.m_ToggleControls[curTabIndex].transform:Find("OFF").gameObject:SetActive(false)
	else		
		self.m_ToggleControls[curTabIndex].transform:Find("ON").gameObject:SetActive(false)
		self.m_ToggleControls[curTabIndex].transform:Find("OFF").gameObject:SetActive(true)
		self.m_curTab = 0
		
		return
	end
	
	if self.m_curTab == curTabIndex then 
		return 
	end
	
	if self.m_defaultGoodsID and self.m_defaultGoodsID > 0 then
		self.GoodsListWidget.m_CurIndex = self.GoodsListWidget.m_JumpToGoodsIndex
		self.m_selectItemIndex = self.GoodsListWidget.m_JumpToGoodsIndex
		self.GoodsListWidget.m_CurrTypeIndex = self.m_defaultGoodsType
		self.m_defaultGoodsID = nil
		self.m_defaultGoodsType = 1
	else
		self.GoodsListWidget.m_CurIndex = 1
		self.m_selectItemIndex = 1
		self.GoodsListWidget.m_CurrTypeIndex = curTabIndex
	end
	
--[[	self.GoodsListWidget.m_CurIndex = 1
	self.m_selectItemIndex = 1
	self.GoodsListWidget.m_CurrTypeIndex = curTabIndex--]]
	-- 刷新当前切页物品信息											--不会出现有tab标签，但是下面没有item的情况
	self:RefeshTabGoodsInfo(curTabIndex)	
end

-------------------------------------------------------------------
-- 刷新当前物品信息			
-------------------------------------------------------------------
function ShopWidget:RefeshTabGoodsInfo(curTabIndex)	
	self.m_curTab = curTabIndex
	
	if curTabIndex == 1 then	--每周6:00刷新提示文字
		self.Controls.m_TipText.gameObject:SetActive(true)
	else
		self.Controls.m_TipText.gameObject:SetActive(false)
	end
	
	-- 刷新一个切页需要更新3项：
	-- 当前物品列表信息、当前物品信息、当前物品消耗信息
	self:ReloadGoodsListItem(curTabIndex)
	
	self:UpdateGoodsInfo(self.m_selectItemIndex)
	self:UpdateExpenseInfo(self.m_selectItemIndex)
end	

--跳转到指定物品
function ShopWidget:JumpToGood(nGoodsID)
	if not nGoodsID and nGoodsID <= 0 then return end
	local nType = IGame.PlazaClient:GetTypeByID(nGoodsID)
	local index = IGame.PlazaClient:GetTypeAndIndexByID(nType,nGoodsID)
	if self.m_curTab == nType then
		self.GoodsListWidget.m_itemScriptCache[self.GoodsListWidget.m_CurIndex]:SetFocus(false)
		self.GoodsListWidget.m_itemScriptCache[index]:SetFocus(true)
	else
		self.GoodsListWidget.m_JumpToGoodsIndex = index
		if self.m_curTab > 0 then
			self.m_ToggleControls[self.m_curTab].isOn = false
		end
		self.m_ToggleControls[nType].isOn = true
	end
	self.m_defaultGoodsID = nil
	self.m_defaultGoodsType = 1
end

--购买成功后刷新界面
function ShopWidget:RefreshBuySuccess(plazaID)
	if self.GoodsListWidget then
		self.GoodsListWidget:RefreshBuySuccess(plazaID)
		self:UpdateGoodsInfo(self.m_selectItemIndex)
		self:UpdateExpenseInfo(self.m_selectItemIndex)
	end
end


-- 购买成功之后 刷新限购次数跟剩余的货币
function ShopWidget:ReloadGoodsListItem(nIndex)
--	self.GoodsListWidget:ReloadData(nIndex)
	self.GoodsListWidget:CreateGoodsList(nIndex)
end

-------------------------------------------------------------------
-- 初始化当前购买物品信息 
-------------------------------------------------------------------
function ShopWidget:UpdateGoodsInfo(nIndex)
	-- 右边的描述框 默认显示第一个	
	self:UpdateExchangeGoodsInfo(nIndex)
end

-------------------------------------------------------------------
-- 更新右边物品详细描述 
-------------------------------------------------------------------
function ShopWidget:UpdateExpenseInfo(nIndex)
	-- 默认显示第一个	
	self:UpdateExchangeExpenseInfo(nIndex)
end

-------------------------------------------------------------------
-- 更新右边物品详细描述  						TODO
-------------------------------------------------------------------
function ShopWidget:UpdateExchangeGoodsInfo(index)
	if not self.GoodsInfo:UpdateGoodsInfo(self.m_curTab,index) then						
		return
	end
	self.m_selectItemIndex = index
end

-------------------------------------------------------------------
-- 更新购买信息等
-------------------------------------------------------------------
function ShopWidget:UpdateExchangeExpenseInfo(index)
	if not self.GoodsExpenseInfo:UpdateGoodsExpenseInfo(self.m_curTab,index) then							
		return
	end
	self.m_selectItemIndex = index
end


-------------------------------------------------------------------
-- 点击购买按钮						判断是否满足购买条件，不满足就弹充值面板，在这里延迟加载	TODO		
-------------------------------------------------------------------
function ShopWidget:OnBuyBtnClick()		--从服务器获取当前item是否售罄，售罄就提示售罄，钱不够跳转到充值界面		TODO
	
	local subGoods = IGame.PlazaClient:GetInfoByIndex(self.m_curTab, self.m_selectItemIndex)
	
	--判断是否是钻石，如果是钻石不够的话，弹出充值面板,其他的不处理
	if subGoods.nYuanbaoType == 1 then
		-- 钻石不足，是否前往充值，打开充值界面
		if GameHelp:DiamondNotEnoughSwitchRecharge(self.GoodsExpenseInfo:GetTotalGoodsCost()) then
			return
		end
	end
	
	
	if self.GoodsExpenseInfo.m_NeedShowUseYuanBaoTip then
		local data = {
			content = "当前银币不足，是否消耗银两购买。",
			confirmCallBack = function() 
				GameHelp.PostServerRequest("RequestPlazaData(".. subGoods.nSaleID..","..self.GoodsExpenseInfo.m_nBuyCount..")") 
			end
		}
		UIManager.ConfirmPopWindow:ShowDiglog(data)
	else
		GameHelp.PostServerRequest("RequestPlazaData("..subGoods.nSaleID..","..self.GoodsExpenseInfo.m_nBuyCount..")")
	end

end

------------------------------------------------------------------------------------------------------------------
--加载完成点击商品条目事件回掉
function ShopWidget:OnClickItem()
	if not self.Controls.m_CurGoodsTrans.gameObject.activeInHierarchy then
		self.Controls.m_CurGoodsTrans.gameObject:SetActive(true)
	end
end

return ShopWidget