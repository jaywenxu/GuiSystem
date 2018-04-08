------------------------------灵兽界面灵兽item------------------------------------
local PetSuitTextItem = UIControl:new
{
	windowName = "PetSuitTextItem",
	
	m_UID = nil, 							--当前灵兽UID
	m_Index = -1, 							--当前是第几条tipItem
}
local this = PetSuitTextItem

function PetSuitTextItem:Attach(obj)
	UIControl.Attach(self,obj)
	
	return self
end

--设置索引
function PetSuitTextItem:SetData(uid, index)
	self.m_UID = uid
	self.m_Index = index
end

--设置灵兽UID
function PetSuitTextItem:SetUID(uid)
	self.m_UID = uid
end

--设置文字
function PetSuitTextItem:SetTipText(highLight)
	local record = IGame.rktScheme:GetSchemeInfo(PETSKILLSUIT_CSV, self.m_Index)
	local str = record.SkillDesc .. "\n"
	
	local type1 = record.Type1
	local type2 = record.Type2
	local type3 = record.Type3
	local type4 = record.Type4
	local type5 = record.Type5
	
	local typeList = {
		type1,
		type2,
		type3,
		type4,
		type5,
	}
	
	for i,data in pairs(typeList) do
		local value = record["Value"..tostring(i)]
		local propRecord = IGame.rktScheme:GetSchemeInfo(EQUIPATTACHPROPDESC_CSV, data)
		if propRecord then 
			local tmpStr = " " .. propRecord.strDesc
			if propRecord.nSign == 1 then			--加号
				tmpStr = tmpStr .. "+"
			elseif propRecord.nSign == 0 then 		--减号
				tmpStr = tmpStr .. "-"
			end
			tmpStr = tmpStr .. tostring(value)
			if propRecord.nPercent == 1 then
				tmpStr = tmpStr .. "%"
			end

			str = str .. tmpStr
		end
	end
	if highLight then 
		str = "<color=green>".. str .."</color>"
	end
	self.Controls.m_Text.text = str
end

--设置title
function PetSuitTextItem:SetTitle()
	
end

return this