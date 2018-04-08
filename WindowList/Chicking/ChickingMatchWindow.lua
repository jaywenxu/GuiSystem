local ChickingMatchWindow = UIWindow:new
{
	windowName = "ChickingMatchWindow" ,
}
	
---------------------------------------------------------------
function ChickingMatchWindow:Init()

end
---------------------------------------------------------------
function ChickingMatchWindow:OnAttach( obj )    
	UIWindow.OnAttach(self,obj)
	self:Update(self.m_Image, self.m_nBeginTime)
end

-- 倒计时
function ChickingMatchWindow:Update(Image, nBeginTime)
	self.m_nBeginTime = nBeginTime
	self.m_Image = Image
	if not self:isLoaded() then
		return
	end
	self:TimeCount()
	self.m_TimeCallBack = function() self:TimeCount() end
	rktTimer.KillTimer(m_TimeCallBack)
	rktTimer.SetTimer(self.m_TimeCallBack, 1000 , -1, "ChickingMatchWindow:Update()")
end

function ChickingMatchWindow:TimeCount()
	local nTime = IGame.EntityClient:GetZoneServerTime() - self.m_nBeginTime
	local nHour = 0
	local nMin = 0
	if nTime > 3600 then
		nHour = math.floor(nTime/3600)
		nTime = nTime - nHour*3600
	end
	if nTime > 60 then
		nMin = math.floor(nTime/60)
		nTime = nTime - nMin*60
	end
	local szMsg = string.format("%02d:%02d:%02d", nHour, nMin, nTime)
	self.Controls.m_downTime.text = szMsg
end

function ChickingMatchWindow:OnDestroy()
	rktTimer.KillTimer(self.m_TimeCallBack)
	UIWindow.OnDestroy(self)
end

return ChickingMatchWindow