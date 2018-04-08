--================AuctionClassListCell.lua=============================
-- @author	Jack Miao
-- @desc	竞拍类型
-- @date	2017.12.15
--================AuctionClassListCell.lua=============================

local AuctionSubClassItem = require( "GuiSystem.WindowList.Exchange.AuctionSubClassItem" )

local AuctionClassListCell = UIControl:new
{
	windowName                  = "AuctionClassListCell",
    
	m_CellIdx                    = 0,               -- 当前Class Cell索引
    m_nCurSelSubClass       = -1,               -- 当前选中的子类索引     
    m_bShowSubClass          = false,        -- 显示子类标记
}

local this = AuctionClassListCell
------------------------------------------------------------

function AuctionClassListCell:Attach(obj)
	UIControl.Attach(self,obj)

 	self.m_TglChangedCallback = function(on) self:OnSelectChanged(on) end
	self.Controls.m_Toggle.onValueChanged:AddListener(self.m_TglChangedCallback)
    
    self.Controls.m_subItemParent.gameObject:SetActive(false) 
    
    self.m_bShowSubClass      = false
    self.m_CellIdx            = 0
    self.m_nCurSelSubClass    = -1
end


function AuctionClassListCell:OnDestroy()
    
    if self.m_SubClassItem and table_count(self.m_SubClassItem) > 0 then    
        for idx, data in pairs(self.m_SubClassItem) do 
            data:Destroy()
        end        
    end 
    self.m_SubClassItem = {}
    
    self.m_bShowSubClass      = false
    self.m_CellIdx            = 0
    self.m_nCurSelSubClass    = -1
    
	self.m_SelectedCallback = nil
	UIControl.OnDestroy(self)
end

-- 刷新cell item 
function AuctionClassListCell:RefreshCellUI(idx, bFocus)
    
    if not self:isLoaded() then return end 
    
    self.m_CellIdx = idx 
    
    self.Controls.m_ClassName.text = gAuctionCfg.Class[idx] or ""

    self:SetToggleOn(bFocus)  
end 

-- 获取选中的idx
function AuctionClassListCell:GetSelCellIdx()	
	return  self.m_CellIdx
end


-- 设置选中的toggle 选中/取消选中
function AuctionClassListCell:SetToggleOn(isOn)	
	if not self:isLoaded() then
		return
	end

	self.Controls.m_Toggle.isOn = isOn
end

-- 设置选中回调
function AuctionClassListCell:SetSelectCallback( func_cb )
	self.m_SelectedCallback = func_cb
end

-- 设置toggle group
function AuctionClassListCell:SetToggleGroup(toggleGroup)
    self.Controls.m_Toggle.group = toggleGroup
end

function AuctionClassListCell:OnRecycle()	
	self.Controls.m_Toggle.onValueChanged:RemoveListener(self.m_TglChangedCallback)
	self.m_SelectedCallback = nil

	UIControl.OnRecycle(self)
end

-- 选择回调
function AuctionClassListCell:OnSelectChanged(on)

	if nil ~= self.m_SelectedCallback and on then
		self.m_SelectedCallback(self.m_CellIdx)
	end
    
    local color = gAuctionCfg.SelectColor[0] or ""
    if on then 
        color = gAuctionCfg.SelectColor[1] or ""   
    end
    self.Controls.m_ClassName.color = UIFunction.ConverRichColorToColor(color)
    
    UIFunction.SetImageSprite(self.Controls.m_ClassBg, gAuctionCfg.ClassSelectPic[on])
end

-- 控制显示子item
function AuctionClassListCell:SetSubItemShow(bShow)
    
    if not self:isLoaded() then return end 
    
    self.m_bShowSubClass = bShow 
    
    self.Controls.m_subItemParent.gameObject:SetActive(bShow) 
    
    if self.m_SubClassItem and table_count(self.m_SubClassItem) > 0 then    
        for idx, data in pairs(self.m_SubClassItem) do 
            data:Destroy()
        end        
    end 
    self.m_SubClassItem = {}
     
    if bShow then 
        self:SetSelectedSubClass(0)
        
        local event_data = {}
        event_data.nClass  = IGame.AuctionClient:GetAuctionType()
        event_data.nSubClass = IGame.AuctionClient:GetAuctionSubClass()
        rktEventEngine.FireEvent(EVENT_UI_AUCTION_UPDATE_GOODSLIST, SOURCE_TYPE_AUCTION, 0, event_data)    
         
        -- local sub_name = { {1, "全部",}, {2, "装备",}, {3, "武学",}, }
        local sub_name = IGame.AuctionClient:GetAucitonSubClassNameList()
        if not sub_name then             
                return 
        end 
        local nCount = table_count(sub_name)
        if nCount == 0 then return end 
        
        for typeIdx = 1, nCount do             
            rkt.GResources.FetchGameObjectAsync( GuiAssetList.Exchange.AuctionSubClassItem,
            function ( path , obj , ud )
                obj.transform:SetParent(self.Controls.m_subItemParent.transform, false)
                obj.transform.localScale = Vector3.New(1,1,1)
                self.m_SubClassItem[typeIdx] = AuctionSubClassItem:new()                                
                self.m_SubClassItem[typeIdx]:Attach(obj)
                self.m_SubClassItem[typeIdx]:SetSelectCallback(slot(self.OnSubClassItemSelected, self))
                self.m_SubClassItem[typeIdx]:UpdateItem(self.m_CellIdx, sub_name[typeIdx][1], sub_name[typeIdx][2], typeIdx == 1)           
                
                end , nil, AssetLoadPriority.GuiNormal )	
        end        
    end
end

-- 设置选中子类
function AuctionClassListCell:SetSelectedSubClass(sub_idx)
    
    self.m_nCurSelSubClass = sub_idx
    
    IGame.AuctionClient:SetAuctionSubClass(sub_idx)    
end

-- 选中子列表回调
function AuctionClassListCell:OnSubClassItemSelected(sub_idx)
    
    if not sub_idx then return end 
    
    if self.m_nCurSelSubClass == sub_idx then 
        return 
    end 

    self:SetSelectedSubClass(sub_idx)
    
    IGame.AuctionClient:SetCurSelectSerial("0")
    
    for idx, sub_item in pairs(self.m_SubClassItem) do 
        if sub_item:GetSubClassIndex() == sub_idx then 
            sub_item:SetSelected(true)
        else 
            sub_item:SetSelected(false)
        end
    end
    
    local event_data = {}
    event_data.nClass  = IGame.AuctionClient:GetAuctionType()
    event_data.nSubClass = sub_idx
	rktEventEngine.FireEvent(EVENT_UI_AUCTION_UPDATE_GOODSLIST, SOURCE_TYPE_AUCTION, 0, event_data)            
end

-- 子Item Parent是否显示
function AuctionClassListCell:CheckSubItemPareatIsShow()

    return (not self.m_bShowSubClass)
end  

return this



