-- 宗派界面(未拥有宗派)
-- @Author: XieXiaoMei
-- @Date:   2017-04-06 21:05:43
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-13 18:42:28

require("GuiSystem.WindowList.Clan.ClanSysDef")

local ClanOwnWindow = UIWindow:new
{
	windowName    = "ClanOwnWindow",

	m_ClanWidgets = {},
	m_WidgetObjs  = {},
	m_TabToggles  = {},

	m_TabTglOffImgObjs  = {},
	
	m_PreTglIdx   = 0,
	
	m_GotoTglIdx   = 0,
	
	m_Tweener = nil,
}

local TabLuaWdtFiles = {
	"ClanInfoWdt",
	"ClanMembersWdt",
	"ClanBuildingWdt",
	"ClanLigeanceWdt",
}

------------------------------------------------------------
function ClanOwnWindow:Init()
end

function ClanOwnWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	for i=1, #TabLuaWdtFiles do
		self.m_WidgetObjs[i]= {
			isFetched = false,
			obj = nil
		}
	end

	m_GotoTglIdx = 2

	self:InitUI()

	self:ScheLoadWdtResCoroutine()

	self:OnTogglesChanged(self.m_GotoTglIdx, true) -- 默认显示第一个页签
	
	rktEventEngine.SubscribeExecute(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM,REDDOT_UI_EVENT_CLAN_OWNWINDOW, self.RefreshRedDot, self)
	
	self:RefreshRedDot()
end

---------------------------------------------------------------------------------------------
-- 显示
function ClanOwnWindow:Show( bringTop)
	UIWindow.Show(self, bringTop)
	
	IGame.ClanClient:ClanDataRequest()
	IGame.ClanBuildingPresenter:RsqBuildingList()

	if not self:isLoaded() then
		return
	end

	--self:OnTogglesChanged(self.m_GotoTglIdx, true) -- 默认显示第一个页签
	self.m_TabToggles[self.m_GotoTglIdx].isOn = true
end

---------------------------------------------------------------------------------------------
-- 显示窗口
function ClanOwnWindow:ShowWindow(gotoTabIdx)
	self.m_GotoTglIdx = gotoTabIdx or 2

	self:Show(true)
end


---------------------------------------------------------------------------------------------
-- 销毁窗口
function ClanOwnWindow:OnDestroy()
	rktEventEngine.UnSubscribeExecute(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM,REDDOT_UI_EVENT_CLAN_OWNWINDOW, self.RefreshRedDot, self)
	UIWindow.OnDestroy(self)

	table_release(self)
end

---------------------------------------------------------------------------------------------
-- 隐藏窗口
function ClanOwnWindow:Hide(destory)	
	local subWindows = {
		"ClanNoneWindow",
		
		"ClanWelcomeNewWindow",
		"ClanApplyListWindow",
		"ClanPositionChgWindow",
		"ClanSettingsWindow",
		"ClanCourseWindow",
		"ClanNameMdfWindow",
		"ClanDeclareMdfWindow",
		"ClanMassMsgWindow",
		"WelcomePopWindow",
		"LigeLogbuchWindow",
		"LigeFlagEditWindow",
		"DeclareWarInputWindow",
		"ClanShrineWindow",
	}

	for i, win in ipairs(subWindows) do
		UIManager[win]:Hide(destory)
	end
	if self:CloseChildWindow() then
		return
	end

	UIWindow.Hide(self, destory)
end

---------------------------------------------------------------------------------------------
-- 初始化
function ClanOwnWindow:InitUI()
	UIWindow.AddCommonWindowToThisWindow(self, true, ClanSysDef.TitleImgFilePath,function() self:Hide() end,nil,function() self:SetFullScreen() end)
	local controls = self.Controls

	self.m_TabToggles = {
		controls.m_ClanInfoTgl,
		controls.m_MembersTgl,
		controls.m_BuildTgl,
		controls.m_ActivityTgl,
	}

	for i=1, 4 do
		local tgl = self.m_TabToggles[i]
		tgl.onValueChanged:AddListener(function (on)
			self:OnTogglesChanged(i, on)
		end)
		--self.m_TabTglOffImgObjs[i] = tgl.transform:Find("Off").gameObject
	end
	
	SysRedDotsMgr.Register(IGame.ClanBuildingPresenter:GetLayout(),"建筑分页",controls.m_BuildTgl,"m_BuildTgl")
	
	self.m_Tweener = self.transform:GetComponent(typeof(DOTweenAnimation))
end

function ClanOwnWindow:CloseChildWindow()
	if self.m_PreTglIdx == 3 then
		if self.m_ClanWidgets[3]:IsExchengeShow() then
			self.m_ClanWidgets[3]:ExchengeHide()
			return true
		end
	end
	return false
end

---------------------------------------------------------------------------------------------
-- toggle切换回调
function ClanOwnWindow:OnTogglesChanged(idx, on)
	--local offImg = self.m_TabTglOffImgObjs[idx]
	--offImg:SetActive(not on)

	if idx == self.m_PreTglIdx then
		return 
	end

	if on then
		self:SwitchTabWdt(idx, on)
	end
end

---------------------------------------------------------------------------------------------
-- 切换页签
function ClanOwnWindow:SwitchTabWdt(idx, on)
	self:CloseAllBuildingWindow()
	
	local clanWdt = self.m_ClanWidgets[idx]
	if not clanWdt then
		self:FetchWidgetAndShow(idx)
	else
		clanWdt:Show()
	end
	
	local preIdx = self.m_PreTglIdx 
	if preIdx > 0 and preIdx < 5 then
		self.m_TabToggles[preIdx].isOn = false
		
		if self.m_ClanWidgets[preIdx] then
			self.m_ClanWidgets[preIdx]:Hide()
		end
	end

	self.m_PreTglIdx = idx
end

function ClanOwnWindow:IsBuildingTabWdtShow()
	return self.m_PreTglIdx == 3
end

---------------------------------------------------------------------------------------------
-- 实例化并显示一个wdiget
function ClanOwnWindow:FetchWidgetAndShow(idx)
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
		local parent = GetValuable(
			TabLuaWdtFiles[idx] == "ClanBuildingWdt", 
			self.Controls.m_ClanBuildingLayer, 
			self.Controls.m_ClanOrganizeLayer)
		if TabLuaWdtFiles[idx] == "ClanLigeanceWdt" then
			parent = self.Controls.m_ClanLigeanceLayer
		end 
			
		obj.transform:SetParent(parent, false)
		
		local prefPath = TabLuaWdtFiles[idx] == "ClanBuildingWdt" and 
		ClanSysDef.ClanBuildingPath or ClanSysDef.ClanOwnPath
		
		clanWdt = require(prefPath .. TabLuaWdtFiles[idx]):new()
		clanWdt:Attach(obj)

		self.m_ClanWidgets[idx] = clanWdt

		clanWdt:Show()
		
		if TabLuaWdtFiles[idx] == "ClanLigeanceWdt" then
			clanWdt:SetBackBtnCallback(handler(self, self.SwitchToBldWdtFromLigeWdt))
		end
		
	end, nil, AssetLoadPriority.GuiNormal)
end

function ClanOwnWindow:SwitchToBldWdtFromLigeWdt()
	self:OnTogglesChanged(3,true)
end

function ClanOwnWindow:Appear()
	if self.m_Tweener then
		self.m_Tweener:DORestart(true)
	end
end

---------------------------------------------------------------------------------------------
-- 调度加载子界面的限时任务协程
function ClanOwnWindow:ScheLoadWdtResCoroutine()
	for i=1, #TabLuaWdtFiles do

		local filePath = GuiAssetList.Clan[TabLuaWdtFiles[i]]
		rkt.IdleTimeTaskScheduler.ScheduleLuaCoroutine( function() 
			rkt.GResources.LoadAsync(filePath, typeof(UnityEngine.Object), nil, "", AssetLoadPriority.GuiNormal)
		end, 0, 2,"加载帮会已拥界面"..i)
	end
end

---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-- 刷新红点显示
function ClanOwnWindow:RefreshRedDot(_, _, _, evtData)
	local redDotObjs = 
	{
		["成员"] = self.Controls.m_MembersTgl,
		--["建筑"] = self.Controls.m_BuildTgl,
	}

	SysRedDotsMgr.RefreshRedDot(redDotObjs, "ClanOwnWindow", evtData)
	
	local m_Presenter = IGame.ClanBuildingPresenter
	SysRedDotsMgr.SetVisible(m_Presenter:GetLayout(),"建筑分页", "m_BuildTgl", m_Presenter:IsUnclaimed())
end

---------------------------------------------------------------------------------------------
-- 关闭打开的建筑类窗口
function ClanOwnWindow:CloseAllBuildingWindow()
	if self.CommonWindowWidget then
		self.CommonWindowWidget.closeCallback = handler(self, self.Hide)
	end
	UIManager["ClanShrineWindow"]:Hide(false)
	UIManager["ClanAcademyWindow"]:Hide(false)
	UIManager["ClanWelfareWindow"]:Hide(false)
	UIManager["ClanPresbyterWindow"]:Hide(false)
	UIManager["ClanWarfareWindow"]:Hide(false)
end

return ClanOwnWindow