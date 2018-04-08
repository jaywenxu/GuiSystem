--/******************************************************************
--** 文件名:	DressSaveItem.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	郝伟(751711994@qq.com)
--** 日  期:	2017-12-25
--** 版  本:	1.0
--** 描  述:	外观窗口-保存界面条目
--** 应  用:  
--******************************************************************/

local DressSaveItem = UIControl:new
{
	windowName = "DressSaveItem",
	
	m_CurTab = 1,									--第几个分页
	m_Index = 0, 									--第几个
	m_AppID = 0,									--时装索引
	m_ItemRecord = nil, 							--缓存的记录
	m_NeedBuy = false,								--是否需要购买
}

function DressSaveItem:Attach(obj)
	UIControl.Attach(self,obj)

	self.BuyBtnClickCB = function() self:OnBuyBtnClick() end 
	self.Controls.m_PurchaseBtn.onClick:AddListener(self.BuyBtnClickCB)
	
end
----------------------------------------------------------------------------------------------------------------------
--购买按钮点击回调
function DressSaveItem:OnBuyBtnClick()
	if not self.m_ItemRecord then return end
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end	
	local currencyNum = pHero:GetActorYuanBao()
	if currencyNum < self.m_ItemRecord.nDiamondCost then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "钻石不足，请充值后购买")
	else
		IGame.AppearanceClient:UnLockAppear(self.m_ItemRecord.nAppearID)
	end
end

----------------------------------------------------------------------------------------------------------------------
--设置初始化信息
function DressSaveItem:SetData(nTab, nIndex)
	self.m_CurTab = nTab
	self.m_Index = nIndex
	self.m_ItemRecord = IGame.AppearanceClient:GetRecordByTypeAndIndex(self.m_CurTab,self.m_Index)
	if self.m_ItemRecord then
		self.m_AppID = self.m_ItemRecord.nAppearID
	end
end


--设置名字
function DressSaveItem:SetName(name)
	if not name then return end
	self.Controls.m_DressNameText.text = name
end

---设置消耗信息
function DressSaveItem:SetCostInfo(nCurrency, nNum)
	if not nCurrency then return end
	UIFunction.SetImageSprite(self.Controls.m_CostImg, AssetPath_CurrencyIcon[nCurrency], function()
		self.Controls.m_CostParent.gameObject:SetActive(true)
	end)
	self.Controls.m_CostText.text = nNum
end

--设置右边显示信息， 该显示哪个
--dataTable = {Purchase = true, HaveBuy = false, GetWay = false,}
function DressSaveItem:SetRightShow(dataTable)
	self.Controls.m_PurchaseBtn.gameObject:SetActive(dataTable.Purchase)
	self.Controls.m_HaveBuyTrans.gameObject:SetActive(dataTable.HaveBuy)
	self.Controls.m_GetWayTrans.gameObject:SetActive(dataTable.GetWay)
	self.Controls.m_CostParent.gameObject:SetActive(false)
	self.m_NeedBuy = not dataTable.HaveBuy
end

--设置获取途径
function DressSaveItem:SetGetWayText(wayStr)
	self.Controls.m_GetWayText.text = wayStr
end

--设置成已经购买
function DressSaveItem:SetHaveBuy()
	local dataTable = {Purchase = false, HaveBuy = true, GetWay = false,}
	self:SetRightShow(dataTable)
end

return DressSaveItem