--/******************************************************************
--** 文件名:	UpgradeWuXueDisplayWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-05
--** 版  本:	1.0
--** 描  述:	玩家技能窗口-武学展示窗口
--** 应  用:  
--******************************************************************/

local UpgradeWuXueItem = require("GuiSystem.WindowList.PlayerSkill.UpgradeWuXueItem")

local UpgradeWuXueDisplayWidget = UIControl:new
{
	windowName 	= "UpgradeWuXueDisplayWidget",
	
	m_NeedLocateWuXueItem = false,		-- 是否需要定位武学图标的标识
	
	m_TotalWuXueSchemeCnt = 0,			-- 武学配置数量:number
	m_HadCreateWuXueItemCnt = 0,		-- 已经创建的武学图标数量:number
	
	m_ScroUpgradeWuXueItem = nil,		-- 武学图标滚动视图:ScrollRect
	m_ScroEventTrigger = nil,			-- 武学图标滚动视图的事件触发器:EventTrigger
	m_ListUpgradeWuXueItem = {},		-- 境界图标脚本列表:table(UpgradeWuXueItem)
}

local ONE_VIEW_MAX_WU_XUE_ITEM_CNT = 5	-- 视图最大的武学图标显示数量

function UpgradeWuXueDisplayWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	
	self.m_ScroUpgradeWuXueItem = self.Controls.m_TfScroUpgradeWuXueItem.gameObject:GetComponent("ScrollRect")
	self.m_ScroEventTrigger = self.Controls.m_TfScroUpgradeWuXueItem.gameObject:GetComponent("EventTrigger")
	
	self.onScroDrag = function(eventData) self:OnScroDrag(eventData) end
	self.onScroDragEnd = function(eventData) self:OnScroDragEnd(eventData) end
	UIFunction.AddEventTriggerListener(self.Controls.m_TfScroUpgradeWuXueItem.gameObject, EventTriggerType.Drag, self.onScroDrag)
	UIFunction.AddEventTriggerListener(self.Controls.m_TfScroUpgradeWuXueItem.gameObject, EventTriggerType.EndDrag, self.onScroDragEnd)
	
end

-- 显示窗口
function UpgradeWuXueDisplayWidget:ShowWidget()
	
	self.m_ScroUpgradeWuXueItem.horizontalNormalizedPosition = 0
	
	self.Controls.m_TfLeftArrow.gameObject:SetActive(false)
	self.Controls.m_TfRightArrow.gameObject:SetActive(false)
	
	-- 更新窗口的显示
	self:UpdateWindowShow()
	
end

-- 更新窗口的显示
function UpgradeWuXueDisplayWidget:UpdateWindowShow()
	
	local hero = GetHero()
	if not hero then
		return
	end

	local studyPart = hero:GetEntityPart(ENTITYPART_PERSON_STUDYSKILL)
	if not studyPart then
		return
	end

	self.Controls.m_TextWuXuePoint.text = string.format("修为: %d", studyPart:GetXiuWei())
	
	if self.m_TotalWuXueSchemeCnt < 1 then
		-- 创建武学图标
		self:CreateWuXueItem()
	else 
		-- 更新境界图标的显示
		self:UpdateWuXueItem()
	end
	
	-- 更新箭头的显示
	self:UpdateArrowShow()
	
end

-- 创建武学图标
function UpgradeWuXueDisplayWidget:CreateWuXueItem()
	
	if self.m_TotalWuXueSchemeCnt > 0 then
		return
	end
	
	local listAllWuXueScheme = IGame.rktScheme:GetSchemeTable(BATTLEBOOK_ACTIVATION_CSV)
	if listAllWuXueScheme == nil then
		return
	end
	
	self.m_TotalWuXueSchemeCnt = 0
	self.m_HadCreateWuXueItemCnt = 0
	
	for k,v in pairs(listAllWuXueScheme) do
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.PlayerSkill.UpgradeWuXueItem ,
        function ( path , obj , ud )
			
			self.m_HadCreateWuXueItemCnt = self.m_HadCreateWuXueItemCnt + 1
			
            obj.transform:SetParent(self.Controls.m_TfLayoutUpgradeWuXueItem.transform, false)
			obj.transform.localScale = Vector3.one
			
			local item = UpgradeWuXueItem:new()
			item:Attach(obj)
			table.insert(self.m_ListUpgradeWuXueItem, item)

			-- 所有图标创建完了
			if self.m_HadCreateWuXueItemCnt == self.m_TotalWuXueSchemeCnt then
				self.Controls.m_TfLeftArrow.gameObject:SetActive(false)
				self.Controls.m_TfRightArrow.gameObject:SetActive(self.m_TotalWuXueSchemeCnt > ONE_VIEW_MAX_WU_XUE_ITEM_CNT)
				
				-- 更新境界图标的显示
				self:UpdateWuXueItem()
			end
			
        end , "", AssetLoadPriority.GuiNormal)
		
		self.m_TotalWuXueSchemeCnt = self.m_TotalWuXueSchemeCnt + 1
	end
	
end

-- 更新武学图标的显示
function UpgradeWuXueDisplayWidget:UpdateWuXueItem()
	
	local listWuXueScheme = IGame.rktScheme:GetSchemeTable(BATTLEBOOK_ACTIVATION_CSV)
	if not listWuXueScheme then
		return
	end
	
	local studyPart = GetHeroEntityPart(ENTITYPART_PERSON_STUDYSKILL)
	if not studyPart then
		return
	end

	local sortTable = {}
	for k,v in pairs(listWuXueScheme) do
		table.insert(sortTable, v.ID)
	end

	table.sort(sortTable)
	for itemIdx = 1, #sortTable do
		local item = self.m_ListUpgradeWuXueItem[itemIdx]
		local id = sortTable[itemIdx]
		local scheme = IGame.rktScheme:GetSchemeInfo(BATTLEBOOK_ACTIVATION_CSV, id)
		
		item:UpdateItem(scheme)
	end
	
end

-- 更新箭头的显示
function UpgradeWuXueDisplayWidget:UpdateArrowShow()
	
	if self.m_TotalWuXueSchemeCnt <= ONE_VIEW_MAX_WU_XUE_ITEM_CNT then
		self.Controls.m_TfLeftArrow.gameObject:SetActive(false)
		self.Controls.m_TfRightArrow.gameObject:SetActive(false)
		return
	end		
	
	local leftHaveItem = self.m_ScroUpgradeWuXueItem.horizontalNormalizedPosition > 0.02
	local rightHaveItem = self.m_ScroUpgradeWuXueItem.horizontalNormalizedPosition < 0.98
	
	self.Controls.m_TfLeftArrow.gameObject:SetActive(leftHaveItem)
	self.Controls.m_TfRightArrow.gameObject:SetActive(rightHaveItem)
	
end

-- 定位武学图标位置
function UpgradeWuXueDisplayWidget:LocateWuXueItem()
	
	if self.m_TotalWuXueSchemeCnt <= ONE_VIEW_MAX_WU_XUE_ITEM_CNT then
		return
	end

	local scroNorPos = self.m_ScroUpgradeWuXueItem.horizontalNormalizedPosition
	if scroNorPos < 0 then
		scroNorPos = 0
	elseif scroNorPos > 1 then
		scroNorPos = 1
	end
	
	local localFactor = 1 / (self.m_TotalWuXueSchemeCnt - ONE_VIEW_MAX_WU_XUE_ITEM_CNT)
	local localIdx = scroNorPos / localFactor
	if localIdx % 1 > 0.5 then
		localIdx = math.floor(localIdx) + 1
	else 
		localIdx = math.floor(localIdx)
	end
	
	self.m_ScroUpgradeWuXueItem.horizontalNormalizedPosition = localIdx * localFactor
	
end

-- 滚动视图在拖动的时候执行的行为
function UpgradeWuXueDisplayWidget:OnScroDrag(eventData)
	
	-- 更新箭头的显示
	self:UpdateArrowShow()
	
end

-- 滚动视图在拖动结束的时候执行的行为
function UpgradeWuXueDisplayWidget:OnScroDragEnd(eventData)
	
	-- 定位武学图标位置
	self:LocateWuXueItem()
	-- 更新箭头的显示
	self:UpdateArrowShow()
	
end

return UpgradeWuXueDisplayWidget