
-----------------------------灵兽阵灵槽------------------------------
local PetZhenLingSlot = UIControl:new
{
	windowName = "PetZhenLingSlot",
	
	ID = -1,										--格子ID
	m_ZhenLingID = -1,								--阵灵对应的物品ID
	click_callback = nil,							--点击回调
}

function PetZhenLingSlot:Attach(obj)
	UIControl.Attach(self,obj)
	self.BtnClickCB = function() self:OnBtnClick() end
	self.Controls.m_ZhenLingBtn.onClick:AddListener(self.BtnClickCB)
end

function PetZhenLingSlot:Show()
	UIControl.Show(self)
end

function PetZhenLingSlot:Hide( destroy )
	UIControl.Hide(self, destroy)
end

function PetZhenLingSlot:OnDestroy()
	UIControl.OnDestroy(self)
end

--设置ID
function PetZhenLingSlot:SetID(id)
	self.ID = id
    
    self.Controls.m_aniUpgrade.gameObject:SetActive(false)
end

--设置开放
function PetZhenLingSlot:SetLock(lock)
	self.Controls.m_Lock.gameObject:SetActive(lock)
	self.Controls.m_AddTrans.gameObject:SetActive(false)
	self.Controls.m_ZhenLingIcon.gameObject:SetActive(false)
	self.Controls.m_ZhenLingQuality.gameObject:SetActive(false)
	self.Controls.m_ZhenLingType.gameObject:SetActive(false)
	self.Controls.m_LevelText.text = ""
end

--设置等级
function PetZhenLingSlot:SetLevel(level)
	self.Controls.m_LevelText.text = tostring(level)
    
    local bFalg = IGame.PetClient:CheckZhenLingCanUpgrade( self.m_ZhenLingID, level)
    self.Controls.m_aniUpgrade.gameObject:SetActive(bFalg)
end

--设置阵灵类型
function PetZhenLingSlot:SetTypeImg(index)
	self.Controls.m_ZhenLingType.gameObject:SetActive(true)
	UIFunction.SetImageSprite(self.Controls.m_ZhenLingType, AssetPath_PetType[index])
end

--设置icon,   path = nil  没有对应的阵灵
function PetZhenLingSlot:SetIcon(path)
	if path then
		self.Controls.m_AddTrans.gameObject:SetActive(false)
		self.Controls.m_Lock.gameObject:SetActive(false)
		self.Controls.m_ZhenLingIcon.gameObject:SetActive(true)
		UIFunction.SetImageSprite(self.Controls.m_ZhenLingIcon, AssetPath.TextureGUIPath..path)
	else
		self.Controls.m_AddTrans.gameObject:SetActive(true)
		self.Controls.m_ZhenLingIcon.gameObject:SetActive(false)
	end	
end

function PetZhenLingSlot:SetZhenLingID(zhenLingID)
	self.m_ZhenLingID = zhenLingID
	local record = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, zhenLingID)
	if not record then
		UIFunction.SetImageSprite(self.Controls.m_ZhenLingQuality,AssetPath_ZhenLingQualityImage[1])
		return 
	end
	UIFunction.SetImageSprite(self.Controls.m_ZhenLingQuality,AssetPath_ZhenLingQualityImage[record.lBaseLevel])
end

--清空
function PetZhenLingSlot:ClearView()
	self.Controls.m_AddTrans.gameObject:SetActive(true)
	self.Controls.m_ZhenLingIcon.gameObject:SetActive(false)
	self.Controls.m_ZhenLingQuality.gameObject:SetActive(false)
	self.Controls.m_ZhenLingType.gameObject:SetActive(false)
	self.Controls.m_Lock.gameObject:SetActive(false)
	self.Controls.m_LevelText.text = ""
    self.Controls.m_aniUpgrade.gameObject:SetActive(false)
end

--设置点击回调
function PetZhenLingSlot:SetClickCallBack(btnClickCB)
	self.click_callback = btnClickCB
end

--点击回调事件
function PetZhenLingSlot:OnBtnClick()
	if self.click_callback ~= nil then
		self.click_callback(self.ID, self)
	end
end

return PetZhenLingSlot