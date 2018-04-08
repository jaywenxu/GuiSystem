-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    Sheepy
-- 日  期:    2017年8月18日
-- 版  本:    1.0
-- 描  述:    获取途径子窗口
-------------------------------------------------------------------


local GetWaysWidget = UIControl:new
{
	windowName = "GetWaysWidget",
	m_WayIndex = {},
	m_GoodID  = 0,
}

local this = GetWaysWidget					-- 方便书写

function GetWaysWidget:Init()

end

function GetWaysWidget:Attach( obj )
	UIControl.Attach(self,obj)
	local WayCellGridTrans = self.transform:Find("Ways/Grid")
	for i = 1,8 do
		self.Controls["m_WayCellTrans"..i] = WayCellGridTrans:Find("WayCell ("..i..")")
		self.Controls["m_WayCellBtn"..i] = self.Controls["m_WayCellTrans"..i]:GetComponent(typeof(Button))
		self.Controls["m_WayName"..i] = self.Controls["m_WayCellTrans"..i]:Find("WayName"):GetComponent(typeof(Text))
		self.Controls["m_GoArrow"..i] = self.Controls["m_WayCellTrans"..i]:Find("GoArrow")
		self.Controls["m_WayCellBtn"..i].onClick:AddListener(function() self:OnWayBtnClick(i) end)
	end
	return self
end

-- 摆摊购买1
function GetWaysWidget:GetWaysType1()
	IGame.ExchangeClient:GoToBuyCustomGoods(self.m_GoodID)
end

-- 去药品商购买2
function GetWaysWidget:GetWaysType2()
	local tWayInfo = IGame.rktScheme:GetSchemeInfo(HOWTOGETGOODS_CSV, 2)
	if tWayInfo and tWayInfo.nPara1 then
		toNpc(tWayInfo.nPara1)
	end
end

-- 去杂货商购买3
function GetWaysWidget:GetWaysType3()
	local tWayInfo = IGame.rktScheme:GetSchemeInfo(HOWTOGETGOODS_CSV, 3)
	if tWayInfo and tWayInfo.nPara1 then
		toNpc(tWayInfo.nPara1)
	end
end

-- 去宠物商购买4
function GetWaysWidget:GetWaysType4()
	local tWayInfo = IGame.rktScheme:GetSchemeInfo(HOWTOGETGOODS_CSV, 4)
	if tWayInfo and tWayInfo.nPara1 then
		toNpc(tWayInfo.nPara1)
	end
end

-- 商城购买5
function GetWaysWidget:GetWaysType5()
	UIManager.ShopWindow:OpenShop(self.m_GoodID)
end

-- 战功商店6
function GetWaysWidget:GetWaysType6()
	IGame.ChipExchangeClient:OpenChipExchangeShop(1)
end

-- 每天礼包7
function GetWaysWidget:GetWaysType7()
	UIManager.WelfareWindow:Show(true,WelfareDef.ItemId.MRLB)
end

-- 武学残页兑换30
function GetWaysWidget:GetWaysType30()
	IGame.ChipExchangeClient:OpenChipExchangeShop(2)
	-- TODO
end

-- 充值37
function GetWaysWidget:GetWaysType37()
	UIManager.ShopWindow:ShowShopWindow(3)
end

-- 宝石合成39
function GetWaysWidget:GetWaysType39()
	-- TODO
	UIManager.ForgeWindow:Show(true)
	UIManager.ForgeWindow.ForgeConpoundWidget:SelectTargetGemID(self.m_GoodID)
	UIManager.ForgeWindow:ChangeForgePage(true, 4, 1)
end

-- 点击了途径前往按钮
function GetWaysWidget:OnWayBtnClick(idxBt)
	if not idxBt then
		return
	end
	local nWayType = self.m_WayIndex[idxBt]
	if not self.m_WayIndex[idxBt] then
		return
	end
	if not self["GetWaysType"..tostringEx(nWayType)] then
		uerror("还没有实现 nWayType="..nWayType.." 的功能")
		return
	end
	self["GetWaysType"..tostringEx(nWayType)](self)
	
	UIManager.GoodsTooltipsWindow:Hide()
	UIManager.ForgeWindow:OnCloseButtonClick()
end

-- 设置获取途径信息
function GetWaysWidget:ShowGoodsInfo(nGoodsId)
	if not self:isLoaded() then
		return
	end

	self.m_WayIndex = {}
	self.m_GoodID = nGoodsId
	self.m_WayIndex = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, self.m_GoodID).itemFetchID or {}

	local nWayCellCount = table_count(self.m_WayIndex)
	
	if nWayCellCount == 0 then
		self:Hide()
		return
	end
	if nWayCellCount < 5 then 
		local nWaysBgHeight = nWayCellCount * 100 
		self.Controls.m_WaysBg.sizeDelta = Vector2.New(self.Controls.m_WaysBg.sizeDelta.x, nWaysBgHeight)
	else
		self.Controls.m_WaysBg.sizeDelta = Vector2.New(self.Controls.m_WaysBg.sizeDelta.x, 500)
	end
	
	local wayRecord = {}

	for i=1,8 do
		local nWayType = self.m_WayIndex[i]
		if nWayType then
			wayRecord = IGame.rktScheme:GetSchemeInfo(HOWTOGETGOODS_CSV, nWayType)
			if wayRecord then
				self.Controls["m_WayName"..i].text = wayRecord.szWayName
				self.Controls["m_WayCellTrans"..i].gameObject:SetActive(true)
				if wayRecord.nArrow == 1 then
					self.Controls["m_GoArrow"..i].gameObject:SetActive(true)
				else
					self.Controls["m_GoArrow"..i].gameObject:SetActive(false)
				end
			end
		else
			self.Controls["m_WayCellTrans"..i].gameObject:SetActive(false)
		end
	end
	self:Show()
end

return GetWaysWidget