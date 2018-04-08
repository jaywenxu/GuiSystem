--BabelEndWnd.lua------------------------------------------------------------
-- 版  权:	(C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:	聂敏隆
-- 日  期:	2017.12.27
-- 版  本:	1.0
-- 描  述:	通天塔结算界面
------------------------------------------------------------------------------

local BabelEndWnd = UIWindow:new
{
	windowName = "BabelEndWnd",

	nTimeWin = 0,
	
	tPosPrize = 
	{
		Vector3.New(-9.5,-118,0),
		Vector3.New(1,0,0),
	},
}

function BabelEndWnd:OnAttach(obj)

	UIWindow.OnAttach(self,obj)
	
    self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))

	self.Controls.m_BtnLeave.onClick:AddListener(handler(self, self.OnBtnLeave))
	self.Controls.m_BtnNext.onClick:AddListener(handler(self, self.OnBtnNext))
				
	self:SubscribeEvent()
	
	self:FreshUI()
end

function BabelEndWnd:OnEnable()
	self:FreshUI()
end

function BabelEndWnd:Show()
	
	if not self:isShow() then
		UIWindow.Show(self,true)
		return
	end
	
	self:FreshUI()
end

function BabelEndWnd:Hide()
	self:StopCDTimer()
	UIWindow.Hide(self)
end

-- 窗口销毁
function BabelEndWnd:OnDestroy()
	self:Hide()
	self:UnSubscribeEvent()
	UIWindow.OnDestroy(self)
end

function BabelEndWnd:SubscribeEvent()
	--self.pOnEventShowMain = handler(self, self.OnEventShowMain)
	--rktEventEngine.SubscribeExecute(EVENT_BABEL_SHOWMAIN, 0, 0, self.pOnEventShowMain)
end

function BabelEndWnd:UnSubscribeEvent()
	--rktEventEngine.UnSubscribeExecute(EVENT_BABEL_SHOWMAIN, 0, 0, self.pOnEventShowMain)
end

-- 刷新界面显示
function BabelEndWnd:FreshUI()

	local tMsg = IGame.BabelEctype:GetWinInfo()
	if not tMsg then
		return
	end

	self.nTimeWin = tMsg[2] or 0
	self:SetCDTimer(self.nTimeWin)
	
	self.Controls.m_TextLevel.text = ""
	
	if not tMsg[1] then
		self.Controls.m_WinBG.gameObject:SetActive(false)
		self.Controls.m_LoseBG.gameObject:SetActive(true)
		return
	end

	self.Controls.m_LoseBG.gameObject:SetActive(false)
	self.Controls.m_WinBG.gameObject:SetActive(true)
	
	self.Controls.m_TextExp.text = tMsg[3]
	self.Controls.m_TextMoney.text = tMsg[4]
	self.Controls.m_TextPrize.gameObject:SetActive(false)
	self.Controls.m_Text1.transform.localPosition = self.tPosPrize[1]
		
	
	local nFloor = IGame.BabelEctype:GetFloor()	
	local tCfg = IGame.rktScheme:GetSchemeInfo(BABEL_CSV, nFloor + 1)
	
	if not tCfg then
		self.Controls.m_BtnNext.interactable = false
		return
	end
	
	local nLevel = GetHero():GetNumProp(CREATURE_PROP_LEVEL)
	local nPower = GetHero():GetNumProp(CREATURE_PROP_POWER)
	
	if nLevel < tCfg.nLevel then
		self.Controls.m_TextLevel.text = "需角色"..tCfg.nLevel.."级"
	
	elseif nPower < tCfg.nPower then
		self.Controls.m_TextLevel.text = "推荐战力"..tCfg.nPower
	end
	self.Controls.m_BtnNext.interactable = true
	
	-- 整条奖励
	local tCfgNow = IGame.rktScheme:GetSchemeInfo(BABEL_CSV, nFloor)
	if tCfgNow.strFloor == "" then
		return
	end
	
	self.Controls.m_Text1.transform.localPosition = self.tPosPrize[2]
	self.Controls.m_TextPrize.gameObject:SetActive(true)
	local strText = ""
	local str = ""
	local tString = split_string(tCfgNow.strFloor, ";")
	for n = 1, 3 do
		str = (tString[n] or "")
		if n == 3 then
			str = "<color=#FF7900>"..str.."</color>"
		end
		strText = strText .. "       "..str
	end
	self.Controls.m_TextProp.text = strText
end

-- 点击离开
function BabelEndWnd:OnBtnLeave()
	self:Hide()
	IGame.BabelEctype:RequestLeave()
end

-- 点击继续
function BabelEndWnd:OnBtnNext()
	if IGame.BabelEctype:RequestEnter(1) then
		self:Hide()
	end
end

-- 设置战斗结束倒计时
function BabelEndWnd:SetCDTimer(nTime)
	
	self:StopCDTimer()

	local nTimeCount = nTime
	local strText = ""
	
	if nTimeCount > 1 then
		strText = GetCDTime(nTimeCount, 3, 3)
		self.m_TimerCallBack = function() self:OnTimer() end
	end
	
	self.Controls.m_TextTime.text = strText
	
	self.nTimeWin = nTimeCount

	rktTimer.SetTimer(self.m_TimerCallBack, 1000, -1, "BabelEndWnd:SetCDTimer")
end

-- 定时器
function BabelEndWnd:OnTimer()
	
	self.nTimeWin = self.nTimeWin - 1
	if self.nTimeWin < 1 then
		self.Controls.m_TextTime.text = ""
		self:StopCDTimer()
		return
	end

	self.Controls.m_TextTime.text = GetCDTime(self.nTimeWin, 3, 3)
end

-- 停止倒计时
function BabelEndWnd:StopCDTimer()
	
	if self.m_TimerCallBack then
		rktTimer.KillTimer(self.m_TimerCallBack)
		self.m_TimerCallBack = nil
		self.nTimeWin = 0
	end
end

return BabelEndWnd



