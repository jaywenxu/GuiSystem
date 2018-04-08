--/******************************************************************
---** 文件名:	HuoDongWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-03-17
--** 版  本:	1.0
--** 描  述:	活跃度相关
--** 应  用:  
--******************************************************************/
local HuoDongRewardItemClass = require( "GuiSystem.WindowList.HuoDong.HuoDongRewardItem" )

local ActiveBoxWidget = UIControl:new
{
	windowName = "ActiveBoxWidget",
	nCurValue = 0, --当前宝箱活跃度值
}

function ActiveBoxWidget:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.ToggleGroup =  self.Controls.m_Grid:GetComponent(typeof(ToggleGroup))
		
	return self
end

function ActiveBoxWidget:SetIWidgetInfo(value)
	self.nCurValue = value
	self.Controls.m_CondValue.text = tostring(value)
	self:CreateRewardList()
end

function ActiveBoxWidget:SetItemInfo(i, obj)
	obj.gameObject:SetActive(true)
	if nil == obj.gameObject then
		return
	end
	
	local behav = obj:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	
	local item = behav.LuaObject
	if nil == item then
		return
	end
	
	if item.windowName ~= "HuoDongRewardItem" then
		return
	end
	
	local RewardObj = IGame.ActivityReward:GetBoxReward(self.nCurValue, i)
	if nil == RewardObj then
		return
	end
	
	item:SetItemCellInfo(RewardObj)	
end

-- 创建奖励列表
function ActiveBoxWidget:CreateRewardList()
	
	local nRewardCnt = IGame.ActivityReward:GetBoxRewardCnt(self.nCurValue)
	local nObjCnt = self.Controls.m_Grid.transform.childCount
	
	local callback = function( path , obj , index) 
		
		obj.transform:SetParent(self.Controls.m_Grid.transform, false)
		
		local item = HuoDongRewardItemClass:new()
		item:Attach(obj)
		
		local RewardObj = IGame.ActivityReward:GetBoxReward(self.nCurValue, tonumber(index))
		item:SetItemCellInfo(RewardObj)							
	end
		
	if  nRewardCnt <=  nObjCnt then
		for i = 1, nRewardCnt do 
			-- 刷新
			local listCell = self.Controls.m_Grid:GetChild(i-1)
			listCell.gameObject:SetActive(true)
			self:SetItemInfo(i, listCell)	
		end
		
		for i = nRewardCnt + 1, nObjCnt do 
			-- 隐藏
			local listCell = self.Controls.m_Grid:GetChild(i-1)
			listCell.gameObject:SetActive(false)
		end
	else
		for i = nObjCnt + 1, nRewardCnt do
			-- 创建
			rkt.GResources.FetchGameObjectAsync(GuiAssetList.HuoDongRewardItem , callback,  i , AssetLoadPriority.GuiNormal)
		end
	end
end

return ActiveBoxWidget
