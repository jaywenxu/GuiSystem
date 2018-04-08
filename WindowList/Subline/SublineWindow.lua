--*****************************************************************
--** 文件名:	SublineWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-12-11
--** 版  本:	1.0
--** 描  述:	分线窗口
--** 应  用:  
--******************************************************************

local SublineItemClass = require("GuiSystem.WindowList.Subline.SublineItem")
local CELL_ITEM_COUNT_IN_LINE = 2  --列表列数

local SublineWindow = UIWindow:new
{
	windowName	= "SublineWindow",
	m_SublineList = {},  -- 分线列表
}

function SublineWindow:OnAttach(obj)
	UIWindow.OnAttach(self, obj)
		
	self:InitWinData()
	
	self:InitCtrlData()
end

function SublineWindow:InitWinData()
	self.m_OnItemSelected = function(...) self:OnItemSelected(...) end 
end

function SublineWindow:InitCtrlData()
	self.m_TlgGroup =  self.Controls.m_SublineCtrl:GetComponent(typeof(ToggleGroup))
	
	self.Controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnCloseClick))
	self.Controls.m_GotoBtn.onClick:AddListener(handler(self, self.OnGotoClick))
	
	self.m_Scroller = self.Controls.m_SublineCtrl:GetComponent(typeof(EnhancedListView))
	self.m_Scroller.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
	self.m_Scroller.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)	
	
	local nSublineCnt = math.ceil(table_count(self.m_SublineList) / CELL_ITEM_COUNT_IN_LINE)
	self.m_Scroller:SetCellCount(nSublineCnt, true)
end

function SublineWindow:CreateCellItem(listcell)	
	local callback = function ( path , obj , ud )
		if not listcell.transform then
			rkt.GResources.RecycleGameObject(obj)
			return
		end
		
		if listcell.transform.childCount >= CELL_ITEM_COUNT_IN_LINE then
			rkt.GResources.RecycleGameObject(obj)
			return
		end
						
		obj.transform:SetParent(listcell.transform, false)
		
		local item = SublineItemClass:new({})
		item:Attach(obj)
		item:SetToggleGroup(self.m_TlgGroup)
		item:SetSelectCB(self.m_OnItemSelected)
		
		if listcell.transform.childCount == CELL_ITEM_COUNT_IN_LINE then
			self:RefreshCellItems(listcell)
		end		
	end
	
	for i = 1 , CELL_ITEM_COUNT_IN_LINE do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.Subline.SublineItem, callback, i, AssetLoadPriority.GuiNormal)
	end
end

function SublineWindow:SetItemInfo(itemCell, nItemIdx)
	if not itemCell.gameObject then
		return
	end
	
	local behav = itemCell:GetComponent(typeof(UIWindowBehaviour))
	if not behav then
		return
	end
	
	local item = behav.LuaObject
	if not item then
		return
	end
	
	if item.windowName ~= "SublineItem" then
		return
	end
	
	local nMapID = self.m_SublineList[nItemIdx]
	item:SetItemInfo(nItemIdx, nMapID)
end

function SublineWindow:RefreshCellItems(listcell)
	local tCelltrans = listcell.transform	
	local nChildCnt  = tCelltrans.childCount

	if nChildCnt ~= CELL_ITEM_COUNT_IN_LINE then
		return
	end	
	
	local nListCnt = table_count(self.m_SublineList)
	for i = 1, CELL_ITEM_COUNT_IN_LINE do				
		local itemCell = tCelltrans:GetChild( i - 1 )	
		local nItemIdx = listcell.dataIndex * CELL_ITEM_COUNT_IN_LINE + i	
		
		if nItemIdx > nListCnt then
			itemCell.gameObject:SetActive(false)
		else
			itemCell.gameObject:SetActive(true)
		end
		
		self:SetItemInfo(itemCell, nItemIdx)
	end
end

-- EnhancedListView 一行被“创建”时的回调
function SublineWindow:OnGetCellView(goCell)
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler(self, self.OnRefreshCellView)
	if 0 == listcell.transform.childCount then
		self:CreateCellItem(listcell)
	end
end

-- EnhancedListView 一行强制刷新时的回调
function SublineWindow:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function SublineWindow:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end

function SublineWindow:OnCloseClick()
	self:Hide()
end

function SublineWindow:TransportMap(nMapID)	
	print("[SublineWindow:TransportMap]", nMapID)	
    local nCurMapID = IGame.EntityClient:GetMapID()
    if nCurMapID == nMapID then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你已在此分线") 
        return   
    end

	CommonApi:Transport(nMapID)
end

function SublineWindow:OnGotoClick()
	--TODO: 随机传送
	self:Hide()
	
	local nSublineCnt = table_count(self.m_SublineList)
	if nSublineCnt <= 0 then
		print("[SublineWindow:OnGotoClick]: 找不到传送的地图？")
		return
	end
	
	local nRandomIdx = math.random(nSublineCnt)
	local nMapID = self.m_SublineList[nRandomIdx]
	
	self:TransportMap(nMapID)
end

function SublineWindow:OnItemSelected(nMapID)
	--TODO: 选中传送
	self:Hide()
	
	self:TransportMap(nMapID)
end

function SublineWindow:InitSublineList(bMapGroupID)
    local tConfig = MIRROR_MAP_LIST[bMapGroupID]
    if not tConfig then
        return false
    end
    
    self.m_SublineList = tConfig
    if table_count(self.m_SublineList) == 0 then
        return false   
    end
    
    return true    
end

function SublineWindow:Show(bTop, bMapGroupID)
	
    bTop = bTop or true
    if not self:InitSublineList(bMapGroupID) then
        return
    end
    		
	UIWindow.Show(self, bTop)
end

return SublineWindow
