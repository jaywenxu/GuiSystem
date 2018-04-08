-- 帮会研究院的窗口
-- @Author: LiaoJunXi
-- @Date:   2017-09-06 19:36:57
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-30 12:22:48

local ClanWarfareWindow = UIWindow:new
{
	windowName        = "ClanWarfareWindow",
	
	m_Presenter = nil,
	m_WeaponCells = {}, -- 当前显示的Weapon项缓存
	m_RefreshUICallback = nil,
	m_SelCellIdx = 1, --当前选择的Weapon格
	m_HandleCellIdx = 0, --当前升级(打造)的Weapon格
}

require("GuiSystem.WindowList.Clan.ClanSysDef")
local UIClanWeaponCell = require(ClanSysDef.ClanBuildingPath .. "ClanWeaponCell")

-----------------------------公共重载方法-------------------------------
function ClanWarfareWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.m_Presenter = IGame.ClanBuildingPresenter
	
	self:SubscribeEvts()
	self:InitUI()
	self:ShowUI()
end

function ClanWarfareWindow:SubscribeEvts()
	self.m_RefreshUICallback = handler(self, self.RefreshUI)
	rktEventEngine.SubscribeExecute( EVENT_CLAN_WEAPON_LIST_REFRESH, SOURCE_TYPE_CLAN, 0, self.m_RefreshUICallback)
end

function ClanWarfareWindow:UnSubscribeEvts()
	rktEventEngine.UnSubscribeVote(EVENT_CLAN_WEAPON_LIST_REFRESH , SOURCE_TYPE_CLAN, 0, self.m_RefreshUICallback)
end

function ClanWarfareWindow:InitUI()
	local controls = self.Controls

	-- init list tgl group
	local scrollView  = controls.m_ScrollView
	controls.listTglGroup  = scrollView.content:GetComponent(typeof(ToggleGroup))
	
	-- Upgrade Option
	controls.m_UpgradeBtn.onClick:AddListener(handler(self, self.OnBtnUpgradeClicked))
	------------------------------------------------
end

-- 界面销毁
function ClanWarfareWindow:OnDestroy()
	self:UnSubscribeEvts()
	self.m_Presenter = nil
	self.m_RefreshUICallback = nil
	
	UIWindow.OnDestroy(self)
	table_release(self)
	
	self.m_SelCellIdx = 1
end

----------------------- 刷新UI -------------------------
function ClanWarfareWindow:RefreshUI()
	if not self:isShow() then
		return
	end
	if self.m_HandleCellIdx == 0 then
		--self:DestroyCells()
		self:CreateCells()
	else
		local idx = self.m_HandleCellIdx
		self:RefreshCell(idx)
		self.m_HandleCellIdx = 0
	end
end

-- 销毁Weapon Cell List的所有Cell，释放table
function ClanWarfareWindow:DestroyCells()
	for i,cell in pairs(self.m_WeaponCells) do
		cell:Destroy()
	end
	self.m_WeaponCells = {}
end

-- 创建Weapon Cell List
function ClanWarfareWindow:CreateCells()
	local nList = self.m_Presenter:GetWeaponDataList()
	if not nList then return end
	local count = #nList

	for i=1, count do
		local cell = self.m_WeaponCells[i]
		if not cell then
			rkt.GResources.FetchGameObjectAsync( GuiAssetList.ClanBuilding.ClanWeaponCell,	
				function ( path , obj , ud )
					local controls = self.Controls
					
					obj.transform:SetParent(controls.m_ViewPort)
					obj.transform.localScale = Vector3.New(1,1,1)
					
					cell = UIClanWeaponCell:new({})
					cell:Attach(obj)
					table.insert(self.m_WeaponCells,i,cell)	
					
					cell:SetToggleGroup(controls.listTglGroup)
					cell:SetSelectCallback(handler(self, self.OnItemCellSelected))
					-- 刷新Cell
					self:RefreshCell(i, cell)
				end ,
			i , AssetLoadPriority.GuiNormal )
		else
			self:RefreshCell(i, cell)
		end
	end
end

-- 刷新 Weapon Cell
function ClanWarfareWindow:RefreshCell(idx, cell)
	if not cell then cell = self.m_WeaponCells[idx] end
	cell:SetCellData(idx, self.m_Presenter:GetWeaponData(idx))
	
	if self.m_SelCellIdx == 0 then
		self.m_SelCellIdx = 1
	end
	if idx == self.m_SelCellIdx and cell:IsToggleOn() then
		self:OnItemCellSelected(idx)
	end
	cell:SetToggleIsOn(idx == self.m_SelCellIdx)
end

function ClanWarfareWindow:SetWeaponDemandDesc(data)
	local controls = self.Controls
	local demandCapacity = 4
	if nil ~= data.m_Demand and type(data.m_Demand) == "table" then
		local capacity = 1
		for i = 1, #data.m_Demand do
			if i <= demandCapacity then
				controls["m_DemandDescTxt_"..i].text = data.m_Demand[i]
				controls["m_Demand_"..i].gameObject:SetActive(true)
				capacity = capacity + 1
			end
		end
		if capacity <= demandCapacity then
			for k = capacity, demandCapacity do
				controls["m_Demand_"..k].gameObject:SetActive(false)
			end
		end
	else
		print("<color=#E4595A>错误：要求为空或者不是table</color>")
	end
end

-- 刷新技能信息和操作按钮
function ClanWarfareWindow:SetSelWeaponDesc(idx)
	local data = self.m_Presenter:GetWeaponData(idx)
	if data == nil then self.m_SelCellIdx = 1 return end
	
	local controls = self.Controls
	controls.m_NameTxt.text = data.m_WeaponCfg.Name
	controls.m_LevTxt.text = GetValuable(data.m_Unlock, data.Level .. "级", "<color=#E4595A>未解锁</color>")
	controls.m_DemandTxt.text = data.m_DemandDesc
	
	self:SetWeaponDemandDesc(data)
	
	if not data.m_IsMaxLev then
		controls.m_BaseInfoContainer.gameObject:SetActive(true)
		
		local m_Funds = IGame.ClanClient:GetClanData(emClanProp_Funds)
		local color = GetValuable(data.m_Cost <= m_Funds, "<color=#597993FF>", "<color=#E4595A>")
		controls.m_CostTxt.text = tostring(data.m_Cost)
		controls.m_HasTxt.text = color .. m_Funds .. "</color>"	
	else
		--controls.m_BaseInfoContainer.gameObject:SetActive(false)
		controls.m_CostTxt.text = "<color=#10a41b>已满级</color>"
		controls.m_HasTxt.text = tostring(m_Funds)
		controls["m_Demand_1"].gameObject:SetActive(true)
		controls["m_DemandDescTxt_1"].text = "<color=#10a41b>已满级</color>"
		for i = 2, 4 do
			controls["m_Demand_"..i].gameObject:SetActive(false)
		end
	end
	UIFunction.SetComsGray(controls.m_UpgradeBtn.gameObject, data.m_IsMaxLev, {typeof(Image)})
	
	controls.m_UpgradeBtn.gameObject:SetActive((self.m_Presenter:IsIDentity(emClanIdentity_Shaikh) or
	self.m_Presenter:IsIDentity(emClanIdentity_Underboss)) and (not data.m_IsMaxLev))
	controls.m_UpgradeImg.enabled = data.m_Unlock
	controls.m_UnlockImg.enabled = not data.m_Unlock
	
	-- 技能当前等级效果
	controls.m_CurrentLevelContent.text = (string.gsub(data.m_WeaponCfg.Desc, "\\n", "\n"))
	controls.m_CurrentLevelTip.text = GetValuable(data.m_Unlock, "当前等级：","武器效果：")
	controls.m_NextLevStatus.gameObject:SetActive(data.m_Unlock and not data.m_IsMaxLev)
	
	-- 技能下个等级效果
	controls.m_NextLevelContent.text = GetValuable(not IsNilOrEmpty(data.nextLevDesc), (string.gsub(data.nextLevDesc, "\\n", "\n")), "")
	
	if nil ~= data.m_WeaponCfg.Icon and "" ~= data.m_WeaponCfg.Icon then
		UIFunction.SetImageSprite(self.Controls.m_IconImg, GuiAssetList.GuiRootTexturePath .. data.m_WeaponCfg.Icon)
	end
end

-----------------------界面响应事件方法-------------------------
-- 显示窗口
function ClanWarfareWindow:ShowWindow()
	UIWindow.Show(self, true)
	UIManager.ClanOwnWindow.CommonWindowWidget.closeCallback = handler(self, self.OnBtnCloseClicked)
	
	if not self:isLoaded() then
		return
	end
	self:ShowUI()
end

function ClanWarfareWindow:ShowUI()
	self.m_SelCellIdx = 1
	self.m_HandleCellIdx = 0
	self:RefreshUI()
end

-- 选中Cell后，Cell的Toggle回调
function ClanWarfareWindow:OnItemCellSelected(idx)
	local data = self.m_Presenter:GetWeaponData(idx)
	if not data then self.m_SelCellIdx = 1 return end
	
	self.m_SelCellIdx = idx
	
	self:SetSelWeaponDesc(idx)
end

-- 点击升级
function ClanWarfareWindow:OnBtnUpgradeClicked()
	if self.m_Presenter:IsIDentity(emClanIdentity_Shaikh) or 
		self.m_Presenter:IsIDentity(emClanIdentity_Underboss) then
		--local nWeapon = self.m_Presenter:GetWeaponData(self.m_SelCellIdx)
		self.m_HandleCellIdx = self.m_SelCellIdx
		self.m_Presenter.m_BuildingModel:GetWarObj():UpgradeToolsRsq(self.m_SelCellIdx)
	else
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你没有解锁或升级的权限！")
	end
end

-- 界面隐藏
function ClanWarfareWindow:OnBtnCloseClicked()
	self:Hide()
	local owenWin = UIManager.ClanOwnWindow
	UIManager.ClanOwnWindow.CommonWindowWidget.closeCallback = handler(owenWin, owenWin.Hide)
end

return ClanWarfareWindow