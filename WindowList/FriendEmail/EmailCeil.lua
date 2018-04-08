-- 单个邮件ceil元素
-- @Author: XieXiaoMei
-- @Date:   2017-05-12 12:16:21
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-29 12:08:26

local EmailCeil = UIControl:new
{
	windowName         = "EmailCeil",

	m_OnToggleChgCallback = nil,
	m_SelectedCallback = nil,
	m_SelCellIdx  	   = 0,

	m_Data = nil
}

local this = EmailCeil

local HasAppxIconFile = "Email/Email_xinjian_weidianji.png"
local NoAppxIconFile  = "Email/Email_xinjian_weidianji.png"
local ReadedIconFile  = "Email/Email_xinjian_yidianji.png"

-------------------------------------------------------------
function EmailCeil:Attach( obj )
	UIControl.Attach(self, obj)

	self.m_OnToggleChgCallback = function(on) self:OnSelectChanged(on) end
    local toggle = self.transform:GetComponent(typeof(Toggle))
	toggle.onValueChanged:AddListener(self.m_OnToggleChgCallback)
	
	self.Controls.toggle = toggle
end


function EmailCeil:SetCellData(idx, data)
	local controls = self.Controls

	controls.m_TitleTxt.text = data.szTopic
	controls.m_DateTxt.text = TimerToStringYMD(data.nReceiveTime, 1)

	self:RefreshEmailIcon(data)

	self.m_Data = data

	self.m_SelCellIdx = idx
end

function EmailCeil:RefreshEmailIcon(data)
	local imgFilePath = NoAppxIconFile
	if data.bHasPlusData then
		imgFilePath = HasAppxIconFile
	else
		if data.bIsRead then
			imgFilePath = ReadedIconFile
		end
	end
	UIFunction.SetImageSprite(self.Controls.m_IconImg, GuiAssetList.GuiRootTexturePath .. imgFilePath)
end

-- 设置选中回调
function EmailCeil:SetSelectCallback( func_cb )
	self.m_SelectedCallback = func_cb
end

-- 设置toggle group
function EmailCeil:SetToggleGroup(toggleGroup)
    self.Controls.toggle.group = toggleGroup
end

-- 设置toggle group
function EmailCeil:SetToggleIsOn(on)
	local tgl = self.Controls.toggle
	if tgl ~= nil then
    	tgl.isOn = on
    end
end


function EmailCeil:OnSelectChanged(on)
	if nil ~= self.m_SelectedCallback and on then
		self.m_SelectedCallback(self.m_SelCellIdx)

		self.m_Data.bIsRead = true
		self:RefreshEmailIcon(self.m_Data)
	end
end

function EmailCeil:OnBtnCloseClicked()
	self:Hide()
end


function EmailCeil:OnRecycle()
	self.Controls.toggle.onValueChanged:RemoveListener(self.m_OnToggleChgCallback)
	self.m_SelectedCallback = nil
	
	local toggle = self.Controls.toggle
	toggle.group = nil
	toggle.isOn = false
	
	UIControl.OnRecycle(self)

	table_release(self)
end


function EmailCeil:OnDestroy()
	self.m_OnToggleChgCallback = nil
	self.m_SelectedCallback = nil
	UIControl.OnDestroy(self)

	table_release(self)
end


return EmailCeil
