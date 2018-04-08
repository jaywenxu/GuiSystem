-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017/02/19
-- 版  本:    1.0
-- 描  述:    滴答窗口
-------------------------------------------------------------------

local SpeechNoticeWindow = UIWindow:new
{
	windowName = "SpeechNoticeWindow",
	m_RecordState = 0, -- 语音发送状态，0：初始状态  1：按下状态（开始录音）  2：已超时状态（结束录音但是没抬手）
	CallBackFunc = "",
}

local RecordLen = 0
local RealRecordLen = 0
local this = SpeechNoticeWindow					-- 方便书写

------------------------------------------------------------
function SpeechNoticeWindow:Init()
	self.m_TimeHanderRecord = function() self:OnRecordTimer() end
end

------------------------------------------------------------
function SpeechNoticeWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj,UIManager._SpecialTopLayer)
	self.Controls.SpeakNotice.gameObject:SetActive(false)
	self.Controls.CancelNotice.gameObject:SetActive(false)
	
	for i=1,6 do
		self["Volume"..i] = self.Controls.SpeakNotice:Find("Volume"..i)
	end
	for i=2,6 do
		self["Volume"..i].gameObject:SetActive(false)
	end
    return self
end

------------------------------------------------------------
-- 点下录音按钮
function SpeechNoticeWindow:OnBtnDownClick(eventData)
	self.m_RecordState = 1
	RecordLen = 0
	RealRecordLen = 0
	rktTimer.SetTimer(self.m_TimeHanderRecord, 500, -1, "SpeechNoticeWindow:SetTimer")
end

function SpeechNoticeWindow:OnBtnUpClick(eventData)
	--print("点下录音按钮 OnBtnUpClick")
	self.m_RecordState = 0
	if not self:isLoaded() then
		return
	end
	local pressPosition =  eventData.pressPosition
	local CurrentPosition =  eventData.position
	self.Controls.SpeakNotice.gameObject:SetActive(false)
	self.Controls.CancelNotice.gameObject:SetActive(false)
	local X = math.abs(pressPosition.x - CurrentPosition.x)
	local Y = math.abs(pressPosition.y - CurrentPosition.y)
	for i=2,6 do
		self["Volume"..i].gameObject:SetActive(false)
	end
	if  X > 1000 or Y >200 then
		--IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "松手录音按钮,取消发送")
		GameHelp.CancleRecord()
		self.CallBackFunc = ""
		return
	end
	rktTimer.KillTimer( self.m_TimeHanderRecord )
	GameHelp.StopRecord(self.CallBackFunc)
	
	
--[[	-- 电脑测试代码
	local recordData = {}
	recordData.speech = "电脑测试"
	recordData.time = 12
	recordData.url = "http://store2.aiwaya.cn/amr58df6bcbbd42f20c64bd8596.amr"
	--_G[self.CallBackFunc](recordData)
	self.CallBackFunc(recordData)
	
	self.CallBackFunc = ""--]]
end

function SpeechNoticeWindow:OnBtnDragClick(eventData)
	local pressPosition =  eventData.pressPosition
	local CurrentPosition =  eventData.position
	local Y = math.abs(pressPosition.y - CurrentPosition.y)
	if Y > 200 then
		--print("=======拖动录音按钮 ")
		self.Controls.SpeakNotice.gameObject:SetActive(false)
		self.Controls.CancelNotice.gameObject:SetActive(true)
	else
		self.Controls.SpeakNotice.gameObject:SetActive(true)
		self.Controls.CancelNotice.gameObject:SetActive(false)
	end
end

function SpeechNoticeWindow:ShowVoiceVolume(Num)
	for i=1,6 do
		if i > Num then
			self["Volume"..i].gameObject:SetActive(false)
		else
			self["Volume"..i].gameObject:SetActive(true)
		end
	end
end

function SpeechNoticeWindow:OnRecordTimer()
	--print("========= RecordLen",RecordLen)
	if self.m_RecordState == 0 then
		RecordLen = 0
		RealRecordLen = 0
		rktTimer.KillTimer( self.m_TimeHanderRecord )
		GameHelp.StopRecord(self.CallBackFunc)
		return
	end
	if RecordLen == 0 then
		local ret = GameHelp.StartRecord()
		if not ret then
			print("录音失败")
			self.m_RecordState = 0
			self:Hide()
			rktTimer.KillTimer( self.m_TimeHanderRecord )
			return
		end
		self.Controls.SpeakNotice.gameObject:SetActive(true)
		self.Controls.CancelNotice.gameObject:SetActive(false)
	end
	if RecordLen < 20 and self.m_RecordState == 1 then
		RecordLen = RecordLen + 1
		RealRecordLen = RealRecordLen + 0.5
		SpeechNoticeWindow:ShowVoiceVolume(math.fmod(RecordLen,6)+1)
		return
	end
	
	if RealRecordLen < 1 then
		return
	end
	
	RecordLen = 0
	RealRecordLen = 0
	rktTimer.KillTimer( self.m_TimeHanderRecord )
	--IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "录音超时，开始发送已录的")
	GameHelp.StopRecord(self.CallBackFunc)
end

function SpeechNoticeWindow:SetCallBackFunc(CallBackFunc)
	self.CallBackFunc = CallBackFunc
end


return this







