-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    zjc
-- 日  期:    2017-10-13
-- 描  述:    武林英雄 每日排行奖励信息
-------------------------------------------------------------------

local WulinHeroDailyPrizeCell = UIControl:new
{
	windowName 	= "WulinHeroDailyPrizeCell",
	curItemInfo = nil,			-- 当前挑战信息
}

local this = WulinHeroDailyPrizeCell

function WulinHeroDailyPrizeCell:Init()

end

function WulinHeroDailyPrizeCell:Attach(obj)
	UIControl.Attach(self,obj)	
	
	return self
end
-------------------------------------------------------------------
-- 销毁
function WulinHeroDailyPrizeCell:OnDestroy()
	self.curItemInfo = nil
	UIControl.OnDestroy(self)
end
-------------------------------------------------------------------
-- 回收
function WulinHeroDailyPrizeCell:OnRecycle()
	self.curItemInfo = nil
end
-------------------------------------------------------------------

-- 判断Unity3D对象是否被加载
function WulinHeroDailyPrizeCell:isLoaded()
	return not tolua.isnull( self.transform )
end

-------------------------------------------------------------------
-- 设置当前item的属性	
-- @param index : 要获取物品的索引
-------------------------------------------------------------------
function WulinHeroDailyPrizeCell:UpdateItemCellInfo(itemIndex)
	if not self:isLoaded() then
		return
	end
	local pItem = IGame.rktScheme:GetSchemeInfo(WULINHERODAILYRANKPRIZE_CSV, (itemIndex + 1))
	if not pItem then
		return
	end
	local nLevelText = "第 " .. pItem.nPreRank .. "-"..pItem.nNextRank .. " 名"
	if pItem.nPreRank == pItem.nNextRank then
		nLevelText = "第 " .. pItem.nPreRank .. " 名"
	end
	self.Controls.m_LevelText.text = nLevelText
	self.Controls.m_JifenText.text = pItem.nLunJian .. " 积分"
end


return this