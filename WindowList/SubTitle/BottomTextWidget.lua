local BottomTextWidget = UIControl:new
{
	windowName = "BottomTextWidget",
	m_index=0
}

function BottomTextWidget:Attach(obj)
	UIControl.Attach(self,obj)
	
	
end


function BottomTextWidget:PrintWordByIndexTime()
	self.m_index = self.m_index+1
	local contentStr = string.sub(self.m_cellInfo.contents,1,self.m_index ) or self.m_cellInfo.contents
	self.Controls.content.text = contentStr
	
end


function BottomTextWidget:RefreshUI(cellInfo)
	self.m_cellInfo = cellInfo
	self.Controls.content.text=""
	if cellInfo.contentMode == 0 then 
		self.Controls.content.text = cellInfo.contents
	else
		local length = string.len(cellInfo.contents) 
		rktTimer.SetTimer(function() self:PrintWordByIndexTime() end,cellInfo.indexTime,length,"PrintWordByIndexTime")
	end
end

return BottomTextWidget