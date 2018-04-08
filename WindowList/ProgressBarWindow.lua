
------------------------------------------------------------
-- 进度条窗口
------------------------------------------------------------

------------------------------------------------------------
local ProgressBarWindow = UIWindow:new
{
	windowName = "ProgressBarWindow" ,
	mNeedUpdate = false,
	m_ProgreesBarName = "",  -- 名字
	m_nIntervalTime = "",	 -- 间隔时间
	m_nCurTime = 0,			 -- 当前时间
    IsEnd = false,           -- 是否结束
}
local this = ProgressBarWindow   -- 方便书写
------------------------------------------------------------
function ProgressBarWindow:Init()
   
end
------------------------------------------------------------
function ProgressBarWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	
	self.calbackTimer = function() self:OnProgressBarTimer() end

    if self.IsEnd then
        self:Hide()
        return self
    end
    
	self.progressText = self.Controls.progressBar:GetComponent(typeof(Slider))
	if self.mNeedUpdate then
		self:NeedUpdate()
		self.mNeedUpdate = false
	end
    
    return self
end
------------------------------------------------------------
------------------------------------------------------------
function ProgressBarWindow:OnDestroy()
	self:ClearData()
	UIWindow.OnDestroy(self)
end

------------------------------------------------------------
-- 响应关闭
function ProgressBarWindow:CloseProgressBar()
	self:Hide()
end

function ProgressBarWindow:Hide( destroy )
	
	self:ClearData()
	UIWindow.Hide(self,destroy)
end
-- 需要更新
function ProgressBarWindow:ClearData()
	self.m_ProgreesBarName = "" -- 名字
	self.m_nIntervalTime = 0  -- 间隔时间
	self.m_nCurTime = 0			-- 当前时间
	self.IsEnd = false
	rktTimer.KillTimer( self.calbackTimer )
end

------------------------------------------------------------
-- 需要更新
function ProgressBarWindow:NeedUpdate()
	self:StartProgressBar()
end

------------------------------------------------------------
-- 显示进度条
function ProgressBarWindow:ShowProgressBar(szName,nTime)
	self.IsEnd = false
	self.m_ProgreesBarName = szName
	self.m_nIntervalTime = nTime
	self.m_nCurTime = luaGetTickCount()
	if self:isLoaded() then
		self:StartProgressBar()
	else
		self.mNeedUpdate = true
	end
end

------------------------------------------------------------
-- 启动进度条
function ProgressBarWindow:StartProgressBar()
	
	-- 如果时间不足则关闭
	if self.m_nIntervalTime <= 0 then
		self:Hide()
	end
	self.Controls.szNameLabel.text = tostring(self.m_ProgreesBarName)
	self.progressText.value = 0
	
	self.Controls.szlTimeLabel.text = "0%"
	
	-- 设置定时器
	rktTimer.SetTimer( self.calbackTimer, 10 , -1 , "ProgressBarWindow:OnProgressBarTimer" )
end

------------------------------------------------------------
-- 显示进度条
function ProgressBarWindow:OnProgressBarTimer()
    if not self:isShow() then
        self:CloseProgressBar()
        return
    end
	
	local nTime = luaGetTickCount() - self.m_nCurTime + 100
	if self.m_nIntervalTime <= nTime then
		self.progressText.value = 1.0
		self.Controls.szlTimeLabel.text = "100%"
		rktTimer.KillTimer( self.calbackTimer )
		return
	end
	if nTime < 0 then
		nTime = 0
	end
	local nPer = math.ceil((nTime/self.m_nIntervalTime)*100)
	if nPer > 100 then
		nPer = 100
	end
	self.Controls.szlTimeLabel.text = tostring(nPer).."%"
	self.progressText.value = nTime/self.m_nIntervalTime
end

------------------------------------------------------------
-- 结束
function ProgressBarWindow:SetEnd( bEnd )
    self.IsEnd = bEnd
end

------------------------------------------------------------
return this
