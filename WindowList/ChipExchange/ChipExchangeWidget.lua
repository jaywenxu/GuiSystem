-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017-9-25
-- 版  本:    2.0
-- 描  述:    通用商城子窗口
-------------------------------------------------------------------
local ChipExchangeWidget = UIControl:new
{
	windowName 	= "ChipExchangeWidget",
	m_curTab	= 1,
	m_selectItemIndex = 1,
	m_selectItemGoodID = nil,
	m_curNpcID = nil,
}

local this = ChipExchangeWidget

function ChipExchangeWidget:Init()
	self.ChipGoodsList			= require("GuiSystem.WindowList.ChipExchange.ChipLimitListWidget"):new{m_ChipExchangeWidget = self}
	self.ChipExchengeExpense	= require("GuiSystem.WindowList.ChipExchange.ChipExpenseInfo"):new{m_ChipExchangeWidget = self}
	self.ChipExchengeGoodsInfo	= require("GuiSystem.WindowList.ChipExchange.ChipGoodsInfo"):new{m_ChipExchangeWidget = self}	-- 右边物品描述框
	
	self.ChipExchengeExpense:Init()
end

function ChipExchangeWidget:Attach(obj)
	UIControl.Attach(self,obj)	

	-- 创建
	self.ChipGoodsList:Attach(self.Controls.m_ChipListWidget.gameObject)
	self.ChipExchengeExpense:Attach(self.Controls.m_ChipCurExpenseWidget.gameObject)
	self.ChipExchengeGoodsInfo:Attach(self.Controls.m_ChipCurGoodsInfoWidget.gameObject)
	self.unityBehaviour.onDisable:AddListener(function() self:OnDisable() end)
	self:SubscribeEvent()
	return self
end

function ChipExchangeWidget:OnDestroy()
	self:UnSubscribeEvent()
	UIWindow.OnDestroy(self)
end

function ChipExchangeWidget:OnDisable()
	self.m_selectItemIndex = 1
end

function ChipExchangeWidget:FetchWidget( ParentTrans,curTabIndex,index )
	rkt.GResources.FetchGameObjectAsync( GuiAssetList.ChipExchangeWidget ,
		function ( path , obj , ud )
			if nil ==obj then   -- 判断U3D对象是否已经被销毁
				return
			end
			self:Attach(obj)
			obj.transform:SetParent(ParentTrans,false)
			self:Refresh(curTabIndex,index)
		end,"", AssetLoadPriority.GuiNormal )
end

function ChipExchangeWidget:Refresh(curTabIndex,index)
	-- uerror("==== ChipExchangeWidget:Refresh ======"..tostring(curTabIndex) .." "..tostring(index).." "..tostring(self.m_curTab) .. " ".. tostring(self.m_selectItemIndex))
	self.m_curTab = curTabIndex or self.m_curTab 
	self.m_selectItemIndex = index or self.m_selectItemIndex
	self.m_selectItemGoodID = IGame.ChipExchangeClient:GetGoodsIDByIndex(self.m_index)
	if not IGame.ChipExchangeClient:UpdateCurExchangeInfo(self.m_curTab) then
		uerror("【ChipExchangeWindow:RefeshGoodsInfo】刷新当前分类数据失败，小类为："..curTabIndex)
		return
	end
	-- 刷新一个切页需要更新3项：
	-- 当前物品列表信息、当前兑换的物品信息、当前兑换的消耗信息
	self.ChipGoodsList:Refresh(self.m_selectItemIndex,true)
	self.ChipExchengeGoodsInfo:UpdateExchangeGoodsInfo(self.m_selectItemIndex)
	self.ChipExchengeExpense:UpdateExchangeExpenseInfo(self.m_selectItemIndex)
end

function ChipExchangeWidget:ShowWidget(npcid, nSubType, selectIndex )
	self.m_curNpcID = npcid
	self.m_curTab = nSubType
	self.m_selectItemIndex = selectIndex
	-- uerror("ChipExchangeWidget:ShowWidget:"..selectIndex)
	if not self:isLoaded() then
		return
	end
	self:Show()
	self:Refresh(nSubType, selectIndex)
end

function ChipExchangeWidget:SetSecIndex(index)
	self.m_selectItemIndex = index
end

-- 获取当前购买的npc id 
function ChipExchangeWidget:GetCurExchangeNpcID()
    return self.m_curNpcID
end
function ChipExchangeWidget:SetTabIndex(TabIndex)
	self.m_curTab = TabIndex
end

-- 定时清空数据后重新刷新数据
function ChipExchangeWidget:RefreshGoodsInfo(curTab)
	self.m_curTab = curTab or self.m_curTab
	if not IGame.ChipExchangeClient:UpdateCurExchangeInfo(self.m_curTab) then
		uerror("【ChipExchangeWindow:RefeshGoodsInfo】刷新当前分类数据失败，小类为："..curTabIndex)
		return
	end
	
	-- 刷新一个切页需要更新3项：
	-- 当前物品列表信息、当前兑换的物品信息、当前兑换的消耗信息
	self.ChipGoodsList:ReloadData()
	self.ChipExchengeGoodsInfo:UpdateExchangeGoodsInfo(self.m_selectItemIndex)
	self.ChipExchengeExpense:UpdateExchangeExpenseInfo(self.m_selectItemIndex)
end

-- 更新货币数值
function ChipExchangeWidget:RefreshRecordData(eventData)
	if self.ChipExchengeExpense then
		self.ChipExchengeExpense:UpdateExpenseInfo()
	end
end

-- 注册事件
function ChipExchangeWidget:SubscribeEvent()
	self:UnSubscribeEvent()
	self.RefreshGoodsInfoTimer = function() self:RefreshGoodsInfo() end
	self.callBackRefreshRecordData = function(event, srctype, srcid, eventData) self:RefreshRecordData(eventData) end
	rktEventEngine.SubscribeExecute( EVENT_CHIPEXCHANGE_LIST_UPDATE,SOURCE_TYPE_PLAZA,0,self.RefreshGoodsInfoTimer) 
	rktEventEngine.SubscribeExecute( EVENT_SYNC_PERSON_RECORD_DATA,SOURCE_TYPE_PERSON,0,self.callBackRefreshRecordData)
end

-- 取消事件
function ChipExchangeWidget:UnSubscribeEvent()
	if not self.RefreshGoodsInfoTimer then
		return
	end
	rktEventEngine.UnSubscribeExecute( EVENT_CHIPEXCHANGE_LIST_UPDATE,SOURCE_TYPE_PLAZA,0,self.RefreshGoodsInfoTimer)
	rktEventEngine.UnSubscribeExecute( EVENT_SYNC_PERSON_RECORD_DATA,SOURCE_TYPE_PERSON,0,self.callBackRefreshRecordData)
end

return this