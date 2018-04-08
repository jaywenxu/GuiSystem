-- 帮会研究院的窗口
-- @Author: LiaoJunXi
-- @Date:   2017-09-06 19:36:57
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-30 12:22:48

local ClanAcademyWindow = UIWindow:new
{
	windowName        = "ClanAcademyWindow",
	
	m_Presenter = nil,
	m_SkillCells = {}, -- 当前显示的技能项缓存
	m_RefreshUICallback = nil,
	m_SelCellIdx = 1, --当前选择的技能格
	m_HandleCellIdx = 0, --当前升级(学习)的技能格
	
	m_TabToggles = {},
	m_SelLefTabIdx = 0,
}

require("GuiSystem.WindowList.Clan.ClanSysDef")
local UIClanSkillCell = require(ClanSysDef.ClanBuildingPath .. "ClanSkillCell")
local UIContainor = require( "GuiSystem.UIContainer" )

-----------------------------公共重载方法-------------------------------
function ClanAcademyWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.m_Presenter = IGame.ClanBuildingPresenter
	
	self:SubscribeEvts()
	self:InitUI()
end

function ClanAcademyWindow:SubscribeEvts()
	self.m_RefreshUICallback = handler(self, self.RefreshUI)
	rktEventEngine.SubscribeExecute( EVENT_CLAN_SKILL_LIST_REFRESH, SOURCE_TYPE_CLAN, 0, self.m_RefreshUICallback)
end

function ClanAcademyWindow:UnSubscribeEvts()
	rktEventEngine.UnSubscribeVote(EVENT_CLAN_SKILL_LIST_REFRESH , SOURCE_TYPE_CLAN, 0, self.m_RefreshUICallback)
end

function ClanAcademyWindow:InitUI()
	local controls = self.Controls

	-- init list tgl group
	local scrollView  = controls.m_SkillScrollView
	controls.listTglGroup  = scrollView.viewport:GetComponent(typeof(ToggleGroup))
	
	-- Upgrade Option
	self.m_UpgradeOptionLua = UIContainor:new({})
	self.m_UpgradeOptionLua.windowName = "SkillUpgradeOptionGroup"
	self.m_UpgradeOptionLua:Attach(controls.m_SkillUpgradeOptionGroup.gameObject)
	
	-- BtnFunc for <Upgrade> <Learn> and <AddSilver>
	self.m_UpgradeOptionLua.Controls.m_UpgradeBtn.onClick:AddListener(handler(self, self.OnBtnUpgradeClicked))
	self.m_UpgradeOptionLua.Controls.m_LearnBtn.onClick:AddListener(handler(self, self.OnBtnUpgradeClicked))
	self.m_UpgradeOptionLua.Controls.m_AddSilverBtn.onClick:AddListener(handler(self, self.OnBtnAddSilverClicked))
	self.m_UpgradeOptionLua.Controls.m_AddContriBtn.onClick:AddListener(handler(self, self.OnBtnAddContriClicked))
	
	self.m_UpgradeSkillMatItem = require("GuiSystem.WindowList.PlayerSkill.UpgradeSkillMatItem")
	self.m_UpgradeSkillMatItem:Attach(self.m_UpgradeOptionLua.Controls.m_UpgradeSkillMatItem.gameObject)
	
	-- Base Info
	self.m_BaseInfoLua = UIContainor:new({})
	self.m_BaseInfoLua.windowName = "SkillBaseInfoGroup"
	self.m_BaseInfoLua:Attach(controls.m_SkillBaseInfoGroup.gameObject)
	
	-- ToggleFunc for <Base> <Ctrl> and <Element> --
	------------------------------------------------
	self.m_TabToggles = {
		controls.m_TabCtrlRise,
		controls.m_TabCtrlResist,
		controls.m_TabElementRise,
		controls.m_TabElementResist
	}
	for i=1, 4 do
		local tgl = self.m_TabToggles[i]
		tgl.onValueChanged:AddListener(function (on)
			self:OnTogglesChanged(i, on)
		end)
	end
	
	self.m_TabToggles[self.m_Presenter.AcademyTabToggles.CtrlRise].isOn = true
	------------------------------------------------
end

-- 界面销毁
function ClanAcademyWindow:OnDestroy()
	self:UnSubscribeEvts()
	self.m_Presenter.m_AcademyTabIdx = 0
	self.m_Presenter = nil
	self.m_RefreshUICallback = nil
	
	UIWindow.OnDestroy(self)
	table_release(self)
	
	self.m_SelCellIdx = 1
end

----------------------- 刷新UI -------------------------
function ClanAcademyWindow:RefreshUI()
	print(debug.traceback("ClanAcademyWindow:RefreshUI()"))
	if not self:isShow() then
		return
	end
	if self.m_HandleCellIdx == 0 then
		print("self.m_HandleCellIdx == 0")
		self.m_Presenter:PrepareSkillsData(self.m_SelLefTabIdx)
		self:DestroySkillCells()
		self:CreateSkillCells()
	else
		print("self.m_HandleCellIdx != 0")
		local idx = self.m_HandleCellIdx
		self:RefreshSkillCell(idx)
		self.m_HandleCellIdx = 0
	end
end

-- 销毁Skill Cell List的所有Cell，释放table
function ClanAcademyWindow:DestroySkillCells()
	for i,cell in pairs(self.m_SkillCells) do
		cell:Destroy()
	end
	self.m_SkillCells = {}
end

-- 创建Skill Cell List
function ClanAcademyWindow:CreateSkillCells()
	local skillList = self.m_Presenter:GetSkillDataList()
	if not skillList then return end
	local count = #skillList

	for i=1, count do
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.ClanBuilding.ClanSkillCell,
		
		function ( path , obj , ud ) 
			local controls = self.Controls
			
			obj.transform:SetParent(controls.m_SkillCellContainer)
			obj.transform.localScale = Vector3.New(1,1,1)
			
			local cell = UIClanSkillCell:new({})
			cell:Attach(obj)
			
			cell:SetToggleGroup(controls.listTglGroup)
			cell:SetSelectCallback(handler(self, self.OnItemCellSelected))
			-- 刷新Cell
			self:RefreshSkillCell(i, cell)
			
			table.insert(self.m_SkillCells,i,cell)
			
		end , i , AssetLoadPriority.GuiNormal )
	end
end

-- 刷新 Skill Cell
function ClanAcademyWindow:RefreshSkillCell(idx, cell)
	if not cell then cell = self.m_SkillCells[idx] end
	cell:SetCellData(idx, self.m_Presenter:GetSkillData(idx))
	
	if self.m_SelCellIdx == 0 then
		self.m_SelCellIdx = 1
	end
	if idx == self.m_SelCellIdx and cell:IsToggleOn() then
		self:OnItemCellSelected(idx)
	end
	cell:SetToggleIsOn(idx == self.m_SelCellIdx)
end

-- 刷新技能信息和操作按钮
function ClanAcademyWindow:SetSelSkillDesc(idx)
	local data = self.m_Presenter.m_SkillList[idx]
	if data == nil then self.m_SelCellIdx = 1 return end
	
	local controls = self.Controls
	-- 技能基本信息
	self.m_BaseInfoLua.Controls.m_SkillName.text = data.m_UpdateCfg.Name
	self.m_BaseInfoLua.Controls.m_SkillLevel.text = GetValuable(data.m_Unlock,data.nLevel .. "级","<color=#E4595A>未学会</color>")
	self.m_BaseInfoLua.Controls.m_SkillDesc.text = data.m_UpdateCfg.CommonDesc
	if nil ~= data.m_CoolTime then
		self.m_BaseInfoLua.Controls.m_CoolTime.text = string.format("冷却时间：%.1fs", data.m_CoolTime)
	end
	self.m_BaseInfoLua.Controls.m_CastDistance.text = GetValuable(nil~=data.m_DistanceTxt,data.m_DistanceTxt,"")
	-- 技能当前等级效果
	controls.m_CurSkillEffTxt.text = data.m_UpdateCfg.LevelDesc
	controls.m_CurSkillLevTip.text = GetValuable(data.m_Unlock, "当前等级：","下一等级：")
	-- 技能满级
	if data.m_IsMaxLev then 
		controls.m_SkillLevelMaxWarn.gameObject:SetActive(true)
		controls.m_SkillUpgradeOptionGroup.gameObject:SetActive(false)
		controls.m_NextLevEffGroup.gameObject:SetActive(false)
		return
	else
		controls.m_SkillLevelMaxWarn.gameObject:SetActive(false)
		controls.m_SkillUpgradeOptionGroup.gameObject:SetActive(true)
	end
	if data.m_Unlock then
		controls.m_CurSkillLevTip.gameObject:SetActive(false)
	else
		controls.m_CurSkillLevTip.gameObject:SetActive(true)
	end
	-- 技能下个等级效果
	controls.m_NextSkillEffTxt.text = GetValuable(nil ~= data.nextLevDesc,data.nextLevDesc,"")
	controls.m_NextSkillCondition.text = data.m_LevDemandTxt
	controls.m_NextLevEffGroup.gameObject:SetActive(data.m_Unlock)
	-- 按钮切换
	controls = self.m_UpgradeOptionLua.Controls
	controls.m_UpgradeBtn.gameObject:SetActive(data.m_Unlock)
	controls.m_LearnBtn.gameObject:SetActive(not data.m_Unlock)
	-- 面板切换
	controls.m_UpgradeMatRect.gameObject:SetActive(data.m_IsCostMat)
	controls.m_UpgradeCostRect.gameObject:SetActive(not data.m_IsCostMat)
	controls.m_UpgradeHaveRect.gameObject:SetActive(not data.m_IsCostMat)
	if data.m_IsCostMat then
		self.m_UpgradeSkillMatItem:UpdateItem(data.NeedGoodsID, data.NeedGoodsNum)
	else
		local nHoldingValue = IGame.EntityClient:GetHero():GetYinBiNum()
		controls.m_SilverCoinCostValue.text = tostring(data.m_NeedSliver)
		controls.m_ClanContribCostValue.text = tostring(data.m_NeedClanContribution)
		controls.m_SilverCoinHoldingValue.text = "<color="..data.m_SliverColor..">" .. nHoldingValue .. "</color>"
		controls.m_ClanContribHoldingValue.text = "<color="..data.m_ContribColor..">" .. (self.m_Presenter:GetContribute()) .. "</color>"
		controls.m_AddContriBtn.gameObject:SetActive(self.m_Presenter:GetContribute() < data.m_UpdateCfg.NeedClanContribution)
		
		if nHoldingValue <= 0 then
			-- ...
			nHoldingValue = IGame.EntityClient:GetHero():GetYinLiangNum()
			controls.m_SilverCoinHoldingValue.text = "<color=white>" .. nHoldingValue .. "</color>"
			controls.m_SilverCoinHoldingIcon.enabled = false
			controls.m_SilverYuanHoldingIcon.enabled = true
			controls.m_SilverCoinCostIcon.enabled = false
			controls.m_SilverYuanCostIcon.enabled = true
		else
			controls.m_SilverCoinHoldingIcon.enabled = true
			controls.m_SilverYuanHoldingIcon.enabled = false
			controls.m_SilverCoinCostIcon.enabled = true
			controls.m_SilverYuanCostIcon.enabled = false
		end
	end
end

-----------------------界面响应事件方法-------------------------
-- 显示窗口
function ClanAcademyWindow:ShowWindow()
	UIWindow.Show(self, true)
	UIManager.ClanOwnWindow.CommonWindowWidget.closeCallback = handler(self, self.OnBtnCloseClicked)
end

-- <基本属性><控制强化><控制抵抗><元素强化><元素抵抗>之间切换tab
function ClanAcademyWindow:OnTogglesChanged(idx, on)
	if on then
		if self.m_SelLefTabIdx ~= 0 then
			self:SwitchTab(idx)
		else
			self.m_SelCellIdx = 1
			self.m_SelLefTabIdx = 1
			self:RefreshUI()
		end
	end
end

-- 切换tab
function ClanAcademyWindow:SwitchTab(idx)
	self:DestroySkillCells()
	
	self.m_SelCellIdx = 1
	self.m_HandleCellIdx = 0
	self.m_SelLefTabIdx = idx
	
	self:RefreshUI()
	
	--[[local tabText = self.m_TabToggles[idx].graphic.transform:GetComponentInChildren(typeof(Text))
	tabText.color = Color.New(0.851,1,1,1)
	for i=1,#self.m_TabToggles do
		if i ~= idx then
			tabText = self.m_TabToggles[i].graphic.transform:GetComponentInChildren(typeof(Text))
			tabText.color = Color.New(0.330,0.604,0.753,1)
		end
	end--]]
end

-- 选中建筑Cell后，Cell的Toggle回调
function ClanAcademyWindow:OnItemCellSelected(idx)
	local data = self.m_Presenter:GetSkillData(idx)
	if not data then self.m_SelCellIdx = 1 return end
	
	self.m_SelCellIdx = idx
	
	self:SetSelSkillDesc(idx)
end

-- 点击升级(学习)技能
function ClanAcademyWindow:OnBtnUpgradeClicked()
	local data = self.m_Presenter:GetSkillData(self.m_SelCellIdx)
	if not data then self.m_SelCellIdx = 1 return end
	
	if data.m_ContribSatisfy then
		self.m_HandleCellIdx = self.m_SelCellIdx
		local hero = GetHero()
		local studyPart = hero:GetEntityPart(ENTITYPART_PERSON_STUDYSKILL)
		if studyPart then
			--[[if data.m_SliverSatisfy then--]]
				if data.m_BdLevSatisfy and data.m_LevelSatisfy then
					studyPart:RequestUpgradeSkill(data.nID)
					self.m_Presenter.m_CurUpgradeSkill = data
				else
					if not data.m_LevelSatisfy then
						IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你的等级不足！")
					else
						IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "研究院的等级不足！")
					end
				end
			--[[else
				IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你的银币不足！")
			end--]]
		end
	else
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你的帮贡不足！")
	end
end

-- 点击获取银币
function ClanAcademyWindow:OnBtnAddSilverClicked()
	UIManager.ShopWindow:OpenShop(2415)
end

function ClanAcademyWindow:OnBtnAddContriClicked()
	--UIManager.ShopWindow:OpenShop(9005)
	--if self.m_nGoodsID ~= 0 then
		local subInfo = {
			bShowBtnType	= 2, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
		}
		UIManager.GoodsTooltipsWindow:SetGoodsInfo(9005, subInfo )
	--end
end

-- 界面隐藏
function ClanAcademyWindow:OnBtnCloseClicked()
	self:Hide()
	local owenWin = UIManager.ClanOwnWindow
	UIManager.ClanOwnWindow.CommonWindowWidget.closeCallback = handler(owenWin, owenWin.Hide)
end

return ClanAcademyWindow