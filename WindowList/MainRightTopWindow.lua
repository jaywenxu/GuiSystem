
---------------------------------------------------------------
-- 主界面右上部分
-- 包含：活动、大字报
---------------------------------------------------------------

require("GuiSystem.WindowList.Exchange.ExchangeWindowDefine")
require("GuiSystem.WindowList.Exchange.ExchangeWindowTool")

local MainActivityItem = require("GuiSystem.WindowList.MainHUD.MainActivityItem")

local MainRightTopWindow = UIWindow:new
{
	windowName = "MainRightTopWindow" ,
	m_switchState =false,

	m_ActItemsList = {},	-- 活动布局item列表
	m_LayoutEntryItems = {},	-- 系统入口item列表

	m_LoungeTimerCallBack = nil, -- 休息室倒计时回调
	m_LoungeCDTime = 0,			 -- 休息室倒计时剩余秒数
	m_LoungeActID = 0,			-- 当前活动ID

	m_PrevLayoutID = 0,  --上一次的布局ID
	m_RedDotState = 0,	-- 红点
	m_autoFindWay = false,
	m_haveDoEnable =false,
	m_bSubEvent = false,
}

local this = MainRightTopWindow

------------------------------------------------------------
function MainRightTopWindow:Init()
	
	-- 活动列表初始化完成
	self.callbackInitActivityList = function() self:InitListFinish() end
	
	-- 活动更新事件
	self.callbackActUpdate = handler(self, self.InitAcivitiesLayout)	

	-- 休息室更新事件
	self.callbackLoungeUpdate = handler(self, self.OnLoungeUpdateEvt)	

	-- 休息室更新事件
	self.callbackMapLoaded = handler(self, self.OnGameStateChanged)
	
	-- 战斗状态UI显示定时器
	self.callbackPKStateTimer = function() self:OnTimerPKState() end
	
	-- 驯马tips定时器回调函数
	self.callbackTameResultTips = function() self:OnTimerTameResultTips() end
end   


function MainRightTopWindow:OnAttach(obj)

	UIWindow.OnAttach(self,obj,UIManager._MainHUDLayer)	
	
	self.Controls.m_switchBtn.onClick:AddListener(function() self:OnClickSwitchBtn() end)
	self.Controls.m_LounActGuideBtn.onClick:AddListener(function() self:OnLoungeActGuideBtnClick() end)

	local openingDTAni = self.Controls.m_OpeningLayout:GetComponent(typeof(DOTweenAnimation))
	self.Controls.openingDTAni = openingDTAni

	local closingDTAni = self.Controls.m_ClosingLayout:GetComponent(typeof(DOTweenAnimation))
	self.Controls.closingDTAni = closingDTAni

	self.callbackIniShopList = function() self:InitShopFinish() end
	

	-- 订阅Boss血条事件
	self.BossHPWindowCB = function(_,_,_,nOpen) self:RefreshOnBossHPWin(nOpen) end
	rktEventEngine.SubscribeExecute( EVENT_BOSSHP_SHOWORHIDE , SOURCE_TYPE_SYSTEM , 0 , self.BossHPWindowCB)
	
	--这里请求初始化物品列表     TODO

	if not self.m_bSubEvent then
		self:SubscribeExecute()
	end
	
	self:InitActivityData()
	-- 初始化商城数据
	self:InitPlazaLimitData()
	
	if self.m_LoungeActID > 0 then
		self:ShowLoungeMatching(true, self.m_LoungeActID)
		self:OnLoungeUpdateEvt(nil, nil, nil, self.m_LoungeActID)
	else
		self:ShowLoungeMatching(false)
	end
		
	self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable)) 
	self:InitAcivitiesLayout()

	self:InitUILayouts()

	IGame.LigeanceEctype:CheckIsFighting()
	IGame.GaoChangEctype:CheckIsFighting()
	
	self:InitActivityRunningIcon()
	self:SubscribeExecute()
    self:RefreshRedDot()
	self:OnEnable()
	uerror(" create MainMidBottomWindow")
	self.Controls.m_PKState.gameObject:SetActive(false)
	self.m_PKStateTweenAnim = self.Controls.m_PKStateText:GetComponent(typeof(DG.Tweening.DOTweenAnimation))
	
	self.Controls.m_TameResult.gameObject:SetActive(false)
	self.m_TameResultTweenAnim = self.Controls.m_TameResultText:GetComponent(typeof(DG.Tweening.DOTweenAnimation))
end

function MainRightTopWindow:OnEnable()
	if self.m_haveDoEnable ==false then 
		self.Controls.m_autoFindWay.gameObject:SetActive(self.m_autoFindWay)
	end
	
	self.m_haveDoEnable = true
end

function MainRightTopWindow:Show( bringTop )
	UIWindow.Show(self, bringTop )

end

function MainRightTopWindow:Hide( destroy )
	UIWindow.Hide(self,destroy)
	self.m_haveDoEnable = false
end

function MainRightTopWindow:RefreshOnBossHPWin(isOpen)
	if not isOpen then 
		self.Controls.openingDTAni:DORestart(true)
		self.Controls.closingDTAni:DOPlayBackwards()
		self.m_switchState=false
		self.Controls.m_offImage.gameObject:SetActive(true)
		self.Controls.m_openImage.gameObject:SetActive(false)
	else
		self.Controls.openingDTAni:DOPlayBackwards()
		self.Controls.closingDTAni:DORestart(true)
		self.m_switchState=true
		self.Controls.m_offImage.gameObject:SetActive(false)
		self.Controls.m_openImage.gameObject:SetActive(true)
	end

end


function MainRightTopWindow:SetAutoFindWay(state)
	local hero = GetHero()
	if hero ~= nil then 
		local uid = hero:GetUID()
		UIManager.NameTitleWindow:SetAutoFindWay(uid,state)
	end
end

function MainRightTopWindow:SubscribeExecute()

	if self.m_bSubEvent then
		return
	end

	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end

	rktEventEngine.SubscribeExecute(EVENT_ACTIVITY_LIST_FINISH, SOURCE_TYPE_ACTIVITY, pHero:GetUID(), self.callbackInitActivityList)
	
	rktEventEngine.SubscribeExecute(EVENT_ACTIVITIES_UPDATE, 0, 0, self.callbackActUpdate)
	
	rktEventEngine.SubscribeExecute(EVENT_LOUNGE_UPDATE, 0, 0, self.callbackLoungeUpdate)

	rktEventEngine.SubscribeExecute(EVENT_AFTER_ENTER_GAMESTATE, 0, 0, self.callbackMapLoaded)

	rktEventEngine.SubscribeExecute(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM,REDDOT_UI_EVENT_MAIN_RIGHT_TOP, self.RefreshRedDot, self)
	self.m_bSubEvent = true
end

function MainRightTopWindow:UnSubscribeExecute()
	rktEventEngine.UnSubscribeExecute( EVENT_BOSSHP_HIDE , SOURCE_TYPE_SYSTEM , 0 , self.BossHPWindowCB)
	rktEventEngine.UnSubscribeExecute( EVENT_ACTIVITY_LIST_FINISH , SOURCE_TYPE_ACTIVITY , GetHero():GetUID() , self.callbackInitActivityList )
	rktEventEngine.UnSubscribeExecute( EVENT_ACTIVITIES_UPDATE , 0 , 0 , self.callbackActUpdate )
	rktEventEngine.UnSubscribeExecute( EVENT_LOUNGE_UPDATE , 0 , 0 , self.callbackLoungeUpdate )
	rktEventEngine.UnSubscribeExecute( EVENT_AFTER_ENTER_GAMESTATE , 0 , 0 , self.callbackMapLoaded )
	rktEventEngine.UnSubscribeExecute( EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM,REDDOT_UI_EVENT_MAIN_RIGHT_TOP, self.RefreshRedDot, self)
	self.m_bSubEvent = false
end

function MainRightTopWindow:OnDestroy()
	for i, item in ipairs(self.m_ActItemsList) do
		item:RecycleItem()
	end
	self.m_haveDoEnable = false
	self:StopCDTimer()
	self:UnSubscribeExecute()
	UIWindow.OnDestroy(self)
end



------------------------------------------------------------
-- 游戏状态切换
function MainRightTopWindow:OnGameStateChanged(_, _, _, gameState)
	if gameState == GameStateType.Running then
		self:InitUILayouts()
	end
end
------------------------------------------------------------
-- 初始化ui布局
function MainRightTopWindow:InitUILayouts()
	if not self:isLoaded() then
		return
	end
	
	local mapID = IGame.EntityClient:GetMapID()
	local layout = GetMainRTLayoutByMapID(mapID)
	if not layout then
		uerror("the main right top layout's data can't equal nil! mapID:".. mapID)
		return
	end

	if mapID ~=  self.m_PrevLayoutID then --此次布局ID与上次相同则返回空，不再做重新布局操作
		for i, item in ipairs(self.m_LayoutEntryItems) do --删掉旧布局items
			item.btn.onClick:RemoveListener(item.btnClickCallback) --清理item的按钮点击事件
			rkt.GResources.RecycleGameObject(item.obj)
		end
		self.m_LayoutEntryItems = {}

		local controls = self.Controls
		for i, v in pairs(layout.opening) do -- 展开时候布局
			self:AddSystemItem(controls.m_OpeningLayout, v)
		end

		for i, v in pairs(layout.closing) do -- 收起时候布局
			self:AddSystemItem(controls.m_ClosingLayout, v)
		end

		self:ShowActivitiesLayout(layout.isShowActLayout) --是否显示活动布局
		-- 右下角背包入口等是否显示
		UIManager.MainRightBottomWindow:SetVisible(layout.isShowMainRBWnd)
	end

	if layout.isEnterClose then
		self.m_switchState = true
		self:OnClickSwitchBtn()
	else
		self.m_switchState = false
		self:OnClickSwitchBtn()
	end
	
	-- 切换
	UIManager.MainRightBottomWindow:SwitchSkillAttackState(layout.isSwitchSkillInput)
	
	self.m_PrevLayoutID = mapID
	self:ShowPeachFeastWindow(mapID)
end

function MainRightTopWindow:ShowActivitiesLayout(isShow)
	self.Controls.m_ActBtnsLayout.gameObject:SetActive(isShow)
end

-- 添加一个活动
function MainRightTopWindow:AddSystemItem(parentTf, data)
	rkt.GResources.FetchGameObjectAsync( GuiAssetList.MainSysEntryItem , 
        function( path , obj , ud )
            if nil == obj then 
				uerror("prefab is nil ")
				return
			end

			obj.transform:SetParent(parentTf, false) 

			local btn = obj.transform:Find("Btn")
			local Icon= btn:Find("GameObject/Icon")
			local img = Icon:GetComponent(typeof(Image))
			local IconName =  btn:Find("GameObject/IconName")
			local IconNameImage = IconName:GetComponent(typeof(Image))
			UIFunction.SetImageSprite(img, AssetPath.TextureGUIPath .. data.icon)
			UIFunction.SetImageSprite(IconNameImage, AssetPath.TextureGUIPath .. data.iconName)

			local btn = btn:GetComponent(typeof(Button))
			btn.onClick:AddListener(data.callback)

			local item = {}
			item.obj = obj
			item.btn = btn
			item.btnClickCallback = data.callback
			item.name = data.name
			table.insert(self.m_LayoutEntryItems, item)
			
			-- 刷新红点，因每个ICON是异步创建的，所以需要在此处创建时候，做刷新操作
			local flag = SysRedDotsMgr.GetSysFlag("MainRightTop", data.name)
			self:RefreshRedDot(nil, nil, nil, {flag=flag, layout = data.name})
			
        end , nil , AssetLoadPriority.GuiNormal)
end

------------------------------------------------------------

function MainRightTopWindow:InitListFinish()
	UIManager.HuoDongWindow:Show()
end

function MainRightTopWindow:OnActivityBtnClick()
	UIManager.HuoDongWindow:Show()
end

function MainRightTopWindow:OnWelfareBtnClick()
	UIManager.WelfareWindow:Show(true, WelfareDef.ItemId.MRQD)
end

-- 摆摊按钮的点击行为
function MainRightTopWindow:OnBaiTanBtnClick()
	
	local hero = GetHero()
	if not hero then
		return
	end
	
	local paramScheme = IGame.rktScheme:GetSchemeInfo(EXCHANGE_CONFIG_CSV, 1)
	if not paramScheme then
		uerror("找不到 ExchangeConfig!")
		return
	end
	
	local heroLevel = hero:GetNumProp(CREATURE_PROP_LEVEL)
	if heroLevel < paramScheme.level then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "摆摊功能需要玩家20级开放！")
		return
	end
	
	IGame.ExchangeClient:RequestQueryCollectData(ExchangeWindowNetHandleControlType.HANDLE_TYPE_SHOW_COLLECT)
end

function MainRightTopWindow:InitShopFinish()
	UIManager.ShopWindow:Show()
end

function MainRightTopWindow:OnShopBtnClick()
		if not IGame.PlazaClient:LoadedPlazaGoodsCsv() then				--加载配置数据
			return 
		end
		--请求获取商城相关数据
		if not IGame.PlazaClient.m_HaveInit then
			local bInit = 0
			GameHelp.PostServerRequest( "RequestPlazaLimitData("..bInit..")" )
		end
		UIManager.ShopWindow:ShowShopWindow(gShopWindowPage.Shop)
end

function MainRightTopWindow:InitActivityData()
	-- 获取活跃度宝箱状态
	GameHelp.PostServerRequest("RequestActiveBoxStatus()")
	
	-- 请求活动通知
	GameHelp.PostServerRequest("RequestActivityNotify()")
end

function MainRightTopWindow:InitPlazaLimitData()
	GameHelp.PostServerRequest("RequestPlazaLimitInfo()")
end

function MainRightTopWindow:InitActivityRunningIcon()
	GameHelp.PostServerRequest("RequestRunningActivity()")
end


function MainRightTopWindow:OnClickSwitchBtn()
	if self.m_switchState then 
		self.Controls.openingDTAni:DORestart(true)
		self.Controls.closingDTAni:DOPlayBackwards()
		self.m_switchState=false
		self.Controls.m_offImage.gameObject:SetActive(true)
		self.Controls.m_openImage.gameObject:SetActive(false)
	else
		self.Controls.openingDTAni:DOPlayBackwards()
		self.Controls.closingDTAni:DORestart(true)
		self.m_switchState=true
		self.Controls.m_offImage.gameObject:SetActive(false)
		self.Controls.m_openImage.gameObject:SetActive(true)
	end

end

function MainRightTopWindow:SetPosterStatus(status)
    if not self:isShow() then
        return
    end
    --TODO 这里是要把boss血条挡住的几个图标隐藏
end


------------------------------------------------------------
-- 初始化活动icon布局
function MainRightTopWindow:InitAcivitiesLayout()
	if self:isLoaded() then 
		for i, item in pairs(self.m_ActItemsList) do
			local actID = item:GetActID()
			if not IGame.OpeningActivitiesMgr:IsShow(actID) then
				item:Hide(true)
				self.m_ActItemsList[i] = nil
			end
		end

		local activities = IGame.OpeningActivitiesMgr:Activities()
		for i, v in pairs(activities) do
			if v.bShowIcon then
				self:AddAcivityItem(v)
			end
		end
	end
	
end

-- 添加一个活动
function MainRightTopWindow:AddAcivityItem(data)
	local actID = data.actID
	local item = self.m_ActItemsList[actID] 
	if not item  then
		local parentTf = self.Controls.m_ActBtnsLayout
		self.m_ActItemsList[actID] = MainActivityItem.CreateItem(parentTf, data)
	else
		item:SetData(data)
	end
end

------------------------------------------------------------
-- 休息室更新事件
function MainRightTopWindow:OnLoungeUpdateEvt(_, _, _, actID)
	local data = IGame.OpeningActivitiesMgr:ActivityAt(actID)
	self:ShowLoungeMatching(not data.bShowIcon) 

	if data.bShowIcon then -- 显示主界面活动ICON 
		return
	end

	self.m_LoungeActID = actID

	local controls = self.Controls
	local timerTxt = controls.m_LouMatchTimer
	local iconBtn  = controls.m_LounActGuideBtn

	timerTxt.text =  GetCDTime(data.cdTime, 3, 3)

	self:StopCDTimer()
	self.m_LoungeCDTime = data.cdTime
	self.m_LoungeTimerCallBack = function() --倒计时timer
		self.m_LoungeCDTime = self.m_LoungeCDTime - 1
		if self.m_LoungeCDTime < 0 then
			self:StopCDTimer(true)
			return
		end

		timerTxt.text =  GetCDTime(self.m_LoungeCDTime, 3, 3)
	end

	rktTimer.SetTimer(self.m_LoungeTimerCallBack, 1000, -1, "lounge activities time down")
end

-- 显示休息室匹配信息
function MainRightTopWindow:ShowLoungeMatching(isShow, nHuoDongID)
	if not self.transform then
		self.m_LoungeActID = nHuoDongID or 0
		return
	end
	self.Controls.m_LoungeMatching.gameObject:SetActive(isShow)
end

-- 隐藏休息室匹配面板
function MainRightTopWindow:HideLoungeMatching()
	if not self.transform then
		return
	end
	
	self:ShowLoungeMatching(false)
end

-- 休息室活动信息按钮回调
function MainRightTopWindow:OnLoungeActGuideBtnClick()
	
	local RuleCfg = IGame.rktScheme:GetSchemeInfo(ACTIVITYWINDOW_CSV, self.m_LoungeActID)
	if nil == RuleCfg then
		print("找不到信息配置！ ActID: "..self.m_LoungeActID)
		return
	end
	
	UIManager.CommonGuideWindow:ShowWindow(RuleCfg.RuleID)
end

-- 停止休息室倒计时timer
function MainRightTopWindow:StopCDTimer(bHide)
	if nil ~= self.m_LoungeTimerCallBack then
		rktTimer.KillTimer(self.m_LoungeTimerCallBack)
		self.m_LoungeTimerCallBack = nil
    
        if bHide then
		    self:ShowLoungeMatching(false)
        end
	end
end

-- 蟠桃盛宴界面开启
function MainRightTopWindow:ShowPeachFeastWindow(mapID)

	local PeachFeast_MapID = 4
	if mapID == PeachFeast_MapID then
		GameHelp.PostServerRequest("RequestPeachFeastWindow()")
	else
		UIManager.PeachFeastWindow:Hide()
	end

end

-- 刷新红点显示
function MainRightTopWindow:RefreshRedDot(_, _, _, evtData)
	local redDotObjs = {}
	for _, v in ipairs(self.m_LayoutEntryItems) do
		local name = v.name
		redDotObjs[name] = redDotObjs[name] or {}
		table.insert(redDotObjs[name], v.obj)
	end
	SysRedDotsMgr.RefreshRedDot(redDotObjs, "MainRightTop", evtData)
end

-- 战斗状态UI定时器回调函数
function MainRightTopWindow:OnTimerPKState()
	self.Controls.m_PKState.gameObject:SetActive(false)
end
	
-- 设置战斗状态
function MainRightTopWindow:SetPKStateUI(nPKState)
	if not self.m_haveDoEnable then
		return
	end
	
	-- 人物战斗状态
	if nPKState == EPK_Person_Battle then
		self.Controls.m_PKStateText.text = "进入战斗"
	-- 人物空闲状态
	else
		self.Controls.m_PKStateText.text = "退出战斗"
	end
	
	self.Controls.m_PKState.gameObject:SetActive(true)
	self.m_PKStateTweenAnim:DORestart(true)
	
	if self.isSetPakeStateTimer then
		rktTimer.KillTimer( self.callbackPKStateTimer )
    end
	rktTimer.SetTimer( self.callbackPKStateTimer , 3000 , 1, "MainRightTopWindow:SetPKStateUI" )
	self.isSetPakeStateTimer = true
end

-- 设置驯马tips
function MainRightTopWindow:SetTameResultTips(isSucceed)
	if not self.m_haveDoEnable then
		return
	end
	
	self.Controls.m_TameResult.gameObject:SetActive(true)
	self.m_TameResultTweenAnim:DORestart(true)
	
	if self.isSetTameTipsTimer then
		rktTimer.KillTimer( self.callbackTameResultTips )
    end
	
	rktTimer.SetTimer( self.callbackTameResultTips , 3000 , 1, "MainRightTopWindow:SetTameResultTips" )
	self.isSetTameTipsTimer = true
end

-- 驯马tips 定时器回调函数
function MainRightTopWindow:OnTimerTameResultTips()
	self.Controls.m_TameResult.gameObject:SetActive(false)
end

------------------------------------------------------------
------------------------------------------------------------
function MainRightTopWindow:OnDestroy()
	UIWindow.OnDestroy(self)

	table_release(self)
end
------------------------------------------------------------

-- 显示或隐藏整个摆摊、活动、商城等按钮，包括右侧的切换按钮
function MainRightTopWindow:ShowAllSystemButtons(isShow)
    if not self:isLoaded() then
        return
    end
    self.Controls.m_SystemBtnLayout.gameObject:SetActive(isShow)
    self.Controls.m_switchBtn.gameObject:SetActive(isShow)
    self:ShowActivitiesLayout(isShow)
end

return this