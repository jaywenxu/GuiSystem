------------------------------------------------------------
-- ChatWindow 的子窗口,不要通过 UIManager 访问
-- 频道切换Toggle窗口
------------------------------------------------------------

local ChannelToggleContainer = UIControl:new
{
	windowName = "ChannelToggleContainer",
	-- 频道选项卡列表
	ToggleList = {},
}

local this = ChannelToggleContainer   -- 方便书写

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function ChannelToggleContainer:Attach( obj )
	UIControl.Attach(self,obj)
	
	-- 注册频道选项卡事件
	for i = 1, 6 do
		self.ToggleList[i] = UIControl:new({windowName = "ToggleList"})
		self.ToggleList[i]:Attach(self.Controls["m_ChannelToggle"..i].gameObject)
		self.Controls["m_ChannelToggle"..i].onValueChanged:AddListener(function(on) self:OnToggleClick(on, i) end)
	end
	
	return self
end

------------------------------------------------------------
function ChannelToggleContainer:OnDestroy()
	UIControl.OnDestroy(self)
end

------------------------------------------------------------
-- 点击频道选项卡
function ChannelToggleContainer:OnToggleClick(on, index)

	if on then
		self.Controls["m_ChannelToggle"..index].transform:Find("Background/Checkmark").gameObject:SetActive(true)
	else
		self.Controls["m_ChannelToggle"..index].transform:Find("Background/Checkmark").gameObject:SetActive(false)
	end
	
	if not on then
		return
	end
	if index == 6 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "暂未开发")
	end
	UIManager.ChatWindow:OnToggleChanged(on, index)
end

------------------------------------------------------------
-- 小红点显示或隐藏
function ChannelToggleContainer:RedDotShowOrHide(index,State)
	if self.ToggleList[index] == nil then
		return
	end
	if State then
		self.ToggleList[index].Controls.RedDot.gameObject:SetActive(true)
	else
		self.ToggleList[index].Controls.RedDot.gameObject:SetActive(false)
	end
end


return this