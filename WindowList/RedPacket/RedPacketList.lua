

-- 红包显示列表

------------------------------------------------------------
local RedPacketList = UIControl:new
{
	windowName = "RedPacketList",
	currentPage = 0,
	packetDatas = {},
	attachItem ={}
}

local RedPacketItem = require("GuiSystem.WindowList.RedPacket.RedPacketItem")
local MAX_LINE_COUNT =4
function RedPacketList:Attach(obj, parent)
    UIControl.Attach(self, obj)
	
	self.m_EnhancedListView = obj:GetComponent(typeof(EnhancedListView))
	self.m_EnhancedScroller = obj:GetComponent(typeof(EnhancedScroller))
	
	self:AddListener(self.m_EnhancedListView, "onGetCellView", self.OnGetCellView, self)
	self:AddListener(self.m_EnhancedListView, "onCellViewVisiable", self.OnCellViewVisiable, self)
	self.m_EnhancedScroller.scrollerScrollingChanged = handler(self, self.OnEnhancedScrollerScrol)
end

--item创建时调用
function RedPacketList:OnGetCellView(goCell)
	local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
	enhancedCell.onRefreshCellView = handler(self, self.OnRefreshCellView)
	local count =  enhancedCell.transform.childCount

	for i=1,MAX_LINE_COUNT do 
		local obj = enhancedCell.transform:GetChild(i-1)
		local index = enhancedCell.dataIndex * MAX_LINE_COUNT + i

		if enhancedCell.dataIndex ==  self.m_EnhancedListView.CellCount-1 then 
			if i >  self.otherCount and self.otherCount ~= 0 then 
				obj.gameObject:SetActive(false)
			else
				obj.gameObject:SetActive(true)
			end
		else
			obj.gameObject:SetActive(true)
		end
		
		if self.attachItem[tostring(index)] == nil and obj.gameObject.name ~= "attach"  then 
			local item = RedPacketItem:new({})
			item:Attach(obj.gameObject)
			obj.gameObject.name ="attach"
			self.attachItem[tostring(index)] = item
		end
		
	end

	
end

function RedPacketList:OnDestroy()
	self:RemoveListener(self.m_EnhancedListView, "onGetCellView", self.OnGetCellView, self)
	self:RemoveListener(self.m_EnhancedListView, "onCellViewVisiable", self.OnCellViewVisiable, self)
	self.attachItem = {}
	UIControl.OnDestroy(self)
end

--刷新每一行的每一个红包
function RedPacketList:RereshCellItem(item,index)
	if index > #self.packetDatas then 
		return
	end
	if item == nil or index > #self.packetDatas then 
		return
	end
	local itemInfo = self.packetDatas[index]
	item:UpdateItem(self.currentPage, itemInfo)
end

--刷新item时调用
function RedPacketList:OnRefreshCellView(goCell)
	local count = goCell.transform.childCount
	local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
	
	for i=1,count do 
		local item =enhancedCell.transform:GetChild(i-1)
		if item ~= nil then 
			local index = enhancedCell.dataIndex * MAX_LINE_COUNT + i
			if enhancedCell.dataIndex ==  self.m_EnhancedListView.CellCount-1 then 
				if i > self.otherCount and self.otherCount ~= 0 then 
					item.gameObject:SetActive(false)
				else
					item.gameObject:SetActive(true)
				end
			else
				item.gameObject:SetActive(true)
			end
			
			local behav = item:GetComponent(typeof(UIWindowBehaviour))
			local itemLua = behav.LuaObject
			self:RereshCellItem(itemLua,index)

		end
	end

end

--item可见时调用
function RedPacketList:OnCellViewVisiable(goCell)
	local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:OnRefreshCellView(goCell)
end

--Scroll 滚动时调用
function RedPacketList:OnEnhancedScrollerScrol(scroller, scrolling)
	
end

function RedPacketList:SetCellCount(page)
	self.currentPage = page
	self.packetDatas = {}
	
	if self.currentPage == 1 then
		self.packetDatas = IGame.RedEnvelopClient:GetWorldRedEnvelop()
	elseif self.currentPage == 2 then
		self.packetDatas = IGame.RedEnvelopClient:GetClanRedEnvelop()
	else
		self.packetDatas = IGame.RedEnvelopClient:GetTeamRedEnvelop()
	end
	
	local cellCount = #self.packetDatas
	self.otherCount = cellCount % MAX_LINE_COUNT
	self.item_count  = 0
	if cellCount ~= 0 then
		self.item_count = math.ceil(cellCount/MAX_LINE_COUNT)
		
	end
	
	if self.item_count == self.m_EnhancedListView.CellCount then 
		self.m_EnhancedScroller:RefreshActiveCellViews()
	else
		self.m_EnhancedListView:SetCellCount(self.item_count, true)
	end
	
	local world =
	{
		"世界",
		"帮会" ,
		"队伍"
	}
	
	local pageStr = world[page]
	if cellCount == 0 then 
		self.Controls.m_noRedText.text = string.format("当前没有%s红包",pageStr)
		self.Controls.m_NoRedPacket.gameObject:SetActive(true)
	else
		self.Controls.m_noRedText.text = ""
		self.Controls.m_NoRedPacket.gameObject:SetActive(false)
	end
	
end

return RedPacketList