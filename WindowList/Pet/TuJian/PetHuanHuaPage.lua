local PetHuanHuaItemClass = require("GuiSystem.WindowList.Pet.TuJian.PetHuanHuaItem")

local PetHuanHuaPage = UIControl:new
{
	windowName = "PetHuanHuaPage",
	
	m_ItemCache = {},		--item脚本缓存
	
	m_petID = -1,			--点击哪个图鉴ID
	
	m_CurUID = nil, 		--当前点击的是哪个item
	m_CurGoodsID = -1,
}

function PetHuanHuaPage:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.Group = self.Controls.m_ToggleGroupTrans:GetComponent(typeof(ToggleGroup))
	
	self.OnItemClickCB = function(item) self:OnItemClick(item) end
	
	self.OnHuanHuaBtnClickCB = function() self:OnHuanHuaBtnClick() end						--幻化按钮点击
	self.Controls.m_HuaHuaBtn.onClick:AddListener(self.OnHuanHuaBtnClickCB)
	
	self.OnCostBtnClickCB = function() self:OnCostBtnClick() end 							--消耗材料获取按钮点击
	self.Controls.m_CostBtn.onClick:AddListener(self.OnCostBtnClickCB)
	
	self.CloseBtnCB = function() self:Hide() end											--关闭按钮点击
	self.Controls.m_CloseBtn.onClick:AddListener(self.CloseBtnCB)
	
	self.OpenPageCB = function(_,_,_,id) self:OpenPage(id) end								--打开幻化界面事件
	rktEventEngine.SubscribeExecute(EVENT_PET_OPENHUANHUAPAGE, SOURCE_TYPE_PET, 0, self.OpenPageCB)
end

function PetHuanHuaPage:Show()
	rktEventEngine.SubscribeExecute(EVENT_PET_CLOSEHUANHUAPAGE, SOURCE_TYPE_PET, 0,self.CloseBtnCB)
	UIControl.Show(self)
end

function PetHuanHuaPage:Hide( destroy )
	rktEventEngine.UnSubscribeExecute(EVENT_PET_CLOSEHUANHUAPAGE, SOURCE_TYPE_PET, 0,self.CloseBtnCB)
	UIControl.Hide(self, destroy)
end

function PetHuanHuaPage:OnDestroy()
	rktEventEngine.UnSubscribeExecute(EVENT_PET_OPENHUANHUAPAGE, SOURCE_TYPE_PET, 0, self.OpenPageCB)
	UIControl.OnDestroy(self)
end
-------------------------------------------------------------------------------------------------
function PetHuanHuaPage:OpenPage(id)
	local petTable = IGame.PetClient:GetCurPetTable()
	if table_count(petTable) <= 0 then 
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "当前没有灵兽,无法幻化")
		return
	end
	
	self.m_petID = id
	self:InitView()
	self:Show()
end

function PetHuanHuaPage:InitView()
	if table_count(self.m_ItemCache) > 0 then
		for i, data in pairs(self.m_ItemCache) do
			data:Destroy()
		end
	end
	
	self.m_ItemCache = {}
	
	local petTable = IGame.PetClient:GetCurPetTable()
	local num = table_count(petTable)
	if num > 0 then
		for i = 1, num do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetHuanHuaItem ,
			function ( path , obj , ud )
				obj.transform:SetParent(self.Controls.m_ListParent)
				obj.transform.localScale = Vector3.New(1,1,1)
				local item = PetHuanHuaItemClass:new({})
				item:Attach(obj)
				item:SetData(petTable[i].uid)
				item:SetToggleGroup(self.Group)
				item:SetSelectCallback(self.OnItemClickCB)
				if i == 1 then
					item:SetFocus(true)
				end
				table.insert(self.m_ItemCache,i,item)	
			end , i , AssetLoadPriority.GuiNormal )
		end
	end
	
	--刷新底部物品
	self:RefreshBottomView(self.m_petID)
end

--item点击回调
function PetHuanHuaPage:OnItemClick(item)
	self.m_CurUID = item.m_UID
end

--刷新下面view
function PetHuanHuaPage:RefreshBottomView(ID)
	local petRecord = IGame.PetClient:GetRecordByID(ID)
	if not petRecord then return end
	self.m_CurGoodsID = petRecord.HuanHuaUseItem
	self.m_CurGoodsNum = petRecord.HuanHuaUseNum
	local goodsRecord = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV,petRecord.HuanHuaUseItem)
	if not goodsRecord then return end 
	UIFunction.SetImageSprite(self.Controls.m_CostQualityImg, AssetPath.TextureGUIPath .. goodsRecord.lIconID2)
	UIFunction.SetImageSprite(self.Controls.m_CostIconImg, AssetPath.TextureGUIPath .. goodsRecord.lIconID1)
	self.Controls.m_CostNameText.text = string.format("<color=#%s>%s</color>",AssetPath_GoodsQualityColor[goodsRecord.lBaseLevel],goodsRecord.szName)
	local haveNum = GameHelp:GetHeroPacketGoodsNum(petRecord.HuanHuaUseItem)
	if haveNum >= petRecord.HuanHuaUseNum then
		self.CanPost = true
		self.Controls.m_CostNumText.text = string.format("%d/%d", haveNum, petRecord.HuanHuaUseNum)
	else
		self.CanPost = false
		self.Controls.m_CostNumText.text = string.format("<color=red>%d</color>/%d", haveNum, petRecord.HuanHuaUseNum)
	end
	
end

--幻化按钮点击事件
function PetHuanHuaPage:OnHuanHuaBtnClick()
		
    local petRecord = IGame.PetClient:GetRecordByUID(self.m_CurUID)
    if not petRecord then return end
    if petRecord.Type == 1 then
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "一代灵兽无法幻化")
        return
    end
    
    local isBattle = IGame.PetClient:IsBattleState(self.m_CurUID)
    if isBattle then
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "出战灵兽无法幻化")
        return
    end
    
    local goodsRecord = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, self.m_CurGoodsID)
    local petName = IGame.PetClient:GetPetName(self.m_CurUID)
    if not goodsRecord then return end
    
    local haveNum = GameHelp:GetHeroPacketGoodsNum(self.m_CurGoodsID)
    if self.m_CurGoodsNum > haveNum then
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "材料不足，无法幻化")
        return
    end    
    
    local contentStr = string.format("确认消耗%d个%s将<color=red>%s</color>幻化吗？", self.m_CurGoodsNum,goodsRecord.szName, petName)
    local data = {
            content = contentStr,
            confirmCallBack = function() 
                    local haveNum = GameHelp:GetHeroPacketGoodsNum(self.m_CurGoodsID)
                    if self.m_CurGoodsNum > haveNum then
                        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "材料不足，无法幻化")
                        return
                    end
                    GameHelp.PostServerRequest("RequestPetTuJian_HuanHua(" .. tostring(self.m_CurUID) .. "," .. self.m_petID .. ")") 
                    self:Hide()
                end
        }
    UIManager.ConfirmPopWindow:ShowDiglog(data)
end

--获取材料点击事件
function PetHuanHuaPage:OnCostBtnClick()
	if not self.CanPost then
		local subInfo = {
			bShowBtnType	= 2, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
		}
		UIManager.GoodsTooltipsWindow:SetGoodsInfo(self.m_CurGoodsID, subInfo )
	end
end

return PetHuanHuaPage
