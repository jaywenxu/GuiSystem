-- 提示窗口
------------------------------------------------------------
local BattleTitleWindow = UIWindow:new
{
	windowName = "BattleTitleWindow",
	unlockSkepID = 0,
	m_UidTable = {}
}
------------------------------------------------------------
function BattleTitleWindow:Init()

end
------------------------------------------------------------
function BattleTitleWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.Controls.m_Close.onClick:AddListener(function() self:OnBtnCloseClick() end)
	self.Controls.m_TipBtn.onClick:AddListener(function() self:ShowTipsInfo() end)
	
	 UIFunction.AddEventTriggerListener( self.Controls.m_CloseButton , EventTriggerType.PointerClick , function( eventData ) self:OnCloseButtonClick(eventData) end )
    return self
end
------------------------------------------------------------
function BattleTitleWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------
function BattleTitleWindow:SetConfigInfo()
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local packetPart = pHero:GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	
	local curBattleTitleID = 1
	local curBattleTitleInfo = IGame.BattleTitleClient:GetInfoByBattletTitleID(curBattleTitleID)
	local nNextBattleTitleID = curBattleTitleInfo.nNextBattleTitleID
	local pNextBattleTitleInfo = IGame.BattleTitleClient:GetInfoByBattletTitleID(nNextBattleTitleID)
	
	-- 需要战斗力
	local nNeedBattle = pNextBattleTitleInfo.nNeedBattle
	-- 拥有战斗力
	local ownBattle   = pHero:GetNumProp(CREATURE_PROP_POWER)
	-- 需要道具ID
	local nGoodsID    = pNextBattleTitleInfo.nNeedGoodsID
	-- 道具数量
	local nGoodsNum   = pNextBattleTitleInfo.nNeedGoodsNum
	-- 拥有GoodsNum
	local ownGoodsNum = packetPart:GetGoodNum(nGoodsID)
	
	-- 道具名字
	local GoodsName   = pNextBattleTitleInfo.szGoodsName
    
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, nGoodsID)
	if not schemeInfo then
		print(mName.."找不到物品配置，物品ID=", nGoodsID)
		return
	end
	
	-- 物品图标
	local imagePath = AssetPath.TextureGUIPath..schemeInfo.lIconID1
	UIFunction.SetImageSprite( self.Controls.m_GoodsIcon , imagePath )
	-- 物品边框
	local imageBgPath = AssetPath.TextureGUIPath..schemeInfo.lIconID2
	UIFunction.SetImageSprite( self.Controls.m_GoodsBorderIcon , imageBgPath )
	
	self.Controls.m_BattleValue.text = ownBattle.."/"..nNeedBattle
	self.Controls.m_GoodsName.text = GoodsName
	self.Controls.m_GoodsNum.text  = ownGoodsNum.."/"..nGoodsNum
	
	self:SetCurBattleTitleInfo(curBattleTitleInfo)
	self:SetNextBattleTitleInfo(pNextBattleTitleInfo)

end

-- 设置当前属性信息
function BattleTitleWindow:SetCurBattleTitleInfo(pCurBattleTitleInfo)
	-- 战斗力属性
	local nAddBattle = pCurBattleTitleInfo.nAddBattle
	local curTitleName = pCurBattleTitleInfo.szName
	self.Controls.m_CurTitleName.text = curTitleName
	self.Controls.m_CurBattlePower.text = "战力 +"..nAddBattle
    local propDesc = IGame.rktScheme:GetSchemeTable(EQUIPATTACHPROPDESC_CSV)
	if not propDesc then
		uerror("[BattleTitleWindow] 读取EQUIPATTACHPROPDESC_CSV失败")
		return
	end
	
	for i = 1, 6 do
		local AddProp = pCurBattleTitleInfo["AddProp"..i] 
		if table_count(AddProp) > 0 then 
			local nPropID = AddProp[1] 
			local nValue = AddProp[2]

			if propDesc[tostring(nPropID)] ~= nil then 
				local strDesc = propDesc[tostring(nPropID)].strDesc
				if AddProp[3] == 1 then 
					self.Controls["m_CurProp"..i].text = strDesc.." +"..nValue.."%"
				else 
					self.Controls["m_CurProp"..i].text = strDesc.." +"..nValue
				end
			end
		else 
			self.Controls["m_CurProp"..i].text = ""
		end
	
	end 
	
end

-- 设置下一个属性信息
function BattleTitleWindow:SetNextBattleTitleInfo(pNextBattleTitleInfo)
	-- 战斗力属性
	local nAddBattle = pNextBattleTitleInfo.nAddBattle
	local nextTitleName = pNextBattleTitleInfo.szName
	self.Controls.m_NextTitleName.text = nextTitleName
	self.Controls.m_NextBattlePower.text = "战力 +"..nAddBattle
	local propDesc = IGame.rktScheme:GetSchemeTable(EQUIPATTACHPROPDESC_CSV)
	if not propDesc then
		uerror("[BattleTitleWindow] 读取EQUIPATTACHPROPDESC_CSV失败")
		return
	end
	
	for i = 1, 6 do
		local AddProp = pNextBattleTitleInfo["AddProp"..i] 
		if table_count(AddProp) > 0 then 
			local nPropID = AddProp[1] 
			local nValue = AddProp[2]
			if propDesc[tostring(nPropID)] ~= nil then 
				local strDesc = propDesc[tostring(nPropID)].strDesc
				if AddProp[3] == 1 then 
					self.Controls["m_NextProp"..i].text = strDesc.." +"..nValue.."%"
				else 
					self.Controls["m_NextProp"..i].text = strDesc.." +"..nValue
				end
			end
		else 
			self.Controls["m_NextProp"..i].text = ""
		end
	
	end
end

-- 关闭按钮
function BattleTitleWindow:OnBtnCloseClick()
	UIManager.BattleTitleWindow:Hide()
end

function BattleTitleWindow:ShowTipsInfo()
	self.Controls.m_TipInfo.gameObject:SetActive(true)
end

function BattleTitleWindow:OnCloseButtonClick(eventData)
	self.Controls.m_TipInfo.gameObject:SetActive(false)
end

return BattleTitleWindow