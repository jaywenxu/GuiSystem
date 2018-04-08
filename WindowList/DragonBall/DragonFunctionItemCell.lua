------------------------------------------------------------
-- DragonBallWindow 的子窗口,不要通过 UIManager 访问
------------------------------------------------------------
-- 功能函数小类
------------------------------------------------------------
local DragonFunctionItemCell = UIControl:new
{
	windowName = "DragonFunctionItemCell" ,
	m_szfunc = nil,
	m_paramList = {},
	m_paramCell = {},
}

local this = DragonFunctionItemCell   -- 方便书写


------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function DragonFunctionItemCell:Attach( obj )
	UIControl.Attach(self,obj)
	self.callbackToggleChangeed = function( on ) self:OnSelectToggleChanged(on) end 
    self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))
    self.Controls.ItemToggle.onValueChanged:AddListener( self.callbackToggleChangeed )
	
    return self
end
------------------------------------------------------------
function DragonFunctionItemCell:SetToggleGroup( toggleGroup )
    self.Controls.ItemToggle.group = toggleGroup
end

------------------------------------------------------------
function DragonFunctionItemCell:OnDestroy()
	self.m_szfunc = nil
	self.m_paramList = {}
	UIControl.OnDestroy(self)
end

------------------------------------------------------------
function DragonFunctionItemCell:OnSelectToggleChanged( on )
	-- 按钮选中
	if not on then
		return
	end
	
	if not self.m_paramList or type(self.m_paramList) ~= 'table' then
		return
	end
	UIManager.DragonBallWindow:SetCurFunctionParam(self.m_szfunc, self.m_paramList)
end

------------------------------------------------------------
function DragonFunctionItemCell:ClearInfo()
	self.m_itemInfo = nil
end

------------------------------------------------------------
function DragonFunctionItemCell:SetItemInfo(szfunc,szTitle,paramList)
	
	self.m_szfunc = tostring(szfunc)
	self.Controls.TitleText.text = tostring(szTitle)
	copy_table(self.m_paramList, paramList)
end
------------------------------------------------------------
function DragonFunctionItemCell:OnRecycle()
	self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callbackToggleChangeed )
end
------------------------------------------------------------

return this