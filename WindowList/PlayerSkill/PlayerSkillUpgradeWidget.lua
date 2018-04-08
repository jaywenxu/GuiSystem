--/******************************************************************
---** 文件名:	PlayerSkillUpgradeWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-03
--** 版  本:	1.0
--** 描  述:	玩家技能窗口-升级窗口
--** 应  用:  
--******************************************************************/

local PlayerSkillUpgradeWidget = UIControl:new
{
	windowName 	= "PlayerSkillUpgradeWidget",
	
	m_CurSelectedTab = 0,					-- 当前选择的页签类型:SkillUpgradeLeftTopTabType(string)
	m_CurSelectedSkillId = 0,				-- 当前选中的技能id:number
	m_UpgradeSkillInfoWidget = nil,			-- 升级技能信息窗口:UpgradeSkillInfoWidget
	m_UpgradeWuXueDisplayWidget = nil,		-- 技能升级窗口的武学展示窗口:UpgradeWuXueDisplayWidget
	m_UpgradeBaseSkillWidget = nil,			-- 升级基础和流派技能的窗口:UpgradeBaseSkillWidget
	m_UpgradeJueXueSkillWidget = nil,		-- 升级绝学技能的窗口:UpgradeJueXueSkillWidget
}

-- 左上角功能页签类型
local SkillUpgradeLeftTopTabType = 
{
	TAB_TYPE_JICHU	= "TAB_TYPE_JICHU", 		-- 基础
	TAB_TYPE_LIUPAI = "TAB_TYPE_LIUPAI",		-- 流派
	TAB_TYPE_JUEXUE = "TAB_TYPE_JUEXUE",		-- 绝学
}

function PlayerSkillUpgradeWidget:Attach(obj)
	
	UIControl.Attach(self,obj)

	-- 事件绑定
	self:SubscribeEvent()
	-- 绑定子窗口
	self:AttachChildWindow()
	-- 初始化左上角页签的点击行为
	self:InitLeftTopTabClickAction()
	
end

-- 显示窗口
function PlayerSkillUpgradeWidget:ShowWindow()
	
	UIControl.Show(self)
	--self.transform.gameObject:SetActive(true)

	self.m_UpgradeWuXueDisplayWidget:ShowWidget()
	
	-- 初始化默认选中的页签
	self:InitTheDefaultSelectedTab()
	-- 变更子窗口的显示
	self:ChangeChildWindow(self.m_CurSelectedTab)

end

-- 隐藏窗口
function PlayerSkillUpgradeWidget:HideWindow()
	
	UIControl.Hide(self, false)
	--self.transform.gameObject:SetActive(false)
	
end

-- 事件绑定
function PlayerSkillUpgradeWidget:SubscribeEvent()
	
    self.handlePlayerSkillDataChange = function(event, srctype, srcid) self:HandlePlayerSkillDataChange(event, srctype, srcid) end
	
    rktEventEngine.SubscribeExecute(ENTITYPART_CREATURE_SKILL, SOURCE_TYPE_SYSTEM, SKILL_UI_EVENT_PLAYER_SKILL_DATA_CHANGE, self.handlePlayerSkillDataChange)
end

-- 移除事件的绑定
function PlayerSkillUpgradeWidget:UnSubscribeEvent()
	
    rktEventEngine.UnSubscribeExecute(ENTITYPART_CREATURE_SKILL, SOURCE_TYPE_SYSTEM, SKILL_UI_EVENT_PLAYER_SKILL_DATA_CHANGE, self.handlePlayerSkillDataChange)
	
end

-- 玩家技能数据变动处理
function PlayerSkillUpgradeWidget:HandlePlayerSkillDataChange(event, srctype, srcid)
	
	self.m_UpgradeWuXueDisplayWidget:UpdateWindowShow()
	
	if self.m_CurSelectedTab == SkillUpgradeLeftTopTabType.TAB_TYPE_JICHU then
		self.m_UpgradeBaseSkillWidget:RefreshWindowShow()
	elseif self.m_CurSelectedTab == SkillUpgradeLeftTopTabType.TAB_TYPE_LIUPAI then
		self.m_UpgradeBaseSkillWidget:RefreshWindowShow()
	else 
		self.m_UpgradeJueXueSkillWidget:RefreshWindowShow()
	end

	self.m_UpgradeSkillInfoWidget:UpdateWindow(self.m_CurSelectedSkillId)
	
end


-- 初始化默认选中的页签
function PlayerSkillUpgradeWidget:InitTheDefaultSelectedTab()
	
	self.m_CurSelectedTab = SkillUpgradeLeftTopTabType.TAB_TYPE_JICHU
	
end

-- 绑定子窗口
function PlayerSkillUpgradeWidget:AttachChildWindow()
	
	self.m_UpgradeBaseSkillWidget = require("GuiSystem.WindowList.PlayerSkill.UpgradeBaseSkillWidget"):new()
	self.m_UpgradeJueXueSkillWidget = require("GuiSystem.WindowList.PlayerSkill.UpgradeJueXueSkillWidget"):new()
	self.m_UpgradeSkillInfoWidget = require("GuiSystem.WindowList.PlayerSkill.UpgradeSkillInfoWidget"):new()
	self.m_UpgradeWuXueDisplayWidget = require("GuiSystem.WindowList.PlayerSkill.UpgradeWuXueDisplayWidget"):new()
	
	self.m_UpgradeBaseSkillWidget:Attach(self.Controls.m_TfUpgradeBaseSkillWidget.gameObject)
	self.m_UpgradeJueXueSkillWidget:Attach(self.Controls.m_TfUpgradeJueXueSkillWidget.gameObject)
	self.m_UpgradeSkillInfoWidget:Attach(self.Controls.m_TfUpgradeSkillInfoWidget.gameObject)
	self.m_UpgradeWuXueDisplayWidget:Attach(self.Controls.m_TfUpgradeWuXueDisplayWidget.gameObject)
	
end

-- 初始化左上角页签的点击行为
function PlayerSkillUpgradeWidget:InitLeftTopTabClickAction()
	
	self.onLeftTopTabClick1 = function() self:OnLeftTopTabClick(SkillUpgradeLeftTopTabType.TAB_TYPE_JICHU) end
	self.onLeftTopTabClick2 = function() self:OnLeftTopTabClick(SkillUpgradeLeftTopTabType.TAB_TYPE_LIUPAI) end
	self.onLeftTopTabClick3 = function() self:OnLeftTopTabClick(SkillUpgradeLeftTopTabType.TAB_TYPE_JUEXUE) end
	self.Controls.m_ButtonJiChu.onClick:AddListener(self.onLeftTopTabClick1)
	self.Controls.m_ButtonLiuPai.onClick:AddListener(self.onLeftTopTabClick2)
	self.Controls.m_ButtonJueXue.onClick:AddListener(self.onLeftTopTabClick3)

end

-- 变更选中的技能
-- @skillId:要选中的技能ID:number
function PlayerSkillUpgradeWidget:ChangeTheSelectedSkill(skillId)
	
	self.m_CurSelectedSkillId = skillId

	if self.m_CurSelectedTab == SkillUpgradeLeftTopTabType.TAB_TYPE_JICHU then
		self.m_UpgradeBaseSkillWidget:ChangeTheSelectedSkill(false, skillId)
	elseif self.m_CurSelectedTab == SkillUpgradeLeftTopTabType.TAB_TYPE_LIUPAI then
		self.m_UpgradeBaseSkillWidget:ChangeTheSelectedSkill(true, skillId)
	else 
		self.m_UpgradeJueXueSkillWidget:ChangeTheSelectedSkill(skillId)
	end

	self.m_UpgradeSkillInfoWidget:UpdateWindow(self.m_CurSelectedSkillId)
	
end

-- 左上角页签按钮点击行为
-- @tabType:页签的类型:SkillUpgradeLeftTopTabType(string)
function PlayerSkillUpgradeWidget:OnLeftTopTabClick(tabType)
	
	-- 相同标签或在隐藏的不用响应
	if self.m_CurSelectedTab == tabType then 
		return
	end
	
	-- 变更子窗口
	self:ChangeChildWindow(tabType)
	
end

-- 变更子窗口的显示
-- @tabType:子页签类型:SkillUpgradeLeftTopTabType(string)
function PlayerSkillUpgradeWidget:ChangeChildWindow(tabType)

	self.m_CurSelectedTab = tabType
	
	local isJueXueInShow = tabType == SkillUpgradeLeftTopTabType.TAB_TYPE_JUEXUE
	self.m_UpgradeBaseSkillWidget.transform.gameObject:SetActive(not isJueXueInShow)
	self.m_UpgradeJueXueSkillWidget.transform.gameObject:SetActive(isJueXueInShow)
	
	-- 标题
--[[	if self.m_CurSelectedTab == SkillUpgradeLeftTopTabType.TAB_TYPE_JICHU then
		self.Controls.m_TextWidgetTitle.text = "基础技能"
	elseif self.m_CurSelectedTab == SkillUpgradeLeftTopTabType.TAB_TYPE_LIUPAI then
		self.Controls.m_TextWidgetTitle.text = "流派技能"
	else 
		self.Controls.m_TextWidgetTitle.text = "绝技技能"
	end--]]
	
	
	-- 初始化子界面技能的选中
	self:InitTheChildWindowSkillSelected()
	-- 更新页签选中的显示
	self:UpdateTheTabSelectedShow()
	-- 变更选中的技能
	self:ChangeTheSelectedSkill(self.m_CurSelectedSkillId)
	
end

-- 初始化子界面技能的选中
function PlayerSkillUpgradeWidget:InitTheChildWindowSkillSelected()
	
	local hero = GetHero()
	if not hero then
		return 
	end 
	
	local skillPart = hero:GetEntityPart(ENTITYPART_CREATURE_SKILL)
	if not skillPart then
		return
	end
	
	if self.m_CurSelectedTab == SkillUpgradeLeftTopTabType.TAB_TYPE_JICHU then -- 基础技能
		local listBaseSkillId = skillPart:GetBaseSkillIdList()

		if #listBaseSkillId > 0 then
			self.m_CurSelectedSkillId = listBaseSkillId[1]
		else 
			self.m_CurSelectedSkillId = 0
		end
	elseif self.m_CurSelectedTab == SkillUpgradeLeftTopTabType.TAB_TYPE_LIUPAI then -- 流派技能
		local listLiuPaiSkillId = skillPart:GetLiuPaiSkillIdList()

		if #listLiuPaiSkillId > 0 then
			self.m_CurSelectedSkillId = listLiuPaiSkillId[1]
		else 
			self.m_CurSelectedSkillId = 0
		end
	else -- 绝学技能
		self.m_CurSelectedSkillId = skillPart:GetJueXueSkillId()
	end
	
end

-- 更新页签选中的显示
function PlayerSkillUpgradeWidget:UpdateTheTabSelectedShow()
	
	PlayerSkillWindowTool.SetTabSelectedState(self.Controls.m_ButtonJiChu, self.m_CurSelectedTab == SkillUpgradeLeftTopTabType.TAB_TYPE_JICHU)
	PlayerSkillWindowTool.SetTabSelectedState(self.Controls.m_ButtonLiuPai, self.m_CurSelectedTab == SkillUpgradeLeftTopTabType.TAB_TYPE_LIUPAI)
	PlayerSkillWindowTool.SetTabSelectedState(self.Controls.m_ButtonJueXue, self.m_CurSelectedTab == SkillUpgradeLeftTopTabType.TAB_TYPE_JUEXUE)
	
end


function PlayerSkillUpgradeWidget:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function PlayerSkillUpgradeWidget:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	    -- 移除事件的绑定
    self:UnSubscribeEvent()
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function PlayerSkillUpgradeWidget:CleanData()
	
	self.Controls.m_ButtonJiChu.onClick:RemoveListener(self.onLeftTopTabClick1)
	self.Controls.m_ButtonLiuPai.onClick:RemoveListener(self.onLeftTopTabClick2)
	self.Controls.m_ButtonJueXue.onClick:RemoveListener(self.onLeftTopTabClick3)
	
	self.onLeftTopTabClick1 = nil
	self.onLeftTopTabClick2 = nil
	self.onLeftTopTabClick3 = nil
	
end


return PlayerSkillUpgradeWidget
