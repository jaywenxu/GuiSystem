--目标组队窗体中显示等级的Cell
------------------------------------------------------------
local LevelCell = UIControl:new
{
	windowName = "LevelCell" ,
	m_level = nil,
}
------------------------------------------------------------
function LevelCell:Attach( obj )
	UIControl.Attach(self,obj)
	
	local m_EnhancedListViewCell = obj.transform:GetComponent(typeof(EnhancedListViewCell))
	
	return self
end


function LevelCell:SetLevel(level)
	
	if self.transform~= nil then 
		local levelText = self.transform:Find("Text"):GetComponent(typeof(Text))
		self.m_level =level
		levelText.text = tostring(level)			--设置项的名称
	end

end
-------------------------------------------------------------
function LevelCell:OnDestroy()
	UIControl.OnDestroy(self)
end
------------------------------------------------------------
--刷新Cell
function LevelCell.OnRefreshCellView(objCell)
	
end
------------------------------------------------------------
return LevelCell