-- 单个好友申请Cell
-- @Author: LiaoJunXi
-- @Date:   2017-09-012 19:00:21
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-29 12:08:26

local FriendApplicantCell = UIControl:new
{
	windowName         = "FriendApplicantCell",

	m_OnToggleChgCallback = nil,
	m_SelectedCallback = nil,
	
	m_SelCellIdx  	   = 0,
}

local this = FriendApplicantCell

-------------------------------------------------------------
function FriendApplicantCell:Attach( obj )
	UIControl.Attach(self, obj)

	self.m_OnToggleChgCallback = function(on) self:OnSelectChanged(on) end
    local toggle = self.transform:GetComponent(typeof(Toggle))
	toggle.onValueChanged:AddListener(self.m_OnToggleChgCallback)
	
	self.Controls.toggle = toggle
	
	self:AddListener( self.Controls.m_AgreeBtn , "onClick" , self.OnBtnAgreeClicked , self )
	self:AddListener( self.Controls.m_RefuseBtn , "onClick" , self.OnBtnRefuseClicked , self )
end

function FriendApplicantCell:OnBtnAgreeClicked()
	IGame.FriendClient:RespondBeApplyFriendMsg(self.m_SelCellIdx, true)
end

function FriendApplicantCell:OnBtnRefuseClicked()
	IGame.FriendClient:RespondBeApplyFriendMsg(self.m_SelCellIdx, false)
end

function FriendApplicantCell:SetCellData(idx, data)
	local controls = self.Controls
	data.hasRead = true

	controls.m_Name.text = data.m_name
	controls.m_Level.text = data.m_level
	controls.m_Job.text = GameHelp.GetVocationName(data.m_vocation)

	self.m_SelCellIdx = idx
	
--[[	if PERSON_VOCATION_LINGXIN == data.m_vocation then
		data.m_faceID = 2
	elseif data.m_faceID == 31 or data.m_faceID == 0 then
		data.m_faceID = 1
	end--]]
	print("data.m_faceID = "..data.m_faceID)
	UIFunction.SetHeadImage(controls.m_Avatar,data.m_faceID)
end

-- 设置选中回调
function FriendApplicantCell:SetSelectCallback( func_cb )
	self.m_SelectedCallback = func_cb
end

-- 设置toggle group
function FriendApplicantCell:SetToggleGroup(toggleGroup)
    self.Controls.toggle.group = toggleGroup
end

-- 设置toggle group
function FriendApplicantCell:SetToggleIsOn(on)
	local tgl = self.Controls.toggle
	if tgl ~= nil then
    	tgl.isOn = on
    end
end

function FriendApplicantCell:IsToggleOn()
	local tgl = self.Controls.toggle
	if tgl then
    	return tgl.isOn
    end
	return false
end

function FriendApplicantCell:OnSelectChanged(on)
	if nil ~= self.m_SelectedCallback and on then
		self.m_SelectedCallback(self.m_SelCellIdx)
	end
end

function FriendApplicantCell:OnRecycle()
	self.Controls.toggle.onValueChanged:RemoveListener(self.m_OnToggleChgCallback)
	self.m_SelectedCallback = nil

	UIControl.OnRecycle(self)
	table_release(self)
end

function FriendApplicantCell:OnDestroy()
	self.Controls.toggle.onValueChanged:RemoveListener(self.m_OnToggleChgCallback)
	self.m_SelectedCallback = nil
	
	UIControl.OnDestroy(self)
	table_release(self)
end

return FriendApplicantCell