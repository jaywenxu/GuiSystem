-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017/02/15
-- 版  本:    1.0
-- 描  述:    滴答Cell
-------------------------------------------------------------------


--聊天富文本协议--------------------------------------------------------
--FF0000 为颜色的rgb值比如ffffff------------
--[herf] 为关键字--------
--倚天屠龙刀为你要显示的内容若要显示为[倚天屠龙刀]则写[倚天屠龙刀]
--test为方法，string为参数当点击倚天屠龙刀时

--为此类型 <herf><color=#FF0000>倚天屠龙刀</color><fun>test(string)</fun></herf>


local MainChatItemCell = UIControl:new
{
    windowName = "MainChatItemCell" ,
	ChatSeq = nil,
	m_PlayerDBID = 0,
	FunText = {}
}

----------------------------------

--[[FunPosItem = {
	startPos = 0,
	endPos =0,
	fun = "",
}--]]
-------------------------------

local mName = "【主窗口聊天Cell】，"

local FunText = {}

------------------------------------------------------------
function MainChatItemCell:Attach( obj )
	UIControl.Attach(self,obj)
    self.Controls.MsgText = self.transform:GetComponent(typeof(Text))
    self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))
	self.Controls.RichText = self.transform:GetComponent(typeof(rkt.RichText))
	self.callback_RichTextClick = function(text,beginIndex,endIndex) self:OnBtnChatTextOnClick(text,beginIndex,endIndex,self.FunText) end
	
	self.Controls.RichText.onClick:AddListener(self.callback_RichTextClick)
	return self
end


------------------------------------------------------------
--点击聊天表情
function MainChatItemCell:OnBtnChatTextOnClick(text,beginIndex,endIndex,FunText)
	if RichTextHelp.OnClickAsysSerText(beginIndex,endIndex,FunText) == false then
		UIManager.ChatWindow:ShowOrHide()
	end
end

------------------------------------------------------------
--设置内容
function MainChatItemCell:SetContentText(text)
	self.Controls.MsgText.text = tostring(text)
end

------------------------------------------------------------
--设置内容
function MainChatItemCell:SetFunText(FunText)
	self.FunText = FunText
end

------------------------------------------------------------
--设置内容颜色
function MainChatItemCell:SetFunTextColor(color)
	self.FunText.color = color
end

------------------------------------------------------------
--设置内容
function MainChatItemCell:SetPlayerDBID(PlayerDBID)
	self.m_PlayerDBID = PlayerDBID
end

------------------------------------------------------------
function MainChatItemCell:OnDestroy()
	self.Controls.RichText.onClick:RemoveListener(self.callback_RichTextClick)
	UIControl.OnDestroy(self)
end

function MainChatItemCell:OnRecycle()
	self.Controls.RichText.onClick:RemoveListener(self.callback_RichTextClick)
end

return MainChatItemCell




