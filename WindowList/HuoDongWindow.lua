--/******************************************************************
---** 文件名:	HuoDongWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-02-22
--** 版  本:	1.0
--** 描  述:	活动窗口
--** 应  用:  
--******************************************************************/

require("GuiSystem.WindowList.HuoDong.HuoDongWinDef")

local m_titleImagePath = AssetPath.TextureGUIPath.."Activity/Activity_huodong.png"
local HuoDongWindow = UIWindow:new
{
	windowName = "HuoDongWindow",
	m_Tgls     = {},
	m_SubLuaObjs = {}, --子控件脚本
	m_SubWdtObjs = {}, --子控件对象
	m_CurIdx   = 0,
	m_InitIdx  = 0,
}

function HuoDongWindow:OnAttach(obj)
	UIWindow.OnAttach(self,obj)
	
	UIWindow.AddCommonWindowToThisWindow(self,true,m_titleImagePath, function() self:OnBackBtnClick() end,nil,function() self:SetFullScreen() end,true)

    self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))

	self:InitObjsMap()
	    
	self:InitToggleData()
				
	self:InitUI()
	
	self:InitData()
end

function HuoDongWindow:InitToggleData()
	self.m_Tgls = 
	{
		self.Controls.m_Activity,
		self.Controls.m_Notice,
		self.Controls.m_Active,
		self.Controls.m_Qiyu,
	}

	for i = 1, #self.m_Tgls do
		self.m_Tgls[i].onValueChanged:AddListener(function(on) self:OnToggleChanged(on, i) end)
	end
end

function HuoDongWindow:InitObjsMap()
	self.m_SubWdtObjs = 
	{
		[HuoDongWinDef.Item.Activity_All] = self.Controls.m_ActivityListWdt,
		[HuoDongWinDef.Item.Activity_Active] = self.Controls.m_ActivityDegreeWdt,
		[HuoDongWinDef.Item.Activity_Qiyu] = self.Controls.m_QiyuWdt,
	}
end

function HuoDongWindow:InitData()
	
	-- 请求更新活动数据
	IGame.ActivityList:RequestActivityData()
	
	-- 请求更新宝箱数据
	GameHelp.PostServerRequest("RequestActiveBoxStatus()")
end

function HuoDongWindow:Show(bringTop, nFocusIdx)
	
	self.m_InitIdx = nFocusIdx or HuoDongWinDef.Item.Activity_All
	
	UIWindow.Show(self, bringTop)	
end

function HuoDongWindow:OnEnable()
	
	self:InitUI()
	
	IGame.ActivityList:RequestActivityData()
	
	IGame.ActivityList:UpdateRedDot()
end

function HuoDongWindow:InitUI()
	for i = 1, #self.m_Tgls do
		self.m_Tgls[i].isOn = ((i == self.m_InitIdx) and true) or false
	end
end

function HuoDongWindow:SwitchTxtImage(on , idx)
	if on then
		self.m_Tgls[idx].transform:Find("ON").gameObject:SetActive(true)
		self.m_Tgls[idx].transform:Find("OFF").gameObject:SetActive(false)
	else
		self.m_Tgls[idx].transform:Find("ON").gameObject:SetActive(false)
		self.m_Tgls[idx].transform:Find("OFF").gameObject:SetActive(true)
	end
end

function HuoDongWindow:OnToggleChanged(on, idx)
	self:SwitchTxtImage(on, idx)
	
	if on then
		self:SwitchTab(idx)
	end
end

function HuoDongWindow:SwitchTab(idx)
	if self.m_CurIdx == idx then
		return
	end
	
	if not self.m_SubLuaObjs[idx] then
		if not HuoDongWinDef.WdtLuaFiles[idx] then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "待开发功能")
			return
		end
		
		if not self.m_SubWdtObjs[idx] then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "待开发功能")
			return
		end
		
		local tLuaObj = require(HuoDongWinDef.WdtLuaFiles[idx])
		local tWdtObj = self.m_SubWdtObjs[idx].gameObject
		tLuaObj:Attach(tWdtObj)
		tLuaObj:Show()
		self.m_SubLuaObjs[idx] = tLuaObj
	else
		self.m_SubLuaObjs[idx]:Show()
	end
	
	if self.m_SubLuaObjs[self.m_CurIdx] then
		self.m_SubLuaObjs[self.m_CurIdx]:Hide()
	end
	
	self.m_CurIdx = idx
end

function HuoDongWindow:OnBackBtnClick()
	self:Hide()
end

function HuoDongWindow:UpdateTimes()	
	local nCurIdx = HuoDongWinDef.Item.Activity_All
	local tLuaObj = self.m_SubLuaObjs[nCurIdx]
	if not tLuaObj then
		return 
	end
	
	tLuaObj:ReloadActivityList()
end

function HuoDongWindow:SubscribeWinExecute()
		
	-- 活动状态更新监听
	self.m_OnActivityUpdate = handler(self, self.UpdateTimes)
	rktEventEngine.SubscribeExecute(EVENT_ACTIVITY_LIST_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.m_OnActivityUpdate)
	
	-- 活动红点更新
	self.m_OnRedDotUpdate = handler(self, self.OnRedDotUpdate)
	rktEventEngine.SubscribeExecute(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM, REDDOT_UI_EVENT_ACTIVITY_PAGE, self.m_OnRedDotUpdate)
end

function HuoDongWindow:UnSubscribeWinExecute()

	rktEventEngine.UnSubscribeExecute( EVENT_ACTIVITY_LIST_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.m_OnActivityUpdate)
	self.m_OnActivityUpdate = nil

	rktEventEngine.UnSubscribeExecute( EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM, REDDOT_UI_EVENT_ACTIVITY_PAGE, self.m_OnRedDotUpdate)
	self.m_OnRedDotUpdate = nil
end

function HuoDongWindow:OnRedDotUpdate(_, _, _, evtData)
	
	local Objs = {["活跃"] = self.Controls.m_Active}
	SysRedDotsMgr.RefreshRedDot(Objs, "ActivePage", evtData)

end

function HuoDongWindow:ReSetData()	
	self.m_SubLuaObjs = {}

	self.m_CurIdx = 0
end

-- 窗口销毁
function HuoDongWindow:OnDestroy()
    
	self:ReSetData()
			
	UIWindow.OnDestroy(self)
end

return HuoDongWindow



