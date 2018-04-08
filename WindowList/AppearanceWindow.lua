--*******************************************************************
--** 文件名:	AppearanceWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	何水大(765865368@qq.com)
--** 日  期:	2017-12-08
--** 版  本:	1.0
--** 描  述:	外观窗口
--** 应  用:  
--*******************************************************************

-- 右边功能页签类型
local AppearanceRightTabType = 
{
	TAB_TYPE_DRESS = "TAB_TYPE_DRESS",			-- 时装
	TAB_TYPE_RIDE = "TAB_TYPE_RIDE",				-- 坐骑
}


local AppearanceWindow = UIWindow:new
{
	windowName = "AppearanceWindow",	-- 窗口名称
	
	m_CurSelectedTab = 0,				-- 当前选择的页签类型:AppearanceRightTabType(string)
	m_OnWindowShowFunc = nil,			-- 外部自定义的当界面显示后执行的行为:function

	m_ArrSubscribeEvent = {},			-- 绑定的事件集合:table(string, function())
	
	-- 各子窗口实例:table(GameObject)
	m_ArrGoChildWindow = 
	{
		TAB_TYPE_DRESS = 0, 
		TAB_TYPE_RIDE = 0, 
	},	
	
	-- 各子窗口脚本:table(UIControl)							
	m_ArrChildWindow = 
	{
		TAB_TYPE_DRESS = 0, 
		TAB_TYPE_RIDE = 0, 
	},
}

local NO_INST_CHILD_WINDOW_GO_VALUE = 0												-- 没有实例化时的对象数值
local TITLE_IMG_PATH = AssetPath.TextureGUIPath.."Store/Shop_waiguan.png"	        -- 窗口标题资源路径

function AppearanceWindow:Init()
	self.m_ArrChildWindow[AppearanceRightTabType.TAB_TYPE_DRESS] = require("GuiSystem.WindowList.Appearance.Dress.DressWidget")
	self.m_ArrChildWindow[AppearanceRightTabType.TAB_TYPE_RIDE] = require("GuiSystem.WindowList.Appearance.Ride.RideWidget")
end	

function AppearanceWindow:OnAttach( obj )
	
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


function AppearanceWindow:_showWindow()
	
	UIWindow._showWindow(self)

	if self:isLoaded() then
		self:OnWindowShow()
	else
		self.needUpdate = true
	end
	
end

-- 显示窗口
-- @tabType:页签类型:AppearanceRightTabType
function AppearanceWindow:ShowWindow(tabType)
	
	self.m_CurSelectedTab = tabType
	
	UIWindow.Show(self, true)
	
end


-- 隐藏窗体
function AppearanceWindow:Hide( destory )
    
	-- 销毁定时器
	UIWindow.Hide(self, destory)
	
end

-- 窗口销毁
function AppearanceWindow:OnDestroy()	
	
    -- 移除事件的绑定
    self:UnSubscribeEvent()

	self.m_ArrGoChildWindow = 
	{
		TAB_TYPE_DRESS = 0, 
		TAB_TYPE_RIDE = 0, 
	},	
    UIWindow.OnDestroy(self)
	
end

-- 事件绑定
function AppearanceWindow:SubscribeEvent()
	
	self.m_ArrSubscribeEvent = 
	{
		--[[{
			e = ENTITYPART_CREATURE_SKILL, s = SOURCE_TYPE_SYSTEM, i = SKILL_UI_EVENT_UPGRADE_WUXUE_CLITK,
			f = function(event, srctype, srcid, wuXueId) self:HandleUI_UpgradeWuXueClick(wuXueId) end,
		},--]]
	}
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.SubscribeExecute(v.e, v.s, v.i, v.f)
	end
	
	self.ShowOrHideBGCB = function(_,_,_,on) self:OnShowOrHideDressWid(on) end
	rktEventEngine.SubscribeExecute(EVENT_APPEARANCE_SHOWORHIDEDRESS,0,0,self.ShowOrHideBGCB)
	
end

-- 移除事件的绑定
function AppearanceWindow:UnSubscribeEvent()
	
	for k,v in pairs(self.m_ArrSubscribeEvent) do
		rktEventEngine.UnSubscribeExecute(v.e, v.s, v.i, v.f)
	end
	
	rktEventEngine.UnSubscribeExecute(EVENT_APPEARANCE_SHOWORHIDEDRESS,0,0,self.ShowOrHideBGCB)
end


-- 窗口每次打开执行的行为
function AppearanceWindow:OnWindowShow()

	-- 变更子窗口
	self:ChangeChildWindow(self.m_CurSelectedTab)
	
	if self.m_OnWindowShowFunc ~= nil then
		self.m_OnWindowShowFunc()
		self.m_OnWindowShowFunc = nil
	end
	
end

-- 设置当界面打开后执行的行为
-- @onWindowShowFunc:当界面打开后调用的行为:boolean
function AppearanceWindow:SetCustomOnWindowShowFunc(onWindowShowFunc)
	
	self.m_OnWindowShowFunc = onWindowShowFunc
	
end

-- 初始化右边页签的点击行为
function AppearanceWindow:InitRightTabClickAction()
	self.Controls.m_ButtonDress.onClick:AddListener(function(on) self:OnRightTabClick(AppearanceRightTabType.TAB_TYPE_DRESS) end)
	self.Controls.m_ButtonRide.onClick:AddListener(function(on) self:OnRightTabClick(AppearanceRightTabType.TAB_TYPE_RIDE) end)
end

-- 变更子窗口
-- @childTab:要显示的子窗口的页签类型:AppearanceRightTabType(string)
-- @onChildWindowShow:子界面成功打开后的回调:function
function AppearanceWindow:ChangeChildWindow(childTab, onChildWindowShow)
	
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
function AppearanceWindow:UpdateTheTabSelectedShow()
	self:SetTabSelectedState(self.Controls.m_ButtonDress, self.m_CurSelectedTab == AppearanceRightTabType.TAB_TYPE_DRESS)
	self:SetTabSelectedState(self.Controls.m_ButtonRide, self.m_CurSelectedTab == AppearanceRightTabType.TAB_TYPE_RIDE)
end

-- 设置页签的选中状态
-- @button:开关组件 MonoBehavior
-- @on:是否选中的标识 boolean
function AppearanceWindow:SetTabSelectedState(tab, on)
	
	tab.transform:Find("GameObject/Image_On").gameObject:SetActive(on)
	tab.transform:Find("GameObject/Image_Off").gameObject:SetActive(not on)
	
end

-- 创建子窗口
-- @childTab:子窗口的页签类型:AppearanceRightTabType(string) 
-- @onChildWindowShow:子界面成功打开后的回调:function
function AppearanceWindow:CreateChildWindow(childTab, onChildWindowShow)
	
	-- 子窗口预制体路径判断
	local prefabPath = nil 
	if childTab == AppearanceRightTabType.TAB_TYPE_DRESS then
		prefabPath = GuiAssetList.Appearance.DressWidget
	else
		prefabPath = GuiAssetList.Appearance.RideWidget
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

-- 返回按钮点击的行为
function AppearanceWindow:OnBackBtnClick()
	self:Hide()
end

-- 右边页签按钮点击行为
-- @childTab:页签的类型:PlayerSkillRightTabType(string) 
function AppearanceWindow:OnRightTabClick(childTab)
	local pHero = GetHero()
	if not pHero then
		return
	end
	
	local level = pHero:GetNumProp(CREATURE_PROP_LEVEL)
	if childTab == AppearanceRightTabType.TAB_TYPE_RIDE then
		if level < gLevelLimitConfig.RideOpen then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "坐骑" .. gLevelLimitConfig.RideOpen .. "级开放")
			return
		end
	elseif childTab == AppearanceRightTabType.TAB_TYPE_DRESS then
		if level < gLevelLimitConfig.DressOpen then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "时装" .. gLevelLimitConfig.DressOpen .. "级开放")
			return
		end
	end
	
	-- 相同标签或在隐藏的不用响应
	if self.m_CurSelectedTab == childTab then 
		return
	end
	
	-- 变更子窗口
	self:ChangeChildWindow(childTab)
	
end

--打开或者隐藏背景显示控制
function AppearanceWindow:OnShowOrHideDressWid(on)
	self.Controls.m_Common_BG.gameObject:SetActive(not on)
end

return AppearanceWindow