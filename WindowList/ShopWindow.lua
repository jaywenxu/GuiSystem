

local ShopWindow = UIWindow:new
{
	windowName 	= "ShopWindow",

	tabName 	= 							--这个表需要读配置表,这里缓存,根据需求添加tab
	{
		emCofC			= 1,                --商会
		emShop			= 2,
		emDress			= 3,
		emDeposit		= 4,	
	},

	toggleCtl	={},
	
	Widget = {},
	Path = {},								--延迟加载相关路径
	m_WidgetObjs = {},
	
	m_defaultPage = -1,
	m_curTab		= 0,
	m_preTab		= 0,
}

local titleImagePath = AssetPath.TextureGUIPath.."Store/Store_shangcheng.png"
local ShopRootPath = "GuiSystem.WindowList.Shop."
ShopWindow.Path = {
			ShopRootPath .. "CofC.",
			ShopRootPath .. "Shop.",
			ShopRootPath .. "Dress.",
			ShopRootPath .. "Deposit.",
}
			
local TabLuaWdtFiles = {
	"CofCWidget",
    "ShopWidget",
	"DressWidget",
	"DepositWidget",
}

function ShopWindow:Init()
	self.Widget[1] = require("GuiSystem.WindowList.Shop.CofC.CofCWidget")
	self.Widget[2] = require("GuiSystem.WindowList.Shop.Shop.ShopWidget")
	self.Widget[3] = require("GuiSystem.WindowList.Shop.Dress.DressWidget")
	self.Widget[4] = require("GuiSystem.WindowList.Shop.Deposit.DepositWidget")
	
	self.HeroDisplayWidgetClass = require( "GuiSystem.WindowList.Shop.Dress.HeroDisplayWidget" )
end

function ShopWindow:OnAttach(obj)
	UIWindow.OnAttach(self,obj)
	
	self.HeroDisplayWidgetClass:Attach(self.Controls.m_HeroDisplayWidget.gameObject)
	
	self.callback_OnCloseBtnClick = function() 
										self:Hide()
										self.HeroDisplayWidgetClass:ShowHeroModel(false)
										rktEventEngine.FireExecute(EVENT_APPEAR_CLOSE_RAPPEAR, 0 , 0)--SOURCE_TYPE_APPEAR
									end
	UIWindow.AddCommonWindowToThisWindow(self, true, titleImagePath, self.callback_OnCloseBtnClick,nil,function() self:SetFullScreen() end)

    self:SetFullScreen() -- 设置为全屏界面

	self.m_WidgetObjs = {
		self.Controls.m_CofCWidget,
		self.Controls.m_ShopWidget,
		self.Controls.m_DressWidget,
		self.Controls.m_DepositWidget,
	}
	self.Widget[1]:Attach(self.Controls.m_CofCWidget.gameObject)
	self.Widget[2]:Attach(self.Controls.m_ShopWidget.gameObject)
	self.Widget[3]:Attach(self.Controls.m_DressWidget.gameObject)
	self.Widget[4]:Attach(self.Controls.m_DepositWidget.gameObject)

	
	--缓存toggle
	self.toggleCtl = {
		self.Controls.m_CofCToggle,
		self.Controls.m_ShopToggle,	
		self.Controls.m_DressToggle,
		self.Controls.m_DepositToggle,
	}
	
	--需要读配置表配置toggle							TODO
	self:InitToggle()
--	ShopWindow:SetDefaultTab(1)
	
	-- 注册toggle group 点击过滤事件
	
	-- 第一个小类
	self.callback_ToggleOne	= function(on) self:OnToggleChanged(on, self.tabName.emCofC) end
	self.Controls.m_CofCToggle.onValueChanged:AddListener(self.callback_ToggleOne)
	
	-- 第二个小类
	self.callback_ToggleOne	= function(on) self:OnToggleChanged(on, self.tabName.emShop) end
	self.Controls.m_ShopToggle.onValueChanged:AddListener(self.callback_ToggleOne)
	
	-- 第三个小类
	self.callback_ToggleTwo	= function(on) self:OnToggleChanged(on, self.tabName.emDeposit) end
	self.Controls.m_DepositToggle.onValueChanged:AddListener(self.callback_ToggleTwo)	
	
	-- 第四个小类
	self.callback_ToggleThree	= function(on) self:OnToggleChanged(on, self.tabName.emDress) end
	self.Controls.m_DressToggle.onValueChanged:AddListener(self.callback_ToggleThree)	
	
	self.callback_CurrencyChange = function() self:OnCurrencyChange() end
	self.callback_ShopDataRefresh = function()  end
	
	local uid = GetHero():GetUID()
	rktEventEngine.SubscribeExecute( EVENT_CION_YUANBAO , SOURCE_TYPE_COIN , self.uid , self.callback_CurrencyChange)
	rktEventEngine.SubscribeExecute( EVENT_CION_YINLIANG , SOURCE_TYPE_COIN , self.uid , self.callback_CurrencyChange)
	rktEventEngine.SubscribeExecute( EVENT_CION_YINBI , SOURCE_TYPE_COIN , self.uid , self.callback_CurrencyChange)
	
	--[[if self.m_defaultPage ~= -1 then
--	if defaultPage ~= nil then
		self:NotFirstShowSetDefault(self.m_defaultPage)
	else
		self:NotFirstShowSetDefault(1)
	end
	
	if self.Widget[1].m_defaultGoodsID ~= nil and self.Widget[1].m_defaultGoodsID > 0 then 
		self.Widget[1]:JumpToDefaultGoods()
	end
	self.m_defaultPage = -1--]]
	
	self:NotFirstShowSetDefault(self.m_defaultPage)
end

--打开商城接口
--nGoodsId  默认选中的商品
function ShopWindow:OpenShop(nGoodsId)
	if not IGame.PlazaClient:LoadedPlazaGoodsCsv() then				--加载配置数据
		return 
	end
		--请求获取商城相关数据
	if not IGame.PlazaClient.m_HaveInit then
		local bInit = 0
		GameHelp.PostServerRequest( "RequestPlazaLimitData("..bInit..")" )
	end

	if nGoodsId ~= nil and nGoodsId > 0 then
		local nType = IGame.PlazaClient:GetTypeByID(nGoodsId)
		self.Widget[2].m_defaultGoodsType = nType
		self.Widget[2].m_defaultGoodsID = nGoodsId
	
	
		--当前界面打开情况下的跳转
		if self:isShow() then
			if self.m_curTab ~= 2 then
				self.toggleCtl[2].isOn	= true
				self.m_preTab = 2
				self.m_curTab = 2
			else
				rktEventEngine.FireExecute(EVENT_SHOP_JUMPTOGOOD,0,0,nGoodsId)
			end
			
			return
		end
	end
	
	self:ShowShopWindow(1)
end
--打开指定的界面
function ShopWindow:ShowShopWindow(defaultPage)
	if not IGame.PlazaClient:LoadedPlazaGoodsCsv() then				--加载配置数据
		return 
	end
	
	--为了兼容之前的需求，可优化 TODO
	if defaultPage == 1 then
		defaultPage = 2
	elseif defaultPage == 2 then
		defaultPage = 1
	elseif defaultPage == 3 then
		defaultPage = 4
	elseif defaultPage == 4 then
		defaultPage = 4
	end
	
	--请求获取商城相关数据
	if not IGame.PlazaClient.m_HaveInit then
		local bInit = 0
		GameHelp.PostServerRequest( "RequestPlazaLimitData("..bInit..")" )
	end
	
	if defaultPage ~= nil then
		self.m_defaultPage = defaultPage
	end
	
    self:Show()
end

--重写父类
function ShopWindow:Show(bringTop)
	if self:isLoaded() and self.m_defaultPage ~= -1 then
		--[[if self.Widget[1].m_defaultGoodsID ~= nil and self.Widget[1].m_defaultGoodsID > 0 then 
			self.Widget[1]:JumpToDefaultGoods()
		end
		self:NotFirstShowSetDefault(self.m_defaultPage)--]]

		self:NotFirstShowSetDefault(self.m_defaultPage)
		
		self.m_defaultPage = -1
	end
	UIWindow.Show(self,true)
end

function ShopWindow:Destory()
	self.m_defaultPage = -1
	rktEventEngine.UnSubscribeExecute( EVENT_CION_YUANBAO , SOURCE_TYPE_COIN , self.uid , self.callback_CurrencyChange)
	rktEventEngine.UnSubscribeExecute( EVENT_CION_YINLIANG , SOURCE_TYPE_COIN , self.uid , self.callback_CurrencyChange)
	rktEventEngine.UnSubscribeExecute( EVENT_CION_YINBI , SOURCE_TYPE_COIN , self.uid , self.callback_CurrencyChange)
	UIWindow.Destroy(self)
end

--货币改变，刷新拥有货币值
function ShopWindow:OnCurrencyChange()
	self.Widget[1].GoodsExpenseInfo:UpdateOwnInfoData()
	self.Widget[1].GoodsExpenseInfo:UpdateGoodsInfo()
end

--非第一次打开初始化默认界面
function ShopWindow:NotFirstShowSetDefault(index)
	if self.m_preTab > 0 then
		self.Widget[self.m_preTab]:Hide()
		self.Widget[index]:Show()
--		self:SetToggleState(false, self.m_preTab)
		self.toggleCtl[self.m_preTab].isOn	= false
		
		self.m_preTab = index
		self.m_curTab = index
--		self:SetToggleState(true, self.m_curTab)
		self.toggleCtl[self.m_preTab].isOn	= true
	else
		self.toggleCtl[self.m_defaultPage].isOn = true
	end
end

-------------------------------------------------------------------
-- Toggle 选中项被改变触发事件
-------------------------------------------------------------------
function ShopWindow:OnToggleChanged(on, curTabIndex)

	self:SetToggleState(on, curTabIndex)
	
	if self.m_curTab == curTabIndex then 
		return 
	end
	
	if on then 
		self:LazzyAttatch(curTabIndex)
	end
	
	--这里切换显示界面 		TODO
	self:RefeshTogglePage(curTabIndex)			
end

function ShopWindow:LazzyAttatch(index)
	local widget = self.Widget[index]
	if not widget then
		self.Widget[index] = require(ShopWindow.Path[index] .. TabLuaWdtFiles[index])
		self.Widget[index]:Attach(self.m_WidgetObjs[index].gameObject)
	end
end 


--设置toggle状态
function ShopWindow:SetToggleState(on, curTabIndex)
	local config = {
		self.Controls.m_CofCToggle,
		self.Controls.m_ShopToggle,
		self.Controls.m_DressToggle,
		self.Controls.m_DepositToggle,
	}

	if on then 
		config[curTabIndex].transform:Find("ON").gameObject:SetActive(true)
		config[curTabIndex].transform:Find("OFF").gameObject:SetActive(false)
	else		
		config[curTabIndex].transform:Find("ON").gameObject:SetActive(false)
		config[curTabIndex].transform:Find("OFF").gameObject:SetActive(true)
		return
	end
end


-------------------------------------------------------------------
-- 刷新toggle对应的页面信息						TODO
-------------------------------------------------------------------
function ShopWindow:RefeshTogglePage(curTabIndex)	
	if self.m_preTab > 0 then
		self.Widget[self.m_preTab]:Hide()
	end
	
	self.m_curTab = curTabIndex
	self.m_preTab = curTabIndex
	
	self.Widget[curTabIndex]:Show()
end	


-------------------------------------------------------------------
-- 初始化所有toggle组件				
-------------------------------------------------------------------
function ShopWindow:InitToggle()
	
	self.Controls.m_ShopToggle.isOn	= false
	self.Controls.m_ShopToggle.gameObject:SetActive(false)
	
	self.Controls.m_DressToggle.isOn	= false
	self.Controls.m_DressToggle.gameObject:SetActive(false)
	
	self.Controls.m_CofCToggle.isOn = false
	self.Controls.m_CofCToggle.gameObject:SetActive(false)
	
	self.Controls.m_DepositToggle.isOn = false
	self.Controls.m_DepositToggle.gameObject:SetActive(false)
	
	for i = 1, 4, 1 do								--这里根据读表的数量扩展，控制显示几个
		if 1 == i then 
			self.Controls.m_CofCToggle.gameObject:SetActive(false)				--商会不要了
		elseif 2 == i then 
			self.Controls.m_ShopToggle.gameObject:SetActive(true)
		elseif 3 == i then
			self.Controls.m_DressToggle.gameObject:SetActive(false)
		elseif 4 == i then
			self.Controls.m_DepositToggle.gameObject:SetActive(true)
		end
				
	end
end

-------------------------------------------------------------------
-- 设置默认显示页面
-------------------------------------------------------------------
function ShopWindow:SetDefaultTab(curTabIndex)	
	if self.tabName.emShop == curTabIndex then 
		self.Controls.m_ShopToggle.isOn	= true
	elseif self.tabName.emDress == curTabIndex then
		self.Controls.m_DressToggle.isOn	= true
	elseif self.tabName.emDeposit == curTabIndex then
		self.Controls.m_DepositToggle.isOn 	= true
	elseif self.tabName.emCofC == curTabIndex then
		self.Controls.m_CofCToggle.isOn 	= true
	end
end	

-- 刷新限购数据
function ShopWindow:RefreshBuyLimit(plazaId, dhcAlone, whcAlone)
	rktEventEngine.FireEvent(EVENT_SHOP_BUYSUCCESS,0,0,plazaId)
end

return ShopWindow