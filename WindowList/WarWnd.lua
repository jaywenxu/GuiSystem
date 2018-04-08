--WarWnd.lua------------------------------------------------------------
-- 版  权:	(C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:	聂敏隆
-- 日  期:	2017.11.20
-- 版  本:	1.0
-- 描  述:	战场窗口管理
-------------------------------------------------------------------

gtWarWndType = 
{
	nLigeance = 1,		-- 领地战
	nGaoChang = 2,		-- 高昌秘道
	nSkyEarth = 3,		-- 天地劫
	nFireDestroy = 4,	-- 火攻粮营
	nBabelEctype = 5,	-- 通天塔
    nJiaRenBattle = 6,  -- 假人战场
}

local WarWnd = UIControl:new
{
	windowName      = "WarWnd",
	tWndObj = {},
	nNowType = 0,
}

-- 初始化
function WarWnd:Init()
	
	self.tWndObj[gtWarWndType.nLigeance] 	= {require("GuiSystem.WindowList.LigeanceWnd"), "m_LigeanceWnd"}
	self.tWndObj[gtWarWndType.nGaoChang] 	= {require("GuiSystem.WindowList.GaoChangWnd"), "m_GaoChangWnd"}
	self.tWndObj[gtWarWndType.nSkyEarth] 	= {require("GuiSystem.WindowList.SkyEarthWnd"), "m_SkyEarthWnd"}
	self.tWndObj[gtWarWndType.nFireDestroy] = {require("GuiSystem.WindowList.FireDestroyWnd"), "m_FireDestroyWnd"}
	self.tWndObj[gtWarWndType.nBabelEctype] = {require("GuiSystem.WindowList.BabelEctypeWnd"), "m_BabelEctypeWnd"}
    self.tWndObj[gtWarWndType.nJiaRenBattle] = {require("GuiSystem.WindowList.JiaRenBattleWnd"), "m_JiaRenBattleWnd"}
end

-- 挂接
function WarWnd:Attach( obj )
	UIControl.Attach(self,obj)
	obj:SetActive(false)

	local tControl = self.Controls
	
	for nType, tData in pairs(self.tWndObj) do
		 tData[1]:Attach(self.Controls[tData[2]].gameObject)
	end
end

-- 销毁
function WarWnd:OnDestroy()
	
	if self.tWndObj[self.nNowType] then
		self.tWndObj[self.nNowType][1]:Destroy()
	end
	
	UIControl.OnDestroy(self)
end

-- 显示
function WarWnd:Show(nWndType)
	if nWndType ~= self.nNowType then
		self:Hide()
	end
	UIControl.Show(self)
	
	self.nNowType = nWndType
	
	self.tWndObj[nWndType][1]:Show()
end

-- 关闭
function WarWnd:Hide()
	
	if not self.tWndObj[self.nNowType] then
		return
	end
	UIControl.Hide(self)
	self.tWndObj[self.nNowType][1]:Hide()
	
	self.nNowType = 0
end

-- 获取当前类型
function WarWnd:GetWarType()
	return self.nNowType
end

return WarWnd


