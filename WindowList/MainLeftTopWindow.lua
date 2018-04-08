
----------------------------------------------------------------
---------------------------------------------------------------
-- 主界面左边上部分窗口
-- 包含：角色头像信息等
---------------------------------------------------------------
------------------------------------------------------------
local MainLeftTopWindow = UIWindow:new
{
	windowName = "MainLeftTopWindow" ,
	mNeedUpDate = false,
	
	m_CurPKMode = -1,
	m_PrePKMode = -1,
	m_LeftPKMode = -1,
	m_RightPKMode = -1,        --PK模式子Btn对应状态，
	
	m_CoolDown = 10,			--PK切换冷却时间, 单位秒
	m_Interval = 30,			--定时器执行间隔
}

local this = MainLeftTopWindow   -- 方便书写
--------------------------------------------------------------------
local PKBtnSprite = {
	[2] = AssetPath.TextureGUIPath.."Main_mainUI/city_tai_banghui.png",						--帮会
	[1] = AssetPath.TextureGUIPath.."Main_mainUI/city_tai_qiangong.png",						--强攻
	[0] = AssetPath.TextureGUIPath.."Main_mainUI/city_tai_heping.png",						    --和平
}



------------------------------------------------------------
function MainLeftTopWindow:Init()
   
	self.PlayerHeadWidget = require("GuiSystem.WindowList.Player.PlayerHeadWidget")
	self.BuffIconWidget = require("GuiSystem.WindowList.Buff.BuffIconWidget")
end
------------------------------------------------------------
function MainLeftTopWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj,UIManager._MainHUDLayer)

	self.PlayerHeadWidget:Attach( self.Controls.m_playerHead.gameObject )
	self.Controls.m_PlayerButton.onClick:AddListener(function() self:OnPlayerButtonClick() end)

	self.BuffIconWidget:Attach(self.transform:Find("LTCon").transform:Find("BuffGrid").gameObject)
	self.Controls.m_BuffIconButton.onClick:AddListener(function() self:OnBuffIconButtonClick() end)
	
	-----------------------------------------------------------------------------
	self.Controls.m_ClanButton.onClick:AddListener(function() self:CurPKModeBtnClickCB() end)
	self.Controls.m_StormButton.onClick:AddListener(function() self:LeftPKModeBtnClickCB() end)
	self.Controls.m_PeaceButton.onClick:AddListener(function() self:RightPKModeBtnClickCB() end)
	self.Controls.m_TipButton.onClick:AddListener(function() self:ClickTipCB() end)
	
	self.OnTimerCoolDownCB = function() self:OnPKBtnCoolDown() end
	--队长 跟随图标在头像上的先不显示
	self.PlayerHeadWidget.Controls.m_followImage.gameObject:SetActive(false)
	self.PlayerHeadWidget.Controls.m_leaderFlag.gameObject:SetActive(false)
--[[	self:InitCurPKBtnImg()
	self:InitSubPKBtnState()--]]
	self.CanClick = true
	
	self.OpenPkBtn = false
	-----------------------------------------------------------------------------
	if self.mNeedUpDate then
		self.mNeedUpDate = false
		self:Refesh()
	end
	
	self:SubscribeEvts()

--[[	local curAreaName = IGame.PKModeClient:GetCurAreaName()
	
	if curAreaName == EPK_AreaName_Safe or curAreaName == EPK_AreaName_Opposite then
		self:SetPKBtnActive(false)
	else
		self:SetPKState()
	end--]]
	
    return self
end

function MainLeftTopWindow:SetTeamFlag(state)
	if self:isLoaded() then
		self.PlayerHeadWidget.Controls.m_leaderFlag.gameObject:SetActive(state)
	end
end

function MainLeftTopWindow:SyncFollowState(state)
	if self:isLoaded() then
		self.PlayerHeadWidget.Controls.m_followImage.gameObject:SetActive(state)
	end
end


function MainLeftTopWindow:SubscribeEvts()
	-- 迎新设置事件
	self.m_ClanWelcomeCallBack = handler(self, self.OnClanWelcomeEvt)
	rktEventEngine.SubscribeExecute( EVENT_CLAN_WELCOME_CONFIRM, SOURCE_TYPE_CLAN, 0, self.m_ClanWelcomeCallBack )
	
	--PK模式按钮隐藏事件
	self.m_HidePKBtnCB = function() self:SetPKBtnActive(false) end
	rktEventEngine.SubscribeExecute(EVENT_PKMODE_HIDE_PKMODEBTN, SOURCE_TYPE_PKMODE, 0, self.m_HidePKBtnCB)
	
	--PK模式按钮显示，并且设置对应信息事件
	self.m_ShowAndSetPKModeBtnStateCB = function() self:SetPKState() end
	rktEventEngine.SubscribeExecute(EVENT_PKMODE_SHOW_PKMODEBTN, SOURCE_TYPE_PKMODE, 0, self.m_ShowAndSetPKModeBtnStateCB)
end

function MainLeftTopWindow:UnSubscribeEvts()
	rktEventEngine.UnSubscribeExecute( EVENT_CLAN_WELCOME_CONFIRM , SOURCE_TYPE_CLAN, 0, self.m_ClanWelcomeCallBack )
	rktEventEngine.UnSubscribeExecute( EVENT_PKMODE_HIDE_PKMODEBTN, SOURCE_TYPE_PKMODE, 0, self.m_HidePKBtnCB )
	rktEventEngine.UnSubscribeExecute( EVENT_PKMODE_SHOW_PKMODEBTN, SOURCE_TYPE_PKMODE, 0, self.m_ShowAndSetPKModeBtnStateCB )
	self.m_ClanWelcomeCallBack = nil
	self.m_HidePKBtnCB = nil
	self.m_ShowAndSetPKModeBtnStateCB  = nil
end

function MainLeftTopWindow:OnClanWelcomeEvt()
	UIManager.WelcomePopWindow:Show(true)
end
----------------------------------------------------------------------------------------------
--初始化当前pk按钮显示信息
function MainLeftTopWindow:InitCurPKBtnImg()
	local pkMode = IGame.PKModeClient:GetCurPKMode()
	if not pkMode then return end
	self.m_PrePKMode = self.m_CurPKMode

	self.m_CurPKMode = pkMode
	UIFunction.SetImageSprite(self.Controls.m_PKBtnImg, PKBtnSprite[pkMode])
end

--初始化子pk 按钮状态
function MainLeftTopWindow:InitSubPKBtnState()
	local pkMode = IGame.PKModeClient:GetCurPKMode()
	if not pkMode then return end
	local leaveTable = {}
	for i = 0, 2, 1 do
		if i ~= pkMode then
			table.insert(leaveTable,i)
		end
	end
--	UIFunction.SetImageSprite(self.Controls.m_LeftPKBtnImg, PKBtnSprite[leaveTable[1]])
	self.m_LeftPKMode = leaveTable[1]
--	UIFunction.SetImageSprite(self.Controls.m_RightPKBtnImg, PKBtnSprite[leaveTable[2]])
	self.m_RightPKMode = leaveTable[2]
end

--设置pk按钮显示
function MainLeftTopWindow:SetPKBtnActive(nShow)
	self.Controls.m_PKModeBtnParent.gameObject:SetActive(nShow)
end

--设置PK Btn状态
function MainLeftTopWindow:SetPKState()
	self:SetPKBtnActive(true)
	self:InitCurPKBtnImg()			--设置当前pk btn显示
	self:RefreshSubPKBtn()
end

--当前选中的pk模式点击回调
function MainLeftTopWindow:CurPKModeBtnClickCB()
	if not self.CanClick then 
		return 
	end
	
	self:SetPKBtnInteractable(false)
	local open = not self.OpenPkBtn
	self:OpenBtn(open)
	self.OpenPkBtn = open
	rktTimer.SetTimer(function() self:SetPKBtnInteractable(true) end,200,1,"MainLeftTopWindow:SetPKBtnInteractable()")
end

--左边的PK Btn点击事件
function MainLeftTopWindow:LeftPKModeBtnClickCB()
	self:StartCoolDown()
	
	self:OpenBtn(false)
	self.OpenPkBtn = false
	
	local tmpMode = self.m_LeftPKMode
	
	--发送切换pk模式请求
	IGame.PKModeClient:SwitchPKMode(tmpMode)
end

--右边的PK Btn点击事件
function MainLeftTopWindow:RightPKModeBtnClickCB()
	self:StartCoolDown()
	
	self:OpenBtn(false)
	self.OpenPkBtn = false

	local tmpMode = self.m_RightPKMode

	--发送切换pk模式请求
	IGame.PKModeClient:SwitchPKMode(tmpMode)
end

--开始冷却
function MainLeftTopWindow:StartCoolDown()
	self.CanClick = false
	self.Controls.m_PKMaskParent.gameObject:SetActive(true)
	self.Controls.m_CDImg.fillAmount = 1
	self.Controls.m_CDText.text = tostring(self.m_CoolDown)			--10秒冷却
	rktTimer.SetTimer(self.OnTimerCoolDownCB,self.m_Interval,-1,"MainLeftTopWindow:OnPKBtnCoolDown()")
end

--刷新子PKBtn 显示
function MainLeftTopWindow:RefreshSubPKBtn()
	if self.m_PrePKMode ~= -1 then
		if self.m_CurPKMode == self.m_LeftPKMode then
			self.m_LeftPKMode = self.m_PrePKMode
		elseif self.m_CurPKMode == self.m_RightPKMode then
			self.m_RightPKMode = self.m_PrePKMode
		end
	else
		self:InitSubPKBtnState()
	end
	UIFunction.SetImageSprite(self.Controls.m_LeftPKBtnImg, PKBtnSprite[self.m_LeftPKMode])
	UIFunction.SetImageSprite(self.Controls.m_RightPKBtnImg, PKBtnSprite[self.m_RightPKMode])
end

--pk btn展开
function MainLeftTopWindow:OpenBtn(bOpen)
	if bOpen then
		self:SetSubPKBtnActive(true)
		local anims = self.Controls.m_StormButton.transform:GetComponentsInChildren(typeof(DG.Tweening.DOTweenAnimation))
		for	i = 0, anims.Length - 1 do
			anims[i]:DORestart(false)
		end
		anims = self.Controls.m_PeaceButton.transform:GetComponentsInChildren(typeof(DG.Tweening.DOTweenAnimation))
		for	i = 0, anims.Length - 1 do
			anims[i]:DORestart(false)
		end
	else
		local anims = self.Controls.m_StormButton.transform:GetComponentsInChildren(typeof(DG.Tweening.DOTweenAnimation))
		for	i = 0, anims.Length - 1 do
			anims[i]:DOPlayBackwards()
		end
		anims = self.Controls.m_PeaceButton.transform:GetComponentsInChildren(typeof(DG.Tweening.DOTweenAnimation))
		for	i = 0, anims.Length - 1 do
			anims[i]:DOPlayBackwards()
		end
		rktTimer.SetTimer(function() self:SetSubPKBtnActive(false) end,100,1,"MainLeftTopWindow:SetSubPKBtnActive()")
	end
end

--设置PKBtn交互状态
function MainLeftTopWindow:SetPKBtnInteractable(nBool)
	self.Controls.m_ClanButton.interactable = nBool
	self.Controls.m_StormButton.interactable = nBool
	self.Controls.m_PeaceButton.interactable = nBool
end

--设置pkBtn的显示状态，动画控制用
function MainLeftTopWindow:SetSubPKBtnActive(nActive)
	self.Controls.m_StormButton.gameObject:SetActive(nActive)
	self.Controls.m_PeaceButton.gameObject:SetActive(nActive)
end

--点击提示按钮显示信息
function MainLeftTopWindow:ClickTipCB()
	UIManager.CommonGuideWindow:ShowWindow(19)		--PK模式介绍
end

--冷却记时
function MainLeftTopWindow:OnPKBtnCoolDown()
	if self.CanClick then return end
	local leftAmount = self.Controls.m_CDImg.fillAmount - self.m_Interval / (self.m_CoolDown * 1000)
	self.Controls.m_CDImg.fillAmount = leftAmount
	if leftAmount < 0 then 
		self.Controls.m_CDImg.fillAmount = 0
		self.CanClick = true
		self.Controls.m_PKMaskParent.gameObject:SetActive(false)
	end
	
	local leftTime = math.ceil(self.m_CoolDown * 1000 * self.Controls.m_CDImg.fillAmount / 1000)
	
	if leftTime <= 0 then
		leftTime = 0
		self.Controls.m_CDText.text = 0
	else
		self.Controls.m_CDText.text = leftTime
	end
	
	if self.CanClick then
		rktTimer.KillTimer(self.OnTimerCoolDownCB)
	end	
end
------------------------------------------------------------
------------------------------------------------------------
function MainLeftTopWindow:OnDestroy()
	UIWindow.OnDestroy(self)

	self:InitState()

	self:UnSubscribeEvts()
end

function MainLeftTopWindow:InitState()
	self.m_CurPKMode = -1
	self.m_PrePKMode = -1
	self.m_LeftPKMode = -1
	self.m_RightPKMode = -1       --PK模式子Btn对应状态，
end

-- 点击人物按钮
function MainLeftTopWindow:OnPlayerButtonClick()
	UIManager.PlayerWindow:Show(true)
    UIManager.PlayerWindow:ShowType(1)
end

-- 点击Buff图标
function MainLeftTopWindow:OnBuffIconButtonClick()
	UIManager.BuffTooltipsWindow:Show(true)
    UIManager.BuffTooltipsWindow:Update()
end

------------------------------------------------------------
function MainLeftTopWindow:Refesh()
	if self:isLoaded() then
		self.PlayerHeadWidget:Update()
	end
end

function MainLeftTopWindow:OnToggleChanged(on,toggleType)
	
	if not on then
		return
	end

	if self.curToggle == toggleType then
		-- 已经显示任务窗口，则不再显示
		if toggleType == self.toggleType.taskToggle and UIManager.MainTaskWindow:isShow()then
			return
		else 
			
		end
	end
	
	self.curToggle = toggleType
	
	-- 显示任务窗口，更新任务信息
	if toggleType == self.toggleType.taskToggle then
		UIManager.MainTaskWindow:Show()
		UIManager.MainTaskWindow:RefeshTaskInfo()
	end
end

-- 刷新血条
function MainLeftTopWindow:UpdateActorBoold()
	if not self:isLoaded() then
		self.mNeedUpDate = true
        return
    end

	self.PlayerHeadWidget:UpdateBoold()
end

------------------------------------------------------------
return this
