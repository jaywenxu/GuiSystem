local AsideClassWidget = UIControl:new
{
	windowName = "AsideClassWidget",
	m_cellInfo = nil,
	m_index = 0
}

function AsideClassWidget:Attach(obj)
	UIControl.Attach(self,obj)
	
	
end



function AsideClassWidget:PrintWordByIndexTime()
	self.m_index = self.m_index+1
	local contentStr = string.sub(self.m_cellInfo.contents,1,self.m_index ) 

	self.Controls.content.text = contentStr
	
end

function AsideClassWidget:RefreshUI(cellInfo)
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
		worldPosToScreen.WorldTransform = AttachTrs
		worldPosToScreen.SceneCamera = CoreUtility.FindCameraForLayer(LayerMask.NameToLayer("Opera"))
		if nil ~= AttachOffset then 
			worldPosToScreen.WorldOffset = AttachOffset
		end
	
	end
end

return AsideClassWidget