-- 火攻梁营排行cell类
-- @Author: XieXiaoMei
-- @Date:   2017-06-12 16:23:33
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-10 12:03:58

------------------------------------------------------------
local HGLYRankCell = UIControl:new
{
	windowName         = "HGLYRankCell",
}


local this = HGLYRankCell

local RankTxtsColor = Color.New()
RankTxtsColor:FromHexadecimal("FF7800FF","As")
local RankTxtsColorNormal = Color.New()
RankTxtsColorNormal:FromHexadecimal("597993FF","As")
------------------------------------------------------------

function HGLYRankCell:Attach(obj)
	UIControl.Attach(self,obj)

	self:AddListener( self.Controls.m_PraiseBtn , "onClick" , self.OnBtnPraiseClicked , self )
end


function HGLYRankCell:OnDestroy()
	UIControl.OnDestroy(self)

	table_release(self)
end

-- 填充cell数据
-- @ranks    ：排名
-- @data     : 排行数据
-- @rankType : 排行类型，1：火攻梁营  2：领地战
function HGLYRankCell:SetCellData(rank, data, rankType)
	local controls = self.Controls

	controls.m_RankTxt.text = rank
	controls.m_NameTxt.text = data.szName
	controls.m_ContributeTxt.text = data.nCtri
	controls.m_KillNumTxt.text = data.nKill
	controls.m_AssistsNum.text = data.nHelp
	controls.m_CureTxt.text = data.nCure
	local index = rank % 2 
	if index == 0 then 
		controls.m_Bg.gameObject:SetActive(true)
	else
		controls.m_Bg.gameObject:SetActive(false)
	end
	local DBID = data.nDBID
	local hero = IGame.EntityClient:GetHero() --是自己则全部text显示为绿色
	local bIsSelf = hero:GetNumProp(CREATURE_PROP_PDBID) == DBID
	local color
	if bIsSelf ==true then 
		color = RankTxtsColor
	else
		color = RankTxtsColorNormal
	end
	
	UIFunction.SetTxtComsColor(self.transform.gameObject, color)
	
	if rankType == 1 then
		local result = IGame.FireDestroyEctype:GetResult()
		local bBalanced = not isTableEmpty(result)
		controls.m_Balance.gameObject:SetActive(bBalanced)
		
		if not bBalanced then
			return
		end
	end

	controls.m_Balance.gameObject:SetActive(true)

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

	local target = IGame.FireDestroyEctype

	if rankType == 2 then
		target = IGame.LigeanceEctype
	end

	local getBestDBIDByType = function (type)
		return target:GetBestDBIDByType(type)
	end

	local bestDBID = getBestDBIDByType("nKill")
	controls.m_KillBestImg.gameObject:SetActive(bestDBID == DBID)
	bIsAnyBest = bIsAnyBest or bestDBID == DBID
	 
	bestDBID = getBestDBIDByType("nHelp")
	controls.m_AssistsBestImg.gameObject:SetActive(bestDBID == DBID)
	bIsAnyBest = bIsAnyBest or bestDBID == DBID

	bestDBID = getBestDBIDByType("nCure")
	controls.m_CureBestImg.gameObject:SetActive(bestDBID == DBID)
	bIsAnyBest = bIsAnyBest or bestDBID == DBID

	--controls.m_PraiseBtn.gameObject:SetActive(bIsAnyBest) --任意一个最佳才显示点赞按钮
end


function HGLYRankCell:OnBtnPraiseClicked()
	print("点赞")
	IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "暂未实现")
end

function HGLYRankCell:OnRecycle()
	UIControl.OnRecycle(self)
	
	table_release(self)
end

return this



