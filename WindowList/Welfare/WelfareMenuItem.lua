
--******************************************************************
--** 文件名:	WelfareMenuItem.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-06-01
--** 版  本:	1.0
--** 描  述:	福利菜单单元
--** 应  用:  
--******************************************************************

require("GuiSystem.WindowList.Welfare.WelfareDef")

local WelfareMenuItem = UIControl:new
{
	windowName = "WelfareMenuItem",
	m_SelectedCallback = nil,
	m_toogle = nil,
	m_Index = 0,
	m_IconXuan = nil,
	m_IconMo = nil,
}

function WelfareMenuItem:Init()
	
end

function WelfareMenuItem:Attach(obj)
	UIControl.Attach(self, obj)
	
    self.m_toggle = self.transform:GetComponent(typeof(Toggle))
    self.m_toggle.onValueChanged:AddListener(handler(self, self.OnSelectChanged))
	
	self.Controls.m_MoImg.gameObject:SetActive(true)
	self.Controls.m_XuanImg.gameObject:SetActive(false)
    
    self.unityBehaviour.onDisable:AddListener(handler(self, self.OnDisable))

end

function WelfareMenuItem:SetItemInfo(idx, iconXuan, iconMo)
	local index = tonumber(idx)
	if not iconXuan or not iconMo then
		uerror("MenuTables value invalid! idx: " .. index)
		return
	end
	self.m_IconXuan = AssetPath.TextureGUIPath .. iconXuan
	self.m_IconMo = AssetPath.TextureGUIPath .. iconMo
	self.m_Index = index
	UIFunction.SetImageSprite(self.Controls.m_Icon, self.m_IconMo)
end

function WelfareMenuItem:SetToggleGroup(group)
	self.m_toggle.group = group
end

function WelfareMenuItem:SetFocus(bFocus)
	self.m_toggle.isOn = bFocus
end

function WelfareMenuItem:SetSelectedCallback(func_cb)
	self.m_SelectedCallback = func_cb
end

function WelfareMenuItem:OnSelectChanged(on)

	if on then
		self.Controls.m_XuanImg.gameObject:SetActive(true)
		self.Controls.m_MoImg.gameObject:SetActive(false)
		UIFunction.SetImageSprite(self.Controls.m_Icon, self.m_IconXuan)
	else
		self.Controls.m_XuanImg.gameObject:SetActive(false)
		self.Controls.m_MoImg.gameObject:SetActive(true)
		UIFunction.SetImageSprite(self.Controls.m_Icon, self.m_IconMo)
	end
	
	if nil ~= self.m_SelectedCallback then
		self.m_SelectedCallback(self.m_Index, on)
	end
end

function WelfareMenuItem:OnDisable()
    self:SetFocus(false)
end

return WelfareMenuItem