--/******************************************************************
--** 文件名:    WuXueBookItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-07-06
--** 版  本:    1.0
--** 描  述:    武学界面的武学书图标
--** 应  用:  
--******************************************************************/

local WuXueBookItem = UIControl:new
{
    windowName = "WuXueBookItem",
	m_group = nil,
	m_ActScheme = nil,		-- 图标对应的武学书激活配置:BattleBook_Activation
}

function WuXueBookItem:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	self.onItemClick = function(isOn) self:OnItemClick(isOn) end
	self.Controls.m_toggle.group = self.m_group
	self.Controls.m_toggle.onValueChanged:AddListener(self.onItemClick )

	
end

-- 更新图标
-- @actScheme:武学书激活配置:BattleBook_Activation
-- @theSelectedWuXueId:当前选中的武学Id:humber
function WuXueBookItem:UpdateItem(actScheme, theSelectedWuXueId)
	
	self.m_ActScheme = actScheme
	
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
	local isOpen = xiuWei >= actScheme.Activation
	local wuXueLevel = studyPart:GetWuXueLevel(actScheme.ID)
	local isSelected = theSelectedWuXueId == actScheme.ID
	
	self.Controls.m_TfLockNode.gameObject:SetActive(not isOpen)
	self.Controls.m_TfOpenNode.gameObject:SetActive(isOpen)
	self.Controls.m_TfSelectedTip.gameObject:SetActive(isSelected)
	
	local oriClr = self.Controls.m_ImageWuXueIcon.color
	local canUpgrade = studyPart:CheckWuXueCanUpgrade(actScheme.ID)
	self.Controls.m_TextWuXueName.text = actScheme.Name
	local imageBg = GuiAssetList.WuxueQualityBg[actScheme.Quality]
	if imageBg == nil then 
		uerror("wuxue QualityBg is nil")
	else
		UIFunction.SetImageSprite(self.Controls.m_IconBg,imageBg)
	end

	if not isOpen then
		oriClr.a =1
		self.Controls.m_TextOpenCondition.text = string.format("<color=#E4595AFF>需要%d修为</color>", actScheme.Activation)
	else 
		oriClr.a = 1

		if wuXueLevel < 1 then
			self.Controls.m_TextWuXueLevel.text = "<color=#597993FF>0</color>"
		else 
			self.Controls.m_TextWuXueLevel.text = string.format("<color=#597993FF>%d</color>", wuXueLevel)
		end
		
	end
	
	self.Controls.m_TfTipCanUpgrade.gameObject:SetActive(canUpgrade)
	self.Controls.m_ImageWuXueIcon.color = oriClr
	UIFunction.SetImageSprite(self.Controls.m_ImageWuXueIcon, AssetPath.TextureGUIPath..actScheme.Icon)
	
end

-- 技能图标的点行为
function WuXueBookItem:OnItemClick(state)
	if state == true then 
		rktEventEngine.FireExecute(ENTITYPART_CREATURE_SKILL, SOURCE_TYPE_SYSTEM, SKILL_UI_EVENT_WUXUE_BOOK_ITEM_CLICK, self.m_ActScheme.ID)
	end

end


function WuXueBookItem:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function WuXueBookItem:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end


function WuXueBookItem:SetGroup(group)
	self.m_group = group
end

-- 清除数据
function WuXueBookItem:CleanData()

	self.Controls.m_toggle.onValueChanged:RemoveListener(self.onItemClick )
	self.onItemClick = nil
	
end

return WuXueBookItem