--*******************************************************************
--** 文件名:	UserAgreementWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	周加财
--** 日  期:	2017-11-24
--** 版  本:	1.0
--** 描  述:	用户协议
--** 应  用:  
--*******************************************************************


-------------------------------------------------------
local UserAgreementWindow = UIWindow:new
{
	windowName  = "UserAgreementWindow",
	m_CurPage = 1,	-- 当前是第几页
}

function UserAgreementWindow:Init()
	
end

function UserAgreementWindow:OnAttach(obj)
	UIWindow.OnAttach(self, obj)	

	self.Controls.m_Close.onClick:AddListener(handler(self, self.OnCloseBtnClick))
	-- self.Controls.m_CloseBg.onClick:AddListener(handler(self, self.OnCloseBtnClick))
	
	self.Controls.m_PreButtonBtn.onClick:AddListener(handler(self, self.OnPreBtnClick))
	self.Controls.m_NextPageBtn.onClick:AddListener(handler(self, self.OnNextBtnClick))
	self.Controls.m_QueDingBtn.onClick:AddListener(handler(self, self.OnCloseBtnClick))
	
	self.m_CurPage = 1	
	self:RefeshAgreementInfo()
end

-- 显示用户协议信息
function UserAgreementWindow:ShowUserAgreement()
	self.m_CurPage = 1
	UIWindow.Show(self,true)
	self:RefeshAgreementInfo()
end

function UserAgreementWindow:OnEnable()

end

function UserAgreementWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

function UserAgreementWindow:OnCloseBtnClick()
	self:Hide()
end

-- 前一页
function UserAgreementWindow:OnPreBtnClick()
	if self.m_CurPage <= 1 then
		return
	end
	self.m_CurPage = self.m_CurPage - 1
	self:RefeshAgreementInfo()
end

-- 下一页
function UserAgreementWindow:OnNextBtnClick()
	local nMaxCount = table_count(gUserAgreementCfg)
	if self.m_CurPage >= nMaxCount then
		return
	end
	self.m_CurPage = self.m_CurPage + 1
	self:RefeshAgreementInfo()
end

-- 刷新信息
function UserAgreementWindow:RefeshAgreementInfo()
	
	if not self:isLoaded() then
		return
	end
	if not gUserAgreementCfg[self.m_CurPage] then
		return
	end
	local nMaxCount = table_count(gUserAgreementCfg)
	-- 设置协议内容
	self.Controls.m_ContentText.text = gUserAgreementCfg[self.m_CurPage].content or ""
	-- 刷新页数
	self.Controls.m_PageText.text = self.m_CurPage .. "/" .. nMaxCount
	
	-- 刷新按钮状态
	if self.m_CurPage == 1 then
		self.Controls.m_PreButtonBtn.gameObject:SetActive(false)
	else
		self.Controls.m_PreButtonBtn.gameObject:SetActive(true)
	end
	
	if self.m_CurPage == nMaxCount then
		self.Controls.m_NextPageBtn.gameObject:SetActive(false)
	else
		self.Controls.m_NextPageBtn.gameObject:SetActive(true)
	end
end

return UserAgreementWindow



