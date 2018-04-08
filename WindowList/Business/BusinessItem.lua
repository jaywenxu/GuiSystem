------------------------------------跑商item--------------------------------------------------

local BusinessItem = UIControl:new
{
	windowName = "BusinessItem",
	
	m_ID = -1,							--缓存的物品ID
	m_SaleWidgetShow = false,			--是否显示出售界面
	
	goumai_callback = nil,				--购买点击回调
	chushou_callback = nil,				--出售点击回调
	upanddown_callback = nil,			--升降价点击回调
}

local UpAndDownImage = {
	"Business/Mobilestore_zhang.png",						--上升
	"Business/Mobilestore_jiang.png",						--下降
}

local YiChangeImage = {
	"Business/Mobilestore_yijiang.png",						--已降
	"Business/Mobilestore_yizhang.png",						--已涨
}

function BusinessItem:Attach(obj)
	UIControl.Attach(self,obj)	
	
	self.Controls.Animtaion = self.Controls.m_SaleBtn.gameObject:GetComponent(typeof(rkt.ButtonClickAnimation))
	
	self.GouMaiBtnCB = function() self:OnGouMaiBtnClick() end
	self.Controls.m_BuyBtn.onClick:AddListener(self.GouMaiBtnCB)
	
	self.ChuShouBtnCB = function() self:OnChuShouBtnClick() end
	self.Controls.m_SaleBtn.onClick:AddListener(self.ChuShouBtnCB)
	
	self.UpAndDownCB = function() self:OnUpAndDownBtnClick() end
	self.Controls.m_UpAndDownBtn.onClick:AddListener(self.UpAndDownCB)
end

function BusinessItem:Destroy()
	UIControl.Destroy(self)
end

--回调设置
function BusinessItem:SetGouMaiCB(gouMai_callback)
	self.goumai_callback = gouMai_callback
end
function BusinessItem:SetChuShouCB(chuShou_callback)
	self.chushou_callback = chuShou_callback
end
function BusinessItem:SetUpAndDownCb(upAndDown_callback)
	self.upanddown_callback = upAndDown_callback
end

--是否显示出售界面
function BusinessItem:SetBuyWidget(nSaleWidgetShow)
	self.m_SaleWidgetShow = nSaleWidgetShow
	self.Controls.m_BuyWidget.gameObject:SetActive(nSaleWidgetShow)
	self.Controls.m_SaleWidget.gameObject:SetActive(not nSaleWidgetShow)
end

--设置物品ID, 附带设置图标,名字
function BusinessItem:SetGoodsID(id)
	self.m_ID = id
	
	local goodsRecord = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, id)
	if not goodsRecord then
		return
	end
	self:SetIcon(goodsRecord.lIconID1, goodsRecord.lIconID2)
	self:SetName(goodsRecord.szName)
end

--设置物品图标
function BusinessItem:SetIcon(nIconPath, nFramePath)
	UIFunction.SetImageSprite(self.Controls.m_Icon, AssetPath.TextureGUIPath..nIconPath)
	UIFunction.SetImageSprite(self.Controls.m_GoodsFrame, AssetPath.TextureGUIPath..nFramePath)
end

--设置买卖提示 买入 卖出
function BusinessItem:ShowTipsText(nBuyPrice, nSalePrice)
    if nBuyPrice == 0 then
        uerror("BusinessItem:ShowTipsText nBuyPrice=0, nSalePrice="..nSalePrice)
        return 
    end
    local rate = (nSalePrice - nBuyPrice) / nBuyPrice * 100
    if rate <= 0 then
        self.Controls.m_TipsText.text = tostring(g_ClanBusinessTips[1][2])
        return
    end
    
    local cnt = table_count(g_ClanBusinessTips)
    for i=2, cnt do
        local info = g_ClanBusinessTips[i]
        if rate <= tonumber(info[1]) then
            self.Controls.m_TipsText.text = tostring(info[2])
            break
        end
    end
end

--设置名字，扩展的可优化
function BusinessItem:SetName(szName)
	szName = szName or ""
	local goodsRecord = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, self.m_ID)
	if not goodsRecord then 
		if self.m_SaleWidgetShow then
			self.Controls.m_BuyGoodsNameText.text = szName
		else
			self.Controls.m_SaleGoodsNameText.text = szName
		end
	else
		if self.m_SaleWidgetShow then
			self.Controls.m_BuyGoodsNameText.text = "<color=#" .. AssetPath_GoodsQualityColor[goodsRecord.lBaseLevel] .. ">" .. szName .. "</color>"
		else
			self.Controls.m_SaleGoodsNameText.text = "<color=#" .. AssetPath_GoodsQualityColor[goodsRecord.lBaseLevel] .. ">" .. szName .. "</color>"
		end
	end
end

--设置扩展名字
function BusinessItem:SetExName(exName)
	exName = exName or ""
	local goodsRecord = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, self.m_ID)
	if not goodsRecord then 
		if self.m_SaleWidgetShow then
			self.Controls.m_BuyGoodsNameText.text = self.Controls.m_BuyGoodsNameText.text .. "(" .. exName .. "收购)"
		else
			self.Controls.m_SaleGoodsNameText.text = self.Controls.m_SaleGoodsNameText.text .. "(" .. exName .."收购)"
		end 
	else
		if self.m_SaleWidgetShow then
			self.Controls.m_BuyGoodsNameText.text =  string.format("<color=#%s>%s(%s)</color>",AssetPath_GoodsQualityColor[goodsRecord.lBaseLevel],self.Controls.m_BuyGoodsNameText.text, exName)
		else
			self.Controls.m_SaleGoodsNameText.text = string.format("<color=#%s>%s(%s)</color>",AssetPath_GoodsQualityColor[goodsRecord.lBaseLevel],self.Controls.m_SaleGoodsNameText.text, exName)
		end 
	end
end

--设置升降价卡显示				2-升价卡	1-降价卡
function BusinessItem:SetShowUpAndDownCard(show, isSalePage)
	if show then
		self.Controls.m_UpAndDownBtn.gameObject:SetActive(true)
		local index = 1
		if isSalePage then
			index = 2
		end
		if index == 1 then 
			self.Controls.m_Up.gameObject:SetActive(true)
			self.Controls.m_Down.gameObject:SetActive(false)
		elseif index == 2 then
			self.Controls.m_Up.gameObject:SetActive(false)
			self.Controls.m_Down.gameObject:SetActive(true)
		end
		UIFunction.SetImageSprite(self.Controls.m_UpAndDownImage, AssetPath.TextureGUIPath .. UpAndDownImage[index])		--升价
	else
		self.Controls.m_UpAndDownBtn.gameObject:SetActive(false)
	end
end


--出售分页-出售价格 买入价格
function BusinessItem:SetSalePrice(nPrice)
	self.Controls.m_SalePriceText.text = tostring(nPrice)
end

--出售分页-收购价格 卖出价格
function BusinessItem:SetSaleShouGouPrice(nPrice)
	self.Controls.m_BuyShouGoupriceText.text = tostring(nPrice)
end

--设置已涨价
function BusinessItem:SetUPing()
	self.Controls.m_UpAndDownBtn.gameObject:SetActive(false)
	self.Controls.m_YiChangeOptionImg.gameObject:SetActive(true)
	UIFunction.SetImageSprite(self.Controls.m_YiChangeOptionImg,AssetPath.TextureGUIPath .. YiChangeImage[2])
end

--取消已涨价
function BusinessItem:CancleUp()
	self.Controls.m_YiChangeOptionImg.gameObject:SetActive(false)
end

--设置已降价
function BusinessItem:SetDowning()
	self.Controls.m_UpAndDownBtn.gameObject:SetActive(false)
	self.Controls.m_YiChangeOptionImg.gameObject:SetActive(true)
	UIFunction.SetImageSprite(self.Controls.m_YiChangeOptionImg, AssetPath.TextureGUIPath .. YiChangeImage[1])
end

--取消已降价
function BusinessItem:CancleDown()
	self.Controls.m_YiChangeOptionImg.gameObject:SetActive(false)
end

--出售分页-已购
function BusinessItem:SetYiGou(nNum, bBuy)
    -- 当前物品被购买的数量
	if nNum and nNum > 0 then
		self:SetYiGouShow(true)
		self.Controls.m_BuyBtn.gameObject:SetActive(false)
		self.Controls.m_BuyHaveBuyText.text = tostring(nNum) .. "份"
    else
        self:SetYiGouShow(false)
	end
    
    -- 是否已经买了物品
    if bBuy then
        self.Controls.m_BuyBtn.gameObject:SetActive(false)
    else
        self.Controls.m_BuyBtn.gameObject:SetActive(true)
	end
end

--出售分页-设置已购是否显示 
function BusinessItem:SetYiGouShow(show)
	self.Controls.m_BuyHaveBuyParent.gameObject:SetActive(show)
end

--收购分页-收购价格 卖出价格
function BusinessItem:SetShouGouPrice(price)
	self.Controls.m_SaleWidgetShouGouPriceText.text = tostring(price)
end

--收购分页-拥有数量
function BusinessItem:SetShouGouHaveNum(num)
	self.Controls.m_SaleWidgetHaveNumText.text = tostring(num) .. "份"
end

--收购分页-卖按钮状态设置
function BusinessItem:SetMaiBtnEnable(enable)
	self.Controls.m_SaleBtn.gameObject:SetActive(enable)
	return
	
	--这个需求取消了
	--[[UIFunction.SetImgComsGray(self.Controls.m_SaleBtnImg.gameObject ,not enable)
	self.Controls.Animtaion.enabled = enable
	self.Controls.m_SaleBtn.interactable = enable	--]]
end

--购买点击事件
function BusinessItem:OnGouMaiBtnClick()
	if self.goumai_callback ~= nil then
		self.goumai_callback(self.m_ID)
	end
end

--出售点击事件
function BusinessItem:OnChuShouBtnClick()
	if self.chushou_callback ~= nil then
		self.chushou_callback(self.m_ID)
	end
end

--升降价点击
function BusinessItem:OnUpAndDownBtnClick()
	if self.upanddown_callback ~= nil then
		self.upanddown_callback(self.m_ID)
	end
end

return BusinessItem