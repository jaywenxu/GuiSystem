--/******************************************************************
--** 文件名:	LifeSkillWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	何水大(765865368@qq.com)
--** 日  期:	2017-10-31
--** 版  本:	1.0
--** 描  述:	玩家生活技能窗口
--** 应  用:  
--******************************************************************/

local LifeSkillListWidget = require("GuiSystem.WindowList.PlayerSkill.LifeSkillListWidget")

local FishingWidget = require("GuiSystem.WindowList.PlayerSkill.FishingWidget")
local MiningWidget = require("GuiSystem.WindowList.PlayerSkill.MiningWidget")
local TameWidget = require("GuiSystem.WindowList.PlayerSkill.TameWidget")
local CookWidget = require("GuiSystem.WindowList.PlayerSkill.CookWidget")
local LuckWidget = require("GuiSystem.WindowList.PlayerSkill.LuckWidget")
local BusinessWidget = require("GuiSystem.WindowList.PlayerSkill.BusinessWidget")

local LifeSkillWidget = UIControl:new
{
	windowName = "LifeSkillWidget",
	
	m_ArrSubscribeEvent = {},		-- 绑定的事件集合:table(string, function())
		
	m_LifeSkillListWidget = nil, -- 生活技能列表脚本
	
	m_LifeSkillWidget = {}, -- 生活技能子窗口
	m_LifeSkillUI = {}, -- 生活技能子窗口UI
	m_LifeSkillScripts = {}, -- 生活技能子窗口脚本
	m_CurrentSkillID = nil, -- 当前选中的技能
}

function LifeSkillWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	
	self.m_LifeSkillListWidget = LifeSkillListWidget:new()
	self.m_LifeSkillListWidget:Attach(self.Controls.m_LifeSkillListWidget.gameObject)
	
	for i = emFishing + 1, emLifeSkillsMax do
		self.m_LifeSkillWidget[i] = nil
	end
	
	self.m_LifeSkillScripts[emFishing + 1] = FishingWidget:new()
	self.m_LifeSkillScripts[emMining + 1] = MiningWidget:new()
	self.m_LifeSkillScripts[emTame + 1] = TameWidget:new()
	self.m_LifeSkillScripts[emCook + 1] = CookWidget:new()
	self.m_LifeSkillScripts[emLuck + 1] = LuckWidget:new()
	self.m_LifeSkillScripts[emBusiness + 1] = BusinessWidget:new()
	
	self.m_LifeSkillUI[emFishing + 1] = self.Controls.m_FishingWidget.gameObject
	self.m_LifeSkillUI[emMining + 1] = self.Controls.m_MiningWidget.gameObject
	self.m_LifeSkillUI[emTame + 1] = self.Controls.m_TameWidget.gameObject
	self.m_LifeSkillUI[emCook + 1] = self.Controls.m_CookWidget.gameObject
	self.m_LifeSkillUI[emLuck + 1] = self.Controls.m_LuckWidget.gameObject
	self.m_LifeSkillUI[emBusiness + 1] = self.Controls.m_BusinessWidget.gameObject
	
	-- 事件绑定
	self:SubscribeEvent()
	
	local hero = GetHero() 
    if not hero then 
        return 
    end
    
	local skillPart = hero:GetEntityPart(ENTITYPART_PERSON_LIFESKILL)
    if not skillPart then
        return
    end
	
	local lifeSkillInfo = skillPart:GetLifeSkillInfo()
	if not lifeSkillInfo then
		return
	end
	
	self.m_lifeSkillInfo = lifeSkillInfo
end

-- 窗口销毁
function LifeSkillWidget:OnDestroy()
    -- 移除事件的绑定
    self:UnSubscribeEvent()
	
	self.m_ArrSubscribeEvent = {}
		
	self.m_LifeSkillListWidget = nil
	
	self.m_LifeSkillWidget = {}
	self.m_LifeSkillUI = {}
	self.m_LifeSkillScripts = {}
	self.m_CurrentSkillID = nil
	
    UIControl.OnDestroy(self)
end


-- 事件绑定
function LifeSkillWidget:SubscribeEvent()
	
	self.m_ArrSubscribeEvent = 
	{
		{
			e = ENTITYPART_PERSON_LIFESKILL, s = SOURCE_TYPE_SYSTEM, i = SKILL_UI_EVENT_LIFESKILL_ITEM_CLICK,
			f = function(event, srctype, srcid, skillId) self:HandleUI_LifeSkillItemClick(skillId) end,
		},
		
		{
			e = ENTITYPART_PERSON_LIFESKILL, s = SOURCE_TYPE_SYSTEM, i = SKILL_UI_EVENT_LIFESKILL_UPGRADE,
			f = function(event, srctype, srcid, skillId) self:HandleUI_LifeSkillUpgrade(skillId) end,
		},
	}
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.SubscribeExecute(v.e, v.s, v.i, v.f)
	end
	
end

-- 移除事件的绑定
function LifeSkillWidget:UnSubscribeEvent()
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.UnSubscribeExecute(v.e, v.s, v.i, v.f)
	end
	
end

-- 显示窗口
function LifeSkillWidget:ShowWindow()
	
	UIControl.Show(self)
	
	local skillID = self.m_lifeSkillInfo[1].nID
	self.m_LifeSkillListWidget:OnWidgetShow(self.m_lifeSkillInfo[1].nID)
	self:HandleUI_LifeSkillItemClick(skillID)
end

-- 隐藏窗口
function LifeSkillWidget:HideWindow()
	
	UIControl.Hide(self, false)
	
end

-- 生活技能列表点击事件处理
-- @skillId:生活技能id:number
function LifeSkillWidget:HandleUI_LifeSkillItemClick(skillId)
	if self.m_CurrentSkillID == skillId then
		return
	end
	self.m_CurrentSkillID = skillId
	-- 更新窗口
	self.m_LifeSkillListWidget:UpdateWidget(skillId)
	local index = skillId + 1
	if not self.m_LifeSkillWidget[index] then
		self.m_LifeSkillWidget[index] = self.m_LifeSkillScripts[index]
		self.m_LifeSkillWidget[index]:Attach(self.m_LifeSkillUI[index])
	end
	
	for k, v in pairs(self.m_LifeSkillWidget) do
		if k == index then
			v:Show()
		else
			if v then
				v:Hide()
			end
		end
	end
end

-- 生活技能升级事件处理
-- @skillId:生活技能id:number
function LifeSkillWidget:HandleUI_LifeSkillUpgrade(skillId)
	
	self.m_LifeSkillListWidget:UpdateSkillItemShow()
	local index = skillId + 1
	
	for k, v in pairs(self.m_LifeSkillWidget) do
		if k == index then
			v:UpdateWidget()
			v:Show()
		else
			if v then
				v:Hide()
			end
		end
	end
end

return LifeSkillWidget