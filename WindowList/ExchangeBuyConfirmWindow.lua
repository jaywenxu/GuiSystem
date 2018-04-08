--/******************************************************************
--** 文件名:    ExchangeBuyConfirmWindow.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-26
--** 版  本:    1.0
--** 描  述:    摆摊购买确认窗口
--** 应  用:  
--******************************************************************/

local ExchangeBuyConfirmWindow = UIWindow:new
{
    windowName = "ExchangeBuyConfirmWindow",	-- 窗口名称
	
    m_IsWindowInvokeOnShow = false;    			-- 窗口是否调用了OnWindowShow方法的标识:boolean
	
	m_CurBuyCnt = 1,							-- 当前购买数量:number
	m_StallData = nil,							-- 摊位数据:ExchangeBillBaseInfo
	m_StallId = {},								-- 摊位id:long
	m_GoodsUid = {},							-- 物品uid:long
	m_ShowForCollect = false,					-- 是否在收藏下显示的标识:boolean
}

function ExchangeBuyConfirmWindow:Init()
	
end

function ExchangeBuyConfirmWindow:OnAttach( obj )
	
    UIWindow.OnAttach(self, obj)
  
    if self.m_IsWindowInvokeOnShow then
        self.m_IsWindowInvokeOnShow = false
        self:OnWindowShow()
    end
	
	self.Controls.m_ButtonGoodCell.onClick:AddListener(function() self:OnGoodCellButtonClick() end)
	self.Controls.m_ButtonClose.onClick:AddListener(function() self:OnCloseButtonClick() end)
	self.Controls.m_ButtonBuy.onClick:AddListener(function() self:OnBuyButtonClick() end)
	self.Controls.m_ButtonSubNum.onClick:AddListener(function() self:OnSubCntButtonClick() end)
	self.Controls.m_ButtonAddNum.onClick:AddListener(function() self:OnAddCntButtonClick() end)
	self.Controls.m_ButtonAddYinLiang.onClick:AddListener(function() self:OnAddYinLiangButtonClick() end)
	self.Controls.m_ButtonMask.onClick:AddListener(function() self:OnMaskButtonClick() end)
	self.Controls.m_ButtonGoodsCnt.onClick:AddListener(function() self:OnGoodsCntButtonClick() end)
	
    self.m_CurBuyCnt = 1
	
end


function ExchangeBuyConfirmWindow:OnDestroy()
	UIWindow.OnDestroy(self)

	table_release(self)			
end

function ExchangeBuyConfirmWindow:_showWindow()
	
    UIWindow._showWindow(self)
	
    if self:isLoaded() then
        self:OnWindowShow()
    else
        self.m_IsWindowInvokeOnShow = true
    end
	
end

-- 显示窗口
-- @stallId:摊位id:long
-- @showForCollect:是否在收藏下显示的标识:boolean
function ExchangeBuyConfirmWindow:ShowWindow(stallId, showForCollect)
	
	self.m_StallId = stallId
	self.m_ShowForCollect = showForCollect
	
	UIWindow.Show(self, true)
	
end


-- 窗口每次打开执行的行为
function ExchangeBuyConfirmWindow:OnWindowShow()
	
	if self.m_ShowForCollect then
		self.m_StallData = IGame.ExchangeClient:GetCollectStallData(self.m_StallId)
	else 
		self.m_StallData = IGame.ExchangeClient:GetShopStallData(self.m_StallId)
	end
	
	if not self.m_StallData then
		uerror("找不到其他玩家的摊位数据!")
		return
	end
	
	self.m_CurBuyCnt = 1
	
	-- 更新窗口的显示
	self:UpdateWindow()
	
end

-- 更新窗口的显示
function ExchangeBuyConfirmWindow:UpdateWindow()
	
	local hero = GetHero()
	if not hero then
		return
	end
	
	local haveYinLiang = hero:GetCurrency(emCoinClientType_YinLiang)
	local costYinLiang = self.m_CurBuyCnt * self.m_StallData.price
	
	if haveYinLiang >= costYinLiang then
		self.Controls.m_TextHaveYinLiang.color = UIFunction.ConverRichColorToColor("FFFFFF")
	else
		self.Controls.m_TextHaveYinLiang.color = UIFunction.ConverRichColorToColor("E4595A")
	end
	
	self.Controls.m_TextGoodsSelectedCnt.text = string.format("%d", self.m_CurBuyCnt)
	self.Controls.m_TextCostYinLiang.text = NumTo10Wan(costYinLiang)
	self.Controls.m_TextHaveYinLiang.text = NumTo10Wan(haveYinLiang)
	
	UIFunction.SetImageGray(self.Controls.m_ImageSubNum, self.m_CurBuyCnt <= 1)
	UIFunction.SetImageGray(self.Controls.m_ImageAddNum, self.m_CurBuyCnt >= self.m_StallData.goodsQnt)
	ExchangeWindowTool.SetGoodsIconAndBg(self.Controls.m_ImageGoodsIcon, self.Controls.m_ImageGoodsQuality, 
		self.m_StallData.goodsID, self.m_StallData.btColor, self.m_StallData.btProNum)
	ExchangeWindowTool.SetGoodsNameLabel(self.Controls.m_TextGoodsName, self.m_StallData.goodsID, self.m_StallData.btColor, self.m_StallData.btProNum, true)
	ExchangeWindowTool.SetGoodsNumLabel(self.Controls.m_TextGoodsCount, self.m_StallData.goodsID, self.m_StallData.goodsQnt)
	
end


-- 变更购买数量
-- @dstCnt:打算购买数量:number
function ExchangeBuyConfirmWindow:ChangeBuyCnt(dstCnt)
	
	self.m_CurBuyCnt = dstCnt
	if self.m_CurBuyCnt > self.m_StallData.goodsQnt then
		self.m_CurBuyCnt = self.m_StallData.goodsQnt
	elseif self.m_CurBuyCnt < 1 then
		self.m_CurBuyCnt = 1
	end
	
	-- 更新窗口的显示
	self:UpdateWindow()
	
end

-- 关闭按钮的点击行为
function ExchangeBuyConfirmWindow:OnCloseButtonClick()
	
	UIManager.ExchangeBuyConfirmWindow:Hide()
	
end

-- 物品图标的点击行为
function ExchangeBuyConfirmWindow:OnGoodCellButtonClick()
	
	local stallId = self.m_StallData.seq
	local goodsCfgId = self.m_StallData.goodsID
	local stallState = self.m_StallData.btState
	local tfItem = self.Controls.m_ButtonGoodCell.transform
	
	IGame.ExchangeClient:RequestExchangeGoodsTips(stallId, goodsCfgId, stallState, tfItem)
	
end

-- 减少物品数量按钮的点击行为
function ExchangeBuyConfirmWindow:OnSubCntButtonClick()
	
	-- 变更购买数量
	self:ChangeBuyCnt(self.m_CurBuyCnt - 1)
	
end

-- 增加物品数量按钮的点击行为
function ExchangeBuyConfirmWindow:OnAddCntButtonClick()
	
	-- 变更购买数量
	self:ChangeBuyCnt(self.m_CurBuyCnt + 1)
	
end

-- 增加银两按钮的点击行为
function ExchangeBuyConfirmWindow:OnAddYinLiangButtonClick()
	
	UIManager.ShopWindow:OpenShop(2415)
	
end

-- 遮罩按钮的点击行为
function ExchangeBuyConfirmWindow:OnMaskButtonClick()
	
	UIManager.ExchangeBuyConfirmWindow:Hide()
	
end

-- 购买按钮的点击行为
function ExchangeBuyConfirmWindow:OnBuyButtonClick()
	
	IGame.ExchangeClient:RequestExchangeBuyBills(self.m_StallData.seq, self.m_StallData.goodsID, self.m_CurBuyCnt, self.m_StallData.price)
	
end

-- 道具数量按钮的点击行为
function ExchangeBuyConfirmWindow:OnGoodsCntButtonClick()
	
	-- 数量不可以变得的时候，不要弹数量窗口
	if self.m_StallData.goodsQnt <= 1 then
		return
	end
	
	local onUpdateChange = function(num) 
		-- 变更购买数量
		self:ChangeBuyCnt(num)
		-- 更新窗口的显示
		self:UpdateWindow()
	end
	
	local numTable = {
	    ["inputNum"] = self.m_CurBuyCnt,
		["minNum"] = 1,
		["maxNum"] =  self.m_StallData.goodsQnt,
		["bLimitExchange"] = 0
	}
	
	local otherInfoTable = {
		["inputTransform"] = self.Controls.m_ButtonGoodsCnt.transform,
	    ["bDefaultPos"] = 1,
	    ["callback_UpdateNum"] = onUpdateChange
	}
	
	UIManager.NumericKeypadWindow:ShowWindow(numTable, otherInfoTable)
	
end

-- 数量输入栏结束时的行为
-- 模糊匹配
-- @inputField:输入栏控件:InputField
--[[function ExchangeBuyConfirmWindow:OnCountInputEndEdit(inputField)
	
	local dstCnt = 1
	if self.m_InputGoodsCnt.text ~= "" then
		dstCnt = tonumber(self.m_InputGoodsCnt.text)
	end
	
	-- 变更购买数量
	self:ChangeBuyCnt(dstCnt)
	-- 更新窗口的显示
	self:UpdateWindow()
	
end--]]

return ExchangeBuyConfirmWindow