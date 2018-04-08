------------------------------灵兽界面灵兽item------------------------------------
local PetIconItem = UIControl:new
{
	windowName = "PetIconItem",
	m_UID = 0,						--当前UID
	m_ID = 0,						--对应的灵兽ID
	m_registerDeadEvent	= false,	--是否带有冷却效果
	m_selected_calback = nil, 		--点击回调
	m_ShowSelectedEffect = true,	--是否显示选中图片
	m_ExcuteCBState = false,		--取消勾选时是否执行回调
	
	m_Interactable = true,
	
	IsTuJian = false,				--是否是图鉴 
}
local this = PetIconItem

local optionImg = {
	AssetPath.TextureGUIPath .. "Pet_1/Pet_kejihuo.png",
	AssetPath.TextureGUIPath .. "Pet_1/Pet_yijihuo.png",
}

function PetIconItem:Attach(obj)
	UIControl.Attach(self,obj)	
	
	--注册点击事件
	self.callback_OnSelectChanged = function(on) self:OnSelectChanged(on) end
	self.Controls.m_Toggle.onValueChanged:AddListener(self.callback_OnSelectChanged)
	
    self.click_animation = self.transform:GetComponent(typeof(rkt.ButtonClickAnimation))
    
	self.UpdateTimeCB = function() self:UpDateDeadCoolTime() end
	self.PetDeadCB = function(_,_,_,uid) self:OnPetDead(uid) end
	
	self.transform.gameObject:SetActive(false)
	
	return self
end

function PetIconItem:Show()
	if self.m_registerDeadEvent then
		self:CheckDead(self.m_UID)
		rktEventEngine.SubscribeExecute(EVENT_PET_PETDEAD, SOURCE_TYPE_PET, 0 , self.PetDeadCB)
	end
	UIControl.Show(self)
end

function PetIconItem:Hide(destroy)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_PETDEAD, SOURCE_TYPE_PET, 0 , self.PetDeadCB)
	UIControl.Hide(self, destroy)
end

function PetIconItem:OnDestroy()
	rktEventEngine.UnSubscribeExecute(EVENT_PET_PETDEAD, SOURCE_TYPE_PET, 0 , self.PetDeadCB)
	rktTimer.KillTimer(self.UpdateTimeCB)
	UIControl.OnDestroy(self)
end

--是否是图鉴
function PetIconItem:SetTuJian(tuJian)
	self.IsTuJian = tuJian
end

--初始化信息，外部调用
function PetIconItem:InitState(ID, iconPath, level, isFighting, func_cb, UID, registerDeadEvent)
	self.m_ID = ID
	self.m_UID = UID
	self.registerDeadEvent = registerDeadEvent
	if self.IsTuJian then
		self:SetTuJianIcon(ID)
	else
		self:SetIcon(UID)
	end

	self:SetBGQuality(ID)
	self:SetLevel(level)
	self:SetFight(isFighting)
	self:SetSelectCallback(func_cb)
	
	if registerDeadEvent then
		self:CheckDead(UID)
		rktEventEngine.SubscribeExecute(EVENT_PET_PETDEAD, SOURCE_TYPE_PET, 0 , self.PetDeadCB)
	end
end

--设置选项图片显示
function PetIconItem:SetRightShow(index)
	if index == 0 then 
		self.Controls.m_YiJiHuo.gameObject:SetActive(false)
	else
		self.Controls.m_YiJiHuo.gameObject:SetActive(true)
		UIFunction.SetImageSprite(self.Controls.m_YiJiHuo,optionImg[index])	
	end
	
end

--设置toggle组
function PetIconItem:SetToggleGroup(toggleGroup)
	self.Controls.m_Toggle.group = toggleGroup
end

--设置回调函数
function PetIconItem:SetSelectCallback(func_cb)
	self.m_selected_calback = func_cb
end

--设置灵兽图标
function PetIconItem:SetIcon(UID)
	local nPath = IGame.PetClient:GetPetIcon(UID)
	if nPath then
		UIFunction.SetImageSprite(self.Controls.m_Icon,AssetPath.TextureGUIPath..nPath)
	end
end

--设置土建图标
function PetIconItem:SetTuJianIcon(ID)
	local record = IGame.PetClient:GetRecordByID(ID)
	if record then
		UIFunction.SetImageSprite(self.Controls.m_Icon,AssetPath.TextureGUIPath..record.HeadIcon)
	end
end

--设置灵兽背景
function PetIconItem:SetBGQuality(id)
	local record = IGame.PetClient:GetRecordByID(id)
	if not record then
		UIFunction.SetImageSprite(self.Controls.m_QualityImage,AssetPath_PetBGQuality[1],function() self.transform.gameObject:SetActive(true) end)
	else
		UIFunction.SetImageSprite(self.Controls.m_QualityImage,AssetPath_PetBGQuality[record.Type], function() self.transform.gameObject:SetActive(true) end)
	end
end

--设置icon置灰
function PetIconItem:SetIconGray(isGray)
	UIFunction.SetImageGray(self.Controls.m_Icon, isGray)
end

--设置品级  nQuality-品级索引
function PetIconItem:SetQuality(nQuality)
	--[[if not nQuality then return end
	UIFunction.SetImageSprite(self.Controls.m_QualityImage, AssetPath_PetIconQuality[nQuality])--]]
end


--设置等级
function PetIconItem:SetLevel(level,isRed)
	if isRed then 
		self.Controls.m_LevelText.text = string.format("<color=red>%d</color>",level)
	else
		self.Controls.m_LevelText.text = tostring(level)
	end
end
--设置是否出战状态
function PetIconItem:SetFight(nIsFighting)
	self.Controls.m_FightImage.gameObject:SetActive(nIsFighting)
end

--设置是否是上阵状态
function PetIconItem:SetZhenIcon(show)
	self.Controls.m_ZhenImg.gameObject:SetActive(show)
end

-- 设置动画开关
function PetIconItem:SetClickAnimation(bSwitch)
    
    if self.click_animation then 
        self.click_animation.enabled = bSwitch
    end
end 

function PetIconItem:OnSelectChanged(on)
	if not self.m_Interactable then
		return
	end
	if not on and self.m_ShowSelectedEffect then
		if self.m_ShowSelectedEffect then
			self.Controls.m_Select.gameObject:SetActive(false)
		end
		if self.m_ExcuteCBState then
			if nil ~= self.m_selected_calback then 
				self.m_selected_calback(self.m_ID,self)
			end
		end
	else
		if self.m_ShowSelectedEffect then
			self.Controls.m_Select.gameObject:SetActive(true)
		end
		if nil ~= self.m_selected_calback then 
			self.m_selected_calback(self.m_ID,self)
		end
	end
end

--是否交互
function PetIconItem:SetInteractable(nInteractable)
	self.m_Interactable = nInteractable
end
  
function PetIconItem:SetFocus(on)
	self.Controls.m_Toggle.isOn = on
end

--是否显示选中图片
function PetIconItem:SetShowSelectedEffect(nShow)
	self.m_ShowSelectedEffect = nShow
end

--取消勾选的时候是否执行回调
function PetIconItem:SetChangeState(nExcute)
	self.m_ExcuteCBState = nExcute
end

--设置选中图片的显示与否
function PetIconItem:SetSelectedImgState(nShow)
	self.Controls.m_Select.gameObject:SetActive(nShow)
end

--设置等级背景蒙版显示
function PetIconItem:SetLevelMaskShow(show)
	self.Controls.m_LevelMask.gameObject:SetActive(show)
end

--检查冷却
function PetIconItem:CheckDead(UID)
	local leftTime = IGame.PetClient:GetLeftTimeByUID(UID)
	self:SetDeadCoolTime(leftTime)
end

--手动设置冷却显示
function PetIconItem:SetCoolShow(show)
	self.Controls.m_CoolTime.gameObject:SetActive(show)
end

--设置冷却时间显示
function PetIconItem:SetDeadCoolTime(coolTime)
	if coolTime > 0 then
		self.CoolTime = coolTime
		self.StartTick = luaGetTickCount()
		self.Controls.m_CoolTime.gameObject:SetActive(true)
		UIFunction.SetImageGray(self.Controls.m_Icon, true)
		rktTimer.SetTimer(self.UpdateTimeCB, 30, -1, "PetIconItem:UpDateDeadCoolTime()")
	else
		self.Controls.m_CoolTime.gameObject:SetActive(false)
		UIFunction.SetImageGray(self.Controls.m_Icon, false)
		rktTimer.KillTimer(self.UpdateTimeCB)
	end
end

--更新倒计时
function PetIconItem:UpDateDeadCoolTime()
	local curTime = luaGetTickCount()
	local passTime = curTime - self.StartTick

	local showTime = math.floor(self.CoolTime / 1000 - passTime / 1000)
	if showTime > 0 then
		self.Controls.m_CoolText.text = tostring(showTime)
	else
		self.Controls.m_CoolText.text = 0
		self.Controls.m_CoolTime.gameObject:SetActive(false)
		local isBattle = IGame.PetClient:IsBattleState(self.m_UID)
		self:SetFight(isBattle)
		UIFunction.SetImageGray(self.Controls.m_Icon, false)
		rktTimer.KillTimer(self.UpdateTimeCB)
	end
end

--灵兽死亡订阅事件
function PetIconItem:OnPetDead(uid)
	if uid == self.m_UID then
		self:CheckDead(uid)
	end
end

return this