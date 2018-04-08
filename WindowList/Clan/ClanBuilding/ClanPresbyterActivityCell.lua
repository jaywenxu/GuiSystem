-- 单个帮会活动ceil元素
-- @Author: LiaoJunXi
-- @Date:   2017-09-07 12:16:21
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-29 12:08:26

local ClanPresbyterActivityCell = UIControl:new
{
	windowName         = "ClanPresbyterActivityCell",

	m_OnToggleChgCallback = nil,
	m_SelectedCallback = nil,
	
	m_SelCellIdx  	   = 0,
}

local this = ClanPresbyterActivityCell

-------------------------------------------------------------
function ClanPresbyterActivityCell:Attach( obj )
	UIControl.Attach(self, obj)

	self.m_OnToggleChgCallback = function(on) self:OnSelectChanged(on) end
    local toggle = self.transform:GetComponent(typeof(Toggle))
	toggle.onValueChanged:AddListener(self.m_OnToggleChgCallback)	
	self.Controls.toggle = toggle
end

function ClanPresbyterActivityCell:SetCellData(idx, data)
	local controls = self.Controls
	local nPresenter = IGame.ClanBuildingPresenter
	
	controls.m_Name.text = data.m_ActCfg.TargetName
	controls.m_Desc.text = data.m_ActCfg.TargetDesc
	controls.m_Progress.text = GetValuable(data.m_State == nPresenter.WageState.GoTo, 
			string.format("进度：%d/%d", data.nProcess,data.m_ActCfg.nTargetTimes), "")
	controls.m_ScroeText.text = string.format("+%d评分",data.m_ActCfg.Score)

	controls.m_Finish.enabled = false
	if data.m_State == nPresenter.WageState.Completed then
		controls.m_Finish.enabled = true
	end

	self.m_SelCellIdx = idx
	
	if nil ~= data.m_ActCfg.Icon and "" ~= data.m_ActCfg.Icon then
		UIFunction.SetImageSprite(self.Controls.m_Icon, GuiAssetList.GuiRootTexturePath .. data.m_ActCfg.Icon)
	end
end

-- 设置选中回调
function ClanPresbyterActivityCell:SetSelectCallback( func_cb )
	self.m_SelectedCallback = func_cb
end

-- 设置toggle group
function ClanPresbyterActivityCell:SetToggleGroup(toggleGroup)
    self.Controls.toggle.group = toggleGroup
end

-- 设置toggle group
function ClanPresbyterActivityCell:SetToggleIsOn(on)
	local tgl = self.Controls.toggle
	if tgl ~= nil then
    	tgl.isOn = on
    end
end

function ClanPresbyterActivityCell:IsToggleOn()
	local tgl = self.Controls.toggle
	if tgl then
    	return tgl.isOn
    end
	return false
end

function ClanPresbyterActivityCell:OnSelectChanged(on)
	if nil ~= self.m_SelectedCallback and on then
		self.m_SelectedCallback(self.m_SelCellIdx)
	end
end

function ClanPresbyterActivityCell:OnRecycle()
	self.Controls.toggle.onValueChanged:RemoveListener(self.m_OnToggleChgCallback)
	self.m_SelectedCallback = nil

	UIControl.OnRecycle(self)
	table_release(self)
end

function ClanPresbyterActivityCell:OnDestroy()
	self.m_OnToggleChgCallback = nil
	self.m_SelectedCallback = nil
	
	UIControl.OnDestroy(self)
	table_release(self)
end

return ClanPresbyterActivityCell