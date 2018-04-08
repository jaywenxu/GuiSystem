--组队窗口主面板
---------------------------------------------------------------
local TeamWindow = UIWindow:new
{
	windowName = "TeamWindow" ,
	
	toggleType = 
	{
		togTeamplatform     = 1,        -- 匹配组队平台toggle
		togMyTeam           = 2,        -- 我的队伍toggle
		togNearbyTeam       = 3,        -- 附近队伍toggle
	},
	
	targetID = 0,
	m_IdleTaskMyTeamID      = nil,      -- 我的队伍
	m_IdleNearTeamID        = nil,		-- 附近队伍
	m_wantGotoType          = nil,

	TitlePath = GuiAssetList.GuiRootTexturePath .. "Team/team_biati_duiwu.png" ,
	currentToggleType = nil,
    
	WidgetConfigInfo = 	
	{
		[1] =
            {
                path = GuiAssetList.TeamPlatFormWidge ,
                haveFetch       = false,
                instantiate     = nil,
                currentState    = false,
                widgetScript    = nil,
            },
        
		[2] =
            {
                path = GuiAssetList.MyTeamWidget ,
                haveFetch       = false,
                instantiate     = nil,
                currentState    = false,
                widgetScript    = nil,
            },
        
		[3] =
            {
                path = GuiAssetList.NearTeamWidget ,
                haveFetch       = false,
                instantiate     = nil,
                currentState    = false,
                widgetScript    = nil,
            
            }
	}
}
	
---------------------------------------------------------------
function TeamWindow:Init()
		self.WidgetConfigInfo[self.toggleType.togMyTeam].widgetScript = require("GuiSystem.WindowList.Team.MyTeamWidget"):new()		--我的队伍界面
		self.WidgetConfigInfo[self.toggleType.togNearbyTeam].widgetScript = require("GuiSystem.WindowList.Team.NearbyTeamWidget"):new()	--附近队伍界面
		self.WidgetConfigInfo[self.toggleType.togTeamplatform].widgetScript  = require("GuiSystem.WindowList.Team.TeamplatformWidget"):new()  --组队平台界面
end
---------------------------------------------------------------
function TeamWindow:OnAttach( obj )
    
	UIWindow.OnAttach(self,obj)
    
	self.callbackOnCloseButtonClick = function() self:OnCloseButtonClick() end    
	self:AddCommonWindowToThisWindow(true,self.TitlePath,self.callbackOnCloseButtonClick,nil,function() self:SetFullScreen() end)
    
	--预加载子界面
	self.LoadMyTeamWidget = function() rkt.GResources.LoadAsync(self.WidgetConfigInfo[self.toggleType.togMyTeam].path,typeof(UnityEngine.Object),nil,"",AssetLoadPriority.GuiNormal) end
	self.LoadNearTeamWidget =function() rkt.GResources.LoadAsync(self.WidgetConfigInfo[self.toggleType.togNearbyTeam].path,typeof(UnityEngine.Object),nil,"",AssetLoadPriority.GuiNormal) end
	self.LoadTeamPlaneWidget = function() rkt.GResources.LoadAsync(self.WidgetConfigInfo[self.toggleType.togTeamplatform].path,typeof(UnityEngine.Object),nil,"",AssetLoadPriority.GuiNormal) end
	
	self.CreateTeam = function(event, srctype, srcid, eventData) self:OnCreateTeam(event, srctype, srcid, eventData) end 
	self.QuitTeam = function(event, srctype, srcid, eventData) self:OnQuitTeam(event, srctype, srcid, eventData) end 
	
	self.callbackOnEnable = function() self:OnEnable() end
	self.unityBehaviour.onEnable:AddListener(self.callbackOnEnable) 
    
	self.callbackOnDisable = function() self:OnDisable() end
	self.unityBehaviour.onDisable:AddListener(self.callbackOnDisable) 

	self:LoadWidgetResourceAsys()
	
	self.callbackMyTeamToogleOnValueChanged = function(on) self:ToogleOnValueChanged(on, self.toggleType.togMyTeam) end
	self.Controls.m_MyTeam.onValueChanged:AddListener(self.callbackMyTeamToogleOnValueChanged)
    
	self.callbackNearbyTeamToogleOnValueChanged = function(on) self:ToogleOnValueChanged(on, self.toggleType.togNearbyTeam) end
	self.Controls.m_NearbyTeam.onValueChanged:AddListener(self.callbackNearbyTeamToogleOnValueChanged)
    
	self.callbackTeamplatformToogleOnValueChanged = function(on) self:ToogleOnValueChanged(on, self.toggleType.togTeamplatform) end
	self.Controls.m_Teamplatform.onValueChanged:AddListener(self.callbackTeamplatformToogleOnValueChanged)
    
	self.config =
	{
		self.Controls.m_Teamplatform,
		self.Controls.m_MyTeam,
		self.Controls.m_NearbyTeam,
	}
	    
    self:RegisterEvent()	
    if self.m_needCreateMyTeamPanel == true then
        self.m_needCreateMyTeamPanel = nil
        self:CreateMyTeamPanel()
    end
    
	self:OnEnable()
end

--预加载UI
function TeamWindow:LoadWidgetResourceAsys()
	
	rkt.IdleTimeTaskScheduler.ScheduleLuaCoroutine(self.LoadTeamPlaneWidget,0,2,"加载队伍平台界面")
	rkt.IdleTimeTaskScheduler.ScheduleLuaCoroutine(self.LoadMyTeamWidget,1,2,"加载我的队伍界面")
	rkt.IdleTimeTaskScheduler.ScheduleLuaCoroutine(self.LoadNearTeamWidget,1,2,"加载附近队伍界面")
end

--注册事件
function TeamWindow:RegisterEvent()
	
	rktEventEngine.SubscribeExecute( EVENT_TEAM_QUITTEAM , SOURCE_TYPE_TEAM , 0, self.QuitTeam)
	rktEventEngine.SubscribeExecute( EVENT_TEAM_CREATETEAM , SOURCE_TYPE_TEAM , 0 , self.CreateTeam)

end

function TeamWindow:OnDisable()
    
	self.targetID  = 0
	self.m_wantGotoType = nil
	if self.MyTeamWidget~= nil then 
		self.MyTeamWidget:OnDisable()
	end	
end

--创建队伍成功后注册事件
function TeamWindow:OnCreateTeam(event, srctype, srcid, eventData)
		--self.MyTeamWidget:SubscribeEvent()	
end

function TeamWindow:UnRegisterEvent()
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_QUITTEAM , SOURCE_TYPE_TEAM , 0, self.QuitTeam)
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_CREATETEAM , SOURCE_TYPE_TEAM , 0 , self.CreateTeam)
end

--退出队伍事件
function TeamWindow:OnQuitTeam(event, srctype, srcid, eventData)
	UIManager.TeamShowPanelWindow:Hide()
	UIManager.TeamShowPanelWindow:UnRegister()
	if UIManager.MainLeftCenterWindow:isLoaded()then 
		UIManager.MainLeftCenterWindow.Controls.m_TeamPanelWidget.gameObject:SetActive(true)
	end
	if UIManager.MainLeftTopWindow:isLoaded() then 
		UIManager.MainLeftTopWindow:SetTeamFlag(false)
		UIManager.MainLeftTopWindow:SyncFollowState(false)
	end

	if not self:isLoaded() then 
		return
	end
	self:ChangeMyTeamToggle(false)
	if 	self.WidgetConfigInfo[self.toggleType.togTeamplatform].widgetScript:isShow() then
		self.WidgetConfigInfo[self.toggleType.togTeamplatform].instantiate:SetActive(true)
	else
		self:FetchTeamWidget((self.toggleType.togTeamplatform))	
	end
	if nil ~= self.WidgetConfigInfo[self.toggleType.togMyTeam].instantiate then 
		self.WidgetConfigInfo[self.toggleType.togMyTeam].instantiate:SetActive(false)
	end
	
	self.Controls.m_myTeamToggleObj.gameObject:SetActive(false)
end

-- 同步玩家跟随状态
function TeamWindow:SyncTeamFollowState(dwPDBID,bFollowCaptain)
	if not self:isShow() then
		return
	end
	local tmpWidgetCfg = self.WidgetConfigInfo[self.toggleType.togMyTeam]
	if not tmpWidgetCfg or not tmpWidgetCfg.widgetScript then
		return
	end
	local pHero = GetHero()
	if not pHero or pHero:GetNumProp(CREATURE_PROP_PDBID) ~= dwPDBID then
		return
	end
	local bCaptain = IGame.TeamClient:IsTeamCaptain(dwPDBID)
	tmpWidgetCfg.widgetScript:RefreshFollowState(bCaptain, bFollowCaptain)
end

---------------------------------------------------------------
function TeamWindow:OnDestroy()
	
	for k,v in pairs(self.WidgetConfigInfo) do 
		v.haveFetch = false
		v.instantiate = nil
	end
	self:UnRegisterEvent()
	self.m_needCreateMyTeamPanel = nil
	UIWindow.OnDestroy(self)
end
---------------------------------------------------------------
--关闭按钮
function TeamWindow:OnCloseButtonClick() 
	UIManager.TeamWindow:Hide()
end
---------------------------------------------------------------
--组件启动时调用
function TeamWindow:OnEnable()

	local MyTeam = IGame.TeamClient:GetTeam()
    if MyTeam == nil then return end 
    
    if self.m_wantGotoType and self.m_wantGotoType > 0 then 
        self:ShowTeamWidgetByType(self.m_wantGotoType)
        self.currentToggleType = self.m_wantGotoType
        return
    end 
         
    if MyTeam:GetTeamID() == INVALID_TEAM_ID then
        self:ChangeMyTeamToggle(false)       
    else     
        self:ChangeMyTeamToggle(true)
    end  
end

---------------------------------------------------------------

function TeamWindow:ChangeMyTeamToggle(state)
    
	if not self:isLoaded() then 
		return
	end
    
	--self.Controls.m_myTeamToggleObj.gameObject:SetActive(state)
    
	if state == true then 
		self.currentToggleType = self.toggleType.togMyTeam
        self:ShowTeamWidgetByType(self.toggleType.togMyTeam)
		--self.Controls.m_MyTeam.gameObject:SetActive(true)
	else
        --self.Controls.m_MyTeam.gameObject:SetActive(false)
		self.currentToggleType = self.toggleType.togTeamplatform
		self:ShowTeamWidgetByType(self.toggleType.togTeamplatform)
	end
end

--创建我的队伍面板
function TeamWindow:CreateMyTeamPanel()
	
	if not self:isLoaded() then
        self.m_needCreateMyTeamPanel = true
        return
	end
	
	self.Controls.m_MyTeam.transform.gameObject:SetActive(true)
	self.Controls.m_Teamplatform.isOn = false
	self.Controls.m_MyTeam.isOn = true
	self.Controls.m_NearbyTeam.isOn = false
	if  self.WidgetConfigInfo[self.toggleType.togMyTeam].instantiate  == nil then 
		self:FetchTeamWidget(self.toggleType.togMyTeam)
	end
	if self.WidgetConfigInfo[self.toggleType.togTeamplatform].instantiate ~= nil then 
		self.WidgetConfigInfo[self.toggleType.togTeamplatform].instantiate:SetActive(false)
	end
	
	if self.WidgetConfigInfo[self.toggleType.togNearbyTeam].instantiate ~= nil then 
		self.WidgetConfigInfo[self.toggleType.togNearbyTeam].instantiate:SetActive(false)
	end

end
---------------------------------------------------------------


function TeamWindow:RefreshMyTeam()
	if not self:isLoaded() then 
        return
	end
	if  self.WidgetConfigInfo[self.toggleType.togMyTeam].instantiate  == nil then 
		self:FetchTeamWidget(self.toggleType.togMyTeam)
	else
		if self.WidgetConfigInfo[self.toggleType.togMyTeam].widgetScript:isShow() then 
			self.WidgetConfigInfo[self.toggleType.togMyTeam].widgetScript:RefreshUI()
		else
			self.WidgetConfigInfo[self.toggleType.togMyTeam].widgetScript:Show()
		end		
	end
end

--
function TeamWindow:ShowTeamWidgetByType(toggleType)
	
    if self.WidgetConfigInfo[toggleType] == nil then 
        uerror("界面显示异常-》TeamWindow:ShowTeamWidgetByType->toggleType = "..tostring(toggleType))
        return
    end 
	self.currentPanel =  self.WidgetConfigInfo[toggleType].instantiate
	self.Controls.m_Teamplatform.isOn = false
	self.Controls.m_MyTeam.isOn = false
	self.Controls.m_NearbyTeam.isOn = false
	
    self.Controls.m_myTeamToggleObj.gameObject:SetActive(false)
    
    if toggleType == self.toggleType.togTeamplatform then
        self.Controls.m_Teamplatform.isOn = true
    elseif toggleType == self.toggleType.togMyTeam then
        self.Controls.m_myTeamToggleObj.gameObject:SetActive(true)
        self.Controls.m_MyTeam.isOn = true       
    elseif toggleType == self.toggleType.togNearbyTeam then
        self.Controls.m_NearbyTeam.isOn = true       
    end 
	
	if nil ~= self.WidgetConfigInfo[self.toggleType.togMyTeam].instantiate then 
		self.WidgetConfigInfo[self.toggleType.togMyTeam].instantiate:SetActive(false)
	end 
	
	if nil ~= self.WidgetConfigInfo[self.toggleType.togTeamplatform].instantiate then 
		self.WidgetConfigInfo[self.toggleType.togTeamplatform].instantiate:SetActive(false)
	end
	
	if nil ~= self.WidgetConfigInfo[self.toggleType.togNearbyTeam].instantiate then 
		self.WidgetConfigInfo[self.toggleType.togNearbyTeam].instantiate:SetActive(false)
	end
    
	if nil ~= self.currentPanel then 
		self.currentPanel.gameObject:SetActive(true)
	else
		self.WidgetConfigInfo[toggleType].currentState =true
		self:FetchTeamWidget(toggleType)
	end
end


--创建队伍子界面
function TeamWindow:FetchTeamWidget(toogleType)
	if nil == self.WidgetConfigInfo[toogleType].instantiate then 
		if self.WidgetConfigInfo[toogleType].haveFetch ==true then 
			return
		end
		self.WidgetConfigInfo[toogleType].haveFetch = true
			--异步加载队伍平台
		rkt.GResources.FetchGameObjectAsync( self.WidgetConfigInfo[toogleType].path ,
			function ( path , obj , ud )
				if nil ==obj then   -- 判断U3D对象是否已经被销毁
					return
				end
				obj.transform:SetParent(self.transform,false)
				self.WidgetConfigInfo[toogleType].widgetScript:Attach(obj)
				if self.currentToggleType == toogleType then 
					obj:SetActive(true)
				else
					obj:SetActive(false)
				end
				self.WidgetConfigInfo[toogleType].instantiate = obj
			end , nil , AssetLoadPriority.GuiNormal )
	end
	
end

--组队进入平台指定的活动
function TeamWindow:GotoActivetyByID(targetID)
    
    if not targetID then return end 
    
	self.WidgetConfigInfo[self.toggleType.togTeamplatform].widgetScript:SelectTargetID(targetID)
	self.targetID = targetID 
	self.m_wantGotoType = self.toggleType.togTeamplatform
	UIWindow.Show(self,true)	
end

---------------------------------------------------------------
--当Toogle发生变化时监听改变
function TeamWindow:ToogleOnValueChanged(isOn , toogleType)
	if isOn then
		self.WidgetConfigInfo[toogleType].currentState = true
		self.currentToggleType = toogleType
		self.config[toogleType].transform:Find("On").gameObject:SetActive(true)
		self.config[toogleType].transform:Find("Off").gameObject:SetActive(false)
		if nil ~= self.WidgetConfigInfo[toogleType].instantiate then 
			self.WidgetConfigInfo[toogleType].instantiate:SetActive(true)
		else
			if self.WidgetConfigInfo[toogleType].haveFetch == false then 
				self:FetchTeamWidget(toogleType)
			end			
		end	

        if toogleType == self.toggleType.togTeamplatform or toogleType == self.toggleType.togNearbyTeam then  
            self.Controls.m_ctrlCommonBg.transform.gameObject:SetActive(false)
            self.Controls.m_ctrlLeftBg.transform.gameObject:SetActive(true)
            self.Controls.m_ctrlRightBg.transform.gameObject:SetActive(true)            
        else
            self.Controls.m_ctrlLeftBg.transform.gameObject:SetActive(false)
            self.Controls.m_ctrlRightBg.transform.gameObject:SetActive(false)             
            self.Controls.m_ctrlCommonBg.transform.gameObject:SetActive(true)            
        end
	else
		self.config[toogleType].transform:Find("On").gameObject:SetActive(false)
		self.config[toogleType].transform:Find("Off").gameObject:SetActive(true)	
		if nil ~= self.WidgetConfigInfo[toogleType].instantiate then 
			self.WidgetConfigInfo[toogleType].instantiate:SetActive(false)	
		end
		self.WidgetConfigInfo[toogleType].currentState = false		
        
        if toogleType == self.toggleType.togTeamplatform or toogleType == self.toggleType.togNearbyTeam then  
            self.Controls.m_ctrlCommonBg.transform.gameObject:SetActive(true)
            self.Controls.m_ctrlLeftBg.transform.gameObject:SetActive(false)
            self.Controls.m_ctrlRightBg.transform.gameObject:SetActive(false)            
        else
            self.Controls.m_ctrlLeftBg.transform.gameObject:SetActive(true)
            self.Controls.m_ctrlRightBg.transform.gameObject:SetActive(true)             
            self.Controls.m_ctrlCommonBg.transform.gameObject:SetActive(false)            
        end        
	end       
end
---------------------------------------------------------------

return TeamWindow
