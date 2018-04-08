------------------------------------------------------------
-- TooltisWindow 的子窗口,不要通过 UIManager 访问
------------------------------------------------------------

require("GuiSystem.WindowList.Exchange.ExchangeWindowPresetDataMgr")

local GoodsTooltipsButtonWidget1 = UIControl:new
{
    windowName = "GoodsTooltipsButtonWidget1" ,
	entity = nil,
	m_MoveType = false
}

local this = GoodsTooltipsButtonWidget1   -- 方便书写
local zero = int64.new("0")

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function GoodsTooltipsButtonWidget1:Attach(obj)
	UIControl.Attach(self, obj)
	
	self.Controls.m_ButtonPut.onClick:AddListener(function() self:OnButtonPutClick() end)
	--self.Controls.m_ButtonDropdown.OnValueChanged:AddListener(function() self:OnValueChanged() end)
	--self.Controls.m_ButtonSell.onClick:AddListener(function() self:OnButtonSellClick() end)
	--self.Controls.m_ButtonSmelt.onClick:AddListener(function() self:OnButtonSmeltClick() end)
	--self.Controls.m_ButtonCompose.onClick:AddListener(function() self:OnButtonComposeClick() end)
	--self.Controls.m_ButtonDecompose.onClick:AddListener(function() self:OnButtonDecomposeClick() end)
	
	return self
end

------------------------------------------------------------
function GoodsTooltipsButtonWidget1:OnDestroy()
	UIControl.OnDestroy(self)
end
------------------------------------------------------------

-- 使用按钮
function GoodsTooltipsButtonWidget1:OnButtonPutClick()
	if not self.entity then
		return
	end
	
	local warePart = GetHero():GetEntityPart(ENTITYPART_PERSON_WARE)
	if not warePart then
		return
	end
	
	if not warePart:IsLoad() then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你的仓库正在加载中，请稍后再试")
		return
	end
	uid = self.entity:GetUID()
	if self.m_MoveType == "pack" then
		IGame.SkepClient.RequestPacketToWare(uid)
	else
	    IGame.SkepClient.RequestWareToPacket(uid)
	end
	
	UIManager.GoodsTooltipsWindow:Hide()
end

function GoodsTooltipsButtonWidget1:SetEntity(goodsUid)
	local entity = IGame.EntityClient:Get(goodsUid)
	self.entity = entity
end

--[[function GoodsTooltipsButtonWidget:OnValueChanged()
	local text = self.Controls.m_ButtonDropdown.text
	print("=============" .. text)
end]]

-- 展示按钮
function GoodsTooltipsButtonWidget1:OnButtonShowClick()
	print("============== show button click ==============")
end

-- 出售按钮
function GoodsTooltipsButtonWidget1:OnButtonSellClick()
	print("============== sell button click ==============")
end

-- 打造按钮
function GoodsTooltipsButtonWidget1:OnButtonSmeltClick()
	print("============== smelt button click ==============")
end

-- 分解按钮
function GoodsTooltipsButtonWidget1:OnButtonDecomposeClick()
	print("============== decompose button click ==============")
end

-- 合成按钮
function GoodsTooltipsButtonWidget1:OnButtonComposeClick()
	print("============== compose button click ==============")
end

-- 设置物品
function GoodsTooltipsButtonWidget1:SetGoods(goodsId, MoveType)
	
	local buttonName = ""
	self.m_MoveType = MoveType
	if MoveType == "pack"  then
	    buttonName = "仓库"
	else 
		buttonName = "背包"
	end
	self:SetButtonType(buttonName)
end

-- 设置标签
function GoodsTooltipsButtonWidget1:SetButtonType(buttonName)
	if not self.entity then
		return
	end
	
	local entityClass = self.entity:GetEntityClass()
	if EntityClass:IsEquipment(entityClass) then
		self.Controls.m_ButtonPut.gameObject:SetActive(true) 
		self.Controls.m_PutText.text = "放入"..buttonName
	elseif EntityClass:IsLeechdom(entityClass) then
		self.Controls.m_ButtonPut.gameObject:SetActive(true)
		self.Controls.m_PutText.text = "放入"..buttonName
	end
end

-- 调整高度
function GoodsTooltipsButtonWidget1:AdjustHeight(height)
	-- local width = self.transform.sizeDelta.x
	--local vector2 = Vector2.New(width, height)
	--self.transform.sizeDelta = vector2
	--local newPostion = Vector2.New(self.transform.localPosition.x, height)
	--self.transform.localPosition.y = height
end

function GoodsTooltipsButtonWidget1:SetActive(on) 
	self.transform.gameObject:SetActive(on)
end

return this