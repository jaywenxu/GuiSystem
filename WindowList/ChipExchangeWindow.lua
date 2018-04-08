-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    zjc
-- 日  期:    2017-05-04
-- 描  述:    通用商店
-------------------------------------------------------------------

local titleImagePath = AssetPath.TextureGUIPath.."Store/Store_shangdian.png"

local ChipExchangeWindow = UIWindow:new
{
	windowName 	= "ChipExchangeWindow",

	tabName = 
	{
		emAthletics			= 1,	
		emDiscussSword		= 2,	
		emChivalrousValue	= 3,	
		emReserve			= 4,
		emReserve2          = 5,	
	},
	
	m_curTab		= 0,
	m_curNpcID		= 0,
	m_curBigType	= 0,
	
	m_selectItemIndex = 0,	--当前页面中选中的index
	m_bSubEvent = false,
}

-------------------------------------------------------------------
-- 初始化 
-------------------------------------------------------------------
function ChipExchangeWindow:Init()
	self.ChipExchangeWidget = require("GuiSystem.WindowList.ChipExchange.ChipExchangeWidget"):new()	-- 通用商城子窗口
	self.ChipExchangeWidget:Init()
	self.ChipConfirmWidget = require("GuiSystem.WindowList.ChipExchange.ChipConfirmWidget"):new()	-- 提示确认购买框
	
	self.callback_OnCurrencyUpdate  = function() self:UpdateOwnInfoData() end
	self.RefreshGoodsInfoTimer = function() self:RefreshGoodsInfo() end
	self.callBackRefreshRecordData = function(event, srctype, srcid, eventData) self:RefreshRecordData(eventData) end
	self.callback_OnEventAddGoods = function() self:OnEventAddGoods() end
	self.callback_OnEventRemoveGoods = function() self:OnEventRemoveGoods() end
	
end

function ChipExchangeWindow:OnAttach(obj)
	UIWindow.OnAttach(self,obj)
	
	self.callback_OnReturnBtnClick = function () 
										self.ChipExchangeWidget.m_selectItemIndex = 1
										self.m_selectItemIndex = 1
										self.m_curTab = 0
										self:Hide() 
									end
	-- 加载通用窗口
	UIWindow.AddCommonWindowToThisWindow(self, true, titleImagePath, self.callback_OnReturnBtnClick,nil,function() self:SetFullScreen() end)
	
	self.ChipConfirmWidget:Attach(self.Controls.m_ChipConfirmWidget.gameObject)

	-- 注册toggle group 点击过滤事件
	-- 第一个小类
	self.callback_ToggleOne	= function(on) self:OnToggleChanged(on, self.tabName.emAthletics) end
	self.Controls.m_Tog_Athletics.onValueChanged:AddListener(self.callback_ToggleOne)
	
	-- 第二个小类
	self.callback_ToggleTwo 	= function(on) self:OnToggleChanged(on, self.tabName.emDiscussSword) end
	self.Controls.m_Tog_DiscSword.onValueChanged:AddListener(self.callback_ToggleTwo)
	
	-- 第三个小类
	self.callback_ToggleThree	= function(on) self:OnToggleChanged(on, self.tabName.emChivalrousValue) end
	self.Controls.m_Tog_ChiValue.onValueChanged:AddListener(self.callback_ToggleThree)
	
	-- 第四个小类
	self.callback_ToggleFour		= function(on) self:OnToggleChanged(on, self.tabName.emReserve) end
	self.Controls.m_Tog_Reserve.onValueChanged:AddListener(self.callback_ToggleFour)
	
	-- 第五个小类
	self.callback_ToggleFour		= function(on) self:OnToggleChanged(on, self.tabName.emReserve2) end
	self.Controls.m_Tog_Reserve2.onValueChanged:AddListener(self.callback_ToggleFour)

	-- self.m_curTab = IGame.ChipExchangeClient:GetCurrIndex()
	
	if not self.m_bSubEvent then
		self:SubscribeEvent()
	end
	self.ChipExchangeWidget:FetchWidget(self.Controls.m_ChipExchangeBG)
	self.ChipExchangeWidget:ShowWidget(self.m_curNpcID,self.m_curTab,self.m_selectItemIndex)
    self:ShowExchangGoodsInfo(self.m_curNpcID,self.m_curTab,self.m_selectItemIndex)
end

function ChipExchangeWindow:Show( bringTop )
	UIWindow.Show(self, bringTop )
	self:SubscribeEvent()
end

function ChipExchangeWindow:Hide( destroy )
	UIWindow.Hide(self,destroy)
	self:UnSubscribeEvent() 
end

-- 注册事件
function ChipExchangeWindow:SubscribeEvent()
	if self.m_bSubEvent then
		return
	end
	rktEventEngine.SubscribeExecute( EVENT_CHIPEXCHANGE_LIST_UPDATE,SOURCE_TYPE_PLAZA,0,self.RefreshGoodsInfoTimer) 
	rktEventEngine.SubscribeExecute( EVENT_SYNC_PERSON_RECORD_DATA,SOURCE_TYPE_PERSON,0,self.callBackRefreshRecordData)
	self.m_bSubEvent = true
end

-- 取消事件
function ChipExchangeWindow:UnSubscribeEvent()
	rktEventEngine.UnSubscribeExecute( EVENT_CHIPEXCHANGE_LIST_UPDATE,SOURCE_TYPE_PLAZA,0,self.RefreshGoodsInfoTimer)
	rktEventEngine.UnSubscribeExecute( EVENT_SYNC_PERSON_RECORD_DATA,SOURCE_TYPE_PERSON,0,self.callBackRefreshRecordData)
	self.m_bSubEvent = false
end

function ChipExchangeWindow:OnDestroy()
	self:UnSubscribeEvent()
	self.ChipExchangeWidget:OnDestroy()
	UIWindow.OnDestroy(self)
end

-------------------------------------------------------------------
-- 点击关闭按钮 
-------------------------------------------------------------------
function ChipExchangeWindow:OnCloseBtnClick()
	self:Hide()
end

-------------------------------------------------------------------
-- 点击返回按钮  暂时写跟关闭按钮一样
-------------------------------------------------------------------
function ChipExchangeWindow:OnReturnBtnClick()
	self:Hide()	
end

function ChipExchangeWindow:UpdateToggleActive(on, curTabIndex)
	local config = {
		self.Controls.m_Tog_Athletics,
		self.Controls.m_Tog_DiscSword,
		self.Controls.m_Tog_ChiValue,
		self.Controls.m_Tog_Reserve,
		self.Controls.m_Tog_Reserve2,
	}
	
	if on then 
		config[curTabIndex].transform:Find("ON").gameObject:SetActive(true)
		config[curTabIndex].transform:Find("OFF").gameObject:SetActive(false)
	else		
		config[curTabIndex].transform:Find("ON").gameObject:SetActive(false)
		config[curTabIndex].transform:Find("OFF").gameObject:SetActive(true)
	end
end
-------------------------------------------------------------------
-- Toggle 选中项被改变触发事件
-------------------------------------------------------------------
function ChipExchangeWindow:OnToggleChanged(on, curTabIndex)
	
	self:UpdateToggleActive(on, curTabIndex)
	if not on then
		return
	end
	
	if self.m_curTab ~= curTabIndex then 
		self.ChipExchangeWidget.ChipGoodsList:UpdateSelectedIndex()
	end
	self.m_curTab = curTabIndex
	-- 刷新当前切页物品信息
	self.ChipExchangeWidget:RefreshGoodsInfo(curTabIndex)
	--self:RefeshTabGoodsInfo(curTabIndex)	
end

-------------------------------------------------------------------
-- 初始化所有toggle组件
-------------------------------------------------------------------
function ChipExchangeWindow:InitToggle(npcID,bigType)
	
	self.Controls.m_Tog_Athletics.isOn	= false
	self.Controls.m_Tog_Athletics.gameObject:SetActive(false)
	
	self.Controls.m_Tog_ChiValue.isOn	= false
	self.Controls.m_Tog_ChiValue.gameObject:SetActive(false)
	
	self.Controls.m_Tog_DiscSword.isOn	= false
	self.Controls.m_Tog_DiscSword.gameObject:SetActive(false)
	
	self.Controls.m_Tog_Reserve.isOn	= false
	self.Controls.m_Tog_Reserve.gameObject:SetActive(false)
	
	self.Controls.m_Tog_Reserve2.isOn	= false
	self.Controls.m_Tog_Reserve2.gameObject:SetActive(false)
	
	local curTabInfo,num = IGame.ChipExchangeClient:GetSubTableInfo(npcID, bigType)
	
	-- 如果类型超过5个 超出部分不管
	for i = 1, num, 1 do
		if not curTabInfo[i] then 
			break
		end
		
		if 1 == i then
			self.Controls.m_Tog_Athletics.gameObject:SetActive(true)
			UIFunction.SetImageSprite(self.Controls.m_Image_Athletics_OFF, AssetPath.TextureGUIPath .. curTabInfo[i].OFF,function() self.Controls.m_Image_Athletics_OFF:SetNativeSize() end)
			UIFunction.SetImageSprite(self.Controls.m_Image_Athletics_ON, AssetPath.TextureGUIPath .. curTabInfo[i].ON,function() self.Controls.m_Image_Athletics_ON:SetNativeSize() end)

		elseif 2 == i then
			self.Controls.m_Tog_DiscSword.gameObject:SetActive(true)
			UIFunction.SetImageSprite(self.Controls.m_Image_Dis_OFF, AssetPath.TextureGUIPath .. curTabInfo[i].OFF,function() self.Controls.m_Image_Dis_OFF:SetNativeSize() end)
			UIFunction.SetImageSprite(self.Controls.m_Image_Dis_ON, AssetPath.TextureGUIPath .. curTabInfo[i].ON,function() self.Controls.m_Image_Dis_ON:SetNativeSize() end)
			
		elseif 3 == i then
			self.Controls.m_Tog_ChiValue.gameObject:SetActive(true)
			UIFunction.SetImageSprite(self.Controls.m_Image_Chi_OFF, AssetPath.TextureGUIPath .. curTabInfo[i].OFF,function() self.Controls.m_Image_Chi_OFF:SetNativeSize() end)
			UIFunction.SetImageSprite(self.Controls.m_Image_Chi_ON, AssetPath.TextureGUIPath .. curTabInfo[i].ON, function() self.Controls.m_Image_Chi_ON:SetNativeSize() end)

		elseif 4 == i then
			self.Controls.m_Tog_Reserve.gameObject:SetActive(true)
			UIFunction.SetImageSprite(self.Controls.m_Image_Res_OFF, AssetPath.TextureGUIPath .. curTabInfo[i].OFF,function() self.Controls.m_Image_Res_OFF:SetNativeSize() end)
			UIFunction.SetImageSprite(self.Controls.m_Image_Res_ON, AssetPath.TextureGUIPath .. curTabInfo[i].ON,function() self.Controls.m_Image_Res_ON:SetNativeSize() end)
		elseif 5 == i then
			self.Controls.m_Tog_Reserve2.gameObject:SetActive(true)		--多余的
			UIFunction.SetImageSprite(self.Controls.m_Button_Res2_OFF, AssetPath.TextureGUIPath .. curTabInfo[i].OFF,function() self.Controls.m_Button_Res2_OFF:SetNativeSize() end)
			UIFunction.SetImageSprite(self.Controls.m_Button_Res2_ON, AssetPath.TextureGUIPath .. curTabInfo[i].ON,function() self.Controls.m_Button_Res2_ON:SetNativeSize() end)
		end
				
	end
end
-------------------------------------------------------------------
-- 设置默认显示页面
-------------------------------------------------------------------
function ChipExchangeWindow:SetDefaultTab(curTabIndex)	
	
	local tableState = 
	{
		[self.tabName.emAthletics] = false,
		[self.tabName.emDiscussSword] = false,
		[self.tabName.emChivalrousValue] = false,
		[self.tabName.emReserve] = false,
		[self.tabName.emReserve2] = false,
	}
	if self.tabName.emAthletics == curTabIndex then 
		tableState[self.tabName.emAthletics] = true
	elseif self.tabName.emDiscussSword == curTabIndex then
		tableState[self.tabName.emDiscussSword]	= true
	elseif self.tabName.emChivalrousValue == curTabIndex then 
		tableState[self.tabName.emChivalrousValue]	= true
	elseif self.tabName.emReserve == curTabIndex then 
		tableState[self.tabName.emReserve]	= true
	elseif self.tabName.emReserve2 == curTabIndex then 
		tableState[self.tabName.emReserve2]	= true
	end
	for i, state in pairs(tableState) do
		if not state then
			self:UpdateToggleActive(false, i)
		end
	end
	
	self.Controls.m_Tog_Athletics.isOn	= tableState[self.tabName.emAthletics] 
	self.Controls.m_Tog_DiscSword.isOn	= tableState[self.tabName.emDiscussSword] 
	self.Controls.m_Tog_ChiValue.isOn	= tableState[self.tabName.emChivalrousValue]
	self.Controls.m_Tog_Reserve.isOn	= tableState[self.tabName.emReserve] 
	self.Controls.m_Tog_Reserve2.isOn	= tableState[self.tabName.emReserve2]
end	
-------------------------------------------------------------------
-- 初始化当前购买物品信息 
function ChipExchangeWindow:InitGoodsInfo()
		
	-- 右边的描述框 默认显示第一个
	local nIndex = self.m_selectItemIndex
	if nIndex == nil or nIndex <= 0 then
		nIndex = 1
	end
	self:UpdateExchangeGoodsInfo(nIndex)
end
-------------------------------------------------------------------
-- 更新右边物品详细描述 
function ChipExchangeWindow:InitExpenseInfo()
	local nIndex = self.m_selectItemIndex
	if nIndex == nil or nIndex <= 0 then
		nIndex = 1
	end
	-- 默认显示第一个	
	self:UpdateExchangeExpenseInfo(1)
end

-------------------------------------------------------------------
-- 更新右边物品详细描述  
-------------------------------------------------------------------
function ChipExchangeWindow:UpdateExchangeGoodsInfo(index)
	self.ChipExchangeWidget.m_selectItemIndex = index
	if not self.ChipExchangeWidget:isLoaded() then
		return
	end
	if not self.ChipExchangeWidget.ChipExchengeGoodsInfo:UpdateExchangeGoodsInfo(index) then
		uerror("[通用商城]刷新右侧物品详细信息失败，当前npcid :"..self.m_curNpcID.." 小类ID："..self.m_curTab)
		return
	end
end

-------------------------------------------------------------------
-- 更新兑换消费信息等
-------------------------------------------------------------------
function ChipExchangeWindow:UpdateExchangeExpenseInfo(index)
	self.ChipExchangeWidget.m_selectItemIndex = index
	if not self.ChipExchangeWidget:isLoaded() then
		return
	end
	if not self.ChipExchangeWidget.ChipExchengeExpense:UpdateExchangeExpenseInfo(index) then
		uerror("[通用商城]刷新右侧物品详细信息失败，当前npcid :"..self.m_curNpcID.." 小类ID："..self.m_curTab)
		return
	end
end

-- 购买成功之后 刷新限购次数跟剩余的货币
function ChipExchangeWindow:ReloadChipListItem()
	self.ChipExchangeWidget.ChipGoodsList:ReloadData()
end

-- 购买成功之后刷新
function ChipExchangeWindow:UpdateChipListItem(index)
	self.ChipExchangeWidget.ChipGoodsList:UpdateData(index)
end

-------------------------------------------------------------------
-- 刷新当前物品信息
-------------------------------------------------------------------
function ChipExchangeWindow:RefeshTabGoodsInfo(curTabIndex)
	
	--self.m_curTab = curTabIndex
	if not self.ChipExchangeWidget:isLoaded() then
		return
	end
	if not IGame.ChipExchangeClient:UpdateCurExchangeInfo(curTabIndex) then
		uerror("【ChipExchangeWindow:RefeshGoodsInfo】刷新当前分类数据失败，小类为："..curTabIndex)
		return
	end
	
	-- 刷新一个切页需要更新3项：
	-- 当前物品列表信息、当前兑换的物品信息、当前兑换的消耗信息
	self:ReloadChipListItem()
	
	self:InitGoodsInfo()
	self:InitExpenseInfo()
end	

-- 定时清空数据后重新刷新数据
function ChipExchangeWindow:RefreshGoodsInfo()
	if not IGame.ChipExchangeClient:UpdateCurExchangeInfo(self.m_curTab) then
		uerror("【ChipExchangeWindow:RefeshGoodsInfo】刷新当前分类数据失败，小类为："..curTabIndex)
		return
	end
	
	-- 刷新一个切页需要更新3项：
	-- 当前物品列表信息、当前兑换的物品信息、当前兑换的消耗信息
	self:ReloadChipListItem()
	
	self:InitGoodsInfo()
	self:InitExpenseInfo()
end

-- 更新货币数值
function ChipExchangeWindow:RefreshRecordData(eventData)
	if self.ChipExchangeWidget.ChipExchengeExpense then
		self.ChipExchangeWidget.ChipExchengeExpense:UpdateExpenseInfo()
	end
end

-- 添加新物品事件
function ChipExchangeWindow:OnEventAddGoods()
	if not self:isShow() then
		return
	end
	self:RefeshTabGoodsInfo(self.m_curTab)
end

-- 删除物品事件
function ChipExchangeWindow:OnEventRemoveGoods()
	self:OnEventAddGoods()
end


-- 显示当前信息
function ChipExchangeWindow:ShowExchangGoodsInfo(npcid, defaultSubTab, selectItemIndex)
	-- 初始化右边切换按钮，该隐藏的隐藏
	local defaultBigType = 1
	defaultSubTab = defaultSubTab or self.m_curTab
	if defaultSubTab == nil or defaultSubTab <= 0 then
		defaultSubTab = 1
	end
	self.m_selectItemIndex = selectItemIndex or 1
	self.m_curTab = defaultSubTab
	self.m_curNpcID = npcid
	self.m_curBigType	= defaultBigType
    if not self:isLoaded() then
        return
    end

	self:InitToggle(npcid, defaultBigType)
	-- 默认选择第一项小类进行显示
	self:SetDefaultTab(defaultSubTab)
	self:RefeshTabGoodsInfo(defaultSubTab) 
    -- 设置当前购买的npcid
    self.ChipExchangeWidget:ShowWidget(self.m_curNpcID, defaultSubTab, selectItemIndex )
end

-------------------------------------------------------------------
-- 设置提示框是否可见
-------------------------------------------------------------------
function ChipExchangeWindow:SetHintVisible(bool)
	self.Controls.m_ChipConfirmWidget.gameObject:SetActive(bool)
end

-------------------------------------------------------------------
-- 获取 数量框 中的值
-------------------------------------------------------------------
function ChipExchangeWindow:GetInputFieldNum()
	
	return self.ChipExchangeWidget.ChipExchengeExpense:GetInputFieldNum()
end	

-------------------------------------------------------------------
-- 获取 物品id
-------------------------------------------------------------------	
function ChipExchangeWindow:GetExchid()
	
	return IGame.ChipExchangeClient:GetExchidByIndex(self.ChipExchangeWidget.m_selectItemIndex)
end 
	
	
-------------------------------------------------------------------
-- 获取 奖励id
-------------------------------------------------------------------		
function ChipExchangeWindow:GetPrizeid()
	
	return IGame.ChipExchangeClient:GetPrizeidByIndex(self.ChipExchangeWidget.m_selectItemIndex)
end 
	
-------------------------------------------------------------------
-- 获取 是否绑定
-------------------------------------------------------------------	
function ChipExchangeWindow:GetuseUnBind()
	return IGame.ChipExchangeClient:GetuseUnBindByIndex(self.ChipExchangeWidget.m_selectItemIndex)
end

function  ChipExchangeWindow:UpdateNum(num)
    self.ChipExchangeWidget.ChipExchengeExpense:UpdateNum(num)
end

-------------------------------------------------------------------
-- 兑换按钮置灰
-------------------------------------------------------------------		
function ChipExchangeWindow:SetTradeBtnGrayState(on)
	if not self.ChipExchangeWidget:isLoaded() then
		return
	end
	self.ChipExchangeWidget.ChipExchengeExpense:SetTradeBtnGrayState(on)
end

return ChipExchangeWindow


