--*****************************************************************
--** 文件名:	BossWdt.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-12-11
--** 版  本:	1.0
--** 描  述:	首领活动窗口
--** 应  用:  
--******************************************************************



local BossItemClass = require("GuiSystem.WindowList.HuoDong.Boss.BossItem")
local RewardItemClass = require("GuiSystem.WindowList.HuoDong.HuoDongRewardItem")

local BossWdt = UIControl:new
{
	windowName	= "BossWdt",
	m_CurFocusIdx = 1, 
	m_ModelObject = nil,
}

function BossWdt:Attach(obj)
	UIControl.Attach(self, obj)
    
    print("[BossWdt:Attach]", self.m_CurFocusIdx)
	self:InitData()

	self:InitWinData()
	
	self:InitRewardCtrl()
	
	self:InitListCtrl()
	
end

function BossWdt:InitData()
	GameHelp.PostServerRequest("RequestRobberBossInfo()")
end

function BossWdt:InitWinData()
	self.m_OnItemSelected = function(...) self:OnItemSelected(...) end 
end

function BossWdt:InitListCtrl()
	
	self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))

	self.m_TlgGroup =  self.Controls.m_BossListCtrl:GetComponent(typeof(ToggleGroup))	

	self.m_Scroller = self.Controls.m_BossListCtrl:GetComponent(typeof(EnhancedListView))
	self.m_Scroller.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
	self.m_Scroller.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)	
	
	self.m_Scroller:SetCellCount(0, true)
end

function BossWdt:InitModelEvts()
	
	self.m_OnDragModel = function(eventData) self:OnDragModel(eventData) end
	UIFunction.AddEventTriggerListener(self.Controls.m_BossModel, EventTriggerType.Drag, self.m_OnDragModel)
	
	self.m_OnClickModel = function(eventData) self:OnClickModel(eventData) end
	UIFunction.AddEventTriggerListener(self.Controls.m_BossModel, EventTriggerType.PointerClick, self.m_OnClickModel)
end

function BossWdt:InitRewardCtrl()
	local controls = self.Controls
	self.m_tRewardCtrl = 
	{
		controls.m_Reward1,
		controls.m_Reward2,
		controls.m_Reward3,
		controls.m_Reward4,
		controls.m_Reward5,
		controls.m_Reward6,
		controls.m_Reward7,
		controls.m_Reward8,
	}
	
	for idx, tCtrl in pairs(self.m_tRewardCtrl) do
		local item = RewardItemClass:new({})
		item:Attach(tCtrl.gameObject)
	end
end

function BossWdt:SubControlExecute()
	self.m_OnBossListUpdate = handler(self, self.OnBossListUpdate)
	rktEventEngine.SubscribeExecute(EVENT_ROBBER_BOSS_LIST_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.m_OnBossListUpdate)
end

function BossWdt:UnSubControlExecute()
	rktEventEngine.UnSubscribeExecute( EVENT_ROBBER_BOSS_LIST_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.m_OnBossListUpdate)
	self.m_OnBossListUpdate = nil
end

function BossWdt:OnEnable()
    self.m_CurFocusIdx = 1
	self:InitData()
end

function BossWdt:OnBossListUpdate()
	local nBossCnt = IGame.RobberBossClient:GetBossCnt()
	self.m_Scroller:SetCellCount(nBossCnt, true)
end

function BossWdt:RefreshDesc(idx)
	local tBoss = IGame.RobberBossClient:GetBossObj(idx)
	if not tBoss then
		print("[BossWdt:RefreshDesc]: 找不到Boss数据", idx)
		return
	end
	
	local tBossConfig = IGame.rktScheme:GetSchemeInfo(ROBBERBOSS_CSV, tBoss.nBossID)
	if not tBossConfig then
		print("[BossWdt:RefreshDesc]: 找不到Boss配置", tBoss.nBossID)
		return
	end
	
	local controls = self.Controls
	
	controls.m_TimeDesc.text = string_unescape_newline(tBossConfig.TimeDesc)
	controls.m_NumDesc.text  = string_unescape_newline(tBossConfig.NumDesc)
	controls.m_PosDesc.text  = string_unescape_newline(tBossConfig.PosDesc)
	controls.m_CurNum.text   = tBoss.nNum
end

function BossWdt:SetRewardInfo(nBossIdx, nRewardIdx, tCell)
	local behav = tCell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	local item = behav.LuaObject
	if not item then
		uerror("RewardBackItem:SetGoodsCellInfo item为空")
		return
	end
	
	local tGoods = IGame.RobberBossClient:GetBossRewardObj(nBossIdx, nRewardIdx)
	if not tGoods then
		return
	end
	
	item:SetItemCellInfo(tGoods)
end

function BossWdt:RefreshReward(nBossIdx)
	local nRewardCnt = IGame.RobberBossClient:GetBossRewardCnt(nBossIdx)
	for idx, tCtrl in pairs(self.m_tRewardCtrl) do
		if idx <= nRewardCnt then
			tCtrl.gameObject:SetActive(true)
			self:SetRewardInfo(nBossIdx, idx, tCtrl)
		else
			tCtrl.gameObject:SetActive(false)
		end
	end
end

function BossWdt:ShowMonsterModel(nBossID, nResourceID)
	if self.m_ModelObject then
		self.m_ModelObject:Destroy()
	end
	
	local tPostionCfg = gBossWinModelCfg[nBossID]
	if not tPostionCfg then
		print("[BossWdt:ShowMonsterModel]", nBossID)
		return
	end
	
	local param = {}
	param.entityClass = tEntity_Class_Monster
    param.layer = "UI"
    param.Name = "MonsterModel"
    param.Position = Vector3.New(tPostionCfg.ModelPosition[1], tPostionCfg.ModelPosition[2], tPostionCfg.ModelPosition[3])
	param.localScale  =  Vector3.New(tPostionCfg.ModelScale[1], tPostionCfg.ModelScale[2], tPostionCfg.ModelScale[3])
	param.rotate = Vector3.New(0,180,0)
	param.MoldeID =  nResourceID
	param.ParentTrs = self.Controls.m_BossModel.transform
	param.UID = GUI_ENTITY_ID_BOSS
	
	self.m_ModelObject = UICharacterHelp:new()
	self.m_ModelObject:Create(param)
end

function BossWdt:SwitchModel(idx)
	local tBoss = IGame.RobberBossClient:GetBossObj(idx)
	if not tBoss then
		print("[BossWdt:SwitchModel]: 找不到Boss数据", idx)
		return
	end
	
	local tMonsterConfig = IGame.rktScheme:GetSchemeInfo(MONSTER_CSV, tBoss.nMonsterID)
	if not tMonsterConfig then
		print("[BossWdt:SwitchModel]: 找不到Boss配置", tBoss.nMonsterID)
		return
	end

	local nResourceID = tMonsterConfig.lResID
	self:ShowMonsterModel(tBoss.nMonsterID, nResourceID)
end

function BossWdt:CreateCellItem(listcell)
	local item = BossItemClass:new({})
	
	item:Attach(listcell.gameObject)	
	item:SetToggleGroup(self.m_TlgGroup)
	item:SetSelectCB(self.m_OnItemSelected)

	--self:RefreshCellItems(listcell)
end

function BossWdt:RefreshCellItems(listcell)
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		uerror("Error： UI Window Behaviour")
		return
	end
	
	local item = behav.LuaObject
	if item == nil then
		uerror("LimitListWidget:RefreshCellItems item为空")
		return
	end
	
	local idx = listcell.dataIndex + 1
	local bFocus = (idx == self.m_CurFocusIdx)
	if nil ~= item and item.windowName == "BossItem" then 
		item:SetItemCellInfo(idx)
		item:SetFocus(bFocus)
	end
end

-- EnhancedListView 一行被“创建”时的回调
function BossWdt:OnGetCellView(goCell)
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler(self, self.OnRefreshCellView)
	self:CreateCellItem(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function BossWdt:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function BossWdt:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end

function BossWdt:OnItemSelected(idx)
	
	self:RefreshDesc(idx)
	
	self:RefreshReward(idx)
	
	self:SwitchModel(idx)
	
	self.m_CurFocusIdx = idx
end

function BossWdt:OnDragModel()
	
end

function BossWdt:OnClickModel()
	
end

function BossWdt:Hide()
	UIControl.Hide(self)
end

function BossWdt:OnDestroy()
	if self.m_ModelObject then
		self.m_ModelObject:Destroy()
		self.m_ModelObject = nil
	end
    
    self.m_CurFocusIdx = 1
        
	UIControl.OnDestroy(self)
end

return BossWdt