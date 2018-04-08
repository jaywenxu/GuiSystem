-- 帮派历程窗口
-- @Author: XieXiaoMei
-- @Date:   2017-04-12 20:46:57
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-04 11:21:31

local ClanCourseWindow = UIWindow:new
{
	windowName        = "ClanCourseWindow",

	m_CourseList = {},
}


------------------------------------------------------------
function ClanCourseWindow:Init()
end

function ClanCourseWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	self:InitUI()

	self:RefreshUI()
    
    self:RefreshClanEvent()

end

function ClanCourseWindow:InitUI()
	local controls = self.Controls
	local scrollView = controls.m_ClanCourseScr

	local listView = scrollView:GetComponent(typeof(EnhanceDynamicSizeListView))
	listView.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
	listView.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)
	controls.listView = listView

    self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))

	local listScroller = scrollView:GetComponent(typeof(EnhancedScroller))
	controls.listScroller = listScroller

	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_BackBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
end

function ClanCourseWindow:Show(bringTop)
	UIWindow.Show(self, bringTop )

	self:RefreshUI()
        
end

function ClanCourseWindow:OnEnable()
    self:RefreshClanEvent()
end

function ClanCourseWindow:SubscribeWinExecute()
	
	-- 帮会事件更新
	self.m_OnUpdateEvent = handler(self, self.OnUpdateEvent)
	rktEventEngine.SubscribeExecute(EVENT_UPDATE_CLANEVENT, SOURCE_TYPE_CLAN, 0, self.m_OnUpdateEvent)
end

function ClanCourseWindow:UnSubscribeWinExecute()
	
	-- 帮会事件更新
	rktEventEngine.UnSubscribeExecute( EVENT_UPDATE_CLANEVENT, SOURCE_TYPE_CLAN, 0, self.m_OnUpdateEvent)
	self.m_OnUpdateEvent = nil
end

function ClanCourseWindow:RefreshClanEvent()
    IGame.ClanClient:RequestClanData(emClanRequestEventList)
end

function ClanCourseWindow:RefreshUI()
	if not self:isLoaded() then
		return 
	end

	local controls = self.Controls

	self.m_CourseList = IGame.ClanClient:GetClan():GetEventList() or {}
	controls.listView:SetCellCount( #self.m_CourseList , true )
	self:SetCellListSize()
	controls.listScroller:ReloadData()
end

function ClanCourseWindow:SetCellListSize()
	
	local DescTxt = self.Controls.m_CellDesc
	local nSpace  = 60
	for k, v in pairs(self.m_CourseList) do
		-- 计算Cell大小
		local Rect = rkt.UIAndTextHelpTools.GetRichTextSize(DescTxt, v.szCoutext)
		local nHeight = Rect.y
		
		-- 设置Cell大小
		self.Controls.listView:SetCellHeight(nHeight + nSpace, k - 1)
	end
end

-- EnhancedListView 一行被“创建”时的回调
function ClanCourseWindow:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView)
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function ClanCourseWindow:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function ClanCourseWindow:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end

--- 刷新列表
function ClanCourseWindow:RefreshCellItems( listcell )	
	local idx = listcell.dataIndex + 1

	local transform = listcell.transform
	transform.gameObject.name = string.format("ClanCourseCell-%d", idx)
	local getTextComponet = function (name)
		return transform:Find(name):GetComponent(typeof(Text))
	end

	local data = self.m_CourseList[idx]

	local dateTxt = getTextComponet("Date")
	local TimeTable = os.date("*t", data.nTime)
	dateTxt.text = tostring(TimeTable.year.."-"..TimeTable.month.."-"..TimeTable.day)

	local descTxt = getTextComponet("Desc")
	descTxt.text = data.szCoutext
end

function ClanCourseWindow:OnUpdateEvent()
	self:RefreshUI()
end

function ClanCourseWindow:OnBtnCloseClicked()
	self:Hide()
end

return ClanCourseWindow