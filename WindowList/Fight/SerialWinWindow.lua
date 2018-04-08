--SerialWinWindow.lua------------------------------------------------------------
-- 版  权:	(C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:	何荣德
-- 日  期:	2017.1.3
-- 版  本:	1.0
-- 描  述:	连胜窗口
-------------------------------------------------------------------

local SerialWinWindow = UIWindow:new
{
	windowName  = "SerialWinWindow",
    m_nSerialWinNum = 0,
    m_timeCallBack = nil,
}

function SerialWinWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
    
    self:ShowSerialWin(self.m_nSerialWinNum)
end

function SerialWinWindow:ShowSerialWin(nSerialWinNum)
    self.m_nSerialWinNum = nSerialWinNum
    
    if not self:isLoaded() then
        self:Show()
        return
    end
    
    self.Controls.m_SerialWinNum.text = nSerialWinNum
    if self.m_timeCallBack then
        rktTimer.KillTimer(self.m_timeCallBack)
    else
        self.m_timeCallBack = function() self:OnTimer() end
    end
    rktTimer.SetTimer(self.m_timeCallBack, 3000, 1, "SerialWinWindow:OnTimer")
end

function SerialWinWindow:OnTimer()
    self:Hide()
    self.m_timeCallBack = nil
end

return SerialWinWindow