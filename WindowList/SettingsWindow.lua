-- 游戏设置界面
-- @Author: XieXiaoMei
-- @Date:   2017-05-23 15:00:14
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-06 15:45:15

local SettingsWindow = UIWindow:new
{
	windowName = "SettingsWindow",

	m_TabToggles = {},
	m_WidgetObjs = {},
	m_TabWidgets = {},

	m_GotoTabIdx = 1, -- 前往跳转的索引
}

local WdtLuaFiles = 
{
	"BasicWidget" ,
	"GameWidget"  ,
	"FightWidget" ,
	"MedicineWidget" ,
}

local WdtLuaFilePath = "GuiSystem.WindowList.Settings."

local this = SettingsWindow

function SettingsWindow:Init()
end


function SettingsWindow:OnAttach( obj )
	UIWindow.OnAttach(self, obj)

	self:InitUI()
end


function SettingsWindow:ShowWindow( idx )
	UIWindow.Show(self, true)

	self.m_GotoTabIdx = idx or 1
end

function SettingsWindow:Hide(destroy)
	rktEventEngine.FireEvent(EVENT_SETTING_CLOSEWINDOW, 0, 0)
	UIWindow.Hide(self, destroy)

	local medicWdt = self.m_TabWidgets[4]
	if medicWdt then
		medicWdt:SaveMedicSettings()
	end
end

function SettingsWindow:OnDestroy()
	UIWindow.OnDestroy(self)

	table_release(self)

	self.m_GotoTabIdx = 1
end


function SettingsWindow:InitUI()
	local controls = self.Controls

	self.m_TabToggles = {
		controls.m_BasicTgl,
		controls.m_GameTgl,
		controls.m_FightTgl,
		controls.m_MedicineTgl,
	}

	self.m_WidgetObjs = {
		controls.m_BasicWidget,
		controls.m_GameWidget,
		controls.m_FightWidget,
		controls.m_MedicineWidget,
	}

	for i, tgl in ipairs(self.m_TabToggles) do
		tgl.onValueChanged:AddListener(function (on)
			self:OnTogglesChanged(i, on)
		end)
	end

	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))

	self:OnTogglesChanged(self.m_GotoTabIdx, true)
end

function SettingsWindow:OnTogglesChanged(idx, on)
	
	if not self.m_TabToggles[idx] then
		return
	end
	
	if on then 
		self.m_TabToggles[idx].transform:Find("Background/Checkmark").gameObject:SetActive(true)
	else
		self.m_TabToggles[idx].transform:Find("Background/Checkmark").gameObject:SetActive(false)
	end

	local tabWdt = self.m_TabWidgets[idx]
	if on then
		if self.m_TabToggles[idx].isOn ~= on then
			self.m_TabToggles[idx].isOn = on
			return
		end

		if not tabWdt then
			tabWdt = require( WdtLuaFilePath.. WdtLuaFiles[idx]):new()
			tabWdt:Attach(self.m_WidgetObjs[idx].gameObject)

			self.m_TabWidgets[idx] = tabWdt
		end

		tabWdt:Show()
	else
		if tabWdt then
			tabWdt:Hide()
		end
	end
end


function SettingsWindow:OnBtnCloseClicked()
	self:Hide()
end

-- 获取设置血条百分比
function SettingsWindow:GetSliderValue()
	local idx = 4 -- 自动吃药界面
	if not self.m_TabWidgets[idx] then
		return 0
	end
	return self.m_TabWidgets[idx]
end


return SettingsWindow