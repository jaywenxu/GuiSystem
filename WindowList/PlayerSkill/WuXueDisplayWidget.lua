--/******************************************************************
---** 文件名:	WuXueDisplayWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-06
--** 版  本:	1.0
--** 描  述:	玩家技能窗口-武学窗口-展示窗口
--** 应  用:  
--******************************************************************/

local WuXueMiJiItem = require("GuiSystem.WindowList.PlayerSkill.WuXueMiJiItem")
local WuXueBookItem = require("GuiSystem.WindowList.PlayerSkill.WuXueBookItem")

local WuXueDisplayWidget = UIControl:new
{
	windowName = "WuXueDisplayWidget",
	
	m_IsWuXueItemCreateSucc = false,	-- 所有武学图标创建成功的标识:boolean
	m_TotalWuXueCnt = 0,				-- 总武学数量:number
	m_CurSelectedWuXueId = 0,			-- 当前选中的武学id:number
	m_CurSelectedMiJiId = 0,			-- 当前选中的秘籍id:number
	
	m_WuXueItemRotDotween = nil,		-- 武学图标旋转的dotween组件:DOTweenAnimation
	
	m_ListWuXueItem = {},				-- 武学图标实例脚本列表:table(WuXueBookItem)
	m_ListMiJiItem = {},				-- 秘籍图标实例脚本列表:table(WuXueMiJiItem)
}

-- 显示3个秘籍图标时的图标位置
local ArrWuXueMiJiItemPos3 = 
{
	Vector3.New(-551.5, 99, 0),
	Vector3.New(-126, 79.8, 0),
	Vector3.New(-508.1, -296.2, 0),
}

-- 显示4个秘籍图标时的图标位置
local ArrWuXueMiJiItemPos4 = 
{
	Vector3.New(-526.5, 112.4, 0),
	Vector3.New(-160.3, 125.9, 0),
	Vector3.New(-158.2, -216.6, 0),
	Vector3.New(-553.9, -279.7, 0),
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

-- 武学图标图标的显示位置
-- 这个是在父亲节点转动0度的时候的坐标
local ArrWuXueItemPos = 
{
	Vector3.New(-178.8852, 388.7483, 0),
	Vector3.New(-340.4528, 259.2627, 0),
	Vector3.New(-422.3185, 69.0826, 0),
	Vector3.New(-405.3176, -137.2702, 0),
	Vector3.New(-293.4297, -311.4872, 0),
	Vector3.New(-112.8488, -412.7839, 0),
	Vector3.New(94.15057, -417.4458, 0),
	Vector3.New(279.1088, -324.3817, 0),
	Vector3.New(398.7263, -155.3783, 0),
	Vector3.New(424.9999, 49.99995, 0),
	Vector3.New(351.7795, 243.6727, 0),
	
}

local ONE_VIEW_MAX_WUXUE_ITEM_SHOW_CNT = 5		-- 一次最大展示的武学图标数量:number
local ONE_WUXUE_ITEM_ANGLE_SIZE = -28			-- 每个武学图标的角度大小:number

function WuXueDisplayWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	
	self.onWuXueShopButtonClick = function() self:OnWuXueShopButtonClick() end
	self.onRuleButtonClick = function() self:OnRuleButtonClick() end
	self.onWuXueIconClick = function() self:OnWuXueIconClick() end
	self.Controls.m_ButtonWuXueShop.onClick:AddListener(function() self:onWuXueShopButtonClick() end)
	self.Controls.m_ButtonRule.onClick:AddListener(function() self:onRuleButtonClick() end)
	self.Controls.m_ButtonWuXueIcon.onClick:AddListener(function() self:onWuXueIconClick() end)
	
	self.onDragWuXueItemStart = function(eventData) self:OnDragWuXueItemStart(eventData) end
	self.onDragWuXueItem = function(eventData) self:OnDragWuXueItem(eventData) end
	self.onDragWuXueItemEnd = function(eventData) self:OnDragWuXueItemEnd(eventData) end
	
	UIFunction.AddEventTriggerListener(self.Controls.m_TfDragWuXueBookItem.gameObject, EventTriggerType.BeginDrag, self.onDragWuXueItemStart)
	UIFunction.AddEventTriggerListener(self.Controls.m_TfDragWuXueBookItem.gameObject, EventTriggerType.Drag, self.onDragWuXueItem)
	UIFunction.AddEventTriggerListener(self.Controls.m_TfDragWuXueBookItem.gameObject, EventTriggerType.EndDrag, self.onDragWuXueItemEnd)
	
	self.onWuXueTweenAniStart = function() self:OnWuXueItemTweenStart() end
	self.onWuXueTweenAniUpdate = function() self:UpdateWuXueItemRot() end
	self.onWuXueTweenAniEnd =  function() self:OnWuXueItemTweenEnd() end
	self.m_WuXueItemRotDotween = self.Controls.m_TfWuXueItemNode:GetComponent(typeof(DOTweenAnimation))
	self.m_WuXueItemRotDotween.onPlay = UnityEngine.Events.UnityEvent.New()
	self.m_WuXueItemRotDotween.onUpdate = UnityEngine.Events.UnityEvent.New()
	self.m_WuXueItemRotDotween.onComplete = UnityEngine.Events.UnityEvent.New()
	self.m_WuXueItemRotDotween.hasOnPlay = true
	self.m_WuXueItemRotDotween.hasOnUpdate = true
	self.m_WuXueItemRotDotween.hasOnComplete = true
	self.m_WuXueItemRotDotween.onPlay:AddListener(self.onWuXueTweenAniStart)
	self.m_WuXueItemRotDotween.onUpdate:AddListener(self.onWuXueTweenAniUpdate)
	self.m_WuXueItemRotDotween.onComplete:AddListener(self.onWuXueTweenAniEnd)
	self.m_WuXueItemRotDotween:CreateTween()
	
	-- 绑定秘籍图标
	self:AttachMiJiItem()
	
end


-- 窗口每次打开时被调用的行为
-- @wuXueId:当前选中的武学id:number
-- @miJiId:当前选中的秘籍id:number
function WuXueDisplayWidget:OnWidgetShow(wuXueId, miJiId)

	self.m_WuXueItemRotDotween:DORestart(true)
	
	-- 更新窗口
	self:UpdateWidget(wuXueId, miJiId, false)

end

-- 更新窗口
-- @wuXueId:当前选中的武学id:number
-- @miJiId:当前选中的秘籍id:number
-- @needLocateWuXueItem:是否需要定位武学图标的标识:boolean
function WuXueDisplayWidget:UpdateWidget(wuXueId, miJiId, needLocateWuXueItem)
	
	self.m_CurSelectedWuXueId = wuXueId
	self.m_CurSelectedMiJiId = miJiId
	--策划哥哥说不要旋转所以注释掉
	if needLocateWuXueItem then
		self.m_WuXueItemRotDotween:DOPause()
		
		-- 定位武学图标
		self:LocateWuXueItem()
	end
	
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

-- 创建武学图标
function WuXueDisplayWidget:CreateWuXueItem()
	
	local listAllWuXueScheme = IGame.rktScheme:GetSchemeTable(BATTLEBOOK_ACTIVATION_CSV)
	if not listAllWuXueScheme then
		uerror("没有找到武学解锁配置表!")
		return
	end
	
	self.m_TotalWuXueCnt = 0
	for k,v in pairs(listAllWuXueScheme) do
		self.m_TotalWuXueCnt = self.m_TotalWuXueCnt + 1
	end
	
	for k,v in pairs(listAllWuXueScheme) do
		
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.PlayerSkill.WuXueBookItem,
        function ( path , obj , ud )
			
			
			obj.transform:SetParent(self.Controls.m_TfWuXueItemNode.transform)
			obj.transform.localScale = Vector3.one
			
			local item = WuXueBookItem:new()
			item:Attach(obj)
			
			table.insert(self.m_ListWuXueItem, item)
		
			-- 创建完最后一个，更新界面
			if #self.m_ListWuXueItem == self.m_TotalWuXueCnt then
				self.m_IsWuXueItemCreateSucc = true
				-- 初始化武学图标的位置
				self:InitWuXueItemPos()
				-- 绑定武学图标的拖动事件
				self:BindWuXueItemDragEvent()
				-- 更新武学图标的显示
				self:UpdateWuXueItemShow()
			end
		
		end , "", AssetLoadPriority.GuiNormal)
	end
	
end

-- 初始化武学图标的位置
function WuXueDisplayWidget:InitWuXueItemPos()
	
	for itemIdx = 1, #self.m_ListWuXueItem do
		local item = self.m_ListWuXueItem[itemIdx]
		local pos = ArrWuXueItemPos[itemIdx]
		
		item.transform.localPosition = pos
	end
	
end

-- 绑定武学图标的拖动事件
function WuXueDisplayWidget:BindWuXueItemDragEvent()
	
	for itemIdx = 1, #self.m_ListWuXueItem do
		local item = self.m_ListWuXueItem[itemIdx]
		
		UIFunction.AddEventTriggerListener(item.transform.gameObject, EventTriggerType.BeginDrag, self.onDragWuXueItemStart)
		UIFunction.AddEventTriggerListener(item.transform.gameObject, EventTriggerType.Drag, self.onDragWuXueItem)
		UIFunction.AddEventTriggerListener(item.transform.gameObject, EventTriggerType.EndDrag, self.onDragWuXueItemEnd)
	end
	
end

-- 更新武学图标的显示
function WuXueDisplayWidget:UpdateWuXueItemShow()
	
	-- 第一次打开界面，未创建图标
	if self.m_TotalWuXueCnt < 1 then
		-- 创建武学图标
		self:CreateWuXueItem()
		return
	end
	
	-- 图标在创建中
	if not self.m_IsWuXueItemCreateSucc then
		return
	end
	
	local listAllWuXueScheme = IGame.rktScheme:GetSchemeTable(BATTLEBOOK_ACTIVATION_CSV)
	if not listAllWuXueScheme then
		return
	end
	
	local tableSort = {}
	for k,v in pairs(listAllWuXueScheme) do
		table.insert(tableSort, v.ID)
	end
	
	table.sort(tableSort)
	
	for itemIdx = 1, #tableSort do
		local item = self.m_ListWuXueItem[itemIdx]
		local schemeId = tableSort[itemIdx]
		local scheme = IGame.rktScheme:GetSchemeInfo(BATTLEBOOK_ACTIVATION_CSV, schemeId)
		item:UpdateItem(scheme, self.m_CurSelectedWuXueId)
	end
	
end

-- 绑定秘籍图标
function WuXueDisplayWidget:AttachMiJiItem()
	
	for itemIdx = 1, 5 do
		local item = WuXueMiJiItem:new()
		item:Attach(self.Controls[string.format("m_TfWuXueMiJiItem%d", itemIdx)].gameObject)
		
		table.insert(self.m_ListMiJiItem, item)
	end
	
end

-- 更新秘籍图标
function WuXueDisplayWidget:UpdateMiJiItem()
	
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

-- 武学图标tween动画开始时的回调
function WuXueDisplayWidget:OnWuXueItemTweenStart()
	
	-- 更新武学图标的角度
	self:UpdateWuXueItemRot()
	-- 设置视图外的武学图标的显示
	self:SetOutViewWuXueItemShow(1, 100)
	
end

-- 更新武学图标的角度
function WuXueDisplayWidget:UpdateWuXueItemRot()
	
	for itemIdx = 1, #self.m_ListWuXueItem do
		local item = self.m_ListWuXueItem[itemIdx]
		item.transform.rotation = Quaternion.identity
	end
	
end

-- 武学图标tween动画结束时的回调
function WuXueDisplayWidget:OnWuXueItemTweenEnd()
	
	-- 更新武学图标的角度
	self:UpdateWuXueItemRot()
	-- 设置视图外的武学图标的显示
	self:SetOutViewWuXueItemShow(1, 5)
	
end

-- 设置视图外的武学图标的显示
-- @startIdx:要显示的图标的起始索引
-- @endIdx:要隐藏的图标的起始索引
function WuXueDisplayWidget:SetOutViewWuXueItemShow(startIdx, endIdx)
	
	for itemIdx = 1, #self.m_ListWuXueItem do
		local item = self.m_ListWuXueItem[itemIdx]
		local itemNeedShow = itemIdx >= startIdx and itemIdx <= endIdx
		
		item.transform.gameObject:SetActive(itemNeedShow)
	end
	
end

-- 拖动武学图标
-- @eventData:拖动事件数据:PointerEventData 
function WuXueDisplayWidget:OnDragWuXueItemStart(eventData)

	-- 更新武学图标的角度
	self:UpdateWuXueItemRot()
	-- 设置视图外的武学图标的显示
	self:SetOutViewWuXueItemShow(1, 100)
	
end

-- 拖动武学图标
-- @eventData:拖动事件数据:PointerEventData 
function WuXueDisplayWidget:OnDragWuXueItem(eventData)

	local oriRot = self.Controls.m_TfWuXueItemNode.transform.localRotation.eulerAngles
	local moveFactor = 0.085
	
	oriRot.z = oriRot.z - eventData.delta.y * moveFactor
	self.Controls.m_TfWuXueItemNode.transform.localRotation = Quaternion.Euler(oriRot.x, oriRot.y, oriRot.z)
	
	-- 更新武学图标的角度
	self:UpdateWuXueItemRot()
	
end

-- 拖动武学图标
-- @eventData:拖动事件数据:PointerEventData 
function WuXueDisplayWidget:OnDragWuXueItemEnd(eventData)

	-- 这里要计算只显示视图内的图标
	local oriRot = self.Controls.m_TfWuXueItemNode.transform.localRotation.eulerAngles
	local minAngleZ = ONE_WUXUE_ITEM_ANGLE_SIZE * (#self.m_ListWuXueItem - ONE_VIEW_MAX_WUXUE_ITEM_SHOW_CNT)
	local maxAngleZ = 0
	local itemFactor = 0
	
	local norAngle = oriRot.z % 360 
	if oriRot.z > 90 then
		norAngle = (oriRot.z / 360 - 1) * 360 
	end
	
	if norAngle < minAngleZ then
		itemFactor = #self.m_ListWuXueItem - ONE_VIEW_MAX_WUXUE_ITEM_SHOW_CNT
	elseif norAngle > 0 then
		itemFactor = 0
	else 
		itemFactor = norAngle / ONE_WUXUE_ITEM_ANGLE_SIZE
		if itemFactor % 1 > 0.5 then
			itemFactor = math.floor(itemFactor) + 1
		else 
			itemFactor = math.floor(itemFactor)
		end
	end
	
	local stopAngle = itemFactor * ONE_WUXUE_ITEM_ANGLE_SIZE
	
	oriRot.z = stopAngle
	self.Controls.m_TfWuXueItemNode.transform.localRotation = Quaternion.Euler(oriRot.x, oriRot.y, oriRot.z)
	
	-- 更新武学图标的角度
	self:UpdateWuXueItemRot()
		-- 设置视图外的武学图标的显示
	self:SetOutViewWuXueItemShow(itemFactor + 1, itemFactor + ONE_VIEW_MAX_WUXUE_ITEM_SHOW_CNT )
	
end

-- 定位武学图标
function WuXueDisplayWidget:LocateWuXueItem()
	
	local listAllWuXueScheme = IGame.rktScheme:GetSchemeTable(BATTLEBOOK_ACTIVATION_CSV)
	if not listAllWuXueScheme then
		return
	end
	
	local tableSort = {}
	for k,v in pairs(listAllWuXueScheme) do
		table.insert(tableSort, v.ID)
	end
	
	table.sort(tableSort)
	
	local stopItemIdx = 1
	for itemIdx = 1, #tableSort do
		local wuXueId = tableSort[itemIdx]
		if wuXueId == self.m_CurSelectedWuXueId then
			stopItemIdx = itemIdx
			break
		end
	end
	
	if stopItemIdx > 3 then
		stopItemIdx = stopItemIdx - 2
	else 
		stopItemIdx = 1
	end 
	
	local oriRot = self.Controls.m_TfWuXueItemNode.transform.localRotation.eulerAngles
	local stopAngle = (stopItemIdx - 1) * ONE_WUXUE_ITEM_ANGLE_SIZE
	
	oriRot.z = stopAngle
	self.Controls.m_TfWuXueItemNode.transform.localRotation = Quaternion.Euler(oriRot.x, oriRot.y, oriRot.z)
	
	-- 更新武学图标的角度
	self:UpdateWuXueItemRot()
		-- 设置视图外的武学图标的显示
	self:SetOutViewWuXueItemShow(stopItemIdx, stopItemIdx + ONE_VIEW_MAX_WUXUE_ITEM_SHOW_CNT - 1 )
	
end

function WuXueDisplayWidget:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function WuXueDisplayWidget:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function WuXueDisplayWidget:CleanData()

	self.m_WuXueItemRotDotween.onPlay:RemoveListener(self.onWuXueTweenAniStart)
	self.m_WuXueItemRotDotween.onUpdate:RemoveListener(self.onWuXueTweenAniUpdate)
	self.m_WuXueItemRotDotween.onComplete:RemoveListener(self.onWuXueTweenAniEnd)
	self.onWuXueTweenAniStart = nil
	self.onWuXueTweenAniUpdate = nil
	self.onWuXueTweenAniEnd = nil
	self.m_IsWuXueItemCreateSucc = false
	
end

-- 武学商店按钮的点击行为
function WuXueDisplayWidget:OnWuXueShopButtonClick()
	IGame.ChipExchangeClient:OpenChipExchangeShop(2)
end

-- 规则按钮的点击行为
function WuXueDisplayWidget:OnRuleButtonClick()
	
	UIManager.CommonGuideWindow:ShowWindow(24)
	
end

-- 武学图标的点击行为
function WuXueDisplayWidget:OnWuXueIconClick()
	
	rktEventEngine.FireExecute(ENTITYPART_CREATURE_SKILL, SOURCE_TYPE_SYSTEM, SKILL_UI_EVENT_WUXUE_BOOK_ITEM_CLICK, self.m_CurSelectedWuXueId)
	
end

return WuXueDisplayWidget