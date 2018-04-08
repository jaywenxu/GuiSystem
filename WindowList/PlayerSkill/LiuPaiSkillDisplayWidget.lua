--/******************************************************************
---** 文件名:	LiuPaiSkillDisplayWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-03
--** 版  本:	1.0
--** 描  述:	玩家技能窗口的-流派窗口-流派展示窗口
--** 应  用:  
--******************************************************************/

local LiuPaiSkillDisplayCell = require("GuiSystem.WindowList.PlayerSkill.LiuPaiSkillDisplayCell")

local LiuPaiSkillDisplayWidget = UIControl:new
{
	windowName 	= "LiuPaiSkillDisplayWidget",
	
	m_LiuPaiNo = 0,					-- 当前窗口对应的流派编号:number
	m_NorSkillCell = 0,				-- 普工技能图标脚本:LiuPaiSkillDisplayCell
	m_ListLiuPaiSkillCell = {},		-- 流派技能图标脚本:LiuPaiSkillDisplayCell
}

function LiuPaiSkillDisplayWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	
	self.onUseButtonClick = function() self:OnUseButtonClick() end
	self.Controls.m_ButtonUse.onClick:AddListener(self.onUseButtonClick)
	
	-- 绑定技能图标
	self:AttachSkillCell()
	
end

-- 更新窗口
-- @vocation:职业:number
-- @liuPaiNo:流派技能编号:number
-- @inUse:该方案是否当前在使用的标识:boolean
function LiuPaiSkillDisplayWidget:UpdateWindow(vocation, liuPaiNo, inUse)
	
	self.m_LiuPaiNo = liuPaiNo
	
	-- 更新技能方案的技能显示
	self:UpdateSkillPanSkillShow(vocation)
	-- 更新技能方案的描述显示
	self:UpdateSkillPanDescShow(vocation, inUse)
	
end

-- 更新技能方案的技能显示
-- @vocation:职业:number
function LiuPaiSkillDisplayWidget:UpdateSkillPanSkillShow(vocation)
	
	local hero = GetHero() 
	if not hero then 
		return 
	end
	
	local skillPart = hero:GetEntityPart(ENTITYPART_CREATURE_SKILL)
	if not skillPart then
		return
	end
	
	local skillButtonScheme = IGame.rktScheme:GetSchemeInfo(SKILLBUTTON_CSV, vocation, self.m_LiuPaiNo)
	if not skillButtonScheme then
		return
	end
	
	local listLiuPaiSkillId = 
	{
		IGame.SkillClient:FilterNormalSkillID(skillButtonScheme.Button2),
		IGame.SkillClient:FilterNormalSkillID(skillButtonScheme.Button3),
		IGame.SkillClient:FilterNormalSkillID(skillButtonScheme.Button4),
		IGame.SkillClient:FilterNormalSkillID(skillButtonScheme.Button5),
	}

	-- 技能数量不一致
	if #listLiuPaiSkillId ~= #self.m_ListLiuPaiSkillCell then
		return
	end
	
	-- 流派技能更新
	for skillIdx = 1, #listLiuPaiSkillId do
		local skillCell = self.m_ListLiuPaiSkillCell[skillIdx]
		local skillId = listLiuPaiSkillId[skillIdx]
		local skillLv = skillPart:GetTotalSkillLevel(skillId)
		
		skillCell:UpdateCell(skillId, skillLv)
	end
	
	-- 普攻技能更新
	local norSkillLv = skillPart:GetTotalSkillLevel(IGame.SkillClient:FilterNormalSkillID(skillButtonScheme.Button1))
	self.m_NorSkillCell:UpdateCell(IGame.SkillClient:FilterNormalSkillID(skillButtonScheme.Button1), norSkillLv)
	
end

-- 更新技能方案的描述显示
-- @vocation:职业:number
-- @inUse:该方案是否当前在使用的标识:boolean
function LiuPaiSkillDisplayWidget:UpdateSkillPanDescShow(vocation, inUse)
	
	local skillButtonScheme = IGame.rktScheme:GetSchemeInfo(SKILLBUTTON_CSV, vocation, self.m_LiuPaiNo)
	if not skillButtonScheme then
		return
	end
	
	self.Controls.m_GoInUseButton.gameObject:SetActive(inUse)
	self.Controls.m_GoUseButton.gameObject:SetActive(not inUse)
	
	--local newDesc = string.gsub(skillButtonScheme.Desc1, "\\n", "\n");
	local newEff = string.gsub(skillButtonScheme.Desc3, "\\n", "\n");
	
	self.Controls.m_TextDesc1.text = skillButtonScheme.Desc1
	self.Controls.m_TextDesc2.text = skillButtonScheme.Desc2
	self.Controls.m_TextEffect.text = newEff
	
end

-- 绑定技能图标
function LiuPaiSkillDisplayWidget:AttachSkillCell()

	self.m_NorSkillCell = LiuPaiSkillDisplayCell:new()
	self.m_NorSkillCell:Attach(self.Controls.m_LiuPaiSkillDisplayCell5.gameObject)
	
	for skillIdx = 1, 4 do
		self.m_ListLiuPaiSkillCell[skillIdx] = LiuPaiSkillDisplayCell:new()
		self.m_ListLiuPaiSkillCell[skillIdx]:Attach(self.Controls[string.format("m_LiuPaiSkillDisplayCell%d", skillIdx)].gameObject)
	end
	
end

-- 使用按钮的点击行为
function LiuPaiSkillDisplayWidget:OnUseButtonClick()
	
	local studyPart = GetHeroEntityPart(ENTITYPART_PERSON_STUDYSKILL)
	if not studyPart then
		return
	end
	
	studyPart:RequestChangeLiuPai(self.m_LiuPaiNo)
	
end

function LiuPaiSkillDisplayWidget:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function LiuPaiSkillDisplayWidget:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function LiuPaiSkillDisplayWidget:CleanData()
	
	self.Controls.m_ButtonUse.onClick:RemoveListener(self.onUseButtonClick)
	self.onUseButtonClick = nil
	
end

return LiuPaiSkillDisplayWidget