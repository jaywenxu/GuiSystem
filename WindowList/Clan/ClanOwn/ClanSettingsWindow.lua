-- 帮派设置界面
-- @Author: XieXiaoMei
-- @Date:   2017-04-18 09:36:19
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-24 16:57:44

local ClanSettingsWindow = UIWindow:new
{
	windowName        = "ClanSettingsWindow",
	
	m_MeetCondFlag    = false,	--满足条件才能申请
	m_AutoRecvFlag 	  = false,  --自动接收成员
	m_AutoInviteFlag  = false,  --自动邀请
	m_RecvLevel 	  = 0,  	--限制等级
}

local LimitLvMin = 20
local LimitLvMax = 150

------------------------------------------------------------
function ClanSettingsWindow:Init()
	
end

function ClanSettingsWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	
	self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))

	local controls = self.Controls
	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_BackBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_ConfirmBtn.onClick:AddListener(handler(self, self.OnBtnConfirmClicked))
	controls.m_SubLvBtn.onClick:AddListener(handler(self, self.OnBtnSubLvClicked))
	controls.m_AddLvBtn.onClick:AddListener(handler(self, self.OnBtnAddLvClicked))
	controls.m_LvInputBtn.onClick:AddListener(handler(self, self.OnBtnLvInputClicked))

 	-- local inputField = controls.m_LevelLmtInput:GetComponent(typeof(InputField))
	-- inputField.onValueChanged:AddListener(handler(self, self.CheckInputValue))
 	-- controls.inputField = inputField
 	
 	controls.m_CondMeetTgl.onValueChanged:AddListener(function (on)
 		self.m_MeetCondFlag = on
 	end)

 	controls.m_AutoRecvTgl.onValueChanged:AddListener(function (on)
 		self.m_AutoRecvFlag  = on
 	end)

 	self:RefreshUI()
end

function ClanSettingsWindow:OnEnable()
	self:RefreshUI()
end

function ClanSettingsWindow:RefreshUI()
	local clan = IGame.ClanClient:GetClan()
 	local autoAcpt = clan:GetAutoAccept()

 	local controls = self.Controls
 	controls.m_InputLvTxt.text = autoAcpt.nAcceptLevel

 	self.m_MeetCondFlag = autoAcpt.bMeetRequestCanApply
 	self.m_AutoRecvFlag = autoAcpt.bAutoAccept
 	
 	controls.m_CondMeetTgl.isOn = self.m_MeetCondFlag
 	controls.m_AutoRecvTgl.isOn = self.m_AutoRecvFlag

 	self:RefreshBtnsState(autoAcpt.nAcceptLevel)
end


function ClanSettingsWindow:RefreshBtnsState(level)
	local controls = self.Controls

	local gameObj = controls.m_SubLvBtn.gameObject
	local bGray = level <= LimitLvMin
	UIFunction.SetImgComsGray( gameObj , bGray )
	UIFunction.SetButtonClickState(gameObj, not bGray)	

	gameObj = controls.m_AddLvBtn.gameObject
	bGray = level >= LimitLvMax
	UIFunction.SetImgComsGray( gameObj , bGray )
	UIFunction.SetButtonClickState(gameObj, not bGray)	
end


function ClanSettingsWindow:OnBtnCloseClicked()
	self:Hide()
end

function ClanSettingsWindow:OnBtnConfirmClicked()

	local level = tonumber(self.Controls.m_InputLvTxt.text)
	if IsNilOrEmpty(level) or (level < LimitLvMin or level > LimitLvMax)  then
		local str = string.format("限制等级必须大于%d小于%d", LimitLvMin, LimitLvMax)
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, str)
		return 
	end

	print("发送自动设置请求 满足条件：", tostring(self.m_MeetCondFlag), 
		"，自动接收：", tostring(self.m_AutoRecvFlag), 
		"，限制等级：", level)

	local bAutoInvite = self.m_AutoInviteFlag
	local acceptData = 127
	IGame.ClanClient:SetAutoAcceptRequest(self.m_AutoRecvFlag, bAutoInvite, self.m_MeetCondFlag, level, acceptData)
	self:OnBtnCloseClicked()
end

function ClanSettingsWindow:OnBtnSubLvClicked()
	local txt = self.Controls.m_InputLvTxt
	local lv = tonumber(txt.text)
	lv = lv - 1
	lv = lv < LimitLvMin and LimitLvMin or lv
	txt.text = lv

	self:RefreshBtnsState(lv)
end

function ClanSettingsWindow:OnBtnAddLvClicked()
	local txt = self.Controls.m_InputLvTxt
	local lv = tonumber(txt.text)
	lv = lv + 1
	lv = lv > LimitLvMax and LimitLvMax or lv
	txt.text = lv

	self:RefreshBtnsState(lv)
end

function ClanSettingsWindow:OnBtnLvInputClicked() 
	local txt = self.Controls.m_InputLvTxt
	
	local numTable = {
	    ["inputNum"] = tonumber(txt.text),
		["minNum"]   = LimitLvMin,
		["maxNum"]   = LimitLvMax, 
		["bLimitExchange"] = 0
	}
	local otherInfoTable = {
		["inputTransform"] = txt.transform,
	    ["bDefaultPos"] = 0,
	    ["callback_UpdateNum"] = function (num)
	    	txt.text = num
	    	self:RefreshBtnsState(tonumber(txt.text))
	    end
	}
	UIManager.NumericKeypadWindow:ShowWindow(numTable, otherInfoTable) -- 打开小键盘
end


return ClanSettingsWindow
------------------------------------------------------------

