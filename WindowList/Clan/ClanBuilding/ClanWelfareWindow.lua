-- 帮会福利殿的窗口
-- @Author: LiaoJunXi
-- @Date:   2017-09-06 19:36:57
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-22 12:22:48

local ClanWelfareWindow = UIWindow:new
{
	windowName        = "ClanWelfareWindow",
	
	m_Presenter = nil,
	m_WageCells = {}, -- 当前显示的活动项缓存
	m_RefreshUICallback = nil,
	m_RefreshGiftCallback = nil,
	m_RefreshDonateCallback = nil,
	m_SelCellIdx = 1, --当前选择的活动格
	m_HandleCellIdx = 0, --当前前往(领取)的活动格
	m_DonateCount = 1,
	m_CallCount = 0,
	m_ReceiveClicked = false,
	
	m_OnGiftHintStatus = nil,
}

require("GuiSystem.WindowList.Clan.ClanSysDef")
local UIClanWageCell = require(ClanSysDef.ClanBuildingPath .. "ClanWageCell")
local UIContainor = require( "GuiSystem.UIContainer" )

-----------------------------公共重载方法-------------------------------
function ClanWelfareWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.m_Presenter = IGame.ClanBuildingPresenter
	
	self:SubscribeEvts()
	self:InitUI()
	self:ShowUI()
end

function ClanWelfareWindow:SubscribeEvts()
	self.m_RefreshUICallback = handler(self, self.RefreshUI)
	rktEventEngine.SubscribeExecute( EVENT_CLAN_WAGE_LIST_REFRESH, SOURCE_TYPE_CLAN, 0, self.m_RefreshUICallback)
	self.m_RefreshGiftCallback = handler(self, self.RefreshGiftWidget)
	rktEventEngine.SubscribeExecute( EVENT_CLAN_WELFARC_GIFT_REFRESH, SOURCE_TYPE_CLAN, 0, self.m_RefreshGiftCallback)
	self.m_RefreshDonateCallback = handler(self, self.RefreshDonateWidget)
	rktEventEngine.SubscribeExecute( EVENT_CLAN_WELFARC_DONATE_REFRESH, SOURCE_TYPE_CLAN, 0, self.m_RefreshDonateCallback)
end

function ClanWelfareWindow:UnSubscribeEvts()
	rktEventEngine.UnSubscribeExecute(EVENT_CLAN_WAGE_LIST_REFRESH , SOURCE_TYPE_CLAN, 0, self.m_RefreshUICallback)
	rktEventEngine.UnSubscribeExecute(EVENT_CLAN_WELFARC_GIFT_REFRESH , SOURCE_TYPE_CLAN, 0, self.m_RefreshGiftCallback)
	rktEventEngine.UnSubscribeExecute(EVENT_CLAN_WELFARC_DONATE_REFRESH , SOURCE_TYPE_CLAN, 0, self.m_RefreshDonateCallback)
	
	local nParentLayout = self.m_Presenter:GetLayout()["建筑分页"]["福利按钮"]
	SysRedDotsMgr.Cancel(nParentLayout,"礼包领取","m_ReceiveBtn",self.m_OnGiftHintStatus)
end

function ClanWelfareWindow:InitUI()
	local controls = self.Controls

	-- init list tgl group, cell prefab
	local scrollView  = controls.m_WageScrollView
	controls.listTglGroup  = scrollView:GetComponentInChildren(typeof(ToggleGroup))	
	controls.m_WageCellContainer = scrollView.content
	------------------------------------------------
	
	-- BtnFunc for <Donate> and <Receive>
	controls.m_DonateBtn.onClick:AddListener(handler(self, self.OnBtnDonateClicked))
	controls.m_ReceiveBtn.onClick:AddListener(handler(self, self.OnBtnReceiveClicked))
	-- Item BtnFunc
	controls.m_BillBtn.onClick:AddListener(handler(self, self.OnBillItemClick))
	controls.m_GiftBtn.onClick:AddListener(handler(self, self.OnGiftItemClick))
	
	-- Donate Detail Dialog ------------------
	self.m_DonateDetailDialog = UIContainor:new({})
	self.m_DonateDetailDialog.windowName = "DonateDetailDialog"
	self.m_DonateDetailDialog:Attach(controls.m_DonateDetailDialog.gameObject)
	self.m_DonateCountInput = self.m_DonateDetailDialog.Controls.m_DonateCountInput.transform:GetComponent(typeof(InputField))
	self.m_DonateCountInput.onEndEdit:AddListener(handler(self, self.OnDonateInputEndEdit))
	self.m_DonateDetailDialog.Controls.m_CountInputBtn.onClick:AddListener(handler(self, self.OnBtnCountInputClicked))
	
	-- BtnFunc for <Confirm> <Cancel> and <AddSilver>
	self.m_DonateDetailDialog.Controls.m_ConfirmBtn.onClick:AddListener(handler(self, self.OnBtnConfirmClicked))
	self.m_DonateDetailDialog.Controls.m_CancelBtn.onClick:AddListener(handler(self, self.OnBtnCancelClicked))
	self.m_DonateDetailDialog.Controls.m_AddSilverBtn.onClick:AddListener(handler(self, self.OnBtnAddSilverClicked))
	self.m_DonateDetailDialog.Controls.m_ReduceSilverBtn.onClick:AddListener(handler(self, self.OnBtnReduceSilverClicked))
	self.m_DonateDetailDialog.Controls.m_MaxSilverBtn.onClick:AddListener(handler(self, self.OnBtnMaxSilverClicked))
	self.m_DonateDetailDialog.Controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnDetailCloseClicked))
	------------------------------------------------
	
	-- 计时器
	self.updateTimerFunc = function() self:UpdateTime() end
	
	-- 注册红点事件
	local nParentLayout = self.m_Presenter:GetLayout()["建筑分页"]["福利按钮"]
	self.m_OnGiftHintStatus = handler(self, self.OnGiftHintStatus)
	SysRedDotsMgr.Register(nParentLayout,"礼包领取",controls.m_ReceiveBtn,"m_ReceiveBtn",self.m_OnGiftHintStatus)
	--SysRedDotsMgr.RegisterCreation(nParentLayout,"工资领取",handler(self, self.OnWageHintStatus))
end

------------------------------------------------
-- 红点事件 ------------------------------------
function ClanWelfareWindow:OnGiftHintStatus()
	if nil == self.m_Presenter then
		return
	end
	local baseLayout = self.m_Presenter:GetBaseLayout()
	local partLayout = self.m_Presenter:GetLayout()
	local nParentLayout = partLayout["建筑分页"]["福利按钮"]
	
	local currentTime = os.time()
	if self.m_ReceiveClicked then
		self.m_Presenter.m_Welfare.m_Obj.m_nGiftLastTime = os.time()
		self.m_ReceiveClicked = false
	end
	local nInterval = currentTime - self.m_Presenter.m_Welfare.m_Obj.m_nGiftLastTime
	print("ClanWelfareWindow:nInterval = "..nInterval)
	
	local nSurplusCount = self.m_Presenter.m_Welfare.m_SurplusDonaCount
	local nCfgInterval = self.m_Presenter.m_Welfare.m_GiftCfg.nInterval
	local result = nSurplusCount > 0 and nInterval > nCfgInterval
	SysRedDotsMgr.SetVisible(nParentLayout,"礼包领取","m_ReceiveBtn",result)
	
	local controls = self.Controls
	UIFunction.SetComsGray(controls.m_ReceiveBtn.gameObject, not result, {typeof(Image)})
	controls.m_GiftCDTime.text = GetValuable(result or nSurplusCount <= 0, "", SecondTimeToString(nCfgInterval-nInterval))
	print("还需"..(nCfgInterval-nInterval).."秒，才可以领取礼包")
	controls.m_GiftCDTime.gameObject:SetActive(not result and nSurplusCount > 0)
	
	result = self.m_Presenter:IsUnclaimed()
	SysRedDotsMgr.Assert(baseLayout,partLayout["建筑分页"],"福利按钮",result)
	
	self.m_Presenter:UpdateClanBtnRetDotState(result)
	
	-- 启动倒计时
	rktTimer.KillTimer(self.updateTimerFunc)
	if nInterval < nCfgInterval and nSurplusCount > 0 then
		self.m_CallCount = nCfgInterval - nInterval
		rktTimer.SetTimer( self.updateTimerFunc, 1000, self.m_CallCount, "ClanWelfareWindow:UpdateTime")
	end
end

function ClanWelfareWindow:CheckGiftHintStatus()
	local nParentLayout = self.m_Presenter:GetLayout()["建筑分页"]["福利按钮"]
	SysRedDotsMgr.Check(nParentLayout,"礼包领取")
end

function ClanWelfareWindow:UpdateTime()
	local currentTime = os.time()
	local nInterval = currentTime - self.m_Presenter.m_Welfare.m_Obj.m_nGiftLastTime
	local nCfgInterval = self.m_Presenter.m_Welfare.m_GiftCfg.nInterval
	local controls = self.Controls
	if nInterval >= nCfgInterval then
		SysRedDotsMgr.SetVisible(nParentLayout,"礼包领取","m_ReceiveBtn",true)
		
		UIFunction.SetComsGray(controls.m_ReceiveBtn.gameObject, false, {typeof(Image)})
		
		controls.m_GiftCDTime.text = ""
		controls.m_GiftCDTime.gameObject:SetActive(false)
		
		result = self.m_Presenter:IsUnclaimed()
		SysRedDotsMgr.Assert(baseLayout,partLayout["建筑分页"],"福利按钮",result)
		self.m_Presenter:UpdateClanBtnRetDotState(result)
		
		rktTimer.KillTimer(self.updateTimerFunc)
	else
		controls.m_GiftCDTime.text = SecondTimeToString(nCfgInterval-nInterval)
	end
end
------------------------------------------------

-- 界面销毁
function ClanWelfareWindow:OnDestroy()
	print("ClanWelfareWindow:OnDestroy")
	self:UnSubscribeEvts()
	self.m_Presenter.isUIWelfareOpened = false
	self.m_Presenter = nil
	self.m_RefreshUICallback = nil
	self.m_RefreshGiftCallback = nil
	self.m_RefreshDonateCallback = nil
	
	UIWindow.OnDestroy(self)
	table_release(self)
	
	self.m_SelCellIdx = 1
	self.m_DonateCount = 1
end

----------------------- 刷新UI -------------------------
function ClanWelfareWindow:RefreshUI()
	if not self:isShow() then
		return
	end
	if self.m_HandleCellIdx == 0 then
		--self:DestroyWageCells()
		self:CreateWageCells()
	else
		local idx = self.m_HandleCellIdx
		self:RefreshWageCell(idx)
		self.m_HandleCellIdx = 0
	end
	
	self:RefreshGiftWidget()
	self:RefreshDonateWidget()
end

-- 销毁Skill Cell List的所有Cell，释放table
function ClanWelfareWindow:DestroyWageCells()
	for i,cell in pairs(self.m_WageCells) do
		cell:Destroy()
	end
	self.m_WageCells = {}
end

-- Wage Cell List
function ClanWelfareWindow:CreateWageCells()
	local wageList = self.m_Presenter:GetWageDataList()
	if not wageList then return end
	local count = #wageList

	for i=1, count do
		local cell = self.m_WageCells[i]
		if not cell then
			rkt.GResources.FetchGameObjectAsync( GuiAssetList.ClanBuilding.ClanWageCell,
				function ( path , obj , ud ) 
					local controls = self.Controls
					
					obj.transform:SetParent(controls.m_WageCellContainer)
					obj.transform.localScale = Vector3.New(1,1,1)
					
					cell = UIClanWageCell:new({})
					cell:Attach(obj)
					table.insert(self.m_WageCells,i,cell)
					
					cell:SetToggleGroup(controls.listTglGroup)
					cell:SetSelectCallback(handler(self, self.OnItemCellSelected))
					cell:SetHandleCallback(handler(self, self.OnItemCellHandle))
					
					self:RefreshWageCell(i, cell)
				end , 
			i , AssetLoadPriority.GuiNormal )
		else
			self:RefreshWageCell(i, cell)	
		end
	end
end

-- 刷新 Skill Cell
function ClanWelfareWindow:RefreshWageCell(idx, cell)
	if not cell then cell = self.m_WageCells[idx] end
	cell:SetCellData(idx, self.m_Presenter:GetWageData(idx))
	
	if self.m_SelCellIdx == 0 then
		self.m_SelCellIdx = 1
	end
	if idx == self.m_SelCellIdx and cell:IsToggleOn() then
		self:OnItemCellSelected(idx)
	end
	cell:SetToggleIsOn(idx == self.m_SelCellIdx)
end

-- 刷新礼包
function ClanWelfareWindow:RefreshGiftWidget()
	local nWelfare = self.m_Presenter.m_Welfare
	local controls = self.Controls
	controls.m_GiftCount.text = nWelfare.m_SurplusGiftCount .. "/" .. nWelfare.m_GiftCfg.nTimes
	
	self:ShowGiftItem()
	
	self:CheckGiftHintStatus()
end

function ClanWelfareWindow:ShowGiftItem()
	local controls = self.Controls
	if self.m_Presenter.ClanWelfare then
		local nLevel = self.m_Presenter.ClanWelfare.nLevel
		local schemeInfo = IGame.rktScheme:GetSchemeInfo(CLANBUILDING_WELFARE_GIFT_CSV, nLevel)
		if schemeInfo then
			schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, schemeInfo.nGoodsID)
			if schemeInfo then
				local iconPath = schemeInfo.lIconID1
				if not IsNilOrEmpty(iconPath) then	
					UIFunction.SetImageSprite(controls.m_GiftIcon, GuiAssetList.GuiRootTexturePath .. iconPath)
				end
				local qualityPath = schemeInfo.lIconID2
				if not IsNilOrEmpty(qualityPath) then	
					UIFunction.SetImageSprite(controls.m_GiftRect, GuiAssetList.GuiRootTexturePath .. qualityPath)
				end
			end
		end
	end
end

-- 刷新贡献
function ClanWelfareWindow:RefreshDonateWidget()
	if nil == self.m_Presenter then
		return
	end
	local nWelfare = self.m_Presenter.m_Welfare
	local controls = self.Controls
	controls.m_DonateCount.text = nWelfare.m_SurplusDonaCount .. "/" .. nWelfare.m_DonateMaxTimes
	
	local sliverCost = self.m_Presenter:GetTotalSliverCost(self.m_DonateCount)
	local mySliver = IGame.EntityClient:GetHero():GetYinLiangNum()
	local colorStr = GetValuable(mySliver < sliverCost, "<color=#E4595AFF>%d</color>", "%d")
	
	controls.m_CostDesc.text = "消耗"..string.format(colorStr, sliverCost) .."银两"
	controls.m_BillCount.text = tostring(self.m_Presenter:GetTotalBillReward(self.m_DonateCount))
	
	self:ShowBillItem()
end

function ClanWelfareWindow:ShowBillItem()
	local controls = self.Controls
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, 9016)
	if schemeInfo then
		local iconPath = schemeInfo.lIconID1
		if not IsNilOrEmpty(iconPath) then	
			UIFunction.SetImageSprite(controls.m_BillIcon, GuiAssetList.GuiRootTexturePath .. iconPath)
		end
		local qualityPath = schemeInfo.lIconID2
		if not IsNilOrEmpty(qualityPath) then	
			UIFunction.SetImageSprite(controls.m_BillRect, GuiAssetList.GuiRootTexturePath .. qualityPath)
		end
	end
end

-- 刷新贡献弹出框
function ClanWelfareWindow:RefreshDonateDetailDialog()
	if nil == self.m_Presenter then
		return
	end
	
	local nWelfare = self.m_Presenter.m_Welfare
	local controls = self.m_DonateDetailDialog.Controls
	controls.m_SurplusCount.text = tostring(nWelfare.m_SurplusDonaCount)
	self.m_DonateCountInput.text = tostring(self.m_DonateCount)
	
	local sliverCost = self.m_Presenter:GetTotalSliverCost(self.m_DonateCount)
	local mySliver = IGame.EntityClient:GetHero():GetYinLiangNum()
	local colorStr = GetValuable(mySliver < sliverCost, "<color=#E4595AFF>%d</color>", "%d")
	
	controls.m_TotalSilver.text = string.format(colorStr, sliverCost)
	controls.m_TotalBill.text = tostring(self.m_Presenter:GetTotalBillReward(self.m_DonateCount))
	
	self:OnBtnAddOrReduceColor()
end

-----------------------界面响应事件方法-------------------------
-- 显示窗口
function ClanWelfareWindow:ShowWindow()
	print("ClanWelfareWindow:ShowWindow")
	UIWindow.Show(self, true)
	UIManager.ClanOwnWindow.CommonWindowWidget.closeCallback = handler(self, self.OnBtnCloseClicked)
	if not self:isLoaded() then
		return
	end
	self:ShowUI()
end

function ClanWelfareWindow:ShowUI()
	self.m_Presenter.isUIWelfareOpened = true
	self.m_Presenter.isUIWelfareClicked = false
	
	self:RefreshUI()
end

-- 选中建筑Cell后，Cell的Toggle回调
function ClanWelfareWindow:OnItemCellSelected(idx)
	local data = self.m_Presenter:GetWageData(idx)
	if not data then self.m_SelCellIdx = 1 return end
	
	self.m_SelCellIdx = idx
end

function ClanWelfareWindow:OnItemCellHandle(idx)
	local data = self.m_Presenter:GetWageData(idx)
	if not data then self.m_HandleCellIdx = 0 return end
	
	self.m_HandleCellIdx = idx
end

-- 界面隐藏
function ClanWelfareWindow:OnBtnCloseClicked()
	self:Hide()
	
	local owenWin = UIManager.ClanOwnWindow
	UIManager.ClanOwnWindow.CommonWindowWidget.closeCallback = handler(owenWin, owenWin.Hide)
	
	self:OnBtnDetailCloseClicked()
end

function ClanWelfareWindow:Hide(destory)
	rktTimer.KillTimer(self.updateTimerFunc)
	
	UIWindow.Hide(self, destory)
end

-- 领取礼包
function ClanWelfareWindow:OnBtnReceiveClicked()
	self.m_Presenter.m_BuildingModel.m_WelfareObj:RecvGiftRsq()
	self.m_ReceiveClicked = true
end

function ClanWelfareWindow:OnGiftItemClick()
	if self.m_Presenter.ClanWelfare then
		local nLevel = self.m_Presenter.ClanWelfare.nLevel
		local schemeInfo = IGame.rktScheme:GetSchemeInfo(CLANBUILDING_WELFARE_GIFT_CSV, nLevel)
		if schemeInfo then
			local subInfo = {
				bShowBtnType	= 0, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
			}
			print("schemeInfo.nGoodsID = "..schemeInfo.nGoodsID)
			UIManager.GoodsTooltipsWindow:SetGoodsInfo(schemeInfo.nGoodsID, subInfo)
		end
	end
end

-- 捐赠
function ClanWelfareWindow:OnBtnDonateClicked()
	self.m_DonateDetailDialog:Show()
	local nSurplusCount = self.m_Presenter.m_Welfare.m_SurplusDonaCount
	self.m_DonateCount = GetValuable(nSurplusCount < 5, nSurplusCount, 5)
	self:RefreshDonateDetailDialog()
end

function ClanWelfareWindow:OnBillItemClick()
	local subInfo = {
		bShowBtnType	= 0, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
	}
	UIManager.GoodsTooltipsWindow:SetGoodsInfo(9016, subInfo )
end

function ClanWelfareWindow:OnBtnCountInputClicked()
	local txt = self.m_DonateDetailDialog.Controls.m_CountInput
	self:OpenNumericKeypad(txt)
end

-- 确认输入次数
function ClanWelfareWindow:OnDonateInputEndEdit(inputField)
	if IsNilOrEmpty(self.m_DonateCountInput.text) then
		return
	end
	local maxCount = self.m_Presenter.m_Welfare.m_SurplusDonaCount
	local currentCount = tonumber(self.m_DonateCountInput.text)
	if not currentCount or currentCount > maxCount then
		self.m_DonateCountInput.text = tostring(self.m_DonateCount)
		return
	end
	self.m_DonateCount = currentCount
	self:RefreshDonateDetailDialog()
end

-- 关闭弹框
function ClanWelfareWindow:OnBtnDetailCloseClicked()
	if nil ~= self.m_DonateDetailDialog.Hide then
		self.m_DonateDetailDialog:Hide(false)
	end
	self.m_DonateCount = 1
	self:RefreshDonateWidget()
end

-- 确认贡献
function ClanWelfareWindow:OnBtnConfirmClicked()
	if self.m_DonateCount > 0 then
		self.m_Presenter.m_BuildingModel.m_WelfareObj:DonateRsq(self.m_DonateCount)
	end
	self.m_DonateDetailDialog:Hide()
	self.m_DonateCount = 1
end

-- 取消贡献
function ClanWelfareWindow:OnBtnCancelClicked()
	if nil ~= self.m_DonateDetailDialog.Hide then
		self.m_DonateDetailDialog:Hide(false)
	end
	self.m_DonateCount = 1
	self:RefreshDonateWidget()
end

-- +
function ClanWelfareWindow:OnBtnAddSilverClicked()
	self.m_DonateCount = self.m_DonateCount+1
	local maxCount = self.m_Presenter.m_Welfare.m_SurplusDonaCount
	if self.m_DonateCount > maxCount then self.m_DonateCount = maxCount end
	self:RefreshDonateDetailDialog()
end

-- -
function ClanWelfareWindow:OnBtnReduceSilverClicked()
	self.m_DonateCount = self.m_DonateCount-1
	local maxCount = self.m_Presenter.m_Welfare.m_SurplusDonaCount
	if self.m_DonateCount < 1 then self.m_DonateCount = GetValuable(maxCount > 0, 1, maxCount) end
	self:RefreshDonateDetailDialog()
end

function ClanWelfareWindow:OnBtnAddOrReduceColor()
	local controls = self.m_DonateDetailDialog.Controls
	local maxCount = self.m_Presenter.m_Welfare.m_SurplusDonaCount
	UIFunction.SetComsGray(controls.m_AddSilverBtn.gameObject, self.m_DonateCount >= maxCount, {typeof(Image)})
	UIFunction.SetComsGray(controls.m_ReduceSilverBtn.gameObject, self.m_DonateCount <= 1, {typeof(Image)})
	controls = self.Controls
	UIFunction.SetComsGray(controls.m_DonateBtn.gameObject, maxCount <= 0, {typeof(Image)})
end

-- [max]
function ClanWelfareWindow:OnBtnMaxSilverClicked()
	self.m_DonateCount = self.m_Presenter.m_Welfare.m_SurplusDonaCount
	self:RefreshDonateDetailDialog()
end

-- 打开小键盘
function ClanWelfareWindow:OpenNumericKeypad(txtCom)
	local numTable = {
	    ["inputNum"] = tonumber(txtCom.text),
		["minNum"]   = 1,
		["maxNum"]   = self.m_Presenter.m_Welfare.m_SurplusDonaCount, 
		["bLimitExchange"] = 0
	}
	local otherInfoTable = {
		["inputTransform"] = txtCom.transform,
	    ["bDefaultPos"] = 0,
	    ["callback_UpdateNum"] = function (num)
	    	txtCom.text = num
			self.m_DonateCount = GetValuable(tonumber(num) > 0, tonumber(num), 1)
			self:RefreshDonateDetailDialog()
	    end
	}
	UIManager.NumericKeypadWindow:ShowWindow(numTable, otherInfoTable) 
end

return ClanWelfareWindow