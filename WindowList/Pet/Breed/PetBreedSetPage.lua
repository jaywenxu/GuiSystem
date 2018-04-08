local PetModelDisPlayClass = require( "GuiSystem.WindowList.Pet.PetModelDisplay" )
local PetItemClass = require("GuiSystem.WindowList.Pet.PetIconItem")
---------------------------灵兽系统繁殖界面---------------------------------------
local PetBreedSetPage = UIControl:new
{
	windowName = "PetBreedSetPage",
	
	m_RightPetID = -1,					--右边自己的灵兽ID
	m_LeftPetID = -1,					--对面玩家的灵兽ID
	
	m_RightUID = nil,					--右边的UID
	m_LeftUID = nil, 					--左边的UID
	
	m_CurLeftItem = nil,
	m_CurRightItem = nil, 
	
	m_RightModelUID = 63,				--  -3
	m_LeftModelUID = 64,				-- 5
	
	m_Type = -1, 						--单双人模式
	m_Luck = -1,						--幸运值
	
	m_PetIconCache = {},				--灵兽item缓存
}

function PetBreedSetPage:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.DBID = GetHeroPDBID()
	
	self.LeftPetModelDisPlay = PetModelDisPlayClass:new()
	self.RightPetModelDisPlay = PetModelDisPlayClass:new()
	self.LeftPetModelDisPlay:SetUID(self.m_LeftModelUID)
	self.RightPetModelDisPlay:SetUID(self.m_RightModelUID)
	self.LeftPetModelDisPlay:Attach(self.Controls.RawImage.gameObject)
	self.RightPetModelDisPlay:Attach(self.Controls.m_RightRawImgTrans.gameObject)

	self.BreedBtnClickCB = function() self:OnBreedBtnClick() end
	
	self.OnePetIconClickCB = function(id, item) self:OnOneIconClick(id, item) end
	self.TwoPetIconClickCB = function(id, item) self:OnTwoIconClick(id, item) end
	
	self.LeftYiHuiBtnCB = function() self:OnLeftYiHuiBtnClick() end
	self.RightYiHuiBtnCB = function() self:OnRightYiHuiBtnClick() end
	
	self.RightLockBtnClickCB = function() self:OnRightLockBtnClick() end
	
	--订阅的事件   回包
	self.SetRightPet = function(_,_,_,uid) self:TwoSetRightView(uid) end			--双人设置右边的
	self.SetLeftPet = function(_,_,_,regTable) self:TwoSetLeftView(regTable) end				--双人设置左边的
	self.RemovePetCB = function(_,_,_,uid,dbid) self:RemovePet(uid,dbid) end 					--移除灵兽
	self.LockPet = function(_,_,_,uid,dbid) self:OnLockPet(uid,dbid) end						--锁定灵兽
	
	
	self:RegisterEvent()
end

function PetBreedSetPage:Show()
	UIControl.Show(self)
	self:ClearLeftView()
	self:ClearRightView()
	self.m_CurLeftItem = nil
	self.m_CurRightItem = nil
	self.LeftPetModelDisPlay:ShowPetModel(true,3)
	if self.LeftPetModelDisPlay.m_dis~= nil then 
		self.RightPetModelDisPlay:CreatModel(true,self.LeftPetModelDisPlay.m_dis.m_GameObject.transform)
	end
	
	self:CheckShowBreedBtn()
	self:InitPetList()
	
	rktEventEngine.SubscribeExecute(EVENT_PET_SETPET, SOURCE_TYPE_PET, 0,self.SetRightPet)
	rktEventEngine.SubscribeExecute(EVENT_PET_OTHERSETPET, SOURCE_TYPE_PET, 0,self.SetLeftPet)
	rktEventEngine.SubscribeExecute(EVENT_PET_REMOVEPET, SOURCE_TYPE_PET, 0,self.RemovePetCB)
	rktEventEngine.SubscribeExecute(EVENT_PET_LOCKPET, SOURCE_TYPE_PET, 0,self.LockPet)
end

function PetBreedSetPage:Hide( destroy )
	self.LeftPetModelDisPlay:ShowPetModel(false)
	self.RightPetModelDisPlay:ShowPetModel(false)
	self.m_CurLeftItem = nil
	self.m_CurRightItem = nil
	self.RightLock = false
	self.LeftLock = false
	rktEventEngine.UnSubscribeExecute(EVENT_PET_SETPET, SOURCE_TYPE_PET, 0,self.SetRightPet)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_OTHERSETPET, SOURCE_TYPE_PET, 0,self.SetLeftPet)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_REMOVEPET, SOURCE_TYPE_PET, 0,self.RemovePetCB)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_LOCKPET, SOURCE_TYPE_PET, 0,self.LockPet)
	
	UIControl.Hide(self, destroy)
end

function PetBreedSetPage:OnDestroy()
	self.LeftPetModelDisPlay:ShowPetModel(false)
	self.RightPetModelDisPlay:ShowPetModel(false)
	self.m_CurLeftItem = nil
	self.m_CurRightItem = nil
	self.RightLock = false
	self.LeftLock = false
	rktEventEngine.UnSubscribeExecute(EVENT_PET_SETPET, SOURCE_TYPE_PET, 0,self.SetRightPet)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_OTHERSETPET, SOURCE_TYPE_PET, 0,self.SetLeftPet)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_REMOVEPET, SOURCE_TYPE_PET, 0,self.RemovePetCB)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_LOCKPET, SOURCE_TYPE_PET, 0,self.LockPet)
	
	UIControl.OnDestroy(self)
end
-------------------------事件注册-----------------------------------

--设置单双人模式 1-单人，2-双人
function PetBreedSetPage:SetType(breedType, lucky_var)
	self.m_Type = breedType
	self.m_Luck = lucky_var
	self.Controls.m_LuckText.text = tostring(lucky_var)
end

function PetBreedSetPage:RegisterEvent()
	--锁定按钮
	self.Controls.m_RightLockBtn.onClick:AddListener(self.RightLockBtnClickCB)
	
	--移回按钮
	self.Controls.m_LeftYiHuiBtn.onClick:AddListener(self.LeftYiHuiBtnCB)
	self.Controls.m_RightYiHuiBtn.onClick:AddListener(self.RightYiHuiBtnCB)
	
	--繁殖按钮
	self.Controls.m_BreedBtn.onClick:AddListener(self.BreedBtnClickCB)
end

--双人 右边锁定按钮点击事件
function PetBreedSetPage:OnLockBtnClick()
	if self.m_RightPetID < 0 then
		return 
	end
	
	if self.m_LeftPetID > 0 then 
		local rightRecord = IGame.PetClient:GetRecordByID(self.m_RightPetID)
		local leftRecord = IGame.PetClient:GetRecordByID(self.m_LeftPetID)
		if not leftRecord or not rightRecord then return end 
		if rightRecord.ClassName ~= leftRecord.ClassName then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "同种一代灵兽才能进行繁殖")
			return
		end
	end
	
	GameHelp.PostServerRequest("RequestLockTeamBreedPet("..tostring(self.m_RightUID)..")")
end


--繁殖按钮点击事件
function PetBreedSetPage:OnBreedBtnClick()
	if self.m_Type == 1 then
		if self.m_LeftPetID < 0 or self.m_RightPetID < 0 then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请选择两只灵兽进行繁殖")
			return
		end
			GameHelp.PostServerRequest("RequestStartSingleBreed(".. tostring(self.m_LeftUID) ..",".. tostring(self.m_RightUID) ..")")
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "开始繁殖")
			UIManager.PetBreedWindow:CloseWindow(self.m_Type)
	elseif self.m_Type == 2 then
		if not GetHero():IsTeamCaptain() then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你不是队长，无法开始繁殖 ")
            return
		end
		
        if self.m_RightPetID < 0 then 
            IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请放入想要繁殖的灵兽")
            return
        end 
                
        if self.m_LeftPetID < 0 then 
            IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "对方未放入灵兽")
            return
        end 
        
        if not self.RightLock then 
            IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请先锁定再进行繁殖")
            return            
        end 
        
        if not self.LeftLock then 
            IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "队友灵兽未锁定，无法繁殖")
            return            
        end
		
		if self.m_RightPetID > 0 and self.m_LeftPetID > 0 then
			GameHelp.PostServerRequest("RequestStartTeamBreed()")
		end
	end
end

--------------------------------------------------------------------
--初始化左侧列表显示
function PetBreedSetPage:InitPetList()
	local tableNum = #self.m_PetIconCache
	if tableNum > 0 then
		for i, data in pairs(self.m_PetIconCache) do
			data:Destroy()
		end
	end
	self.m_PetIconCache = {}
	
	--从model中获取灵兽Table
	local petList = IGame.PetClient:GetOneGenerationPet()
	if not petList then return end
	local count = #petList
	
	for	i = 1,count do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetIconItem,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_PetListParent, false)
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
			if self.m_Type == 1 then
				item:InitState(petID, iconPath, level, siFighting, self.OnePetIconClickCB,uid,true)
			else
				item:InitState(petID, iconPath, level, siFighting, self.TwoPetIconClickCB,uid,true)
			end
			item:SetClickAnimation(false)
            item:SetShowSelectedEffect(false)
			table.insert(self.m_PetIconCache,i,item)	
		end , i , AssetLoadPriority.GuiNormal )
	end
end

--单人模式图标点击回调
function PetBreedSetPage:OnOneIconClick(petID, item) 
    
    if self.m_LeftUID and tostring(self.m_LeftUID) == tostring(item.m_UID) then 
        self:OnLeftYiHuiBtnClick()
        return
    end 
    
    if self.m_RightUID and tostring(self.m_RightUID) == tostring(item.m_UID) then 
        self:OnRightYiHuiBtnClick()
        return
    end 
    
	if self.m_LeftPetID > 0 and self.m_RightPetID > 0 then
		return
	end
	
	if IGame.PetClient:IsBattleState(item.m_UID) then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "出战灵兽不能参与繁殖")
		return
	end
	
	if IGame.PetClient:IsDead(item.m_UID) then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "死亡灵兽无法繁殖")
		return
	end
	
	if self.m_LeftPetID > 0 and self.m_RightPetID < 0 then
		local rightRecord = IGame.PetClient:GetRecordByID(petID)
		local leftRecord = IGame.PetClient:GetRecordByID(self.m_LeftPetID)
		if not rightRecord or not leftRecord then return end
		if rightRecord.ClassName ~= leftRecord.ClassName then 
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "相同种类的才能繁殖")
			return
		end
	elseif self.m_LeftPetID < 0 and self.m_RightPetID > 0 then
		local rightRecord = IGame.PetClient:GetRecordByID(self.m_RightPetID)
		local leftRecord = IGame.PetClient:GetRecordByID(petID)
		if not rightRecord or not leftRecord then return end
		if rightRecord.ClassName ~= leftRecord.ClassName then 
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "相同种类的才能繁殖")
			return
		end
	end
	
	if self.m_LeftPetID < 0 then
		if item == self.m_CurRightItem then return end
		self:SetLeftView(item.m_UID)
		if self.m_CurLeftItem then
			self.m_CurLeftItem:SetSelectedImgState(false)
		end
		item:SetSelectedImgState(true)
		self.m_CurLeftItem = item
	elseif self.m_RightPetID < 0 then
		if item == self.m_CurLeftItem then return end
		self:SetRightView(item.m_UID)
		if self.m_CurRightItem then
			self.m_CurRightItem:SetSelectedImgState(false)
		end
		item:SetSelectedImgState(true)
		self.m_CurRightItem = item
	end
end

--双人模式图标点击回调
function PetBreedSetPage:OnTwoIconClick(petID, item)
    
    if self.m_RightUID and tostring(self.m_RightUID) == tostring(item.m_UID) then 
        self:OnRightYiHuiBtnClick()
        return
    end 
    
	if self.m_RightPetID > 0 then
		return
	end
	if IGame.PetClient:IsDead(item.m_UID) then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "死亡灵兽无法繁殖")
		return
	end
	if IGame.PetClient:IsBattleState(item.m_UID) then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "出战灵兽不能参与繁殖")
		return
	end
	if self.m_RightPetID < 0 then
		--self:SetRightView(item.m_UID)

		if self.m_CurRightItem then
			self.m_CurRightItem:SetSelectedImgState(false)
		end
		item:SetSelectedImgState(true)
		self.m_CurRightItem = item
		
		GameHelp.PostServerRequest("RequestPetTeamBreedPutIn("..tostring(item.m_UID)..")")
	end
end

--清空左边显示
function PetBreedSetPage:ClearLeftView()	
	--清空左边模型显示
	self.Controls.m_LeftRawImgTrans.gameObject:SetActive(false)
	
	self.Controls.m_LeftLockImg.gameObject:SetActive(false)
	self.Controls.m_LeftParent.gameObject:SetActive(false)
	self.LeftPetModelDisPlay:CreatModel(false)
	
	self.m_LeftPetID = -1
end

--清空右边显示
function PetBreedSetPage:ClearRightView()
	self.RightLock = false
	--清空模型显示
	self.Controls.m_RightRawImgTrans.gameObject:SetActive(false)
	
	self.Controls.m_RightLockImg.gameObject:SetActive(false)
	self.Controls.m_RightLockParent.gameObject:SetActive(false)
	if self.m_Type == 2 then
		self.Controls.m_RightNoLockParent.gameObject:SetActive(true)
	end
	self.RightPetModelDisPlay:CreatModel(false)
	self.m_RightPetID = -1
end

--单人模式左边移回
function PetBreedSetPage:OnLeftYiHuiBtnClick()
	self.m_LeftPetID = -1
	self.m_LeftUID = nil
	self.m_CurLeftItem:SetSelectedImgState(false)
	self.m_CurLeftItem = nil
	self:ClearLeftView()
	self.Controls.m_LeftTip.gameObject:SetActive(true)
end

--单人,双人,模式右边移回
function PetBreedSetPage:OnRightYiHuiBtnClick()
	self.m_RightPetID = -1

	self.m_CurRightItem:SetSelectedImgState(false)
	self.m_CurRightItem = nil
	self:ClearRightView()
	
	if self.m_Type == 2 then
		self.Controls.m_RightNoLockParent.gameObject:SetActive(false)
		GameHelp.PostServerRequest("RequestRemoveTeamBreedPet("..tostring(self.m_RightUID)..")")
	end
	
	self.m_RightUID = nil
	self.Controls.m_RightTip.gameObject:SetActive(true)
end

--双人模式移除 回包
function PetBreedSetPage:RemovePet(uid,dbid)
	if dbid == self.DBID then
		if uid == self.m_LeftUID then
			--移除右边的
			self.m_RightPetID = -1
			self.m_CurRightItem:SetSelectedImgState(false)
			self.m_CurRightItem = nil
			self:ClearRightView()
			self.m_RightUID = nil
		end
	else
		--队友移除了，移除左边的
		self.m_LeftPetID = -1
		self.m_CurLeftItem = nil
		self:ClearLeftView()
		self.m_LeftUID = nil
	end
end

--双人模式锁定， 回包
function PetBreedSetPage:OnLockPet(uid, dbid)
	if dbid == self.DBID then		--自己锁定
		if tostring(uid) == tostring(self.m_RightUID) then
			self.RightLock = true
			self.Controls.m_RightNoLockParent.gameObject:SetActive(false)
			self.Controls.m_RightLockImg.gameObject:SetActive(true)
		end
	else
		self.LeftLock = true
		self.Controls.m_LeftLockImg.gameObject:SetActive(true)
	end
end

--双人模式右边锁定按钮点击 
function PetBreedSetPage:OnRightLockBtnClick()
	if self.LeftLock then 
		local record = IGame.PetClient:GetRecordByID(self.m_LeftPetID)
		local rightRecord = IGame.PetClient:GetRecordByID(self.m_RightPetID)
		if record.ClassName ~= rightRecord.ClassName then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "同种灵兽才可锁定")
			return
		end
	end
	
	self.Controls.m_RightYiHuiBtn.gameObject:SetActive(false)
	self.Controls.m_RightLockImg.gameObject:SetActive(false)

	GameHelp.PostServerRequest("RequestLockTeamBreedPet("..tostring(self.m_RightUID)..")")
end

--双人模式设置左边显示
function PetBreedSetPage:TwoSetLeftView(regTable)
	self.Controls.m_LeftRawImgTrans.gameObject:SetActive(true)
	local record = IGame.PetClient:GetRecordByID(regTable[3])
	local entityView = rkt.EntityView.GetEntityView(self.m_LeftModelUID)
	if not entityView then
		self.LeftPetModelDisPlay:CreatModel(true,self.LeftPetModelDisPlay.m_dis.m_GameObject.transform)
		self.LeftPetModelDisPlay:SetEntityPos(PET_BREED_MODEL_ENTITY_POS[1])
	else
		entityView.transform.localPosition = PET_BREED_MODEL_ENTITY_POS[1]
	end
	self.LeftPetModelDisPlay:ChangePet(record.ModelResource)
	self.m_LeftPetID = regTable[3]
	
	self.Controls.m_LeftParent.gameObject:SetActive(true)
	self.Controls.m_PlayerNameText.text = regTable[1]
	self.Controls.m_PlayerPetNameText.text = regTable[2]
	UIFunction.SetImageSprite(self.Controls.m_PlayerPetGrowRateImg, AssetPath_PetGrowType[regTable[4]])
	self.Controls.m_LeftTip.gameObject:SetActive(false)
end

--双人模式设置右边的
function PetBreedSetPage:TwoSetRightView(nUID)
	if tostring(nUID) ~= tostring(self.m_CurRightItem.m_UID) then
		return
	end
	self:SetRightView(nUID)
	
	self.Controls.m_RightYiHuiBtn.gameObject:SetActive(true)
	self.Controls.m_RightNoLockParent.gameObject:SetActive(true)
	self.Controls.m_RightTip.gameObject:SetActive(false)
end

--设置左边显示View
function PetBreedSetPage:SetLeftView(nUID)
	--设置模型显示
	self.Controls.m_LeftRawImgTrans.gameObject:SetActive(true)
	local record = IGame.PetClient:GetRecordByUID(nUID)
	local entityView = rkt.EntityView.GetEntityView(self.m_LeftModelUID)
	if not entityView then
		self.LeftPetModelDisPlay:CreatModel(true,self.LeftPetModelDisPlay.m_dis.m_GameObject.transform)
		self.LeftPetModelDisPlay:SetEntityPos(PET_BREED_MODEL_ENTITY_POS[1])
	else
		entityView.transform.localPosition = PET_BREED_MODEL_ENTITY_POS[1]
	end
	self.LeftPetModelDisPlay:ChangePet(record.ModelResource)
	local nID = IGame.PetClient:GetIDByUID(nUID)
	self.m_LeftPetID = nID
	self.m_LeftUID = nUID
	self.Controls.m_LeftParent.gameObject:SetActive(true)
	self.Controls.m_PlayerNameText.text = GetHero():GetName()
	self.Controls.m_PlayerPetNameText.text = IGame.PetClient:GetPetName(nUID)
	local growth = IGame.PetClient:GetGrowRate(nUID)
	UIFunction.SetImageSprite(self.Controls.m_PlayerPetGrowRateImg, AssetPath_PetGrowType[growth])
	
	--关闭提示信息
	self.Controls.m_LeftTip.gameObject:SetActive(false)
end

--设置右边显示view
function PetBreedSetPage:SetRightView(nUID)
	if self.RightLock then
		return
	end
	local nID = IGame.PetClient:GetIDByUID(nUID)
	
	self.Controls.m_RightLockParent.gameObject:SetActive(true)
	
	--设置模型显示
	self.Controls.m_RightRawImgTrans.gameObject:SetActive(true)
	local record = IGame.PetClient:GetRecordByUID(nUID)
	local entityView = rkt.EntityView.GetEntityView(self.m_RightModelUID)
	if not entityView then
		self.RightPetModelDisPlay:CreatModel(true,self.LeftPetModelDisPlay.m_dis.m_GameObject.transform)
		self.RightPetModelDisPlay:SetEntityPos(PET_BREED_MODEL_ENTITY_POS[2])
	else
		entityView.transform.localPosition = PET_BREED_MODEL_ENTITY_POS[2]
	end
	self.RightPetModelDisPlay:ChangePet(record.ModelResource)
		
	self.m_RightPetID = nID
	self.m_RightUID = nUID
	
	self.Controls.m_RightPetNameText.text = IGame.PetClient:GetPetName(nUID)
	self.Controls.m_RightPlayerNameText.text = GetHero():GetName()
	local growth = IGame.PetClient:GetGrowRate(nUID)
	UIFunction.SetImageSprite(self.Controls.m_RightGrowRateImg, AssetPath_PetGrowType[growth])
	--关闭提示文字
	self.Controls.m_RightTip.gameObject:SetActive(false)
end

--检测是否需要显示繁殖按钮
function PetBreedSetPage:CheckShowBreedBtn()
	if self.m_Type == 1 then
		self.Controls.m_RightNoLockParent.gameObject:SetActive(false)
		self.Controls.m_LeftYiHuiBtn.gameObject:SetActive(true)
		self.Controls.m_RightNoLockParent.gameObject:SetActive(false)
		self.Controls.m_LeftTip.gameObject:SetActive(true)
		self.Controls.m_RightTip.gameObject:SetActive(true)
	elseif self.m_Type == 2 then
		self.Controls.m_LeftYiHuiBtn.gameObject:SetActive(false)
		self.Controls.m_RightNoLockParent.gameObject:SetActive(false)
		self.Controls.m_RightYiHuiBtn.gameObject:SetActive(false)
		self.Controls.m_RightLockImg.gameObject:SetActive(false)
		local myTeam = IGame.TeamClient:GetTeam()
		if nil == myTeam then 
			self.Controls.m_BreedBtn.gameObject:SetActive(false)
			return
		end
		if GetHero():IsTeamCaptain() then
			self.Controls.m_BreedBtn.gameObject:SetActive(true)
		else
			self.Controls.m_BreedBtn.gameObject:SetActive(false)
		end
		self.Controls.m_LeftTip.gameObject:SetActive(false)
		self.Controls.m_RightTip.gameObject:SetActive(true)
	else
		self.Controls.m_BreedBtn.gameObject:SetActive(false)
	end
end

return PetBreedSetPage