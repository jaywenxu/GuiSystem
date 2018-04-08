
---------------------------灵兽系统展示界面---------------------------------------
local PetItemClass = require("GuiSystem.WindowList.Pet.PetIconItem")
local PetSkillItemClass = require( "GuiSystem.WindowList.Pet.PetSkillItem" )
local PetModelDisPlayClass = require( "GuiSystem.WindowList.Pet.PetModelDisplay" )

local PetDisplayWidget = UIControl:new
{
	windowName = "PetDisplayWidget",
	
	m_petItemScriptCache = {},				--缓存左侧灵兽item脚本表
	m_petSkillScriptCache = {},				--灵兽技能脚本缓存
	m_petSkillStarImageCache = {},			--星级Imge缓存
	
	m_CurPetID = -1,						--当前灵兽UID
}

function PetDisplayWidget:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.PetModelDisplay = PetModelDisPlayClass:new()
	self.PetModelDisplay:Attach(self.Controls.m_PetRawImageTrans.gameObject)
	
	--缓存星级image组件
	self:CacheStarImageCom()
	
	
	self.PetListGroup = self.Controls.m_ToggleGroupTrans:GetComponent(typeof(ToggleGroup))
	
	self.PetIconClickCB = function(ID, item) self:OnSelectPet(ID, item) end
	self.ChangeNameCB = function(newName) self:ChangeNameConfirm(newName) end
	self.OnPetSkillItemSelectedCB = function(index, item) self:OnPetSkillSelected(index, item) end
	
	
	--改名注册
	self.ChangeNameClickCB = function() self:OnClickChangeNameBtn() end
	self.Controls.m_ChangeNameBtn.onClick:AddListener(self.ChangeNameClickCB)
	--天赋技能点击事件
	self.SpecialSkillClickCB = function() self:OnSpecialSkillClick() end
	self.Controls.m_TalentSkillBtn.onClick:AddListener(self.SpecialSkillClickCB)
	--援助技能点击事件
	self.Controls.m_HelpSkillBtn.onClick:AddListener(self.SpecialSkillClickCB)
	
	--服务器返回注册
	self.OnChangeNameSuccess = function(_,_,_,_,msg) self:OnChangeName(msg) end
	rktEventEngine.SubscribeExecute(EVENT_PET_CHANGENAME, SOURCE_TYPE_PET, 0, self.OnChangeNameSuccess)		--改名
	
	self.GotoBattleCB = function(_,_,_,_,msg) self:OnGotoBattle(msg) end
	rktEventEngine.SubscribeExecute(EVENT_PET_GOTOBATTLE, SOURCE_TYPE_PET, 0, self.GotoBattleCB)		--出战
	
	--放生返回
	self.OnFangShengCB = function(_,_,_,msg) self:OnFangSheng(msg) end
	rktEventEngine.SubscribeExecute(EVENT_PET_FANSEHNG, SOURCE_TYPE_PET, 0, self.OnFangShengCB)
	
	--关闭灵兽界面事件监听
	self.ClosePetWindowCB = function() self:OnClosePetWindow() end
	rktEventEngine.SubscribeExecute(EVENT_PET_CLOSE_WINDOW, SOURCE_TYPE_PET, 0, self.ClosePetWindowCB)
	
	--重新打开界面
	self.ReOpenWidgetCB = function(_,_,_,index) self:OnReOpenPetWindow(index) end
	rktEventEngine.SubscribeExecute(EVENT_PET_REOPEN_WIDGET, SOURCE_TYPE_PET, 0, self.ReOpenWidgetCB)
	
	--使用经验物品
	self.UseExpGoodsCB = function(_,_,_,uid) self:OnUseExpGoods(uid) end
	
    -- 响应灵兽属性变化
    self.UpdatePetProp = function(_,_,_,uid) self:OnUpdatePetProp(uid) end 
    rktEventEngine.SubscribeExecute(EVENT_PET_BASEPROP, SOURCE_TYPE_PET, 0, self.UpdatePetProp)
end

-- 响应灵兽属性变化
function PetDisplayWidget:OnUpdatePetProp(pet_uid)

    if tostring(self.m_CurPetID) == tostring(pet_uid) then 
        self:RefreshMiddleWidget(self.m_CurPetID)   
    end
end 

function PetDisplayWidget:Show()
	local petTable = IGame.PetClient:GetCurPetTable()
	if table_count(petTable) > 0 then 
		self:SetPet(true)
	else
		self:SetPet(false)
	end
	
	rktEventEngine.SubscribeExecute(EVENT_PET_USEXPGOODS, SOURCE_TYPE_PET, 0, self.UseExpGoodsCB)
	UIControl.Show(self)
end

function PetDisplayWidget:Hide( destroy )
	self.m_CurPetID = -1
	self.PetModelDisplay:ShowPetModel(false)
	
	rktEventEngine.UnSubscribeExecute(EVENT_PET_USEXPGOODS, SOURCE_TYPE_PET, 0, self.UseExpGoodsCB)
	UIControl.Hide(self, destroy)
end

function PetDisplayWidget:OnDestroy()
	self.m_CurPetID = -1
	self.PetModelDisplay:ShowPetModel(false)
	
	self.m_petSkillScriptCache = {}
	
	--服务器返回事件注销
	rktEventEngine.UnSubscribeExecute(EVENT_PET_CHANGENAME, SOURCE_TYPE_PET, 0, self.OnChangeNameSuccess)		--改名
	rktEventEngine.UnSubscribeExecute(EVENT_PET_GOTOBATTLE, SOURCE_TYPE_PET, 0, self.GotoBattleCB)		--出战
	rktEventEngine.UnSubscribeExecute(EVENT_PET_CLOSE_WINDOW, SOURCE_TYPE_PET, 0, self.ClosePetWindowCB)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_REOPEN_WIDGET, SOURCE_TYPE_PET, 0, self.ReOpenWidgetCB)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_FANSEHNG, SOURCE_TYPE_PET, 0, self.OnFangShengCB)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_USEXPGOODS, SOURCE_TYPE_PET, 0, self.UseExpGoodsCB)				--使用经验物品
    rktEventEngine.UnSubscribeExecute(EVENT_PET_BASEPROP, SOURCE_TYPE_PET, 0, self.UpdatePetProp)
	UIControl.OnDestroy(self)
end

--设置有没有灵兽的显示
function PetDisplayWidget:SetPet(havePet)
	if havePet then 
		self.Controls.m_Pet.gameObject:SetActive(true)
		self.Controls.m_NoPet.gameObject:SetActive(false)
		self.PetModelDisplay:SetModePosition(Vector3.New(-0.62,1.31,0))
		self.PetModelDisplay:ShowPetModel(true)
		self.m_CurPetID = -1
		self:InitView()
	else
		self.PetModelDisplay:ShowPetModel(false)
		self.Controls.m_Pet.gameObject:SetActive(false)
		self.Controls.m_NoPet.gameObject:SetActive(true)
	end
end

--加载的时候初始化界面
function PetDisplayWidget:InitView()
	self:InitPetList()
end


--缓存星级image
function PetDisplayWidget:CacheStarImageCom()
	self.m_petSkillStarImageCache = {}
	
	for	i = 1, 9 do
		local child = self.Controls.m_StarParentTrans:GetChild(i-1)
		local image = child:GetComponent(typeof(Image))
		if image then
			table.insert(self.m_petSkillStarImageCache,i,image)
		end
	end
end

--重新打开界面回调
function PetDisplayWidget:OnReOpenPetWindow(nIndex)
	if nIndex == 1 or nIndex == 2 then
		self:Hide()
		self:Show()
	end
end

--刷新中间界面
function PetDisplayWidget:RefreshMiddleWidget(UID)
	local curRecord = IGame.PetClient:GetRecordByUID(UID)
	if not curRecord then return end
	
	UIFunction.SetImageSprite(self.Controls.m_PetQualityImage, AssetPath_PetQuality[curRecord.Type], function() self.Controls.m_PetQualityImage.gameObject:SetActive(true) end)
	UIFunction.SetImageSprite(self.Controls.m_PetTypeImage, AssetPath_PetType[curRecord.BattleType],  function() 
				self.Controls.m_GrowParent.gameObject:SetActive(true)
				self.Controls.m_PetTypeImage.gameObject:SetActive(true)
			end)

	self.Controls.m_PetLevelLabel.text = string.format("%d级", IGame.PetClient:GetPetLevel(UID))
	self.Controls.m_PetNameLabel.text = IGame.PetClient:GetPetName(UID)
	
	local growType = IGame.PetClient:GetGrowRate(UID)
	UIFunction.SetImageSprite(self.Controls.m_GrowTypeImg, AssetPath_PetGrowType[growType])
	self.Controls.m_TakeLevelLabel.text = string.format("%d级", curRecord.BattleLevel)

	self.Controls.m_FightNumLabel.text = tostring(IGame.PetClient:GetFightNum(UID)) 
	
	self:RefreshStar(UID)
	--self:RefreshCommonSkillList(UID)
	self:RefreshTalentAndHelpSkill(UID)
end

--刷新星级评分
function PetDisplayWidget:RefreshStar(UID)
	local starNum = IGame.PetClient:GetStarLevel(UID)
	for i = 1, 9 do
		if i <= starNum then
			UIFunction.SetImageSprite(self.m_petSkillStarImageCache[i], AssetPath_Star[2])	--亮
		else
			UIFunction.SetImageSprite(self.m_petSkillStarImageCache[i], AssetPath_Star[1])
		end
	end
end

--刷新天赋技能，援助技能
function PetDisplayWidget:RefreshTalentAndHelpSkill(UID)
	local talentSkillTable = IGame.PetClient:GetTalentSkill(UID)

	local talentSkillRecord_1 = IGame.rktScheme:GetSchemeInfo(PETSKILLBOOK_CSV, talentSkillTable[1].skill_id, talentSkillTable[1].skill_lv)
	local talentSkillRecord_2 = IGame.rktScheme:GetSchemeInfo(PETSKILLBOOK_CSV, talentSkillTable[2].skill_id, talentSkillTable[2].skill_lv)
	
	if talentSkillRecord_1 then
		UIFunction.SetImageSprite(self.Controls.m_TalentImage, AssetPath.TextureGUIPath .. talentSkillRecord_1.SkillIcon, function() self.Controls.m_TalentSkillParent.gameObject:SetActive(true) end)
        self.Controls.m_SkillNameLeft.text = talentSkillRecord_1.SkillName
		UIFunction.SetImageSprite(self.Controls.m_TalentSkillQuality_1, AssetPath_PetSkillQuality[talentSkillRecord_1.SkillQuality])
	end
	if talentSkillRecord_2 then
        self.Controls.m_SkillNameRight.text = talentSkillRecord_2.SkillName
		UIFunction.SetImageSprite(self.Controls.m_HelpImage, AssetPath.TextureGUIPath .. talentSkillRecord_2.SkillIcon, function() self.Controls.m_HelpSkillBG.gameObject:SetActive(true) end)
		UIFunction.SetImageSprite(self.Controls.m_TalentSkillQuality_2, AssetPath_PetSkillQuality[talentSkillRecord_2.SkillQuality])
	end
end

--刷新普通技能列表
function PetDisplayWidget:RefreshCommonSkillList(UID)
	local num = table.getn(self.m_petSkillScriptCache)
	
	if num == 0 then 
		local loadedNum = 0
		for	i = 1,8 do 
			rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetSkillItem ,
			function ( path , obj , ud )
				obj.transform:SetParent(self.Controls.m_SkillParentTrans, false)
				obj.transform.localScale = Vector3.New(1,1,1)
				local item = PetSkillItemClass:new({})
				item:Attach(obj)
				item:SetSelectCallback(self.OnPetSkillItemSelectedCB)
				
				item:SetIndex(i, UID)
				item:SetShowZheZhao(false)
                
				table.insert(self.m_petSkillScriptCache,i,item)	
				loadedNum = loadedNum + 1
				if loadedNum == 8 then
					self:RefreshCommonSkill(UID)
				end
				
			end , i , AssetLoadPriority.GuiNormal )
		end
	else
		self:RefreshCommonSkill(UID)
	end
end

--刷新通用技能 
function PetDisplayWidget:RefreshCommonSkill(UID)
	--获取本灵兽学习的技能		{id = 0, level = 0},
	local skillTable = IGame.PetClient:GetSkillTable(UID)
	if not skillTable then return end
	
	local skillSlotNum = IGame.PetClient:GetSkillSlot(UID)
	local skillNum = table.getn(skillTable)

	for i = 1, 8 do 
		if i <= skillSlotNum then
			if i <= skillNum then
				self.m_petSkillScriptCache[i]:SetViewByID(skillTable[i].id)
			else
				--设置空槽
				self.m_petSkillScriptCache[i]:SetAddImg(false)
			end	
		else
			--没开放技能,加锁
			self.m_petSkillScriptCache[i]:SetLock(true)
		end
	end
end

--点击灵兽普通技能回调  index - 技能槽索引
function PetDisplayWidget:OnPetSkillSelected(index, item)
	if item.m_SkillID == -1 then		--空技能
		return
	else
		--  TODO
	end
end

--改名按钮点击事件
function PetDisplayWidget:OnClickChangeNameBtn()
	local data = {
		title = AssetPath.TextureGUIPath.. "Pet_1/pet_lingshougaim.png",							--改名图片路径
		confirmCallBack = self.ChangeNameCB,
		content = "输入新的灵兽名字(最多5个字)",
		maxLimit = 10,
	}
	UIManager.InputPopWindow:ShowDiglog(data)
end
--请求改名
function PetDisplayWidget:ChangeNameConfirm(newName)
	
	if IsNilOrEmpty(newName) then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请输入灵兽名")
		return
	end 
	
	if utf8.wchar_size(newName) > 10  then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "灵兽的角色名过长，请重新输入")
		return
	end
	
	if StringFilter.FilterKeyWord(newName) then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "灵兽名含有屏蔽字，请重新输入！") 
		return
	end
	
	if StringFilter.CheckMoreSpaceStr(newName, 1) then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "灵兽名含有空格，请重新输入！") 
	end
	
	IGame.PetClient:ChangePetNameRequest(self.m_CurPetID, newName)
end

--特殊技能点击事件
function PetDisplayWidget:OnSpecialSkillClick()
	
end


--初始化左边灵兽列表
function PetDisplayWidget:InitPetList()
	local tableNum = table.getn(self.m_petItemScriptCache) 
	if tableNum > 0 then
		--销毁之前的
		for i, data in pairs(self.m_petItemScriptCache) do
			data:Destroy()
		end
	end
	self.m_petItemScriptCache = {}
	
	--从model中获取灵兽Table
	local petList = IGame.PetClient:GetCurPetTable()
	if not petList then return end
	local count = table.getn(petList)
	
	for	i = 1,count do 
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetIconItem,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_ItemParent, false)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = PetItemClass:new({})
			item:Attach(obj)
			item:SetToggleGroup(self.PetListGroup)
			item:SetClickAnimation(false)
			local id = IGame.PetClient:GetIDByUID(petList[i].uid)
			local petRecord = IGame.PetClient:GetRecordByID(id)
			if petRecord ~= nil then 
				local iconPath = petRecord.HeadIcon
				local level = IGame.PetClient:GetPetLevel(petList[i].uid)
				local isBattle = IGame.PetClient:IsBattleState(petList[i].uid)
				
				item:SetQuality(petRecord.Type)
				item:InitState(id, iconPath, level, isBattle, self.PetIconClickCB, petList[i].uid, true)			-- 这里赋值的是灵兽ID不是索引

				item:SetFocus(false)
				if i == 1 then
					item:SetFocus(true)
				end

				table.insert(self.m_petItemScriptCache,i,item)	
		    end 
		end , i , AssetLoadPriority.GuiNormal )
	end
end

--选中PetItem回调
function PetDisplayWidget:OnSelectPet(ID, item)
	if self.m_CurPetID == item.m_UID then
		return
	end
	
	self.m_CurPetID = item.m_UID	
	local name = IGame.PetClient:GetPetName(item.m_UID)
	IGame.PetClient:SetCurPetID(item.m_UID)			--设置model中的ID
	local resID = IGame.PetClient:GetPetResID(item.m_UID)
	--展示灵兽模型
	self.PetModelDisplay:ChangePet(resID)
	
	--这里通过事件系统解耦, 刷新右边界面
	rktEventEngine.FireExecute(EVENT_PET_CLICK_PETICON, SOURCE_TYPE_PET, 0,item.m_UID)		--刷新右边的界面,切换选中的灵兽
	self:RefreshMiddleWidget(item.m_UID)													--刷新中间的界面
end

--使用经验物品回调
function PetDisplayWidget:OnUseExpGoods(uid)
	for i, data in pairs(self.m_petItemScriptCache) do
		if data.m_UID == uid then
			local level = IGame.PetClient:GetPetLevel(uid)
			data:SetLevel(level)
			break
		end
	end
	if self.m_CurPetID == uid then
		self.Controls.m_PetLevelLabel.text = string.format("%d级", IGame.PetClient:GetPetLevel(uid))
	end
end 

----------------------------服务器返回回调， 刷新界面-----------------------------------------

--改名成功回调
function PetDisplayWidget:OnChangeName(msg)
	if not msg then return end 
	if msg.uidPet == self.m_CurPetID then
		self.Controls.m_PetNameLabel.text = IGame.PetClient:GetPetName(msg.uidPet)
	end
end

--灵兽出战返回
function PetDisplayWidget:OnGotoBattle(msg)
	if not msg then return end

	--刷新界面
	for i, data in pairs(self.m_petItemScriptCache) do
		local isBattle = IGame.PetClient:IsBattleState(data.m_UID)
		if isBattle then
			data:SetFight(true)
		else
			data:SetFight(false)
		end
	end
end

--灵兽放生返回
function PetDisplayWidget:OnFangSheng(msg)
	self:InitPetList()
	
	local a = ""
end



--关闭灵兽界面
function PetDisplayWidget:OnClosePetWindow()
	self.PetModelDisplay:ShowPetModel(false)
end
----------------------------------------------------------------------------------------------
return PetDisplayWidget
