local CentextWidget = UIControl:new
{
	windowName = "CentextWidget",
	contentInfo = nil,
	m_index =0,

}

function CentextWidget:Attach(obj)
	UIControl.Attach(self,obj)
	
	
end


function CentextWidget:PrintWordByIndexTime()
	self.m_index = self.m_index+1
	local contentStr = string.sub(self.m_cellInfo.contents,1,self.m_index ) or self.m_cellInfo.contents
	self.Controls.content.text = contentStr
	
end

function CentextWidget:RefreshUI(cellInfo)
	self.m_cellInfo = cellInfo
	self.Controls.content.text=""
	if cellInfo.contentMode == 0 then 
		self.Controls.content.text = cellInfo.contents
	else
		local length = string.len(cellInfo.contents) 
		rktTimer.SetTimer(function() self:PrintWordByIndexTime() end,cellInfo.indexTime,length,"PrintWordByIndexTime")
	end
end

return CentextWidget