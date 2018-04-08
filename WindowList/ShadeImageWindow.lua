-- 界面窗口的背景
------------------------------------------------------------
local ShadeImageWindow = UIWindow:new
{
	windowName = "ShadeImageWindow" ,
}
------------------------------------------------------------
function ShadeImageWindow:Init()
end
------------------------------------------------------------

------------------------------------------------------------
function ShadeImageWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	ShadeImageWindow:SetParentAndShow(obj)
end


--挂载
function ShadeImageWindow:SetParentAndShow(obj)
	UIManager.AttachToLayer( obj , UIManager._BackgroundLayer ) 
	obj.transform:SetAsFirstSibling()
end

return ShadeImageWindow
