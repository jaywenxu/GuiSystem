--/******************************************************************
--** 文件名:    ExchangeSearchRecordItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-21
--** 版  本:    1.0
--** 描  述:    交易搜索窗口-历史记录图标
--** 应  用:  
--******************************************************************/

local ExchangeSearchRecordItem = UIControl:new
{
    windowName = "ExchangeSearchRecordItem",
	
	m_RecordData = nil,		-- 记录数据:BaiTanFuzzySearchData
}

function ExchangeSearchRecordItem:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	self.onItemClick = function() self:OnItemClick() end
	self.Controls.m_ButtonItem.onClick:AddListener(self.onItemClick)

end

-- 更新图标
-- @recordData:记录数据:BaiTanFuzzySearchData
function ExchangeSearchRecordItem:UpdateItem(recordData)
	
	self.m_RecordData = recordData
	
	--self.Controls.m_TextSearchRecordName.text = recordData.m_SearchName
	
	ExchangeWindowTool.SetGoodsNameLabel(self.Controls.m_TextSearchRecordName, recordData.m_GoodsCfgId, recordData.m_Quality, 0, true)
	
end


-- 图标的点击行为
function ExchangeSearchRecordItem:OnItemClick()
	
	IGame.ExchangeClient:AddSearchRecord(self.m_RecordData)
	UIManager.ExchangeSearchWindow:Hide()
	
	rktEventEngine.FireExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCHANGE_UI_EVENT_CONFRIM_SEARCH_GOODS, self.m_RecordData)
		--self.m_RecordData.m_GoodsCfgId, self.m_RecordData.m_Quality)
	
end


function ExchangeSearchRecordItem:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function ExchangeSearchRecordItem:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function ExchangeSearchRecordItem:CleanData()
	
	self.Controls.m_ButtonItem.onClick:RemoveListener(self.onItemClick)
	self.onItemClick = nil
		
end

return ExchangeSearchRecordItem