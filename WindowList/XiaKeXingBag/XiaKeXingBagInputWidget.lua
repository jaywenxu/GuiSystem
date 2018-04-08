------------------------------------------------------------
-- TooltisWindow 的子窗口,不要通过 UIManager 访问
------------------------------------------------------------

local XiaKeXingBagInputWidget = UIControl:new
{
    windowName = "XiaKeXingBagInputWidget" ,
}

local this = XiaKeXingBagInputWidget   -- 方便书写
local zero = int64.new("0")

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function XiaKeXingBagInputWidget:Attach(obj)
	UIControl.Attach(self, obj)
	
	-- 监听关闭按钮
	self.Controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	
	-- 监听关闭按钮
	self.Controls.m_CancelBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	
	-- 监听发送按钮
	self.Controls.m_ConfirmBtn.onClick:AddListener(handler(self, self.OnConfirmBtnClicked))
	
	-- 输入内容变化
	self.callbackOnInputFieldValueChanged = function() self:OnInputFieldValueChanged() end
	self.Controls.m_InputField:GetComponent(typeof(InputField)).onValueChanged:AddListener(self.callbackOnInputFieldValueChanged)
	
	self.Controls.m_WordCountTips.text = "还可编辑"..XIAKEXING_BAG_MSG_MAXLEN.."个字"
	
	return self
end

function XiaKeXingBagInputWidget:OnBtnCloseClicked()
	self:Hide()
end

function XiaKeXingBagInputWidget:OnConfirmBtnClicked()
 	local InputField = self.Controls.m_InputField:GetComponent(typeof(InputField))
	local text = InputField.text
    if text == "" then
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "输入你想说的话，才能点击确认按钮")
        return
    end
	UIManager.XiaKeXingBagWindow:SetToggleText(text)
    self:Hide()
end

function XiaKeXingBagInputWidget:OnInputFieldValueChanged()
 	local length  = utf8.len(self.Controls.m_InputField:GetComponent(typeof(InputField)).text)
	local lastLength = XIAKEXING_BAG_MSG_MAXLEN - length
	self.Controls.m_WordCountTips.text = "还可编辑"..tostring(lastLength).."个字"
end

return this