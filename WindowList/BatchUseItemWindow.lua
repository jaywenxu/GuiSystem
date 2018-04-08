--BatchUseItemWindow.lua------------------------------------------------------------
-- 版  权:	(C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:	何荣德
-- 日  期:	2017.1.3
-- 版  本:	1.0
-- 描  述:	物品批量使用窗口
-------------------------------------------------------------------

local ItemClass = require("GuiSystem.WindowList.HuoDong.HuoDongRewardItem")

local BatchUseItemWindow = UIWindow:new
{
	windowName = "BatchUseItemWindow" ,
	m_nItemId = 0,
    m_nUseNum = 1,
    m_nMaxUseNum = 1,
    m_Item = nil,
}

function BatchUseItemWindow:InitUI()
    self.m_nUseNum = 1
    
    local item = ItemClass:new({})
	
    local pGameObject = self.Controls.m_Item.gameObject
	item:Attach(pGameObject)
    local tGoods = {ID=self.m_nItemId, Num=self.m_nMaxUseNum} 
	item:SetItemCellInfo(tGoods)
    
    self.m_Item = item
    
    self.Controls.m_UseNum = self.Controls.m_InputField:GetComponent(typeof(InputField))
end

function BatchUseItemWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	self:AddListener(self.Controls.m_SubBtn, "onClick", self.OnSubBtnClick, self)
	self:AddListener(self.Controls.m_AddBtn, "onClick", self.OnAddBtnClick, self)
	self:AddListener(self.Controls.m_MaxBtn, "onClick", self.OnMaxBtnClick, self)
	self:AddListener(self.Controls.m_CloseBtn, "onClick", self.OnCloseBtnClick, self)
	self:AddListener(self.Controls.m_ConfirmBtn, "onClick", self.OnConfirmBtnClick, self)
    
    --物品增加事件
	self.callback_OnEventAddGoods = function(event, srctype, srcid, eventdata) self:OnEventAddGoods(eventdata) end
	rktEventEngine.SubscribeExecute( EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	--物品减少事件
	self.callback_OnEventRemoveGoods = function(event, srctype, srcid, eventdata) self:OnEventRemoveGoods(eventdata) end
	rktEventEngine.SubscribeExecute( EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
    
    self.callbackOnNumChanged = function() self:OnInputFieldValueChanged() end
	self.Controls.m_InputField:GetComponent(typeof(InputField)).onValueChanged:AddListener(self.callbackOnNumChanged)
    
    self:InitUI()
end

-- 增加物品处理
function BatchUseItemWindow:OnEventAddGoods(eventdata)
	if not self:isShow() or not eventdata then
		return
	end
	
	local entity = IGame.EntityClient:Get(eventdata.uidGoods)
	if not entity then
		return
	end
	local goodId = entity:GetNumProp(GOODS_PROP_GOODSID)
    if goodId ~= self.m_nItemId then
        return
    end
    
    self.m_nMaxUseNum = GameHelp:GetHeroPacketGoodsNum(self.m_nItemId)
    local tGoods = {ID=self.m_nItemId, Num=self.m_nMaxUseNum} 
    self.m_Item:SetItemNum(tGoods)
end

-- 移除物品处理
function BatchUseItemWindow:OnEventRemoveGoods(eventdata)
	if not self:isShow() or not eventdata then
		return
	end
	
	local goodId = eventdata.goodId
	if goodId == self.m_nItemId or goodId == 0 then
        self.m_nMaxUseNum = GameHelp:GetHeroPacketGoodsNum(self.m_nItemId)
        if self.m_nMaxUseNum == 0 then
            self:Hide()
            return
        end
        
        local tGoods = {ID=self.m_nItemId, Num=self.m_nMaxUseNum} 
        self.m_Item:SetItemNum(tGoods)
        self.m_nUseNum = math.min(self.m_nUseNum, self.m_nMaxUseNum) 
        self.Controls.m_UseNum.text = self.m_nUseNum 
    end
end

function BatchUseItemWindow:OnDestroy()
	UIWindow.OnDestroy(self)
    
    self.m_nItemId = 0
    self.m_nUseNum = 1
    self.m_nMaxUseNum = 1
    self.m_Item = nil
    
    self.callbackOnNumChanged = nil
end

function BatchUseItemWindow:Show(nItemId, nItemNum)
    if nItemId and nItemNum then
        self.m_nItemId = nItemId
        self.m_nMaxUseNum = nItemNum
    else
        uerror("BatchUseItemWindow:Show param nil")
        return
    end
    
    if not self:isLoaded() then
        UIWindow.Show(self)
        return
    end
    
     self:InitUI()
end

-- 输入变化
function BatchUseItemWindow:OnInputFieldValueChanged()
    local num = tonumber(self.Controls.m_UseNum.text)
    if num >  self.m_nMaxUseNum then
        self.m_nUseNum = self.m_nMaxUseNum
    elseif num < 1 then
        self.m_nUseNum = 1
    else
        self.m_nUseNum = num
    end
    self.Controls.m_UseNum.text = self.m_nUseNum  
end

-- 减少数量
function BatchUseItemWindow:OnSubBtnClick()
    if self.m_nUseNum == 1 then
        return
    end
	self.m_nUseNum = self.m_nUseNum - 1
    self.Controls.m_UseNum.text = self.m_nUseNum
end

-- 增加数量
function BatchUseItemWindow:OnAddBtnClick()
    if self.m_nUseNum >= self.m_nMaxUseNum then
        return
    end
	self.m_nUseNum = self.m_nUseNum + 1
    self.Controls.m_UseNum.text = self.m_nUseNum
end

-- 最大数量
function BatchUseItemWindow:OnMaxBtnClick()
	self.m_nUseNum = self.m_nMaxUseNum
    self.Controls.m_UseNum.text = self.m_nUseNum
end

-- 响应关闭
function BatchUseItemWindow:OnCloseBtnClick()
	self:Hide()
end

-- 确认使用
function BatchUseItemWindow:OnConfirmBtnClick()
	local packetPart = IGame.EntityClient:GetHeroEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	
--	if packetPart:CountEmptyPlace(false) < self.m_nUseNum then
--		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "包裹栏剩余空位不足" .. self.m_nUseNum .. "个，请先清理背包")
--		return
--	end
	
    local tUidGroup = packetPart:GetGoodsUIDGroupByGoodsID(self.m_nItemId, self.m_nUseNum)
    if not tUidGroup then
        return
    end
    
    local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return 
	end
    
    -- 这个时候不更新背包窗口
    UIManager.PackWindow:SetRemoveGoodNeedLoadFlag(false)
    
    local msg = {}
    msg.uidTarget = pHero:GetUID()
    msg.nUseCount = self.m_nUseNum
    msg.nGoodsCount = table_count(tUidGroup)
    msg.uidGoods = tUidGroup
    
    IGame.Network:Send(msg, MSG_MODULEID_SKEP, MSG_SKEP_BATCH_USE_CS, MSG_ENDPOINT_ZONE)
    
    self:Hide()
end

return BatchUseItemWindow
