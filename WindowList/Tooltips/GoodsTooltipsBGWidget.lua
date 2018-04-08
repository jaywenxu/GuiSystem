------------------------------------------------------------
-- TooltisWindow 的子窗口,不要通过 UIManager 访问
------------------------------------------------------------
local BottomButtonsWidgetClass = require("GuiSystem.WindowList.Tooltips.TipsBottomButtonsWidget")
local GetWaysWidgetClass = require("GuiSystem.WindowList.Tooltips.GetWaysWidget")

local GoodsTooltipsBGWidget = UIControl:new
{
    windowName = "GoodsTooltipsBGWidget" ,
	m_nGoodID = nil,
	m_subInfo = nil,
	entity = nil,
	info = nil,
	AllWidgets ={},
}

local this = GoodsTooltipsBGWidget   -- 方便书写
local zero = int64.new("0")

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function GoodsTooltipsBGWidget:Attach(obj)
	UIControl.Attach(self, obj)
	self.AllWidgets = {}
	
	self.HeadWidget = UIControl:new{windowName = "HeadWidget"}
	self.HeadWidget:Attach(self.Controls.m_Head.gameObject)
	table.insert(self.AllWidgets, self.HeadWidget)

	self.ContentWidget = UIControl:new{windowName = "ContentWidget"}
	self.ContentWidget:Attach(self.Controls.m_Content.gameObject)
	table.insert(self.AllWidgets, self.ContentWidget)
	
	self.BottomButtonsWidget = require("GuiSystem.WindowList.Tooltips.TipsBottomButtonsWidget")
	self.BottomButtonsWidget:Attach(self.Controls.m_btnWid.gameObject)
	table.insert(self.AllWidgets, self.BottomButtonsWidget)
	
	self.GetWaysWidget = GetWaysWidgetClass:new()
	self.GetWaysWidget:Attach(self.Controls.m_getWayCell.gameObject)
	table.insert(self.AllWidgets, self.GetWaysWidget)
	
	self.m_originPosition = self.Controls.m_mainWindow.localPosition
	self.m_originBgPos    = self.Controls.m_bg.localPosition

	self.m_NeedButton      = true
	self.MoveType          = "other"
	self.otherTrs = nil
	return self
end

------------------------------------------------------------
function GoodsTooltipsBGWidget:OnDestroy()
	UIControl.OnDestroy(self)
end
------------------------------------------------------------

-- 设置物品
function GoodsTooltipsBGWidget:SetGoodsID(nGoodID,subInfo)
	self.m_nGoodID = nGoodID
	self.m_subInfo = subInfo
	self.entity = UIManager.GoodsTooltipsWindow:GetEntity()
	self:SetHeadInfo() -- 窗口头
	self:SetContentInfo() -- 内容属性
	self:SetBottomButtonsInfo() -- 底部按钮
	self:SetGetWaysInfo() -- 获取途径
	if self.m_subInfo == nil then 
		self.transform.localPosition =Vector3.New(0,0,0)
		return
	end
	self.transform.localPosition =Vector3.New(5000,5000,0)
	self:RefreshPos()
--[[	self.RefreshFun = function() self:RefreshPos() end
	rktTimer.SetTimer(self.RefreshFun,30,1)--]]
end

function GoodsTooltipsBGWidget:RefreshPos()
	if self.m_subInfo.ScrTrans then -- 如果传子预设
        rktTimer.SetTimer(function()UIFunction.ToolTipsShowPivotCent(true,self.transform,self.m_subInfo.ScrTrans,Vector2.New(0,0)) end,30,1,"")
		
	elseif self.m_subInfo.Pos then
		self.transform.anchoredPosition = self.m_subInfo.Pos
		self.transform.gameObject:SetActive(true)
	else
		self.transform.anchoredPosition = Vector3.New(-249,0,0)
		self.transform.gameObject:SetActive(true)
	end
end

-- 设置物品
function GoodsTooltipsBGWidget:SetGoods(entity)
	self.entity = entity
	local goodsID = entity:GetNumProp(GOODS_PROP_GOODSID)
	local entityClass = entity:GetEntityClass()
	if EntityClass:IsEquipment(entityClass) then
		self.info = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, goodsID)
	elseif EntityClass:IsLeechdom(entityClass) then
		self.info = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodsID)
	end
	
	if not self.info then
		print("GoodsTooltipsBGWidget:SetGoods, can not find scheme info")
		return
	end
	
	self:SetHeadInfo() -- 窗口头
	self:SetContentInfo() -- 内容属性
end



-- 窗口头
function GoodsTooltipsBGWidget:SetHeadInfo()
	local widget = self.HeadWidget
	
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, self.m_nGoodID)
	if not schemeInfo then
		return
	end
	local level = GetHero():GetNumProp(CREATURE_PROP_LEVEL)
	local szLevelUse = ""
	if schemeInfo.lAllowLevel ~= 0 then
		if level >= schemeInfo.lAllowLevel then
			szLevelUse = "<color=white>"..schemeInfo.lAllowLevel.."级</color>"
		else
			szLevelUse = "<color=red>"..schemeInfo.lAllowLevel.."级</color>"
		end
	end
	
	local ImagePath = AssetPath.TextureGUIPath .. schemeInfo.lIconID1
	UIFunction.SetImageSprite(widget.Controls.m_Icon, ImagePath)
	
	local imageBgPath = AssetPath.TextureGUIPath .. schemeInfo.lIconID2
	UIFunction.SetImageSprite(widget.Controls.m_IconBg, imageBgPath)
	local color = getGoodsEntityViewNameColor(schemeInfo.lBaseLevel)
	UIFunction.SetImageSprite(widget.Controls.m_headBg, AssetPath_GoodsTipsHeadBg[schemeInfo.lBaseLevel])
	-- 物品名称
	widget.Controls.m_GoodsName.text = "<color=#".. color .. ">" .. schemeInfo.szName .. "</color>" or ""
	
	if schemeInfo.nShowType == 0 then
		widget.Controls.m_NormalDescBG.gameObject:SetActive(true)
		widget.Controls.m_GoodNum.gameObject:SetActive(false)
		-- 道具类型
		widget.Controls.m_GoodsDesc1.text = schemeInfo.subDesc1
		widget.Controls.m_GoodsDesc2.text = schemeInfo.subDesc2
	else
		widget.Controls.m_NormalDescBG.gameObject:SetActive(false)
		widget.Controls.m_GoodNum.gameObject:SetActive(true)
		widget.Controls.m_GoodNum.text = "拥有 <color=#0CFB04>"..GameHelp:GetHeroGoodsNum(self.m_nGoodID).."</color> 个   "..szLevelUse
	end
end

-- 内容
function GoodsTooltipsBGWidget:SetContentInfo()
	local widget = self.ContentWidget
	widget.transform.gameObject:SetActive(true)
	
	local entity = self.entity
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, self.m_nGoodID)
	if not schemeInfo then
		return
	end
	local nCanSell = schemeInfo.lCanSell
	local szShowString = ""
	-- 添加物品描述
	szShowString = schemeInfo.szDesc
	
	local baitanString =""
	-- 添加物品摆摊信息
	if nCanSell == 1 and entity then
		local noBindNum = entity:GetNumProp(GOODS_PROP_NO_BIND_QTY)
		baitanString = "<color='#0CFB04'>可摆摊数量:" .. noBindNum.."</color>"
	end
	
	-- 添加物品限制个数
	local nDayUseCount		= schemeInfo.nDayUseCount
	local nTotalUseCount	= schemeInfo.nTotalUseCount
	local tGoodsUseCountData = IGame.GoodsUseCountManager:GetGoodsUseCountData(self.m_nGoodID)
	local nDayLeftCnt = 0
	local nTotalLeftCnt = 0
	
	local szLimitShowString = ""
	if nTotalUseCount and nTotalUseCount ~= 0 then
		if nTotalUseCount < tGoodsUseCountData.totalCnt then
			local retstr = string.format("使用个数比限制个数大：使用了 %d,限制使用个数  %d！", tGoodsUseCountData.totalCnt,nTotalUseCount)
			uerror(retstr)
		else
			nTotalLeftCnt = nTotalUseCount - tGoodsUseCountData.totalCnt
			szLimitShowString = string.format("还可使用<color='#0CFB04'>%d</color>次", nTotalLeftCnt)
		end
	end
	
	if nDayUseCount and nDayUseCount ~= 0 then
		if nDayUseCount < tGoodsUseCountData.dayCnt then
			local retstr = string.format("使用个数比限制个数大：使用了 %d,天限制使用个数  %d！", tGoodsUseCountData.dayCnt,nDayUseCount)
			uerror(retstr)
		else
			local nDayLeftCnt = nDayUseCount - tGoodsUseCountData.dayCnt
			if nTotalUseCount and nTotalUseCount ~= 0 then
				nDayLeftCnt =  math.min(nDayLeftCnt,nTotalLeftCnt)
			end
			
			local szTring = string.format("今日还可使用<color='#0CFB04'>%d</color>次", nDayLeftCnt)
			if szLimitShowString ~= "" then
				szLimitShowString = szTring .. "\n" .. szLimitShowString
			else
				szLimitShowString = szTring
			end
		end
	end

	szShowString = string.gsub(szShowString, "\\n", "\n") 
	widget.Controls.m_ContentText.text = szShowString
	if IsNilOrEmpty(baitanString) and IsNilOrEmpty(szLimitShowString) then 
		self.Controls.m_useWdt.gameObject:SetActive(false)
		self.Controls.m_UseInfoText.gameObject:SetActive(false)
	else
		self.Controls.m_useWdt.gameObject:SetActive(true)
		self.Controls.m_UseInfoText.gameObject:SetActive(true)
		if szLimitShowString =="" then 
			self.Controls.m_UseInfoText.text =baitanString
		else
			if IsNilOrEmpty(baitanString) then 
				self.Controls.m_UseInfoText.text = szLimitShowString
			else
				self.Controls.m_UseInfoText.text = baitanString	.. "\n\n" .. szLimitShowString
			end
			
		end
	
	end

end

-- 按钮
function GoodsTooltipsBGWidget:SetBottomButtonsInfo()
	local widget = self.BottomButtonsWidget
	local entity = self.entity
	local subInfo = self.m_subInfo
	if subInfo.bShowBtnType ~= 1 then
		widget:Hide()
		return
	else
		widget:Show()
	end
	widget:Refresh(self.m_nGoodID,subInfo.bBottomBtnType)
end


function GoodsTooltipsBGWidget:SetGetWaysInfo() -- 获取途径
	local widget = self.GetWaysWidget
	local subInfo = self.m_subInfo
	if self.m_nGoodID == nil then 
		return
	end
	local info = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, self.m_nGoodID)
	if info == nil then 
		return
	end
	local wayID = info.itemFetchID
	local nWayCellCount = table_count(wayID)
	if subInfo.bShowBtnType ~= 2 or nWayCellCount == 0 then
		widget:Hide()
		self.Controls.m_getWayLine.gameObject:SetActive(false)
		self.Controls.m_getWayTitle.gameObject:SetActive(false)
		return
	else
		widget:Show()
		self.Controls.m_getWayLine.gameObject:SetActive(true)
		self.Controls.m_getWayTitle.gameObject:SetActive(true)
	end
	widget:ShowGoodsInfo(self.m_nGoodID)
end

--===========================================================================

function GoodsTooltipsBGWidget:ShowGoodsTooltips(goodsId, subInfo)

	local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodsId)
	if not schemeInfo then
		return
	end
	local HeadWidget = self.HeadWidget
	local ImagePath = AssetPath.TextureGUIPath .. schemeInfo.lIconID1
	UIFunction.SetImageSprite(HeadWidget.Controls.m_Icon, ImagePath)
	
	local imageBgPath = AssetPath.TextureGUIPath .. schemeInfo.lIconID2
	UIFunction.SetImageSprite(HeadWidget.Controls.m_IconBg, imageBgPath)
			
	-- 物品名称
	if schemeInfo.lBaseLevel == 1 then 
		HeadWidget.Controls.m_GoodsName.text = "<color=".. "#f6e5c7" .. ">" .. schemeInfo.szName .. "</color>" or ""
	elseif schemeInfo.lBaseLevel == 2 then 
		HeadWidget.Controls.m_GoodsName.text = "<color=".. "#078301" .. ">" .. schemeInfo.szName .. "</color>" or ""
	elseif schemeInfo.lBaseLevel == 3 then
	    HeadWidget.Controls.m_GoodsName.text = "<color=".. "#0052c5" .. ">" .. schemeInfo.szName .. "</color>" or ""
	elseif schemeInfo.lBaseLevel == 4 then
	    HeadWidget.Controls.m_GoodsName.text = "<color=".. "#b708bd" .. ">" .. schemeInfo.szName .. "</color>" or ""
	else
		HeadWidget.Controls.m_GoodsName.text = "<color=".. "#e80505" .. ">" .. schemeInfo.szName .. "</color>" or ""
	end
	
	-- 道具类型
	HeadWidget.Controls.m_GoodsDesc1.text = schemeInfo.subDesc1 
	HeadWidget.Controls.m_GoodsDesc2.text = schemeInfo.subDesc2 
	
	local ContentWidget = self.ContentWidget
	--ContentWidget.transform.gameObject:SetActive(true)
	ContentWidget.Controls.m_ContentText.text = schemeInfo.szDesc
	
	--local BasicWidget = self.BasicWidget
	--BasicWidget.transform.gameObject:SetActive(false)
	if not bNeedButton then
		self.LineWidget.transform.gameObject:SetActive(false)
	end
	    
	self.m_NeedButton      = subInfo[3] 
	self.MoveType          = subInfo[1]  
	self.otherTrs  			=subInfo[2] 

	
end


return this