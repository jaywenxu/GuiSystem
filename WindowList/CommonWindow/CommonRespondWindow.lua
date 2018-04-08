--邀请窗口
---------------------------------------------------
local CommonRespondWindow = UIWindow:new
{
	windowName = "CommonRespondWindow" ,
	
	m_Content         = "",
	m_Title           = "",
	
	m_AcceptBtnTxt   = "接受",
	m_RefuseBtnTxt    = "拒绝",
	
	m_AcceptCallBack = nil,
	m_RefuseCallBack  = nil,
	
	m_WindowData = {}
}

-- 公用方法
---------------------------------------------------
function CommonRespondWindow:Init()
end

function CommonRespondWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.Controls.m_RefuseButton.onClick:AddListener(function() self:RefuseButtonClick() end)
	self.Controls.m_AcceptButton.onClick:AddListener(function() self:AcceptButtonClick() end)
	self.Controls.m_CloseButton.onClick:AddListener(function() self:CloseWindow() end)
	self:RefreshUI()
	return self
end

function CommonRespondWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end
---------------------------------------------------

--[[
@purpose	：显示通用回复的弹出框
@param ：
data = {
		title			: 标题资源路径
		content 		: 内容
		acceptBtnTxt    ：接受按钮文本
		refuseBtnTxt 	：拒绝按钮文本
		acceptCallBack : 确认按钮回调，不传默认关闭弹框
		refuseCallBack 	: 取消按钮回调，不传默认关闭弹框
}
]]
function CommonRespondWindow:ShowWindow(data)
	UIWindow.Show(self, true)
	
	if nil ~= table_match(self.m_WindowData, function (record) return record.content == data.content end) then
		uerror("已有相同内容的弹出框！")
		return
	end
	table.insert(self.m_WindowData, data)
	
	self:InitData(self.m_WindowData[1])
	if self:isLoaded() then
		self:RefreshUI()
	end
end

function CommonRespondWindow:InitData(data)
	self.m_Content = data.content or ""
	self.m_Title = data.title or AssetPath.TextureGUIPath.."Team/team_biati_yaoqing.png"
	
	self.m_AcceptBtnTxt = data.acceptBtnTxt or "接受"
	self.m_RefuseBtnTxt = data.refuseBtnTxt or "拒绝"
	
	self.m_AcceptCallBack  = data.acceptCallBack
	self.m_RefuseCallBack   = data.refuseCallBack
end

function CommonRespondWindow:RefreshUI()
	local controls = self.Controls
	
	controls.m_InvitedInfoText.text = self.m_Content
	
	controls.m_AcceptBtnTxt.text = self.m_AcceptBtnTxt
	controls.m_RefuseBtnTxt.text = self.m_RefuseBtnTxt
	
	UIFunction.SetImageSprite(controls.m_ImageTitle, self.m_Title)
end

function CommonRespondWindow:RefuseButtonClick() 
	if self.m_RefuseCallBack ~= nil then
		self.m_RefuseCallBack()
	end
	table.remove(self.m_WindowData,1)
	self:CheckHaveInvite()
end
---------------------------------------------------
function CommonRespondWindow:AcceptButtonClick() 
	if self.m_AcceptCallBack ~= nil then
		self.m_AcceptCallBack()
	end
	self.m_WindowData = {}
	self:Hide(true)
end

function CommonRespondWindow:CloseWindow()
	if self.m_RefuseCallBack ~= nil then
		self.m_RefuseCallBack()
	end
	table.remove(self.m_WindowData,1)
	self:CheckHaveInvite()
end

function CommonRespondWindow:CheckHaveInvite()
	local cnt = #self.m_WindowData
	if cnt <= 0 then 
		self:Hide(true)
	else
		self:InitData(self.m_WindowData[1])
		if self:isLoaded() then
			self:RefreshUI()
		end
	end
end
---------------------------------------------------
return CommonRespondWindow