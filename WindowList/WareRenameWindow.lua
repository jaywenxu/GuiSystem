-- 仓库重命名窗口
------------------------------------------------------------
local WareRenameWindow = UIWindow:new
{
	windowName = "WareRenameWindow",
	unlockSkepID = 0,
}
------------------------------------------------------------
function WareRenameWindow:Init()

end
------------------------------------------------------------
function WareRenameWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	self.Controls.m_Rename.onClick:AddListener(function() self:OnBtnRenameClick() end)
	self.Controls.m_Close.onClick:AddListener(function() self:OnBtnCloseClick() end)
	self.Controls.m_bgClose.onClick:AddListener(function() self:OnBtnCloseClick() end)
	
    return self
end
------------------------------------------------------------
function WareRenameWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------

-- 解锁目标
function WareRenameWindow:SetUnlockSkep(DBSkepID)
	self.unlockSkepID = DBSkepID
end

-- 确认按钮
function WareRenameWindow:OnBtnConfirmClick()
	UIManager.WareRenameWindow:Hide()
	
	local rowCellCount = UIManager.PackWindow:GetRowCellCount(self.unlockSkepID)
	local costDiamond = rowCellCount * 6
	-- todo: 计算钻石价格，判断钻石是否足够
	
	local msg = {nDBSkepID = self.unlockSkepID, nUnlockNum = rowCellCount}
	IGame.Network:Send(msg, MSG_MODULEID_SKEP, MSG_SKEP_UNLOCK_CS, MSG_ENDPOINT_ZONE)
end

-- 重命名
function WareRenameWindow:OnBtnRenameClick()
	local newName = self.Controls.m_Name.text 
	-- 计算中文字符串的个数
	local _, count   =  string.gsub(newName, "[^\128-\193]", "")
	if count > 4 then
	   IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "仓库名长度不能超过4个字") 
	   return 
	elseif count <= 0 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "仓库名长度不能为空！") 
	   return 
	end
	-- 仓库名有屏蔽字，不能修改
	if StringFilter.FilterKeyWord(newName) then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "仓库名含有屏蔽字，不能修改！") 
		return
	end
	-- 仓库名含有空格，不能修改
	if StringFilter.CheckMoreSpaceStr(newName, 1) then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "仓库名含有空格，不能修改！") 
		return
	end
	if IGame.SkepClient:IsExistWareName(newName) then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "仓库名字重复") 
		return
	end
	UIManager.PackWindow:RenameWareLabel(newName)
end

-- 关闭按钮
function WareRenameWindow:OnBtnCloseClick()
	UIManager.WareRenameWindow:Hide()
end

return WareRenameWindow