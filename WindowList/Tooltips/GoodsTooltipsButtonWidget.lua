------------------------------------------------------------
-- TooltisWindow 的子窗口,不要通过 UIManager 访问
------------------------------------------------------------

local GoodsTooltipsButtonWidget = UIControl:new
{
    windowName = "GoodsTooltipsButtonWidget" ,
	entity = nil,
	m_bTask = false,
	m_canSell = false,
	m_canCompose = false,
	m_canRecycle = false,
	m_canRevert  = false,
	m_clickCount = 0,
	m_goodsId    = 0,
	m_BtnMoreShowFlg = false,
}

local this = GoodsTooltipsButtonWidget   -- 方便书写
local zero = int64.new("0")

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function GoodsTooltipsButtonWidget:Attach(obj)
	UIControl.Attach(self, obj)
	
	self.Controls.m_ButtonUse.onClick:AddListener(function() self:OnButtonUseClick() end)
	self.Controls.m_ButtonRecycle.onClick:AddListener(function() self:OnButtonRecycleClick() end) 
	self.Controls.m_ButtonSell.onClick:AddListener(function() self:OnButtonSellClick() end) 
	self.Controls.m_ButtonCompose.onClick:AddListener(function() self:OnButtonComposeClick() end) 
	self.Controls.m_ButtonDecompose.onClick:AddListener(function() self:OnButtonDecomposeClick() end) 
	self.Controls.m_ButtonMore.onClick:AddListener(function() self:OnButtonMoreClick() end)
	self.Controls.m_BtnRecycle.onClick:AddListener(function() self:OnButtonRecycleClick() end) 
	self.Controls.m_BtnConvert.onClick:AddListener(function() self:OnButtonConvertClick() end) 
	
	return self
end

------------------------------------------------------------
function GoodsTooltipsButtonWidget:OnDestroy()
	UIControl.OnDestroy(self)
end
------------------------------------------------------------

-- 使用按钮
function GoodsTooltipsButtonWidget:OnButtonUseClick()
	if not self.entity then
		return
	end
	
	local entityClass = self.entity:GetEntityClass()
	if EntityClass:IsLeechdom(entityClass) then
		
		local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, self.entity:GetNumProp(GOODS_PROP_GOODSID))
		if not schemeInfo then
			print("[GoodsTooltipsButtonWidget]找不到物品配置，物品ID=", self.entity:GetNumProp(GOODS_PROP_GOODSID))
			return
		end
		IGame.SkepClient:RequestUseItem(self.entity:GetUID())
		
		local nCloseTips = schemeInfo.nClosetips
		if nCloseTips == 1 then
			-- 直接关闭tips
			UIManager.GoodsTooltipsWindow:Hide() 
		else
			local totalNum = self.entity:GetNumProp(GOODS_PROP_QTY)
			if totalNum <= 1 then 
				UIManager.GoodsTooltipsWindow:Hide()
			end 
		end		
		
	end
end

function GoodsTooltipsButtonWidget:OnButtonRecycleClick()
	-- todo
	if not self.entity then
		return
	end
	local entity     = self.entity
	
	local data = {}
	data.content = string.format("物品一旦回收就不可找回，是否继续？")
	data.confirmCallBack = function ()
		self:ConfirmRecycle(entity)
	end
	data.cancelCallBack = function ()
		UIManager.GoodsTooltipsWindow:Hide()
	end
	UIManager.ConfirmPopWindow:ShowDiglog(data)
end

function GoodsTooltipsButtonWidget:OnButtonConvertClick()
    UIManager.GoodsTooltipsWindow:Hide()
	UIManager.GemConvertWindow:Show(true)
    UIManager.GemConvertWindow:Refresh()
end

function GoodsTooltipsButtonWidget:ConfirmRecycle(entity)
	local strfun     = "RequestGoodsRecycle("..tostring(entity:GetUID())..")"
	GameHelp.PostServerRequest(strfun)
	UIManager.GoodsTooltipsWindow:Hide()
end

-- 展示按钮
function GoodsTooltipsButtonWidget:OnButtonShowClick()
	print("============== show button click ==============")
end

-- 出售按钮
function GoodsTooltipsButtonWidget:OnButtonSellClick()
	
	IGame.ExchangeClient:GoToSellCustomGoods(self.entity:GetUID())
	
end

-- 打造按钮
function GoodsTooltipsButtonWidget:OnButtonSmeltClick()
	print("============== smelt button click ==============")
end

-- 分解按钮
function GoodsTooltipsButtonWidget:OnButtonDecomposeClick()
	--print("============== decompose button click ==============")
    local goodsId = self.m_goodsId
	UIManager.GoodsTooltipsWindow:Hide()
	UIManager.MaterialComposeWindow:Show(true)
    UIManager.MaterialComposeWindow:RefreshDataInfo(goodsId,2)
end

-- 合成按钮
function GoodsTooltipsButtonWidget:OnButtonComposeClick()
    local goodsId = self.m_goodsId
    local canCompose = self.m_canCompose
	UIManager.GoodsTooltipsWindow:Hide()
	UIManager.MaterialComposeWindow:Show(true)
    UIManager.MaterialComposeWindow:RefreshDataInfo(goodsId,canCompose)
end

function GoodsTooltipsButtonWidget:OnButtonMoreClick()
	if self.m_clickCount == 0 then
		self.Controls.m_ShowMore.gameObject:SetActive(true)
		local bgHeight = 0
		if not self.m_canRecycle then
			self.Controls.m_BtnRecycle.gameObject:SetActive(false)
		else
			self.Controls.m_BtnRecycle.gameObject:SetActive(true)
			bgHeight = bgHeight + self.Controls.m_BtnRecycle.gameObject.transform.sizeDelta.y
		end
		if not self.m_canCompose then
			self.Controls.m_ButtonCompose.gameObject:SetActive(false)
		else
			if self.m_canCompose  == 1 then
				self.Controls.m_ButtonCompose.gameObject:SetActive(true)
				self.Controls.m_ButtonDecompose.gameObject:SetActive(false)
			else
				self.Controls.m_ButtonCompose.gameObject:SetActive(false)
				self.Controls.m_ButtonDecompose.gameObject:SetActive(true)
			end
			
			bgHeight = bgHeight + self.Controls.m_ButtonCompose.gameObject.transform.sizeDelta.y
		end
		if not self.m_canSell then
			self.Controls.m_ButtonSell.gameObject:SetActive(false)
		else
			self.Controls.m_ButtonSell.gameObject:SetActive(true)
			bgHeight = bgHeight + self.Controls.m_ButtonSell.gameObject.transform.sizeDelta.y
		end
		if not self.m_canRevert then
			self.Controls.m_BtnConvert.gameObject:SetActive(false)
		else
			self.Controls.m_BtnConvert.gameObject:SetActive(true)
			bgHeight = bgHeight + self.Controls.m_BtnConvert.gameObject.transform.sizeDelta.y
		end
		self.Controls.m_Arrow.localRotation = Vector3.New(0, 0, 0)
		self.m_clickCount = 1
		-- 计算背景总高度
		--self.Controls.m_ShowMore.sizeDelta = Vector2.New(self.Controls.m_ShowMore.sizeDelta.x, bgHeight+30)
	else
		self.Controls.m_ShowMore.gameObject:SetActive(false)
		self.Controls.m_Arrow.localRotation = Vector3.New(0, 0, 180)
		self.m_clickCount = 0
	end
end

-- 设置物品
function GoodsTooltipsButtonWidget:SetGoods(entity)
	self.entity = entity
	-- 初始化点击次数为0
	self.m_clickCount = 0
	self.Controls.m_Arrow.localRotation = Vector3.New(0, 0, 180)
	local noBindNum = entity:GetNumProp(GOODS_PROP_NO_BIND_QTY)
	self.m_goodsId = entity:GetNumProp(GOODS_PROP_GOODSID)
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
	if not schemeInfo then
		return
	end
	
	self.Controls.m_ButtonMore.gameObject:SetActive(false)
	self.Controls.m_ShowMore.gameObject:SetActive(false)
	self.Controls.m_ButtonRecycle.gameObject:SetActive(true)
	-- 是否显示更多按钮
	local canSell = schemeInfo.lCanSell
	local canRecycle = schemeInfo.lCanRecycle
	local canCompound = schemeInfo.lCanCompound
	local canConvert  = schemeInfo.nCanConvert
	
	if canSell == 1 then
		if noBindNum > 0 then
			self.m_canSell = true 
		else 
			self.m_canSell = false
		end 
	else
		self.m_canSell = false
	end
	
	if canRecycle == 1 then 
		self.m_canRecycle = true
	else 
		self.m_canRecycle = false
	end
	
	if canCompound == 1 or canCompound == 2 then 
		self.m_canCompose = canCompound
	else 
		self.m_canCompose = false
	end
	
	if canConvert == 1 then
		self.m_canRevert = true 
	else 
		self.m_canRevert = false
	end
	
	self:SetButtonType()
end

-- 设置标签
function GoodsTooltipsButtonWidget:SetButtonType()
	if not self.entity then
		return
	end
	
	local entityClass = self.entity:GetEntityClass()
	if EntityClass:IsEquipment(entityClass) then
		self.Controls.m_ButtonUse.gameObject:SetActive(true) 
		self.Controls.m_UseText.text = "穿上"
	elseif EntityClass:IsLeechdom(entityClass) then
		self.Controls.m_ButtonUse.gameObject:SetActive(true)
		if not self.m_bTask then 
			if self.m_canCompose or self.m_canSell then 
			    self.Controls.m_ButtonRecycle.gameObject:SetActive(false)
				self.Controls.m_ButtonMore.gameObject:SetActive(true)
		    else 
				self.Controls.m_ButtonMore.gameObject:SetActive(false)
			    self.Controls.m_ShowMore.gameObject:SetActive(false)
			    self.Controls.m_ButtonRecycle.gameObject:SetActive(true)
		    end
		end

		self.Controls.m_UseText.text = "使用"
	end
end

-- 调整高度
function GoodsTooltipsButtonWidget:AdjustHeight(height)
	-- local width = self.transform.sizeDelta.x
	--local vector2 = Vector2.New(width, height)
	--self.transform.sizeDelta = vector2
	--local newPostion = Vector2.New(self.transform.localPosition.x, height)
	--self.transform.localPosition.y = height
end

function GoodsTooltipsButtonWidget:SetActive(on) 
	self.transform.gameObject:SetActive(on)
end

function GoodsTooltipsButtonWidget:SetTaskFlag(bTask) 
	self.m_bTask = bTask
end

function GoodsTooltipsButtonWidget:SetButtonMoreStatus(status)
	self.Controls.m_ButtonMore.gameObject:SetActive(status)
	self.Controls.m_ShowMore.gameObject:SetActive(status)
end

return this