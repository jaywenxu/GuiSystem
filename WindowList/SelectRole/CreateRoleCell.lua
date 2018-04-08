------------------------------------------------------------
-- 创建角色单元,不要通过 UIManager 访问
-- 复用类
------------------------------------------------------------
local	CreateRoleCell = UIControl:new
{
    windowName = "CreateRoleCell" ,
	onItemSelectedCallBack = nil  ,   --  选中回调
}

local mName = "【角色创建单元】，"

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function CreateRoleCell:Attach( obj )
	UIControl.Attach(self,obj)
	
    self.callback_OnSwitchCreateRoleWindow = function( on ) self:OnSwitchToCreateRole(on) end
    self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))
    self.Controls.ItemToggle.onValueChanged:AddListener( self.callback_OnSwitchCreateRoleWindow )
    return self
end
------------------------------------------------------------
function CreateRoleCell:SetToggleGroup( toggleGroup )
    self.Controls.ItemToggle.group = toggleGroup
end
------------------------------------------------------------
function CreateRoleCell:OnSwitchToCreateRole( on )
	if self.onItemSelectedCallBack == nil then
		return
	end
	self.onItemSelectedCallBack( self )	
end
	
------------------------------------------------------------
function CreateRoleCell:SetItemCellSelectedCallback( cb )
	self.onItemSelectedCallBack = cb
end
------------------------------------------------------------
function CreateRoleCell:OnRecycle()
	self.onItemSelectedCallBack = nil
	self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callback_OnSwitchCreateRoleWindow )
end
------------------------------------------------------------
function CreateRoleCell:OnDestroy()
	self.onItemCellSelected = nil
	self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callback_OnSwitchCreateRoleWindow )
	
	UIControl.OnDestroy(self)
end

------------------------------------------------------------
return CreateRoleCell




