-- 包裹解锁窗口
------------------------------------------------------------
local MaterialComposeWindow = UIWindow:new
{
	windowName = "MaterialComposeWindow",
	m_nType = 1,	-- 1:合成 , 2:分解
    m_goodsIndex = 0,
    m_goodsId = 0,
	m_tFilterGoodsInfo = {},
}
local TypeName = {"合成","分解"}
------------------------------------------------------------
function MaterialComposeWindow:Init()
	self.MaterialGoodsList	= require("GuiSystem.WindowList.MaterialCompose.MaterialListWidget") 
	self.MaterialGoodsInfo	= require("GuiSystem.WindowList.MaterialCompose.MaterialGoodsInfo")
	
	self:InitCallbacks()
end
------------------------------------------------------------
function MaterialComposeWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
    self.MaterialGoodsList:Attach(self.Controls.m_MaterialListWidget.gameObject)
	self.MaterialGoodsInfo:Attach(self.Controls.m_MaterialGoodsInfoWidget.gameObject)
	self.Controls.m_closeButton.onClick:AddListener(function() self:OnBtnCloseClick() end)

	self:SubscribeEvent()
    if 0 ~= self.m_goodsId then
        self:RefreshDataInfo( self.m_goodsId , self.m_nType )
    end
end
------------------------------------------------------------
function MaterialComposeWindow:OnDestroy()
	self:UnsubscribeEvent()
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------

function MaterialComposeWindow:RefreshDataInfo(goodsId,nType,ReloadFlg)
	self.m_nType = nType or self.m_nType
	if not goodsId or not self.m_nType or not TypeName[self.m_nType] then
		return
	end
	
	self.m_goodsId = goodsId

    if not self:isLoaded() then
        return
    end
	
	
	self.Controls.m_TitleImageHeCheng.gameObject:SetActive(self.m_nType == 1)
	self.Controls.m_TitleImageFenJie.gameObject:SetActive( not (self.m_nType == 1))
	
	local HaveGoodsId = false
	self:FilterGoodsByCompound()
	if table_count(self.m_tFilterGoodsInfo) == 0 then
		self:Hide()
		return
	end
	local itemIndex = 0
	
	for i, v in pairs(self.m_tFilterGoodsInfo) do 
		if v == goodsId then 
			itemIndex = i
			self.m_goodsIndex = i
			HaveGoodsId = true
		end
	end
	
	if HaveGoodsId == false then
		if self.m_goodsIndex and self.m_goodsIndex <= table_count(self.m_tFilterGoodsInfo) then
			self.m_goodsId = self.m_tFilterGoodsInfo[self.m_goodsIndex]
		else
			self.m_goodsIndex = 1
			self.m_goodsId = self.m_tFilterGoodsInfo[self.m_goodsIndex]
		end
	end
	
	self:UpdateMaterialGoodsInfo(self.m_goodsIndex)
	self.MaterialGoodsList:ReloadData(self.m_goodsId,ReloadFlg)
end


function MaterialComposeWindow:UpdateMaterialGoodsInfo(itemIndex) 
	
	self.MaterialGoodsInfo:UpdateMaterialGoodsInfo(itemIndex)
end

-- 获取类型
function MaterialComposeWindow:GetType()
	return self.m_nType
end

-- 关闭按钮
function MaterialComposeWindow:OnBtnCloseClick()
	self:Hide()
end


-- 遍历包裹蓝找材料
function MaterialComposeWindow:FilterGoodsByCompound()
	local tGoodsUID = {} 
	local tFilterGoods = {}
	local curSize = 0
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	local nType = self:GetType()
	local TableTmp = {}
	if packetPart and packetPart:IsLoad() then
		tGoodsUID = packetPart:GetAllGoods()
		curSize = packetPart:GetSize()

		for i = 1, curSize do
			local uid = tGoodsUID[i]
			if uid then
				local entity = IGame.EntityClient:Get(uid)
				if entity then
					local entityClass = entity:GetEntityClass()
					local nGoodID = entity:GetNumProp(GOODS_PROP_GOODSID)
					if EntityClass:IsLeechdom(entityClass) and TableTmp[nGoodID] == nil then
						TableTmp[nGoodID] = 1
						local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, nGoodID)
						if schemeInfo and schemeInfo.lCanCompound == nType then
							table.insert(tFilterGoods, nGoodID)
						end
					end
				end
			end
		end
	end
	
	table.sort(tFilterGoods, function(nGoodID1, nGoodID2) return nGoodID1 < nGoodID2 end)
	self.m_tFilterGoodsInfo = tFilterGoods
end

function MaterialComposeWindow:GetFilterGoodsList()
	return self.m_tFilterGoodsInfo
end


-- 添加新物品事件
function MaterialComposeWindow:OnEventAddGoods()
	if not self:isShow() then
		return
	end
	self:RefreshDataInfo(self.m_goodsId, self.m_nType)
end

-- 删除物品事件
function MaterialComposeWindow:OnEventRemoveGoods()
	self:OnEventAddGoods()
end

-- 初始化全局回调函数
function MaterialComposeWindow:InitCallbacks()
	self.callback_OnEventAddGoods = function() self:OnEventAddGoods() end
	self.callback_OnEventRemoveGoods = function() self:OnEventRemoveGoods() end
end

-- 订阅事件
function MaterialComposeWindow:SubscribeEvent()
	rktEventEngine.SubscribeExecute(EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
end

-- 取消订阅事件
function MaterialComposeWindow:UnsubscribeEvent()
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
end


return MaterialComposeWindow