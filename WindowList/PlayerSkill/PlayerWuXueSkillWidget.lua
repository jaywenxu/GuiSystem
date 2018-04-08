--/******************************************************************
--** 文件名:	PlayerWuXueSkillWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-03
--** 版  本:	1.0
--** 描  述:	玩家技能窗口的-武学窗口
--** 应  用:  
--******************************************************************/

local WuXueVerDragWidget = require("GuiSystem.WindowList.PlayerSkill.WuXueVerDragWidget")
local WuXueControlWidget = require("GuiSystem.WindowList.PlayerSkill.WuXueControlWidget")

local PlayerWuXueSkillWidget = UIControl:new
{
	windowName = "PlayerWuXueSkillWidget",
	
	m_CurSelectedWuXueId = 0,		-- 当前选中的武学id:number
	m_CurSelectedMiJiId = 0,		-- 当前选中的秘籍id:number
	m_NeedLocateWuXueItem = false,	-- 是否需要定位武学图标的标识:boolean
	
	m_WuXueDisplayWidget = nil,		-- 武学的展示窗口的脚本:WuXueVerDragWidget
	m_WuXueControlWidget = nil,		-- 武学的操作窗口的脚本:WuXueControlWidget
	
	m_ArrSubscribeEvent = {},		-- 绑定的事件集合:table(string, function())
}

function PlayerWuXueSkillWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	
	self.m_WuXueDisplayWidget = WuXueVerDragWidget:new()
	self.m_WuXueControlWidget = WuXueControlWidget:new()
	self.m_WuXueDisplayWidget:Attach(self.Controls.m_TfWuXueDisplayWidget.gameObject)
	self.m_WuXueControlWidget:Attach(self.Controls.m_TfWuXueControlWidget.gameObject)
	-- 事件绑定
	self:SubscribeEvent()
	
end

-- 窗口销毁
function PlayerWuXueSkillWidget:OnDestroy()
	
    -- 移除事件的绑定
    self:UnSubscribeEvent()
    UIWindow.OnDestroy(self)
	
end


-- 事件绑定
function PlayerWuXueSkillWidget:SubscribeEvent()
	
	self.m_ArrSubscribeEvent = 
	{
		{
			e = ENTITYPART_CREATURE_SKILL, s = SOURCE_TYPE_SYSTEM, i = SKILL_NET_EVENT_ON_QUERY_ZHEN_QI,
			f = function(event, srctype, srcid) self:HandleNet_PlayerZhenQiRes() end,
		},
		
		{
			e = ENTITYPART_CREATURE_SKILL, s = SOURCE_TYPE_SYSTEM, i = SKILL_NET_EVENT_ON_UPGRADE_SLOT,
			f = function(event, srctype, srcid) self:HandleNet_OnUpgradeSlot() end,
		},
		
		{
			e = ENTITYPART_CREATURE_SKILL, s = SOURCE_TYPE_SYSTEM, i = SKILL_NET_EVENT_ON_UPGRADE_WUXUE,
			f = function(event, srctype, srcid) self:HandleNet_OnUpgradeWuXue() end,
		},
		
		{
			e = ENTITYPART_CREATURE_SKILL, s = SOURCE_TYPE_SYSTEM, i = SKILL_UI_EVENT_WUXUE_MIJI_ITEM_CLICK,
			f = function(event, srctype, srcid, miJiId) self:HandleUI_WuXueMiJiItemClick(miJiId) end,
		},
		
		{
			e = ENTITYPART_CREATURE_SKILL, s = SOURCE_TYPE_SYSTEM, i = SKILL_UI_EVENT_WUXUE_BOOK_ITEM_CLICK,
			f = function(event, srctype, srcid, bookId) self:HandleUI_WuXueBookItemClick(bookId) end,
		},
		
		{
			e = EVENT_SKEP_ADD_GOODS, s = SOURCE_TYPE_SKEP, i = 0,
			f = function(event, srctype, srcid) self:HandleBroadcast_PacketItemAdd() end,
		},
		
		{
			e = EVENT_SKEP_REMOVE_GOODS, s = SOURCE_TYPE_SKEP, i = 0,
			f = function(event, srctype, srcid) self:HandleBroadcast_PacketItemRmv() end,
		},
		
		{
			e = EVENT_HAVE_BATTLE_BOOK_DATA_CHANGE, s = SOURCE_TYPE_SKEP, i = 0,
			f = function(event, srctype, srcid) self:HandleNet_HaveBattleBookDataChange() end,
		},
	}
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.SubscribeExecute(v.e, v.s, v.i, v.f)
	end
	
end

-- 移除事件的绑定
function PlayerWuXueSkillWidget:UnSubscribeEvent()
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.UnSubscribeExecute(v.e, v.s, v.i, v.f)
	end
	
end

-- 显示窗口
function PlayerWuXueSkillWidget:ShowWindow()
	
	UIControl.Show(self)
	
	-- 初始化默认选中的武学和秘籍
	self:InitTheDefaultSelectedWuXueAndMiJi()
	
	self.m_WuXueDisplayWidget:OnWidgetShow(self.m_CurSelectedWuXueId, self.m_CurSelectedMiJiId)
	self.m_WuXueControlWidget:OnWidgetShow(self.m_CurSelectedWuXueId, self.m_CurSelectedMiJiId)
	
end

-- 更新窗口
function PlayerWuXueSkillWidget:UpdateWidget()
	
	self.m_WuXueDisplayWidget:UpdateWidget(self.m_CurSelectedWuXueId, self.m_CurSelectedMiJiId, self.m_NeedLocateWuXueItem)
	self.m_WuXueControlWidget:UpdateWidget(self.m_CurSelectedWuXueId, self.m_CurSelectedMiJiId)
	
end

function PlayerWuXueSkillWidget:UpdareControlWidget()
	self.m_WuXueControlWidget:UpdateWidget(self.m_CurSelectedWuXueId, self.m_CurSelectedMiJiId)
end

-- 变更选中的武学
-- @wuXueId:武学id:number
function PlayerWuXueSkillWidget:ChangeSelectedWuXue(wuXueId)
	
	self.m_CurSelectedWuXueId = wuXueId
	self.m_CurSelectedMiJiId = 0
	self.m_NeedLocateWuXueItem = true
	
	-- 更新窗口
	self:UpdateWidget()
	self.m_NeedLocateWuXueItem = false
	
end

-- 初始化默认选中的武学和秘籍
function PlayerWuXueSkillWidget:InitTheDefaultSelectedWuXueAndMiJi()
	
	local listAllWuXueScheme = IGame.rktScheme:GetSchemeTable(BATTLEBOOK_ACTIVATION_CSV)
	if not listAllWuXueScheme then
		uerror("没有找到武学解锁配置表!")
		return
	end
	
	-- 排序
	local tableSort = {}
	for k,v in pairs(listAllWuXueScheme) do
		table.insert(tableSort, v.ID)
	end
	
	table.sort(tableSort)
	
	for schemeIdx = 1, #tableSort do
		local schemeId = tableSort[schemeIdx]
		local scheme = IGame.rktScheme:GetSchemeInfo(BATTLEBOOK_ACTIVATION_CSV, schemeId)
		if scheme then
			self.m_CurSelectedWuXueId = scheme.ID
			self.m_CurSelectedMiJiId = 0 --v.Slot1ID
			break
		end
	end
	
end


-- 背包添加新物品事件广播处理
function PlayerWuXueSkillWidget:HandleBroadcast_PacketItemAdd()
	
	if not self.transform.gameObject.activeInHierarchy then
		return
	end
	
	self.m_WuXueDisplayWidget:UpdateWidget(self.m_CurSelectedWuXueId, self.m_CurSelectedMiJiId)
	self.m_WuXueControlWidget:UpdateWidget(self.m_CurSelectedWuXueId, self.m_CurSelectedMiJiId)
	
end

-- 背包移除物品事件广播处理
function PlayerWuXueSkillWidget:HandleBroadcast_PacketItemRmv()
	
	if not self.transform.gameObject.activeInHierarchy then
		return
	end
	
	self.m_WuXueDisplayWidget:UpdateWidget(self.m_CurSelectedWuXueId, self.m_CurSelectedMiJiId)
	self.m_WuXueControlWidget:UpdateWidget(self.m_CurSelectedWuXueId, self.m_CurSelectedMiJiId)
	
end

-- 隐藏窗口
function PlayerWuXueSkillWidget:HideWindow()
	
	UIControl.Hide(self, false)
	
end


-- 收到真气查询回包处理
function PlayerWuXueSkillWidget:HandleNet_PlayerZhenQiRes()

	self.m_WuXueControlWidget:HandleNet_PlayerZhenQiRes()
	
end

-- 收到升级秘籍回包处理
function PlayerWuXueSkillWidget:HandleNet_OnUpgradeSlot()

	-- 更新窗口
	self:UpdateWidget()
	
end

-- 收到升级武学回包处理
function PlayerWuXueSkillWidget:HandleNet_OnUpgradeWuXue()

	-- 更新窗口
	self:UpdateWidget()
	
end

-- 武学界面秘籍图标点击处理
-- @miJiId:秘籍id:number
function PlayerWuXueSkillWidget:HandleUI_WuXueMiJiItemClick(miJiId)
	
	self.m_CurSelectedMiJiId = miJiId
	
	-- 更新窗口
	self:UpdateWidget()
	
end


-- 武学界面武学书点击处理
-- @bookId:武学书id:number
function PlayerWuXueSkillWidget:HandleUI_WuXueBookItemClick(bookId)

	self.m_CurSelectedWuXueId = bookId
	self.m_CurSelectedMiJiId = 0
	
	--[[local actScheme = IGame.rktScheme:GetShemeInfo(BATTLEBOOK_ACTIVATION_CSV, self.m_CurSelectedWuXueId)
	if not actScheme then
		return
	end
	
	self.m_CurSelectedMiJiId = actScheme.Slot1ID--]]
	
	-- 更新窗口
	self:UpdateWidget()
	
end

return PlayerWuXueSkillWidget