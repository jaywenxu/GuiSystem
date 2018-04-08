--/******************************************************************
---** 文件名:	QingGongButtonJoysticks.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	贾屹夫
--** 日  期:	2017-09-28
--** 版  本:	1.0
--** 描  述:	轻功用虚拟摇杆
--** 应  用:  
--******************************************************************/

local QingGongButtonJoysticks = UIControl:new
{
	windowName = "QingGongButtonJoysticks",
	
	m_IsVisible = false, -- 是否显示界面
}

-- Attach
function QingGongButtonJoysticks:Attach(obj)

	UIControl.Attach(self,obj)
	
    self.m_callbackOnJoystickPointDown = function( id ) self:OnJoystickPointDown(id) end
	
    for i = 1, 3 do
        local joystick = self.Controls["QingGongButton_"..i]:GetComponent(typeof(rkt.UIJoyStick))
        if nil ~= joystick then
            self.Controls["m_JoyStick_"..i] = joystick
            joystick.onPointDown:AddListener( self.m_callbackOnJoystickPointDown )
        end
    end
    
	return self
end

-- 按钮按下
function QingGongButtonJoysticks:OnJoystickPointDown( id )
	rktEventEngine.FireEvent( EVENT_JOY_STICK_POINT_DOWN , 0 , id)
end

-- 销毁窗口
function QingGongButtonJoysticks:OnDestroy()
    UIControl.OnDestroy(self)
end

-- 更新气力值
function QingGongButtonJoysticks:UpdateQingGongStrength(curStrength, maxStrength)
    self.curStrength = curStrength
	self.maxStrength = maxStrength
		
	if not self:isLoaded() then
		return
	end
	
	if self.curStrength < 0 then
		self.curStrength = 0
	end
    
    if self.maxStrength <= 0 then
        self.maxStrength = 1
    end
	
    self.Controls.QingGongButton_1.transform:Find("Fill"):GetComponent(typeof(Image)).fillAmount = self.curStrength / self.maxStrength
end

return QingGongButtonJoysticks