-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立（Sheepy）
-- 日  期:    2017年9月15日
-- 版  本:    1.0
-- 描  述:    富文本文字表情Cell
-------------------------------------------------------------------

local RichTextFunnyWordCell = UIControl:new
{
    windowName = "RichTextFunnyWordCell" ,
	m_Index = 0,
}

------------------------------------------------------------
local mName = "【富文本物品Cell】，"

local FunText = {}
------------------------------------------------------------
function RichTextFunnyWordCell:Attach( obj )
	UIControl.Attach(self,obj)
	self.callback_OnClick = function() self:OnClick() end
	self.Controls.m_Btn =self.transform:GetComponent(typeof(Button))	
	self.Controls.m_Text = self.transform:Find("MainBg/Text"):GetComponent(typeof(Text))
	
	self.Controls.m_Btn.onClick:AddListener(self.callback_OnClick)
	
	return self
end

------------------------------------------------------------
function RichTextFunnyWordCell:OnClick()
	UIManager.RichTextWindow.RichTextFunnyWordWidget:SetFunnyWord(self.m_Index)
	UIManager.RichTextWindow:Hide()
end

------------------------------------------------------------
function RichTextFunnyWordCell:SetIndex(index)
	self.m_Index = index
	self.Controls.m_Text.text = Chat_Funny_Word[index].TitleName
end

return RichTextFunnyWordCell




