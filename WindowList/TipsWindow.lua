-- 提示窗口
------------------------------------------------------------
local TipsWindow = UIWindow:new
{
	windowName = "TipsWindow",
	unlockSkepID = 0,
	m_UidTable = {}
}
------------------------------------------------------------
function TipsWindow:Init()

end
------------------------------------------------------------
function TipsWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	self.Controls.m_ConfirmBtn.onClick:AddListener(function() self:OnBtnConfirmClick() end)
	self.Controls.m_Close.onClick:AddListener(function() self:OnBtnCloseClick() end)
	self.Controls.m_CancelBtn.onClick:AddListener(function() self:OnBtnCloseClick() end)
    return self
end
------------------------------------------------------------
function TipsWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------

-- 解锁目标
function TipsWindow:SetUnlockSkep(DBSkepID)
	self.unlockSkepID = DBSkepID
end


-- 重命名
function TipsWindow:OnBtnConfirmClick()
	local strfun = "RequestBatchEquipDecompose('"..tableToString(self.m_UidTable).."')"
	GameHelp.PostServerRequest(strfun)   
    UIManager.PackWindow:NextConfirmDecompose()
	self:Hide()
end

function TipsWindow:SetUidTable(equipDecomposeUidTable)
	self.m_UidTable = equipDecomposeUidTable
end
-- 关闭按钮
function TipsWindow:OnBtnCloseClick()
	UIManager.TipsWindow:Hide()
end

return TipsWindow