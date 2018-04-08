------------------------------------------------------------
-- DragonBallWindow 的子窗口,不要通过 UIManager 访问
------------------------------------------------------------
-- 功能函数模块类
------------------------------------------------------------
local DragonFunctionModuleCell = UIControl:new
{
	windowName = "DragonFunctionModuleCell" ,
	m_curFunc = "",
	m_curName = "",
}

local this = DragonFunctionModuleCell   -- 方便书写


------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function DragonFunctionModuleCell:Attach( obj )
	UIControl.Attach(self,obj)

	self.callbackToggleChange = function( on ) self:OnSelectToggleChanged(on) end 
    self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))
    self.Controls.ItemToggle.onValueChanged:AddListener( self.callbackToggleChange )
    return self
end
------------------------------------------------------------
function DragonFunctionModuleCell:SetToggleGroup( toggleGroup )
    self.Controls.ItemToggle.group = toggleGroup
end

------------------------------------------------------------
function DragonFunctionModuleCell:OnDestroy()
	self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callbackToggleChange )
	self.m_curFunc = ""
	self.m_curName = ""
	UIControl.OnDestroy(self)
end

------------------------------------------------------------
function DragonFunctionModuleCell:OnSelectToggleChanged( on )
	if not on then
		return
	end
	if IsNilOrEmpty(self.m_curFunc) then
		return
	end
	local szFunc = self.m_curFunc.."()"
	GameHelp.PostServerRequest(szFunc)
end

------------------------------------------------------------
function DragonFunctionModuleCell:ClearInfo()
	self.m_itemInfo = nil
end

------------------------------------------------------------
function DragonFunctionModuleCell:SetItemInfo(szfunc,szName)

	self.m_curFunc = tostring(szfunc)
	self.m_curName = szName or ""
	self.Controls.TitleText.text = tostring(self.m_curName)
end
------------------------------------------------------------
function DragonFunctionModuleCell:OnRecycle()
	self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callbackToggleChange )
end
------------------------------------------------------------
return this