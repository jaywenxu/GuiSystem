--/******************************************************************
---** 文件名:	UpgradeBaseSkillCell.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-06
--** 版  本:	1.0
--** 描  述:	玩家技能窗口-升级基础和流派技能窗口-技能图标
--** 应  用:  
--******************************************************************/

local UpgradeBaseSkillCell = UIControl:new
{
	windowName 	= "UpgradeBaseSkillCell",
	
	m_SkillId = 0,		-- 技能图标对应的技能Id:number
}

function UpgradeBaseSkillCell:Attach(obj)
	
	UIControl.Attach(self,obj)
	
	self.onLiuPaiSkillCellClick = function() self:OnLiuPaiSkillCellClick() end
	self.Controls.m_ButtonSkillIcon.onClick:AddListener(self.onLiuPaiSkillCellClick)
	
end

-- 更新图标
-- @skillId:技能id:number
-- @skillLv:技能等级:number
-- @isSelected:是否选中的标识:boolean
function UpgradeBaseSkillCell:UpdateCell(skillId, skillTotalLv, skillOriginalLv, isSelected)
	
	local schemeLv = skillTotalLv 
	if schemeLv < 1 then
		schemeLv = 1
	end
	
	local skillUpdateScheme = IGame.rktScheme:GetSchemeInfo(SKILLUPDATE_CSV, skillId, schemeLv)
	if not skillUpdateScheme then
        uerror("UpgradeBaseSkillCell:UpdateCell could not find skill update config, id = "..skillId..", level = "..schemeLv)
		return
	end
    
	if skillUpdateScheme.UIIsShow < 1 then 
		self.transform.gameObject:SetActive(false)
		return
	else
		self.transform.gameObject:SetActive(true)
	end
	
	self.m_SkillId = skillId
	
	if skillTotalLv > 0 then
        if skillTotalLv > skillOriginalLv then
            self.Controls.m_TextSkillLevel.text = string.format("<color=#FF7800FF>等级 %d(+%d)</color>", skillOriginalLv, skillTotalLv - skillOriginalLv)
        else
            self.Controls.m_TextSkillLevel.text = string.format("<color=#FF7800FF>等级 %d</color>", skillTotalLv)
        end
	else
		self.Controls.m_TextSkillLevel.text = string.format("<color=#e4595aFF>未学会</color>") 
	end
	
	self.Controls.m_TfLockTip.gameObject:SetActive(skillTotalLv < 1)
	self.Controls.m_TfSelectedTip.gameObject:SetActive(isSelected)
	self.Controls.m_TextSkillName.text = skillUpdateScheme.Name
	UIFunction.SetImageSprite(self.Controls.m_ImageSkillIcon, AssetPath.TextureGUIPath..skillUpdateScheme.Icon)
	
end

-- 流派技能点击的行为
function UpgradeBaseSkillCell:OnLiuPaiSkillCellClick()
	
	UIManager.PlayerSkillWindow:ChangeTheUpgradeWindowSkillSelected(self.m_SkillId)
	
end	


function UpgradeBaseSkillCell:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function UpgradeBaseSkillCell:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function UpgradeBaseSkillCell:CleanData()
	
	self.Controls.m_ButtonSkillIcon.onClick:RemoveListener(self.onLiuPaiSkillCellClick)
	self.onLiuPaiSkillCellClick = nil
	
end
	

return UpgradeBaseSkillCell