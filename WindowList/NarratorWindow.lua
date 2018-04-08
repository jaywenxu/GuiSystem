

-- 旁白窗口

------------------------------------------------------------
local NarratorWindow = UIWindow:new
{
	windowName = "NarratorWindow" ,
	m_NeedUpdate = false,
	m_nNarratorID = 0,
}
------------------------------------------------------------
function NarratorWindow:Init()
	
end
------------------------------------------------------------
function NarratorWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	self.callbackTimerFunc = function() self:OnNarratorEndTimer() end
	
	if self.m_NeedUpdate == true then
		self.m_NeedUpdate = false
		self:ShowNarratorInfo()
	end
    return self
end
------------------------------------------------------------
------------------------------------------------------------
function NarratorWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

-----------------------------------------------------------
-- 清除信息
function NarratorWindow:ClearNarratorInfo()
	self.m_nNarratorID = 0
end

------------------------------------------------------------
-- 显示旁白 
function NarratorWindow:ShowNarrator(nNarratorID)
	
	local pSchemeInfo = IGame.rktScheme:GetSchemeInfo(NARRATOR_CSV, nNarratorID)
	if not pSchemeInfo then
		return
	end
	self.m_nNarratorID = nNarratorID
	if self:isLoaded() then
		self:ShowNarratorInfo()
	else
		self.m_NeedUpdate = true
	end
end

------------------------------------------------------------
-- 显示旁白
function NarratorWindow:ShowNarratorInfo()
	local pSchemeInfo = IGame.rktScheme:GetSchemeInfo(NARRATOR_CSV, self.m_nNarratorID)
	if not pSchemeInfo then
		return
	end
	local nTime = pSchemeInfo.nTime or 5000
	rktTimer.KillTimer( self.callbackTimerFunc )
	rktTimer.SetTimer(self.callbackTimerFunc, nTime, 1, "NarratorWindow:ShowNarratorInfo")
	
	-- 播放音效
	-- PlaySound(nType, pSchemeInfo.nMusicID)
	local imagePath = pSchemeInfo.szICon
	UIFunction.SetImageSprite( self.Controls.ICon , imagePath )
	self.Controls.TitleName.text = pSchemeInfo.szName
	self.Controls.szText.text = pSchemeInfo.szNarratorText
end

------------------------------------------------------------
-- 定时器时间
function NarratorWindow:OnNarratorEndTimer()
	
	-- 关闭定时器
	rktTimer.KillTimer( self.callbackTimerFunc )
	
	-- 关闭声音音效
	-- StopSound()
	
	-- 清空数据
	self:ClearNarratorInfo()
	self:Hide()
end

return NarratorWindow
