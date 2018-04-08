------------------------------------------------------------
-- ForgeWindow 的子窗口,不要通过 UIManager 访问
-- 镶嵌窗口
------------------------------------------------------------

-- local PackageGemInfoCellClass	= require( "GuiSystem.WindowList.Forge.ForgeSetting.PackageGemInfoCell" )
local ForgeGemInfoCellClass		= require( "GuiSystem.WindowList.Forge.ForgeSetting.ForgeGemInfoCell" )
local CanSetGemTypeItemClass    = require( "GuiSystem.WindowList.Forge.ForgeSetting.CanSetGemTypeItem" )

local titleImagePath_Normal		= AssetPath.TextureGUIPath.."Strength/stronger_baoti_qianghua_1.png"
local titleImagePath_PCT		= AssetPath.TextureGUIPath.."Strength/stronger_baoti_fujiaqianghua_1.png"

-- 默认可镶嵌的宝石类型
local DEF_EXP_CANSETGEMTYPE = -1

-- 可镶嵌类宝石类型
local DefSetGemsTypeStart = 1
local DefSetGemsTypeEnd   = 12

-- 装备宝石孔位置
local Def_GemPlace_First    = 1
local Def_GemPlace_Last     = 6

-- 宝石孔最多可镶嵌的宝石类型
local Def_GemPlace_SetGemType_Limit = 6

-- 宝石精华ID
local BAOSHIJINGHUA_GOODSID = 2500

local ForgeSettingWidget = UIControl:new
{
	windowName = "ForgeSettingWidget",
	m_CurGemPlace = 1,
    m_ListCanSetGemType = {},
    
    m_nExpandedCanSetGemType = nil,    -- 可被镶嵌的Gem被展开了的类型
    m_nDefExpCanSetGemType = DEF_EXP_CANSETGEMTYPE,     -- 子类默认可被展开的类型
}

local this = ForgeSettingWidget   -- 方便书写
local zero = int64.new("0")

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function ForgeSettingWidget:Attach( obj )
	UIControl.Attach(self,obj)

	--前往合成宝石按钮
    self.Controls.m_GoToSynthesisBtn.onClick:AddListener(function() self:OnGoToSynthesisBtnClick() end)
	
	for i=Def_GemPlace_First, Def_GemPlace_Last do
		self.Controls["m_ForgeGemInfoCellTans"..i] = self.Controls.m_SettedGemGrid.transform:Find("ForgeGemInfoCell ("..i..")")
		self.Controls["m_ForgeGemInfoCell"..i] = ForgeGemInfoCellClass:new()
		self.Controls["m_ForgeGemInfoCell"..i]:Attach(self.Controls["m_ForgeGemInfoCellTans"..i].gameObject)
		self.Controls["m_ForgeGemInfoCell"..i]:SetItemCellSelectedCallback(function (ForgeCell,on) self:OnForgeGemClick(ForgeCell,on) end)
		self.Controls["m_ForgeGemInfoCell"..i]:SetInsex(i)
	end
	
	self.m_OnPackageGemClick = function (CellInfo) self:OnPackageGemClick(CellInfo)	end
	--[[
	for i=1,10 do
		self.Controls["m_PacketGemInfoCellTans"..i] = self.Controls.m_CanSetGemGrid.transform:Find("PacketGemInfoCell ("..i..")")
		self.Controls["m_PacketGemInfoCell"..i] = PackageGemInfoCellClass:new()
		self.Controls["m_PacketGemInfoCell"..i]:Attach(self.Controls["m_PacketGemInfoCellTans"..i].gameObject)
		self.Controls["m_PacketGemInfoCell"..i]:SetCellClickCallBack(self.m_OnPackageGemClick)
	end
	]]
	return self
end

--======================按钮回调函数====================
-- 前往宝石合成
function ForgeSettingWidget:OnGoToSynthesisBtnClick()
	UIManager.ForgeWindow:ChangeForgePage(true, 4)
end

-- 点击拥有钻石Cell
function ForgeSettingWidget:OnPackageGemClick(CellInfo)
	if self.m_CurGemPlace == 0 then
		return
	end
	local CurEquipCell = UIManager.ForgeWindow:GetSelsctEquipPlace()
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	local HoleProp = forgePart:GetHoleProp(CurEquipCell)
	if not HoleProp then
		return
	end
	local tGemInfo = HoleProp.GemInfo
	local ForgeGemID = tGemInfo[self.m_CurGemPlace].nGemID
	
	local nGemID = CellInfo.nGoodID
	if not GameHelp:CheckCanUseLeechdom(nGemID) then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, string.format("等级不足，无法使用物品！", lAllowLevel))
		return
	end
	
	if ForgeGemID == nGemID then
		--IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, string.format("", lAllowLevel))
		return
	end

	GameHelp.PostServerRequest("RequestForgeGemInset("..CurEquipCell..","..tostringEx(self.m_CurGemPlace - 1)..","..nGemID..","..tostring(CellInfo.nGoodUID)..")")
end

-- 点击镶嵌钻石Cell
function ForgeSettingWidget:OnForgeGemClick(ForgeCell,on)
	if on then
		self.m_CurGemPlace = ForgeCell.m_index
	else
		return
	end
	self:Refresh()
end
--======================按钮回调函数====================


-- 显示可镶嵌宝石分类
function ForgeSettingWidget:ShowCanSetGemGrid(nGemType, nShow, tFitGemsList)
    if nil == nGemType then
        return
    end
    if nil == self.m_ListCanSetGemType[nGemType] and (nil == nShow or 1 ~= nShow) then
        return
    end
    local bIsExpandChild = (self.m_nDefExpCanSetGemType == nGemType)
    local objGemType = self.m_ListCanSetGemType[nGemType]
    if nil == objGemType then
        self.m_ListCanSetGemType[nGemType] = CanSetGemTypeItemClass:new()
        objGemType = self.m_ListCanSetGemType[nGemType]
    
        if nil == objGemType.transform then
            -- 没有则创建
            rkt.GResources.FetchGameObjectAsync( GuiAssetList.Forge.CanSetGemTypeItem,
            function ( path , obj , ud )
                
                obj.transform:SetParent(self.Controls.m_CanSetGemTypeGrid.transform, false)
                objGemType:Attach(obj)
                objGemType:UpdateGridInfo(nGemType, tFitGemsList, bIsExpandChild)
                objGemType:SetExpandBtnClickedCalBak( function(nGemType) self:OnCanSetGemType_ExpandBtnClicked(nGemType) end )
                objGemType:SetGemCellClickedCalBak( self.m_OnPackageGemClick )
                objGemType:SetGridHeightChangedCalBak( function() self:OnChildHeightChanged() end )
                
            end , nGemType, AssetLoadPriority.GuiNormal )
        end
    else
        if objGemType:isLoaded() then
            if nShow == 1 then
                objGemType:Show()
                objGemType:UpdateGridInfo(nGemType, tFitGemsList, bIsExpandChild)
            else
                objGemType:Hide()
            end
        end
    end
end

-- 子类拓展按钮被点击响应时间
function ForgeSettingWidget:OnCanSetGemType_ExpandBtnClicked( nGemType )
    if nil == nGemType or self.m_nExpandedCanSetGemType == nGemType  then
        return
    end
    if nil == self.m_nExpandedCanSetGemType then
        self.m_nExpandedCanSetGemType = nGemType
        return
    end
    
    local tmpGrid = self.m_ListCanSetGemType[self.m_nExpandedCanSetGemType]
    if tmpGrid and tmpGrid.transform then
        tmpGrid:OnExpandBtnClicked( true )
    end
    self.m_nExpandedCanSetGemType = nGemType
end

-- 子类高度发生变化
function ForgeSettingWidget:OnChildHeightChanged( )
    local ntmpHeight = 0
    local nCount = self.Controls.m_CanSetGemTypeGrid.transform.childCount
    for i=1,nCount do
		local childGrid = self.Controls.m_CanSetGemTypeGrid.transform:GetChild(i-1)
        if childGrid.gameObject.activeInHierarchy then
            ntmpHeight = ntmpHeight + childGrid.sizeDelta.y
        end
    end
    local tmpSD = self.Controls.m_CanSetGemScroll_Content.transform.sizeDelta
    tmpSD.y = ntmpHeight
    self.Controls.m_CanSetGemScroll_Content.transform.sizeDelta = tmpSD
end

-- 获取子Grid刷新状态
function ForgeSettingWidget:IsRefreshFinished()
    local bIsRefreshed = true
    for nKey, cItem in pairs(self.m_ListCanSetGemType) do
        bIsRefreshed = bIsRefreshed and cItem:IsRefreshFinished()
        if not bIsRefreshed then
            return bIsRefreshed
        end
    end
    return bIsRefreshed
end

--======================ForgeWidget必须实现的函数=======
-- 刷新子窗口
function ForgeSettingWidget:Refresh(GemPlace)
    if self:IsRefreshFinished() == false then
        DelayExecuteEx(100,function ()
			self:Refresh(GemPlace)
		end)
        return
    end
    
	if not self.transform then
		return
	end
	local nGemPlaceSet  = GemPlace or self.m_CurGemPlace or 1
    
    if not self.Controls["m_ForgeGemInfoCell"..nGemPlaceSet]:IsSelected() then
        self.Controls["m_ForgeGemInfoCell"..nGemPlaceSet]:SetSelect(true)
        return
    end
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	
	local CurEquipCell = UIManager.ForgeWindow:GetSelsctEquipPlace()
	--cLog("镶嵌 装备编号: "..CurEquipCell .. " -- 位置: " .. nGemPlaceSet,"green")
	local HoleProp = forgePart:GetHoleProp(CurEquipCell)
	if not HoleProp then
		return
	end
	local tGemInfo = HoleProp.GemInfo
    --cLog("normal check -| ForgeSettingWidget ---- tGemInfo="..tostringEx(tGemInfo), "green")

	local nHeroLV = pHero:GetNumProp(CREATURE_PROP_LEVEL)	-- 获取等级
	local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)	-- 获取职业
	-- 原料宝石属性
	local pConsumeGemPropScheme = forgePart.m_SettingCfgCenter:GetGemProp( tGemInfo[nGemPlaceSet].nGemID, nVocation) or {}
	if not pConsumeGemPropScheme then
		return
	end
    if pConsumeGemPropScheme.nGemType then
        self.m_nDefExpCanSetGemType = pConsumeGemPropScheme.nGemType
    else
        self.m_nDefExpCanSetGemType = DEF_EXP_CANSETGEMTYPE
    end
	--cLog("normal check -| ForgeSettingWidget ---- pConsumeGemPropScheme="..tostringEx(pConsumeGemPropScheme), "green")
	local CanUpGradeFlg,UpGrade = forgePart:GetSettingUpGradeFlg()
	--print("<color=green>镶嵌升级状态\n"..tostringEx(UpGrade).."</color>")
	
	local EquipUpGrade = {}
	for key,v in ipairs(UpGrade) do
		EquipUpGrade[key] = v.EquipCanSetFlg
	end
	
	--print("<color=green>镶嵌装备升级状态\n"..tostringEx(EquipUpGrade).."</color>")
	UIManager.ForgeWindow.ForgeEquipWidget:SetUpGradeState(EquipUpGrade)
	
	
	-- 开始刷新已装备宝石
	for i=Def_GemPlace_First, Def_GemPlace_Last do
		local GemPlaceScheme = IGame.rktScheme:GetSchemeInfo(EQUIPSETTING_CSV , nVocation, CurEquipCell, i-1)
								or IGame.rktScheme:GetSchemeInfo(EQUIPSETTING_CSV , 10000, CurEquipCell, i-1)
		if GemPlaceScheme then
			local nNeedHeroLv = GemPlaceScheme.nHeroLV
			if nHeroLV >= nNeedHeroLv then
				self.Controls["m_ForgeGemInfoCell"..i]:Show()
				self.Controls["m_ForgeGemInfoCell"..i]:SetGem(tGemInfo[i].nGemID)
				local UpGradeFlg = UpGrade[CurEquipCell+1].EquipHoleUpFlg[i] or 0
				self.Controls["m_ForgeGemInfoCell"..i]:SetUpGradeFlg(UpGradeFlg)
			else
				self.Controls["m_ForgeGemInfoCell"..i]:Hide()
			end
		end
	end
	
	local pGemPlaceScheme = IGame.rktScheme:GetSchemeInfo(EQUIPSETTING_CSV , nVocation, CurEquipCell, nGemPlaceSet - 1)
								or IGame.rktScheme:GetSchemeInfo(EQUIPSETTING_CSV , 10000, CurEquipCell, nGemPlaceSet - 1)
	if not pGemPlaceScheme then
		uerror("GemPlaceScheme nil"..nVocation)
		return
	end
	local CanSetGemTable = {}
	local CanSetGemType = {}
	for i=1, Def_GemPlace_SetGemType_Limit do
		if pGemPlaceScheme["nGemType"..i] ~= 0 then
			CanSetGemType[pGemPlaceScheme["nGemType"..i]] = 1
		end
	end
	
	local tGoodsUID = {} 
	local tFilterGoods = {}
	local curSize = 0
	local packetPart = pHero:GetEntityPart(ENTITYPART_PERSON_PACKET)
	if nHeroLV >= FORGE_SETTING_OPEN_LEVEL and packetPart and packetPart:IsLoad() then
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
						if pGemPropScheme and CanSetGemType[pGemPropScheme.nGemType] and CanSetGemType[pGemPropScheme.nGemType] == 1 and GameHelp:CheckCanUseLeechdom(nGoodIDTmp) then
							
							local tmpTable = {}
							tmpTable.nGoodID	= nGoodIDTmp
							tmpTable.nGemLv		= pGemPropScheme.nGemLv
                            tmpTable.nGemType   = pGemPropScheme.nGemType
							tmpTable.nGoodNum	= nGoodNumTmp
							tmpTable.nGoodUID	= uid
							tmpTable.TuiJian	= pGemPropScheme.nGemLv > (pConsumeGemPropScheme.nGemLv or 0)
							table.insert(tFilterGoods, tmpTable)
                            
						end
					end
				end
			end
		end
	end
	table.sort(tFilterGoods, 
		function(a, b)
            if a.nGemType ~= b.nGemType then
                return a.nGemType < b.nGemType
            elseif a.nGemLv ~= b.nGemLv then
				return a.nGemLv > b.nGemLv
			end
			return a.nGoodID > b.nGoodID
		end
    )
	--cLog("背包符合的宝石:\n"..tostringEx(tFilterGoods), "green")
	local CanSetCnt = table_count(tFilterGoods)
	local nMaxLv = 0
	if tFilterGoods[1] then
		nMaxLv = tFilterGoods[1].nGemLv
	end
    for nType = DefSetGemsTypeStart, DefSetGemsTypeEnd do
        if DEF_EXP_CANSETGEMTYPE == self.m_nDefExpCanSetGemType and CanSetGemType[nType] == 1 then
            if CanSetCnt == 0 then
                self.m_nDefExpCanSetGemType = nType
            else
                if tFilterGoods[1].nGemType == nType then
                    self.m_nDefExpCanSetGemType = nType
                end
            end
        end
        self:ShowCanSetGemGrid(nType, CanSetGemType[nType], tFilterGoods)
    end
    self.m_nExpandedCanSetGemType = self.m_nDefExpCanSetGemType
    --self.Controls.m_CanSetGemGrid.transform.localPosition = Vector3.New(0,0,0)
    
	local JinghuaNum = packetPart:GetGoodNum( BAOSHIJINGHUA_GOODSID )
	self.Controls.m_JingHuaNum.text = "拥有宝石精华"..JinghuaNum.."个"
end

function ForgeSettingWidget:IsCanUpGrade()
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	
	local CanUpGradeFlg,UpGrade = forgePart:GetSettingUpGradeFlg()
	--print("镶嵌升级状态"..tostringEx(CanUpGradeFlg))
	if CanUpGradeFlg then
		return true
	end
	return false
end

--======================ForgeWidget必须实现的函数=======

function ForgeSettingWidget:Setting_Success(EquipPlace,SetPlace,GemID)
	--print("<color=green>镶嵌成功 "..tostringEx(EquipPlace)..","..tostringEx(SetPlace)..","..tostringEx(GemID).."</color>")
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	forgePart:SetGemID(EquipPlace,SetPlace + 1,GemID)
	UIManager.ForgeWindow:Refresh()
end

function ForgeSettingWidget:Setting_OutSetGem_Success(EquipPlace,SetPlace)
	--print("<color=green>镶嵌卸下成功 "..tostringEx(EquipPlace)..","..tostringEx(SetPlace).."</color>")
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	forgePart:SetGemID(EquipPlace,SetPlace + 1,0)
	UIManager.ForgeWindow:Refresh()
end

function ForgeSettingWidget:Setting_UpGrade_Success(EquipPlace,SetPlace,GemID)
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	forgePart:SetGemID(EquipPlace,SetPlace + 1,GemID)
	UIManager.ForgeWindow:Refresh()
end

-- 清理数据
function ForgeSettingWidget:OnRecycle()
    self:CleanData()
    
    UIControl.OnRecycle(self)
end   

function ForgeSettingWidget:OnDestroy()
    self:CleanData()
    
    UIControl.OnDestroy(self)
end

function ForgeSettingWidget:CleanData()
    for ikey, cItem in pairs(self.m_ListCanSetGemType) do
        if cItem.transform then
            cItem:Destroy()
        end
    end
    self.m_ListCanSetGemType = {}
    
    self.m_nExpandedCanSetGemType = nil    
end


return this