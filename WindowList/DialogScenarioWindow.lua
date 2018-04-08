----------------------------------------------------------------
---------------------------------------------------------------
-- npc 对话窗口
----------------------------------------------------------------
------------------------------------------------------------
local DialogScenarioWindow = UIWindow:new
{
	windowName = "DialogScenarioWindow" ,
	
	m_needAwakeAfter = false,
	m_npcuid = 0,
	m_npcID = 0,
	m_contentText = "",
	m_taskID = 0,
	m_linkStr = "",
	m_topiclist = {},
}
local this = DialogScenarioWindow   -- 方便书写
------------------------------------------------------------
function DialogScenarioWindow:Init()
	self.DialogScenarioWidget = require("GuiSystem.WindowList.Dialog.DialogScenarioWidget")
	self.DialogTopicListWidget = require("GuiSystem.WindowList.Dialog.DialogTopicListWidget")
end
------------------------------------------------------------
function DialogScenarioWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.DialogScenarioWidget:Attach( self.Controls.m_DialogWidget.gameObject )
	self.DialogScenarioWidget:SetParentWindow(self)	
	self.DialogTopicListWidget:Attach( self.Controls.m_DialogTopicWidget.gameObject )
	self.DialogTopicListWidget:SetParentWindow(self)
	
	self.callbackCloseBtn = function() self:OnClickCloseButton() end
	self.Controls.m_CloseBtn.onClick:AddListener(self.callbackCloseBtn)
	if self.m_needAwakeAfter == true then
		self.m_needAwakeAfter = false
		self:OnNeedAwakeAfter()
	end
    return self
end
------------------------------------------------------------
function DialogScenarioWindow:OnDestroy()

	self:ClearInfo()
	UIWindow.OnDestroy(self)	
end

function DialogScenarioWindow:Hide( destroy )
	
	self:ClearInfo()
	UIWindow.Hide(self,destroy)
end

function DialogScenarioWindow:OnClickCloseButton()
	self:Hide()
end

------------------------------------------------------------
function DialogScenarioWindow:ClearInfo()

	if self:isLoaded() then
		self.DialogScenarioWidget:OnCloseWindow()
		self.DialogTopicListWidget:OnCloseWindow()
	end
	self.m_npcuid = 0
	self.m_npcID = 0
	self.m_contentText = ""
	self.m_npc = 0
	self.m_topiclist = {}
end

------------------------------------------------------------
-- 操作需要在 OnAttach 之后进行的操作
function DialogScenarioWindow:OnNeedAwakeAfter()
	self:ShowNpcDialog()
end

------------------------------------------------------------
-- 打开对话，开始对白
function DialogScenarioWindow:OpenDialog(npc,npcid,topiclist,contentText)
	
    -- 打开对白关闭 UIManager._WindowLayer 层
   
	-- 清空对白
	self:ClearInfo()
	self.m_npc = npc
	self.m_npcID = npcid
	self.m_contentText = contentText
	copy_table(self.m_topiclist,topiclist)

	if self:isLoaded() then
		self:ShowNpcDialog()
	else
		self.m_needAwakeAfter = true
	end

end

------------------------------------------------------------
-- 结束对白
function DialogScenarioWindow:HideDialogScenario()
	
	-- 清空数据，关闭对白
	self:ClearInfo()
	if self:isLoaded() then
		self:Hide()
	end
end

------------------------------------------------------------
-- 显示对白信息
function DialogScenarioWindow:ShowNpcDialog()
	
	local npcInfo = NPC_TABLE[self.m_npcID]
	if not npcInfo then
		self:HideDialogScenario()
		return
	end
	self.DialogScenarioWidget:ShowDialog(self.m_npcID,self.m_contentText)
	self.DialogTopicListWidget:ShowTopicList(self.m_npc,self.m_npcID,self.m_topiclist)
	self.transform:SetAsLastSibling()
end

------------------------------------------------------------
return this
