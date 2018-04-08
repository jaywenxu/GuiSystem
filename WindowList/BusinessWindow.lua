-------------------------------------------------------------------
-- 版  权:	(C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:	HaoWei
-- 日  期:	2017.8.15
-- 版  本:	1.0
-- 描  述:	帮会跑商
-------------------------------------------------------------------
-----------------------跑商窗口---------------------------------
local BusinessItemClass = require( "GuiSystem.WindowList.Business.BusinessItem" )

local BusinessWindow = UIWindow:new
{
	windowName 	= "BusinessWindow",
	
	m_NPCID = 0,			--缓存当前NPCID
	m_NPCUID = 0,			--缓存当前npcUID
	
	m_CurGoodsID = 0, 		--当前点击的item对应的物品ID， 升降价卡使用
	
	m_CurTab = 0, 			--当前商人分页
	m_CurSubTab = 0, 		--当前的子分页  1-出售，2-收购
	
	businessItemChchae = {},		--缓存脚本表
	
	m_InBusiness = false,			--是否处于跑商状态
	
	m_StartTopLeftTime = -1, 		--打开界面开始计时时刻,为了精确计时,防止定时器误差积累
	m_StartBottomLeftTime = -1,	

	m_CacheTopLeftTime = -1,		--缓存的剩余时间， 虚拟计时变量
	m_CacheBottomLeftTime = -1,		
	
	m_subIndex1 = nil,				--索引缓存， 用于切换到之前选中子分页
	m_subIndex2 = nil,
	m_subIndex3 = nil, 
}

--或改为读表配置
local ID2Page = {
	[5802] = 1,
	[5803] = 2,
	[5804] = 3,
}
local Page2ID = {
	[1] = 5802,
	[2] = 5803,
	[3] = 5804,
}

--跑商评级
local BusinessQuality = {
	AssetPath.TextureGUIPath .. "Business/Mobilestore_pj_putong.png",						--普通
	AssetPath.TextureGUIPath .. "Business/Mobilestore_pj_youxiu.png",						--优秀
	AssetPath.TextureGUIPath .. "Business/Mobilestore_pj_zhuoyue.png",						--卓越
	AssetPath.TextureGUIPath .. "Business/Mobilestore_pj_wanmei.png",						--完美
	AssetPath.TextureGUIPath .. "Business/Mobilestore_pj_nitian.png",						--逆天
	AssetPath.TextureGUIPath .. "Business/Mobilestore_pj_chaoshen.png",						--超神				
}

function BusinessWindow:OnAttach(obj)
	UIWindow.OnAttach(self,obj)
	
	self.TweenAnim = self.Controls.m_BusinessPanel:GetComponent(typeof(DG.Tweening.DOTweenAnimation))
	
	self.BusinessToggleCtl = {
		self.Controls.m_NanZhaoToggle,
		self.Controls.m_GaoLiToggle,
		self.Controls.m_BoSiToggle,
	}
	
	self.SubToggleCtl = {
		self.Controls.m_SaleToggle,
		self.Controls.m_BuyToggle,
	}
	
	--GOTO按钮
	self.GoToCB = function() self:OnGoToBtnClick() end
	self.Controls.m_GoButton.onClick:AddListener(self.GoToCB)
	
	--关闭按钮
	self.CloseWindowCB = function() self:CloseWindow() end
	self.Controls.m_FoldButton.onClick:AddListener(self.CloseWindowCB)
	
	--事件定义 - 打开界面
	self.OnOpenWindowCB = function(npcID) self:OnOpenWindow(npcID) end
	--事件定义 - 更新时间
	self.updateTimerFunc = function() self:UpdateTime() end
	--事件定义 - 跑商结束
	self.EndCB = function() self:EndPaoShang() end
	--事件定义 - 刷新物品
	self.UpdateGoodsItemCB = function() self:UpdateGoodsItem() end
	--事件定义 - 购买物品
	self.PurchaseGoodsCB = function(goodsID) self:PurchaseGoods(goodsID) end
	--事件定义 - 出售物品
	self.SaleGoodsCB = function(goodsID) self:SaleGoods(goodsID) end
	--事件定义 - 使用升价卡
	self.UseUpCardCB = function(goodsID) self:UseUpCard(goodsID) end
	--事件定义 - 使用降价卡
	self.UseDownCardCb = function(goodsID) self:UseDownCard(goodsID) end
	--事件定义 - 跑商次数更新
	self.UpdateTimesCB = function() self:OnUpdateTimes() end
	
	self:InitView(self.tNpcID, self.tNpcUID, self.tFirstShow)
end

function BusinessWindow:Show( bringTop)		
	UIWindow.Show(self, bringTop)
end

function BusinessWindow:Hide(destory)
	rktTimer.KillTimer(self.updateTimerFunc)
	self.setTimer = false
	self.m_InBusiness = false
	self:RemoveEvent()
	
	self.m_StartTopLeftTime = -1
	self.m_StartBottomLeftTime = -1
	
	self.m_subIndex1 = nil
	self.m_subIndex2 = nil
	self.m_subIndex3 = nil
	
	if self.BottomLeftTime <= 0 then
		GameHelp.PostServerRequest("RequestClanBusinessNotBusiness(0)")
	end	
	
	--事件注销
	rktEventEngine.UnSubscribeExecute(EVENT_CLANBUSINESS_UPDATE_PRICE,SOURCE_TYPE_CLAN,0,self.UpdateGoodsItemCB)
	rktEventEngine.UnSubscribeExecute(EVENT_CLANBUSINESS_UPDATE_MONEY, SOURCE_TYPE_CLAN, 0,self.UpdateGoodsItemCB)
	rktEventEngine.UnSubscribeExecute(EVENT_CLAN_UPDATETIMES, SOURCE_TYPE_CLAN, 0,self.UpdateTimesCB)
	rktEventEngine.UnSubscribeExecute(EVENT_CLAN_TIMEEND, SOURCE_TYPE_CLAN, 0, self.EndCB)
	
	UIWindow.Hide(self, destory)
end

function BusinessWindow:OnDestroy()
	self.m_InBusiness = false
	UIWindow.OnDestroy(self)
end

--控件事件注册
function BusinessWindow:RegisterEvent()
	self:RemoveEvent()
	local num = #self.BusinessToggleCtl
	local subNum = #self.SubToggleCtl
	for i = 1, num do 
		local toggleChangeCB = function(on) self:OnToggleChanged(on,i) end
		self.BusinessToggleCtl[i].onValueChanged:AddListener(toggleChangeCB)
	end
	
	for i = 1, subNum do
		local subToggleChangeCB = function(on) self:OnSubToggleChanged(on,i) end
		self.SubToggleCtl[i].onValueChanged:AddListener(subToggleChangeCB)
	end
end
--控件事件注销
function BusinessWindow:RemoveEvent()
	local num = #self.BusinessToggleCtl
	local subNum = #self.SubToggleCtl
	for i = 1, num do 
		self.BusinessToggleCtl[i].onValueChanged:RemoveAllListeners()
	end
	
	for i = 1, subNum do
		self.SubToggleCtl[i].onValueChanged:RemoveAllListeners()
	end
end

--打开指定分页
function BusinessWindow:OpenBusinessWindow(npcID, npcUID, firstShow)
	self:OnOpenWindow(npcID, npcUID, firstShow)
end

--打开界面
function BusinessWindow:OnOpenWindow(npcID, npcUID, firstShow)
	self:Show()
	
	if self:isLoaded() then
		self:InitView(npcID, npcUID, firstShow)
	else
		self.tNpcID = npcID
		self.tNpcUID = npcUID
		self.tFirstShow = firstShow
	end
end

function BusinessWindow:InitView(npcID, npcUID, firstShow)
	self.m_NPCUID = npcUID
	self.m_NPCID = npcID
	if firstShow then
		self.TweenAnim:DORestart(false) 
	end
	self.BusinessToggleCtl[ID2Page[npcID]].isOn = true
	self.m_CurTab = ID2Page[npcID]
	
	--红点设置
	self:SetRedPointView()
	--评级设置
	self:SetQuality()
	--初始化npc名字
	self:InitNPCToggleName()
	--判断显示哪个子分页
	self:InitItemList(npcID)
	--完成界面初始化
	self:InitTopLeftTime()
	self:InitBottomView()
	--开启定时器更新倒计时
	rktTimer.KillTimer(self.updateTimerFunc)
	rktTimer.SetTimer( self.updateTimerFunc, 30, -1, "BusinessWindow:UpdateTime")
	self.setTimer = true
	--订阅刷新事件
	rktEventEngine.SubscribeExecute(EVENT_CLANBUSINESS_UPDATE_PRICE,SOURCE_TYPE_CLAN,0,self.UpdateGoodsItemCB)
	rktEventEngine.SubscribeExecute(EVENT_CLANBUSINESS_UPDATE_MONEY, SOURCE_TYPE_CLAN, 0,self.UpdateGoodsItemCB)
	rktEventEngine.SubscribeExecute(EVENT_CLAN_UPDATETIMES, SOURCE_TYPE_CLAN, 0,self.UpdateTimesCB)
	rktEventEngine.SubscribeExecute(EVENT_CLAN_TIMEEND, SOURCE_TYPE_CLAN, 0, self.EndCB)
end

--初始化NPC名字, 扩展预留，目前写死
function BusinessWindow:InitNPCToggleName()
	
end

--显示item列表
function BusinessWindow:InitItemList(npcID)
	if not npcID or npcID <= 0 then
		return
	end
	local manager = IGame.ClanClient.m_ClanBusinessManager
	if not manager then
		return
	end
	
	local haveBuy = manager:CheckHaveGoods(npcID)
	--已经购买过了，默认打开收购分页
	if haveBuy then
		self:RefreshListItem(npcID, false)
		self.SubToggleCtl[2].isOn = true
		self.m_CurSubTab = 2
	else
		self:RefreshListItem(npcID, true)
		self.SubToggleCtl[1].isOn = true
		self.m_CurSubTab = 1
	end
	
	--注册toggle事件，关闭界面的时候注销掉
	self:RemoveEvent()
	self:RegisterEvent()

	self.BusinessToggleCtl[ID2Page[npcID]].transform:Find("Select").gameObject:SetActive(true)
end

--生成listItem 
function BusinessWindow:RefreshListItem(npcID, isSalePage)
	local manager = IGame.ClanClient.m_ClanBusinessManager
	if not manager then
		return
	end
	
	local goodsTable = IGame.ClanClient.m_ClanBusinessManager:GetGoodsData(npcID, isSalePage)
	local goodsCount = #goodsTable

	local count = #self.businessItemChchae
	if count > 0 then
		for i,data in pairs(self.businessItemChchae) do
			data:Destroy()
		end
	end
	self.businessItemChchae = {}
	
	local showUpAndDownBtn = self:CheckHaveCard(isSalePage)							--内部已经区分是否有对应的卡
	
    local bBuy = (manager:CheckBuyWhoseGoods() ~= 0)

	for i = 1, goodsCount do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.BusinessItem,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_ListParent, false)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = BusinessItemClass:new({})
			item:Attach(obj)
			--显示设置
			local data = goodsTable[i]
			item:SetBuyWidget(isSalePage)
			item:SetGoodsID(data.dwGoodsID)
			--local exName = manager:GetShouGouBusinessManName(data.dwGoodsID)
			--item:SetExName(exName)
			if showUpAndDownBtn then												--是否显示升降价卡图标
				item:SetShowUpAndDownCard(true, isSalePage)						
			else
				item:SetShowUpAndDownCard(false)
			end
			local num = self:CheckHaveGoods(data.dwGoodsID)						--控制已购显示
			if isSalePage then
				if data.bDownIng then 	--降价中
					item:SetSalePrice("<color=green>"..data.nNpcSalePrice.."</color>")
					item:SetDowning()
				else
					item:SetSalePrice(data.nNpcSalePrice)								--出售价格
					item:CancleDown()
				end
				if data.bUpIng then		--涨价中
					item:SetSaleShouGouPrice("<color=red>"..data.nNpcBuyPrice.."</color>")
				else
					item:SetSaleShouGouPrice(data.nNpcBuyPrice)							--收购价格
				end
				
				item:SetYiGou(num, bBuy)	
				--买点击回调
				item:SetGouMaiCB(self.PurchaseGoodsCB)
				item:SetUpAndDownCb(self.UseDownCardCb)
                
                item:ShowTipsText(data.nNpcSalePrice, data.nNpcBuyPrice)
			else
				if data.bUpIng then		--收购涨价中
					item:SetShouGouPrice("<color=red>"..data.nNpcBuyPrice.."</color>")
					item:SetUPing()
				else
					item:SetShouGouPrice(data.nNpcBuyPrice)								--收购分页收购价格
					item:CancleUp()
				end
				if num > 0 then
					item:SetMaiBtnEnable(true)
				else
					item:SetMaiBtnEnable(false)
				end
				item:SetShouGouHaveNum(num)
				
				item:SetChuShouCB(self.SaleGoodsCB)
				item:SetUpAndDownCb(self.UseUpCardCB)
			end
			
			table.insert(self.businessItemChchae,i,item)	
		end , i , AssetLoadPriority.GuiNormal )
	end
end

--初始化剩余时间
function BusinessWindow:InitTopLeftTime()
	local manager = IGame.ClanClient.m_ClanBusinessManager
	if not manager then
		return 
	end
	local leftTime = manager:GetPriceData().dwTimeLeft
	
	self.TopLeftTime = leftTime
	
	self.Controls.m_TopRefreshText.text = SecondTimeToString(leftTime)
	
	self.m_CacheTopLeftTime = luaGetTickCount()
end

--初始化底部显示信息
function BusinessWindow:InitBottomView()
	local manager = IGame.ClanClient.m_ClanBusinessManager
	if not manager then
		return 
	end
	
	local bottomLeftTime = manager:GetLeftTime()
	local curMoney = manager:GetCurMoney()
	local gouMaiCount = manager:GetSaleCount()
	
	self.BottomLeftTime = bottomLeftTime
	
	if self.BottomLeftTime >= 0 then
		self.m_InBusiness = true
	end
	
	--活动结束打开界面
	if bottomLeftTime <= 0 then 
		self:SetUIShow(false)
	else
		self:SetUIShow(true)
	end
	
	self.Controls.m_CurrentCoinText.text = "当前资金:" .. NumToWan(curMoney)
	self.Controls.m_PurchaseTimesText.text = string.format("购买次数:  <color=green>%d/20</color>", gouMaiCount)
	self.Controls.m_LeftTimeText.text = "剩余时间:  " .. SecondTimeToString(bottomLeftTime)
	
	self.m_StartBottomLeftTime = luaGetTickCount()
	self.m_CacheBottomLeftTime = self.m_StartBottomLeftTime
end

--定时器更新剩余时间
function BusinessWindow:UpdateTime()
	local curTime = luaGetTickCount()
	local topPassTime = curTime - self.m_CacheTopLeftTime
	local bottomPassTime = curTime - self.m_CacheBottomLeftTime
	

	self.m_CacheTopLeftTime = curTime
	self.TopLeftTime = self.TopLeftTime - topPassTime / 1000
	
	self.m_CacheBottomLeftTime = curTime
	self.BottomLeftTime = self.BottomLeftTime - bottomPassTime / 1000


	self.Controls.m_LeftTimeText.text = "剩余时间:  " .. SecondTimeToString(self.BottomLeftTime)
	self.Controls.m_TopRefreshText.text = SecondTimeToString(self.TopLeftTime)
	
	--任务结束，把身上的物品卖出
	if self.BottomLeftTime <= 0 then
		self:SetUIShow(false)
		self.m_CacheTopLeftTime = -1
		self.m_CacheBottomLeftTime = -1
		rktTimer.KillTimer(self.updateTimerFunc)
		self.setTimer = false
	end
end

--关闭界面
function BusinessWindow:CloseWindow()
	self.TweenAnim:DOPlayBackwards()
	rktTimer.SetTimer(function() self:Hide() end, 100, 1, "BusinessWindow:Hide()")
end

--商人Toggle分页改变事件
function BusinessWindow:OnToggleChanged(on, index)
	if on then
		if self.m_CurTab == index then
			return
		else
			self.m_CurTab = index
		end	
		self.BusinessToggleCtl[index].transform:Find("Select").gameObject:SetActive(true)
	else
		self.BusinessToggleCtl[index].transform:Find("Select").gameObject:SetActive(false)
		return
	end
	
	if index == 1 then
		if not self.m_subIndex1 then
			if not self.SubToggleCtl[2].isOn then 
				self:RefreshListItem(Page2ID[self.m_CurTab], true)
			end
			self.SubToggleCtl[1].isOn = true
			self.m_subIndex1 = 1
			return
		end
	elseif index == 2 then
		if not self.m_subIndex2 then
			if not self.SubToggleCtl[2].isOn then 
				self:RefreshListItem(Page2ID[self.m_CurTab], true)
			end
			self.SubToggleCtl[1].isOn = true
			self.m_subIndex2 = 1
			
			return
		end
	elseif index == 3 then
		if not self.m_subIndex3 then
			if not self.SubToggleCtl[2].isOn then 
				self:RefreshListItem(Page2ID[self.m_CurTab], true)
			end
			self.SubToggleCtl[1].isOn = true
			self.m_subIndex3 = 1
			return
		end
	end
	
	if index == 1 then
		if self.SubToggleCtl[1].isOn then
			if self.m_subIndex1 and self.m_subIndex1 == 1 then
				self:RefreshListItem(Page2ID[self.m_CurTab], true)
			else
				self.SubToggleCtl[2].isOn = true
			end
		else
			if  self.m_subIndex1 and self.m_subIndex1 == 1 then
				self.SubToggleCtl[1].isOn = true
			else
				self:RefreshListItem(Page2ID[self.m_CurTab], false)
			end
		end
	elseif index == 2 then
		if self.SubToggleCtl[1].isOn then
			if self.m_subIndex2 and self.m_subIndex2 == 1 then
				self:RefreshListItem(Page2ID[self.m_CurTab], true)
			else
				self.SubToggleCtl[2].isOn = true
			end
		else
			if self.m_subIndex2 and self.m_subIndex2 == 1 then
				self.SubToggleCtl[1].isOn = true
			else
				self:RefreshListItem(Page2ID[self.m_CurTab], false)
			end
		end	
	elseif index == 3 then
		if self.SubToggleCtl[1].isOn then
			if self.m_subIndex3 and self.m_subIndex3 == 1 then
				self:RefreshListItem(Page2ID[self.m_CurTab], true)
			else
				self.SubToggleCtl[2].isOn = true
			end
		else
			if self.m_subIndex3 and self.m_subIndex3 == 1 then
				self.SubToggleCtl[1].isOn = true
			else
				self:RefreshListItem(Page2ID[self.m_CurTab], false)
			end
		end
	end
end

--子分页，Toggle切换事件
function BusinessWindow:OnSubToggleChanged(on, index)
	if on then 
		if self.m_CurSubTab == index then
			return
		else
			self.m_CurSubTab = index
		end
	else
		return
	end
	
	if self.m_CurTab == 1 then
		self.m_subIndex1 = index
	elseif self.m_CurTab == 2 then 
		self.m_subIndex2 = index
	elseif self.m_CurTab == 3 then
		self.m_subIndex3 = index
	end
	
	local isSale = true
	if index == 2 then
		isSale = false
	end
	
	self:RefreshListItem(Page2ID[self.m_CurTab], isSale)
end

--刷新回调
function BusinessWindow:UpdateGoodsItem()
	local manager = IGame.ClanClient.m_ClanBusinessManager
	if not manager then
		return 
	end
	
	--红点刷新
	self:SetRedPointView()
	--评级刷新
	self:SetQuality()
    
    local bBuy = (manager:CheckBuyWhoseGoods() ~= 0)
	
	for i, data in pairs(self.businessItemChchae) do
		local goodsData = manager:GetGoodsDataByID(data.m_ID)
		--升降价卡
		local isSalePage = true
		if self.m_CurSubTab == 2 then
			isSalePage = false
		end
		local showUpAndDownBtn = self:CheckHaveCard(isSalePage)
		if showUpAndDownBtn then												--是否显示升降价卡图标
			data:SetShowUpAndDownCard(true, isSalePage)						
		else
			data:SetShowUpAndDownCard(false)
		end
		local haveNum = self:CheckHaveGoods(data.m_ID)
		if self.m_CurSubTab == 1 then
			if goodsData.bDownIng then
				data:SetSalePrice("<color=green>"..goodsData.nNpcSalePrice.."</color>")
				data:SetDowning()
			else
				data:SetSalePrice(goodsData.nNpcSalePrice)			--出售分页-出售价格
				data:CancleDown()
			end
			if goodsData.bUpIng then
				data:SetSaleShouGouPrice("<color=red>"..goodsData.nNpcBuyPrice.."</color>")
			else
				data:SetSaleShouGouPrice(goodsData.nNpcBuyPrice)	--出售分页-收购价格
			end
			data:SetYiGou(haveNum, bBuy)		--出售分页-已购数量
            
            data:ShowTipsText(goodsData.nNpcSalePrice, goodsData.nNpcBuyPrice)
		else
			--收购界面
			if goodsData.bUpIng then
				data:SetShouGouPrice("<color=red>"..goodsData.nNpcBuyPrice.."</color>")
				data:SetUPing()
			else
				data:SetShouGouPrice(goodsData.nNpcBuyPrice)
				data:CancleUp()
			end
			data:SetShouGouHaveNum(haveNum)
			if haveNum > 0 then
				data:SetMaiBtnEnable(true)
			else
				data:SetMaiBtnEnable(false)
			end
		end
	end
	
	--非list部分刷新
	local bottomLeftTime = manager:GetLeftTime()
	self.m_CacheTopLeftTime = luaGetTickCount()

	local curMoney = manager:GetCurMoney()
	local gouMaiCount = manager:GetSaleCount()
	

	
	if bottomLeftTime <= 0 then 
		self:SetUIShow(false)
		return
	else
		self:SetUIShow(true)
	end
	
	local leftTime = manager:GetPriceData().dwTimeLeft
	self.TopLeftTime = leftTime
	self.m_CacheBottomLeftTime = luaGetTickCount()
	
	self.Controls.m_TopRefreshText.text = SecondTimeToString(self.TopLeftTime)
	self.Controls.m_CurrentCoinText.text = "当前资金:" .. NumToWan(curMoney)
    self.Controls.m_PurchaseTimesText.text = string.format("购买次数:  <color=green>%d/20</color>", gouMaiCount)
--	self.Controls.m_LeftTimeText.text = "剩余时间:" .. SecondTimeToString(bottomLeftTime)
	
	if not self.setTimer then			--没有开启定时器，就开启
		if self.BottomLeftTime > 0 or self.TopLeftTime > 0 then
			rktTimer.KillTimer(self.updateTimerFunc)
			if bottomLeftTime > 0 then
				self.BottomLeftTime = bottomLeftTime
			end
			rktTimer.SetTimer(self.updateTimerFunc, 30, -1, "BusinessWindow:UpdateTime")
		end
	end
end

--活动是否结束, 显示or隐藏UI
function BusinessWindow:SetUIShow(show)
	self.Controls.m_TopLeftTimeWidget.gameObject:SetActive(show)
	self.Controls.m_BottomWidget.gameObject:SetActive(show)
end

--跑商结束
function BusinessWindow:EndPaoShang()
	self.m_InBusiness = false
	self:SetUIShow(false)
	rktTimer.KillTimer(self.updateTimerFunc)
	
	local manager = IGame.ClanClient.m_ClanBusinessManager
	if not manager then
		return 
	end
	manager:SetLeftTime(0)
end

--GoTo按钮
function BusinessWindow:OnGoToBtnClick()
	--导航到指定Npc	
	TalkWithNPC(Page2ID[self.m_CurTab])
	self:CloseWindow()
end

--检查是否有升降价卡	upCard - true 升价卡， false 降价卡
function BusinessWindow:CheckHaveCard(isSalePage)
	local goodsID

	if isSalePage then
		goodsID = g_ClanBusinessCardSubGoodID
	else
		goodsID = g_ClanBusinessCardAddGoodID
	end
	
	local ret = self:CheckHaveGoods(goodsID)
	if ret > 0 then
		return true
	end
	return false
end

--检查背包中是否有相关物品
function BusinessWindow:CheckHaveGoods(goodsID)
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		uerror("packetPart is nil")
		return
	end
	
	local num = packetPart:GetVaildGoodNum(goodsID)
	return num
end

--请求方法
--购买物品
function BusinessWindow:PurchaseGoods(goodsID)
	local flag = 0
	local manager = IGame.ClanClient.m_ClanBusinessManager
	if not manager then
		return 
	end
	
	local haveBuy = manager:CheckHaveGoods(self.m_NPCID)
	if haveBuy then 
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "只有卖出已买货物才可购买")
		return
	end
	
	local whoSale = manager:GetWhoSaleByGoodsID(goodsID)
	if whoSale == self.m_NPCID and self.m_NPCUID ~= 0 then 
		local salePrice = manager:GetGoodsDataByID(goodsID).nNpcSalePrice
		local buyPrice = manager:GetGoodsDataByID(goodsID).nNpcBuyPrice
        if salePrice > buyPrice then
            local contentStr = "您所将要购买的物品处于<color=red>亏损</color>价格，是否仍要购买"
            local data = {
                content = contentStr,
                confirmCallBack = function() 
                    GameHelp.PostServerRequest("RequestClanBusinessShop("..flag..","..goodsID..","..salePrice..","..self.m_NPCUID..")") 
                end,
            }
            UIManager.ConfirmPopWindow:ShowDiglog(data)
        else
           GameHelp.PostServerRequest("RequestClanBusinessShop("..flag..","..goodsID..","..salePrice..","..self.m_NPCUID..")") 
        end
		--self:CloseWindow()
	elseif whoSale == 0 then
		
	else
		--self:CloseWindow()
		TalkWithNPC(whoSale)
	end
end
--出售物品
function BusinessWindow:SaleGoods(goodsID)
	
	local flag = 1
	local manager = IGame.ClanClient.m_ClanBusinessManager
	if not manager then
		return 
	end
	
	local haveBuy = self:CheckHaveGoods(goodsID)
	if not haveBuy then return end
	
	local shougouNpcID = manager:CheckBuyWhoseGoods()

	if shougouNpcID == self.m_NPCID and self.m_NPCUID ~= 0 then
		local price = manager:GetGoodsDataByID(goodsID).nNpcBuyPrice
		GameHelp.PostServerRequest("RequestClanBusinessShop("..flag..","..goodsID..","..price..","..self.m_NPCUID..")")
	else
		self:CloseWindow()
		TalkWithNPC(shougouNpcID)
	end
end
--使用升价卡
function BusinessWindow:UseUpCard(goodsID)
	if not self.m_InBusiness then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "活动未开始，无法使用涨价卡")
		return
	end
	self.m_CurGoodsID = goodsID
	--local contentStr = "确定使用涨价卡吗?"
	local contentStr = "是否要对".. GameHelp.GetLeechdomColorName(goodsID) .."涨价?"
	local data = {
		content = contentStr,
		confirmCallBack = function() self:OnConfirmUseUpCard() end,
	}
	UIManager.ConfirmPopWindow:ShowDiglog(data)
end
--使用降价卡
function BusinessWindow:UseDownCard(goodsID)
	if not self.m_InBusiness then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "活动未开始，无法使用降价卡")
		return
	end
	self.m_CurGoodsID = goodsID
	--local contentStr = "确定使用降价卡吗?"
    local contentStr = "是否要对".. GameHelp.GetLeechdomColorName(goodsID) .."降价?"
	local data = {
		content = contentStr,
		confirmCallBack = function() self:OnConfirmUseDownCard() end,
	}
	UIManager.ConfirmPopWindow:ShowDiglog(data)
end

--确认使用升价卡
function BusinessWindow:OnConfirmUseUpCard()
	GameHelp.PostServerRequest("RequestClanBusinessUseCard("..tostring(1)..","..self.m_CurGoodsID..")")
end
--确认使用降价卡
function BusinessWindow:OnConfirmUseDownCard()
	GameHelp.PostServerRequest("RequestClanBusinessUseCard("..tostring(0)..","..self.m_CurGoodsID..")")
end

--设置小红点接口
function BusinessWindow:SetRedPointView()
	local manager = IGame.ClanClient.m_ClanBusinessManager
	if not manager then
		return 
	end
	
	local id = manager:CheckBuyWhoseGoods()

	for i = 1, 3 do 
		if id == Page2ID[i] then
			self:SetRedPoint(i,true)
		else
			self:SetRedPoint(i,false)
		end
	end
end

--设置小红点
function BusinessWindow:SetRedPoint(index, show)
	local transformParent = self.BusinessToggleCtl[index].transform
	UIFunction.ShowRedDotImg(transformParent, show)
end

--刷新跑商次数,   卖掉物品跳转到购买分页
function BusinessWindow:OnUpdateTimes()
	self.SubToggleCtl[1].isOn = true
end

--评级
function BusinessWindow:SetQuality()
	local manager = IGame.ClanClient.m_ClanBusinessManager
	if not manager then
		return 
	end
	
	local curMoney = manager:GetPingJiMoney()
	--按照剩余货币计数来评级
	if curMoney < g_ClanBusinessMoneyB then	
		UIFunction.SetImageSprite(self.Controls.m_EavluateImg, BusinessQuality[1])							--普通
	elseif g_ClanBusinessMoneyB <= curMoney and curMoney < g_ClanBusinessMoneyA then
		UIFunction.SetImageSprite(self.Controls.m_EavluateImg, BusinessQuality[2])							--优秀
	elseif g_ClanBusinessMoneyA <= curMoney and curMoney < g_ClanBusinessMoneyS then
		UIFunction.SetImageSprite(self.Controls.m_EavluateImg, BusinessQuality[3])							--卓越
	elseif g_ClanBusinessMoneyS <= curMoney and curMoney < g_ClanBusinessMoneySS then
		UIFunction.SetImageSprite(self.Controls.m_EavluateImg, BusinessQuality[4])							--完美
	elseif g_ClanBusinessMoneySS <= curMoney and curMoney < g_ClanBusinessMoneySSS then
		UIFunction.SetImageSprite(self.Controls.m_EavluateImg, BusinessQuality[5])							--逆天
	elseif g_ClanBusinessMoneySSS <= curMoney then
		UIFunction.SetImageSprite(self.Controls.m_EavluateImg, BusinessQuality[6])							--超神
	end
end

return BusinessWindow