-- 加入帮派列表cell类
-- @Author: XieXiaoMei
-- @Date:   2017-04-10 10:28:16
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-08 15:56:51

------------------------------------------------------------
local ClanJoinCell = UIControl:new
{
	windowName         = "ClanJoinCell",
	m_SelCellIdx       = 0, 
	m_SelectedCallback = nil,
	m_TglChangedCallback = nil,
}

local this = ClanJoinCell
------------------------------------------------------------

function ClanJoinCell:Attach(obj)
	UIControl.Attach(self,obj)

 	self.m_TglChangedCallback = function(on) self:OnSelectChanged(on) end
	self.Controls.m_Toggle.onValueChanged:AddListener(self.m_TglChangedCallback)
end


function ClanJoinCell:OnDestroy()
	self.m_SelectedCallback = nil
	UIControl.OnDestroy(self)

	table_release(self)
end


-- 填充cell数据
function ClanJoinCell:SetCellData(idx, data, bFocus)
	local controls = self.Controls

	controls.m_IDTxt.text       = data.dwID
	controls.m_NameTxt.text     = data.szName

	local maxMemberCnt = ClanSysDef.GetMaxMemberCnt(data.nLevel)
	controls.m_MembersTxt.text  = string.format("%d/%d", data.nMemberCount, maxMemberCnt) 
	
	controls.m_HostNameTxt.text = data.szShaikhName
	controls.m_LevelTxt.text    = data.nLevel
	controls.m_IDTxt.text       = data.dwID

	controls.m_Applied.gameObject:SetActive(data.nIsApply)
	
	local str = ""
	if not data.nIsApply then
		str = string.format("%s级以上", data.nLevelLimit)
		local limitJob = data.dwVocationLimit
		if not IsNilOrEmpty(limitJob) and limitJob ~= ClanSysDef.NoVocationLimitCode then
			str = string.format("%s，职业：%s", str, limitJob)
		end	
	end
	controls.m_JoinCondTxt.text  = str

	self.m_SelCellIdx = idx
	
	self:SetToggleOn(bFocus)
end

-- 获取选中的idx
function ClanJoinCell:GetSelCellIdx()	
	return  self.m_SelCellIdx
end


-- 设置选中的toggle 选中/取消选中
function ClanJoinCell:SetToggleOn(isOn)	
	if not self:isLoaded() then
		return
	end

	self.Controls.m_Toggle.isOn = isOn
end

-- 设置选中回调
function ClanJoinCell:SetSelectCallback( func_cb )
	self.m_SelectedCallback = func_cb
end

-- 设置toggle group
function ClanJoinCell:SetToggleGroup(toggleGroup)
    self.Controls.m_Toggle.group = toggleGroup
end

function ClanJoinCell:OnRecycle()	
	self.Controls.m_Toggle.onValueChanged:RemoveListener(self.m_TglChangedCallback)
	self.m_SelectedCallback = nil

	UIControl.OnRecycle(self)

	table_release(self)
end

function ClanJoinCell:OnSelectChanged(on)
	--local color = on and Color.New(1,1,1,1) or Color.New(0.117,0.353,0.408,1)
	--UIFunction.SetTxtComsColor(self.transform.gameObject, color)
	
	if nil ~= self.m_SelectedCallback and on then
		self.m_SelectedCallback(self.m_SelCellIdx)
	end
end

return this



