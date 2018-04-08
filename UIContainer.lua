local UIContainer = UIControl:new
{
	windowName = "UIContainer",
}

local this = UIContainer

function UIContainer:Attach( obj )
	UIControl.Attach(self, obj)
end

function UIContainer:OnDestroy()
	UIControl.OnDestroy(self)	
end

function UIContainer:OnRecycle()
	UIControl.OnRecycle(self)
end

function UIContainer:Hide(destory)
	UIControl.Hide(self)
end

return UIContainer