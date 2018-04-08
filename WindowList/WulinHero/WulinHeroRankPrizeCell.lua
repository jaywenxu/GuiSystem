-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    zjc
-- 日  期:    2017-10-13
-- 描  述:    武林英雄 排行奖励信息
-------------------------------------------------------------------

local WulinHeroRankPrizeCell = UIControl:new
{
	windowName 	= "WulinHeroRankPrizeCell",
	
	curItemInfo = {},			-- 当前挑战信息
}

local this = WulinHeroRankPrizeCell

function WulinHeroRankPrizeCell:Init()

end

function WulinHeroRankPrizeCell:Attach(obj)
	UIControl.Attach(self,obj)	
	self.calbackDuiHuanClick = function() self:OnTiaoDuiHuanClick() end
	self.Controls.m_DuiHuanBtn.onClick:AddListener( self.calbackDuiHuanClick )
	
	self.calbackItemButtonClick1 = function() self:OnItemButtonClick(1) end
	self.calbackItemButtonClick2 = function() self:OnItemButtonClick(2) end
	self.calbackItemButtonClick3 = function() self:OnItemButtonClick(3) end
	self.calbackItemButtonClick4 = function() self:OnItemButtonClick(4) end
	
	self.Controls.m_RankCellBtn1.onClick:AddListener( self.calbackItemButtonClick1 )
	self.Controls.m_RankCellBtn2.onClick:AddListener( self.calbackItemButtonClick2 )
	self.Controls.m_RankCellBtn3.onClick:AddListener( self.calbackItemButtonClick3 )
	self.Controls.m_RankCellBtn4.onClick:AddListener( self.calbackItemButtonClick4 )
	return self
end
-------------------------------------------------------------------
-- 销毁
function WulinHeroRankPrizeCell:OnDestroy()
	self.Controls.m_DuiHuanBtn.onClick:RemoveListener( self.calbackDuiHuanClick )
	self.Controls.m_RankCellBtn1.onClick:RemoveListener( self.calbackItemButtonClick1 )
	self.Controls.m_RankCellBtn2.onClick:RemoveListener( self.calbackItemButtonClick2 )
	self.Controls.m_RankCellBtn3.onClick:RemoveListener( self.calbackItemButtonClick3 )
	self.Controls.m_RankCellBtn4.onClick:RemoveListener( self.calbackItemButtonClick4 )
	self.curItemInfo = {}
	UIControl.OnDestroy(self)
end
-------------------------------------------------------------------
-- 回收
function WulinHeroRankPrizeCell:OnRecycle()
	self.Controls.m_DuiHuanBtn.onClick:RemoveListener( self.calbackDuiHuanClick )
	self.Controls.m_RankCellBtn1.onClick:RemoveListener( self.calbackItemButtonClick1 )
	self.Controls.m_RankCellBtn2.onClick:RemoveListener( self.calbackItemButtonClick2 )
	self.Controls.m_RankCellBtn3.onClick:RemoveListener( self.calbackItemButtonClick3 )
	self.Controls.m_RankCellBtn4.onClick:RemoveListener( self.calbackItemButtonClick4 )	
	self.curItemInfo = {}
	self:AllRankCellHide()
	UIControl.OnRecycle(self)
end
-------------------------------------------------------------------

-- 判断Unity3D对象是否被加载
function WulinHeroRankPrizeCell:isLoaded()
	return not tolua.isnull( self.transform )
end

-- 所有的按钮都隐藏
function WulinHeroRankPrizeCell:AllRankCellHide()
	if self:isLoaded() then
		for i = 1, 4 do
			self.Controls["m_RankCellBtn"..i].gameObject:SetActive(false)
		end
	end
end

-------------------------------------------------------------------
-- 设置当前item的属性	
-- @param index : 要获取物品的索引
-------------------------------------------------------------------
function WulinHeroRankPrizeCell:UpdateItemCellInfo(itemIndex)
	if not self:isLoaded() then
		return
	end
	local pTmpTable = IGame.rktScheme:GetSchemeTable(WULINHERORANKPRIZE_CSV)
	local nCellCount = table_count(pTmpTable)
	
	local nIndex = (nCellCount - itemIndex ) -- 最大项 - 当前是第几个 倒序
	local pItem = IGame.rktScheme:GetSchemeInfo(WULINHERORANKPRIZE_CSV, nIndex )
	if not pItem then
		return
	end
	self.Controls.m_Name.text = pItem.szDesc
	self.Controls.m_Cost.text = pItem.nCostLunJian
	self.Controls.m_Cost.gameObject:SetActive(true)
	self.Controls.m_CostIcon.gameObject:SetActive(true)
	
	-- 设置兑换按钮状态
	local nPrizeFlag= UIManager.WulinHeroWindow:GetMainHeroPrizeFlag()
	if lua_NumberAnd(nPrizeFlag, (2 ^ (nIndex - 1))) ~= 0 then
		self.Controls.m_DuiHuanBtn.gameObject:SetActive(false)
		self.Controls.m_yiduihuan.gameObject:SetActive(true)
		self.Controls.m_Cost.gameObject:SetActive(false)
		self.Controls.m_CostIcon.gameObject:SetActive(false)
	else
		local bGray = true
		local nCurLunjian = GetHero():GetLunJianScore()
		local nHighestRank = UIManager.WulinHeroWindow:GetMainHeroHighestRank()
		if nHighestRank ~= 0 and nHighestRank <= pItem.nRank and nCurLunjian >= pItem.nCostLunJian then
			bGray = false
		end
		self.Controls.m_DuiHuanBtn.gameObject:SetActive(true)
		self.Controls.m_yiduihuan.gameObject:SetActive(false)
		GameHelp:SetButtonGray(self.Controls.m_DuiHuanBtn.gameObject, bGray)
	end
	
	-- 设置奖励信息
	local tmpList = pItem.prizeList
	if not tmpList or table_count(tmpList)%3 ~= 0 then
		return
	end
	local nCount = math.floor(table_count(tmpList)/3)
	if nCount <= 0 then
		return
	end
	if nCount > 4 then
		nCount = 4
	end
	for i = 1, nCount do
		local nGoodsID = tmpList[3*(i-1) + 1]
		self.curItemInfo[i] = nGoodsID
		local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, nGoodsID)
		if schemeInfo then
			-- 物品图标
			local imagePath = AssetPath.TextureGUIPath..schemeInfo.lIconID1
			UIFunction.SetImageSprite( self.Controls["m_ItemIcon"..i] , imagePath )
			-- 物品边框
			local imageBgPath = AssetPath.TextureGUIPath..schemeInfo.lIconID2
			UIFunction.SetImageSprite( self.Controls["m_ItemBg"..i] , imageBgPath )
		end
		self.Controls["m_ItemCount"..i].text = tostring(tmpList[3*(i-1) + 3])
		self.Controls["m_RankCellBtn"..i].gameObject:SetActive(true)
	end
end

-------------------------------------------------------------------
-- 点击挑战按钮
function WulinHeroRankPrizeCell:OnTiaoDuiHuanClick()
	if not self.curItemInfo then
		return
	end
end

-- 点击物品图标
function WulinHeroRankPrizeCell:OnItemButtonClick(nIndex)
	
	if not self.curItemInfo or not self.curItemInfo[nIndex] then
		return
	end
	local subInfo = {
		bShowBtnType	= 0, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
		ScrTrans = self.Controls["m_RankCellBtn"..nIndex].transform,	-- 源预设
	}
	local nGoodsID = tonumber( self.curItemInfo[nIndex] )
	UIManager.GoodsTooltipsWindow:Show(true)
	UIManager.GoodsTooltipsWindow:SetGoodsInfo( nGoodsID, subInfo )
end

return this