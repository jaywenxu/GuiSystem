-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    zjc
-- 日  期:    2017-10-13
-- 描  述:    武林英雄 战斗记录信息
-------------------------------------------------------------------

local WulinHeroChallengeCell = UIControl:new
{
	windowName 	= "WulinHeroChallengeCell",
	curItemInfo = nil,			-- 当前挑战信息
}

local this = WulinHeroChallengeCell

function WulinHeroChallengeCell:Init()

end

function WulinHeroChallengeCell:Attach(obj)
	UIControl.Attach(self,obj)	
	
	return self
end
-------------------------------------------------------------------
-- 销毁
function WulinHeroChallengeCell:OnDestroy()
	self.curItemInfo = nil
	UIControl.OnDestroy(self)
end
-------------------------------------------------------------------
-- 回收
function WulinHeroChallengeCell:OnRecycle()
	self.curItemInfo = nil
end
-------------------------------------------------------------------

-- 判断Unity3D对象是否被加载
function WulinHeroChallengeCell:isLoaded()
	return not tolua.isnull( self.transform )
end

-------------------------------------------------------------------
-- 设置当前item的属性	
-- @param index : 要获索引
-------------------------------------------------------------------
function WulinHeroChallengeCell:UpdateItemCellInfo(itemIndex)
	if not self:isLoaded() then
		return
	end
	if itemIndex%2 == 0 then
		self.Controls.m_fenlanImg.gameObject:SetActive(false)
	else
		self.Controls.m_fenlanImg.gameObject:SetActive(true)
	end
	local pItem = IGame.WulinHeroClient:GetFightReportInfo(itemIndex + 1)
	if not pItem then
		return
	end
	local szTab = os.date("*t",pItem.nTime)
	local szTime = string.format("%02d-%02d ", szTab.month, szTab.day) .. string.format("%02d:%02d", szTab.hour, szTab.min)

	local szText = "<color=green>"..szTime .. "</color>"
	if pItem.nFlag == WULINHERO_FIGHT_AVSB_SUCCESS then		--玩家角度，玩家挑战假人成功
		if pItem.nRank >= pItem.nOtherRank or pItem.nRankChange == 0 then
			szText = szText .. "你挑战".. "<color=#FF7800>"..pItem.szName.. "</color>".."，你获得胜利，排名不变！"
		else
			szText = szText .. "你挑战".. "<color=#FF7800>"..pItem.szName.. "</color>".."，你获得胜利，你的排名上升至第" .. pItem.nRank .. "名"
		end
	elseif pItem.nFlag == WULINHERO_FIGHT_AVSB_FAILURE then	-- 玩家角度，玩家挑战假人失败
		szText = szText .. "你挑战".. "<color=#FF7800>" .. pItem.szName.. "</color>".."，挑战失败，排名不变！"
	elseif pItem.nFlag == WULINHERO_FIGHT_BVSA_SUCCESS then -- 假人角度，玩家挑战假人失败
		szText = szText .. "<color=#FF7800>" .. pItem.szName.. "</color>".."挑战你" .. "，挑战失败，排名不变！"
	elseif pItem.nFlag == WULINHERO_FIGHT_BVSA_FAILURE then -- 假人角度，玩家挑战假人成功
		if pItem.nOtherRank < pItem.nRank then
			szText = szText .. "<color=#FF7800>" .. pItem.szName.. "</color>".."挑战您".. "，获得胜利，你的排名降至！"..pItem.nRank .. "名"
		else
			szText = szText .. "<color=#FF7800>" .. pItem.szName.. "</color>".."挑战您".. "，获得胜利，排名不变！"
		end
	end
	self.Controls.m_ChallengeInfoText.text = szText
end


return this