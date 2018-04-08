------------------------------------------------------------
-- TooltisWindow 的子窗口,不要通过 UIManager 访问
------------------------------------------------------------

local RightButtonType = {
	[1] = {2,5,3,4},		-- 包裹栏人物装备
	[2] = {1,6,9},			-- 包裹装备物品
	[3] = {7},				-- 仓库-点击包裹栏装备物品
	[4] = {8},				-- 仓库-点击仓库装备物品
	[5] = {5,3,4},			-- 包裹栏人物装备
}
local TipsRightButtonsWidget = UIControl:new
{
    windowName = "TipsRightButtonsWidget" ,
	entity = nil,
	m_ButtonInfo = {},
}

local this = TipsRightButtonsWidget   -- 方便书写
local zero = int64.new("0")

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function TipsRightButtonsWidget:Attach(obj)
	UIControl.Attach(self, obj)
	
	for i=1,5 do
		self.Controls["RightButtonTrans"..i] = self.transform:Find("RightButton ("..i..")")
		self.Controls["RightButton"..i] = self.Controls["RightButtonTrans"..i]:GetComponent(typeof(Button))
		self.Controls["ButtonName"..i] = self.Controls["RightButtonTrans"..i]:Find("ButtonName"):GetComponent(typeof(Text))
		self.Controls["RedDot"..i] = self.Controls["RightButtonTrans"..i]:Find("RedDot")
		self.Controls["RightButton"..i].onClick:AddListener(function() self:OnButtonClick(i) end)
	end
	return self
end

------------------------------------------------------------
function TipsRightButtonsWidget:OnDestroy()
	UIControl.OnDestroy(self)
end
------------------------------------------------------------



-- 穿上按钮
function TipsRightButtonsWidget:OnButtonUseClick()
	if not self.entity then
		return
	end
	
	local entityClass = self.entity:GetEntityClass()
	if EntityClass:IsEquipment(entityClass) then
		IGame.SkepClient.RequestOnEquip(self.entity:GetUID(), -1)
	elseif EntityClass:IsLeechdom(entityClass) then
		IGame.SkepClient.RequestUseItem(self.entity:GetUID())
	end
	
	UIManager.EquipTooltipsWindow:Hide()
end

-- 脱下按钮
function TipsRightButtonsWidget:OnButtonUnEquipClick()
	if not self.entity then
		return
	end
	
	local entity = self.entity
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
	if not schemeInfo then
		return
	end
	local equipPlace = schemeInfo.EquipLoc1	
    IGame.SkepClient:RequestUnEquip(index2lua(equipPlace))
	
	UIManager.EquipTooltipsWindow:Hide()
end

-- 镶嵌按钮
function TipsRightButtonsWidget:OnButtonSettingClick()
	if not self.entity then
		return
	end
	
	UIManager.EquipTooltipsWindow:Hide()
	if GameHelp:GetHeroLevel() < FORGE_SETTING_OPEN_LEVEL then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, FORGE_SETTING_OPEN_LEVEL.."级后开放！")
		return
	end
	local entity = self.entity
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
	if not schemeInfo then
		return
	end
	
	local equipPlace = schemeInfo.EquipLoc1	
	UIManager.PackWindow:CloseButtonClick()
	UIManager.ForgeWindow:Show(true)
    UIManager.ForgeWindow:ChangeForgePage(true, 2, equipPlace)
end

-- 洗炼按钮
function TipsRightButtonsWidget:OnButtonShuffleClick()
	if not self.entity then
		return
	end

	UIManager.EquipTooltipsWindow:Hide()
	if GameHelp:GetHeroLevel() < FORGE_SHUFFLE_OPEN_LEVEL then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, FORGE_SHUFFLE_OPEN_LEVEL.."级后开放！")
		return
	end
	
	local entity = self.entity
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
	if not schemeInfo then
		return
	end
	local equipPlace = schemeInfo.EquipLoc1	
	UIManager.PackWindow:CloseButtonClick()
	UIManager.ForgeWindow:Show(true)
    UIManager.ForgeWindow:ChangeForgePage(true, 3, equipPlace)
end

-- 强化按钮
function TipsRightButtonsWidget:OnButtonSmeltClick()
	if not self.entity then
		return
	end

	UIManager.EquipTooltipsWindow:Hide()
	if GameHelp:GetHeroLevel() < FORGE_SMELT_OPEN_LEVEL then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, FORGE_SMELT_OPEN_LEVEL.."级后开放！")
		return
	end
	
	local entity = self.entity
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
	if not schemeInfo then
		return
	end
	local equipPlace = schemeInfo.EquipLoc1	
	UIManager.PackWindow:CloseButtonClick()
	UIManager.ForgeWindow:Show(true)
    UIManager.ForgeWindow:ChangeForgePage(true, 1, equipPlace)
end

-- 打造按钮
function TipsRightButtonsWidget:OnButtonSmeltClick1() 
	UIManager.PackWindow:CloseButtonClick()
	UIManager.EquipTooltipsWindow:Hide()
	UIManager.ForgeWindow:Show(true)
    UIManager.ForgeWindow:ChangeForgePage(true, 1)
end

-- 分解按钮
function TipsRightButtonsWidget:OnButtonDecomposeClick()
	if not self.entity then
	   return
	end
	local entity     = self.entity
	local goodsID   = entity:GetNumProp(GOODS_PROP_GOODSID)
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, goodsID)
	if not schemeInfo then
		return
	end
    local nBaseLevel = schemeInfo.BaseLevel
	local nQuality   = entity:GetNumProp(EQUIP_PROP_QUALITY)
	local nShuffleScore = entity:GetShuffleScore()
	local decomposeInfo = IGame.rktScheme:GetSchemeInfo(EQUIPDECOMPOSE_CSV, nBaseLevel, nQuality)
	if not decomposeInfo then 
		return
	end

	local str = ""
	if decomposeInfo.nSilverCoin > 0 then 
		str = str .. "分解后将获得"..decomposeInfo.nSilverCoin.."银币"
	end
	
	if decomposeInfo.nItemId > 0 and decomposeInfo.nItemNum > 0 then 
		local leechdomInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, decomposeInfo.nItemId)
		if not leechdomInfo then
			return
		end
		
		if str ~= "" then 
			str = str .. "和"..leechdomInfo.szName.."x"..decomposeInfo.nItemNum
		else 
			str = str .. "分解后将获得 "..leechdomInfo.szName.."x"..decomposeInfo.nItemNum
		end
	end
	if nShuffleScore > 0 then
		str = str.."，并返还随机数量的洗炼石"
	end
	str = str.."，确认要分解吗？"
	local data = {}
	data.content = str
	data.confirmCallBack = function ()
		self:ConfirmDecompose()
	end
	data.cancelCallBack = function ()
	end
	UIManager.ConfirmPopWindow:ShowDiglog(data)


end

function TipsRightButtonsWidget:ConfirmDecompose() 
	local strfun     = "RequestBatchEquipDecompose({"..tostring(self.entity:GetUID()).."})"
	GameHelp.PostServerRequest(strfun)
	UIManager.EquipTooltipsWindow:Hide()
end

-- 包裹放入仓库
function TipsRightButtonsWidget:OnButtonPutInClick()
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
	IGame.SkepClient.RequestPacketToWare(uid)
	UIManager.EquipTooltipsWindow:Hide()
end

-- 从仓库中取出
function TipsRightButtonsWidget:OnButtonPutOutClick()
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
	IGame.SkepClient.RequestWareToPacket(uid)

	UIManager.EquipTooltipsWindow:Hide()
end

-- 摆摊按钮
function TipsRightButtonsWidget:OnButtonExchangeClick()
	if not self.entity then
		return
	end
	local nQuality = self.entity:GetNumProp(EQUIP_PROP_QUALITY)
	if nQuality < 3 then
		return
	end
	IGame.ExchangeClient:GoToSellCustomGoods(self.entity:GetUID())
	--UIManager.ExchangeWindow:ShowWindow(ExchangeWindowRightTabType.TAB_TYPE_BAITAN)
	UIManager.EquipTooltipsWindow:Hide()
end

-- 合成按钮
function TipsRightButtonsWidget:CheckExchangeShow()
	if not self.entity then
		return false
	end
	local nQuality = self.entity:GetNumProp(EQUIP_PROP_QUALITY)
	if nQuality < 3 then
		return false
	end
	local nBindQty = self.entity:GetNumProp(GOODS_PROP_NO_BIND_QTY)
	if nBindQty < 1 then
		return false
	end
	
	return true
end

function TipsRightButtonsWidget:CheckForgeShow(EquipPlace)
	local nLevel = GameHelp:GetHeroLevel()
	if nLevel >= FORGE_OPEN_LEVEL then
		return true
	end
	return false
end

local RightButtonFuncInfo = {
	[1] = {BtnName = "穿上",BtnFunc = function() this:OnButtonUseClick() end,		},
	[2] = {BtnName = "脱下",BtnFunc = function() this:OnButtonUnEquipClick() end},
	[3] = {BtnName = "镶嵌",BtnFunc = function() this:OnButtonSettingClick() end,CheckFunc = function (EquipPlace)return this:CheckForgeShow(EquipPlace) end,	RedDotFunc = function (EquipPlace)return TipsRightButtonsWidget:RedDot_Setting(EquipPlace) end},
	[4] = {BtnName = "洗炼",BtnFunc = function() this:OnButtonShuffleClick() end,CheckFunc = function (EquipPlace)return this:CheckForgeShow(EquipPlace) end,},
	[5] = {BtnName = "强化",BtnFunc = function() this:OnButtonSmeltClick() end,CheckFunc = function (EquipPlace)return this:CheckForgeShow(EquipPlace) end,	RedDotFunc = function (EquipPlace)return TipsRightButtonsWidget:RedDot_Smelt(EquipPlace) end},
	[6] = {BtnName = "分解",BtnFunc = function() this:OnButtonDecomposeClick() end},
	[7] = {BtnName = "放入",BtnFunc = function() this:OnButtonPutInClick() end},
	[8] = {BtnName = "取出",BtnFunc = function() this:OnButtonPutOutClick() end},
	[9] = {BtnName = "摆摊",BtnFunc = function() this:OnButtonExchangeClick() end,CheckFunc = function ()return this:CheckExchangeShow() end},
}


function TipsRightButtonsWidget:RedDot_Setting(EquipPlace)
	local forgePart = GetHero():GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	local CanUpGradeFlg,UpGrade = forgePart:GetSettingUpGradeFlg()
	return UpGrade[EquipPlace + 1].EquipCanSetFlg
end

function TipsRightButtonsWidget:RedDot_Smelt(EquipPlace)
	local forgePart = GetHero():GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	local CanUpGradeFlg,UpGrade1 = forgePart:GetNormalUpGradeFlg()
	local CanUpGradeFlg,UpGrade2 = forgePart:GetPCTUpGradeFlg()
	return UpGrade1[EquipPlace + 1] or UpGrade2[EquipPlace + 1]
end

function TipsRightButtonsWidget:Refresh(entity,subInfo )
	
	self.entity = entity
	local ButtonType = subInfo.bRightBtnType
	local RightBtnRedDot = subInfo.bRightBtnRedDot
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
	if not schemeInfo then
		return
	end
	local equipPlace = schemeInfo.EquipLoc1
	self.m_ButtonInfo = RightButtonType[ButtonType] or {}
	for i=1,5 do
		local RightButtonFuncIndex = self.m_ButtonInfo[i]
		if RightButtonFuncIndex then
			local RightButtonFuncInfo = RightButtonFuncInfo[RightButtonFuncIndex]
			if RightButtonFuncInfo then
				local bShowFlg = true
				if RightButtonFuncInfo.CheckFunc then
					if not RightButtonFuncInfo.CheckFunc() then
						bShowFlg = false
					end
				end
				if bShowFlg then
					self.Controls["RightButtonTrans"..i].gameObject:SetActive(true)
					self.Controls["ButtonName"..i].text = RightButtonFuncInfo.BtnName
					if RightButtonFuncInfo.RedDotFunc and RightBtnRedDot ~= false then
						local RedDotFlg = RightButtonFuncInfo.RedDotFunc(schemeInfo.EquipLoc1)
						if RedDotFlg == true then
							self.Controls["RedDot"..i].gameObject:SetActive(true)
						else
							self.Controls["RedDot"..i].gameObject:SetActive(false)
						end
					else
						self.Controls["RedDot"..i].gameObject:SetActive(false)
					end
				else
					self.Controls["RightButtonTrans"..i].gameObject:SetActive(false)
				end
			else
				self.Controls["RightButtonTrans"..i].gameObject:SetActive(false)
			end
		else
			self.Controls["RightButtonTrans"..i].gameObject:SetActive(false)
		end
	end
end

-- 点击回调
function TipsRightButtonsWidget:OnButtonClick(i)
	local RightButtonFuncIndex = self.m_ButtonInfo[i]
	local FuncInfo = RightButtonFuncInfo[RightButtonFuncIndex]
	if not FuncInfo then
		return
	end
	FuncInfo.BtnFunc()
end

return this