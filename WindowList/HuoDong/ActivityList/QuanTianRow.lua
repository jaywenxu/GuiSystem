--/******************************************************************
---** 文件名:	QuanTianRow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-02-28
--** 版  本:	1.0
--** 描  述:	全天活动(行)
--** 应  用:  
--******************************************************************/

local QuanTianCellClass = require("GuiSystem.WindowList.HuoDong.ActivityList.QuanTianCell")
local CELL_ITEM_COUNT_IN_LINE = 3  --列表列数

local QuanTianRow = UIControl:new
{
	windowName	= "QuanTianRow",
	m_TlgGroup  = nil,
	m_SelectCallback = nil,
	m_AllDayManager  = nil,
}

function QuanTianRow:Attach(obj, TlgGroup, SelectCallback)
	
	UIControl.Attach(self, obj)
	
	self:InitData(TlgGroup, SelectCallback)
	
	self:onCreateCellList()
end

function QuanTianRow:InitData(TlgGroup, SelectCallback)
	
	self.m_TlgGroup = TlgGroup
	
	self.m_SelectCallback = SelectCallback
	
	self.m_AllDayManager  = IGame.ActivityList:GetAllDayManager()
end

-- 实例化元素
function QuanTianRow:OnCreateCellList()
	local callback = function ( path , obj , ud )
		if not self.transform then
			rkt.GResources.RecycleGameObject(obj)
			return
		end
		
		if self.transform.childCount >= CELL_ITEM_COUNT_IN_LINE then
			rkt.GResources.RecycleGameObject(obj)
			return
		end
						
		obj.transform:SetParent(self.transform, false)
		
		local item = QuanTianCellClass:new({})
		item:Attach(obj)
		item:SetToggleGroup(self.m_TlgGroup)
		item:SetSelectCallback(self.m_SelectCallback)
		
		if self.transform.childCount == CELL_ITEM_COUNT_IN_LINE then
			self:RefreshCellItems()
		end		
	end
	
	for i = 1 , CELL_ITEM_COUNT_IN_LINE do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.HuoDongItemCell, callback, i, AssetLoadPriority.GuiNormal)
	end
end

-- 重新关联脚本
function QuanTianRow:ReAttach()	
	
	local tCelltrans = self.transform	
	for i = 1, self.transform.childCount do				
		local itemCell = tCelltrans:GetChild( i - 1 )	
		local item = QuanTianCellClass:new({})
		item:Attach(itemCell.gameObject)
		item:SetToggleGroup(self.m_TlgGroup)
		item:SetSelectCallback(self.m_SelectCallback)
	end
	
	self:RefreshCellItems()
end

-- 创建活动列表
function QuanTianRow:onCreateCellList()
	
	if self.transform.childCount == 0 then
		self:OnCreateCellList()
	else
		self:ReAttach()
	end					
end

function QuanTianRow:GetCellItem(tCell, szWdtName)
	if not tCell.gameObject then
		return
	end
	
	local behav = tCell:GetComponent(typeof(UIWindowBehaviour))
	if not behav then
		return
	end
	
	local item = behav.LuaObject
	if not item then
		return
	end
	
	if item.windowName ~= szWdtName then
		return
	end
	
	return item
end

function QuanTianRow:SetCellInfo(tCell, nIdx)
	local HuoDongObj = self.m_AllDayManager:GetElement(nIdx)
	if not HuoDongObj then
		return
	end
	
	local item = self:GetCellItem(tCell, "QuanTianCell")
	if not item then
		return
	end
		
	local bFocus = (HuoDongObj:GetActID() == IGame.ActivityList:GetFocusID())
	item:SetItemCellInfo(HuoDongObj, bFocus)
end

function QuanTianRow:RefreshCellItems()
	local tCelltrans = self.transform	
	local nChildCnt  = tCelltrans.childCount

	if nChildCnt ~= CELL_ITEM_COUNT_IN_LINE then
		return
	end	
	
	local listcell = self.transform:GetComponent(typeof(EnhancedListViewCell))
	local nListCnt = self.m_AllDayManager:GetListCount()
		
	for i = 1, CELL_ITEM_COUNT_IN_LINE do				
		local itemCell = tCelltrans:GetChild( i - 1 )	
		local nItemIdx = listcell.dataIndex * CELL_ITEM_COUNT_IN_LINE + i	
		
		if nItemIdx > nListCnt then
			itemCell.gameObject:SetActive(false)
		else
			itemCell.gameObject:SetActive(true)
		end
		
		self:SetCellInfo(itemCell, nItemIdx)
	end
end

function QuanTianRow:OnCellRecycle(tCell)
	
	local item = self:GetCellItem(tCell, "QuanTianCell")
	if not item then
		return
	end
	
	item:OnRecycle()
end

function QuanTianRow:OnRecycle()
	
	local tCelltrans = self.transform	
	local nChildCnt  = tCelltrans.childCount

	for i = 1, nChildCnt do
		local itemCell = tCelltrans:GetChild( i - 1 )	
		self:OnCellRecycle(itemCell)
	end
	
	UIControl.OnRecycle(self)
end

function QuanTianRow:OnCellDestroy(tCell)
	local item = self:GetCellItem(tCell, "QuanTianCell")
	if not item then
		return
	end
	
	item:OnDestroy()
end

function QuanTianRow:OnDestroy()
	local tCelltrans = self.transform	
	local nChildCnt  = tCelltrans.childCount

	for i = 1, nChildCnt do
		local itemCell = tCelltrans:GetChild( i - 1 )	
		self:OnCellDestroy(itemCell)
	end
	
	UIControl.OnDestroy(self)
end

return QuanTianRow






