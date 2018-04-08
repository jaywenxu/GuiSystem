

-- 红包发送界面

------------------------------------------------------------
local RedPacketSend = UIControl:new
{
	windowName = "RedPacketSend",
	currentPage = 0,                 --发世界还是帮会红包
	m_conditionDesc = {}, -- 帮会红包发送条件描述
}

function RedPacketSend:Attach(obj)
    UIControl.Attach(self, obj)
	
	local controls = self.Controls
	self:AddListener(controls.m_closeBtn, "onClick", self.OnCloseClick, self)
	self:AddListener(controls.m_sendBtn, "onClick", self.OnSendClick, self)
	self:AddListener(controls.m_addMoneyBtn, "onClick", self.OnAddMoneyClick, self)
	self:AddListener(controls.m_addNumBtn, "onClick", self.OnAddNumClick, self)
	self:AddListener(controls.m_subMoneyBtn, "onClick", self.OnSubMoneyClick, self)
	self:AddListener(controls.m_subNumBtn, "onClick", self.OnSubNumClick, self)
	self:AddListener(controls.m_setting, "onClick", self.OnSetting, self)
	self:AddListener(controls.m_setclose, "onClick", self.OnSettingClose, self)
	
	self:AddListener(controls.m_diamondBtn, "onClick", self.OnSetDiamond, self)
	self:AddListener(controls.m_numBtn, "onClick", self.OnSetNum, self)
	self:AddListener(controls.m_closeBtnMask, "onClick", self.OnCloseClick, self)
	
	controls.Page = 
	{
		controls.send_world,
		controls.send_gang,
	}
	
	for i=1, 2 do
		controls.Page[i].onValueChanged:AddListener(function(isOn)
			self:OnPageChange(isOn, i)
		end)
	end
	
	controls.Set_Page = 
	{
		controls.m_page1,
		controls.m_page2,
		controls.m_page3,
	}
	
	for i=1, 3 do
		controls.Set_Page[i].onValueChanged:AddListener(function(isOn)
			self:OnSetChange(isOn, i)
		end)
	end
	
	controls.m_inputMsg = controls.m_input:GetComponent(typeof(InputField))
	
	self.callback_Close = function () self:Hide() end
	rktEventEngine.SubscribeExecute(MSG_MODULEID_REDENVELOP, SOURCE_TYPE_SYSTEM, EVENT_RED_PACKET_SENDSUCCEED, self.callback_Close)
	
	-- 获取帮会红包发送条件的描述
	local clanPersonCfg = IGame.rktScheme:GetSchemeInfo(REDENVELOP_CSV, emRED_ENVELOP_TYPE_PERSON_CLAN)
	if clanPersonCfg then
		local nSplitIndex = 1
		for k, v in pairs(clanPersonCfg.szCondition) do
			local nFindStartIndex = 3
			local nFindLastIndex = string.find(v, "|", nFindStartIndex)
			if nFindLastIndex then
				self.m_conditionDesc[nSplitIndex] = string.sub(v, nFindStartIndex, nFindLastIndex - 1)
			else
				self.m_conditionDesc[nSplitIndex] = ""
			end
			nSplitIndex = nSplitIndex + 1
		end
	end
	
	controls.m_txtSetting1.text = self.m_conditionDesc[1] or ""
	controls.m_txtSetting2.text = self.m_conditionDesc[2] or ""
	controls.m_txtSetting3.text = self.m_conditionDesc[3] or ""
end

function RedPacketSend:OpenSendPanel(page)
	local controls = self.Controls
	self.currentPage = page
	
	for i=1, 2 do
		if self.currentPage == i then
			controls.Page[i].isOn = true
		else
			controls.Page[i].isOn = false
		end
	end
	
	self:RefreshUI()
	self:Show()
end

function RedPacketSend:RefreshUI()
	local controls = self.Controls
	if self.currentPage == 1 then
		self.pSchemeInfo = IGame.rktScheme:GetSchemeInfo(REDENVELOP_CSV, 4) 
		controls.m_setting.gameObject:SetActive(false)
		controls.m_txtCondition.gameObject:SetActive(false)
		controls.m_txtShijie.color = UIFunction.ConverRichColorToColor("16808e")
		controls.m_txtBanghui.color = UIFunction.ConverRichColorToColor("597993")
	else
		self.pSchemeInfo = IGame.rktScheme:GetSchemeInfo(REDENVELOP_CSV, 3)
		controls.m_setting.gameObject:SetActive(true)
		
		local value = PlayerPrefsEx.GetInt("red_packet_setting")
		if not value or value <= 0 then
			value = 1
		end
		
		controls.m_txtCondition.text = "发放对象: " .. self.m_conditionDesc[value]
		
		controls.m_txtCondition.gameObject:SetActive(true)
		controls.m_txtShijie.color = UIFunction.ConverRichColorToColor("597993")
		controls.m_txtBanghui.color = UIFunction.ConverRichColorToColor("16808e")
	end
	
	self:SetMoney(self.pSchemeInfo.nDefaultDiamond)
	self:SetNum(self.pSchemeInfo.nDefaultNum)
	
	controls.m_inputMsg.text = self.pSchemeInfo.szBlessWords
end

--标签页
function RedPacketSend:OnPageChange(isOn, page)
	if isOn then
		if self.currentPage ~= page then
			self.currentPage = page
			self:RefreshUI()
		end
	end
end

function RedPacketSend:OnAddMoneyClick()
	if self.m_diamondTotal >= self.pSchemeInfo.nMaxDiamond then
		--IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "超过最大钻石发送数")
		return 
	end
	
	self.m_diamondTotal = self.m_diamondTotal + 1
	self:SetMoney(self.m_diamondTotal)
end

function RedPacketSend:OnAddNumClick()
	if self.m_packetNum >= self.pSchemeInfo.nMaxNum then
		--IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "超过最大红包发送数量")
		return 
	end
	
	self.m_packetNum = self.m_packetNum + 1
	self:SetNum(self.m_packetNum)
end

function RedPacketSend:OnSubMoneyClick()
	if self.m_diamondTotal <= self.pSchemeInfo.nMinDiamond then
		--IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "少于最少钻石发送数")
		return 
	end
	
	self.m_diamondTotal = self.m_diamondTotal - 1
	self:SetMoney(self.m_diamondTotal)
end

function RedPacketSend:OnSubNumClick()
	if self.m_packetNum <= self.pSchemeInfo.nMinNum then
		--IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "少于最少红包发送数量")
		return 
	end
	
	self.m_packetNum = self.m_packetNum - 1
	self:SetNum(self.m_packetNum)
end

--发送红包
function RedPacketSend:OnSendClick()
	local tips = self.Controls.m_inputMsg.text
	if "" == tips then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请先输入红包留言")
		return
	end
	
	self.Controls.m_setPanel.gameObject:SetActive(false)
		
	local pHero = GetHero()
	if not pHero then
		return
	end
	
	local nLevel = pHero:GetNumProp(CREATURE_PROP_LEVEL)
	local diamondTotal = self.m_diamondTotal
	
	if GameHelp:DiamondNotEnoughSwitchRecharge(diamondTotal) then
		return
	end
	
	local callBack = nil
	
	if self.currentPage == 1 then
		if nLevel < self.pSchemeInfo.nSendLevel then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, 
				"等级达到"..self.pSchemeInfo.nSendLevel.."级才可发送世界红包")
			return 
		end
		
		callBack = function ()
			IGame.RedEnvelopClient:OnRequestSendWorldRedenvelop(diamondTotal,
				self.m_packetNum, tips)
		end
	else
		if nLevel < self.pSchemeInfo.nSendLevel then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, 
				"等级达到"..self.pSchemeInfo.nSendLevel.."级才可发送帮会红包")
			return 
		end
		
		
		local value = PlayerPrefsEx.GetInt("red_packet_setting")
		if not value or value == 0 then
			value = 1
		end
	
		callBack = function ()
			IGame.RedEnvelopClient:OnRequestSendClanRedenvelop(diamondTotal,
				self.m_packetNum, tips, value)
		end
	end
	
	local data = 
	{
		content = string.format("是否花费<color=#008000>%d</color>钻石发送红包？", diamondTotal),
		confirmBtnTxt = "确定",
		cancelBtnTxt = "取消",
		confirmCallBack = callBack,
	}	
	
	UIManager.ConfirmPopWindow:ShowDiglog(data)
end

function RedPacketSend:OnSetting()
	local controls = self.Controls
	self.Controls.m_setPanel.gameObject:SetActive(true)
	
	local value = PlayerPrefsEx.GetInt("red_packet_setting")
	if not value or value == 0 then
		value = 1
	end
	
	for i=1, 3 do
		if value == i then
			controls.Set_Page[i].isOn = true
		else
			controls.Set_Page[i].isOn = false
		end
	end
end

function RedPacketSend:OnSettingClose()
	self.Controls.m_setPanel.gameObject:SetActive(false)
end

function RedPacketSend:OnSetChange(isOn, index)
	local controls = self.Controls
	if isOn then
		PlayerPrefsEx.SetInt("red_packet_setting", index)
		controls.m_txtCondition.text = "发放对象: " .. self.m_conditionDesc[index]
	end
end

function RedPacketSend:OnCloseClick()
	self:Hide(false)
end

--按钮灰度设置
function RedPacketSend:UpdateButtonGrayShow(image, showFlag)
	UIFunction.SetImageGray(image, showFlag)
	image.raycastTarget = not showFlag
end

function RedPacketSend:OnDestroy()
	local controls = self.Controls
	rktEventEngine.UnSubscribeExecute(MSG_MODULEID_REDENVELOP, SOURCE_TYPE_SYSTEM, EVENT_RED_PACKET_SENDSUCCEED, self.callback_Close)
	for i=1, 3 do
		controls.Set_Page[i].onValueChanged:RemoveAllListeners()
	end
	self:RemoveListener(controls.m_closeBtn, "onClick", self.OnCloseClick, self)
	self:RemoveListener(controls.m_sendBtn, "onClick", self.OnSendClick, self)
	self:RemoveListener(controls.m_addMoneyBtn, "onClick", self.OnAddMoneyClick, self)
	self:RemoveListener(controls.m_addNumBtn, "onClick", self.OnAddNumClick, self)
	self:RemoveListener(controls.m_subMoneyBtn, "onClick", self.OnSubMoneyClick, self)
	self:RemoveListener(controls.m_subNumBtn, "onClick", self.OnSubNumClick, self)
	self:RemoveListener(controls.m_setting, "onClick", self.OnSetting, self)
	self:RemoveListener(controls.m_setclose, "onClick", self.OnSettingClose, self)
	
	self:RemoveListener(controls.m_diamondBtn, "onClick", self.OnSetDiamond, self)
	self:RemoveListener(controls.m_numBtn, "onClick", self.OnSetNum, self)
	self:RemoveListener(controls.m_closeBtnMask, "onClick", self.OnCloseClick, self)
	
	UIControl.OnDestroy(self)
end

-- 钻石文本点击事件
function RedPacketSend:OnSetDiamond()
	
	local onUpdateChange = function(num) 
	self:SetMoney(num)
	end
	
	local numTable = {
	    ["inputNum"] = self.pSchemeInfo.nMinDiamond,
		["minNum"] = self.pSchemeInfo.nMinDiamond,
		["maxNum"] =  self.pSchemeInfo.nMaxDiamond,
		["bLimitExchange"] = 0
	}
	
	local otherInfoTable = {
		["inputTransform"] = self.Controls.m_diamondBtn.transform,
	    ["bDefaultPos"] = 1,
	    ["callback_UpdateNum"] = onUpdateChange
	}
	
	UIManager.NumericKeypadWindow:ShowWindow(numTable, otherInfoTable)
end

-- 红包数量文本点击事件
function RedPacketSend:OnSetNum()
	
	local onUpdateChange = function(num) 
	self:SetNum(num)
	end
	
	local numTable = {
	    ["inputNum"] = self.pSchemeInfo.nMinNum,
		["minNum"] = self.pSchemeInfo.nMinNum,
		["maxNum"] =  self.pSchemeInfo.nMaxNum,
		["bLimitExchange"] = 0
	}
	
	local otherInfoTable = {
		["inputTransform"] = self.Controls.m_numBtn.transform,
	    ["bDefaultPos"] = 1,
	    ["callback_UpdateNum"] = onUpdateChange
	}
	
	UIManager.NumericKeypadWindow:ShowWindow(numTable, otherInfoTable)
end

-- 设置金钱
function RedPacketSend:SetMoney(diamond)
	local controls = self.Controls
	self.m_diamondTotal = diamond
	controls.m_moneyLabel.text = tostringEx(diamond * self.pSchemeInfo.nRate)
	controls.m_costLabel.text = tostring(diamond)
	
	UIFunction.SetImageGray(controls.m_imgSubDiamond, diamond <= self.pSchemeInfo.nMinDiamond)
	UIFunction.SetImageGray(controls.m_imgAddDiamond, diamond >= self.pSchemeInfo.nMaxDiamond)
end

-- 设置红包数量
function RedPacketSend:SetNum(num)
	local controls = self.Controls
	self.m_packetNum = num
	controls.m_numLabel.text = tostringEx(num)

	UIFunction.SetImageGray(controls.m_imgSubNum, num <= self.pSchemeInfo.nMinNum)
	UIFunction.SetImageGray(controls.m_imgAddNum, num >= self.pSchemeInfo.nMaxNum)
end


return RedPacketSend