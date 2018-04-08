
---------------------------灵兽系统培养界面---------------------------------------
local PetPropSliderItemClass = require( "GuiSystem.WindowList.Pet.PetPropSliderItem" )
local PetXiLianItemClass = require("GuiSystem.WindowList.Pet.Train.PetXiLianItem")
local PetSkillItemClass = require( "GuiSystem.WindowList.Pet.PetSkillItem" )
local PetGoodsItemClass = require( "GuiSystem.WindowList.Pet.PetSkillLearn.PetGoodsItem" )

local PetTrainWidget = UIControl:new
{
	windowName = "PetTrainWidget",
	m_PropSliderScriptCache = {},					--属性脚本缓存
	m_RightPropItemScriptCache = {},				--右侧新洗炼属性缓存
	m_TrainSkillItemScriptCache = {},				--技能训练script缓存
	m_TrainTalentSkillItemCache = {},				--天赋技能脚本缓存
	--应该共用，这里没共用							
	m_SkillGoodsCache = {},							--技能界面花费缓存
	m_TalentGoodsCache = {},						--天赋界面花费缓存
	
	m_StarImage = {},								--缓存星级组件
	m_RightStarImage = {},
	
	m_ID = nil, 									--缓存当前灵兽ID
	m_UID = -1,										--缓存的实体UID
	
	m_CurSkillID = -1,								--当前选中的技能ID
	m_CurSlot = -1,									--当前选中的技能槽
	m_CurCostIndex = -1, 							--当前升级普通技能消耗的物品索引, 不是goodsID
	
	m_TalentCurSlot = -1,							--天赋技能槽索引
	m_CurGoodsID = -1,								--当前天赋消耗物品ID
	m_CurTalentCostIndex = -1,						--当前升级天赋技能消耗物品索引， 不是goodsID
	m_TalentCostEnough = false,						--当前消耗物品是否够
	
	m_InitZiZhi = false,							--标识是否初始化完成,
	m_InitZiZhiRight = false, 						
	m_InitTrain = false,
	m_InitTalent = false,
	m_InitSkillGoods = false,
	m_InitTalentGoods = false,
	
	m_FirstShow = false,							--第一次显示
}

local SkillBtnPath = {
	AssetPath.TextureGUIPath.."Pet/pet_xuexi.png",										--学习
	AssetPath.TextureGUIPath.."Pet/pet_shengji.png",									--升级
	AssetPath.TextureGUIPath.."Pet/pet_shengji.png",									--已经满级
}

local propName = {
	"物攻资质",
	"法攻资质",
	"生命资质",
	"防御资质",
	"敏捷资质",
}

local protocolDefine = {
	CREATURE_PET_APTITUDE_PHYSICAL,						--力量
	CREATURE_PET_APTITUDE_SPELL,						--智力
	CREATURE_PET_APTITUDE_LIFE,							--根骨	
	CREATURE_PET_APTITUDE_AGILITY,						--敏捷
	CREATURE_PET_APTITUDE_DEFENCE,						--防御
}

function PetTrainWidget:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.m_InitTrain = false
	self.m_InitTalent = false
	self.m_InitSkillGoods = false
	self.m_InitTalentGoods = false
	
	self.Toggle = {
		self.Controls.m_SkillTrainToggle,
		self.Controls.m_TalentToggle,
	}
	
	self.SubPage = {
		self.Controls.m_SkillTrainPage,
		self.Controls.m_TalentTrainPage,
	}

	self.SkillTrainToggleGroup	= self.Controls.m_SkillTrainListParent.gameObject:GetComponent(typeof(ToggleGroup))
	self.TalentSkillGroup = self.Controls.m_TalentSkillGrid.gameObject:GetComponent(typeof(ToggleGroup))

	self.LateUpdatePage = function() self:LateRefresh() end
	self.SkillItemSelectedCB = function(nSlot, item) self:SkillItemClick(nSlot, item) end	
	self.TalentSkillSelectedCB = function(nSlot, item) self:TalentSkillClick(nSlot, item) end
	
	self.TalentCostClickCB = function(item) self:OnClickGoodsItem(item) end
	self.PassiveCostClickCB = function(item) self:OnClickPassiveGoodsItem(item) end
	
	--被动技能学习技能界面，option按钮点击事件
	self.PassiveOptionCB = function(item) self:OnPassiveOptionBtnClick(item) end
	
	self.m_FirstShow = true
	self:InitPetTrainView()
	
	self:RegisterEvent()
	
	--刷新界面事件注册
	self.UpdatePage = function(_,_,_,UID) self:RefreshPage(UID) end
	rktEventEngine.SubscribeExecute(EVENT_PET_CLICK_PETICON, SOURCE_TYPE_PET, 0, self.UpdatePage)
	
	--回包  监听,  剥离技能成功
	self.BoLiCB = function(_,_,_,uid, pos) self:OnBoLiMsg(uid, pos) end
	rktEventEngine.SubscribeExecute(EVENT_PET_BOLISUCCESS, SOURCE_TYPE_PET, 0, self.BoLiCB)
	--回包 监听， 升级天赋技能
	self.OnUpgradeCB = function(_,_,_,msg) self:OnUpgradeTalentMsg(msg) end
	rktEventEngine.SubscribeExecute(EVENT_PET_UPGRADETALENTSKILLSUC, SOURCE_TYPE_PET, 0, self.OnUpgradeCB)
	--回包 开孔 
	self.OnOpenSlotCB = function(_,_,_,uid, slotPos) self:OnOpenSlot(uid, slotPos) end
	rktEventEngine.SubscribeExecute(EVENT_PET_OPENSLOT, SOURCE_TYPE_PET, 0, self.OnOpenSlotCB)
	--回包 学习被动技能
	self.OnLearnPassiveSkillCB = function(_,_,_,msg) self:OnLearnPassiveSkill(msg) end
	rktEventEngine.SubscribeExecute(EVENT_PET_LEARNPASSIVESKILL, SOURCE_TYPE_PET, 0, self.OnLearnPassiveSkillCB)
	--回包 升级被动技能
	self.OnUpgradePassiveSkillCB = function(_,_,_,msg) self:OnOpgradePassiveSkill(msg) end
	rktEventEngine.SubscribeExecute(EVENT_PET_UPGRADEPASSIVESKILL, SOURCE_TYPE_PET, 0, self.OnUpgradePassiveSkillCB)
end

function PetTrainWidget:Show()
	local petTable = IGame.PetClient:GetCurPetTable()
	if table_count(petTable) > 0 then
		self:SetPet(true)
	else
		self:SetPet(false)
	end
	
	rktEventEngine.FireEvent(EVENT_PET_ClOSE_LEARNSKILLWIDGET, SOURCE_TYPE_PET, 0)
	UIControl.Show(self)
end

function PetTrainWidget:Hide( destroy )
	self.m_FirstShow = true
	if self.m_CurSlot > 0 then 
		self.m_TrainSkillItemScriptCache[self.m_CurSlot]:SetFocus(false)
	end
	rktEventEngine.FireEvent(EVENT_PET_ClOSE_LEARNSKILLWIDGET, SOURCE_TYPE_PET, 0)
	UIControl.Hide(self, destroy)
end

function PetTrainWidget:OnDestroy()
	rktEventEngine.UnSubscribeExecute(self.UpdatePage)
	rktTimer.KillTimer(self.LateUpdatePage)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_BOLISUCCESS, SOURCE_TYPE_PET, 0, self.BoLiCB)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_UPGRADETALENTSKILLSUC, SOURCE_TYPE_PET, 0, self.OnUpgradeCB)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_OPENSLOT, SOURCE_TYPE_PET, 0, self.OnOpenSlotCB)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_LEARNPASSIVESKILL, SOURCE_TYPE_PET, 0, self.OnOpenSlotCB)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_UPGRADEPASSIVESKILL, SOURCE_TYPE_PET, 0, self.OnUpgradePassiveSkillCB)
	UIControl.OnDestroy(self)	
end

--设置有没有灵兽显示
function PetTrainWidget:SetPet(havePet)
	if havePet then
		self.Controls.m_Pet.gameObject:SetActive(true)
		self.Controls.m_NoPet.gameObject:SetActive(false)
		self.Controls.m_SkillTrainToggle.isOn = true
		self.Controls.m_TalentToggle.isOn = false
	else
		self.Controls.m_Pet.gameObject:SetActive(false)
		self.Controls.m_NoPet.gameObject:SetActive(true)
	end
end

function PetTrainWidget:RegisterEvent()
	self.toggleChangeCB = function(on) self:OnToggleChanged(on,1) end
	self.Controls.m_SkillTrainToggle.onValueChanged:AddListener(self.toggleChangeCB)
	self.toggleChangeCB = function(on) self:OnToggleChanged(on,2) end
	self.Controls.m_TalentToggle.onValueChanged:AddListener(self.toggleChangeCB)
	
	--套装技能点击事件
	self.SuitBtnClickCB = function() rktEventEngine.FireEvent(EVENT_PET_OPENSUITTIPS,  SOURCE_TYPE_PET, 0, self.m_UID) end
	self.Controls.m_SkillSuitBtn.onClick:AddListener(self.SuitBtnClickCB)
	
	--技能 - 剥离
	self.BoLiCB = function() self:OnBoLiBtnClick() end
	self.Controls.m_SkillBoLiBtn.onClick:AddListener(self.BoLiCB)
	--技能 - 升级
	self.UpGradeSkillCB = function() self:OnUpgradeSkillBtnClick() end
	self.Controls.m_SkillUpgradeBtn.onClick:AddListener(self.UpGradeSkillCB)
	--天赋技能 - 升级
	self.UpGradeTalentSkillCb = function() self:OnUpgradeTalentBtnClick() end
	self.Controls.m_TalentUpgradeBtn.onClick:AddListener(self.UpGradeTalentSkillCb)
end

--Toggle切换事件
function PetTrainWidget:OnToggleChanged(on, index)
	if on then
		self.Toggle[index].transform:Find("Select").gameObject:SetActive(true)
		self.SubPage[index].gameObject:SetActive(true)
		if index == 1 then
			self.m_FirstShow = true
			if self.m_CurSlot > 0 then 
				self.m_TrainSkillItemScriptCache[self.m_CurSlot]:SetFocus(false)
			end
			self.m_FirstShow = true
			self.m_TrainSkillItemScriptCache[1]:SetFocus(false)
			self.m_TrainSkillItemScriptCache[1]:SetFocus(true)
		elseif index == 2 then
			
		end
	else
		self.SubPage[index].gameObject:SetActive(false)
		self.Toggle[index].transform:Find("Select").gameObject:SetActive(false)
	end
end

--初始化属性界面
function PetTrainWidget:InitPetTrainView()
	for i, data in pairs(self.m_TalentGoodsCache) do
		data:Destroy()
	end
	for i, data in pairs(self.m_SkillGoodsCache) do
		data:Destroy()
	end
	for i, data in pairs(self.m_TrainTalentSkillItemCache) do 
		data:Destroy()
	end
	self.m_PropSliderScriptCache = {}
	self.m_TrainSkillItemScriptCache = {}
	self.m_RightPropItemScriptCache = {}
	self.m_TrainTalentSkillItemCache = {}
	self.m_TalentGoodsCache = {}
	self.m_SkillGoodsCache = {}
	local skillNum = 0
	local talentNum = 0
	local skillCostNum = 0 							--优化， 共用
	local talentCostNum = 0
	
	for i = 1, 8 do 
	rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetSkillItem ,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_SkillTrainListParent, false)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = PetSkillItemClass:new({})
			item:Attach(obj)
			item:SetIndex(i)
			item:SetLevel(false)
			item:SetBG("Pet_1/Pet_p_di1.png")
			item:SetToggleGroup(self.SkillTrainToggleGroup)
			item:SetSelectCallback(self.SkillItemSelectedCB)
            item:SetShowZheZhao(false)
			table.insert(self.m_TrainSkillItemScriptCache,i,item)
			skillNum = skillNum + 1
			if skillNum == 8 then self.m_InitTrain = true end
		end , i , AssetLoadPriority.GuiNormal)
	end
	
	for i = 1, 2 do 
	rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetSkillItem ,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_TalentSkillGrid, false)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = PetSkillItemClass:new({})
			item:Attach(obj)
			item:SetIndex(i)
			item:SetBG("Pet_1/Pet_p_di1.png")
			item:SetToggleGroup(self.TalentSkillGroup)
			item:SetLevel(false)
			item:SetSelectCallback(self.TalentSkillSelectedCB)
			item:SetShowSelectEffect(true)
            item:SetShowZheZhao(false)
			table.insert(self.m_TrainTalentSkillItemCache,i,item)	
			talentNum = talentNum + 1
			if talentNum == 2 then self.m_InitTalent = true end
		end , i , AssetLoadPriority.GuiNormal)
	end
	

	for i = 1, 2 do 
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetGoodsItem ,
			function ( path , obj , ud )
				obj.transform:SetParent(self.Controls.m_TalentCostGrid, false)
				obj.transform.localScale = Vector3.New(1,1,1)
				local item = PetGoodsItemClass:new({})
				item:Attach(obj)				
				item:SetIndex(i)
				item:SetClickCB(self.TalentCostClickCB)
				table.insert(self.m_TalentGoodsCache,i,item)	
				talentCostNum = talentCostNum + 1
				if talentCostNum == 2 then self.m_InitTalentGoods = true end
			end , i , AssetLoadPriority.GuiNormal)
			
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetGoodsItem ,
			function ( path , obj , ud )
				obj.transform:SetParent(self.Controls.m_SkillTrainCostGrid, false)
				obj.transform.localScale = Vector3.New(1,1,1)
				local item = PetGoodsItemClass:new({})
				item:Attach(obj)
				item:SetIndex(i)
				item:SetClickCB(self.PassiveCostClickCB)
				table.insert(self.m_SkillGoodsCache,i,item)	
				skillCostNum = skillCostNum + 1
				if skillCostNum == 2 then self.m_InitSkillGoods = true end
			end , i , AssetLoadPriority.GuiNormal)
	end
end

--天赋消耗材料点击事件					--应该合并的， 先这样了
function PetTrainWidget:OnClickGoodsItem(item)
	item:SetSelected(true)
	self.m_CurGoodsID = item.m_GoodsID
	self.m_CurTalentCostIndex = item.m_Index
	for i, data in pairs(self.m_TalentGoodsCache) do
		if item ~= data then
			data:SetSelected(false)
		end
	end
	if item:CheckShowHowToGet() then		--材料不足,需要显示获取材料界面
		self.m_TalentCostEnough = false
		local subInfo = {
			bShowBtnType	= 2, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
		}
		UIManager.GoodsTooltipsWindow:SetGoodsInfo(item.m_GoodsID, subInfo )
	else
		self.m_TalentCostEnough = true
	end
end

--被动技能消耗材料点击事件 
function PetTrainWidget:OnClickPassiveGoodsItem(item)
	self.m_CurCostIndex = item.m_Index
	item:SetSelected(true)
	for i, data in pairs(self.m_SkillGoodsCache) do
		if item ~= data then
			data:SetSelected(false)
		end
	end

    local subInfo = {
        bShowBtnType	= 2, 		
    }
    UIManager.GoodsTooltipsWindow:SetGoodsInfo(item.m_GoodsID, subInfo )
end

--天赋技能点击技能回调
function PetTrainWidget:TalentSkillClick(nSlot, item)
	self.m_TalentCurSlot = nSlot
	local talentTable = IGame.PetClient:GetTalentSkill(self.m_UID)
	self:RefreshTalentBottom(talentTable[nSlot].skill_id, talentTable[nSlot].skill_lv)
end

--刷新界面
function PetTrainWidget:RefreshPage(UID)
	--更新缓存信息
	self.m_UID = UID
	self.m_ID = IGame.PetClient:GetIDByUID(UID)
	self.m_FirstShow = true
	
	local record = IGame.PetClient:GetRecordByUID(UID)	
	if not record then return end
	if record.Type == 1 then 
		self.Controls.m_OneGeneration.gameObject:SetActive(true)
		self.Controls.m_NotOneGenerationParent.gameObject:SetActive(false)
	else
		self.Controls.m_OneGeneration.gameObject:SetActive(false)
		self.Controls.m_NotOneGenerationParent.gameObject:SetActive(true)
		if self.m_InitTrain and self.m_InitTalent and self.m_InitTalentGoods and self.m_InitSkillGoods then 
			--self:RefreshZiZhiPage()
			self.Controls.m_SkillTrainToggle.isOn = true
			self.m_TrainTalentSkillItemCache[1]:SetFocus(true)
			self.m_TrainTalentSkillItemCache[2]:SetFocus(false)
			self:RefreshTrainPage()
			self:RefreshTalentPage()
		else
			--开启定时器，等异步加载完再刷新界面
			rktTimer.SetTimer(self.LateUpdatePage, 60, -1, "PetTrainWidget:LateRefresh")
		end
	end
end

--异步加载延迟刷新
function PetTrainWidget:LateRefresh()
	if self.m_InitTrain and self.m_InitTalent and self.m_InitTalentGoods and self.m_InitSkillGoods then 
		--self:RefreshZiZhiPage()
		self.Controls.m_SkillTrainToggle.isOn = true
		self.m_TrainTalentSkillItemCache[1]:SetFocus(true)
		self.m_TrainTalentSkillItemCache[2]:SetFocus(false)
		self:RefreshTrainPage()
		self:RefreshTalentPage()
		rktTimer.KillTimer(self.LateUpdatePage)
	end
end

--刷新天赋界面
function PetTrainWidget:RefreshTalentPage(index)
	local talentTable = IGame.PetClient:GetTalentSkill(self.m_UID)
	for i, data in pairs(self.m_TrainTalentSkillItemCache) do
		if i == 1 then data:SetFocus(true) end
		data:SetViewByID(talentTable[i].skill_id, talentTable[i].skill_lv)
	end
	self:RefreshTalentBottom(talentTable[1].skill_id, talentTable[1].skill_lv)
end

--刷新天赋界面底部
function PetTrainWidget:RefreshTalentBottom(id, level)
	local skillRecord = IGame.PetClient:GetSkillRecordByIDAndLevel(id, level)
	if not skillRecord then return end
	self.Controls.m_TalentSkillNameText.text = skillRecord.SkillName
	self.Controls.m_TalentSkillLevelText.text = string.format("%d级",level)
	self.Controls.m_TalentCurDesText.text = skillRecord.SkillDesc[1]
	if skillRecord.SkillDesc[2] ~= nil and skillRecord.SkillDesc[2] ~= "" then
		self.Controls.m_TalentNextDesText.text = skillRecord.SkillDesc[2]
	end
	
	--刷新底部消耗物品
	if skillRecord.FullLevel == 1 then 								-- 满级
		self.Controls.m_TalentFullLevelTrans.gameObject:SetActive(true)
		self.Controls.m_TalentBottomWidget.gameObject:SetActive(false)
		--[[self.m_TalentGoodsCache[1]:SetID(skillRecord.NeedGoodsID1)
		self.m_TalentGoodsCache[1]:SetGoodsNum(skillRecord.NeedGoodsNum1)
		self.m_TalentGoodsCache[2]:SetID(skillRecord.NeedGoodsID2)
		self.m_TalentGoodsCache[2]:SetGoodsNum(skillRecord.NeedGoodsNum2)--]]
	elseif skillRecord.FullLevel == 0 then
		local nextLevel = level + 1
		local nextRecord = IGame.PetClient:GetSkillRecordByIDAndLevel(id, nextLevel)
		if not nextRecord then return end
		self.Controls.m_TalentFullLevelTrans.gameObject:SetActive(false)
		self.Controls.m_TalentBottomWidget.gameObject:SetActive(true)
		self.m_TalentGoodsCache[1]:SetID(nextRecord.NeedGoodsID1)
		self.m_TalentGoodsCache[1]:SetGoodsNum(nextRecord.NeedGoodsNum1)
		self.m_TalentGoodsCache[2]:SetID(nextRecord.NeedGoodsID2)
		self.m_TalentGoodsCache[2]:SetGoodsNum(nextRecord.NeedGoodsNum2)
		
		local haveNum_1 =  GameHelp:GetHeroPacketGoodsNum(nextRecord.NeedGoodsID1)
		local haveNum_2 = GameHelp:GetHeroPacketGoodsNum(nextRecord.NeedGoodsID2)
		if haveNum_1 >= nextRecord.NeedGoodsNum1 then 					--1物品够
			self.m_TalentCostEnough = true
			self.m_CurTalentCostIndex = 1
		elseif haveNum_2 >= nextRecord.NeedGoodsNum2 then				--2物品够
			self.m_TalentCostEnough = true
			self.m_CurTalentCostIndex = 2
		else															--不够
			self.m_TalentCostEnough = false
			self.m_CurTalentCostIndex = 1
		end
		
		for i,data in pairs(self.m_TalentGoodsCache) do
			if i == self.m_CurTalentCostIndex then
				data:SetSelected(true)
			else
				data:SetSelected(false)
			end
		end
	end
	
	self.m_CurGoodsID = self.m_TalentGoodsCache[1].m_GoodsID
	
	--刷新底部学习按钮
	if skillRecord.FullLevel == 0 then 
		self.TalentFullLevel = false
		UIFunction.SetImageGray(self.Controls.m_TalentUpgradeBtnImg,false)
--		UIFunction.SetImageSprite(self.Controls.m_TalentUpgradeBtnOptionImg, SkillBtnPath[2])			--升级
		self.Controls.m_TalentYiManJiImg.gameObject:SetActive(false)
	else
		self.TalentFullLevel = true
		UIFunction.SetImageGray(self.Controls.m_TalentUpgradeBtnImg,true)
--		UIFunction.SetImageSprite(self.Controls.m_TalentUpgradeBtnOptionImg, SkillBtnPath[3])			--满级
		self.Controls.m_TalentYiManJiImg.gameObject:SetActive(true)
	end
end

--刷新训练界面
function PetTrainWidget:RefreshTrainPage()
	self:RefreshSkillTop()
end

--刷新技能界面
function PetTrainWidget:RefreshSkillTop(isOnMsg)
	local skillNum = table_count(self.m_TrainSkillItemScriptCache)
	local haveSlot = IGame.PetClient:GetSkillSlot(self.m_UID)
	local skillTable = IGame.PetClient:GetSkillTable(self.m_UID)
	local learnNum = 0
	
	for i,data in pairs(skillTable) do
		if data.skill_id > 0 then 
			learnNum = learnNum + 1
		end
	end

	for i = 1, skillNum do
		if i <= haveSlot then
			if i <= learnNum then				--空技能槽
				--技能显示
				self.m_TrainSkillItemScriptCache[i]:SetViewByID(skillTable[i].skill_id, skillTable[i].skill_lv)
                self.m_TrainSkillItemScriptCache[i]:SetLevel(true, skillTable[i].skill_lv)
			else
				self.m_TrainSkillItemScriptCache[i]:SetAddImg(true)
			end
			self.m_TrainSkillItemScriptCache[i]:SetShowSelectEffect(true)
		else
			--未开技能槽，加锁
			self.m_TrainSkillItemScriptCache[i]:SetLock(true)
			self.m_TrainSkillItemScriptCache[i]:SetShowSelectEffect(false)
		end
	end
	
	self.m_FirstShow = true
	if not isOnMsg then 
		self.m_TrainSkillItemScriptCache[1]:SetFocus(false)
		self.m_FirstShow = true
		self.m_TrainSkillItemScriptCache[1]:SetFocus(true)
	end
	
	self.Controls.m_SkillSuitText.text = IGame.PetClient:GetSuitNumAndID(self.m_UID)
end

--刷新技能界面底部信息, 技能Item选中回调
function PetTrainWidget:SkillItemClick(nSlot, item)
	local haveSlot = IGame.PetClient:GetSkillSlot(self.m_UID)
	local skillTable = IGame.PetClient:GetSkillTable(self.m_UID)
	
	local learnNum = 0
	local skillData
	for i,data in pairs(skillTable) do
		if data.skill_id > 0 then 
			learnNum = learnNum + 1
		end
		if data.skill_id == item.m_SkillID then
			skillData = data
		end
	end
	self.m_CurSlot = nSlot
	self.m_CurSkillID = item.m_SkillID
	
	if nSlot <= learnNum and nSlot <= haveSlot then  		--已经解锁的	
		local skillRecord = IGame.PetClient:GetSkillRecordByIDAndLevel(skillData.skill_id, skillData.skill_lv)
		if not skillRecord then return end
		if skillRecord.FullLevel == 1 then	--满级
			self:RefreshLearnSkillBottom(true,2)
		elseif skillRecord.FullLevel == 0 then	--可升级
			self:RefreshLearnSkillBottom(true,1)
		end
	elseif nSlot > learnNum and nSlot <= haveSlot then						--开孔了， 但是没有学习技能
		if not self.m_FirstShow then
			self:SkillItemClickLearnSkill(nSlot, item)
		end
		self:RefreshLearnSkillBottom(false)
	elseif nSlot > haveSlot and nSlot <= 8 then								--没开空，锁定状态
		if not self.m_FirstShow then
			self:SkillItemClickOpenSlot(nSlot, item)
		end
		self:RefreshLearnSkillBottom(false)
	end
	
	self.m_FirstShow = false
end

--点击技能槽的时候， 没开孔
function PetTrainWidget:SkillItemClickOpenSlot(nSlot, item)
	local contentStr, confirmFunc
	local skillTable = IGame.PetClient:GetSkillTable(self.m_UID)
	if not skillTable then return end
	local tmpSlot = 0
	for i, data in pairs(skillTable) do
		if data.is_open == 1 then 
			tmpSlot = tmpSlot + 1
		end
	end
	tmpSlot = tmpSlot + 1
	local goodsID = gPetCfg.PetOpenSkillSlot[tmpSlot].use_item_id
	local goodsNum =  gPetCfg.PetOpenSkillSlot[tmpSlot].use_item_num
	local haveNum = GameHelp:GetHeroPacketGoodsNum(goodsID)
	local goodsRecord = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodsID)
	if not goodsRecord then return end
	if haveNum < goodsNum then
		contentStr = string.format("确定消耗<color=red>%d</color>个%s开启1个技能槽吗?", goodsNum, goodsRecord.szName)
		confirmFunc = function() IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "材料不足") end
	else
		contentStr = string.format("确定消耗%d个%s开启1个技能槽吗?", goodsNum, goodsRecord.szName)
		confirmFunc = function() GameHelp.PostServerRequest("RequestPetPassiveSkillOpen("..tostring(self.m_UID) .. "," .. tmpSlot ..")") end
	end
	
	local data = {
		content = contentStr,
		confirmCallBack = confirmFunc
	}
	UIManager.ConfirmPopWindow:ShowDiglog(data)
end

--点击技能槽，学习技能
function PetTrainWidget:SkillItemClickLearnSkill(nSlot, item)
	rktEventEngine.FireEvent(EVENT_PET_OPENSKILLLEARN,SOURCE_TYPE_PET, 0, 1, self.PassiveOptionCB)
end

--被动技能学些界面， option按钮点击事件
function PetTrainWidget:OnPassiveOptionBtnClick(item)
	IGame.PetClient:LearnPassiveSkillRequest(self.m_UID,item.m_GoodsID, self.m_CurSlot)
end

--刷新技能界面底部, state  1:升级 2:满级 
function PetTrainWidget:RefreshLearnSkillBottom(show, state)
	self.Controls.m_SkillBottom.gameObject:SetActive(show)
	if not show then return end
	local skillData
	local skillTable = IGame.PetClient:GetSkillTable(self.m_UID)
	for i, data in pairs(skillTable) do
		if data.skill_id == self.m_CurSkillID then 
			skillData = data
		end
	end
	
	local skillRecord = IGame.PetClient:GetSkillRecordByIDAndLevel(skillData.skill_id, skillData.skill_lv)
	self.Controls.m_SkillNameText.text = skillRecord.SkillName				--技能名字
	self.Controls.m_SkillLevelText.text = string.format("%d级", skillData.skill_lv)				--当前技能等级
	self.Controls.m_CurLevelDesText.text = skillRecord.SkillDesc[1]			--当前技能描述
	if not skillRecord.SkillDesc[2] then
		self.Controls.m_NextLevelDesText.text = ""
	else
		self.Controls.m_NextLevelDesText.text = skillRecord.SkillDesc[2]
	end

	if state == 2 then
		self.PassiveFullLevel = true
		self.Controls.m_FullLevelTrans.gameObject:SetActive(true)
		self.Controls.m_SkillBottomWidget.gameObject:SetActive(false)
		return
	end

	if state == 2 then									--满级了,执行不到，预留
		self.PassiveFullLevel = true
		self.Controls.m_FullLevelTrans.gameObject:SetActive(true)
		self.Controls.m_SkillBottomWidget.gameObject:SetActive(false)
		UIFunction.SetImageGray(self.Controls.m_SkillOptionBtnImage, true)	
		self.Controls.m_SkillYiManJiImg.gameObject:SetActive(true)
		self.Controls.m_SkillTrainCostGrid.gameObject:SetActive(false)
		self.m_SkillGoodsCache[1]:SetID(skillRecord.NeedGoodsID1)
		self.m_SkillGoodsCache[1]:SetGoodsNum(skillRecord.NeedGoodsNum1)
		self.m_SkillGoodsCache[2]:SetID(skillRecord.NeedGoodsID2)
		self.m_SkillGoodsCache[2]:SetGoodsNum(skillRecord.NeedGoodsNum2)
	else
		self.PassiveFullLevel = false
		UIFunction.SetImageGray(self.Controls.m_SkillOptionBtnImage, false)
		self.Controls.m_SkillYiManJiImg.gameObject:SetActive(false)
		self.Controls.m_FullLevelTrans.gameObject:SetActive(false)
		self.Controls.m_SkillBottomWidget.gameObject:SetActive(true)
		local nextLevel = skillData.skill_lv + 1
		local nextRecord = IGame.PetClient:GetSkillRecordByIDAndLevel(skillData.skill_id, nextLevel)
		if not nextRecord then return end
		self.Controls.m_SkillTrainCostGrid.gameObject:SetActive(true)
		self.m_SkillGoodsCache[1]:SetID(nextRecord.NeedGoodsID1)
		self.m_SkillGoodsCache[1]:SetGoodsNum(nextRecord.NeedGoodsNum1)
		self.m_SkillGoodsCache[2]:SetID(nextRecord.NeedGoodsID2)
		self.m_SkillGoodsCache[2]:SetGoodsNum(nextRecord.NeedGoodsNum2)
		if not self.OnMsg then 
			self.OnMsg = false
			local haveNum_1 =  GameHelp:GetHeroPacketGoodsNum(nextRecord.NeedGoodsID1)
			local haveNum_2 = GameHelp:GetHeroPacketGoodsNum(nextRecord.NeedGoodsID2)
			if haveNum_1 >= nextRecord.NeedGoodsNum1 then
				self.m_SkillGoodsCache[1]:SetSelected(true)
				self.m_SkillGoodsCache[2]:SetSelected(false)
				self.m_CurCostIndex = 1
			elseif haveNum_2 >= nextRecord.NeedGoodsNum2 then
				self.m_SkillGoodsCache[2]:SetSelected(true)
				self.m_SkillGoodsCache[1]:SetSelected(false)
				self.m_CurCostIndex = 2
			else
				self.m_SkillGoodsCache[1]:SetSelected(true)
				self.m_SkillGoodsCache[2]:SetSelected(false)
				self.m_CurCostIndex = 1
			end
		end
	end	
end

--------------------------------------------------------------------
----------------------点击事件--------------------------------------
--剥离Btn点击
function PetTrainWidget:OnBoLiBtnClick()
	local contentStr
	local skillTable = IGame.PetClient:GetSkillByIndex(self.m_UID, self.m_CurSlot)
	if not skillTable then return end
	local skillRecord = IGame.PetClient:GetSkillRecordByIDAndLevel(skillTable.skill_id,skillTable.skill_lv)
	if not skillRecord then return end 
	contentStr = string.format("确认要剥离%d级的%s技能么？", skillTable.skill_lv, skillRecord.SkillName)
    local bookName = GameHelp.GetLeechdomColorName(skillRecord.NeedGoodsID1)
    local strRet = ""
    if bookName then 
        strRet = "\n剥离获得"..bookName.." * 1"
    end 
    
    if skillRecord.ReturnNum  > 0 then 
        local goodName = GameHelp.GetLeechdomColorName(skillRecord.ReturnGoods)
        if goodName then
            strRet = strRet.."，"..goodName.." * "..skillRecord.ReturnNum
        end                
    end 
    
    contentStr = contentStr..strRet
	local data = {
		content = contentStr,
		confirmCallBack = function() GameHelp.PostServerRequest("RequestPetRemovePassiveSkill(".. tostring(self.m_UID) .. "," .. self.m_CurSlot ..")") end
	}
	UIManager.ConfirmPopWindow:ShowDiglog(data)	
end

--普通技能升级Btn点击			 加一些判断  	TODO
function PetTrainWidget:OnUpgradeSkillBtnClick()
	if self.PassiveFullLevel or self.m_CurCostIndex < 1 or self.m_CurCostIndex > 2 then
		return
	end 
		
	local skillTable = IGame.PetClient:GetSkillByIndex(self.m_UID, self.m_CurSlot)
	if not skillTable then return end
	local skillRecord = IGame.PetClient:GetSkillRecordByIDAndLevel(skillTable.skill_id,skillTable.skill_lv+1)
	if not skillRecord then return end 
        
    if GameHelp:GetHeroPacketGoodsNum(skillRecord.NeedGoodsID1) >= skillRecord.NeedGoodsNum1 then 
        IGame.PetClient:UpgradePassiveSkillRequest(self.m_UID, self.m_CurSlot, 1)
        return
    end 
    
    if GameHelp:GetHeroPacketGoodsNum(skillRecord.NeedGoodsID2) >= skillRecord.NeedGoodsNum2 then 
        IGame.PetClient:UpgradePassiveSkillRequest(self.m_UID, self.m_CurSlot, 2)
        return        
    end 

    IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "材料不足")
end

--升级天赋技能		加一些判断
function PetTrainWidget:OnUpgradeTalentBtnClick()
	if self.TalentFullLevel then
		return
	else
		if self.m_TalentCostEnough then 
			IGame.PetClient:UpgradeTalentSkillRequest(self.m_UID, self.m_TalentCurSlot, self.m_CurTalentCostIndex)
		else
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "材料不足")
		end
	end

end

---------------------------服务器返回响应-----------------------------------------
--剥离返回
function PetTrainWidget:OnBoLiMsg(uid, pos)
	rktEventEngine.FireEvent(EVENT_PET_REFRESHPROPWIDGET, SOURCE_TYPE_PET, 0)
	self:OnMsgRefreshView(false)
end

--升级天赋技能返回
function PetTrainWidget:OnUpgradeTalentMsg(msg)
	local talentTable = IGame.PetClient:GetTalentSkill(self.m_UID)
	self:RefreshTalentBottom(talentTable[self.m_TalentCurSlot].skill_id, talentTable[self.m_TalentCurSlot].skill_lv)
	rktEventEngine.FireEvent(EVENT_PET_REFRESHPROPWIDGET, SOURCE_TYPE_PET, 0)
end

--回包 , 开孔
function PetTrainWidget:OnOpenSlot(uid, slotPos)
	self:OnMsgRefreshView()
end

--回包， 学习被动技能
function PetTrainWidget:OnLearnPassiveSkill(msg)
	rktEventEngine.FireEvent(EVENT_PET_REFRESHPROPWIDGET, SOURCE_TYPE_PET, 0)
	self:OnMsgRefreshView()
end

--回包， 升级被动技能
function PetTrainWidget:OnOpgradePassiveSkill(msg)
	rktEventEngine.FireEvent(EVENT_PET_REFRESHPROPWIDGET, SOURCE_TYPE_PET, 0)		--刷新属性界面
	self:OnMsgRefreshView()
end

--回包统一刷新
function PetTrainWidget:OnMsgRefreshView(click)
	self:RefreshSkillTop(true)
	local curItem
	for i,data in pairs(self.m_TrainSkillItemScriptCache) do
		if self.m_CurSlot == data.m_Index then
			curItem = data
			break
		end
	end
	self.OnMsg = true
	self.m_FirstShow = true
	if curItem and not click then
		self:SkillItemClick(self.m_CurSlot,curItem)
	end
end


return PetTrainWidget
