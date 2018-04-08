------------------------------------------------------------

local PackWindow = UIWindow:new
{
	windowName = "PackWindow",
	tabName = {
		emAll = 0,
		emGeneral = 1,
		emOther = 2,
		emWare = 3,
		emMax = 4,
	},
	curTab = 0,
    
    -- 移除物品是否要更新
    bRemoveGoodNeedLoad = true,
}



local titleImagePath = AssetPath.TextureGUIPath.."Bag/Bag_beibao.png"
------------------------------------------------------------
function PackWindow:Init()
    self.PersonPackSkepWidget = require("GuiSystem.WindowList.Package.PersonPackSkepWidget")
	self.PersonWareSkepWidget = require("GuiSystem.WindowList.Package.PersonWareSkepWidget")
	self.PersonEquipSkepWidget = require("GuiSystem.WindowList.Package.PersonEquipSkepWidget")
	
	self.NeedReload = false
end
------------------------------------------------------------
function PackWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
    self.PersonPackSkepWidget:Attach( self.transform:Find("PersonPack_Skep_Wight").gameObject )
	self.PersonWareSkepWidget:Attach( self.transform:Find("PersonPack_Ware_Wight").gameObject )
	self.PersonEquipSkepWidget:Attach( self.transform:Find("PersonPack_Equip_Wight").gameObject )
	self.callback_OnCloseButtonClick =	function() self:CloseButtonClick() end
	self.PersonWareSkepWidget:Hide()
	UIWindow.AddCommonWindowToThisWindow(self,true,titleImagePath,self.callback_OnCloseButtonClick,nil,function()self:SetFullScreen() end,true)

   -- self:SetFullScreen() -- 设置为全屏界面

	self.Controls.ToggleGroup = self.transform:Find( "ButtonType_List" ):GetComponent(typeof(ToggleGroup))
	
	self:AddListeners()
	if self.needUpdate then
		self.needUpdate = false
		self:Update()
	end
	
    return self
end
------------------------------------------------------------
------------------------------------------------------------
function PackWindow:_showWindow()
	UIWindow._showWindow(self)
	IGame.Network:Send({}, MSG_MODULEID_SKEP, MSG_SKEP_OPEN_UI, MSG_ENDPOINT_ZONE)
		--打开背包显示常用界面
	self.curTab = self.tabName.emAll
	if self:isLoaded() then
		self.Controls.ToggleAll.isOn = true
		self:Update()
	else
		self.needUpdate = true
	end
end


function PackWindow:Show(bringTop)
	UIWindow.Show(self,bringTop)
	if self:isLoaded() then
		self.PersonWareSkepWidget:Hide()
	end
end

function PackWindow:Update()
	self:ShowByTab()
	if self.NeedReload then
		if self.PersonWareSkepWidget:isShow() then
			self.PersonWareSkepWidget:ReloadData()
		end
		self.PersonPackSkepWidget:ReloadData()
	end
	
	self.PersonEquipSkepWidget:ReloadData()	
end
------------------------------------------------------------
------------------------------------------------------------
------------------------------------------------------------
function PackWindow:OnDestroy()
	self:RemoveListeners()
	UIWindow.OnDestroy(self)
    self.bRemoveGoodNeedLoad = true
end
------------------------------------------------------------
-- 关闭
function PackWindow:CloseButtonClick()
	--[[IGame.Network:Send({}, MSG_MODULEID_SKEP, MSG_SKEP_CLOSE_UI, MSG_ENDPOINT_ZONE)
	if self:isLoaded() then
		self.PersonEquipSkepWidget:ShowHeroModel(false)
		self:Hide()
	end--]]
	
end
-- 订阅事件
function PackWindow:SubscribeWinExecute()
	self:InitCallbacks()
	rktEventEngine.SubscribeExecute(EVENT_SKEP_ON_TIDY, SOURCE_TYPE_SKEP, 0, self.callback_OnEventTidy)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_WARE_LOAD, SOURCE_TYPE_SKEP, 0, self.callback_OnEventWareLoad)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_WIDGET_RELOAD, SOURCE_TYPE_SKEP, 0, self.callback_OnEventWidgetReload)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_FILL_EMPTY, SOURCE_TYPE_SKEP, 0, self.callback_OnEventFillEmpty)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_PACKET_TO_WARE, SOURCE_TYPE_SKEP, 0, self.callback_OnEventPacketToWare)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_WARE_TO_PACKET, SOURCE_TYPE_SKEP, 0, self.callback_OnEventWareToPacket)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_UNEQUIP, SOURCE_TYPE_SKEP, 0, self.callback_OnEventUnEquip)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_ONEQUIP, SOURCE_TYPE_SKEP, 0, self.callback_OnEventOnEquip)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_ONEQUIP_BATTLE_BOOK, SOURCE_TYPE_SKEP, 0, self.callback_OnEventOnEquipBattleBook)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_UNLOCK, SOURCE_TYPE_SKEP, 0, self.callback_OnEventUnlock)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_RENAME, SOURCE_TYPE_SKEP, 0, self.callback_OnEventReName)
	rktEventEngine.SubscribeExecute(EVENT_APPEAR_CLOSE_RAPPEAR, 0, 0, self.callback_OnReOpenHeroModel)
end

-- 取消订阅事件
function PackWindow:UnSubscribeWinExecute()
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_ON_TIDY, SOURCE_TYPE_SKEP, 0, self.callback_OnEventTidy)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_WARE_LOAD, SOURCE_TYPE_SKEP, 0, self.callback_OnEventWareLoad)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_WIDGET_RELOAD, SOURCE_TYPE_SKEP, 0, self.callback_OnEventWidgetReload)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_FILL_EMPTY, SOURCE_TYPE_SKEP, 0, self.callback_OnEventFillEmpty)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_PACKET_TO_WARE, SOURCE_TYPE_SKEP, 0, self.callback_OnEventPacketToWare)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_WARE_TO_PACKET, SOURCE_TYPE_SKEP, 0, self.callback_OnEventWareToPacket)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_UNEQUIP, SOURCE_TYPE_SKEP, 0, self.callback_OnEventUnEquip)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_ONEQUIP, SOURCE_TYPE_SKEP, 0, self.callback_OnEventOnEquip)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_ONEQUIP_BATTLE_BOOK, SOURCE_TYPE_SKEP, 0, self.callback_OnEventOnEquipBattleBook)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_UNLOCK, SOURCE_TYPE_SKEP, 0, self.callback_OnEventUnlock)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_RENAME, SOURCE_TYPE_SKEP, 0, self.callback_OnEventReName)
	rktEventEngine.UnSubscribeExecute(EVENT_APPEAR_CLOSE_RAPPEAR, 0, 0, self.callback_OnReOpenHeroModel)
end

-- 整理包裹事件
function PackWindow:OnEventTidy(DBSkepID)
	if not self:isShow() or not DBSkepID then
		self.NeedReload = true
		return
	end
	
	if DBSkepID == GOODS_SKEPID_PACKET then
		if self:IsWareTab() then
			self.PersonWareSkepWidget:ReloadPackData()	
		end
		self.PersonPackSkepWidget:ReloadData()
	elseif DBSkepID == GOODS_SKEPID_WARE and self:IsWareTab() then
		self.PersonWareSkepWidget:RefreshCurrentWareData()
	end
end

-- 仓库加载事件
function PackWindow:OnEventWareLoad()
	if not self:isShow() then
		self.NeedReload = true
		return
	end
	
--[[	if not self:IsWareTab() then
		return
	end--]]
	
	self:ShowWareTab()
	self.PersonWareSkepWidget:ReloadData()
	self.PersonEquipSkepWidget:ReloadData()	
end

-- 添加新物品事件
function PackWindow:OnEventAddGoods()
	if not self:isShow() then
		self.NeedReload = true
		return
	end
	
	if self:IsWareTab() then
		self.PersonWareSkepWidget:RefreshData()
	else
		self.PersonPackSkepWidget:RefreshData()
	end
	self.PersonEquipSkepWidget:ReloadData()	
end

-- 重新加载事件
function PackWindow:OnEventWidgetReload()
	self.NeedReload = true
end

-- 删除物品事件
function PackWindow:OnEventRemoveGoods()
    if not self.bRemoveGoodNeedLoad then
        return
    end
        
	if not self:isShow() then
		self.NeedReload = true
		return
	end
	
	if self:IsWareTab() then
		self.PersonWareSkepWidget:RefreshData()
	else
		self.PersonPackSkepWidget:ReloadData()
	end
	self.PersonEquipSkepWidget:ReloadData()	
end

-- 填充空位事件
function PackWindow:OnEventFillEmpty()
	if not self:isShow() then
		self.NeedReload = true
		return
	end
	
	if self:IsWareTab() then
		self.PersonWareSkepWidget:RefreshData()
	else
		self.PersonPackSkepWidget:ReloadData()
	end
end

-- 标签切换
function PackWindow:OnToggleChanged(on, tabIndex)
	if not on then -- 标签关闭不用响应
		return
	end
	
	if self.curTab == tabIndex then -- 相同标签不用响应
		return
	end
	
	self.curTab = tabIndex
	
	-- 如果是仓库，要判断是否加载
	if tabIndex == self.tabName.emWare then
		local warePart = GetHero():GetEntityPart(ENTITYPART_PERSON_WARE)
		if not warePart then
			return
		end
		
		if not warePart:IsLoad() then
			IGame.SkepClient.RequestOpenWare()
			return
		end
	end
	
	self.PersonPackSkepWidget:SetLanSelectedStatus()
	 
	if self:IsTaskTab() then 
		self:ShowPackTab()
		self.PersonPackSkepWidget:ReloadTaskData()
	else
		self:ShowPackTab()
		self.PersonPackSkepWidget:ReloadData()
	end
end

-- 显示仓库
function PackWindow:ShowWareTab()
	self.transform:Find("PersonPack_Ware_Wight").gameObject:SetActive(true)
	-- 初始化仓库名字
	self.PersonWareSkepWidget:InitWareName()
	--[[self.transform:Find("PersonPack_Skep_Wight").gameObject:SetActive(false)
	self.transform:Find("PersonPack_Equip_Wight").gameObject:SetActive(false)--]]
end

-- 显示包裹
function PackWindow:ShowPackTab()
	--self.transform:Find("PersonPack_Ware_Wight").gameObject:SetActive(false)
	self.transform:Find("PersonPack_Skep_Wight").gameObject:SetActive(true)
	self.transform:Find("PersonPack_Equip_Wight").gameObject:SetActive(true)
	if self:IsTaskTab() then 
		self.PersonPackSkepWidget:SetTaskStatus()
	else 
		self.NeedReload = true
		self.PersonPackSkepWidget:InitDecomposeStatus()
		self.PersonPackSkepWidget:SetDecomposeStatus(true)
	end
end

-- 根据标签加载数据
function PackWindow:ShowByTab()
	if self:IsWareTab() then
		self:ShowWareTab()
	else
		self:ShowPackTab()
	end
end

-- 仓库
function PackWindow:IsWareTab()
	return self.PersonWareSkepWidget:isShow()
end 

-- 任务 
function PackWindow:IsTaskTab()
	return self.curTab == self.tabName.emGeneral
end 

-- 包裹
function PackWindow:IsPacketTab()
	return self.curTab >= self.tabName.emAll and self.curTab <= self.tabName.emOther
end

-- 获取当前标签
function PackWindow:GetCurTab()
	return self.curTab
end

-- 移动至仓库事件
function PackWindow:OnEventPacketToWare()
	if not self:isShow() then
		self.NeedReload = true
		return
	end
	
	self.PersonWareSkepWidget:RefreshData()
	self.PersonPackSkepWidget:RefreshData()
	self.PersonEquipSkepWidget:ReloadData()	
end

-- 移动至包裹事件
function PackWindow:OnEventWareToPacket()
	if not self:isShow() then
		self.NeedReload = true
		return
	end

	self.PersonWareSkepWidget:RefreshData()
	self.PersonPackSkepWidget:RefreshData()
	self.PersonEquipSkepWidget:ReloadData()	
end

-- 脱装备
function PackWindow:OnEventUnEquip(fromPlace)
	if not self:isShow() then
		self.NeedReload = true
		return
	end
	
	if self:IsPacketTab() then
		self.PersonEquipSkepWidget:ClearCell(fromPlace)
	end
end

-- 穿武学书
function PackWindow:OnEventOnEquipBattleBook()
	if not self:isShow() then
		self.NeedReload = true
		return
	end
	
	if self:IsPacketTab() then
		self.PersonPackSkepWidget:ReloadData()
	end
end

-- 穿装备
function PackWindow:OnEventOnEquip(toPlace, bNeedRefreshPack)
	if not self:isShow() then
		self.NeedReload = true
		return
	end
	
	if self:IsPacketTab() then
		self.PersonEquipSkepWidget:SetCell(toPlace)
		if bNeedRefreshPack then
			self.PersonPackSkepWidget:ReloadData()
		end
	end
	self.PersonEquipSkepWidget:ReloadData()	
end

-- 获取一行格子数量
function PackWindow:GetRowCellCount(DBSkepID)
	if DBSkepID == GOODS_SKEPID_PACKET then
		return self.PersonPackSkepWidget:GetRowCellCount()
	elseif DBSkepID == GOODS_SKEPID_WARE then
		return self.PersonWareSkepWidget:GetRowCellCount()
	else
		return 0
	end
end

function PackWindow:UpdateEquipTotalScore(totalScore)
	self.PersonEquipSkepWidget:UpdateEquipTotalScore(totalScore)
end

-- 解锁
function PackWindow:OnEventUnlock(skepID)
	if not self:isShow() then
		self.NeedReload = true
		return
	end
	
	if skepID == GOODS_SKEPID_PACKET then
		if self:IsPacketTab() then
			self.PersonPackSkepWidget:RefreshData()
		else
			self.PersonWareSkepWidget:ReloadPackData()
		end
	elseif skepID == GOODS_SKEPID_WARE then
		
		
		self.PersonWareSkepWidget:ReloadData()
	end
end

function PackWindow:OnEventReName(nPageIndex, szName)
	self.PersonWareSkepWidget:InitWareName()
end

function PackWindow:SetEquipDecomposeUID(equipUID, flag)
    self.PersonPackSkepWidget:SetEquipDecomposeUID(equipUID, flag)
end

function  PackWindow:RenameWareLabel(newName)
	self.PersonWareSkepWidget:RenameWareLabel(newName)
end

function PackWindow:GetDecomposeStatus() 
	local decomposeStatus = self.PersonPackSkepWidget:GetDecomposeStatus() 
	return decomposeStatus
end

function PackWindow:GetWareCurPageIndex()
    local tabIndex = self.PersonWareSkepWidget:GetCurWareTab() 
	return tabIndex
end

function PackWindow:NextConfirmDecompose()
	self.PersonPackSkepWidget:NextConfirmDecompose() 
end

function PackWindow:OnReOpenHeroModel()
	if self:isShow() then
		self.PersonEquipSkepWidget:ReOpenHeroModel()
	end
end

-- 添加listener
function PackWindow:AddListeners()
	self.Controls.ToggleAll.onValueChanged:AddListener(self.callback_OnToggleAll)
	self.Controls.ToggleGeneral.onValueChanged:AddListener(self.callback_OnToggleGeneral)
	self.Controls.WareBtn.onClick:AddListener(self.OnClickWare)
end

-- 删除listener
function PackWindow:RemoveListeners()
	self.Controls.ToggleAll.onValueChanged:RemoveListener(self.callback_OnToggleAll)
	self.Controls.ToggleGeneral.onValueChanged:RemoveListener(self.callback_OnToggleGeneral)
	self.Controls.WareBtn.onClick:RemoveListener(self.OnClickWare)
end

function PackWindow:RefreshPackGoodsCool(nGoodID,CoolInfo)
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local packetPart = pHero:GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	local nCurSize = packetPart:GetSize()
	local leftAmount = CoolInfo.LeftTime / CoolInfo.TotalTime
	for i=1,nCurSize do
		local UID = packetPart:GetGoodsUIDByPos(i)
		local entity = IGame.EntityClient:Get(UID)
		if entity and entity:GetNumProp(GOODS_PROP_GOODSID) == nGoodID then
			
		end
	end
end

-- 初始化全局回调函数
function PackWindow:InitCallbacks()
	self.callback_OnEventTidy =	function(event, srctype, srcid, DBSkepID) self:OnEventTidy(DBSkepID) end
	self.callback_OnEventWareLoad = function() self:OnEventWareLoad() end
	self.callback_OnEventAddGoods = function() self:OnEventAddGoods() end
	self.callback_OnEventWidgetReload = function() self:OnEventWidgetReload() end
	self.callback_OnEventRemoveGoods = function() self:OnEventRemoveGoods() end
	self.callback_OnEventFillEmpty = function() self:OnEventFillEmpty() end
	self.callback_OnEventPacketToWare = function() self:OnEventPacketToWare() end
	self.callback_OnEventWareToPacket = function() self:OnEventWareToPacket() end
	self.callback_OnEventUnEquip = function(event, srctype, srcid, fromPlace) self:OnEventUnEquip(fromPlace) end
	self.callback_OnEventOnEquip = function(event, srctype, srcid, toPlace, bNeedRefreshPack) self:OnEventOnEquip(toPlace, bNeedRefreshPack) end
	self.callback_OnEventOnEquipBattleBook = function() self:OnEventOnEquipBattleBook() end
	self.callback_OnEventUnlock = function(event, srctype, srcid, skepID) self:OnEventUnlock(skepID) end
	self.callback_OnEventReName = function(event, srctype, srcid, nPageIndex, szName) self:OnEventReName(nPageIndex, szName) end
	
	self.callback_OnToggleAll = function(on) self:OnToggleChanged(on, self.tabName.emAll) end
	self.callback_OnToggleGeneral = function(on) self:OnToggleChanged(on, self.tabName.emGeneral) end
	--self.callback_OnToggleOther = function(on) self:OnToggleChanged(on, self.tabName.emOther) end
	self.OnClickWare = function() self:OnClickOpenWare() end
	self.callback_OnReOpenHeroModel = function() self:OnReOpenHeroModel() end
end

function PackWindow:OnClickOpenWare()
	local warePart = GetHero():GetEntityPart(ENTITYPART_PERSON_WARE)
	if not warePart then
		return
	end
		
	if not warePart:IsLoad() then
		IGame.SkepClient.RequestOpenWare()
		return
	end
	self.PersonPackSkepWidget:SetLanSelectedStatus()
	self:ShowWareTab()
	self.PersonWareSkepWidget:ReloadData()	
end

function PackWindow:ShowGoodLeftTime(nGoodID)
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	local CoolingList = packetPart:GetCoolInfoList()
	if not CoolingList[nGoodID] then
		return
	end
	local nGoodCDInfo = CoolingList[nGoodID]
	if nGoodCDInfo.ShowTipsTime and Time.realtimeSinceStartup - nGoodCDInfo.ShowTipsTime <= 1  then
		return
	end
	local nTime = nGoodCDInfo.LeftTime/1000
	local nTimeText = string.format("%.1f", nTime)
	IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "该物品还有"..nTimeText.."秒冷却结束")
	nGoodCDInfo.ShowTipsTime = Time.realtimeSinceStartup
end

function PackWindow:RefreshCool()
	if not self:isShow() then
		return
	end
	self.PersonPackSkepWidget:RefreshCool()
end

-- 解锁背包一行，仓库一页确认框函数
function PackWindow:UnLockConfirmFun(unlockSkepID, unlockCost, pageIndex)

	local totalYuanbao = GetHero():GetActorYuanBao() 
	if unlockCost > totalYuanbao then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你的钻石不足"..self.unlockCost..", 无法解锁")
		return		
	end

	local msg = {}
	if unlockSkepID == GOODS_SKEPID_PACKET then
		local rowCellCount = UIManager.PackWindow:GetRowCellCount(self.unlockSkepID)
		msg = {nDBSkepID = unlockSkepID, nUnlockNum = rowCellCount}
	else
		msg = {nDBSkepID = unlockSkepID, nPageIndex = pageIndex-1, nUnlockNum = 40}
	end
	
	IGame.Network:Send(msg, MSG_MODULEID_SKEP, MSG_SKEP_UNLOCK_CS, MSG_ENDPOINT_ZONE)
end

-- 设置物品减少背包是否刷新
function PackWindow:SetRemoveGoodNeedLoadFlag(flag)
    self.bRemoveGoodNeedLoad = flag
end

return PackWindow
