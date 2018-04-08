
---------------------------灵兽系统 - 经验物品使用界面---------------------------------------
local PetExpUseItemClass = require("GuiSystem.WindowList.Pet.Property.PetExpUseItem")

local PetUseGoodsWidget = UIControl:new
{
	windowName = "PetUseGoodsWidget",
	
	m_UseGoodsScriptsCache = {},
}

function PetUseGoodsWidget:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.CloseCB = function( eventData ) self:OnCloseButtonClick(eventData) end
	UIFunction.AddEventTriggerListener( self.Controls.m_BGMask , EventTriggerType.PointerClick ,  self.CloseCB)
	
	--接受到关闭界面事件
	self.CloseWidgetCB = function() if self:isShow() then self:Hide() end end
	rktEventEngine.SubscribeExecute(EVENT_PET_CLOSEXPGOODS_WIDGET, SOURCE_TYPE_PET, 0, self.CloseWidgetCB)
end

function PetUseGoodsWidget:Destroy()
	rktEventEngine.SubscribeExecute(EVENT_PET_CLOSEXPGOODS_WIDGET, SOURCE_TYPE_PET, 0, self.CloseWidgetCB)
	UIFunction.RemoveEventTriggerListener(self.Controls.m_BGMask,EventTriggerType.PointerClick ,  self.CloseCB)
	UIControl.Destroy(self)
end

--初始化使用物品界面  3个
function PetUseGoodsWidget:ShowPetUseGoodsWidget(uid)
	self:Show()
	
	local num = table.getn(self.m_UseGoodsScriptsCache)
	if num > 0 then
		for i, data in pairs(self.m_UseGoodsScriptsCache) do
			data:Destroy()
		end
	end
	self.m_UseGoodsScriptsCache = {}
	
	for i = 1, 3 do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetExpUseItem ,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_GoodsItemList)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = PetExpUseItemClass:new({})
			item:Attach(obj)
			item:Show()
			item:SetIndex(i, gPetCfg.PetExpUseGoodsID[i], uid)					 -- 设置绑定的经验物品ID, 界面初始化放在这个方法里
			table.insert(self.m_UseGoodsScriptsCache,i,item)	
		end , i , AssetLoadPriority.GuiNormal )
	end
	
end

function PetUseGoodsWidget:OnCloseButtonClick( eventData )    
    rkt.UIAndTextHelpTools.PassThroughPointerClickEvent( eventData )
	self:Hide()
end


return PetUseGoodsWidget