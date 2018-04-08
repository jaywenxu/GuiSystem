
-----------------------------------外观界面------------------------------
local ItemCellClass = require( "GuiSystem.WindowList.Shop.Dress.DressItem" )
local HeroDisplayWidgetClass = require( "GuiSystem.WindowList.Shop.Dress.HeroDisplayWidget" )
local HairColorItemClass = require("GuiSystem.WindowList.Shop.Dress.HairColorItem")

local ExteriroTypeWidget = UIControl:new {
	windowName = "ExteriroTypeWidget",

	tabToggleName = {
		emClothes				= 1,
		emHairstyle				= 2,
		emHairstyleToggle		= 3,
		emMakeup				= 4,
		emWeapon				= 5,
		emZuoQi					= 6,
	},

	m_HairColorItemTable = {},			--缓存生成的发饰颜色item, 衣服item也放在这里了
	m_DressItemScriptCache = {},		--缓存生成的时装List脚本
	
	toggleCtl	={},
	
	m_curTab		= 0,			--当前是哪个分页
	m_preTab		= 0,
	
	m_nCount = 0,		--当前分页DressItem数量
	m_CurrIndex = 0,	--当前选中时装索引
	
	m_CurHairColor = 1,		--当前选中发饰index
	
	m_PreView = false,					--是否开启预览
}

local ButtonPath = {
	AssetPath.TextureGUIPath.."Common_button_text/Common_buttongoumai.png",				--购买
	AssetPath.TextureGUIPath.."Store/Shop_wz_chuanshang.png",						--穿上
	AssetPath.TextureGUIPath.."Store/Shop_wz_jiesuo.png",							--解锁
	AssetPath.TextureGUIPath.."Store/Shop_wz_shangma.png",							--上马
	AssetPath.TextureGUIPath.."Store/Shop_wz_xiama.png",							--下马
	AssetPath.TextureGUIPath.."Store/Shop_wz_xufei.png",							--续费			6
	AssetPath.TextureGUIPath.."Store/Shop_wz_yichuanshang.png",					--已穿上
	AssetPath.TextureGUIPath.."Common_frame/Common_mz_huoqucailiao.png",								--获取材料
}
local TitlePath = {
	AssetPath.TextureGUIPath.."Store/Shop_ranse.png",
	AssetPath.TextureGUIPath.."Store/Shop_fashiyanse.png",
}

local BodyPart = {
	EntityBodyPart.BodyMesh,
	EntityBodyPart.HairMesh,
	EntityBodyPart.FaceMesh,
	"",										--武器，不用这种方式
	EntityBodyPart.HorsePart,
}



function ExteriroTypeWidget:Attach(obj)
	UIControl.Attach(self,obj)
	
	HeroDisplayWidgetClass:Attach(self.Controls.m_HeroDisplayWidget.gameObject)
	self.ModelClickEvent = function(eventData) HeroDisplayWidgetClass:OnClickModel(eventData) end
	UIFunction.AddEventTriggerListener(HeroDisplayWidgetClass.Controls.m_HeroRawImage,EventTriggerType.PointerClick,self.ModelClickEvent)
	
	self.OriginPos = true
	
	--缓存toggle
	self.toggleCtl = {
		self.Controls.m_ClothesToggle,	
		self.Controls.m_HairstyleToggle,
		self.Controls.m_MakeupToggle,
		self.Controls.m_WeaponToggle,
		self.Controls.m_ZuoQiToggle,
	}
	
	--事件注册
	self:RegisterEvent()

	self.Controls.ItemToggleGroup =  self.Controls.m_DressList:GetComponent(typeof(ToggleGroup))	
	
	self.Controls.HairColorToggleGroup = self.Controls.m_ColorList:GetComponent(typeof(ToggleGroup))	
	
	self.OnHairColorSelectedCB = function(index) self:OnHairColorSelected(index) end
	self.OnClothesColorSelectedCB = function(subIndex) self:OnClothesSelected(subIndex) end
	self.OnItemCellSelectedCB = function(nType, nIndex) self:OnItemCellSelected(nType, nIndex) end
	
	self.OnUnLockCurAppCB = function() self:OnUnLockCurApp() end
	self.GODepositCB = function() self:GODeposit() end
	self.GetGoodsCB = function() self:GetGoods() end
	self.SetOptionBtnNativeCB = function() self:SetOptionBtnImgNative() end
end

function ExteriroTypeWidget:Show()
	UIControl.Show(self)
	HeroDisplayWidgetClass:ShowHeroModel(true)
	self.OriginPos = true
	--显示的时候，如果默认勾选预览，就直接换装掉，默认选取第一个index的套装
	self.m_PreView = false
	
		
	--刷新界面回调,服务器交互响应
	self.BuySuitCB = function(_,_,_,_,nIDList) self:BuySuitCallBack(nIDList) end
	rktEventEngine.SubscribeExecute(EVENT_APPEAR_UPDATE_RAPPEAR, SOURCE_TYPE_APPEAR, 0, self.BuySuitCB)
	
	self.UnLockAppCB = function(_,_,_,_,nID) self:UnLockAppCallBack(nID) end
	rktEventEngine.SubscribeExecute(EVENT_APPEAR_UNLOCK_APPEAR, SOURCE_TYPE_APPEAR, 0, self.UnLockAppCB)
	--穿上外观返回订阅的事件
	self.EquipAppCB = function(nID) self:EquipAppCallBack(nID) end
	rktEventEngine.SubscribeExecute(EVENT_APPEAR_EQUIP_APPEAR, SOURCE_TYPE_APPEAR, 0, self.EquipAppCB)
	
	self.CloseConfigCB = function() rktEventEngine.SubscribeExecute(EVENT_APPEAR_UPDATE_RAPPEAR, SOURCE_TYPE_APPEAR, 0, self.BuySuitCB) end
	rktEventEngine.SubscribeExecute(EVENT_APPEAR_CLOSE_HAIRCONFIG, 0, 0, self.BuySuitCB)
	
	self:SetDefaultTab(self.m_curTab)
end
function ExteriroTypeWidget:Hide(destroy)
	UIControl.Hide(self)
	HeroDisplayWidgetClass:ShowHeroModel(false)
	self.m_preTab = 0
	--注销订阅的事件
	rktEventEngine.UnSubscribeExecute(EVENT_APPEAR_UPDATE_RAPPEAR, SOURCE_TYPE_APPEAR, 0, self.BuySuitCB)
	rktEventEngine.UnSubscribeExecute(EVENT_APPEAR_UNLOCK_APPEAR, SOURCE_TYPE_APPEAR, 0, self.UnLockAppCB)
	rktEventEngine.UnSubscribeExecute(EVENT_APPEAR_EQUIP_APPEAR, SOURCE_TYPE_APPEAR, 0, self.EquipAppCB)
	
	rktEventEngine.UnSubscribeExecute(EVENT_APPEAR_CLOSE_HAIRCONFIG, 0, 0, self.CloseConfigCB)
end

function ExteriroTypeWidget:OnDestroy()
	self.HairColorConfigWidget = nil
	self.m_curTab		= 0
	self.m_preTab		= 0
	UIControl.OnDestroy(self)
end

function ExteriroTypeWidget:RegisterEvent()
	--部位toggle事件
	self:RegisterToggleChangeEvent()
	
	--染色Btn点击事件
	self.callback_OnConfigHairColorBtnClick = function() self:OnConfigHairColorBtnClick() end
	self.Controls.m_ColorConfigBtn.onClick:AddListener(self.callback_OnConfigHairColorBtnClick)
	
	--套装点击购买
	self.callback_OnBuySuitBtnClick = function() self:OnBuySuitBtnClick() end
	self.Controls.m_SuitBuyBtn.onClick:AddListener(self.callback_OnBuySuitBtnClick)
	
	--恢复默认按钮点击事件
	self.callback_OnRecoveryBtnClick = function() self:OnRecoveryBtnClick() end
	self.Controls.m_RecoveryBtn.onClick:AddListener(self.callback_OnRecoveryBtnClick)
	
	--套装预览Toggle切换事件
	self.callback_PreviewToggle = function(on) self:PreviewToggleChange(on) end
	self.Controls.m_PreviewSuitToggle.onValueChanged:AddListener(self.callback_PreviewToggle)
	
	--放大按钮点击事件
	self.callback_OnEnlargeBtnClick = function() self:OnEnlargeBtnClick() end
	self.Controls.m_EnlargeBtn.onClick:AddListener(self.callback_OnEnlargeBtnClick)
	
	--OptionBtn点击事件
	self.callback_OnOptionBtnClick = function() self:OnOptionBtnClick() end
	self.Controls.m_OptionBtn.onClick:AddListener(self.callback_OnOptionBtnClick)
	
	self.CanClick = true
	self.LateClickCB = function() self:LateClick() end
end

--控制按钮点击，防止连续点击产生的位移积累
function ExteriroTypeWidget:LateClick()
	self.CanClick = true
end

--注册外观部位toggle切换事件
function ExteriroTypeWidget:RegisterToggleChangeEvent()
	for i =1,5,1 do
		self.callback_Toggle = function(on) self:OnToggleChanged(on, i) end
		self.toggleCtl[i].onValueChanged:AddListener(self.callback_Toggle)
	end	
end

--染色按钮点击事件
function ExteriroTypeWidget:OnConfigHairColorBtnClick()
	--延迟加载
	if not self.HairColorConfigWidget then
		self.HairColorConfigWidget = require("GuiSystem.WindowList.Shop.Dress.HairColorConfigWidget")
		self.HairColorConfigWidget:Attach(self.Controls.m_HairColorConfigWidget.gameObject)
	end

	self.HairColorConfigWidget:Show()
	self.HairColorConfigWidget:InitView(self.m_CurrIndex, self.m_CurHairColor)
	
	rktEventEngine.UnSubscribeExecute(EVENT_APPEAR_UPDATE_RAPPEAR, SOURCE_TYPE_APPEAR, 0, self.BuySuitCB)
end

--套装购买点击事件
function ExteriroTypeWidget:OnBuySuitBtnClick()
	local record
	if self.m_curTab == 2 then 
		record = IGame.AppearanceClient:GetHairRecordByIndex(self.m_CurrIndex, self.m_CurHairColor)
	else
		record = IGame.AppearanceClient:GetItemInfoBy(self.m_curTab, self.m_CurrIndex)
	end
	
	if not record then 
		return 
	end
	
	local suitName = record.nSuitName
	
	local costStr = "是否" .. "购买" .. suitName .. "套装?"
	local OnBuySuit_CB = function() self:OnBuySuit() end
	local data = {
		content = costStr,
		confirmCallBack = OnBuySuit_CB,
	}
	UIManager.ConfirmPopWindow:ShowDiglog(data)
end

--确认购买套装逻辑								
function ExteriroTypeWidget:OnBuySuit()
	local recordItem
	if self.m_curTab == 2 then 
		recordItem = IGame.AppearanceClient:GetHairRecordByIndex(self.m_CurrIndex, self.m_CurHairColor)
	else
		recordItem = IGame.AppearanceClient:GetItemInfoBy(self.m_curTab, self.m_CurrIndex)
	end

	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return nil
	end	
	local heroLevel = pHero:GetNumProp(CREATURE_PROP_LEVEL)
	
	local suitTable = IGame.AppearanceClient:GetSuit(self.m_curTab,self.m_CurrIndex)
	local curInfo = IGame.AppearanceClient:GetHeroAppInfo()
	local canBuy = false
	for i,data in pairs(suitTable) do
		if heroLevel < recordItem.nNeedLevel then
			UIManager.TipsActorUnderWindow:AddSystemTips("当前等级不足，无法解锁套装")
			return 
		end
		
		if not curInfo[data.nAppearID] then
			canBuy = true
			break
		end
	end
	
	if not canBuy then
		UIManager.TipsActorUnderWindow:AddSystemTips("已经拥有该套装")
		return
	end
	
	IGame.AppearanceClient:UnLockGroupAppears(recordItem.nAppearID)
end

--恢复默认Btn点击事件
function ExteriroTypeWidget:OnRecoveryBtnClick()
	if not self.CanClick then
		return
	end
	self.CanClick = false
	--恢复放大效果
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end

	local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)
	
	local camera = HeroDisplayWidgetClass.m_Camera.m_Camera
	local enlargePosition
	
	if not self.OriginPos then
		enlargePosition = APPEARANCE_ROLE_CAMERA_UNENLARGE[nVocation]
		UIFunction.AddEventTriggerListener(HeroDisplayWidgetClass.Controls.m_HeroRawImage,EventTriggerType.PointerClick,self.ModelClickEvent)
		self.OriginPos = true
		UIFunction.DOTweenLocalMOVE(camera.gameObject,0.2,enlargePosition)
	end

	self.Controls.m_PreviewSuitToggle.isOn = false
	
	rktTimer.SetTimer(self.LateClickCB, 210,1,"self:LateClick()")			--移动动画完成后恢复交互状态
end

--套装预览Toggle切换事件
function ExteriroTypeWidget:PreviewToggleChange(on)
	self.m_PreView = on
	if on then 						--显示预览套装
		self:PrefiewSuit()
	else							--恢复默认
		self:RecoverSuit()
	end
		
	if self.m_curTab == 2 then
		local itemRecord = IGame.AppearanceClient:GetHairRecordByIndex(self.m_CurrIndex, self.m_CurHairColor)
		self:RefreshSuit(itemRecord.nAppearID)
	elseif self.m_curTab == 1 then
		local itemRecord = IGame.AppearanceClient:GetClothesRecordByIndex(self.m_CurrIndex, self.m_CurHairColor)
		self:RefreshSuit(itemRecord.nAppearID)
	else
		self:RefreshSuitWidget(self.m_curTab, self.m_CurrIndex)
	end
end

--套装预览， 换装方法
function ExteriroTypeWidget:PrefiewSuit()
	local nType = self.m_curTab
	local nIndex = self.m_CurrIndex
	local tmpCurAppearInfo = IGame.AppearanceClient:GetHeroCurAppearInfo()
	
--[[	local clothes = IGame.AppearanceClient:GetSuitPart(nType,nIndex,1)		--衣服
	local hair 		--发型
	local face	= IGame.AppearanceClient:GetSuitPart(nType,nIndex,3)
	local weapon = IGame.AppearanceClient:GetSuitPart(nType,nIndex,4)		--武器
	local ride = IGame.AppearanceClient:GetSuitPart(nType,nIndex,5)			-- 坐骑	
	local colorNum--]]
	
	local clothes
	local hair
	local face
	local weapon
	local ride
	local colorNum
	
	if nType == 1 or nType == 2 then
		clothes = IGame.AppearanceClient:GetClothAndHairSuitPart(nType,nIndex,self.m_CurHairColor,1)
		face = IGame.AppearanceClient:GetClothAndHairSuitPart(nType,nIndex,self.m_CurHairColor,3)
		weapon = IGame.AppearanceClient:GetClothAndHairSuitPart(nType,nIndex,self.m_CurHairColor,4)
		ride = IGame.AppearanceClient:GetClothAndHairSuitPart(nType,nIndex,self.m_CurHairColor,5)
	else
		clothes = IGame.AppearanceClient:GetSuitPart(nType,nIndex,1)
		face = IGame.AppearanceClient:GetSuitPart(nType,nIndex,3)
		weapon = IGame.AppearanceClient:GetSuitPart(nType,nIndex,4)
		ride = IGame.AppearanceClient:GetSuitPart(nType,nIndex,5)
	end
	
	
	local curAppInfo = IGame.AppearanceClient:GetHeroCurAppearInfo()
	
	if nType == 2 then	--发饰分页特殊处理
		hair = IGame.AppearanceClient:GetHairRecordByIndex(self.m_CurrIndex,self.m_CurHairColor)
		local colors = IGame.AppearanceClient:GetAllHairColorNumber(self.m_CurrIndex,self.m_CurHairColor)
		colorNum = colors[1]
	elseif nType == 1 then
		hair = IGame.AppearanceClient:GetClothAndHairSuitPart(nType,nIndex,self.m_CurHairColor,2)
		if hair.nColorList then
			colorNum = hair.nColorList[1]
		end
	else
		hair = IGame.AppearanceClient:GetSuitPart(nType,nIndex,2)
		if not hair then
			colorNum = tmpCurAppearInfo.nColor
		else
			colorNum = IGame.AppearanceClient:GetDefaultColorNum(hair.nAppearID)			
		end
	end
	
	if self.Vocation == nil then
		local pHero = IGame.EntityClient:GetHero()
		if not pHero then
			return
		end
		self.Vocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)
	end
	
	--预览换装逻辑
	local nWeaponAppRecord = GameHelp:GetDefaultAppearance(EntityBodyPart.RWeaponPart) --.nResID
	local nBodyMeshResID = GameHelp:GetDefaultAppearance(EntityBodyPart.BodyMesh).nResID
	local nFaceMeshResID = GameHelp:GetDefaultAppearance(EntityBodyPart.FaceMesh).nResID
	local nHairMeshResID = GameHelp:GetDefaultAppearance(EntityBodyPart.HairMesh).nResID
	
	if clothes then 
		if clothes.nAppearID > 0 then
			nBodyMeshResID = clothes.nResID
		end
	else
		local curData = IGame.AppearanceClient:GetHeroCurInfoByPart(APPEARANCE_CLOTH_PART_ID)
		if curData then
			if curData.nAppearID > 0 then
				nBodyMeshResID = curData.nResID
			end
		end
	end
	
	if hair then 
		if hair.nAppearID > 0 then
			nHairMeshResID = hair.nResID
		end
	else
		local curData = IGame.AppearanceClient:GetHeroCurInfoByPart(APPEARANCE_HAIR_PART_ID)
		if curData then
			if curData.nAppearID > 0 then
				nHairMeshResID = curData.nResID
			end
		end
	end
	
	if face then 
		if face.nAppearID > 0 then
			nFaceMeshResID = face.nResID
		end
	else
		local curData = IGame.AppearanceClient:GetHeroCurInfoByPart(APPEARANCE_FACIAL_PART_ID)
		if curData then
			if curData.nAppearID > 0 then
				nFaceMeshResID = curData.nResID
			end
		end
	end
	if weapon then 
		if weapon.nAppearID > 0 then
			nWeaponAppRecord = weapon
		end
	else
		local curData = IGame.AppearanceClient:GetHeroCurInfoByPart(APPEARANCE_WEAP_PART_ID)
		if curData then
			if curData.nAppearID > 0 then
				nWeaponAppRecord = curData
			end
		end
	end
--[[	if ride then 
		if ride.nAppearID > 0 then
			nHorseMeshResID = ride.nResID
		end
	else
		local curData = IGame.AppearanceClient:GetHeroCurInfoByPart(APPEARANCE_RIDE_PART_ID)
		if curData then
			if curData > 0 then
				nHorseMeshResID = curData.nResID
			end
		end
	end--]]
	
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_DRESS )
	if not entityView then return end
	if nWeaponAppRecord and nWeaponAppRecord.nAppearID > 0 then
		if nWeaponAppRecord.nLeftWeapResID and nWeaponAppRecord.nLeftWeapResID > 0 then
			IGame.EntityFactory:SetWeapon(entityView,nWeaponAppRecord.nResID,false,true)
		end
		if nWeaponAppRecord.nRightWeapResID and nWeaponAppRecord.nRightWeapResID > 0 then
			IGame.EntityFactory:SetWeapon(entityView,nWeaponAppRecord.nResID,true,true)
		end
	end
	
	IGame.EntityFactory:SetPartMesh(entityView,EntityBodyPart.BodyMesh,nBodyMeshResID,true)
    IGame.EntityFactory:SetPartMesh(entityView,EntityBodyPart.FaceMesh,nFaceMeshResID,true)
    IGame.EntityFactory:SetPartMesh(entityView,EntityBodyPart.HairMesh,nHairMeshResID,true)
--	IGame.EntityFactory:SetPartMesh(entityView,EntityBodyPart.HorsePart,nHorseMeshResID,true)
	if colorNum then
		local color = Color:New()
		color:FromHexadecimal(colorNum)
		local colorVec3 = Vector3.New(color.r,color.g,color.b)
		entityView:SetVector3(EntityPropertyID.HairColor, colorVec3)
	end
end
--恢复默认， 取消预览
function ExteriroTypeWidget:RecoverSuit()
	HeroDisplayWidgetClass:Recover()--恢复默认
	local scriptNum = table.getn(self.m_DressItemScriptCache)
	--设置当前换装
	if self.m_curTab == 2 then
		if scriptNum > 0 then
			self.m_HairColorItemTable[self.m_CurHairColor]:SetFocus(true)
		end
	else
		if scriptNum > 0 then
			self.m_DressItemScriptCache[self.m_CurrIndex]:SetFocus(true)
		end
	end
end

--放大按钮点击事件
function ExteriroTypeWidget:OnEnlargeBtnClick()
	if not self.CanClick then
		return
	end
	self.CanClick = false
	
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end

	local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)
	
	local camera = HeroDisplayWidgetClass.m_Camera.m_Camera
	local enlargePosition
	
	if self.OriginPos then
		 enlargePosition = APPEARANCE_ROLE_CAMERA_ENLARGE[nVocation]
		 UIFunction.RemoveEventTriggerListener(HeroDisplayWidgetClass.Controls.m_HeroRawImage,EventTriggerType.PointerClick,self.ModelClickEvent)
	else
		enlargePosition = APPEARANCE_ROLE_CAMERA_UNENLARGE[nVocation]
		UIFunction.AddEventTriggerListener(HeroDisplayWidgetClass.Controls.m_HeroRawImage,EventTriggerType.PointerClick,self.ModelClickEvent)
	end
	self.OriginPos = not self.OriginPos
	UIFunction.DOTweenLocalMOVE(camera.gameObject,0.2,enlargePosition)
	rktTimer.SetTimer(self.LateClickCB, 210,1,"self:LateClick()")
end

-------------------------------------------------------------------
-- Toggle 选中项被改变触发事件
-------------------------------------------------------------------
function ExteriroTypeWidget:OnToggleChanged(on, curTabIndex)
	self:SetToggleState(on, curTabIndex)
	
	if self.m_curTab == curTabIndex then 
		return 
	end
	
	self.m_CurrIndex = 1				--切换分页默认选中第一个
	
	--这里切换显示界面
	self:RefeshTogglePage(curTabIndex)			
end




--设置toggle状态
function ExteriroTypeWidget:SetToggleState(on, curTabIndex)
	local config = {
		self.Controls.m_ClothesToggle,	
		self.Controls.m_HairstyleToggle,
		self.Controls.m_MakeupToggle,
		self.Controls.m_WeaponToggle,
		self.Controls.m_ZuoQiToggle,
	}

	if on then 
		config[curTabIndex].transform:Find("ON").gameObject:SetActive(true)
		config[curTabIndex].transform:Find("OFF").gameObject:SetActive(false)
	else		
		config[curTabIndex].transform:Find("ON").gameObject:SetActive(false)
		config[curTabIndex].transform:Find("OFF").gameObject:SetActive(true)
		return
	end
end

-------------------------------------------------------------------
--切换toggle刷新操作,		刷新右边详细信息
-------------------------------------------------------------------
function ExteriroTypeWidget:RefeshTogglePage(curTabIndex)
	if self.m_preTab == curTabIndex then
		return
	end	
	self.m_curTab = curTabIndex
	self.m_preTab = curTabIndex
	
	self:RefreshDressList(curTabIndex)								--刷新右侧时装列表	
	--[[self:RefreshSuitWidget(self.m_curTab,1)				--刷洗左侧套装			默认显示的是第一个
	self:RefreshRightBottom(self.m_curTab,1)--]]
end	

--刷新左侧套装列表
function ExteriroTypeWidget:RefreshSuitWidget(nType,nIndex)
	if self.m_curTab == 1 or self.m_curTab == 2 then return end
	local suitTable = IGame.AppearanceClient:GetSuit(nType, nIndex)
	local itemRecord = 	IGame.AppearanceClient:GetRecordByTypeAndIndex(nType, nIndex)
	if not suitTable then
		self.Controls.m_SuitNameText.text = ""
		self.Controls.m_SuitTimeOutText.text = ""
		return
	end
	local count = table.getn(suitTable)
	self.Controls.m_SuitNameText.text = ""
	
	local serverTime = GetServerTimeSecond()
	local heroPreInfo = IGame.AppearanceClient:GetHeroAppInfo()
	if count > 1 then
		if self.m_PreView then
			if itemRecord.nLimitTime == 0 then
				self.Controls.m_SuitTimeOutText.text = "有效期:永久"
			else
				self.Controls.m_SuitTimeOutText.text = "有效期:" .. tostring(GetDayBySecond(itemRecord.nLimitTime)) .. "天\n"
			end
			self.Controls.m_AppNameText.text = itemRecord.nSuitName
		else
			if itemRecord.nLimitTime == 0 then
				self.Controls.m_SuitTimeOutText.text = "有效期:永久"
			elseif not heroPreInfo[itemRecord.nAppearID] or serverTime > heroPreInfo[itemRecord.nAppearID].nDeadLine then
				--过期或者没有买过，显示表里的数据
				self.Controls.m_SuitTimeOutText.text = "有效期:" .. tostring(GetDayBySecond(itemRecord.nLimitTime)) .. "天\n"
			else
				--没有过期
				local useDate = heroPreInfo[itemRecord.nAppearID].nDeadLine
				local str = ""
				if useDate > 0 then
					local date = os.date("*t",useDate)
					str = date.year.."-"..date.month.."-"..date.day.."\n"..date.hour..":"..date.min..":"..date.sec .. " 过期"
				end
				self.Controls.m_SuitTimeOutText.text = str
			end
			self.Controls.m_AppNameText.text = itemRecord.szAppearName
		end
		
		for i,data in pairs(suitTable) do
			if i < count then
				self.Controls.m_SuitNameText.text = self.Controls.m_SuitNameText.text .. data.szAppearName .. "\n"
			else
				self.Controls.m_SuitNameText.text = self.Controls.m_SuitNameText.text .. data.szAppearName
			end
		end
	else
		if itemRecord.nLimitTime == 0 then
			self.Controls.m_SuitTimeOutText.text = "有效期:永久"
		else
			self.Controls.m_SuitTimeOutText.text = "有效期" .. tostring(GetDayBySecond(itemRecord.nLimitTime)) .. "天\n"
		end
		self.Controls.m_AppNameText.text = itemRecord.szAppearName
		self.Controls.m_SuitNameText.text = itemRecord.nDes
	end
	
	if not self.m_PreView then
		self.Controls.m_SuitNameText.text = itemRecord.nDes
		self.Controls.m_SuitBuyBtn.gameObject:SetActive(false)
	else
		if count > 1 then
			self.Controls.m_SuitBuyBtn.gameObject:SetActive(true)
		end
	end
end

--衣服、发型分页刷新套装显示
function ExteriroTypeWidget:RefreshSuit(nID)
	if self.m_curTab ~= 1 and self.m_curTab ~= 2 then 
		return
	end
	local count
	local suitTable = IGame.AppearanceClient:GetSuitByID(nID)
	local itemRecord = IGame.AppearanceClient:GetRecordByID(nID)
	if not suitTable then 
		self.Controls.m_SuitNameText.text = ""
		self.Controls.m_SuitTimeOutText.text = ""
		count = 0
	else
		count = table.getn(suitTable)
	end

	self.Controls.m_SuitNameText.text = ""
	
	local serverTime = GetServerTimeSecond()
	local heroPreInfo = IGame.AppearanceClient:GetHeroAppInfo()
	if count > 1 then
		if self.m_PreView then
			if itemRecord.nLimitTime == 0 then
				self.Controls.m_SuitTimeOutText.text = "有效期:永久"
			else
				self.Controls.m_SuitTimeOutText.text = "有效期" .. tostring(GetDayBySecond(itemRecord.nLimitTime)) .. "天\n"
			end
			self.Controls.m_AppNameText.text = itemRecord.nSuitName
		else
			if itemRecord.nLimitTime == 0 then
				self.Controls.m_SuitTimeOutText.text = "有效期:永久"
			elseif not heroPreInfo[itemRecord.nAppearID] or serverTime > heroPreInfo[itemRecord.nAppearID].nDeadLine then
				--过期或者没有买过，显示表里的数据
				self.Controls.m_SuitTimeOutText.text = "有效期" .. tostring(GetDayBySecond(itemRecord.nLimitTime)) .. "天\n"
			else
				--没有过期
				local useDate = heroPreInfo[itemRecord.nAppearID].nDeadLine
				local str = ""
				if useDate > 0 then
					local date = os.date("*t",useDate)
					str = date.year.."-"..date.month.."-"..date.day.."\n"..date.hour..":"..date.min..":"..date.sec .. " 过期"
				end
				self.Controls.m_SuitTimeOutText.text = str
			end
			self.Controls.m_AppNameText.text = itemRecord.szAppearName
		end
			
			for i,data in pairs(suitTable) do
				if i < count then
					self.Controls.m_SuitNameText.text = self.Controls.m_SuitNameText.text .. data.szAppearName .. "\n"
				else
					self.Controls.m_SuitNameText.text = self.Controls.m_SuitNameText.text .. data.szAppearName
				end
			end
	else
		if itemRecord.nLimitTime == 0 then
			self.Controls.m_SuitTimeOutText.text = "有效期:永久"
		else
			self.Controls.m_SuitTimeOutText.text = "有效期" .. tostring(GetDayBySecond(itemRecord.nLimitTime)) .. "天\n"
		end
		self.Controls.m_SuitNameText.text = itemRecord.szAppearName
		self.Controls.m_AppNameText.text = itemRecord.szAppearName
	end
	
	if not self.m_PreView then
		self.Controls.m_SuitNameText.text = itemRecord.nDes
		self.Controls.m_SuitBuyBtn.gameObject:SetActive(false)
	else
		if count > 1 then
			self.Controls.m_SuitBuyBtn.gameObject:SetActive(true)
		end
	end
end

--刷新右下侧显示信息
function ExteriroTypeWidget:RefreshRightBottom(nType,nIndex)
	if nType == 1 then
		self.Controls.m_MiddleWidget.gameObject:SetActive(true)
		UIFunction.SetImageSprite(self.Controls.m_MiddleWidgetTitleTextImg,TitlePath[1],function() self.Controls.m_MiddleWidgetTitleTextImg:SetNativeSize() end )
		self:InitHairColorItem(nIndex, 1)	
	elseif nType == 2 then
		self.Controls.m_MiddleWidget.gameObject:SetActive(true)
		UIFunction.SetImageSprite(self.Controls.m_MiddleWidgetTitleTextImg,TitlePath[2],function() self.Controls.m_MiddleWidgetTitleTextImg:SetNativeSize() end)
		self:InitHairColorItem(nIndex, 2)					--创建发色Item
	else
		self.Controls.m_MiddleWidget.gameObject:SetActive(false)
	end	
--	self:RefreshOptionBtn(nType, nIndex)
end

--由于异步设置，添加此回调
function ExteriroTypeWidget:SetOptionBtnImgNative()
	self.Controls.m_OptionBtnImg:SetNativeSize()
end

--刷新右下侧按钮显示文字, 设置按钮相关图片，和不同的点击事件
function ExteriroTypeWidget:RefreshOptionBtn(nType, nIndex)
	local itemRecord 
	if nType == 2 then 
		itemRecord = IGame.AppearanceClient:GetHairRecordByIndex(nIndex, self.m_CurHairColor)
	elseif nType == 1 then
		itemRecord = IGame.AppearanceClient:GetClothesRecordByIndex(nIndex, self.m_CurHairColor)
	else
		itemRecord = IGame.AppearanceClient:GetRecordByTypeAndIndex(nType, nIndex)
	end

	if itemRecord == nil then 
		UIManager.TipsActorUnderWindow:AddSystemTips("没有获得对应时装")
		self.Controls.m_OptionBtn.gameObject:SetActive(false)
		return
	end
	
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return nil
	end	
	local haveDiamond = pHero:GetActorYuanBao()
	
	self.Controls.m_OptionBtn.gameObject:SetActive(true)
	--置灰还原
--	UIFunction.SetImgComsGray(self.Controls.m_OptionBtnParentImg.gameObject,false)
	self.Controls.m_OptionBtn.interactable = true
	
	self.Controls.m_BottomCostText.color = Color.New(1,1,1)			--恢复成白色的
	local haveBuy = IGame.AppearanceClient:HaveBuy(itemRecord.nAppearID) 

	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		uerror("packetPart is nil")
		return
	end
	
	if itemRecord.nDefault == 1 then
		self.Controls.m_DesInfoParent.gameObject:SetActive(false)
		if IGame.AppearanceClient:IsEquip(itemRecord.nAppearID) then 							--已经穿上
				if nType == 5 then 
					UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg,ButtonPath[5],self.SetOptionBtnNativeCB)				--下马
				else
					UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg,ButtonPath[7],self.SetOptionBtnNativeCB)				--已穿上
					UIFunction.SetImgComsGray(self.Controls.m_OptionBtnParentImg.gameObject,true)
					self.Controls.m_OptionBtn.interactable = false
				end
		else															--没有穿上
				UIFunction.SetImgComsGray(self.Controls.m_OptionBtnParentImg.gameObject,false)
				if nType == 5 then 
					UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg,ButtonPath[4],self.SetOptionBtnNativeCB)				--上马
				else
					UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg,ButtonPath[2],self.SetOptionBtnNativeCB)				--穿上
				end
		end
		if nType == 2 then
			self.Controls.m_ColorConfigBtn.gameObject:SetActive(true)
		end
		return
	end
	
	if haveBuy then		--已经购买
		self.Controls.m_DesInfoParent.gameObject:SetActive(false)
	    local heroInfo = IGame.AppearanceClient:GetHeroCurAppearInfo()
		local heroPreInfo = IGame.AppearanceClient:GetHeroAppInfo()
		--获取服务器时间
		local serverTime = GetServerTimeSecond()
		if heroPreInfo[itemRecord.nAppearID].nDeadLine > 0 and heroPreInfo[itemRecord.nAppearID].nDeadLine < serverTime then		--0表示永久外观
			if itemRecord.nCostGoodsID and itemRecord.nCostGoodsID > 0 then
				UIFunction.SetImgComsGray(self.Controls.m_OptionBtnParentImg.gameObject,false)
				local haveNum = packetPart:GetGoodNum(itemRecord.nCostGoodsID)
				if haveNum < itemRecord.nCostGoodsNum then
					UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg,ButtonPath[8],self.SetOptionBtnNativeCB)			--道具不足，获取材料
				else
					UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg,ButtonPath[6],self.SetOptionBtnNativeCB)			--续费
				end
			else
				UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg,ButtonPath[6],self.SetOptionBtnNativeCB)
			end
				
			
			self.Controls.m_DesInfoParent.gameObject:SetActive(true)					--续费
			if itemRecord.nDiamondCost == nil or itemRecord.nDiamondCost == 0 then
				local goodsInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, itemRecord.nCostGoodsID)
				UIFunction.SetImageSprite(self.Controls.m_CostIcon,AssetPath.TextureGUIPath..goodsInfo.lIconID1)
				self.Controls.m_BottomCostText.text = goodsInfo.szName .. tostring(itemRecord.nCostGoodsNum) .. "个"
				self.Controls.m_CostIcon.gameObject:SetActive(false)
			else
				self.Controls.m_CostIcon.gameObject:SetActive(true)
				UIFunction.SetImageSprite(self.Controls.m_CostIcon,AssetPath_CurrencyIcon[1])	--消耗钻石
				self.Controls.m_BottomCostText.text = tostring(itemRecord.nDiamondCost)
			end
			if self.m_curTab == 2 then
				self.Controls.m_ColorConfigBtn.gameObject:SetActive(false)
			end
		else
			if self.m_curTab == 2 then
				self.Controls.m_ColorConfigBtn.gameObject:SetActive(true)
			else
				
			end
			if IGame.AppearanceClient:IsEquip(itemRecord.nAppearID) then 							--已经穿上
				if nType == 5 then 
					UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg,ButtonPath[5],self.SetOptionBtnNativeCB)				--下马
				else
					UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg,ButtonPath[7],self.SetOptionBtnNativeCB)				--已穿上
					UIFunction.SetImgComsGray(self.Controls.m_OptionBtnParentImg.gameObject,true)
					self.Controls.m_OptionBtn.interactable = false
				end
			else															--没有穿上
				UIFunction.SetImgComsGray(self.Controls.m_OptionBtnParentImg.gameObject,false)
				if nType == 5 then 
					UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg,ButtonPath[4],self.SetOptionBtnNativeCB)				--上马
				else
					UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg,ButtonPath[2],self.SetOptionBtnNativeCB)				--穿上
				end
			end
		end
	else
		self.Controls.m_DesInfoParent.gameObject:SetActive(true)
		UIFunction.SetImgComsGray(self.Controls.m_OptionBtnParentImg.gameObject,false)
		if itemRecord.nDiamondCost == nil or itemRecord.nDiamondCost == 0 then
			if itemRecord.nCostGoodsID and itemRecord.nCostGoodsID > 0 then
				local haveNum = packetPart:GetGoodNum(itemRecord.nCostGoodsID)
				if haveNum < itemRecord.nCostGoodsNum then
					UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg,ButtonPath[8],self.SetOptionBtnNativeCB)			--道具不足，获取材料
				else
					UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg,ButtonPath[3],self.SetOptionBtnNativeCB)
				end
			else
				UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg,ButtonPath[3],self.SetOptionBtnNativeCB)
			end
			
			local goodsInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, itemRecord.nCostGoodsID)
			if goodsInfo then
				UIFunction.SetImageSprite(self.Controls.m_CostIcon,AssetPath.TextureGUIPath..goodsInfo.lIconID1)
			end
			
			local haveNum = packetPart:GetGoodNum(itemRecord.nCostGoodsID)
			if haveNum < itemRecord.nCostGoodsNum then
				self.Controls.m_BottomCostText.text = goodsInfo.szName .. "<color=#FF0000>"..tostring(itemRecord.nCostGoodsNum).."</color>个"
			else
				self.Controls.m_BottomCostText.text = goodsInfo.szName .. tostring(itemRecord.nCostGoodsNum) .. "个"
			end
			
			self.Controls.m_CostIcon.gameObject:SetActive(false)
		else
			self.Controls.m_CostIcon.gameObject:SetActive(true)
			UIFunction.SetImageSprite(self.Controls.m_CostIcon,AssetPath_CurrencyIcon[1])	--消耗钻石
			self.Controls.m_BottomCostText.text = tostring(itemRecord.nDiamondCost)
			if haveDiamond < itemRecord.nDiamondCost then
				self.Controls.m_BottomCostText.color = Color.New(1,0,0)
			end
			UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg,ButtonPath[3],self.SetOptionBtnNativeCB)				--解锁
		end
		if self.m_curTab == 2 then
			self.Controls.m_ColorConfigBtn.gameObject:SetActive(false)
		end	
	end
end

-------------------------------------------------------------------
-- 设置默认显示页面
-------------------------------------------------------------------
function ExteriroTypeWidget:SetDefaultTab(curTabIndex)	
--[[	if self.m_preTab == curTabIndex then
		return
	end--]]
	
	if self.m_preTab > 0 then 
		self:SetToggleState(false, self.m_preTab)
	end
	
	if curTabIndex == 0 then
		curTabIndex = 1
	end
	if not self.toggleCtl[curTabIndex].isOn then
		self.toggleCtl[curTabIndex].isOn	= true
	end
	self:SetToggleState(true, curTabIndex)
	
	self:RefeshTogglePage(curTabIndex)
end	

--创建发饰item
function ExteriroTypeWidget:InitHairColorItem(nIndex, nType)
	local tableNum = table.getn(self.m_HairColorItemTable)
	if tableNum > 0 then
		--销毁之前的
		for i, data in pairs(self.m_HairColorItemTable) do
			data:Destroy()
		end
	end

	self.m_HairColorItemTable = {}
	
	if nType == 1 then
		self.Controls.m_ColorConfigBtn.gameObject:SetActive(false)
	elseif nType == 2 then
		self.Controls.m_ColorConfigBtn.gameObject:SetActive(false)
	else
		self.Controls.m_ColorConfigBtn.gameObject:SetActive(false)
	end
	
	--获取服务器时间
	local serverTime = GetServerTimeSecond()
	local heroPreInfo = IGame.AppearanceClient:GetHeroAppInfo()
	
	local groupTable, groupRecord = IGame.AppearanceClient:GetRecordTableByIndex(nType,nIndex)					--获得发型组数量
	
	if nType == 1 or nType == 2 then
		if not groupTable then return end
	end
	
	local groupNum = table.getn(groupTable)
	
	local colorList = IGame.AppearanceClient:GetColorListByTypeAndIndex(nType,nIndex)
	
	for i = 1,groupNum,1 do	
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.HairColorItem ,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_ColorList, false)
			
			local dataRecord = groupTable[i]
			
			local item = HairColorItemClass:new({})
			item:Attach(obj)
			item:SetToggleGroup(self.Controls.HairColorToggleGroup)
			item:SetAppID(dataRecord.nAppearID)
			item:SetIndex(i)
			if nType == 2 then 
				item:SetSelectCallback(self.OnHairColorSelectedCB)
			elseif nType == 1 then
				item:SetSelectCallback(self.OnClothesColorSelectedCB)
			end
			item:SetCustom(false)
			
			if not heroPreInfo[dataRecord.nAppearID] then
				item:SetLock(true)			--没有买过
			else
				if heroPreInfo[dataRecord.nAppearID].nDeadLine == 0 then 		--永久的，不会过期
					item:SetLock(false)
				else
					if heroPreInfo[dataRecord.nAppearID].nDeadLine > serverTime then	--没有过期
						item:SetLock(false)
					else
						--过期了
						item:SetLock(true)
					end
				end
			end
			
			if colorList[i] ~= nil then
--				local color = Color.New(colorList[i].x, colorList[i].y, colorList[i].z)
--				item:SetColor(color)
				item:SetColor(colorList[i])
			end
			
			if i == 1 then 
				self.m_CurHairColor = 1
				item:SetFocus(true)
			end
			
			--加到缓存表中
			table.insert(self.m_HairColorItemTable,item)
		end , i , AssetLoadPriority.GuiNormal )
	end
end


--发饰item选中回调
function ExteriroTypeWidget:OnHairColorSelected(nIndex)
	self.m_CurHairColor = nIndex
	local record = IGame.AppearanceClient:GetHairRecordByIndex(self.m_CurrIndex, nIndex)
	local haveBuy = IGame.AppearanceClient:HaveBuy(record.nAppearID)
	local heroPreInfo = IGame.AppearanceClient:GetHeroAppInfo()
	if havaBuy then
		local serverTime = GetServerTimeSecond()
		if heroPreInfo[record.nAppearID].nDeadLine > 0 and heroPreInfo[record.nAppearID].nDeadLine > serverTime then
			self.Controls.m_ColorConfigBtn.gameObject:SetActive(true)
		end
	else
		self.Controls.m_ColorConfigBtn.gameObject:SetActive(false)
	end
	--=======================================================
	self:RefreshHairStyle(nIndex)
	self:RefreshSuit(record.nAppearID)
	self:RefreshOptionBtn(self.m_curTab, self.m_CurrIndex)
	--=====================================================
end

--衣服item选中回调，和上面成一个方法也可以，这里扩展的写成了两个
function ExteriroTypeWidget:OnClothesSelected(nSubIndex)
	self.m_CurHairColor = nSubIndex				--这里用发饰色变量缓存索引了，没用新的
	local record = IGame.AppearanceClient:GetClothesRecordByIndex(self.m_CurrIndex, nSubIndex)
	--==========================================================
	self:RefreshClothes(nSubIndex)
	self:RefreshSuit(record.nAppearID)
	self:RefreshOptionBtn(self.m_curTab, self.m_CurrIndex)
end

--更新衣服，
function ExteriroTypeWidget:RefreshClothes(nindex)
	local record = IGame.AppearanceClient:GetClothesRecordByIndex(self.m_CurrIndex, nindex)
	local heroInfo = IGame.AppearanceClient:GetHeroCurAppearInfo()

	if self.m_PreView then
		self:PrefiewSuit()
	else
		HeroDisplayWidgetClass:Recover()	--复原
		
		local vocation = IGame.AppearanceClient:GetVocation()
		local resID = GameHelp:GetDefaultAppearance(EntityBodyPart.BodyMesh).nResID
		--[[local resID = gVocationDefaultBodyMeshCfg[vocation].BodyMeshResID--]]
		
		local curData = IGame.AppearanceClient:GetHeroCurInfoByPart(APPEARANCE_CLOTH_PART_ID)
		if curData then
			if curData.nAppearID > 0 then
				resID = curData.nResID
			end
		end
		
		if record and record.nAppearID > 0 then
			local resRecord = IGame.rktScheme:GetSchemeInfo(CONFIGRESOURCE, record.nResID)
			if resRecord and resRecord.szHighModel and resRecord.szHighModel ~= "" then
				resID = record.nResID
			end
		end
		local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_DRESS )
		if not entityView then return end
		IGame.EntityFactory:SetPartMesh(entityView,EntityBodyPart.BodyMesh,resID,true)
		local hairColor = heroInfo.nColor
		local color = Color:New()
		color:FromHexadecimal(hairColor)
		local colorVec = Vector3.New(color.r,color.g,color.b)
		entityView:SetVector3(EntityPropertyID.HairColor, colorVec)
	end
end

--更新发饰色,本质是头发模型						
function ExteriroTypeWidget:RefreshHairStyle(nIndex)
	local record = IGame.AppearanceClient:GetHairRecordByIndex(self.m_CurrIndex, nIndex)
	local heroInfo = IGame.AppearanceClient:GetHeroCurAppearInfo()

	if self.m_PreView then
		self:PrefiewSuit()
	else
		HeroDisplayWidgetClass:Recover()	--复原

		local vocation = IGame.AppearanceClient:GetVocation()
		local resID = GameHelp:GetDefaultAppearance(EntityBodyPart.HairMesh).nResID
		--[[local resID = gVocationDefaultHairMeshCfg[vocation].HairMeshResID--]]
		
		local curData = IGame.AppearanceClient:GetHeroCurInfoByPart(APPEARANCE_HAIR_PART_ID)
		if curData then
			if curData.nAppearID > 0 then
				resID = curData.nResID
			end
		end
		--[[if heroInfo.nHairID > 0 then
			resID = heroInfo.nHairID
		end--]]
		
		if record and record.nAppearID > 0 then
			local resRecord = IGame.rktScheme:GetSchemeInfo(CONFIGRESOURCE, record.nResID)
			if resRecord and resRecord.szHighModel and resRecord.szHighModel ~= "" then
				resID = record.nResID
			end
		end
		
		
		local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_DRESS )
		if not entityView then return end
		
		IGame.EntityFactory:SetPartMesh(entityView,EntityBodyPart.HairMesh,resID,true)
		local hairDefaultColorTable = IGame.AppearanceClient:GetAllHairColorNumber(self.m_CurrIndex, nIndex)
		local hairColor = hairDefaultColorTable[1]
		
		local hexColor = string.format( "%06x" , hairColor )
		local color = Color:New()
		color:FromHexadecimal(hairColor)
		local colorVec = Vector3.New(color.r,color.g,color.b)
		entityView:SetVector3(EntityPropertyID.HairColor, colorVec)
	end
end

--创建时装列表
function ExteriroTypeWidget:RefreshDressList(nCurTabIndex)
	
	local tableNum = table.getn(self.m_DressItemScriptCache) 
	if tableNum > 0 then
		--销毁之前的
		for i, data in pairs(self.m_DressItemScriptCache) do
			data:Destroy()
		end
	end
	self.m_DressItemScriptCache = {}

	self.m_nCount = IGame.AppearanceClient:GetInfosCountByPartID(self.m_curTab)
	if self.m_nCount < 1 then		--表里没配，就返回
		return 
	end
	
	local serverTime = GetServerTimeSecond()
	local heroPreInfo = IGame.AppearanceClient:GetHeroAppInfo()
	
	for	i = 1,self.m_nCount do 
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.DressItemCell ,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_Grid)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = ItemCellClass:new({})
			item:Attach(obj)
			item:SetToggleGroup(self.Controls.ItemToggleGroup)
			item:SetSelectCallback(self.OnItemCellSelectedCB)
			
			item:SetItemCellInfo(self.m_curTab,i)
			
			local lock = true

				if self.m_curTab == 1 or self.m_curTab == 2 then
					local dressTable = IGame.AppearanceClient:GetRecordTableByIndex(self.m_curTab,i)
					for i,data in pairs(dressTable) do
						--[[if heroPreInfo[data.nAppearID] then
							if data.nLimitTime == 0 then
								lock = false
								break
							elseif heroPreInfo[data.nAppearID].nDeadLine > serverTime then
								lock = false
								break
							end
						end--]]
					end
					lock = false				--衣服，发饰，在下面显示锁头
				else
					local record = IGame.AppearanceClient:GetRecordByTypeAndIndex(self.m_curTab, i)
					if record.nDefault == 1 then
						lock = false
					else
						if heroPreInfo[record.nAppearID] then
							if record.nLimitTime == 0 then
								lock = false
							elseif heroPreInfo[record.nAppearID].nDeadLine > serverTime then
								lock = false
							end
						end
					end
				end

			
			item:SetLock(lock)
			item:SetFocus(false)
			if i == 1 then
				item:SetFocus(true)
				self.m_CurrIndex = 1
			end
			table.insert(self.m_DressItemScriptCache,i,item)	
		end , i , AssetLoadPriority.GuiNormal )
	end
end

-- 时装item 被选中
function ExteriroTypeWidget:OnItemCellSelected(nType,index)	
	
	if nType == 5 then  						---测试用，坐骑暂时不处理，后期处理
		return
	end
	
	if nil == index or nil == nType then
		return   
	end
	--[[if index == self.m_CurrIndex and nType == self.m_curTab then
		return
	end--]]

	self.m_CurrIndex = index
		
	self:RefreshSuitWidget(nType,index)				--刷新套装显示
	if nType ~= 1 and nType ~= 2 then
		self:RefreshOptionBtn(nType,index)				--刷新右下侧按钮显示文字
	end
	self:RefreshRightBottom(nType,index)
	
	if self.m_PreView then
		if self.m_curTab == 2 or self.m_curTab == 1 then
			return --发饰Item点击已经处理过预览了
		end
		self:PrefiewSuit(nType, index)				    --刷新套装预览
	else
		local vocation = IGame.AppearanceClient:GetVocation()
		local heroInfo = IGame.AppearanceClient:GetHeroCurAppearInfo()
		
		if nType ~= 2 and nType ~= 1 then
			HeroDisplayWidgetClass:Recover()	--复原

			--普通换装逻辑
			local resID
			local record = IGame.AppearanceClient:GetRecordByTypeAndIndex(nType, index)
			
			local curID
			
			if nType == 1 then
				resID = GameHelp:GetDefaultAppearance(EntityBodyPart.BodyMesh).nResID
				curID = heroInfo.nClothID
			elseif nType == 3 then
				resID = GameHelp:GetDefaultAppearance(EntityBodyPart.FaceMesh).nResID
				curID = heroInfo.nFacialID
			elseif nType == 4 then
				resID = GameHelp:GetDefaultAppearance(EntityBodyPart.RWeaponPart)		--.nResID
				curID = heroInfo.nWaepID
			elseif nType == 5 then 
			end
			
			if curID and curID > 0 then
				if nType == 4 then
					resID = curID
				else
					resID = IGame.rktScheme:GetSchemeInfo(APPEARANCE_CSV, curID).nResID
				end
			end
			
			if record and record.nAppearID > 0 then
				if nType ~= 4 then
					resID = record.nResID
				elseif nType == 4 then
					resID = record
				end
			end
			
			local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_DRESS )
			if not entityView then return end
			
			if nType == 4 then			--武器resID存储的是App记录
				if resID.nLeftWeapResID and resID.nLeftWeapResID > 0 then
					IGame.EntityFactory:SetWeapon(entityView,resID.nResID,false,true)
				end
				if resID.nRightWeapResID and resID.nRightWeapResID > 0 then
					IGame.EntityFactory:SetWeapon(entityView,resID.nResID,true,true)
				end
			else
				IGame.EntityFactory:SetPartMesh(entityView,BodyPart[nType],resID,true)
			end
		end
	end
end

--OptionBtn点击事件
function ExteriroTypeWidget:OnOptionBtnClick()
	local nType = self.m_curTab
	local nIndex = self.m_CurrIndex
	local nSubIndex = self.m_CurHairColor
	local itemRecord = 	IGame.AppearanceClient:GetRecordByTypeAndIndex(nType, nIndex)
	local heroInfo = IGame.AppearanceClient:GetHeroCurAppearInfo()
	
	local itemRecord 
	if nType == 2 then 
		itemRecord = IGame.AppearanceClient:GetHairRecordByIndex(nIndex, self.m_CurHairColor)
	elseif nType == 1 then
		itemRecord = IGame.AppearanceClient:GetClothesRecordByIndex(nIndex, self.m_CurHairColor)
	else
		itemRecord = IGame.AppearanceClient:GetRecordByTypeAndIndex(nType, nIndex)
	end	
	
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return nil
	end	

	if itemRecord.nDefault == 1 then
		if IGame.AppearanceClient:IsEquip(itemRecord.nAppearID) then 							--已经穿上，不做处理
			return
		else															--没有穿上,发送穿上请求
			if nType == 2 then
				local colors = IGame.AppearanceClient:GetAllHairColorNumber(nIndex, self.m_CurHairColor)
				IGame.AppearanceClient:EquipAppear(itemRecord.nAppearID,colors[1])										--穿上外观
			else
				IGame.AppearanceClient:EquipAppear(itemRecord.nAppearID,0)	
			end
		end
		return
	end

	local packetPart = IGame.EntityClient:GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then return end
	
	local heroLevel = pHero:GetNumProp(CREATURE_PROP_LEVEL)
	if IGame.AppearanceClient:HaveBuy(itemRecord.nAppearID) then		--已经购买
		local heroPreInfo = IGame.AppearanceClient:GetHeroAppInfo()
		--获取服务器时间
		local serverTime = GetServerTimeSecond()
		if heroPreInfo[itemRecord.nAppearID].nDeadLine > 0 and heroPreInfo[itemRecord.nAppearID].nDeadLine < serverTime then
			--续费
			if itemRecord.nDiamondCost and itemRecord.nDiamondCost > 0 then
				if not self:HaveEnoughDiamond(itemRecord.nDiamondCost) then
					UIManager.TipsActorUnderWindow:AddSystemTips("钻石不足，无法续费")
					return
				elseif itemRecord.nCostGoodsID and itemRecord.nCostGoodsID > 0 then
					local goods = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, itemRecord.nCostGoodsID)
					if not self:HaveEnoughGoods(itemRecord.nCostGoodsID, itemRecord.nCostGoodsNum) then
						UIManager.TipsActorUnderWindow:AddSystemTips(goods.szName.."不足，无法解锁")
						return
					end
				else
					--[[return--]]
				end
			end
			IGame.AppearanceClient:ReUnLockAppear(itemRecord.nAppearID)										--续费请求
		else		--没有过期
			if IGame.AppearanceClient:IsEquip(itemRecord.nAppearID) then 							--已经穿上，不做处理
				return
			else															--没有穿上,发送穿上请求
				if nType == 2 then
					local colors = IGame.AppearanceClient:GetAllHairColorNumber(nIndex, self.m_CurHairColor)
					IGame.AppearanceClient:EquipAppear(itemRecord.nAppearID,colors[1])										--穿上外观
				else
					IGame.AppearanceClient:EquipAppear(itemRecord.nAppearID,0)	
				end
			end
		end
	else
		--没有达到购买等级
		if heroLevel < itemRecord.nNeedLevel then
			UIManager.TipsActorUnderWindow:AddSystemTips("购买等级不足，无法购买")
			return
		end
		
		--没有买过,弹出提示框提示是否购买
		local costStr = ""
		local confirmCB
		local showDialog =  false
		if itemRecord.nDiamondCost and itemRecord.nDiamondCost > 0 then
			local haveDiamond = pHero:GetActorYuanBao()
			if haveDiamond >= itemRecord.nDiamondCost then
				costStr = "是否花费".. itemRecord.nDiamondCost .."钻石解锁该外观"
				confirmCB = self.OnUnLockCurAppCB
			else
				costStr = "钻石不足，是否前往充值"
				confirmCB = self.GODepositCB
			end
			showDialog =  true
		else
			if itemRecord.nCostGoodsID and itemRecord.nCostGoodsID > 0 then
				local haveNum = packetPart:GetGoodNum(itemRecord.nCostGoodsID)
				if haveNum >= itemRecord.nCostGoodsNum then
					local goods = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, itemRecord.nCostGoodsID)
					costStr = "是否花费".. itemRecord.nCostGoodsNum .. goods.szName .."解锁该外观"
					confirmCB = self.OnUnLockCurAppCB
					showDialog =  true
				else
					self:GetGoods(itemRecord.nCostGoodsID)				--材料不足，弹出获取材料界面
				end
			else
				--可以给出提示信息
			end	
		end
		if showDialog then
			local data = {
				content = costStr,
				confirmCallBack = confirmCB,
			}
			UIManager.ConfirmPopWindow:ShowDiglog(data)
		end
	end
end

--刷新衣服，发饰Item区域
function ExteriroTypeWidget:RefreshItem(nID)
	if self.m_curTab ~= 1 and self.m_curTab ~= 2 then
		return
	end

	for i,data in pairs(self.m_HairColorItemTable) do
		if data.m_AppID == nID then
			data:SetLock(false)
			break
		end
	end
end
--刷新外观列表item显示, 解锁
function ExteriroTypeWidget:RefreshDressItem(nID)
	for i, data in pairs(self.m_DressItemScriptCache) do
		if self.m_curTab == 1 or self.m_curTab == 2 then 
			local lock = true
			local tmpTable = data.m_IDTable
			for i, data in pairs(tmpTable) do
				if data == nID then 
					lock = false
				end
			end
			if not lock then
				data:SetLock(false)
			end
		else
			if data.m_DressID == nID then
				data:SetLock(false)
			end
		end
	end
end

--获取材料，弹出获取材料界面
function ExteriroTypeWidget:GetGoods(nGoodsID)
	local subInfo = {
		bShowBtnType	= 2, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
	}
	UIManager.GoodsTooltipsWindow:SetGoodsInfo(nGoodsID, subInfo )
end

--确认面板，跳转到充值界面
function ExteriroTypeWidget:GODeposit()
	UIManager.ShopWindow:ShowShopWindow(3)
end

--解锁单件时装，确认面板回调
function ExteriroTypeWidget:OnUnLockCurApp()
	local itemRecord 
	if self.m_curTab == 2 then 
		itemRecord = IGame.AppearanceClient:GetHairRecordByIndex(self.m_CurrIndex, self.m_CurHairColor)
	elseif self.m_curTab == 1 then
		itemRecord = IGame.AppearanceClient:GetClothesRecordByIndex(self.m_CurrIndex, self.m_CurHairColor)
	else
		itemRecord = IGame.AppearanceClient:GetRecordByTypeAndIndex(self.m_curTab, self.m_CurrIndex)
	end
	if itemRecord.nDiamondCost and itemRecord.nDiamondCost > 0 then
		
		if not self:HaveEnoughDiamond(itemRecord.nDiamondCost) then
			UIManager.TipsActorUnderWindow:AddSystemTips("钻石不足，无法解锁")
			return
		end
	elseif itemRecord.nCostGoodsID and itemRecord.nCostGoodsID > 0 then
		local goods = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, itemRecord.nCostGoodsID)
		if not self:HaveEnoughGoods(itemRecord.nCostGoodsID, itemRecord.nCostGoodsNum) then
			UIManager.TipsActorUnderWindow:AddSystemTips(goods.szName.."不足，无法解锁")
			return
		end
	else
		return
	end
	
	IGame.AppearanceClient:UnLockAppear(itemRecord.nAppearID)
end

--判断是否有足够的钻石
function ExteriroTypeWidget:HaveEnoughDiamond(num)
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return false
	end	
	local haveNum = pHero:GetActorYuanBao()
	if num > haveNum then
		return false
	else
		return true
	end
end

--判断背包是否有足够的物品
function ExteriroTypeWidget:HaveEnoughGoods(nGoodsID,num)
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return false
	end	
	local packetPart = pHero:GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return false
	end

	local haveNum = packetPart:GetGoodNum(nGoodsID)
	
	if haveNum >= num then
		return true
	else
		return false
	end
end

--服务器购买套装返回信息，刷新界面
function ExteriroTypeWidget:BuySuitCallBack(nListID)
	if nListID == nil then return end
	self:RefreshOptionBtn(self.m_curTab, self.m_CurrIndex)	
	for i,data in pairs(nListID) do 
		self:RefreshItem(data)
		self:RefreshDressItem(data)
	end
	
	if self.m_curTab == 2 then
		local curRecord = IGame.AppearanceClient:GetHairRecordByIndex(self.m_CurrIndex, self.m_CurHairColor) --防止网络延迟引起的非正常刷新
		self:RefreshSuit(curRecord.nAppearID)
	elseif self.m_curTab == 1 then
		local curRecord = IGame.AppearanceClient:GetClothesRecordByIndex(self.m_CurrIndex, self.m_CurHairColor)
		self:RefreshSuit(curRecord.nAppearID)
	else
		self:RefreshSuitWidget(self.m_curTab, self.m_CurrIndex)
	end
end

--解锁外观返回
function ExteriroTypeWidget:UnLockAppCallBack(nAppID)
	if nAppID == nil then return end
	self:RefreshOptionBtn(self.m_curTab, self.m_CurrIndex)		
	self:RefreshItem(nAppID)
	self:RefreshDressItem(nAppID)
	if self.m_curTab == 2 then
		local curRecord = IGame.AppearanceClient:GetHairRecordByIndex(self.m_CurrIndex, self.m_CurHairColor) --防止网络延迟引起的非正常刷新
		self:RefreshSuit(curRecord.nAppearID)
	elseif self.m_curTab == 1 then
		local curRecord = IGame.AppearanceClient:GetClothesRecordByIndex(self.m_CurrIndex, self.m_CurHairColor)
		self:RefreshSuit(curRecord.nAppearID)
	else
		self:RefreshSuitWidget(self.m_curTab, self.m_CurrIndex)
	end
end
--穿上装备返回
function ExteriroTypeWidget:EquipAppCallBack(nID)
	self:RefreshOptionBtn(self.m_curTab, self.m_CurrIndex)
end

return ExteriroTypeWidget