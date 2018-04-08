-------------------------------------------------------------------
-- @Author: XieXiaoMei
-- @Date:   2017-08-07 14:41:19
-- @Vers:	1.0
-- @Desc:	领地结算战况元素
-------------------------------------------------------------------

local LigeBalceLogCell =  UIControl:new
{
	windowName = "LigeBalceLogCell",
	
	m_ID       = nil, --领地ID

	m_EnterBtnClickCallBack = nil,
}

local this = LigeBalceLogCell

------------------------------------------------------------
-- 设置数据
function LigeBalceLogCell:SetData(warInfo, ligeance)
	local controls = self.Controls

	local ligeCfg = IGame.rktScheme:GetSchemeInfo(LIGEANCE_CSV, warInfo.nID)
	if not ligeCfg then
		cLog("本地配置不能为空 id:".. warInfo.nID, "red")
		return
	end

	print("ligeance:",tableToString(ligeance))

	--领地名
	controls.m_NameTxt.text = ligeCfg.szName 

	-- icon
	local iconImg = controls.m_IconImg
	UIFunction.SetImageSprite(iconImg  , GuiAssetList.GuiRootTexturePath ..ligeCfg.icon, function ()
		-- 根据领地等级动态调整ICON的大小，等级越大图标越大
		local lv = ligeCfg.nLevel + 1  
		local scale = 0.6 + lv / 10 + 0.05
		iconImg.transform.localScale = Vector3.New(scale, scale, 1)
	end)
	if not IsNilOrEmpty(ligeCfg.icon) then
		if string.find(ligeCfg.icon, "Ligeance_huangcheng") ~= nil then
			controls.m_Scaler.transform.localScale = Vector3.New(0.7,0.7,1)
		else
			controls.m_Scaler.transform.localScale = Vector3.New(1,1,1)
		end
	end
	iconImg:SetNativeSize()
	

	-- 防守帮会
	local str = #ligeance.szClanName > 0 and ligeance.szClanName or "无"
	controls.m_DefenciesTxt.text = str 

	-- 进攻帮会
	str = ligeance.szEnemyName1
	if #ligeance.szEnemyName2 > 0 then
		if #str > 0 then
			str = string.format("%s\n",str)
		end
		str = string.format("%s%s",str, ligeance.szEnemyName2)
	end
	controls.m_AttacksTxt.text = str 

		
	-- 胜利帮会
	str = "无"
	local winClanID = ligeance.nWinClanID
	local bHasWiner = winClanID > 0
	if bHasWiner then
		if winClanID == ligeance.nClanID then
			str = ligeance.szClanName
		elseif winClanID == ligeance.nEnemy1 then
			str = ligeance.szEnemyName1
		elseif winClanID == ligeance.nEnemy2 then
			str = ligeance.szEnemyName2
		end
	end
	controls.m_WinerTxt.text = str 

	-- 攻守标记, 有胜利帮会才显示
	--local bAttack = warInfo.byAttack == 1 -- 0:守  1：攻
	--controls.m_AttackFlag.gameObject:SetActive(bHasWiner and bAttack)
	--controls.m_DefenceFlag.gameObject:SetActive(bHasWiner and not bAttack)

	self.m_ID = warInfo.nID
end

------------------------------------------------------------
-- 自身销毁
function LigeBalceLogCell:OnDestroy()
	UIControl.OnDestroy(self)

	table_release(self) 
end

------------------------------------------------------------
-- 回收自身
function LigeBalceLogCell:Recycle()
	rkt.GResources.RecycleGameObject(self.transform.gameObject)
end

------------------------------------------------------------

return this

