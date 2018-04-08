-- 提示窗口
------------------------------------------------------------
local HeadTitleWindow = UIWindow:new
{
	windowName = "HeadTitleWindow",
    m_curHeadTitleID =0,
	unlockSkepID = 0,
	m_nGoodsID = 0,
	m_UidTable = {},
	bSubExecute = false,
}

local TextColor =
{	
	"567a96",
	"5aad41",
	"337942",
	"c736c9",
	"dfb801"
	
}


------------------------------------------------------------
function HeadTitleWindow:Init()

end
------------------------------------------------------------
function HeadTitleWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.Controls.m_Close.onClick:AddListener(function() self:OnBtnCloseClick() end)
	self.Controls.m_BgCloseBtn.onClick:AddListener(function() self:OnBtnCloseClick() end)
	self.Controls.m_TipBtn.onClick:AddListener(function() self:ShowTipsInfo() end)
	self.Controls.m_PromotionBtn.onClick:AddListener(function() self:OnPromotionClick() end)
	self.Controls.m_GoodsBtn.onClick:AddListener(function() self:OnGoodsBtnClick() end)
	self.Controls.m_TishengBtn.onClick:AddListener(function() self:OnTishengBtnClick() end)
	-- UIFunction.AddEventTriggerListener( self.Controls.m_CloseButton , EventTriggerType.PointerClick , function( eventData ) self:OnCloseButtonClick(eventData) end )

	-- 属性更新事件
	self.callback_OnUpdateProp = function(event, srctype, srcid, msg) self:OnUpdateProp(msg) end
	
    self:refreshWindow()
end

------------------------------------------------------------
-- 注册控件事件
function HeadTitleWindow:SubscribeWinExecute()
	if self.bSubExecute then
		return
	end
	rktEventEngine.SubscribeExecute( EVENT_ENTITY_UPDATEPROP , SOURCE_TYPE_PERSON , tEntity_Class_Person , self.callback_OnUpdateProp)
	self.bSubExecute = true
end
------------------------------------------------------------
-- 注销控件事件
function HeadTitleWindow:UnSubscribeWinExecute()
	-- 属性更新事件
	rktEventEngine.UnSubscribeExecute( EVENT_ENTITY_UPDATEPROP , SOURCE_TYPE_PERSON , tEntity_Class_Person , self.callback_OnUpdateProp)
	self.bSubExecute = false
end

------------------------------------------------------------
function HeadTitleWindow:OnDestroy()
	self.Currenthead = nil
	self.Nexthead = nil
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------
function HeadTitleWindow:UpdateHeadTitleInfo()
	if not self:isLoaded() then
        return
    end
    self:refreshWindow()
end

function HeadTitleWindow:refreshWindow()
    local pHero = GetHero()
    if nil == pHero then
        self:Hide()
        return
    end
	local pTitlePart = GetHeroEntityPart(ENTITYPART_PERSON_TITLE)
	if not pTitlePart then
		return
	end
	local curHeadTitleID = pTitlePart:GetHeadTitleID()
	
	-- 当前头衔称号的信息
	self:UpdateCurHeadTitlePropInfo(curHeadTitleID)
	-- 下一级头衔称号的信息
	self:UpdateNextHeadTitlePropInfo(curHeadTitleID+1)
	-- 升级条件信息
	self:UpdateUpgradeConditionInfo(curHeadTitleID+1)
end

-- 更新头衔称号升级条件信息
function HeadTitleWindow:UpdateUpgradeConditionInfo(nNextHeadTitleID)
	
	local pHero = GetHero()
    if nil == pHero then
        return
    end
	local pNextHeadTitleInfo = IGame.rktScheme:GetSchemeInfo(HEADTITLE_CSV,nNextHeadTitleID)
	-- 已经是最大等级，获取下一等级信息无
	if not pNextHeadTitleInfo then
		-- 最高等级不需要显示升级条件信息
		self.Controls.m_BattleValue.text = ""
		self.Controls.m_GoodsName.text = ""
		self.Controls.m_GoodsNum.text  = ""
		self.Controls.m_GetText.text = "所需道具：无"
		self.Controls.m_GoodsBtn.gameObject:SetActive(false)
		self.Controls.m_BattlePower.text = "所需战力：-/-"
		self.Controls.m_Condition.text = "晋升条件"
		self.m_nGoodsID = 0
		self.Controls.m_RedDot.gameObject:SetActive(false)
	else
		
		local nCurattle = pHero:GetNumProp(CREATURE_PROP_POWER)
		self.Controls.m_GoodsName.text = pNextHeadTitleInfo.szGoodsName or ""
		local bRedDotActive = true
        local szCurattle = nCurattle
		if nCurattle < pNextHeadTitleInfo.nNeedBattle then
			bRedDotActive  = false
            szCurattle = "<color=red>" ..nCurattle .."</color>" 
		end
        self.Controls.m_BattleValue.text = szCurattle.."/"..pNextHeadTitleInfo.nNeedBattle
		-- 不需要消耗物品
		if not pNextHeadTitleInfo.nNeedGoodsID or pNextHeadTitleInfo.nNeedGoodsID <= 0 
			or not pNextHeadTitleInfo.nNeedGoodsNum or pNextHeadTitleInfo.nNeedGoodsNum <= 0 then
			
			self.Controls.m_GoodsBtn.gameObject:SetActive(false)
			self.Controls.m_GoodsName.text = ""
			self.Controls.m_GoodsNum.text  = ""
			self.Controls.m_GetText.text = "所需道具：无"
			self.m_nGoodsID = 0
			self.Controls.m_RedDot.gameObject:SetActive(bRedDotActive)
			return
		end
		
		-- 需要道具ID
		local nGoodsID    = pNextHeadTitleInfo.nNeedGoodsID
		-- 道具数量
		local nGoodsNum   = pNextHeadTitleInfo.nNeedGoodsNum
		-- 拥有GoodsNum
		local ownGoodsNum = GameHelp:GetHeroPacketGoodsNum(nGoodsID)
		
		local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, nGoodsID)
		if not schemeInfo then
			print("【HeadTitleWindow】找不到物品配置，物品ID=", nGoodsID)
			return
		end
		self.m_nGoodsID = nGoodsID
		if ownGoodsNum < nGoodsNum then
			self.Controls.m_GoodsBtn.gameObject:SetActive(true)
			self.Controls.m_GetText.text = "所需道具："
			self.Controls.m_GoodsNum.text  = "<color=red>("..ownGoodsNum.."/"..nGoodsNum..")</color>"
			bRedDotActive  = false
		else 
			self.Controls.m_GoodsBtn.gameObject:SetActive(false)
			self.Controls.m_GetText.text = "所需道具："
			self.Controls.m_GoodsNum.text  = "("..ownGoodsNum.."/"..nGoodsNum..")"
		end 
		self.Controls.m_RedDot.gameObject:SetActive(bRedDotActive)
	end
end

-- 设置当前属性信息
function HeadTitleWindow:UpdateCurHeadTitlePropInfo(curHeadTitleID)
	
	if not curHeadTitleID then
		return
	end
	
	-- 当前头衔称号初始值为0时
	if curHeadTitleID == 0 then
		-- 等级为0时不显示
		self.Controls.m_CurBattlePower.text = ""
		for i = 1, 6 do
			self.Controls["m_CurProp"..i].text = "" 
			local ImageObj = self.Controls["m_CurProp"..i].transform:Find("Star")
			ImageObj.gameObject:SetActive(false)
		
		end
		local ImageObj = self.Controls.m_CurBattlePower.transform:Find("Star")
		ImageObj.gameObject:SetActive(false)
		self.Controls.m_CurNoneName.gameObject:SetActive(true)
		
	-- 当前头程称号id为正常值时
	else 
		local pCurHeadTitleInfo = IGame.rktScheme:GetSchemeInfo(HEADTITLE_CSV,curHeadTitleID)
		if not pCurHeadTitleInfo then
			uerror("【HeadTitleWindow】当前头衔称号信息获取事变，头衔称号id:"..curHeadTitleID)
			return
		end
		self.Controls.m_CurNoneName.gameObject:SetActive(false)
		local info =
		{
			Path= pCurHeadTitleInfo.szIconPath,
			color = pCurHeadTitleInfo.szColor,
			alphaVal = pCurHeadTitleInfo.nLight
		}
		if self.Currenthead == nil then 
			self.Currenthead = UIFunction.SetHeadTitle(self.Controls.m_CurHeadTitleName,info)
		else
			self.Currenthead:RefreshHead(info)
		end
		local color =Color.New(0,0,0,0)
		color:FromHexadecimal( pCurHeadTitleInfo.WordColor , 'A' )
		color = Color.New(color.r,color.g,color.b,1)
		self.Controls.m_CurBattlePower.color = color
        --策划wxh说就战斗力的显示是相对于上一级加的战斗力。特意让我改
        local lastCureBattle =0
        local lastCureBattleInfo = IGame.rktScheme:GetSchemeInfo(HEADTITLE_CSV,curHeadTitleID-1)
        if lastCureBattleInfo ~= nil then 
            lastCureBattle = lastCureBattleInfo.nAddBattle
		end
		self.Controls.m_CurBattlePower.text = "战力 +"..pCurHeadTitleInfo.nAddBattle-lastCureBattle
		local ImageObj = self.Controls.m_CurBattlePower.transform:Find("Star")
		if ImageObj ~=nil then 
			ImageObj.gameObject:SetActive(true)
			local image = ImageObj:GetComponent(typeof(Image))
		
			UIFunction.SetImageSprite(image,GuiAssetList.GuiRootTexturePath.."Title/"..pCurHeadTitleInfo.WordIcon)
			
		end

		
		local propDesc = IGame.rktScheme:GetSchemeTable(EQUIPATTACHPROPDESC_CSV)
		if not propDesc then
			uerror("[HeadTitleWindow] 显示当前头衔称号时，读取EQUIPATTACHPROPDESC_CSV失败！")
			return
		end
		for i = 1, 6 do
			local AddProp = pCurHeadTitleInfo["AddProp"..i] 
			local ImageObj = self.Controls["m_CurProp"..i].transform:Find("Star")
			if table_count(AddProp) > 0 then 
				local nPropID = AddProp[1] 
				local nValue = AddProp[2]
				self.Controls["m_CurProp"..i].gameObject:SetActive(true)
				ImageObj.gameObject:SetActive(true)
				local color =Color.New(0,0,0,1)
				color:FromHexadecimal( pCurHeadTitleInfo.WordColor , 'As' )
	
				color = Color.New(color.r,color.g,color.b,1)
				
				self.Controls["m_CurProp"..i].color = color
				
				if ImageObj ~=nil then 
					local image = ImageObj:GetComponent(typeof(Image))
					UIFunction.SetImageSprite(image,GuiAssetList.GuiRootTexturePath.."Title/"..pCurHeadTitleInfo.WordIcon)
				end
				if propDesc[tostring(nPropID)] ~= nil then 
					local strDesc = propDesc[tostring(nPropID)].strDesc
					if AddProp[3] == 1 then 
						self.Controls["m_CurProp"..i].text = strDesc.." +"..nValue.."%"
					else 
						self.Controls["m_CurProp"..i].text = strDesc.." +"..nValue
					end
				end
			else 
				self.Controls["m_CurProp"..i].gameObject:SetActive(false)
				ImageObj.gameObject:SetActive(false)
				self.Controls["m_CurProp"..i].text = ""
			end
		end 
	end
 
end

-- 设置下一个属性信息
function HeadTitleWindow:UpdateNextHeadTitlePropInfo(nextHeadTitleID)
	
	if not nextHeadTitleID and nextHeadTitleID <= 0 then
		uerror("【HeadTitleWindow】下一头衔称号id 为nil or 0")
		return
	end
	-- 当前称号
	local pNextHeadTitleInfo = IGame.rktScheme:GetSchemeInfo(HEADTITLE_CSV,nextHeadTitleID)
	if not pNextHeadTitleInfo then
		-- 最高等级时不显示
		self.Controls.m_NextBattlePower.text = ""

		self.Controls.m_NextHeadTitleName.gameObject:SetActive(false)
		for i = 1, 6 do
			self.Controls["m_NextProp"..i].text = ""
			local ImageObj = self.Controls["m_NextProp"..i].transform:Find("Star")
			ImageObj.gameObject:SetActive(false)
		end
		local ImageObj = self.Controls.m_NextBattlePower.transform:Find("Star")
		ImageObj.gameObject:SetActive(false)
		self.Controls.m_MaxLevel.gameObject:SetActive(true)
		self.Controls.m_NextNoneName.gameObject:SetActive(true)
	else 
		self.Controls.m_MaxLevel.gameObject:SetActive(false)
		self.Controls.m_NextNoneName.gameObject:SetActive(false)
		local info =
		{
			Path= pNextHeadTitleInfo.szIconPath,
			color = pNextHeadTitleInfo.szColor,
			alphaVal = pNextHeadTitleInfo.nLight
		}
		if self.Nexthead == nil then 
			self.Nexthead = UIFunction.SetHeadTitle(self.Controls.m_NextHeadTitleName,info)
		else
			self.Nexthead:RefreshHead(info)
		end
		
		local color =Color.New(0,0,0,0)
		color:FromHexadecimal( pNextHeadTitleInfo.WordColor , 'A' )
		color = Color.New(color.r,color.g,color.b,1)
		self.Controls.m_NextBattlePower.color = color
	    local lastCureBattle =0
        local lastCureBattleInfo = IGame.rktScheme:GetSchemeInfo(HEADTITLE_CSV,nextHeadTitleID-1)
        if lastCureBattleInfo ~= nil then 
            lastCureBattle = lastCureBattleInfo.nAddBattle
		end
	       --策划wxh说就战斗力的显示是相对于上一级加的战斗力。特意让我改
		self.Controls.m_NextBattlePower.text = "战力 +"..pNextHeadTitleInfo.nAddBattle-lastCureBattle
		local ImageObj = self.Controls.m_NextBattlePower.transform:Find("Star")
			ImageObj.gameObject:SetActive(true)
			if ImageObj ~=nil then 
				local image = ImageObj:GetComponent(typeof(Image))
				
				UIFunction.SetImageSprite(image,GuiAssetList.GuiRootTexturePath.."Title/"..pNextHeadTitleInfo.WordIcon)
				
			end
		local propDesc = IGame.rktScheme:GetSchemeTable(EQUIPATTACHPROPDESC_CSV)
		if not propDesc then
			uerror("[HeadTitleWindow] 读取EQUIPATTACHPROPDESC_CSV失败")
			return
		end
		
		for i = 1, 6 do
			local AddProp = pNextHeadTitleInfo["AddProp"..i] 
			local ImageObj = self.Controls["m_NextProp"..i].transform:Find("Star")
			if table_count(AddProp) > 0 then 
				self.Controls["m_NextProp"..i].gameObject:SetActive(true)
				ImageObj.gameObject:SetActive(true)
				local nPropID = AddProp[1] 
				local nValue = AddProp[2]
				local color =Color.New(0,0,0,0)
				color:FromHexadecimal( pNextHeadTitleInfo.WordColor , 'A' )
				color = Color.New(color.r,color.g,color.b,1)
				self.Controls["m_NextProp"..i].color = color
				local ImageObj = self.Controls["m_NextProp"..i].transform:Find("Star")
				if ImageObj ~=nil then 
					local image = ImageObj:GetComponent(typeof(Image))
					
					UIFunction.SetImageSprite(image,GuiAssetList.GuiRootTexturePath.."Title/"..pNextHeadTitleInfo.WordIcon)
					
				end
				if propDesc[tostring(nPropID)] ~= nil then 
					local strDesc = propDesc[tostring(nPropID)].strDesc
					if AddProp[3] == 1 then 
						self.Controls["m_NextProp"..i].text = strDesc.." +"..nValue.."%"
					else 
						self.Controls["m_NextProp"..i].text = strDesc.." +"..nValue
					end
				end
			else 
				self.Controls["m_NextProp"..i].gameObject:SetActive(false)
				ImageObj.gameObject:SetActive(false)
				self.Controls["m_NextProp"..i].text = ""
			end
		end 
	end
end


function HeadTitleWindow:OnPromotionClick()
	
	--增加判断，是否满足要求
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end
	local packetPart = pHero:GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	local pTitlePart = pHero:GetEntityPart(ENTITYPART_PERSON_TITLE)
	if not pTitlePart then
		return
	end
	
	local nCurHeadTitleID = pTitlePart:GetHeadTitleID()
	local pCurHeadTitleInfo = IGame.rktScheme:GetSchemeInfo(HEADTITLE_CSV, nCurHeadTitleID)
	local pNextHeadTitleInfo = IGame.rktScheme:GetSchemeInfo(HEADTITLE_CSV, nCurHeadTitleID +1)
	
	-- 判断是否达到最大等级
	if nCurHeadTitleID > 0 then
		if not pCurHeadTitleInfo then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你当前头衔配置有问题")
			return
		end
		if not pNextHeadTitleInfo then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你的头衔已达到最大等级")
			return
		end
	end
	if not pNextHeadTitleInfo then
		uerror("下一头衔配置获取失败!")
		return
	end

	local nPower = pHero:GetNumProp(CREATURE_PROP_POWER)
	if pNextHeadTitleInfo.nNeedBattle and nPower < pNextHeadTitleInfo.nNeedBattle then 
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "战力不足，无法晋升")
		return
	end
 
	-- 拥有GoodsNum
	if pNextHeadTitleInfo.nNeedGoodsID > 0 and pNextHeadTitleInfo.nNeedGoodsNum > 0 then
		local ownGoodsNum = packetPart:GetGoodNum(pNextHeadTitleInfo.nNeedGoodsID)
		if ownGoodsNum < pNextHeadTitleInfo.nNeedGoodsNum then 
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "所需道具不足，无法晋升")
			return
		end 
	end
	
	GameHelp.PostServerRequest("RequestUpgradeHeadTitle()")
end

function HeadTitleWindow:OnGoodsBtnClick()
	if self.m_nGoodsID ~= 0 then
		local subInfo = {
			bShowBtnType	= 2, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
		}
		UIManager.GoodsTooltipsWindow:SetGoodsInfo(self.m_nGoodsID, subInfo )
	end
end

function HeadTitleWindow:OnTishengBtnClick()
	IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "正在开发中..")
end

-- 关闭按钮
function HeadTitleWindow:OnBtnCloseClick()
	UIManager.HeadTitleWindow:Hide()
end

function HeadTitleWindow:ShowTipsInfo()
	UIManager.CommonGuideWindow:ShowWindow(21) -- 头衔规则说明
end

function HeadTitleWindow:OnCloseButtonClick(eventData)
	
end

-- 战斗力更新，界面刷新
function HeadTitleWindow:OnUpdateProp(msg)
	if not self:isLoaded() then
		return
	end
	if not msg or type(msg) ~= "table" or not msg.nPropCount or msg.nPropCount == 0  then
		return
	end
	for i = 1, msg.nPropCount do
		if msg.propData[i].nPropID == CREATURE_PROP_POWER then
			self:refreshWindow()
		end
	end
end

return HeadTitleWindow