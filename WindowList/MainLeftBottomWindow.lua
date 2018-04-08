
----------------------------------------------------------------
---------------------------------------------------------------
-- 主界面左边下部分分窗口
-- 包含：坐骑、摄像机
---------------------------------------------------------------
------------------------------------------------------------
local MainLeftBottomWindow = UIWindow:new
{
	windowName = "MainLeftBottomWindow" ,
	mNeedUpDate = false,
}

local this = MainLeftBottomWindow   -- 方便书写
------------------------------------------------------------
function MainLeftBottomWindow:Init()
   

end
------------------------------------------------------------
function MainLeftBottomWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj,UIManager._MainHUDLayer)
	
	self.callbackChatClick = function() self:OnChatButtonClick() end
	self.callbackDidaClick = function() self:OnDidaeButtonClick() end
	self.Controls.m_CammeraButton.onClick:AddListener( self.callbackCammeraClick )
	
	self.callbackRideClick = function() self:OnRideButtonClick() end
	self.Controls.m_RideButton.onClick:AddListener( self.callbackRideClick )

	if self.mNeedUpDate then
		self.mNeedUpDate = false
		self:Refesh()
	end
	
	-- m_friendButton
	-- m_DidaButton
	-- m_ChatButton
	
    return self
end
------------------------------------------------------------
------------------------------------------------------------
function MainLeftBottomWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

-- 点击摄像机按钮
function MainLeftBottomWindow:OnCammeraButtonClick()
	
end

-- 点击坐骑按钮
function MainLeftBottomWindow:OnRideButtonClick()
	IGame.RideClient:OnRequestMount()
end

-- 点击机器人按钮
function MainLeftBottomWindow:OnRobotButtonClick()

end

------------------------------------------------------------
function MainLeftBottomWindow:Refesh()
	if self:isLoaded() then
		
	end
end



------------------------------------------------------------
return this
