-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017/02/19
-- 版  本:    1.0
-- 描  述:    他人角色菜单窗口
-------------------------------------------------------------------

local ContextMenuWindow = UIWindow:new
{
	windowName = "ContextMenuWindow",
	m_PersonName = "",
	m_PersonDBID = 0,
	
	
}


local this = ContextMenuWindow					-- 方便书写

------------------------------------------------------------
function ContextMenuWindow:Init()
end
------------------------------------------------------------
function ContextMenuWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	--关闭滴答消息窗口按钮
    self.Controls.m_Close.onClick:AddListener(function() self:OnBtnCloseClick() end)
	--关闭滴答消息窗口按钮
    self.Controls.m_Close1.onClick:AddListener(function() self:OnBtnCloseClick() end)
	-- 注册Menu事件
	for i = 1, 6 do
	end

    return self
end

------------------------------------------------------------
------------------------------------------------------------
-- 窗口销毁
function ContextMenuWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

--------------------------------------------------------------------------------
--关闭窗口按钮回调函数
function ContextMenuWindow:OnBtnCloseClick()
	self:Hide()
end

--------------------------------------------------------------------------------
-- 设置名字
function ContextMenuWindow:SetContent(Pdbid,Name)
	if not self:isLoaded() then
		return
	end
	self.m_PersonDBID = Pdbid
	self.m_PersonName = Name
	self.Controls.NameText.text = tostring(Name).."\n".."123456"
end











return ContextMenuWindow







