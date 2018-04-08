
------------------------------------------------------------
-- MainHUDWindow 的子窗口,不要通过 UIManager 访问
-- 任务追踪器组件
------------------------------------------------------------

local TaskTrackerElementCellClass = require( "GuiSystem.WindowList.Task.TaskTrackerElementCell" )
------------------------------------------------------------
local TaskTrackerWidget = UIControl:new
{
	windowName = "TaskTrackerWidget",
	m_trackerListInfo = nil,
    
    isNeedUpdate = nil,
}

local this = TaskTrackerWidget   -- 方便书写


------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function TaskTrackerWidget:Attach( obj )
	UIControl.Attach(self,obj)
	self.Controls.TaskList = self.Controls.m_ItemList:GetComponent(typeof(EnhancedListView))
	self.callbackCreateRewardList = function(goCell) self:OnGetCellView(goCell) end
	self.Controls.TaskList.onGetCellView:AddListener(self.callbackCreateRewardList)
	
	self.callbackOnCellViewVisiable = function(goCell) self:OnCellViewVisiable(goCell) end
	self.Controls.TaskList.onCellViewVisiable:AddListener(self.callbackOnCellViewVisiable)
	self.Controls.listView = self.Controls.TaskList:GetComponent(typeof(EnhanceDynamicSizeListView))
	self.Controls.scroller =  self.Controls.m_ItemList:GetComponent(typeof(EnhancedScroller))
	self.Controls.richTextTemplate = self.Controls.listView.CellViewPrefab.transform:Find("TaskContent"):GetComponent(typeof(Text))
	
	-- 初始化个数为0
	self.Controls.TaskList:SetCellCount( 0 , true )
    
    if self.isNeedUpdate  then
        self.isNeedUpdate = false
        self:UpdateAllTaskTracker()
    end
	return self
end

function TaskTrackerWidget:OnDestroy()
	self.m_trackerListInfo = nil
end

--------------------------------------------------------------------------------
-- EnhancedListView 一行被“创建”时的回调
function TaskTrackerWidget:OnGetCellView(goCell)
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView)
	self:createCell( listcell )
end

-- EnhancedListView 一行强制刷新时的回调
function TaskTrackerWidget:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:UpdateTaskTrackerScroll(listcell)
end

function TaskTrackerWidget:RefreshCellItems( goCell )
		local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
		self:UpdateTaskTrackerScroll( listcell )
end

--------------------------------------------------------------------------------
-- EnhancedListView 一行可见时的回调
function TaskTrackerWidget:OnCellViewVisiable(goCell)
	
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:UpdateTaskTrackerScroll( listcell )
end

-----------------------------------------------------------
-- 设置父窗口
function TaskTrackerWidget:SetParentWindow(win)
	self.m_ParentWindow = win
end

-----------------------------------------------------------
-- 回收所有的对象
function TaskTrackerWidget:RecycleGameObject()
	
	-- 回收任务追踪表
	local pTrackerList = self.Controls.m_trackerGroup
	if pTrackerList and pTrackerList.transform  then
		local nCount = pTrackerList.transform.childCount
		if nCount >= 1 then
			local tmpTable = {}
			for i = 1, nCount, 1 do
				table.insert(tmpTable,pTrackerList.transform:GetChild(i-1).gameObject)
			end
			for i, v in pairs(tmpTable) do
				rkt.GResources.RecycleGameObject(v)
			end
		end
	end
end

------------------------------------------------------------
-- 更新所有任务追踪列表
function TaskTrackerWidget:UpdateAllTaskTracker()
	if not self:isLoaded() then
        self.isNeedUpdate = true
		return
	end
	self.m_trackerListInfo = IGame.TaskSick:GetTaskTrackerList()

	if not self.m_trackerListInfo then
		return
	end

	self.Controls.TaskList:SetCellCount( table_count(self.m_trackerListInfo) , true )
	local  index =0
	for i,v in pairs( self.m_trackerListInfo) do
		local taskTrackerInfo = self.m_trackerListInfo[i]
		local height = 0
		local info = IGame.TaskSick:GetShowText(taskTrackerInfo)
		height = self:CalcHeight(info) + 46
		self.Controls.listView:SetCellHeight(height,index)
		index = index+1
	end
	
	self.Controls.scroller:ReloadData()
	
	-- 自动跳到第一行
	-- self.Controls.scroller:JumpToDataIndex( 0 , 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0.2 , nil)
end

	
-- toggle 组
function TaskTrackerWidget:ParseItemInfo(trackerInfo)
	
	if type(trackerInfo) ~= 'table' then
		return nil
	end
	if trackerInfo[3] == nil then
		return nil
	end

	local m_sztaskname = trackerInfo[2] or ""
	local tracker = trackerInfo[3]
	
	-- 字符串中，以"<a href="开头，">"结尾作为函数解析
	local szTracker,matchList = lua_GetStrAndMatchSubList(tracker, "<a href=",">")
	local m_szTracker = szTracker or ""
	return m_sztaskname .. m_szTracker
end
-----------------------------------------------------------
function TaskTrackerWidget:UpdateItemInfo(taskid, trackerInfo)

	if not trackerInfo then
		return
	end
	self.m_trackInfo = trackerInfo
	for i,v in pairs(trackerInfo) do
		if type(v) == 'table' then
		return self:ParseItemInfo(v)
	
		end
	end
	
end	

------------------------------------------------------------
-- 创建cell
function TaskTrackerWidget:createCell(goCell)
	if not self.m_trackerListInfo then
		return
	end
	local listcell_trans = goCell.transform	
	local cellIndex = goCell.dataIndex 
	local pToggleGroup = self.Controls.m_trackerGroup.transform:GetComponent(typeof(ToggleGroup))
	local item = TaskTrackerElementCellClass:new({})
	item:Attach(goCell.gameObject)
	item:SetToggleGroup( pToggleGroup )	
end

------------------------------------------------------------
-- 更新任务追踪列表
function TaskTrackerWidget:UpdateTaskTrackerScroll(goCell)
	--local pTrackerList = IGame.TaskSick:GetTaskTrackerList()
	if not self.m_trackerListInfo then
		return
	end
	local dataIndex = goCell.dataIndex
	local taskTrackerInfo = self.m_trackerListInfo[dataIndex+1]
	if nil ~= goCell.gameObject then
		local behav = goCell:GetComponent(typeof(UIWindowBehaviour))
		if nil ~= behav then
			local item = behav.LuaObject
			if nil ~= item then
				item:UpdateItemInfo(i,taskTrackerInfo)
			end
		end
	end
end

function TaskTrackerWidget:CalcHeight(content)
	
	return rkt.UIAndTextHelpTools.GetRichTextSize(self.Controls.richTextTemplate,content).y
	
end

-- 更新任务追踪列表
function TaskTrackerWidget:UpdateTaskTracker(nTaskID, taskTrackerInfo, nCRC, accept)	
	self:UpdateAllTaskTracker()
	
end

------------------------------------------------------------
-- 删除任务追踪信息
function TaskTrackerWidget:DeleteTaskTracker(nTaskID)
	self:UpdateAllTaskTracker()
end

------------------------------------------------------------

return this