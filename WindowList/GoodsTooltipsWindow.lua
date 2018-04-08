-- tooltips窗口
------------------------------------------------------------
local GoodsTooltipsWindow = UIWindow:new
{
	windowName = "GoodsTooltipsWindow",
	mNeedUpdate = false,
	m_entity = nil,
	m_nGoodID = nil,
}
------------------------------------------------------------
function GoodsTooltipsWindow:Init()
    --self.ButtonWidget = require("GuiSystem.WindowList.Tooltips.GoodsTooltipsButtonWidget")
	--.ButtonWidget1 = require("GuiSystem.WindowList.Tooltips.GoodsTooltipsButtonWidget1")
	self.BGWidget = require("GuiSystem.WindowList.Tooltips.GoodsTooltipsBGWidget")
	self:InitCallbacks()
end
------------------------------------------------------------
function GoodsTooltipsWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	
	local mainObj = self.transform:Find("MainWindow").gameObject
	
	local BGWidgetObj = mainObj.transform:Find("ToolTips_Bg_Wight").gameObject
	self.BGWidget:Attach(BGWidgetObj)

    UIFunction.AddEventTriggerListener( self.Controls.m_CloseButton , EventTriggerType.PointerClick , function( eventData ) self:OnCloseButtonClick(eventData) end )

	self:SubscribeEvent()
	if self.mNeedUpdate then
		self.mNeedUpdate = false
        if nil ~= self.m_entity then
            self:SetGoodsEntity(self.m_entity,self.m_subInfo)
        elseif nil ~= self.m_nGoodID then
            self:SetGoodsInfo(self.m_nGoodID,self.m_subInfo)
        end
	end
end

------------------------------------------------------------
function GoodsTooltipsWindow:OnDestroy()
	self:UnsubscribeEvent()
	UIWindow.OnDestroy(self)
end

------------------------------------------------------------
function GoodsTooltipsWindow:CloseWindow()
    self:Hide()
end

------------------------------------------------------------
function GoodsTooltipsWindow:OnCloseButtonClick( eventData )
    self:Hide()
    rkt.UIAndTextHelpTools.PassThroughPointerClickEvent( eventData )
end

------------------------------------------------------------
-- 设置物品实体
-- subInfo = {
--		bShowBtnType		= 1, 	是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
--		bBottomBtnType = 1,
--		ScrTrans = nil,	-- 源预设
--		Pos = Vector3.New(),
-- }
function GoodsTooltipsWindow:SetGoodsEntity(entity, subInfo)
	if not entity then
		return
	end
	self.m_entity = entity
	self.m_nGoodID = entity:GetNumProp(GOODS_PROP_GOODSID)
	self.m_subInfo = subInfo
    if not self:isLoaded() then
        self.mNeedUpdate = true
        return
    end
	self.BGWidget:SetGoodsID(self.m_nGoodID, subInfo)
end

-- 设置物品ID
-- subInfo = {
--		bShowBtnType		= 1, 	是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
--		bBottomBtnType = 1,
--		ScrTrans = nil,	-- 源预设
-- }
function GoodsTooltipsWindow:SetGoodsInfo(nGoodID, subInfo)
		
	UIWindow.Show(self,true)
    self.m_entity = nil
	self.m_nGoodID = nGoodID
	self.m_subInfo = subInfo

    if not self:isLoaded() then
        self.mNeedUpdate = true
        return
    end

	self.BGWidget:SetGoodsID(nGoodID, subInfo)
end

function GoodsTooltipsWindow:Hide(destory)
	UIWindow.Hide(self,destory)
	if self.BGWidget~= nil and self.BGWidget.transform ~= nil then
		self.BGWidget.transform.gameObject:SetActive(false)
	end
end


-- 背包界面设置物品
function GoodsTooltipsWindow:SetGoods(entity)
	self.m_entity = entity
    if not self:isLoaded() then
        self.mNeedUpdate = true
        return
    end

    self.ButtonWidget1:SetActive(false)
    self.ButtonWidget:SetActive(true)
    local curTab = UIManager.PackWindow:GetCurTab()
    local tabName = UIManager.PackWindow.tabName
    local bTask = false
    if curTab == tabName.emGeneral then 
    	self.Controls.m_RecycleButton.gameObject:SetActive(false)
    	bTask = true
    else 
    	self.Controls.m_RecycleButton.gameObject:SetActive(true) 
    end
    self.ButtonWidget:SetTaskFlag(bTask)
    self.ButtonWidget:SetGoods(entity)
    self.BGWidget:SetGoods(entity)
end

-- 仓库显示物品tips 
-- entityInfo 属性表
-- subInfo 其他表
function GoodsTooltipsWindow:ShowGoodsTooltips(entityInfo, subInfo)
	uerror("ShowGoodsTooltips 这个函数改为 SetGoodsInfo ，用法见注释")
end

-- 调整右侧按钮高度
function GoodsTooltipsWindow:AdjustButtonWidgetHeight(height)
	self.ButtonWidget:AdjustHeight(height)
end

function GoodsTooltipsWindow:SetEntity(goodsUid)
	self.ButtonWidget1:SetEntity(goodsUid)
end

function GoodsTooltipsWindow:AdjustTipsBgHeight(height)
	self.Controls.m_TipsBg.sizeDelta = Vector2.New(self.Controls.m_TipsBg.sizeDelta.x,height)
end

-- 添加新物品事件
function GoodsTooltipsWindow:OnEventAddGoods()
	if not self:isShow() then
		return
	end
	
	if not self.m_entity then
		return
	end
	self.BGWidget:SetGoodsID(self.m_nGoodID, self.m_subInfo)
end

-- 删除物品事件
function GoodsTooltipsWindow:OnEventRemoveGoods()
	self:OnEventAddGoods()
end

function GoodsTooltipsWindow:OnEventGoodsUseCntChange(eventdata)
	if eventdata.nGoodsId ~= self.m_nGoodID then
		return
	end
	self:OnEventAddGoods()
end

-- 订阅事件
function GoodsTooltipsWindow:SubscribeEvent()
	rktEventEngine.SubscribeExecute(EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
	rktEventEngine.SubscribeExecute(EVENT_GOODS_USE_COUNT_CHANGE, SOURCE_TYPE_GOODS, 0, self.callback_OnEventGoodsUseCntChange)
	
end

-- 取消订阅事件
function GoodsTooltipsWindow:UnsubscribeEvent()
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
	rktEventEngine.UnSubscribeExecute(EVENT_GOODS_USE_COUNT_CHANGE, SOURCE_TYPE_GOODS, 0, self.callback_OnEventGoodsUseCntChange)
end

-- 初始化全局回调函数
function GoodsTooltipsWindow:InitCallbacks()
	self.callback_OnEventAddGoods = function(event, srctype, srcid, eventdata) self:OnEventAddGoods(eventdata) end
	self.callback_OnEventRemoveGoods = function(event, srctype, srcid, eventdata) self:OnEventRemoveGoods(eventdata) end
	self.callback_OnEventGoodsUseCntChange = function(event, srctype, srcid, eventdata) self:OnEventGoodsUseCntChange(eventdata) end
end

-- 
function GoodsTooltipsWindow:GetEntity()
	return self.m_entity
end

return GoodsTooltipsWindow