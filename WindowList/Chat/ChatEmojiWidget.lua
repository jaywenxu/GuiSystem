------------------------------------------------------------
-- ChatWindow 的子窗口,不要通过 UIManager 访问
-- 聊天表情界面
------------------------------------------------------------

local ChatEmojiWidget = UIControl:new
{
	windowName = "ChatEmojiWidget",
	-- 所有表情
	FaceList = {},
}
local this = ChatEmojiWidget   -- 方便书写
------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function ChatEmojiWidget:Attach( obj )
	UIControl.Attach(self,obj)
	local cout = self.transform.childCount
	-- 注册表情点击事件
	for i = 1, cout do
		local faceItem = self.transform:GetChild(i-1)
		local faceBtn = faceItem:GetComponent(typeof(Button))
		faceBtn.onClick:AddListener(function(faceItem) self:FaceButtonClick(faceItem) end)
	end
	
	return self
end

------------------------------------------------------------
--点击表情的事件
function ChatEmojiWidget:FaceButtonClick( obj )
	
end

return this