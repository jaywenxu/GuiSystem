
--------------------------------------灵兽界面------------------------------------------
local PetDisplayWindow = UIWindow:new
{
	windowName 	= "PetDisplayWindow",
	
}	

function PetDisplayWindow:Init()

end

function PetDisplayWindow:OnAttach(obj)
	UIWindow.OnAttach(self,obj)	
end

function PetDisplayWindow:Show( bringTop )
	UIWindow.Show(self, bringTop)
end
 
function PetDisplayWindow:Hide(destory)
	
	UIWindow.Hide(self, destory)
end

function PetDisplayWindow:OnDestroy()
	
	UIWindow.OnDestroy(self)
end	

return PetDisplayWindow