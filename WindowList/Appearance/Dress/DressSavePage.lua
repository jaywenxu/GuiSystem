--/******************************************************************
--** 文件名:	DressSavePage.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	haowei(751711994@qq.com)
--** 日  期:	2017-12-26
--** 版  本:	1.0
--** 描  述:	外观窗口-保存购买界面
--** 应  用:  
--******************************************************************/
local DressSaveItemClass = require("GuiSystem.WindowList.Appearance.Dress.DressSaveItem")
local DressSavePage = UIControl:new
{
	windowName = "DressSavePage",
	
	m_DressSaveItemScripts = {},						
	
	m_CurTab = 1,							--当前第几个分页
	m_Data = nil,
	m_TotalCost = 0,
}

function DressSavePage:Attach(obj)
	UIControl.Attach(self,obj)
	
	self:SubscribeEvent()
end


-- 窗口销毁
function DressSavePage:OnDestroy()
    -- 移除事件的绑定
    self:UnSubscribeEvent()
	
    UIControl.OnDestroy(self)
end


-- 事件绑定
function DressSavePage:SubscribeEvent()
	self.CloseCB = function() self:Hide() end
	self.Controls.m_CloseBtn.onClick:AddListener(self.CloseCB)
	
	self.UnLockAppCB = function(_,_,_,_,nID) self:UnLockAppCallBack(nID) end
	
	self.CombineBuy = function() self:OnCombineBuyBtnClick() end
	self.Controls.m_TotalBuyBtn.onClick:AddListener(self.CloseCB)
end

-- 移除事件的绑定
function DressSavePage:UnSubscribeEvent()
	
end

function DressSavePage:Show()
	UIControl.Show(self)
	
	rktEventEngine.SubscribeExecute(EVENT_APPEAR_UNLOCK_APPEAR, SOURCE_TYPE_APPEAR, 0, self.UnLockAppCB)
end

function DressSavePage:Hide( destroy )
	UIControl.Hide(self, destroy)
	rktEventEngine.UnSubscribeExecute(EVENT_APPEAR_UNLOCK_APPEAR, SOURCE_TYPE_APPEAR, 0, self.UnLockAppCB)
end

-- 显示窗口
function DressSavePage:ShowWindow(nTab ,nData)
	self:Show()
	self.m_CurTab = nTab
	self.m_Data = nData
	self.m_TotalCost = 0
	self:InitView(nData)
end

-- 隐藏窗口
function DressSavePage:HideWindow()
	self:Hide(false)
	
end
---------------------------------------------------------------------------------
--合并购买
function DressSavePage:OnCombineBuyBtnClick()
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end	
	local currencyNum = pHero:GetActorYuanBao()
	if self.m_TotalCost > currencyNum then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "钻石不足，无法购买")
	else
		for i, data in pairs(self.m_DressSaveItemScripts) do
			IGame.AppearanceClient:UnLockAppear(data.m_AppID)
		end
	end
end

----------------------------------------------------------------------------------
--初始化界面显示
function DressSavePage:InitView(nData)
	local tableNum = table.getn(self.m_DressSaveItemScripts) 
	if tableNum > 0 then
		for i, data in pairs(self.m_DressSaveItemScripts) do
			data:Destroy()
		end
	end
	self.m_DressSaveItemScripts = {}
	
	local serverTime = GetServerTimeSecond()
	local heroPreInfo = IGame.AppearanceClient:GetHeroAppInfo()
	
	local totalCost = 0

	for i, data in pairs(nData) do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.Appearance.DressSaveItem ,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_ListGrid,false)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = DressSaveItemClass:new({})
			item:Attach(obj)
			item:SetData(i, data)
			
			local itemRecord = IGame.AppearanceClient:GetRecordByTypeAndIndex(i,data)
			if not itemRecord then return end
			item.m_AppID = itemRecord.nAppearID
			
			item:SetName(itemRecord.szAppearName)
			
			local dataTable = {Purchase = false, HaveBuy = false, GetWay = false,}
			if heroPreInfo[itemRecord.nAppearID] then												--买过
				if itemRecord.nLimitTime == 0 then
					dataTable.HaveBuy = true
					item:SetRightShow(dataTable)
				else
					if serverTime < heroPreInfo[itemRecord.nAppearID].nDeadLine then				--没过期
						dataTable.HaveBuy = true
						item:SetRightShow(dataTable)
					else
						if itemRecord.nGetWay and itemRecord.nGetWay ~= "" then						--显示获取路径
							dataTable.GetWay = true
							item:SetRightShow(dataTable)
							item:SetGetWayText(itemRecord.nGetWay)
						else
							dataTable.Purchase = true												--显示钻石图标
							item:SetRightShow(dataTable)
							item:SetCostInfo(1,itemRecord.nDiamondCost)
							totalCost = totalCost + itemRecord.nDiamondCost
						end
					end
				end
			else
				if itemRecord.nGetWay and itemRecord.nGetWay ~= "" then						--显示获取路径
					dataTable.GetWay = true
					item:SetRightShow(dataTable)
					item:SetGetWayText(itemRecord.nGetWay)
				else
					dataTable.Purchase = true												--显示钻石图标
					item:SetRightShow(dataTable)
					item:SetCostInfo(1,itemRecord.nDiamondCost)
					totalCost = totalCost + itemRecord.nDiamondCost
				end
			end
			self.Controls.m_CostNum.text = tostring(totalCost)
			self.m_TotalCost = totalCost
			table.insert(self.m_DressSaveItemScripts,i,item)	
		end , i , AssetLoadPriority.GuiNormal )
	end
end

--刷新底部
function DressSavePage:RefreshBottomView()
	local totalNum = 0
	
	local serverTime = GetServerTimeSecond()
	local heroPreInfo = IGame.AppearanceClient:GetHeroAppInfo()
	
	for i,data in pairs(self.m_DressSaveItemScripts) do
		if heroPreInfo[data.m_ItemRecord.nAppearID] then
			if serverTime > heroPreInfo[itemRecord.nAppearID].nDeadLine then				--没过期
				totalNum = totalNum + data.m_ItemRecord.nDiamondCost
			end
		else
			totalNum = totalNum + data.m_ItemRecord.nDiamondCost
		end
	end
	self.m_TotalCost = totalNum
	self.Controls.m_CostNum.text = tostring(totalNum)
end

---------------------------------------------

--解锁成功回调
function DressSavePage:UnLockAppCallBack(nAppID)
	for i,data in pairs(self.m_DressSaveItemScripts) do
		if nAppID == data.m_AppID then
			data:SetHaveBuy()
		end
	end
	
	self:RefreshBottomView()
end

return DressSavePage