------------------------------------------------------------
-- PackWindow 的子窗口,不要通过 UIManager 访问
-- 背包界面包裹窗口
------------------------------------------------------------
require("GuiSystem.WindowList.PlayerSkill.PlayerSkillWindowDefine")
local PackageItemCellClass = require( "GuiSystem.WindowList.Package.PackageItemCell" )
------------------------------------------------------------
local PersonPackSkepWidget = UIControl:new
{
    windowName = "PersonPackSkepWidget" ,
	FunText      = {},
	m_greenComposeSelected =true,
	m_blueCompoSelected =false,
}

local this = PersonPackSkepWidget   -- 方便书写
local CELL_ROW_COUNT_IN_PAGE = 5        -- 一页有几行
local zero = int64.new("0")

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
--btnActionRangePacket : ButtonActionRangePacket (UnityEngine.UI.Button)
--skepGoodsCellList : SkepGoodS_CellList (UnityEngine.RectTransform)
--btnActionCancel : ButtonActionCancel (UnityEngine.UI.Button)
--toggleSelectBase : SelectnBase (UnityEngine.UI.Toggle)
--btnActionCompose : ButtonActionCompose (UnityEngine.UI.Button)
--btnGoodsListUp : Up_Button (UnityEngine.UI.Button)
--btnGoodsListDown : Down_Button (UnityEngine.UI.Button)
--btnActionSale : ButtonActionSale (UnityEngine.UI.Button)
--btnActionSale1 : ButtonActionSale1 (UnityEngine.UI.Button)
------------------------------------------------------------
function PersonPackSkepWidget:Attach( obj )
	UIControl.Attach(self,obj)
	-- 包裹事件
	self.Controls.listViewSkepGoods = self.Controls.skepGoodsCellList:GetComponent(typeof(EnhancedListView))
	self.callback_OnGetCellView = function(goCell) self:OnGetCellView(goCell) end
	self.Controls.listViewSkepGoods.onGetCellView:AddListener(self.callback_OnGetCellView)
	self.callback_OnCellViewVisiable = function(goCell) self:OnCellViewVisiable(goCell) end
	
	self.Controls.listViewSkepGoods.onCellViewVisiable:AddListener(self.callback_OnCellViewVisiable)
	
	self.Controls.scrollerSkepGoods = self.Controls.skepGoodsCellList:GetComponent(typeof(EnhancedScroller))
	self.Controls.scrollerSkepGoods.scrollerScrollingChanged = PersonPackSkepWidget.SkepGoodsListViewScrollingChanged
	self.Controls.GoodsToggleGroup = self.Controls.skepGoodsCellList:GetComponent(typeof(ToggleGroup)) 
    
	-- 勾选蓝装
	self.callback_OnLanDefaultSelected = function( on ) self:OnLanDefaultSelected(on) end
	--self.Controls.m_LanDefaultSelected.onValueChanged:AddListener(self.callback_OnLanDefaultSelected)
	
	-- 勾选绿装
	self.callback_OnGreenEquipTpgSelected = function( on ) self:OnGreenEquipTpgSelected(on) end
	self.Controls.m_GreenEquipTpg.onValueChanged:AddListener(self.callback_OnGreenEquipTpgSelected)    
	-- 勾选蓝装
	self.callback_OnBlueEquipTpgSelected = function( on ) self:OnBlueEquipTpgSelected(on) end
	self.Controls.m_BlueEquipTpg.onValueChanged:AddListener(self.callback_OnBlueEquipTpgSelected)
	
	-- 分解包裹事件
	self.Controls.listViewDecomposeSkepGoods = self.Controls.skepGoodsDecomposeCellList:GetComponent(typeof(EnhancedListView))
	self.Controls.listViewDecomposeSkepGoods.onGetCellView:AddListener(self.callback_OnGetCellView)
	
	self.Controls.listViewDecomposeSkepGoods.onCellViewVisiable:AddListener(self.callback_OnCellViewVisiable) 
	
	self.Controls.scrollerDecomposeSkepGoods = self.Controls.skepGoodsDecomposeCellList:GetComponent(typeof(EnhancedScroller))
	--self.Controls.scrollerDecomposeSkepGoods.scrollerScrollingChanged = PersonPackSkepWidget.SkepGoodsListViewScrollingChanged
	self.Controls.GoodsDecomposeToggleGroup = self.Controls.skepGoodsDecomposeCellList:GetComponent(typeof(ToggleGroup)) 
	
	-- 任务事件 
	self.Controls.listViewTaskSkepGoods = self.Controls.skepGoodsTaskCellList:GetComponent(typeof(EnhancedListView))
	self.Controls.listViewTaskSkepGoods.onGetCellView:AddListener(self.callback_OnGetCellView)
	
	self.Controls.listViewTaskSkepGoods.onCellViewVisiable:AddListener(self.callback_OnCellViewVisiable) 
	
	self.Controls.scrollerTaskSkepGoods = self.Controls.skepGoodsTaskCellList:GetComponent(typeof(EnhancedScroller))
	self.Controls.GoodsTaskToggleGroup = self.Controls.skepGoodsTaskCellList:GetComponent(typeof(ToggleGroup))
	
	-- 按钮事件
	self.Controls.btnGoodsListUp.onClick:AddListener( this.OnClickPageUp )
	self.Controls.btnGoodsListDown.onClick:AddListener( this.OnClickPageDown )
	
	-- 整理包裹
	self.callback_OnBtnSortClick = function() self:OnBtnSortClick() end
	self.Controls.btnActionSort.onClick:AddListener(self.callback_OnBtnSortClick)
	
	-- 一键分解
	self.callback_OnBtnDecomposeClick = function() self:OnBtnDecomposeClick() end
	self.Controls.btnActionDecompose.onClick:AddListener(self.callback_OnBtnDecomposeClick) 
	
	-- 取消分解
	self.callback_OnBtnCancelDecomposeClick = function() self:OnBtnCancelDecomposeClick() end
	self.Controls.btnCancelDecompose.onClick:AddListener(self.callback_OnBtnCancelDecomposeClick)
	
	-- 确认分解
	self.callback_OnBtnConfirmDecomposeClick = function() self:OnBtnConfirmDecomposeClick() end
	self.Controls.btnConfirmDecompose.onClick:AddListener(self.callback_OnBtnConfirmDecomposeClick)
	
	self.Controls.DecomposeRichText = self.Controls.m_DecomposeRichText:GetComponent(typeof(rkt.RichText))
	self.callback_DecomposeRichTextClick = function(text, beginIndex, endIndex) self:OnGoodsNameClick(text,beginIndex, endIndex, self.FunText) end 
	self.Controls.DecomposeRichText.onClick:AddListener(self.callback_DecomposeRichTextClick)
	
	-- 设置最大行数
	self.Controls.listViewSkepGoods:SetCellCount( math.floor(MAX_PACKET_SIZE / PACKET_CELL_ITEM_COUNT_IN_LINE) , true )
	self.Controls.listViewDecomposeSkepGoods:SetCellCount( 5  , true )
	self.Controls.listViewTaskSkepGoods:SetCellCount( 7 , true )
	
	self.callback_OnPackItemCellPointClick = function(itemCell, on) self:OnPackItemCellPointClick(itemCell, on) end
	
	-- 包裹上下翻页按钮初始位置设置
	this.SkepGoodsListViewScrollingChanged(self.Controls.scrollerSkepGoods , false ) 
	
	self.m_bDecompose = false
	--self.FunText      = {}
	self.m_EquipDecomposeUidTable = {} 
	self.m_EquipDecomposeItemTable = {}
	return self
end

--双击去仓库
function PersonPackSkepWidget:OnPackItemCellPointClick(itemCell, on)
	local uid = itemCell:GetGoodsUID()
	if uid == zero or uid == 0 then
		return
	end 
	local canToWare = self:NeedShowToWareByGoodSUid(uid)
	if canToWare ==true then 
		self.m_selectUid = uid
		IGame.SkepClient.RequestPacketToWare(uid)
	end

end

function PersonPackSkepWidget:RefreshData()
	 self.Controls.scrollerSkepGoods:RefreshActiveCellViews()
end

function PersonPackSkepWidget:RefreshSize()
	 self.Controls.scrollerSkepGoods:Resize(true)
end

-- 重新加载格子数据
function PersonPackSkepWidget:ReloadData() 
	self.Controls.listViewTaskSkepGoods.gameObject:SetActive(false)
	if self.m_bDecompose then 
		self.Controls.listViewDecomposeSkepGoods.gameObject:SetActive(true)
		self.Controls.scrollerDecomposeSkepGoods:JumpToDataIndex( 0, 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0.2, function() self.Controls.scrollerDecomposeSkepGoods:Resize(false) end )
		self.DecomPoseItemList = {}
	    self.Controls.scrollerDecomposeSkepGoods:ReloadData()
		self.Controls.wareBtn.gameObject:SetActive(false)
		
	else 
		self.Controls.listViewSkepGoods.gameObject:SetActive(true)
	    self.Controls.scrollerSkepGoods:JumpToDataIndex( 0, 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0.2, function() self.Controls.scrollerSkepGoods:Resize(false) end )
	    self.Controls.scrollerSkepGoods:ReloadData()
		self.Controls.btnActionDecompose.gameObject:SetActive(true)
		self.Controls.wareBtn.gameObject:SetActive(true)
	end 

	rktEventEngine.FireExecute(EVENT_SKEP_WIDGET_RELOAD, SOURCE_TYPE_SKEP, 0)
end

function PersonPackSkepWidget:ReloadTaskData() 
	--self.Controls.btnActionDecompose.gameObject:SetActive(true)
--[[	self.Controls.btnActionSort.gameObject:SetActive(false)
	self.Controls.btnCancelDecompose.gameObject:SetActive(false)
	self.Controls.btnConfirmDecompose.gameObject:SetActive(false)  ]]
	self.Controls.listViewSkepGoods.gameObject:SetActive(false)
	self.Controls.listViewDecomposeSkepGoods.gameObject:SetActive(false)
	self.Controls.listViewTaskSkepGoods.gameObject:SetActive(true)
	self.Controls.scrollerTaskSkepGoods:JumpToDataIndex( 0, 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0.2, function() self.Controls.scrollerTaskSkepGoods:Resize(false) end )
	self.m_bDecompose = false
	self.Controls.scrollerTaskSkepGoods:ReloadData()
	rktEventEngine.FireExecute(EVENT_SKEP_WIDGET_RELOAD, SOURCE_TYPE_SKEP, 0)
end 

function PersonPackSkepWidget:SetEquipDecomposeUID(equipUID, flag) 
	if flag then 
		table.insert(self.m_EquipDecomposeUidTable, equipUID)
	else 
		for pos , v in pairs(self.m_EquipDecomposeUidTable) do 
			if v == equipUID then 
				table.remove(self.m_EquipDecomposeUidTable, pos)
			end
		end
	end
	self:ShowDetailInfo()
end



------------------------------------------------------------
-- 包裹上翻页按钮响应函数
function PersonPackSkepWidget.OnClickPageUp()
	local scroller = this.Controls.scrollerSkepGoods
	local cellIndex = scroller:GetCellViewIndexAtPosition(scroller.ScrollPosition)
	cellIndex = cellIndex - CELL_ROW_COUNT_IN_PAGE
	if cellIndex < 0 then
		cellIndex = 0
	end
	scroller:JumpToDataIndex( cellIndex , 0 , 0 , true ,
	EnhancedScroller.TweenType.easeOutQuad , 0.2 ,
	function () this.SkepGoodsListViewScrollingChanged( scroller , false ) end )
end
------------------------------------------------------------
-- 包裹下翻页按钮响应函数
function PersonPackSkepWidget.OnClickPageDown()
	local scroller = this.Controls.scrollerSkepGoods
	local cellIndex = scroller:GetCellViewIndexAtPosition(scroller.ScrollPosition)
	cellIndex = cellIndex + CELL_ROW_COUNT_IN_PAGE
	if cellIndex > this.Controls.listViewSkepGoods.CellCount then
		cellIndex = this.Controls.listViewSkepGoods.CellCount
	end
	scroller:JumpToDataIndex( cellIndex , 0 , 0 , true ,
	EnhancedScroller.TweenType.easeOutQuad , 0.2 ,
	function () this.SkepGoodsListViewScrollingChanged( scroller , false ) end )
end
------------------------------------------------------------
-- 根据滑块的位置显示上下翻页按钮
function PersonPackSkepWidget.SkepGoodsListViewScrollingChanged( scroller , scrolling )
	if scrolling then  -- 停下来的时候才处理
		return
	end
	local cellIndex = scroller:GetCellViewIndexAtPosition(scroller.ScrollPosition)
	if 0 == cellIndex then
		this.Controls.btnGoodsListUp.gameObject:SetActive(false)
		this.Controls.btnGoodsListDown.gameObject:SetActive(true)
		return
	end
	if cellIndex + CELL_ROW_COUNT_IN_PAGE >= this.Controls.listViewSkepGoods.CellCount then
		this.Controls.btnGoodsListUp.gameObject:SetActive(true)
		this.Controls.btnGoodsListDown.gameObject:SetActive(false)
		return
	end
	this.Controls.btnGoodsListUp.gameObject:SetActive(true)
	this.Controls.btnGoodsListDown.gameObject:SetActive(true)
end
------------------------------------------------------------
-- 创建物品格子
function PersonPackSkepWidget:CreateCellItems( listcell )
	for i = 1 , PACKET_CELL_ITEM_COUNT_IN_LINE , 1 do
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.PackageItemCell ,
		function ( path , obj , ud )
			if nil == listcell.gameObject then   -- 判断U3D对象是否已经被销毁
				rkt.GResources.RecycleGameObject(obj)
				return
			end
			if listcell.transform.childCount >= PACKET_CELL_ITEM_COUNT_IN_LINE then  -- 已经满了
				rkt.GResources.RecycleGameObject(obj)
				return
			end
			obj.transform:SetParent(listcell.transform,false)
			local item = PackageItemCellClass:new({})
			item:Attach(obj)
			item:SetToggleGroup( this.Controls.GoodsToggleGroup )
			local selectFun =  function(itemCell , on)self:OnItemCellSelected(itemCell , on) end
			item:SetItemCellPointerClickCallback( selectFun )
			item:SetItemCellPointerDoubleClickCallback(self.callback_OnPackItemCellPointClick)
			if listcell.transform.childCount == PACKET_CELL_ITEM_COUNT_IN_LINE then
				self:RefreshCellItems(listcell)
			end	
			
		end , i , AssetLoadPriority.GuiNormal )
	end
end

------------------------------------------------------------
--- 刷新物品格子内容
function PersonPackSkepWidget:RefreshCellItems( listcell )
	local listcell_trans = listcell.transform
	if listcell_trans.childCount ~= PACKET_CELL_ITEM_COUNT_IN_LINE then
		return
	end
		
	local tGoodsUID = {}
	local itemType = "pack"
	local curSize = 0
	local maxSize = 0
	local hero = GetHero()
	if nil == hero then 
		return
	end
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if packetPart and packetPart:IsLoad() then
		tGoodsUID = packetPart:GetAllGoods()
		curSize = packetPart:GetSize()
		maxSize = packetPart:GetMaxSize()
	end
	
	-- 根据标签筛选
	local tFilterGoods = {}
	if self.m_bDecompose then
		tFilterGoods = self:FilterGoodsByQuality(tGoodsUID, curSize)
	else 
		tFilterGoods = self:FilterGoodsByTab(tGoodsUID, curSize)
	end
	
	for i = 1 , PACKET_CELL_ITEM_COUNT_IN_LINE , 1 do
		local itemCell = listcell_trans:GetChild( i - 1 )
		local itemIndex = listcell.dataIndex * PACKET_CELL_ITEM_COUNT_IN_LINE + (i - 1) + 1
		local uidGoods = tFilterGoods[itemIndex] or 0
		if nil ~= itemCell.gameObject then
			local behav = itemCell:GetComponent(typeof(UIWindowBehaviour))
			if nil ~= behav then
				local item = behav.LuaObject
				if nil ~= item and item.windowName == "PackageItemCell" then
					if self.m_bDecompose then 
						table.insert(self.m_EquipDecomposeItemTable, item)
					end
					item:SetEquipDecompose(self.m_bDecompose) 
					item:SetItemType(itemType)
					item:SetItemInfo(uidGoods, itemIndex, curSize, maxSize)
					item:SetCoolImg(0) 
					--是否分解初始化化
					if self.m_bDecompose ==true then 
						item:SetEquipChooseStatus(self.m_greenComposeSelected,1)
						item:SetEquipChooseStatus(self.m_blueCompoSelected,2)
					end
				
				end
			end
		end
	end
end
------------------------------------------------------------
-- EnhancedListView 一行可见时的回调
function PersonPackSkepWidget:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end
------------------------------------------------------------
-- EnhancedListView 一行被“创建”时的回调
function PersonPackSkepWidget:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView)
	if 0 == listcell.transform.childCount then
		self:CreateCellItems(listcell)
	end
end
------------------------------------------------------------
-- EnhancedListView 一行强制刷新时的回调
function PersonPackSkepWidget:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end
------------------------------------------------------------
function PersonPackSkepWidget:OnItemCellSelected( itemCell , on)
	if not on then
		return
	end
	
	-- itemCell.gameObject:SetActive(true)
	local uid = itemCell:GetGoodsUID()
	local entity = IGame.EntityClient:Get(uid)
	
	-- 显示tips
	if entity then
		local needShowToWare = self:NeedShowToWareByGoodSUid(uid)
	
		local entityClass = entity:GetEntityClass()
		
		
		if EntityClass:IsEquipment(entityClass) then
			local cfgId = entity:GetNumProp(GOODS_PROP_GOODSID)
			local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, cfgId)
			if not schemeInfo then
				return
			end
			
			local subInfo = {}
				
			if needShowToWare == true then 
				subInfo = 
				{
					bShowBtn = 1,
					bShowCompare = false,
					bRightBtnType = 3,
				}	
				UIManager.EquipTooltipsWindow:Show(true)
                UIManager.EquipTooltipsWindow:SetEntity(entity, subInfo)
			else
				
				if schemeInfo.GoodsSubClass == EQUIPMENT_SUBCLASS_BATTLEBOOK then
					UIManager.WuXueDetailWindow:ShowForPacket(uid)
				else 
					subInfo = 
					{
						bShowBtn = 1,
						bShowCompare = true,
						bRightBtnType = 2,
					}
					UIManager.EquipTooltipsWindow:Show(true)
					UIManager.EquipTooltipsWindow:SetEntity(entity, subInfo)
				end	
			end
		
			-- 武学
			
		else
			local subInfo = {}
			if needShowToWare == true then 
				subInfo =
				{
					bShowBtnType	= 1, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
					bBottomBtnType = 3,	-- 源预设
				}
				
			else
				subInfo =
				{
					bShowBtnType	= 1, 	--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
					bBottomBtnType	= 1,
				}
			end
		
			UIManager.GoodsTooltipsWindow:Show(true)
            UIManager.GoodsTooltipsWindow:SetGoodsEntity(entity,subInfo)
		end
		
		return
	end
	
	
	-- 解锁
	if itemCell:IsLock() then 
		local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
		if not packetPart then
			return
		end
		
		local nCurSize = packetPart:GetSize() 
		local nUnlockLine = (nCurSize - 40)/PACKET_CELL_ITEM_COUNT_IN_LINE + 1 
		local unlockCost = GetUnLockSkepCost(nUnlockLine)
		if unlockCost ~= -1 then 
			if not GameHelp:DiamondNotEnoughSwitchRecharge(unlockCost, "解锁") then
				local contentStr ="是否花费"..unlockCost.."钻石解锁一行包裹栏？"
				local data = {
					content = contentStr,
					confirmCallBack = function() UIManager.PackWindow:UnLockConfirmFun(GOODS_SKEPID_PACKET, unlockCost, -1) end,
				}
				UIManager.ConfirmPopWindow:ShowDiglog(data)
			end
		else 
			uerror("解锁格子对应的钻石出错")
		end

	end
end


function PersonPackSkepWidget:NeedShowToWareByGoodSUid(uid)
	
	if UIManager.PackWindow.PersonWareSkepWidget:isShow() then 
		local entity = IGame.EntityClient:Get(uid)
		if entity then
			local entityClass = entity:GetEntityClass()
			if EntityClass:IsLeechdom(entityClass) then
				local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
				if schemeInfo and schemeInfo.lIsTaskGoods == 0 then
					return true
				end
			else
                local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
				if schemeInfo then
					return true
				end
			end
		end
	end
	return false
end


------------------------------------------------------------
function PersonPackSkepWidget:OnDestroy()
	UIControl.OnDestroy(self)
end
------------------------------------------------------------

-- 根据标签筛选物品
function PersonPackSkepWidget:FilterGoodsByTab(tGoodsUID, size)
	local tFilterGoods = {}
	local curTab = UIManager.PackWindow:GetCurTab()
	local tabName = UIManager.PackWindow.tabName
	if curTab == tabName.emAll then
		for i = 1, size do
			local uid = tGoodsUID[i] or 0
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
	elseif curTab == tabName.emGeneral then
		for i = 1, table.getn(tGoodsUID) do
			local uid = tGoodsUID[i] or 0
			if tostring(uid) ~= "0" then
				local entity = IGame.EntityClient:Get(uid)
				if entity and EntityClass:IsLeechdom(entity:GetEntityClass()) then
					local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
					-- 任务道具
					if schemeInfo and schemeInfo.lIsTaskGoods == 1 then
						table.insert(tFilterGoods, uid)
					end
				end
			end
		end
	elseif curTab == tabName.emOther then
		for i = 1, size do
			local uid = tGoodsUID[i] or 0
			if uid ~= zero and uid ~= 0 then
				local entity = IGame.EntityClient:Get(uid)
				if entity then
					local entityClass = entity:GetEntityClass()
					if EntityClass:IsLeechdom(entityClass) then
						local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
						if schemeInfo and schemeInfo.lGoodsSubClass ~= LEECHDOM_SUBCLASS_GENERAL then
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
	end
	
	return tFilterGoods
end 

function PersonPackSkepWidget:FilterGoodsByQuality(tGoodsUID, curSize) 
	local tFilterGoods = {}
	 
	for j = 1, 4 do
		for i = 1, curSize do 
			local uid = tGoodsUID[i] or 0 
			if uid ~= zero then 
				local entity = IGame.EntityClient:Get(uid) 
				if entity then 
					local tQuality = entity:GetNumProp(EQUIP_PROP_QUALITY) 
					local entityClass = entity:GetEntityClass() 
					local isEquip = EntityClass:IsEquipment(entityClass)
					if tQuality == j and isEquip then 
						table.insert(tFilterGoods, uid)
					end
				end
			end
		end
	end
	
	return tFilterGoods
end

-- 整理包裹
function PersonPackSkepWidget:OnBtnSortClick()	
	IGame.SkepClient.RequestTidy(GOODS_SKEPID_PACKET)
end

function PersonPackSkepWidget:OnLanDefaultSelected(on)
	if on then 
		--self.Controls.m_LanBg.gameObject:SetActive(false)
	    --self.Controls.m_LanMark.gameObject:SetActive(true)
	else 
		--self.Controls.m_LanBg.gameObject:SetActive(true)
	    --self.Controls.m_LanMark.gameObject:SetActive(false)
	end
	self.m_blueCompoSelected =false
	self.m_greenComposeSelected = true
	for i, item in pairs(self.m_EquipDecomposeItemTable) do 
		item:SetEquipChooseStatus(on)
	end
end

function PersonPackSkepWidget:OnGreenEquipTpgSelected(on)
	if on then 
	
		self.m_greenComposeSelected = true

	else 
		self.m_greenComposeSelected = false

	end
	for i, item in pairs(self.m_EquipDecomposeItemTable) do 
		item:SetEquipChooseStatus(on,1)
	end
end

function PersonPackSkepWidget:OnBlueEquipTpgSelected(on)
	if on then 
		self.m_blueCompoSelected =true

	else 
		self.m_blueCompoSelected =false

	end
	for i, item in pairs(self.m_EquipDecomposeItemTable) do 
		item:SetEquipChooseStatus(on,2)
	end
end


-- 一键分解
function PersonPackSkepWidget:OnBtnDecomposeClick()
	local tGoodsUID = {}
	local curSize   = 0
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if packetPart and packetPart:IsLoad() then
		tGoodsUID = packetPart:GetAllGoods()
		curSize = packetPart:GetSize()
	else 
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你没有要分解的装备")
		return 
	end
	local tFilterGoods = self:FilterGoodsByQuality(tGoodsUID, curSize)
	if not next(tFilterGoods) then 
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你没有要分解的装备")
		return
	end
	self.m_greenComposeSelected =true
	self.m_blueCompoSelected =false
	self.Controls.btnActionDecompose.gameObject:SetActive(false)
	self.Controls.wareBtn.gameObject:SetActive(false)
	self.Controls.btnActionSort.gameObject:SetActive(false)
	self.Controls.btnCancelDecompose.gameObject:SetActive(true)
	self.Controls.btnConfirmDecompose.gameObject:SetActive(true)
	
	self.m_bDecompose = true
	--self.Controls.m_LanText.gameObject:SetActive(true) 
	self.Controls.m_LanDefaultSelected.gameObject:SetActive(true)
	self.Controls.m_GreenEquipTpg.isOn = true
	self.Controls.m_BlueEquipTpg.isOn = false
	--self.Controls.m_LanBg.gameObject:SetActive(true)
	--self.Controls.m_LanMark.gameObject:SetActive(false)
	self.Controls.m_DecomposeInfo.gameObject:SetActive(true) 
	self.Controls.listViewSkepGoods.gameObject:SetActive(false)
	self.Controls.listViewDecomposeSkepGoods.gameObject:SetActive(true)
	self:ReloadData()
	
	rktTimer.SetTimer(function() self:ShowDetailInfo() end, 100, 1, "PersonPackSkepWidget:OnBtnDecomposeClick")

end

function PersonPackSkepWidget:ShowDetailInfo() 
	if not self:isLoaded() then
		return
	end
	local strDetailInfo = self:GetDecomposeDetailInfo()

	local chatText,FunText,maxHeight = RichTextHelp.AsysSerText(strDetailInfo,32)
	self.FunText = FunText
	if strDetailInfo then 
		self.Controls.DecomposeRichText.text = chatText
    else 
		self.Controls.m_DetailInfo.text = ""
	end
end

function PersonPackSkepWidget:GetDecomposeDetailInfo()
	local equipDecomposeUidTable = self.m_EquipDecomposeUidTable
	local nTotalSilverInfo = 0
	local itemTable = {}
	local strInfo   = ""
	for i, uid in pairs(equipDecomposeUidTable) do 
		local entity = IGame.EntityClient:Get(uid) 
		if entity then 
			local nQuality = entity:GetNumProp(EQUIP_PROP_QUALITY)
			local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
			if schemeInfo then
				local nBaseLevel = schemeInfo.BaseLevel
				local decomposeInfo = IGame.rktScheme:GetSchemeInfo(EQUIPDECOMPOSE_CSV, nBaseLevel, nQuality)
                if decomposeInfo then 
					nTotalSilverInfo = nTotalSilverInfo + decomposeInfo.nSilverCoin
					
					local nItemId  = decomposeInfo.nItemId
					local nItemNum = decomposeInfo.nItemNum
					if nItemNum ~= nil then 
						if itemTable[nItemId] then 
							itemTable[nItemId] = itemTable[nItemId] + nItemNum
						else 
							itemTable[nItemId] = nItemNum
						end
					end
				end			
			end
		end
	end
	if nTotalSilverInfo ~= 0 then 	
	    strInfo = strInfo .. "可获得: "..nTotalSilverInfo.."银币," 
	end
	if next(itemTable) ~= nil then 
		if strInfo == "" then 
			strInfo = "可获得: "
		end
		for itemId , itemNum in pairs(itemTable) do
			local goodsInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, itemId)
			if goodsInfo then
				local entityInfo = {
				     ["goodsId"] = itemId
				}
				local strName = goodsInfo.szName
				local _, p = string.find(strName, "蓝")
				local ItemColor = DColorDef.getNameColor(0,goodsInfo.lBaseLevel)
				if p ~= nil then
					strInfo = strInfo .. " <herf><color=#"..ItemColor..">"..strName.."×"..itemNum.."</color><fun>ShowDecomposeGoodsInfo('"..tableToString(entityInfo).."')</fun></herf>,"  
				else 
					strInfo = strInfo .. " <herf><color=#"..ItemColor..">"..strName.."×"..itemNum.."</color><fun>ShowDecomposeGoodsInfo('"..tableToString(entityInfo).."')</fun></herf>,"
				end
				
			end
		end
	end
	strInfo = string.sub(strInfo, 1, -2)
	return strInfo
end

function PersonPackSkepWidget:OnGoodsNameClick(text,beginIndex,endIndex,FunText)
    RichTextHelp.OnClickAsysSerText(beginIndex,endIndex,FunText)
end

function ShowDecomposeGoodsInfo(entityInfo)
	local entityTable = stringToTable(entityInfo)
	local subInfo = {
		bShowBtnType	= 0, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
	}
    UIManager.GoodsTooltipsWindow:SetGoodsInfo(entityTable.goodsId, subInfo )
end

-- 取消分解
function PersonPackSkepWidget:OnBtnCancelDecomposeClick() 
	self.Controls.btnActionDecompose.gameObject:SetActive(true)
	self.Controls.wareBtn.gameObject:SetActive(true)
	self.Controls.btnActionSort.gameObject:SetActive(true)
	self.Controls.btnCancelDecompose.gameObject:SetActive(false)
	self.Controls.btnConfirmDecompose.gameObject:SetActive(false) 
	
	--self.Controls.m_LanText.gameObject:SetActive(false) 
	self.Controls.m_LanDefaultSelected.gameObject:SetActive(false)
	self.Controls.m_DecomposeInfo.gameObject:SetActive(false)
	self.Controls.m_DetailInfo.text = ""
    self.m_bDecompose = false
	self.m_EquipDecomposeUidTable = {}
	self.m_EquipDecomposeItemTable = {}
	self.Controls.listViewSkepGoods.gameObject:SetActive(true)
	self.Controls.listViewDecomposeSkepGoods.gameObject:SetActive(false)
	
	self:ReloadData()

end

-- 确认分解 
function PersonPackSkepWidget:OnBtnConfirmDecomposeClick() 
		
    local equipDecomposeUidTable = self:GetEquipDecomposeUidTable()
	
	local itemUIDList = {}
	local str = "" 
	if next(equipDecomposeUidTable) ~= nil then 
        local tipsFlag = false
		for i, uid in pairs(equipDecomposeUidTable) do 
			local entity = IGame.EntityClient:Get(uid) 
			if entity then
				local nQuality = entity:GetNumProp(EQUIP_PROP_QUALITY) 
				if nQuality > 2 then 
					tipsFlag = true
				end
				table.insert(itemUIDList,entity:GetUID())
			end
		end
		if table_count(itemUIDList) <= 0 then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请先勾选要分解的装备")
			return
		end
		if tipsFlag then
			local data = 
			{
				content = "分解装备包含了橙装或紫装，确认分解吗？",
				confirmCallBack = function() GameHelp.PostServerRequest("RequestBatchEquipDecompose("..tableToString(itemUIDList)..")") end,
			}	
			UIManager.ConfirmPopWindow:ShowDiglog(data)			
		else
			local strfun = "RequestBatchEquipDecompose("..tableToString(itemUIDList)..")"
			GameHelp.PostServerRequest(strfun)   
			local ComposeCount = #itemUIDList
			if not self:CheckCanCompose(ComposeCount) then 
				rktTimer.SetTimer(function() self:NextConfirmDecompose() end,300,1,"")
			end
		--    self:NextConfirmDecompose()
		end
	else 
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请先勾选要分解的装备")
		return 
	end
end

--检查是否有可分解的
function PersonPackSkepWidget:CheckCanCompose(ComposeCount)
	local equipGoods={}
	local allGoods ={}
	local curSize = 0
	local hero = GetHero()
	if nil == hero then 
		return false
	end
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if packetPart and packetPart:IsLoad() then
		allGoods = packetPart:GetAllGoods()
		curSize = packetPart:GetSize()
	end
	
	-- 根据标签筛选
	equipGoods = self:FilterGoodsByQuality(allGoods, curSize)
	if #equipGoods > ComposeCount then 
		return true
	else
		return false
	end
	
end

function PersonPackSkepWidget:NextConfirmDecompose()
	self.m_EquipDecomposeUidTable = {} 
	self.m_EquipDecomposeItemTable = {}
	self.m_bDecompose = false
	self.Controls.btnActionDecompose.gameObject:SetActive(true)
	self.Controls.btnActionSort.gameObject:SetActive(true)
	self.Controls.btnCancelDecompose.gameObject:SetActive(false)
	self.Controls.btnConfirmDecompose.gameObject:SetActive(false)
	self.Controls.listViewSkepGoods.gameObject:SetActive(true)
	self.Controls.listViewDecomposeSkepGoods.gameObject:SetActive(false)
	self.Controls.wareBtn.gameObject:SetActive(true)
	
	--self.Controls.m_LanText.gameObject:SetActive(false) 
	self.Controls.m_LanDefaultSelected.gameObject:SetActive(false)
	self.Controls.m_DecomposeInfo.gameObject:SetActive(false)
	self.Controls.m_DetailInfo.text = ""
	self:ReloadData()
end

function PersonPackSkepWidget:GetEquipDecomposeUidTable()
     return self.m_EquipDecomposeUidTable
end

function PersonPackSkepWidget:SetLanSelectedStatus()
	--self.Controls.m_LanText.gameObject:SetActive(false) 
	self.Controls.m_LanDefaultSelected.gameObject:SetActive(false)
	self.Controls.m_DecomposeInfo.gameObject:SetActive(false)
end

function PersonPackSkepWidget:SetDecomposeStatus(status) 
	self.Controls.m_btnDecompose.gameObject:SetActive(status)
	self.Controls.btnActionSort.gameObject:SetActive(status) 
	self.Controls.btnCancelDecompose.gameObject:SetActive(false)
	self.Controls.btnConfirmDecompose.gameObject:SetActive(false)
	self.Controls.listViewDecomposeSkepGoods.gameObject:SetActive(false)
	self.Controls.listViewSkepGoods.gameObject:SetActive(true)
	
	--self.Controls.m_LanText.gameObject:SetActive(false) 
	self.Controls.m_LanDefaultSelected.gameObject:SetActive(false)
	self.Controls.m_DecomposeInfo.gameObject:SetActive(false)
	self.Controls.m_DetailInfo.text = ""
end

function PersonPackSkepWidget:SetTaskStatus()
	self.Controls.btnCancelDecompose.gameObject:SetActive(false)
	self.Controls.btnConfirmDecompose.gameObject:SetActive(false)
	self.Controls.listViewDecomposeSkepGoods.gameObject:SetActive(false)
	--self.Controls.listViewSkepGoods.gameObject:SetActive(false)

	--self.Controls.m_LanText.gameObject:SetActive(false) 
	self.Controls.m_LanDefaultSelected.gameObject:SetActive(false)

	self.Controls.m_DecomposeInfo.gameObject:SetActive(false)
	
	self.Controls.m_DetailInfo.text = ""
end

function PersonPackSkepWidget:GetDecomposeStatus(status)
	return self.m_bDecompose
end

function PersonPackSkepWidget:InitDecomposeStatus() 
	self.m_bDecompose = false
end

-- 获取一行的数量
function PersonPackSkepWidget:GetRowCellCount()
	return PACKET_CELL_ITEM_COUNT_IN_LINE
end

-- 刷新冷却
function PersonPackSkepWidget:RefreshCool()
	if not self:isLoaded() then
		return
	end
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	local CoolInfoList = packetPart:GetCoolInfoList()
	if not CoolInfoList then
		return
	end
	
	local tGoodsUID = {}
	local itemType = "pack"
	local curSize = 0
	local maxSize = 0
	if packetPart and packetPart:IsLoad() then
		tGoodsUID = packetPart:GetAllGoods()
		curSize = packetPart:GetSize()
		maxSize = packetPart:GetMaxSize()
	end
	
	-- 根据标签筛选
	local tFilterGoods = {}
	tFilterGoods = self:FilterGoodsByTab(tGoodsUID, curSize)
	local LineCnt = math.ceil(table_count(tFilterGoods)/5)
	for LineCntTmp=1,LineCnt do
		local listcell_trans = self.Controls.skepGoodsCellList:Find("Container/Cell "..(LineCntTmp-1))
		if listcell_trans then
			local Cnt = listcell_trans.childCount
			if Cnt < PACKET_CELL_ITEM_COUNT_IN_LINE then -- 格子没加载完全
				return
			end
			for i = 1 , PACKET_CELL_ITEM_COUNT_IN_LINE , 1 do
				local itemCell = listcell_trans:GetChild( i - 1 )
				local itemIndex = (LineCntTmp - 1) * PACKET_CELL_ITEM_COUNT_IN_LINE + i
				if nil ~= itemCell.gameObject then
					local behav = itemCell:GetComponent(typeof(UIWindowBehaviour))
					if nil ~= behav then
						local item = behav.LuaObject
						if nil ~= item and item.windowName == "PackageItemCell" then
							local uidGoods = item:GetGoodsUID()
							if uidGoods and uidGoods ~= 0 then
								local entity = IGame.EntityClient:Get(uidGoods)
								if entity then
									local nGoodID = entity:GetNumProp(GOODS_PROP_GOODSID) or 0
									local CoolInfo = CoolInfoList[nGoodID]
									local leftAmount = 0
									if CoolInfo then
										leftAmount = CoolInfo.LeftTime / CoolInfo.TotalTime
									end
									item:SetCoolImg(leftAmount) 
								end
							end
						end
					end
				end
			end
		end
	end
end




return this