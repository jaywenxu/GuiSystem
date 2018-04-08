-- 单个帮会活动ceil元素
-- @Author: LiaoJunXi
-- @Date:   2017-09-07 12:16:21
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-29 12:08:26

local ClanWageCell = UIControl:new
{
	windowName         = "ClanWageCell",

	m_OnToggleChgCallback = nil,
	m_SelectedCallback = nil,
	m_HandledCallback = nil,
	
	m_SelCellIdx  	   = 0,
}

local this = ClanWageCell

-------------------------------------------------------------
function ClanWageCell:Attach( obj )
	UIControl.Attach(self, obj)

	self.m_OnToggleChgCallback = function(on) self:OnSelectChanged(on) end
    local toggle = self.transform:GetComponent(typeof(Toggle))
	toggle.onValueChanged:AddListener(self.m_OnToggleChgCallback)	
	self.Controls.toggle = toggle
	
	self.Controls.m_Button.onClick:AddListener(handler(self, self.OnBtnOptionClicked))
end


function ClanWageCell:SetCellData(idx, data)
	local controls = self.Controls

	controls.m_Name.text = data.m_WageCfg.Name
	controls.m_Desc.text = data.m_WageCfg.Desc
	
	controls.m_Reward.text = tostring(data.m_RewardBill)
	
	local nPresenter = IGame.ClanBuildingPresenter
	
	controls.m_Finish.enabled = false
	controls.m_Progress.text = ""
	controls.m_Button.gameObject:SetActive(false)
	if data.m_State == nPresenter.WageState.GoTo then
		controls.m_Progress.text = string.format("进度：%d/%d", data.nTimes,data.m_WageCfg.Times)
	elseif data.m_State == nPresenter.WageState.Unclaimed then
		controls.m_Button.gameObject:SetActive(true)
	elseif data.m_State == nPresenter.WageState.Completed then
		controls.m_Finish.enabled = true
	end

	self.m_SelCellIdx = idx
	self.m_State = data.m_State
	
	if nil ~= data.m_WageCfg.Icon and "" ~= data.m_WageCfg.Icon then
		UIFunction.SetImageSprite(self.Controls.m_Icon, GuiAssetList.GuiRootTexturePath .. data.m_WageCfg.Icon)
	end
	
	self:ShowOrHideRedDot(data.m_State == nPresenter.WageState.Unclaimed)
end

function ClanWageCell:ShowOrHideRedDot (status)
	if nil == status then status = false end
	--[[print(debug.traceback(self.transform.gameObject.name.. 
	"-><color=red>ClanWageCell:ShowOrHideRedDot.state="..tostring(status)..
	"</color>"))--]]
	UIFunction.ShowRedDotImg(self.Controls.m_Button.transform,status)
end

-- 设置选中回调
function ClanWageCell:SetSelectCallback( func_cb )
	self.m_SelectedCallback = func_cb
end

function ClanWageCell:SetHandleCallback( func_cb )
	self.m_HandledCallback = func_cb
end

-- 设置toggle group
function ClanWageCell:SetToggleGroup(toggleGroup)
    self.Controls.toggle.group = toggleGroup
end

-- 设置toggle group
function ClanWageCell:SetToggleIsOn(on)
	local tgl = self.Controls.toggle
	if tgl ~= nil then
    	tgl.isOn = on
    end
end

function ClanWageCell:IsToggleOn()
	local tgl = self.Controls.toggle
	if tgl then
    	return tgl.isOn
    end
	return false
end

function ClanWageCell:OnSelectChanged(on)
	if nil ~= self.m_SelectedCallback and on then
		self.m_SelectedCallback(self.m_SelCellIdx)
	end
end

function ClanWageCell:OnBtnOptionClicked()
	local nPresenter = IGame.ClanBuildingPresenter
	if self.m_State ~= nPresenter.WageState.Completed then
		if nil ~= self.m_HandledCallback and on then
			self.m_HandledCallback(self.m_SelCellIdx)
		end
	end
	local nPresenter = IGame.ClanBuildingPresenter
	if self.m_State == nPresenter.WageState.GoTo then
		IGame.ClanClient.m_ClanBuildingManager.m_WelfareObj:ExecEntryFunc(self.m_SelCellIdx)
	elseif self.m_State == nPresenter.WageState.Unclaimed then
		IGame.ClanClient.m_ClanBuildingManager.m_WelfareObj:ActivityRewardRsq(self.m_SelCellIdx)
	end
end

function ClanWageCell:OnRecycle()
	self.Controls.toggle.onValueChanged:RemoveListener(self.m_OnToggleChgCallback)
	self.m_SelectedCallback = nil
	self.m_HandledCallback = nil

	UIControl.OnRecycle(self)
	table_release(self)
end

function ClanWageCell:OnDestroy()
	self.m_OnToggleChgCallback = nil
	self.m_SelectedCallback = nil
	self.m_HandledCallback = nil
	
	UIControl.OnDestroy(self)
	table_release(self)
end

return ClanWageCell