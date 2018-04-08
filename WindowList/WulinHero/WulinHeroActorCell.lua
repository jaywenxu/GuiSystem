-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    zjc
-- 日  期:    2017-10-13
-- 描  述:    武林英雄 可挑战的玩家信息
-------------------------------------------------------------------

-- 背景总共有4中，前三名不同，后面的都相同
local tmpWulinHeroRankBg =
{
	[1] = "WulinHero_board_1.png",
	[2] = "WulinHero_board_2.png",
	[3] = "WulinHero_board_3.png",
	[4] = "WulinHero_board_4.png",
}
-- 头像背景只有前三名才有
local tmpWulinHeroActorIconBg =
{
	[1] = "WulinHero_board_5.png",
	[2] = "WulinHero_board_6.png",
	[3] = "WulinHero_board_7.png",
}
local WulinHeroActorCell = UIControl:new
{
	windowName 	= "WulinHeroActorCell",
	curItemInfo = nil,			-- 当前挑战信息
}

local this = WulinHeroActorCell

function WulinHeroActorCell:Init()

end

function WulinHeroActorCell:Attach(obj)
	UIControl.Attach(self,obj)	
	self.calbackTiaoZhanClick = function() self:OnTiaoZhanBtnClick() end
	self.Controls.m_TiaoZhanBtn.onClick:AddListener( self.calbackTiaoZhanClick )
	
	return self
end
-------------------------------------------------------------------
-- 销毁
function WulinHeroActorCell:OnDestroy()
	self.Controls.m_TiaoZhanBtn.onClick:RemoveListener( self.calbackTiaoZhanClick )
	self.curItemInfo = nil
	UIControl.OnDestroy(self)
end
-------------------------------------------------------------------
-- 回收
function WulinHeroActorCell:OnRecycle()
	self.Controls.m_TiaoZhanBtn.onClick:RemoveListener( self.calbackTiaoZhanClick )
	self.curItemInfo = nil
end
-------------------------------------------------------------------

-- 判断Unity3D对象是否被加载
function WulinHeroActorCell:isLoaded()
	return not tolua.isnull( self.transform )
end

-------------------------------------------------------------------
-- 设置角色头像
function WulinHeroActorCell:UpdateActorFace(faceid)
	if not self:isLoaded()then
		return
	end 
	if not faceid then
		return
	end
	local iconIconPath = gPersonHeadIconCfg[faceid]
	if not IsNilOrEmpty(iconIconPath) then
		UIFunction.SetImageSprite(self.Controls.m_ActorIcon, iconIconPath)
	end
end

-------------------------------------------------------------------
-- 设置职业
function WulinHeroActorCell:UpdateActorVocation(nVoc)
	if not self:isLoaded()then
		return
	end
	nVoc = nVoc or 1
	local szActorVocPath = GuiAssetList.gProfessionIcon[nVoc]
	UIFunction.SetImageSprite(self.Controls.m_VocationImg , szActorVocPath)
end

-------------------------------------------------------------------
-- 按照排行设置信息
function WulinHeroActorCell:UpdateInitInfo(nRank)
	
	if not nRank or nRank < 0 then
		return
	end
	-- 排名
	self.Controls.m_RankText.text = "第"..nRank.."名"
	if nRank > 4 then
		nRank = 4
	end
	-- 排行背景
	local rankBgPath = AssetPath.WulinHeroTexturePath..tmpWulinHeroRankBg[nRank]
	UIFunction.SetImageSprite(self.Controls.m_ActorRankBg , rankBgPath)	
	
	-- 角色头像背景 + 显示排名
	if nRank >= 1 and nRank <= 3 then
		local actorIconPath = AssetPath.WulinHeroTexturePath..tmpWulinHeroActorIconBg[nRank]
		UIFunction.SetImageSprite(self.Controls.m_ActorIconBg , actorIconPath)
		self.Controls.m_ActorIconBg.gameObject:SetActive(true)
		self.Controls.m_RankText.gameObject:SetActive(false)
	else
		self.Controls.m_ActorIconBg.gameObject:SetActive(false)
		self.Controls.m_RankText.gameObject:SetActive(true)
	end
end

-------------------------------------------------------------------
-- 设置当前item的属性	
-- @param index : 要获取物品的索引
-------------------------------------------------------------------
function WulinHeroActorCell:UpdateItemCellInfo(itemIndex)
	if not self:isLoaded() then
		return
	end
	local pItem = IGame.WulinHeroClient:GetAttackActorInfo(itemIndex + 1)
	if not pItem then
		return
	end
	-- 20级特殊处理
	local nHeroRank = IGame.WulinHeroClient:GetSlefAttackRank()
	if pItem.nRank <= 10 then
		if (nHeroRank ~= 0 and nHeroRank <= 20) then
			self.Controls.m_TiaoZhanBtn.gameObject:SetActive(true)
			GameHelp:SetButtonGray(self.Controls.m_TiaoZhanBtn.gameObject, false)
		else
			self.Controls.m_TiaoZhanBtn.gameObject:SetActive(true)
			GameHelp:SetButtonGray(self.Controls.m_TiaoZhanBtn.gameObject, true)
		end
	else
		self.Controls.m_TiaoZhanBtn.gameObject:SetActive(true)
		GameHelp:SetButtonGray(self.Controls.m_TiaoZhanBtn.gameObject, false)
	end
	-- 主角自己隐藏界面
	if GameHelp:IsMainHero(pItem.dwPDBID) then
		self.Controls.m_TiaoZhanBtn.gameObject:SetActive(false)
		self.Controls.m_MyselfImg.gameObject:SetActive(true)
		self.Controls.m_PrizeExpText.gameObject:SetActive(false)
		self.Controls.m_PrizeExpText.text = 0
	else
		self.Controls.m_MyselfImg.gameObject:SetActive(false)
		self:UpdateExpView( pItem.nRank )
		self.Controls.m_PrizeExpText.gameObject:SetActive(true)
	end
	self.curItemInfo = pItem
	self.Controls.m_ActorName.text = pItem.szActorName
	self.Controls.m_ZhandouliText.text = "总战力："..math.floor((pItem.nAttackValue + pItem.nDefendValue)/2)
	
	self.Controls.m_LevelText.text = pItem.nLevel
	
	self:UpdateInitInfo(pItem.nRank)
	self:UpdateActorFace(pItem.nFaceID)
	self:UpdateActorVocation(pItem.nVocation)
end

-- 更新奖励显示信息
function WulinHeroActorCell:UpdateExpView( nRank )
	local nExp = 0
	local prizeInfo = IGame.rktScheme:GetSchemeInfo( PRIZESTANDARD_CSV, GameHelp:GetHeroLevel() )
	if not prizeInfo then
		uerror( "【武林英雄】获取基础奖励配置错误，玩家等级为：" .. GameHelp:GetHeroLevel() )
		return
	end
	if nRank <= 1000 then
		nExp = math.floor( (2000 - nRank)/333333 * prizeInfo.Exp )
	else
		nExp = math.floor( 0.003 * prizeInfo.Exp )
	end
	self.Controls.m_PrizeExpText.text = NumToWanEx(nExp) .. "经验"
end
-------------------------------------------------------------------
-- 点击挑战按钮
function WulinHeroActorCell:OnTiaoZhanBtnClick()
	if not self.curItemInfo then
		return
	end
	if GameHelp:IsMainHero(self.curItemInfo.dwPDBID) then
		return
	end
	if not self.curItemInfo then
		return
	end
	local nRank = self.curItemInfo.nRank or 0
	local nHeroRank = IGame.WulinHeroClient:GetSlefAttackRank()
	if nRank <= 10 and nHeroRank > 20 then
		return 
	end
	
	local dwPDBID = self.curItemInfo.dwPDBID
	local nFlag = self.curItemInfo.nFlag
	local byType = self.curItemInfo.byType
	local dwTime = 0
	
	if not IGame.WulinHeroClient:RequestFight(dwPDBID, nFlag, byType, dwTime, nRank) then
		return
	end
	UIManager.WulinHeroWindow:Hide()
end

return this