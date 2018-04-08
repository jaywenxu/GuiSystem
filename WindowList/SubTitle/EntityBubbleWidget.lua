local EntityBubbleWidget = UIControl:new
{
	windowName = "AsideClassWidget",
	m_index = 0,
}

function EntityBubbleWidget:Attach(obj)
	UIControl.Attach(self,obj)
	
	
end

function EntityBubbleWidget:PrintWordByIndexTime()
	self.m_index = self.m_index+1
	
	local contentStr = string.sub(self.m_cellInfo.contents,1,self.m_index ) or self.m_cellInfo.contents
	self.Controls.content.text = contentStr
	
end

function EntityBubbleWidget:RefreshUI(cellInfo)
	self.m_cellInfo = cellInfo
	self.Controls.content.text=""
	if cellInfo.contentMode == 0 then 
		self.Controls.content.text = cellInfo.contents
	else
		local length = string.len(cellInfo.contents) 
		rktTimer.SetTimer(function() self:PrintWordByIndexTime() end,cellInfo.indexTime,length,"PrintWordByIndexTime")
	end
	
	if nil ~= AttachTrs then 
		local worldPosToScreen = UIWorldPositionToScreen.Get(self.transform.gameObject)
		worldPosToScreen.UICamera = UIManager.FindUICamera()
		worldPosToScreen.SceneCamera = CoreUtility.FindCameraForLayer(LayerMask.NameToLayer("Opera"))
		worldPosToScreen.WorldTransform = AttachTrs
	if nil ~= AttachOffset then 
		worldPosToScreen.WorldOffset = AttachOffset
	end
		
	end

	
end

return EntityBubbleWidget