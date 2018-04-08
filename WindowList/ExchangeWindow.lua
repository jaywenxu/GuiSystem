--/******************************************************************
---** 文件名:	ExchangeWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-09
--** 版  本:	1.0
--** 描  述:	商品交易窗口
--** 应  用:  
--******************************************************************/

require("GuiSystem.WindowList.Exchange.ExchangeWindowDefine")
require("GuiSystem.WindowList.Exchange.ExchangeWindowTool")
require("GuiSystem.WindowList.PlayerSkill.PlayerSkillWindowTool")
require("GuiSystem.WindowList.Exchange.ExchangeWindowPresetDataMgr")

local ExchangeWindow = UIWindow:new(
{
	windowName = "ExchangeWindow",		-- 窗口名称
	
	m_IsWindowInvokeOnShow = false;		-- 窗口是否调用了OnWindowShow方法的标识:boolean
	m_CurSelectedTab = nil,				-- 当前选中的页签类型:ExchangeWindowRightTabType(string)
	
	m_OnChildWindowShow = nil,			-- 子界面显示成功额外执行的行为:function
	
	m_ArrGoChildWindow = 
	{
		["RIGHT_TAB_BAITAN"] = 0,
		["RIGHT_TAB_PAIMAI"] = 0,
	},									-- 各子窗口实例:table(GameObject)
	
	m_ArrChildWindow = 
	{
		["RIGHT_TAB_BAITAN"] = 0,
		["RIGHT_TAB_PAIMAI"] = 0,
	}									-- 各子窗口脚本:table(UIControl)
})

local NO_INST_CHILD_WINDOW_GO_VALUE = 0												-- 没有实例化时的对象数值
local TITLE_IMG_PATH = AssetPath.TextureGUIPath.."Exchanger/Exchange_baitan.png"	-- 窗口标题资源路径
local PAIMAI_TITLE_IMG_PATH = AssetPath.TextureGUIPath.."Exchanger/Exchange_paimai.png"

function ExchangeWindow:Init()
	
end

function ExchangeWindow:OnAttach( obj )
	
	UIWindow.OnAttach(self, obj)

	self.m_ArrGoChildWindow = 
	{
		["RIGHT_TAB_BAITAN"] = 0,
		["RIGHT_TAB_PAIMAI"] = 0,
	}									
	
	self.m_ArrChildWindow = 
	{
		["RIGHT_TAB_BAITAN"] = 0,
		["RIGHT_TAB_PAIMAI"] = 0,
	}		

	self.m_ArrChildWindow[ExchangeWindowRightTabType.TAB_TYPE_BAITAN] = require("GuiSystem.WindowList.Exchange.ExchangeBaiTanWidget"):new()
	self.m_ArrChildWindow[ExchangeWindowRightTabType.TAB_TYPE_PAIMAI] = require("GuiSystem.WindowList.Exchange.ExchangePaiMaiWidget"):new()

	-- 通用顶部菜单的返回点击
	UIWindow.AddCommonWindowToThisWindow(self, true, TITLE_IMG_PATH,
		function()
			IGame.ExchangeClient:RequestLeaveExchange()
			self:OnBackBtnClick() 
		end,nil,function() self:SetFullScreen() end
	)	
	-- 初始化右边页签的点击行为
	self:InitRightTabClickAction()
	
	if self.m_IsWindowInvokeOnShow then
		self.m_IsWindowInvokeOnShow = false
		self:OnWindowShow()
	end
end


function ExchangeWindow:OnDestroy()
	UIWindow.OnDestroy(self)

	table_release(self)			
end

function ExchangeWindow:_showWindow()
	
	UIWindow._showWindow(self)

	if self:isLoaded() then
		self:OnWindowShow()
	else
		self.m_IsWindowInvokeOnShow = true
	end
	
end

-- 显示窗口
-- @tabType:页签类型:ExchangeWindowRightTabType(string)
function ExchangeWindow:ShowWindow(tabType)

	self.m_CurSelectedTab = tabType

	UIWindow.Show(self, true)

end


-- 窗口每次打开执行的行为
function ExchangeWindow:OnWindowShow()

	-- 变更子窗口
	self:ChangeChildWindow(self.m_CurSelectedTab)
	
	rktEventEngine.FireExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCHANGE_UI_EVENT_WINDOW_SHOW)
	
end

-- 初始化右边页签的点击行为
function ExchangeWindow:InitRightTabClickAction()

	self.Controls.m_ButtonBaiTan.onClick:AddListener(function(on) self:OnRightTabClick(ExchangeWindowRightTabType.TAB_TYPE_BAITAN) end)
	self.Controls.m_ButtonPaiMai.onClick:AddListener(function(on) self:OnRightTabClick(ExchangeWindowRightTabType.TAB_TYPE_PAIMAI) end)
	
end

-- 变更子窗口
-- @childTab:要显示的子窗口的页签类型:ExchangeWindowRightTabType(string)
function ExchangeWindow:ChangeChildWindow(childTab)
	
	self.m_CurSelectedTab = childTab
	       
	-- 先判断子窗口是否创建了，如果没有创建的就动态创建出来
	-- 如果子窗口已经创建了，就更新子界面
	if(self.m_ArrGoChildWindow[childTab] == NO_INST_CHILD_WINDOW_GO_VALUE) then
		-- 创建子窗口
		self:CreateChildWindow(childTab)
	else
		for k,v in pairs(self.m_ArrGoChildWindow) do
			if(v ~= NO_INST_CHILD_WINDOW_GO_VALUE) then
				if(k == childTab) then
					self.m_ArrChildWindow[k]:ShowWidget()
				else 
					self.m_ArrChildWindow[k]:HideWidget()
				end
			end
		end
        
        if self.CommonWindowWidget then
            if self.CommonWindowWidget:isLoaded() and self.CommonWindowWidget:isShow() then 
                if self.m_CurSelectedTab == ExchangeWindowRightTabType.TAB_TYPE_BAITAN then        
                    self.CommonWindowWidget:SetName(TITLE_IMG_PATH)
                elseif self.m_CurSelectedTab == ExchangeWindowRightTabType.TAB_TYPE_PAIMAI then 
                    self.CommonWindowWidget:SetName(PAIMAI_TITLE_IMG_PATH)
                end
            end
        end        
	end
	
	-- 更新页签选中的显示
	self:UpdateTheTabSelectedShow()
		
end

--- 更新页签选中的显示
function ExchangeWindow:UpdateTheTabSelectedShow()
	
	self:SetTabSelectedState(self.Controls.m_ButtonBaiTan, self.m_CurSelectedTab == ExchangeWindowRightTabType.TAB_TYPE_BAITAN)
	self:SetTabSelectedState(self.Controls.m_ButtonPaiMai, self.m_CurSelectedTab == ExchangeWindowRightTabType.TAB_TYPE_PAIMAI)
	
end

function ExchangeWindow:SetTabSelectedState(tab, on)
	
	tab.transform:Find("Image_On").gameObject:SetActive(on)
	tab.transform:Find("Image_Off").gameObject:SetActive(not on)
	
end

-- 创建子窗口
-- @childTab:子窗口的页签类型:ExchangeWindowRightTabType(string)
function ExchangeWindow:CreateChildWindow(childTab)
	
	-- 子窗口预制体路径判断
	local prefabPath = nil 
	if childTab == ExchangeWindowRightTabType.TAB_TYPE_BAITAN then
		prefabPath = GuiAssetList.Exchange.ExchangeBaiTanWidget            
	else 
		prefabPath = GuiAssetList.Exchange.ExchangePaiMaiWidget     
	end
	
	rkt.GResources.FetchGameObjectAsync( prefabPath ,
		function ( path , obj , ud )

			self.m_ArrGoChildWindow[childTab] = obj
			obj.transform:SetParent(self.Controls.m_TfChildWindowNode.transform, false)
			self.m_ArrChildWindow[childTab]:Attach(obj)
			
			-- 变更子窗口
			self:ChangeChildWindow(childTab)
			
		end, nil, AssetLoadPriority.GuiNormal)
end

-- 返回按钮点击的行为
function ExchangeWindow:OnBackBtnClick()
	
	UIManager.ExchangeWindow:Hide()
	
end

-- 右边页签按钮点击行为
-- @tabType:页签的类型:ExchangeWindowRightTabType(string)
function ExchangeWindow:OnRightTabClick(tabType)
	
	-- 相同标签或在隐藏的不用响应
	if self.m_CurSelectedTab == tabType then 
		return
	end
	
	-- 变更子窗口
	self:ChangeChildWindow(tabType)
	
end


return ExchangeWindow