--JRBattleRankCell.lua------------------------------------------------------------
-- 版  权:	(C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:	何荣德
-- 日  期:	2017.12.20
-- 版  本:	1.0
-- 描  述:	假人战场排行榜cell
-------------------------------------------------------------------
local JRBattleRankCell = UIControl:new
{
	windowName         = "JRBattleRankCell",
}

local this = JRBattleRankCell

local RankTxtsColor = Color.New()
RankTxtsColor:FromHexadecimal("FF7800FF","As")
local RankTxtsColorNormal = Color.New()
RankTxtsColorNormal:FromHexadecimal("597993FF","As")
------------------------------------------------------------

function JRBattleRankCell:Attach(obj)
	UIControl.Attach(self,obj)
end

-- 填充cell数据
-- @ranks    ：排名
-- @data     : 排行数据
-- @bIsSelf : 是否是玩家自己
function JRBattleRankCell:SetCellData(rank, data, bIsSelf)
	local controls = self.Controls

	controls.m_RankTxt.text = rank
	controls.m_NameTxt.text = data.name
    controls.m_ProfTxt.text = GameHelp.GetVocationName(tonumber(data.prof))
    
    if tonumber(data.camp) == 4 then
        controls.m_CampTxt.text = "<color=blue>我方</color>"
    else
        controls.m_CampTxt.text = "<color=red>敌方</color>"
    end
	
    controls.m_PointsTxt.text = data.points
	controls.m_KillNumTxt.text = data.kill
	controls.m_SerialNumTxt.text = data.maxSerialKill
	
	local index = rank % 2 
	if index == 0 then 
		controls.m_Bg.gameObject:SetActive(true)
	else
		controls.m_Bg.gameObject:SetActive(false)
	end
	
	local bIsAnyBest = rank == 1
	local bTopThree = rank < 4
	if bTopThree then	
		local rankTopImgFile = GuiAssetList.GuiRootTexturePath .. "CommonPlay_Frame/FireFight_" .. rank .. ".png"
		UIFunction.SetImageSprite(controls.m_RankTopImg, rankTopImgFile, function ()
			controls.m_RankTopImg:SetNativeSize()
		end)
	end

	controls.m_RankTopImg.gameObject:SetActive(bTopThree)
	controls.m_RankTxt.gameObject:SetActive(not bTopThree)
    controls.m_Balance.gameObject:SetActive(true)
    
    local color
	if bIsSelf then 
		color = RankTxtsColor
	else
		color = RankTxtsColorNormal
	end
    UIFunction.SetTxtComsColor(self.transform.gameObject, color)
end

return this



