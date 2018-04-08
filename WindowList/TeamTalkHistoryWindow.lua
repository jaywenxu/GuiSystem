--组队系统喊话面板历史记录窗口
---------------------------------------------------------------
local MyTeamHistoryListCellClass = require("GuiSystem.WindowList.Team.MyTeamHistoryListCell")
---------------------------------------------------------------
local TeamTalkHistoryWindow = UIWindow:new
{
	windowName = "TeamTalkHistoryWindow" ,

	m_List = nil,						--Unity场景中的记录cell父节点
	
	m_HistoryList = {},					--喊话历史记录列表
	--m_HistoryListStartIndex = 1,		--列表开始索引
	--m_HistoryListEndIndex = 1,			--列表结束索引
	m_HistoryListMaxLength = 10,		--列表最大长度
	m_HistoryListCount = 0,				--列表当前计数
	m_HistoryCellList = {},				--cell列表
}
---------------------------------------------------------------
function TeamTalkHistoryWindow:Init()
		
end
---------------------------------------------------------------
function TeamTalkHistoryWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	self.callbackOnBackButtonClick = function() self:OnBackButtonClick() end
	self.Controls.m_BackButton.onClick:AddListener(self.callbackOnBackButtonClick)
	
	
	local item = nil
	for i = 1,self.m_HistoryListMaxLength do
		--在显示面板创建一个Cell
		item = MyTeamHistoryListCellClass.CreateACell(self.Controls.m_List.transform)
		self.m_HistoryCellList[i] = item
	end

	self:ShowHistory()
	return self
end
---------------------------------------------------------------
function TeamTalkHistoryWindow:OnDestroy()
	--self.Controls.m_BackButton.onClick:RemoveListener(self.callbackOnBackButtonClick)
	
	UIWindow.OnDestroy(self)
end
---------------------------------------------------------------
--返回按钮
function TeamTalkHistoryWindow:OnBackButtonClick() 
	UIManager.TeamTalkHistoryWindow:Hide()
end
---------------------------------------------------------------
--显示当前所有的历史消息
function TeamTalkHistoryWindow:ShowHistory()
	--[[改前
	if self.m_HistoryListEndIndex < self.m_HistoryListStartIndex then
		for i = self.m_HistoryListEndIndex,self.m_HistoryListStartIndex do
			if self.m_HistoryList[i] ~= nil then
				self.m_HistoryCellList[i]:SetContent(self.m_HistoryList[i])
			end
		end
	else
	self.m_HistoryCellList[self.m_HistoryListStartIndex]:SetContent(self.m_HistoryList[self.m_HistoryListStartIndex])
		for i = self.m_HistoryListEndIndex,self.m_HistoryListMaxLength do
			self.m_HistoryCellList[i]:SetContent(self.m_HistoryList[i])
		end
		for i = 1,self.m_HistoryListStartIndex - 1 do
			if self.m_HistoryList[i] ~= nil then
				self.m_HistoryCellList[i]:SetContent(self.m_HistoryList[i])
			end
		end
	end	
	]]--
	--改后
	for i = 1, self.m_HistoryListCount do
		self.m_HistoryCellList[i]:SetContent(self.m_HistoryList[i])
	end
    
	if self.m_HistoryListCount > 0 then 
		self.Controls.m_NoHistory.gameObject:SetActive(false)
	else
		self.Controls.m_NoHistory.gameObject:SetActive(true)
	end
end
---------------------------------------------------------------
--向历史记录列表添加一条消息，如果超过最大信息数，则替换最早的信息
function TeamTalkHistoryWindow:AddAnInfo(info)
	if nil == info then
		return
	end
	
	--[[改前
	if self.m_HistoryListCount <= self.m_HistoryListMaxLength then
		self.m_HistoryListCount = self.m_HistoryListCount + 1
	end
	
	self.m_HistoryList[self.m_HistoryListStartIndex] = info
	self.m_HistoryListStartIndex = self.m_HistoryListStartIndex + 1
	if self.m_HistoryListStartIndex > self.m_HistoryListMaxLength then
		self.m_HistoryListStartIndex = 1	
	end
	
	if self.m_HistoryListStartIndex == self.m_HistoryListEndIndex then
		self.m_HistoryListEndIndex = self.m_HistoryListEndIndex + 1
		if self.m_HistoryListEndIndex > self.m_HistoryListMaxLength then
			self.m_HistoryListEndIndex = 1
		end
	end
	]]--
	local count = #self.m_HistoryList
	local item
	for i=1,count do
		item = self.m_HistoryList[i]
		if item ==  info then
			return
		end
	end
	--改后
	if self.m_HistoryListCount < self.m_HistoryListMaxLength then
		self.m_HistoryListCount = self.m_HistoryListCount + 1
		self.m_HistoryList[self.m_HistoryListCount] = info
	else
		for i = 1,self.m_HistoryListMaxLength - 1 do
			--前移元素
			self.m_HistoryList[i] = self.m_HistoryList[i + 1]
		end
		self.m_HistoryList[self.m_HistoryListMaxLength] = info
	end
	
end
---------------------------------------------------------------


---------------------------------------------------------------
return TeamTalkHistoryWindow