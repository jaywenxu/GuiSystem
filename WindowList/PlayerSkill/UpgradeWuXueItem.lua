--/******************************************************************
---** 文件名:	UpgradeWuXueItem.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-07
--** 版  本:	1.0
--** 描  述:	玩家技能窗口-境界展示窗口-境界图标
--** 应  用:  
--******************************************************************/

local UpgradeWuXueItem = UIControl:new
{
	windowName 	= "UpgradeWuXueItem",
	
	m_wuXueId = 0,		-- 当前图标对应的武学ID:number
}

function UpgradeWuXueItem:Attach(obj)
	
	UIControl.Attach(self,obj)
	
	self.onItemClick = function() self:OnItemClick() end
	self.Controls.m_ButtonIcon.onClick:AddListener(self.onItemClick )
	
end

-- 更新图标
-- @wuXueScheme:武学配置表:BattleBook_Activation
function UpgradeWuXueItem:UpdateItem(wuXueScheme)
	
	self.m_wuXueId = wuXueScheme.ID
	
	local hero = GetHero() 
    if not hero then 
        return 
    end
    
	local skillPart = hero:GetEntityPart(ENTITYPART_CREATURE_SKILL)
    local studyPart = hero:GetEntityPart(ENTITYPART_PERSON_STUDYSKILL)
    if not studyPart or not skillPart then
        return
    end
	
	local xiuWei = studyPart:GetXiuWei()
	local isOpen = xiuWei >= wuXueScheme.Activation
	
	self.Controls.m_TfLockNode.gameObject:SetActive(not isOpen)
	self.Controls.m_TfOpenNode.gameObject:SetActive(isOpen)
	
	local oriClr = self.Controls.m_ImageWuXueIcon.color
	
	if not isOpen then
		oriClr.a = 0.75
		self.Controls.m_TextOpenCondition.text = string.format("需%d修为", wuXueScheme.Activation)
	else 
		oriClr.a = 1
		self.Controls.m_TextWuXueName.text = wuXueScheme.Name
	end
	
	self.Controls.m_ImageWuXueIcon.color = oriClr
	UIFunction.SetImageSprite(self.Controls.m_ImageWuXueIcon, AssetPath.TextureGUIPath..wuXueScheme.Icon)
	
end

-- 图标的点击行为
function UpgradeWuXueItem:OnItemClick()
	
	-- UIManager.JingJieDetailWindow:ShowWindow(self.m_JingJieId, self.m_LiuPaiNo)
	rktEventEngine.FireExecute(ENTITYPART_CREATURE_SKILL, SOURCE_TYPE_SYSTEM, SKILL_UI_EVENT_UPGRADE_WUXUE_CLITK, self.m_wuXueId)
	
end

function UpgradeWuXueItem:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function UpgradeWuXueItem:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function UpgradeWuXueItem:CleanData()
	
	self.Controls.m_ButtonIcon.onClick:RemoveListener(self.onItemClick)
	self.onItemClick = nil
	
end

return UpgradeWuXueItem
