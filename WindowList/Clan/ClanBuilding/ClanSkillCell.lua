-- 单个帮会技能ceil元素
-- @Author: LiaoJunXi
-- @Date:   2017-09-07 12:16:21
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-29 12:08:26

local ClanSkillCell = UIControl:new
{
	windowName         = "ClanSkillCell",

	m_OnToggleChgCallback = nil,
	m_SelectedCallback = nil,
	
	m_SelCellIdx  	   = 0,
}

local this = ClanSkillCell

-------------------------------------------------------------
function ClanSkillCell:Attach( obj )
	UIControl.Attach(self, obj)

	self.m_OnToggleChgCallback = function(on) self:OnSelectChanged(on) end
    local toggle = self.transform:GetComponent(typeof(Toggle))
	toggle.onValueChanged:AddListener(self.m_OnToggleChgCallback)
	
	self.Controls.toggle = toggle
end


function ClanSkillCell:SetCellData(idx, data)
	local controls = self.Controls

	controls.m_TextSkillName.text = data.m_UpdateCfg.Name
	controls.m_TextSkillLevel.text = GetValuable(data.m_Unlock,data.nLevel .. "级","<color=#e4595a>未学会</color>") 
	controls.m_LockTip.enabled = not data.m_Unlock

	self.m_SelCellIdx = idx
	
	if nil ~= data.m_UpdateCfg.Icon and "" ~= data.m_UpdateCfg.Icon then
		UIFunction.SetImageSprite(self.Controls.m_ImageSkillIcon, 
		GuiAssetList.GuiRootTexturePath .. data.m_UpdateCfg.Icon)
	end
end

-- 设置选中回调
function ClanSkillCell:SetSelectCallback( func_cb )
	self.m_SelectedCallback = func_cb
end

-- 设置toggle group
function ClanSkillCell:SetToggleGroup(toggleGroup)
    self.Controls.toggle.group = toggleGroup
end

-- 设置toggle group
function ClanSkillCell:SetToggleIsOn(on)
	local tgl = self.Controls.toggle
	if tgl ~= nil then
    	tgl.isOn = on
    end
end

function ClanSkillCell:IsToggleOn()
	local tgl = self.Controls.toggle
	if tgl then
    	return tgl.isOn
    end
	return false
end

function ClanSkillCell:OnSelectChanged(on)
	if nil ~= self.m_SelectedCallback and on then
		self.m_SelectedCallback(self.m_SelCellIdx)
	end
end

function ClanSkillCell:OnBtnCloseClicked()
	self:Hide()
end

function ClanSkillCell:OnRecycle()
	self.Controls.toggle.onValueChanged:RemoveListener(self.m_OnToggleChgCallback)
	self.m_SelectedCallback = nil

	UIControl.OnRecycle(self)
	table_release(self)
end

function ClanSkillCell:OnDestroy()
	self.m_OnToggleChgCallback = nil
	self.m_SelectedCallback = nil
	
	UIControl.OnDestroy(self)
	table_release(self)
end

return ClanSkillCell