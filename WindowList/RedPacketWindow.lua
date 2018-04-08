

-- 红包主界面

------------------------------------------------------------
local RedPacketWindow = UIWindow:new
{
	windowName = "RedPacketWindow" ,
	currentPage = 0,                 --当前标签页
	titleImagePath = AssetPath.TextureGUIPath.."Strength/stronger_baoti_qianghua_1.png",
	m_EventHandler = {},
	m_initPage = 1,
}

function RedPacketWindow:Init()
	self.RedPacketList = require("GuiSystem.WindowList.RedPacket.RedPacketList"):new()
	self.RedPacketSend = require("GuiSystem.WindowList.RedPacket.RedPacketSend"):new()
end

-- 订阅事件
function RedPacketWindow:SubscribeWinExecute()
	self.m_EventHandler = 
	{
		{
			event = MSG_MODULEID_REDENVELOP, srcid = EVENT_RED_PACKET_LIST, srctype = SOURCE_TYPE_SYSTEM, 
			func = function(event, srctype, srcid) self:callback_RedPacketList() end,
		},
		
		{
			event = MSG_MODULEID_REDENVELOP, srcid = EVENT_RED_PACKET_RECORD, srctype = SOURCE_TYPE_SYSTEM, 
			func = function(event, srctype, srcid) self:callback_RedPacketRecord() end,
		},
		
		{
			event = MSG_MODULEID_REDENVELOP, srcid = EVENT_RED_PACKET_OPEN, srctype = SOURCE_TYPE_SYSTEM, 
			func = function(event, srctype, srcid) self:callback_RedPacketOpen() end,
		},
		
		{
			event = EVENT_UI_REDDOT_UPDATE, srcid = REDDOT_UI_EVENT_REPACKET_PAGE, srctype = SOURCE_TYPE_SYSTEM, 
			func = function(event, srctype, srcid) self:RefreshRedDot() end,
		},
	}
	
	for k, v in pairs(self.m_EventHandler) do
		rktEventEngine.SubscribeExecute(v.event, v.srctype, v.srcid, v.func)
	end
end

-- 取消订阅事件
function RedPacketWindow:UnSubscribeWinExecute()
	for k, v in pairs(self.m_EventHandler) do
		rktEventEngine.UnSubscribeExecute(v.event, v.srctype, v.srcid, v.func)
	end
	self.m_EventHandler = {}
end

--更新红包领取信息
function RedPacketWindow:callback_RedPacketRecord()
	self:RefreshWindow()
end

--更新红包列表
function RedPacketWindow:callback_RedPacketList()
	self.RedPacketList:SetCellCount(self.currentPage)
end

--打开红包回调
function RedPacketWindow:callback_RedPacketOpen()
	self.RedPacketList:SetCellCount(self.currentPage)
end

function RedPacketWindow:OnAttach(obj)
	UIWindow.OnAttach(self, obj)

	self:SubscribeWinExecute()
--[[	
	UIWindow.AddCommonWindowToThisWindow(self, true, self.titleImagePath, 
		handler(self, self.OnClose))--]]
		
	if self.RedPacketList == nil then 
		uerror("qqqqqq")
	end
	
	self.RedPacketList:Attach(self.Controls.m_packetListPanel.gameObject)
	self.RedPacketSend:Attach(self.Controls.m_sendPanel.gameObject)
	
	self.Controls.Page = 
	{
		self.Controls.m_worldPage,
		self.Controls.m_gangPage,
		self.Controls.m_teamPage,
	}
	
	for i=1, 3 do
		self.Controls.Page[i].onValueChanged:AddListener(function(isOn)
			self:OnPageChange(isOn, i)
		end)
	end
	
	self:AddListener(self.Controls.m_sendPacket, "onClick", self.OnSendPacket, self)
	self:AddListener(self.Controls.m_refreshPacket, "onClick", self.OnRefreshPacket, self)
	self:AddListener(self.Controls.m_closeBtn, "onClick", self.OnClose, self)
	if nil ~= self.m_cacheRefreshInfo then
		self.m_cacheRefreshInfo = nil
		self:OnPageChange(true, self.m_initPage)
	end
	
	self:RefreshWindow()
	
	self:RefreshRedDot()
end

function RedPacketWindow:OpenPanel(type)
	if not IGame.RedEnvelopClient:IsCanUseRedEnvelop() then
		return
	end
	
	type = type or 1
	self.m_initPage = type
	UIManager.RedPacketWindow:Show()
	UIManager.RedPacketWindow:OnPageChange(true, type)
end

--标签页
function RedPacketWindow:OnPageChange(isOn, page)
	if not self:isLoaded() then
        self.m_cacheRefreshInfo = true
        return
    end
	
	if isOn then
		if self.currentPage ~= page then
			self.currentPage = page
			local packet_type
			if self.currentPage == 1 then
				packet_type = emRED_ENVELOP_TYPE_WORLD
			elseif self.currentPage == 2 then
				packet_type = emRED_ENVELOP_TYPE_CLAN
			else
				packet_type = emRED_ENVELOP_TYPE_TEAM
			end
			self.Controls.m_sendPacket.gameObject:SetActive(packet_type ~= emRED_ENVELOP_TYPE_TEAM)
			IGame.RedEnvelopClient:OnRequestRedenvelopList(packet_type)
			self.Controls.Page[page].isOn = true
		end
	end
end

function RedPacketWindow:RefreshWindow()
	if not self:isLoaded() then
		return
	end
	
	self.Controls.m_sendTime.text = "已发："..IGame.RedEnvelopClient.m_recordSendTimes.."个"
	self.Controls.m_sendSilver.text = tostringEx(IGame.RedEnvelopClient.m_recordSendMoney)
	self.Controls.m_getTime.text = "已收："..IGame.RedEnvelopClient.m_recordGetTimes.."个"
	self.Controls.m_getSilver.text = tostringEx(IGame.RedEnvelopClient.m_recordGetMoney)
end

--发红包按钮
function RedPacketWindow:OnSendPacket()
	self.RedPacketSend:OpenSendPanel(self.currentPage)
end

--刷新按钮
function RedPacketWindow:OnRefreshPacket()
	local packet_type
	if self.currentPage == 1 then
		packet_type = emRED_ENVELOP_TYPE_WORLD
	elseif self.currentPage == 2 then
		packet_type = emRED_ENVELOP_TYPE_CLAN
	else
		packet_type = emRED_ENVELOP_TYPE_TEAM
	end
	IGame.RedEnvelopClient:OnRequestRedenvelopList(packet_type)
end

function RedPacketWindow:OnClose()
	self:Hide()
	self.currentPage = 0
end

function RedPacketWindow:OnDestroy()
	for i=1, 3 do
		self.Controls.Page[i].onValueChanged:RemoveAllListeners()
	end
	
	self:RemoveListener(self.Controls.m_sendPacket, "onClick", self.OnSendPacket, self)
	self:RemoveListener(self.Controls.m_refreshPacket, "onClick", self.OnRefreshPacket, self)
	
	self:UnSubscribeWinExecute()
	UIWindow.OnDestroy(self)
end

-- 刷新红点显示
function RedPacketWindow:RefreshRedDot(_, _, _, evtData)
	local redDotObjs = 
	{
		["世界红包"] = self.Controls.m_worldPage,
		["队伍红包"] = self.Controls.m_teamPage,
	}
	
	local pClan = IGame.ClanClient:GetClan()
	if pClan then
		redDotObjs["帮会红包"] = self.Controls.m_gangPage
	end

	SysRedDotsMgr.RefreshRedDot(redDotObjs, "RedPacketPage", evtData)
end

return RedPacketWindow
