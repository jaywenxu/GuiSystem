local PetItemClass = require("GuiSystem.WindowList.Pet.PetIconItem")
local PetModelDisPlayClass = require( "GuiSystem.WindowList.Pet.PetModelDisplay" )

---------------------------灵兽系统继承界面---------------------------------------
local GrowTypeStr = {
	"普通",
	"优秀",
	"完美",				
	"卓越",
	"超神",
}

local PetInheritWidget = UIControl:new
{
	windowName = "PetInheritWidget",
	
	m_PetScriptCache = {},				--缓存灵兽列表脚本
	m_LeftSettedID = -1,				--左边是否已经配置
	m_RightSettedID = -1,				--右边是否已经配置
	
	m_LeftScriptItem = nil, 			--缓存第一个IconItem脚本
	m_RightScriptItem = nil, 			--缓存第二个IconItem脚本
	
	m_LeftModelUID = 62,
	m_RightModelUID = 61,
}

function PetInheritWidget:Attach(obj)
	UIControl.Attach(self,obj)
	
	--[[self.NewPetWidget = require("GuiSystem.WindowList.Pet.PetNewPet.PetNewPetWidget"):new()
	self.NewPetWidget:Attach(self.Controls.m_PetNewPetWidget.gameObject)--]]
	
	self.LeftPetModelDisPlay = PetModelDisPlayClass:new()
	self.RightPetModelDisPlay = PetModelDisPlayClass:new()
	self.LeftPetModelDisPlay:SetUID(self.m_LeftModelUID)
	self.RightPetModelDisPlay:SetUID(self.m_RightModelUID)
	self.LeftPetModelDisPlay:Attach(self.Controls.m_RawImage.gameObject)
	self.RightPetModelDisPlay:Attach(self.Controls.m_RightRawImageTrans.gameObject)

	
	self.ToggleCtl = {
		self.Controls.m_GrowToggle,
		self.Controls.m_SkillSlotToggle,
		self.Controls.m_TalentSkillToggle,
		self.Controls.m_HelpSkillToggle,
	}
	
	--按钮点击事件缓存
	self.LeftMoveBackBtnClickCB = function() self:OnClickLeftMoveBackBtn() end
	self.RightMoveBackBtnClickCB = function() self:OnClickRightMoveBackBtn() end
	self.JiChengBtnClickCB = function() self:OnClickJiChengBtn() end
	
	self.PetIconClickCB = function(nID, item) self:OnClickPetIconItem(nID, item) end
	
	--请求返回
	self.InheritCB = function(_,_,_,nID) self:OnInheritCallBack(nID) end
	
	self:RegisterEvent()
	
	--关闭灵兽界面事件监听
	self.ClosePetWindowCB = function() self:OnClosePetWindow() end
	rktEventEngine.SubscribeExecute(EVENT_PET_CLOSE_WINDOW, SOURCE_TYPE_PET, 0, self.ClosePetWindowCB)
	
--[[	self.OnInheritCB = function(ID) self:OnInheritCallBack(ID) end							--TODO
	rktEventEngine.SubscribeExecute(, SOURCE_TYPE_PET, 0, self.OnInheritCB)--]]
end

function PetInheritWidget:Show()
	UIControl.Show(self)
	self.LeftPetModelDisPlay:SetModePosition(Vector3.New())							--根据灵兽模型，设置位置		--TODO
	self.LeftPetModelDisPlay:ShowPetModel(true,2)
	
	if self.LeftPetModelDisPlay.m_dis~= nil then 
		self.LeftPetModelDisPlay:SetModePosition(Vector3.New())						--根据灵兽模型，设置位置		--todo
		self.RightPetModelDisPlay:CreatModel(true,self.LeftPetModelDisPlay.m_dis.m_GameObject.transform)
	end
	
	self:ClearLeftPetView()
	self:ClearRightPetView()		
	
	--打开的时候初始化，不选中状态
	for i, data in pairs(self.ToggleCtl) do
		data.isOn = false
	end
	
	self:InitPetList()
end

function PetInheritWidget:Hide( destroy )
	self.LeftPetModelDisPlay:ShowPetModel(false)
	self.RightPetModelDisPlay:ShowPetModel(false)
	
	UIControl.Hide(self, destroy)
end

function PetInheritWidget:OnDestroy()
	self.LeftPetModelDisPlay:ShowPetModel(false)
	self.RightPetModelDisPlay:ShowPetModel(false)
	
	rktEventEngine.UnSubscribeExecute(EVENT_PET_CLOSE_WINDOW, SOURCE_TYPE_PET, 0, self.ClosePetWindowCB)
	UIControl.OnDestroy(self)
end

-----------------------------------控件事件注册--------------------------------------------------
--控件相关的事件注册
function PetInheritWidget:RegisterEvent()
	--toggle切换事件			目前逻辑不需要注册toggle事件
	--[[for i = 1, 4 do
		local toggleChangeCB = function(on) self:OnToggleChanged(on,i) end
		self.ToggleCtl[i].onValueChanged:AddListener(toggleChangeCB)
	end--]]
	
	--左边移回按钮点击事件注册
	self.Controls.m_LeftMoveBackBtn.onClick:AddListener(self.LeftMoveBackBtnClickCB)
	--右边移回按钮点击事件
	self.Controls.m_RightMoveBackBtn.onClick:AddListener(self.RightMoveBackBtnClickCB) 
	--继承按钮点击事件
	self.Controls.m_JiChengBtn.onClick:AddListener(self.JiChengBtnClickCB)
end

--[[function PetInheritWidget:OnToggleChanged(on, Index)
	
end--]]

--左边移回按钮点击回调
function PetInheritWidget:OnClickLeftMoveBackBtn()
	self:ClearLeftPetView()
end

--右边移回按钮点击回调
function PetInheritWidget:OnClickRightMoveBackBtn()
	self:ClearRightPetView()
end

--继承按钮点击回调
function PetInheritWidget:OnClickJiChengBtn()
	if not self.m_LeftScriptItem or not self.m_RightScriptItem then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "没有正确选择灵兽，不能进行继承")
		return
	end
	
	local leftPetRecord = IGame.PetClient:GetRecordByUID(self.m_LeftScriptItem.m_UID)
	local rightPetRecord = IGame.PetClient:GetRecordByUID(self.m_RightScriptItem.m_UID)
	if rightPetRecord.Type ~= 3 then				--继承方不是神兽
		if leftPetRecord.BattleLevel ~= rightPetRecord.BattleLevel then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "只有出战等级相同的灵兽才可以继承！")
			return
		end
	end
	
	if self.ToggleCtl[2].isOn then
		local leftHaveSkill = IGame.PetClient:HaveLearnSkill(self.m_LeftScriptItem.m_UID)
		--判断技能是否全部剥离
		if leftHaveSkill then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "传承方没有剥离所有技能，不能传承技能孔")
			return
		end
		local rightHaveSkill = IGame.PetClient:HaveLearnSkill(self.m_RightScriptItem.m_UID)
		if rightHaveSkill then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "接收方没有剥离所有技能，不能继承技能孔")
			return
		end
	end
	local haveSelected = false
	for i, data in pairs(self.ToggleCtl) do
		if data.isOn then
			haveSelected = true
			break
		end
	end
	if not haveSelected then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "没有选择继承属性，不能进行传承")
		return
	end
	
	--像服务器发送继承消息
	local argTable = {}
	argTable.uidPetSrc = self.m_LeftScriptItem.m_UID
	argTable.uidPetTar = self.m_RightScriptItem.UID
	argTable.bGrowth = self.ToggleCtl[1].isOn
	argTable.bSkillSolt = self.ToggleCtl[2].isOn
	argTable.bTalent = self.ToggleCtl[3].isOn
	argTable.bAssist = self.ToggleCtl[4].isOn
	IGame.PetClient:PetInherit(argTable)
end
------------------------------------------------------------------------------------------------------------
--初始化左边灵兽列表
function PetInheritWidget:InitPetList()
	local tableNum = table.getn(self.m_PetScriptCache) 
	if tableNum > 0 then
		--销毁之前的
		for i, data in pairs(self.m_PetScriptCache) do
			data:Destroy()
		end
	end
	self.m_PetScriptCache = {}
	
	--从model中获取灵兽Table
	local petList = IGame.PetClient:GetCurPetTable()
	if not petList then return end
	local count = table.getn(petList)
	
	for	i = 1,count do 
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetIconItem,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_PetIconListParent, false)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = PetItemClass:new({})
			item:Attach(obj)
			item:SetShowSelectedEffect(false)
			item:SetFocus(false)
			item:SetChangeState(true)
--			local iconPath = "Icon_Item/wuqi1.png"					--for test
			local isFighting = false
			local uid = petList[i].uid		--下面替换成这个
			local level = IGame.PetClient:GetPetLevel(uid)
			local petID = IGame.PetClient:GetIDByUID(uid)
			item:InitState(petID, iconPath, level, false, self.PetIconClickCB,uid)			--for test,  这里赋值的是灵兽ID不是索引
			table.insert(self.m_PetScriptCache,i,item)
		end , i , AssetLoadPriority.GuiNormal )
	end
end

--灵兽icon item点击回调
function PetInheritWidget:OnClickPetIconItem(nID, item)

	if nID == self.m_LeftSettedID then
		self:ClearLeftPetView()
		return
	elseif nID == self.m_RightSettedID then
		self:ClearRightPetView()
		return
	end
	
	if self.m_LeftSettedID ~= -1 and self.m_RightSettedID ~= -1 then
		return
	end
	
	
	item:SetSelectedImgState(true)
	
	if self.m_LeftSettedID == -1 then
		--配置左边
		self:SetLeftPetView(nID, item)
	elseif self.m_RightSettedID == -1 then
		--配置右边
		self:SetRightPetView(nID, item)
	end
	
	
end

--设置左边的传承方
function PetInheritWidget:SetLeftPetView(nID, nItem)
	self.Controls.m_LeftNoPetParent.gameObject:SetActive(false)
	self.Controls.m_LeftPetParent.gameObject:SetActive(true)
	self.Controls.m_LeftTalentSkillIcon.gameObject:SetActive(true)
	self.Controls.m_LeftHelpSkillIcon.gameObject:SetActive(true)
	
	self.m_LeftSettedID = nID
	self.m_LeftScriptItem = nItem

	self.Controls.m_LeftPetLevel.text = IGame.PetClient:GetPetLevel(nItem.m_UID)
	self.Controls.m_LeftPetName.text = IGame.PetClient:GetPetName(nItem.m_UID)
	--设置模型显示
--	self.Controls.m_LeftRawImageTrans.gameObject:SetActive(true)
	local entityView = rkt.EntityView.GetEntityView(self.m_LeftModelUID)
	if entityView then
		entityView.transform.gameObject:SetActive(true)
	end
	local record = IGame.PetClient:GetRecordByUID(nItem.m_UID)
	self.LeftPetModelDisPlay:ChangePet(record.ModelResource)
	
	
	--设置下方信息
	local growthRate = IGame.PetClient:GetGrowRate(nItem.m_UID)
	self.Controls.m_LeftGrowRateText.text = tostring(GrowTypeStr[growthRate])
	self.Controls.m_LeftSkillSlotText.text = IGame.PetClient:GetSkillSlot(nItem.m_UID)
--	UIFunction.SetImageSprite(self.Controls.m_LeftTalentSkillIcon, path)
--	UIFunction.SetImageSprite(self.Controls.m_LeftHelpSkillIcon, path)


	--正式的
--[[	self.Controls.m_LeftPetName.text = IGame.PetClient:GetPetName(nID)
	self.Controls.m_LeftPetLevel.text = IGame.PetClient:GetPetLevel(nID)
	self.Controls.m_LeftGrowRateText.text = IGame.PetClient:GetNumProp(nID, PET_PROP_GROWTH)
	local skillTable = IGame.PetClient:GetSkillTable(nID)
	local skillNum
	if not skillTable then 
		skillNum = 0
	else
		skillNum = table.getn(skillTable)
	end
	self.Controls.m_LeftSkillSlotText.text = tostring(skillNum)	.. "个"		--已经学习的技能数量
	
	local talentSkillInfo = IGame.PetClient:GetTalentSkill(nID)
	local talentSkillRecord = IGame.rktScheme:GetSchemeInfo( , talentSkillInfo.id)
	local helpSkillInfo = IGame.PetClient:GetHelpSkill(nID)
	local helpSkillRecord = IGame.rktScheme:GetSchemeInfo( 灵兽技能表, helpSkillInfo.id)
	
	UIFunction.SetImageSprite(self.Controls.m_LeftTalentSkillIcon, AssetPath.TextureGUIPath..talentSkillRecord.skillIconPath)
	UIFunction.SetImageSprite(self.Controls.m_LeftHelpSkillIcon,  AssetPath.TextureGUIPath..helpSkillRecord.skillIconPath)--]]
end

--设置右边的接受方
function PetInheritWidget:SetRightPetView(nID, nItem)
	self.Controls.m_RightNoPetParent.gameObject:SetActive(false)
	self.Controls.m_RightPetParent.gameObject:SetActive(true)
	self.Controls.m_RightTalentSkillIcon.gameObject:SetActive(true)
	self.Controls.m_RightHelpIcon.gameObject:SetActive(true)
	
	self.m_RightSettedID = nID
	self.m_RightScriptItem = nItem
	--TODO
	self.Controls.m_RightPetLevel.text = IGame.PetClient:GetPetLevel(nItem.m_UID)
	self.Controls.m_RightPetName.text = IGame.PetClient:GetPetName(nItem.m_UID)
	--设置模型显示
--	self.Controls.m_RightRawImageTrans.gameObject:SetActive(true)
	local entityView = rkt.EntityView.GetEntityView(self.m_RightModelUID)
	if entityView then
		entityView.transform.gameObject:SetActive(true)
	end
	local record = IGame.PetClient:GetRecordByUID(nItem.m_UID)
	self.RightPetModelDisPlay:ChangePet(record.ModelResource)
	
	--设置下方信息
	local growthRate = IGame.PetClient:GetGrowRate(nItem.m_UID)
	self.Controls.m_RightGrowRateText.text = tostring(GrowTypeStr[growthRate])
	self.Controls.m_RightSkillSlotText.text = IGame.PetClient:GetSkillSlot(nItem.m_UID)
	
--	UIFunction.SetImageSprite(self.Controls.m_RightTalentSkillIcon, path)
--	UIFunction.SetImageSprite(self.Controls.m_RightHelpIcon, path)

	--正式的
--[[	self.Controls.m_RightPetName.text = IGame.PetClient:GetPetName(nID)
	self.Controls.m_RightPetLevel.text = IGame.PetClient:GetPetLevel(nID)
	self.Controls.m_RightGrowRateText.text = IGame.PetClient:GetNumProp(nID, PET_PROP_GROWTH)
	local skillTable = IGame.PetClient:GetSkillTable(nID)
	local skillNum
	if not skillTable then 
		skillNum = 0
	else
		skillNum = table.getn(skillTable)
	end
	self.Controls.m_RightSkillSlotText.text = tostring(skillNum)	.. "个"		--已经学习的技能数量
	
	local talentSkillInfo = IGame.PetClient:GetTalentSkill(nID)
	local talentSkillRecord = IGame.rktScheme:GetSchemeInfo( , talentSkillInfo.id)
	local helpSkillInfo = IGame.PetClient:GetHelpSkill(nID)
	local helpSkillRecord = IGame.rktScheme:GetSchemeInfo( 灵兽技能表, helpSkillInfo.id)
	
	UIFunction.SetImageSprite(self.Controls.m_RightTalentSkillIcon, AssetPath.TextureGUIPath..talentSkillRecord.skillIconPath)
	UIFunction.SetImageSprite(self.Controls.m_RightHelpIcon,  AssetPath.TextureGUIPath..helpSkillRecord.skillIconPath)--]]
end

--清空左边传承方
function PetInheritWidget:ClearLeftPetView()
	self.Controls.m_LeftNoPetParent.gameObject:SetActive(true)
	self.Controls.m_LeftPetParent.gameObject:SetActive(false)
	self.m_LeftSettedID = -1
	if self.m_LeftScriptItem then
		self.m_LeftScriptItem:SetSelectedImgState(false)
	end
	self.m_LeftScriptItem = nil
	
	for i, data in pairs(self.ToggleCtl) do
		data.isOn = false
	end
	
	self.Controls.m_LeftGrowRateText.text = "?"
	self.Controls.m_LeftSkillSlotText.text = "?"
	self.Controls.m_LeftTalentSkillIcon.gameObject:SetActive(false)
	self.Controls.m_LeftHelpSkillIcon.gameObject:SetActive(false)
	
	--清空灵兽显示			TODO
	local entityView = rkt.EntityView.GetEntityView(self.m_LeftModelUID)
	if entityView then
		entityView.transform.gameObject:SetActive(false)
	end
--	self.Controls.m_LeftRawImageTrans.gameObject:SetActive(false)
end

--清空右边接受方
function PetInheritWidget:ClearRightPetView()
	self.Controls.m_RightNoPetParent.gameObject:SetActive(true)
	self.Controls.m_RightPetParent.gameObject:SetActive(false)
	self.m_RightSettedID = -1
	if self.m_RightScriptItem then
		self.m_RightScriptItem:SetSelectedImgState(false)
	end
	self.m_RightScriptItem = nil
	
	self.Controls.m_RightGrowRateText.text = "?"
	self.Controls.m_RightSkillSlotText.text = "?"
	self.Controls.m_RightTalentSkillIcon.gameObject:SetActive(false)
	self.Controls.m_RightHelpIcon.gameObject:SetActive(false)
	
	--清空灵兽显示
	local entityView = rkt.EntityView.GetEntityView(self.m_RightModelUID)
	if entityView then
		entityView.transform.gameObject:SetActive(false)
	end
--	self.Controls.m_RightRawImageTrans.gameObject:SetActive(false)
end


--继承消息返回
function PetInheritWidget:OnInheritCallBack(ID)
	local name = IGame.PetClient:GetPetName(ID)
	self:ClearLeftPetView()
	self:ClearRightPetView()
	--self.NewPetWidget:ShowNewPetWidget(ID,name)
	
	--发送事件,显示获得新灵兽界面
	rktEventEngine.FireExecute(EVENT_PET_SHOWNEWPET_WIDGET, SOURCE_TYPE_PET, 0, ID)
end

--关闭灵兽界面
function PetInheritWidget:OnClosePetWindow()
	self.LeftPetModelDisPlay:ShowPetModel(false)
	self.RightPetModelDisPlay:ShowPetModel(false)
end

return PetInheritWidget
