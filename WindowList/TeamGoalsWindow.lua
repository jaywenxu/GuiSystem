--队伍目标窗口
------------------------------------------------------------
local LevelCellCalss = require("GuiSystem.WindowList.Team.LevelCell")
local TeamGoalActiveCellClass = require("GuiSystem.WindowList.Team.TeamGoalActiveCell")
------------------------------------------------------------
local TeamGoalsWindow = UIWindow:new
{
	windowName          = "TeamGoalsWindow" ,

	m_currentHuodongArr	= {},	                -- 目标信息
	fromeListView 	    = nil,
	toListView          = nil,
	
	m_indexJump         = 2,	
	m_currentTarget     = 0,                    -- 当前选中目标
	expectLowLevel      = 0,                    -- 等级下限
	expectHighLevel     = 0,                    -- 等级上限
    m_lowLevel          = 0,
}
------------------------------------------------------------
function TeamGoalsWindow:Init()

end
------------------------------------------------------------
function TeamGoalsWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	--将UI前移以便遮挡住后层的3D模型
	self.callBackOnCloseButtonClick = function() self:OnCloseButtonClick() end
	self.Controls.m_CloseButton.onClick:AddListener(self.callBackOnCloseButtonClick)
	
	self.callBackOnOkButtonClick = function() self:OnOkButtonClick() end
	self.Controls.m_OkButton.onClick:AddListener(self.callBackOnOkButtonClick)
	
	self.callBackOnGetCellView = function(objCell) self:OnGetFromCellView(objCell) end
	self.callBackOnCellViewVisiable =  function(objCell) self:OnGetVisiableFromCellView(objCell) end    
	self.fromeListView  = 	self.Controls.m_FromLevelPanel:GetComponent(typeof(EnhancedListView))
	self.fromeListView.onGetCellView:AddListener(self.callBackOnGetCellView)
	self.fromeListView.onCellViewVisiable:AddListener(self.callBackOnCellViewVisiable)
	
	self.callBackOnGetToCellView = function(objCell) self:OnGetToCellView(objCell) end
	self.callBackOnVisiableToCellView = function(objCell) self:OnGetVisiableToCellView(objCell) end    
	self.toListView = self.Controls.m_ToLevelPanel :GetComponent(typeof(EnhancedListView))
	self.toListView.onGetCellView:AddListener(self.callBackOnGetToCellView)
	self.toListView.onCellViewVisiable:AddListener(self.callBackOnVisiableToCellView)
	
	self.Controls.TargetEnhanceGroup = self.Controls.m_TeamEventList:GetComponent(typeof(ToggleGroup))
    
	--活动目标
	self.callBackOnGetTargetCellView = function(objCell) self:OnGetTarGetCellView(objCell) end
	self.callBackOnCellTargetVisiable = function(objCell) self:TarGetCellVisiable(objCell) end
	self.enhanceListView = self.Controls.m_TeamEventList:GetComponent(typeof(EnhancedListView))
	if nil ~= self.enhanceListView then 
		self.enhanceListView.onGetCellView:AddListener(self.callBackOnGetTargetCellView)
		self.enhanceListView.onCellViewVisiable:AddListener(self.callBackOnCellTargetVisiable)
	end


	local m_EnhancedScroller = self.Controls.m_FromLevelPanel:GetComponent(typeof(EnhancedScroller))
	self.callbackScrollerSnapped = function(scroller,cellIndex,dataIndex) self:OnScrollerSnapped(scroller,cellIndex,dataIndex) end
	if nil ==  m_EnhancedScroller.scrollerSnapped then
		m_EnhancedScroller.scrollerSnapped = self.callbackScrollerSnapped
	else
		m_EnhancedScroller.scrollerSnapped = m_EnhancedScroller.scrollerSnapped + self.callbackScrollerSnapped
	end
	self.unityBehaviour.onEnable:AddListener(function() self:OnEnable() end) 
	self.unityBehaviour.onDisable:AddListener(function() self:OnDisable() end)

	self:OnEnable()
	
	return self
end

function TeamGoalsWindow:OnGetVisiableFromCellView(objCell)
	local cell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))
	local behav = objCell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	local item = behav.LuaObject	
	item:SetLevel(cell.dataIndex+self.m_lowLevel)
	local m_EnhancedListViewCell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))
	if m_EnhancedListViewCell.dataIndex == self.toListView.CellCount-1 then 
		self.FromCellHaveGet =true
		if self.ToCellHaveGet == true and self.needJump == true then 
			local fromScroller = self.Controls.m_FromLevelPanel:GetComponent(typeof(EnhancedScroller))
			local toScroller = self.Controls.m_ToLevelPanel:GetComponent(typeof(EnhancedScroller))	
			fromScroller:JumpToDataIndex(self.expectLowLevel, 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0 , nil)
			toScroller:JumpToDataIndex(self.expectHighLevel, 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0 , nil) 
			self.needJump =false
		end
	end
end

function TeamGoalsWindow:OnGetVisiableToCellView(objCell)
	local cell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))
	local behav = objCell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	local item = behav.LuaObject	
	item:SetLevel(cell.dataIndex+self.m_lowLevel)
	local m_EnhancedListViewCell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))
	if m_EnhancedListViewCell.dataIndex == self.fromeListView.CellCount-1 then 
		self.ToCellHaveGet =true
		if self.FromCellHaveGet == true and self.needJump == true then 
			local fromScroller = self.Controls.m_FromLevelPanel:GetComponent(typeof(EnhancedScroller))
			local toScroller = self.Controls.m_ToLevelPanel:GetComponent(typeof(EnhancedScroller))	
			fromScroller:JumpToDataIndex(self.expectLowLevel, 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0 , nil)
			toScroller:JumpToDataIndex(self.expectHighLevel, 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0 , nil) 
			self.needJump =false
		end
	end
end

--活动目标cellcreat
function TeamGoalsWindow:OnGetTarGetCellView(objCell)
    
	local activeTargetClass = TeamGoalActiveCellClass:new()
	activeTargetClass:Attach(objCell)
	local viewCell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))
	if nil == viewCell then 
		return
	end
    
	local toggle = objCell.transform:GetComponent(typeof(Toggle))	
	toggle.group = self.Controls.TargetEnhanceGroup	
end

--点击目标标签页
function TeamGoalsWindow:GotoCurrentActiveID(TargetID)
    
    if not GetHero() then return end 
    
	self.m_currentTarget = TargetID
	local level = GetHero():GetNumProp(CREATURE_PROP_LEVEL)

	local LowLevel  = 0
	local HighLevel = 0

	if self.m_currentTarget == 0 then 
		self.expectLowLevel = 1
		self.expectHighLevel = 150
        LowLevel  = 1
        HighLevel = 150
	else		
		local targetInfo = IGame.rktScheme:GetSchemeInfo(TEAMTARGET_CSV, self.m_currentTarget)
        if targetInfo == nil or targetInfo.ActivityMinLv > level or level > targetInfo.ActivityMaxLv then 
            return 
        end 

		LowLevel = targetInfo.ActivityMinLv
		HighLevel = targetInfo.ActivityMaxLv
		self.expectLowLevel = math.max(level-targetInfo.lLowLv,LowLevel)
		self.expectHighLevel = math.min(level+targetInfo.lHighLv,HighLevel) 
	end

	self.expectHighLevel = self.expectHighLevel-self.m_indexJump-LowLevel

	
	if self.expectLowLevel-self.m_indexJump < LowLevel then 
		self.expectLowLevel = self.expectLowLevel-self.m_indexJump-LowLevel + HighLevel-LowLevel+1
	else
		self.expectLowLevel =  self.expectLowLevel-self.m_indexJump-LowLevel
	end
	self.FromCellHaveGet =false
	self.ToCellHaveGet =false
    self.m_lowLevel = LowLevel

	local count = HighLevel - LowLevel+1
	self.needJump = true 

	local fromScroller = self.Controls.m_FromLevelPanel:GetComponent(typeof(EnhancedScroller))
	local toScroller = self.Controls.m_ToLevelPanel:GetComponent(typeof(EnhancedScroller))    
	if self.fromeListView.CellCount ~= count then 
		self.fromeListView:SetCellCount( count , true )
	else
		fromScroller:JumpToDataIndex(self.expectLowLevel, 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0 , nil)
		fromScroller:RefreshActiveCellViews()
	end
	if self.toListView.CellCount ~= count then 
		self.toListView:SetCellCount( count , true )		
	else
		toScroller:JumpToDataIndex(self.expectHighLevel, 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0 , nil) 
		toScroller:RefreshActiveCellViews()		
	end
end


--活动目标CellVisiable
function TeamGoalsWindow:TarGetCellVisiable(objCell)
    
	local viewCell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))
	
	local behav = objCell:GetComponent(typeof(UIWindowBehaviour))
	if nil ~= behav then
		local item = behav.LuaObject	

		if viewCell.cellIndex == 0 then 
			item:SetName("全部")
			item:SetActiveID(0)
		else
			item:SetName(self.m_currentHuodongArr[viewCell.cellIndex].ActivityName)
			item:SetActiveID(self.m_currentHuodongArr[viewCell.cellIndex].lTargetID)
		end
        
		if (self.m_currentTarget == 0 and viewCell.cellIndex == 0) or	
		  (self.m_currentHuodongArr[viewCell.cellIndex] ~= nil and self.m_currentTarget == self.m_currentHuodongArr[viewCell.cellIndex].lTargetID) then
			local toggle = objCell.transform:GetComponent(typeof(Toggle)) 
			toggle.isOn = true
		end
	end	
end
------------------------------------------------------------
function TeamGoalsWindow:OnDestroy()
	--self.Controls.m_CloseButton.onClick:RemoveListener(self.callBackOnCloseButtonClick)
	--self.Controls.m_OkButton.onClick:RemoveListener(self.callBackOnOkButtonClick)
	
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------
function TeamGoalsWindow:OnCloseButtonClick() 
	UIManager.TeamGoalsWindow:Hide()
end
------------------------------------------------------------
function TeamGoalsWindow:OnOkButtonClick()
        
    if not self.m_currentTarget or self.m_currentTarget < 0 then 
        return 
    end 
    
	local FromcontainTrs = self.Controls.m_FromLevelPanel:Find("Container")
	local FromvalTrs = FromcontainTrs:GetChild(self.m_indexJump+2)
	
	local TocontainTrs = self.Controls.m_ToLevelPanel:Find("Container")
	local TovalTrs = TocontainTrs:GetChild(self.m_indexJump+2)
	
    if not FromvalTrs or not TovalTrs then 
        return 
    end 
    
	local fromLevel = 0
	local toLevel   = 0
    local FromtextObj = FromvalTrs:Find("Text")
    if FromtextObj ~= nil then 
        local textName = FromtextObj:GetComponent(typeof(Text))
        fromLevel = tonumber(textName.text)
    end
    
    local ToObj = TovalTrs:Find("Text")
    if ToObj ~= nil then 
        local textName = ToObj:GetComponent(typeof(Text))
        toLevel = tonumber(textName.text)
    end
			
	if fromLevel > toLevel then
        fromLevel, toLevel = toLevel, fromLevel
	end

    if self.m_currentTarget == 0 then 
        -- 目标为0时设置队伍目标
        IGame.TeamClient:ChangeTeamTarget(self.m_currentTarget, fromLevel, toLevel)
    else 
        -- 目标大于0时
        cLog("队伍系统----TeamGoalsWindow:OnOkButtonClick->self.m_currentTarget, fromLevel, toLevel = "..self.m_currentTarget..","..fromLevel..","..toLevel)
        IGame.TeamClient:ReqAutoMatchTeam(emQMT_Team, self.m_currentTarget, fromLevel, toLevel)
    end

	UIManager.TeamGoalsWindow:Hide()
end
------------------------------------------------------------
--某一项被创建时的回调
function TeamGoalsWindow:OnGetFromCellView(objCell) 
    
	--关联一个Cell项和一个Levelcell模块
	local item = LevelCellCalss:new()
	item:Attach(objCell)	
end


function TeamGoalsWindow:OnGetToCellView(objCell)
    
	--关联一个Cell项和一个Levelcell模块
	local item = LevelCellCalss:new()
	item:Attach(objCell)
end
------------------------------------------------------------
--监听ScrollerSnapped事件 滚动条归位事件
function TeamGoalsWindow:OnScrollerSnapped(scroller,cellIndex,dataIndex)
	--print(cellIndex)
	--print(dataIndex)
end
------------------------------------------------------------

--队伍目标窗口Enable事件
function TeamGoalsWindow:OnEnable() 
	--每次启动时访问TeamTarget表，获取相应的TargetID，并访问HuodongWindow表，获取相应的目标名称和等级
	local teamTargetTable = IGame.rktScheme:GetSchemeTable(TEAMTARGET_CSV)
	local level = GetHero():GetNumProp(CREATURE_PROP_LEVEL)

	self.m_currentHuodongArr={}
	local cout = 1
	for k, item in pairs(teamTargetTable) do
        if item.ActivityMinLv <= level and level <= item.ActivityMaxLv then 
            cout = cout+1
            table.insert(self.m_currentHuodongArr, item)
        end 
	end
	
	self.enhanceListView:SetCellCount( cout , true )
	self:GotoCurrentActiveID(self.m_currentTarget)	
end

------------------------------------------------------------
function TeamGoalsWindow:OnDisable() 

end
------------------------------------------------------------
function TeamGoalsWindow:OnTeamGoalActiveCellButtonClick(LowLv, HighLv, targetID)

	
end
------------------------------------------------------------
return TeamGoalsWindow