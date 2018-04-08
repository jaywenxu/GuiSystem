--------------------------------------------------------------------

local ChipItemGroupCell = UIControl:new
{
	windowName 	= "ChipItemGroupCell",
}

local this = ChipItemGroupCell

function ChipItemGroupCell:Init()

end

function ChipItemGroupCell:Attach(obj)
	UIControl.Attach(self,obj)	

	return self
end

-- 回收
function ChipItemGroupCell:OnRecycle()
	
	local tCelltrans = self.transform	
	local nChildCnt  = tCelltrans.childCount

	for i = 1, nChildCnt do
		local itemCell = tCelltrans:GetChild( i - 1 )	
		self:OnCellRecycle(itemCell)
	end
	UIControl.OnRecycle(self)
end

-- 子空间回收
function ChipItemGroupCell:OnCellRecycle(tCell)
	
	local item = self:GetCellItem(tCell, "ChipItemCell")
	if not item then
		return
	end
	item:OnRecycle()
end

-- 获取子空间
function ChipItemGroupCell:GetCellItem(tCell, szWdtName)
	if not tCell.gameObject then
		return
	end
	
	local behav = tCell:GetComponent(typeof(UIWindowBehaviour))
	if not behav then
		return
	end
	
	local item = behav.LuaObject
	if not item then
		return
	end
	if item.windowName ~= szWdtName then
		return
	end	
	return item
end

return this