
--------------------------发色配置Item--------------------------
local HairColorItem = UIControl:new
{ 
    windowName = "HairColorItem",
	
	m_Custom = false,
	m_Index  = 0,
	m_ColorNum = 0,
	m_AppID = 0,
	m_selected_calback = nil,
}

function HairColorItem:Attach(obj)
	UIControl.Attach(self,obj)
	
	--Toggle点击事件注册
	self.callback_Toggle = function(on) self:OnToggleChange(on) end
	self.Controls.m_Toggle.onValueChanged:AddListener(self.callback_Toggle)
end

--初始化item状态
function HairColorItem:InitState(nIndex, nLock, nColor, nCustom,nFunc_cb)
	self:SetIndex(nIndex)
	self:SetLock(nLock)
	self:SetColor(nColor)
	self:SetCustom(nCustom)
	self:SetSelectCallback(nFunc_cb)
end

function HairColorItem:SetAppID(nID)
	self.m_AppID = nID
end

function HairColorItem:SetIndex(nIndex)
	self.m_Index = nIndex
end

--设置锁定状态
function HairColorItem:SetLock(nLock)
	self.Controls.m_Lock.gameObject:SetActive(nLock)
end

--是否自制
function HairColorItem:SetCustom(nCustom)
	self.m_Custom = nCustom
	self.Controls.m_Custom.gameObject:SetActive(nCustom)
end

--设置Icon
function HairColorItem:SetIcon(path)
	UIFunction.SetImageSprite(self.Controls.m_ColorImg,AssetPath.TextureGUIPath..path)
end

--设置颜色
function HairColorItem:SetColor(nColor)
	self.Controls.m_ColorImg.color = nColor
end

--设置十进制颜色,  可只保存十进制色值，用的时候再转化
function HairColorItem:SetColorNum(nColorNum)
	self.m_ColorNum = nColorNum
end

--获取十进制颜色值 
function HairColorItem:GetColorNum()
	return self.m_ColorNum
end

--获取颜色
function HairColorItem:GetColor()
	return self.Controls.m_ColorImg.color
end

--设置ToggleGroup
function HairColorItem:SetToggleGroup(toggleGroup)
	self.Controls.m_Toggle.group = toggleGroup
end

--
function HairColorItem:SetSelectCallback(func_cb)
	self.m_selected_calback = func_cb
end

--Toggle改变回调				根据需求写，暂时不处理
function HairColorItem:OnToggleChange(on)
	if not on then
		self.Controls.m_Select.gameObject:SetActive(false)
	else
		self.Controls.m_Select.gameObject:SetActive(true)
		
		if nil ~= self.m_selected_calback then
			self.m_selected_calback(self.m_Index,self.m_ColorNum,self.Controls.m_ColorImg.color)
		end
	end
end

--选中
function HairColorItem:SetFocus(nFocus)
	 self.Controls.m_Toggle.isOn = nFocus
end

function HairColorItem:Destory()
	UIControl.Destroy(self)
end

return HairColorItem