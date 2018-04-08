--/******************************************************************
---** 文件名:	PlayerLiuPaiSkillWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-03
--** 版  本:	1.0
--** 描  述:	玩家技能窗口-流派窗口
--** 应  用:  
--******************************************************************/

local LiuPaiSkillDisplayWidget = require("GuiSystem.WindowList.PlayerSkill.LiuPaiSkillDisplayWidget")

local PlayerLiuPaiSkillWidget = UIControl:new
{
	windowName 	= "PlayerLiuPaiSkillWidget",
	
	m_LiuPaiSkillDisplayWidgetLeft = 0,			-- 左边的流派技能展示窗口 
	m_LiuPaiSkillDisplayWidgetRight = 0,		-- 左边的流派技能展示窗口
	
}

function PlayerLiuPaiSkillWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	
	-- 事件绑定
	self:SubscribeEvent()
	-- 绑定流派展示窗口
	self:AttachLiuPaiDisplayWidget()
	
end

-- 窗口销毁
function PlayerLiuPaiSkillWidget:OnDestroy()
	
	-- 移除事件的绑定
	self:UnSubscribeEvent()
	
	UIWindow.OnDestroy(self)
	
end

-- 显示窗口
function PlayerLiuPaiSkillWidget:ShowWindow()
	
	UIControl.Show(self)
	--self.transform.gameObject:SetActive(true)
	
	-- 更新窗口的显示
	self:UpdateWindowShow()
	
end

-- 更新窗口的显示
function PlayerLiuPaiSkillWidget:UpdateWindowShow()

	local hero = GetHero()
	if not hero then
		return
	end
	
	local studyPart = hero:GetEntityPart(ENTITYPART_PERSON_STUDYSKILL)
	if not studyPart then
		return
	end
	
	local vocation = hero:GetNumProp(CREATURE_PROP_VOCATION)
	
	self.m_LiuPaiSkillDisplayWidgetLeft:UpdateWindow(vocation, 1, studyPart.liuPai == 1)
	self.m_LiuPaiSkillDisplayWidgetRight:UpdateWindow(vocation, 2, studyPart.liuPai == 2)
	
end

-- 隐藏窗口
function PlayerLiuPaiSkillWidget:HideWindow()
	
	UIControl.Hide(self, false)
	--self.transform.gameObject:SetActive(false)
	
end

-- 事件绑定
function PlayerLiuPaiSkillWidget:SubscribeEvent()
	
	self.handlePlayerLiuPaiChange = function(event, srctype, srcid) self:HandlePlayerLiuPaiChange(event, srctype, srcid) end
	rktEventEngine.SubscribeExecute(ENTITYPART_CREATURE_SKILL, SOURCE_TYPE_SYSTEM, SKILL_UI_EVENT_PLAYER_LIUPAI_CHANGE, self.handlePlayerLiuPaiChange)
	
end

-- 移除事件的绑定
function PlayerLiuPaiSkillWidget:UnSubscribeEvent()
	
	rktEventEngine.UnSubscribeExecute(ENTITYPART_CREATURE_SKILL, SOURCE_TYPE_SYSTEM, SKILL_UI_EVENT_PLAYER_LIUPAI_CHANGE, self.handlePlayerLiuPaiChange)
	
end


-- 绑定流派展示窗口
function PlayerLiuPaiSkillWidget:AttachLiuPaiDisplayWidget()
	
	self.m_LiuPaiSkillDisplayWidgetLeft = LiuPaiSkillDisplayWidget:new()
	self.m_LiuPaiSkillDisplayWidgetRight = LiuPaiSkillDisplayWidget:new()
	
	self.m_LiuPaiSkillDisplayWidgetLeft:Attach(self.Controls.m_LiuPaiSkillDisplayWidget1.gameObject)
	self.m_LiuPaiSkillDisplayWidgetRight:Attach(self.Controls.m_LiuPaiSkillDisplayWidget2.gameObject)
	
end

-- 玩家流派变动处理
function PlayerLiuPaiSkillWidget:HandlePlayerLiuPaiChange(event, srctype, srcid)
	
	-- 更新窗口的显示
	self:UpdateWindowShow()
	
end

return PlayerLiuPaiSkillWidget