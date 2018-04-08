
---------------------------灵兽系统属性展示界面---------------------------------------
local PetPropertyItemClass = require("GuiSystem.WindowList.Pet.PetPropertyItem")
local PetSkillItemClass = require( "GuiSystem.WindowList.Pet.PetSkillItem" )

local PetPropertyWidget = UIControl:new
{
	windowName = "PetPropertyWidget",
	
	m_BasePropScriptCache = {},   				--基础信息缓存
	m_ZiZhiPropScriptCahce = {},				--资质信息缓存
	m_SkillScriptCache = {},					--技能列表item缓存
	
	m_UID = -1, 								--当前实体ID
	m_PetID = -1, 								--当前灵兽ID
	
	CurSlotItem = nil, 							--当前点击的技能槽缓存
	
	
	m_InitBase = false,						--是否加载基础属性item
	m_InitZiZhi = false,						--是否加载完资质属性item
	m_InitSkill = false,						--是否加载完技能item
}

local BasePropName = {
	"物理攻击",
	"法术攻击",
	"物理防御",
	"法术防御",
	"命中",
	"躲闪",
}

local BasePropEnum = {
	
}

local ZiZhiPropName = {
	"物攻资质",
	"法攻资质",
	"生命资质",
	"防御资质",
	"敏捷资质",	
}

local BattleOrRelaxPath = {
	AssetPath.TextureGUIPath .. "Pet_1/pet_xiuxi.png",									--休息按钮
	AssetPath.TextureGUIPath .. "Pet_1/pet_chuzhan.png",								--出战按钮
}

function PetPropertyWidget:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.PetUseGoodsWidget = require("GuiSystem.WindowList.Pet.Property.PetUseGoodsWidget"):new()
	self.PetUseGoodsWidget:Attach(self.Controls.m_PetUseGoodsWidget.gameObject)
	
	self.SkillToggleGroup = self.Controls.m_SkillListGrid:GetComponent(typeof(ToggleGroup))
	--控件缓存
	self.HPSlider = self.Controls.m_HPSlider:GetComponent(typeof(Slider))
	self.EXPSlider = self.Controls.m_EXPSlider:GetComponent(typeof(Slider))
	
	self.m_InitBase = false
	self.m_InitZiZhi = false
	self.m_InitSkill = false
	--生成属性列表
	self:InitPropView()
	self:InitSkillView()
	
	self.toggle = {
		self.Controls.m_PropertyToggle,
		self.Controls.m_SkillToggle,
	}
	self.PageGameObject = {
		self.Controls.m_PropertyPage.gameObject,
		self.Controls.m_SkillPage.gameObject,
	}
	
	--放生按钮点击事件
	self.FanShengBtnClickCB = function() self:OnClickFangShengBtn() end
	self.Controls.m_FanShengBtn.onClick:AddListener(self.FanShengBtnClickCB)
	
	--出战按钮点击事件
	self.GOTOBattleBtnClickCB = function() self:OnClickGOTOBattleBtn() end
	self.Controls.m_GoFightBtn.onClick:AddListener(self.GOTOBattleBtnClickCB)
	
	--增加经验按钮点击事件
	self.AddEXPBtnClickCB = function() self:OnClickAddEXPBtn() end
	self.Controls.m_AddEXPBtn.onClick:AddListener(self.AddEXPBtnClickCB)

	--套装技能点击事件
	self.SkillSuitClickCB = function() self:OnSuitSkillClick() end
	self.Controls.m_SkillSuit.onClick:AddListener(self.SkillSuitClickCB)
		
	--事件缓存
	self.OnConfirmFangSheng = function() self:ConfirmFangsheng() end
	self.LateUpdatePageCB = function() self:LateUpdatePage() end
	self.LazaRefreshBasePropCB = function(msg) self:LazaRefreshBaseProp(msg) end
	
	--刷新界面事件注册
	self.UpdatePage = function(_,_,_,UID) self:RefreshPage(UID) end
	rktEventEngine.SubscribeExecute(EVENT_PET_CLICK_PETICON, SOURCE_TYPE_PET, 0, self.UpdatePage)
	
	--服务器使用增加经验物品返回
	self.UseExpCB = function() self:OnUseExpGoods() end
	rktEventEngine.SubscribeExecute(EVENT_PET_BASEPROP, SOURCE_TYPE_PET, 0, self.UseExpCB)

	--出战,休息返回
	self.ChangeStateCB = function(_,_,_,_,msg) self:OnChangeState(msg) end
	rktEventEngine.SubscribeExecute(EVENT_PET_GOTOBATTLE, SOURCE_TYPE_PET, 0, self.ChangeStateCB)		--出战

	--技能升级，学习回包订阅
	self.SkillChangeCB = function() self:OnChangeSkill() end
	rktEventEngine.SubscribeExecute(EVENT_PET_REFRESHPROPWIDGET, SOURCE_TYPE_PET, 0, self.SkillChangeCB)

	--请求基础属性
	--[[self.BasePropMsgCB = function(_,_,_,_,msg) self:OnBasePropMsg(msg) end
	rktEventEngine.SubscribeExecute(EVENT_PET_BASEPROP, SOURCE_TYPE_PET, 0, self.BasePropMsgCB)--]]
	
	--技能点击回调
	self.SkillClickCB = function(index, item) self:OnSkillClick(index, item) end
	
	--灵兽死亡回掉
	self.PetDeadCB = function(_,_,_,uid) self:OnPetDead(uid) end
	rktEventEngine.SubscribeExecute(EVENT_PET_PETDEAD, SOURCE_TYPE_PET, 0 , self.PetDeadCB)
	
	--灵兽死亡复活事件
	self.PetReLiveCB = function(_,_,_,eventdata) self:OnReLiveCB(eventdata) end
	rktEventEngine.SubscribeExecute(EVENT_FREEZE_END, SOURCE_TYPE_FREEZE, 0 , self.PetReLiveCB)
	self:RegisterEvent()
end

function PetPropertyWidget:Show()
	local petTable = IGame.PetClient:GetCurPetTable()
	if table_count(petTable) > 0 then
		self:SetPet(true)
	else
		self:SetPet(false)
	end
	UIControl.Show(self)
end

function PetPropertyWidget:Hide( destroy )
	if self.PetUseGoodsWidget:isShow() then
		self.PetUseGoodsWidget:Hide()
	end
	UIControl.Hide(self, destroy)
end

function PetPropertyWidget:OnDestroy()
	self.m_InitBase = false
	self.m_InitZiZhi = false
	self.m_InitSkill = false
	self.CurSlotItem = false
	self:ClearCache(self.m_SkillScriptCache)
	self:ClearCache(self.m_BasePropScriptCache)
	self:ClearCache(self.m_ZiZhiPropScriptCahce)

	rktEventEngine.UnSubscribeExecute(EVENT_PET_CLICK_PETICON, SOURCE_TYPE_PET, 0, self.UpdatePage)
	--注销服务器返回增加经验物品使用
	rktEventEngine.UnSubscribeExecute(EVENT_PET_BASEPROP, SOURCE_TYPE_PET, 0, self.UseExpCB)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_GOTOBATTLE, SOURCE_TYPE_PET, 0, self.ChangeStateCB)
	--技能改变回包
	rktEventEngine.UnSubscribeExecute(EVENT_PET_REFRESHPROPWIDGET, SOURCE_TYPE_PET, 0, self.SkillChangeCB)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_PETDEAD, SOURCE_TYPE_PET, 0 , self.PetDeadCB)					--灵兽死亡事件注销
	UIControl.OnDestroy(self)
end

--设置有没有灵兽显示
function PetPropertyWidget:SetPet(havePet)
	if havePet then
		self.Controls.m_Pet.gameObject:SetActive(true)
		self.Controls.m_NoPet.gameObject:SetActive(false)
		self.toggle[1].isOn = true
		self.toggle[2].isOn = false
	else
		self.Controls.m_Pet.gameObject:SetActive(false)
		self.Controls.m_NoPet.gameObject:SetActive(true)
	end
end

--注册toggle事件
function PetPropertyWidget:RegisterEvent()
	self.toggleChangeCB = function(on) self:OnToggleChanged(on,1) end
	self.Controls.m_PropertyToggle.onValueChanged:AddListener(self.toggleChangeCB)
	self.toggleChangeCB = function(on) self:OnToggleChanged(on,2) end
	self.Controls.m_SkillToggle.onValueChanged:AddListener(self.toggleChangeCB)
end

--toggle改变事件
function PetPropertyWidget:OnToggleChanged(on,index)
	if on then 
		self.toggle[index].transform:Find("Select").gameObject:SetActive(true)
		self.PageGameObject[index]:SetActive(true)
		if index == 2 then
			self.m_SkillScriptCache[1]:SetFocus(false)
			self.m_SkillScriptCache[1]:SetFocus(true)
		end
	else
		self.PageGameObject[index]:SetActive(false)
		self.toggle[index].transform:Find("Select").gameObject:SetActive(false)
	end
end

--生成属性列表
function PetPropertyWidget:InitPropView()
	self:ClearCache(self.m_BasePropScriptCache)
	self:ClearCache(self.m_ZiZhiPropScriptCahce)
	
	self.m_BasePropScriptCache = {}
	self.m_ZiZhiPropScriptCahce = {}
	
	local baseNum = 0
	local ziZhiNum = 0
	--基础信息
	for i = 1,6 do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetPropertyItem ,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_BaseProList)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = PetPropertyItemClass:new({})
			item:Attach(obj)
			item:InitView(BasePropName[i],0)
			table.insert(self.m_BasePropScriptCache,i,item)	
			baseNum = baseNum + 1
			if baseNum == 6 then
				self.m_InitBase = true
			end
		end , i , AssetLoadPriority.GuiNormal )
	end
	--资质信息
	for i = 1, 5 do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetPropertyItem ,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_ZiZhiProList)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = PetPropertyItemClass:new({})
			item:Attach(obj)
			item:InitView(ZiZhiPropName[i],0)
			table.insert(self.m_ZiZhiPropScriptCahce,i,item)	
			ziZhiNum = ziZhiNum + 1
			if ziZhiNum == 5 then
				self.m_InitZiZhi = true
			end
		end , i , AssetLoadPriority.GuiNormal )
	end
end

--生成技能列表
function PetPropertyWidget:InitSkillView()
	self:ClearCache(self.m_SkillScriptCache)
	self.m_SkillScriptCache = {}
	local loadedNum = 0
	--技能槽
	for i = 1,8 do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetSkillItem ,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_SkillListGrid, false)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = PetSkillItemClass:new({})
			item:Attach(obj)
			
			item:SetIndex(i)
			item:SetBG("Pet_1/Pet_p_di1.png")
			item:SetLevel(false)
			item:SetAddImg(false)
			item:SetToggleGroup(self.SkillToggleGroup)
			item:SetSelectCallback(self.SkillClickCB)
			item:SetShowSelectEffect(true)
            item:SetShowZheZhao(false)
			table.insert(self.m_SkillScriptCache,i,item)	
			loadedNum = loadedNum + 1
			if loadedNum == 8 then
				self.m_InitSkill = true
			end
		end , i , AssetLoadPriority.GuiNormal )
	end
end

--清空操作
function PetPropertyWidget:ClearCache(nTable)
	if not nTable then return end
	local num = table.getn(nTable)
	
	if num > 0 then
		for i, data in pairs(nTable) do
			data:Destroy()
		end
	end
	nTable = {}
end

--确认放生点击回调
function PetPropertyWidget:ConfirmFangsheng()
	--发消息
	IGame.PetClient:FangShengRequest(self.m_UID)
end

--放生按钮点击回调
function PetPropertyWidget:OnClickFangShengBtn()
	local curID = IGame.PetClient:GetCurPetID()
	local isBattle = IGame.PetClient:IsBattleState(curID)
	
	if isBattle then
		UIManager.TipsActorUnderWindow:AddSystemTips("出战灵兽不可放生哦！")
	else
		GameHelp.PostServerRequest("RequestPrepareFreePet("..tostring(self.m_UID)..")")
		
		--[[local name = IGame.PetClient:GetPetName(curID)
		local contentStr = "确定要将灵兽"..name.."放生吗?\n放生的灵兽将返回一定的经验丹/培养丹"
		local data = {
			content = contentStr,
			confirmCallBack = self.OnConfirmFangSheng,
		}
		UIManager.ConfirmPopWindow:ShowDiglog(data)--]]
	end
end

--出战按钮点击回调
function PetPropertyWidget:OnClickGOTOBattleBtn()
	local curID = self.m_UID
	local isBattle = IGame.PetClient:IsBattleState(curID)
	
	local pHero = GetHero()
	if not pHero then
		return
	end
	local level	= pHero:GetNumProp(CREATURE_PROP_LEVEL)
	
	if isBattle then
		--休息
		IGame.PetClient:RelaxRequest(curID)
	else
		local record = IGame.PetClient:GetRecordByUID(curID)
		if not record then return end
		if record.BattleLevel > level then
			UIManager.TipsActorUnderWindow:AddSystemTips("等级不足，无法出战！")
			return
		end
		
		if IGame.PetClient:IsDead(curID) then
			UIManager.TipsActorUnderWindow:AddSystemTips("灵兽死亡，无法出战，重生自动出战！")
			return
		end
		
		IGame.PetClient:GOTOBattleRequest(curID)
	end
end

--增加经验按钮点击回调
function PetPropertyWidget:OnClickAddEXPBtn()
	self.PetUseGoodsWidget:ShowPetUseGoodsWidget(self.m_UID)
end

--套装技能点击
function PetPropertyWidget:OnSuitSkillClick()
	rktEventEngine.FireEvent(EVENT_PET_OPENSUITTIPS,  SOURCE_TYPE_PET, 0, self.m_UID)
end

--使用经验物品
function PetPropertyWidget:OnUseExpGoods()
	self:RefreshPage(self.m_UID)			--不发请求的刷新
end

--刷新本界面
function PetPropertyWidget:RefreshPage(UID)	
	self.m_UID = UID
	self.m_PetID = IGame.PetClient:GetIDByUID(UID)
	
	if self.Controls.m_SkillToggle.isOn then
		self.Controls.m_PropertyToggle.isOn = true
	end
	
	self:RefreshSliderWidget(UID)
	
	--多余刷新
--[[	if not noPost then
		self:CheckRefreshBasePro()
	end--]]
	
	local record = IGame.PetClient:GetRecordByID(self.m_PetID)
	if record then
		self.toggle[2].gameObject:SetActive(true)
	else
		self.toggle[2].gameObject:SetActive(false)
	end
	self.toggle[1].isOn = true
	
	if self.m_InitBase and self.m_InitZiZhi and self.m_InitSkill then 
		self:RefreshMiddleWidget(UID)
		self:RefreshSkillWidget(UID)
	else
		--开启定时器，等加载完再刷新
		rktTimer.SetTimer(self.LateUpdatePageCB, 60, -1, "PetPropertyWidget:LateUpdatePage")
	end
	
	--刷新底部出战按钮
	self:RefreshBottomBtnSprite()
end

--延迟刷新
function PetPropertyWidget:LateUpdatePage()
	if self.m_InitBase and self.m_InitZiZhi and self.m_InitSkill then
		self:RefreshMiddleWidget(self.m_UID)
		self:RefreshSkillWidget(self.m_UID)
		rktTimer.KillTimer(self.LateUpdatePageCB)
	end
end

--刷新底部按钮图片
function PetPropertyWidget:RefreshBottomBtnSprite()
	if IGame.PetClient:IsBattleState(self.m_UID) then
		UIFunction.SetImageSprite(self.Controls.GoFightImage, BattleOrRelaxPath[1])						--出战
	else
		UIFunction.SetImageSprite(self.Controls.GoFightImage, BattleOrRelaxPath[2])						--休息
	end
end

--刷新滑动条界面
function PetPropertyWidget:RefreshSliderWidget(curUID)
	local curHP = IGame.PetClient:GetNumProp(curUID,CREATURE_PROP_CUR_HP)
	local maxHP = IGame.PetClient:GetNumProp(curUID,CREATURE_PROP_MAX_HP)
	local curEXP = IGame.PetClient:GetNumProp(curUID,CREATURE_PROP_EXP)
	local maxEXP = IGame.PetClient:GetNextLevelEXP(curUID)
	self.Controls.m_HPText.text = string.format("%d/%d", curHP, maxHP)
	self.Controls.m_EXPText.text = string.format("%d/%d", curEXP, maxEXP)
	self.HPSlider.value = curHP / maxHP
	self.EXPSlider.value = curEXP / maxEXP
end

--刷新技能界面
function PetPropertyWidget:RefreshSkillWidget(uid)
	local num = IGame.PetClient:GetSuitNumAndID(uid)
	self.Controls.m_SkillSuitText.text = tostring(num)
	
	local skillTable = IGame.PetClient:GetSkillTable(uid)
	local haveSlot = IGame.PetClient:GetSkillSlot(uid)
	local learnNum = 0
	for i,data in pairs(skillTable) do
		if data.skill_id > 0 then 
			learnNum = learnNum + 1
		end
	end
	for i, data in pairs(self.m_SkillScriptCache) do
		data:SetUID(uid)
		
		if i <= haveSlot then 
			if skillTable[i].skill_id > 0 then				--学过技能
				data:SetViewByID(skillTable[i].skill_id, skillTable[i].skill_lv)
                data:SetLevel(true, skillTable[i].skill_lv)
			else											--槽开了，没学技能
				data:Clear()
			end
		else
			data:SetLock(true)
		end
		if i == 1 then data:SetFocus(true) end
	end
end

--技能槽点击回调
function PetPropertyWidget:OnSkillClick(index, item)
	self.CurSlotItem = item
	local skillTable = IGame.PetClient:GetSkillTable(item.m_UID)
	if skillTable[index] then
		local skillRecord = IGame.PetClient:GetSkillRecordByIDAndLevel(skillTable[index].skill_id, skillTable[index].skill_lv)
		if not skillRecord then
			self.Controls.m_SkillDesText.text = ""
			return
		end
		self.Controls.m_SkillDesText.text = skillRecord.SkillDesc[1]
	end
end


--刷新基础，资质信息界面
function PetPropertyWidget:RefreshMiddleWidget(curUID)
	self:RefreshBaseInfo(curUID)
	self:RefreshAptitudeInfo(curUID)
end

--刷新基础信息界面
function PetPropertyWidget:RefreshBaseInfo(UID)
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
		self.m_BasePropScriptCache[i]:SetValue(baseValue[i])
	end
end

--刷新资质信息界面
function PetPropertyWidget:RefreshAptitudeInfo(UID)
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
		self.m_ZiZhiPropScriptCahce[i]:SetValue(ziZhiValue[i])
	end
end

--延迟刷新基础属性
function PetPropertyWidget:LazaRefreshBaseProp()
	if self.m_InitBase then
		self:RefreshBaseInfo(self.m_UID)
	end
end

---------------------------事件订阅handler---------------

--出战返回
function PetPropertyWidget:OnChangeState(msg)
	if msg.uidPet == self.m_UID then
		if IGame.PetClient:IsBattleState(self.m_UID) then
			UIFunction.SetImageSprite(self.Controls.GoFightImage, BattleOrRelaxPath[1])						--出战
		else
			UIFunction.SetImageSprite(self.Controls.GoFightImage, BattleOrRelaxPath[2])						--休息
		end
	end
end

--基础属性返回
function PetPropertyWidget:CheckRefreshBasePro()
	if self.m_InitBase then
		self:LazaRefreshBaseProp()
	else
		rktTimer.SetTimer(self.LazaRefreshBasePropCB, 60, -1, "PetPropertyWidget:LazaRefreshBaseProp")
	end
end

function PetPropertyWidget:OnChangeSkill()
	self:RefreshSkillWidget(self.m_UID)
	if self.CurSlotItem then 
		self:OnSkillClick(self.CurSlotItem.m_Index, self.CurSlotItem)
	end
end

--灵兽死亡
function PetPropertyWidget:OnPetDead(uid)
	if uid == self.m_UID then
		self:RefreshBottomBtnSprite()
	end
end

--灵兽重生
function PetPropertyWidget:OnReLiveCB(eventData)
	if eventData.dwClassID == EFreeze_ClassID_Dead then
		local record = IGame.PetClient:GetRecordByUID(self.m_UID)
		if not record then return end
		if record.FreezeID == eventData.dwFreezeID then
			self:RefreshBottomBtnSprite()
		end
	end
end

return PetPropertyWidget
