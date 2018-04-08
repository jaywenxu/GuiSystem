local PetItemClass = require("GuiSystem.WindowList.Pet.PetIconItem")
local PetModelDisPlayClass = require( "GuiSystem.WindowList.Pet.PetModelDisplay" )
local PetHuanHuaPageClass = require( "GuiSystem.WindowList.Pet.TuJian.PetHuanHuaPage" )
---------------------------灵兽系统展示界面---------------------------------------
--美术出图替换掉
local optionImg = {
	AssetPath.TextureGUIPath.."Pet_1/pet_jihuo.png",				--可激活
	AssetPath.TextureGUIPath.."Pet_1/pet_huanhua.png",				--幻化
}

local PetIconItemPath = {
	"Pet_1/Pet_yishouji",					
	"Pet_1/Pet_yishouji",
}

local PetTuJianWidget = UIControl:new
{
	windowName = "PetTuJianWidget",
	
	m_IconItemCache = {}, 				--灵兽iconItem脚本缓存
	m_PropItemCache = {}, 				--灵兽资质Item脚本缓存

	m_CurID = 0,						--当前的灵兽ID
}

function PetTuJianWidget:Attach(obj)
	UIControl.Attach(self,obj)

	self.PetHuanHuaPage = PetHuanHuaPageClass:new()
	self.PetHuanHuaPage:Attach(self.Controls.m_HuanHuaPage.gameObject)
	
	self.PetModelDisPlay = PetModelDisPlayClass:new()
	self.PetModelDisPlay:SetUID(65)
	self.PetModelDisPlay:Attach(self.Controls.m_RawImageTrans.gameObject)
	
	self.Toggle = {
		self.Controls.m_NormalPet,
		self.Controls.m_MythicalPet,
	}
	
	self.toggleChangeCB_1 = function(on) self:OnToggleChanged(on,1) end
	self.toggleChangeCB_2 = function(on) self:OnToggleChanged(on,2) end
	self.HuoQuLuJingBtnClickCB = function() self:OnHuoQuLuJingBtnClick() end 
	self.PetIconItemClickCB = function(nID,item) self:OnIconItemClick(nID,item) end												--iconItem点击回调
	self.OptionBtnClickCB = function() self:OnOptionBtnClick() end																--option按钮点击回调

	self.UpdateTuJianCB = function() self:RefreshIconList() end
	
	self.ToggleGroup = self.Controls.m_ToggleGroup.gameObject:GetComponent(typeof(ToggleGroup))
	
	self:RegisterEvent()
	
	--关闭灵兽界面事件监听
	self.ClosePetWindowCB = function() self:OnClosePetWindow() end
	rktEventEngine.SubscribeExecute(EVENT_PET_CLOSE_WINDOW, SOURCE_TYPE_PET, 0, self.ClosePetWindowCB)

end


function PetTuJianWidget:Show()
	UIControl.Show(self)
	self.PetModelDisPlay:SetModePosition(Vector3.New(-2.91,1.02))	
	self.PetModelDisPlay:ShowPetModel(true,4)			--生成显示组件
	rktEventEngine.SubscribeExecute(EVENT_PET_UPDATETUJIAN, SOURCE_TYPE_PET, 0,self.UpdateTuJianCB)
	self:SetDefaultPage(1)
end

function PetTuJianWidget:Hide( destroy )
	self.PetModelDisPlay:ShowPetModel(false)
	self.m_CurID = 0
	rktEventEngine.UnSubscribeExecute(EVENT_PET_UPDATETUJIAN, SOURCE_TYPE_PET, 0,self.UpdateTuJianCB)
	UIControl.Hide(self, destroy)
end

function PetTuJianWidget:OnDestroy()
	self.PetModelDisPlay:ShowPetModel(false)
	self.m_CurID = 0
	rktEventEngine.UnSubscribeExecute(EVENT_PET_CLOSE_WINDOW, SOURCE_TYPE_PET, 0, self.ClosePetWindowCB)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_UPDATETUJIAN, SOURCE_TYPE_PET, 0,self.UpdateTuJianCB)
	UIControl.OnDestroy(self)
end

---------------------------------------------------事件注册-------------------------------------------------------------------
--注册函数
function PetTuJianWidget:RegisterEvent()
	--toggle切换   1-普通灵兽     2-神兽
	self.Controls.m_NormalPet.onValueChanged:AddListener(self.toggleChangeCB_1)
	self.Controls.m_MythicalPet.onValueChanged:AddListener(self.toggleChangeCB_2)
	
	--获取路径
	self.Controls.m_HuoQuPathBtn.onClick:AddListener(self.HuoQuLuJingBtnClickCB)
	
	--选项按钮    激活，幻化
	self.Controls.m_OptionBtn.onClick:AddListener(self.OptionBtnClickCB)
end

--Toggle切换函数
function PetTuJianWidget:OnToggleChanged(on, nIndex)
	--刷新列表
	if on then
		self.Toggle[nIndex].transform:Find("Select").gameObject:SetActive(true)
		self:InitIconListView(nIndex)
	else
		self.Toggle[nIndex].transform:Find("Select").gameObject:SetActive(false)
	end
end

--获取路径按钮点击事件
function PetTuJianWidget:OnHuoQuLuJingBtnClick()
	local record = IGame.rktScheme:GetSchemeInfo(PETMANUAL_CSV, self.m_CurID)
	if not record then 
		uerror("获取图鉴配置失败，ID:"..self.m_CurID)
		return
	end
	local subInfo = {
		bShowBtnType	= 2, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
	}
	UIManager.GoodsTooltipsWindow:SetGoodsInfo(record.WayToGet, subInfo )
end
-----------------------------------------------------------------------------------------------------------------
--默认显示哪个分类界面
function PetTuJianWidget:SetDefaultPage(nDefault)
	if nDefault == 2 then
		self.Controls.m_MythicalPet.isOn = true
	else
		if self.Controls.m_NormalPet.isOn == true then
			self:InitIconListView(1)
		else
			self.Controls.m_NormalPet.isOn = true
		end
	end
end

--初始化itemIcon列表
function PetTuJianWidget:InitIconListView(nIndex)

	for i,data in pairs(self.m_IconItemCache) do
		data:Destroy()
	end
	self.m_IconItemCache = {}
	
	--从model中获取灵兽Table
	local petList = IGame.PetClient:GetPetTableByType(nIndex)
	if not petList then return end
	local num = table_count(petList)
	
	local loadNum = 0
	for i,data in pairs(petList) do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetIconItem,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_PetListParent, false)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = PetItemClass:new({})
			item:Attach(obj)
			item:SetTuJian(true)
			item:SetToggleGroup(self.ToggleGroup)
            item:SetClickAnimation(false)
			local isFighting = false
			local record = IGame.PetClient:GetRecordByID(data.ID)
			local level = record.BattleLevel
			local iconPath = record.HeadIcon
			item:InitState(data.ID, iconPath, level, false, self.PetIconItemClickCB,nil,false)
			item:SetQuality(record.Type)
			item:SetCoolShow(false)
			table.insert(self.m_IconItemCache,i,item)
			loadNum = loadNum + 1
			if loadNum == 1 then
				item:SetFocus(true)
			end
			if loadNum == num then
				self:RefreshIconList()
			end
		end , i , AssetLoadPriority.GuiNormal )
	end
	
end

--iconItem点击事件
function PetTuJianWidget:OnIconItemClick(nID,item)
	if self.m_CurID == nID then return end
	self.m_CurID = nID
	self:RefreshMiddleWidget(nID,item)
	self:RefreshRightWidget(nID,item)
end

--刷新左侧图标按钮
function PetTuJianWidget:RefreshIconList()
	local hero = IGame.EntityClient:GetHero()
	if not hero then return end
	local level = hero:GetNumProp(CREATURE_PROP_LEVEL)
	for i,data in pairs(self.m_IconItemCache) do
		local state = IGame.PetClient:GetPetTuJianState(data.m_ID)
		if state < 2 then
			data:SetIconGray(true)
		else
			data:SetIconGray(false)
		end
		data:SetRightShow(state)

		local record = IGame.PetClient:GetRecordByID(data.m_ID)
		if record then
			if level < record.BattleLevel then
				data:SetLevelMaskShow(true)
				data:SetLevel(record.BattleLevel,true)
			else
				data:SetLevelMaskShow(false)
				data:SetLevel(record.BattleLevel,false)
			end 
		end
	end
	
	local state = IGame.PetClient:GetPetTuJianState(self.m_CurID)
	if state == 0 then
		UIFunction.SetImgComsGray(self.Controls.m_OptionBtnGrayImg, true)
		UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg, optionImg[1])
	else
		UIFunction.SetImgComsGray(self.Controls.m_OptionBtnGrayImg, false)
		UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg, optionImg[state])
	end
	
	local qinYuan = IGame.PetClient:GetMyQingYuan()
	self.Controls.m_MyQingYuanText.text = string.format("我的情缘值：%d", qinYuan)
	
	self:RefreshZiZhiAdd(qinYuan)
end

--刷新中间界面
function PetTuJianWidget:RefreshMiddleWidget(nID,item)
	
	--刷新模型展示
	if not self.PetModelDisPlay:HaveInit() then
		self.PetModelDisPlay:ShowPetModel(true)
	end
	local record = IGame.PetClient:GetRecordByID(nID)
	self.PetModelDisPlay:ChangePet(record.ModelResource)
	
	UIFunction.SetImageSprite(self.Controls.m_PetTypeImage, AssetPath_PetType[record.BattleType])
	UIFunction.SetImageSprite(self.Controls.m_PetQualityImage, AssetPath_PetQuality[record.Type])
	self.Controls.m_PetNameText.text = record.Name
	
	self.Controls.m_QingYuanText.text = string.format("+%d", record.AddScore)
	
	--刷新optionBtn图标
	local state = IGame.PetClient:GetPetTuJianState(self.m_CurID)
	if state == 0 then
		UIFunction.SetImgComsGray(self.Controls.m_OptionBtnGrayImg, true)
		UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg, optionImg[1])
	elseif state == 1 then
		UIFunction.SetImgComsGray(self.Controls.m_OptionBtnGrayImg, false)
		UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg, optionImg[1])
	else
		UIFunction.SetImgComsGray(self.Controls.m_OptionBtnGrayImg, false)
		UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg, optionImg[state])
	end
	
	self:RefreshSkillView(record)
end

--刷新天赋，援助技能区域
function PetTuJianWidget:RefreshSkillView(nPetRecord)
	local skillRecord_1 = IGame.rktScheme:GetSchemeInfo(PETSKILLBOOK_CSV, nPetRecord.TalentSkill[1], 1)
	local skillRecord_2 = IGame.rktScheme:GetSchemeInfo(PETSKILLBOOK_CSV, nPetRecord.TalentSkill[2], 1)
	if not skillRecord_1 or not skillRecord_2 then return end
	UIFunction.SetImageSprite(self.Controls.m_PetTalentSkillIcon_1, AssetPath.TextureGUIPath .. skillRecord_1.SkillIcon)
	UIFunction.SetImageSprite(self.Controls.m_PetTalentSkillQuality_1, AssetPath_PetSkillQuality[skillRecord_1.SkillQuality])
	UIFunction.SetImageSprite(self.Controls.m_PetTalentSkillIcon_2, AssetPath.TextureGUIPath .. skillRecord_2.SkillIcon)
	UIFunction.SetImageSprite(self.Controls.m_PetTalentSkillQuality_2, AssetPath_PetSkillQuality[skillRecord_2.SkillQuality])
end

--刷新右侧界面
function PetTuJianWidget:RefreshRightWidget(nID,item)
	self:InitZiZhiWidgetView(nID)
end

--初始化资质View
function PetTuJianWidget:InitZiZhiWidgetView(nID)
	self:RefreshRight(nID)
end

--刷新右边的
function PetTuJianWidget:RefreshRight(nID)
	local record = IGame.rktScheme:GetSchemeInfo(PETMANUAL_CSV, nID)
	local qinYuan = IGame.PetClient:GetMyQingYuan()
	if not record then return end
	self.Controls.m_MyQingYuanText.text = string.format("我的情缘值：%d", qinYuan)
	
	self:RefreshZiZhiAdd(qinYuan)
end

--刷新资质加成
function PetTuJianWidget:RefreshZiZhiAdd(qingyuan)
	local addition = 0
	if qingyuan <= 0 then
		addition = 0
	elseif qingyuan >= gPetCfg.PetTuJianScoreAddConfig[1].lower and qingyuan <= gPetCfg.PetTuJianScoreAddConfig[1].upper then
		addition = gPetCfg.PetTuJianScoreAddConfig[1].add_per
	elseif qingyuan >= gPetCfg.PetTuJianScoreAddConfig[2].lower and qingyuan <= gPetCfg.PetTuJianScoreAddConfig[2].upper then
		addition = gPetCfg.PetTuJianScoreAddConfig[2].add_per
	elseif qingyuan >= gPetCfg.PetTuJianScoreAddConfig[3].lower and qingyuan <= gPetCfg.PetTuJianScoreAddConfig[3].upper then
		addition = gPetCfg.PetTuJianScoreAddConfig[3].add_per
	elseif qingyuan >= gPetCfg.PetTuJianScoreAddConfig[4].lower and qingyuan <= gPetCfg.PetTuJianScoreAddConfig[4].upper then
		addition = gPetCfg.PetTuJianScoreAddConfig[4].add_per
	else
		addition = gPetCfg.PetTuJianScoreAddConfig[4].add_per
	end
	
	self.Controls.m_LiLiang.text = string.format(" +%d%%", addition)
	self.Controls.m_MingJie.text = string.format(" +%d%%", addition)
	self.Controls.m_ZhiLi.text = string.format(" +%d%%", addition)
	self.Controls.m_JingLi.text = string.format(" +%d%%", addition)
	self.Controls.m_GenGu.text = string.format(" +%d%%", addition)
end

--关闭灵兽界面回调
function PetTuJianWidget:OnClosePetWindow()
	self.PetModelDisPlay:ShowPetModel(false)
	rktEventEngine.FireEvent(EVENT_PET_CLOSEHUANHUAPAGE, SOURCE_TYPE_PET, 0)
end

--选项按钮点击回调
function PetTuJianWidget:OnOptionBtnClick()
	local state = IGame.PetClient:GetPetTuJianState(self.m_CurID)
	if state == 0 then return end
	if state == 1 then 						--激活
		GameHelp.PostServerRequest("RequestActivePet_TuJian(" .. self.m_CurID .. ")")
	elseif state == 2 then					--打开幻化界面
		rktEventEngine.FireEvent(EVENT_PET_OPENHUANHUAPAGE, SOURCE_TYPE_PET, 0, self.m_CurID)
	end
end

return PetTuJianWidget
