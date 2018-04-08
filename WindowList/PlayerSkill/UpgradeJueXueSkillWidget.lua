--/******************************************************************
---** 文件名:	UpgradeJueXueSkillWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-05
--** 版  本:	1.0
--** 描  述:	玩家技能窗口-绝学技能升级窗口
--** 应  用:  
--******************************************************************/



local UpgradeJueXueSkillWidget = UIControl:new
{
	windowName 	= "UpgradeJueXueSkillWidget",
	
	m_CurSkillIdSelected = 0,			-- 当前选中的技能id:number
}

function UpgradeJueXueSkillWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	
end

-- 变更选中的技能
-- @skillId:要选中的技能ID:number
function UpgradeJueXueSkillWidget:ChangeTheSelectedSkill(skillId)

	self.m_CurSkillIdSelected = skillId
	
	-- 刷新窗口的显示
	self:RefreshWindowShow()

end

-- 刷新窗口的显示
function UpgradeJueXueSkillWidget:RefreshWindowShow()
	
	local hero = GetHero() 
	if not hero then 
		return 
	end
	
	local skillPart = hero:GetEntityPart(ENTITYPART_CREATURE_SKILL)
	if not skillPart then
		return
	end

	local skillTotalLv = skillPart:GetTotalSkillLevel(self.m_CurSkillIdSelected)
	local schemeLv = skillTotalLv 
	if schemeLv < 1 then
		schemeLv = 1
	end
    
    local skillOriginalLv = skillPart:GetOriginalSkillLevel(self.m_CurSkillIdSelected)
	local skillUpdateScheme = IGame.rktScheme:GetSchemeInfo(SKILLUPDATE_CSV, self.m_CurSkillIdSelected, schemeLv)
	if not skillUpdateScheme then
		return
	end
	
	if skillTotalLv > 0 then
        if skillTotalLv > skillOriginalLv then
            self.Controls.m_TextSkillLevel.text = string.format("<color=#02F2FB>等级 %d(+%d)</color>", skillOriginalLv, skillTotalLv - skillOriginalLv)
        else
            self.Controls.m_TextSkillLevel.text = string.format("<color=#02F2FB>等级 %d</color>", skillTotalLv)
        end
	else 
		self.Controls.m_TextSkillLevel.text = string.format("<color=#F31E4D>未学会</color>")
	end
	
	self.Controls.m_TextSkillName.text = skillUpdateScheme.Name
	
	UIFunction.SetImageSprite(self.Controls.m_ImageSkillIcon, AssetPath.TextureGUIPath..skillUpdateScheme.Icon)
	UIFunction.SetImageGray(self.Controls.m_ImageSkillIcon, skillTotalLv < 1)
	UIFunction.SetImageGray(self.Controls.m_ImageBgSkill, skillTotalLv < 1)
	
end

return UpgradeJueXueSkillWidget