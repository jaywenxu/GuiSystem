--/******************************************************************
--** 文件名:    ExchangePutGoodsWindow.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-22
--** 版  本:    1.0
--** 描  述:    摆摊上架物品界面
--** 应  用:  
--******************************************************************/

local ExchangePutGoodsWindow = UIWindow:new
{
    windowName = "ExchangePutGoodsWindow",	-- 窗口名称
    m_IsWindowInvokeOnShow = false,    		-- 窗口是否调用了OnWindowShow方法的标识:boolean
	
	m_GoodsUid = {},						-- 物品uid:long
	m_StallData = nil,						-- 摊位数据:SMsgExchangeTableExchangeBill
	m_MsgBody = nil,						-- 协议回包消息体:SMsgExchangeCheapest_SC
	
	m_ExchangePutReferenceWidget = nil,		-- 价格参考窗口:ExchangePutReferenceWidget
	m_ExchangePutControlWidget = nil,		-- 上架操作窗口:ExchangePutControlWidget
}

function ExchangePutGoodsWindow:Init()
	
end

function ExchangePutGoodsWindow:OnAttach( obj )
	
    UIWindow.OnAttach(self, obj)

	self.m_ExchangePutReferenceWidget = require("GuiSystem.WindowList.ExchangePutGoods.ExchangePutReferenceWidget"):new()
	self.m_ExchangePutControlWidget = require("GuiSystem.WindowList.ExchangePutGoods.ExchangePutControlWidget"):new()

	self.m_ExchangePutReferenceWidget:Attach(self.Controls.m_TfChangePutReferenceWidget.gameObject)
	self.m_ExchangePutControlWidget:Attach(self.Controls.m_TfExchangePutControlWidget.gameObject)

	self.Controls.m_ButtonMask.onClick:AddListener(function() self:OnMaskButtonClick() end)
	self.Controls.m_ButtonClose.onClick:AddListener(function() self:OnCloseButtonClick() end)

    if self.m_IsWindowInvokeOnShow then
        self.m_IsWindowInvokeOnShow = false
        self:OnWindowShow()
    end
	
    return self
	
end


function ExchangePutGoodsWindow:OnDestroy()
	UIWindow.OnDestroy(self)

	table_release(self)			
end

function ExchangePutGoodsWindow:_showWindow()
	
    UIWindow._showWindow(self)
	
    if self:isLoaded() then
        self:OnWindowShow()
    else
        self.m_IsWindowInvokeOnShow = true
    end
	
end

--[[-- 设置要上架物的uid
-- @goodsUid:物品uid:long
function ExchangePutGoodsWindow:SetPutGoodsUid(goodsUid)
	
	self.m_GoodsUid = goodsUid
	self.m_StallData = nil
	
end

-- 设置摊位数据
-- @stallData:摊位数据:SMsgExchangeTableExchangeBill
function ExchangePutGoodsWindow:SetStallData(stallData)
	
	self.m_GoodsUid = nil
	self.m_StallData = stallData
	
end--]]

-- 显示窗口
-- @msgBody:协议回包消息体:SMsgExchangeCheapest_SC
function ExchangePutGoodsWindow:ShowWindow(msgBody)
	
	self.m_MsgBody = msgBody

    UIWindow.Show(self, true)
	
end

-- 窗口每次打开执行的行为
function ExchangePutGoodsWindow:OnWindowShow()
	
	local goodsCfgId = 0
	local goodsQuality = 0
	
	self.m_GoodsUid = ExchangeWindowPresetDataMgr.m_DstPutEntityUid
	self.m_StallData = ExchangeWindowPresetDataMgr.m_DstRedealStallData
	
	if self.m_GoodsUid == nil then -- 已经上架了的物品的操作
		goodsCfgId = self.m_StallData.nGoods
		goodsQuality = self.m_StallData.btColor
	
		self.m_ExchangePutControlWidget:UpdateForRedeal(self.m_StallData)
	else -- 未上架物品的操作
		local entity = IGame.EntityClient:Get(self.m_GoodsUid)
		if not entity then
			return
		end
		
		goodsCfgId = entity:GetNumProp(GOODS_PROP_GOODSID)
		goodsQuality = entity:GetNumProp(EQUIP_PROP_QUALITY)
		
		self.m_ExchangePutControlWidget:UpdateForPut(self.m_GoodsUid)
	end
	
	self.m_ExchangePutReferenceWidget:UpdateWidget(self.m_MsgBody, goodsCfgId, goodsQuality)
	
end

-- 遮罩按钮的点击行为
function ExchangePutGoodsWindow:OnMaskButtonClick()
	
	UIManager.ExchangePutGoodsWindow:Hide()
	
end

-- 关闭按钮的点击行为
function ExchangePutGoodsWindow:OnCloseButtonClick()
	
	UIManager.ExchangePutGoodsWindow:Hide()
	
end

return ExchangePutGoodsWindow