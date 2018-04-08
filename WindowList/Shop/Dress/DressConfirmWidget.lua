
-----------------------------------外观系统确认面板---------------------------------------------
local DressConfirmWidget = UIControl:new
{ 
    windowName = "DressConfirmWidget",
	
	m_cancle_cb = 	nil, 			--取消回调
	m_confirm_cb = 	nil,			--确认回调
	m_mask_cb = 	nil,			--背景mask回调
}

function DressConfirmWidget:Attach(obj)
	UIControl.Attach(self,obj)
	
	--确认button点击事件
	self.callback_OnConfirmBtnClick = function() self:OnConfirmBtnClick() end
	self.Controls.m_ConfirmBtn.onClick:RemoveListener(self.callback_OnConfirmBtnClick)				--防止重复添加事件
	self.Controls.m_ConfirmBtn.onClick:AddListener(self.callback_OnConfirmBtnClick)
	--取消button点击事件
	self.callback_OnCancleBtnClick = function() self:OnCancleBtnClick() end
	self.Controls.m_CancleBtn.onClick:RemoveListener(self.callback_OnCancleBtnClick)
	self.Controls.m_CancleBtn.onClick:AddListener(self.callback_OnCancleBtnClick)
	
	--点击背景mask层触发事件
	self.calbackMaskBtnDownClick = function(eventData) self:OnMaskBtnDownClick(eventData) end
	UIFunction.AddEventTriggerListener(self.Controls.m_BGMask,EventTriggerType.PointerDown,self.calbackMaskBtnDownClick)
end

--对外接口，设置回调
function DressConfirmWidget:ShowWidget(nTitle,nConfirm_cb, nCancle_cb, nMask_cb)
	self.Controls.m_TitleText.text = nTitle
	self.m_confirm_cb = nConfirm_cb
	self.m_cancle_cb = nCancle_cb
	self.m_mask_cb = nMask_cb
	
	self:Show()
end

--确认Btn点击回调
function DressConfirmWidget:OnConfirmBtnClick()
	if nil ~= self.m_confirm_cb then
		self.m_confirm_cb()
	end
	self:Hide()
end

--取消Btn点击回调
function DressConfirmWidget:OnCancleBtnClick()
	if nil ~= self.m_cancle_cb then
		self.m_cancle_cb()
	else
		self:Hide()
	end
end

--背景遮罩点击，默认关闭界面
function DressConfirmWidget:OnMaskBtnDownClick(eventData)
	if nil ~= self.m_mask_cb then
		self.m_mask_cb()
	else
		self:Hide()
	end
end

return DressConfirmWidget