--组队系统中邀请玩家的窗口
---------------------------------------------------------------
local MyTeamInviteFriendsListWidgetClass = require("GuiSystem.WindowList.Team.MyTeamInviteFriendsListWidget")
---------------------------------------------------------------
local TeamInviteFriendsWindow = UIWindow:new
{
	windowName = "TeamInviteFriendsWindow" ,
	
	m_FriendPanelListWidget = nil,
	m_SocietyPanelListWidget = nil,
	m_NearbyPanelListWidget = nil,
}
---------------------------------------------------------------
function TeamInviteFriendsWindow:Init()
	self.m_FriendPanelListWidget = MyTeamInviteFriendsListWidgetClass:new()
	self.m_SocietyPanelListWidget = MyTeamInviteFriendsListWidgetClass:new()
	self.m_NearbyPanelListWidget = MyTeamInviteFriendsListWidgetClass:new()	
end
---------------------------------------------------------------
function TeamInviteFriendsWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	self.callbackOnCloseButtonClick = function() self:OnCloseButtonClick() end
	self.Controls.m_CloseButton.onClick:AddListener(self.callbackOnCloseButtonClick)
	
	self.m_FriendPanelListWidget.m_PanelType = MyTeamInviteFriendsListWidgetClass.PanelType.Myfriend
	self.m_SocietyPanelListWidget.m_PanelType = MyTeamInviteFriendsListWidgetClass.PanelType.Society
	self.m_NearbyPanelListWidget.m_PanelType = MyTeamInviteFriendsListWidgetClass.PanelType.Nearby
	
	self.m_FriendPanelListWidget:Attach(self.Controls.m_FriendPanelList.gameObject)
	self.m_SocietyPanelListWidget:Attach(self.Controls.m_SocietyPanelList.gameObject)
	self.m_NearbyPanelListWidget:Attach(self.Controls.m_NearbyPanelList.gameObject)
	
	return self
end
---------------------------------------------------------------
function TeamInviteFriendsWindow:OnDestroy()
	
	--self.Controls.m_CloseButton.onClick:RemoveListener(self.callbackOnCloseButtonClick)	
	UIWindow.OnDestroy(self)
end
---------------------------------------------------------------
function TeamInviteFriendsWindow:OnCloseButtonClick() 
	UIManager.TeamInviteFriendsWindow:Hide()
end
---------------------------------------------------------------
return TeamInviteFriendsWindow