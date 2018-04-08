------------------------------------------------------------
-- MainRightBottomWindow 的子窗口,不要通过 UIManager 访问
-- 右边底部功能按钮窗口
------------------------------------------------------------

local FunctionWidget = UIControl:new
{
	windowName = "FunctionWidget",
}

local this = FunctionWidget   -- 方便书写

function FunctionWidget:Init()

end

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function FunctionWidget:Attach( obj )
	UIControl.Attach(self,obj)
	
	self.DOTweener = self.transform:GetComponent(typeof(DG.Tweening.DOTweenAnimation))
	
	
	
	--点击打造按钮
	--self.calbackForgeButton = function() self:OnForgeButtonClick() end
    --self.Controls.m_ForgeBtn.onClick:AddListener(self.calbackForgeButton)

	self.Controls.m_SettingsBtn.onClick:AddListener(handler(self, self.OnSettingsButtonClick))
	
	
	--点击帮会按钮
	self.Controls.m_ClanBtn.onClick:AddListener(handler(self, self.OnClanBtnClick))

	--点击技能按钮
	self.Controls.m_SkillBtn.onClick:AddListener(handler(self, self.OnSkillBtnClick))
	
	-- 点击头衔按钮
    self.Controls.m_HeadTitleBtn.onClick:AddListener(handler(self, self.OnHeadTitleBtnClick))
	
	--点击坐骑（灵兽）按钮
	self.Controls.m_ZuoqiBtn.onClick:AddListener(handler(self, self.OnZuoqiBtnClick))
	
	--点击外观按钮
	self.Controls.m_AppearanceBtn.onClick:AddListener(handler(self, self.OnAppearanceBtnClick))
	
	-- 帮会红点：红包
	rktEventEngine.SubscribeExecute(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM,REDDOT_UI_EVENT_MAIN_RIGHT_BOTTOM, self.RefreshRedDot, self)
	
	-- 加入帮会，显示红点（红包）
	rktEventEngine.SubscribeExecute( EVENT_JOIN_SUCCESS, SOURCE_TYPE_CLAN, 0, self.OnJoinClan, self)
	
	-- 退出帮会，不显示红点（红包）
	rktEventEngine.SubscribeExecute( EVENT_CLAN_QUIT, SOURCE_TYPE_CLAN, 0, self.OnExitClan, self)

	self:RefreshRedDot()
	
	return self
end

------------------------------------------------------------
function FunctionWidget:MoveInWindow()
	if not self.DOTweener then return end
	self.DOTweener:DOPlayBackwards()
end

------------------------------------------------------------
function FunctionWidget:MoveOutWindow()
	if not self.DOTweener then return end

	self.DOTweener:DORestart(false)
end

------------------------------------------------------------
function FunctionWidget:OnDestroy()
	
	rktEventEngine.UnSubscribeExecute(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM,REDDOT_UI_EVENT_MAIN_RIGHT_BOTTOM, self.RefreshRedDot, self)
	
	-- 加入帮会，显示红点（红包）
	rktEventEngine.UnSubscribeExecute( EVENT_JOIN_SUCCESS, SOURCE_TYPE_CLAN, 0, self.OnJoinClan, self)
	
	-- 退出帮会，不显示红点（红包）
	rktEventEngine.UnSubscribeExecute( EVENT_CLAN_QUIT, SOURCE_TYPE_CLAN, 0, self.OnExitClan, self)
	
	UIControl.OnDestroy(self)
end

function FunctionWidget:OnForgeButtonClick()
	UIManager.ForgeWindow:Show(true)
    UIManager.ForgeWindow:ChangeForgePage(true, 1)
end

function FunctionWidget:OnSettingsButtonClick()
	UIManager.SettingsWindow:Show(true)
end


function FunctionWidget:OnClanBtnClick()
	local clan = IGame.ClanClient:GetClan()
	if not clan then
		UIManager.ClanNoneWindow:ShowWindow()
	else
		UIManager.ClanOwnWindow:ShowWindow()
	end	
end

--技能按钮的点击行为
function FunctionWidget:OnSkillBtnClick()

	UIManager.PlayerSkillWindow:ShowWindow("TAB_TYPE_SHENGJI")
	
end

function FunctionWidget:OnHeadTitleBtnClick()
	UIManager.HeadTitleWindow:Show(false)
    UIManager.HeadTitleWindow:UpdateHeadTitleInfo()
end

--灵兽按钮点击
function FunctionWidget:OnZuoqiBtnClick()
	UIManager.PetWindow:ShowPetWindow(1)
end

-- 外观按钮点击
function FunctionWidget:OnAppearanceBtnClick()
	local pHero = GetHero()
	if not pHero then
		return
	end
	
	local level = pHero:GetNumProp(CREATURE_PROP_LEVEL)
	local min = math.min(gLevelLimitConfig.DressOpen, gLevelLimitConfig.RideOpen)
	if level < min then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "外观系统" .. min .. "级开放")
		return
	end
	
	local strOpen = "TAB_TYPE_RIDE"
	if level < gLevelLimitConfig.RideOpen then
		strOpen = "TAB_TYPE_DRESS"
	end

	UIManager.AppearanceWindow:ShowWindow(strOpen)
end

-- 刷新红点显示
function FunctionWidget:RefreshRedDot(_, _, _, evtData)
	local pClan = IGame.ClanClient:GetClan()
	if not pClan then
		evtData = {}
		evtData = {flag = false, layout = "帮会"}
	end
	
	local redDotObjs = 
	{
		["帮会"] = self.Controls.m_ClanBtn
	}
	SysRedDotsMgr.RefreshRedDot(redDotObjs, "MainRightBottom", evtData)
end

function FunctionWidget:OnJoinClan()
	IGame.RedEnvelopClient:OnRequestCanGetRedenvelop()
end

function FunctionWidget:OnExitClan()
	self:RefreshRedDot()
end

return this