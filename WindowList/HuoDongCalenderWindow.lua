--/******************************************************************
---** 文件名:	HuoDongCalenderWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-02-22
--** 版  本:	1.0
--** 描  述:	活动推送设置窗口
--** 应  用:  
--******************************************************************/

local HuoDongCalenderItemClass = require( "GuiSystem.WindowList.HuoDong.ActivityCalender.HuoDongCalenderItemCell" )
local ItemFocusImage = AssetPath.TextureGUIPath.."Common_frame/Common_shanglanxzt.png"

local tNormalTxtColor = Color.New(0.32, 0.48, 0.6)
local tFocusTxtColor  = Color.New(0.8,0.48, 0.26)

local HuoDongCalenderWindow = UIWindow:new
{
	windowName = "HuoDongCalenderWindow",
	m_CalenderMgr = nil,
}

function HuoDongCalenderWindow:Init()
	self.CalenderTips = require( "GuiSystem.WindowList.HuoDong.ActivityCalender.HuoDongCalenderTips"):new()
end

function HuoDongCalenderWindow:OnAttach(obj)
	UIWindow.OnAttach(self,obj)
	
	self.CalenderTips:Attach(self.Controls.m_ActivityInfo.gameObject)
	
	self.callbackCloseClick = function() self:OnCloseClick() end
	self.Controls.m_Close.onClick:AddListener(self.callbackCloseClick)
	
	self.callbackOnClick = function() self:OnActWindowClick() end
	self.Controls.m_infoClose.onClick:AddListener(self.callbackOnClick)
	
	self.Controls.ActivityList = self.Controls.m_ItemList:GetComponent(typeof(EnhancedListView))
	self.callbackCreateActivityList = function(goCell) self:OnGetCellView(goCell) end
	self.Controls.ActivityList.onGetCellView:AddListener(self.callbackCreateActivityList)
	
	self.callbackOnCellViewVisiable = function(goCell) self:OnCellViewVisiable(goCell) end
	self.Controls.ActivityList.onCellViewVisiable:AddListener(self.callbackOnCellViewVisiable)
	
	self.Controls.scrollerHuoDong =  self.Controls.m_ItemList:GetComponent(typeof(EnhancedScroller))
	self.Controls.ItemToggleGroup =  self.Controls.m_ItemList:GetComponent(typeof(ToggleGroup))
	
	self.m_CalenderMgr = IGame.ActivityList:GetCalenderMgr()
	self.Controls.ActivityList:SetCellCount( self.m_CalenderMgr:GetListCount() , true )
	
	self:WeekDayFocus()
end

function HuoDongCalenderWindow:WeekDayFocus()
	local ControlsName = 
	{
		"Mon",
		"Tues",
		"Wed",
		"Thur",
		"Fri",
		"Sat",
		"Sun",
	}
	local nCurTime = IGame.EntityClient:GetZoneServerTime()
	local nCurWeekDay = tonumber(os.date("%w", nCurTime))
	if nCurWeekDay == 0 then
		nCurWeekDay = 7
	end
	
	-- 设置聚焦图片
	local gameObj = self.Controls.m_SubTitle.transform:Find(ControlsName[nCurWeekDay])
	local BgImage = gameObj:GetComponent(typeof(Image))
	UIFunction.SetImageSprite(BgImage, ItemFocusImage)
	
	-- 设置字体颜色
	self:SetSubTitleTxtColor(gameObj, tFocusTxtColor)
end

-- 创建活动列表
function HuoDongCalenderWindow:CreateListItem(listcell)
						
	local item = HuoDongCalenderItemClass:new({})
	item:Attach(listcell.gameObject)
	item:SetSelectCallback(handler(self, self.OnItemCellSelected))
		
end

function HuoDongCalenderWindow:OnItemCellSelected(row, col)
	local HuoDongObj = self.m_CalenderMgr:GetElement(row, col)
	if not HuoDongObj then
		return
	end
	
	self.CalenderTips:SetTipsInfo(HuoDongObj)
	self.Controls.m_ActivityInfo.gameObject:SetActive(true)
end

--- 刷新列表
function HuoDongCalenderWindow:RefreshCellItems( listcell )	

	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	
	local item = behav.LuaObject
	if nil ~= item and item.windowName == "HuoDongCalenderItemCell" then
		item:SetItemCellInfo(listcell.dataIndex)
	end
end

-- EnhancedListView 一行被“创建”时的回调
function HuoDongCalenderWindow:OnGetCellView(goCell)
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler(self, self.OnRefreshCellView)
	self:CreateListItem(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function HuoDongCalenderWindow:OnRefreshCellView(goCell)
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function HuoDongCalenderWindow:OnCellViewVisiable(goCell)
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

function HuoDongCalenderWindow:SetSubTitleTxtColor(gameObj, color)
	local texts = gameObj:GetComponentsInChildren(typeof(Text))
	for i = 0 , texts.Length - 1 do 
		texts[i].color = color
	end
end

function HuoDongCalenderWindow:OnCloseClick()
	self:Hide()
end

function HuoDongCalenderWindow:OnActWindowClick()
	self.Controls.m_ActivityInfo.gameObject:SetActive(false)
end

return HuoDongCalenderWindow



