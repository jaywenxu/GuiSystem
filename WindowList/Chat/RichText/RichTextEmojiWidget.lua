------------------------------------------------------------
-- ChatWindow 的子窗口,不要通过 UIManager 访问
-- 频道切换Toggle窗口
------------------------------------------------------------

local RichTextEmojiWidget = UIControl:new
{
	windowName = "RichTextEmojiWidget",
	m_GoodsInfo = {},
}

local this = RichTextEmojiWidget   -- 方便书写

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function RichTextEmojiWidget:Attach( obj )
	UIControl.Attach(self,obj)
	return self
end

------------------------------------------------------------
function RichTextEmojiWidget:OnDestroy()
	UIControl.OnDestroy(self)
end

return this