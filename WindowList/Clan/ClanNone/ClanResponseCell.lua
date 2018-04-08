-- 响应帮派列表cell类
-- @Author: XieXiaoMei
-- @Date:   2017-04-10 10:28:16
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-08 10:29:59

------------------------------------------------------------
local ClanResponseCell = UIControl:new
{
	windowName         = "ClanResponseCell",
	m_CellIdx          = 0,
	
	m_SelectedCallback = nil,
	m_TglChangedCallback = nil,
	m_RespTimeOutCallback = nil,

	m_CDTimerCallBack  = nil,

	m_RespLeftTime = 0,
}

local this = ClanResponseCell
------------------------------------------------------------

function ClanResponseCell:Attach(obj)
	UIControl.Attach(self,obj)

	self:AddListener( self.Controls.m_RespToggle , "onValueChanged" , self.OnTglCellChanged , self )
end

function ClanResponseCell:ResetCell()
	self:StopCDTimer()

	self.Controls.m_RespToggle.isOn = false

	self.m_SelectedCallback = nil
	self.m_TglChangedCallback = nil
	self.m_RespTimeOutCallback = nil
end

function ClanResponseCell:OnRecycle()
	self:ResetCell()

	UIControl.OnRecycle(self)

	table_release(self)
end

function ClanResponseCell:OnDestroy()
	self:ResetCell()

	UIControl.OnDestroy(self)

	table_release(self)
end

-- 填充cell数据
function ClanResponseCell:SetCellData(idx, data, bFocus)
	local controls = self.Controls

	-- cLog("ClanResponseCell:SetCellData", "red")

	controls.m_IDTxt.text       = data.dwID
	controls.m_NameTxt.text     = data.szName
	controls.m_CreatorTxt.text  = data.szShaikhName

	local maxRespCnt = IGame.ClanClient:GetClanConfig(CLAN_CONFIG.REPONSE_COUNT)
	controls.m_RespNumTxt.text  = string.format("%d/%d", data.nMemberCount, maxRespCnt)
	
	local respTotalTime = IGame.ClanClient:GetClanConfig(CLAN_CONFIG.REPONSE_DURATION)
	local sec = respTotalTime - (IGame.EntityClient:GetZoneServerTime() - data.nCreateTime)

	-- print("nCreateTime:", data.nCreateTime)
	-- print("respTotalTime:", respTotalTime)
	-- print("sec:", sec)
	if sec > 0 then
		local s = ""
		if sec >= 3600 then -- 1小时以上,显示：xx小时xx分
			s = GetCDTime(sec, 6)
		else 		
			s = GetCDTime(sec, 3) -- 不足1小时，显示：xx分xx秒，并且倒计时
			
			self.m_CDTimerCallBack = function()
				self.m_RespLeftTime = self.m_RespLeftTime - 1
				if self.m_RespLeftTime <= 0 then
					if self.m_RespTimeOutCallback then
						self.m_RespTimeOutCallback(self.m_CellIdx) -- 倒计时完成，清理自己帮会
					end
					self:StopCDTimer()
					return
				end
				controls.m_LeftTimeTxt.text = GetCDTime(self.m_RespLeftTime, 3)
			end
	
			rktTimer.SetTimer(self.m_CDTimerCallBack, 1000, sec, "clan response time down")
	
			self.m_RespLeftTime = sec
		end
		controls.m_LeftTimeTxt.text  = s
	else
		controls.m_LeftTimeTxt.text  = ""
	end
	controls.m_LineImg.enabled = data.nIsApply
	controls.m_LeftTimeTxt.enabled = not data.nIsApply
	
	self:SetToggleOn(bFocus)

	self.m_CellIdx  = idx
end

-- 设置选中回调
function ClanResponseCell:SetSelectCallback( func_cb )
	self.m_SelectedCallback = func_cb
end


-- 设置倒计时结束回调
function ClanResponseCell:SetRespTimeOutCallback( func_cb )
	self.m_RespTimeOutCallback = func_cb
end

-- 设置toggle group
function ClanResponseCell:SetToggleGroup(toggleGroup)
    self.Controls.m_RespToggle.group = toggleGroup
end


-- 设置选中的toggle 选中/取消选中
function ClanResponseCell:SetToggleOn(isOn)	
	self.Controls.m_RespToggle.isOn = isOn
end


-- 停止倒计时
function ClanResponseCell:StopCDTimer()
	if nil ~= self.m_CDTimerCallBack then
		rktTimer.KillTimer(self.m_CDTimerCallBack)
		self.m_CDTimerCallBack = nil
	end
end

-- cell toggle 选中回调
function ClanResponseCell:OnTglCellChanged(on)
	--local color = on and Color.New(1,1,1,1) or Color.New(0.117,0.353,0.408,1)
	--UIFunction.SetTxtComsColor(self.transform.gameObject, color)
	
	if nil ~= self.m_SelectedCallback and on then
		self.m_SelectedCallback(self.m_CellIdx)
	end
end

return this