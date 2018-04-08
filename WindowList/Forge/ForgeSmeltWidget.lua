------------------------------------------------------------
-- ForgeWindow 的子窗口,不要通过 UIManager 访问
-- 强化窗口
------------------------------------------------------------

local CommonGoodCellClass = require( "GuiSystem.WindowList.CommonWindow.CommonGoodCell" )
local CommonConsumeGoodWidgetClass = require( "GuiSystem.WindowList.CommonWindow.CommonConsumeGoodWidget" )

local titleImagePath_Normal		= AssetPath.TextureGUIPath.."Strength/Strength_dazao.png"
local titleImagePath_PCT		= AssetPath.TextureGUIPath.."Strength/Strength_dazao.png"

local ForgeSmeltWidget = UIControl:new
{
	windowName = "ForgeSmeltWidget",
	m_CurSmeltType = 1,
	m_CurEquipCell = 1,
	m_ShowGoodGetWayWinFlg1 = false,
	m_ShowGoodGetWayWinFlg2 = false,
	m_CurConsumeGoodID1 = 0,
	m_CurConsumeGoodID2 = 0,
	m_ConsumeEnough = true,
}

local this = ForgeSmeltWidget   -- 方便书写
local zero = int64.new("0")
local BREAK_TEXT_INIT	= "强化已达到瓶颈，需要突破，\n才可以继续升级"
local SmeltName = {"强化","附加强化"}
local FULL_LEVEL_TEXT	= "该装备已经%s至最高级"
------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function ForgeSmeltWidget:Attach( obj )
	UIControl.Attach(self,obj)

	-- //////普通强化///////
	self.Controls.m_NormalPanel = self.Controls.m_SmeltBG.transform:Find("Normal_SmeltPanel")
	self.NormalSmeltWidget = require("GuiSystem.WindowList.Forge.ForgeSmelt.NormalSmeltWidget")
	self.NormalSmeltWidget:Attach(self.Controls.m_NormalPanel.gameObject)
	
	-- //////附加强化///////
	self.Controls.m_PCTPanel = self.Controls.m_SmeltBG.transform:Find("PCT_SmeltPanel")
	self.PCT_SmeltWidget = require("GuiSystem.WindowList.Forge.ForgeSmelt.PCT_SmeltWidget")
	self.PCT_SmeltWidget:Attach(self.Controls.m_PCTPanel.gameObject)
	
	-- 注册强化选项卡事件
	for i = 1, 2 do
		self.Controls["m_TogRedDot"..i] = self.Controls["m_SmeltTypeTog"..i].transform:Find("RedDot")
		self.Controls["m_TogText"..i] = self.Controls["m_SmeltTypeTog"..i].transform:Find("Text"):GetComponent(typeof(Text))
		self.Controls["m_TogRedDot"..i].gameObject:SetActive(false)
		self.Controls["m_SmeltTypeTog"..i].onValueChanged:AddListener(function(on) self:OnSmeltTypeToggleClick(on, i) end)
	end
	
	-- 选中的装备
	if not self.Controls.m_SelectEquipCell then
		self.Controls.m_SelectEquipCell = self.transform:Find("PanelBG/EquipInfoBG/SelectEquipCell")
	end
	self.ShowEquipCell = CommonGoodCellClass:new({})
	self.ShowEquipCell:Attach(self.Controls.m_SelectEquipCell.gameObject)
	self.callBack_OnShowEquipCellClick = function (CellItem,on) self:OnShowEquipCellClick(CellItem,on) end
	self.ShowEquipCell:SetItemCellSelectedCallback(self.callBack_OnShowEquipCellClick)

	return self
end

function ForgeSmeltWidget:OnShowEquipCellClick(CellItem)
	local EquipUID = CellItem.m_UserData
	
	local pEquipEntity = IGame.EntityClient:Get(EquipUID)
	if pEquipEntity == nil then
		return false
	end

	local subInfo = {
		bShowBtn = 0,
		bShowCompare = false,
		bRightBtnType = 0,
	}
	UIManager.EquipTooltipsWindow:Show(true)
    UIManager.EquipTooltipsWindow:SetEntity(pEquipEntity, subInfo)
end

function ForgeSmeltWidget:OnSmeltTypeToggleClick(on,index)
	if not on then
		self.Controls["m_TogText"..index].color = UIFunction.ConverRichColorToColor("597993")
		return
	end
	
	self.Controls["m_TogText"..index].color = UIFunction.ConverRichColorToColor("16808E")

	if index == self.m_CurSmeltType then -- 相同标签不用响应
		return
	end
	self:Refresh(index)
end

function ForgeSmeltWidget:SetSmeltType(nSmeltType)
	self.m_CurSmeltType = nSmeltType
end

function ForgeSmeltWidget:NormalRefreshEquip()
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	
	local CanUpGradeFlg,UpGrade = forgePart:GetNormalUpGradeFlg()
	UIManager.ForgeWindow.ForgeEquipWidget:SetUpGradeState(UpGrade)
end

function ForgeSmeltWidget:PCTRefreshEquip()
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	
	local CanUpGradeFlg,UpGrade = forgePart:GetPCTUpGradeFlg()
	UIManager.ForgeWindow.ForgeEquipWidget:SetUpGradeState(UpGrade)
end

function ForgeSmeltWidget:IsCanUpGrade()
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	
	local CanUpGradeFlg,UpGrade = forgePart:GetNormalUpGradeFlg()
	if CanUpGradeFlg then
		return true
	end
	
	local CanUpGradeFlg,UpGrade = forgePart:GetPCTUpGradeFlg()
	if CanUpGradeFlg then
		return true
	end
	return false
end

function ForgeSmeltWidget:Refresh(SmeltType)
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	local equipPart = GetHero():GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	
	self.m_CurSmeltType = SmeltType or self.m_CurSmeltType
    print( "m_CurSmeltType := " .. self.m_CurSmeltType )
	self.Controls["m_SmeltTypeTog"..self.m_CurSmeltType].isOn = true
	local path = {
		titleImagePath_Normal,
		titleImagePath_PCT,
	}
	if UIManager.ForgeWindow.CommonWindowWidget then
		UIManager.ForgeWindow.CommonWindowWidget:SetName(path[self.m_CurSmeltType])
	end
	local CurEquipCell = UIManager.ForgeWindow:GetSelsctEquipPlace()
	local CanUpGradeFlg,UpGrade = forgePart:GetPCTUpGradeFlg()
	if UpGrade[CurEquipCell + 1] == true then
		self.Controls["m_TogRedDot2"].gameObject:SetActive(true)
	else
		self.Controls["m_TogRedDot2"].gameObject:SetActive(false)
	end
	
	local CanUpGradeFlg,UpGrade = forgePart:GetNormalUpGradeFlg()
	if UpGrade[CurEquipCell + 1] == true then
		self.Controls["m_TogRedDot1"].gameObject:SetActive(true)
	else
		self.Controls["m_TogRedDot1"].gameObject:SetActive(false)
	end
	local CurEquipUID = equipPart:GetGoodsUIDByPos(CurEquipCell + 1)
	self.ShowEquipCell:SetItemInfo(CurEquipUID)
	local entity = IGame.EntityClient:Get(CurEquipUID)
	if not entity or not EntityClass:IsEquipment(entity:GetEntityClass()) then
		return
	end
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
	local EquipName = schemeInfo.szName
	local EquipColor = GameHelp.GetEquipNameColor(entity:GetNumProp(EQUIP_PROP_QUALITY), entity:GetAdditionalPropNum())
	self.Controls.m_EquipName.text = "<color=#"..EquipColor..">"..EquipName.."</color>"
	
	UIManager.ForgeWindow.ForgeEquipWidget:ReloadData()
	if self.m_CurSmeltType == 1 then
		self.Controls.m_NormalPanel.gameObject:SetActive(true)
		self.Controls.m_PCTPanel.gameObject:SetActive(false)
		self:NormalRefreshEquip()
		self.NormalSmeltWidget:RefreshNormalSmelt()
	elseif self.m_CurSmeltType == 2 then
		self.Controls.m_NormalPanel.gameObject:SetActive(false)
		self.Controls.m_PCTPanel.gameObject:SetActive(true)
		self:PCTRefreshEquip()
		self.PCT_SmeltWidget:RefreshPCTSmelt()
	end
end

function ForgeSmeltWidget:ShowEquipCellChildSetActive(ChildName, ActiveFlg)
	self.ShowEquipCell:ChildSetActive( ChildName, ActiveFlg )
end

function ForgeSmeltWidget:RefreshShowEquipCell(NormalSmeltLv)
	local CurEquipCell = UIManager.ForgeWindow:GetSelsctEquipPlace()
	local HoleProp = forgePart:GetHoleProp(self.m_CurEquipCell)
	if not HoleProp then
		return
	end
	local NormalSmeltLv = HoleProp.bySmeltLv
end

function ForgeSmeltWidget:GetNormalSmeltScheme(SchemeName,nEquipID,nVocation,nNormalSmeltLv)
	local pNormalScheme = IGame.rktScheme:GetSchemeInfo(EQUIPNORMALSMELT_CSV , nEquipID,nVocation,nNormalSmeltLv)
	if not pNormalScheme then
		pNormalScheme = IGame.rktScheme:GetSchemeInfo(EQUIPNORMALSMELT_CSV , nEquipID,10000,nNormalSmeltLv)
	end
	return pNormalScheme
end

function ForgeSmeltWidget:PalyEffect()
	local ParentTrans = self.Controls.m_EffectBG.gameObject.transform
	local EfName = "ef_QHCG.prefab"
	GameHelp.PlayUI_Effect(ParentTrans,EfName,true)
end

function ForgeSmeltWidget:PalyBreakEffect()
	local ParentTrans = self.Controls.m_BreakEffectBG.gameObject.transform
	local EfName = "ef_TPCG.prefab"
	GameHelp.PlayUI_Effect(ParentTrans,EfName,true)
end

function ForgeSmeltWidget:Smelt_Success(place,level)
	local forgePart = GetHero():GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	forgePart:SetHoleProp(place,"bySmeltLv",level)
	forgePart:SetHoleProp(place,"bBreakState",false)
	if ForgeSmeltWidget:isShow() then
		ForgeSmeltWidget:Refresh(self.m_CurSmeltType)
		ForgeSmeltWidget:PalyEffect()
		UIManager.TiShiBattleUpWindow:SetDelayShow(false)
		DelayExecuteEx(300,function ()
			UIManager.TiShiBattleUpWindow:DelayShow()
		end)
	end
end

function ForgeSmeltWidget:Break_Success(place)
	local forgePart = GetHero():GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	forgePart:SetHoleProp(place,"bBreakState",true)
	ForgeSmeltWidget:Refresh(ForgeSmeltWidget.m_CurSmeltType)
	ForgeSmeltWidget:PalyBreakEffect()
end


function ForgeSmeltWidget:PCTSmelt_Success(place,level)
	local forgePart = GetHero():GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	forgePart:SetHoleProp(place,"byPCTSmeltLv",level)
	if ForgeSmeltWidget:isShow() then
		ForgeSmeltWidget:Refresh(ForgeSmeltWidget.m_CurSmeltType)
		ForgeSmeltWidget:PalyEffect()
		UIManager.TiShiBattleUpWindow:SetDelayShow(false)
		DelayExecuteEx(300,function ()
			UIManager.TiShiBattleUpWindow:DelayShow()
		end)
	end
end

return this