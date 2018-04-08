-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    方称称
-- 日  期:    2017/06/22
-- 版  本:    1.0
-- 描  述:    门派入侵主界面ICON窗口
-------------------------------------------------------------------

local MenPaiIconWindow = UIWindow:new
{
	windowName = "MenPaiIconWindow",
	m_info = nil,
}

local this = MenPaiIconWindow	-- 方便书写

function MenPaiIconWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj,UIManager._MainHUDLayer)
	
	self.Controls.m_btn.onClick:AddListener( handler(self, self.clickCallback) )
	return self
end

--点击
function MenPaiIconWindow:clickCallback()
	if self.m_info.cellInfo ~= nil then
		UIManager.MenPaiWindow:Show(true)
        UIManager.MenPaiWindow:SetData(self.m_info.cellInfo)
	end
	GameHelp.PostServerRequest("RequestMenPaiListInfo()")
end

-- 设置数字
function MenPaiIconWindow:setInfo( info )
	if not info then
		return
	end
	self.m_info = info
	self.Controls.m_NumTxt.text = info.totalNum
	
	if UIManager.MenPaiWindow:isLoaded() and self.m_info.cellInfo ~= nil then
		UIManager.MenPaiWindow:SetData(self.m_info.cellInfo)
	end
end

--隐藏窗口
function MenPaiIconWindow:hideWindow()
	-- 关闭定时器
	self:Hide()
end

function MenPaiIconWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

return MenPaiIconWindow