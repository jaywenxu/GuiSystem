
--******************************************************************
--** 文件名:	UpgradePackageWdt.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-06-01
--** 版  本:	1.0
--** 描  述:	奖励回收
--** 应  用:  
--******************************************************************

local UpgradePackageClass = require("GuiSystem.WindowList.Welfare.UpgradePackage.UpgradePackageItem")

local UpgradePackageWdt = UIControl:new
{
	windowName = "UpgradePackageWdt",
}

function UpgradePackageWdt:Attach(obj)
	UIControl.Attach(self, obj)
    
    self:InitCtrlData()
end

function UpgradePackageWdt:InitCtrlData()
    local scrollView = self.Controls.m_RewardList
    
    self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))

	self.m_Scroller = scrollView:GetComponent(typeof(EnhancedListView))
	self.m_Scroller.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
	self.m_Scroller.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)
    
    self.m_Scroller:SetCellCount(0 , true)
end

function UpgradePackageWdt:InitData()
    IGame.UpgradePackageClient:GetPackageDataRsq()
end

function UpgradePackageWdt:SubControlExecute()
	self.m_OnPackageListUpdate = handler(self, self.OnPackageListUpdate)
	rktEventEngine.SubscribeExecute(EVENT_UPGRADE_PACKAGE_LIST_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.m_OnPackageListUpdate)
end

function UpgradePackageWdt:UnSubControlExecute()
	rktEventEngine.UnSubscribeExecute( EVENT_UPGRADE_PACKAGE_LIST_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.m_OnPackageListUpdate)
	self.m_OnPackageListUpdate = nil
end

-- EnhancedListView 一行被创建时的回调
function UpgradePackageWdt:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler(self, self.OnRefreshCellView)

	self:CreateCellItems(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function UpgradePackageWdt:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function UpgradePackageWdt:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end

-- 创建元素
function UpgradePackageWdt:CreateCellItems(listcell)
	local item = UpgradePackageClass:new({})
	item:Attach(listcell.gameObject)
end

function UpgradePackageWdt:RefreshCellItems(listcell)
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	
	local item = behav.LuaObject
	if item == nil then
		return
	end
	
	local idx = listcell.dataIndex + 1
	if nil ~= item and item.windowName == "UpgradePackageItem" then 
		item:SetCellInfo(idx)
	end
end

function UpgradePackageWdt:OnEnable()
    self:InitData()
end

function UpgradePackageWdt:OnPackageListUpdate()
    local nCount = IGame.UpgradePackageClient:GetListCnt()
	self.m_Scroller:SetCellCount(nCount, true)
end

return UpgradePackageWdt

