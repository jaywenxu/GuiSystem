-- 通用确认弹出框
-- @Author: XieXiaoMei
-- @Date:   2017-04-20 14:59:09
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-11 11:52:08

local ConfirmPopWindow = UIWindow:new
{
	windowName        = "ConfirmPopWindow",
	
	m_BtnCnt          = 2,
	m_Content         = "",
	m_Title           = "",
	m_CancelBtnTxt    = "取  消",
	m_ConfirmBtnTxt   = "确  认",
	
	m_Alignment       = 0,
	
	m_ConfirmCallBack = nil,
	m_CancelCallBack  = nil,
    
    m_LiveTime        = 0,
    m_LiveTimeCallBack = nil,
}

----------------------------------------------------------------
function ConfirmPopWindow:Init()
end

function ConfirmPopWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self:SetToTopLayer(obj)
	
	local controls = self.Controls

 	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
 	controls.m_CancelBtn.onClick:AddListener(handler(self, self.OnBtnCancelClicked))
 	controls.m_ConfirmBtn.onClick:AddListener(handler(self, self.OnBtnConfirmClicked))
 	controls.m_SingleConfirmBtn.onClick:AddListener(handler(self, self.OnBtnConfirmClicked))
	self.callback_OnCloseBtnClick = function( eventData ) self:OnCloseButtonClick(eventData) end 
	--策划说要加透传
 --   UIFunction.AddEventTriggerListener( self.Controls.m_CloseButton , EventTriggerType.PointerClick , self.callback_OnCloseBtnClick)

 	self:UpdateUI()
end

--挂载
function ConfirmPopWindow:SetToTopLayer(obj)
	UIManager.AttachToLayer( obj , UIManager._SpecialTopLayer ) 
	obj.transform:SetAsLastSibling()
end

--关闭窗口并且透传
function ConfirmPopWindow:OnCloseButtonClick(eventData)
	self:Hide()
--	rkt.UIAndTextHelpTools.PassThroughPointerClickEvent( eventData )
end

function ConfirmPopWindow:UpdateUI()
	local controls = self.Controls
	
	controls.m_ContentTxt.text = self.m_Content
	controls.m_ContentTxt.alignment = self.m_Alignment
	

	controls.m_CancelBtnTxt.text = self.m_CancelBtnTxt

	controls.m_SingConfBtnTxt.text = self.m_ConfirmBtnTxt

	local bIsDoubleBtn = self.m_BtnCnt == 2
	controls.m_CancelBtn.gameObject:SetActive(bIsDoubleBtn)
	controls.m_ConfirmBtn.gameObject:SetActive(bIsDoubleBtn)
	
	controls.m_SingleConfirmBtn.gameObject:SetActive(not bIsDoubleBtn)
	
	UIFunction.SetImageSprite(self.Controls.m_ImageTitle, self.m_Title)
    
    if self.m_LiveTime ~= 0 then
        if self.m_LiveTimeCallBack then
            rktTimer.KillTimer(self.m_LiveTimeCallBack, self.m_LiveTime, 1)
        end
        self.m_LiveTimeCallBack = function() self:Hide() end
        rktTimer.SetTimer(self.m_LiveTimeCallBack, self.m_LiveTime, 1)
    end
	if self.m_AutoConFirmTime then
		if self.m_AutoConFirmTimeCallBack == ni then
			self.m_AutoConFirmTimeCallBack = function() self:TimeCount() end
			rktTimer.SetTimer(self.m_AutoConFirmTimeCallBack, 1000, -1, "m_AutoConFirmTimeCallBack")
		end
		self:TimeCount()
	else
		controls.m_ConfirmBtnTxt.text = self.m_ConfirmBtnTxt
	end
end

function ConfirmPopWindow:TimeCount()
	if self.m_AutoConFirmTime <= 0 then
		if self.m_ConfirmCallBack then
			self.m_ConfirmCallBack(self.m_ConfirmArg)
		end
		self:OnBtnCloseClicked()
		return
	end
	self.Controls.m_ConfirmBtnTxt.text = self.m_ConfirmBtnTxt.."("..self.m_AutoConFirmTime..")"
	self.m_AutoConFirmTime = self.m_AutoConFirmTime - 1
end

function ConfirmPopWindow:OnBtnCloseClicked()
    if self.m_LiveTimeCallBack then
        rktTimer.KillTimer(self.m_LiveTimeCallBack, self.m_LiveTime, 1)
        self.m_LiveTimeCallBack = nil
    end
	if self.m_AutoConFirmTimeCallBack then
		rktTimer.KillTimer(self.m_AutoConFirmTimeCallBack)
        self.m_AutoConFirmTimeCallBack = nil
	end
	self:Hide()
end

function ConfirmPopWindow:OnBtnCancelClicked()
	if self.m_CancelCallBack ~= nil then
		self.m_CancelCallBack(self.m_CancleArg)
	end

	self:OnBtnCloseClicked()
end

function ConfirmPopWindow:OnBtnConfirmClicked()
	if self.m_ConfirmCallBack ~= nil then
		self.m_ConfirmCallBack(self.m_ConfirmArg)
	end

	self:OnBtnCloseClicked()
end

----------------------------------------------------------------
--[[
@purpose	：显示确认弹出框
@param ：
data = {
		btnCnt 			: 按钮个数，默认为2
		title			: 标题资源路径
		content 		: 内容
		confirmBtnTxt   ：确认按钮文本
		cancelBtnTxt 	：取消按钮文本
		confirmCallBack : 确认按钮回调，不传默认关闭弹框
		cancelCallBack 	: 取消按钮回调，不传默认关闭弹框
		alignment		: content布局，TextAnchor类型，默认为MiddleCenter布局
}
]]
function ConfirmPopWindow:ShowDiglog(data)
	UIWindow.Show(self, true)

	self.m_BtnCnt = data.btnCnt or 2
	self.m_Content = data.content or ""
	self.m_Title = data.title or AssetPath.TextureGUIPath.."Common_frame/Common_mz_tishi.png"

	self.m_ConfirmBtnTxt = data.confirmBtnTxt or "确  认"
	self.m_CancelBtnTxt = data.cancelBtnTxt or "取  消"
	
	self.m_ConfirmCallBack  = data.confirmCallBack
	self.m_CancelCallBack   = data.cancelCallBack

	self.m_Alignment = data.alignment or UnityEngine.TextAnchor.MiddleCenter
    
    self.m_LiveTime = data.liveTime or self.m_LiveTime
	
	self.m_AutoConFirmTime = data.autoConFirmTime
	
	self.m_ConfirmArg = data.confirmArg
	
	self.m_CancleArg = data.cancleArg
	if not self:isLoaded() then
		return 
	end

	self:UpdateUI()
end

return ConfirmPopWindow
