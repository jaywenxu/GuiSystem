--================AuctionRecordWindow.lua=============================
-- @author	Jack Miao
-- @desc	竞品日志记录
-- @date	2017.12.25
--================AuctionRecordWindow.lua=============================

local AuctionRecordItem = require("GuiSystem.WindowList.ExchangeHistory.AuctionRecordItem")

local AuctionRecordWindow = UIWindow:new
{
    windowName = "AuctionRecordWindow",	    -- 窗口名称
    haveDoEnable = false,			
}

function AuctionRecordWindow:Init()
	
end

function AuctionRecordWindow:OnAttach( obj )
	
    UIWindow.OnAttach(self, obj)

	self.Controls.m_ButtonClose.onClick:AddListener(function() self:OnCloseButtonClick() end)
	self.Controls.m_ButtonMask.onClick:AddListener(function() self:OnMaskButtonClick() end)
	
	-- 绑定无限列表
	self.RecordEnhanceListView = self.Controls.m_ScrollerRecord:GetComponent(typeof(EnhancedListView))
	self.callbackOnRecordGetCellView = function(objCell) self:OnRecordGetCellView(objCell) end
	self.RecordEnhanceListView.onGetCellView:AddListener(self.callbackOnRecordGetCellView)
	self.callBackOnRefreshCellView = function(objCell) self:OnRefreshRecordCellView(objCell) end
	self.RecordEnhanceListView.onCellViewVisiable:AddListener(self.callBackOnRefreshCellView)   

    self.callbackOnEnable = function() self:OnEnable() end
	self.unityBehaviour.onEnable:AddListener(self.callbackOnEnable) 	
    
	self.callbackOnDisable = function() self:OnDisable() end
	self.unityBehaviour.onDisable:AddListener(self.callbackOnDisable) 
    
    self:OnEnable()
	
    return self
end

function AuctionRecordWindow:OnEnable()
    
    if not self.haveDoEnable then 
        self.haveDoEnable = true 
        local nType = IGame.AuctionClient:GetAuctionType()
        local record_cnt = IGame.AuctionClient:GetAuctionRecordCnt(nType)
        self.RecordEnhanceListView:SetCellCount( 0, true )
        if record_cnt <= 0 then 
            self.Controls.m_CtrlNoRecord.gameObject:SetActive(true)
        else 
            self.Controls.m_CtrlNoRecord.gameObject:SetActive(false)
            self.RecordEnhanceListView:SetCellCount( record_cnt, true )
        end
        
        if nType == emAuction_Clan then 
            UIFunction.SetImageSprite(self.Controls.m_RecordTitle, AssetPath.TextureGUIPath.."Exchanger/Exchange_banghuipaimaijilu.png")
        else 
            UIFunction.SetImageSprite(self.Controls.m_RecordTitle, AssetPath.TextureGUIPath.."Exchanger/Exchange_quanfupaimaijilu.png")
        end 
    end
end 

function AuctionRecordWindow:OnDisable()
    
    self.haveDoEnable = false
end 

function AuctionRecordWindow:OnDestroy()
    
    self.haveDoEnable = false
	UIWindow.OnDestroy(self)
end

-- 竞品EnhancedListView 一行被“创建”时的回调
function AuctionRecordWindow:OnRecordGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshRecordCellView)
	self:CreateCellItems(listcell)
end

-- 竞品EnhancedListView 一行强制刷新时的回调
function AuctionRecordWindow:OnRefreshRecordCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshRecordCellItems(listcell)
end

-- 竞品EnhancedListView 一行可见时的回调
function AuctionRecordWindow:OnRefreshRecordCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshRecordCellItems( listcell )
end

-- 创建条目
function AuctionRecordWindow:CreateCellItems( listcell )
	
    local item = AuctionRecordItem:new({})
	item:Attach(listcell.gameObject)    
	local idx = listcell.dataIndex + 1
    item:SetIndex(idx)
	listcell.gameObject.name = string.format("AuctionRecordItem-%d",idx)
	
	self:RefreshRecordCellItems(listcell)
end

--- 刷新竞品列表
function AuctionRecordWindow:RefreshRecordCellItems( listcell )	
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
		
    local item = behav.LuaObject
    local record = IGame.AuctionClient:GetAuctionRecord(IGame.AuctionClient:GetAuctionType(), item:GetIndex())
    if not record then return end 
       
	item:RefreshUI(record)
end


-- 关闭按钮的点击行为
function AuctionRecordWindow:OnCloseButtonClick()
	
	UIManager.AuctionRecordWindow:Hide()	
end

-- 遮罩按钮的点击行为
function AuctionRecordWindow:OnMaskButtonClick()
	
	UIManager.AuctionRecordWindow:Hide()	
end

return AuctionRecordWindow