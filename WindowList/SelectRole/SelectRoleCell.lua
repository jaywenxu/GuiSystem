------------------------------------------------------------
-- 角色选择单元,不要通过 UIManager 访问
-- 复用类
------------------------------------------------------------
local	SelectRoleCell = UIControl:new
{
    windowName = "SelectRoleCell" ,
	onItemSelectedCallBack = nil  ,   --  选中回调
	m_curActorName = "", 	-- 当前角色的名称
	m_widget = nil,
}

local mName = "【角色选择单元】"

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function SelectRoleCell:Attach( obj )
	UIControl.Attach(self,obj)
	
    self.callback_OnSelectChangeRole = function( on ) self:OnSelectRole(on) end 
    self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))
    self.Controls.ItemToggle.onValueChanged:AddListener( self.callback_OnSelectChangeRole )
	
    return self
end
------------------------------------------------------------
function SelectRoleCell:SetToggleGroup( toggleGroup )
    self.Controls.ItemToggle.group = toggleGroup
end

------------------------------------------------------------
function SelectRoleCell:SetParentWidget( pwidget )
    self.m_widget = pwidget
end
------------------------------------------------------------
function SelectRoleCell:OnSelectRole( on )
	if nil ~= self.onItemSelectedCallBack then
		self.onItemSelectedCallBack( self ,self.m_widget, on )
	end
end

------------------------------------------------------------
-- 设置单元信息
function SelectRoleCell:ClearInfo()
	self.m_curActorName = ""
	self.Controls.m_LevelText.text = ""
end


------------------------------------------------------------
-- 设置单元信息
function SelectRoleCell:UpdateItemInfo(actorInfo)

	if actorInfo == nil then
		return
	end
	self.m_curActorName = tostring(actorInfo.szActorName)
	self.Controls.m_LevelText.text = tostring(actorInfo.nLevel)
	
	-- m_BgImage
	-- m_SelectedImage
end

------------------------------------------------------------
-- 获取玩家名字
function SelectRoleCell:GetPlayerName()
	return self.Controls.m_PlayerName.text
end

------------------------------------------------------------
-- 获取玩家等级
function SelectRoleCell:GetPlayerLevel()
	return self.Controls.m_LevelText.text
end

------------------------------------------------------------
-- 选择的角色弹出删除按钮
function SelectRoleCell:SelectRoleDelActor()
	
	local win = self:GetRoleDeleteDialog()
	win:OpenRoleDeleteDialog(true)
end

------------------------------------------------------------
function SelectRoleCell:SetItemCellSelectedCallback( cb )
	self.onItemSelectedCallBack = cb
end

------------------------------------------------------------
function SelectRoleCell:OnRecycle()
	self.onItemSelectedCallBack = nil
	self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callback_OnSelectChangeRole )
end

------------------------------------------------------------
function SelectRoleCell:OnDestroy()
	self.onItemSelectedCallBack = nil
	self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callback_OnSelectChangeRole )
	
	UIControl.OnDestroy(self)
end

------------------------------------------------------------
function SelectRoleCell:ClearInfo()
end

------------------------------------------------------------
return SelectRoleCell




