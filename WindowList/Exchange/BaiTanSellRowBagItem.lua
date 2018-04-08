--/******************************************************************
--** 文件名:    BaiTanSellRowBagItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-27
--** 版  本:    1.0
--** 描  述:    摆摊出售窗口-上架物选择窗口-上架物行图标
--** 应  用:  
--******************************************************************/

local BaiTanSellBagItem = require("GuiSystem.WindowList.Exchange.BaiTanSellBagItem")

local BaiTanSellRowBagItem = UIControl:new
{
    windowName = "BaiTanSellRowBagItem",
	
	m_ListBaiTanSellBagItem = {},		-- 摆摊出售背包图标列表:table(BaiTanSellBagItem)
}

function BaiTanSellRowBagItem:Attach(obj)
	
    UIControl.Attach(self,obj)
end

-- 隐藏选中提示
function BaiTanSellRowBagItem:HideSelectedTip(obj)
	
    for k,v in pairs(self.m_ListBaiTanSellBagItem) do
		v:HideSelectedTip()
	end
	
end

-- 更新图标
-- @rowData:行数据:table(entity or 0)
-- @selectedUid:当前选中的实体uid:long
function BaiTanSellRowBagItem:UpdateItem(rowData, selectedUid)
	for itemIdx = 1, 4 do 

		local colData = rowData[itemIdx] 
		if colData and colData ~= 0 then -- 无数据不创建item
			local item = self.m_ListBaiTanSellBagItem[itemIdx]
			if not item then
				
				item = BaiTanSellBagItem:new() 
				local parent = self.Controls[string.format("m_TfBaiTanSellBagItem%d", itemIdx)]
				rkt.GResources.FetchGameObjectAsync( GuiAssetList.Exchange.BaiTanSellBagItem,
				function ( path , obj , ud )
					if nil == obj then 
						uerror("prefab is nil : " .. path )
						return
					end

					obj.transform:SetParent(parent, false)

					item:Attach(obj.gameObject)

					item:UpdateItem(colData, selectedUid)

					self.m_ListBaiTanSellBagItem[itemIdx] = item
					
				end , i, AssetLoadPriority.GuiNormal )	
			else
				item:UpdateItem(colData, selectedUid)
			end

		end 
	end
	
end


function BaiTanSellRowBagItem:OnRecycle()
	-- 清除数据

	for k, item in pairs(self.m_ListBaiTanSellBagItem) do
		item:RecycleItem()
	end
	self.m_ListBaiTanSellBagItem = {}
	
	UIControl.OnRecycle(self)
end

return BaiTanSellRowBagItem