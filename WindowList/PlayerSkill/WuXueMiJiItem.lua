--/******************************************************************
--** 文件名:    WuXueMiJiItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-07-06
--** 版  本:    1.0
--** 描  述:    武学界面的秘籍图标
--** 应  用:  
--******************************************************************/

local WuXueMiJiItem = UIControl:new
{
    windowName = "WuXueMiJiItem",
	
	m_WuXueId = 0,		-- 秘籍对应的武学id:number
	m_MiJiId = 0,		-- 秘籍配置id:number
	m_MiJiIdx = 0,		-- 秘籍对应的编号:number
}

function WuXueMiJiItem:Attach(obj)
	
    UIControl.Attach(self, obj)
	
	self.onItemClick = function() self:OnItemClick() end
	self.Controls.m_ButtonItem.onClick:AddListener(self.onItemClick )
	
end

-- 更新图标
-- @wuXueId:秘籍对应的武学id:number
-- @miJiId:秘籍配置id:number
-- @miJiIdx:秘籍对应的编号:number
-- @theSelectedMiJiId:当前选中的秘籍id:number
function WuXueMiJiItem:UpdateItem(wuXueId, miJiId, miJiIdx, theSelectedMiJiId)
	
	self.m_WuXueId = wuXueId
	self.m_MiJiId = miJiId
	self.m_MiJiIdx  = miJiIdx
	
	local wuXueScheme = IGame.rktScheme:GetSchemeInfo(BATTLEBOOK_ACTIVATION_CSV, wuXueId)
	if not wuXueScheme then
		return
	end
	
	local studyPart = GetHeroEntityPart(ENTITYPART_PERSON_STUDYSKILL)
	if not studyPart then
		return
	end
	
	local isWuXueUnlock = studyPart:CheckWuXueIsUnlock(wuXueId)
	local canUpgradeMiJi = studyPart:CheckMiJiCanUpgrade(miJiId)
	local miJiLv = studyPart:GetWuXueSlotLevel(miJiId)
	local iconName = wuXueScheme[string.format("Slot%dIcon", miJiIdx)]
	local bgName = wuXueScheme[string.format("Slot%dFrame", miJiIdx)]
	
	if miJiLv < 1 then
		self.Controls.m_TextMiJiLevel.gameObject:SetActive(false)
		self.Controls.m_TextMiJiLevel.text = "<color=#F9063F>0级</color>"
	else
		self.Controls.m_TextMiJiLevel.gameObject:SetActive(true)
		self.Controls.m_TextMiJiLevel.text = string.format("<color=#FF7800FF>%d级</color>", miJiLv)
	end

	-- 1.秘籍没有激活且不可提升时（0级、升级材料不足），秘籍变灰
	-- 2.秘籍可提升时，显示常态（亮）+箭头（右上角）
	-- 3.秘籍已激活（等级＞0）、不可提升时，显示常态
	local iconNeedGray = not isWuXueUnlock or (not canUpgradeMiJi and miJiLv < 1)
	self.Controls.m_TfTipCanUp.gameObject:SetActive(canUpgradeMiJi and isWuXueUnlock)
	self.realNeedGray = iconNeedGray
	self.SetGrayFun = function()self:RealSetGray() end
	UIFunction.SetImageGray(self.Controls.m_ImageMiJiIcon, iconNeedGray,self.SetGrayFun)
	UIFunction.SetImageGray(self.Controls.m_ImageMiJiQuality, iconNeedGray,self.SetGrayFun)
	
	self.Controls.m_TfSelectedTip.gameObject:SetActive(miJiId == theSelectedMiJiId)
	UIFunction.SetImageSprite(self.Controls.m_ImageMiJiIcon, AssetPath.TextureGUIPath..iconName)
	UIFunction.SetImageSprite(self.Controls.m_ImageMiJiQuality, AssetPath.TextureGUIPath..bgName)
	
end

function WuXueMiJiItem:RealSetGray()
	UIFunction.SetImageGray(self.Controls.m_ImageMiJiIcon, self.realNeedGray )
	UIFunction.SetImageGray(self.Controls.m_ImageMiJiQuality, self.realNeedGray )
end

-- 技能图标的点行为
function WuXueMiJiItem:OnItemClick()
	
	rktEventEngine.FireExecute(ENTITYPART_CREATURE_SKILL, SOURCE_TYPE_SYSTEM, SKILL_UI_EVENT_WUXUE_MIJI_ITEM_CLICK, self.m_MiJiId)
	
end


function WuXueMiJiItem:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function WuXueMiJiItem:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function WuXueMiJiItem:CleanData()

	self.Controls.m_ButtonItem.onClick:RemoveListener(self.onItemClick)
	self.onItemClick = nil
	
end


return WuXueMiJiItem