
local PetHuanHuaItem = UIControl:new
{
	windowName = "PetHuanHuaItem",
	call_back = nil, 								--改变回调
	m_UID = nil, 		
}

function PetHuanHuaItem:Attach(obj)
	UIControl.Attach(self,obj)
	self.callback_OnSelectChanged = function(on) self:OnSelectChanged(on) end
	self.Controls.m_Toggle.onValueChanged:AddListener(self.callback_OnSelectChanged)
end

function PetHuanHuaItem:Show()
	UIControl.Show(self)
end

function PetHuanHuaItem:Hide( destroy )
	UIControl.Hide(self, destroy)
end

function PetHuanHuaItem:OnDestroy()
	UIControl.OnDestroy(self)
end
--------------------------------------------------------------------------------------

--设置相关显示
function PetHuanHuaItem:SetData(UID)
	if not UID then return end 
	self.m_UID = UID
	local record = IGame.PetClient:GetRecordByUID(UID)
	if not record then return end
	
	UIFunction.SetImageSprite(self.Controls.m_PetIcon, AssetPath.TextureGUIPath..record.HeadIcon)
	
	local isBattle = IGame.PetClient:IsBattleState(UID)
	self.Controls.m_FightTrans.gameObject:SetActive(isBattle)
	
	local level = IGame.PetClient:GetPetLevel(UID)
	self.Controls.m_LevelText.text = level
	
	local name = IGame.PetClient:GetPetName(UID)
	self.Controls.m_NameText.text = name
	
	local fightNum = IGame.PetClient:GetFightNum(UID)
	self.Controls.m_FightText.text = "战力："..tostring(fightNum or 0)
end

--设置回调函数
function PetHuanHuaItem:SetSelectCallback(func_cb)
	self.call_back = func_cb
end

--设置toggleGroup
function PetHuanHuaItem:SetToggleGroup(group)
	self.Controls.m_Toggle.group = group
end

--设置选中状态
function PetHuanHuaItem:SetFocus(on)
	self.Controls.m_Toggle.isOn = on
end

function PetHuanHuaItem:OnSelectChanged(on)
	if on then 
		if self.call_back ~= nil then 
			self.call_back(self)
		end
	end
end

return PetHuanHuaItem
