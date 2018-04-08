------------------------------------------------------------
-- ForgeWindow 的子窗口,不要通过 UIManager 访问
-- 打造宝石合成子窗口
------------------------------------------------------------
local PackageGemInfoCellClass	= require( "GuiSystem.WindowList.Forge.ForgeSetting.PackageGemInfoCell" )
local CommonGoodCellClass = require( "GuiSystem.WindowList.CommonWindow.CommonGoodCell" )
local GemInfoCellClass = require( "GuiSystem.WindowList.CommonWindow.GemInfoCell" )

local ForgeConpoundWidget = UIControl:new
{
	windowName = "ForgeConpoundWidget",
	m_curTargetGemTab = 0,
	m_TargetCurGemID = 0,
	m_TargetGemID = nil,
}

local nBaoshiJingHuaID = 2500
local this = ForgeConpoundWidget					-- 方便书写
local zero = int64.new("0")

local titleImagePath	= AssetPath.TextureGUIPath.."Strength/stronger_baoti_qianghua_1.png"

------------------------------------------------------------
function ForgeConpoundWidget:Attach( obj )
	UIControl.Attach(self,obj)
	
	-- 目标宝石类型切换
	self.Controls.m_TargetGemDrop = self.Controls.m_TargetGemTab:GetComponent(typeof(require("UnityEngine.UI.Dropdown")))
	self.callback_OnTargetGemTabChanged = function(value) self:OnTargetGemTabChanged(value) end
	self.Controls.m_TargetGemDrop.onValueChanged:AddListener(self.callback_OnTargetGemTabChanged)
	
	
	self.callback_OnTargetGemInfoCellChanged = function(GemCell,on) self:OnTargetGemInfoCellChanged(GemCell,on) end
	for i=1,15 do
		self.Controls["m_TargetGemInfoCellTans"..i] = self.Controls.m_TargetGemListGrid.transform:Find("TargetGemInfoCell ("..i..")")
		self.Controls["m_TargetGemInfoCell"..i] = PackageGemInfoCellClass:new()
		self.Controls["m_TargetGemInfoCell"..i]:Attach(self.Controls["m_TargetGemInfoCellTans"..i].gameObject)
		self.Controls["m_TargetGemInfoCell"..i].Controls.GoodCell:ChildSetActive("Count",true)
		self.Controls["m_TargetGemInfoCell"..i]:SetItemCellSelectedCallback(self.callback_OnTargetGemInfoCellChanged)
	end
		
	for i=1,15 do
		self.Controls["m_ConsumeGemInfoCellTans"..i] = self.Controls.m_ConsumeGemListGrid.transform:Find("ConsumeGemInfoCell ("..i..")")
		self.Controls["m_ConsumeGemInfoCell"..i] = GemInfoCellClass:new()
		self.Controls["m_ConsumeGemInfoCell"..i]:Attach(self.Controls["m_ConsumeGemInfoCellTans"..i].gameObject)
	end
	
	--合成宝石按钮
	if self.Controls.m_ConpoundBtn then
		self.Controls.m_ConpoundBtn.onClick:AddListener(function() self:OnConpoundBtnClick() end)
	end
    
	-- 目标宝石
	self.ShowTarGemCell = CommonGoodCellClass:new({})
	self.ShowTarGemCell:Attach(self.Controls.m_ShowTarGemCell.gameObject)
	self.callBack_OnShowTarGemCellClick = function (CellItem) self:OnShowTarGemCellClick(CellItem) end
	self.ShowTarGemCell:SetItemCellPointerClickCallback(self.callBack_OnShowTarGemCellClick)

	-- 材料宝石
	self.ShowConGemCell = CommonGoodCellClass:new({})
	self.ShowConGemCell:Attach(self.Controls.m_ShowConsumeGemCell.gameObject)
	self.ShowConGemCell:ChildSetActive("Count",true)
	
    return self
end

function ForgeConpoundWidget:OnShowTarGemCellClick(CellItem)
	local LeechdomID = CellItem.m_GoodID
	local subInfo = {
		bShowBtnType	= 0, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
	}
    UIManager.GoodsTooltipsWindow:SetGoodsInfo(LeechdomID, subInfo )
end

------------------------------------------------------------
-- 判断当前窗体是否显示
function ForgeConpoundWidget:isShow()
	if nil == self.transform then
		return false
	end
	return self.transform.gameObject.activeInHierarchy
end

-- 目标宝石类型切换
function ForgeConpoundWidget:OnTargetGemTabChanged(value)
	if self.curPackTab == value then -- 相同标签不用响应
		return
	end

	self.m_curTargetGemTab = value
	self.m_TargetCurGemID = nil
	self:Refresh()
end

function ForgeConpoundWidget:SetGemTypeDropValue(value)
    if self.curPackTab == value then -- 相同标签不用响应
		return
	end
    
    self.Controls.m_TargetGemDrop.value = value
    self.m_curTargetGemTab = value
	self.m_TargetCurGemID = nil
    
	self:Refresh()
end

function ForgeConpoundWidget:OnTargetGemInfoCellChanged(GemCell,on)
	if not on then
		return
	end
	self.m_TargetCurGemID = GemCell.m_CellInfo.nGoodID
	self:Refresh()
end

function ForgeConpoundWidget:OnConpoundBtnClick()
	if self.m_TargetCurGemID == 0 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请选择要合成的宝石类型")
		return
	end
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local nConsumeGemFlg,nConsumeGemValue,tConsumeDiamondInfo,nConsumeDiamond = self:GetConsumeDiamondInfo(self.m_TargetCurGemID)
	if nConsumeGemFlg == 2 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "材料不足！")
		return
	elseif nConsumeGemFlg == 3 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "对不起，没有找到合适的原料方案，可以充值哦(*^_^*) ")
		return
	end
	local tYuanLiaoTable = tConsumeDiamondInfo
	--PrintTable(tConsumeDiamondInfo)
	if nConsumeDiamond > 0 and GetGemAutoUseDiamond() ~= 1 then
		local pShowConGemInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, self.m_TargetCurGemID)
		if not pShowConGemInfo then
			return
		end

		--print(pShowConGemInfo.szName)
		local nCount = tConsumeDiamondInfo.nBuyXianJiaNum + tConsumeDiamondInfo.nBuyQuanJiaNum
		local szContent = "合成消耗：钻石" .. nConsumeDiamond
		if nCount > 0 then
			szContent = szContent .."、".. GameHelp.GetGoodsName(nBaoshiJingHuaID) .. "*" .. nCount
		end
		local tmpTable = {}
		copy_table( tmpTable, tYuanLiaoTable.HavedDiamond )
		table.sort(tmpTable, function(a, b) return a.nGoodID < b.nGoodID end )
		for i, v in pairs(tmpTable) do
			szContent = szContent .."、" ..GameHelp.GetGoodsName(v.nGoodID).."*" .. v.nGoodNum
		end	
		local pData = {
			content = szContent,
			confirmCallBack = function ()
				GameHelp.PostServerRequest("RequestForgeConpound("..self.m_TargetCurGemID..","..tostringEx(tYuanLiaoTable)..")")
			end,
            getMarkCallBack = GetGemAutoUseDiamond,
            setMarkCallBack = SetGemAutoUseDiamond,
            bMarkShow = true,
		}
		-- UIManager.ConfirmPopWindow:ShowDiglog(data)
        UIManager.CommonConfirmWindow:ShowConfirmInfo(pData)
		return
	end
	GameHelp.PostServerRequest("RequestForgeConpound("..self.m_TargetCurGemID..","..tostringEx(tYuanLiaoTable)..")")
end

-- 获得消耗材料的情况 
-- nConsumeGemFlg  材料方案结果
-- 0:不成功，未知原因 1:成功  2:不成功，宝石不足  3:不成功，未找到方案
function ForgeConpoundWidget:GetConsumeDiamondInfo(nTarGemID)
	local nConsumeGemFlg = nil
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local packetPart = pHero:GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	
	local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)	-- 获取职业
	
	local pGemPropScheme = forgePart.m_SettingCfgCenter:GetGemProp( nTarGemID, nVocation)
	if not pGemPropScheme then
		return
	end
	
	local nNeedValue = pGemPropScheme.nGemValue
	
	local nHavedGemTypeTotalValue,GemTypeList = self:CalGemTypeTotalValue(pGemPropScheme.nGemLv)
	local pPlazaGoodScheme,leftNum = IGame.PlazaClient:GetRecordByTypeAndID(1, nBaoshiJingHuaID)	-- 打折
	local nPlazaGemPrice = 0
	local nPlazaGemNum = 0
	if pPlazaGoodScheme then
		nPlazaGemPrice = pPlazaGoodScheme.nPrice * pPlazaGoodScheme.nCutPercent/100
		nPlazaGemNum = leftNum
	end
	local nPlazaQuanGoodScheme = IGame.PlazaClient:GetRecordByTypeAndID(2, nBaoshiJingHuaID)
	local nPlazaQuanGemPrice = 0
	if nPlazaQuanGoodScheme then
		nPlazaQuanGemPrice = nPlazaQuanGoodScheme.nPrice
	end
	
	local nShengYuValue = nNeedValue
	local ConsumeHaveGemList = {}
	local nConsumeGemValue = 0
	for key,v in ipairs(GemTypeList) do
		if nShengYuValue > 0 then
			local nItemTotalValue = v.nGoodNum * v.nGoodValue
			if nShengYuValue >= nItemTotalValue then
				v.nKouNum = v.nGoodNum
				nShengYuValue = nShengYuValue - nItemTotalValue
				table.insert(ConsumeHaveGemList,v)
			else
				local nKouNum = math.modf(nShengYuValue / v.nGoodValue)
				v.nKouNum = nKouNum
				nShengYuValue = nShengYuValue - nKouNum * v.nGoodValue
				if nKouNum > 0 then
					table.insert(ConsumeHaveGemList,v)
				end
			end
		end
	end
	nConsumeGemValue = nNeedValue - nShengYuValue

	local nXianJiaValue = nPlazaGemNum * 1
	local nBuyXianJiaNum = 0
	if nShengYuValue > 0 then
		if nShengYuValue >= nXianJiaValue then
			nBuyXianJiaNum = nPlazaGemNum
			nShengYuValue = nShengYuValue - nPlazaGemNum * 1
		else
			nBuyXianJiaNum =   math.modf(nShengYuValue / 1)
			nShengYuValue = nShengYuValue - nBuyXianJiaNum * 1
		end
	end
	
	local nBuyQuanJiaNum = math.modf(nShengYuValue / 1)
	
	nShengYuValue = nShengYuValue - nBuyQuanJiaNum * 1
	
	if nShengYuValue ~= 0 then
		nConsumeGemFlg = nConsumeGemFlg or 3
	end
	local Diamond	= pHero:GetActorYuanBao()
	local nConsumeDiamond = nPlazaQuanGemPrice * nBuyQuanJiaNum + nPlazaGemPrice * nBuyXianJiaNum
	if nConsumeDiamond > Diamond then
		nConsumeGemFlg = nConsumeGemFlg or 2
	end
	
	nConsumeGemFlg = nConsumeGemFlg or 1
	local tYuanLiaoTable = {}
	tYuanLiaoTable.HavedDiamond = ConsumeHaveGemList or {}
	tYuanLiaoTable.nBuyXianJiaNum = nBuyXianJiaNum
	tYuanLiaoTable.nBuyQuanJiaNum = nBuyQuanJiaNum
	return nConsumeGemFlg,nConsumeGemValue,tYuanLiaoTable,nConsumeDiamond
end


-- 计算某种类型宝石的总价值量
function ForgeConpoundWidget:CalGemTypeTotalValue(TargetGemLv)
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local packetPart = pHero:GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	
	local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)	-- 获取职业
	local nCurShowGemType = self.m_curTargetGemTab + 1
	
	local tGoodsUID = {} 
	local tFilterGoods = {}
	local curSize = 0
	local nGemTotalValue = 0
	local packetPart = pHero:GetEntityPart(ENTITYPART_PERSON_PACKET)
	if packetPart and packetPart:IsLoad() then
		tGoodsUID = packetPart:GetAllGoods()
		curSize = packetPart:GetSize()

		for i = 1, curSize do
			local uid = tGoodsUID[i]
			if uid then
				local entity = IGame.EntityClient:Get(uid)
				if entity then
					local entityClass = entity:GetEntityClass()
					if EntityClass:IsLeechdom(entityClass) then
						local nGoodIDTmp = entity:GetNumProp(GOODS_PROP_GOODSID)
						local nGoodNumTmp = entity:GetNumProp(GOODS_PROP_QTY)
						local pGemPropScheme = forgePart.m_SettingCfgCenter:GetGemProp( nGoodIDTmp, nVocation)
						if pGemPropScheme and (nGoodIDTmp == nBaoshiJingHuaID or (pGemPropScheme.nGemType == nCurShowGemType and pGemPropScheme.nGemLv < TargetGemLv )) then
							nGemTotalValue = nGemTotalValue + nGoodNumTmp * pGemPropScheme.nGemValue
							local tmpTable = {}
							tmpTable.nGoodID	= nGoodIDTmp
							tmpTable.nGemLv		= pGemPropScheme.nGemLv
							tmpTable.nGoodNum	= nGoodNumTmp
							tmpTable.nGoodUID	= uid
							tmpTable.nGoodValue	= pGemPropScheme.nGemValue
							table.insert(tFilterGoods, tmpTable)
						end
					end
				end
			end
		end
	end
	table.sort(tFilterGoods, 
	function(a, b)
		if a.nGemLv ~= b.nGemLv then
			return a.nGemLv > b.nGemLv
		end
		return a.nGoodID > b.nGoodID
	end)
	return nGemTotalValue,tFilterGoods
end
-- 
function ForgeConpoundWidget:OnEventTriggerClick(eventData)
    rkt.UIAndTextHelpTools.PassThroughPointerClickEvent( eventData )
end

function ForgeConpoundWidget:SetTargetCurGemID(TargetGemID)
	self.m_TargetGemID = TargetGemID
end

function ForgeConpoundWidget:SelectTargetGemID(TargetGemID)
	if not self:isLoaded() then
		DelayExecuteEx(10,function ()
			self:SelectTargetGemID(TargetGemID)
		end)
		return
	end
	self.m_TargetGemID = TargetGemID
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)	-- 获取职业
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	local pGemPropScheme = forgePart.m_SettingCfgCenter:GetGemProp( self.m_TargetGemID, nVocation) or {}
	if not pGemPropScheme then
		return
	end
	local nCurValue= self.Controls.m_TargetGemDrop.value
	if nCurValue ~= pGemPropScheme.nGemType - 1 then
		self.Controls.m_TargetGemDrop.value = pGemPropScheme.nGemType - 1
	else
		self:Refresh()
	end
	
end
function ForgeConpoundWidget:Refresh()
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	local packetPart = pHero:GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	
	local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)	-- 获取职业
	local Diamond	= pHero:GetActorYuanBao()

	local nCurShowGemType = self.m_curTargetGemTab + 1
	local pGemTypeScheme = forgePart.m_SettingCfgCenter:GetGemType_KeyGemLv(nCurShowGemType)
	if not pGemTypeScheme then
		return
	end
	local GemTypeSchemeCnt = table_count(pGemTypeScheme)
	for i=1,15 do
		local nGemID = pGemTypeScheme[i]
		if nGemID and nGemID > 0 then
			local nGemNum = packetPart:GetGoodNum(nGemID)
			local nGemNumText = ""
			if nGemNum > 0 then
				nGemNumText = ""..tostringEx(nGemNum)
			end
			self.Controls["m_TargetGemInfoCellTans"..i].gameObject:SetActive(true)
			self.Controls["m_TargetGemInfoCell"..i]:SetCellGoodID(nGemID,nGemNumText)
		else
			self.Controls["m_TargetGemInfoCellTans"..i].gameObject:SetActive(false)
		end
	end
	if self.m_TargetGemID then
		self.m_TargetCurGemID = self.m_TargetGemID
		self.m_TargetGemID = nil
	end

	if not self.m_TargetCurGemID or self.m_TargetCurGemID == 0 then
		self.m_TargetCurGemID = pGemTypeScheme[1]
	end
	
	local pGemPropScheme = forgePart.m_SettingCfgCenter:GetGemProp( self.m_TargetCurGemID, nVocation) or {}
	if not pGemPropScheme then
		return
	end
	self.Controls["m_TargetGemInfoCell"..tostringEx(pGemPropScheme.nGemLv)]:SetFocus(true)
	
	local OneLvGemID = pGemTypeScheme[1]
	local pOneLvGemPropScheme = forgePart.m_SettingCfgCenter:GetGemProp( OneLvGemID, nVocation) or {}
	if not pOneLvGemPropScheme then
		return
	end

	self.ShowTarGemCell:SetLeechdomItemInfo(self.m_TargetCurGemID)
	local pShowTarGemInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, self.m_TargetCurGemID) or {}
	local pShowTarGemPropScheme = forgePart.m_SettingCfgCenter:GetGemProp( self.m_TargetCurGemID, nVocation)
	local nTarGemValue = pShowTarGemPropScheme.nGemValue
	local nShowGemLV = pShowTarGemPropScheme.nGemLv - 1
	
	local ShowConGemID = pGemTypeScheme[nShowGemLV] or nBaoshiJingHuaID
	local pShowGemPropScheme = forgePart.m_SettingCfgCenter:GetGemProp( ShowConGemID, nVocation)
	local nShowGemValue = pShowGemPropScheme.nGemValue
	local nNeedCnt = math.modf(nTarGemValue/nShowGemValue)

	if not pShowTarGemInfo then
		self.Controls.m_TarGemName.text = ""
		self.Controls.m_TarGemProp.text = ""
	else
		local nGemPropID = pShowTarGemPropScheme.nPropID or 0
		local nGemPropNum = pShowTarGemPropScheme.nPropNum or 0
		self.Controls.m_TarGemName.text = pShowTarGemInfo.szName
		self.Controls.m_TarGemProp.text = GameHelp.PropertyName[nGemPropID].." <color=#FF7800FF>+"..tostringEx(nGemPropNum).."</color>"
	end
	self.ShowConGemCell:SetLeechdomItemInfo(ShowConGemID)
	local pShowConGemInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, ShowConGemID)
	if not pShowConGemInfo then
		self.Controls.m_ConsumeGemName.text = ""
	else
		self.Controls.m_ConsumeGemName.text = pShowConGemInfo.szName
	end
	

	self.Controls.m_HaveDiamond.text = Diamond
	self.Controls.m_ConsumeDiamond.text = Diamond
	
	local nConsumeGemFlg,nConsumeGemValue,tConsumeDiamondInfo = self:GetConsumeDiamondInfo(self.m_TargetCurGemID)
	local pPlazaGoodScheme,leftNum = IGame.PlazaClient:GetRecordByTypeAndID(1, nBaoshiJingHuaID)	-- 打折
	local nPlazaGemPrice = 0
	local nPlazaGemNum = 0
	local nCutPercent = 0
	if pPlazaGoodScheme then
		nCutPercent = pPlazaGoodScheme.nCutPercent/10
		nPlazaGemPrice = pPlazaGoodScheme.nPrice * pPlazaGoodScheme.nCutPercent/100
		nPlazaGemNum = leftNum
	end
	local nPlazaQuanGoodScheme = IGame.PlazaClient:GetRecordByTypeAndID(2, nBaoshiJingHuaID)
	local nPlazaQuanGemPrice = 0
	if nPlazaQuanGoodScheme then
		nPlazaQuanGemPrice = nPlazaQuanGoodScheme.nPrice
	end
	local ConsumeDiamond = tConsumeDiamondInfo.nBuyXianJiaNum * nPlazaGemPrice + tConsumeDiamondInfo.nBuyQuanJiaNum * nPlazaQuanGemPrice
	if ConsumeDiamond > Diamond then
		--self.Controls.m_ConsumeDiamond.text = "<color=#E4595AFF>"..ConsumeDiamond.."</color>"
		self.Controls.m_HaveDiamond.text = "<color=#E4595AFF>"..Diamond.."</color>"
		local nDiamondGemValue = 0
		if Diamond > tConsumeDiamondInfo.nBuyXianJiaNum * nPlazaGemPrice then
			nDiamondGemValue = tConsumeDiamondInfo.nBuyXianJiaNum + (Diamond - tConsumeDiamondInfo.nBuyXianJiaNum * nPlazaGemPrice)/nPlazaQuanGemPrice
		else
			nDiamondGemValue = Diamond / nPlazaGemPrice
		end
		local nTotalValue = nConsumeGemValue + nDiamondGemValue
		local nHaveCnt = math.modf(nTotalValue/nShowGemValue)
		local szShowGemCntText = "<color=#E4595AFF>"..nHaveCnt.."</color>/"..nNeedCnt
		self.ShowConGemCell:SetCountText(szShowGemCntText)
	else
		self.Controls.m_ConsumeDiamond.text = ConsumeDiamond
		local szShowGemCntText = nNeedCnt.."/"..nNeedCnt
		self.ShowConGemCell:SetCountText(szShowGemCntText)
	end
	
	
	local nConvertOneLvNeedCnt = pGemPropScheme.nGemValue/pOneLvGemPropScheme.nGemValue
	self.Controls.m_ContentText.text = pShowTarGemPropScheme.nGemLv.."级宝石自动计算成"..nConvertOneLvNeedCnt.."颗1级宝石"
	
	local ConGemTypeList = tConsumeDiamondInfo.HavedDiamond
	for i=1,13 do
		self.Controls["m_ConsumeGemInfoCell"..i]:SetCellInfo(ConGemTypeList[i])
		if ConGemTypeList[i] and ConGemTypeList[i].nKouNum and ConGemTypeList[i].nKouNum ~= 0 then
			self.Controls["m_ConsumeGemInfoCell"..i]:SetChildsText("GemProp","包裹中")
			self.Controls["m_ConsumeGemInfoCell"..i]:SetChildsText("ConsumeNum",""..(ConGemTypeList[i].nKouNum or 0).."颗")
		else
			self.Controls["m_ConsumeGemInfoCell"..i]:SetChildsText("ConsumeNum","")
		end
	end
	
	if tConsumeDiamondInfo.nBuyXianJiaNum == 0 then
		self.Controls["m_ConsumeGemInfoCell14"]:Hide()
	else
		self.Controls["m_ConsumeGemInfoCell14"]:SetCellGoodID(nBaoshiJingHuaID,"")
		self.Controls["m_ConsumeGemInfoCell14"]:SetChildsText("GemProp", "购买"--[[..tConsumeDiamondInfo.nBuyXianJiaNum * nPlazaGemPrice--]])
		self.Controls["m_ConsumeGemInfoCell14"]:SetChildsText("ConsumeNum",""..tConsumeDiamondInfo.nBuyXianJiaNum.."颗")
		self.Controls["m_ConsumeGemInfoCell14"]:SetChildsText("LabelText",nCutPercent.."折")
	end
		
	if tConsumeDiamondInfo.nBuyQuanJiaNum == 0 then
		self.Controls["m_ConsumeGemInfoCell15"]:Hide()
	else
		self.Controls["m_ConsumeGemInfoCell15"]:SetCellGoodID(nBaoshiJingHuaID,"")
		self.Controls["m_ConsumeGemInfoCell15"]:SetChildsText("GemProp", "购买"--[[tConsumeDiamondInfo.nBuyQuanJiaNum * nPlazaQuanGemPrice--]])
		self.Controls["m_ConsumeGemInfoCell15"]:SetChildsText("ConsumeNum",""..tConsumeDiamondInfo.nBuyQuanJiaNum.."颗")
	end
	

end

-- 添加新物品事件
function ForgeConpoundWidget:OnEventAddGoods()
	if not self:isShow() then
		return
	end
	self:Refresh()
end

-- 删除物品事件
function ForgeConpoundWidget:OnEventRemoveGoods()
	if not self:isShow() then
		return
	end
	self:Refresh()
end

-- 订阅事件
function ForgeConpoundWidget:SubscribeEvent()
	rktEventEngine.SubscribeExecute(EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.SubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
end

-- 取消订阅事件
function ForgeConpoundWidget:UnsubscribeEvent()
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	rktEventEngine.UnSubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
end

-- 初始化全局回调函数
function ForgeConpoundWidget:InitCallbacks()
	self.callback_OnEventAddGoods = function() self:OnEventAddGoods() end
	self.callback_OnEventRemoveGoods = function() self:OnEventRemoveGoods() end
end

return ForgeConpoundWidget







