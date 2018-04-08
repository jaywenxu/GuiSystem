--================AuctionSubClassItem.lua=============================
-- @author	Jack Miao
-- @desc	竞拍子类型
-- @date	2017.12.15
--================AuctionSubClassItem.lua=============================

local AuctionSubClassItem = UIControl:new
{
	windowName           = "AuctionSubClassItem",

	m_nClassID    = 0,		-- 大类
	m_nSubClassID = 0,		-- 小类    
    m_bSelect       = false, -- 被选中标记
    m_SelectedCallback   = nil,
}

local this = AuctionSubClassItem
------------------------------------------------------------

function AuctionSubClassItem:Attach(obj)
	
    UIControl.Attach(self,obj)

	self.onItemClick = function() self:OnItemClick() end
	self.Controls.m_ButtonItem.onClick:AddListener(self.onItemClick)
    
    self.m_bSelect       = false
end


function AuctionSubClassItem:OnDestroy()

	self.m_nClassID = nil
	self.m_nSubClassID = nil
    self.m_SelectedCallback   = nil
    self.m_bSelect       = false
	UIControl.OnDestroy(self)
end

function AuctionSubClassItem:UpdateItem(bigTypeId, smallTypeId, smallTypeName, isSelected)
	
	self.m_nClassID = bigTypeId
	self.m_nSubClassID = smallTypeId
	
    local color = gAuctionCfg.SelectColor[0] or ""
	if isSelected then
        color = gAuctionCfg.SelectColor[1] or ""
	end
    self.m_bSelect       = isSelected
    
    self.Controls.m_TextSmallTypeName.color = UIFunction.ConverRichColorToColor(color)	
	self.Controls.m_TextSmallTypeName.text = smallTypeName
    
    self.Controls.m_TfSelectedTip.gameObject:SetActive(isSelected)	
    
    UIControl.Show(self)	
end

-- 小类型图标的点击行为
function AuctionSubClassItem:OnItemClick()
	
    if self.m_bSelect  then return end 
    
	if nil ~= self.m_SelectedCallback then
		self.m_SelectedCallback(self.m_nSubClassID)
	end    
end

function AuctionSubClassItem:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function AuctionSubClassItem:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

function AuctionSubClassItem:SetSelectCallback( func_cb )
	self.m_SelectedCallback = func_cb
end

-- 获取子类索引
function AuctionSubClassItem:GetSubClassIndex()
    
    return self.m_nSubClassID 
end

-- 清除数据
function AuctionSubClassItem:CleanData()
	
	self.m_nClassID = nil
	self.m_nSubClassID = nil
    self.m_SelectedCallback   = nil
    self.m_bSelect       = false
    
	self.Controls.m_ButtonItem.onClick:RemoveListener(self.onItemClick)
	self.onItemClick = nil	
end

-- 选中与否
function AuctionSubClassItem:SetSelected(bSelect)
 
    if not self:isLoaded() then return end 

    self.m_bSelect       = bSelect
    self.Controls.m_TfSelectedTip.gameObject:SetActive(bSelect)	
    
    local color = gAuctionCfg.SelectColor[0] or ""
    if bSelect then 
        color = gAuctionCfg.SelectColor[1] or ""
    end
    self.Controls.m_TextSmallTypeName.color = UIFunction.ConverRichColorToColor(color)	
end

return this



