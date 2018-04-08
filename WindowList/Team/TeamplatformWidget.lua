--组队平台界面
------------------------------------------------------------
local TeamWindowClass = require("GuiSystem.WindowList.TeamWindow")
local TeamListCellClass =  require("GuiSystem.WindowList.Team.TeamListCell")
local TargetToggle =  require("GuiSystem.WindowList.Team.TargetToggleCell")
---------------------------------------------------------------
local TeamplatformWidget = UIControl:new
{
	windowName      = "TeamplatformWidget",
    haveDoEnable    = false,
    
	currentTargetID = 0,                -- 当前目标	
	m_refreshLastClickTime = 0,         -- 上次刷新时间
}

function TeamplatformWidget:Attach( obj )
	UIControl.Attach(self,obj)
	
    --刷新按钮
	self.callBackOnRefreshButtonClick = function() self:OnRefreshBtnClick(true) end
	self.Controls.m_RefreshButton.onClick:AddListener(self.callBackOnRefreshButtonClick)
	
    --自动匹配
	self.autoMatchTeam = function() self:OnAutoMatchTeamClick() end
	self.Controls.m_AutoMatchButton.onClick:AddListener(self.autoMatchTeam)
		
    --取消自动匹配
	self.DisautoMatchTeam = function() self:OnCancelAutoMatchTeamClick() end
	self.Controls.m_disAutoMatchBtn.onClick:AddListener(self.DisautoMatchTeam)
	
    --创建队伍
	self.callBackOnCreateTeamButtonClick = function() self:OnCreateTeamButtonClick() end
	self.Controls.m_CreateTeamButton.onClick:AddListener(self.callBackOnCreateTeamButtonClick)
    
    --离开队伍按钮
	self.LeavFun = function() self:OnClickLeaveTeamBtn() end
	self.Controls.m_leaveTeamBtn.onClick:AddListener(self.LeavFun)    
	
	self.callBackOnGetCellView = function(objCell) self:OnGetCellView(objCell) end
	local enhanceListView = self.Controls.m_TeamListScroller:GetComponent(typeof(EnhancedListView))
	enhanceListView.onGetCellView:AddListener(self.callBackOnGetCellView)
	self.callBackTargetTeamCellVis = function(objCell) self:OnGetTargetCellTeamVisiable(objCell) end
	enhanceListView.onCellViewVisiable:AddListener(self.callBackTargetTeamCellVis)
		
	--活动目标项	
	self.targetEnhanceListView = self.Controls.m_TargetListScroller:GetComponent(typeof(EnhancedListView))
	self.callbackOnTargetGetCellView = function(objCell) self:OnTargetGetCellView(objCell) end
	self.targetEnhanceListView.onGetCellView:AddListener(self.callbackOnTargetGetCellView)
		
	self.callBackOnRefreshCellView = function(objCell) self:OnRefreshToggleCellView(objCell) end
	self.targetEnhanceListView.onCellViewVisiable:AddListener(self.callBackOnRefreshCellView)
	self.Controls.TargetEnhanceGroup = self.Controls.m_toggleGroup:GetComponent(typeof(ToggleGroup))
	
	self.callbackOnEnable = function() self:OnEnable() end
	self.unityBehaviour.onEnable:AddListener(self.callbackOnEnable) 	
    
	self.callbackOnDisable = function() self:OnDisable() end
	self.unityBehaviour.onDisable:AddListener(self.callbackOnDisable) 
	
    self:OnEnable()
    
	return self
end

--监听事件
function TeamplatformWidget:SubControlExecute()
	self.SearchTeamList = function(event, srctype, srcid,eventData) self:RefreshTargetTeamContent(eventData) end
	rktEventEngine.SubscribeExecute( EVENT_TEAM_QUERY_BY_TARGET , SOURCE_TYPE_TEAM , 0 , self.SearchTeamList)
    
    -- 订阅退出队伍事件
	self.EventQuitTeam = function(event, srctype, srcid, eventData) self:OnEventQuitTeam(eventData) end 
	rktEventEngine.SubscribeExecute( EVENT_TEAM_QUITTEAM , SOURCE_TYPE_TEAM , 0, self.EventQuitTeam)
    
    -- 订阅创建（加入）队伍事件
    self.EventJoinTeam = function(event, srctype, srcid, eventData) self:OnEventJoinTeam(eventData) end 
	rktEventEngine.SubscribeExecute( EVENT_TEAM_CREATETEAM , SOURCE_TYPE_TEAM , 0, self.EventJoinTeam)    
    
    -- 订阅匹配状态刷新事件
    self.EventUpdateMatchState = function(event, srctype, srcid, eventData) self:OnEventUpdateMatchState(eventData) end 
    rktEventEngine.SubscribeExecute(EVENT_TEAM_MATCHSTATE_UPDATE, SOURCE_TYPE_TEAM, 0, self.EventUpdateMatchState)
end

function TeamplatformWidget:UnSubControlExecute()
    
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_QUERY_BY_TARGET , SOURCE_TYPE_TEAM , self.currentTargetID , self.SearchTeamList)
    
    -- 取消订阅退出队伍事件
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_QUITTEAM , SOURCE_TYPE_TEAM , 0, self.EventQuitTeam)
    
    -- 取消订阅创建（加入）队伍事件
	rktEventEngine.UnSubscribeExecute( EVENT_TEAM_CREATETEAM , SOURCE_TYPE_TEAM , 0, self.EventJoinTeam)    
    
    -- 取消订阅匹配状态刷新事件
    rktEventEngine.UnSubscribeExecute( EVENT_TEAM_MATCHSTATE_UPDATE, SOURCE_TYPE_TEAM, 0, self.EventUpdateMatchState)
end


-- 匹配状态刷新
function TeamplatformWidget:OnEventUpdateMatchState(eventData)
    
    self:UpdateAllBtnState()
end

-- 退出队伍事件回调
function TeamplatformWidget:OnEventQuitTeam(eventData)
    
    if not self:isLoaded() or not self:isShow() then 
        return 
    end
    
	self:OnRefreshBtnClick()  
  
    self.Controls.m_leaveBtnTrs.gameObject:SetActive(false)
    self.Controls.m_createTeamTrs.gameObject:SetActive(true)       
end

-- 加入队伍事件回调
function TeamplatformWidget:OnEventJoinTeam(eventData)
    
    if not self:isLoaded() or not self:isShow() then 
        return 
    end
    
    self:UpdateAllBtnState()
end

-- 点击取消匹配按钮回调
function TeamplatformWidget:OnCancelAutoMatchTeamClick()
        
    local hero = GetHero()
    if not hero then return end 
    
    IGame.TeamClient:ReqCancelAutoMatchTeam(emQMT_Player)   
end

-- 点击自动匹配队伍按钮回调
function TeamplatformWidget:OnAutoMatchTeamClick()
        
    local hero = GetHero()
    if not hero then return end 
    
    if not self.currentTargetID or self.currentTargetID <= 0 then 
        return
    end 

    IGame.TeamClient:ReqAutoMatchTeam(emQMT_Player, self.currentTargetID, hero:GetNumProp(CREATURE_PROP_LEVEL), hero:GetNumProp(CREATURE_PROP_LEVEL))    
end

-- 点击离开队伍按钮回调
function TeamplatformWidget:OnClickLeaveTeamBtn()
    
	IGame.TeamClient:LeaveTeam()
end

-- 点击创建队伍按钮回调
function TeamplatformWidget:OnCreateTeamButtonClick()
    
    IGame.TeamClient:CreateTeam(self.currentTargetID)
end

-- 点击刷新按钮回调
function TeamplatformWidget:OnRefreshBtnClick(needCheck)
    
	if needCheck then 
        local IntervalTime = 3                -- 刷新间隔时间
		if not UIFunction.CheckOftenClick(self.m_refreshLastClickTime,IntervalTime) then 
			return
		end
		self.m_refreshLastClickTime = Time.realtimeSinceStartup
	end
    
	local enhanceListView = self.Controls.m_TeamListScroller:GetComponent(typeof(EnhancedListView))
	enhanceListView:SetCellCount( 0 , true )
	local targetEnhanceListView = self.Controls.m_TargetListScroller:GetComponent(typeof(EnhancedListView))
    
	--设置所有活动目标
	--每次启动时访问TeamTarget表，获取相应的TargetID，并访问HuodongWindow表，获取相应的目标名称和等级
	local teamTargetTable = IGame.rktScheme:GetSchemeTable(TEAMTARGET_CSV)
	self.tempTable = {}
	local level = GetHero():GetNumProp(CREATURE_PROP_LEVEL)
	for k,v in pairs(teamTargetTable) do
        if v.ActivityMinLv <= level and level <= v.ActivityMaxLv then
			local item = IGame.rktScheme:GetSchemeInfo(HUODONGWINDOW_CSV, v.lHuoDongID)
			if nil ~= item then
				table.insert(self.tempTable, {Name  = v.ActivityName, TargetID = v.lTargetID,})
			end            
        end          
	end
    
	targetEnhanceListView:SetCellCount( 0 , true )
	targetEnhanceListView:SetCellCount( #self.tempTable+1 , true )
end

-- 刷新所有按钮状态
function TeamplatformWidget:UpdateAllBtnState()
    
    if not self:isLoaded() then return end 
    
    if IGame.TeamClient:GetHeroTeamID() > 0 then 
		self.Controls.m_leaveBtnTrs.gameObject:SetActive(true)
		self.Controls.m_createTeamTrs.gameObject:SetActive(false)    

        self.Controls.m_disAutoMatchImage.gameObject:SetActive(false)
        self.Controls.m_autoMatchImage.gameObject:SetActive(true)
        UIFunction.SetImgComsGray(self.Controls.m_autoMatchImage,true)
    else
		self.Controls.m_leaveBtnTrs.gameObject:SetActive(false)
		self.Controls.m_createTeamTrs.gameObject:SetActive(true)   

        if IGame.TeamClient:HeroIsAutoMatching() then 
            self.Controls.m_autoMatchImage.gameObject:SetActive(false)            
            self.Controls.m_disAutoMatchImage.gameObject:SetActive(true)     
        else 
            self.Controls.m_autoMatchImage.gameObject:SetActive(true)
            UIFunction.SetImgComsGray(self.Controls.m_autoMatchImage,false)
            self.Controls.m_disAutoMatchImage.gameObject:SetActive(false)        
        end
    end    
end 

--刷新查询到的目标队伍
function TeamplatformWidget:RefreshTargetTeamContent(info)
	local enhanceListView = self.Controls.m_TeamListScroller:GetComponent(typeof(EnhancedListView))
	--判断是否是我查询的targetID
	if self.currentTargetID == info.nTeamTargetID then 
		
		local targetListTeamInfo = IGame.TeamClient:GetQueryTeamList(info.nTeamTargetID)
		if nil ~= targetListTeamInfo then 
			local cout = table.getn(targetListTeamInfo)
			enhanceListView:SetCellCount( cout , true )
		else
			enhanceListView:SetCellCount( 0 , true )
		end
		local MyTeam = IGame.TeamClient:GetTeam()
		local haveTeam = MyTeam:GetTeamID() ~= INVALID_TEAM_ID
		--0为全部（需要将自动匹配按钮置灰）
		if self.currentTargetID == 0 or  haveTeam == true then
			self:SetAutoMatchBtnGray(true)
		else
			self:SetAutoMatchBtnGray(false)
		end
	end
end


function TeamplatformWidget:SetAutoMatchBtnGray(state)
	UIFunction.SetImgComsGray(self.Controls.m_autoMatchImage,state)
	
end

-- 显示回调
function TeamplatformWidget:OnEnable()
	
    if self.haveDoEnable == false then 
        self:UpdateAllBtnState()
		self:OnRefreshBtnClick() 
		self.haveDoEnable = true
	end	
end

-- 隐藏回调
function TeamplatformWidget:OnDisable()
	self.haveDoEnable = false	
end

--当目标队伍中的某一项可见时
function TeamplatformWidget:OnGetTargetCellTeamVisiable(objCell)
	local viewCell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))
	local behav = objCell:GetComponent(typeof(UIWindowBehaviour))
	if nil ~= behav then
		local item = behav.LuaObject	
		local info = IGame.TeamClient:GetQueryTeam(self.currentTargetID, viewCell.cellIndex+1)
		item:RefreshCellUI(info)
	end

end

---------------------------------------------------------------
--某一项被创建时的回调
function TeamplatformWidget:OnGetCellView(objCell) 
	local item = TeamListCellClass:new()
	item:Attach(objCell)
end
---------------------------------------------------------------
--toggle活动列表刷新可见时
function TeamplatformWidget:OnRefreshToggleCellView(objCell) 
	local viewCell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))
	local behav = objCell:GetComponent(typeof(UIWindowBehaviour))
	if nil == viewCell then 
		return
	end
	if viewCell.cellIndex < 0 then
		return
	end
	if behav ~= nil then 
		local item = behav.LuaObject
		if viewCell.cellIndex == 0 then 
			item:Refresh("全部",0, self.currentTargetID)
		else
			item:Refresh(self.tempTable[viewCell.cellIndex].Name,self.tempTable[viewCell.cellIndex].TargetID,self.currentTargetID)
		end		
	end	
end

--活动目标项创建调用
function TeamplatformWidget:OnTargetGetCellView(objCell) 
	local viewCell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))
	if nil == viewCell then 
		return
	end
    
	local toggleItem = TargetToggle:new()
	toggleItem:Attach(objCell)
	toggleItem:SetToggleGroup(self.Controls.TargetEnhanceGroup)	
end

--跳转到指定的ID类型
function TeamplatformWidget:SelectTargetID(targetID)
	self.currentTargetID = targetID	
end

-- 卸载
function TeamplatformWidget:OnDestroy()
	
	self.Controls.m_RefreshButton.onClick:RemoveListener(self.callBackOnRefreshButtonClick)
    
	self.Controls.m_CreateTeamButton.onClick:RemoveListener(self.callBackOnCreateTeamButtonClick)
    self.Controls.m_leaveTeamBtn.onClick:RemoveListener(self.LeavFun)
    
    self.Controls.m_AutoMatchButton.onClick:RemoveListener(self.autoMatchTeam)
    self.Controls.m_disAutoMatchBtn.onClick:RemoveListener(self.DisautoMatchTeam)
	
	self.Controls.m_TeamListScroller:GetComponent(typeof(EnhancedListView)).onGetCellView:RemoveListener(self.callBackOnGetCellView)
	self.Controls.m_TeamListScroller:GetComponent(typeof(EnhancedListView)).onGetCellView:RemoveListener(self.callbackOnTargetGetCellView)
	
	self.unityBehaviour.onEnable:RemoveListener(self.callbackOnEnable) 
	UIControl.OnDestroy(self)
end

return TeamplatformWidget