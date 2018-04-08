
-----------------------------灵兽阵发槽------------------------------
--可和阵灵槽合并复用，这里没有用这种方式
local PetZhenFaIcon = UIControl:new
{
	windowName = "PetZhenFaIcon",
	
	ID = -1,										--格子ID
	click_callback = nil,							--点击回调
}

--各职业固定
local IconPath = {
	AssetPath.TextureGUIPath.."Pet_1/Pet_z_qinglong.png",
	AssetPath.TextureGUIPath.."Pet_1/Pet_z_baihu.png",
	AssetPath.TextureGUIPath.."Pet_1/Pet_z_zhuque.png",
	AssetPath.TextureGUIPath.."Pet_1/Pet_z_xuanwu.png",
}

local OpenLevel = {
	gPetCfg.PetDeploymentOpenCfg.PetDeploymentOpenLevel_1,
	gPetCfg.PetDeploymentOpenCfg.PetDeploymentOpenLevel_2,
	gPetCfg.PetDeploymentOpenCfg.PetDeploymentOpenLevel_3,
	gPetCfg.PetDeploymentOpenCfg.PetDeploymentOpenLevel_4,
}

function PetZhenFaIcon:Attach(obj)
	UIControl.Attach(self,obj)
	self.OnValueChangedCB = function(on) self:OnValueChanged(on) end
	self.Controls.m_Toggle.onValueChanged:AddListener(self.OnValueChangedCB)
end

function PetZhenFaIcon:Show()
	UIControl.Show(self)
end

function PetZhenFaIcon:Hide( destroy )
	UIControl.Hide(self, destroy)
end

function PetZhenFaIcon:OnDestroy()
	UIControl.OnDestroy(self)
end

--设置toggleGroup
function PetZhenFaIcon:SetToggleGroup(group)
	self.Controls.m_Toggle.group = group
end

--设置阵法槽ID
function PetZhenFaIcon:SetID(id)
	self.ID = id
	self:SetIcon(id)   
end

-- 设置红点显示
function PetZhenFaIcon:SetShowRedDot()
    
    local bFlag = IGame.PetClient:CheckPetZhenCanUpgrade(self.ID-1)
    self.Controls.m_ZhenFaRedDot.gameObject:SetActive(bFlag)
end

--设置lock状态
function PetZhenFaIcon:SetLock(lock)
	self.Controls.m_LockTrans.gameObject:SetActive(lock)
end

--设置开放等级相关, level当前等级
function PetZhenFaIcon:SetOpen(level)
	local needLevel = OpenLevel[self.ID]
	
	if level >= needLevel then
		self.Controls.m_OpenLevelMask.gameObject:SetActive(false)
		self.Controls.m_OpenLevelText = ""
		self:SetLock(false)
        self:SetShowRedDot()
	else
		self:SetLock(true)
		self.Controls.m_OpenLevelMask.gameObject:SetActive(true)
		self.Controls.m_OpenLevelText.text = string.format("%d\n级开启", needLevel)
        self.Controls.m_ZhenFaRedDot.gameObject:SetActive(false)
	end
end

function PetZhenFaIcon:IsOpen()
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local level = pHero:GetNumProp(CREATURE_PROP_LEVEL)
	local needLevel = OpenLevel[self.ID]
	if needLevel > level then 
		return false
	else
		return true
	end
end

--设置lock
function PetZhenFaIcon:SetIcon(id)
	UIFunction.SetImageSprite(self.Controls.m_ZhenFaIcon, IconPath[id])
end

--设置点击回调
function PetZhenFaIcon:SetClickCallBack(btnClickCB)
	self.click_callback = btnClickCB
end

--value改变事件
function PetZhenFaIcon:OnValueChanged(on)
	if on and self.click_callback ~= nil then
		self.click_callback(self)
		self:SetSelected(true)
	else
		self:SetSelected(false)
	end
end

--设置选择框
function PetZhenFaIcon:SetSelected(selected)
	self.Controls.m_Select.gameObject:SetActive(selected)
end

--设置交互状态
function PetZhenFaIcon:SetInteractable(enabled)
	self.Controls.m_Toggle.interactable = enabled
end

--设置焦点
function PetZhenFaIcon:SetFocus(focus)
	self.Controls.m_Toggle.isOn = true
end
return PetZhenFaIcon