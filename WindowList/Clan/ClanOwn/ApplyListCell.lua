-- 帮派申请列表Cell
-- @Author: XieXiaoMei
-- @Date:   2017-04-12 16:43:41
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-25 17:16:21

------------------------------------------------------------
local ApplyListCell = UIControl:new
{
	windowName = "ApplyListCell",
	m_MemberID = 0, 
	m_SelectedCallback = nil,
	m_TglChangedCallback = nil,
}
local this = ApplyListCell
------------------------------------------------------------

function ApplyListCell:Attach(obj)
	UIControl.Attach(self,obj)

 	self.m_TglChangedCallback = function(on) self:OnSelectChanged(on) end
    local toggle = self.transform:GetComponent(typeof(Toggle))
	toggle.onValueChanged:AddListener(self.m_TglChangedCallback)
	
	self.Controls.toggle = toggle
end

function ApplyListCell:SetCellData(data, idx)
	local controls = self.Controls

	local titleID  = data.nTitle
	if UIFunction.SetCellHeadTitle(titleID, controls.m_Title, controls) then
		controls.m_TitleTxt.text = ""
	else
		controls.m_TitleTxt.text = "无"
	end

	controls.m_NameTxt.text  = data.szName
	controls.m_LevelTxt.text = data.nLevel
	controls.m_JobTxt.text   = GameHelp.GetVocationName(data.nVocation)

	self.m_MemberID = data.dwPDBID
end


function ApplyListCell:SetSelectCallback( func_cb )
	self.m_SelectedCallback = func_cb
end

function ApplyListCell:OnDestroy()
	UIControl.OnDestroy(self)

	self.m_SelectedCallback = nil

	table_release(self) 
end

function ApplyListCell:OnRecycle()
	local controls = self.Controls
	controls.toggle.isOn = false
	controls.toggle.onValueChanged:RemoveListener(self.m_TglChangedCallback)
	self.m_TglChangedCallback = nil

	if controls.headTitleCell then
		self.Controls.headTitleCell:Recycle()
	end

	UIControl.OnRecycle(self)

	self.m_SelectedCallback = nil

	table_release(self)
end

function ApplyListCell:SetToggleGroup(toggleGroup)
    self.Controls.toggle.group = toggleGroup
end

function ApplyListCell:SetTxtColor(color)
	local Texts = self.transform:GetComponentsInChildren(typeof(Text))
	for i = 0 , Texts.Length - 1 do 
		Texts[i].color = color
	end
end

function ApplyListCell:OnSelectChanged(on)

	if on then
		--self:SetTxtColor(Color.New(1,1,1,1))
	else
		--self:SetTxtColor(Color.New(0.117,0.353,0.408,1))
	end
	
	if nil ~= self.m_SelectedCallback and on then
		self.m_SelectedCallback(self.m_MemberID)
	end
end

return this



