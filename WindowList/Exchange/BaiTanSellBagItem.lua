--/******************************************************************
--** 文件名:    BaiTanSellBagItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-27
--** 版  本:    1.0
--** 描  述:    摆摊出售窗口-上架物选择窗口-上架物图标
--** 应  用:  
--******************************************************************/

local CommonGoodCell = require( "GuiSystem.WindowList.CommonWindow.CommonGoodCell" )

local BaiTanSellBagItem = UIControl:new
{
    windowName = "BaiTanSellBagItem",
	
	m_CommonGoodCell = nil,		-- 通用道具图标
	m_CellData = nil,			-- 格子数据
}

function BaiTanSellBagItem:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	self.m_CommonGoodCell = CommonGoodCell:new()
	self.m_CommonGoodCell:Attach(self.Controls.m_TfCommGoodCell.gameObject)
	
    self:AddListener( self.Controls.m_ButtonItem , "onClick" , self.OnItemClick , self )

end

-- 更新图标
-- @cellData:格子数据:entity or 0
-- @selectedUid:当前选中的uid:long
function BaiTanSellBagItem:UpdateItem(cellData, selectedUid)
	
	self.m_CellData = cellData
	
	if cellData == 0 then
		self.Controls.m_TfCommGoodCell.gameObject:SetActive(false)
		self.Controls.m_TfSelectedTip.gameObject:SetActive(false)
		return
	end
	
	self.Controls.m_TfCommGoodCell.gameObject:SetActive(true)
	self.m_CommonGoodCell:SetItemInfo(cellData.m_uid)
	self.Controls.m_TfSelectedTip.gameObject:SetActive(tostring(selectedUid) == tostring(cellData.m_uid))

	-- 道具
	if EntityClass:IsLeechdom(cellData:GetEntityClass()) then 
		local notBindGoodCnt = cellData:GetNumProp(GOODS_PROP_NO_BIND_QTY)
		local text = GetValuable(notBindGoodCnt>1,notBindGoodCnt,"")
		self.m_CommonGoodCell:SetCountText(text)
	end 
	
end

-- 隐藏选中提示
function BaiTanSellBagItem:HideSelectedTip()
	
	self.Controls.m_TfSelectedTip.gameObject:SetActive(false)
	
end

-- 图标的点击行为
function BaiTanSellBagItem:OnItemClick()
	
	if self.m_CellData == 0 then
		return
	end
	
	local entity = self.m_CellData
	
	ExchangeWindowPresetDataMgr:PresetPutData(entity.m_uid, nil)
	
	--UIManager.ExchangePutGoodsWindow:SetPutGoodsUid(entity.m_uid)
	
	rktEventEngine.FireExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCHANGE_UI_EVENT_SELL_PACKET_CELL_SELECTED, entity.m_uid)
	self.Controls.m_TfSelectedTip.gameObject:SetActive(true)
	
	IGame.ExchangeClient:RequestQueryEntityReferencePrice(entity)
	
end


function BaiTanSellBagItem:RecycleItem()
	rkt.GResources.RecycleGameObject(self.transform.gameObject)
end

function BaiTanSellBagItem:OnRecycle()
	self.m_CommonGoodCell:OnRecycle()

	UIControl.OnRecycle(self)
end


return BaiTanSellBagItem