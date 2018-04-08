
--商会
local ItemCellClass = require( "GuiSystem.WindowList.Shop.Shop.GoodsItemCell" )

local CofCWidget = UIControl:new {
	windowName = "CofCWidget",
	
	tabName = {
		Toggle_1	     = 1,
		Toggle_2    	 = 2,
		Toggle_3    	 = 3,
	},
	
	m_GoodsScriptsCache = {},						--物品script缓存
	
	m_CurTab = 0,									--当前选中的分页索引
	m_JumpToIndex = -1,								--打开跳转到的物品
	m_CurSelectIndex = 0,							--当前选中的物品索引
	
	m_CurBuyGoodsNum = 1,							--当前购买数量
	m_CurrencyType = 0,								--当前的货币类型
	m_CurGoodsUnitPrice = 0,						--当前道具单价
	m_CurTotalCost = 0,								--当前总花费
	m_CurConfigRecord = nil, 						--配置表一条记录
	
	m_CanBuy = true,								--当前是否可以购买
	
	m_ShouUseYinLiangTip = false,					--银币不足，需要用银两
}

function CofCWidget:Attach(obj)
	UIControl.Attach(self,obj)

	--控件事件订阅
	self.callback_BuyBtn = function() self:OnBuyBtnClick() end
	self.Controls.m_BuyBtn.onClick:AddListener(self.callback_BuyBtn)
	
	self.NumMinusClickCB = function() self:OnNumberMinusBtnClick() end
	self.Controls.m_SubBtn.onClick:AddListener(self.NumMinusClickCB)
	
	self.NumAddClickCB = function() self:OnNumberAddBtnClick() end
	self.Controls.m_AddBtn.onClick:AddListener(self.NumAddClickCB)
	
	self.AddCurrentyClickCB = function() self:OnAddCurencyBtnClick() end
	self.Controls.m_AddHaveBtn.onClick:AddListener(self.AddCurrentyClickCB)
	
	self.InputBtnCB = function() self:OnInputBtnClick() end
	self.Controls.m_InputButton.onClick:AddListener(self.InputBtnCB)
	
	self.Controls.GoodsToggleGroup =  self.Controls.m_GoodsToggleGroup:GetComponent(typeof(ToggleGroup))
	
	--物品条目点击事件
	self.GoodsSelectedCB = function(item, on) self:OnItemClick(item,on) end
	
	self.callback_Toggle_1	= function(on) self:OnToggleChanged(on, self.tabName.Toggle_1) end
	self.Controls.m_Toggle_1.onValueChanged:AddListener(self.callback_Toggle_1)
	
	self.callback_Toggle_2	= function(on) self:OnToggleChanged(on, self.tabName.Toggle_2) end
	self.Controls.m_Toggle_2.onValueChanged:AddListener(self.callback_Toggle_2)
	
	self.callback_Toggle_3	= function(on) self:OnToggleChanged(on, self.tabName.Toggle_3) end
	self.Controls.m_Toggle_3.onValueChanged:AddListener(self.callback_Toggle_3)
	
	self.Controls.InputCom = self.Controls.m_Input_Value:GetComponent(typeof(InputField))
	self.callback_OnValueChange = function() self:OnValueChanged() end
	if self.Controls.InputCom then
		self.Controls.InputCom.onValueChanged:AddListener(self.callback_OnValueChange)
	end

	self.callback_UpdateNum = function(num) self:UpdateCofCNum(num) end
	
	self.RefreshCb = function(_,_,_, plazaID) self:RefreshBuySuccess(plazaID) end			--购买成功刷新事件
	rktEventEngine.SubscribeExecute(EVENT_SHOP_BUYSUCCESS,0,0,self.RefreshCb)
	
	self:InitToggle()
	
end

function CofCWidget:Show()
	UIControl.Show(self)
	
	if self.m_JumpToIndex and self.m_JumpToIndex > 0 then
		self:JumpToCofCGoods(self.m_JumpToIndex)
	
	else
		self.m_JumpToIndex = -1
		
		for i,data in pairs(self.m_ToggleControls) do
			data.isOn = false
		end
		
		if self.m_CurTab > 0 then
			self.m_ToggleControls[self.m_CurTab].isOn = false
		end
		
		self.m_ToggleControls[1].isOn = false
		self.m_ToggleControls[1].isOn = true
	end
end

function CofCWidget:Hide(destroy)
	UIControl.Hide(self,destroy)
end

function CofCWidget:OnDestroy()
	self.m_CurTab = 0
	rktEventEngine.UnSubscribeExecute(EVENT_SHOP_BUYSUCCESS,0,0,self.RefreshCb)
	UIControl.OnDestroy(self)
end

-------------------------------------------------------------------
-- 初始化所有toggle组件					这里没必要这样初始化，这里固定是两个toggle,这么写也可以
-------------------------------------------------------------------
function CofCWidget:InitToggle()	
	self.Controls.m_Toggle_1.isOn	= false
	self.Controls.m_Toggle_1.gameObject:SetActive(false)
	
	self.Controls.m_Toggle_2.isOn	= false
	self.Controls.m_Toggle_2.gameObject:SetActive(false)

	self.Controls.m_Toggle_3.isOn	= false
	self.Controls.m_Toggle_3.gameObject:SetActive(false)

	--TODO
	local tabTable = IGame.PlazaClient:GetCofCTabList()		--获取配置表中的Tab信息

	self.m_ToggleControls = {
		self.Controls.m_Toggle_1,
		self.Controls.m_Toggle_2,
		self.Controls.m_Toggle_3,
	}
	
	self.m_ToggleTextHightLigt = {
		self.Controls.m_ToggleText_1,
		self.Controls.m_ToggleText_2,
		self.Controls.m_ToggleText_3,
	}
	
	self.m_ToggleText =
	{
		self.Controls.m_ToggleText2_1,
		self.Controls.m_ToggleText2_2,
		self.Controls.m_ToggleText2_3,
	}
	
	for i, data in pairs(tabTable) do
		self.m_ToggleControls[i].gameObject:SetActive(true)
		self.m_ToggleTextHightLigt[i].text = data.szName
		self.m_ToggleText[i].text = data.szName
	end
end

-------------------------------------------------------------------
-- Toggle 选中项被改变触发事件
-------------------------------------------------------------------
function CofCWidget:OnToggleChanged(on, curTabIndex)
	if on then 
		self.m_ToggleControls[curTabIndex].transform:Find("ON").gameObject:SetActive(true)
		self.m_ToggleControls[curTabIndex].transform:Find("OFF").gameObject:SetActive(false)
	else		
		self.m_ToggleControls[curTabIndex].transform:Find("ON").gameObject:SetActive(false)
		self.m_ToggleControls[curTabIndex].transform:Find("OFF").gameObject:SetActive(true)
		return
	end

	if self.m_JumpToIndex > -1 then							--需要跳转的情况下
	
	else	
		if self.m_CurTab == curTabIndex then 				-- 不需要跳转直接返回
			return 
		end
	end
	
	self.m_CurTab = curTabIndex
	
	-- 刷新当前切页物品信息											--不会出现有tab标签，但是下面没有item的情况
	self:RefeshCofCTabGoodsInfo(curTabIndex)	
end

--对外接口，跳转到指定分页
function CofCWidget:OpenCofCGoods(goodsID)
	self.m_JumpToIndex = goodsID
	self:Show()
end

--跳转到指定分页				TODO
function CofCWidget:JumpToCofCGoods(goodsID)
	
end


--刷新商会子分页
function CofCWidget:RefeshCofCTabGoodsInfo(index)
	if index == 1 then
		self.Controls.m_TipText.gameObject:SetActive(true)
	else
		self.Controls.m_TipText.gameObject:SetActive(false)
	end
	self:InitGoodsList(index)
end

--初始化
function CofCWidget:InitGoodsList(index)
	local tableNum = table.getn(self.m_GoodsScriptsCache) 
	if tableNum > 0 then
		for i, data in pairs(self.m_GoodsScriptsCache) do
			data:Destroy()
		end
	end
	
	self.m_GoodsScriptsCache = {}
	
	--根据类型获取商会子分页物品数据		TODO
	local goodsTable = IGame.PlazaClient:GetCofCGoodsListByType(index)
	if not goodsTable then return end
	
	local loadNum = 0
	local nNum = table_count(goodsTable)
	for i, data in pairs(goodsTable) do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.GoodsItemCell ,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_GoodsGrid)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = ItemCellClass:new({})
			item:Attach(obj)
			item:SetToggleGroup(self.Controls.GoodsToggleGroup)
			item:SetSelectCallback(self.GoodsSelectedCB)
			
			item:SetCofCCellInfo(self.m_CurTab,i)
			item:SetCofCIcon(self.m_CurTab, i)
			
			item:SetFocus(false)
			
			table.insert(self.m_GoodsScriptsCache,i,item)	
			loadNum = loadNum + 1
			if loadNum == nNum then
				if self.m_JumpToIndex ~= -1 then
					self.m_GoodsScriptsCache[self.m_JumpToIndex]:SetFocus(true)
					self.m_JumpToIndex = -1
				else
					self.m_GoodsScriptsCache[1]:SetFocus(true)
				end
			end
			
		end , i , AssetLoadPriority.GuiNormal )
	end
end

--清空显示信息
function CofCWidget:CleanInfoView()
	-- 先清除数据
	self.Controls.m_CurGoodsNameText.text = ""
	self.Controls.m_CurGoodsDesText.text = ""
	self.Controls.m_CurGoodsEffectText.text = ""
	self.Controls.m_CurGoodsLevelText.text = ""					--等级区域
	self.Controls.m_CurGoodsHaveText.text = ""					--info区域
end

--更新商会商品信息界面显示,   record - 物品分表的一条记录
function CofCWidget:RefreshInfoWidget(record)
	self:CleanInfoView()
	
	if record then 
		if not self.Controls.m_CurGoodsInfoParent.gameObject.activeInHierarchy then
			self.Controls.m_CurGoodsInfoParent.gameObject:SetActive(true)
		end
	else
		self.Controls.m_CurGoodsInfoParent.gameObject:SetActive(false)
		return
	end
	
	--物品总表的一条记录
	local goods = IGame.PlazaClient:GetCofCGoodsData(self.m_CurTab, self.m_CurSelectIndex)
	if not goods then return end
	
	local goodsType = record.nSelectType 
	
	if 1 == goodsType then						--装备
		
	elseif 2 == goodsType then					--物品
		UIFunction.SetImageSprite(self.Controls.m_CurGoodsIcon , AssetPath.TextureGUIPath..goods.lIconID1)
		UIFunction.SetImageSprite(self.Controls.m_CurGoodsQuality , AssetPath.TextureGUIPath..goods.lIconID2)		
	end

	local buyLevel = record.nBuyLevel
	
	local pHero = GetHero()
	if not pHero then
		return
	end
	
	local curLevel = pHero:GetNumProp(CREATURE_PROP_LEVEL)
	
	self.Controls.m_CurGoodsLevelText.text = ""
	if goods.lAllowLevel > 0 then
		if curLevel < goods.lAllowLevel then
			self.Controls.m_CurGoodsLevelText.gameObject:SetActive(true)
			self.Controls.m_CurGoodsLevelText.text = string.format("<color=#e4595a>%d级</color>", goods.lAllowLevel)
		else
			self.Controls.m_CurGoodsLevelText.text = goods.lAllowLevel .. "级"
		end
	end
	if goods.nShowType == 0 then
		self.Controls.m_CurGoodsHaveText.text = ""
		local szEffectText = goods.subDesc1 or ""
		if szEffectText ~= "" and goods.subDesc2 then
			szEffectText = szEffectText .. "\n"..goods.subDesc2
		end
		self.Controls.m_CurGoodsEffectText.text = szEffectText
	else
		self.Controls.m_CurGoodsEffectText.text = ""
		self.Controls.m_CurGoodsHaveText.text = string.format("拥有<color=#10A41B>%d</color>个", GameHelp:GetHeroGoodsNum(goods.lGoodsID))
	end
	
	self.Controls.m_CurGoodsNameText.text = string.format("<color=#%s>%s</color>",AssetPath_GoodsQualityColor[goods.lBaseLevel],goods.szName) or ""
	
	self.Controls.m_CurGoodsDesText.text = goods.szDesc or ""
end

--更新商品购买面板显示
function CofCWidget:RefreshBuyInfoWidget(record)
	if not record or not record.nYuanbaoType or not record.nPrice then
		return
	end
	
	self.m_CurrencyType = record.nYuanbaoType
	
	--打折的商品
	if record.bCut ~= 1 then
		self.m_CurGoodsUnitPrice = record.nPrice
	else
		local price = record.nPrice
		self.m_CurGoodsUnitPrice = Mathf.Round(price * record.nCutPercent / 100)        --道具单价
	end
	
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end

	local nType = self.m_CurrencyType
	local nValue = 0
	if 1 == nType then   		-- 钻石
		nValue = pHero:GetActorYuanBao()												
	elseif 2 == nType then 		-- 银两
		nValue = pHero:GetYinLiangNum()	
	elseif 3 == nType then 		-- 银币					--这里要和服务器统一		TODO
		nValue = pHero:GetYinBiNum()
	end	
	
	local nTotalValue = tonumber(self.m_CurGoodsUnitPrice) * tonumber(self.m_CurBuyGoodsNum)
	self.m_CurTotalCost = nTotalValue
	if nTotalValue > nValue then
		if self.m_CurrencyType == 3 then
			if nTotalValue > pHero:GetYinLiangNum() then
				self.Controls.m_CurHaveText.text = "<color=#e4595a>" .. tostring(nValue) .. "</color>" 
				self.m_CanBuy = false
				self.m_ShouUseYinLiangTip = false
			else
				self.Controls.m_CurHaveText.text =  tostring(pHero:GetYinLiangNum()) 
				self.m_CanBuy = true
				self.m_ShouUseYinLiangTip = true
				self.m_CurrencyType = 2
			end
		else
			self.Controls.m_CurHaveText.text = "<color=#e4595a>" .. tostring(nValue) .. "</color>" 
			self.m_CanBuy = false
			self.m_ShouUseYinLiangTip = false
		end
	else
		self.Controls.m_CurHaveText.text = nValue
		self.m_CanBuy = true
		self.m_ShouUseYinLiangTip = false
	end
	self.Controls.m_CurTotalCostText.text = nTotalValue
	
	self.Controls.InputCom.text = tostring(self.m_CurBuyGoodsNum)
	
	UIFunction.SetImageSprite(self.Controls.m_CurCostIcon, AssetPath_CurrencyIcon[self.m_CurrencyType])
	UIFunction.SetImageSprite(self.Controls.m_CurHaveIcon, AssetPath_CurrencyIcon[self.m_CurrencyType])
	
	self:UpdateCofCAddMinusBtn(self.m_CurTab, self.m_CurSelectIndex)
end

---------------------------按钮回调事件
--购买商品点击回调
function CofCWidget:OnBuyBtnClick()
	--判断是否是钻石，如果是钻石不够的话，弹出充值面板,其他的不处理
	if self.m_CurrencyType == 1 then
		-- 钻石不足，是否前往充值，打开充值界面
		if GameHelp:DiamondNotEnoughSwitchRecharge(self.m_CurTotalCost) then
			return
		end
	end
	if self.m_CanBuy then
		if self.m_ShouUseYinLiangTip then 
			
			local data = {
				content = "当前银币不足，是否消耗银两购买。",
				confirmCallBack = function() 
					GameHelp.PostServerRequest("RequestPlazaData(".. self.m_CurConfigRecord.nSaleID..","..self.m_CurBuyGoodsNum..")") 
				end
			}
			UIManager.ConfirmPopWindow:ShowDiglog(data)
		else
			if self.m_CurConfigRecord then
				GameHelp.PostServerRequest("RequestPlazaData(".. self.m_CurConfigRecord.nSaleID..","..self.m_CurBuyGoodsNum..")")
			end
		end
	else
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "货币不足，无法购买")
	end
end

--输入区域点击回调
function CofCWidget:OnInputBtnClick()
	
	local goods = IGame.PlazaClient:GetCofCGoodsData(self.m_CurTab, self.m_CurSelectIndex)
	local subGoods = self.m_CurConfigRecord

	if not goods or not subGoods then
		return
	end
	
	local limitBuy = subGoods.nTypeFlag
	local exchMaxNum
	local nLimitExchange = false
	
	if limitBuy == 1 then 				--限购
		nLimitExchange = true
		local n, count = IGame.PlazaClient:GetCofCLimitToGoodsTime(self.m_CurTab, self.m_CurSelectIndex)		--读表的限购数量
		local exist
		if n == 1 then
			exist =  IGame.PlazaClient:GetCofCLimitGoodsCountByDay(subGoods.nSaleID)			--服务器返回已经购买的数量
		else
			exist =  IGame.PlazaClient:GetCofCLimitGoodsCountByWeek(subGoods.nSaleID)
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

--小键盘输入响应
function CofCWidget:UpdateCofCNum(num)
	self.Controls.InputCom.text = num
	self.m_CurBuyGoodsNum = num
	self:UpdateCofCAddMinusBtn(self.m_CurTab, self.m_CurSelectIndex)
	self:RefreshBuyInfoWidget(self.m_CurConfigRecord)
end

function CofCWidget:OnValueChanged()
	--self:RefreshBuyInfoWidget(self.m_CurConfigRecord)
end


--减号按钮点击回调
function CofCWidget:OnNumberMinusBtnClick()
	self.m_CurBuyGoodsNum = self.m_CurBuyGoodsNum - 1
	if self.m_CurBuyGoodsNum < 1 then
		self.m_CurBuyGoodsNum = 1
	end
	self:RefreshBuyInfoWidget(self.m_CurConfigRecord)
	self:UpdateCofCAddMinusBtn(self.m_CurTab, self.m_CurSelectIndex)
end

--加号按钮点击回调
function CofCWidget:OnNumberAddBtnClick()
	if not self.m_CurConfigRecord then return end
		
	local info = self.m_CurConfigRecord
	local nLimitExchange
	if goods == nil or goods.GoodsTime == 0 or goods.GoodsTime == nil then
		nLimitExchange = 0
	else
		nLimitExchange = goods.GoodsTime
	end

	if 0 == nLimitExchange then
		self.m_CurBuyGoodsNum = self.m_CurBuyGoodsNum + 1
	else
		local n, count = IGame.PlazaClient:GetCofCLimitToGoodsTime(self.m_CurTab, self.m_CurSelectIndex)
		if nil ~= n and nil ~= count then 
				if 1 == n then 
					local exist =  IGame.PlazaClient:GetCofCLimitGoodsCountByDay(info.nSaleID)					--日限购，
					if count <= exist then 	--达到限定次数，无法增加
						return				
					else
						local leftNum = count - exist
						if self.m_CurBuyGoodsNum < leftNum then
							self.m_CurBuyGoodsNum = self.m_CurBuyGoodsNum + 1
						end
					end
				elseif 2 == n then 			
					local exist =  IGame.PlazaClient:GetCofCLimitGoodsCountByWeek(info.nSaleID)					--周限购
					if count <= exist then 	--达到限定次数，无法增加
						return
					else
						local leftNum = count - exist
						if self.m_CurBuyGoodsNum < leftNum then
							self.m_CurBuyGoodsNum = self.m_CurBuyGoodsNum + 1
						end
					end
				end	
		end	 
	end

	if self.m_CurBuyGoodsNum >= 1000 then
		self.m_CurBuyGoodsNum = 999
	end

	self:RefreshBuyInfoWidget(self.m_CurConfigRecord)
	self:UpdateCofCAddMinusBtn(self.m_CurTab, self.m_CurSelectIndex)
end

--更新加减按钮
function CofCWidget:UpdateCofCAddMinusBtn(nType, nIndex)
	local nCount = self.Controls.InputCom.text or 1
		
	local info = IGame.PlazaClient:GetCofCConfigInfoByIndex(nType,nIndex)
	local nLimitExchange = IGame.PlazaClient:IsCofCLimitBuy(nType,nIndex)
		
	nCount = tonumber(nCount)
	if nLimitExchange == 0 then
		self:SetAddBtnState(false)
	else
		local n, count = IGame.PlazaClient:GetCofCLimitToGoodsTime(nType,nIndex)
		if nil ~= n and nil ~= count then 
				if 1 == n then 
					local exist =  IGame.PlazaClient:GetCofCLimitGoodsCountByDay(info.nSaleID)					--日限购，
					if count <= exist + nCount then 	--达到限定次数，无法增加
						self:SetAddBtnState(true)			
					else
						self:SetAddBtnState(false)
					end
				elseif 2 == n then 			
					local exist =  IGame.PlazaClient:GetCofCLimitGoodsCountByWeek(info.nSaleID)					--周限购
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

function CofCWidget:SetMinusBtnState(gray)
	UIFunction.SetImageGray(self.Controls.m_SubBtnImg,gray)
	local interactable = not gray
	self.Controls.m_SubBtn.interactable = interactable
end

function CofCWidget:SetAddBtnState(gray)
	UIFunction.SetImageGray(self.Controls.m_AddBtnImg,gray)
	local interactable = not gray
	self.Controls.m_AddBtn.interactable = interactable
end


--增加货币按钮点击回调
function CofCWidget:OnAddCurencyBtnClick()
	local way = gCurrencyCfg.CurrencyGetCfg[self.m_CurrencyType]
	if way == 0 then
		UIManager.ShopWindow:ShowShopWindow(UIManager.ShopWindow.tabName.emDeposit)
	else
		UIManager.ShopWindow:OpenShop(way)
	end
end

--物品条目点击回调
function CofCWidget:OnItemClick(item,on)
	self.m_CurSelectIndex = item.m_index
	self.m_CurBuyGoodsNum = 1
	local record = IGame.PlazaClient:GetCofCConfigInfoByIndex(self.m_CurTab, item.m_index) 
	if record then
		self.m_CurConfigRecord = record
		--刷新
		self:RefreshInfoWidget(record)
		self:RefreshBuyInfoWidget(record)
	else
		self.m_CurConfigRecord = nil
	end
end

--购买成功刷新物品
function CofCWidget:RefreshBuySuccess(plazaID)
	local cellitem = nil
	for i,data in pairs(self.m_GoodsScriptsCache) do
		if data.m_plazaID == plazaID then
			cellitem = data
		end
	end
	if cellitem and cellitem.m_type == self.m_CurTab then
		cellitem:SetCofCCellInfo(cellitem.m_type,cellitem.m_index)
	end
	local record = IGame.PlazaClient:GetCofCConfigInfoByIndex(self.m_CurTab, self.m_CurSelectIndex) 
	if not record then return end
	self:RefreshBuyInfoWidget(record)
end


return CofCWidget