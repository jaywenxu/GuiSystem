--/******************************************************************
--** 文件名:    ExchangeFuzzySearchResultItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-21
--** 版  本:    1.0
--** 描  述:    交易界面搜索窗口-模糊搜索结果图标
--** 应  用:  
--******************************************************************/

local ExchangeFuzzySearchResultItem = UIControl:new
{
    windowName = "ExchangeFuzzySearchResultItem",
	
	m_ListFuzzySearchData = {},			-- 模糊搜索数据列表:table(BaiTanFuzzySearchData)
}

function ExchangeFuzzySearchResultItem:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	self.onResultButtonClick1 = function() self:OnResultButtonClick(1) end
	self.onResultButtonClick2 = function() self:OnResultButtonClick(2) end

	self.Controls.m_ButtonResult1.onClick:RemoveListener(self.onResultButtonClick1)
	self.Controls.m_ButtonResult2.onClick:RemoveListener(self.onResultButtonClick2)

	self.Controls.m_ButtonResult1.onClick:AddListener(self.onResultButtonClick1)
	self.Controls.m_ButtonResult2.onClick:AddListener(self.onResultButtonClick2)
	
end

-- 更新图标
-- @listFuzzySearchData:模糊搜索数据列表:table(BaiTanFuzzySearchData)
function ExchangeFuzzySearchResultItem:UpdateItem(listFuzzySearchData)
	
	self.m_ListFuzzySearchData = listFuzzySearchData
	
	self:UpdateOneResultButton(1, listFuzzySearchData[1])
	self:UpdateOneResultButton(2, listFuzzySearchData[2])
	
end

-- 更新一个结果按钮
-- @btnIdx:按钮索引:number
-- @fuzzySearchData:商品配置:BaiTanFuzzySearchData
function ExchangeFuzzySearchResultItem:UpdateOneResultButton(btnId, fuzzySearchData)
	
	if not fuzzySearchData then
		self.Controls[string.format("m_ButtonResult%d", btnId)].gameObject:SetActive(false)
		return
	end
	
	self.Controls[string.format("m_ButtonResult%d", btnId)].gameObject:SetActive(true)
	
	ExchangeWindowTool.SetGoodsNameLabel(self.Controls[string.format("m_TextResultName%d", btnId)], 
		fuzzySearchData.m_GoodsCfgId, fuzzySearchData.m_Quality, 0, true)
	
end

-- 结果按钮的点击行为
function ExchangeFuzzySearchResultItem:OnResultButtonClick(btnIdx)
	
	local fuzzySearchData = self.m_ListFuzzySearchData[btnIdx]
	if not fuzzySearchData then
		return
	end

	IGame.ExchangeClient:AddSearchRecord(fuzzySearchData)
	UIManager.ExchangeSearchWindow:Hide()
	
	--[[rktEventEngine.FireExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCHANGE_UI_EVENT_CHANGE_QUERY_GOODS, 
		fuzzySearchData.m_GoodsCfgId, fuzzySearchData.m_Quality)--]]
	rktEventEngine.FireExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCHANGE_UI_EVENT_CONFRIM_SEARCH_GOODS, fuzzySearchData)
	
end


function ExchangeFuzzySearchResultItem:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function ExchangeFuzzySearchResultItem:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function ExchangeFuzzySearchResultItem:CleanData()

	self.Controls.m_ButtonResult1.onClick:RemoveListener(self.onResultButtonClick1)
	self.Controls.m_ButtonResult2.onClick:RemoveListener(self.onResultButtonClick2)
	self.onResultButtonClick1 = nil
	self.onResultButtonClick2 = nil
	
end

return ExchangeFuzzySearchResultItem