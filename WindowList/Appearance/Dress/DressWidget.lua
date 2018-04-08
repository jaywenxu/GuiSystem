--/******************************************************************
--** 文件名:	DressWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	何水大(765865368@qq.com)
--** 日  期:	2017-12-08
--** 版  本:	1.0
--** 描  述:	外观窗口-时装子窗口
--** 应  用:  
--******************************************************************/

local SavePageClass =  require("GuiSystem.WindowList.Appearance.Dress.DressSavePage")
local HeroDisplayWidgetClass = require( "GuiSystem.WindowList.Shop.Dress.HeroDisplayWidget" )
local DressCellItemClass = require( "GuiSystem.WindowList.Appearance.Dress.DressCellItem" )

local BodyPart = {
	EntityBodyPart.BodyMesh,
	EntityBodyPart.HairMesh,
	EntityBodyPart.FaceAdorn,
	"",										--武器，不用这种方式
}


local DressWidget = UIControl:new
{
	windowName = "DressWidget",
	
	m_DressItemScriptCache = {},
	m_curTab = 0,								--当前选中第几个分页
	m_CurrIndex = 1,							--当前选中第几个item
	m_preTab = 0, 								--上次选中的分页
	
	m_CurAppID = 0,								--当前选中的AppearanceID
	
	m_AppearanceChace = {[1]=1,[2]=1,[3]=1,[4]=1},						--缓存本次打开界面选中的外观
}

local OptionBtnImage = {
	HaveGet = AssetPath.TextureGUIPath.."Store/Common_mz_yihuoqu.png",
	NeedBuy = AssetPath.TextureGUIPath.."Common_frame/Common_mz_goumai.png",
}

function DressWidget:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.SavePage = SavePageClass:new()
	self.SavePage:Attach(self.Controls.m_SavePage.gameObject)
	
	HeroDisplayWidgetClass:Attach(self.Controls.m_HeroDisplayWidget.gameObject)
	self.ModelClickEvent = function(eventData) HeroDisplayWidgetClass:OnClickModel(eventData) end
	UIFunction.AddEventTriggerListener(HeroDisplayWidgetClass.Controls.m_HeroRawImage,EventTriggerType.PointerClick,self.ModelClickEvent)
	self.OriginPos = true
	self.CanClick = true
	self.LateClickCB = function() self:LateClick() end

	self.ToggleGroup = self.Controls.m_ToggleGroup:GetComponent(typeof(ToggleGroup))
	
	self.OnItemCellSelectedCB = function(nType, nIndex) self:OnItemCellSelected(nType, nIndex) end
	
	self.m_AppearanceChace = {[1]=1,[2]=1,[3]=1,[4]=1}									--缓存选中的第几个
	
	self:SubscribeEvent()
end

-- 窗口销毁
function DressWidget:OnDestroy()
    -- 移除事件的绑定
    self:UnSubscribeEvent()
	HeroDisplayWidgetClass:ShowHeroModel(false)
	self.m_curTab = 0
	self.m_preTab = 0
	self.m_CurAppID = 0
	self.m_AppearanceChace = {[1]=1,[2]=1,[3]=1,[4]=1}
    UIControl.OnDestroy(self)
end


-- 事件绑定
function DressWidget:SubscribeEvent()
	self.toggleCtl = {
		self.Controls.m_ClothesTgl,
		self.Controls.m_HairstyleTgl,	
		self.Controls.m_FaceAdornTgl,
		self.Controls.m_WeaponTgl,
	}
	--toggle事件绑定
	for i =1,4,1 do
		self.callback_Toggle = function(on) self:OnToggleChanged(on, i) end
		self.toggleCtl[i].onValueChanged:AddListener(self.callback_Toggle)
	end	
	
	self.toggleCtl[1].isOn = true
	
	self.RecoveryCB = function() self:OnRecoveryBtnClick() end 
	self.Controls.m_RecoveryBtn.onClick:AddListener(self.RecoveryCB)
	
	self.EnlargeBtnCB = function() self:OnEnlargeBtnClick() end
	self.Controls.m_EnlargeBtn.onClick:AddListener(self.EnlargeBtnCB)
	
	self.SaveBtnCB = function() self:OnSaveBtnClick() end
	self.Controls.m_SaveBtn.onClick:AddListener(self.SaveBtnCB)
	
	self.PurchaseCB = function() self:OnPurchaseBtnClick() end
	self.Controls.m_PurchaseBtn.onClick:AddListener(self.PurchaseCB)

	self.UnLockAppCB = function(_,_,_,_,nID) self:UnLockAppCallBack(nID) end
	rktEventEngine.SubscribeExecute(EVENT_APPEAR_UNLOCK_APPEAR, SOURCE_TYPE_APPEAR, 0, self.UnLockAppCB)
end

-- 移除事件的绑定
function DressWidget:UnSubscribeEvent()
	rktEventEngine.UnSubscribeExecute(EVENT_APPEAR_UNLOCK_APPEAR, SOURCE_TYPE_APPEAR, 0, self.UnLockAppCB)
end

-- 显示窗口
function DressWidget:ShowWindow()
	UIControl.Show(self)
	HeroDisplayWidgetClass:ShowHeroModel(true)
	self.OriginPos = true
	
	rktEventEngine.FireEvent(EVENT_APPEARANCE_SHOWORHIDEDRESS,0,0,true)
end

-- 隐藏窗口
function DressWidget:HideWindow()
	UIControl.Hide(self, false)
	HeroDisplayWidgetClass:ShowHeroModel(false)
	rktEventEngine.FireEvent(EVENT_APPEARANCE_SHOWORHIDEDRESS,0,0,false)
end
----------------------------------------------------------------------------------
--toggle切换事件 
function DressWidget:OnToggleChanged(on, i)
	self:SetToggleState(on, i)
	
	if not on then return end
	
	if i == 3 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "正在开发中...")
		return
	end
	
	if self.m_curTab == i then 
		return 
	end
	self.m_curTab = i
	self.m_CurrIndex = 1				--切换分页默认选中第一个
	
	--这里切换显示界面
	self:RefeshTogglePage(i)		
end

--设置toggle状态
function DressWidget:SetToggleState(on, curTabIndex)
	if on then 
		self.toggleCtl[curTabIndex].transform:Find("ON").gameObject:SetActive(true)
		self.toggleCtl[curTabIndex].transform:Find("OFF").gameObject:SetActive(false)
	else		
		self.toggleCtl[curTabIndex].transform:Find("ON").gameObject:SetActive(false)
		self.toggleCtl[curTabIndex].transform:Find("OFF").gameObject:SetActive(true)
		return
	end
end

--恢复按钮点击事件
function DressWidget:OnRecoveryBtnClick()
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
	rktTimer.SetTimer(self.LateClickCB, 210,1,"self:LateClick()")			--移动动画完成后恢复交互状态
end

--放大按钮点击事件
function DressWidget:OnEnlargeBtnClick()
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

--控制按钮点击，防止连续点击产生的位移积累
function DressWidget:LateClick()
	self.CanClick = true
end

--保存按钮点击回调 
function DressWidget:OnSaveBtnClick()
	local showSavePage = false
	
	local serverTime = GetServerTimeSecond()
	local heroPreInfo = IGame.AppearanceClient:GetHeroAppInfo()
	
	for i, data in pairs(self.m_AppearanceChace) do
		local itemRecord = IGame.AppearanceClient:GetRecordByTypeAndIndex(i,data)
		if itemRecord then
			if heroPreInfo[itemRecord.nAppearID] then					--买过
				if itemRecord.nLimitTime ~= 0 then
					if serverTime > heroPreInfo[itemRecord.nAppearID].nDeadLine then
						self.SavePage:ShowWindow(self.m_curTab, self.m_AppearanceChace)
						return
					end
				end
			else
				self.SavePage:ShowWindow(self.m_curTab, self.m_AppearanceChace)
				return
			end
		end
	end
	
	self:ConfirmChangeDress()					--满足换装条件， 开始换装
end

--购买按钮点击事件
function DressWidget:OnPurchaseBtnClick()
	local itemRecord = IGame.AppearanceClient:GetRecordByTypeAndIndex(self.m_curTab,self.m_CurrIndex)					--可优化， 缓存一份
	if not itemRecord then return end
	
	local serverTime = GetServerTimeSecond()
	local heroPreInfo = IGame.AppearanceClient:GetHeroAppInfo()
	
	if heroPreInfo[itemRecord.nAppearID] and serverTime < heroPreInfo[itemRecord.nAppearID].nDeadLine  then 	
		return
	end
	if itemRecord.nGetWay and itemRecord.nGetWay ~= "" then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请完成任务获得该外观")
	else
		if self:GetOwnDiamond() < itemRecord.nDiamondCost then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "钻石不足，请充值后购买")
		else
			IGame.AppearanceClient:UnLockAppear(itemRecord.nAppearID)
		end
	end
end

--时装item选中回调,条件限定优化todo
function DressWidget:OnItemCellSelected(item)
	if self.m_CurAppID == item.m_DressID then
		return
	end

	self.m_CurrIndex = item.m_index
	self.m_CurAppID = item.m_DressID
	self.m_AppearanceChace[self.m_curTab] = self.m_CurrIndex 
	local itemRecord = IGame.AppearanceClient:GetRecordByTypeAndIndex(item.m_nType,item.m_index)
	if not itemRecord then return end
	
	--刷新左上角描述信息
	self:RefreshDesInfo(itemRecord)
	--刷新右下购买按钮,消耗信息状态  TODO
	self:RefreshRightBottom(itemRecord)
	
	self:ChangetPart(item, itemRecord)
end

--换装逻辑
function DressWidget:ChangetPart(nItem, nItemRecord)
	--if nItem.m_nType == 3 then return end
	
	local vocation = IGame.AppearanceClient:GetVocation()
	local heroInfo = IGame.AppearanceClient:GetHeroCurAppearInfo()
	
	local resID
	local curID	
	if nItem.m_nType == 1 then
		resID = GameHelp:GetDefaultAppearance(EntityBodyPart.BodyMesh).nResID
		curID = heroInfo.nClothID
	elseif nItem.m_nType == 2 then
		resID = GameHelp:GetDefaultAppearance(EntityBodyPart.HairMesh).nResID
		curID = heroInfo.nFacialID
	elseif nItem.m_nType == 3 then
		resID = GameHelp:GetDefaultAppearance(EntityBodyPart.FaceAdorn).nResID
		curID = 1001									--客户端测试用
		--curID = heroInfo.nFaceAdornID
	elseif nItem.m_nType == 4 then
		resID = GameHelp:GetDefaultAppearance(EntityBodyPart.RWeaponPart)		--默认的武器外观, 存的是记录
		curID = heroInfo.nWaepID
	end
	
	if curID and curID > 0 then
		if nItem.m_nType == 4 then
			resID = curID
		else
			resID = IGame.rktScheme:GetSchemeInfo(APPEARANCE_CSV, curID).nResID
		end
	end
	
	if nItemRecord and nItemRecord.nAppearID > 0 then
		if nItem.m_nType ~= 4 then
			resID = nItemRecord.nResID

		else 
			resID = nItemRecord
		end
	end
	
	local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_DRESS )
	if not entityView then return end
	
	if nItem.m_nType == 4 then			--武器resID存储的是App记录
		if resID.nLeftWeapResID and resID.nLeftWeapResID > 0 then
			IGame.EntityFactory:SetWeapon(entityView,resID.nResID,false,true)
		end
		if resID.nRightWeapResID and resID.nRightWeapResID > 0 then
			IGame.EntityFactory:SetWeapon(entityView,resID.nResID,true,true)
		end
	else
		IGame.EntityFactory:SetPartMesh(entityView,BodyPart[nItem.m_nType],resID,true)
	end
end
-----------------------------------------------------------------------------------------------------------------------
--判断是否有足够的钻石
function DressWidget:HaveEnoughDiamond(num)
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

--获得有多少钻石
function DressWidget:GetOwnDiamond()
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return 0
	end	
	return pHero:GetActorYuanBao()
end
-----------------------------------------------------------刷新方法-------------------------------------------------------
--设置货币类型，及消耗数量
function DressWidget:SetCost(nCurrency, nNum)
	if not nCurrency then return end
	UIFunction.SetImageSprite(self.Controls.m_CostImage, AssetPath_CurrencyIcon[nCurrency])
	self.Controls.m_CostNum.text = nNum
end

--toggle改变刷新
function DressWidget:RefeshTogglePage(curTabIndex)
	if self.m_preTab == curTabIndex then
		return
	end	

	self.m_preTab = curTabIndex
	
	self:RefreshDressList(curTabIndex)		
end

--Toggle改变，刷新右侧列表
function DressWidget:RefreshDressList(nCurTabIndex)
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
	
	local loadedNum = 0
	for	i = 1,self.m_nCount do 
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.Appearance.DressCellItem ,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_DressListGrid,false)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = DressCellItemClass:new({})
			item:Attach(obj)
			item:Hide()
			item:SetToggleGroup(self.ToggleGroup)
			item:SetSelectCallback(self.OnItemCellSelectedCB)
			
			item:SetItemCellInfo(self.m_curTab,i)
			
			local lock = true
			local itemRecord = IGame.AppearanceClient:GetRecordByTypeAndIndex(nCurTabIndex,i)
			if heroPreInfo[itemRecord.nAppearID] and serverTime < heroPreInfo[itemRecord.nAppearID].nDeadLine  then 	
				lock = false
			end
	
			item:SetLock(lock)
			item:SetFocus(false)
			loadedNum = loadedNum + 1
			if loadedNum == self.m_AppearanceChace[nCurTabIndex] then
				item:SetFocus(true)
			else
				item:SetFocus(false)
			end
			table.insert(self.m_DressItemScriptCache,i,item)	
		end , i , AssetLoadPriority.GuiNormal )
	end
end

--刷新左上角描述信息
function DressWidget:RefreshDesInfo(itemRecord)
	if not itemRecord then return end
	self.Controls.m_DressName.text = itemRecord.szAppearName
	self.Controls.m_DressDesc.text = itemRecord.nDes
	
	local serverTime = GetServerTimeSecond()
	local heroPreInfo = IGame.AppearanceClient:GetHeroAppInfo()
	if itemRecord.nLimitTime == 0 then
		self.Controls.m_DressDate.text = "有效期:永久"
	else
		self.Controls.m_DressDate.text = "有效期" .. tostring(GetDayBySecond(itemRecord.nLimitTime)) .. "天\n"
	end
end

--刷新右下购买按钮状态
function DressWidget:RefreshRightBottom(itemRecord) 
	if not itemRecord then return end 
	UIFunction.SetImageSprite(self.Controls.m_CostImage, AssetPath_CurrencyIcon[1], function() self.Controls.m_CostImage:SetNativeSize() end)	--都用钻石买
	
	local heroPreInfo = IGame.AppearanceClient:GetHeroAppInfo()
	local serverTime = GetServerTimeSecond()
	if heroPreInfo[itemRecord.nAppearID] then 								--如果已经获得过
		if serverTime > heroPreInfo[itemRecord.nAppearID].nDeadLine then		--过期了
			self.Controls.m_CostParent.gameObject:SetActive(true)
			if itemRecord.nGetWay and itemRecord.nGetWay ~= "" then
				self.Controls.m_CostNum.text = itemRecord.nGetWay
				self.Controls.m_CostImage.gameObject:SetActive(false)
			else
				self.Controls.m_CostNum.text = tostring(itemRecord.nDiamondCost)
				self.Controls.m_CostImage.gameObject:SetActive(true)
			end
		else
			self.Controls.m_CostParent.gameObject:SetActive(false)		--没过期，可以使用
			UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg, OptionBtnImage.HaveGet, function() 
				self.Controls.m_OptionBtnImg:SetNativeSize() 
				UIFunction.SetImgComsGray(self.Controls.m_PurchaseBtn.gameObject,true)
				self.Controls.m_PurchaseBtn.interactable = false
			end)
			return
		end
	else
		self.Controls.m_CostParent.gameObject:SetActive(true)
		if itemRecord.nGetWay and itemRecord.nGetWay ~= "" then
			self.Controls.m_CostNum.text = itemRecord.nGetWay
			self.Controls.m_CostImage.gameObject:SetActive(false)
		else
			self.Controls.m_CostNum.text = tostring(itemRecord.nDiamondCost)
			self.Controls.m_CostImage.gameObject:SetActive(true)
		end
	end
	UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg, OptionBtnImage.NeedBuy, function() 
		self.Controls.m_OptionBtnImg:SetNativeSize() 
		UIFunction.SetImgComsGray(self.Controls.m_PurchaseBtn.gameObject,false)
		self.Controls.m_PurchaseBtn.interactable = true
	end)
end

--确认换装
function DressWidget:ConfirmChangeDress()
	for i, data in pairs(self.m_AppearanceChace) do
		local itemRecord = IGame.AppearanceClient:GetRecordByTypeAndIndex(i,data)
		if itemRecord then
			IGame.AppearanceClient:EquipAppear(itemRecord.nAppearID,0)
		end
	end
end

--解锁成功返回
function DressWidget:UnLockAppCallBack(nAppID)
	for i, data in pairs(nAppID) do
		if data.m_DressID == nAppID then
			data:SetLock(false)
			self:RefreshRightBottom(data)
		end
	end
end

return DressWidget