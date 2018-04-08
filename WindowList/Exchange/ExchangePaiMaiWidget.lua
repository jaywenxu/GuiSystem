--/******************************************************************
---** 文件名:	ExchangePaiMaiWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-09
--** 版  本:	1.0
--** 描  述:	交易窗口-拍卖窗口
--** 应  用:  
--******************************************************************/

local AuctionGoodsCellClass = require( "GuiSystem.WindowList.Exchange.AuctionGoodsListCell" )
local AuctionClassCellClass = require( "GuiSystem.WindowList.Exchange.AuctionClassListCell" )

local ExchangePaiMaiWidget = UIControl:new
{
	windowName 	= "ExchangePaiMaiWidget",
    haveDoEnable = false,

    m_curSelectClass = 0,               -- 当前选中的大类（帮会/全服）
    
    m_arrAuctionClassItem = {},       -- 大类item 对象  
    
    m_goodsCellItem         = {},       -- 竞品cell
    
    m_nAuctionTime          = 0,        -- 竞拍操作时间
    
    m_reqAuctionRecTime   = 0,         -- 查看竞拍日志时间
}

function ExchangePaiMaiWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	
    -- 查看日志按钮
	self.callBackOnQueryAuctionRecord = function() self:OnBtnQueryAuctioRecord() end
	self.Controls.m_btnRecord.onClick:AddListener(self.callBackOnQueryAuctionRecord)    
    
    -- 一口价竞拍按钮
    self.callbackOnMaxPriceAuction  = function() self:OnBtnMaxPriceAuction() end 
	self.Controls.m_btnBuyItNow.onClick:AddListener(self.callbackOnMaxPriceAuction) 
    
    -- 竞拍按钮
    self.callbackOnAuction = function() self:OnBtnAuction() end 
    self.Controls.m_btnJoinAuction.onClick:AddListener(self.callbackOnAuction) 
    
    -- 加价按钮
    self.callbackOnAddPriceAuction = function() self:OnBtnAddPriceAuction() end 
    self.Controls.m_btnAddPrce.onClick:AddListener(self.callbackOnAddPriceAuction)         
    
    self.ClassToggleGroup = self.Controls.m_ClassToggleGroup:GetComponent(typeof(ToggleGroup))
    
    -- 竞品list scroller
	self.GoodsEnhanceListView = self.Controls.m_AuctionGoodsListScroller:GetComponent(typeof(EnhancedListView))
	self.callbackOnGoodsGetCellView = function(objCell) self:OnGoodsGetCellView(objCell) end
	self.GoodsEnhanceListView.onGetCellView:AddListener(self.callbackOnGoodsGetCellView)
	self.callBackOnRefreshCellView = function(objCell) self:OnRefreshGoodsToggleCellView(objCell) end
	self.GoodsEnhanceListView.onCellViewVisiable:AddListener(self.callBackOnRefreshCellView)    
    self.GoodsToggleGroup = self.Controls.m_GoodsToggleGroup:GetComponent(typeof(ToggleGroup))
        
    self.callbackOnEnable = function() self:OnEnable() end
	self.unityBehaviour.onEnable:AddListener(self.callbackOnEnable) 	
    
	self.callbackOnDisable = function() self:OnDisable() end
	self.unityBehaviour.onDisable:AddListener(self.callbackOnDisable) 
    
    self.m_TimerCallback = function() self:OnTimerChangeCD() end
    self:OnEnable()
end

-- 显示
function ExchangePaiMaiWidget:OnEnable() 

    if self.haveDoEnable == false then      

        IGame.AuctionClient:SetAuctionType(emAuction_Clan)   
        
        -- 初始UI
        self:InitUI()
        
        -- 订阅事件
        self:RegisterEvent()
        
        if self.m_TimerCallback then 
            rktTimer.KillTimer( self.m_TimerCallback )
        end
        rktTimer.SetTimer(self.m_TimerCallback, 1000, -1, "ExchangePaiMaiWidget:InitUI")         
        
		self.haveDoEnable = true
	end	
end 

-- 隐藏
function ExchangePaiMaiWidget:OnDisable()
    
    -- 通知服务器退出观察
    IGame.AuctionClient:CloseUIReqExitAuction()
    
    -- 取消订阅
    self:UnRegisterEvent()
    
    for idx, data in pairs(self.m_arrAuctionClassItem) do 
        data:Destroy()
    end
    self.m_arrAuctionClassItem = {}                
    
    if self.m_TimerCallback then 
        rktTimer.KillTimer( self.m_TimerCallback )
    end
    
    self.haveDoEnable = false
    self.m_curSelectClass = 0        
end 

-- 初始化UI
function ExchangePaiMaiWidget:InitUI()
    
    self.m_curSelectClass = 0
    
    if self.GoodsEnhanceListView then 
          self.GoodsEnhanceListView:SetCellCount( 0, true )
          self.m_goodsCellItem = {}
    end
       
    for idx, data in pairs(self.m_arrAuctionClassItem) do 
        data:Destroy()
    end    
    self.m_arrAuctionClassItem = {}   
     
    local loadedNum = 0
    local nCount = table_count(gAuctionCfg.Class)
    for	i = 1, nCount do 
        rkt.GResources.FetchGameObjectAsync(GuiAssetList.Exchange.AuctionClassListCell,
        function ( path , obj , ud )
            obj.transform:SetParent(self.Controls.m_ClassParent, false)
            obj.transform.localScale = Vector3.New(1,1,1)
            local item = AuctionClassCellClass:new({})
            item:Attach(obj)
            item:SetToggleGroup(self.ClassToggleGroup)
            item:SetSelectCallback(slot(self.OnClassItemCellSelected, self))
            
            local bFocus = ((i-1) == self.m_curSelectClass)
            item:RefreshCellUI(i-1, bFocus)            
            
            table.insert(self.m_arrAuctionClassItem,i,item)	
            loadedNum = loadedNum + 1
            
            if i == nCount then 
                  self:ReqEnterAuction()   
            end
        end , i , AssetLoadPriority.GuiNormal )
    end
    
    self.Controls.m_txtNoGoods.gameObject:SetActive(false)
    self.Controls.m_txtDividendYL.text = 0
    
    self.Controls.m_btnJoinAuction.gameObject:SetActive(true)
    self.Controls.m_btnAddPrce.gameObject:SetActive(false)   
end 

-- 请求竞拍信息
function ExchangePaiMaiWidget:ReqEnterAuction()
    
        -- 告知服务器进入竞拍所，下发数据        
        IGame.AuctionClient:OpenUIReqEnterAuction()    
end 

-- 订阅事件
function ExchangePaiMaiWidget:RegisterEvent()

	self.OnSyncAuctionInfo = function(event, srctype, srcid,eventData) self:SyncAuctionInfo(eventData) end
	rktEventEngine.SubscribeExecute(EVENT_UI_AUCTION_SYNC_GOODSLIST , SOURCE_TYPE_AUCTION , 0 , self.OnSyncAuctionInfo)    
    
    self.OnUpdateAuctionInfo = function(event, srctype, srcid,eventData) self:UpdateAuctionInfo(eventData) end 
    rktEventEngine.SubscribeExecute(EVENT_UI_AUCTION_UPDATE_GOODSLIST , SOURCE_TYPE_AUCTION , 0 , self.OnUpdateAuctionInfo)  
    
    self.OnUpdateAuctionBtn  = function(event, srctype, srcid,eventData) self:UpdateAuctionBtnState(eventData) end 
    rktEventEngine.SubscribeExecute(EVENT_UI_AUCTION_UPDATE_BUTTON , SOURCE_TYPE_AUCTION , 0 , self.OnUpdateAuctionBtn)  

    self.OnUpdateMyDividend = function() self:UpdateMyDividend() end
    rktEventEngine.SubscribeExecute(EVENT_UI_AUCTION_UPDATE_DIVIDEND , SOURCE_TYPE_AUCTION , 0 , self.OnUpdateMyDividend)          
end

-- 取消订阅
function ExchangePaiMaiWidget:UnRegisterEvent()
    
    if self.OnSyncAuctionInfo then 
        rktEventEngine.UnSubscribeExecute( EVENT_UI_AUCTION_SYNC_GOODSLIST , SOURCE_TYPE_AUCTION , 0, self.OnSyncAuctionInfo)
    end
    
    if self.OnUpdateAuctionInfo  then 
       rktEventEngine.UnSubscribeExecute( EVENT_UI_AUCTION_UPDATE_GOODSLIST , SOURCE_TYPE_AUCTION , 0, self.OnUpdateAuctionInfo)     
    end
    
    if self.OnUpdateAuctionBtn then 
       rktEventEngine.UnSubscribeExecute( EVENT_UI_AUCTION_UPDATE_BUTTON , SOURCE_TYPE_AUCTION , 0, self.OnUpdateAuctionBtn)             
    end
    
    if self.OnUpdateMyDividend  then 
       rktEventEngine.UnSubscribeExecute( EVENT_UI_AUCTION_UPDATE_DIVIDEND , SOURCE_TYPE_AUCTION , 0, self.OnUpdateMyDividend)          
    end
end

-- 刷新倒计时
function ExchangePaiMaiWidget:OnTimerChangeCD()
    
    if not self.m_goodsCellItem  or table_count(self.m_goodsCellItem ) <= 0 then return end 
    
    for _, item in pairs(self.m_goodsCellItem) do             
        item:RefreshTimeCD()
    end
end 

-- 同步刷新竞品
function ExchangePaiMaiWidget:SyncAuctionInfo(eventData)
    
    if not self:isLoaded() then return end 
    
    if not eventData then return end 
      
    if self.m_curSelectClass ~= eventData.nClass then return end 
    
    local item = self.m_arrAuctionClassItem[self.m_curSelectClass+1]
    if not item then return end 

    item:SetSubItemShow(true)
end 

-- 刷新竞价按钮
function ExchangePaiMaiWidget:UpdateAuctionBtnState(eventData)
    
    if eventData and GetHero() and IGame.AuctionClient:GetCurSelectSerial() == eventData.GoodsSerial then 
        local  auction_goods = IGame.AuctionClient:GetAuctionGoods(eventData.GoodsSerial)
        if auction_goods and auction_goods.dwAuctioner == GetHero():GetNumProp(CREATURE_PROP_PDBID) then 
            self.Controls.m_btnJoinAuction.gameObject:SetActive(false)
            self.Controls.m_btnAddPrce.gameObject:SetActive(true)                   
            return
        end
    end 
    
    self.Controls.m_btnJoinAuction.gameObject:SetActive(true)
    self.Controls.m_btnAddPrce.gameObject:SetActive(false)   
end 

-- 刷新竞品
function ExchangePaiMaiWidget:UpdateAuctionInfo(eventData)
    
    if not self:isLoaded() or not eventData then return end 
    
    if self.m_curSelectClass ~= eventData.nClass then 
        uerror("[拍卖系统]刷新竞品->ExchangePaiMaiWidget:UpdateAuctionInfo，类别异常！")
        return
    end 

    IGame.AuctionClient:CheckSortGoods()
    
    self.GoodsEnhanceListView:SetCellCount( 0, true )
    self.m_goodsCellItem = {}
    local nCount = IGame.AuctionClient:GetAuctionSubClassGoodsNum(eventData.nClass, eventData.nSubClass)

    if nCount > 0 then 
        self.GoodsEnhanceListView:SetCellCount( nCount, true )  
        self.Controls.m_txtNoGoods.gameObject:SetActive(false)
    else 
        self.Controls.m_txtNoGoods.gameObject:SetActive(true)
    end
    
    if self.m_curSelectClass == emAuction_Clan then 
          self.Controls.m_txtDividendYL.text = IGame.AuctionClient:GetMyDividendMoney()   
    end    
end 

-- 刷新我的分红金额
function ExchangePaiMaiWidget:UpdateMyDividend()
    
    if not self:isLoaded() then return end 
    
    if IGame.AuctionClient:GetAuctionType() ~= emAuction_Clan then return end 
    
    self.Controls.m_txtDividendYL.text = IGame.AuctionClient:GetMyDividendMoney()
end

-- 查看日志按钮回调
function ExchangePaiMaiWidget:OnBtnQueryAuctioRecord()
    
    local nType = IGame.AuctionClient:GetAuctionType()
    if nType == emAuction_Clan and not IGame.ClanClient:GetClan() then
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你当前没有帮会，不能查看竞拍日志！") 
        return
    end 
    
    if self.m_reqAuctionRecTime and Time.realtimeSinceStartup < self.m_reqAuctionRecTime + 1 then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "操作过于频繁！")
        return
    end
    self.m_reqAuctionRecTime = Time.realtimeSinceStartup        
    
    IGame.AuctionClient:ReqQueryRecord()
end

-- 竞拍条件检查
function ExchangePaiMaiWidget:AuctionRightCheck()
    
    local nType = IGame.AuctionClient:GetAuctionType()
    if nType ~= emAuction_Clan and nType ~= emAuction_Global then
        return false
    end
    
    if nType == emAuction_Clan and not IGame.ClanClient:GetClan() then
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你当前没有帮会！") 
        return false
    end 

    local goods_list = IGame.AuctionClient:GetTypeAuctionGoods(nType)
    if not goods_list or table_count(goods_list) <= 0 then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "暂无竞品可拍！") 
        return false
    end
    
    return true 
end 

-- 一口价竞拍按钮回调
function ExchangePaiMaiWidget:OnBtnMaxPriceAuction()
    
    if not self:AuctionRightCheck() then return end 

    local goods_serial = IGame.AuctionClient:GetCurSelectSerial()
    if not goods_serial or tonumber(goods_serial) <= 0 then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "先选择竞拍的物品！")
        return
    end 
    
    local auction_goods = IGame.AuctionClient:GetAuctionGoods(goods_serial)
    if not auction_goods then 
        return 
    end 
    
    if auction_goods.end_flag  then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "该竞品已结束拍卖！")
        return
    end 
    
    if auction_goods.nState == E_AuctionGoodsState_MaxPrice then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "该竞品已拍卖！")
        return 
    end 
    
    local auction_config = IGame.rktScheme:GetSchemeTable(AUCTION_CSV)
    if not auction_config then 
        uerror("[拍卖系统]刷新倒计时->获取配置失败！文件名："..AUCTION_CSV)
        return
    end

    local config = nil
    for j, data in pairs(auction_config) do
        config = data
    end
    if not config then return end 
    
    if IGame.EntityClient:GetZoneServerTime() < auction_goods.dwTime + config.PrepareTime then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "该竞品未开始竞拍！")
        return 
    end 
    
    local pHero = GetHero()
    if not pHero then return end 
    
    if self.m_nAuctionTime and Time.realtimeSinceStartup < self.m_nAuctionTime + 1 then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "操作过于频繁！")
        return
    end
    self.m_nAuctionTime = Time.realtimeSinceStartup    
    
    local tip_str = ""
    local auction_way    = E_AuctionWay_MaxPrice       
    local auction_price = auction_goods.dwMaxPrice
    if auction_goods.dwAuctioner ~= pHero:GetNumProp(CREATURE_PROP_PDBID) then 
        tip_str = string.format("确定要花费%s银两一口价购买【%s】吗？", NumTo10Wan(auction_price), IGame.AuctionClient:GetAuctionGoodsName(goods_serial))
    else
        auction_price = auction_goods.dwMaxPrice - auction_goods.dwCurPrice
        tip_str = string.format("你当前出价最高（%s银两），确定增加%s银两一口价购买【%s】吗？", NumTo10Wan(auction_goods.dwCurPrice), NumTo10Wan(auction_price), IGame.AuctionClient:GetAuctionGoodsName(goods_serial))
    end
 
	local data = {
                        title    =  AssetPath.TextureGUIPath.."Exchanger/Exchange_jingjia.png",
                        content = tip_str,
                        confirmCallBack = function() IGame.AuctionClient:ReqJoinAuction(goods_serial, auction_way, auction_price) end,
                    }
	UIManager.ConfirmPopWindow:ShowDiglog(data)     
end

-- 正常竞拍按钮回调
function ExchangePaiMaiWidget:OnBtnAuction()
        
    if not self:AuctionRightCheck() then return end 
        
    local goods_serial = IGame.AuctionClient:GetCurSelectSerial()
    if not goods_serial or tonumber(goods_serial) <= 0 then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "先选择竞拍的物品！")
        return
    end 
    
    local auction_goods = IGame.AuctionClient:GetAuctionGoods(goods_serial)
    if not auction_goods then 
        return 
    end 
    
    if auction_goods.end_flag  then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "该竞品已结束拍卖！")
        return
    end 
    
    if auction_goods.nState == E_AuctionGoodsState_MaxPrice then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "该竞品已拍卖！")
        return 
    end     
    
    local auction_config = IGame.rktScheme:GetSchemeTable(AUCTION_CSV)
    if not auction_config then 
        uerror("[拍卖系统]刷新倒计时->获取配置失败！文件名："..AUCTION_CSV)
        return
    end

    local config = nil
    for j, data in pairs(auction_config) do
        config = data
    end
    if not config then return end 
    
    if IGame.EntityClient:GetZoneServerTime() < auction_goods.dwTime + config.PrepareTime then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "该竞品未开始竞拍！")
        return 
    end    
    
    local pHero = GetHero()
    if not pHero then return end 
    
    if self.m_nAuctionTime and Time.realtimeSinceStartup < self.m_nAuctionTime + 1 then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "操作过于频繁！")
        return
    end
    self.m_nAuctionTime = Time.realtimeSinceStartup    
    
    local auction_price = 0
    local bMaxAuction = false
    local auction_way = E_AuctionWay_Common
    if auction_goods.dwAuctioner == 0 then 
        auction_price = auction_goods.dwBasePrice
    else 
        if auction_goods.dwAuctioner == pHero:GetNumProp(CREATURE_PROP_PDBID) then 
             auction_price = auction_goods.dwAddPrice
            if auction_price + auction_goods.dwCurPrice >= auction_goods.dwMaxPrice then 
                 bMaxAuction = true   
                auction_way  = E_AuctionWay_MaxPrice
                 auction_price = auction_goods.dwMaxPrice - auction_goods.dwCurPrice  
            end
        else 
             auction_price = auction_goods.dwCurPrice + auction_goods.dwAddPrice
            if auction_price >= auction_goods.dwMaxPrice then 
                 bMaxAuction = true   
                 auction_way  = E_AuctionWay_MaxPrice
                 auction_price = auction_goods.dwMaxPrice
            end            
        end
    end 
    
    local tip_str = ""
    if not bMaxAuction then 
        tip_str = string.format("确定要花费%s银两参与【%s】的竞拍吗？", NumTo10Wan(auction_price), IGame.AuctionClient:GetAuctionGoodsName(goods_serial))
    else 
        tip_str = string.format("你的出价已经达到一口价（%s银两），是否一口价购买【%s】？", NumTo10Wan(auction_goods.dwMaxPrice), IGame.AuctionClient:GetAuctionGoodsName(goods_serial))
    end     
	local data = {
                        title    = AssetPath.TextureGUIPath.."Exchanger/Exchange_jingjia.png",
                        content = tip_str,
                        confirmCallBack = function() IGame.AuctionClient:ReqJoinAuction(goods_serial, auction_way, auction_price) end,
                    }
	UIManager.ConfirmPopWindow:ShowDiglog(data)       
end

-- 加价竞拍按钮回调
function ExchangePaiMaiWidget:OnBtnAddPriceAuction()
    
    if not self:AuctionRightCheck() then return end 
    
    local goods_serial = IGame.AuctionClient:GetCurSelectSerial()
    if not goods_serial or tonumber(goods_serial) <= 0 then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "先选择竞拍的物品！")
        return
    end 
    
    local auction_goods = IGame.AuctionClient:GetAuctionGoods(goods_serial)
    if not auction_goods then 
        return 
    end 
    
    if auction_goods.end_flag  then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "该竞品已结束拍卖！")
        return
    end 
    
    if auction_goods.nState == E_AuctionGoodsState_MaxPrice then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "该竞品已拍卖！")
        return 
    end     
    
    local auction_config = IGame.rktScheme:GetSchemeTable(AUCTION_CSV)
    if not auction_config then 
        uerror("[拍卖系统]刷新倒计时->获取配置失败！文件名："..AUCTION_CSV)
        return
    end

    local config = nil
    for j, data in pairs(auction_config) do
        config = data
    end
    if not config then return end 
    
    if IGame.EntityClient:GetZoneServerTime() < auction_goods.dwTime + config.PrepareTime then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "该竞品未开始竞拍！")
        return 
    end    
    
    local pHero = GetHero()
    if not pHero then return end 
    
    if self.m_nAuctionTime and Time.realtimeSinceStartup < self.m_nAuctionTime + 1 then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "操作过于频繁！")
        return
    end
    self.m_nAuctionTime = Time.realtimeSinceStartup
    
    if auction_goods.dwAuctioner ~= pHero:GetNumProp(CREATURE_PROP_PDBID) then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "商品竞价信息发生变化！") 
        self.Controls.m_btnJoinAuction.gameObject:SetActive(true)
        self.Controls.m_btnAddPrce.gameObject:SetActive(false)         
        return
    end
    
    local bMaxAuction    = false
    local auction_price = auction_goods.dwAddPrice
    local auction_way    = E_AuctionWay_AddPrice
    if auction_price + auction_goods.dwCurPrice >= auction_goods.dwMaxPrice then 
         bMaxAuction = true   
         auction_way  = E_AuctionWay_MaxPrice
         auction_price = auction_goods.dwMaxPrice - auction_goods.dwCurPrice  
    end    
    if auction_price < 0 then auction_price = 0 end 
    
    local tip_str = ""
    if not bMaxAuction then 
        tip_str = string.format("你当前出价最高（%s银两），确定增加%s银两竞拍【%s】吗？", NumTo10Wan(auction_goods.dwCurPrice), NumTo10Wan(auction_price), IGame.AuctionClient:GetAuctionGoodsName(goods_serial))
    else 
        tip_str = string.format("你当前出价最高（%s银两），确定增加%s银两一口价购买【%s】吗？", NumTo10Wan(auction_goods.dwCurPrice), NumTo10Wan(auction_price), IGame.AuctionClient:GetAuctionGoodsName(goods_serial))
    end     
	local data = {
                        title    = AssetPath.TextureGUIPath.."Exchanger/Exchange_jingjia.png",
                        content = tip_str,
                        confirmCallBack = function() IGame.AuctionClient:ReqJoinAuction(goods_serial, auction_way, auction_price) end,
                    }
	UIManager.ConfirmPopWindow:ShowDiglog(data)     
end 

-- 竞品EnhancedListView 一行被“创建”时的回调
function ExchangePaiMaiWidget:OnGoodsGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnRefreshGoodsCellView)
	self:CreateCellItems(listcell)
end

-- 竞品EnhancedListView 一行强制刷新时的回调
function ExchangePaiMaiWidget:OnRefreshGoodsCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshGoodsCellItems(listcell)
end

-- 竞品EnhancedListView 一行可见时的回调
function ExchangePaiMaiWidget:OnRefreshGoodsToggleCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshGoodsCellItems( listcell )
end

-- 创建条目
function ExchangePaiMaiWidget:CreateCellItems( listcell )
	
    local item = AuctionGoodsCellClass:new({})
	item:Attach(listcell.gameObject)
	item:SetToggleGroup(self.GoodsToggleGroup)
	table.insert(self.m_goodsCellItem, item)
    
	local idx = listcell.dataIndex + 1
	listcell.gameObject.name = string.format("AuctionGoodsListCell-%d",idx)
	
	self:RefreshGoodsCellItems(listcell)
end

--- 刷新竞品列表
function ExchangePaiMaiWidget:RefreshGoodsCellItems( listcell )	
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
		
    local idx = listcell.cellIndex + 1
    local sub_class = IGame.AuctionClient:GetAuctionSubClass()
    local goods_serial = IGame.AuctionClient:GetAuctionGoodsSerial(self.m_curSelectClass, sub_class, idx)   
    if not goods_serial then 
        uerror("[拍卖系统]刷新竞品列表->获取竞品序列号失败！self.m_curSelectClass, sub_class, idx = "..self.m_curSelectClass.."，"..sub_class.."，"..idx)
        return 
    end 
    
    local bFocus = (IGame.AuctionClient:GetCurSelectSerial() == goods_serial)
    local item = behav.LuaObject
	item:RefreshCellUI(idx, goods_serial, bFocus)
end

-- 选中竞品类型回调
function ExchangePaiMaiWidget:OnClassItemCellSelected(idx)
    
    if not self:isLoaded() then return end 
    
    if self.m_curSelectClass == idx then 
        local item = self.m_arrAuctionClassItem[idx+1]  
        if item then 
            local bShow = item:CheckSubItemPareatIsShow()  
            if bShow then 
                item:SetSubItemShow(true)
            else 
                item:SetSubItemShow(false)
            end
        end
    else 
        local item = self.m_arrAuctionClassItem[self.m_curSelectClass+1]  
        if item then 
            item:SetSubItemShow(false)
        end
        
        self.m_curSelectClass = idx 
        IGame.AuctionClient:SetAuctionType(self.m_curSelectClass)
        
        if not IGame.AuctionClient:GetTypeAuctionGoods(self.m_curSelectClass) then 
            -- 连空表都没有，向服务器问下
            IGame.AuctionClient:OpenUIReqEnterAuction() 
        end 
        
        item = self.m_arrAuctionClassItem[self.m_curSelectClass+1]
        if item then
            item:SetSubItemShow(true)
        end
    end
        
    -- 预估分红显示
    if self.m_curSelectClass == 0 then 
         self.Controls.m_imgDividend.gameObject:SetActive(true)   
    else 
        self.Controls.m_imgDividend.gameObject:SetActive(false)
    end
end

-- 显示窗口
function ExchangePaiMaiWidget:ShowWidget()

	UIControl.Show(self)	
end

-- 隐藏窗口
function ExchangePaiMaiWidget:HideWidget()
	
	UIControl.Hide(self, false)
end

return ExchangePaiMaiWidget