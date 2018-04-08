--组队系统喊话面板历史记录窗口项
---------------------------------------------------------------
local MyTeamHistoryListCell = UIControl:new
{
	windowName = "MyTeamHistoryListCell" ,
	m_Info = nil,
}
---------------------------------------------------------------
function MyTeamHistoryListCell:Attach( obj )
	UIControl.Attach(self,obj)
	self.transform.gameObject:SetActive(false)
	self.Controls.m_clickItem.onClick:AddListener(function() self:OnClickItem() end)
	if self.m_Info ~= nil then
		self.transform.gameObject:SetActive(true)
		self.Controls.m_Text.text = self.m_Info
	end
	
	return self
end
------------------------------------------------------------
function MyTeamHistoryListCell:OnDestroy()
	UIControl.OnDestroy(self)
end
---------------------------------------------------------------
--创建一个项
function MyTeamHistoryListCell.CreateACell(parentTransform)
	local item = MyTeamHistoryListCell:new()
	--异步加载NPC列表项
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.MyTeamHistoryListCell,
		function (path , obj , ud)
		if nil == obj then
			print("Failed to Load the object")
			return
		else
			obj.transform:SetParent(parentTransform,false)
			item:Attach(obj)
		end
	end,
	nil, AssetLoadPriority.GuiNormal )
	return item
end
---------------------------------------------------------------
--设置Cell内容
function MyTeamHistoryListCell:SetContent(info)
	self.m_Info = info
	if self.transform ~= nil then
		self.transform.gameObject:SetActive(true)
		self.Controls.m_Text.text = self.m_Info
	end
end
---------------------------------------------------------------
--设置定时器,第一次Cell transform没被关联时每次调用一次
function MyTeamHistoryListCell:UpdateContent()
	if self.transform == nil then
		return	
	end
	self.transform.gameObject:SetActive(true)
	self.Controls.m_Text.text = self.m_Info
	--print(self.Controls.m_Text.text)
	--rktTimer.KillTimer( self.callbackUpdateContent )	
end

function MyTeamHistoryListCell:OnClickItem()
	UIManager.TeamTalkWindow:SortFace(self.Controls.m_Text.text )
	UIManager.TeamTalkHistoryWindow:Hide(false)
end
---------------------------------------------------------------
return MyTeamHistoryListCell
