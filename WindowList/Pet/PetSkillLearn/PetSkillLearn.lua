
-----------------------------灵兽阵真灵附体技能页面------------------------------
local PetSkillItemClass = require( "GuiSystem.WindowList.Pet.PetSkillItem" )

--按钮图片
local OptionBtnImg = {
	AssetPath.TextureGUIPath .. "",						--学习
	AssetPath.TextureGUIPath .. "",						--附体
}

local PetSkillLearn = UIControl:new
{
	windowName = "PetSkillLearn",
	
	m_ScriptsCache = {},						--脚本缓存
	
	option_callback = nil, 						--optionBtn按钮点击回调
	item_callback = nil, 						--goodsItem点击回调
	
	m_CurSkillID = -1, 							--当前选中的ID
	m_GoodsID = -1,								--学习消耗的物品ID
	m_CurType = -1,								--当前打开类型
}

local TitleImgPath = {
	AssetPath.TextureGUIPath.."Pet_1/Pet_xuanzejineng.png",
	AssetPath.TextureGUIPath.."Pet_1/Pet_xuanzhezhenling.png",
}

local OptionBtnPath = {
	AssetPath.TextureGUIPath.."Common_frame/Common_mz_xuexi.png",
	AssetPath.TextureGUIPath.."Common_frame/Common_mz_xuexi.png",
}

function PetSkillLearn:Attach(obj)
	UIControl.Attach(self,obj)
	self.BtnClickCB = function() self:OnOptionBtnClick() end
	self.Controls.m_OptionBtn.onClick:AddListener(self.BtnClickCB)
	
	self.AddBtnClickCB = function() self:OnAddBtnClick() end
	self.Controls.m_AddBtn.onClick:AddListener(self.AddBtnClickCB)
	
	self.SkillClickCB = function(index, item) self:OnSkillClickCB(index, item) end
	
	self.ToggleGroup = self.Controls.m_ListParent.gameObject:GetComponent(typeof(ToggleGroup))
	
	self.OnCloseCB = function() self:Hide() end
	self.Controls.m_CloseBtn.onClick:AddListener(self.OnCloseCB)
--	UIFunction.AddEventTriggerListener(self.Controls.m_BGMask,  EventTriggerType.PointerClick, self.OnCloseCB)
	
	self.OnOpenPageCB = function(_,_,_,index, call_back) self:OpenPage(index, call_back) end
	rktEventEngine.SubscribeExecute(EVENT_PET_OPENSKILLLEARN,SOURCE_TYPE_PET, 0, self.OnOpenPageCB)
    
    self.updateSelectSkillItem = function() self:UpdateCurSelectSkillUI() end 
    rktEventEngine.SubscribeExecute(EVENT_PET_SKILL_FUTI, SOURCE_TYPE_PET, 0, self.updateSelectSkillItem)    
end

function PetSkillLearn:Show()
	UIControl.Show(self)
end

function PetSkillLearn:Hide( destroy )
	self.m_CurType = -1
	UIControl.Hide(self, destroy)
end

function PetSkillLearn:OnDestroy()
	option_callback = nil
	self.m_CurType = -1
	UIFunction.RemoveEventTriggerListener(self.Controls.m_BGMask,  EventTriggerType.PointerClick, self.OnCloseCB)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_OPENSKILLLEARN,SOURCE_TYPE_PET, 0, self.OnOpenPageCB)
    rktEventEngine.UnSubscribeExecute(EVENT_PET_SKILL_FUTI,SOURCE_TYPE_PET, 0, self.updateSelectSkillItem)
	UIControl.OnDestroy(self)
end
------------------------------------------------------------------------------------------------------------------
--打开面板接口	1-技能学习 2-阵灵附体
function PetSkillLearn:OpenPage(index , optionClickCB)
    
	self.option_callback = optionClickCB
	self.m_CurType = index
	
	UIFunction.SetImageSprite(self.Controls.m_TitleImg, TitleImgPath[index])
	UIFunction.SetImageSprite(self.Controls.m_OptionBtnImg, OptionBtnPath[index])
		
	self.Controls.m_ScrollView.verticalNormalizedPosition  = 1
	
    local skillList = nil
	if index == 1 then 
		skillList =  IGame.PetClient:GetAllPetSkillRecord()
	elseif index == 2 then
		skillList = IGame.PetClient:GetAllPetZhenLinRecord()
	else
		return
	end
    if not skillList then return end 
	--TODO
--	UIFunction.SetImageSprite(self.Controls.m_OptionImg, OptionBtnImg[index])
	
	self:InitListView(skillList)
	self:Show()
end

--设置技能view
function PetSkillLearn:SetSkillVeiw(skillID)
	local skillRecord
	if self.m_CurType == 1 then						--技能学些
		self.Controls.m_SkillExtraDes.gameObject:SetActive(false)
		skillRecord = IGame.rktScheme:GetSchemeInfo(PETSKILLBOOK_CSV, skillID, 1)
		if not skillRecord then return end
		self.Controls.m_SkillNameText.text = skillRecord.SkillName        
        local szText = ""
        if skillRecord.SkillDesc[1] then 
            szText = skillRecord.SkillDesc[1]
        end         
        if skillRecord.SkillDesc[2] then 
            szText = szText.."\n"..skillRecord.SkillDesc[2]
        end 
		self.Controls.m_SkillDes.text = szText
		self:SetCostGoodsView(skillRecord.NeedGoodsID1, skillRecord.NeedGoodsNum1)
	elseif self.m_CurType == 2 then					--阵灵学习
		self.Controls.m_SkillExtraDes.gameObject:SetActive(false)
		skillRecord = IGame.rktScheme:GetSchemeInfo(PETZHENCFG_CSV,skillID,1)
		if not skillRecord then return end
		self.Controls.m_SkillNameText.text = skillRecord.Name
		self.Controls.m_SkillDes.text = skillRecord.Desc
		self:SetCostGoodsView(skillRecord.ID, skillRecord.UpgradeUseNum)
	else
		return
	end
end

--设置消耗物品
function PetSkillLearn:SetCostGoodsView(goodsID,num)
	self.m_GoodsID = goodsID
	local goodRecord = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodsID)
	if not goodRecord then return end
	
	self.Controls.m_CostName.text =  "<color=#" .. AssetPath_GoodsQualityColor[goodRecord.lBaseLevel] .. ">" .. goodRecord.szName .. "</color>"
	UIFunction.SetImageSprite(self.Controls.m_CostBG, AssetPath.TextureGUIPath .. goodRecord.lIconID2)
	UIFunction.SetImageSprite(self.Controls.m_CostIcon, AssetPath.TextureGUIPath .. goodRecord.lIconID1)
	
	local haveNum = GameHelp:GetHeroPacketGoodsNum(goodsID)
	if haveNum >= num then
		self.Controls.m_CostNum.text = string.format("%d/%d",haveNum, num)
		self.Controls.m_AddBtn.gameObject:SetActive(false)
		self.CanPost = true
	else
		self.Controls.m_CostNum.text = string.format("<color=red>%d</color>/%d", haveNum, num)
		self.Controls.m_AddBtn.gameObject:SetActive(true)
		self.CanPost = false
	end
end

--初始化列表
function PetSkillLearn:InitListView(skillList)
	for i, data in pairs(self.m_ScriptsCache) do
		data:Destroy()
	end
	
	local index = 0
	for	i,data in pairs(skillList) do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetSkillItem,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_ListParent, false)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = PetSkillItemClass:new({})
			item:Attach(obj)

			if self.m_CurType == 1 then
				item:SetViewByID(data.PetSkillID,1)
                local num = IGame.PetClient:GetHaveGoodsNum(data.NeedGoodsID1)
                if num > 0 then 
                    item:SetLevel(true, num)
                    item:SetShowZheZhao(false)
                else 
                    item:SetLevel(false)
                    item:SetShowZheZhao(true)
                end
			else
				item:SetZhenLinViewByID(data.ID,1)
                local num = IGame.PetClient:GetHaveGoodsNum(data.ID)
                if num > 0 then 
                    item:SetLevel(true, num)
                    item:SetShowZheZhao(false)
                else 
                    item:SetLevel(false)
                    item:SetShowZheZhao(true)
                end                
			end	
			item:SetSelectCallback(self.SkillClickCB)			
			item:SetShowSelectEffect(true)
			item:SetToggleGroup(self.ToggleGroup)
			
			table.insert(self.m_ScriptsCache,i,item)
			index = index + 1
			if index == 1 then
				item:SetFocus(true)
			end
		end , i , AssetLoadPriority.GuiNormal )
	end
end

--点击技能item回调事件
function PetSkillLearn:OnSkillClickCB(index, item)
	self.m_CurSkillID = item.m_SkillID
	self:SetSkillVeiw(self.m_CurSkillID)
end

--点击option按钮回调事件
function PetSkillLearn:OnOptionBtnClick()
	if not self.CanPost then 
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "材料不足")
		return
	end

	if self.option_callback ~= nil then
        self.option_callback(self) 
	end	
end

--点击增加物品按钮
function PetSkillLearn:OnAddBtnClick()
	if self.m_GoodsID ~= 0 then
		local subInfo = {
			bShowBtnType	= 2, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
			ScrTrans = self.transform,	-- 源预设
		}
		UIManager.GoodsTooltipsWindow:SetGoodsInfo(self.m_GoodsID, subInfo )
	end
end

-- 刷新学习技能界面
function PetSkillLearn:UpdateCurSelectSkillUI()
    
    if self.m_CurSkillID then 
        self:SetSkillVeiw(self.m_CurSkillID)
    end
    
    for _, item in pairs(self.m_ScriptsCache) do 
        if item.m_SkillID == self.m_CurSkillID then 
            item:SetFocus(true)
            
			if self.m_CurType == 1 then
                local skillRecord = IGame.rktScheme:GetSchemeInfo(PETSKILLBOOK_CSV, self.m_CurSkillID, 1)
                if not skillRecord then return end
                local num = IGame.PetClient:GetHaveGoodsNum(skillRecord.NeedGoodsID1)
                if num > 0 then 
                    item:SetLevel(true, num)
                    item:SetShowZheZhao(false)
                else 
                    item:SetLevel(false)
                    item:SetShowZheZhao(true)
                end
			else
                local num = IGame.PetClient:GetHaveGoodsNum(self.m_CurSkillID)
                if num > 0 then 
                    item:SetLevel(true, num)
                    item:SetShowZheZhao(false)
                else 
                    item:SetLevel(false)
                    item:SetShowZheZhao(true)
                end  
            end
            
            break
        end
    end    
end

return PetSkillLearn