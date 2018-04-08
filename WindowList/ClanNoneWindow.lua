-- 宗派界面(未拥有宗派)
-- @Author: XieXiaoMei
-- @Date:   2017-04-06 21:05:43
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-15 10:46:56

require("GuiSystem.WindowList.Clan.ClanSysDef")

local ClanNoneWindow = UIWindow:new
{
	windowName          = "ClanNoneWindow",
	
	m_PreTglIdx         = 0,

	m_TabToggles        = {},
	m_ClanWidgets       = {},
	m_WidgetObjs        = {},
	
	m_ClanListMgr       = nil,
	m_OnListEvtCallBack = nil,

	m_bOnlyShowJoinList = false,
}


local TabWidgets = ClanSysDef.ClanNoneTabs

local TabLuaWdtFiles = {
    "ClanJoinWdt",
	"ClanCreateWdt",
	"ClanResponseWdt"
}

------------------------------------------------------------
function ClanNoneWindow:Init()
end
---------------------------------------------------------------------------------------------
function ClanNoneWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	self.m_ClanListMgr = IGame.ClanClient:GetClanListManager()

	for i=1, #TabLuaWdtFiles do
		self.m_WidgetObjs[i]= {
			isFetched = false,
			obj = nil
		}
	end
	self:ScheLoadWdtResCoroutine()

	self:InitUI()

	self:SubscribeEvts()

	self:OnTogglesChanged(TabWidgets.Join, true)

	self.unityBehaviour.onDisable:AddListener(handler(self, self.OnDisable)) 
end
---------------------------------------------------------------------------------------------
function ClanNoneWindow:InitUI()
	UIWindow.AddCommonWindowToThisWindow(self, true, ClanSysDef.TitleImgFilePath, function() self:Hide() end)
	self:SetFullScreen() -- 设置为全屏界面
	local controls = self.Controls

	self.m_TabToggles = {
		controls.m_JoinClanTgl,
		controls.m_CreateClanTgl,
		controls.m_ResponClanTgl
	}

	for i=1, 3 do
		local tgl = self.m_TabToggles[i]
		tgl.onValueChanged:AddListener(function (on)
			self:OnTogglesChanged(i, on)
		end)
	end

	self:UpdateTabTgls()
end

---------------------------------------------------------------------------------------------
function ClanNoneWindow:ShowWindow(bOnlyShowJoinList, bringTop )
	UIWindow.Show(self, bringTop )

	self.m_bOnlyShowJoinList = bOnlyShowJoinList ~= nil and bOnlyShowJoinList == true

	if self:isLoaded() then
		self:UpdateTabTgls()
		
		self:OnTogglesChanged(TabWidgets.Join, true)
	end
end

---------------------------------------------------------------------------------------------
function ClanNoneWindow:OnDisable()
	self.m_ClanListMgr:Reset()
end

---------------------------------------------------------------------------------------------
function ClanNoneWindow:Hide( destory )
	UIWindow.Hide(self, destory )
end

---------------------------------------------------------------------------------------------
function ClanNoneWindow:OnDestroy()
	self:UnSubscribeEvts()
	
	UIWindow.OnDestroy(self)
	
	table_release(self)
end

---------------------------------------------------------------------------------------------
function ClanNoneWindow:SubscribeEvts()
	-- 请求帮派列表
	self.m_OnListEvtCallBack = handler(self, self.OnClanListEvt)
	rktEventEngine.SubscribeExecute( EVENT_CLAN_LISTUPDATE, SOURCE_TYPE_CLAN, 0, self.m_OnListEvtCallBack )
	
	-- 成功加入帮会
	self.m_OnJoinSuccessCallBack = handler(self, self.OnJoinSuccessEvt)
	rktEventEngine.SubscribeExecute( EVENT_JOIN_SUCCESS, SOURCE_TYPE_CLAN, 0, self.m_OnJoinSuccessCallBack )
	
	-- 帮会变为正式帮会
	self.m_OnToFormalCallBack = handler(self, self.OnClanToFormalEvt)
	rktEventEngine.SubscribeExecute( EVENT_CLAN_TOFORMAL, SOURCE_TYPE_CLAN, 0, self.m_OnToFormalCallBack )
end

---------------------------------------------------------------------------------------------
function ClanNoneWindow:UnSubscribeEvts()
	rktEventEngine.UnSubscribeExecute( EVENT_CLAN_LISTUPDATE , SOURCE_TYPE_CLAN, 0, self.m_OnListEvtCallBack )
	self.m_OnListEvtCallBack = nil
	
	rktEventEngine.UnSubscribeExecute( EVENT_JOIN_SUCCESS , SOURCE_TYPE_CLAN, 0, self.m_OnJoinSuccessCallBack )
	self.m_OnJoinSuccessCallBack = nil
	
	rktEventEngine.UnSubscribeExecute( EVENT_CLAN_TOFORMAL , SOURCE_TYPE_CLAN, 0, self.m_OnToFormalCallBack )
	self.m_OnToFormalCallBack = nil
end

---------------------------------------------------------------------------------------------
-- 设置只显示帮派正式加入列表
function ClanNoneWindow:UpdateTabTgls()
	local bFlag = self.m_bOnlyShowJoinList

	local tagTgls = self.m_TabToggles
	for i = 2, 3 do
		tagTgls[i].gameObject:SetActive(not bFlag)
	end
end

---------------------------------------------------------------------------------------------
-- 帮会列表请求返回事件
function ClanNoneWindow:OnClanListEvt(_, _, _, evtData)

	local state = evtData.nState
	local wdtIdx = state == ClanSysDef.FormalState and TabWidgets.Join or TabWidgets.Response

	if not self.m_ClanWidgets[wdtIdx] then
		self:OnTogglesChanged(wdtIdx, true)
	else
		self.m_ClanWidgets[wdtIdx]:OnClanListEvt(evtData)
	end
end

---------------------------------------------------------------------------------------------
-- 加入帮会成功事件
function ClanNoneWindow:OnJoinSuccessEvt(_, _, _, evtData)
	cLog("ClanNoneWindow:OnJoinSuccessEvt", "green")
		
	self:GotoClanOwnWindow()
end


---------------------------------------------------------------------------------------------
-- 成为正式帮会事件
function ClanNoneWindow:OnClanToFormalEvt(_, _, _, eventData)
	cLog("ClanNoneWindow:OnClanToFormalEvt", "green")

	self:GotoClanOwnWindow()
end

---------------------------------------------------------------------------------------------
-- 跳转到已拥有帮会面板
function ClanNoneWindow:GotoClanOwnWindow()
	if self:isShow() then
		if self.m_ClanWidgets[2] and self.m_ClanWidgets[2]:IsClanCreateing() then -- 关闭创建时候的确认弹出框
			UIManager.ConfirmPopWindow:Hide()
		end
		
		UIManager.ClanNoneWindow:Hide()
		UIManager.ClanOwnWindow:ShowWindow()
	end
end
---------------------------------------------------------------------------------------------
-- toggle切换回调
function ClanNoneWindow:OnTogglesChanged(idx, on)
	if not self.m_TabToggles[idx] then
		return 
	end

	if self.m_TabToggles[idx].isOn ~= on then
		self.m_TabToggles[idx].isOn = on
		return
	end

	if self.m_PreTglIdx == idx and on then
		return
	end
	
	local param = idx == TabWidgets.Join and self.m_bOnlyShowJoinList == true
	local clanWdt = self.m_ClanWidgets[idx]
	if on then
		if not clanWdt then
			self:FetchWidgetAndShow(idx, param)
		else
			clanWdt:Show(param)
		end
		self.m_PreTglIdx = idx
	else
		if clanWdt then
			clanWdt:Hide()
		end
	end
end


---------------------------------------------------------------------------------------------
-- 实例化并显示一个wdiget
function ClanNoneWindow:FetchWidgetAndShow(idx, param)
	if self.m_WidgetObjs[idx].obj ~= nil or self.m_WidgetObjs[idx].isFetching then
		return
	end

	self.m_WidgetObjs[idx].isFetching = true

	local filePath = GuiAssetList.Clan[TabLuaWdtFiles[idx]]
	rkt.GResources.FetchGameObjectAsync( filePath ,
	function ( path , obj , ud )
		self.m_WidgetObjs[idx].isFetching = false

		if obj == nil then
			return
		end

		self.m_WidgetObjs[idx].obj = obj
		obj.transform:SetParent(self.transform, false)

		local clanWdt = require(ClanSysDef.ClanNonePath .. TabLuaWdtFiles[idx]):new()
		clanWdt:Attach(obj)

		self.m_ClanWidgets[idx] = clanWdt

		clanWdt:Show(param)
		
	end, nil, AssetLoadPriority.GuiNormal)
end


---------------------------------------------------------------------------------------------
-- 调度加载子界面的限时任务协程
function ClanNoneWindow:ScheLoadWdtResCoroutine()
	for i=1, #TabLuaWdtFiles do

		local filePath = GuiAssetList.Clan[TabLuaWdtFiles[i]]
		rkt.IdleTimeTaskScheduler.ScheduleLuaCoroutine( function() 
			rkt.GResources.LoadAsync(filePath, typeof(UnityEngine.Object), nil, "", AssetLoadPriority.GuiNormal)
		end, 0, 2,"加载帮会已拥界面"..i)
	end
end

return ClanNoneWindow
------------------------------------------------------------

