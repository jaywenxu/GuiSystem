-- 服务器入口配置文件下载
-- @Author zengsq
-- @Date 2017/11/28 

local EntryConfigWindow = UIWindow:new
{
    windowName      = "EntryConfigWindow",
}

function EntryConfigWindow:Init()
end

function EntryConfigWindow:OnAttach(obj)
    UIWindow.OnAttach(self,obj)
    
    self.cbOnCloseBtnClick = function() self:OnCloseBtnClick() end
    self.Controls.m_btnClose.onClick:AddListener(self.cbOnCloseBtnClick)
    
    self.cbOnDebugServerClick = function() self:OnDebugServerClick() end
    self.Controls.m_btnDebugServer.onClick:AddListener(self.cbOnDebugServerClick)
    
    self.cbOnReleaseServerClick = function() self:OnReleaseServerClick() end
    self.Controls.m_btnReleaseServer.onClick:AddListener(self.cbOnReleaseServerClick)
    
    self.cbOnRehearsalServerClick = function() self:OnRehearsalServerClick() end
    self.Controls.m_btnRehearsalServer.onClick:AddListener(self.cbOnRehearsalServerClick)
    
    self.cbOnVerifyServerClick = function() self:OnVerifyServerClick() end
    self.Controls.m_btnVerifyServer.onClick:AddListener(self.cbOnVerifyServerClick)
    
    self.cbOnClearClick = function() self:OnClearClick() end
    self.Controls.m_btnClear.onClick:AddListener(self.cbOnClearClick)
end

function EntryConfigWindow:OnDestroy()
    UIWindow.OnDestroy(self)
end

function EntryConfigWindow:OnCloseBtnClick()
    self:Hide()
end

function EntryConfigWindow:downloadEntryConfig(name)
    print("选择服务器:"..name)
    local url = IGame.LoginForm.entryconfig[name]
    if not url or type(url) ~= "string" or url == "" then
        return
    end
    print("下载配置文件:"..url)
    rkt.EntryService.Me:downloadEntryConfig(url)
end

function EntryConfigWindow:OnDebugServerClick()
    self:downloadEntryConfig("内网服务器")
    self:Hide()
end

function EntryConfigWindow:OnReleaseServerClick()
    self:downloadEntryConfig("外网服务器")
    self:Hide()
end

function EntryConfigWindow:OnRehearsalServerClick()
    self:downloadEntryConfig("预演服务器")
    self:Hide()
end

function EntryConfigWindow:OnVerifyServerClick()
    self:downloadEntryConfig("版署服务器")
    self:Hide()
end

function EntryConfigWindow:OnClearClick()
    rkt.EntryService.Me:clearEntryConfig()
    self:Hide()
end

return EntryConfigWindow