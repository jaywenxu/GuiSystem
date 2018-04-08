--/******************************************************************
---** 文件名:	LifeSkillListWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	何水大(765865368@qq.com)
--** 日  期:	2017-11-01
--** 版  本:	1.0
--** 描  述:	玩家生活技能列表
--** 应  用:  
--******************************************************************/

local LifeSkillItem = require("GuiSystem.WindowList.PlayerSkill.LifeSkillItem")

local LifeSkillListWidget = UIControl:new
{
	windowName = "LifeSkillListWidget",
	m_lifeSkillInfo = {},

	m_CurSelectedSkillId = 0,			-- 当前选中的技能ID
	m_firstShow = true, -- 初次显示
}

function LifeSkillListWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	
	self.m_firstShow = true
	
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
	local controls = self.Controls
	
	self.Group = controls.m_LifeSkillListScroller:GetComponent(typeof(ToggleGroup))
	--绑定EnhanceScroller事件
	self.DragListView  = controls.m_LifeSkillListScroller:GetComponent(typeof(EnhancedListView))
	self.callBackOnGetCellView = function(objCell) self:OnGetCellView(objCell) end
	self.enhanceListView = controls.m_LifeSkillListScroller:GetComponent(typeof(EnhancedListView))
	self.callBackTargetTeamCellVis = function(objCell) self:OnGetSkillItemVisiable(objCell) end
	self.enhanceScroller = controls.m_LifeSkillListScroller:GetComponent(typeof(EnhancedScroller))
	if self.enhanceListView ~= nil then 
		self.enhanceListView.onGetCellView:AddListener(self.callBackOnGetCellView)
		self.enhanceListView.onCellViewVisiable:AddListener(self.callBackTargetTeamCellVis)
	end
end

--EnhancedListView 创建实体回调
function LifeSkillListWidget:OnGetCellView(objCell)
	local item = LifeSkillItem:new()
	local enhancedCell = objCell:GetComponent(typeof(EnhancedListViewCell))
	enhancedCell.onRefreshCellView = handler(self, self.OnGetSkillItemVisiable)
	item:SetGroup(self.Group)
	item:Attach(objCell)
end

--EnhancedListView 创建实体可见
function LifeSkillListWidget:OnGetSkillItemVisiable(objCell)
	local viewCell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))
	local behav = objCell:GetComponent(typeof(UIWindowBehaviour))
	if nil ~= behav then
		local defaultIndex = IGame.LifeSkillClient:GetDefaultSkillID()
		local item = behav.LuaObject
		local schemeId =self.m_lifeSkillInfo[viewCell.cellIndex+1].nID
		item:UpdateItem(schemeId)
		if self.m_firstShow then
			if viewCell.dataIndex == defaultIndex then
				item:SetFocus(true)
				IGame.LifeSkillClient:SetDefaultSkillID(0)
				self.m_firstShow = false
			end
		else
			item:SetFocus(self.m_CurSelectedSkillId == schemeId)
		end
	end	
end

-- 窗口每次打开时被调用的行为
-- @skillId:当前选中的技能id:number
function LifeSkillListWidget:OnWidgetShow(skillId)
	-- 更新窗口
	self:UpdateWidget(skillId)
end

-- 更新窗口
-- @skillId:当前选中的技能id:number
function LifeSkillListWidget:UpdateWidget(skillId)
	
	self.m_CurSelectedSkillId = skillId

	-- 更新技能图标的显示
	self:UpdateSkillItemShow()
	
end

-- 更新技能图标的显示
function LifeSkillListWidget:UpdateSkillItemShow()

	local count =-1
	count = self.DragListView.CellCount
	if #self.m_lifeSkillInfo ~= count then 
		self.enhanceListView:SetCellCount( #self.m_lifeSkillInfo , true )	
	else
		self.enhanceScroller:RefreshActiveCellViews()
	end

end

function LifeSkillListWidget:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function LifeSkillListWidget:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function LifeSkillListWidget:CleanData()
	
end

return LifeSkillListWidget