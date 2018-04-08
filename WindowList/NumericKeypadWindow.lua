-- 数字小键盘窗口
------------------------------------------------------------
local NumericKeypadWindow = UIWindow:new
{
	windowName = "NumericKeypadWindow",
	m_strTotalNum = "",
	m_MinNum     = 1,
	m_MaxNum     = 999,
	callback_UpdateNum = nil,
}
------------------------------------------------------------
function NumericKeypadWindow:Init()

end
------------------------------------------------------------
function NumericKeypadWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
     
    -- 数字按钮点击事件
	self.Controls.m_Num0.onClick:AddListener(function() self:OnBtnNumClick(0) end)
	self.Controls.m_Num1.onClick:AddListener(function() self:OnBtnNumClick(1) end)
	self.Controls.m_Num2.onClick:AddListener(function() self:OnBtnNumClick(2) end)
	self.Controls.m_Num3.onClick:AddListener(function() self:OnBtnNumClick(3) end)
	self.Controls.m_Num4.onClick:AddListener(function() self:OnBtnNumClick(4) end)
	self.Controls.m_Num5.onClick:AddListener(function() self:OnBtnNumClick(5) end)
	self.Controls.m_Num6.onClick:AddListener(function() self:OnBtnNumClick(6) end)
	self.Controls.m_Num7.onClick:AddListener(function() self:OnBtnNumClick(7) end)
	self.Controls.m_Num8.onClick:AddListener(function() self:OnBtnNumClick(8) end)
	self.Controls.m_Num9.onClick:AddListener(function() self:OnBtnNumClick(9) end) 
	
    UIFunction.AddEventTriggerListener(self.Controls.m_closeButton , EventTriggerType.PointerClick , function( eventData ) self:OnCloseButtonClick(eventData) end )
	
	-- 添加和删除按钮事件
	self.Controls.m_BtnAdd.onClick:AddListener(function() self:OnBtnAddNumClick() end)
	self.Controls.m_BtnDelete.onClick:AddListener(function() self:OnBtnDeleteNumClick() end) 

    if nil ~= self.m_cachedNumInfo then
        local info = self.m_cachedNumInfo
        self.m_cachedNumInfo = nil
        self:SetNum( info.numTable , info.otherInfoTable )
    end
end
------------------------------------------------------------
function NumericKeypadWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------

function NumericKeypadWindow:OnBtnNumClick(index)
	
	if self.m_strTotalNum == "" then
		self.m_strTotalNum = self.m_strTotalNum..tostring(index)
	elseif tonumber(self.m_strTotalNum) == 0 then
		self.m_strTotalNum = tostring(index)
	else
		self.m_strTotalNum = self.m_strTotalNum..tostring(index)
	end
	
	local nTotalNum = tonumber(self.m_strTotalNum)
	if nTotalNum > self.m_MaxNum then
		if self.m_MaxNum == 0 then 
			self.m_MaxNum = 1
		end 
		self.m_strTotalNum = tostring(self.m_MaxNum) 
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "输入数量已达最大值")		
	end
	
	local num = tonumber(self.m_strTotalNum)
	self:UpdateNum(num)	
end

function NumericKeypadWindow:OnBtnNum0Click() 
    -- 为空显示默认值
	if tonumber(self.m_strTotalNum) > 0 then 
		self.m_strTotalNum = self.m_strTotalNum.."0"
		local nTotalNum = tonumber(self.m_strTotalNum) 
		
		if nTotalNum > self.m_MaxNum then
			if self.m_MaxNum == 0 then 
				self.m_MaxNum = 1
			end
			self.m_strTotalNum = tostring(self.m_MaxNum)
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "输入数量已达最大值")	
		end
	end
 
	local num = tonumber(self.m_strTotalNum)
	self:UpdateNum(num) 
end 

function NumericKeypadWindow:OnBtnAddNumClick() 
	self:Hide()
	if tonumber(self.m_strTotalNum) < self.m_MinNum then 
		self:UpdateNum(tonumber(self.m_MinNum))
	end
	if tonumber(self.m_strTotalNum) > self.m_MaxNum then
		if self.m_MaxNum == 0 then 
			self.m_MaxNum = 1
		end
		self:UpdateNum(tonumber(self.m_MaxNum))
	end
end

function NumericKeypadWindow:OnBtnDeleteNumClick() 
    if self.m_strTotalNum ~= "" then
		-- 删除最后一个数字
		self.m_strTotalNum = string.sub(self.m_strTotalNum, 1, -2)
	end 
	
	if self.m_strTotalNum == "" then 
		self.m_strTotalNum = "0"
	end
	local num = tonumber(self.m_strTotalNum) 
	self:UpdateNum(num)
end

function NumericKeypadWindow:UpdateNum(num) 
	if self.callback_UpdateNum then
		self.callback_UpdateNum(num)	
	end
end


--[[
 numTable = {
    inputNum 输入框默认值 
    minNum 最小值
    maxNum 最大值 
    bLimitExchange 是否限购提示(0：不提示，1提示)
}
otherInfoTable = {
	inputTransform 输入框transform
	bDefaultPos  是否移动(0:默认位置， 1:移动位置)
	callback_UpdateNum 回调函数
}
]]
function  NumericKeypadWindow:ShowWindow(numTable, otherInfoTable)
	UIWindow.Show(self, true)
    self:SetNum(numTable, otherInfoTable)
end

function NumericKeypadWindow:SetNum(numTable, otherInfoTable)
	if not self:isLoaded() then
        self.m_cachedNumInfo = { numTable = numTable , otherInfoTable = otherInfoTable }
        return
    end

	self.m_strTotalNum = "0"
    self.m_MinNum = numTable.minNum
	self.m_MaxNum = numTable.maxNum
	
	self.callback_UpdateNum = otherInfoTable.callback_UpdateNum
	
	if otherInfoTable.bDefaultPos == 1 then 
 	    local vector2 = Vector2.New(-otherInfoTable.inputTransform.sizeDelta.x*0.5, otherInfoTable.inputTransform.sizeDelta.y*0.5)
	    UIFunction.ToolTipsShow(true,self.Controls.m_KeypadBg,otherInfoTable.inputTransform, vector2)
	else 
 	    local vector2 = Vector2.New(-otherInfoTable.inputTransform.sizeDelta.x*0.5, otherInfoTable.inputTransform.sizeDelta.y*0.5)
	    UIFunction.ToolTipsShow(true,self.Controls.m_KeypadBg,otherInfoTable.inputTransform, vector2)
	end 
	
end

function NumericKeypadWindow:OnCloseButtonClick(eventData)
	self:Hide()
	-- 小于最小值就更新为最小值
	if self.m_strTotalNum == "" then 
		self.m_strTotalNum = "0"
	end
	if tonumber(self.m_strTotalNum) < self.m_MinNum then 
		self:UpdateNum(tonumber(self.m_MinNum))
	end
	--rkt.UIAndTextHelpTools.PassThroughPointerClickEvent( eventData )
end

return NumericKeypadWindow