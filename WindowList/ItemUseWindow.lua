

-- 物品快捷使用窗口

------------------------------------------------------------
local ItemUseWindow = UIWindow:new
{
	windowName = "ItemUseWindow" ,
}

function ItemUseWindow:Init()

end

function ItemUseWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	self:AddListener(self.Controls.UseBtn, "onClick", self.OnUseBtnClick, self)
	self:AddListener(self.Controls.CloseBtn, "onClick", self.OnCloseBtnClick, self)
	self:AddListener(self.Controls.PutBtn, "onClick", self.OnPutBtnClick, self)
	self:AddListener(self.Controls.ClickIcon, "onClick", self.OnClickIcon, self)
	
    if nil ~= self.m_cacheRefreshInfo then
        local info = self.m_cacheRefreshInfo
        self.m_cacheRefreshInfo = nil
        self:RefreshWindow(info.flush)
    end
end

function ItemUseWindow:RefreshWindow(flush)
    if not self:isLoaded() then
        self.m_cacheRefreshInfo = { flush = flush }
        return
    end

	local flag, showItem, entity =  IGame.ItemUseController:GetCurShowItem()
	if not flag then
		self:OnClose()
		return 
	end
	
	local imagePath
	local imageBgPath
	local pSchemeInfo
	
	if showItem.item_type == 0 then
		pSchemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, 
				entity:GetNumProp(GOODS_PROP_GOODSID)) 
		imagePath = AssetPath.TextureGUIPath..pSchemeInfo.lIconID1
		imageBgPath = AssetPath.TextureGUIPath..pSchemeInfo.lIconID2
		self.Controls.PutBtn.gameObject:SetActive(false)
		self.Controls.UseBtn.gameObject:SetActive(true)
		-- 物品名称
        local color = DColorDef.getNameColor(0, pSchemeInfo.lBaseLevel)
		self.Controls.itemName.text = "<color=#".. color .. ">" .. pSchemeInfo.szName .. "</color>" or ""
	else
		pSchemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, 
				entity:GetNumProp(GOODS_PROP_GOODSID))
		imagePath = AssetPath.TextureGUIPath..pSchemeInfo.IconIDNormal
		local nQuality = entity:GetNumProp(EQUIP_PROP_QUALITY)
		local nAdditionalPropNum = entity:GetAdditionalPropNum()	
		imageBgPath = GetEquipBgPath(nQuality, nAdditionalPropNum)
		self.Controls.PutBtn.gameObject:SetActive(true)
		self.Controls.UseBtn.gameObject:SetActive(false)
		self.Controls.itemName.text = "战斗力:+"..self:GetFighting(entity)
	end
	
	UIFunction.SetImageSprite( self.Controls.itemIcon , imagePath)
	UIFunction.SetImageSprite( self.Controls.itemBg , imageBgPath)
	
	if entity:GetNumProp(GOODS_PROP_QTY) == 1 then
		self.Controls.itemNum.gameObject:SetActive(false)
	else
		self.Controls.itemNum.gameObject:SetActive(true)
		self.Controls.itemNum.text = tostringEx(entity:GetNumProp(GOODS_PROP_QTY))
	end
end

--玩家身上装备判定
function ItemUseWindow:GetFighting(entity)
	local pHero = GetHero()
	local pSchemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, 
		entity:GetNumProp(GOODS_PROP_GOODSID))
	local place = pSchemeInfo.GoodsSubClass
	local equipPart = pHero:GetEntityPart(ENTITYPART_PERSON_EQUIP)
	local pEquipEntity = IGame.EntityClient:Get(equipPart:GetGoodsUIDByPos(place))

	if pEquipEntity then
		local dropEquipScore = entity:ComputeEquipScore()
		local bodyEquipScore = pEquipEntity:ComputeEquipScore()
		return math.floor(dropEquipScore/10) - math.floor(bodyEquipScore/10)
	else
		return math.floor(entity:ComputeEquipScore()/10)
	end
end

-- 使用物品按钮
function ItemUseWindow:OnUseBtnClick()
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	
	--[[if packetPart:CountEmptyPlace(false) <= 0 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你的包裹空位不足，无法使用物品")
		return
	end--]]
    -- 当前物品不在包裹中
    if not IGame.ItemUseController:IsCurEntityInPacket() then
        IGame.ItemUseController:RemoveQueueEntity()
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "物品不在包裹栏中，使用失败。")
        return
    end
	
	-- 调用使用物品接口
	IGame.SkepClient:RequestUseItem(IGame.ItemUseController:QueueHead().id)
end

--穿上装备按钮
function ItemUseWindow:OnPutBtnClick()
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	
    -- 当前物品不在包裹中
    if not IGame.ItemUseController:IsCurEntityInPacket() then
        IGame.ItemUseController:RemoveQueueEntity()
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "该装备不在包裹栏中，使用失败。")
        return
    end
	if packetPart:CountEmptyPlace(false) <= 0 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你的包裹空位不足，无法穿上装备")
		return
	end
	
	--调用穿装备接口
	local entity = IGame.EntityClient:Get(IGame.ItemUseController:QueueHead().id)
	IGame.SkepClient.RequestOnEquip(entity:GetUID(), -1)
end

--点击icon显示tips
function ItemUseWindow:OnClickIcon()
	local showItem = IGame.ItemUseController:QueueHead()
	local entity = IGame.EntityClient:Get(showItem.id)
	local entityClass = entity:GetEntityClass()
	
	if EntityClass:IsEquipment(entityClass) then
		local cfgId = entity:GetNumProp(GOODS_PROP_GOODSID)
		local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, cfgId)
		if not schemeInfo then
			return
		end
		
		-- 武学
		if schemeInfo.GoodsSubClass == EQUIPMENT_SUBCLASS_BATTLEBOOK then
			UIManager.WuXueDetailWindow:ShowForPacket(showItem.id)
		else 
			local subInfo = {
				bShowBtn = 1,
				bShowCompare = true,
				bRightBtnType = 2,
			}
			
			UIManager.EquipTooltipsWindow:Show(true)
			UIManager.EquipTooltipsWindow:SetEntity(entity, subInfo)
		end
	else
		local subInfo = {
			bShowBtnType	= 1, 	--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
			bBottomBtnType	= 1,
		}
		
		UIManager.GoodsTooltipsWindow:Show(true)
        UIManager.GoodsTooltipsWindow:SetGoodsEntity(entity, subInfo)
	end
end

function ItemUseWindow:ShowPanel()
	UIManager.ItemUseWindow:Show(true)
	UIManager.ItemUseWindow:RefreshWindow(false)
end

-- 响应关闭按钮
function ItemUseWindow:OnCloseBtnClick()
	IGame.ItemUseController:RemoveQueue()
	
	if IGame.ItemUseController:ShowCondition() then
		self:ShowPanel()
	else
		self:OnClose()
	end
end

-- 响应关闭
function ItemUseWindow:OnClose()
	IGame.ItemUseController:RemoveQueue()
	self:Hide()
end

return ItemUseWindow
