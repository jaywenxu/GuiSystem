------------------------------------------------------------
-- PackWindow 的子窗口,不要通过 UIManager 访问
-- 装备界面包裹窗口 上的宝石
------------------------------------------------------------

local EquipCellWidgetClass	= require( "GuiSystem.WindowList.Forge.EquipCellWidget" )

local ForgeEquipWidget = UIControl:new
{
	windowName = "ForgeEquipWidget",
	m_CurSelsctEquipPlace = 0,
	m_dis = nil,
	m_totalScore = 0,
	tmpGoodsUid = {},
	m_showAniOver = false,
	m_showModel = false,
}

local this = ForgeEquipWidget   -- 方便书写
local zero = int64.new("0")


------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
--m_ButtonView : ButtonView (UnityEngine.UI.Button)
--m_EquipX : PersonPack_Equip_Cell_1 (UnityEngine.UI.Toggle)
------------------------------------------------------------
function ForgeEquipWidget:Attach( obj )
	UIControl.Attach(self,obj)

	-- 点击装备 ----------------------------------上的宝石
	for i = PERSON_EQUIPPLACE_WEAPON, PERSON_EQUIPPLACE_SHOES do
		self.Controls["m_EquipTrans"..(i+1)] = self.Controls.m_EquipGrid:Find("Player_Equip_Cell ("..tostring(i+1)..")")
		self.Controls["m_EquipTransObj"..(i+1)] = EquipCellWidgetClass:new{index = i}
		self.Controls["m_EquipTransObj"..(i+1)]:Attach(self.Controls["m_EquipTrans"..(i+1)].gameObject)
		self.Controls["m_EquipTransObj"..(i+1)]:SetItemCellSelectedCallback( function(on) self:OnEquipSelected(on, i) end )
	end
	
	return self
end

------------------------------------------------------------
function ForgeEquipWidget:SetEquipPlace(EquipPlace)
	self.m_CurSelsctEquipPlace = EquipPlace
	if self.transform == nil then
		return
	end
	
	if self.Controls["m_EquipTransObj"..(EquipPlace+1)] then
		self.Controls["m_EquipTransObj"..(EquipPlace+1)]:SetFocus(true)
	end
end

-- 点击某件装备
function ForgeEquipWidget:OnEquipSelected(on, equipPlace)
	if not on then
		return
	end
	
    local equipPart = GetHero():GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
    local forgePart = GetHero():GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart or not forgePart:IsLoad() then
		return
	end
	
	local EquipUID = equipPart:GetGoodsUIDByPos(equipPlace + 1)
	if not EquipUID or EquipUID == zero then
		--self.Controls["m_EquipTransObj"..(self.m_CurSelsctEquipPlace+1)]:SetSelect(true)
		return
	end
	
	if self.m_CurSelsctEquipPlace == equipPlace then
		return
	end
	self.m_CurSelsctEquipPlace = equipPlace
	UIManager.ForgeWindow:OnEquipSelected(on, equipPlace)
end

function ForgeEquipWidget:GetSelsctEquipPlace()
	return self.m_CurSelsctEquipPlace
end

-- 加载数据
function ForgeEquipWidget:ReloadData()
	if self.transform == nil then
		return
	end
	local hero = GetHero()
	if not hero then
		return
	end
	
	local equipPart = GetHero():GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	local InitEquipUID = equipPart:GetGoodsUIDByPos(self.m_CurSelsctEquipPlace + 1)
	local InitPlaceTmp = nil
	for i = PERSON_EQUIPPLACE_WEAPON, PERSON_EQUIPPLACE_SHOES do
		local EquipUID = equipPart:GetGoodsUIDByPos(i + 1)
		self:SetCell(i)
		if not EquipUID or EquipUID == zero then
			--self.Controls["m_EquipTransObj"..(i+1)]:ChildSetActive("Select",false)
		else
			if InitPlaceTmp == nil then
				InitPlaceTmp = i
			end
			--self.Controls["m_EquipTransObj"..(i+1)]:ChildSetActive("Select",true)
		end
	end

	if not InitEquipUID or InitEquipUID == zero then
		self.m_CurSelsctEquipPlace = InitPlaceTmp
	end
	self:SetEquipPlace(self.m_CurSelsctEquipPlace)
end

-- 清除某个格子图片
-- equipPlace 从1开始
function ForgeEquipWidget:ClearCell(equipPlace)
	if not equipPlace or  equipPlace < PERSON_EQUIPPLACE_WEAPON or equipPlace > PERSON_EQUIPPLACE_SHOES then
		return
	end
	local equipPart = GetHero():GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	self.Controls["m_EquipTransObj"..(equipPlace+1)]:SetItemInfo(equipPart:GetGoodsUIDByPos(equipPlace+1),equipPlace)
end

-- 设置某个格子图片
-- equipPlace 从0开始
function ForgeEquipWidget:SetCell(equipPlace)
	if equipPlace < PERSON_EQUIPPLACE_WEAPON or equipPlace > PERSON_EQUIPPLACE_SHOES then
		return
	end
	local pHero = GetHero()
	if not pHero then
		return
	end
	local equipPart = pHero:GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart or not forgePart:IsLoad() then
		return
	end
	
	local HoleProp = forgePart:GetHoleProp(equipPlace)
	if not HoleProp then
		return
	end
	self.Controls["m_EquipTransObj"..(equipPlace+1)]:SetUID(equipPart:GetGoodsUIDByPos(equipPlace+1),equipPlace)
end

function ForgeEquipWidget:ClearCellBottomText()
	for i = PERSON_EQUIPPLACE_WEAPON, PERSON_EQUIPPLACE_SHOES do
		--self.Controls["m_EquipTransObj"..(i+1)]:SetBottomText("")
	end
end

function ForgeEquipWidget:RefreshCellSmelt(SmeltType)
	if nil == self.transform then
		return
	end
	local nSmeltType = SmeltType or UIManager.ForgeWindow.ForgeSmeltWidget.m_CurSmeltType or 1
	local pHero = GetHero()
	if not pHero then
		return
	end
	local equipPart = pHero:GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart or not forgePart:IsLoad() then
		return
	end
	local SmeltKey = {"bySmeltLv","byPCTSmeltLv"}
	local SmeltTitle = {"+","附+"}

	for i = PERSON_EQUIPPLACE_WEAPON, PERSON_EQUIPPLACE_SHOES do
		local HoleProp = forgePart:GetHoleProp(i)
		if not HoleProp then
			return
		end
		if HoleProp[SmeltKey[nSmeltType]] ~= 0 then
			local BottomText = SmeltTitle[nSmeltType]..tostring(HoleProp[SmeltKey[nSmeltType]])
			--print(i..","..BottomText)
			self.Controls["m_EquipTransObj"..(i+1)]:SetBottomText(BottomText)
		else
			self.Controls["m_EquipTransObj"..(i+1)]:SetBottomText("")
		end
	end
end

-- true CanForge   false CanotForge   2 Full
function ForgeEquipWidget:SetUpGradeState(StateTable)
	--print("== 打造装备设置箭头-==== StateTable"..tostringEx(StateTable))
	if self.transform == nil then
		return
	end
	if not StateTable or type(StateTable) ~= "table" then
		return
	end
	for key,v in ipairs(StateTable) do
		if v == 2 then
			self.Controls["m_EquipTransObj"..key]:ChildSetActive("ForgeFull",true)
			self.Controls["m_EquipTransObj"..key]:SetRedDotState(false)
			--self.Controls["m_EquipTransObj"..key]:ChildSetActive("UpGrade",false)
			--self.Controls["m_EquipTransObj"..key]:ChildSetActive("BottomText",false)
		else
			self.Controls["m_EquipTransObj"..key]:ChildSetActive("ForgeFull",false)
			self.Controls["m_EquipTransObj"..key]:SetRedDotState(v)
			--self.Controls["m_EquipTransObj"..key]:ChildSetActive("UpGrade",v)
			--self.Controls["m_EquipTransObj"..key]:ChildSetActive("BottomText",true)
		end
	end
end

function ForgeEquipWidget:SetForceScore(ForceScore)
	self.Controls.m_ForceScore.text = ForceScore
end

return this