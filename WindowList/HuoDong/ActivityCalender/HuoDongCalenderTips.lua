--/******************************************************************
---** 文件名:	HuoDongWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-04-10
--** 版  本:	1.0
--** 描  述:	周活历Tips
--** 应  用:  
--******************************************************************/
local HuoDongRewardItemClass = require( "GuiSystem.WindowList.HuoDong.HuoDongRewardItem" )

local CELL_ITEM_COUNT_IN_LINE = 1 --单列

local HD_CalenderTips = UIControl:new
{
	windowName = "HD_CalenderTips",
	huodong_id = 0,
}
local this = HD_CalenderTips
------------------------------------------------------------

function HD_CalenderTips:Init()

end

function HD_CalenderTips:Attach(obj)
	UIControl.Attach(self,obj)	
	
	self.Controls.RewardList = self.Controls.m_ItemList:GetComponent(typeof(EnhancedListView))
	self.callbackCreateRewardList = function(goCell) self:OnGetCellView(goCell) end
	self.Controls.RewardList.onGetCellView:AddListener(self.callbackCreateRewardList)
	
	self.callbackOnCellViewVisiable = function(goCell) self:OnCellViewVisiable(goCell) end
	self.Controls.RewardList.onCellViewVisiable:AddListener(self.callbackOnCellViewVisiable)
	
	self.Controls.scroller =  self.Controls.m_ItemList:GetComponent(typeof(EnhancedScroller))
	self.Controls.ItemToggleGroup =  self.Controls.m_ItemList:GetComponent(typeof(ToggleGroup))
	
	return self
end

function HD_CalenderTips:SetTipsInfo(HuoDongObj)

	-- 设置活动名称
	self.Controls.m_Name.text = tostring(HuoDongObj:GetName())
		
	--获取界面配置
	local ActInfo = IGame.rktScheme:GetSchemeInfo(ACTIVITYWINDOW_CSV, HuoDongObj.id)
	if nil == ActInfo then
		print("找不到界面信息配置！ ActID: "..HuoDongObj.id)
		return nil
	end
	
	-- 设置活动图标
	UIFunction.SetImageSprite(self.Controls.m_Icon, AssetPath.TextureGUIPath..ActInfo.IconID)
	
	-- 设置活动类型
	UIFunction.SetImageSprite(self.Controls.m_Type, HuoDongTypePath[HuoDongObj.join_type])
	
	-- 设置时间描述
	self.Controls.m_Time.text = tostring(ActInfo.TimeDesc)
	
	-- 设置活动描述
	self.Controls.m_Desc.text = tostring(ActInfo.ActDesc)
	
	-- 设置次数
    local nMaxTimes = HuoDongObj:GetMaxTimes()
    if -1 == nMaxTimes then
        self.Controls.m_TimesTxt.text = "无限制"
    else
        self.Controls.m_TimesTxt.text = HuoDongObj:GetCurTimes().."/"..nMaxTimes
    end
	
	-- 刷新活动任务奖励
	self.huodong_id = HuoDongObj.id
	self:ReloadData()
end

function HD_CalenderTips:ReloadData()
	self.Controls.RewardList:SetCellCount( IGame.ActivityReward:GetActRewardCnt(self.huodong_id) , true )
end

-- 创建奖励列表
function HD_CalenderTips:onCreateRewardList(listcell)

	local item = HuoDongRewardItemClass:new({})
	item:Attach(listcell.gameObject)	
	self:RefreshCellItems(listcell)
	
end

--- 刷新列表
function HD_CalenderTips:RefreshCellItems( listcell )
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if not behav then
		uerror("Error： UI Window Behaviour")
		return
	end
	
	local item = behav.LuaObject
	if not item  then
		uerror("LimitListWidget:RefreshCellItems item为空")
		return
	end
	
	local idx = listcell.dataIndex + 1
	local Reward =  IGame.ActivityReward:GetActReward(self.huodong_id, idx)
	if nil == Reward then
		return
	end
	
	if nil ~= item and item.windowName == "HuoDongRewardItem" then 
		item:SetItemCellInfo(Reward)
	end
end

-- EnhancedListView 一行被“创建”时的回调
function HD_CalenderTips:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView)
	self:onCreateRewardList(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function HD_CalenderTips:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function HD_CalenderTips:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end


function HD_CalenderTips:OnDestroy()	
	UIControl.OnDestroy(self)
end

return this


