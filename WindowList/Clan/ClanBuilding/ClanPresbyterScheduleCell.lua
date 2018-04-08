-- 单个帮会活动目标cell元素
-- @Author: LiaoJunXi
-- @Date:   2017-09-21 12:16:21
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-29 12:08:26

local ClanPresbyterScheduleCell = UIControl:new
{
	windowName         = "ClanPresbyterScheduleCell",

	m_OnToggleChgCallback = nil,
	m_SelectedCallback = nil,
	
	m_SelCellIdx  	   = 0,
}

local this = ClanPresbyterScheduleCell

-------------------------------------------------------------
function ClanPresbyterScheduleCell:Attach( obj )
	UIControl.Attach(self, obj)

	self.m_OnToggleChgCallback = function(on) self:OnSelectChanged(on) end
    local toggle = self.transform:GetComponent(typeof(Toggle))
	toggle.onValueChanged:AddListener(self.m_OnToggleChgCallback)
	
	self.Controls.toggle = toggle
end


function ClanPresbyterScheduleCell:SetCellData(idx, data)
	local controls = self.Controls
	
	if data then
		controls.m_Name.text = data.m_Name
	end
	
	self.m_SelCellIdx = idx
end

-- 设置选中回调
function ClanPresbyterScheduleCell:SetSelectCallback( func_cb )
	self.m_SelectedCallback = func_cb
end

-- 设置toggle group
function ClanPresbyterScheduleCell:SetToggleGroup(toggleGroup)
    self.Controls.toggle.group = toggleGroup
end

-- 设置toggle group
function ClanPresbyterScheduleCell:SetToggleIsOn(on)
	local tgl = self.Controls.toggle
	if tgl ~= nil then
    	tgl.isOn = on
    end
end

function ClanPresbyterScheduleCell:IsToggleOn()
	local tgl = self.Controls.toggle
	if tgl then
    	return tgl.isOn
    end
	return false
end

function ClanPresbyterScheduleCell:OnSelectChanged(on)
	if nil ~= self.m_SelectedCallback and on then
		self.m_SelectedCallback(self.m_SelCellIdx)
	end
end

function ClanPresbyterScheduleCell:OnRecycle()
	self.Controls.toggle.onValueChanged:RemoveListener(self.m_OnToggleChgCallback)
	self.m_SelectedCallback = nil

	UIControl.OnRecycle(self)
	table_release(self)
end

function ClanPresbyterScheduleCell:OnDestroy()
	self.m_OnToggleChgCallback = nil
	self.m_SelectedCallback = nil
	
	UIControl.OnDestroy(self)
	table_release(self)
end

return ClanPresbyterScheduleCell