--/******************************************************************
---** 文件名:	LiuPaiSkillDisplayCell.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-06
--** 版  本:	1.0
--** 描  述:	玩家技能窗口-升级流派技能窗口-技能图标
--** 应  用:  
--******************************************************************/

local LiuPaiSkillDisplayCell = UIControl:new
{
	windowName 	= "LiuPaiSkillDisplayCell",
	
	m_SkillId = 0,		-- 技能图标对应的技能Id:number
	m_SkillLv = 0,		-- 技能图标对应的技能lv:number
}

local CELL_WIDTH = 150	-- 图标的宽度

function LiuPaiSkillDisplayCell:Attach(obj)
	
	UIControl.Attach(self,obj)
	
	self.onLiuPaiSkillCellClick = function() self:OnLiuPaiSkillCellClick() end
	self.Controls.m_ButtonSkillIcon.onClick:AddListener(self.onLiuPaiSkillCellClick)
	
end

-- 更新图标
-- @skillId:技能id:number
-- @skillLv:技能等级:number
function LiuPaiSkillDisplayCell:UpdateCell(skillId, skillLv)
	
	local schemeLv = skillLv 
	if schemeLv < 1 then
		schemeLv = 1
	end
	
	local skillUpdateScheme = IGame.rktScheme:GetSchemeInfo(SKILLUPDATE_CSV, skillId, schemeLv)
	if not skillUpdateScheme then
        uerror("LiuPaiSkillDisplayCell:UpdateCell could not find skill update config, id = "..skillId..", level = "..schemeLv)
		return
	end
	
	self.m_SkillId = skillId
	self.m_SkillLv = skillLv
	
	UIFunction.SetImageSprite(self.Controls.m_ImageSkillIcon, AssetPath.TextureGUIPath..skillUpdateScheme.Icon)
	UIFunction.SetImageGray(self.Controls.m_ImageSkillIcon, skillLv < 1)
	
end

-- 流派技能点击的行为
function LiuPaiSkillDisplayCell:OnLiuPaiSkillCellClick()
	
	UIManager.LiuPaiSkillTipWindow:ShowWindow(self.m_SkillId, self.transform.position, CELL_WIDTH)
	
end	

function LiuPaiSkillDisplayCell:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function LiuPaiSkillDisplayCell:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function LiuPaiSkillDisplayCell:CleanData()
	
	self.Controls.m_ButtonSkillIcon.onClick:RemoveListener(self.onLiuPaiSkillCellClick)
	self.onLiuPaiSkillCellClick = nil
	
end

return LiuPaiSkillDisplayCell