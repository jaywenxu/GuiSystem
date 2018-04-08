
--******************************************************************
--** 文件名:	WelfareWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-06-01
--** 版  本:	1.0
--** 描  述:	福利窗口
--** 应  用:  
--******************************************************************
require("GuiSystem.WindowList.Welfare.WelfareDef")

local TitleImagePath = AssetPath.TextureGUIPath.."Activity/activity_biaoti_zu.png"
local MenuItemClass  = require("GuiSystem.WindowList.Welfare.WelfareMenuItem")


local WelfareWindow = UIWindow:new
{
	windowName = "WelfareWindow",
	m_SubWidgets = {},         --子控件列表
	m_SubObjects = {},         --子对象列表
	m_MenuTlgGroup = nil,
	m_MenuObjects = {},
	m_DefMenuItemId = 0,
	m_CurMenuItemId = 0,
	m_MenuTables = {},
}

function WelfareWindow:Init()
	
end

function WelfareWindow:OnAttach(obj)
	UIWindow.OnAttach(self, obj)
		
	self.m_MenuTlgGroup =  self.Controls.m_MenuGrid:GetComponent(typeof(ToggleGroup))
	
	self.Controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnCloseClick))
	
	self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))
	
	self:InitObjMap()
	
	self:CreateMenuList() -- 创建菜单选项
	
	self:FocusItem(self.m_DefMenuItemId)
	
	rktEventEngine.SubscribeExecute(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM,
	 REDDOT_UI_EVENT_WELRARE, self.RefreshRedDot, self)
end

function WelfareWindow:AddMenuItem(heroLevel, id)
    local cfgData = IGame.rktScheme:GetSchemeInfo(WELFARECFG_CSV, id)
    if not cfgData then
        return
    end
    
    if heroLevel < cfgData.MinLevel or cfgData.MaxLevel < heroLevel then
        return
    end

    self.m_MenuTables[cfgData.nIndex] = {id=cfgData.nID, name=cfgData.Title, iconXuan=cfgData.IconXuan, iconMo=cfgData.IconMo}
    if cfgData.nIndex <  100 and self.m_DefMenuItemId == 0 then
        self.m_DefMenuItemId = cfgData.nID
    end
end

function WelfareWindow:InitMenuTable()
    self.m_MenuTables = {}
	local heroLevel = GetHero():GetNumProp(CREATURE_PROP_LEVEL)
	for k, id in pairs(WelfareDef.ItemId) do
        self:AddMenuItem(heroLevel, id)
	end
end

-- 创建选项菜单列表
function WelfareWindow:CreateMenuList()
    
    self:InitMenuTable()
	
	for k, v in pairs(self.m_MenuTables) do 
			
		local MenuItem = rkt.GResources.InstantiateGameObject(self.Controls.m_MenuItemCell.gameObject)
		MenuItem.transform:SetParent(self.Controls.m_MenuGrid.transform, false)
		
		local item = MenuItemClass:new({})
		item:Attach(MenuItem)
		
		-- 设置Toggle Group
		item:SetToggleGroup(self.m_MenuTlgGroup)
		
		-- 设置Select callback	
		item:SetSelectedCallback(handler(self, self.OnSelectedChanged))
		
		local name = v.name
		-- 设置Item数据
		item:SetItemInfo(k, v.iconXuan, v.iconMo)
		self.m_MenuObjects[name] = MenuItem
		
		-- 刷新红点，因每个ICON是异步创建的，所以需要在此处创建时候，做刷新操作
		local flag = SysRedDotsMgr.GetSysFlag("Welfare", name)
		self:RefreshRedDot(nil, nil, nil, {flag=flag, layout = name})
	end
end

function WelfareWindow:InitObjMap()
	self.m_SubObjects = 
	{
		[WelfareDef.ItemId.JLZH] = self.Controls.m_RewardBackWdt,
		[WelfareDef.ItemId.MRQD] = self.Controls.m_DailySignInWdt,
		[WelfareDef.ItemId.SJLB] = self.Controls.m_UpgradePackageWdt,
		[WelfareDef.ItemId.QTDL] = self.Controls.m_WeekLoginWdt,
	}
end

function WelfareWindow:FocusItem(itemId)
	local name = nil
	for k, v in pairs(self.m_MenuTables) do
		if itemId == v.id then
			name = v.name
			break
		end
	end
	if name == nil then
		print("WelfareWindow:FocusItem name为空")
		return
	end
	
	local MenuObj = self.m_MenuObjects[name]
	
	local behav = MenuObj:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		uerror("Error： UI Window Behaviour")
		return
	end
	
	local item = behav.LuaObject
	if item == nil then
		uerror("WelfareWindow:FocusItem item为空")
		return
	end
	
	if nil ~= item and item.windowName == "WelfareMenuItem" then 
		item:SetFocus(true)
	end
end

function WelfareWindow:OnSelectedChanged(idx, on)
	if on then
		self:SwitchTabWdt(idx)
	end
end

function WelfareWindow:SwitchTabWdt(nSelectIdx)
	-- 根据索引获取对应的id
	if not self.m_MenuTables[nSelectIdx] then
		print("[WelfareWindow:SwitchTabWdt] self.m_MenuTables[nSelectIdx]=nil", nSelectIdx)
		return
	end
	local itemId = self.m_MenuTables[nSelectIdx].id
	if itemId == self.m_CurMenuItemId  then
		return 
	end
	
	--加载选中Widget
	if nil == self.m_SubWidgets[itemId] then
		if nil == WelfareDef.WdtLuaFiles[itemId] then
			--IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "暂不实现")
		else
			local WdtClass = require(WelfareDef.WdtLuaFiles[itemId]):new()
			local WelfareObj = self.m_SubObjects[itemId].gameObject
			WdtClass:Attach(WelfareObj)
			WdtClass:Show()
			self.m_SubWidgets[itemId] = WdtClass
		end
	else
		self.m_SubWidgets[itemId]:Show()
	end

	--隐藏上次Widget
	if nil ~= self.m_SubWidgets[self.m_CurMenuItemId] then
		self.m_SubWidgets[self.m_CurMenuItemId]:Hide()
	end
	
	self.m_CurMenuItemId  = itemId
end

-- 刷新红点显示
function WelfareWindow:RefreshRedDot(_, _, _, evtData)
	SysRedDotsMgr.RefreshRedDot(self.m_MenuObjects, "Welfare", evtData)
end

function WelfareWindow:OnEnable()
    self:FocusItem(self.m_DefMenuItemId)
	self:RefreshRedDot()
end

function WelfareWindow:OnCloseClick()
	self:Hide()
end

function WelfareWindow:OnDestroy()
	self.m_MenuObjects = {}
	self.m_SubWidgets  = {}
	self.m_CurMenuItemId = 0
	
	rktEventEngine.UnSubscribeExecute( EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM, 
		REDDOT_UI_EVENT_WELRARE, self.RefreshRedDot, self)
		
	UIWindow.OnDestroy(self)
end

function WelfareWindow:Show(bringTop, nItemId)
	local bTop = bringTop or true
	
	self.m_DefMenuItemId = nItemId or self.m_DefMenuItemId
	
	UIWindow.Show(self, bTop)
end

return WelfareWindow