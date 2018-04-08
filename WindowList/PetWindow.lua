
--------------------------------------灵兽界面------------------------------------------
local PetWindow = UIWindow:new
{
	windowName 	= "PetWindow",

	TabToggleName = {
		PropertyToggle			= 1,				--属性
		TrainToggle				= 2,				--培养
		DeploymentToggle		= 3,				--阵法
		TuJianToggle			= 4,				--图鉴
	},
	
	ToggleCtl = {},				--缓存组件表
	WidgetCtlCache = {},		--子界面缓存
	WidgetModule = {},			--子模块缓存
	
	m_curTab		= 1,
	m_preTab		= 0,
	
	m_InitDeployment = false,		--初始化阵法界面
	m_InitTuJian = false,			--初始化图鉴界面
}

local titleImagePath = AssetPath.TextureGUIPath.."Pet_1/pet_lingshou.png"

function PetWindow:Init()
	self.WidgetModule[1] = require("GuiSystem.WindowList.Pet.Property.PetPropertyWidget"):new()
	self.WidgetModule[2] = require("GuiSystem.WindowList.Pet.Train.PetTrainWidget"):new()
	self.WidgetModule[3] = require("GuiSystem.WindowList.Pet.Deployment.DeploymentWidget"):new()
	self.WidgetModule[4] = require("GuiSystem.WindowList.Pet.TuJian.PetTuJianWidget"):new()
	self.WidgetModule[5] = require("GuiSystem.WindowList.Pet.PetDisplayWidget"):new()		--属性，培养界面共享界面
	self.SuitTips = require("GuiSystem.WindowList.Pet.SuitTip.PetSuitTips"):new()
	self.PetLearnSkillWidget = require("GuiSystem.WindowList.Pet.PetSkillLearn.PetSkillLearn"):new()
end

function PetWindow:OnAttach(obj)
	UIWindow.OnAttach(self,obj)
	
	self.callback_OnCloseBtnClick = function() self:Hide() end				
	UIWindow.AddCommonWindowToThisWindow(self, true, titleImagePath, self.callback_OnCloseBtnClick,nil,function() self:SetFullScreen() end)
	
	self.LateSetDefaultCB = function() self:LateSetDefault() end
	
	self.ToggleCtl = {
		self.Controls.m_PropertyToggle,
		self.Controls.m_TrainToggle,
		self.Controls.m_DeploymentToggle,
		self.Controls.m_TuJianToggle,
	}
	self:SetFullScreen() -- 设置为全屏界面
	self.WidgetModule[1]:Attach(self.Controls.m_PropertyWidget.gameObject)
	self.WidgetModule[2]:Attach(self.Controls.m_TrainWidget.gameObject)
	self.WidgetModule[5]:Attach(self.Controls.m_PetDisplayWidget.gameObject)
	--异步加灵兽阵承界面
	rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetDeploymentWidget ,
		function ( path , obj , ud )
			if nil ==obj then   -- 判断U3D对象是否已经被销毁
				return
			end
			obj.transform:SetParent(self.Controls.m_PetDeploymentParent,false)
			self.WidgetModule[3]:Attach(obj)
			self.WidgetModule[3]:Hide()
			self.m_InitDeployment = true
		end , nil , AssetLoadPriority.GuiNormal )
	
	--异步加载图鉴界面
	rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetTuJianWidget ,
		function ( path , obj , ud )
			if nil ==obj then   -- 判断U3D对象是否已经被销毁
				return
			end
			obj.transform:SetParent(self.Controls.m_TuJianParent,false)
			self.WidgetModule[4]:Attach(obj)
			self.WidgetModule[4]:Hide()
			self.m_InitTuJian = true
		end , nil , AssetLoadPriority.GuiNormal )
		
	--异步加载套装tips界面
	rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetSkillSuitTip ,
		function ( path , obj , ud )
			if nil ==obj then   -- 判断U3D对象是否已经被销毁
				return
			end
			obj.transform:SetParent(self.Controls.m_PetSkillSuitTipParent,false)
			self.SuitTips:Attach(obj)
			self.SuitTips:Hide()
		end , nil , AssetLoadPriority.GuiNormal )

	rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetSkillLearn ,
		function ( path , obj , ud )
			if nil ==obj then   -- 判断U3D对象是否已经被销毁
				return
			end
			obj.transform:SetParent(self.Controls.m_PetLearnParent,false)
			self.PetLearnSkillWidget:Attach(obj)
			self.PetLearnSkillWidget:Hide()
		end , nil , AssetLoadPriority.GuiNormal )

	self:InitToggle()
	self.Attatched = true
	if self.LateTojumpPage then
		self:CheckShow()
		self:SetDefaultTab(self.LateTojumpPage)
		self.LateTojumpPage = nil
	end
	
	if self.NeedOpenExpUsePage then
		self.NeedOpenExpUsePage = nil
		self.WidgetModule[1]:OnClickAddEXPBtn()
	end
	
	self.OnFangshengCB = function() self:OnPetFangSheng() end
	rktEventEngine.SubscribeExecute(EVENT_PET_FANSEHNG, SOURCE_TYPE_PET, 0, self.OnFangshengCB)
    
    self.OnRefreshRedDot = function() self:RefreshToggleRedDot() end  
    rktEventEngine.SubscribeExecute(EVENT_REFRESH_PET_REDDOT, SOURCE_TYPE_PET, 0, self.OnRefreshRedDot) 
end

function PetWindow:Show( bringTop )
	UIWindow.Show(self, bringTop)
end

function PetWindow:Hide(destory)
	rktEventEngine.FireExecute(EVENT_PET_CLOSE_WINDOW, SOURCE_TYPE_PET, 0)
	UIWindow.Hide(self, destory)
end

function PetWindow:OnDestroy()
	self.Attatched = false
	self.LateTojumpPage = nil
	self.m_preTab = 0
	
	self.m_InitDeployment = false
	self.m_InitTuJian = false
	self.LateDefaultIndex = nil
	rktEventEngine.UnSubscribeExecute(EVENT_PET_FANSEHNG, SOURCE_TYPE_PET, 0, self.OnFangshengCB)
    rktEventEngine.UnSubscribeExecute(EVENT_REFRESH_PET_REDDOT, SOURCE_TYPE_PET, 0, self.OnRefreshRedDot) 
	UIWindow.OnDestroy(self)
end

function PetWindow:InitToggle()
	for i = 1, #self.ToggleCtl do 
		local toggleChangeCB = function(on) self:OnToggleChanged(on,i) end
		self.ToggleCtl[i].onValueChanged:AddListener(toggleChangeCB)
	end
end

function PetWindow:ShowPetWindow(defaultPage)
	if self:isLoaded() then
		self:CheckShow()
		self:SetDefaultTab(defaultPage)
	else
		self.LateTojumpPage = defaultPage
	end
	UIWindow.Show(self,true)
end

--直接跳到经验使用界面
function PetWindow:OpenExpUsePage()
	if self:isLoaded() then
		self:ShowPetWindow(1)
		self.WidgetModule[1]:OnClickAddEXPBtn()
	else
		self.NeedOpenExpUsePage = true
	end
end

--打开界面初始化
function PetWindow:CheckShow()	
	local pHero = IGame.EntityClient:GetHero()
	if pHero == nil then
		uerror("获得Hero实体失败!your Hero is nil!")
		return
	end
	
	local level = pHero:GetNumProp(CREATURE_PROP_LEVEL)
	if level < gPetCfg.PetTrainOpenLevel then
		self.ToggleCtl[2].gameObject:SetActive(false)
		self.ToggleCtl[3].gameObject:SetActive(false)
	elseif level >= gPetCfg.PetTrainOpenLevel and level < gPetCfg.PetDeploymentOpenCfg.PetDeploymentOpenLevel_1 then
		self.ToggleCtl[2].gameObject:SetActive(true)
		self.ToggleCtl[3].gameObject:SetActive(false)
	else
		self.ToggleCtl[2].gameObject:SetActive(true)
		self.ToggleCtl[3].gameObject:SetActive(true)
        
        self:RefreshToggleRedDot()
	end
end


-------------------------------------------------------------------
-- Toggle 选中项被改变触发事件
-------------------------------------------------------------------
function PetWindow:OnToggleChanged(on, curTabIndex)
	self:SetToggleState(on, curTabIndex)
	self:RefeshTogglePage(curTabIndex)
end

--设置toggle状态
function PetWindow:SetToggleState(on, curTabIndex)
	if on then 
		self.ToggleCtl[curTabIndex].transform:Find("ON").gameObject:SetActive(true)
		self.ToggleCtl[curTabIndex].transform:Find("OFF").gameObject:SetActive(false)
	else		
		self.ToggleCtl[curTabIndex].transform:Find("ON").gameObject:SetActive(false)
		self.ToggleCtl[curTabIndex].transform:Find("OFF").gameObject:SetActive(true)
		return
	end
end

--特殊处理toggle切换
function PetWindow:UpdateToggleState()
	self.ToggleCtl[self.m_preTab].transform:Find("ON").gameObject:SetActive(true)
	self.ToggleCtl[self.m_preTab].transform:Find("OFF").gameObject:SetActive(false)
end

-------------------------------------------------------------------
-- 刷新toggle对应的页面信息						TODO
-------------------------------------------------------------------
function PetWindow:RefeshTogglePage(curTabIndex)
	if self.m_preTab == curTabIndex then
		return 
	end
	
	if self.m_preTab > 0 then
		self.ToggleCtl[self.m_preTab].isOn	= false
		self.WidgetModule[self.m_preTab]:Hide()
	end

	if curTabIndex == 2 or curTabIndex == 1 then
		if self.m_preTab ~= 1 and self.m_preTab ~= 2 then
			--self.WidgetModule[5]:Hide()
			self.WidgetModule[5]:Show()
		end		
	else
		if self.WidgetModule[5]:isShow() then
			self.WidgetModule[5]:Hide()
		end
	end
	
	self.m_curTab = curTabIndex
	self.m_preTab = curTabIndex
	
	self.WidgetModule[curTabIndex]:Show()
end	

-------------------------------------------------------------------
-- 设置默认显示页面
-------------------------------------------------------------------
function PetWindow:SetDefaultTab(curTabIndex)
	self.LateDefaultIndex = curTabIndex
	if self.m_InitDeployment and self.m_InitTuJian then
		self:SetDefaultTabFunc(curTabIndex)
	else
		rktTimer.SetTimer(self.LateSetDefaultCB,30,-1,"PetWindow:SetDefaultTab()")
	end
end

--封装默认选中tab
function PetWindow:SetDefaultTabFunc()
	local curTabIndex = self.LateDefaultIndex
	--上次关闭本界面，重新打开，设置模型重新显示
	if self.Attatched and self.m_preTab == 1 or self.m_preTab == 2 then
		rktEventEngine.FireEvent(EVENT_PET_REOPEN_WIDGET, SOURCE_TYPE_PET, 0, curTabIndex)
	end
	
	if self.TabToggleName.PropertyToggle == curTabIndex then 
		self.ToggleCtl[1].isOn	= true
	elseif self.TabToggleName.TrainToggle == curTabIndex then
		self.ToggleCtl[2].isOn	= true
	elseif self.TabToggleName.DeploymentToggle == curTabIndex then
		self.ToggleCtl[3].isOn 	= true
	elseif self.TabToggleName.TuJianToggle == curTabIndex then
		self.ToggleCtl[4].isOn 	= true
	end
end

--延迟设置默认界面
function PetWindow:LateSetDefault()
	if self.m_InitDeployment and self.m_InitTuJian then
		if self.LateDefaultIndex then
			self:SetDefaultTabFunc()
			self.LateDefaultIndex = nil
		end
		rktTimer.KillTimer(self.LateSetDefaultCB)
	end
end

--放生返回
function PetWindow:OnPetFangSheng()
	local petTable = IGame.PetClient:GetCurPetTable()
	if table_count(petTable) <= 0 then
		self.WidgetModule[5]:SetPet(false)
		self.WidgetModule[1]:SetPet(false)
		self.WidgetModule[2]:SetPet(false)
	end
end

-- 刷新toggle红点
function PetWindow:RefreshToggleRedDot()
 
    if IGame.PetClient:CheckIsZhenLingCanUpgrade() then 
        self.Controls.m_ZhenFaRedDot.gameObject:SetActive(true)
    else
        self.Controls.m_ZhenFaRedDot.gameObject:SetActive(false)    
    end        
end

return PetWindow