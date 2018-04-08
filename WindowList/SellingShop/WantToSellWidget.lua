
--我要出售
local WantToSellWidget= UIControl:new
{
	windowName = "WantToSellWidget",
}

function WantToSellWidget:Attach(obj)
	UIControl.Attach(self,obj)
	return self
end