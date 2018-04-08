
------------------------时装Item------------------------------

local DressItem = UIControl:new
{
	windowName 	= "DressItem",
	m_index		= nil,				-- 时装索引

	m_selected_calback = nil ,		-- 选中时回调
	
	m_nType 	= nil,				-- 类型

	m_lock		= true,
	
	m_DressID = 0, 					--非衣服发饰 ID
	m_IDTable = {},					--衣服，发饰所包含的ID
}

local this = DressItem

function DressItem:Init()

end

function DressItem:Attach(obj)
	UIControl.Attach(self,obj)	
	--注册点击事件
	self.callback_OnSelectChanged = function(on) self:OnSelectChanged(on) end
	self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))	
	self.Controls.ItemToggle.onValueChanged:AddListener(self.callback_OnSelectChanged)
end

function DressItem:SetItemCellInfo(nType,index)
	self.m_nType = nType
	self.m_index = index
	
	if nType == 2 or nType == 1 then 
		self:SetHairStyleInfo(index)
	else
		local item = IGame.AppearanceClient:GetItemInfoBy(nType,index)					--当前数据
		self.m_DressID = item.nAppearID
		self:SetIcon(item.nIconPath)
	end
	
end

--设置发色,特殊处理
function DressItem:SetHairStyleInfo(index)
	local record
	if self.m_nType == 1 then
		record = IGame.AppearanceClient:GetClothesRecordByIndex(index,1)		--默认显示第一个 
	elseif self.m_nType == 2 then
		record = IGame.AppearanceClient:GetHairRecordByIndex(index,1)		--默认显示第一个 
	end
	local recordTable = IGame.AppearanceClient:GetRecordTableByIndex(self.m_nType, self.m_index)
	
	if not record then
		return 
	end
	
	self.m_IDTable = {}
	if recordTable then
		for i,data in pairs(recordTable) do
			table.insert(self.m_IDTable, i, data.nAppearID)
		end
	end
	self:SetIcon(record.nIconPath)
end

function DressItem:SetIcon(path)
	UIFunction.SetImageSprite(self.Controls.m_Icon, AssetPath.TextureGUIPath..path)
end

function DressItem:SetLock(nLock)
	self.Controls.m_Lock.gameObject:SetActive(nLock)
end

-- 销毁
function DressItem:OnDestroy()	
--[[	self.Controls.ItemToggle.onValueChanged:RemoveListener(self.callback_OnSelectChanged)--]]
	UIControl.OnDestroy(self)
end

-------------------------------------------------------------------
-- 设置选中时回调函数	
-- @param func_cb : 回调函数
-------------------------------------------------------------------
function DressItem:SetSelectCallback(func_cb)
	self.m_selected_calback = func_cb
end	

-------------------------------------------------------------------
-- 设置组	
-- @param toggleGroup : 要设置的item(需要有toggle属性)
-------------------------------------------------------------------
function DressItem:SetToggleGroup(toggleGroup)
	self.Controls.ItemToggle.group = toggleGroup
end

-- 选中
function DressItem:OnSelectChanged(on)
	if not on then
		self.Controls.m_Select.gameObject:SetActive(false)
	else
		self.Controls.m_Select.gameObject:SetActive(true)
	end
	if nil ~= self.m_selected_calback then 
		if on then
			self.m_selected_calback(self.m_nType,self.m_index)
		end
	end
end

function DressItem:SetFocus(on)
	self.Controls.ItemToggle.isOn = on
end

function DressItem:GetDressItemIndex()
	if nil ~= self.m_index then 
		return self.m_index
	end	
end

function DressItem:GetDressItemType()
	if nil ~= self.m_nType then
		return self.m_nType
	end
end


return this