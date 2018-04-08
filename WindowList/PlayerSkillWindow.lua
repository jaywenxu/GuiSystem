--/******************************************************************
---** 文件名:	PlayerSkillWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-03
--** 版  本:	1.0
--** 描  述:	玩家技能窗口
--** 应  用:  
--******************************************************************/

require("GuiSystem.WindowList.PlayerSkill.PlayerSkillWindowDefine")
require("GuiSystem.WindowList.PlayerSkill.PlayerSkillWindowTool")
require("GuiSystem.WindowList.Exchange.ExchangeWindowTool")

local PlayerSkillWindow = UIWindow:new
{
	windowName = "PlayerSkillWindow",	-- 窗口名称
	
	m_CurSelectedTab = 0,				-- 当前选择的页签类型:PlayerSkillRightTabType(string)
	m_IsTimerOpen = false,				-- 定时器是否在开启的标识:boolean
	m_TimerReqZhenQi = nil,				-- 请求真气的定时器行为:function
	m_OnWindowShowFunc = nil,			-- 外部自定义的当界面显示后执行的行为:function

	m_ArrSubscribeEvent = {},		-- 绑定的事件集合:table(string, function())
	
	-- 各子窗口实例:table(GameObject)
	m_ArrGoChildWindow = 
	{
		TAB_TYPE_SHENGJI = 0, 
		TAB_TYPE_LIUPAI = 0, 
		TAB_TYPE_WUXUE = 0, 
		TAB_TYPE_LIFESKILL = 0, 
	},	
	
	-- 各子窗口脚本:table(UIControl)							
	m_ArrChildWindow = 
	{
		TAB_TYPE_SHENGJI = 0, 
		TAB_TYPE_LIUPAI = 0, 
		TAB_TYPE_WUXUE = 0, 
		TAB_TYPE_LIFESKILL = 0, 
	},									-- 各子窗口脚本:table(UIControl)
}

local NO_INST_CHILD_WINDOW_GO_VALUE = 0												-- 没有实例化时的对象数值
local TITLE_IMG_PATH = AssetPath.TextureGUIPath.."Skills/Skills_jineng.png"	        -- 窗口标题资源路径

function PlayerSkillWindow:Init()
	
	self.m_IsTimerOpen = false
	self.m_TimerReqZhenQi = function() self:TimerReqZhenQi() end
	
	self.m_ArrChildWindow[PlayerSkillRightTabType.TAB_TYPE_SHENGJI] = require("GuiSystem.WindowList.PlayerSkill.PlayerSkillUpgradeWidget")
	self.m_ArrChildWindow[PlayerSkillRightTabType.TAB_TYPE_LIUPAI] = require("GuiSystem.WindowList.PlayerSkill.PlayerLiuPaiSkillWidget")
	self.m_ArrChildWindow[PlayerSkillRightTabType.TAB_TYPE_WUXUE] = require("GuiSystem.WindowList.PlayerSkill.PlayerWuXueSkillWidget")
	self.m_ArrChildWindow[PlayerSkillRightTabType.TAB_TYPE_LIFESKILL] = require("GuiSystem.WindowList.PlayerSkill.LifeSkillWidget")

end	

function PlayerSkillWindow:OnAttach( obj )
	
	UIWindow.OnAttach(self, obj)

	-- 通用顶部菜单的返回点击
	UIWindow.AddCommonWindowToThisWindow(self, true, TITLE_IMG_PATH,
		function()
			self:OnBackBtnClick() 
		end,nil,function() self:SetFullScreen() end
	)


	-- 初始化右边页签的点击行为
	self:InitRightTabClickAction()
	-- 事件绑定
	self:SubscribeEvent()
	
	if self.needUpdate then
		self.needUpdate = false
		self:OnWindowShow()
	end
		
	return self
end


function PlayerSkillWindow:_showWindow()
	
	UIWindow._showWindow(self)

	if self:isLoaded() then
		self:OnWindowShow()
	else
		self.needUpdate = true
	end
	
end

-- 显示窗口
-- @tabType:页签类型:PlayerSkillRightTabType
function PlayerSkillWindow:ShowWindow(tabType)
	
	self.m_CurSelectedTab = tabType
	
	-- 请求真气
	self:TimerReqZhenQi()
	-- 开启定时器
	self:OpenTimer()
	
	UIWindow.Show(self, true)
	
end


-- 隐藏窗体
function PlayerSkillWindow:Hide( destory )
    
	-- 销毁定时器
	self:KillTimer()
	
	UIWindow.Hide(self, destory)
	
end

-- 窗口销毁
function PlayerSkillWindow:OnDestroy()	
	
    -- 移除事件的绑定
    self:UnSubscribeEvent()
	-- 销毁定时器
	self:KillTimer()
	self.m_ArrGoChildWindow = 
	{
		TAB_TYPE_SHENGJI = 0, 
		TAB_TYPE_LIUPAI = 0, 
		TAB_TYPE_WUXUE = 0, 
		TAB_TYPE_LIFESKILL = 0, 
	},	
    UIWindow.OnDestroy(self)
	
end

-- 开启定时器
function PlayerSkillWindow:OpenTimer()
	
	if self.m_IsTimerOpen then
		return
	end
	
	self.m_IsTimerOpen = true
	rktTimer.SetTimer(self.m_TimerReqZhenQi, ZHEN_QI_ADD_PERIOD * 1000, -1, "PlayerSkillWindow:ReqZhenQi")
	
end

-- 销毁定时器
function PlayerSkillWindow:KillTimer()
	
	if not self.m_IsTimerOpen then
		return
	end
	
	self.m_IsTimerOpen = false
	rktTimer.KillTimer( self.m_TimerReqZhenQi )

end

-- 事件绑定
function PlayerSkillWindow:SubscribeEvent()
	
	self.m_ArrSubscribeEvent = 
	{
		{
			e = ENTITYPART_CREATURE_SKILL, s = SOURCE_TYPE_SYSTEM, i = SKILL_UI_EVENT_UPGRADE_WUXUE_CLITK,
			f = function(event, srctype, srcid, wuXueId) self:HandleUI_UpgradeWuXueClick(wuXueId) end,
		},
	}
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.SubscribeExecute(v.e, v.s, v.i, v.f)
	end
	
end

-- 移除事件的绑定
function PlayerSkillWindow:UnSubscribeEvent()
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.UnSubscribeExecute(v.e, v.s, v.i, v.f)
	end
	
end


-- 窗口每次打开执行的行为
function PlayerSkillWindow:OnWindowShow()

	-- 变更子窗口
	self:ChangeChildWindow(self.m_CurSelectedTab)
	
	if self.m_OnWindowShowFunc ~= nil then
		self.m_OnWindowShowFunc()
		self.m_OnWindowShowFunc = nil
	end
	
end

-- 设置当界面打开后执行的行为
-- @onWindowShowFunc:当界面打开后调用的行为:boolean
function PlayerSkillWindow:SetCustomOnWindowShowFunc(onWindowShowFunc)
	
	self.m_OnWindowShowFunc = onWindowShowFunc
	
end

-- 变更升级窗口的技能选中
-- @skillId:要选中的技能id:number
function PlayerSkillWindow:ChangeTheUpgradeWindowSkillSelected(skillId)
	
	self.m_ArrChildWindow[PlayerSkillRightTabType.TAB_TYPE_SHENGJI]:ChangeTheSelectedSkill(skillId)
	
end

-- 初始化右边页签的点击行为
function PlayerSkillWindow:InitRightTabClickAction()

	self.Controls.m_ButtonShengJi.onClick:AddListener(function(on) self:OnRightTabClick(PlayerSkillRightTabType.TAB_TYPE_SHENGJI) end)
	self.Controls.m_ButtonLiuPai.onClick:AddListener(function(on) self:OnRightTabClick(PlayerSkillRightTabType.TAB_TYPE_LIUPAI) end)
	self.Controls.m_ButtonWuXue.onClick:AddListener(function(on) self:OnRightTabClick(PlayerSkillRightTabType.TAB_TYPE_WUXUE) end)
	self.Controls.m_ButtonLifeSkill.onClick:AddListener(function(on) self:OnRightTabClick(PlayerSkillRightTabType.TAB_TYPE_LIFESKILL) end)
end

-- 变更子窗口
-- @childTab:要显示的子窗口的页签类型:PlayerSkillRightTabType(string)
-- @onChildWindowShow:子界面成功打开后的回调:function
function PlayerSkillWindow:ChangeChildWindow(childTab, onChildWindowShow)
	
	self.m_CurSelectedTab = childTab
	
	-- 先判断子窗口是否创建了，如果没有创建的就动态创建出来
	-- 如果子窗口已经创建了，就更新子界面
	if(self.m_ArrGoChildWindow[childTab] == NO_INST_CHILD_WINDOW_GO_VALUE) then
		-- 创建子窗口
		self:CreateChildWindow(childTab, onChildWindowShow)
	else
		for k,v in pairs(self.m_ArrGoChildWindow) do
			if(v ~= NO_INST_CHILD_WINDOW_GO_VALUE) then
				if(k == childTab) then
					self.m_ArrChildWindow[k]:ShowWindow()
					
					if onChildWindowShow then
						onChildWindowShow()
					end
				else 
					self.m_ArrChildWindow[k]:HideWindow()
				end
			end
		end
	end
	
	-- 更新页签选中的显示
	self:UpdateTheTabSelectedShow()
		
end

-- 更新页签选中的显示
function PlayerSkillWindow:UpdateTheTabSelectedShow()
	
	PlayerSkillWindowTool.SetTabSelectedState(self.Controls.m_ButtonShengJi, self.m_CurSelectedTab == PlayerSkillRightTabType.TAB_TYPE_SHENGJI)
	PlayerSkillWindowTool.SetTabSelectedState(self.Controls.m_ButtonLiuPai, self.m_CurSelectedTab == PlayerSkillRightTabType.TAB_TYPE_LIUPAI)
	PlayerSkillWindowTool.SetTabSelectedState(self.Controls.m_ButtonWuXue, self.m_CurSelectedTab == PlayerSkillRightTabType.TAB_TYPE_WUXUE)
	PlayerSkillWindowTool.SetTabSelectedState(self.Controls.m_ButtonLifeSkill, self.m_CurSelectedTab == PlayerSkillRightTabType.TAB_TYPE_LIFESKILL)
end

-- 请求真气
function PlayerSkillWindow:TimerReqZhenQi()
	
	local studyPart = GetHeroEntityPart(ENTITYPART_PERSON_STUDYSKILL)
	if not studyPart then
		return
	end
	
	studyPart:RequestZhenQi()
	
end


-- 创建子窗口
-- @childTab:子窗口的页签类型:PlayerSkillRightTabType(string) 
-- @onChildWindowShow:子界面成功打开后的回调:function
function PlayerSkillWindow:CreateChildWindow(childTab, onChildWindowShow)
	
	-- 子窗口预制体路径判断
	local prefabPath = nil 
	if childTab == PlayerSkillRightTabType.TAB_TYPE_SHENGJI then
		prefabPath = GuiAssetList.PlayerSkill.PlayerSkillUpgradeWidget
	elseif childTab == PlayerSkillRightTabType.TAB_TYPE_LIUPAI then
		prefabPath = GuiAssetList.PlayerSkill.PlayerLiuPaiSkillWidget
	elseif childTab == PlayerSkillRightTabType.TAB_TYPE_WUXUE then
		prefabPath = GuiAssetList.PlayerSkill.PlayerWuXueSkillWidget
	elseif childTab == PlayerSkillRightTabType.TAB_TYPE_LIFESKILL then
		prefabPath = GuiAssetList.LifeSkills.PlayerLifeSkillWidget
	else 
		prefabPath = GuiAssetList.PlayerSkill.PlayerOtherSkillWidget
	end
	
	rkt.GResources.FetchGameObjectAsync( prefabPath ,
		function ( path , obj , ud )

			self.m_ArrGoChildWindow[childTab] = obj
			obj.transform:SetParent(self.Controls.m_ChildWindowNode.transform, false)
			self.m_ArrChildWindow[childTab]:Attach(obj)
			
			-- 变更子窗口
			self:ChangeChildWindow(childTab, onChildWindowShow)
			
		end, nil , AssetLoadPriority.GuiNormal)
end

-- 技能升级界面武学图标点击处理
-- @wuXueId:选中的武学id:number
function PlayerSkillWindow:HandleUI_UpgradeWuXueClick(wuXueId)
	
	local onChildWindowShow = function() 
		self.m_ArrChildWindow[PlayerSkillRightTabType.TAB_TYPE_WUXUE]:ChangeSelectedWuXue(wuXueId)
	end
	
	-- 变更子窗口
	self:ChangeChildWindow(PlayerSkillRightTabType.TAB_TYPE_WUXUE, onChildWindowShow)
	
end

-- 返回按钮点击的行为
function PlayerSkillWindow:OnBackBtnClick()
	UIManager.PlayerSkillWindow:Hide()
end

-- 右边页签按钮点击行为
-- @childTab:页签的类型:PlayerSkillRightTabType(string) 
function PlayerSkillWindow:OnRightTabClick(childTab)
	
	-- 相同标签或在隐藏的不用响应
	if self.m_CurSelectedTab == childTab then 
		return
	end
	
	-- 变更子窗口
	self:ChangeChildWindow(childTab)
	
end

return PlayerSkillWindow