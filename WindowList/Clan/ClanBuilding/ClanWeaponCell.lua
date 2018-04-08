-- 单个武器cell元素
-- @Author: LiaoJunXi
-- @Date:   2017-09-26 12:16:21
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-29 12:08:26

local ClanWeaponCell = UIControl:new
{
	windowName         = "ClanWeaponCell",

	m_OnToggleChgCallback = nil,
	m_SelectedCallback = nil,
	
	m_SelCellIdx  	   = 0,
}

local this = ClanWeaponCell

-------------------------------------------------------------
function ClanWeaponCell:Attach( obj )
	UIControl.Attach(self, obj)

	self.m_OnToggleChgCallback = function(on) self:OnSelectChanged(on) end
    local toggle = self.transform:GetComponent(typeof(Toggle))
	toggle.onValueChanged:AddListener(self.m_OnToggleChgCallback)
	
	self.Controls.toggle = toggle
end

function ClanWeaponCell:SetCellData(idx, data)
	local controls = self.Controls

	controls.m_NameTxt.text = data.m_WeaponCfg.Name
	controls.m_LevTxt.text = GetValuable(data.m_Unlock, data.Level .. "级", "<color=#e4595a>未解锁</color>")
	if data.m_IsMaxLev then
		controls.m_LevTxt.text = "已满级"
	end

	self.m_SelCellIdx = idx
	
	if not IsNilOrEmpty(data.m_WeaponCfg.Icon) then
		UIFunction.SetImageSprite(self.Controls.m_IconImg, 
		GuiAssetList.GuiRootTexturePath .. data.m_WeaponCfg.Icon)
	end
end

-- 设置选中回调
function ClanWeaponCell:SetSelectCallback( func_cb )
	self.m_SelectedCallback = func_cb
end

-- 设置toggle group
function ClanWeaponCell:SetToggleGroup(toggleGroup)
    self.Controls.toggle.group = toggleGroup
end

-- 设置toggle group
function ClanWeaponCell:SetToggleIsOn(on)
	local tgl = self.Controls.toggle
	if tgl ~= nil then
    	tgl.isOn = on
    end
end

function ClanWeaponCell:IsToggleOn()
	local tgl = self.Controls.toggle
	if tgl then
    	return tgl.isOn
    end
	return false
end

function ClanWeaponCell:OnSelectChanged(on)
	if nil ~= self.m_SelectedCallback and on then
		self.m_SelectedCallback(self.m_SelCellIdx)
	end
end

function ClanWeaponCell:OnRecycle()
	self.Controls.toggle.onValueChanged:RemoveListener(self.m_OnToggleChgCallback)
	self.m_SelectedCallback = nil

	UIControl.OnRecycle(self)
	table_release(self)
end

function ClanWeaponCell:OnDestroy()
	self.m_OnToggleChgCallback = nil
	self.m_SelectedCallback = nil
	
	UIControl.OnDestroy(self)
	table_release(self)
end

return ClanWeaponCell