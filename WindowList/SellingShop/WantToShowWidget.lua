
--我要展示
local WantToShowWidget= UIControl:new
{
	windowName = "WantToShowWidget",
}

function WantToShowWidget:Attach(obj)
	UIControl.Attach(self,obj)
	return self
end