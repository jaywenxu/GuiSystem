-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    周加财
-- 日  期:    2017/11/28
-- 版  本:    1.0
-- 描  述:    通用确认界面，带勾选框的
-------------------------------------------------------------------


local CommonConfirmWindow = UIWindow:new
{
	windowName        = "CommonConfirmWindow",
	
	m_Content         = "",
	m_CancelBtnText    = "取  消",
	m_ConfirmBtnText   = "确  认",
	m_CheckText        = "不再提示",
	
	m_ConfirmCallBack = nil,
	m_CancelCallBack  = nil,

	m_bRequestComfitm = false,

	m_GetMarkCallBack   = nil,    -- 获取确认的状态的函数
	m_SetMarkCallBack   = nil,    -- 设置确认状态的信息
    
	m_MarkHide   = false,    -- 设置确认状态的信息
}

----------------------------------------------------------------
function CommonConfirmWindow:Init()

end

function CommonConfirmWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

 	self.Controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
 	self.Controls.m_CancelBtn.onClick:AddListener(handler(self, self.OnBtnCancelClicked))
 	self.Controls.m_ConfirmBtn.onClick:AddListener(handler(self, self.OnBtnConfirmClicked))
	self.Controls.m_CheckMark.onValueChanged:AddListener(handler(self, self.OnCheckMark))

 	self:UpdateUI()
end

function CommonConfirmWindow:Hide(destroy )
	
	self:ClearData()
	UIWindow.Hide(self,destroy)
end

-- 清楚数据
function CommonConfirmWindow:ClearData()
	self.m_bRequestComfitm = false
	self.m_ConfirmCallBack = nil
	self.m_CancelCallBack  = nil
	self.m_bRequestComfitm = false
	self.m_GetMarkCallBack   = nil    -- 获取确认的状态的函数
	self.m_SetMarkCallBack   = nil    -- 设置确认状态的信息
	self.m_MarkHide   = false    -- 设置确认状态的信息
end

-- 响应关闭，即取消
function CommonConfirmWindow:OnBtnCloseClicked()
	self:OnBtnCancelClicked()
end

-- 响应取消
function CommonConfirmWindow:OnBtnCancelClicked()

	if not self.m_bRequestComfitm then
		if self.m_CancelCallBack then
            self.m_CancelCallBack()
        end
	end
	self.m_bRequestComfitm = true
	self:Hide()
end

-- 响应确认
function CommonConfirmWindow:OnBtnConfirmClicked()

	if not self.m_bRequestComfitm then
		if self.m_ConfirmCallBack then
            self.m_ConfirmCallBack()   
        end
	end
	self.m_bRequestComfitm = true
	self:Hide()
end

function CommonConfirmWindow:OnCheckMark(on)
    if self.m_SetMarkCallBack ~= nil then
		self.m_SetMarkCallBack(on and 1 or 0)
	end
end

----------------------------------------------------------------
-- 显示确认信息
function CommonConfirmWindow:ShowConfirmInfo(pData)
	UIWindow.Show(self, true)

	-- 标题
	self.m_Title = pData.title or AssetPath.TextureGUIPath.."Common_frame/Common_mz_tishi.png"
	-- 内容
	self.m_Content = pData.content or "" 

	self.m_ConfirmBtnText = pData.confirmBtnText or "确  认"
	self.m_CancelBtnText = pData.cancelBtnText or "取  消"
	self.m_CheckText = pData.markText or "不再提示"
	
	self.m_ConfirmCallBack  = pData.confirmCallBack  -- 确认回调函数
	self.m_CancelCallBack   = pData.cancelCallBack   -- 取消回调函数
    
	self.m_GetMarkCallBack   = pData.getMarkCallBack    -- 获取确认的状态的函数
	self.m_SetMarkCallBack   = pData.setMarkCallBack    -- 设置确认状态的信息
    
	self.m_MarkHide   = pData.bMarkShow or false    -- 设置确认状态的信息
    
	self:UpdateUI()
end

-- 刷新界面信息
function CommonConfirmWindow:UpdateUI()
	if not self:isLoaded() then
		return 
	end
	self.Controls.m_ConfirmBtnText.text = self.m_ConfirmBtnText -- 确认按钮名
	self.Controls.m_CancelBtnText.text = self.m_CancelBtnText   -- 取消按钮名
	self.Controls.m_ContentText.text = self.m_Content           -- 内容信息
	self.Controls.m_CheckMarkText.text = self.m_CheckText       -- 确认的信息
    
    if not self.m_MarkHide then
        self.Controls.m_CheckMark.gameObject:SetActive(false)
    else
        self.Controls.m_CheckMark.gameObject:SetActive(true)
        -- 设置选择状态
        if self.m_GetMarkCallBack then
            self.Controls.m_CheckMark.isOn = self.m_GetMarkCallBack() == 1
        end
    end
end

return CommonConfirmWindow
