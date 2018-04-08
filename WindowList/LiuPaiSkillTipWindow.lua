--/******************************************************************
---** 文件名:	LiuPaiSkillTipWindow.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-06
--** 版  本:	1.0
--** 描  述:	流派技能提示弹窗
--** 应  用:  
--******************************************************************/

local LiuPaiSkillTipWindow = UIWindow:new
{
	windowName = "LiuPaiSkillTipWindow",	-- 窗口名称
	
	m_SkillId = 0,							-- 当前显示技能对应的id:number
	m_TheClickCellWorldPos = 0,				-- 当前点击的图标的世界坐标:Vector3
	m_PartOfCellWidth = 0,					-- 点击的图标的一半宽度:number
	m_HaveInvokeOnWindowShow = false,		-- 是否调用了OnWindowShow方法的标识:boolean
}

local PART_OF_WINDOW_WIDTH = 190			-- 窗口的一半宽度

function LiuPaiSkillTipWindow:Init()
	

end

function LiuPaiSkillTipWindow:OnAttach( obj )
	
	UIWindow.OnAttach(self, obj)
	
	self.Controls.m_ButtonMask.onClick:AddListener(function() UIManager.LiuPaiSkillTipWindow:Hide() end)
	
	if self.m_HaveInvokeOnWindowShow then
		self.m_HaveInvokeOnWindowShow = false
		self:OnWindowShow()
	end
		
	return self
	
end

function LiuPaiSkillTipWindow:_showWindow()
	UIWindow._showWindow(self)

	if self:isLoaded() then
		self:OnWindowShow()
	else
		self.m_HaveInvokeOnWindowShow = true
	end
end

-- 显示窗口
-- @skillId:要显示的技能id:number
-- @cellWorldPos:图标世界位置:Vector3
-- @cellWidth:图标宽度:number
function LiuPaiSkillTipWindow:ShowWindow(skillId, cellWorldPos, cellWidth)

	self.m_SkillId = skillId 
	self.m_TheClickCellWorldPos = cellWorldPos
	self.m_PartOfCellWidth = cellWidth / 2

	UIWindow.Show(self, true)
	
end


-- 窗口每次打开执行的行为
function LiuPaiSkillTipWindow:OnWindowShow()
	
	local skillUpdateScheme = IGame.rktScheme:GetSchemeInfo(SKILLUPDATE_CSV, self.m_SkillId, 1)
	local skillScheme = IGame.rktScheme:GetSchemeInfo(SKILL_CSV, self.m_SkillId, 1, 1)
	if not skillUpdateScheme or not skillScheme then
		return 
	end
	
	-- 冷却时间计算
	local freezeScheme = IGame.rktScheme:GetSchemeInfo(FREEZE_CSV, EFreeze_ClassID_Skill, skillScheme.CoolDown)
	local coolTime = 0
	if(freezeScheme) then
		coolTime = freezeScheme.Time / 1000
	end
	
	self.Controls.m_TextSkillName.text = skillUpdateScheme.Name
	self.Controls.m_TextSkillType.text = "类型："..skillUpdateScheme.TypeDesc
	self.Controls.m_TextSkillDesc.text = skillUpdateScheme.CommonDesc
	self.Controls.m_TextSkillCoolTime.text = string.format("冷却时间：%ds", coolTime)
	
	UIFunction.SetImageSprite(self.Controls.m_ImageSkillIcon, AssetPath.TextureGUIPath..skillUpdateScheme.Icon)
	
	-- 计算显示的位置
	local localPos = self.transform:InverseTransformVector(self.m_TheClickCellWorldPos)
	if localPos.x + PART_OF_WINDOW_WIDTH + self.m_PartOfCellWidth > 960 - PART_OF_WINDOW_WIDTH then
		localPos.x = localPos.x - PART_OF_WINDOW_WIDTH - self.m_PartOfCellWidth
	else 
		localPos.x = localPos.x + PART_OF_WINDOW_WIDTH + self.m_PartOfCellWidth
	end
	
	localPos.y = localPos.y + self.m_PartOfCellWidth
	self.Controls.m_NodeElement.localPosition = localPos
	
end


return LiuPaiSkillTipWindow