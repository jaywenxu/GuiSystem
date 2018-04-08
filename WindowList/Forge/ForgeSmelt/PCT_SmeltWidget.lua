------------------------------------------------------------
-- ForgeWindow 的子窗口,不要通过 UIManager 访问
-- 强化窗口
------------------------------------------------------------

local CommonConsumeGoodWidgetClass = require( "GuiSystem.WindowList.CommonWindow.CommonConsumeGoodWidget" )

local PCT_SmeltWidget = UIControl:new
{
	windowName = "PCT_SmeltWidget",
	m_NeedLv = 0,
}

local this = PCT_SmeltWidget   -- 方便书写
local zero = int64.new("0")
local BREAK_TEXT_INIT	= "强化已达到瓶颈，需要突破，\n才可以继续升级"
local SmeltName = {"强化","附加强化"}
local FULL_LEVEL_TEXT	= "该装备已经%s至最高级"
------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function PCT_SmeltWidget:Attach( obj )
	UIControl.Attach(self,obj)


	-- 消耗物品
	self.ConsumeGoodWidget = CommonConsumeGoodWidgetClass:new()
	self.ConsumeGoodWidget:Attach(self.Controls.m_ConsumeGoodWidget.gameObject)		-- 消耗物品子窗口


	--
	self.Controls.m_NowValueBGTrans = self.transform:Find("SmeltValuePanel/NowValueBG")
	local Normal_NowValueBGLuaObj = UIControl:new{windowName = "Normal_NowValueBGLuaObj"}
	UIControl.Attach(Normal_NowValueBGLuaObj,self.Controls.m_NowValueBGTrans.gameObject)
	self.Controls.m_NormalNowGrid = Normal_NowValueBGLuaObj.Controls.m_Grid										-- 普通强化当前属性网格
	self.Controls.m_NormalLab1 = Normal_NowValueBGLuaObj.Controls.m_LevelText									-- 普通强化当前等级文本
	
	-- 强化数据显示
	for i = 1, 4 do
		self.Controls["m_SmeltProp"..i] = {}
		self.Controls["m_SmeltProp"..i].transform	= self.Controls.m_NormalNowGrid.transform:Find("ProFusionCell ("..i..")")
		self.Controls["m_SmeltProp"..i].Text		= self.Controls["m_SmeltProp"..i].transform:Find("Text1"):GetComponent(typeof(Text))
		self.Controls["m_SmeltProp"..i].TextNow		= self.Controls["m_SmeltProp"..i].transform:Find("NowValue"):GetComponent(typeof(Text))
		self.Controls["m_SmeltProp"..i].TextNext	= self.Controls["m_SmeltProp"..i].transform:Find("NextValue"):GetComponent(typeof(Text))
	end

	-- 隐藏所有的
	for i=2,4 do
		self.Controls["m_SmeltProp"..i].transform.gameObject:SetActive(false)
	end
	
	--强化按钮
    self.Controls.m_UpGradeBtn.onClick:AddListener(function() self:OnUpGradeBtnClick() end)
	
	return self
end

function PCT_SmeltWidget:OnUpGradeBtnClick()
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end

	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	self.m_CurEquipCell = UIManager.ForgeWindow:GetSelsctEquipPlace()
	local HoleProp = forgePart:GetHoleProp(self.m_CurEquipCell)
	if not HoleProp then
		return
	end
	local NormalSmeltLv = HoleProp.bySmeltLv
	local PCTSmeltLv = HoleProp.byPCTSmeltLv
	local HeroLevel = GameHelp:GetHeroLevel()
	if self.m_NeedLv > HeroLevel then
		local szString = string.format("当前级别只能强化到%d级，需要%d级才可以继续强化",PCTSmeltLv,self.m_NeedLv)
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, szString)
		return
	end
	
	if self.ConsumeGoodWidget.m_ConsumeEnough == false then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "材料不足，无法强化")
		return
	end
	local place = UIManager.ForgeWindow:GetSelsctEquipPlace()
	--IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "当前强化类型是 : "..tostring(self.m_CurSmeltType).."当前装备类型是 : "..tostring(self.m_CurEquipCell))
	
	if PCTSmeltLv >= MAX_PCT_SMELT_LEVEL then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "已满级")
		return
	end
	UIManager.TiShiBattleUpWindow:SetDelayShow(true)
	GameHelp.PostServerRequest("RequestForgePCTSmelt("..place..")")
end

-- 刷新附加强化
function PCT_SmeltWidget:RefreshPCTSmelt()
	local pHero = IGame.EntityClient:GetHero()
	if pHero == nil then
		return false
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	local equipPart = pHero:GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart then
		return
	end
	local CurEquipCell = UIManager.ForgeWindow:GetSelsctEquipPlace()
	local HoleProp = forgePart:GetHoleProp(CurEquipCell)
	if not HoleProp then
		return
	end
	
	local PCTSmeltLv = HoleProp.byPCTSmeltLv

	self.Controls["m_SmeltProp1"].transform.gameObject:SetActive(true)
	self.Controls["m_SmeltProp1"].Text.text		= "附加强化"
	self.Controls["m_SmeltProp1"].TextNow.text		= "+"..tostringEx(PCTSmeltLv)
	self.Controls["m_SmeltProp1"].TextNext.text	= "+"..tostringEx(PCTSmeltLv+1)
	
	local EquipUID = equipPart:GetGoodsUIDByPos(CurEquipCell + 1)

	if not EquipUID or EquipUID == zero then
		return
	end
	local entity = IGame.EntityClient:Get(EquipUID)
	if not entity or not EntityClass:IsEquipment(entity:GetEntityClass()) then
		return
	end
	
	-- ===== 满级 =====
	if PCTSmeltLv >= MAX_PCT_SMELT_LEVEL then -- 满级
		self.Controls.m_ValuePanel.gameObject:SetActive(false)
		self.Controls.m_FullText.gameObject:SetActive(true)
		UIManager.ForgeWindow.ForgeSmeltWidget:ShowEquipCellChildSetActive("ForgeFull",true)
		self.Controls.m_FullText.text = "该装备已经附加强化至最高级"
		self.ConsumeGoodWidget:Hide()
		return
	else
		self.Controls.m_ValuePanel.gameObject:SetActive(true)
		self.Controls.m_FullText.gameObject:SetActive(false)
		UIManager.ForgeWindow.ForgeSmeltWidget:ShowEquipCellChildSetActive("ForgeFull",false)
	end
	
--	print("我的职业ID是 ： "..nCreatureVocation)
	nCreatureVocation = 0
	local pPCTLab1Scheme = IGame.rktScheme:GetSchemeInfo(EQUIPPCTSMELT_CSV , PCTSmeltLv)
	local pPCTLab2Scheme = IGame.rktScheme:GetSchemeInfo(EQUIPPCTSMELT_CSV , PCTSmeltLv + 1)
	local nNeedLevel = pPCTLab2Scheme.nHeroLV or 0
	local nLevel = GetHero():GetNumProp(CREATURE_PROP_LEVEL)
	self.m_NeedLv = nNeedLevel
	self.ConsumeGoodWidget:SetGoodID(pPCTLab2Scheme.nGoodID or pPCTLab1Scheme.nGoodID ,pPCTLab2Scheme.nGoodNum or 0 )
	self.ConsumeGoodWidget:Show()
--[[	if nLevel < nNeedLevel then		--	等级不足
		print("==============等级不足================")
		self.Controls.m_ValuePanel.gameObject:SetActive(false)
		self.Controls.m_FullText.gameObject:SetActive(true)
		self.Controls.m_FullText.text = "当前级别只能强化到"..PCTSmeltLv.."级\n需要"..nNeedLevel.."级才可以继续强化"
		return
	end--]]
	
	local PCT_NowPercent = 0
	local PCT_NextPercent = 0
	if pPCTLab1Scheme and pPCTLab1Scheme.nPercent then
		PCT_NowPercent = pPCTLab1Scheme.nPercent/100
	end
	
	if pPCTLab2Scheme and pPCTLab2Scheme.nPercent then
		PCT_NextPercent = pPCTLab2Scheme.nPercent/100
	end
	
	self.Controls["m_SmeltProp2"].Text.text = "基础属性"
	self.Controls["m_SmeltProp2"].TextNow.text = tostring(PCT_NowPercent).."%"
	self.Controls["m_SmeltProp2"].TextNext.text = tostring(PCT_NextPercent).."%"
	self.Controls["m_SmeltProp2"].transform.gameObject:SetActive(true)
end

return this