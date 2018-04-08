


------------------------------------------------------------
local MakeFaceWindow = UIWindow:new
{
	windowName = "MakeFaceWindow" ,
	m_curVoaction = 0,		-- 职业
	m_nSex = 0,				-- 技能
}
------------------------------------------------------------
function MakeFaceWindow:Init()

end
------------------------------------------------------------
function MakeFaceWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	
	-- 返回按钮
	self.calbackReturnButtonClick = function() self:OnReturnButtonClick() end
	self.Controls.ReturnButton.onClick:AddListener( self.calbackReturnButtonClick )
	
	-- 下一步按钮
	self.calbackCreateRoleButtonClick = function() self:OnCreateRoleButtonClick() end
	self.Controls.NextButton.onClick:AddListener( self.calbackCreateRoleButtonClick )
	
    return self
end
------------------------------------------------------------
function MakeFaceWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------

function MakeFaceWindow:SetCurRoleInfo(nVocation,nSex)
	self.m_curVoaction = nVocation
	self.m_nSex = nSex
end

-- 返回
function MakeFaceWindow:OnReturnButtonClick()
	
	UIManager.MakeFaceWindow:Hide()
	UIManager.CreateRoleWindow:Show()
end

function MakeFaceWindow:OnCreateRoleButtonClick()
	
	local strActorName = self.Controls.NameInputField:GetComponent(typeof(InputField)).text
	
	if IsNilOrEmpty(strActorName) then
		return
	end 
	if string.len(strActorName) > 14 then
		-- uerror("=== CreateActor == Name length to long,length is: ",string.len(strActorName)) 这里应该弹窗提示用户而不是打印log
		return
	end
	
	IGame.SelectActorForm:CreateActor(self.m_curVoaction,self.m_nSex,strActorName)
end

return MakeFaceWindow
