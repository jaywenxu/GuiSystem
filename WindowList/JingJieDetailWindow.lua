--/******************************************************************
---** 文件名:	JingJieDetailWindow.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-07
--** 版  本:	1.0
--** 描  述:	境界详情窗口
--** 应  用:  
--******************************************************************/

local JingJieDetailWindow = UIWindow:new
{
	windowName = "JingJieDetailWindow",	-- 窗口名称
	
	m_JingJieId = 0,					-- 当前显示的境界id:number
	m_LiuPaiNo = 0,						-- 当前显示的流派编号:number
	m_HaveInvokeOnWindowShow = false,	-- 是否调用了窗口显示方法的标识:boolean
}

local TITLE_IMG_PATH = AssetPath.TextureGUIPath.."Activity/activity_biaoti_zu.png"	-- 窗口标题资源路径

function JingJieDetailWindow:Init()
	

end

function JingJieDetailWindow:OnAttach( obj )
	
	UIWindow.OnAttach(self, obj)

	self.Controls.m_ButtonMask.onClick:AddListener(function() UIManager.JingJieDetailWindow:Hide() end)
	self.Controls.m_ButtonZBWX.onClick:AddListener(function() self:OnZBWXButtonClick() end)
	
	if not self.m_HaveInvokeOnWindowShow then
		self.m_HaveInvokeOnWindowShow = true
		self:OnWindowShow()
	end
	
	return self
	
end

function JingJieDetailWindow:_showWindow()
	
	UIWindow._showWindow(self)

	if self:isLoaded() then
		self.m_HaveInvokeOnWindowShow = true
		self:OnWindowShow()
	end
	
end

-- 显示窗口
-- @jingJieId:境界id:number
-- @liuPaiNo:流派编号
function JingJieDetailWindow:ShowWindow(jingJieId, liuPaiNo)
	
	self.m_JingJieId = jingJieId
	self.m_LiuPaiNo = liuPaiNo
	self.m_HaveInvokeOnWindowShow = false
	
	UIWindow.Show(self, true)
	
end

-- 窗口每次打开执行的行为
function JingJieDetailWindow:OnWindowShow()
	
	local jingJieScheme = IGame.rktScheme:GetSchemeInfo(BATTLE_BOOK_ACTIVATION_CSV, self.m_JingJieId)
	if not jingJieScheme then
		return
	end
	
	self.Controls.m_TextJingJieName.text = jingJieScheme.Name
	self.Controls.m_TextJingJieDesc.text = jingJieScheme.Desc
	
	-- 更新武学效果的显示
	self:UpdateWuXueEffectShow(jingJieScheme)
	-- 更新套装效果的显示
	self:UpdateSuitEffectShow()
	
	UIFunction.SetImageSprite(self.Controls.m_ImageJingJieIcon, AssetPath.TextureGUIPath..jingJieScheme.Icon)
	
end

-- 更新武学效果的显示
-- @jingJieScheme:境界配置表:BattleBookActivation
function JingJieDetailWindow:UpdateWuXueEffectShow(jingJieScheme)
	
	local studyPart = GetHeroEntityPart(ENTITYPART_PERSON_STUDYSKILL)
	if not studyPart then
		return
	end

	local playerXiuWei = studyPart:GetXiuWei()
	local attrNameStr = ""
	local attrEffStr = ""
	-- 境界未解锁
	if playerXiuWei < jingJieScheme.Activation then
		for slotIdx = 1, 5 do
			attrNameStr = attrNameStr .. string.format("<color=#F9063FFF>未解锁武学%d\n</color>", slotIdx)
		end
			
		self.Controls.m_TextWuXueName.text = attrNameStr
		self.Controls.m_TextWuXueEff.text = ""
		
		return
	end
	
	local jingJieInfo = studyPart:GetJingJieInfo(self.m_JingJieId)
	if not jingJieInfo then
		return
	end
	
	local arrBookUid = {}
	if self.m_LiuPaiNo == 1 then
		arrBookUid = jingJieInfo.arrLiuPai1WuXueUid
	else 
		arrBookUid = jingJieInfo.arrLiuPai2WuXueUid
	end
	
	local arrSlotXiuWeiNeed = 
	{
		jingJieScheme.Slot1Actvation, jingJieScheme.Slot2Actvation, jingJieScheme.Slot3Actvation, 
		jingJieScheme.Slot4Actvation, jingJieScheme.Slot5Actvation, 
	}
	
	for slotIdx = 1, 5 do
		local isSlotOpen = playerXiuWei >= arrSlotXiuWeiNeed[slotIdx]
		
		if not isSlotOpen then	-- 位置未解锁
			attrNameStr = attrNameStr .. string.format("<color=#F9063FFF>未解锁武学%d</color>\n", slotIdx)
			attrEffStr = attrEffStr .. "\n"
		elseif not arrBookUid[slotIdx] then -- 未装备武学
			attrNameStr = attrNameStr .. string.format("<color=#F9063FFF>未装备武学%d</color>\n", slotIdx)
			attrEffStr = attrEffStr .. "\n"
		else -- 有武学书
			local equipInfo = IGame.EntityClient:Get(arrBookUid[slotIdx])
			if not equipInfo then
				self.Controls.m_TextWuXueName.text = string.format("找不到装备信息 %d", arrBookUid[slotIdx])
				self.Controls.m_TextWuXueEff.text = ""	
				return
			end
			
			local bookCfgId = equipInfo:GetNumProp(GOODS_PROP_GOODSID)
			local equipScheme = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, bookCfgId)
			if not equipScheme then
				self.Controls.m_TextWuXueName.text = string.format("找不到武学配置表 %d", bookCfgId) 
				self.Controls.m_TextWuXueEff.text = ""	
				return
			end
			
			local bookInfo = equipInfo.BattleBookProp
			local bookLevelScheme = IGame.rktScheme:GetSchemeInfo(BATTLE_BOOK_UPGRADE_CSV, bookCfgId, bookInfo.level)
			if not bookLevelScheme then
				self.Controls.m_TextWuXueName.text = string.format("找不到武学等级配置表 %d %d", bookCfgId, bookInfo.level)
				self.Controls.m_TextWuXueEff.text = ""	
			end
			
			local bookEffStr = ""
			for k,v in pairs(bookLevelScheme.Property) do
				local attrName = GameHelp.PropertyName[k]
				bookEffStr = bookEffStr .. string.format("<color=#FF7785FF>%s+%d</color> ", attrName, v)
			end
			
			attrNameStr = attrNameStr .. string.format("<color=#CEDBDBFF>%s（%d级）:</color>\n", equipScheme.szName, bookInfo.level)
			attrEffStr = attrEffStr .. string.format("%s\n", bookEffStr)		
		end
	end
	
	self.Controls.m_TextWuXueName.text = attrNameStr
	self.Controls.m_TextWuXueEff.text = attrEffStr

end


-- 更新套装效果的显示
function JingJieDetailWindow:UpdateSuitEffectShow()
	
	local studyPart = GetHeroEntityPart(ENTITYPART_PERSON_STUDYSKILL)
	if not studyPart then
		return
	end
	
	local suitId = studyPart:CheckPlayerJingJieSuitId(self.m_JingJieId, self.m_LiuPaiNo)
	if suitId < 1 then
		self.Controls.m_TextSuitEff.text = "<color=#F9063FFF>未激活任何套装效果</color>"
		return
	end
	
	local suitScheme = IGame.rktScheme:GetSchemeInfo(BATTLE_BOOK_SUIT_CSV, suitId)
	if not suitScheme then
		return
	end

	local attrStr = ""
	for k,v in pairs(suitScheme.Property) do
		local attrName = GameHelp.PropertyName[k]
		attrStr = attrStr .. string.format("<color=#FF7785FF>增加角色%d%s</color>\n", v, attrName)
	end
	
	self.Controls.m_TextSuitEff.text = attrStr
	
end


-- 装备武学按钮点击行为
function JingJieDetailWindow:OnZBWXButtonClick()
	
	--rktEventEngine.FireExecute(ENTITYPART_CREATURE_SKILL, SOURCE_TYPE_SYSTEM, SKILL_UI_EVENT_JUMP_EQUIP_JINGJIE_WUXUE, self.m_JingJieId, self.m_LiuPaiNo)
	--UIManager.JingJieDetailWindow:Hide()
	
end


return JingJieDetailWindow