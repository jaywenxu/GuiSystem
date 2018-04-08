--/******************************************************************
---** 文件名:	HuoDongWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	张杰
--** 日  期:	2017-02-28
--** 版  本:	1.0
--** 描  述:	移动用虚拟摇杆
--** 应  用:  
--******************************************************************/

------------------------------------------------------------
local MoveJoyStick = UIControl:new
{
	windowName = "MoveJoyStick",
}
------------------------------------------------------------

function MoveJoyStick:Attach(obj)
	UIControl.Attach(self,obj)
    self.Controls.m_JoyStick = self.transform:GetComponent(typeof(rkt.UIJoyStick))
    self.m_callbackOnJoyStickDragBegin = function( id ) self:OnJoyStickDragBegin(id) end
    self.m_callbackOnJoyStickDragEnd = function( id ) self:OnJoyStickDragEnd(id) end
    self.Controls.m_JoyStick.onDragBegin:AddListener( self.m_callbackOnJoyStickDragBegin )
    self.Controls.m_JoyStick.onDragEnd:AddListener( self.m_callbackOnJoyStickDragEnd )
	return self
end
------------------------------------------------------------
function MoveJoyStick:OnJoyStickDragBegin( id )
    rktEventEngine.FireEvent( EVENT_JOY_STICK_BEGIN_DRAG , 0 , id , nil )
end
------------------------------------------------------------
function MoveJoyStick:OnJoyStickDragEnd( id )
    rktEventEngine.FireEvent( EVENT_JOY_STICK_END_DRAG , 0 , id , nil )
end

------------------------------------------------------------
function MoveJoyStick:SetActive(isAct)
    self.Controls.m_JoyStick.SetActive( 1, isAct)
end
------------------------------------------------------------
function MoveJoyStick:OnDestroy()
    self.Controls.m_JoyStick.onDragBegin:RemoveListener( self.m_callbackOnJoyStickDragBegin )
    self.Controls.m_JoyStick.onDragEnd:RemoveListener( self.m_callbackOnJoyStickDragEnd )

    UIControl.OnDestroy(self)
end
------------------------------------------------------------

return MoveJoyStick



