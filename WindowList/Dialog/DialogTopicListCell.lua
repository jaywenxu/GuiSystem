------------------------------------------------------------
-- DialogScenarioWindow 的子窗口,不要通过 UIManager 访问
-- 剧情对话
------------------------------------------------------------

------------------------------------------------------------
local DialogTopicListCell = UIControl:new
{
	windowName = "DialogTopicListCell" ,
	m_itemInfo = nil,
	m_npc = nil,
	m_npc_id = nil,
}

local this = DialogTopicListCell   -- 方便书写


------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function DialogTopicListCell:Attach( obj )
	UIControl.Attach(self,obj)

	self.callbackButtonClick = function() self:OnButtonClick() end 
	self.Controls.ClickButton.onClick:AddListener( self.callbackButtonClick )
    return self
end
-----------------------------------------------------------

------------------------------------------------------------
function DialogTopicListCell:OnRecycle()
	self.Controls.ClickButton.onClick:RemoveListener( self.callbackButtonClick )
end

-- 响应按钮点击
function DialogTopicListCell:OnButtonClick()
	if not self.m_itemInfo then
		return
	end
	if not self.m_itemInfo[2] then
		return
	end
	-- 函数名
	local szFunc = self.m_itemInfo[2]
	-- 参数列表
	local paramList = ""
	if  self.m_itemInfo[3] and type(self.m_itemInfo[3]) == 'table' then
		local n = table.getn(self.m_itemInfo[3])
		for i = 1, n  do
			if paramList ~= "" then
				paramList = paramList..","
			end
			paramList = paramList .. tostring(self.m_itemInfo[3][i])
		end
	end
	
	-- 拼接函数
	szFunc = szFunc .. "(" .. paramList..")"
	GameHelp.PostServerRequest(szFunc)
	UIManager.DialogScenarioWindow:HideDialogScenario()
end

------------------------------------------------------------
function DialogTopicListCell:ClearInfo()
	self.m_itemInfo = nil
end

------------------------------------------------------------
function DialogTopicListCell:SetItemInfo(iteminfo)
	if not iteminfo or type(iteminfo) ~= 'table' then
		return
	end
	self.m_itemInfo = iteminfo
	if self.m_itemInfo[4] and self.m_itemInfo[4] == 1 then
        self.Controls.WenHao.gameObject:SetActive(true)
    else
        self.Controls.WenHao.gameObject:SetActive(false)
    end
	self.Controls.TopicText.text = self.m_itemInfo[1]
	
end
------------------------------------------------------------

function DialogTopicListCell:SetNpcInfo(npc,npc_id)
	self.m_npc = npc
	self.m_npc_id = npc_id
end

return this