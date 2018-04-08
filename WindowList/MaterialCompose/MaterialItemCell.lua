--------------------------------------------------------------------

local MaterialItemCell = UIControl:new
{
	windowName 	= "MaterialItemCell",
    m_uidGoods  = "",
    m_GoodID  = "",
	m_index     = 0,
	m_selected_calback = nil ,		-- 选中时回调
}

local this = MaterialItemCell

function MaterialItemCell:Init()
	self.m_GoodID = nil
	self.m_index = nil
end

function MaterialItemCell:Attach(obj)
	UIControl.Attach(self,obj)	
	self.callback_OnSelectChanged = function(on) self:OnSelectChanged(on) end
	self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))	
	self.Controls.ItemToggle.onValueChanged:RemoveListener(self.callback_OnSelectChanged)
	self.Controls.ItemToggle.onValueChanged:AddListener(self.callback_OnSelectChanged)
	--print("<color=red>Attach</color>")
	--self:SetFocus(false)
	return self
end

-- 选中
function MaterialItemCell:OnSelectChanged(on)

	if not on then
		self.Controls.m_SelectImg.gameObject:SetActive(false)
	else
		self.Controls.m_SelectImg.gameObject:SetActive(true)
	end
	if nil ~= self.m_selected_calback then 
		self.m_selected_calback(self, on, self.m_index)
	end
end

-------------------------------------------------------------------
-- 设置选中时回调函数	
-- @param func_cb : 回调函数
-------------------------------------------------------------------
function MaterialItemCell:SetSelectCallback(func_cb)
	
	self.m_selected_calback = func_cb
end	

-- 设置组	
-- @param toggleGroup : 要设置的item(需要有toggle属性)
-------------------------------------------------------------------
function MaterialItemCell:SetToggleGroup(toggleGroup)
	
	self.Controls.ItemToggle.group = toggleGroup
end

function MaterialItemCell:SetItemCellInfo(nGoodID, itemIndex, goodsNum)
	if nGoodID and nGoodID ~= 0 then 
        local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, nGoodID)
		if not schemeInfo then
			print("找不到物品配置，物品ID=", nGoodID)
			return
		end
		
		local goodsName = schemeInfo.szName
		self.Controls.m_Text_GoodsName.text = GameHelp.GetLeechdomColorName(nGoodID)
		-- 物品图片
		local imagePath = AssetPath.TextureGUIPath..schemeInfo.lIconID1
		UIFunction.SetImageSprite( self.Controls.m_Image_GoodsIcon , imagePath ) 
		-- 物品边框
		local imageBgPath = AssetPath.TextureGUIPath..schemeInfo.lIconID2
		UIFunction.SetImageSprite( self.Controls.m_Image_GoodsBG , imageBgPath ) 
		--拥有的数量
		local totalNum = goodsNum
		if totalNum <= 1 then 
			self.Controls.m_Text_GoodsNum.text = "" 
		else 
			self.Controls.m_Text_GoodsNum.text = totalNum
		end
		self.m_GoodID = nGoodID
		self.m_uidGoods = uidGoods
		self.m_index    = itemIndex			
	end
	
end

function MaterialItemCell:SetFocus(on)
	self.Controls.ItemToggle.isOn = on
end

function MaterialItemCell:GetGoodsUid()
	if self.m_uidGoods ~= "" then 
		return  self.m_uidGoods
	end
end

function MaterialItemCell:GetGoodID()
	return  self.m_GoodID
end

function MaterialItemCell:GetItemIndex()
	if self.m_index ~= 0 then 
		return self.m_index
	end 
end

-- 销毁
function MaterialItemCell:OnDestroy()
	self.m_GoodID = nil
	self.m_index = nil
	self.Controls.ItemToggle.isOn = false
	self.Controls.ItemToggle.onValueChanged:RemoveListener(self.callback_OnSelectChanged)
	UIControl.OnDestroy(self)
end

-- 回收
function MaterialItemCell:OnRecycle()
	self.m_GoodID = nil
	self.m_index = nil
	self.Controls.ItemToggle.isOn = false
	self.Controls.ItemToggle.onValueChanged:RemoveListener(self.callback_OnSelectChanged)
	UIControl.OnRecycle(self)
end

return this