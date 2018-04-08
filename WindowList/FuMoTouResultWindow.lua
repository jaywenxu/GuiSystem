--/******************************************************************
--** 文件名:    FuMoTouResultWindow.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-07-14
--** 版  本:    1.0
--** 描  述:    伏魔骰投掷结果界面
--** 应  用:  
--******************************************************************/

local FuMoTouResultWindow = UIWindow:new
{
    windowName = "FuMoTouResultWindow",	-- 窗口名称
    
	m_IsWindowInvokeOnShow = false,    	-- 窗口是否调用了OnWindowShow方法的标识:boolean
	m_DiceResultPoint = 0,				-- 骰子的结果点数:number
	m_CountDownTime = 0 ,              --刷怪倒计时
}

function FuMoTouResultWindow:Init()

	
end

function FuMoTouResultWindow:OnAttach( obj )
	
    UIWindow.OnAttach(self, obj)

	self.onUseAgainButtonClick = function() self:OnUseAgainButtonClick() end
	self.onConfirmButtonClick = function() self:OnConfirmButtonClick() end
	self.onCloseButtonClick = function() self:OnCloseButtonClick() end
	self.refreshTimeFun = function() FuMoTouResultWindow:RefreshTimer() end
	self.Controls.m_ButtonUseAgain.onClick:AddListener(self.onUseAgainButtonClick)
	self.Controls.m_ButtonConfirm.onClick:AddListener(self.onConfirmButtonClick)
	self.Controls.m_ButtonClose.onClick:AddListener(self.onCloseButtonClick)

    if self.m_IsWindowInvokeOnShow then
        self.m_IsWindowInvokeOnShow = false
        self:OnWindowShow()
    end
	
    return self
	
end


function FuMoTouResultWindow:_showWindow()
	
    UIWindow._showWindow(self)
    if self:isLoaded() then
        self:OnWindowShow()
    else
        self.m_IsWindowInvokeOnShow = true
    end
	
end

-- 显示窗口
-- @diceResultPoint:骰子的结果点数
function FuMoTouResultWindow:ShowWindow(diceResultPoint)
	
	self.m_DiceResultPoint = diceResultPoint
	
	
    UIWindow.Show(self, true)
	
end

-- 窗口每次打开执行的行为
function FuMoTouResultWindow:OnWindowShow()
	
	local pointCfg = gFuMoTouCfg.monsters[self.m_DiceResultPoint]
	if pointCfg == nil then
		return
	end
	
	local monsterScheme = IGame.rktScheme:GetSchemeInfo(MONSTER_CSV, pointCfg.id)
	if not monsterScheme then
		return
	end
	
	local dropScheme = FuMoTouWindowTool.CalcTheBestDropScheme(pointCfg)
	if not dropScheme then
		return
	end
	
	local dropAwardStr = ""
	for k,v in pairs(dropScheme.items) do
		local dropAwardScheme = gFuMoTouDropCfg[v]
		local color = gFuMoTouColorCfg[dropAwardScheme.color]
		if dropAwardScheme then
			local str = string.format("<color=%s>%s</color>",color,dropAwardScheme.text)
            if not IsNilOrEmpty(dropAwardStr) then 
                dropAwardStr = dropAwardStr..","
            end
			dropAwardStr = dropAwardStr .. str
		end
	end
	local time = gFuMoTouCfg.AutoCreateBossTime / 1000
	self.m_CountDownTime = time
	rktTimer.SetTimer(self.refreshTimeFun,1000,-1,"心魔开始倒计时")
	self.Controls.m_TimeTips.text = string.format("（%s秒后自动召唤）",self.m_CountDownTime)
	self.Controls.m_TextAward.text = string.format("掉落%s", dropAwardStr)
	
	local numColor = gFuMoTouColorCfg[pointCfg.numColor]
	local monsterName = string.format("%s",monsterScheme.szName)
	self.Controls.m_TextResult.text = string.format("你当前点数为<color=%s>%d</color>，可召唤<color=%s>%s</color>，是否召唤？", numColor, self.m_DiceResultPoint, numColor, monsterName)
	
end

function FuMoTouResultWindow:RefreshTimer()
	
	self.m_CountDownTime  = Mathf.Max(0,self.m_CountDownTime -1) 
	self.Controls.m_TimeTips.text = string.format("（%s秒后自动召唤）",self.m_CountDownTime)
	
end

-- 再摇一次按钮的点击行为
function FuMoTouResultWindow:OnUseAgainButtonClick()
	GameHelp.PostServerRequest("RequestFuMoTouContinue()")
	self:Hide()
	GameHelp.PostServerRequest("RequestFuMoTouRandom()")
	
end

-- 确认按钮的点击行为
function FuMoTouResultWindow:OnConfirmButtonClick()
	
	GameHelp.PostServerRequest("RequestFuMoTouCreateBoss()")
	
end

function FuMoTouResultWindow:Hide(destory)
	rktTimer.KillTimer(self.refreshTimeFun)
	UIWindow.Hide(self,destory)
end

-- 关闭按钮的点击行为
function FuMoTouResultWindow:OnCloseButtonClick()
	
	GameHelp.PostServerRequest("RequestFuMoTouDoNoThing()")
	UIManager.FuMoTouResultWindow:Hide()
	
end

return FuMoTouResultWindow