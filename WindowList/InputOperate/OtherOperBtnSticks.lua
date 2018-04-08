-- 其它输入操作面板
-- @Author: XieXiaoMei
-- @Date:   2017-06-15 11:20:27
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-04 16:40:55

local OtherOperBtnSticks = UIControl:new
{
	windowName = "OtherOperBtnSticks",

	m_OperBtnCallbacks = {}, 	-- 按钮回调列表
	m_CoolTime = 0,
	m_CanUse = true,
}

local UIOperBtnName = "m_OpBtn" 	-- UIWindowBehavior中定义的按钮名
local UIOperBtnCnt = 1			-- 按钮的数量

------------------------------------------------------------
function OtherOperBtnSticks:Attach(obj, tData)
	UIControl.Attach(self,obj)

	self.CoolUpdate = function() self:OnCoolUpdate() end

	local controls = self.Controls
	for i=1, UIOperBtnCnt do
		local btn = controls[UIOperBtnName .. i]
		if btn ~= nil then
			btn.onClick:AddListener(function()
                self:OnBtnOperateClicked(i)            
            end)
			btn.gameObject:SetActive(false)
		end
	end
	
	if tData then
		self:ShowOperBtn(tData)
	end
end


function OtherOperBtnSticks:OnBtnOperateClicked(idx)
	print("操作按钮按下 ", idx)

	if self.m_OperBtnCallbacks[idx] == nil then
		return 
	end

	if not self.m_CanUse then
		return
	end
	self.m_OperBtnCallbacks[idx]()
end


function OtherOperBtnSticks:OnDestroy()
	rktTimer.KillTimer(self.CoolUpdate)
	rktEventEngine.UnSubscribeExecute(EVENT_OTHEROPERBTN_COOLSTART,SOURCE_TYPE_FREEZE, 0,self.CoolStartCB)
    UIControl.OnDestroy(self)

    self.m_OperBtnCallbacks = {}
end

------------------------------------------------------------
-- 显示操作按钮
-- @param
-- data = {
--		btnIdx 		：操作按钮索引
--		callback 	：回调函数
--		icon	    : icon图标
--		text		: 文字
-- }
function OtherOperBtnSticks:ShowOperBtn(data)
	if self.CoolStartCB == nil then 
		self.CoolStartCB = function() self:OnCoolStart() end
	end

	
	rktEventEngine.SubscribeExecute(EVENT_OTHEROPERBTN_COOLSTART,SOURCE_TYPE_FREEZE, 0,self.CoolStartCB)
	
	self.m_CoolTime = data.coolTime or 0
	if self.m_CoolTime < 0 then
		self.m_CoolTime = 0
	end
	
	local nIndex = data.btnIdx or 1
	
	local btn = self.Controls[UIOperBtnName .. nIndex]
	if btn ~= nil then
		btn.gameObject:SetActive(true)
		self.m_OperBtnCallbacks[nIndex] = data.callback

		self:SetOperBtnUI(nIndex, data.icon, data.text)
	end
end

------------------------------------------------------------
-- 隐藏操作按钮
-- @param:
--		btnIdx 		： 操作按钮索引
function OtherOperBtnSticks:HideOperBtn(btnIdx)
	btnIdx  = btnIdx or 1
	rktTimer.KillTimer(self.CoolUpdate)
	rktEventEngine.UnSubscribeExecute(EVENT_OTHEROPERBTN_COOLSTART,SOURCE_TYPE_FREEZE, 0,self.CoolStartCB)
	self.CoolStartCB = nil
	self.coolTime = 0
	local btn = self.Controls[UIOperBtnName .. btnIdx]
	if btn ~= nil then
		btn.gameObject:SetActive(false)
		self.m_OperBtnCallbacks[btnIdx] = nil
	end
end

------------------------------------------------------------
-- 设置操作按钮UI
-- @param:
--		btnIdx 		：操作按钮索引
--		icon 		: icon图标
--		text 		: 文字
function OtherOperBtnSticks:SetOperBtnUI(btnIdx, icon, text)
	local btn = self.Controls[UIOperBtnName .. btnIdx]
	if btn == nil then
		return
	end

	if not IsNilOrEmpty(icon) then
		local img = btn.transform:Find("Icon"):GetComponent(typeof(Image))
		UIFunction.SetImageSprite( img , icon, nil)
	end

	self:SetText(text)
	UIFunction.SetAllComsGray( btn.gameObject , false )
end

--设置按钮UI  text
function OtherOperBtnSticks:SetText(text)
	if not text or text == "" then
		self.Controls.m_OPBG.gameObject:SetActive(false)
		return
	end
	self.Controls.m_OPBG.gameObject:SetActive(true)
	self.Controls.m_OpText.text = text
end

------------------------------------------------------
--冷却开始
function OtherOperBtnSticks:OnCoolStart() 
	if self.m_CoolTime == 0 then return end
	self.m_CanUse = false
	self.StartTick = luaGetTickCount()
	self.Controls.m_CoolImg.gameObject:SetActive(true)
	rktTimer.SetTimer(self.CoolUpdate, 30, -1,"OtherOperBtnSticks:OnCoolUpdate")
end

--定时器方法
function OtherOperBtnSticks:OnCoolUpdate()
	local curTick = luaGetTickCount()
	local passTime = curTick - self.StartTick
	
	local fill = 1 - passTime / self.m_CoolTime
	
	if fill < 0 then 
		fill = 0
	end
	
	self.Controls.m_CoolImg.fillAmount = fill
	
	if curTick - self.StartTick >= self.m_CoolTime then 
		self.Controls.m_CoolImg.gameObject:SetActive(false)
		self.m_CanUse = true
		rktTimer.KillTimer(self.CoolUpdate)
	end
end

return OtherOperBtnSticks