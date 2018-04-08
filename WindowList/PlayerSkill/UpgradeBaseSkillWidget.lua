--/******************************************************************
---** 文件名:	UpgradeBaseSkillWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-05
--** 版  本:	1.0
--** 描  述:	玩家技能窗口-基础和流派技能升级窗口
--** 应  用:  
--******************************************************************/

local UpgradeBaseSkillCell = require("GuiSystem.WindowList.PlayerSkill.UpgradeBaseSkillCell")

local UpgradeBaseSkillWidget = UIControl:new
{
	windowName 	= "UpgradeBaseSkillWidget",
	
	m_CurSkillIdSelected = 0,			-- 当前选中的技能id:number
	m_IsLiuPaiSkillInShow = false,		-- 当前是否在显示流派技能的标识:boolean
	m_ListBaseSkillCell = { } 			-- 基础技能图标脚本列表:UpgradeBaseSkillCell
}

function UpgradeBaseSkillWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	
	-- 绑定流派技能图标
	self:AttachLiuPaiSkillCell()
	
end

-- 变更选中的技能
-- @isLiuPaiSkill:是否是流派技能的标识:boolean
-- @skillId:当前选中要显示的技能id:number
function UpgradeBaseSkillWidget:ChangeTheSelectedSkill(isLiuPaiSkill, skillId)
	
	self.m_CurSkillIdSelected = skillId
	self.m_IsLiuPaiSkillInShow = isLiuPaiSkill
	
	-- 更新流派技能图标的显示
	self:UpdateLiuPaiSkillCellShow()
	
end

-- 刷新窗口的显示
function UpgradeBaseSkillWidget:RefreshWindowShow()

	-- 更新流派技能图标的显示
	self:UpdateLiuPaiSkillCellShow()	
	
end

-- 绑定流派技能图标
function UpgradeBaseSkillWidget:AttachLiuPaiSkillCell()
	
	for cellIdx = 1, 8 do
		self.m_ListBaseSkillCell[cellIdx] = UpgradeBaseSkillCell:new()
		self.m_ListBaseSkillCell[cellIdx]:Attach(self.Controls[string.format("m_TfUpgradeBaseSkillCell%d", cellIdx)].gameObject)
	end
	
end

-- 更新流派技能图标的显示
function UpgradeBaseSkillWidget:UpdateLiuPaiSkillCellShow()
	
	local hero = GetHero() 
	if not hero then 
		return 
	end
	
	local skillPart = hero:GetEntityPart(ENTITYPART_CREATURE_SKILL)
	if not skillPart then
		return
	end
	
	local listSkillId = {}
	
	if self.m_IsLiuPaiSkillInShow then
		listSkillId = skillPart:GetLiuPaiSkillIdList()
	else 
		listSkillId = skillPart:GetBaseSkillIdList()
	end
	
	local skillCnt = #listSkillId
	for skillIdx = 1, #self.m_ListBaseSkillCell do
		local skillCell = self.m_ListBaseSkillCell[skillIdx]
		skillCell.transform.gameObject:SetActive(skillIdx <= skillCnt)

		if skillIdx <= skillCnt then
			local skillId = listSkillId[skillIdx]
			local skillTotalLv = skillPart:GetTotalSkillLevel(skillId)
            local skillOriginalLv = skillPart:GetOriginalSkillLevel(skillId)
			local isSelected = skillId == self.m_CurSkillIdSelected
			skillCell:UpdateCell(skillId, skillTotalLv, skillOriginalLv, isSelected)
		end
	end
	
end

return UpgradeBaseSkillWidget