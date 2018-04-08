--/******************************************************************
---** 文件名:	WuXueDisplayWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-10-14
--** 版  本:	1.0
--** 描  述:	玩家技能窗口-武学窗口-展示窗口
--** 应  用:  针对策划日息万变的需求，不改那个旋转的代码另外加了个脚本
--******************************************************************/

local WuXueMiJiItem = require("GuiSystem.WindowList.PlayerSkill.WuXueMiJiItem")
local WuXueBookItem = require("GuiSystem.WindowList.PlayerSkill.WuXueBookItem")

local WuXueVerDragWidget = UIControl:new
{
	windowName = "WuXueVerDragWidget",
	m_listAllWuXueScheme = nil,
	m_wuxueTableSort = {},
	m_IsWuXueItemCreateSucc = false,	-- 所有武学图标创建成功的标识:boolean
	m_TotalWuXueCnt = 0,				-- 总武学数量:number
	m_CurSelectedWuXueId = 0,			-- 当前选中的武学id:number
	m_CurSelectedMiJiId = 0,			-- 当前选中的秘籍id:number
	
	m_ListWuXueItem = {},				-- 武学图标实例脚本列表:table(WuXueBookItem)
	m_ListMiJiItem = {},				-- 秘籍图标实例脚本列表:table(WuXueMiJiItem)
}

-- 显示3个秘籍图标时的图标位置
local ArrWuXueMiJiItemPos3 = 
{
	Vector3.New(-331.89,28.2, 0),
	Vector3.New(-131, 138.6, 0),
	Vector3.New(67.87, 22.6, 0),
}

-- 显示4个秘籍图标时的图标位置
local ArrWuXueMiJiItemPos4 = 
{
	Vector3.New(-331.89,28.2, 0),
	Vector3.New(-204.7, 138.6, 0),
	Vector3.New(-47.7, 137, 0),
	Vector3.New(68, 22.2, 0),
}

-- 显示5个秘籍图标时的图标位置
local ArrWuXueMiJiItemPos5 = 
{
	Vector3.New(-594, 31, 0),
	Vector3.New(-315, 175, 0),
	Vector3.New(-111, -55, 0),
	Vector3.New(-223, -308, 0),
	Vector3.New(-556, -283, 0),
}


function WuXueVerDragWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	self.m_listAllWuXueScheme = IGame.rktScheme:GetSchemeTable(BATTLEBOOK_ACTIVATION_CSV)
	if not self.m_listAllWuXueScheme then
		return
	end
	for k,v in pairs(self.m_listAllWuXueScheme) do
		table.insert(self.m_wuxueTableSort, v.ID)
	end
	table.sort(self.m_wuxueTableSort)
	self.onWuXueShopButtonClick = function() self:OnWuXueShopButtonClick() end
	self.onRuleButtonClick = function() self:OnRuleButtonClick() end
	self.onWuXueIconClick = function() self:OnWuXueIconClick() end
	self.Controls.m_ButtonWuXueShop.onClick:AddListener(function() self:onWuXueShopButtonClick() end)
	self.Controls.m_ButtonRule.onClick:AddListener(function() self:onRuleButtonClick() end)
	self.Controls.m_ButtonWuXueIcon.onClick:AddListener(function() self:onWuXueIconClick() end)
	self.Group = self.Controls.m_wuxueListScroller:GetComponent(typeof(ToggleGroup))
	--绑定EnhanceScroller事件
	self.DragListView  = self.Controls.m_wuxueListScroller:GetComponent(typeof(EnhancedListView))
	self.callBackOnGetCellView = function(objCell) self:OnGetCellView(objCell) end
	self.enhanceListView = self.Controls.m_wuxueListScroller:GetComponent(typeof(EnhancedListView))
	self.callBackTargetTeamCellVis = function(objCell) self:OnGetWuxueItemVisiable(objCell) end
	self.enhanceScroller = self.Controls.m_wuxueListScroller:GetComponent(typeof(EnhancedScroller))
	if self.enhanceListView ~= nil then 
		self.enhanceListView.onGetCellView:AddListener(self.callBackOnGetCellView)
		self.enhanceListView.onCellViewVisiable:AddListener(self.callBackTargetTeamCellVis)
	end
	
	
	-- 绑定秘籍图标
	self:AttachMiJiItem()
	
end

--EnhancedListView 创建实体回调
function WuXueVerDragWidget:OnGetCellView(objCell)
	local item = WuXueBookItem:new()
	local enhancedCell = objCell:GetComponent(typeof(EnhancedListViewCell))
	enhancedCell.onRefreshCellView = handler(self, self.OnGetWuxueItemVisiable)
	item:SetGroup(self.Group)
	item:Attach(objCell)
end

--EnhancedListView 创建实体可见
function WuXueVerDragWidget:OnGetWuxueItemVisiable(objCell)
	local viewCell = objCell.transform:GetComponent(typeof(EnhancedListViewCell))
	local behav = objCell:GetComponent(typeof(UIWindowBehaviour))
	if nil ~= behav then
		local item = behav.LuaObject
		local schemeId =self.m_wuxueTableSort[viewCell.cellIndex+1]
		local scheme = IGame.rktScheme:GetSchemeInfo(BATTLEBOOK_ACTIVATION_CSV, schemeId)
		item:UpdateItem(scheme, self.m_CurSelectedWuXueId)
	end	
	
end



-- 窗口每次打开时被调用的行为
-- @wuXueId:当前选中的武学id:number
-- @miJiId:当前选中的秘籍id:number
function WuXueVerDragWidget:OnWidgetShow(wuXueId, miJiId)
	-- 更新窗口
	self:UpdateWidget(wuXueId, miJiId, false)
    self.enhanceScroller:JumpToDataIndex(0, 0, 0, true, EnhancedScroller.TweenType.immediate, 0.2, nil)
end

-- 更新窗口
-- @wuXueId:当前选中的武学id:number
-- @miJiId:当前选中的秘籍id:number
-- @needLocateWuXueItem:是否需要定位武学图标的标识:boolean
function WuXueVerDragWidget:UpdateWidget(wuXueId, miJiId, needLocateWuXueItem)
	
	self.m_CurSelectedWuXueId = wuXueId
	self.m_CurSelectedMiJiId = miJiId

	local wuXueScheme = IGame.rktScheme:GetSchemeInfo(BATTLEBOOK_ACTIVATION_CSV, wuXueId)
	if not wuXueScheme then
		return
	end
	
	local studyPart = GetHeroEntityPart(ENTITYPART_PERSON_STUDYSKILL)
	if not studyPart then
		return
	end
	
--	self.Controls.m_TfTipWuXueSelected.gameObject:SetActive(self.m_CurSelectedMiJiId < 1)
	self.Controls.m_TextFight.text = string.format("%d", studyPart:CalcAllWuXueFightValue())
	UIFunction.SetImageSprite(self.Controls.m_ImageWuXueIcon, AssetPath.TextureGUIPath..wuXueScheme.Icon)
	
	-- 更新武学图标的显示
	self:UpdateWuXueItemShow()
	-- 更新秘籍图标
	self:UpdateMiJiItem()
	
end

-- 更新武学图标的显示
function WuXueVerDragWidget:UpdateWuXueItemShow()

	local listAllWuXueScheme = IGame.rktScheme:GetSchemeTable(BATTLEBOOK_ACTIVATION_CSV)
	if not listAllWuXueScheme then
		return
	end
	
	local tableSort = {}
	for k,v in pairs(listAllWuXueScheme) do
		table.insert(tableSort, v.ID)
	end
	
	table.sort(tableSort)
	local count =-1
	count = self.DragListView.CellCount
	if #tableSort ~= count then 
		self.enhanceListView:SetCellCount( #tableSort , true )	
	else
		self.enhanceScroller:RefreshActiveCellViews()
	end

end

-- 更新秘籍图标
function WuXueVerDragWidget:UpdateMiJiItem()
	
	local wuXueScheme = IGame.rktScheme:GetSchemeInfo(BATTLEBOOK_ACTIVATION_CSV, self.m_CurSelectedWuXueId)
	if not wuXueScheme then
		uerror("没有找到对应的武学解锁表, id:%d", self.m_CurSelectedWuXueId)
		return
	end
	
	-- 计算数量判断坐标数组
	local itemCnt = 0
	for itemIdx = 1, 5 do
		local miJiId = wuXueScheme[string.format("Slot%dID", itemIdx)]
		local itemNeedShow = miJiId > 0
		
		if itemNeedShow then
			itemCnt = itemCnt + 1
		end
	end
	
	local posTable = ArrWuXueMiJiItemPos3
	if itemCnt == 4 then
		posTable = ArrWuXueMiJiItemPos4
	elseif itemCnt == 5 then
		posTable = ArrWuXueMiJiItemPos5
	end
	
	for itemIdx = 1, 5 do
		local miJiId = wuXueScheme[string.format("Slot%dID", itemIdx)]
		local itemNeedShow = miJiId > 0
		local item = self.m_ListMiJiItem[itemIdx]
		
		item.transform.gameObject:SetActive(itemNeedShow)
		if itemNeedShow then
			item:UpdateItem(self.m_CurSelectedWuXueId, miJiId, itemIdx, self.m_CurSelectedMiJiId)
			item.transform.localPosition = posTable[itemIdx]
		end
	end
	
end

-- 绑定秘籍图标
function WuXueVerDragWidget:AttachMiJiItem()
	
	for itemIdx = 1, 5 do
		local item = WuXueMiJiItem:new()
		item:Attach(self.Controls[string.format("m_TfWuXueMiJiItem%d", itemIdx)].gameObject)
		
		table.insert(self.m_ListMiJiItem, item)
	end
	
end

function WuXueVerDragWidget:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function WuXueVerDragWidget:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function WuXueVerDragWidget:CleanData()

	self.m_IsWuXueItemCreateSucc = false
	
end


-- 武学商店按钮的点击行为
function WuXueVerDragWidget:OnWuXueShopButtonClick()
	IGame.ChipExchangeClient:OpenChipExchangeShop(2)
end

-- 规则按钮的点击行为
function WuXueVerDragWidget:OnRuleButtonClick()
	
	UIManager.CommonGuideWindow:ShowWindow(24)
	
end

-- 武学图标的点击行为
function WuXueVerDragWidget:OnWuXueIconClick()
	
	rktEventEngine.FireExecute(ENTITYPART_CREATURE_SKILL, SOURCE_TYPE_SYSTEM, SKILL_UI_EVENT_WUXUE_BOOK_ITEM_CLICK, self.m_CurSelectedWuXueId)
	
end
return WuXueVerDragWidget