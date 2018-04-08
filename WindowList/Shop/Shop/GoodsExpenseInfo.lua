
--local ShopWidgetClass = require("GuiSystem.WindowList.Shop.Shop.ShopWidget")

local GoodsExpenseInfo = UIControl:new
{
	windowName 	= "GoodsExpenseInfo",
	
	------------------------------------------------------------
	-- 暂时只支持货币
	------------------------------------------------------------
	m_nType		= 0,				-- 货币类型
	m_price		= 0,				-- 单价
	m_nGoodsID	= 0,				-- 是否有物品id
	m_nBuyCount	= 0,				-- 购买的数量
	m_index     = 0,                -- 记录item的索引
    m_GoodsType = 0,				--item所属类型
	m_DefaultCount	= 1,		

	m_GoodsIndex = 0,				--记录item索引	
	m_NeedShowUseYuanBaoTip = false, --是否需要显示元宝
}

local this = GoodsExpenseInfo

function GoodsExpenseInfo:Init()
end

-------------------------------------------------------------------
-- 设置Icon	
-------------------------------------------------------------------


function GoodsExpenseInfo:Attach(obj)
	UIControl.Attach(self,obj)
	
	-- 数量+ 按钮事件
	self.callback_AddBtnClick = function() self:OnAddButtonClick() end
	self.Controls.m_Button_Add.onClick:AddListener(self.callback_AddBtnClick)
	
	--增加货物
	self.OnAddCurrencyClickCB = function() self:OnAddCurrencyBtnClick() end 
	self.Controls.m_AddBtnHave.onClick:AddListener(self.OnAddCurrencyClickCB)
	
	-- 数量- 按钮事件
	self.callback_SubBtnClick = function() self:OnSubButtonClick() end
	self.Controls.m_Button_Sub.onClick:AddListener(self.callback_SubBtnClick)
	
	-- 当InputField值被改变时
	self.callback_OnValueChange = function() self:OnValueChanged() end
	self.Controls.m_Input_Value:GetComponent(typeof(InputField)).onValueChanged:AddListener(self.callback_OnValueChange)
	
	-- 初始化
	self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text  = tostring(self.m_DefaultCount)
	
	-- 打开输入界面按钮事件
	self.callback_InputBtnClick = function() self:OnInputButtonClick() end
	self.Controls.m_InputButton.onClick:AddListener(self.callback_InputBtnClick)
	
	self.callback_UpdateNum = function(num) self:UpdateNum(num) end
end

--设置父对象
function GoodsExpenseInfo:SetParentWidget(parent)
	self.ParentWidget = parent
end

-------------------------------------------------------------------
-- 所有归零
-------------------------------------------------------------------
function GoodsExpenseInfo:Clean()
	
	self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text  = 0
	self.Controls.m_Text_Consume.text = 0
	self.m_nType		= 0				-- 货币类型
	self.m_price		= 0				-- 单价
	self.m_nGoodsID		= 0				-- 是否有物品id
	self.m_nBuyCount		= 0				-- 购买的数量
end

-------------------------------------------------------------------
-- 设置Icon	
-------------------------------------------------------------------
function GoodsExpenseInfo:SetIcon(nType)
	if not AssetPath_CurrencyIcon[nType] then
		return
	end
	self.CurrencyType = nType
	UIFunction.SetImageSprite(self.Controls.m_Image_Expense, AssetPath_CurrencyIcon[nType])
	UIFunction.SetImageSprite(self.Controls.m_Image_Own, AssetPath_CurrencyIcon[nType])
end

-- 设置当前物品的货币类型及单价信息
function GoodsExpenseInfo:SetGoodsCost(subGoods)
	
	if not subGoods or not subGoods.nYuanbaoType or not subGoods.nPrice then
		return
	end
	self.m_nType = subGoods.nYuanbaoType
	
	--打折的商品
	if subGoods.bCut ~= 1 then
		self.m_price = subGoods.nPrice
	else
		local price = subGoods.nPrice
		self.m_price = Mathf.Round(price * subGoods.nCutPercent / 100)        --道具单价
	end
	
	
	if 1 == self.m_nType then   		-- 物品
		self.m_nGoodsID = subGoods.nGoodsID
	end
	self:SetIcon(self.m_nType)
	
end

--获得本次购买的花费
function GoodsExpenseInfo:GetTotalGoodsCost()
	return self.m_price * self.m_nBuyCount
end

-------------------------------------------------------------------
-- 设置默认购买数量
-------------------------------------------------------------------
function GoodsExpenseInfo:UpdateGoodsCount()
	self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text  = tostring(self.m_nBuyCount)
end

-- 角色当前的物品数量
function GoodsExpenseInfo:GetOwnStuffData()
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return 0
	end
    if self.m_index == 0 then
		self.m_index = 1
	end

	local nType = self.m_nType
	local nValue = 0
	if 1 == nType then   		-- 钻石
		nValue = pHero:GetActorYuanBao()												
	elseif 2 == nType then 		-- 银两
		nValue = pHero:GetYinLiangNum()	
	elseif 3 == nType then 		-- 银币					--这里要和服务器统一		TODO
		nValue = pHero:GetYinBiNum()
	end	

	return nValue
end

-------------------------------------------------------------------
-- 设置 拥有 数据
-- @param  nType : 要显示的货币类型  
-------------------------------------------------------------------
function GoodsExpenseInfo:UpdateOwnInfoData()
	local nValue = self:GetOwnStuffData()
	
	local nTotalValue = tonumber(self.m_price) * tonumber(self.m_nBuyCount)
	if nTotalValue > nValue then
		self.Controls.m_Text_Total.text = "<color=#e4595a>" .. tostring(nValue) .. "</color>" 
	else
		self.Controls.m_Text_Total.text = nValue
	end
end

-- 刷新购买的物品信息，数量*单价
function GoodsExpenseInfo:UpdateGoodsInfo()
	if not self.m_price or not self.m_nBuyCount then
		return 
	end
	--local nValue = self:GetOwnStuffData()
	local nTotalValue = tonumber(self.m_price) * tonumber(self.m_nBuyCount)
	self.Controls.m_Text_Consume.text = tostring(nTotalValue)
	
end

-------------------------------------------------------------------
-- 刷新购买数量信息\单价
-------------------------------------------------------------------
function GoodsExpenseInfo:UpdateExpenseInfo(nGoodsType,index)
	self:UpdateOwnInfoData()
	self:UpdateGoodsCount()
	self:UpdateGoodsInfo()
	self:UpdateBuyBtn(nGoodsType,index)
	self:UpdateAddMinusBtn(nGoodsType,index)
end

--更新加减按钮			是否置灰，取消交互
function GoodsExpenseInfo:UpdateAddMinusBtn(nGoodsType,index)
	local nCount = self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text or 1
		
	local info = IGame.PlazaClient:GetInfoByIndex(self.m_GoodsType,self.m_index)
	local nLimitExchange = IGame.PlazaClient:IsLimitBuy(self.m_GoodsType,self.m_index)
		
	nCount = tonumber(nCount)
	if nLimitExchange == 0 then
		self:SetAddBtnState(false)
	else
		local n, count = IGame.PlazaClient:GetLimitToGoodsTime(self.m_GoodsType,self.m_index)
		if nil ~= n and nil ~= count then 
				if 1 == n then 
					local exist =  IGame.PlazaClient:GetLimitGoodsCountByDay(info.nSaleID)					--日限购，
					if count <= exist + nCount then 	--达到限定次数，无法增加
						self:SetAddBtnState(true)			
					else
						self:SetAddBtnState(false)
					end
				elseif 2 == n then 			
					local exist =  IGame.PlazaClient:GetLimitGoodsCountByWeek(info.nSaleID)					--周限购
					if count <= exist + nCount then 	--达到限定次数，无法增加
						self:SetAddBtnState(true)
					else
						self:SetAddBtnState(false)
					end
				end	
		end	 
	end
	
	if nCount <= 1 then
		self:SetMinusBtnState(true)
	else
		self:SetMinusBtnState(false)
	end
end

function GoodsExpenseInfo:SetMinusBtnState(gray)
	UIFunction.SetImageGray(self.Controls.m_SubBtnImg,gray)
	local interactable = not gray
	self.Controls.m_Button_Sub.interactable = interactable
end

function GoodsExpenseInfo:SetAddBtnState(gray)
	UIFunction.SetImageGray(self.Controls.m_AddBtnImg,gray)
	local interactable = not gray
	self.Controls.m_Button_Add.interactable = interactable
end


--更新购买按钮
function GoodsExpenseInfo:UpdateBuyBtn(nGoodsType,index)
	self.m_GoodsType = nGoodsType
	self.m_GoodsIndex = index
	local info = IGame.PlazaClient:GetInfoByIndex(nGoodsType,index)
	local nLimitExchange = IGame.PlazaClient:IsLimitBuy(nGoodsType,index)
	
	if not nLimitExchange then
		UIFunction.SetImgComsGray(self.ParentWidget.Controls.m_BuyBtnImage.gameObject,false)
		self.ParentWidget.Controls.m_BuyBtn.interactable  = true
	else
		local n, count = IGame.PlazaClient:GetLimitToGoodsTime(nGoodsType,index)
		if nil ~= n and nil ~= count then 
				if 1 == n then 
					local exist =  IGame.PlazaClient:GetLimitGoodsCountByDay(info.nSaleID)					--日限购，
					if count <= exist then 
						UIFunction.SetImgComsGray(self.ParentWidget.Controls.m_BuyBtnImage.gameObject,true)
						self.ParentWidget.Controls.m_BuyBtn.interactable  = false
					else
						UIFunction.SetImgComsGray(self.ParentWidget.Controls.m_BuyBtnImage.gameObject,false)
						self.ParentWidget.Controls.m_BuyBtn.interactable  = true
					end
				elseif 2 == n then 			
					local exist =  IGame.PlazaClient:GetLimitGoodsCountByWeek(info.nSaleID)					--周限购
					if count <= exist then 
						UIFunction.SetImgComsGray(self.ParentWidget.Controls.m_BuyBtnImage.gameObject,true)
						self.ParentWidget.Controls.m_BuyBtn.interactable  = false
					else
						UIFunction.SetImgComsGray(self.ParentWidget.Controls.m_BuyBtnImage.gameObject,false)
						self.ParentWidget.Controls.m_BuyBtn.interactable  = true
					end
				end	
		end	 
	end
	
	self:UpdateAddMinusBtn(nGoodsType,index)
end

function GoodsExpenseInfo:UpdateExpenseChangedInfo()
	self:UpdateGoodsCount()
	self:UpdateGoodsInfo()
end

function GoodsExpenseInfo:SetGoodsIndex(index)
	self.m_index = index
end

-------------------------------------------------------------------
-- 更新消费信息等		
-------------------------------------------------------------------
function GoodsExpenseInfo:UpdateGoodsExpenseInfo(nGoodsType,index)
	self.m_GoodsType = nGoodsType
	-- 清除消耗
	self:Clean()	
	
	local goods = IGame.PlazaClient:GetGoodsData(nGoodsType, index)
	local subGoods = IGame.PlazaClient:GetInfoByIndex(nGoodsType, index)	
	
	if nil == goods or nil == subGoods then
		return 
	end
	
	local defaultNum = 0							--表里没有
	
    if defaultNum == 0 then 
		defaultNum = 1
	end
	self.m_index = index
	self.m_nBuyCount = tonumber(defaultNum)
	
	----------------------------------------------------------
	--self:SetGoodsCost(subGoods)
	
	self.m_nType = subGoods.nYuanbaoType
	
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return 
	end
	local curCurrency = 0
	if 1 == self.m_nType then   		-- 钻石
		curCurrency = pHero:GetActorYuanBao()												
	elseif 2 == self.m_nType then 		-- 银两
		curCurrency = pHero:GetYinLiangNum()	
	elseif 3 == self.m_nType then 		-- 银币					--这里要和服务器统一		TODO
		curCurrency = pHero:GetYinBiNum()
	end	
	
	
	--打折的商品
	if subGoods.bCut ~= 1 then
		self.m_price = subGoods.nPrice
	else
		local price = subGoods.nPrice
		self.m_price = Mathf.Round(price * subGoods.nCutPercent / 100)        --道具单价
	end
	
	
	if 1 == self.m_nType then   		-- 物品
		self.m_nGoodsID = subGoods.nGoodsID
	end
	
	local nTotalValue = tonumber(self.m_price) * tonumber(self.m_nBuyCount)
	
	self.m_NeedShowUseYuanBaoTip = false
	if nTotalValue > curCurrency then
		if self.m_nType == 3 then						--银币检测，银币不足用银两
			if nTotalValue > pHero:GetYinLiangNum() then 
				
			else
				self.m_nType = 2
				self.m_NeedShowUseYuanBaoTip = true
			end
		end
	end
	
	self:SetIcon(self.m_nType)
	
	
	
	-- 刷新消耗
	self:UpdateExpenseInfo(nGoodsType,index)
	return true
end

-------------------------------------------------------------------
-- 设置购买数量
-------------------------------------------------------------------
function GoodsExpenseInfo:SetBuyCount(nNum)
	
	self.m_nBuyCount = tonumber(nNum)
end

-- 控件修改变化
function GoodsExpenseInfo:OnValueChanged()
	
	local nCount = self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text or 1
	self:SetBuyCount(nCount)
	-- 刷新消耗
	self:UpdateExpenseChangedInfo()
end

-------------------------------------------------------------------
-- 点击增加数量按钮	
-------------------------------------------------------------------
function GoodsExpenseInfo:OnAddButtonClick()
	local nCount = self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text or 1
		
	local info = IGame.PlazaClient:GetInfoByIndex(self.m_GoodsType,self.m_index)
	local nLimitExchange = IGame.PlazaClient:IsLimitBuy(self.m_GoodsType,self.m_index)
	
	nCount = tonumber(nCount)
	if 0 == nLimitExchange then
		nCount = nCount + 1
	else
		local n, count = IGame.PlazaClient:GetLimitToGoodsTime(self.m_GoodsType,self.m_index)
		if nil ~= n and nil ~= count then 
				if 1 == n then 
					local exist =  IGame.PlazaClient:GetLimitGoodsCountByDay(info.nSaleID)					--日限购，
					if count <= exist then 	--达到限定次数，无法增加
						return				
					else
						local leftNum = count - exist
						if nCount < leftNum then
							nCount = nCount + 1
						end
					end
				elseif 2 == n then 			
					local exist =  IGame.PlazaClient:GetLimitGoodsCountByWeek(info.nSaleID)					--周限购
					if count <= exist then 	--达到限定次数，无法增加
						return
					else
						local leftNum = count - exist
						if nCount < leftNum then
							nCount = nCount + 1
						end
					end
				end	
		end	 
	end

	if nCount >= 1000 then
		nCount = 999
	end
	self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text = tostring(nCount)
	
	self:UpdateAddMinusBtn(self.m_GoodsType,self.m_index)
end

-------------------------------------------------------------------
-- 点击减少数量按钮	
-------------------------------------------------------------------
function GoodsExpenseInfo:OnSubButtonClick()	
	local nCount = self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text or 1
	local nNewCount = tonumber(nCount) - 1
	-- 至少保留一个
	if nNewCount <= 0 then
		nNewCount = 1			
	end
	self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text = tostring(nNewCount)
	
	self:UpdateAddMinusBtn(self.m_GoodsType,self.m_index)
end

-------------------------------------------------------------------
-- 获取输入框的值	
-------------------------------------------------------------------
function GoodsExpenseInfo:GetInputFieldNum()
	local num = self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text
	if nil == num then 
		return 0
	end
	
	return tonumber(num)
end	

-- 点击输入按钮，响应打开输入数字界面
function GoodsExpenseInfo:OnInputButtonClick() 
	local goods = IGame.PlazaClient:GetGoodsData(self.m_GoodsType, self.m_index)
	local subGoods = IGame.PlazaClient:GetInfoByIndex(self.m_GoodsType, self.m_index)	

	if not goods or not subGoods then
		return
	end
	
	local limitBuy = subGoods.nTypeFlag
	local exchMaxNum
	local nLimitExchange = false
	
	if limitBuy == 1 then 				--限购
		nLimitExchange = true
		local n, count = IGame.PlazaClient:GetLimitToGoodsTime(self.m_GoodsType, self.m_index)		--读表的限购数量
		local exist
		if n == 1 then
			exist =  IGame.PlazaClient:GetLimitGoodsCountByDay(subGoods.nSaleID)			--服务器返回已经购买的数量
		else
			exist =  IGame.PlazaClient:GetLimitGoodsCountByWeek(subGoods.nSaleID)
		end 
		exchMaxNum = count - exist
	else
		exchMaxNum = subGoods.nLimitNum
		if exchMaxNum == 0 then
			exchMaxNum = 9999
		end
		
		if exchMaxNum > 0 then
			nLimitExchange = true
		else
			nLimitExchange = false
		end
	end

	local num = self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text

	local numTable = {
	    ["inputNum"] = num,
		["minNum"]   = 1,
		["maxNum"]   =  exchMaxNum,  --exchMaxNum, 
		["bLimitExchange"] =  nLimitExchange --nLimitExchange
	}
	local otherInfoTable = {
		["inputTransform"] =  self.Controls.m_Input_Value,
	    ["bDefaultPos"] = 1,
	    ["callback_UpdateNum"] = self.callback_UpdateNum
	}
	
	UIManager.NumericKeypadWindow:ShowWindow(numTable, otherInfoTable)
end

--更新购买数量
function GoodsExpenseInfo:UpdateNum(num)
	self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text = num
	self:UpdateAddMinusBtn(self.m_GoodsType,self.m_index)
end

--增加货币按钮点击回调
function GoodsExpenseInfo:OnAddCurrencyBtnClick()
	local way = gCurrencyCfg.CurrencyGetCfg[self.CurrencyType]
	if way == 0 then
		UIManager.ShopWindow:ShowShopWindow(UIManager.ShopWindow.tabName.emDeposit)
	else
		UIManager.ShopWindow:OpenShop(way)
	end
end


return this