------------------------------------------------------------
-- TooltisWindow 的子窗口,不要通过 UIManager 访问
------------------------------------------------------------

local BottomButtonType = {
	[1] = {1,{2,3,4,5,6}},		-- 包裹物品
	[2] = {1,6},			-- 包裹装备物品
	[3] = {7},			-- 放入仓库
	[4] = {8},			-- 取出仓库
}
local TipsBottomButtonsWidget = UIControl:new
{
    windowName = "TipsBottomButtonsWidget" ,
	m_nGoodID = nil,
	entity = nil,
	m_ButtonType = nil,
	m_ButtonInfo = {},
	m_LeftIndex = nil,
	m_BtnMoreShowFlg = false,
}

local this = TipsBottomButtonsWidget   -- 方便书写
local zero = int64.new("0")

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function TipsBottomButtonsWidget:Attach(obj)
	UIControl.Attach(self, obj)
	
	
	self.Controls.m_ButtonMore.onClick:AddListener(function() self:OnButtonMoreClick() end)
	
	for i=1,2 do
		self.Controls["BottomButton"..i].onClick:AddListener(function() self:OnBottomButtonClick(i) end)
	end	
	
	
	for i=1,5 do
		self.Controls["MoreButton"..i].onClick:AddListener(function() self:OnButtonClick(i) end)
	end
	
	return self
end

------------------------------------------------------------
function TipsBottomButtonsWidget:OnDestroy()
	UIControl.OnDestroy(self)
end
------------------------------------------------------------

-- 使用按钮
function TipsBottomButtonsWidget:OnButtonUseClick()
	local pGoodEntity	=	UIManager.GoodsTooltipsWindow:GetEntity()
	if not pGoodEntity then
		return
	end
	local nGoodID = pGoodEntity:GetNumProp(GOODS_PROP_GOODSID)
	
	local entityClass = pGoodEntity:GetEntityClass()
	if EntityClass:IsLeechdom(entityClass) then
		local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, nGoodID)
		if not schemeInfo then
			print("[GoodsTooltipsButtonWidget]找不到物品配置，物品ID=", nGoodID)
			return
		end
        
        -- 检查一下是否批量使用
        local goodNum = GameHelp:GetHeroPacketGoodsNum(nGoodID)
        if schemeInfo.bCanBatchUse and goodNum > 1 then
            UIManager.GoodsTooltipsWindow:Hide()
            UIManager.BatchUseItemWindow:Show(nGoodID, goodNum)
            return
        end
            
		local Result = IGame.SkepClient:RequestUseItem(pGoodEntity:GetUID())
		if Result == false then
			UIManager.PackWindow:ShowGoodLeftTime(nGoodID)
		end
		local nCloseTips = schemeInfo.nClosetips
		if nCloseTips == 1 then
			-- 直接关闭tips
			UIManager.GoodsTooltipsWindow:Hide() 
		else
			local totalNum = pGoodEntity:GetNumProp(GOODS_PROP_QTY)
			if totalNum <= 1 then 
				UIManager.GoodsTooltipsWindow:Hide()
			end 
		end		
	end
end

-- 回收按钮
function TipsBottomButtonsWidget:OnButtonRecycleClick()
	local pGoodEntity	=	UIManager.GoodsTooltipsWindow:GetEntity()
	if not pGoodEntity then
		return
	end
	local nGoodID = pGoodEntity:GetNumProp(GOODS_PROP_GOODSID)
	
	local data = {}
	data.content = string.format("物品一旦回收就不可找回，是否继续？")
	data.confirmCallBack = function ()
		local strfun     = "RequestGoodsRecycle("..tostring(pGoodEntity:GetUID())..")"
		GameHelp.PostServerRequest(strfun)
		UIManager.GoodsTooltipsWindow:Hide()
	end
	data.cancelCallBack = function ()
		UIManager.GoodsTooltipsWindow:Hide()
	end
	UIManager.ConfirmPopWindow:ShowDiglog(data)
end

-- 分解按钮
function TipsBottomButtonsWidget:OnButtonDecomposeClick()
    local goodsid = self.m_nGoodID
	UIManager.GoodsTooltipsWindow:Hide()
	UIManager.MaterialComposeWindow:Show(true)
    UIManager.MaterialComposeWindow:RefreshDataInfo(self.m_nGoodID,2)
end

-- 合成按钮
function TipsBottomButtonsWidget:OnButtonComposeClick()
    local goodsid = self.m_nGoodID
	UIManager.GoodsTooltipsWindow:Hide()
	UIManager.MaterialComposeWindow:Show(true)
    UIManager.MaterialComposeWindow:RefreshDataInfo(self.m_nGoodID,1)
end

-- 转换按钮
function TipsBottomButtonsWidget:OnButtonConvertClick()
    UIManager.GoodsTooltipsWindow:Hide()
	UIManager.GemConvertWindow:Show(true)
    UIManager.GemConvertWindow:SetShowGoodID(self.m_nGoodID)
end

-- 摆摊按钮
function TipsBottomButtonsWidget:OnButtonExchangeClick()
	local pGoodEntity	=	UIManager.GoodsTooltipsWindow:GetEntity()
	if not pGoodEntity then
		return
	end
	IGame.ExchangeClient:GoToSellCustomGoods(pGoodEntity:GetUID())
    UIManager.GoodsTooltipsWindow:Hide()
end

-- 放入仓库
function TipsBottomButtonsWidget:OnButtonPutInClick()
	local pGoodEntity	=	UIManager.GoodsTooltipsWindow:GetEntity()
	if not pGoodEntity then
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
	local uid = pGoodEntity:GetUID()
	IGame.SkepClient.RequestPacketToWare(uid)
	UIManager.GoodsTooltipsWindow:Hide()
end

-- 取出仓库
function TipsBottomButtonsWidget:OnButtonPutOutClick()
	local pGoodEntity	=	UIManager.GoodsTooltipsWindow:GetEntity()
	if not pGoodEntity then
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
	local uid = pGoodEntity:GetUID()
	IGame.SkepClient.RequestWareToPacket(uid)

	UIManager.GoodsTooltipsWindow:Hide()
end

function TipsBottomButtonsWidget:CheckButtonShow(schemeKeyText,num)
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, self.m_nGoodID)
	if not schemeInfo then
		return false
	end
	if schemeInfo[schemeKeyText] ~= num then
		return false
	end
	if schemeKeyText == "lCanSell" then
		local pGoodEntity	=	UIManager.GoodsTooltipsWindow:GetEntity()
		if not pGoodEntity then
			return false
		end
		local nNoBindNum = pGoodEntity:GetNumProp(GOODS_PROP_NO_BIND_QTY)
		if not nNoBindNum or nNoBindNum < 1 then
			return false
		end
	end
	return true
end

local BottomButtonFuncInfo = {
	[1] = {BtnName = "使用",BtnFunc = function() this:OnButtonUseClick() end		,},
	[2] = {BtnName = "回收",BtnFunc = function() this:OnButtonRecycleClick() end	,CheckFunc = function() return this:CheckButtonShow("lCanRecycle",1) end},
	[3] = {BtnName = "合成",BtnFunc = function() this:OnButtonComposeClick() end	,CheckFunc = function() return this:CheckButtonShow("lCanCompound",1) end},
	[4] = {BtnName = "分解",BtnFunc = function() this:OnButtonDecomposeClick() end	,CheckFunc = function() return this:CheckButtonShow("lCanCompound",2) end},
	[5] = {BtnName = "转换",BtnFunc = function() this:OnButtonConvertClick() end	,CheckFunc = function() return this:CheckButtonShow("nCanConvert",1) end},
	[6] = {BtnName = "摆摊",BtnFunc = function() this:OnButtonExchangeClick() end	,CheckFunc = function() return this:CheckButtonShow("lCanSell",1) end},
	[7] = {BtnName = "放入",BtnFunc = function() this:OnButtonPutInClick() end	,},
	[8] = {BtnName = "取出",BtnFunc = function() this:OnButtonPutOutClick() end	,},
}

function TipsBottomButtonsWidget:RedDot_Setting(EquipPlace)
	local forgePart = GetHero():GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	local CanUpGradeFlg,UpGrade = forgePart:GetSettingUpGradeFlg()
	return UpGrade[EquipPlace + 1].EquipCanSetFlg
end

function TipsBottomButtonsWidget:RedDot_Smelt(EquipPlace)
	local forgePart = GetHero():GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	local CanUpGradeFlg,UpGrade1 = forgePart:GetNormalUpGradeFlg()
	local CanUpGradeFlg,UpGrade2 = forgePart:GetPCTUpGradeFlg()
	return UpGrade1[EquipPlace + 1] or UpGrade2[EquipPlace + 1]
end

function TipsBottomButtonsWidget:Refresh(nGoodID,ButtonType)
	if not nGoodID or not ButtonType or not BottomButtonType[ButtonType] then
		return
	end
	self.m_nGoodID = nGoodID
	
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, nGoodID)
	if not schemeInfo then
		return
	end
	
	self.m_ButtonType = ButtonType
	local ButtonInfo = BottomButtonType[ButtonType] or {}
	local schemeKeyText = {}
	local ShowButtonFlg = {}
	local nIndexTmp = 0
	if ButtonInfo[2] then
		for key,v in ipairs(ButtonInfo[2]) do
			local BottomButtonFuncInfo = BottomButtonFuncInfo[v]
			if BottomButtonFuncInfo and BottomButtonFuncInfo.CheckFunc then
				local ShowFlg = BottomButtonFuncInfo.CheckFunc()
				if ShowFlg then
					ShowButtonFlg[v] = 1
					nIndexTmp = v
				end
			end
		end
	end
	local nMoreButtonCnt = table_count(ShowButtonFlg)
	
	local ButtonTmp = {ButtonInfo[1], nIndexTmp}
	for i=1,2 do
		local MoreButtonFuncIndex = ButtonTmp[i]
		if MoreButtonFuncIndex then
			local BottomButtonFuncInfo = BottomButtonFuncInfo[MoreButtonFuncIndex]
			if BottomButtonFuncInfo then
				self.Controls["BottomButton"..i].gameObject:SetActive(true)
				self.Controls["BottomButtonName"..i].text = BottomButtonFuncInfo.BtnName
			else
				self.Controls["BottomButton"..i].gameObject:SetActive(false)
			end
		else
			self.Controls["BottomButton"..i].gameObject:SetActive(false)
		end
	end
	
	if nMoreButtonCnt <=0 then
		self.Controls["BottomButton2"].gameObject:SetActive(false)
		self.Controls.m_ButtonMore.gameObject:SetActive(false)
		return
	elseif nMoreButtonCnt == 1 then
		self.m_LeftIndex = nIndexTmp
		self.Controls["BottomButton2"].gameObject:SetActive(true)
		self.Controls.m_ButtonMore.gameObject:SetActive(false)
		
	else
		self.Controls["BottomButton2"].gameObject:SetActive(false)
		self.Controls.m_ButtonMore.gameObject:SetActive(true)
		for i=1,5 do
			local MoreButtonFuncIndex = ButtonInfo[2][i]
			if MoreButtonFuncIndex and ShowButtonFlg[MoreButtonFuncIndex] then
				local BottomButtonFuncInfo = BottomButtonFuncInfo[MoreButtonFuncIndex]
				if BottomButtonFuncInfo then
					self.Controls["MoreButton"..i].gameObject:SetActive(true)
					self.Controls["MoreButtonName"..i].text = BottomButtonFuncInfo.BtnName
				else
					self.Controls["MoreButton"..i].gameObject:SetActive(false)
				end
			else
				self.Controls["MoreButton"..i].gameObject:SetActive(false)
			end
		end
		self.m_BtnMoreShowFlg = false
		self.Controls.m_ShowMoreBG.gameObject:SetActive(false)
	end
end

-- 点击回调
function TipsBottomButtonsWidget:OnButtonClick(i)
	local RightButtonFuncIndex = BottomButtonType[self.m_ButtonType][2][i]
	local FuncInfo = BottomButtonFuncInfo[RightButtonFuncIndex]
	if not FuncInfo then
		return
	end
	FuncInfo.BtnFunc()
end

-- 点击回调
function TipsBottomButtonsWidget:OnBottomButtonClick(i)
	if not self.m_ButtonType or not BottomButtonType[self.m_ButtonType] then
		return
	end
	local RightButtonFuncIndex = 0
	if i == 1 then
		RightButtonFuncIndex = BottomButtonType[self.m_ButtonType][1]
	else
		RightButtonFuncIndex = self.m_LeftIndex
	end
	local FuncInfo = BottomButtonFuncInfo[RightButtonFuncIndex]
	if not FuncInfo then
		return
	end
	FuncInfo.BtnFunc()
end
function TipsBottomButtonsWidget:OnButtonMoreClick()
	self.m_BtnMoreShowFlg = not self.m_BtnMoreShowFlg
	self.Controls.m_ShowMoreBG.gameObject:SetActive(self.m_BtnMoreShowFlg)
end

return this