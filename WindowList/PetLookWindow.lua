
--------------------------------------灵兽界面------------------------------------------
local PetPropertyItemClass = require("GuiSystem.WindowList.Pet.PetPropertyItem")
local PetSkillItemClass = require( "GuiSystem.WindowList.Pet.PetSkillItem" )
local PetModelDisPlayClass = require( "GuiSystem.WindowList.Pet.PetModelDisplay" )
local BasePropName = {
	"物理攻击",
	"法术攻击",
	"物理防御",
	"法术防御",
	"命中",
	"躲闪",
}

local ZiZhiPropName = {
	"物攻资质",
	"法攻资质",
	"生命资质",
	"防御资质",
	"敏捷资质",	
}

local PetLookWindow = UIWindow:new
{
	windowName 	= "PetLookWindow",
	m_petSkillStarImageCache = {},				--星级图标缓存
	
	m_BasePropItemCache = {},					--基础属性脚本缓存
	m_ZiZhiPropItemCache = {},					--资质脚本缓存
	m_SkillItemCache = {},						--技能脚本缓存
	
	m_MasterDBID = nil, 						--主人DBID
	m_PetDBID = nil, 							--灵兽DBID
	m_OwnPet = false,							--是否是自己的灵兽
	
	m_InitBaseProp = false,						--初始化基础属性完成
	m_InitZiZhiProp = false,					--初始化资质属性完成
	m_InitSkillItem = false,					--初始化技能信息
}	

function PetLookWindow:Init()

end

function PetLookWindow:OnAttach(obj)
	UIWindow.OnAttach(self,obj)	
	
	self.LateShowCB = function() self:LateShow() end
	
	self.PetModelDisPlay = PetModelDisPlayClass:new()
	self.PetModelDisPlay:SetUID(70)
	self.PetModelDisPlay:Attach(self.Controls.m_RawImageTrans.gameObject)
	
	self.CloseWin = function() self:Hide() end 
	self.Controls.m_CloseWindow.onClick:AddListener(self.CloseWin)
	
	self:CacheStarImageCom()
	self:InitView()
	
	if self.NeedShow then 					--延迟显示
		self.NeedShow = false
		rktTimer.SetTimer(self.LateShowCB, 30, -1, "PetLookWindow:LateShow()")
	end
end

function PetLookWindow:Show( bringTop )
	UIWindow.Show(self, bringTop)
end
 
function PetLookWindow:Hide(destory)
	self.PetModelDisPlay:ShowPetModel(false)
	UIWindow.Hide(self, destory)
end

function PetLookWindow:OnDestroy()
	self.NeedShow = nil
	self.m_InitBaseProp = false					
	self.m_InitZiZhiProp = false				
	self.m_InitSkillItem = false
	self.PetData = nil
	self.PetModelDisPlay:ShowPetModel(false)
	UIWindow.OnDestroy(self)
end	
-----------------------------------------------------------------------------------------------
--对外接口, 显示界面
function PetLookWindow:ShowLookPetWindow(master_dbid, pet_dbid)
	self.m_MasterDBID = master_dbid
	self.m_PetDBID = pet_dbid
	self.m_OwnPet = GameHelp:IsMainHero(master_dbid) 
	if self.m_OwnPet then 						--数据缓存
		local uid = IGame.PetClient:GetPetUIDByDBID(pet_dbid)
		self.UID = uid   						--自己的灵兽UID，
	else
		local petData = IGame.PetClient:GetObservePetData(self.m_MasterDBID, self.m_PetDBID)
		if not petData then return end
		self.PetData = petData
	end
	if self:isLoaded() then
		self:LateShow()
	else
		self.NeedShow = true
	end
	UIWindow.Show(self,true)
end
-----------------------------------------------初始化方法-----------------------------------------------------------------
--初始化界面控件
function PetLookWindow:InitView()
	self:ClearCache(self.m_BasePropItemCache)
	self:ClearCache(self.m_ZiZhiPropItemCache)
	self:ClearCache(self.m_SkillItemCache)
	
	self.m_BasePropItemCache = {}
	self.m_ZiZhiPropItemCache = {}
	self.m_SkillItemCache = {}
	
	self.HPSlider = self.Controls.m_HPSlider:GetComponent(typeof(Slider))
	
	local baseNum = 0
	local ziZhiNum = 0
	--基础信息
	for i = 1,6 do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetPropertyItem ,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_BasePropListParent)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = PetPropertyItemClass:new({})
			item:Attach(obj)
			item:InitView(BasePropName[i],0)
			table.insert(self.m_BasePropItemCache,i,item)	
			baseNum = baseNum + 1
			if baseNum == 6 then
				self.m_InitBaseProp = true
			end
		end , i , AssetLoadPriority.GuiNormal )
	end
	--资质信息
	for i = 1, 5 do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetPropertyItem ,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_ZiZhiPropListParent)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = PetPropertyItemClass:new({})
			item:Attach(obj)
			item:InitView(ZiZhiPropName[i],0)
			table.insert(self.m_ZiZhiPropItemCache,i,item)	
			ziZhiNum = ziZhiNum + 1
			if ziZhiNum == 5 then
				self.m_InitZiZhiProp = true
			end
		end , i , AssetLoadPriority.GuiNormal )
	end
	
	--
	local loadedNum = 0
	--技能槽
	for i = 1,8 do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetSkillItem ,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_SkillList, false)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = PetSkillItemClass:new({})
			item:Attach(obj)
			
			item:SetIndex(i)
			item:SetBG("Pet_1/Pet_p_di1.png")
			item:SetLevel(false)
			item:SetAddImg(false)
            item:SetShowZheZhao(false)
			--[[item:SetToggleGroup(self.SkillToggleGroup)
			item:SetSelectCallback(self.SkillClickCB)
			item:SetShowSelectEffect(true)--]]
			table.insert(self.m_SkillItemCache,i,item)	
			loadedNum = loadedNum + 1
			if loadedNum == 8 then
				self.m_InitSkillItem = true
			end
		end , i , AssetLoadPriority.GuiNormal )
	end
end

--清空操作
function PetLookWindow:ClearCache(nTable)
	if not nTable then return end
	local num = table.getn(nTable)
	
	if num > 0 then
		for i, data in pairs(nTable) do
			data:Destroy()
		end
	end
	nTable = {}
end

--缓存星级image
function PetLookWindow:CacheStarImageCom()
	self.m_petSkillStarImageCache = {}
	
	for	i = 1, 9 do
		local child = self.Controls.m_StarParent:GetChild(i-1)
		local image = child:GetComponent(typeof(Image))
		if image then
			table.insert(self.m_petSkillStarImageCache,i,image)
		end
	end
end
-----------------------------------------------显示方法------------------------------------------------------
--加载完成延迟显示 
function PetLookWindow:LateShow()
	if self.m_InitBaseProp and self.m_InitZiZhiProp and self.m_InitSkillItem then
		self.PetModelDisPlay:SetModePosition(Vector3.New(-2.91,1.02))	
		self.PetModelDisPlay:ShowPetModel(true,1)			--生成显示组件
		if self.m_OwnPet then
			self:SetOwnLeftShow(self.UID)
			self:RefreshOwnRightView(self.UID)
		else
			self:SetOtherLeftShow(self.PetData)
			self:RefreshOtherRightView(self.PetData)
		end
		rktTimer.KillTimer(self.LateShowCB)
	end
end
-------------------------------------------------------------------------------------------------------------

--设置自己的灵兽显示左边
function PetLookWindow:SetOwnLeftShow(uid)
	local record = IGame.PetClient:GetRecordByUID(uid)
	if not record then
		uerror("读取灵兽表失败,灵兽UID：" .. tostring(uid))
		return 
	end
	UIFunction.SetImageSprite(self.Controls.m_GenerationImage, AssetPath_PetQuality[record.Type])				--一、二代
	UIFunction.SetImageSprite(self.Controls.m_TypeImage, AssetPath_PetType[record.BattleType])					--战斗类型
	local growType = IGame.PetClient:GetGrowRate(uid)
	UIFunction.SetImageSprite(self.Controls.m_GrowTypeImage, AssetPath_PetGrowType[growType])
	self.Controls.m_TakeLevelText.text = record.BattleLevel
	local petLevel = IGame.PetClient:GetPetLevel(uid)
	local name = IGame.PetClient:GetPetName(uid)
	local fightNum = IGame.PetClient:GetFightNum(uid)
	self.Controls.m_LevelText.text = string.format("%d级", petLevel)
	self.Controls.m_NameText.text = name
	self.Controls.m_FightNumText.text = tostring(fightNum)
	local starNum = IGame.PetClient:GetStarLevel(uid)
	for i = 1, 9 do
		if i <= starNum then
			UIFunction.SetImageSprite(self.m_petSkillStarImageCache[i], AssetPath_Star[2])	--亮
		else
			UIFunction.SetImageSprite(self.m_petSkillStarImageCache[i], AssetPath_Star[1])
		end
	end
	local talentSkillTable = IGame.PetClient:GetTalentSkill(uid)

	local talentSkillRecord_1 = IGame.rktScheme:GetSchemeInfo(PETSKILLBOOK_CSV, talentSkillTable[1].skill_id, talentSkillTable[1].skill_lv)
	local talentSkillRecord_2 = IGame.rktScheme:GetSchemeInfo(PETSKILLBOOK_CSV, talentSkillTable[2].skill_id, talentSkillTable[2].skill_lv)

	if talentSkillRecord_1 then
		UIFunction.SetImageSprite(self.Controls.m_TalentSkillIcon, AssetPath.TextureGUIPath .. talentSkillRecord_1.SkillIcon)
		UIFunction.SetImageSprite(self.Controls.m_TalentSkillQuality, AssetPath_PetSkillQuality[talentSkillRecord_1.SkillQuality])
	end
	if talentSkillRecord_2 then
		UIFunction.SetImageSprite(self.Controls.m_HelpSkillIcon, AssetPath.TextureGUIPath .. talentSkillRecord_2.SkillIcon)
		UIFunction.SetImageSprite(self.Controls.m_HelpSkillQuality, AssetPath_PetSkillQuality[talentSkillRecord_2.SkillQuality])
	end
	
	--设置模型显示
	if not self.PetModelDisPlay:HaveInit() then
		self.PetModelDisPlay:ShowPetModel(true)
	end
	local resID = IGame.PetClient:GetPetResID(uid)
	self.PetModelDisPlay:ChangePet(resID)
end

--设置其他人的左边显示
function PetLookWindow:SetOtherLeftShow(petData)
	local petRecord = IGame.PetClient:GetRecordByID(petData.PetId)
	if not petRecord then return end
	UIFunction.SetImageSprite(self.Controls.m_GenerationImage, AssetPath_PetQuality[petRecord.Type])				--一、二代
	UIFunction.SetImageSprite(self.Controls.m_TypeImage, AssetPath_PetType[petRecord.BattleType])					--战斗类型
	UIFunction.SetImageSprite(self.Controls.m_GrowTypeImage, AssetPath_PetGrowType[petData.nGrowth])				--成长率	
	self.Controls.m_LevelText.text = string.format("%d级", petData.lLevel)
	self.Controls.m_NameText.text = petData.szPetName
	self.Controls.m_FightNumText.text = tostring(petData.nPower)
	self.Controls.m_TakeLevelText.text = petRecord.BattleLevel
	for i = 1, 9 do
		if i <= petData.nStarLv then
			UIFunction.SetImageSprite(self.m_petSkillStarImageCache[i], AssetPath_Star[2])	--亮
		else
			UIFunction.SetImageSprite(self.m_petSkillStarImageCache[i], AssetPath_Star[1])
		end
	end
	local talentSkillRecord_1 = IGame.rktScheme:GetSchemeInfo(PETSKILLBOOK_CSV, petData.talent_skill[1].skill_id, petData.talent_skill[1].skill_lv)
	local talentSkillRecord_2 = IGame.rktScheme:GetSchemeInfo(PETSKILLBOOK_CSV, petData.talent_skill[2].skill_id, petData.talent_skill[1].skill_id)
	if talentSkillRecord_1 then
		UIFunction.SetImageSprite(self.Controls.m_TalentSkillIcon, AssetPath.TextureGUIPath .. talentSkillRecord_1.SkillIcon)
		UIFunction.SetImageSprite(self.Controls.m_TalentSkillQuality, AssetPath_PetSkillQuality[talentSkillRecord_1.SkillQuality])
	end
	if talentSkillRecord_2 then
		UIFunction.SetImageSprite(self.Controls.m_HelpSkillIcon, AssetPath.TextureGUIPath .. talentSkillRecord_2.SkillIcon)
		UIFunction.SetImageSprite(self.Controls.m_HelpSkillQuality, AssetPath_PetSkillQuality[talentSkillRecord_2.SkillQuality])
	end
		
	--设置模型显示
	if not self.PetModelDisPlay:HaveInit() then
		self.PetModelDisPlay:ShowPetModel(true)
	end
	local record = IGame.PetClient:GetRecordByID(petData.PetHuanHuaID)
	self.PetModelDisPlay:ChangePet(record.ModelResource)
end

--设置自己的右边显示
function PetLookWindow:RefreshOwnRightView(UID)
	--血条
	local curHP = IGame.PetClient:GetNumProp(UID,CREATURE_PROP_CUR_HP)
	local maxHP = IGame.PetClient:GetNumProp(UID,CREATURE_PROP_MAX_HP)
	self.Controls.m_HPText.text = string.format("%d/%d", curHP, maxHP)
	self.HPSlider.value = curHP / maxHP
	
	--基础
	local physicsAttack = IGame.PetClient:GetNumProp(UID, CREATURE_PROP_CUR_P_A)
	local magicAttack = IGame.PetClient:GetNumProp(UID, CREATURE_PROP_CUR_M_A)
	local physicsDefence = IGame.PetClient:GetNumProp(UID, CREATURE_PROP_CUR_P_D)
	local magicDefence = IGame.PetClient:GetNumProp(UID, CREATURE_PROP_CUR_M_D)
	local hitPresent = IGame.PetClient:GetNumProp(UID, CREATURE_PROP_CUR_PRESENT)
	local hedge = IGame.PetClient:GetNumProp(UID, CREATURE_PROP_CUR_HEDGE)
	
	local baseValue = {
		physicsAttack,
		magicAttack,
		physicsDefence,
		magicDefence,
		hitPresent,
		hedge,
	}
	
	for i = 1, 6 do 
		self.m_BasePropItemCache[i]:SetValue(baseValue[i])
	end
	
	--资质
	local power = IGame.PetClient:GetNumProp(UID, CREATURE_PET_APTITUDE_PHYSICAL)					--物攻
	local intelligence = IGame.PetClient:GetNumProp(UID, CREATURE_PET_APTITUDE_SPELL)		--法功
	local vitality = IGame.PetClient:GetNumProp(UID, CREATURE_PET_APTITUDE_LIFE)				--生命
	local agility = IGame.PetClient:GetNumProp(UID, CREATURE_PET_APTITUDE_AGILITY)					--敏捷
	local energy = IGame.PetClient:GetNumProp(UID, CREATURE_PET_APTITUDE_DEFENCE)					--防御
	
	local ziZhiValue = {
		power,
		intelligence,
		vitality,
		energy,
		agility,
	}
	
	for i = 1, 5 do
		self.m_ZiZhiPropItemCache[i]:SetValue(ziZhiValue[i])
	end
	
	--技能
	local num = IGame.PetClient:GetSuitNumAndID(UID)
	self.Controls.m_SkillSuitText.text = tostring(num)
	
	local skillTable = IGame.PetClient:GetSkillTable(UID)
	local haveSlot = IGame.PetClient:GetSkillSlot(UID)
	local learnNum = 0
	for i,data in pairs(skillTable) do
		if data.skill_id > 0 then 
			learnNum = learnNum + 1
		end
	end
	for i, data in pairs(self.m_SkillItemCache) do
		data:SetUID(UID)
		
		if i <= haveSlot then 
			if skillTable[i].skill_id > 0 then				--学过技能
				data:SetViewByID(skillTable[i].skill_id, skillTable[i].skill_lv)
			else											--槽开了，没学技能
				data:Clear()
			end
		else
			data:SetLock(true)
		end
	end
end

--设置他人右边显示
function PetLookWindow:RefreshOtherRightView(petData)
	self.Controls.m_HPText.text = string.format("%d/%d", petData.lHp, petData.lMaxHp)
	self.HPSlider.value = petData.lHp / petData.lMaxHp
	
	--基础
	local physicsAttack = petData.nPhysicalAttack
	local magicAttack = petData.nSpellAttack
	local physicsDefence = petData.nPhysicalDefence
	local magicDefence = petData.nSpellDefence
	local hitPresent = petData.nPresent
	local hedge = petData.nHEDGE
	
	local baseValue = {
		physicsAttack,
		magicAttack,
		physicsDefence,
		magicDefence,
		hitPresent,
		hedge,
	}
	
	for i = 1, 6 do 
		self.m_BasePropItemCache[i]:SetValue(baseValue[i])
	end
	
	--资质
	local power = petData.nAptitudePhysical
	local intelligence = petData.nAptitudeSpell
	local vitality = petData.nAptitudeDefence
	local agility = petData.nAptitudeAgility
	local energy = petData.nAptitudeLife
	
	local ziZhiValue = {
		power,
		intelligence,
		vitality,
		energy,
		agility,
	}
	
	for i = 1, 5 do
		self.m_ZiZhiPropItemCache[i]:SetValue(ziZhiValue[i])
	end
	
	--技能
	local num = IGame.PetClient:GetSuitNumBySkills(petData.passive_skill)
	self.Controls.m_SkillSuitText.text = tostring(num)
	
	local learnNum = 0
	local haveSlot = 0
	for i,data in pairs(petData.passive_skill) do
		if data.skill_id > 0 then 
			learnNum = learnNum + 1
		end
		if data.is_open > 0 then
			haveSlot = haveSlot + 1
		end
	end
	for i, data in pairs(self.m_SkillItemCache) do
		if i <= haveSlot then 
			if petData.passive_skill[i].skill_id > 0 then				--学过技能
				data:SetViewByID(petData.passive_skill[i].skill_id,petData.passive_skill[i].skill_lv)
			else											--槽开了，没学技能
				data:Clear()
			end
		else
			data:SetLock(true)
		end
	end
end

return PetLookWindow