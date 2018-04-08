-- @Author: LiaoJunXi
-- @Date:   2017-12-25 12:16:21
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-29 12:08:26

local RankCompeteOutcomeCell = UIControl:new
{
	windowName         = "RankCompeteOutcomeCell",
	m_OnToggleChgCallback = nil,
	m_SelectedCallback = nil,
	m_SelCellIdx  	   = 0,
}

-------------------------------------------------------------
function RankCompeteOutcomeCell:Attach( obj )
	UIControl.Attach(self, obj)
	
	self.m_OnToggleChgCallback = function(on) self:OnSelectChanged(on) end
    local toggle = self.transform:GetComponent(typeof(Toggle))
	toggle.onValueChanged:AddListener(self.m_OnToggleChgCallback)	
	self.Controls.toggle = toggle
end

function RankCompeteOutcomeCell:SetCellData(idx, data)
	local controls = self.Controls
	
	controls.m_Name.text = data.m_ActCfg.TargetName
	controls.m_KillNum.text = data.m_ActCfg.TargetDesc
	controls.m_ScroeValue.text = data.m_ActCfg.Score

	self.m_SelCellIdx = idx
	
	if nil ~= data.m_ActCfg.Icon and "" ~= data.m_ActCfg.Icon then
		UIFunction.SetHeadImage(controls.m_AvatarIcon, data.m_ActCfg.Icon)
	end
end

-- 设置选中回调
function RankCompeteOutcomeCell:SetSelectCallback( func_cb )
	self.m_SelectedCallback = func_cb
end

function RankCompeteOutcomeCell:OnSelectChanged(on)
	if nil ~= self.m_SelectedCallback and on then
		self.m_SelectedCallback(self.m_SelCellIdx)
	end
end

function RankCompeteOutcomeCell:OnRecycle()
	self.Controls.toggle.onValueChanged:RemoveListener(self.m_OnToggleChgCallback)
	self.m_OnToggleChgCallback = nil
	self.m_SelectedCallback = nil

	UIControl.OnRecycle(self)
	table_release(self)
end

function RankCompeteOutcomeCell:OnDestroy()
	self.Controls.toggle.onValueChanged:RemoveListener(self.m_OnToggleChgCallback)
	self.m_OnToggleChgCallback = nil
	self.m_SelectedCallback = nil
	
	UIControl.OnDestroy(self)
	table_release(self)
end

return RankCompeteOutcomeCell