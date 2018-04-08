------------------------------------------------------------
-- ForgeWindow 的子窗口,不要通过 UIManager 访问
-- 强化窗口
------------------------------------------------------------

local CommonConsumeGoodWidgetClass = require( "GuiSystem.WindowList.CommonWindow.CommonConsumeGoodWidget" )

local NormalSmeltWidget = UIControl:new
{
	windowName = "NormalSmeltWidget",
	m_NormalSmeltLv = 0,
	m_NeedLv = 0,
}

local this = NormalSmeltWidget   -- 方便书写
local zero = int64.new("0")
local BREAK_TEXT_INIT	= "强化已达到瓶颈，需要突破，\n才可以继续升级"
local SmeltName = {"强化","附加强化"}
local FULL_LEVEL_TEXT	= "该装备已经%s至最高级"

local BtnName_Smelt		= AssetPath.TextureGUIPath.."Strength/Strength_qianghua.png"
local BtnName_Break		= AssetPath.TextureGUIPath.."Strength/Strength_tupo.png"

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function NormalSmeltWidget:Attach( obj )
	UIControl.Attach(self,obj)

	-- 消耗物品
	self.Normal_ConsumeGoodWidget = CommonConsumeGoodWidgetClass:new()
	self.Normal_ConsumeGoodWidget:Attach(self.Controls.m_Normal_ConsumeGoodWidget.gameObject)		-- 消耗物品子窗口


	-- 普通强化  当前等级
	self.Controls.m_NowValueBGTrans = self.transform:Find("SmeltValuePanel/NowValueBG")
	local Normal_NowValueBGLuaObj = UIControl:new{windowName = "Normal_NowValueBGLuaObj"}
	UIControl.Attach(Normal_NowValueBGLuaObj,self.Controls.m_NowValueBGTrans.gameObject)
	self.Controls.m_NormalNowGrid = Normal_NowValueBGLuaObj.Controls.m_Grid										-- 普通强化当前属性网格
	self.Controls.m_NormalLab1 = Normal_NowValueBGLuaObj.Controls.m_LevelText									-- 普通强化当前等级文本
	
	-- 强化数据显示
	for i = 1, 4 do
		self.Controls["m_NormalSmeltNowProp"..i] = {}
		self.Controls["m_NormalSmeltNowProp"..i].transform	= self.Controls.m_NormalNowGrid.transform:Find("ProFusionCell ("..i..")")
		self.Controls["m_NormalSmeltNowProp"..i].Text		= self.Controls["m_NormalSmeltNowProp"..i].transform:Find("Text1"):GetComponent(typeof(Text))
		self.Controls["m_NormalSmeltNowProp"..i].TextNow	= self.Controls["m_NormalSmeltNowProp"..i].transform:Find("NowValue"):GetComponent(typeof(Text))
		self.Controls["m_NormalSmeltNowProp"..i].TextNext	= self.Controls["m_NormalSmeltNowProp"..i].transform:Find("NextValue"):GetComponent(typeof(Text))
	end

	-- 隐藏所有的
	for i=2,4 do
		self.Controls["m_NormalSmeltNowProp"..i].transform.gameObject:SetActive(false)
	end
	
	--强化按钮
    self.Controls.m_UpGradeBtn.onClick:AddListener(function() self:OnUpGradeBtnClick() end)
	
	return self
end

function NormalSmeltWidget:OnUpGradeBtnClick()
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
	local HeroLevel = GameHelp:GetHeroLevel()
	if self.m_NeedLv > HeroLevel then
		local szString = string.format("当前级别只能强化到%d级，需要%d级才可以继续强化",NormalSmeltLv,self.m_NeedLv)
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, szString)
		return
	end
	
	if self.Normal_ConsumeGoodWidget.m_ConsumeEnough == false then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "材料不足，无法强化")
		return
	end
	local place = UIManager.ForgeWindow:GetSelsctEquipPlace()
	if NormalSmeltLv >= MAX_EQUIPSMELT_LEVEL then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "已满级")
		return
	end
	UIManager.TiShiBattleUpWindow:SetDelayShow(true)
	if self.BreakFlg then
		GameHelp.PostServerRequest("RequestForgeBreak("..place..")")
	else
		GameHelp.PostServerRequest("RequestForgeNormalSmelt("..place..")")
	end
end

function NormalSmeltWidget:RefreshNormalSmelt()
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local forgePart = GetHero():GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	
	local equipPart = GetHero():GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	local CurEquipCell = UIManager.ForgeWindow:GetSelsctEquipPlace()
	local HoleProp = forgePart:GetHoleProp(CurEquipCell)
	if not HoleProp then
		return
	end
	local NormalSmeltLv = HoleProp.bySmeltLv
	self.Controls["m_NormalSmeltNowProp1"].transform.gameObject:SetActive(true)
	self.Controls["m_NormalSmeltNowProp1"].Text.text		= "强化等级"
	self.Controls["m_NormalSmeltNowProp1"].TextNow.text		= "+"..tostringEx(NormalSmeltLv)
	self.Controls["m_NormalSmeltNowProp1"].TextNext.text	= "+"..tostringEx(NormalSmeltLv+1)
	
	local CurEquipUID = equipPart:GetGoodsUIDByPos(CurEquipCell + 1)
	--print("当前显示UID : "..tostringEx(CurEquipUID))
	local entity = IGame.EntityClient:Get(CurEquipUID)
	if not entity then
		return
	end
	local nAdditionalPropNum = entity:GetAdditionalPropNum() -- 取装备的附加属性个数
	
	-- 获得基础属性增加百分比
	local NowAdditionalPercent = entity:GetAdditionalPercent()
	
	-- 获得New基础属性增加百分比
	local ShuffleAdditionalPercent = entity:GetShuffleAdditionalPercent()
	local nQuality = entity:GetNumProp(EQUIP_PROP_QUALITY)
	local nGoodID = entity:GetNumProp(GOODS_PROP_GOODSID)
	
	-- 获取装备的基础属性
	local pEquipBasePropScheme = IGame.rktScheme:GetSchemeInfo(EQUIPBASEPROP_CSV , nGoodID, nQuality, nAdditionalPropNum)
	if not pEquipBasePropScheme then
		return
	end
	
	local nCreatureVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)
	local nLevel = GetHero():GetNumProp(CREATURE_PROP_LEVEL)
	
	local EquipUID = equipPart:GetGoodsUIDByPos(CurEquipCell + 1)
	
	if not EquipUID or EquipUID == zero then
		return
	end
	local entity = IGame.EntityClient:Get(EquipUID)
	if not entity or not EntityClass:IsEquipment(entity:GetEntityClass()) then
		return
	end
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
	local EquipName = schemeInfo.szName
	local EquipColor = GameHelp.GetEquipNameColor(entity:GetNumProp(EQUIP_PROP_QUALITY), entity:GetAdditionalPropNum())
	
	local pNormalLab1Scheme = self:GetNormalSmeltScheme(EQUIPNORMALSMELT_CSV , CurEquipCell,nCreatureVocation,NormalSmeltLv) or {}
	local pNormalLab2Scheme = self:GetNormalSmeltScheme(EQUIPNORMALSMELT_CSV , CurEquipCell,nCreatureVocation,NormalSmeltLv + 1) or {}
	local nNeedLevel = pNormalLab2Scheme.nHeroLV or 0
	self.Normal_ConsumeGoodWidget:SetGoodID(pNormalLab2Scheme.nGoodID or pNormalLab1Scheme.nGoodID ,pNormalLab2Scheme.nGoodNum or 0 )
	-- ===== 满级 =====
	self.Normal_ConsumeGoodWidget:Show()
	if NormalSmeltLv >= MAX_EQUIPSMELT_LEVEL then -- 满级
		self.Controls.m_ValuePanel.gameObject:SetActive(false)
		self.Controls.m_FullText.gameObject:SetActive(true)
		UIManager.ForgeWindow.ForgeSmeltWidget:ShowEquipCellChildSetActive("ForgeFull",true)
		self.Controls.m_FullText.text = "该装备已经强化至最高级"
		self.Normal_ConsumeGoodWidget:Hide()
		return
	else
		self.Controls.m_ValuePanel.gameObject:SetActive(true)
		self.Controls.m_FullText.gameObject:SetActive(false)
		UIManager.ForgeWindow.ForgeSmeltWidget:ShowEquipCellChildSetActive("ForgeFull",false)
	end
	self.m_NeedLv = nNeedLevel
	if nLevel < nNeedLevel then		--	等级不足
		--self.Controls.m_NormalPanel.gameObject:SetActive(false)
		--self.Controls.m_BreakPanel.gameObject:SetActive(true)
		--self.Controls.m_FullText.text = "当前级别只能强化到"..NormalSmeltLv.."级\n需要"..nNeedLevel.."级才可以继续强化"
	end
	
	-- 判断是否突破
	if pNormalLab2Scheme and pNormalLab2Scheme.nBreakFlg == 1 and HoleProp.bBreakState == false then -- 需要突破 且 还未突破
		UIFunction.SetImageSprite(self.Controls.m_BtnNameImg,BtnName_Break)
		self.Controls.m_ValuePanel.gameObject:SetActive(false)
		self.Controls.m_FullText.gameObject:SetActive(true)
		self.Controls.m_FullText.text = BREAK_TEXT_INIT
		self.Normal_ConsumeGoodWidget:SetGoodID(pNormalLab2Scheme.nBreakGoodID1,pNormalLab2Scheme.nBreakGoodNum1 or 0 )
		self.BreakFlg = true
		return
	else
		UIFunction.SetImageSprite(self.Controls.m_BtnNameImg,BtnName_Smelt)
		self.Controls.m_ValuePanel.gameObject:SetActive(true)
		self.Controls.m_FullText.gameObject:SetActive(false)
		self.BreakFlg = false
	end
	
	for i=2,4 do
		local nType = pEquipBasePropScheme["Type"..i]
		local value = (pEquipBasePropScheme["Value"..i] or 0) * (1 + NowAdditionalPercent)
		value = math.floor(value)
		local propDesc = IGame.rktScheme:GetSchemeInfo(EQUIPATTACHPROPDESC_CSV, pEquipBasePropScheme["Type"..i])
		propDesc = propDesc or {}
		local ShuXingName = string.format("%-12s", (propDesc.strDesc or "未知属性"))
		self.Controls["m_NormalSmeltNowProp"..i].Text.text		= ShuXingName
		self.Controls["m_NormalSmeltNowProp"..i].TextNow.text	= (pNormalLab1Scheme["nPropValue"..i] or 0) + value
		self.Controls["m_NormalSmeltNowProp"..i].TextNext.text	= (pNormalLab2Scheme["nPropValue"..i] or 0) + value

		if nType == 0 or nType == nil then
			self.Controls["m_NormalSmeltNowProp"..i].transform.gameObject:SetActive(false)
		else
			self.Controls["m_NormalSmeltNowProp"..i].transform.gameObject:SetActive(true)
		end
	end
end

function NormalSmeltWidget:GetNormalSmeltScheme(SchemeName,nEquipID,nVocation,nNormalSmeltLv)
	local pNormalScheme = IGame.rktScheme:GetSchemeInfo(EQUIPNORMALSMELT_CSV , nEquipID,nVocation,nNormalSmeltLv)
	if not pNormalScheme then
		pNormalScheme = IGame.rktScheme:GetSchemeInfo(EQUIPNORMALSMELT_CSV , nEquipID,10000,nNormalSmeltLv)
	end
	return pNormalScheme
end

function NormalSmeltWidget:PalyEffect()
	local ParentTrans = self.Controls.m_EffectBG.gameObject.transform
	local EfName = "ef_QHCG.prefab"
	GameHelp.PlayUI_Effect(ParentTrans,EfName,true)
end

function NormalSmeltWidget:Smelt_Success(place,level)
	local forgePart = GetHero():GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	forgePart:SetHoleProp(place,"bySmeltLv",level)
	forgePart:SetHoleProp(place,"bBreakState",false)
	if NormalSmeltWidget:isShow() then
		
		NormalSmeltWidget:Refresh(NormalSmeltWidget.m_CurSmeltType)
		NormalSmeltWidget:PalyEffect()
		UIManager.TiShiBattleUpWindow:SetDelayShow(false)
		DelayExecuteEx(300,function ()
			UIManager.TiShiBattleUpWindow:DelayShow()
		end)
	end
end

return this