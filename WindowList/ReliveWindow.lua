-- 复活窗口
------------------------------------------------------------
local ReliveWindow = UIWindow:new
{
	windowName = "ReliveWindow",
	m_ReliveInfo = nil,
	m_TimerCnt = 0,
	hint = "",
	
	-- 禁止弹窗tick
	forbidTick = {},
	
	m_TimerHereRelive = 0,
}

------------------------------------------------------------
function ReliveWindow:Init()
	self.m_TimeHander = function() self:OnTimer() end
end

------------------------------------------------------------
function ReliveWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	
	self.Controls.m_Confirm.onClick:AddListener(function() self:OnBtnConfirm() end)
	self.Controls.m_HomeRelive.onClick:AddListener(function() self:OnHomeReliveBtnConfirm() end)
	
	self.callback_OnExecuteEventRelive = function() self:OnRelive() end
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local uid = pHero:GetUID()
	rktEventEngine.SubscribeExecute(EVENT_PERSON_RELIVE, SOURCE_TYPE_PERSON, uid, self.callback_OnExecuteEventRelive)
	if self.m_ReliveInfo then
		self:Refresh()
	end
	if self.m_TimerHereRelive > 0 then
		UIFunction.SetImgComsGray(self.Controls.m_Confirm.gameObject,true)
		local Animtaion = self.Controls.m_Confirm:GetComponent(typeof(rkt.ButtonClickAnimation))
		Animtaion.enabled = false
		self.Controls.m_Confirm.interactable = false
		self.Controls.m_HereText.text = "<color=#FF0000FF>原地复活("..self.m_TimerHereRelive.."秒)</color>"
	else
		UIFunction.SetImgComsGray(self.Controls.m_Confirm.gameObject,false)
		local Animtaion = self.Controls.m_Confirm:GetComponent(typeof(rkt.ButtonClickAnimation))
		Animtaion.enabled = true
		self.Controls.m_Confirm.interactable = true
		self.Controls.m_HereText.text = "原地复活"
	end
	return self
end

function ReliveWindow:OnDestroy()	
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local uid = pHero:GetUID()
	rktEventEngine.UnSubscribeExecute(EVENT_PERSON_RELIVE, SOURCE_TYPE_PERSON, uid, self.callback_OnExecuteEventRelive)
	rktTimer.KillTimer(self.m_TimeHander, 1000, -1, "ReliveWindow:SetTimer")
	UIWindow.OnDestroy(self)
end

-- 复活
function ReliveWindow:OnRelive()
	self:Hide()
end
------------------------------------------------------------

-- 点击回城复活按钮
function ReliveWindow:OnHomeReliveBtnConfirm()
	self:Hide()
	local dwMapID = IGame.EntityClient:GetMapID()
	local pMapLandScheme = IGame.rktScheme:GetSchemeInfo(MAPLAND_CSV, dwMapID)
	if not pMapLandScheme then
		return
	end
	local szSafeCallFunc = pMapLandScheme.szSafeCallFunc
	
	if szSafeCallFunc and szSafeCallFunc ~= "" then
		local pos = string.find(szSafeCallFunc,')')
		if pos == nil then
			szSafeCallFunc = szSafeCallFunc .. "()"
		end
		
		pos = string.find(szSafeCallFunc,"Request")
		if pos == nil then
			LuaEval(szSafeCallFunc)
			return
		end
		GameHelp.PostServerRequest(szSafeCallFunc)
		return
	end
	GameHelp.PostServerRequest("RequestImmediateRelive(0)")
end

-- 点击原地复活按钮，消耗银币，银币不够可以使用银，两等价的
function ReliveWindow:OnBtnConfirm()
	--self:Hide()
	GameHelp.PostServerRequest("RequestOnthespotRelive(2)")
end

-- 点击银两复活按钮
function ReliveWindow:OnYinLiangReliveBtnConfirm()
	self:Hide()
	GameHelp.PostServerRequest("RequestOnthespotRelive(2)")
end

-- 点击关闭按钮
function ReliveWindow:OnBtnClose()
	self:Hide()
end

-- 更新信息
function ReliveWindow:Update(msg)
	cLog("[复活窗口]Update "..tostringEx(msg)..", nReliveHereTime"..tostringEx(msg.nReliveHereTime))
	if msg.bForbidWindow then
		self.forbidTick[msg.dwTick] = true
        print("ReliveWindow:Update insert forbid tick: "..tostring(msg.dwTick))
	end
	
	self.m_ReliveInfo = msg
	self.m_TimerCnt = msg.nReliveCountDown
	if msg.nTimes >= 3 then
		self.m_TimerHereRelive = msg.nReliveHereTime
	end
end

-- 更新信息
function ReliveWindow:Refresh()
	if not self:isLoaded() then
		return
	end

	local lastDieTick = 0
	local commonPart = GetHero():GetEntityPart(ENTITYPART_CREATURE_COMMON)
	if commonPart then
		lastDieTick = commonPart:GetLastDieTick()
	end
	
	if self.forbidTick[lastDieTick] then
        print("ReliveWindow:Refresh is forbidden, lastDieTick: "..tostring(lastDieTick))
		self:Hide()
		return
	end
    
    print("ReliveWindow:Refresh is not forbidden, lastDieTick: "..tostring(lastDieTick))
	
	self.Controls.m_AutoReliveTime.text = self.m_TimerCnt.."秒"
	
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	
	local nHeroLv = pHero:GetNumProp(CREATURE_PROP_LEVEL)
	local pUpGradeScheme = IGame.rktScheme:GetSchemeInfo(UPGRADE_CSV, nHeroLv)
	if not pUpGradeScheme then
		return
	end
	local YinBi = pUpGradeScheme.ReliveYinLiang or 0
    local szCostText = "原地复活所需银币<color=#ead387>"..YinBi.."</color>"
    if pHero:GetYinBiNum() < YinBi then
        if pHero:GetYinLiangNum() >= YinBi then
            szCostText = "原地复活所需银两<color=#ead387>"..YinBi.."</color>"
        end
    end
	self.Controls.m_JinBiText.text = szCostText
    
	--self.Controls.m_HomeText.text = "回城复活 ("..self.m_TimerCnt.." 秒)"
	--self.Controls.m_YuanDiText.text = "原地复活 ("..self.m_ReliveInfo.byFreeReliveNum.." 次)"
	--self.Controls.m_YinLiangText.text = "银两复活 ( 20 两)"
	rktTimer.SetTimer(self.m_TimeHander, 1000, -1, "ReliveWindow:SetTimer")
	
	local MapID = self.m_ReliveInfo.dwReliveMapID
	local MyMapID = IGame.EntityClient:GetMapID()
	local pMapLandScheme = IGame.rktScheme:GetSchemeInfo(MAPLAND_CSV, MyMapID)
	if not pMapLandScheme then
		return
	end
	local szSafeCallFuncPos = pMapLandScheme.szSafeCallFuncPos
	
	if szSafeCallFuncPos and szSafeCallFuncPos ~= "" then
		local pos = string.find(szSafeCallFuncPos,')')
		if pos == nil then
			szSafeCallFuncPos = szSafeCallFuncPos .. "()"
		end
		
		MapID = LuaEval("return "..szSafeCallFuncPos)
	end
	
	local pMapSchemeInfo = IGame.rktScheme:GetSchemeInfo(MAPINFO_CSV, MapID)
	if not pMapSchemeInfo then
		uerror("[复活][ReliveWindow:Refresh]  复活配置的MapID 找不到信息"..tostringEx(MapID))
		return
	end
		cLog("[复活][ReliveWindow:Refresh]  复活配置的MapID 找不到信息"..tostringEx(MapID))
	self.Controls.m_MapName.text = "("..pMapSchemeInfo.szName..")"
end

function ReliveWindow:OnTimer()
	self.m_TimerCnt = self.m_TimerCnt - 1
	if self.m_TimerCnt <= 0 then
		rktTimer.KillTimer( self.m_TimeHander )
	end
	
	self.m_TimerHereRelive = self.m_TimerHereRelive - 1
	if self.m_TimerHereRelive > 0 then
		UIFunction.SetImgComsGray(self.Controls.m_Confirm.gameObject,true)
		local Animtaion = self.Controls.m_Confirm:GetComponent(typeof(rkt.ButtonClickAnimation))
		Animtaion.enabled = false
		self.Controls.m_Confirm.interactable = false
		self.Controls.m_HereText.text = "<color=#FF0000FF>原地复活("..self.m_TimerHereRelive.."秒)</color>"-- <color=#FF0000FF>原地复活(5秒)</color>
	else
		UIFunction.SetImgComsGray(self.Controls.m_Confirm.gameObject,false)
		local Animtaion = self.Controls.m_Confirm:GetComponent(typeof(rkt.ButtonClickAnimation))
		Animtaion.enabled = true
		self.Controls.m_Confirm.interactable = true
		self.Controls.m_HereText.text = "原地复活"
	end
	
	self.Controls.m_AutoReliveTime.text = self.m_TimerCnt.."秒"
end

function ReliveWindow:TryShow()
	UIManager.ReliveWindow:Show(true)
	self:Refresh()
end

return ReliveWindow
