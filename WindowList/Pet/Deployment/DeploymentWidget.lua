
-----------------------------灵兽阵法Page------------------------------
local PetZhenLingSlotClass = require("GuiSystem.WindowList.Pet.Deployment.PetZhenLingSlot")
local PetItemClass = require("GuiSystem.WindowList.Pet.PetIconItem")
local PetZhenFaIconClass = require("GuiSystem.WindowList.Pet.Deployment.PetZhenFaIcon")
local PetZhenFaPropClass = require("GuiSystem.WindowList.Pet.Deployment.PetZhenFaProp")

local DeploymentWidget = UIControl:new
{
	windowName = "DeploymentWidget",
	m_PetIconCache = {}, 					--左边灵兽列表缓存
	m_ZhenFaIconCache = {},					--底部阵法缓存
	m_SlotCache = {}, 						--阵灵槽缓存
	m_PropCache = {},						--阵法属性条目

	m_ZhenFaIndex = 1,						--当前显示的阵法ID
	
	
	m_InitZhenFa = false,					--初始化阵法完成
	m_InitZhenLingSlot = false,				--初始化阵灵完成
	m_InitPetIcon = false,					--初始化灵兽Icon完成
	m_InitProp = false,						--初始化属性item
}

function DeploymentWidget:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.UpgradeZhenLingConfrimPage = require("GuiSystem.WindowList.Pet.Deployment.ZhenLingUpgradeConfirmTips"):new()
	self.UpgradeZhenLingConfrimPage:Attach(self.Controls.m_ZhenLingUpgradeConfirm.gameObject)
	
	self.Slot = {
		self.Controls.m_Slot_1,
		self.Controls.m_Slot_2,
		self.Controls.m_Slot_3,
		self.Controls.m_Slot_4,
		self.Controls.m_Slot_5,
		self.Controls.m_Slot_6,
	}
	
	self.ZhenFaGroup = self.Controls.m_ZhenFaGrid:GetComponent(typeof(ToggleGroup))
	
	--灵兽左边icon点击回调
	self.OnPetIconClickCB = function(id,item) self:OnPetIconClick(id, item) end
	--阵灵槽点击回调
	self.OnSlotBtnClickCB = function(id,item) self:OnSlotBtnClick(id,item) end
	--底部阵法icon点击回调
	self.OnZhenFaIconClickCB = function(item) self:OnZhenFaIconClick(item) end
	--下阵按钮点击事件
	self.OnXiaZhenBtnClickCB = function() self:OnXiaZhenBtnClick() end
	self.Controls.m_XiaZhenBtn.onClick:AddListener(self.OnXiaZhenBtnClickCB)
	
	--点击
	self.OnAttatchZhenLingCB = function(item) self:OnAttatchZhenLingBtnClick(item) end
	
	--延迟刷新，
	self.LateShowViewCB = function() self:LateRefresh() end
	
	--回包刷新回调
	self.OnMsgRereshCB = function() self:OnMsgRefresh() end
	
	self:InitZhenFaIconView()
	self:InitSlotView()
	self:InitPropItem()
	
	rktEventEngine.SubscribeExecute(EVENT_PET_SHANGZHEN, SOURCE_TYPE_PET, 0, self.OnMsgRereshCB)				--上阵成功
	rktEventEngine.SubscribeExecute(EVENT_PET_XIAZHEN, SOURCE_TYPE_PET, 0, self.OnMsgRereshCB)					--上阵成功
	rktEventEngine.SubscribeExecute(EVENT_PET_ATTACHZHENLING, SOURCE_TYPE_PET, 0, self.OnMsgRereshCB)			--附体成功
	rktEventEngine.SubscribeExecute(EVENT_PET_UPGRADEZHENLING, SOURCE_TYPE_PET, 0, self.OnMsgRereshCB)			--阵灵升级
	rktEventEngine.SubscribeExecute(EVENT_PET_BOLIZHENLING, SOURCE_TYPE_PET, 0, self.OnMsgRereshCB)				--阵灵剥离	
	rktEventEngine.SubscribeExecute(EVENT_PET_OPENZHENLING, SOURCE_TYPE_PET, 0, self.OnMsgRereshCB)				--阵灵开孔	
end

function DeploymentWidget:Show()
	self:InitPetListView()
	rktTimer.SetTimer(self.LateShowViewCB, 60, -1, "DeploymentWidget:LateRefresh()")
	UIControl.Show(self)
end

function DeploymentWidget:Hide( destroy )
	rktTimer.KillTimer(self.LateShowViewCB)
	UIControl.Hide(self, destroy)
end

function DeploymentWidget:OnDestroy()
	self.m_PetIconCache = {} 					
	self.m_ZhenFaIconCache = {}					
	self.m_SlotCache = {} 
	self.m_PropCache = {}
	self.m_InitZhenFa = false
	self.m_InitZhenLingSlot = false
	self.m_InitPetIcon = false
	self.m_InitProp = false
	rktTimer.KillTimer(self.LateShowViewCB)
	
	rktEventEngine.UnSubscribeExecute(EVENT_PET_SHANGZHEN, SOURCE_TYPE_PET, 0, self.OnMsgRereshCB)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_XIAZHEN, SOURCE_TYPE_PET, 0, self.OnMsgRereshCB)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_ATTACHZHENLING, SOURCE_TYPE_PET, 0, self.OnMsgRereshCB)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_UPGRADEZHENLING, SOURCE_TYPE_PET, 0, self.OnMsgRereshCB)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_BOLIZHENLING, SOURCE_TYPE_PET, 0, self.OnMsgRereshCB)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_OPENZHENLING, SOURCE_TYPE_PET, 0, self.OnMsgRereshCB)				--阵灵剥离
	UIControl.OnDestroy(self)
end

--------------------------------------------------------------------

--初始化完成延迟刷新
function DeploymentWidget:LateRefresh()
	if self.m_InitZhenFa and self.m_InitZhenLingSlot and self.m_InitPetIcon and self.m_InitProp then 
		self.m_ZhenFaIconCache[1]:SetFocus(false)
		self.m_ZhenFaIconCache[1]:SetFocus(true)
		self:RefreshZhenFaIcon()
		rktTimer.KillTimer(self.LateShowViewCB)
	end
end

--初始化底部阵法
function DeploymentWidget:InitZhenFaIconView()
	for i, data in pairs(self.m_ZhenFaIconCache) do
		data:Destroy()
	end
	self.m_ZhenFaIconCache = {}
	local loadedNum = 0
	for	i = 1,4 do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetZhenFaIcon,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_ZhenFaGrid)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = PetZhenFaIconClass:new({})
			item:Attach(obj)
			item:SetID(i)
			item:SetToggleGroup(self.ZhenFaGroup)
			item:SetClickCallBack(self.OnZhenFaIconClickCB)
			table.insert(self.m_ZhenFaIconCache,i,item)	
			loadedNum = loadedNum + 1
			if loadedNum == 4 then
				self.m_InitZhenFa = true
			end
		end , i , AssetLoadPriority.GuiNormal )
	end
end

--初始化右边属性条目
function DeploymentWidget:InitPropItem()
	for i, data in pairs(self.m_PropCache) do
		data:Destroy()
	end
	self.m_PropCache = {}
	local loadedNum = 0
	for	i = 1,18 do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetZhenFaProp,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_ZhenFaPropGrid)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = PetZhenFaPropClass:new({})
			item:Attach(obj)
			item:SetIndex(i)
			table.insert(self.m_PropCache,i,item)	
			loadedNum = loadedNum + 1
			if loadedNum == 18 then
				self.m_InitProp = true
			end
		end , i , AssetLoadPriority.GuiNormal )
	end
end

--初始化顶部阵灵槽
function DeploymentWidget:InitSlotView()
	for i, data in pairs(self.m_SlotCache) do
		data:Destroy()
	end
	self.m_SlotCache = {}
	
	local loadedNum = 0
	for	i = 1,6 do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetZhenLingSlot,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Slot[i], false)
			obj.transform.localScale = Vector3.New(1,1,1)
			obj.transform.localPosition = Vector3.New(0,0,0)
			local item = PetZhenLingSlotClass:new({})
			item:Attach(obj)
			item:SetID(i)
			item:SetClickCallBack(self.OnSlotBtnClickCB)
			table.insert(self.m_SlotCache,i,item)
			loadedNum = loadedNum + 1
			if loadedNum == 6 then 
				self.m_InitZhenLingSlot = true
			end
		end , i , AssetLoadPriority.GuiNormal )
	end
end

--初始化左边灵兽列表
function DeploymentWidget:InitPetListView()
	local tableNum = table_count(self.m_PetIconCache) 
	if tableNum > 0 then
		for i, data in pairs(self.m_PetIconCache) do
			data:Destroy()
		end
	end
	self.m_PetIconCache = {}
	
	--从model中获取灵兽Table
	local petList = IGame.PetClient:GetCurPetTable()
	if not petList then return end
	local listcount = table_count(petList)
	if listcount <= 0 then self.m_InitPetIcon = true end
	
	local loadedNum = 0
	for	i = 1,listcount do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetIconItem,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_LeftListParent, false)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = PetItemClass:new({})
			item:Attach(obj)
			item:SetShowSelectedEffect(false)
			item:SetFocus(false)
			item:SetChangeState(false)

			local uid = petList[i].uid
			local petID = IGame.PetClient:GetIDByUID(uid)
			local petRecord = IGame.PetClient:GetRecordByUID(uid)
			local iconPath
			if petRecord then
				iconPath =  petRecord.HeadIcon
			end
			local level = IGame.PetClient:GetPetLevel(uid)
			local siFighting = IGame.PetClient:IsBattleState(uid)
			
			item:InitState(petID, iconPath, level, false, self.OnPetIconClickCB,uid,true)

			table.insert(self.m_PetIconCache,i,item)	
			loadedNum = loadedNum + 1
			if loadedNum == listcount then
				self.m_InitPetIcon = true
				self:RefreshPetListView()
			end
		end , i , AssetLoadPriority.GuiNormal )
	end
end

--刷新左侧灵兽头像列表
function DeploymentWidget:RefreshPetListView()
	local cfg = IGame.PetClient:GetZhenConfigData()
	local petID = {}
	
	for i, script in pairs(self.m_PetIconCache) do 
		local flag = false
		for i, v in pairs(cfg) do
			if v.shangzhen_pet_dbid > 0 then
				local uid = IGame.PetClient:GetPetUIDByDBID(v.shangzhen_pet_dbid)
				if tostring(script.m_UID) == tostring(uid) then
					flag = true
				end
			end
		end
		script:SetZhenIcon(flag)
	end
end

-- 刷新阵灵槽显示,index-当前阵法ID
function DeploymentWidget:RefreshSlotView(zhenLingIndex)
	local zhenLingCfg = IGame.PetClient:GetZhenLingConfigByID(zhenLingIndex)
	if not zhenLingCfg then 
		self:ClearMiddleView()
		return
	end

	for i, data in pairs(self.m_SlotCache) do
		local id = zhenLingCfg.zhenling_set[i].zhenling_id
		local lv = zhenLingCfg.zhenling_set[i].zhenling_lv
		local isOpen = zhenLingCfg.zhenling_set[i].open_flag
		if id > 0 then 
			local record = IGame.PetClient:GetZhenLingRecordByIDAndLv(id, lv)
			if not record then self:ClearMiddleView() return end
			data:SetIcon(record.Icon)
			data:SetZhenLingID(record.ID)
			data:SetLevel(lv)
			data:SetTypeImg(record.nType)
		elseif isOpen == 1 then
			data:ClearView()
		else
			data:SetLock(true)
		end
	end
	
	self:RefreshPropView()
	
	--刷新底部petIcon显示
	local shangzhen_pet_uid = IGame.PetClient:GetPetUIDByDBID(zhenLingCfg.shangzhen_pet_dbid)
	local petRecord = IGame.PetClient:GetRecordByUID(shangzhen_pet_uid)
	if not petRecord then
		self.Controls.m_ZhenFaIconParent.gameObject:SetActive(false)
		self.Controls.m_NameOrTipText.text = "在左侧列表选择上阵灵兽  "
		return
	end
	self.Controls.m_ZhenFaIconParent.gameObject:SetActive(true)
	UIFunction.SetImageSprite(self.Controls.m_PetIcon, AssetPath.TextureGUIPath .. petRecord.HeadIcon)
	local petName = IGame.PetClient:GetPetName(shangzhen_pet_uid)
	self.Controls.m_NameOrTipText.text = petName
	UIFunction.SetImageSprite(self.Controls.m_PetTypeIcon, AssetPath_PetZhenType[petRecord.BattleType])
    local ex_add = IGame.PetClient:GetExtraAddInZhen(zhenLingCfg.shangzhen_pet_dbid)
     local strContext = string.format("%s阵灵额外加成", petRecord.BattleTypeName)
    if ex_add and ex_add > 0 then 
        strContext = strContext.."<color=#ff7800>" .. ex_add .. "%</color>"
    end
	self.Controls.m_DesText.text = strContext
	self.Controls.m_XiaZhenBtn.gameObject:SetActive(true)
	self.Controls.m_PetTypeIcon.gameObject:SetActive(true)
end

--刷新右边属性条目显示
function DeploymentWidget:RefreshPropView()
	--从数据层获取数据
	local dataTable = IGame.PetClient:GetZhenFaAddProp()

	for i, data in pairs(self.m_PropCache) do
		local propRecord = IGame.rktScheme:GetSchemeInfo(EQUIPATTACHPROPDESC_CSV, gPetCfg.PetZhenPropDisplay[i])
		if propRecord then 
			if dataTable[propRecord.nPropID] then
				data:SetText(propRecord.strDesc .. "+" .. dataTable[propRecord.nPropID])
			else
				data:SetText(propRecord.strDesc .. "+" .. "0")
			end
		end
	end
end

--刷新底部阵法
function DeploymentWidget:RefreshZhenFaIcon()
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local level = pHero:GetNumProp(CREATURE_PROP_LEVEL)
	
	for i, data in pairs(self.m_ZhenFaIconCache) do
		data:SetOpen(level)
		if data:IsOpen() then
			data:SetInteractable(true)
		else
			data:SetInteractable(false)
		end
	end
end

--清空中间显示
function DeploymentWidget:ClearMiddleView()
	for i, data in pairs(self.m_SlotCache) do
		data:ClearView()
	end
	--设置petIcon问号 
	UIFunction.SetImageSprite(self.Controls.m_PetIcon, AssetPath.TextureGUIPath .. "Pet/pet_zengjia.png")
	self.Controls.m_NameOrTipText.text = "请选择上阵灵兽"
	self.Controls.m_DesText.text = ""
	self.Controls.m_XiaZhenBtn.gameObject:SetActive(false)
	self.Controls.m_PetTypeIcon.gameObject:SetActive(false)
end

--回包刷新
function DeploymentWidget:OnMsgRefresh()
	self:RefreshSlotView(self.m_ZhenFaIndex)
	self:RefreshPetListView()
    self:RefreshRedDot()
end

-- 刷新红点显示
function DeploymentWidget:RefreshRedDot()
    
    for _, item in pairs(self.m_ZhenFaIconCache) do 
        item:SetShowRedDot()
    end
end

---------------------------------------------------------------------------------------------------------------------------

--左边边灵兽列表点击回调
function DeploymentWidget:OnPetIconClick(id, item)
	local cfg = IGame.PetClient:GetZhenLingConfigByID(self.m_ZhenFaIndex)
	if cfg then	
		if cfg.shangzhen_pet_dbid <= 0 then			--没上阵
			local idx = self.m_ZhenFaIndex - 1
			GameHelp.PostServerRequest("RequestPet_ShangZhen(" .. tostring(item.m_UID) .. "," .. idx ..")")
		end
	end
end

--阵灵槽点击回调
function DeploymentWidget:OnSlotBtnClick(id, item)
	local cfg = IGame.PetClient:GetZhenLingSlotCfg(self.m_ZhenFaIndex, id)

	if cfg then 
		if cfg.id > 0 and cfg.openFlag == 1 then		--学习了
			self.UpgradeZhenLingConfrimPage:OpenUpgradePage(self.m_ZhenFaIndex, id)
		elseif cfg.openFlag == 1 and cfg.id == 0 then				--没学
			rktEventEngine.FireEvent(EVENT_PET_OPENSKILLLEARN,SOURCE_TYPE_PET, 0, 2, self.OnAttatchZhenLingCB)				--打开附体界面
		else
			local contentStr
			local curZhenfaIndex = self.m_ZhenFaIndex - 1
			local openSlot = IGame.PetClient:GetZhenLingOpenSlotNum(self.m_ZhenFaIndex) + 1
			local curCostTable = gPetCfg.PetZhenOpenSlotCfg[curZhenfaIndex][openSlot]
			local goodsRecord = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, curCostTable.use_item_id)
			local contentStr = string.format("确定消耗%d个%s开启一个阵灵槽吗？",curCostTable.use_item_num, goodsRecord.szName)
			local data = {
				content = contentStr,
				confirmCallBack = function()
						local haveNum = GameHelp:GetHeroPacketGoodsNum(curCostTable.use_item_id)
						if haveNum < curCostTable.use_item_num then
							IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "材料不足，无法开启")
							return
						end
						GameHelp.PostServerRequest("RequestOpenPetZhenSlot(" .. curZhenfaIndex .."," .. id ..")")
					end
			}
			UIManager.ConfirmPopWindow:ShowDiglog(data)
		end
	end
end

--阵法图标点击回调
function DeploymentWidget:OnZhenFaIconClick(item)
	local opened = item:IsOpen()
	
	if not opened then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "等级不足，无法切换")
		return
	end
	
	self.m_ZhenFaIndex = item.ID
	self:RefreshSlotView(self.m_ZhenFaIndex)
end

--下阵按钮点击回调
function DeploymentWidget:OnXiaZhenBtnClick()
	local cfg = IGame.PetClient:GetZhenLingConfigByID(self.m_ZhenFaIndex)
	if cfg then
		if cfg.shangzhen_pet_dbid > 0 then
			local pet_uid = IGame.PetClient:GetPetUIDByDBID(cfg.shangzhen_pet_dbid)
			GameHelp.PostServerRequest("RequestPet_XiaZhen(" .. tostring(pet_uid)..")")
		end
	end
end

--点击附体界面附体阵灵按钮 
function DeploymentWidget:OnAttatchZhenLingBtnClick(item)
    
    if not item then return end 
    
	local zhenling_id = item.m_CurSkillID
	local zhenfaIndex = self.m_ZhenFaIndex - 1
    
    if  IGame.PetClient:CheckZhenLingIsFuTi(zhenfaIndex, zhenling_id) then 
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "不能重复学习同种阵灵!")
        return
    end
	
    GameHelp.PostServerRequest("RequestPetSpirit_Futi(" .. zhenling_id .. "," .. zhenfaIndex ..")")
    item:Hide()
end


------------------------------------------------------------------------------------------------------------------
return DeploymentWidget