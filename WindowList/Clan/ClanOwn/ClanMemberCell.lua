-- @Author: XieXiaoMei
-- @Date:   2017-04-12 16:43:41
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-08 15:17:07

------------------------------------------------------------
local ClanMemberCell = UIControl:new
{
	windowName = "ClanMemberCell",
	
	m_CellIdx 	= 0, 

	m_SelectedCallback = nil,
	m_TglChangedCallback = nil,
	m_PassGongCallback = nil,

	m_IsLocalPlayer = false,
}
local this = ClanMemberCell

local LocalPlaTxtsColor = "<color=#10a41b>%s</color>" --本地玩家字体颜色
local NormalTxtsColor   = "%s"		--正常字体颜色
local SelectedTxtsColor = Color.New(1,1,1,1)					--选中字体颜色

------------------------------------------------------------

function ClanMemberCell:Attach(obj)
	UIControl.Attach(self,obj)

 	self.m_TglChangedCallback = function(on) self:OnSelectChanged(on) end
    local toggle = self.transform:GetComponent(typeof(Toggle))
	toggle.onValueChanged:AddListener(self.m_TglChangedCallback)
	
	self:AddListener( self.Controls.m_PassGongBtn , "onClick" , self.OnBtnPassGongClicked , self )

	self.Controls.toggle = toggle
end


-- 设置选中的toggle 选中/取消选中
function ClanMemberCell:SetToggleOn(isOn)	
	self.Controls.toggle.isOn = isOn
end


function ClanMemberCell:SetCellData(idx, data)
	local controls = self.Controls
	
	local selfName = IGame.EntityClient:GetHero():GetName()
	self.m_IsLocalPlayer = selfName == data.szName
	local color  = self.m_IsLocalPlayer and LocalPlaTxtsColor or NormalTxtsColor

	local titleID  = data.nTitle
	if UIFunction.SetCellHeadTitle(titleID, controls.m_Title, controls) then
		controls.m_TitleTxt.text = ""
	else
		controls.m_TitleTxt.text = self.m_IsLocalPlayer and string.format(color, "无") or "无"
	end

	controls.m_NameTxt.text = self.m_IsLocalPlayer and string.format(color, data.szName) or data.szName
	controls.m_LevelTxt.text = self.m_IsLocalPlayer and string.format(color, data.nLevel) or data.nLevel
	controls.m_JobTxt.text = self.m_IsLocalPlayer and string.format(color, GameHelp.GetVocationName(data.nVocation)) or GameHelp.GetVocationName(data.nVocation)
	controls.m_PositionTxt.text = self.m_IsLocalPlayer and string.format(color, ClanSysDef.ClanPositionStrs[data.nIdentity]) or ClanSysDef.ClanPositionStrs[data.nIdentity]
	controls.m_WeekContribTxt.text = self.m_IsLocalPlayer and string.format(color, data.nTotalContribute) or data.nTotalContribute
	
	local offlineSec = IGame.EntityClient:GetZoneServerTime() - data.nLogoutTime
	local _, t = GetCDTime(offlineSec)

	local str = "在线"
	if not data.bIsOnline then
		str = "刚刚"
		if t["天"] > 0 then
			str = t["天"] .. "天前"
		elseif t["小时"] > 0 then
			str = t["小时"] .. "小时前"
		end
	end
	controls.m_OnlineStateTxt.text = self.m_IsLocalPlayer and string.format(color, str) or str

	controls.m_LocalPlaBgImg.gameObject:SetActive(self.m_IsLocalPlayer)
	
	--self:SetTxtsColor(color)
	
	controls.m_PassGongBtn.gameObject:SetActive(data.bCanImpart)

	self.m_CellIdx = idx
end

function ClanMemberCell:SetSelectCallback( func_cb )
	self.m_SelectedCallback = func_cb
end

function ClanMemberCell:SetPassGongCallback( func_cb )
	self.m_PassGongCallback = func_cb
end

function ClanMemberCell:OnDestroy()
	UIControl.OnDestroy(self)

	self.m_SelectedCallback = nil
	
	table_release(self)
end

function ClanMemberCell:OnRecycle()
	local controls = self.Controls
	
	controls.toggle.onValueChanged:RemoveListener(self.m_TglChangedCallback)
	
	self.m_SelectedCallback = nil

	if controls.headTitleCell then
		controls.headTitleCell:Recycle()
	end

	UIControl.OnRecycle(self)

	table_release(self)
end

function ClanMemberCell:SetToggleGroup(toggleGroup)
    self.Controls.toggle.group = toggleGroup
end

function ClanMemberCell:OnSelectChanged(on)
	-- 改变字体颜色
	local color = NormalTxtsColor
	if on then
		color = SelectedTxtsColor
	else
		color  = self.m_IsLocalPlayer and LocalPlaTxtsColor or color
	end
	--self:SetTxtsColor(color)

	if nil ~= self.m_SelectedCallback and on then
		self.m_SelectedCallback(self.m_CellIdx)
	end
end

function ClanMemberCell:SetTxtsColor(color)
	local texts = self.transform:GetComponentsInChildren(typeof(Text))
	for i = 0 , texts.Length - 1 do 
		texts[i].color = color
	end
end

function ClanMemberCell:OnBtnPassGongClicked()
	--print("点击传功")
	if nil ~= self.m_PassGongCallback then
		self.m_PassGongCallback(self.m_CellIdx)
	end
end

return this