------------------------------------------------------------
-- ForgeWindow 的子窗口,不要通过 UIManager 访问
-- 洗炼窗口 
------------------------------------------------------------

local CommonGoodCellClass = require( "GuiSystem.WindowList.CommonWindow.CommonGoodCell" )
local CommonConsumeGoodWidgetClass = require( "GuiSystem.WindowList.CommonWindow.CommonConsumeGoodWidget" )

local ForgeShuffleWidget = UIControl:new
{
	windowName = "ForgeShuffleWidget",
	m_CurEquipCell = 1,
	m_CurConsumeGoodID1 = 0,
	m_ShowGoodGetWayWinFlg = false,
	m_bWaiting = false,
	m_TimerFuncHander = nil,
}

local this = ForgeShuffleWidget   -- 方便书写
local zero = int64.new("0")

local ImgPath_jichushuxingtisheng		= AssetPath.TextureGUIPath.."Strength/Strength_shuxingtisheng.png"
local ImgPath_jichushuxingxiajiang		= AssetPath.TextureGUIPath.."Strength/Strength_shuxingtixia.png"
------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function ForgeShuffleWidget:Attach( obj )
	UIControl.Attach(self,obj)

	-- //////原属性///////
	self.Controls.m_NowValueBGTrans = self.Controls.m_ShuffleValueBG.transform:Find("NowValueBG/ValueBG")
	self.Controls.m_NowScoreText = self.Controls.m_NowValueBGTrans:Find("ScoreText"):GetComponent(typeof(Text))	-- 原属性评分
	self.Controls.m_NowGrid = self.Controls.m_NowValueBGTrans:Find("ScrollRect/Grid")	-- 原属性GridGroup
	
	-- //////新属性///////
	self.Controls.m_NewValueBGTrans = self.Controls.m_ShuffleValueBG.transform:Find("NewValueBG/ValueBG")
	self.Controls.m_NewScoreText = self.Controls.m_NewValueBGTrans:Find("ScoreText"):GetComponent(typeof(Text))	-- 新属性评分
	self.Controls.m_NewGrid = self.Controls.m_NewValueBGTrans:Find("ScrollRect/Grid")	-- 新属性GridGroup
	
	self.Controls.m_BaseGrid = self.Controls.m_ShuffleValueBG.transform:Find("BasePropGrid")	-- 基础属性 GridGroup
	
	-- 洗炼数据显示
	for i = 1, 10 do
		self.Controls["m_NowProp"..i] = {}
		self.Controls["m_NowProp"..i].transform = self.Controls.m_NowGrid:Find("ProFusionCell ("..i..")")
		self.Controls["m_NowProp"..i].Text = self.Controls["m_NowProp"..i].transform:GetComponent(typeof(Text))
		self.Controls["m_NowProp"..i].transform.gameObject:SetActive(false)
		
		self.Controls["m_NewProp"..i] = {}
		self.Controls["m_NewProp"..i].transform = self.Controls.m_NewGrid:Find("ProFusionCell ("..i..")")
		self.Controls["m_NewProp"..i].Text = self.Controls["m_NewProp"..i].transform:GetComponent(typeof(Text))
		self.Controls["m_NewProp"..i].transform.gameObject:SetActive(false)
	end
		-- 基础属性数据显示
	for i = 1, 3 do
		self.Controls["m_BaseProp"..i] = {}
		self.Controls["m_BaseProp"..i].transform = self.Controls.m_BaseGrid:Find("ProFusionCell ("..i..")")
		self.Controls["m_BaseProp"..i].PropName = self.Controls["m_BaseProp"..i].transform:Find("PropName"):GetComponent(typeof(Text))
		self.Controls["m_BaseProp"..i].PropData = self.Controls["m_BaseProp"..i].transform:Find("PropData"):GetComponent(typeof(Text))
		self.Controls["m_BaseProp"..i].JianTouImg = self.Controls["m_BaseProp"..i].transform:Find("JianTouImg"):GetComponent(typeof(Image))
		self.Controls["m_BaseProp"..i].transform.gameObject:SetActive(false)
	end
	-- Stuff Good 附加 lua程序
	self.Controls.StuffGood =  CommonConsumeGoodWidgetClass:new()
	self.Controls.StuffGood:Attach(self.Controls.m_ConsumeGood.gameObject)
	self.Controls.StuffGood:SetGoodID(2121,0)
	-- 钻石
	self.Controls.m_Stuff = self.transform:Find("PanelBG/ShufflePanelBG/ConsumeBG/ConsumeGoodWidget")
	self.Controls.m_Diamond = self.transform:Find("PanelBG/ShufflePanelBG/ConsumeBG/Diamond")
	self.Controls.m_ConsumeNum = self.Controls.m_Diamond:Find("Consume/image/DiamondNum"):GetComponent(typeof(Text))
	self.Controls.m_HaveNum = self.Controls.m_Diamond:Find("Have/image/DiamondNum"):GetComponent(typeof(Text))
	self.Controls.m_GetDiamondBtn = self.Controls.m_Diamond:Find("Have/GetDiamondBtn"):GetComponent(typeof(Button))
	
	-- 获取宝石按钮
    self.Controls.m_GetDiamondBtn.onClick:AddListener(function() self:OnGetDiamondBtnClick() end)
	
	-- 是否使用钻石Toggle
	self.Controls.m_DiamondUseToggle = self.transform:Find("PanelBG/ShufflePanelBG/DiamondUseToggle"):GetComponent(typeof(Toggle))
	self.Controls.m_DiamondUseToggle.onValueChanged:AddListener(function(on) self:OnDiamondUseToggleClick(on) end)
	self.Controls.m_DiamondUseToggle.isOn = false
	
	--洗炼按钮
    self.Controls.m_ShuffleBtn.onClick:AddListener(function() self:OnShuffleBtnClick() end)
	--替换按钮
    self.Controls.m_ReplaceBtn.onClick:AddListener(function() self:OnReplaceBtnClick() end)
	--基础属性按钮
    self.Controls.m_BasePropBtn.onClick:AddListener(function() self:OnBasePropBtnClick() end)
	--self.Controls.m_BasePropBtn.interactable = false
	
    UIFunction.AddEventTriggerListener( self.Controls.m_EventTrigger , EventTriggerType.PointerClick , function( eventData ) self:OnEventTriggerClick(eventData) end )
	self:BasePropHide()
	self.Controls.m_EventTrigger.gameObject:SetActive(false)
	return self
end

function ForgeShuffleWidget:OnShuffleBtnClick()
	--IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "点击了洗炼")
	
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local CurEquipCell = UIManager.ForgeWindow:GetSelsctEquipPlace()

	local equipPart = pHero:GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	local CurEquipUID = equipPart:GetGoodsUIDByPos(CurEquipCell + 1)
	
	print("当前显示UID : "..tostringEx(CurEquipUID))
	if not CurEquipUID or CurEquipUID == 0 then
		return
	end
	local entity = IGame.EntityClient:Get(CurEquipUID)
	if not entity then
		return
	end
	
	if not entity:IsCanReCastShuffle() then
		self:DoShuffle()
	else
		local nScore = entity:ComputeEquipScore()
		local nShuffleScore = entity:ComputeEquipScore(false)
		local data = 
		{
			content = "洗炼出的属性更好，是否继续洗炼？",
			confirmCallBack = function() 
				UIManager.ForgeWindow.ForgeShuffleWidget:DoShuffle()
			end
		}
		if nScore < nShuffleScore then	-- 洗炼出来的属性好
			UIManager.ConfirmPopWindow:ShowDiglog(data)
		else
			self:DoShuffle()
		end
	end
end

function ForgeShuffleWidget:DoShuffle()
	if self.DoShuffleTimeCD and luaGetTickCount() - self.DoShuffleTimeCD < 300 then
		return
	end
	self.DoShuffleTimeCD = luaGetTickCount()
	
	if self.m_bWaiting == true then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "操作太频繁，请稍候再试！")
		return
	end
	
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local CurEquipCell = UIManager.ForgeWindow:GetSelsctEquipPlace()

	local equipPart = pHero:GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	local CurEquipUID = equipPart:GetGoodsUIDByPos(CurEquipCell + 1)
	
	print("当前显示UID : "..tostringEx(CurEquipUID))
	if not CurEquipUID or CurEquipUID == 0 then
		return
	end
	local entity = IGame.EntityClient:Get(CurEquipUID)
	if not entity then
		return
	end
	
	local nEquipID = entity:GetNumProp(GOODS_PROP_GOODSID)
	local nQuality = entity:GetNumProp(EQUIP_PROP_QUALITY)
	if nQuality == 1 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "绿色装备不能洗炼")
		return
	end
	local pShuffleScheme = IGame.rktScheme:GetSchemeInfo(EQUIPSHUFFLE_CSV ,nEquipID,nQuality)
	if not pShuffleScheme then
		return false
	end
	local ConsumeGoodID = pShuffleScheme.nGoodID
	local ConsumeGoodNum = pShuffleScheme.nGoodNum

	local Diamond	= pHero:GetActorYuanBao()
	local pPlazaGoodScheme = IGame.PlazaClient:GetRecordByTypeAndID(2,ConsumeGoodID) or {}
	local GoodPrice = pPlazaGoodScheme.nPrice
	local PackGoodNum = packetPart:GetGoodNum(ConsumeGoodID)
	local NeedDiamond = 0
	local ToggleFlg = self.Controls.m_DiamondUseToggle.isOn
	local ToggleNumFlg = 0
	if ConsumeGoodNum > PackGoodNum then  -- 消耗的材料不足
		NeedDiamond = (ConsumeGoodNum - PackGoodNum) * GoodPrice
		if ToggleFlg == false then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "材料不足，无法洗炼")
			return
		elseif NeedDiamond > Diamond then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "钻石不足，无法洗炼")
			return
		end
	end
	if ToggleFlg == true then
		ToggleNumFlg = 1
	end
	GameHelp.PostServerRequest("RequestForgeShuffle("..tostringEx(CurEquipCell)..","..tostringEx(ToggleNumFlg)..")")
	
	self.m_bWaiting = true
	self.m_TimerFuncHander = DelayExecuteEx(1000*10,function ()
		self:Shuffle_CDTimer()
	end)
end

function ForgeShuffleWidget:OnReplaceBtnClick()
	local ShowText = {
			"洗炼出的属性更好，是否替换？",
			"洗炼出的属性低于原属性，确认要替换？",
		}
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local CurEquipCell = UIManager.ForgeWindow:GetSelsctEquipPlace()

	local equipPart = pHero:GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	local CurEquipUID = equipPart:GetGoodsUIDByPos(CurEquipCell + 1)
	
	print("当前显示UID : "..tostringEx(CurEquipUID))
	if not CurEquipUID or CurEquipUID == 0 then
		return
	end
	local entity = IGame.EntityClient:Get(CurEquipUID)
	if not entity then
		return
	end
	if not entity:IsCanReCastShuffle() then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "没有可替换的属性")
		return
	end
	local nScore = entity:ComputeEquipScore()
	local nShuffleScore = entity:ComputeEquipScore(false)
	local data = 
	{
		content = "洗炼出的属性低于原属性，确认要替换？",
		confirmCallBack = function() 
			UIManager.ForgeWindow.ForgeShuffleWidget:Replace()
		end
	}
	if nScore > nShuffleScore then	-- 洗炼出来的属性不好
		UIManager.ConfirmPopWindow:ShowDiglog(data)
	else
		self:Replace()
	end
end

function ForgeShuffleWidget:Replace()
	--IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "点击了替换")
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local CurEquipCell = UIManager.ForgeWindow:GetSelsctEquipPlace()

	local equipPart = pHero:GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	local CurEquipUID = equipPart:GetGoodsUIDByPos(CurEquipCell + 1)
	
	print("当前显示UID : "..tostringEx(CurEquipUID))
	local entity = IGame.EntityClient:Get(CurEquipUID)
	if not entity then
		return
	end
	if not entity:IsCanReCastShuffle() then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "没有可替换的属性")
		return
	end
	GameHelp.PostServerRequest("RequestForgeReplace("..tostringEx(CurEquipCell)..")")
end

function ForgeShuffleWidget:OnBasePropBtnClick()
	--IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "点击了基础属性")
	local openState = self.Controls.m_BaseGrid.gameObject.activeInHierarchy
	if openState then
		self:BasePropHide()
	else
		local pHero = GetHero()
		if pHero == nil then
			return
		end
		local CurEquipCell = UIManager.ForgeWindow:GetSelsctEquipPlace()

		local equipPart = pHero:GetEntityPart(ENTITYPART_PERSON_EQUIP)
		if not equipPart or not equipPart:IsLoad() then
			return
		end
		local CurEquipUID = equipPart:GetGoodsUIDByPos(CurEquipCell + 1)
		
		print("当前显示UID : "..tostringEx(CurEquipUID))
		local entity = IGame.EntityClient:Get(CurEquipUID)
		if not entity then
			return
		end
		local nEquipGoodID = entity:GetNumProp(GOODS_PROP_GOODSID)
		local nQuality = entity:GetNumProp(EQUIP_PROP_QUALITY)
		local nAdditionalPropNum = entity:GetAdditionalPropNum()
		local nShuffleAdditionalPropNum = entity:GetShuffleAdditionalPropNum()
		local pEquipBasePropScheme = IGame.rktScheme:GetSchemeInfo(EQUIPBASEPROP_CSV , nEquipGoodID, nQuality, nAdditionalPropNum)
		local pEquipShuffleBasePropScheme = IGame.rktScheme:GetSchemeInfo(EQUIPBASEPROP_CSV , nEquipGoodID, nQuality, nShuffleAdditionalPropNum)
		local BaseChangeTable = {}
		for i=1,3 do
			local nType = pEquipBasePropScheme["Type"..i]
			local value = pEquipBasePropScheme["Value"..i]
			local nShuffleType = pEquipShuffleBasePropScheme["Type"..i]
			local ShuffleValue = pEquipShuffleBasePropScheme["Value"..i]
			print("=====,"..tostringEx(nType)..","..tostringEx(value)..","..tostringEx(nShuffleType)..","..tostringEx(ShuffleValue)..",")
			if nType ~= nil and nType ~= 0 and value ~= ShuffleValue then
				BaseChangeTable[nType] = {}
				BaseChangeTable[nType].NowValue = value
				BaseChangeTable[nType].NewValue = ShuffleValue
				if ShuffleValue > value then
					BaseChangeTable[nType].UpFlg = 1
				else
					BaseChangeTable[nType].UpFlg = 2
				end
			end
		end
		local JianTouPath = {
			GuiAssetList.GuiRootTexturePath.."Common_frame/Common_shangsheng.png",
			GuiAssetList.GuiRootTexturePath.."Common_frame/Common_xiajiang.png",
		}
		for i=1,3 do
			self.Controls["m_BaseProp"..i].transform.gameObject:SetActive(false)
		end
		if table_count(BaseChangeTable) > 0 then
			self.Controls.m_BaseGrid.gameObject:SetActive(true)
			local i = 0
			for nType,ValueInfo in pairs(BaseChangeTable) do
				i = i + 1
				self.Controls["m_BaseProp"..i].transform.gameObject:SetActive(true)
				
				self.Controls.m_EventTrigger.gameObject:SetActive(true)
				local PropName = GameHelp.PropertyName[nType]
				local ValueText = string.format("%4d → %4d", ValueInfo.NowValue, ValueInfo.NewValue)
				self.Controls["m_BaseProp"..i].PropName.text = PropName
				self.Controls["m_BaseProp"..i].PropData.text = ValueText
				UIFunction.SetImageSprite(self.Controls["m_BaseProp"..i].JianTouImg,JianTouPath[ValueInfo.UpFlg])	-- 设置图标
			end
		end
	end
end

function ForgeShuffleWidget:OnEventTriggerClick(eventData)
	local openState = self.Controls.m_BaseGrid.gameObject.activeInHierarchy
	--print("点击了 trigger"..tostringEx(openState))
    rkt.UIAndTextHelpTools.PassThroughPointerClickEvent( eventData )
	if not openState then
		return
	end
	self.Controls.m_EventTrigger.gameObject:SetActive(false)
	self:BasePropHide()
end

function ForgeShuffleWidget:OnGetDiamondBtnClick()
	UIManager.ShopWindow:ShowShopWindow(3)
end

function ForgeShuffleWidget:OnDiamondUseToggleClick(on)
	if on then
		self.Controls.m_Stuff.gameObject:SetActive(false)
		self.Controls.m_Diamond.gameObject:SetActive(true)
		--self:RefreshConsumeDiamond()
	else
		self.Controls.m_Stuff.gameObject:SetActive(true)
		self.Controls.m_Diamond.gameObject:SetActive(false)
		--self:RefreshShuffleConsumeGood()
	end
end

function GetEquipPropContext(prop)
	local text = ""
	if prop and type(prop) == "table" then
		local nType = prop.nType
		local value = prop.nid
		local propDesc = IGame.rktScheme:GetSchemeInfo(EQUIPATTACHPROPDESC_CSV, nType)
		if propDesc then 
			local strDesc = propDesc.strDesc 
			local subDesc = propDesc.subDesc
			local nSign   = propDesc.nSign
			local nPercent = propDesc.nPercent 
			local strSign = "" 
			if nSign == 0 then 
				strSign = "-"
			elseif nSign == 1 then
				strSign = "+" 
			else  
				strSign = ""
			end
			
			local strPerc = ""
			if nPercent == 1 then 
				value = value / 100
				strPerc = "%"
			end
			
			local specialDesc = ""
			local nValue = value
			local vocationName = ""
			
			-- 特殊属性
			if GameHelp:IsSpecialProp(nType) then
				-- 多重属性：致命一击;致命伤害  抗致命一击;抗致命伤害
				if nType == CREATURE_PROP_CUR_FATAL_AND_FATAL_PER or nType == CREATURE_PROP_CUR_TOUGH_AND_TOUGH_PER then
					local specialScheme = IGame.rktScheme:GetSchemeInfo(EQUIPSPECIALPROP_CSV, nType, nValue)
					local descTable = split_string(strDesc, ";")
					if specialScheme then 
						local tempTable = {}
						for j = 2, #(specialScheme.DetailItem), 2 do
							table.insert(tempTable, specialScheme.DetailItem[j])
						end
						
						local nSecondValue = math.floor(tempTable[2]/100)
						specialDesc = specialDesc..descTable[1]..strSign..tempTable[1].."，"..descTable[2]..strSign..nSecondValue.."%"
					end
				-- 多重属性：物理、法术伤害增加百分比  物理、法术伤害吸收百分比
				elseif nType == CREATURE_PROP_CUR_P_AND_M_ENHANCE_PER or nType == CREATURE_PROP_CUR_P_AND_M_ABSORB_PER then
					local specialScheme = IGame.rktScheme:GetSchemeInfo(EQUIPSPECIALPROP_CSV, nType, nValue)
					local descTable = split_string(strDesc, ";")
					if specialScheme then 
						local tempTable = {}
						for j = 2, #(specialScheme.DetailItem), 2 do
							table.insert(tempTable, math.floor(specialScheme.DetailItem[j] / 100))
						end
						
						specialDesc = specialDesc..descTable[1]..strSign..tempTable[1].."%，"..descTable[2]..strSign..tempTable[2].."%"
					end
				-- 提升某个技能等级
				elseif nType == CREATURE_PROP_CUR_SKILL_SINGLE then
					local specialScheme = IGame.rktScheme:GetSchemeInfo(EQUIPSPECIALPROP_CSV, nType, value)
					if specialScheme then
						local t = GameHelp:ConvertToDictTable(specialScheme.DetailItem)
						for j = 1, #t do
							local nSkillId = t[j].key
							local nLevel = t[j].value
							local SkillInfo = IGame.rktScheme:GetSchemeInfo(SKILLUPDATE_CSV, nSkillId, nLevel)
							if SkillInfo then
								value = nLevel
								local vocationId = SkillInfo.Voc
								local skillName = SkillInfo.Name
								if vocationId == 0 then 
									vocationName = "真武"..skillName
								elseif vocationId == 1 then 
									vocationName = "灵心"..skillName
								elseif vocationId == 2 then
									vocationName = "天羽"..skillName
								else
									vocationName = "玄宗"..skillName	
								end
							end
						end
					end
				-- 提升全技能等级
				elseif nType == CREATURE_PROP_CUR_SKILL_ALL then
					local specialScheme = IGame.rktScheme:GetSchemeInfo(EQUIPSPECIALPROP_CSV, nType, value)
					if specialScheme then
						local t = GameHelp:ConvertToDictTable(specialScheme.DetailItem)
						local skillId = t[1].key
						local skillLevel = t[1].value
						local voc = IGame.SkillClient:GetSkillVoc(skillId) -- 根据第一个技能来取职业
						value = skillLevel -- 根据第一个技能取等级
						
						if voc == PERSON_VOCATION_ZHENWU then 
							vocationName = "真武"
						elseif voc == PERSON_VOCATION_LINGXIN then 
							vocationName = "灵心"
						elseif voc == PERSON_VOCATION_TIANYU then
							vocationName = "天羽"
						elseif voc == PERSON_VOCATION_XUANZONG then
							vocationName = "玄宗"
						else
							vocationName = "未知"
						end
					end
				end
			end
			
			local desc = strDesc..strSign..value
			if vocationName ~= "" then 
				desc = vocationName..desc
			end
			
			if specialDesc ~= "" then
				desc =  specialDesc
			end 
			
			local schemeDesc = IGame.rktScheme:GetSchemeInfo(PROPDESC_CSV, prop.descID)
			if schemeDesc then 
				local word = schemeDesc.desc 
				if subDesc ~= "" then
					text = text .. "【".. word .."】" .. desc..strPerc..subDesc
				else 
					text = text .. "【".. word .."】" .. desc..strPerc
				end
			else 
				if subDesc ~= "" then 
					text = text ..desc..strPerc..subDesc
				else 
					text = text ..desc..strPerc
				end
			end
		end
	end
	
	return text
end

function ForgeShuffleWidget:RefreshConsumeDiamond(ConsumeDiamond)
	if not ConsumeDiamond then
		return
	end
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end
	local Diamond	= pHero:GetActorYuanBao()
	if Diamond < ConsumeDiamond then -- 不足
		self.Controls.m_HaveNum.text = "<color=red>"..Diamond.."</color>"
		self.Controls.m_ConsumeNum.text = ConsumeDiamond
	else
		self.Controls.m_HaveNum.text = Diamond
		self.Controls.m_ConsumeNum.text = ConsumeDiamond
	end
end

function ForgeShuffleWidget:RefreshEquip()
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	
	local CanUpGradeFlg,UpGrade = forgePart:GetShuffleUpGradeFlg()
	UIManager.ForgeWindow.ForgeEquipWidget:SetUpGradeState(UpGrade)
	UIManager.ForgeWindow.ForgeEquipWidget:ClearCellBottomText()
end

function ForgeShuffleWidget:IsCanUpGrade()
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	
	local CanUpGradeFlg,UpGrade = forgePart:GetShuffleUpGradeFlg()
	
	if CanUpGradeFlg then
		return true
	end
	return false
end

function ForgeShuffleWidget:Refresh()
	if not self.transform then
		return
	end
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local CurEquipCell = UIManager.ForgeWindow:GetSelsctEquipPlace()
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	local equipPart = pHero:GetEntityPart(ENTITYPART_PERSON_EQUIP)
	if not equipPart or not equipPart:IsLoad() then
		return
	end
	
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	local HoleProp = forgePart:GetHoleProp(CurEquipCell)
	if not HoleProp then
		return
	end
	
	local CurEquipUID = equipPart:GetGoodsUIDByPos(CurEquipCell + 1)
	
	--print("当前显示UID : "..tostringEx(CurEquipUID))
	if not CurEquipUID or CurEquipUID == 0 then
		for i = 1, 10 do
			self.Controls["m_NowProp"..i].transform.gameObject:SetActive(false)
			self.Controls["m_NewProp"..i].transform.gameObject:SetActive(false)
		end
		return
	end
	local entity = IGame.EntityClient:Get(CurEquipUID)
	if not entity then
		return
	end
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
	local EquipName = schemeInfo.szName
	local EquipColor = GameHelp.GetEquipNameColor(entity:GetNumProp(EQUIP_PROP_QUALITY), entity:GetAdditionalPropNum())
	--self.Controls.m_EquipName.text = tostring("<color=" ..EquipColor.. ">" .. EquipName .. "</color>" or "未穿装备")
	
	local EquipNowScore = entity:ComputeEquipScore()
	local EquipShuffleScore = 0
	local AdditionalPropNum = entity:GetAdditionalPropNum()
	local ShuffleAdditionalPropNum = entity:GetShuffleAdditionalPropNum()
	if ShuffleAdditionalPropNum == 0 then
		EquipShuffleScore = 0
	else
		EquipShuffleScore = entity:ComputeEquipScore(false)
	end
	self.Controls.m_NowScoreText.text = "评分："..math.floor(EquipNowScore/10)
	if EquipShuffleScore ~= 0 then
		self.Controls.m_NewScoreText.text = "评分："..math.floor(EquipShuffleScore/10)
	else
		self.Controls.m_NewScoreText.text = ""
	end
	
	-- 获得Now附加属性
	local EquipNowPropContext = entity:GetAllEffectInfo()
	-- 获得New附加属性
	local EquipNewPropContext = entity:GetAllShuffleEffectInfo()
	if ShuffleAdditionalPropNum ~= AdditionalPropNum then
		--self.Controls.m_BasePropBtn.interactable = true
		self.Controls.m_ChangeBG.gameObject:SetActive(true)
		if AdditionalPropNum < ShuffleAdditionalPropNum then -- 提升
			UIFunction.SetImageSprite( self.Controls.m_BasePropBtnImg , ImgPath_jichushuxingtisheng )
		else	-- 下降
			UIFunction.SetImageSprite( self.Controls.m_BasePropBtnImg , ImgPath_jichushuxingxiajiang )
		end
		self.Controls.m_BasePropBtnImg:SetNativeSize()
	else
		self.Controls.m_ChangeBG.gameObject:SetActive(false)
	end
	local EquipColorShuffle = GameHelp.GetEquipNameColor(entity:GetNumProp(EQUIP_PROP_QUALITY), ShuffleAdditionalPropNum)
	for i=1,MAX_ADDITIONAL_PROP_NUM do
		-- 显示 Now 附加属性
		local prop = EquipNowPropContext[i]
		local text = GetEquipPropContext(prop)
		if text and text ~= "" then
			self.Controls["m_NowProp"..i].Text.text = "<color=#"..EquipColor..">"..text.."</color>"
			self.Controls["m_NowProp"..i].transform.gameObject:SetActive(true)
		else
			self.Controls["m_NowProp"..i].transform.gameObject:SetActive(false)
		end
		if ShuffleAdditionalPropNum ~= 0 then
			self.Controls.m_NewValueBGTrans.gameObject:SetActive(true)
			-- 显示 New 附加属性
			local prop = EquipNewPropContext[i]
			local text = GetEquipPropContext(prop)
			if text and text ~= "" then
				self.Controls["m_NewProp"..i].Text.text = "<color=#"..EquipColorShuffle..">"..text.."</color>"
				self.Controls["m_NewProp"..i].transform.gameObject:SetActive(true)
			else
				self.Controls["m_NewProp"..i].Text.text = ""
				self.Controls["m_NewProp"..i].transform.gameObject:SetActive(false)
			end
		else
			self.Controls.m_NewValueBGTrans.gameObject:SetActive(false)
		end
	end
	local nEquipID = entity:GetNumProp(GOODS_PROP_GOODSID)
	local nQuality = entity:GetNumProp(EQUIP_PROP_QUALITY)
	self:RefreshEquip()
	local pShuffleScheme = IGame.rktScheme:GetSchemeInfo(EQUIPSHUFFLE_CSV ,nEquipID,nQuality)
	if not pShuffleScheme then
		return false
	end
	local ConsumeGoodID = pShuffleScheme.nGoodID
	local ConsumeGoodNum = pShuffleScheme.nGoodNum
	local ConsumeDiamondScheme = IGame.rktScheme:GetSchemeTable(PLAZAGOODS_CSV,ConsumeGoodID) or {}
	if not ConsumeDiamondScheme then
		return false
	end
	
	local Diamond	= pHero:GetActorYuanBao()
	local pPlazaGoodScheme = IGame.PlazaClient:GetRecordByTypeAndID(2,ConsumeGoodID) or {}
	local GoodPrice = pPlazaGoodScheme.nPrice
	local PackGoodNum = packetPart:GetGoodNum(ConsumeGoodID)
	local NeedDiamond = 0
	if ConsumeGoodNum > PackGoodNum then  -- 消耗的材料不足
		NeedDiamond = (ConsumeGoodNum - PackGoodNum) * GoodPrice
		self.Controls.m_DiamondUseToggle.gameObject:SetActive(true)
	else
		self.Controls.m_DiamondUseToggle.gameObject:SetActive(false)
		self.Controls.m_DiamondUseToggle.isOn = false
	end
	self:RefreshConsumeDiamond(NeedDiamond)
	self.Controls.StuffGood:SetGoodID(pShuffleScheme.nGoodID,pShuffleScheme.nGoodNum)
	self:OnDiamondUseToggleClick(self.Controls.m_DiamondUseToggle.isOn )
	DelayExecuteEx( 100,function ()
		self:Hide()
		self:Show()
		DelayExecuteEx( 100,function ()
		self:Hide()
		self:Show()
	end)
	end)
end

function ForgeShuffleWidget:Shuffle_Success()
	if self.m_TimerFuncHander then
		KillDelayExecuteFunction(self.m_TimerFuncHander)
	end
	self.m_bWaiting = false
end

function ForgeShuffleWidget:Shuffle_CDTimer()
	self.m_bWaiting = false
end


function ForgeShuffleWidget:IsCanReCastShuffle()
end

function ForgeShuffleWidget:BasePropHide()
	self.Controls.m_BaseGrid.gameObject:SetActive(false)
end

return this