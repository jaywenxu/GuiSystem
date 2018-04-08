--******************************************************************
--** 文件名:	AdventureTypeItem.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-11-2
--** 版  本:	1.0
--** 描  述:	奇遇类型
--** 应  用:  
--******************************************************************

local AdventureTypeItem = UIControl:new
{
	windowName	= "AdventureTypeItem",
	m_SelectCallback = nil,
}

function AdventureTypeItem:Attach(obj)
	
	UIControl.Attach(self, obj)
	
	self.m_toggle = self.transform:GetComponent(typeof(Toggle))
    self.m_toggle.onValueChanged:AddListener(handler(self, self.OnSelectChanged))
end

function AdventureTypeItem:OnSelectChanged(on)
	if self.m_SelectCallback then
		self.m_SelectCallback(on)
	end
end

function AdventureTypeItem:SetItemData()
	
end

function AdventureTypeItem:SetToggleGroup(TlgGroup)
	self.m_toggle.group = TlgGroup
end

function AdventureTypeItem:SetSelectCallback(tFunc)
	self.m_SelectCallback = tFunc
end

return AdventureTypeItem