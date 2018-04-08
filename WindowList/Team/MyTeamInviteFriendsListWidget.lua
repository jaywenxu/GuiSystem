--我的队伍邀请面板玩家列表
------------------------------------------------------------
local MyTeamInviteFriendCellClass = require("GuiSystem.WindowList.Team.MyTeamInviteFriendCell")
------------------------------------------------------------
local MyTeamInviteFriendsListWidget =  UIControl:new
{
	windowName = "MyTeamInviteFriendsListWidget" ,
	m_EnhancedListView = nil,
	m_PanelType = nil,					--面板类型：我的好友 帮会成员 附近玩家
	
	PanelType = 
	{
		Myfriend = 1,
		Society = 2,
		Nearby = 3,
	},
	
	entitysWithoutPlayerUID = {},		--不包含玩家自身UID的实体表
}
------------------------------------------------------------
function MyTeamInviteFriendsListWidget:Attach( obj )
	UIControl.Attach(self,obj)
			
	self.callbackOnEnable = function() self:OnEnable() end
	self.unityBehaviour.onEnable:AddListener(self.callbackOnEnable) 
	
	self.callbackOnDisable = function() self:OnDisable() end
	self.unityBehaviour.onDisable:AddListener(self.callbackOnDisable) 
	
	self.m_EnhancedListView = self.transform:GetComponent(typeof(EnhancedListView))
	
	self.callBackOnGetCellView = function(objCell) self:OnGetCellView(objCell) end
	self.m_EnhancedListView.onGetCellView:AddListener(self.callBackOnGetCellView)
	
	self:OnEnable() 

	return self
end
------------------------------------------------------------
function MyTeamInviteFriendsListWidget:OnDestroy()
	self.unityBehaviour.onEnable:RemoveListener(self.callbackOnEnable) 
	self.unityBehaviour.onDisable:RemoveListener(self.callbackOnDisable) 
	self.m_EnhancedListView.onGetCellView:RemoveListener(self.callBackOnGetCellView)
	UIControl.OnDestroy(self)
end
------------------------------------------------------------
function MyTeamInviteFriendsListWidget:OnEnable() 
	print("MyTeamInviteFriendsListWidget:OnEnable() ")
	--根据面板的类型在每次面板加载时初始化面板上面的玩家
	if self.m_PanelType == MyTeamInviteFriendsListWidget.PanelType.Nearby then			--附近玩家
		self.entitys = EntityWorld:GetClassEntitys(tEntity_Class_Person)
		self.m_EnhancedListView:SetCellCount( #self.entitys , true )
	elseif self.m_PanelType == MyTeamInviteFriendsListWidget.PanelType.Myfriend then	--我的好友
		--print("我的好友")
		--print("1232123212321"..tostring(table.maxn(self:GetSocietyTestNameData())))
		self.m_EnhancedListView:SetCellCount( table.maxn(self:GetSocietyTestNameData()) , true )
		
		--print(self.m_EnhancedListView.CellCount)
	elseif self.m_PanelType == MyTeamInviteFriendsListWidget.PanelType.Society then		--帮会成员
		--print("帮会成员")
		self.m_EnhancedListView:SetCellCount( table.maxn(self:GetSocietyTestNameData()) , true )
	end
end
------------------------------------------------------------
function MyTeamInviteFriendsListWidget:OnDisable() 
	
end
------------------------------------------------------------
function MyTeamInviteFriendsListWidget:OnGetCellView(objCell) 
	--print(objCell.name)
	if self.m_PanelType == MyTeamInviteFriendsListWidget.PanelType.Nearby then			--附近玩家
		self.entitys = EntityWorld:GetClassEntitys(tEntity_Class_Person)
		self.entitysWithoutPlayerUID = {}
		local pHero = IGame.EntityClient:GetHero()
		if not pHero then
			return
		end
		local UID = pHero:GetUID()
		for i = 1,table.maxn(self.entitys) do
			if self.entitys[i]:GetUID() ~= UID then
				table.insert(self.entitysWithoutPlayerUID, self.entitys[i])
			end
		end
		
		if table.maxn( self.entitysWithoutPlayerUID) <= 0 then
			self.m_EnhancedListView.CellCount = 0
		else
			self.m_EnhancedListView.CellCount = table.maxn(self.entitysWithoutPlayerUID)
		end		
		
		if self.m_EnhancedListView.CellCount == 0 then
			return
		end
		
		local viewCell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))

		if viewCell.cellIndex < 0 then
			return
		end
		local index = viewCell.cellIndex + 1  --+1表示viewCell索引从0开始，而entity从1开始
											
		local name = self.entitysWithoutPlayerUID[index]:GetName()				
		local level = self.entitysWithoutPlayerUID[index]:GetNumProp(CREATURE_PROP_LEVEL)
		local item = MyTeamInviteFriendCellClass:new()
		item:Attach(objCell)
		item:OnRefreshCellView(name, level)
		item.m_Entity = self.entitysWithoutPlayerUID[index]
		
	elseif self.m_PanelType == MyTeamInviteFriendsListWidget.PanelType.Myfriend then	--我的好友
		
		self.m_EnhancedListView.CellCount = table.maxn(self:GetSocietyTestNameData())
		local viewCell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))
		if viewCell.cellIndex < 0 then
			return
		end
		local index = viewCell.cellIndex + 1  --+1表示viewCell索引从0开始，而entity从1开始	
		--print(viewCell.cellIndex)
		local nameTab = self:GetSocietyTestNameData()
		local levelTab = self:GetSocietyTestLevelData()			
		
		local name = nameTab[index]				
		local level = levelTab[index]
		
		--print(name)	
		local item = MyTeamInviteFriendCellClass:new()
		item:Attach(objCell)
		item:OnRefreshCellView(name, level)
		
		--print(self.m_EnhancedListView.CellCount)
		--print(self.transform.name)
	elseif self.m_PanelType == MyTeamInviteFriendsListWidget.PanelType.Society then		--帮会成员
		
		self.m_EnhancedListView.CellCount = table.maxn(self:GetSocietyTestNameData())
		local viewCell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))
		if viewCell.cellIndex < 0 then
			return
		end
		local index = viewCell.cellIndex + 1  --+1表示viewCell索引从0开始，而entity从1开始	
		--print(viewCell.cellIndex)
		local nameTab = self:GetSocietyTestNameData()
		local levelTab = self:GetSocietyTestLevelData()			
		
		local name = nameTab[index]				
		local level = levelTab[index]
			
		local item = MyTeamInviteFriendCellClass:new()
		item:Attach(objCell)
		item:OnRefreshCellView(name, level)
				
	end	
end
------------------------------------------------------------
function MyTeamInviteFriendsListWidget:GetSocietyTestNameData()
	local tab = {}
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end
	
	local UID = pHero:GetUID()
	--print(UID)
	local name = pHero:GetName()
	--print(name)
	
	table.insert(tab,name)
	table.insert(tab,"1234")
	table.insert(tab,"5678")
	table.insert(tab,"nihaoa")
	
	return tab
end
------------------------------------------------------------
function MyTeamInviteFriendsListWidget:GetSocietyTestLevelData()
	local tab = {}
	table.insert(tab,1)
	table.insert(tab,3)
	table.insert(tab,5)
	table.insert(tab,10)
	
	return tab
end
------------------------------------------------------------
return MyTeamInviteFriendsListWidget