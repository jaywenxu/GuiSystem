--/******************************************************************
--** 文件名:    ExchangeWindowPresetDataMgr.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-07-05
--** 版  本:    1.0
--** 描  述:    交易界面的预设置数据管理
--** 应  用:  	通常时在请求了相应协议之后对之后的界面进行指定操作
--******************************************************************/

ExchangeWindowPresetDataMgr = 
{
	m_DstSelectedPacketItemUid = nil,	-- 打算选中的背包物品的uid:long
	m_DstRedealStallData = nil,			-- 打算2次操作的摊位数据:SMsgExchangeTableExchangeBill
	m_DstPutEntityUid = nil,			-- 打算要上架的实体uid:long
	m_NetHandleCtrlType = nil,			-- 网络回调后的操作类型:ExchangeWindowNetHandleControlType
	m_DstBuyGoodsCfgId = nil,			-- 打算购买的商品的配置id:number
}

-- 预设置背包选中的实体uid
-- @entityUid:实体uid:long
function ExchangeWindowPresetDataMgr:PresetDestPacketSelectEntityUid(entityUid)

	self.m_DstSelectedPacketItemUid = entityUid

end

-- 预设置将要购买的商品的配置id
-- @goodsCfgId:商品id:number
function ExchangeWindowPresetDataMgr:PresetDestBuyGoodsCfgId(goodsCfgId)
	
	self.m_DstBuyGoodsCfgId = goodsCfgId
	
end

-- 预设置网络回调操作类型
-- @ctrlType:ExchangeWindowNetHandleControlType
function ExchangeWindowPresetDataMgr:PresetNetHandleCtrlType(ctrlType)
	
	self.m_NetHandleCtrlType = ctrlType
	
end

-- 预设置上架数据
-- @entityUid:实体uid:long
-- @stallData:摊位数据:SMsgExchangeTableExchangeBill
function ExchangeWindowPresetDataMgr:PresetPutData(entityUid, stallData)

	self.m_DstPutEntityUid = entityUid
	self.m_DstRedealStallData = stallData

end