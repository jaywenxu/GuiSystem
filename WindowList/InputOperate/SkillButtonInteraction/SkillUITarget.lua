--/******************************************************************
---** 文件名:	SkillUITarget.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	haowei
--** 日  期:	2017-08-30
--** 版  本:	1.0
--** 描  述:	施法目标
--** 应  用:  
--******************************************************************/

local HeadIconClass = require("GuiSystem.WindowList.InputOperate.SkillButtonInteraction.HeadIcon")

local SkillUITarget = UIControl:new
{
	windowName = "SkillUITarget",
}

function SkillUITarget:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.HeadIcon1 = HeadIconClass:new()
	self.HeadIcon2 = HeadIconClass:new()
	self.HeadIcon3 = HeadIconClass:new()
	self.HeadIcon1:Attach(self.Controls.m_HeadIcon1.gameObject)
	self.HeadIcon2:Attach(self.Controls.m_HeadIcon2.gameObject)
	self.HeadIcon3:Attach(self.Controls.m_HeadIcon3.gameObject)
	
	self.HeadIconCache = {
		self.HeadIcon1,
		self.HeadIcon2,
		self.HeadIcon3,
	}
	
	return self
end

---------------------------------------设置view显示相关-----------------------------------
--设置显示headIcon
function SkillUITarget:SetHeadIconShow(index, show, faceID)
	if show then
		self.HeadIconCache[index]:Show()
		self.HeadIconCache[index]:SetHeadIcon(faceID)
	else
		self.HeadIconCache[index]:Hide()
	end
end

--设置血量
function SkillUITarget:SetHp(index, percent, showWarning)
	self.HeadIconCache[index]:SetHP(percent, showWarning)
end

--设置是否是队长
function SkillUITarget:SetCaptain(index, isCaptain)
	self.HeadIconCache[index]:SetCaptain(isCaptain)
end

--设置选中状态
function SkillUITarget:SetSelected(index, selected)
	self.HeadIconCache[index]:SetSelect(selected)
end

-------------------------------------------------------------------------------------------
--订阅鼠标移入事件
function SkillUITarget:SetPointEnterCB(enter_callback)
	if not enter_callback then return end
	for i, data in pairs(self.HeadIconCache) do
		data:SetPointEnterCB(enter_callback)
	end
end

--订阅鼠标移出事件
function SkillUITarget:SetPointExitCB(exit_callback)
	if not exit_callback then return end
	for i, data in pairs(self.HeadIconCache) do
		data:SetPointExitCB(exit_callback)
	end
end

--移除所有控件订阅事件
function SkillUITarget:ClearAllListeners()
	for i, data in pairs(self.HeadIconCache) do
		data:RemoveAllListener()
	end
	UIControl.ClearAllListeners(self)
end

return SkillUITarget