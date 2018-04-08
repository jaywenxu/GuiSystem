
--******************************************************************
--** 文件名:	RewardBackWdt.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-06-01
--** 版  本:	1.0
--** 描  述:	奖励回收
--** 应  用:  
--******************************************************************

local RewardBackItemClass = require("GuiSystem.WindowList.Welfare.RewardBack.RewardBackItem")

local RewardBackWdt = UIControl:new
{
	windowName = "RewardBackWdt",
	m_TlgGroup = nil,
	m_CurOption = 0,
	m_listScroller = nil,
	m_RbManager = nil,
}

function RewardBackWdt:Attach(obj)
	UIControl.Attach(self, obj)
	
	self:InitUI()
	
	self:SubscribeEvts()
	
	self:InitData()
	
	self:SetTipsInfo()
	
	self:SetMoneyInfo()
end

function RewardBackWdt:InitUI()
	local controls = self.Controls
	self.m_RecycleWdt  = require("GuiSystem.WindowList.Welfare.RewardBack.TimesSelectWdt")
	self.m_RecycleWdt:Attach(controls.m_Recycle.gameObject)

	local scrollView = controls.m_ItemList
	
	local listView = scrollView:GetComponent(typeof(EnhancedListView))
	listView.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
	listView.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)
	
	self.m_listView = listView
	self.m_listScroller = scrollView:GetComponent(typeof(EnhancedScroller))
	
	local listTglGroup = scrollView:GetComponent(typeof(ToggleGroup))
	self.m_TlgGroup = listTglGroup
	
	controls.m_AddBtn.onClick:AddListener(handler(self, self.OnAddMoney))
    
	controls.m_WdtClose.onClick:AddListener(handler(self, self.OnTimesClose))


	local Tgls = {
		controls.m_PerfectTgl,
		controls.m_NormalTgl,
	}
	
	for k, v in pairs(Tgls) do
		Tgls[k].onValueChanged:AddListener(function(on) self:OnOptionChanged(k, on) end)
	end
	
	self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))	
end

function RewardBackWdt:GetMoneyInfo()
    
    local nValue = 0
	local nImgPath = ""

    if self.m_CurOption == RB_OPTION.PERFECT then
        nValue = GetHero():GetActorYuanBao()
        nImgPath = RB_CostIconPath.YUANBAO
    else
        local nCurYinbiNum = GetHero():GetYinBiNum()
        local bCanUseYinbi = self.m_RbManager:CanUseMoney(nCurYinbiNum)
        
        local nCurYinLiangNum = GetHero():GetYinLiangNum()
        local bCanUseYinLiang = self.m_RbManager:CanUseMoney(nCurYinLiangNum)

        if bCanUseYinbi then
            nValue = GetHero():GetYinBiNum()
            nImgPath = RB_CostIconPath.YINBI
        else
            if bCanUseYinLiang then
                nValue = GetHero():GetYinLiangNum()
                nImgPath = RB_CostIconPath.YINLIANG
            else
                nValue = GetHero():GetYinBiNum()
                nImgPath = RB_CostIconPath.YINBI
            end
        end
    end
    
    return nValue, nImgPath
end

function RewardBackWdt:SetMoneyInfo()
	local controls = self.Controls

    local nNum, nImgPath = self:GetMoneyInfo()
	
	UIFunction.SetImageSprite(controls.m_MoneyIcon, nImgPath)
	
    local nValue = nNum / 10000
    local nDecimal = nValue % 1
    local nInteger = nValue - nDecimal
    
    local Txt = ""

    if nDecimal >= 0.1 then
		Txt = tostring(math.floor(nValue*10)*0.1).."万"
    else
		Txt = nInteger.."万"
    end
	
	if nInteger < 1 then
        Txt = nNum
    end
    
	controls.m_MoneyNum.text = Txt
end

function RewardBackWdt:InitData()
	
	self.m_CurOption = RB_OPTION.PERFECT
	
	GameHelp.PostServerRequest("RequestRecycleList()")
		
	self.m_RbManager = IGame.WelfareClient:GetRewardBackManager()
end

function RewardBackWdt:SubscribeEvts()
	-- 列表刷新
	self.m_UpdateListCB = function (_, _, _, evtData) self:OnUpdateListEvt(evtData) end
	rktEventEngine.SubscribeExecute( EVENT_WELFARE_UPDATE_RECYCLELIST , SOURCE_TYPE_WELFARE, 0, self.m_UpdateListCB )
	
	-- 货币刷新
	self.m_UpdateMoney = function (_, _, _, evtData) self:OnUpdateMoney(evtData) end 
	rktEventEngine.SubscribeExecute( EVENT_CION_YUANBAO , SOURCE_TYPE_COIN , 0, self.m_UpdateMoney)
	rktEventEngine.SubscribeExecute( EVENT_CION_YINLIANG , SOURCE_TYPE_COIN , 0, self.m_UpdateMoney)
end

function RewardBackWdt:UnSubscribeEvts()
	rktEventEngine.UnSubscribeExecute( EVENT_WELFARE_UPDATE_RECYCLELIST , SOURCE_TYPE_WELFARE, 0, self.m_UpdateListCB )
	self.m_UpdateListCB = nil
	
	rktEventEngine.UnSubscribeExecute( EVENT_CION_YUANBAO , SOURCE_TYPE_COIN , 0, self.m_UpdateMoney)
	rktEventEngine.UnSubscribeExecute( EVENT_CION_YINLIANG , SOURCE_TYPE_COIN , 0, self.m_UpdateMoney)
	self.m_UpdateMoney = nil

end

function RewardBackWdt:SetTlg()
	if self.m_CurOption == RB_OPTION.PERFECT then
		self.Controls.m_PerfectTgl.isOn = true
		self.Controls.m_NormalTgl.isOn = false
	else
		self.Controls.m_PerfectTgl.isOn = false
		self.Controls.m_NormalTgl.isOn = true
	end
end

function RewardBackWdt:OnEnable()
	
	self:InitData()
	
	self:SetTlg()
end

-- EnhancedListView 一行被创建时的回调
function RewardBackWdt:OnGetCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler(self, self.OnRefreshCellView)

	self:CreateCellItems(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function RewardBackWdt:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function RewardBackWdt:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end

-- 创建元素
function RewardBackWdt:CreateCellItems(listcell)
	local item = RewardBackItemClass:new({})
	item:Attach(listcell.gameObject)
	item:SetToggleGroup(self.m_TlgGroup)
	item:SetGainBtnCallbak(handler(self, self.OnGainBtnClicked))

end

-- 刷新元素
function RewardBackWdt:RefreshCellItems(listcell)
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		uerror("Error： UI Window Behaviour")
		return
	end
	
	local item = behav.LuaObject
	if item == nil then
		uerror("RewardBackWdt:RefreshCellItems item为空")
		return
	end
	
	if nil ~= item and item.windowName == "RewardBackItem" then 
		local idx = listcell.dataIndex + 1
		item:SetItemInfo(self.m_CurOption, idx)
	end
end

function RewardBackWdt:OnAddMoney()
	if self.m_CurOption == RB_OPTION.PERFECT then
		UIManager.ShopWindow:ShowShopWindow(UIManager.ShopWindow.tabName.emDeposit)
	else
		UIManager.ShopWindow:OpenShop(2415)
	end
end

function RewardBackWdt:SetTipsInfo()
	if self.m_CurOption  == RB_OPTION.PERFECT then
		self.m_CurOption = RB_OPTION.PERFECT
		self.Controls.m_Tips.text = "完美找回可找回100%的经验, 全部道具"
	else
		self.m_CurOption = RB_OPTION.NORMAL
		self.Controls.m_Tips.text = "普通找回可找回70%的经验, 部分道具"
	end
end

function RewardBackWdt:OnOptionChanged(index, on)
	if not on then
		return
	end
    	
	self.m_CurOption = index
	
	self:SetTipsInfo()
	
	self:SetMoneyInfo()
	
	self.m_listScroller:ReloadData()
end

function RewardBackWdt:OnGainBtnClicked(idx)
	self.m_RecycleWdt:SetCurState(self.m_CurOption, idx)
	self.m_RecycleWdt:Show()
end

function RewardBackWdt:OnUpdateListEvt()

	local ncellCount = self.m_listView.CellCount
	local nRecycleCnt = self.m_RbManager:GetRecycleCnt()
	if ncellCount == nRecycleCnt then
		self.m_listScroller:RefreshActiveCellViews()
	else
		self.m_listView:SetCellCount( nRecycleCnt , true )
	end
end

function RewardBackWdt:OnTimesClose()
   	self.m_RecycleWdt:Hide() 
end

function RewardBackWdt:OnUpdateMoney()
	self:SetMoneyInfo()
end

function RewardBackWdt:OnDestroy()
	self:UnSubscribeEvts()
end

return RewardBackWdt