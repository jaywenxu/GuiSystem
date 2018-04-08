--*****************************************************************
--** 文件名:	SublineItem.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-12-11
--** 版  本:	1.0
--** 描  述:	分线选项
--** 应  用:  
--******************************************************************
local SublineItem = UIControl:new
{
	windowName	= "SublineItem",
	m_nCurMapID = 0,
}

function SublineItem:Attach(obj)
	UIControl.Attach(self, obj)
	
	self.m_SelectCB = function(on) self:OnToggleChange(on) end
	self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))
    self.Controls.ItemToggle.onValueChanged:AddListener(self.m_SelectCB)
end

function SublineItem:SetToggleGroup(tTlgGroup)
	self.Controls.ItemToggle.group = tTlgGroup
end

function SublineItem:SetSelectCB(tFunc_cb)
	self.m_SelectCallback = tFunc_cb
end

function SublineItem:SetItemInfo(nItemIdx, nMapID)
	
	self.Controls.m_SublineName.text = "分线"..nItemIdx
	self.m_nCurMapID = nMapID
end

function SublineItem:SetFocus(bFocus)
	if nil == bFocus then
		return
	end
	
	self.Controls.ItemToggle.isOn = bFocus
end

function SublineItem:OnToggleChange(on)
	if not on then
		return
	end
	
	if self.m_SelectCallback then
		self.m_SelectCallback(self.m_nCurMapID)
	end
end

function SublineItem:OnRecycle()
	self.Controls.ItemToggle.onValueChanged:RemoveListener(self.m_SelectCB)
	UIControl.OnRecycle(self)
end

return SublineItem