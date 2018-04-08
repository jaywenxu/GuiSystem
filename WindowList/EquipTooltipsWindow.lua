-- tooltips窗口
------------------------------------------------------------
local EquipTooltipsWidgetClass = require("GuiSystem.WindowList.Tooltips.EquipTooltipsWidget")
local TipsRightButtonsWidgetClass = require("GuiSystem.WindowList.Tooltips.TipsRightButtonsWidget")

local EquipTooltipsWindow = UIWindow:new
{
	windowName = "EquipTooltipsWindow",
	mNeedUpdate = false,
	m_entity = nil,
	m_EntityInfo = {},
	m_EntityType = 1,	-- 1:实体  2:数据
	m_subInfo = {},
}

------------------------------------------------------------
function EquipTooltipsWindow:Init()

end

------------------------------------------------------------
function EquipTooltipsWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	
	-- 对比窗口
	self.CompareWidget = EquipTooltipsWidgetClass:new()
	self.CompareWidget:Attach(self.Controls.m_EquipToolTipsWidgetCompare.gameObject)
	
	-- 主tips窗口
	self.MainWidget = EquipTooltipsWidgetClass:new()
	self.MainWidget:Attach(self.Controls.m_EquipToolTipsWidgetMain.gameObject)
	
	self.RightButtonsWidget = TipsRightButtonsWidgetClass	-- 这里不要new，因为按钮回调需要内部参数
	self.RightButtonsWidget:Attach(self.Controls.m_TipsRightButtonsWidget.gameObject)

	self.callback_OnCloseBtnClick = function( eventData ) self:OnCloseButtonClick(eventData) end 
    UIFunction.AddEventTriggerListener( self.Controls.m_CloseButton , EventTriggerType.PointerClick , self.callback_OnCloseBtnClick)

    if self.mNeedUpdate then
        self.mNeedUpdate = false
        if 1 == self.m_EntityType then
            self:SetEntity(self.m_entity,self.m_subInfo)
        elseif 2 == self.m_EntityType then
            self:SetInfo(self.m_EntityInfo,self.m_subInfo)
        end
    end
end
------------------------------------------------------------
function EquipTooltipsWindow:OnDestroy()
	UIFunction.RemoveEventTriggerListener( self.Controls.m_CloseButton , EventTriggerType.PointerClick , self.callback_OnCloseBtnClick)
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------
function EquipTooltipsWindow:OnCloseButtonClick( eventData )
    self:Hide()
    rkt.UIAndTextHelpTools.PassThroughPointerClickEvent( eventData )
end

-- 设置物品
-- subInfo = {
--		bShowBtn		= 1, 	是否显示按钮(1:显示, 0:不显示)
--		bShowCompare	= true,	是否显示对比窗口(true:显示, false:不显示)
--		bRightBtnType = 1,
-- }
--
function EquipTooltipsWindow:SetEntity(entity, subInfo)
	if not self:isLoaded() then
		DelayExecuteEx( 100,function ()
			self:SetEntity(entity, subInfo)
		end)
		return
	end
	self.m_entity = entity
	self.m_EntityType = 1
	self.m_subInfo = subInfo
	if not self:isLoaded() then
        self.mNeedUpdate = true
		return
	end
	self:Refresh()
end

function EquipTooltipsWindow:SetInfo(EquipInfo, subInfo)
	self.m_EntityInfo = EquipInfo
	self.m_EntityType = 2
	self.m_subInfo = subInfo
	if not self:isLoaded() then
        self.mNeedUpdate = true
		return
	end
	self:Refresh()
end

--
function EquipTooltipsWindow:Refresh()
	if not self:isLoaded() then
		return
	end
	if self.m_EntityType == 1 then -- 实体
		self.MainWidget:SetEntity(self.m_entity)
		if self.m_subInfo.bShowCompare == true then
			local pEquipEntity = self:GetPutOnEquipByEntity(self.m_entity:GetNumProp(GOODS_PROP_GOODSID))
			if pEquipEntity then
				self.CompareWidget:SetEntity(pEquipEntity)
				self.Controls.m_CompareWidget.gameObject:SetActive(true)
			else
				self.Controls.m_CompareWidget.gameObject:SetActive(false)
			end
		else
			self.Controls.m_CompareWidget.gameObject:SetActive(false)
		end
		if self.m_subInfo.bShowBtn == 1 then
			self.RightButtonsWidget:Refresh(self.m_entity, self.m_subInfo)
			self.RightButtonsWidget:Show()
		else
			self.RightButtonsWidget:Hide()
		end
	else
		self.MainWidget:SetInfo(self.m_EntityInfo)
		if self.m_subInfo.bShowCompare == true then
			local pEquipEntity = self:GetPutOnEquipByEntity(self.m_EntityInfo[PASTER_EQUIP_INFO_KEY_GOODSID])
			if pEquipEntity then
				self.CompareWidget:SetEntity(pEquipEntity)
				self.Controls.m_CompareWidget.gameObject:SetActive(true)
			else
				self.Controls.m_CompareWidget.gameObject:SetActive(false)
			end
		else
			self.Controls.m_CompareWidget.gameObject:SetActive(false)
		end
		self.RightButtonsWidget:Hide()
	end
	self:Show(true)
end

function EquipTooltipsWindow:GetPutOnEquipByEntity(EquipID)
	-- 装备对比窗口
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, EquipID)
	if not schemeInfo then
		return
	end
	local place = schemeInfo.EquipLoc1
	local equipPart = GetHero():GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	local pEquipEntity = IGame.EntityClient:Get(equipPart:GetGoodsUIDByPos(place + 1))
	return pEquipEntity
end

return EquipTooltipsWindow
