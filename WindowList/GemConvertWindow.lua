---------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    Sheepy
-- 日  期:    2017/06/29
-- 版  本:    1.0
-- 描  述:    宝石转换窗口
---------------------------------------------------------------------

local GemInfoCellClass = require( "GuiSystem.WindowList.CommonWindow.GemInfoCell" )
local GemConvertWindow = UIWindow:new
{
	windowName = "GemConvertWindow",
	m_tHavedGemListTable = {},
	m_tTargetGemListTable = {},
	m_SecHavedGemInfo = {},
	m_SecHavedGemCell = nil,    
	m_TarGemID = 0,
}


local this = GemConvertWindow					-- 方便书写
local zero = int64.new("0")

------------------------------------------------------------
function GemConvertWindow:Init()
	self.m_tHavedGemListTable = {}
	self.m_tTargetGemListTable = {}
	self.m_SecHavedGemInfo = {}
	self.m_SecHavedGemCell = nil
	self.m_TarGemID = 0
end

------------------------------------------------------------
function GemConvertWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	
	-- 注册关闭按钮
	self.Controls.m_CloseBtn.onClick:AddListener(function() self:Init() self:Hide() end)
	self.Controls.m_BackBtn.onClick:AddListener(function() self:Init() self:Hide() end)
	
	-- 注册宝石转换按钮
	self.Controls.m_ConvertButton.onClick:AddListener(function() self:OnConvertButtonClick() end)
	
	-- 注册银两
	self.Controls.m_ChongZhiButton.onClick:AddListener(function() self:OnChongZhitButtonClick() end)
	
	-- 包裹事件
	self.Controls.listViewHavedGem = self.Controls.m_HavedGemList:GetComponent(typeof(EnhancedListView))
	--UIFunction.AddEventTriggerListener( self.Controls.m_ClosBtnTrans , EventTriggerType.PointerClick , function( eventData ) self:OnCloseButtonClick(eventData) end )
	self.callback_OnGetCellView = function(goCell) self:OnGetCellView(goCell) end
	self.Controls.listViewHavedGem.onGetCellView:AddListener(self.callback_OnGetCellView)
	
	self.callback_OnCellViewVisiable = function(goCell) self:OnCellViewVisiable(goCell) end
	self.Controls.listViewHavedGem.onCellViewVisiable:AddListener(self.callback_OnCellViewVisiable)
	
	self.Controls.scrollerHavedGem = self.Controls.m_HavedGemList:GetComponent(typeof(EnhancedScroller))
	--self.Controls.scrollerSkepGoods.scrollerScrollingChanged = PersonPackSkepWidget.SkepGoodsListViewScrollingChanged
	self.Controls.GoodsToggleGroup = self.Controls.m_HavedGemList:GetComponent(typeof(ToggleGroup)) 
	
	self.callBack_OnHavedCellChanged =function(GemCell,on) self:OnHavedCellChanged(GemCell,on) end
	
	-- 要显示的行数  
	self.m_tHavedGemListTable = self:FilterAllGemOfPacket(1)
	self.m_nCount = table.getn(self.m_tHavedGemListTable)

	self.Controls.listViewHavedGem:SetCellCount( self.m_nCount , true )
	
	self.callback_OnTargetGemInfoCellChanged = function(GemCell,on) self:OnTargetGemInfoCellChanged(GemCell,on) end
	for i=1,13 do
		self.Controls["m_TargetGemInfoCellTans"..i] = self.Controls.m_TargetGemListGrid.transform:Find("TargetGemInfoCell ("..i..")")
		self.Controls["m_TargetGemInfoCell"..i] = GemInfoCellClass:new()
		self.Controls["m_TargetGemInfoCell"..i]:Attach(self.Controls["m_TargetGemInfoCellTans"..i].gameObject)
		self.Controls["m_TargetGemInfoCell"..i].Controls.GoodCell:ChildSetActive("Count",true)
		self.Controls["m_TargetGemInfoCell"..i]:SetItemCellSelectedCallback(self.callback_OnTargetGemInfoCellChanged)
	end
	
	--- 处理二次确认框
	self.ConvertSurWidget = UIControl:new{windowName = "ConvertSurWidget"}
	UIControl.Attach(self.ConvertSurWidget,self.Controls.m_ConvertSurWidget.gameObject)
	
	self.Controls.m_SurCloseBtn = self.ConvertSurWidget.Controls.m_CloseBtn
	self.Controls.m_SurNumJianBtn = self.ConvertSurWidget.Controls.m_NumJianBtn
	self.Controls.m_SurNumJiaBtn = self.ConvertSurWidget.Controls.m_NumJiaBtn
	self.Controls.m_SurBtn = self.ConvertSurWidget.Controls.m_SurBtn
	
	self.Controls.m_SurConvertNum = self.ConvertSurWidget.Controls.m_ConvertNum
	self.Controls.m_SurConsumeNum = self.ConvertSurWidget.Controls.m_ConsumeNum
	self.Controls.m_SurContentText = self.ConvertSurWidget.Controls.m_ContentText
	
	self.Controls.m_SurCloseBtn.onClick:AddListener(function () self.ConvertSurWidget:Hide() end)
	self.Controls.m_SurNumJianBtn.onClick:AddListener(function () self:OnSurNumJianBtnClick() end)
	self.Controls.m_SurNumJiaBtn.onClick:AddListener(function () self:OnSurNumJiaBtnClick() end)
	self.Controls.m_SurBtn.onClick:AddListener(function () self:OnSurBtnClick() end)
	self.ConvertSurWidget:Hide()
	self:SubscribeEvent()
    
    --self:Refresh()
end

function GemConvertWindow:OnEventTriggerClick(eventData)
    rkt.UIAndTextHelpTools.PassThroughPointerClickEvent( eventData )
end

------------------------------------------------------------
-- 窗口销毁
function GemConvertWindow:OnDestroy()
	self:UnsubscribeEvent()
	UIWindow.OnDestroy(self)
end

--========================/按钮回调\============================================

------------------------------------------------------------
function GemConvertWindow:OnCloseButtonClick( eventData )
	self:Init()
    self:Hide()
    rkt.UIAndTextHelpTools.PassThroughPointerClickEvent( eventData )
end

--------------------------------------------------------------------------------
-- 转换数量 减
function GemConvertWindow:OnSurNumJianBtnClick()
	local TextTmp = self.Controls.m_SurConvertNum.text
	local CurNum = tonumber(TextTmp)
	if CurNum and type(CurNum) == "number" and CurNum > 1 then
		CurNum = CurNum - 1
	end
	self.Controls.m_SurConvertNum.text = CurNum
	self:RefreshSurCunsumeDiamond()
end

--------------------------------------------------------------------------------
-- 转换数量 加
function GemConvertWindow:OnSurNumJiaBtnClick()
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local packetPart = pHero:GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	local NumMax = packetPart:GetGoodNum(self.m_SecHavedGemInfo.nGoodID) or 0
	local TextTmp = self.Controls.m_SurConvertNum.text
	local CurNum = tonumber(TextTmp)
	if CurNum and type(CurNum) == "number" and CurNum < NumMax then
		CurNum = CurNum + 1
	end
	self.Controls.m_SurConvertNum.text = CurNum
	self:RefreshSurCunsumeDiamond()
end

--------------------------------------------------------------------------------
-- 确认转换
function GemConvertWindow:OnSurBtnClick()
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local packetPart = pHero:GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	if self.m_TarGemID == self.m_SecHavedGemInfo.nGoodID then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "相同类型宝石不可以转换哦！(＾＿＾)")
		return
	end
	local TextTmp = self.Controls.m_SurConvertNum.text
	local CurNum = tonumber(TextTmp)
	if not CurNum or CurNum <= 0 then
		return
	end
	-- 获得Hero的银两
	local YinLiang	= pHero:GetActorYuanBao()
	local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)	-- 获取职业
	local pGemPropScheme = forgePart.m_SettingCfgCenter:GetGemProp( self.m_TarGemID, nVocation) or {}
	if not pGemPropScheme or not pGemPropScheme.nGemLv then
		return
	end
	local pGemPropConvertScheme = IGame.rktScheme:GetSchemeInfo(GEMPROPCONVERT_CSV, pGemPropScheme.nGemLv)
	if not pGemPropConvertScheme then
		print("找不到宝石转换消耗配置，宝石等级=", pGemPropScheme.nGemLv)
		return
	end
	local nCurConsume = CurNum * pGemPropConvertScheme.nConsume
	if nCurConsume > YinLiang then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "钻石不足！")
		return
	end
	GameHelp.PostServerRequest("RequestGemConvert("..tostringEx(self.m_SecHavedGemInfo)..","..self.m_TarGemID..","..tostring(CurNum)..")")
	self.ConvertSurWidget:Hide()
end
--========================\按钮回调/=============================================

function GemConvertWindow:RefreshSurCunsumeDiamond()
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local packetPart = pHero:GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	
	local TextTmp = self.Controls.m_SurConvertNum.text
	local CurNum = tonumber(TextTmp)
	if not CurNum then
		self.Controls.m_SurConsumeNum.text = "0"
		self.Controls.m_SurContentText = 0
		return
	end
	
	local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)	-- 获取职业
	-- 原料宝石属性
	local pConsumeGemPropScheme = forgePart.m_SettingCfgCenter:GetGemProp( self.m_SecHavedGemInfo.nGoodID, nVocation) or {}
	if not pConsumeGemPropScheme then
		return
	end
	
	local pGemPropScheme = forgePart.m_SettingCfgCenter:GetGemProp( self.m_TarGemID, nVocation) or {}
	if not pGemPropScheme or not pGemPropScheme.nGemLv then
		return
	end
	--cLog("pGemPropScheme.nGemLv "..pGemPropScheme.nGemLv)
	local pGemPropConvertScheme = IGame.rktScheme:GetSchemeInfo(GEMPROPCONVERT_CSV, pConsumeGemPropScheme.nGemLv)
	if not pGemPropConvertScheme then
		print("找不到宝石转换消耗配置，宝石等级=", pConsumeGemPropScheme.nGemLv)
		return
	end
	local nCurConsume = CurNum * pGemPropConvertScheme.nConsume
	self.Controls.m_SurConsumeNum.text = nCurConsume
	local szSurContentText = "要将<color=blue>"..CurNum.."</color>颗"..pConsumeGemPropScheme.szGemTypeDes.."宝石转换成同等数量的"
	szSurContentText = szSurContentText..pGemPropScheme.szGemTypeDes.."宝石？"
	self.Controls.m_SurContentText.text = szSurContentText
end
--------------------------------------------------------------------------------
-- 设置最大行数
function GemConvertWindow:SetCellCnt(CellCount)
    if not self:isShow() then
        return
    end
	self.Controls.listViewHavedGem:SetCellCount( CellCount , true )
end

--------------------------------------------------------------------------------
-- 创建滴答格子
function GemConvertWindow:CreateCellItems( listcell )
	local item = GemInfoCellClass:new({})
	item:Attach(listcell.gameObject)
	self:RefreshCellItems(listcell)
end


--------------------------------------------------------------------------------
--- 刷新物品格子内容
function GemConvertWindow:RefreshCellItems( listcell )
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	local item = behav.LuaObject
	if item == nil then
		uerror("GemConvertWindow:RefreshCellItems item为空")
		return
	end
	if nil ~= item and item.windowName == "GemInfoCell" then
		local GemInfo = self.m_tHavedGemListTable[listcell.dataIndex + 1]
		local nCurSecGemID = self.m_SecHavedGemInfo.nGoodID or 0
		if GemInfo == nil then
			item:Hide()
			return
		end
		item:SetCellInfo(GemInfo)
		item:SetCellSeq(listcell.dataIndex)
		item:SetToggleGroup( self.Controls.GoodsToggleGroup )
		item:SetItemCellSelectedCallback( self.callBack_OnHavedCellChanged )
		--cLog("01 "..tostringEx(self.m_SecHavedGemCell).." -1- "..tostringEx(listcell.dataIndex ))
		if self.m_SecHavedGemCell == listcell.dataIndex then
			item:SetFocus(true)
		else
			item:SetFocus(false)
		end
		
	end
end


-- EnhancedListView 一行被“创建”时的回调
function GemConvertWindow:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))

	listcell.onRefreshCellView = handler( self , self.OnRefreshCellView )

	self:CreateCellItems(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function GemConvertWindow:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function GemConvertWindow:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end



function GemConvertWindow:SetShowGoodID(nGoodID,bNeedReLoad)
	self.m_tHavedGemListTable = self:FilterAllGemOfPacket(1)
	local HaveGoodsId = false
	for key,v in ipairs(self.m_tHavedGemListTable) do
		if nGoodID == v.nGoodID then
			self.m_SecHavedGemCell = key-1
			self.m_SecHavedGemInfo = v
			HaveGoodsId = true
			break
		end
	end
	if HaveGoodsId == false then
		if self.m_SecHavedGemCell and self.m_tHavedGemListTable[self.m_SecHavedGemCell + 1] then
			self.m_SecHavedGemInfo = self.m_tHavedGemListTable[self.m_SecHavedGemCell + 1]
		else
			self.m_SecHavedGemCell = 0
			self.m_SecHavedGemInfo = self.m_tHavedGemListTable[self.m_SecHavedGemCell + 1]
		end
	end
	self:Refresh(nSecHavedGemCell,bNeedReLoad)
end

function GemConvertWindow:Refresh(SecHavedGemCellSeq,bNeedReLoad)
    if not self:isLoaded() then
		DelayExecuteEx( 10,function ()
			self:Refresh(SecHavedGemCellSeq,bNeedReLoad)
		end)
        return
    end

	bNeedReLoad = bNeedReLoad or false
	local pHero = GetHero()
	if pHero == nil then
		return
	end

	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	self.m_tHavedGemListTable = self:FilterAllGemOfPacket(1)
	self.m_SecHavedGemCell = SecHavedGemCellSeq or self.m_SecHavedGemCell or 0
	if not self.m_tHavedGemListTable[self.m_SecHavedGemCell + 1] then
		self.m_SecHavedGemCell = 0
	end
	
	local nHavedGemCnt = table_count(self.m_tHavedGemListTable)
	if bNeedReLoad then
		self:SetCellCnt(nHavedGemCnt)
		self.Controls.scrollerHavedGem:ReloadData()
		if nHavedGemCnt > 5 then
			DelayExecuteEx(10,function () self:JumpToDataIndex( self.m_SecHavedGemCell )	end)
		end
	end
	
	local nSecGemID = self.m_SecHavedGemInfo.nGoodID
	if not nSecGemID then
		self.Controls.m_OneConsume.text = "0"
		return
	end

	local nCurGemInfo = self.m_tHavedGemListTable[self.m_SecHavedGemCell + 1]
	if not nCurGemInfo then
		return
	end
	local nCurGemLv = nCurGemInfo.nGemLv
	
	local nCurGemType = nCurGemInfo.nGemType
	
	self.m_tTargetGemListTable = self:GetSameLvGem(nCurGemLv)
	--print("同等级的宝石列表 ： \n"..tostringEx(self.m_tTargetGemListTable))
	for i=1,13 do
		local nTarGemIDTmp = self.m_tTargetGemListTable[i]
		if nSecGemID == nTarGemIDTmp then
			self.Controls["m_TargetGemInfoCell"..i]:Hide()
		else
			self.Controls["m_TargetGemInfoCell"..i]:Show()
			self.Controls["m_TargetGemInfoCell"..i]:SetCellGoodID(nTarGemIDTmp,"")
			if self.Controls["m_TargetGemInfoCell"..i]:GetFocus() then
				self.m_TarGemID = nTarGemIDTmp
			end
		end
	end
	if self.m_TarGemID == 0 then
		self.Controls["m_TargetGemInfoCell1"]:SetFocus(true)
	end
	--self.Controls["m_TargetGemInfoCell1"]

	local pGemPropConvertScheme = IGame.rktScheme:GetSchemeInfo(GEMPROPCONVERT_CSV, nCurGemLv)
	if not pGemPropConvertScheme then
		print("找不到宝石转换消耗配置，宝石等级=", pConsumeGemPropScheme.nGemLv)
		return
	end
	self.Controls.m_OneConsume.text = pGemPropConvertScheme.nConsume
end

function GemConvertWindow:JumpToDataIndex( itemIndex )
	self.Controls.scrollerHavedGem:JumpToDataIndex( itemIndex, 0 , 0 , true , EnhancedScroller.TweenType.immediate , 0.2, nil)
end

function GemConvertWindow:OnTargetGemInfoCellChanged(GemCell,on)
	if not on then
		return
	end
	self.m_TarGemID = GemCell.m_CellInfo.nGoodID
	--self:Refresh()
end

function GemConvertWindow:OnHavedCellChanged(GemCell,on)
	if not GemCell then
		return
	end
	--print("GemConvertWindow:OnHavedCellChanged<color=green>我的宝石</color>"..GemCell.m_Seq..","..tostringEx(on))
	if not on then
		return
	end
	self.m_SecHavedGemInfo = GemCell.m_CellInfo
	self.m_SecHavedGemCell = GemCell.m_Seq
	local pGemPropConvertScheme = IGame.rktScheme:GetSchemeInfo(GEMPROPCONVERT_CSV, GemCell.m_CellInfo.nGemLv)
	if not pGemPropConvertScheme then
		print("找不到宝石转换消耗配置，宝石等级=", pConsumeGemPropScheme.nGemLv)
		return
	end
	self.Controls.m_OneConsume.text = pGemPropConvertScheme.nConsume
	self:Refresh(GemCell.m_Seq,false)
end

function GemConvertWindow:OnConvertButtonClick()
	local nSecGemID = self.m_SecHavedGemInfo.nGoodID
	if not nSecGemID then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请选择要转换的宝石！")
		return
	end
	
	if self.m_TarGemID == 0 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请选择转换的目标宝石！")
		return
	end
	self.Controls.m_SurConvertNum.text = 1
	self.ConvertSurWidget:Show()
	self:RefreshSurCunsumeDiamond()
end

function GemConvertWindow:OnChongZhitButtonClick()
	UIManager.ShopWindow:OpenShop(2415)
	--UIManager.ShopWindow:ShowShopWindow(3)
end

-- 添加新物品事件
function GemConvertWindow:OnEventAddGoods()
	--print("GemConvertWindow:OnEventAddGoods<color=green>添加新物品事件</color>")
	if not self:isShow() then
		return
	end
	
	local SecGoodID = self.m_SecHavedGemInfo.nGoodID
	self:SetShowGoodID(SecGoodID,true)
end

-- 删除物品事件
function GemConvertWindow:OnEventRemoveGoods()
	self:OnEventAddGoods()
end

-- 订阅事件
function GemConvertWindow:SubscribeEvent()
	self:InitCallbacks()
	rktEventEngine.SubscribeExecute(EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
end

-- 取消订阅事件
function GemConvertWindow:UnsubscribeEvent()
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
	self:ClearCallbacks()
end

-- 初始化全局回调函数
function GemConvertWindow:InitCallbacks()
	self.callback_OnEventAddGoods = function() self:OnEventAddGoods() end
	self.callback_OnEventRemoveGoods = function() self:OnEventRemoveGoods() end
end

-- 清全局回调函数
function GemConvertWindow:ClearCallbacks()
	self.callback_OnEventAddGoods = nil
	self.callback_OnEventRemoveGoods = nil
end

function GemConvertWindow:GetSameLvGem(nGemLv)
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	local GemLvMap_KeyGemID = forgePart.m_SettingCfgCenter:GetGemLv_KeyGemLv(nGemLv)
	local SameLvGemList = {}
	for GemID,GemType in pairs(GemLvMap_KeyGemID) do
		table.insert(SameLvGemList,GemID)
	end
	return SameLvGemList
end

-- SortFlg 0:从小到大  1:从大到小
function GemConvertWindow:FilterAllGemOfPacket(SortFlg)
	SortFlg = SortFlg or 1
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local packetPart = pHero:GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	
	local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)	-- 获取职业
	
	local tGoodsUID = {} 
	local tFilterGoods = {}
	local curSize = 0
	local packetPart = pHero:GetEntityPart(ENTITYPART_PERSON_PACKET)
	if packetPart and packetPart:IsLoad() then
		tGoodsUID = packetPart:GetAllGoods()
		curSize = packetPart:GetSize()

		for i = 1, curSize do
			local uid = tGoodsUID[i]
			if uid then
				local entity = IGame.EntityClient:Get(uid)
				if entity then
					local entityClass = entity:GetEntityClass()
					if EntityClass:IsLeechdom(entityClass) then
						local nGoodIDTmp = entity:GetNumProp(GOODS_PROP_GOODSID)
						local nGoodNumTmp = entity:GetNumProp(GOODS_PROP_QTY)
						if forgePart.m_SettingCfgCenter:IsGemByID(nGoodIDTmp) then
							local pGemPropScheme = forgePart.m_SettingCfgCenter:GetGemProp( nGoodIDTmp, nVocation) or {}
							if pGemPropScheme and pGemPropScheme.nGemLv > 0 then
								local tmpTable = {}
								tmpTable.nGoodID	= nGoodIDTmp
								tmpTable.nGemLv		= pGemPropScheme.nGemLv or 0
								tmpTable.nGemType	= pGemPropScheme.nGemType or 0
								tmpTable.nGoodNum	= nGoodNumTmp
								tmpTable.nGoodUID	= uid
								tmpTable.nGoodValue	= pGemPropScheme.nGemValue or 0
								table.insert(tFilterGoods, tmpTable)
							end
						end
					end
				end
			end
		end
	end
	if SortFlg == 1 then
		table.sort(tFilterGoods, 
		function(a, b)
			if a.nGemLv ~= b.nGemLv then
				return a.nGemLv < b.nGemLv
			end
			return a.nGoodID < b.nGoodID
		end)
	elseif SortFlg == 2 then
		table.sort(tFilterGoods, 
		function(a, b)
			if a.nGemLv ~= b.nGemLv then
				return a.nGemLv > b.nGemLv
			end
			return a.nGoodID > b.nGoodID
		end)
	end
	--print("包裹里的宝石列表 ： \n"..tostringEx(tFilterGoods))
	return tFilterGoods
end






return GemConvertWindow







