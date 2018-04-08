--/******************************************************************
--** 文件名:    BaiTanBuySmallTypeItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-19
--** 版  本:    1.0
--** 描  述:    交易窗口-摆摊部件-搜索部件-小类型图标
--** 应  用:  
--******************************************************************/
local BaiTanBuySmallTypeItem = UIControl:new
{
    windowName = "BaiTanBuySmallTypeItem",
	
	m_BigTypeId = 0,		-- 所属大类型id:number
	m_SmallTypeId = 0,		-- 对应的小类型id:number
}

function BaiTanBuySmallTypeItem:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	self.onItemClick = function() self:OnItemClick() end
	self.Controls.m_ButtonItem.onClick:AddListener(self.onItemClick)
	
end

-- 更新图标
-- @bigTypeId:所属的大类型id:number
-- @smallTypeId:对应的类型id:number
-- @smallTypeName:小类型名称:string
-- @isSelected:是否选中的标识
function BaiTanBuySmallTypeItem:UpdateItem(bigTypeId, smallTypeId, smallTypeName, isSelected)
	
	self.m_BigTypeId = bigTypeId
	self.m_SmallTypeId = smallTypeId
	
	if isSelected then
		self.Controls.m_TextSmallTypeName.color = UIFunction.ConverRichColorToColor("AD4534")
	else 
		self.Controls.m_TextSmallTypeName.color = UIFunction.ConverRichColorToColor("597993")
	end
	
	self.Controls.m_TfSelectedTip.gameObject:SetActive(isSelected)
	self.Controls.m_TextSmallTypeName.text = smallTypeName
	
end

-- 小类型图标的点击行为
function BaiTanBuySmallTypeItem:OnItemClick()
	
	rktEventEngine.FireExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCHANGE_UI_EVENT_SMALL_TYPE_ITEM_CLICK, self.m_BigTypeId, self.m_SmallTypeId)
	
end

function BaiTanBuySmallTypeItem:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function BaiTanBuySmallTypeItem:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function BaiTanBuySmallTypeItem:CleanData()
	
	self.Controls.m_ButtonItem.onClick:RemoveListener(self.onItemClick)
	self.onItemClick = nil
	
end

return BaiTanBuySmallTypeItem