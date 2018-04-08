-- 设置-基本窗口
-- @Author: XieXiaoMei
-- @Date:   2017-05-23 19:45:00
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-29 12:13:43

local BasicWidget = UIControl:new
{
	windowName = "BasicWidget",

	m_QualitiesTgls = {},
	m_ViewTgls = {},
	m_CurQualityIdx = 1,

	m_RecomQualGo = nil,
}

local this = BasicWidget

local QualitiesStrs = 
{
	"流畅",
	"高清",
	"完美"
}
local DefaultSceenPeoleCnt = 15
local DefaultVolum = 0.5

----------------------------------------------------------------
function BasicWidget:Attach( obj )
	UIControl.Attach(self, obj)

	self:InitUI()
end


function BasicWidget:OnDestroy()
	self.FirstInit = true
	UIControl.OnDestroy(self)

	table_release(self)
end

function BasicWidget:InitUI()
	local controls = self.Controls

	self.m_QualitiesTgls = {
		controls.m_FluencyQualTgl,
		controls.m_HIDQualTgl,
		controls.m_PerfectQualTgl,
	}
	
	self.m_ViewTgls = {
		self.Controls.m_2DToggle,
		self.Controls.m_3DToggle,
	}
	
	self.m_RecomQualGo = controls.m_RecoQualImg.transform.gameObject

	local quality = GetQuality()
	
	if quality == 0 then
		quality = 2
	end
	self.m_QualitiesTgls[quality].isOn = true
	self:SwitchQualitiesTgl(quality)
	
	for i, tgl in ipairs(self.m_QualitiesTgls) do
		tgl.onValueChanged:AddListener(function (on)
			self:OnQualitiesTglsChanged(i, on)
		end)
	end
	
	controls.m_MusicTgl.onValueChanged:AddListener(handler(self, self.OnMusicTglChanged))
	controls.m_MusicTgl.isOn = IsMusicPlayOn()
	
	controls.m_SoundTgl.onValueChanged:AddListener(handler(self, self.OnSoundTglChanged))
	controls.m_SoundTgl.isOn = IsSoundPlayOn()

	controls.m_PowerSaveBtn.onClick:AddListener(handler(self, self.OnBtnPowerSaveClicked))
	controls.m_BackLoginBtn.onClick:AddListener(handler(self, self.OnBtnBackLoginClicked))
	controls.m_UserCenterBtn.onClick:AddListener(handler(self, self.OnBtnUserCenterClicked))
	controls.m_ChgAccountBtn.onClick:AddListener(handler(self, self.OnBtnChgAccountClicked))

	local sceenPeoSlider = controls.m_SceenPeoleSlider:GetComponent(typeof(Slider))
	sceenPeoSlider.minValue = 1
	sceenPeoSlider.maxValue = 100
	local sceenPeople = GetSceenPeople()
	if sceenPeople == 0 then
		sceenPeople = DefaultSceenPeoleCnt
	end
	sceenPeoSlider.value = sceenPeople
	controls.sceenPeoSlider = sceenPeoSlider
	self.Controls.m_SceenPeopleTxt.text = string.format("%s人", math.floor(sceenPeople))
	sceenPeoSlider.onValueChanged:AddListener(handler(self, self.OnSceenPeoSldChanged))
	
	local musicVolSlider = controls.m_MusicVolSlider:GetComponent(typeof(Slider))
	musicVolSlider.minValue = 0
	musicVolSlider.maxValue = 1
	local curVolume = GetMusicVolume()
	if curVolume == -1 then
		curVolume = DefaultVolum
	end
	musicVolSlider.value = curVolume
	curVolume = math.floor(curVolume * 100)
	self.Controls.m_MusicVolTxt.text = curVolume .. "%"
	controls.musicVolSlider = musicVolSlider
	musicVolSlider.onValueChanged:AddListener(handler(self, self.OnMusicVolSldChanged))
	
	local view = GetView()
	if view == 0 then view = 2 end
	if view == 1 then 
		self:SetTglView(1, true)
		self:SetTglView(2, false)
		self.m_ViewTgls[1].isOn = true
		self.m_ViewTgls[2].isOn = false
	else
		self:SetTglView(2, true)
		self:SetTglView(1, false)
		self.m_ViewTgls[1].isOn = false
		self.m_ViewTgls[2].isOn = true
	end
	
	for i, tgl in pairs(self.m_ViewTgls) do
		tgl.onValueChanged:AddListener(function (on)
			self:OnViewTglChanged(i, on)
		end)
	end
	
	
	if quality == 1 then
		self:ForceTo2D(true)
	else
		self:ForceTo2D(false)
	end

    local power_save_mode = GetPowerSaveMode()
    if 1 == power_save_mode then
        controls.m_PowerSaveText.text = "性能模式"
    else
        controls.m_PowerSaveText.text = "省电模式"
    end

end

----------------------------------------------------------------
--TODO
function BasicWidget:OnSceenPeoSldChanged(value)
	self.Controls.m_SceenPeopleTxt.text = string.format("%s人", math.floor(value))
	SetSceenPeople(value)
end

function BasicWidget:OnMusicVolSldChanged(value)
	SetMusicVolume(value)
	value = math.floor(value * 100)
	self.Controls.m_MusicVolTxt.text = value .. "%"
end

----------------------------------------------------------------
function BasicWidget:OnMusicTglChanged(on)
	SetMusicPlayOn(on)
end

function BasicWidget:OnSoundTglChanged(on)
	SetSoundPlayOn(on)
end

function BasicWidget:OnQualitiesTglsChanged(idx, on)
	if not on or idx == self.m_CurQualityIdx then
		return
	end
	
	local data = {}
--	data.content = string.format("将当前画质切换为%s，需要重新进入场景", QualitiesStrs[idx])
    data.content = string.format("是否将当前画质切换为%s", QualitiesStrs[idx])
	data.confirmCallBack = function ()
		self:SwitchQualitiesTgl(idx)
		SetQuality(idx)
        rktRenderQualitySetting.UpdateQualityLevel(idx-1)
	end
	data.cancelCallBack = function ()
		print("取消切换")
	end
	UIManager.ConfirmPopWindow:ShowDiglog(data)
	
end

function BasicWidget:OnViewTglChanged(i, on)
	if on then 
		self:SetTglView(i, true)
	else		
		self:SetTglView(i, false)
		return
	end
	
	--设置
	if self.m_CurQualityIdx ~= 1 then
		SetView(i)			--非低画质，则更新设置
	end
	local flag = ( i == 2 )						--是否是3D视角
	rktMainCamera.SetViewType(flag)
end
--设置视角tgl显示
function BasicWidget:SetTglView(i, on)
	self.m_ViewTgls[i].transform:Find("Background/Checkmark").gameObject:SetActive(on)
end

function BasicWidget:SwitchQualitiesTgl(idx)
	local showTglCheckMark = function (i, isShow)
		if not i or i == 0 then
			return
		end
		local checkmark = self.m_QualitiesTgls[i].transform:Find("Checkmark")
		checkmark.gameObject:SetActive(isShow)
	end

	showTglCheckMark(self.m_CurQualityIdx, false)
	showTglCheckMark(idx, true)

	local isHIDTglClick = idx == 2
	self.m_RecomQualGo:SetActive(not isHIDTglClick)

	self.m_CurQualityIdx = idx

	if idx == 1 then
		self:ForceTo2D(true)
	else
		self:ForceTo2D(false)
		local view = GetView()
		if view == 0 then view = 2 end
		self.m_ViewTgls[view].isOn = true
		if view == 1 then 
			self.m_ViewTgls[2].isOn = false
		elseif view == 2 then
			self.m_ViewTgls[1].isOn = false
		end
	end

	print("当前画质 :", self.m_CurQualityIdx)
end

--强制选中2D模式
function BasicWidget:ForceTo2D(is2D)
	if is2D then
		self.Controls.m_2DToggle.isOn = true
		self.Controls.m_3DToggle.interactable = false
		UIFunction.SetAllComsGray(self.Controls.m_3DToggle.gameObject, true)
	else
		self.Controls.m_3DToggle.interactable = true
		UIFunction.SetAllComsGray(self.Controls.m_3DToggle.gameObject, false)
	end
end

----------------------------------------------------------------
function BasicWidget:OnBtnPowerSaveClicked()
    local power_save_mode = GetPowerSaveMode()
    if 0 == power_save_mode then
        SetPowerSaveMode(1)
        self.Controls.m_PowerSaveText.text = "性能模式"
        rktRenderQualitySetting.SetToPowerSaveSettings()
       	IGame.ChatClient:addSystemTips(TipType_Operate,InfoPos_ActorUnder, "进入省电模式")
    else
        SetPowerSaveMode(0)
        self.Controls.m_PowerSaveText.text = "省电模式"
        rktRenderQualitySetting.RestoreFromPowerSaveSettings()
        IGame.ChatClient:addSystemTips(TipType_Operate,InfoPos_ActorUnder, "进入性能模式")
    end
end

function BasicWidget:OnBtnBackLoginClicked()
	print("返回登录")
	UIManager.SettingsWindow:Hide()
	IGame.CommonClient:SwitchLoginStateSystem()
end


function BasicWidget:OnBtnChgAccountClicked()
	print("切换账号")
	UIManager.SettingsWindow:Hide()
	IGame.CommonClient:NotifyQuitSystem()
end


function BasicWidget:OnBtnUserCenterClicked()
	print("用户中心")
end


return BasicWidget