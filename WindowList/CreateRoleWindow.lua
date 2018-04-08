------------------------------------------------------------
local CreateRoleWindow = UIWindow:new
{
	windowName = "CreateRoleWindow" ,
	
	m_CurActorName = ""
}
local this = CreateRoleWindow   -- 方便书写
------------------------------------------------------------
function CreateRoleWindow:Init()
   
end
------------------------------------------------------------
function CreateRoleWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	-- 返回按钮
	self.calbackRetuanButtonClick = function() self:OnReturnButtonClick() end
	self.Controls.ReturnButton.onClick:AddListener( self.calbackRetuanButtonClick )
	
	-- 下一步按钮
	self.calbackNextButtonClick = function() self:OnNextButtonClick() end
	self.Controls.NextButton.onClick:AddListener( self.calbackNextButtonClick )
	
	
    return self
end
------------------------------------------------------------
------------------------------------------------------------
function CreateRoleWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

------------------------------------------------------------
function CreateRoleWindow:UpdateInfo()
	
end

------------------------------------------------------------
-- 返回
function CreateRoleWindow:OnReturnButtonClick()
	
	UIManager.CreateRoleWindow:Hide()
	UIManager.SelectRoleWindow:Show()
	
end

------------------------------------------------------------
-- 下一个
function CreateRoleWindow:OnNextButtonClick()
	
	UIManager.CreateRoleWindow:Hide()
	UIManager.MakeFaceWindow:Show()
	
	local nVocation = 0 -- 先暂时这么填，职业0,2,3 已经有模板，1没有模板
	local nSex = 0		-- 0男性，1女性
	UIManager.MakeFaceWindow:SetCurRoleInfo(nVocation,nSex)
	
end


------------------------------------------------------------
return this
