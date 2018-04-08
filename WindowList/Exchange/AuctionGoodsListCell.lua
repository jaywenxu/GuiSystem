--================AuctionGoodsListCell.lua=============================
-- @author	Jack Miao
-- @desc	竞品信息
-- @date	2017.12.13
--================AuctionGoodsListCell.lua=============================

local AuctionGoodsListCell = UIControl:new
{
	windowName         = "AuctionGoodsListCell",
	m_CellIndex       = 0, 
    m_goodsSerial    = "0",
	m_SelectedCallback = nil,
	m_TglChangedCallback = nil,
    m_registerFlag       = false,
}

local this = AuctionGoodsListCell
------------------------------------------------------------

function AuctionGoodsListCell:Attach(obj)
	UIControl.Attach(self,obj)

    self.OnShowGoodsTipsClick = function() self:OnShowGoodsTips() end 
    self.Controls.m_BtnGoodsTips.onClick:AddListener(self.OnShowGoodsTipsClick)    
    
 	self.m_TglChangedCallback = function(on) self:OnSelectChanged(on) end
	self.Controls.m_Toggle.onValueChanged:AddListener(self.m_TglChangedCallback)
    
    self.callbackOnEnable = function() self:OnEnable() end
	self.unityBehaviour.onEnable:AddListener(self.callbackOnEnable) 	
    
	self.callbackOnDisable = function() self:OnDisable() end
	self.unityBehaviour.onDisable:AddListener(self.callbackOnDisable)  

    self:OnEnable()   
end

function AuctionGoodsListCell:OnEnable()
    
    if not self.m_registerFlag then 
        self.OnUpdateGoodsPrice = function(event, srctype, srcid,eventData) self:UpdateGoodsPrice(eventData) end
        rktEventEngine.SubscribeExecute(EVENT_UI_AUCTION_UPDATE_PRICE , SOURCE_TYPE_AUCTION , 0 , self.OnUpdateGoodsPrice)           
        self.m_registerFlag = true
    end
end 

function AuctionGoodsListCell:OnDisable()
    
    self.Controls.m_BtnGoodsTips.onClick:RemoveListener(self.OnShowGoodsTipsClick)
    self.Controls.m_Toggle.onValueChanged:RemoveListener(self.m_TglChangedCallback)
    if self.OnUpdateGoodsPrice then 
        rktEventEngine.UnSubscribeExecute( EVENT_UI_AUCTION_UPDATE_PRICE , SOURCE_TYPE_AUCTION , 0, self.OnUpdateGoodsPrice)   
    end
    self.m_registerFlag = false
end 

function AuctionGoodsListCell:OnShowGoodsTips()
    
    local auction_goods = IGame.AuctionClient:GetAuctionGoods(self.m_goodsSerial)
    if not auction_goods then return end 
    
	local goodsScheme = IGame.rktScheme:GetSchemeInfo(AUCTION_GOODS_CSV, auction_goods.nGoods)
	if not goodsScheme then
		uerror("[拍卖系统]查找物品配置失败！物品ID: " .. auction_goods.nGoods )
		return
	end

	if goodsScheme.class ~= GOODS_CLASS_EQUIPMENT  then
		UIManager.GoodsTooltipsWindow:Show(true)
		local subInfo = {
			bShowBtnType	= 0, 	--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
			bBottomBtnType	= 1,
			ScrTrans = self.Controls.m_BtnGoodsTips.transform,	-- 源预设
		}
		UIManager.GoodsTooltipsWindow:SetGoodsInfo(auction_goods.nGoods, subInfo ) 
		return
	end 

    local equip_uid = IGame.AuctionClient:GetEquipUIDByAuctionGoodsSerial()
	if equip_uid then
		local entity = IGame.EntityClient:GetDeceitEntity(equip_uid)
		if entity ~= nil then
			ExchangeWindowTool.ClickEntityItem(entity, self.Controls.m_BtnGoodsTips.transform)
			return
		end
	end
    
    -- 请求服务器获取装备信息
   IGame.AuctionClient:ReqAuctionGoodsEquipTipsInfo(self.m_goodsSerial, self.Controls.m_BtnGoodsTips.transform)
end 

function AuctionGoodsListCell:UpdateGoodsPrice(eventData)
    
    if not self:isLoaded() or not self:isShow() then return end
    
    if not eventData or not GetHero() then return end 
    
    if eventData.goods_serial ~= self.m_goodsSerial then return end 
    
    self.Controls.m_AuctionPriceTxt.text = NumTo10Wan(eventData.dwCurPrice)
    
    if GetHero():GetNumProp(CREATURE_PROP_PDBID) == eventData.dwAuctioner then 
        self.Controls.m_MyAuctionTip.gameObject:SetActive(true)
        self.Controls.m_AuctionPriceTxt.color = UIFunction.ConverRichColorToColor("c67764")
        self.Controls.m_MaxAuctionPriceTxt.color = UIFunction.ConverRichColorToColor("c67764")
        self.Controls.m_RestTimeTxt.color    =    UIFunction.ConverRichColorToColor("c67764")
        self.Controls.m_GoodsNameTxt.color  =  UIFunction.ConverRichColorToColor("c67764")          
    else 
        self.Controls.m_MyAuctionTip.gameObject:SetActive(false)        
        self.Controls.m_AuctionPriceTxt.color = UIFunction.ConverRichColorToColor("597993")
        self.Controls.m_MaxAuctionPriceTxt.color = UIFunction.ConverRichColorToColor("597993")
        self.Controls.m_RestTimeTxt.color    =    UIFunction.ConverRichColorToColor("597993")   
    end
    
    if eventData.nState == E_AuctionGoodsState_MaxPrice then 
        self.Controls.m_ctrlAuctioned.gameObject:SetActive(true)  
        self.Controls.m_ctrlRestTime.gameObject:SetActive(false)         
    else 
        self.Controls.m_ctrlAuctioned.gameObject:SetActive(false)  
        self.Controls.m_ctrlRestTime.gameObject:SetActive(true) 
    end
end 

function AuctionGoodsListCell:OnDestroy()
    
    if self.OnUpdateGoodsPrice then 
        rktEventEngine.UnSubscribeExecute( EVENT_UI_AUCTION_UPDATE_PRICE , SOURCE_TYPE_AUCTION , 0, self.OnUpdateGoodsPrice)   
    end    
    self.m_registerFlag = false
	self.m_SelectedCallback = nil
	UIControl.OnDestroy(self)
end

-- 刷新cell item 
function AuctionGoodsListCell:RefreshCellUI(idx, goods_serial, bFocus)
    
    if goods_serial == nil then return end 
    
    self.m_CellIndex = idx
    self.m_goodsSerial = goods_serial
    
    local auction_goods = IGame.AuctionClient:GetAuctionGoods(self.m_goodsSerial)
    if not auction_goods then return end 
    
    local auction_price = auction_goods.dwCurPrice
    if auction_price <= 0 then auction_price = auction_goods.dwBasePrice end 
    self.Controls.m_AuctionPriceTxt.text = NumTo10Wan(auction_price or 0)
    self.Controls.m_MaxAuctionPriceTxt.text = NumTo10Wan(auction_goods.dwMaxPrice or 0)
    
    -- 时间显示
    self:RefreshTimeCD()
   
    self:SetToggleOn(bFocus)
    
    -- 道具显示
	local goodsScheme = IGame.rktScheme:GetSchemeInfo(AUCTION_GOODS_CSV, auction_goods.nGoods)
	if not goodsScheme then
		return
	end
		
	if goodsScheme.class == GOODS_CLASS_EQUIPMENT  then
        -- 装备
		local equipScheme = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, auction_goods.nGoods)
		if not equipScheme then
			return
		end
		
		local bgPath = GameHelp.GetEquipImageBgPath(auction_goods.nQuality, auction_goods.nAttrNum)
		if not bgPath then
			return
		end
		
		UIFunction.SetImageSprite(self.Controls.m_IconImg, AssetPath.TextureGUIPath..equipScheme.IconIDNormal)
		UIFunction.SetImageSprite(self.Controls.m_QualityImg, bgPath)
        
		local szNameTemp = GameHelp.GetEquipName(auction_goods.nQuality, auction_goods.nAttrNum, equipScheme.szName)
		self.Controls.m_GoodsNameTxt.text = szNameTemp
		
        local signColor = DColorDef.getNameColor(1,auction_goods.nQuality,auction_goods.nAttrNum)
        local color_str = string.sub(signColor, 1, #signColor-2)
		self.Controls.m_GoodsNameTxt.color = UIFunction.ConverRichColorToColor(color_str)        
    else
        -- 物品
        local leechdomScheme = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, auction_goods.nGoods)
        if not leechdomScheme then
            return
        end

        UIFunction.SetImageSprite(self.Controls.m_IconImg, AssetPath.TextureGUIPath..leechdomScheme.lIconID1)
        UIFunction.SetImageSprite(self.Controls.m_QualityImg, AssetPath.TextureGUIPath..leechdomScheme.lIconID2)   
        
        self.Controls.m_GoodsNameTxt.text = leechdomScheme.szName
        self.Controls.m_GoodsNameTxt.color = UIFunction.GetQualityColor(leechdomScheme.lBaseLevel)           
	end
    
    if auction_goods.dwAuctioner == GetHero():GetNumProp(CREATURE_PROP_PDBID) then 
        self.Controls.m_MyAuctionTip.gameObject:SetActive(true)
        self.Controls.m_AuctionPriceTxt.color = UIFunction.ConverRichColorToColor("c67764")
        self.Controls.m_MaxAuctionPriceTxt.color = UIFunction.ConverRichColorToColor("c67764")
        self.Controls.m_RestTimeTxt.color    =    UIFunction.ConverRichColorToColor("c67764")
        self.Controls.m_GoodsNameTxt.color  =  UIFunction.ConverRichColorToColor("c67764")         
    else 
        self.Controls.m_MyAuctionTip.gameObject:SetActive(false)        
        self.Controls.m_AuctionPriceTxt.color = UIFunction.ConverRichColorToColor("597993")
        self.Controls.m_MaxAuctionPriceTxt.color = UIFunction.ConverRichColorToColor("597993")
        self.Controls.m_RestTimeTxt.color    =    UIFunction.ConverRichColorToColor("597993") 
    end 

    if auction_goods.nState == E_AuctionGoodsState_MaxPrice then 
        self.Controls.m_ctrlAuctioned.gameObject:SetActive(true)  
        self.Controls.m_ctrlRestTime.gameObject:SetActive(false)         
    else 
        self.Controls.m_ctrlAuctioned.gameObject:SetActive(false)  
        self.Controls.m_ctrlRestTime.gameObject:SetActive(true) 
    end
end 

-- 获取选中的idx
function AuctionGoodsListCell:GetSelCellIdx()	
	return  self.m_CellIndex
end

-- 设置选中的toggle 选中/取消选中
function AuctionGoodsListCell:SetToggleOn(isOn)	
	if not self:isLoaded() then
		return
	end

	self.Controls.m_Toggle.isOn = isOn
end

-- 设置选中回调
function AuctionGoodsListCell:SetSelectCallback( func_cb )
	self.m_SelectedCallback = func_cb
end

-- 设置toggle group
function AuctionGoodsListCell:SetToggleGroup(toggleGroup)
    self.Controls.m_Toggle.group = toggleGroup
end

function AuctionGoodsListCell:OnRecycle()	
    
    self.Controls.m_BtnGoodsTips.onClick:RemoveListener(self.OnShowGoodsTipsClick)
	self.Controls.m_Toggle.onValueChanged:RemoveListener(self.m_TglChangedCallback)
	self.m_SelectedCallback = nil

	UIControl.OnRecycle(self)
end

function AuctionGoodsListCell:OnSelectChanged(on)

	if  on then
		IGame.AuctionClient:SetCurSelectSerial(self.m_goodsSerial)     
        local event_data = {}   
        event_data.GoodsSerial = self.m_goodsSerial
        rktEventEngine.FireEvent(EVENT_UI_AUCTION_UPDATE_BUTTON, SOURCE_TYPE_AUCTION, 0, event_data)    
	end
end

-- 刷新倒计时
function AuctionGoodsListCell:RefreshTimeCD()
    
    if not self:isLoaded() then return end 
    
    local auction_goods = IGame.AuctionClient:GetAuctionGoods(self.m_goodsSerial)
    if not auction_goods  then 
        uerror("[拍卖系统]刷新倒计时->获取竞品数据失败！序列号："..self.m_goodsSerial)
        return 
    end 
    
    -- 过滤已拍卖的竞品
    if auction_goods.nState == E_AuctionGoodsState_MaxPrice then 
        return
    end 
    
    local now_time = IGame.EntityClient:GetZoneServerTime()
    if now_time < auction_goods.dwTime then      
        -- 注：允许一点误差，毕竟客户端服务器的时间不是绝对一致的
        if math.abs(now_time - auction_goods.dwTime) <= 3 then 
            now_time = auction_goods.dwTime
        else 
            uerror("[拍卖系统]刷新倒计时->客户端拟算服务器时间小于竞品产生时间异常！now_time, auction_goods.dwTime = "..tostring(now_time).."，"..tostring(auction_goods.dwTime ))
        end
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
    
    if now_time < auction_goods.dwTime + config.PrepareTime then 
        local sec_count = auction_goods.dwTime + config.PrepareTime - now_time
        self.Controls.m_RestTimeTxt.text = SecondTimeToString_HMS(sec_count).." 开始"
    else                     
        local RestSec  = 0
        local tmSettleTime = os.date("*t", auction_goods.nSettleTime)  
        -- 注：服务器下发结算时间减去了60秒
        if (auction_goods.nSettleTime+60) <  auction_goods.dwTime  + config.AheadTime then
            local interval = 0
            local total_sec = tmSettleTime.hour*3600 + tmSettleTime.min*60 + tmSettleTime.sec
            local bargin = config.ClanBargain
            if IGame.AuctionClient:GetAuctionType() ~= emAuction_Clan then 
                bargin = config.GlobalBargain
            end      
            for idx, time_min in ipairs(bargin) do 
                -- 注：允许一点误差，毕竟客户端服务器的时间不是绝对一致的
                if math.abs(total_sec - time_min*60) <= 3 then 
                    if config.ClanBargain[idx+1] then 
                         interval = (bargin[idx+1] - time_min)*60
                    else
                         interval = (24*60-time_min)*60 + bargin[1]*60
                    end
                    break
                end
            end  
            RestSec = auction_goods.nSettleTime - now_time + interval
        else 
            RestSec = auction_goods.nSettleTime - now_time             
        end         
        if RestSec < 0 then RestSec = 0 end
        
        if RestSec <= 0 then 
            if not auction_goods.end_flag then 
                -- 注:加个结束的标记
                auction_goods.end_flag = true    
            end
            self.Controls.m_RestTimeTxt.text = "  已结束"
        else 
            self.Controls.m_RestTimeTxt.text = SecondTimeToString_HMS(RestSec)
        end        
    end    
end

return this



