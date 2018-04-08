-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017/02/19
-- 版  本:    1.0
-- 描  述:    喇叭窗口--服务器存喇叭列表，喇叭播放间隔服务器定，客户端不存列表
-------------------------------------------------------------------

local SpeakerWindow = UIWindow:new
{
	windowName		= "SpeakerWindow",
	m_TimeHander	= nil,
	m_TimerRunning	= false,
	LiveTime		= 3000,
	m_anims			= nil,
}

------------------------------------------------------------
function SpeakerWindow:Init()
	self.m_TimeHander = function() self:OnTimer() end
	self.m_TimeHanderTextMove = function() self:OnTimerTextMove() end
	self.m_TimeHanderTextMove_Sys = function() self:OnTimerTextMoveSys() end
end

------------------------------------------------------------
function SpeakerWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
    return self
end

------------------------------------------------------------
-- 窗口销毁
function SpeakerWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

------------------------------------------------------------
--设置内容
function SpeakerWindow:SetSpeakerText(SenderName,MsgText)
	self.Controls.m_SysMask.gameObject:SetActive(false)
	self.Controls.m_BG.gameObject:SetActive(true)
	local Transform = self.Controls.m_MsgText.gameObject:GetComponent(typeof(RectTransform))
	Transform.localPosition = Vector3.New(0,0,0)
	self.Controls.m_SenderName.text = tostring("["..SenderName.."]")
	self.Controls.m_MsgText.text = tostring(MsgText)
	rktTimer.SetTimer(self.m_TimeHanderTextMove, Chat_SPEAK_MOVE_QIAN, 1, "SpeakerWindow:SetTimer")
	self:Show(true)
end

------------------------------------------------------------
--设置内容-长系统
function SpeakerWindow:SetLongSysSpeakerText(MsgText)
	self.Controls.m_SysMask.gameObject:SetActive(true)
	self.Controls.m_BG.gameObject:SetActive(false)
	self.Controls.m_SysMsgTextShort.text = ""
	
	local Transform = self.Controls.m_SysMsgText.gameObject:GetComponent(typeof(RectTransform))
	Transform.localPosition = Vector3.New(0,0,0)
	self.Controls.m_SysMsgText.text = tostring(MsgText)
	rktTimer.SetTimer(self.m_TimeHanderTextMove_Sys, Chat_SPEAK_MOVE_QIAN, 1, "SpeakerWindow:SetTimer")
	self:Show(true)
end

------------------------------------------------------------
--设置内容-短系统
function SpeakerWindow:SetShortSysSpeakerText(MsgText)
	self.Controls.m_SysMask.gameObject:SetActive(true)
	self.Controls.m_BG.gameObject:SetActive(false)
	self.Controls.m_SysMsgText.text = ""
	self.Controls.m_SysMsgTextShort.text = tostring(MsgText)
	self:Show(true)
end

------------------------------------------------------------
--定时器回调函数
function SpeakerWindow:OnTimer()
	self.m_TimerRunning = false
	self.m_anims = nil
	self:Hide()
	rktTimer.KillTimer( self.m_TimeHander )
end

------------------------------------------------------------
-- 添加新的tpis消息到列表
function SpeakerWindow:OnSpeakerArrived(msgTable)
	self:Show(true)
	if self.m_anims then
		self.m_anims:DOKill()
	end
	self:RefrashSpeaker(msgTable)
end

------------------------------------------------------------
-- 刷新喇叭显示
function SpeakerWindow:RefrashSpeaker(msgTable)
	if not self:isLoaded() then
		DelayExecuteEx(10,function ()
			self:RefrashSpeaker(msgTable)
		end)
		return
	end
	if self.m_TimerRunning == true then
		rktTimer.KillTimer( self.m_TimeHander )
	end
	local SysSZ = "<color=red>[系统提示]</color>"
	self.m_TimerRunning = true
	rktTimer.SetTimer(self.m_TimeHander, 8000, -1, "SpeakerWindow:SetTimer")
	
	--cLog("刷新喇叭显示"..tostringEx(self.Controls.m_MsgText)..", "..tostringEx(msgTable.szText))
	local Rect = rkt.UIAndTextHelpTools.GetRichTextSize(self.Controls.m_MsgText,SysSZ..msgTable.szText)
	local chatCellWidth  = Rect.x
	local ShowWidth = self.Controls.m_SysMask.sizeDelta.x
	--cLog(" SpeakerWindow:RefrashSpeaker 刷新喇叭显示 "..tostringEx(chatCellWidth),"red")
	if msgTable.dwSenderDBID ~= 0 and msgTable.szSenderName ~= "系统" and msgTable.szSenderName ~= "系统管理员" then
		self:SetSpeakerText(msgTable.szSenderName,msgTable.szText)
	elseif chatCellWidth <= ShowWidth then
		self:SetShortSysSpeakerText(SysSZ..msgTable.szText)
	else
		self:SetLongSysSpeakerText(SysSZ..msgTable.szText)
	end
end

function SpeakerWindow:OnTimerTextMove()
	rktTimer.KillTimer( self.m_TimeHanderTextMove )
	local anims = self.Controls.m_MsgText.gameObject:GetComponent(typeof(DG.Tweening.DOTweenAnimation))	
	local Transform = self.Controls.m_MsgText.gameObject:GetComponent(typeof(RectTransform))
	--local Transform.localPosion = Vector3.New(0,0,0)
	local ShowWidth = self.Controls.m_TextMask.sizeDelta.x
	if Transform.sizeDelta.x <= ShowWidth then
		return
	end
	local vec3Point = Vector3.New(ShowWidth - Transform.sizeDelta.x,0,0)
	local duration = (Transform.sizeDelta.x - ShowWidth)/Chat_SPEAK_MOVE_SPEED
	if duration > Chat_SPEAK_MOVE_MAX_TIME then
		duration = Chat_SPEAK_MOVE_MAX_TIME
	end
	anims.duration = duration
	anims.endValueV3 = vec3Point
	anims:DOKill()
	anims:CreateTween()
	anims:DORestart(false)
	self.m_anims = anims
end

function SpeakerWindow:OnTimerTextMoveSys()
	rktTimer.KillTimer( self.m_TimeHanderTextMove_Sys )
	local anims = self.Controls.m_SysMsgText.gameObject:GetComponent(typeof(DG.Tweening.DOTweenAnimation))	
	local Transform = self.Controls.m_SysMsgText.gameObject:GetComponent(typeof(RectTransform))
	local ShowWidth = self.Controls.m_SysMask.sizeDelta.x
	if Transform.sizeDelta.x <= ShowWidth then
		return
	end
	local vec3Point = Vector3.New(ShowWidth - Transform.sizeDelta.x,0,0)
	local duration = (Transform.sizeDelta.x - ShowWidth)/Chat_SPEAK_MOVE_SPEED
	if duration > Chat_SPEAK_MOVE_MAX_TIME then
		duration = Chat_SPEAK_MOVE_MAX_TIME
	end
	anims.duration = duration
	anims.endValueV3 = vec3Point
	--cLog("juli "..(ShowWidth).."  "..(Transform.sizeDelta.x),"red")
	anims:DOKill()
	anims:CreateTween()
	anims:DORestart(false)
	self.m_anims = anims
end




return SpeakerWindow