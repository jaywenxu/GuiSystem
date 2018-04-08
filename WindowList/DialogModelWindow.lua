
----------------------------------------------------------------
---------------------------------------------------------------
-- 任务对话弹窗
----------------------------------------------------------------
------------------------------------------------------------
local DialogModelWindow = UIWindow:new
{
	windowName = "DialogModelWindow" ,
	m_windowType = 1,         -- 窗口类型 1：普通   2：任务奖励窗口						
	m_needAwakeAfter = false,
	m_npcid,
	m_linkStr,				-- 链接
	m_taskInfo,				-- 任务信息
    m_openInfo = nil ,      -- {}
}
local this = DialogModelWindow   -- 方便书写
------------------------------------------------------------
function DialogModelWindow:Init()
	-- 普通
	self.DialogModelWidget = require("GuiSystem.WindowList.Dialog.DialogModelWidget")
end
------------------------------------------------------------
function DialogModelWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.DialogModelWidget:Attach( self.Controls.m_DialogWidget.gameObject )
	self.DialogModelWidget:SetParentWindow(self)
	self.Controls.m_DialogWidget.gameObject:SetActive(true)
	
	if self.m_needAwakeAfter == true then
		self.m_needAwakeAfter = false
	end

    if nil ~= self.m_openInfo then
        local info = self.m_openInfo
        self.m_openInfo = nil
        self:ShowSceneDialog(info.npcid,info.dialog_content,info.dialog_id,info.linkstr,info.taskInfo)
    end
    self:AddListener(self.Controls.m_skipButton, "onClick", self.OnSkipButtonClick, self)
end
------------------------------------------------------------
------------------------------------------------------------
function DialogModelWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

function DialogModelWindow:Hide( destroy )
	
	UIWindow.Hide(self,destroy)
end

------------------------------------------------------------
-- 操作需要在 OnAttach 之后进行的操作
function DialogModelWindow:OnNeedAwakeAfter()
	
end

------------------------------------------------------------
-- 打开情景对白
function DialogModelWindow:OpenSceneDialog(npcid,dialog_content,dialog_id,linkstr,taskInfo)
    if not self:isLoaded() then
        self.m_openInfo = { npcid = npcid , dialog_content = dialog_content , dialog_id = dialog_id , linkstr = linkstr , taskInfo = taskInfo }
        return
    end
	self:ShowSceneDialog(npcid,dialog_content,dialog_id,linkstr,taskInfo)
end

------------------------------------------------------------
-- 关闭情景对白
function DialogModelWindow:HideDialogModel()
	
	if self:isLoaded() then
		self:Hide()
	end
    self:ShowHudWindow(true)
end

------------------------------------------------------------
-- 显示情景对白
function DialogModelWindow:ShowSceneDialog(npcid,dialog_content,dialog_id,linkstr,taskInfo)
	self.m_linkStr = linkstr
	self.m_npcid = npcid
	self.m_taskInfo = taskInfo
	-- 如果没有配则用默认的任务显示框框显示
	if dialog_id <= 0 then
		self.DialogModelWidget:ShowSceneDialog(npcid,dialog_content,dialog_id,linkstr)
		self:ShowHudWindow(true)
		return
	end
	
	-- 获取配置
	local pSchemeInfo = IGame.rktScheme:GetSchemeInfo(SCENEDIALOG_CSV, dialog_id)
	if not pSchemeInfo then
		return
	end
	
	self.DialogModelWidget:ShowSceneDialog(npcid,dialog_content,dialog_id,linkstr)
	self:ShowHudWindow(true)
end

-- 显示任务奖励窗口
function DialogModelWindow:showTaskPrizeWindow()
	self:HideDialogModel()
	UIManager.CommonPrizeWindow:Show(true)
    UIManager.CommonPrizeWindow:ShowSceneDialog(self.m_npcid,self.m_linkStr,self.m_taskInfo)
end

------------------------------------------------------------
function DialogModelWindow:ShowHudWindow( bShow )
    UIManager.ShowHudWindow( bShow )
end
------------------------------------------------------------
-- 跳过按钮响应
function DialogModelWindow:OnSkipButtonClick()
    self.DialogModelWidget:SkipDialog()
end

return this
