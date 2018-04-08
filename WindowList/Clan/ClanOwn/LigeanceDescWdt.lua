-- 帮派领地战界面
-- @Author: XieXiaoMei
-- @Date:   2017-07-11 17:43:19
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-26 15:42:45

local LigeanceDescWdt = UIControl:new
{
	windowName      = "LigeanceDescWdt",
	tShowItem 		= {},	-- 显示图标对应的物品ID
}

-- 初始化
function LigeanceDescWdt:Attach( obj )
	
	UIControl.Attach(self,obj)
	
	for n = 1, 4 do
		self.Controls["m_BtnIcon"..n].onClick:AddListener(function () self:OnBtnIcon(n) end)
	end
end

------------------------------------------------------------
-- 显示界面
function LigeanceDescWdt:Show(data)
	UIControl.Show(self)

	local ligeCfg = IGame.rktScheme:GetSchemeInfo(LIGEANCE_CSV, data.nID)
	if not ligeCfg then
		cLog("本地配置不能为空 id:".. data.nID, "red")
		return
	end

	local  controls = self.Controls

	controls.m_TitleTxt.text = ligeCfg.szName
	-- controls.m_Awards = data.

	controls.m_TypeTxt.text = ligeCfg.szLevelName

	local s = #data.szClanName > 0 and data.szClanName or "暂无"
	controls.m_OwnerTxt.text = s


	local s = "暂无"
	local state = IGame.Ligeance:GetState(0)
	if state == eLigeance_State_Auction then --竞拍期，显示竞拍个数
		s = data.nAuctionClanNum .. "个"
	else
		-- 非竞拍期，显示进攻个数
		s = data.szEnemyName1
		if #data.szEnemyName2 > 0 then
			if #s > 0 then
				s = s .. "、"
			end
			s = s .. data.szEnemyName2
		end
	end
	controls.m_AttacksTxt.text =  s
	
	self:ShowItem(data.nID)
end

------------------------------------------------------------
-- 自身销毁
function LigeanceDescWdt:OnDestroy()
	UIControl.OnDestroy(self)

	table_release(self) 
end

------------------------------------------------------------
-- 关闭按钮回调
function LigeanceDescWdt:OnBtnCloseClicked(idx)
	self:Hide()
end

------------------------------------------------------------
-- 关闭按钮回调
function LigeanceDescWdt:ShowTips(data, cityBtnTf)
	self:Show(data)

	local transform = self.transform
	UIFunction.ToolTipsShow(true, transform, cityBtnTf, {x=0,y=0})
end

-- 关闭按钮回调
function LigeanceDescWdt:HideTips()
	local transform = self.transform
	UIFunction.ToolTipsShow(false, transform)
end

-- 显示物品
function LigeanceDescWdt:ShowItem(nID)
	
	local tCfg = IGame.Ligeance:GetPrizeCsv(nID)
	if not tCfg then
		uerror("【领地战】显示物品，失败，找不到配置"..nID)
		return
	end
	
	local nCivilGrade = IGame.ResAdjustClient:GetLvCivilGrade()

	self.tShowItem = {}
	local tItem = 
	{
		[1] = tCfg.tItem1[1] or 0,
		[2] = tCfg.tItem2[1] or 0,
		[3] = tCfg.tItem3[nCivilGrade] or 0,
		[4] = tCfg.tItem4[nCivilGrade] or 0,
	}
	local tCfgItem = self:GetItemCfg(tCfg.tItem1[1])
	
	local nIndex = 1
	for n = 1, #tItem do
		
		tCfgItem = self:GetItemCfg(tItem[n])	
		if tCfgItem then
			self.Controls["m_Award"..nIndex].gameObject:SetActive(true)
			local m_AwardBG = self.Controls["m_Award"..nIndex].gameObject:GetComponent(typeof(Image))
			UIFunction.SetImageSprite(m_AwardBG, AssetPath.TextureGUIPath..tCfgItem.lIconID2)
			UIFunction.SetImageSprite(self.Controls["m_Icon"..nIndex], AssetPath.TextureGUIPath..tCfgItem.lIconID1)
			nIndex = nIndex + 1
			self.tShowItem[n] = tItem[n]
		end
	end
	
	for n = nIndex, 4 do
		self.Controls["m_Award"..n].gameObject:SetActive(false)
	end
end

-- 获取物品配置
function LigeanceDescWdt:GetItemCfg(nItemID)
	if not nItemID then
		return
	end
	return IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, nItemID)
end

-- 点击按钮
function LigeanceDescWdt:OnBtnIcon(nIndex)
	
	GameHelp.ShowChatWinLeechdomTips(self.tShowItem[nIndex])
end

return LigeanceDescWdt
------------------------------------------------------------

