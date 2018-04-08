------------------------------------------------------------
-- PackWindow 的子窗口,不要通过 UIManager 访问
-- 背包界面仓库窗口
------------------------------------------------------------

local PackageItemCellClass = require( "GuiSystem.WindowList.Package.PackageItemCell" )
local WareItemCellClass = require( "GuiSystem.WindowList.Package.WareWidget" )
------------------------------------------------------------
local PersonWareSkepWidget = UIControl:new
{
    windowName = "PersonWareSkepWidget" ,
	curWareTab = 1,		-- 仓库页码
	
	packTabName = {
		emAll = 0,
		emGeneral = 1,
		emOther = 2,
		emMax = 3,
	},
	
	curPackTab = 0,		-- 包裹筛选标签
	m_selectUid = 0,
}

local this = PersonWareSkepWidget	-- 方便书写
local PACK_ITEM_COUNT_IN_LINE = 5	-- 包裹一行5个物品格子
local WARE_ITEM_COUNT_IN_LINE = 6	-- 仓库一行8个物品格子
local CELL_ROW_COUNT_IN_PAGE = 5	-- 一页有几行
local zero = int64.new("0")

--四个仓库的位置
local FOUR_WARE_POS=
{
    Vector3.New(0,0,0),	
	Vector3.New(-1030,0,0),
	Vector3.New(-2060,0,0),
	Vector3.New(-3090,0,0),

}

--回弹时间
local returnTime = 0.5

--滑动超过多少往后滑
local factorPos = 515

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
--btnActionSortPacket : ButtonActionSortPacket (UnityEngine.UI.Button)
--btnActionSortWare : ButtonActionSortWare (UnityEngine.UI.Button)
--PackGoodsCellList : SkepGoods_CellList (UnityEngine.RectTransform)
--WareGoodsCellList : SkepGoods_CellList (UnityEngine.RectTransform)
--btnPackListUp : Up_Button (UnityEngine.UI.Button)
--btnPackListDown : Down_Button (UnityEngine.UI.Button)
--btnWareListUp : Up_Button (UnityEngine.UI.Button)
--btnWareListDown : Down_Button (UnityEngine.UI.Button)
------------------------------------------------------------
function PersonWareSkepWidget:Attach( obj )
	UIControl.Attach(self,obj)
	
	-- 设置最大行数
	--self.Controls.listViewPackGoods:SetCellCount( math.floor(MAX_PACKET_SIZE / PACK_ITEM_COUNT_IN_LINE) , true )
	
	-- 包裹上下翻页按钮初始位置设置
	--this.PackGoodsListViewScrollingChanged( self.Controls.scrollerPackGoods , false )
	
	-- 包裹标签切换
	self.Controls.PackTabControl = self.Controls.PackTab:GetComponent(typeof(Dropdown))
	self.callback_OnPackTabChanged = function(value) self:OnPackTabChanged(value) end
	self.Controls.PackTabControl.onValueChanged:AddListener(self.callback_OnPackTabChanged)
	
	-- 仓库事件
	self.Controls.listViewWareGoods = self.Controls.WareGoodsCellList:GetComponent(typeof(EnhancedListView))
	self.callback_OnGetWareCellView = function(goCell) self:OnGetWareCellView(goCell) end
	self.Controls.listViewWareGoods.onGetCellView:AddListener(self.callback_OnGetWareCellView)
	self.callback_OnWareCellViewVisiable = function(goCell) self:OnWareCellViewVisiable(goCell) end
	self.Controls.listViewWareGoods.onCellViewVisiable:AddListener(self.callback_OnWareCellViewVisiable)
	self.Controls.scrollerWareGoods = self.Controls.WareGoodsCellList:GetComponent(typeof(EnhancedScroller))
	self.Controls.WareToggleGroup = self.Controls.WareGoodsCellList:GetComponent(typeof(ToggleGroup))
	self.OnClickUnlock1 = function() self:OnClickSuo(2)end
	self.Controls.m_suo1.onClick:AddListener(self.OnClickUnlock1)
	self.OnClickUnlock2 = function() self:OnClickSuo(3)end
	self.Controls.m_suo2.onClick:AddListener(self.OnClickUnlock2)
	self.OnClickUnlock3 = function() self:OnClickSuo(4)end
	self.Controls.m_suo3.onClick:AddListener(self.OnClickUnlock3)
	-- 改名字按钮
	self.Controls.btnRenameWare.onClick:AddListener( function() self:OnWareRenameShow() end )
	
	-- 整理仓库
	self.callback_OnWareBtnSortClick = function() self:OnWareBtnSortClick() end
	self.Controls.btnActionSortWare.onClick:AddListener(self.callback_OnWareBtnSortClick)

	self.Controls.m_closeBtn.onClick:AddListener(function() self:CloseWare() end)
	-- 设置最大行数
	self.Controls.listViewWareGoods:SetCellCount( 1, true )
	self.callback_OnTabSelected ={}
	for i=1,4 do 
	
		self.callback_OnTabSelected[i] = function(on) self:OnWareTabChanged(on, i) end
		self:AddListenToggle(i)
	end
	
	return self
end

function PersonWareSkepWidget:CloseWare()
	self:Hide()
end

function PersonWareSkepWidget:RemoveListenToggle(index)
	local toggle = "m_Toggle"..index
	self.Controls[toggle].onValueChanged:RemoveListener(self.callback_OnTabSelected[index])
end


function PersonWareSkepWidget:AddListenToggle(index)
	local toggle = "m_Toggle"..index
	self.Controls[toggle].onValueChanged:AddListener(self.callback_OnTabSelected[index])
end

-- 包裹标签切换
function PersonWareSkepWidget:OnPackTabChanged(value)
	if self.curPackTab == value then -- 相同标签不用响应
		return
	end
	
	self.curPackTab = value
	self:ReloadPackData()
end

--点击解锁
function PersonWareSkepWidget:OnClickSuo(tabIndex)
	local warePart = GetHero():GetEntityPart(ENTITYPART_PERSON_WARE) 
	local nLastSize = warePart:GetSize(tabIndex - 1) 
	if nLastSize == 0 then 
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "需解锁上一个仓库，才可解锁当前仓库")	
		return
	end
	local unlockCost = GetUnLockWareCost(tabIndex)
	if unlockCost ~= -1 then
		if not GameHelp:DiamondNotEnoughSwitchRecharge(unlockCost, "解锁") then
			local contentStr ="是否花费"..unlockCost.."钻石解锁当前仓库？"
			local data = {
				content = contentStr,
				confirmCallBack = function() UIManager.PackWindow:UnLockConfirmFun(GOODS_SKEPID_WARE, unlockCost, tabIndex) end,
			}
			UIManager.ConfirmPopWindow:ShowDiglog(data)
		end
	else
		print("获得解锁仓库钻石失败")
	end
end



function PersonWareSkepWidget:ScrollChanged(enhanceScroller,scrollVal,position)

		local pos = enhanceScroller.ScrollRectSize/2/enhanceScroller.ScrollRectSize
		local t1,t2 = math.modf(enhanceScroller.ScrollPosition/enhanceScroller.ScrollRectSize)
		if math.abs(t2) > pos then 
			t1 = t1+1
		end
		local index = t1 +1
		local toggle = "m_Toggle"..index
		if self.Controls[toggle].isOn == false then 
			self:RemoveListenToggle(index)
			self:SetToggleIsOn(index)
			self.curWareTab = index
			self:AddListenToggle(index)
		end
		
end

-- 仓库标签切换
function PersonWareSkepWidget:OnWareTabChanged(on, tabIndex)
	if not on then -- 关闭标签不用响应
		return
	end
	local warePart = GetHero():GetEntityPart(ENTITYPART_PERSON_WARE) 
	if not warePart then
		print(mName.."SkepClient.OnMessageWareLoad，无法获取仓库部件")
		return
	elseif not warePart:IsLoad() then
		return
	end
	
	local nCurSize = warePart:GetSize(tabIndex) 
	if on then 
		if nCurSize == 0 then 
			if tabIndex == 1 then 
			elseif tabIndex == 2 then

				self.Controls.m_Suo1.gameObject:SetActive(true)
			elseif tabIndex == 3 then
				self.Controls.m_Suo2.gameObject:SetActive(true) 
			else
				self.Controls.m_Suo3.gameObject:SetActive(true)
			end
		else 
			if tabIndex == 1 then 
			elseif tabIndex == 2 then
				self.Controls.m_Suo1.gameObject:SetActive(false)
			elseif tabIndex == 3 then
				self.Controls.m_Suo2.gameObject:SetActive(false) 
			else
				self.Controls.m_Suo3.gameObject:SetActive(false)
			end
		end 
		
	end
	
	if nCurSize ~= 0 then 
		if self.curWareTab == tabIndex then -- 相同标签不用响应
			return
		end
	end
	self.curWareTab = tabIndex

	if nCurSize == 0 then
		local nLastSize = warePart:GetSize(tabIndex - 1) 
		if nLastSize == 0 then 
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "需解锁上一个仓库，才可解锁当前仓库")	
			return
		end
		local unlockCost = GetUnLockWareCost(tabIndex)
		if unlockCost ~= -1 then
			if not GameHelp:DiamondNotEnoughSwitchRecharge(unlockCost, "解锁") then
				local contentStr ="是否花费"..unlockCost.."钻石解锁当前仓库？"
				local data = {
					content = contentStr,
					confirmCallBack = function() self:UnLockConfirmFun(GOODS_SKEPID_WARE, unlockCost, -1) end,
				}
				UIManager.ConfirmPopWindow:ShowDiglog(data)
			end	
		else
			uerror("获得解锁仓库钻石失败")
		end
	else 
		--self.jumpComplete = function() self:JumpWareComplete() end
	--	self.Controls.scrollerWareGoods:JumpToDataIndex(self.curWareTab-1,0,0,true,EnhancedScroller.TweenType.immediate,0,self.jumpComplete)
		self:ReloadWareData() -- 加载数据
	end
end

--add xwej 保留
function PersonWareSkepWidget:JumpWareComplete()
	
end

function PersonWareSkepWidget:InitWareTable()
	local warePart = GetHero():GetEntityPart(ENTITYPART_PERSON_WARE) 
	if not warePart then
		print(mName.."SkepClient.OnMessageWareLoad，无法获取仓库部件")
		return
	end	
	if self.curWareTab > 1 then
		for i = self.curWareTab,1, -1 do
			local nCurSize = warePart:GetSize(i)
			if nCurSize > 0 then 
				self.curWareTab = i
				break
			end
		end
	else
		self.curWareTab = 1
	end
end

-- 重新加载所有数据
function PersonWareSkepWidget:ReloadData()
	self:InitWareTable()
	self:ReloadWareData()
	self:ReloadPackData()
end

function PersonWareSkepWidget:RefreshData()
	self:InitWareTable()
	self:RefreshCurrentWareData()
	self:ReloadPackData()
end

--add xwj
function PersonWareSkepWidget:RefreshCurrentWareData()
	self.Controls.scrollerWareGoods:RefreshActiveCellViews()
end

-- 重新加载格子数据
function PersonWareSkepWidget:ReloadWareData()
	local warePart = GetHero():GetEntityPart(ENTITYPART_PERSON_WARE) 
	if not warePart then
		print(mName.."SkepClient.OnMessageWareLoad，无法获取仓库部件")
		return
	end
	local nCurSize = warePart:GetSize(self.curWareTab)
	if nCurSize == 0 then 
		if self.curWareTab == 1 then 
		elseif self.curWareTab == 2 then
			self.Controls.m_Suo1.gameObject:SetActive(true)
		elseif self.curWareTab == 3 then
			self.Controls.m_Suo2.gameObject:SetActive(true) 
		else
			self.Controls.m_Suo3.gameObject:SetActive(true)
		end
	else 
		if self.curWareTab == 1 then 
			self.Controls.m_Toggle1.isOn = true
		elseif self.curWareTab == 2 then
			self.Controls.m_Suo1.gameObject:SetActive(false)
			self.Controls.m_Toggle2.isOn = true
		elseif self.curWareTab == 3 then
			self.Controls.m_Suo2.gameObject:SetActive(false) 
			self.Controls.m_Toggle3.isOn = true
		else
			self.Controls.m_Suo3.gameObject:SetActive(false)
			self.Controls.m_Toggle4.isOn = true
		end
	end
	self:InitWareName()
	
	--设置开启的仓库
	local warePart = GetHero():GetEntityPart(ENTITYPART_PERSON_WARE) 
	--local wareCount = warePart:GetUnLockPage()
	local wareCount = self.Controls.listViewWareGoods.CellCount
	if wareCount ~= self.Controls.listViewWareGoods.CellCount then 
		self.Controls.listViewWareGoods:SetCellCount(1, true )
	else
		self:RefreshCurrentWareData()
	end

	rktEventEngine.FireExecute(EVENT_SKEP_WIDGET_RELOAD, SOURCE_TYPE_SKEP, 0)
end

-- 重新加载包裹数据
function PersonWareSkepWidget:ReloadPackData()
	--add xwj这里需要修改
	--self.Controls.scrollerPackGoods:ReloadData()
	rktEventEngine.FireExecute(EVENT_SKEP_WIDGET_RELOAD, SOURCE_TYPE_SKEP, 0)
end

------------------------------------------------------------
-- 包裹上翻页按钮响应函数
function PersonWareSkepWidget.OnPackPageUp()
	local scroller = this.Controls.scrollerPackGoods
	local cellIndex = scroller:GetCellViewIndexAtPosition(scroller.ScrollPosition)
	cellIndex = cellIndex - CELL_ROW_COUNT_IN_PAGE
	if cellIndex < 0 then
		cellIndex = 0
	end
	scroller:JumpToDataIndex( cellIndex , 0 , 0 , true ,
	EnhancedScroller.TweenType.easeOutQuad , 0.2 ,
	function () this.PackGoodsListViewScrollingChanged( scroller , false ) end )
end
------------------------------------------------------------
-- 包裹下翻页按钮响应函数
function PersonWareSkepWidget.OnPackPageDown()
	local scroller = this.Controls.scrollerPackGoods
	local cellIndex = scroller:GetCellViewIndexAtPosition(scroller.ScrollPosition)
	cellIndex = cellIndex + CELL_ROW_COUNT_IN_PAGE
	if cellIndex > this.Controls.listViewPackGoods.CellCount then
		cellIndex = this.Controls.listViewPackGoods.CellCount
	end
	scroller:JumpToDataIndex( cellIndex , 0 , 0 , true ,
	EnhancedScroller.TweenType.easeOutQuad , 0.2 ,
	function () this.PackGoodsListViewScrollingChanged( scroller , false ) end )
end
------------------------------------------------------------
-- 根据滑块的位置显示上下翻页按钮
function PersonWareSkepWidget.PackGoodsListViewScrollingChanged( scroller , scrolling )
	if scrolling then  -- 停下来的时候才处理
		return
	end
	local cellIndex = scroller:GetCellViewIndexAtPosition(scroller.ScrollPosition)
	if 0 == cellIndex then
		this.Controls.btnPackListUp.gameObject:SetActive(false)
		this.Controls.btnPackListDown.gameObject:SetActive(true)
		return
	end
	if cellIndex + CELL_ROW_COUNT_IN_PAGE >= this.Controls.listViewPackGoods.CellCount then
		this.Controls.btnPackListUp.gameObject:SetActive(true)
		this.Controls.btnPackListDown.gameObject:SetActive(false)
		return
	end
	this.Controls.btnPackListUp.gameObject:SetActive(true)
	this.Controls.btnPackListDown.gameObject:SetActive(true)
end

------------------------------------------------------------
-- 仓库上翻页按钮响应函数
function PersonWareSkepWidget.OnWarePageUp()
	local scroller = this.Controls.scrollerWareGoods
	local cellIndex = scroller:GetCellViewIndexAtPosition(scroller.ScrollPosition)
	cellIndex = cellIndex - CELL_ROW_COUNT_IN_PAGE
	if cellIndex < 0 then
		cellIndex = 0
	end
	scroller:JumpToDataIndex( cellIndex , 0 , 0 , true ,
	EnhancedScroller.TweenType.easeOutQuad , 0.2 ,
	function () this.WareGoodsListViewScrollingChanged( scroller , false ) end )
end
------------------------------------------------------------
-- 仓库下翻页按钮响应函数
function PersonWareSkepWidget.OnWarePageDown()
	local scroller = this.Controls.scrollerWareGoods
	local cellIndex = scroller:GetCellViewIndexAtPosition(scroller.ScrollPosition)
	cellIndex = cellIndex + CELL_ROW_COUNT_IN_PAGE
	if cellIndex > this.Controls.listViewWareGoods.CellCount then
		cellIndex = this.Controls.listViewWareGoods.CellCount
	end
	scroller:JumpToDataIndex( cellIndex , 0 , 0 , true ,
	EnhancedScroller.TweenType.easeOutQuad , 0.2 ,
	function () this.WareGoodsListViewScrollingChanged( scroller , false ) end )
end

function PersonWareSkepWidget:OnWareRenameShow()
    -- 显示修改仓库名字按钮
	local nPageIndex = self.curWareTab
	local warePart = GetHero():GetEntityPart(ENTITYPART_PERSON_WARE)
	if warePart and warePart:IsLoad() then
		local nCurSize = warePart:GetSize(nPageIndex)
		if nCurSize ~= WARE_PAGE_CAPACITY then 
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "该仓库未解锁，不能重命名")		
		else 
			UIManager.WareRenameWindow:Show()
		end
	end
	
end
------------------------------------------------------------
-- 根据滑块的位置显示上下翻页按钮
--[[function PersonWareSkepWidget:WareGoodsListViewScrollingChanged( scroller , scrolling )
	if scrolling then  -- 停下来的时候才处理
		return
	end
	local contain = scroller.transform:GetChild(0)
	local posX = 0
	if contain ~= nil then 
		posX = contain.localPosition.x
		local index,factor = math.modf(posX/1030)
		factor = math.abs(factor*1030) 
		if factor > factorPos then 
			posX = 1030*index
		else
			posX = 1030*(index-1)
		end
	end
	local DotweenAni = contain.gameObject:GetComponent(typeof(DOTweenAnimation))
	if DotweenAni == nil then 
		DotweenAni = contain.gameObject:AddComponent(typeof(DOTweenAnimation))
		DotweenAni.autoPlay = false
		DotweenAni.autoKill = false
		DotweenAni:CreateTween()
	end
	DotweenAni.animationType = DG.Tweening.Core.DOTweenAnimationType.Move
	DotweenAni.duration = returnTime
	uerror(posX)
	DotweenAni.endValueV3 = Vector3.New(posX,0,0)
	DotweenAni:DORestart(true)
	
end--]]


------------------------------------------------------------
-- 创建物品格子
function PersonWareSkepWidget:CreateWareCellItems( listcell )
	local tGoodsUID = {}
	local curSize = 0
	local maxSize = 0
	local nPageIndex = self.curWareTab
	local warePart = GetHero():GetEntityPart(ENTITYPART_PERSON_WARE)
	if warePart and warePart:IsLoad() then
		tGoodsUID = warePart:GetAllGoods(nPageIndex)
		curSize = warePart:GetSize(nPageIndex)
		maxSize = warePart:GetMaxSize(nPageIndex)
	end
		
	-- 根据标签筛选
	local tFilterGoods = self:FilterPackGoodsByTab(tGoodsUID)
	for i = 1 , WARE_ITEM_COUNT_IN_LINE , 1 do
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.PackageItemCell ,
		function ( path , obj , ud )
			if nil == listcell.gameObject then   -- 判断U3D对象是否已经被销毁
				rkt.GResources.RecycleGameObject(obj)
				return
			end
			if listcell.transform.childCount >= WARE_ITEM_COUNT_IN_LINE then  -- 已经满了
				rkt.GResources.RecycleGameObject(obj)
				return
			end
			obj.transform:SetParent(listcell.transform,false)
			local item = PackageItemCellClass:new({})
			local itemIndex = listcell.dataIndex * WARE_ITEM_COUNT_IN_LINE + ( i - 1 ) + 1
		    local indexByPage = itemIndex -- (self.curWareTab - 1) * WARE_PAGE_CAPACITY + 
		    local uidGoods = tGoodsUID[indexByPage] or 0
			item:Attach(obj)
			item:SetToggleGroup( this.Controls.WareToggleGroup )
			item:SetItemCellPointerClickCallback( self.callback_OnWareItemCellSelected ) --PersonWareSkepWidget.OnWareItemCellSelected )
			item:SetItemCellPointerDoubleClickCallback(self.callback_OnWareItemCellPointClick)
			if listcell.transform.childCount <= WARE_ITEM_COUNT_IN_LINE then 
				item:SetItemInfo(uidGoods, itemIndex, curSize, maxSize)
				--item:SetSelect(uidGoods == self.m_selectUid)
			end
			item:SetWareSkepWidget(self)
		
		end , i , AssetLoadPriority.GuiNormal )
	end
end

-- 获取当前仓库页码
function PersonWareSkepWidget:GetCurWareTab()
	return self.curWareTab
end

-- 获取当前包裹筛选标签
function PersonWareSkepWidget:GetCurPackTab()
	return self.curPackTab
end


function PersonWareSkepWidget:SetToggleIsOn(index)
	local toggle = "m_Toggle"..index
	self.Controls[toggle].isOn = true
	
end

------------------------------------------------------------
--- 刷新物品格子内容
function PersonWareSkepWidget:RefreshPackCellItems( listcell )
	local listcell_trans = listcell.transform

	if listcell_trans.childCount ~= PACK_ITEM_COUNT_IN_LINE then
		return
	end
	
	local tGoodsUID = {}
	local itemType  = "pack"
	local curSize = 0
	local maxSize = 0
	local nPageIndex = self.curWareTab
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if packetPart and packetPart:IsLoad() then
		tGoodsUID = packetPart:GetAllGoods(nPageIndex)
		curSize = packetPart:GetSize(nPageIndex)
		maxSize = packetPart:GetMaxSize(nPageIndex)
	end
	
	-- 根据标签筛选
	local tFilterGoods = self:FilterPackGoodsByTab(tGoodsUID)
	local nCurOnItem = nil
	for i = 1 , PACK_ITEM_COUNT_IN_LINE , 1 do
		local itemCell = listcell_trans:GetChild( i - 1 )
		local itemIndex = listcell.dataIndex * PACK_ITEM_COUNT_IN_LINE + ( i - 1 ) + 1
		local uidGoods = tFilterGoods[itemIndex] or 0
		if nil ~= itemCell.gameObject then
			local behav = itemCell:GetComponent(typeof(UIWindowBehaviour))
			if nil ~= behav then
				local item = behav.LuaObject
				if nil ~= item and item.windowName == "PackageItemCell" then
					item:SetItemType(itemType)
					item:SetItemInfo(uidGoods, itemIndex, curSize, maxSize)
					local flag = (uidGoods == self.m_selectUid)
					--item:SetSelect(tostring(uidGoods) == tostring(self.m_selectUid))
					if tostring(uidGoods) == tostring(self.m_selectUid) then
						nCurOnItem = item
						local pentity = IGame.EntityClient:Get(uidGoods)
						if pentity then
							uerror("RefreshPackCellItems： "..pentity:GetNumProp(GOODS_PROP_GOODSID))
						end
					end
				end
			end
		end
	end
	if nCurOnItem then
		nCurOnItem:SetSelect(true)
	end
end
------------------------------------------------------------
-- EnhancedListView 一行可见时的回调
function PersonWareSkepWidget:OnPackCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshPackCellItems( listcell )
end
------------------------------------------------------------
-- EnhancedListView 一行被“创建”时的回调
function PersonWareSkepWidget:OnGetPackCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshPackCellView)
	if 0 == listcell.transform.childCount then
		self:CreatePackCellItems(listcell)
	end
end
------------------------------------------------------------
-- EnhancedListView 一行强制刷新时的回调
function PersonWareSkepWidget:OnRefreshPackCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshPackCellItems(listcell)
end
------------------------------------------------------------
------------------------------------------------------------
-- EnhancedListView 一行可见时的回调
function PersonWareSkepWidget:OnWareCellViewVisiable( goCell )
	local viewCell = goCell.transform:GetComponent(typeof(EnhancedListViewCell))
	local behav = goCell:GetComponent(typeof(UIWindowBehaviour))
	if nil ~= behav then
		local item = behav.LuaObject	
		item:InitWare(self.Controls.WareToggleGroup,self.curWareTab)
	end
	
--[[	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshWareCellItems( listcell )--]]
end
------------------------------------------------------------
-- EnhancedListView 一行被“创建”时的回调
function PersonWareSkepWidget:OnGetWareCellView( goCell )
	
	local wareItem = WareItemCellClass:new()
	wareItem:Attach(goCell)
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshWareCellView)

end
------------------------------------------------------------
-- EnhancedListView 一行强制刷新时的回调
function PersonWareSkepWidget:OnRefreshWareCellView( goCell )
	local behav = goCell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	
	local item = behav.LuaObject
	if nil ~= item  then
		item:InitWare(self.Controls.WareToggleGroup,self.curWareTab)
		item:RefreshWidget()
	end
	
	
end
------------------------------------------------------------


------------------------------------------------------------
function PersonWareSkepWidget:OnDestroy()
	self.curWareTab = 1
	UIControl.OnDestroy(self)
end
------------------------------------------------------------

-- 根据标签筛选物品
function PersonWareSkepWidget:FilterPackGoodsByTab(tGoodsUID)
	local tFilterGoods = {}
	local curPackTab = self.curPackTab
	if curPackTab == self.packTabName.emAll then
        for i, uid in pairs(tGoodsUID) do
			if uid ~= zero and uid ~= 0 then
				local entity = IGame.EntityClient:Get(uid)
				if entity then
					local entityClass = entity:GetEntityClass()
					if EntityClass:IsLeechdom(entityClass) then
						local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
						if schemeInfo and schemeInfo.lIsTaskGoods == 0 then
							table.insert(tFilterGoods, uid)
						end
					else
						table.insert(tFilterGoods, uid)
					end
				end
			else
				table.insert(tFilterGoods, uid)
			end
		end
	elseif curPackTab == self.packTabName.emGeneral then
		for i,v in pairs(tGoodsUID) do
			if v ~= zero and v ~= 0 then
				local entity = IGame.EntityClient:Get(v)
				if entity and EntityClass:IsLeechdom(entity:GetEntityClass()) then
					local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
					if schemeInfo and schemeInfo.lGoodsSubClass == LEECHDOM_SUBCLASS_GENERAL then
						table.insert(tFilterGoods, v)
					end
				end
			else
				table.insert(tFilterGoods, v)
			end
		end
	elseif curPackTab == self.packTabName.emOther then
		for i,v in pairs(tGoodsUID) do
			if v ~= zero and v ~= 0 then
				local entity = IGame.EntityClient:Get(v)
				if entity then
					local entityClass = entity:GetEntityClass()
					if EntityClass:IsLeechdom(entityClass) then
						local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
						if schemeInfo and schemeInfo.lGoodsSubClass ~= LEECHDOM_SUBCLASS_GENERAL then
							table.insert(tFilterGoods, v)
						end
					else
						table.insert(tFilterGoods, v)
					end
				end
			else
				table.insert(tFilterGoods, v)
			end
		end
	end
	
	return tFilterGoods
end

-- 整理包裹
function PersonWareSkepWidget:OnPackBtnSortClick()
	IGame.SkepClient.RequestTidy(GOODS_SKEPID_PACKET)
end

-- 整理仓库
function PersonWareSkepWidget:OnWareBtnSortClick()
	local nPageIndex = self.curWareTab - 1 -- 服务器分页序号是从0开始
	if nPageIndex < 0 or nPageIndex >= 4 then
		uerror("【整理仓库】仓库，当前页码序号错误！"..nPageIndex)
		return
	end
	IGame.SkepClient.RequestTidy(GOODS_SKEPID_WARE,nPageIndex)
end

-- 获取一行的数量
function PersonWareSkepWidget:GetRowCellCount()
	return WARE_ITEM_COUNT_IN_LINE
end

-- 获取页码
function PersonWareSkepWidget:GetWareCurPageIndex()
	local nPageIndex = self.curWareTab
	if nPageIndex <= 0 or nPageIndex > 4 then
		uerror("【仓库】获取当前页码序号错误！"..nPageIndex)
		return
	end
	return nPageIndex
end

function PersonWareSkepWidget:InitWareName()
	local warePart = GetHero():GetEntityPart(ENTITYPART_PERSON_WARE) 
	if not warePart then
		print(mName.."SkepClient.OnMessageWareLoad，无法获取仓库部件")
		return
	end
	local tabName1 = warePart:GetWareName(1)
	if tabName1 ~= "" then 
		self.Controls.m_tab1.text = tabName1
	else 
		self.Controls.m_tab1.text = "仓库1"
	end
	
	local tabName2 = warePart:GetWareName(2) 
	local size2    = warePart:GetSize(2)
	if size2 == 0 then
		self.Controls.m_Suo1.gameObject:SetActive(true)
		self.Controls.m_tab2.text = ""
	else 
		self.Controls.m_Suo1.gameObject:SetActive(false)
		if tabName2 ~= "" then 
			self.Controls.m_tab2.text = tabName2
		else 
			self.Controls.m_tab2.text = "仓库2"
		end 
	end
	
	local tabName3 = warePart:GetWareName(3)
	local size3    = warePart:GetSize(3) 
	if size3 == 0 then
		self.Controls.m_Suo2.gameObject:SetActive(true)
		self.Controls.m_tab3.text = ""
	else 
		self.Controls.m_Suo2.gameObject:SetActive(false)
		if tabName3 ~= "" then 
			self.Controls.m_tab3.text = tabName3
		else 
			self.Controls.m_tab3.text = "仓库3"
		end	 
	end

	
	local tabName4 = warePart:GetWareName(4)
	local size4    = warePart:GetSize(4)
	if size4 == 0 then
		self.Controls.m_Suo3.gameObject:SetActive(true)
		self.Controls.m_tab4.text = ""
	else 
		self.Controls.m_Suo3.gameObject:SetActive(false)
		if tabName4 ~= "" then 
			self.Controls.m_tab4.text = tabName4
		else 
			self.Controls.m_tab4.text = "仓库4"
		end 
	end 

end

function PersonWareSkepWidget:RenameWareLabel(newName)
	local warePart = GetHero():GetEntityPart(ENTITYPART_PERSON_WARE) 
	if not warePart then
		print(mName.."SkepClient.OnMessageWareLoad，无法获取仓库部件")
		return
	end 
	local nPageIndex = self.curWareTab - 1
    IGame.SkepClient:RequestModifyWareName(GOODS_SKEPID_WARE, nPageIndex, newName)	
	UIManager.WareRenameWindow:Hide()
end


function PersonWareSkepWidget:SnapComplete(enhanceScroller,cellIndex,DataIndex)
	self.curWareTab = cellIndex+1
	self:SetToggleIsOn(self.curWareTab)
end

return this