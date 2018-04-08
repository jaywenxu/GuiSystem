--*****************************************************************
--** 文件名:	ArrestRobberWdt.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	何荣德
--** 日  期:	2017-12-18
--** 版  本:	1.0
--** 描  述:	缉拿大盗窗口
--** 应  用:  
--******************************************************************

local RobberCellClass = require("GuiSystem.WindowList.ArrestRobber.RobberCell")
local RewardItemClass = require("GuiSystem.WindowList.HuoDong.HuoDongRewardItem")

local ArrestRobberWdt = UIControl:new
{
	windowName	= "ArrestRobberWdt",
	m_CurFocusIdx = 1, 
    tRobberItem = {},
}

function ArrestRobberWdt:Attach(obj)
	UIControl.Attach(self, obj)
    
    self:InitListCtrl()
end

function ArrestRobberWdt:InitListCtrl()
    self.m_OnItemSelected = function(...) self:OnItemSelected(...) end 
    
	self.m_RobberTlgGroup =  self.Controls.m_RobberList:GetComponent(typeof(ToggleGroup))	
    
	self.Controls.m_LeftBtn.onClick:AddListener(handler(self, self.OnLeftBtnClick))
	self.Controls.m_RightBtn.onClick:AddListener(handler(self, self.OnRightBtnClick))
    self.Controls.m_ZuDuiBtn.onClick:AddListener(handler(self, self.OnZuDuiBtnClick))
	self.Controls.m_QianWangBtn.onClick:AddListener(handler(self, self.OnQianWangBtnClick))
	
	self.m_ObjectDisplay = self.Controls.m_ObjectDisplay:GetComponent(typeof(RawImage))

	self.m_RobberScroller = self.Controls.m_RobberList:GetComponent(typeof(EnhancedListView))
	self.m_RobberScroller.onGetCellView:AddListener(function(goCell) self:OnGetCellView(goCell) end)
	self.m_RobberScroller.onCellViewVisiable:AddListener(function(goCell) self:OnCellViewVisiable(goCell) end)	
    
    self:InitRobberList()
    self:InitRewardList()
    
    self.Controls.m_TipsText.text = gArrestRobberCfg.szTips
    local msg = "奖励次数: <color=#10a41b>0/3</color>"
    local huodong = IGame.ActivityList:GetHuoDong(gArrestRobberCfg.nHuoDongId)
    if huodong then
        msg = "奖励次数: <color=#10a41b>" .. huodong:GetCurTimes() .. "/" .. huodong:GetMaxTimes() .. "</color>"
    else
        uerror("ArrestRobberWdt:RefreshDesc huodong = nil")
    end
	self.Controls.m_TimesText.text = msg
end

function ArrestRobberWdt:InitRobberList()
	local nRobberCnt = table_count(gArrestRobberCfg.tRobberList)
	self.m_RobberScroller:SetCellCount(nRobberCnt, true)
end

function ArrestRobberWdt:InitRewardList()
	local count =  IGame.ActivityReward:GetActRewardCnt(gArrestRobberCfg.nHuoDongId)
    local controls = self.Controls
	self.m_tRewardCtrl = 
	{
		controls.m_Reward1,
		controls.m_Reward2,
		controls.m_Reward3,
	}
	
	for idx, tCtrl in pairs(self.m_tRewardCtrl) do
        if count < idx then
            break
        end
		local item = RewardItemClass:new({})
		item:Attach(tCtrl.gameObject)
        tCtrl.gameObject:SetActive(true)
		self:SetRewardInfo(idx, item)
	end
end

function ArrestRobberWdt:SetRewardInfo(idx, item)
    local reward = IGame.ActivityReward:GetActReward(gArrestRobberCfg.nHuoDongId, idx)
    if not reward then
        return
    end
    
    item:SetItemCellInfo(reward)
end

function ArrestRobberWdt:RefreshDesc(idx)
	self.Controls.m_TitleText.text = gArrestRobberCfg.tNameTitle[idx]
	self.Controls.m_IntroduceText.text = gArrestRobberCfg.tIntroduce[idx]
end

function ArrestRobberWdt:CreateCellItem(listcell)
	local item = RobberCellClass:new({})
	
	item:Attach(listcell.gameObject)	
	item:SetToggleGroup(self.m_RobberTlgGroup)
	item:SetSelectedCallback(self.m_OnItemSelected)
	item:SetCellInfo(listcell.dataIndex + 1)
    self.tRobberItem[listcell.dataIndex + 1] = item

	self:RefreshCellItems(listcell)
end

function ArrestRobberWdt:RefreshCellItems(listcell)
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
	
	if nil ~= item and item.windowName == "RobberCell" then 
		item:SetFocus(bFocus)
	end
end

-- EnhancedListView 一行被“创建”时的回调
function ArrestRobberWdt:OnGetCellView(goCell)
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler(self, self.OnRefreshCellView)
	self:CreateCellItem(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function ArrestRobberWdt:OnRefreshCellView( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end

-- EnhancedListView 一行可见时的回调
function ArrestRobberWdt:OnCellViewVisiable( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems( listcell )
end

function ArrestRobberWdt:ShowRobberModel(tWinModelPos, nResourceID)
	if nResourceID == self.m_CurResID then
		return
	end
	
	if self.m_ModelObject then
		self.m_ModelObject:Destroy()
	end
	
	local param = {}
	param.entityClass = tEntity_Class_Monster
    param.layer = "UI"
    param.Name = "MonsterModel"
    param.Position = Vector3.New(tWinModelPos.ModelPosition[1], tWinModelPos.ModelPosition[2], tWinModelPos.ModelPosition[3])
	param.localScale  =  Vector3.New(tWinModelPos.ModelScale[1], tWinModelPos.ModelScale[2], tWinModelPos.ModelScale[3])
	param.rotate = Vector3.New(tWinModelPos.ModelRotate[1], tWinModelPos.ModelRotate[2], tWinModelPos.ModelRotate[3])
	param.MoldeID =  nResourceID
	param.ParentTrs = self.Controls.m_ObjectDisplay.transform
	param.UID = GUI_ENTITY_ID_ROBBER
	
	self.m_ModelObject = UICharacterHelp:new()
	self.m_ModelObject:Create(param)
end

function ArrestRobberWdt:SwitchRobberModel(idx)
	local tRobber = gArrestRobberCfg.tRobberList[idx]
	if not tRobber then
		print("[ArrestRobberWdt:SwitchRobberModel]: 找不到robber数据", idx)
		return
	end
	
	local tMonsterConfig = IGame.rktScheme:GetSchemeInfo(MONSTER_CSV, tRobber.monsterId)
	if not tMonsterConfig then
        print("[ArrestRobberWdt:SwitchRobberModel]: 找不到robber配置", tRobber.monsterId)
		return
	end
    
	local nResourceID = tMonsterConfig.lResID
    local tWinModelPos = gArrestRobberCfg.tWinModelPos[tRobber.monsterId]
    if not tWinModelPos then
        print("[ArrestRobberWdt:SwitchRobberModel]: 找不到robber模型位置配置", tRobber.monsterId)
		return
    end
    
	self:ShowRobberModel(tWinModelPos, nResourceID)
end

function ArrestRobberWdt:OnItemSelected(idx)
    idx = tonumber(idx)
	self.m_CurFocusIdx = idx
    self:SwitchRobberModel(idx)
    self:RefreshDesc(idx)
end

function ArrestRobberWdt:OnLeftBtnClick()
    if self.m_CurFocusIdx <= 1 then
        return
    end
    
    self.tRobberItem[self.m_CurFocusIdx - 1]:SetFocus(true)
end

function ArrestRobberWdt:OnRightBtnClick()
    if self.m_CurFocusIdx >= table_count(self.tRobberItem) then
        return
    end
    
    self.tRobberItem[self.m_CurFocusIdx + 1]:SetFocus(true)
end

function ArrestRobberWdt:OnZuDuiBtnClick()
    UIManager.ArrestRobberWindow:Hide()
    UIManager.TeamWindow:GotoActivetyByID(gArrestRobberCfg.nTeamTargetId)
end

function ArrestRobberWdt:OnQianWangBtnClick()
    local robberInfo = gArrestRobberCfg.tRobberList[self.m_CurFocusIdx]
    if not robberInfo then
        uerror("ArrestRobberWdt:OnQianWangBtnClick robberInfo=nil self.m_CurFocusIdx=" .. self.m_CurFocusIdx)
        return
    end
    
    if self.tRobberItem[self.m_CurFocusIdx]:IsSuo() then
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "当前文明等级暂未开放")
        return    
    end
    
    UIManager.ArrestRobberWindow:Hide()
    GameHelp.PostServerRequest("RequestFindArrestRobberPos(" .. robberInfo.level .. ")")	
end

return ArrestRobberWdt