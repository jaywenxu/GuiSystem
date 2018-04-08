--/******************************************************************
---** 文件名:	HuoDongWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-03-016
--** 版  本:	1.0
--** 描  述:	活动描述模块
--** 应  用:  
--******************************************************************/

local HuoDongRewardItemClass = require( "GuiSystem.WindowList.HuoDong.HuoDongRewardItem" )

local HuoDongDescWidget = UIControl:new
{
	windowName	= "HuoDongDescWidget",
	huodong_id = 0,  
}

local this = HuoDongDescWidget

function HuoDongDescWidget:Attach(obj)
	UIControl.Attach(self,obj)
	
	local controls = self.Controls

	controls.m_Detailed.onClick:AddListener(handler(self, self.OnDetailedBtnClick))
	controls.m_ViewBtn.onClick:AddListener(handler(self, self.OnView))
	
	local ItemList = self.Controls.m_ItemList
	self.m_ListView = ItemList:GetComponent(typeof(EnhancedListView))
	
	self.m_ListView.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
	self.m_ListView.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)
	
	self.m_scroller =  ItemList:GetComponent(typeof(EnhancedScroller))

	return self
end

function HuoDongDescWidget:OnDetailedBtnClick()
	
	local ActInfo = IGame.rktScheme:GetSchemeInfo(ACTIVITYWINDOW_CSV, self.huodong_id)
	
	if nil == ActInfo then
		print("找不到界面信息配置！ ActID: "..self.huodong_id)
		return
	end
	
	UIManager.CommonGuideWindow:ShowWindow(ActInfo.RuleID)
end

function HuoDongDescWidget:OnView()
	local ActInfo = IGame.rktScheme:GetSchemeInfo(ACTIVITYWINDOW_CSV, self.huodong_id)
	if nil == ActInfo then
		print("找不到界面信息配置！ ActID: ", self.huodong_id)
		return
	end
	
	if not ActInfo.ViewFunc then
		return
	end
	    
	loadstring(ActInfo.ViewFunc.."()")()
end

function HuoDongDescWidget:ReloadData()
	self.m_ListView:SetCellCount( IGame.ActivityReward:GetActRewardCnt(self.huodong_id) , true )
end

function HuoDongDescWidget:SetActDesc(huodong_id)
		
	--获取界面配置
	local ActInfo = IGame.rktScheme:GetSchemeInfo(ACTIVITYWINDOW_CSV, huodong_id)
	if nil == ActInfo then
		print("找不到界面信息配置！ ActID: "..huodong_id)
		return
	end
	
	local controls = self.Controls
	
	local bShowDetailBtn = (ActInfo.Detailed ~= 0)
	controls.m_Detailed.gameObject:SetActive(bShowDetailBtn)
	
	local bShowViewBtn = (ActInfo.View ~= 0)
	controls.m_ViewBtn.gameObject:SetActive(bShowViewBtn)

	controls.m_ActDesc.text = ActInfo.ActDesc
	
	--设置活动奖励
	self.huodong_id = huodong_id
	self:ReloadData()
end

-- 创建列表
function HuoDongDescWidget:CreateRewardItem(listcell)
	
	local item = HuoDongRewardItemClass:new({})
	item:Attach(listcell.gameObject)
end

--- 刷新列表
function HuoDongDescWidget:RefreshCellItems( listcell )
	
	local idx = listcell.dataIndex + 1
	local Reward = IGame.ActivityReward:GetActReward(self.huodong_id, idx)
	if nil == Reward then
		cLog("Get reward failed! "..idx, "red")
		return
	end
		
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	
	local item = behav.LuaObject
	local op = {bShowExpNum = false}
	
	if nil ~= item and item.windowName == "HuoDongRewardItem" then
		item:SetItemCellInfo(Reward, op)
	end
end

-- EnhancedListView 一行被“创建”时的回调
function HuoDongDescWidget:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler(self, self.OnRefreshCellView)
	
	self:CreateRewardItem(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function HuoDongDescWidget:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function HuoDongDescWidget:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

return this