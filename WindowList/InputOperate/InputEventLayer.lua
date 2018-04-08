--/******************************************************************
---** 文件名:	HuoDongWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	张杰
--** 日  期:	2017-02-28
--** 版  本:	1.0
--** 描  述:	事件输入层
--** 应  用:  
--******************************************************************/
------------------------------------------------------------
local InputEventLayer = {}
local this = InputEventLayer
------------------------------------------------------------

function InputEventLayer.Attach(obj)
    require("HedgehogTeam.EasyTouch.BaseFinger")
    require("HedgehogTeam.EasyTouch.Gesture")
    this.m_EasyTouchTrigger = obj:GetComponent(typeof(rkt.UGUIEasyTouchTrigger))
    this.m_EasyTouchTrigger.onSimpleTap:AddListener(InputEventLayer.OnEasyTouch_SimpleTap)
    --this.m_EasyTouchTrigger.onDoubleTap:AddListener(InputEventLayer.OnEasyTouch_DoubleTap)
    --this.m_EasyTouchTrigger.onPinchIn:AddListener(InputEventLayer.OnEasyTouch_PinchIn)
    --this.m_EasyTouchTrigger.onPinchOut:AddListener(InputEventLayer.OnEasyTouch_PinchOut)
    --this.m_EasyTouchTrigger.onSwipe:AddListener(InputEventLayer.OnEasyTouch_Swipe)
    --this.m_EasyTouchTrigger.onTwist:AddListener(InputEventLayer.OnEasyTouch_Twist)

    local cameraFrame = rktMainCamera.GetCameraFrame_Operate(true)
    if nil ~= cameraFrame then
        cameraFrame:AttachEasyTouchEvent( this.m_EasyTouchTrigger.onPinch , this.m_EasyTouchTrigger.onSwipe )
    end
end
------------------------------------------------------------
function InputEventLayer.OnEasyTouch_SimpleTap( gesture )
    rktEventEngine.FireEvent( EVENT_INPUT_LAYER_SIMPLE_TAP , 0 , 0 , gesture )
end
------------------------------------------------------------
function InputEventLayer.OnEasyTouch_DoubleTap( gesture )

end
------------------------------------------------------------
function InputEventLayer.OnEasyTouch_PinchIn( gesture )

end
------------------------------------------------------------
function InputEventLayer.OnEasyTouch_PinchOut( gesture )

end
------------------------------------------------------------
function InputEventLayer.OnEasyTouch_Swipe( gesture )

end
------------------------------------------------------------
function InputEventLayer.OnEasyTouch_Twist( gesture )

end
------------------------------------------------------------
function InputEventLayer.OnDestroy()
    this.m_EasyTouchTrigger = nil
end
------------------------------------------------------------

return InputEventLayer



