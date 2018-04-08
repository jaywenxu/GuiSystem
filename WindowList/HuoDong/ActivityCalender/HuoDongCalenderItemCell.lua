--/******************************************************************
---** 文件名:	HuoDongWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-02-28
--** 版  本:	1.0
--** 描  述:	活动窗口
--** 应  用:    
--******************************************************************/

--用一行7列的方式创建列表, 在设置显隐的时候会被移位
--目前前采用一行一列, 但是一行中固定7个预设

------------------------------------------------------------

local ItemFocusImage = AssetPath.TextureGUIPath.."Common_frame/Common_fenlan_xuan.png"
local ItemUnFocusImg = AssetPath.TextureGUIPath.."Common_frame/Common_fenlan_mo.png"

local tNormalTxtColor = Color.New(0.32, 0.48, 0.6)
local tFocusTxtColor  = Color.New(0.8,0.48, 0.26)

local HuoDongCalenderItemCell = UIControl:new
{
	windowName = "HuoDongCalenderItemCell",
	selected_calback = nil,
	BtnCallBack = {},
	RowIndex = 0,
	m_CalenderMgr = nil, 
}

function HuoDongCalenderItemCell:Attach(obj)
	UIControl.Attach(self, obj)
	self.m_BtnControls = 
	{
		self.Controls.m_Mon,
		self.Controls.m_Tues,
		self.Controls.m_Wed,
		self.Controls.m_Thur,
		self.Controls.m_Fri,
		self.Controls.m_Sat,
		self.Controls.m_Sun,
	} 

	for i = 1, 7 do 
		local button = self.m_BtnControls[i].gameObject:GetComponent(typeof(Button))
		self.BtnCallBack[i] = function() self:OnElementClick(i) end
		button.onClick:AddListener(self.BtnCallBack[i])
	end
	
	self.m_CalenderMgr = IGame.ActivityList:GetCalenderMgr()
	return self
end
function HuoDongCalenderItemCell:OnElementClick(col)
	if nil ~= self.selected_calback then
		self.selected_calback(self.RowIndex, col)
	end
end

function HuoDongCalenderItemCell:SetElementInfo(col, Element, HuoDong)

	local NameText = Element.transform:Find("Name"):GetComponent(typeof(Text))
	local TimeText = Element.transform:Find("Time"):GetComponent(typeof(Text))
	if nil ~= HuoDong then
		--设置活动名称
		NameText.text = tostring(HuoDong:GetName())
		
		local nTimeID = HuoDong:GetTimeID()
		local TimeCfg = IGame.rktScheme:GetSchemeInfo(ACTIVITYTIME_CSV, nTimeID)
		if not TimeCfg then
			print("找不到时间信息配置！ TimeID: "..nTimeID)
			return false
		end		
		
		--设置活动时间
		local StartTime = split_string(TimeCfg.StartTime,":",tostring)
		local EndTime   = split_string(TimeCfg.EndTime,":",tostring)
		local TimeInfo = StartTime[1]..":"..StartTime[2].."-"..EndTime[1]..":"..EndTime[2]
		TimeText.text = tostring(TimeInfo)
	else
		NameText.text = tostring("")
		TimeText.text = tostring("")
	end
	
	--设置背景
	local nCurTime = IGame.EntityClient:GetZoneServerTime()
	local nCurWeekDay = tonumber(os.date("%w", nCurTime))
	if nCurWeekDay == 0 then
		nCurWeekDay = 7
	end
	
	local BgImage = Element.gameObject:GetComponent(typeof(Image))
	if nCurWeekDay == col then
		self:SetSubTitleTxtColor(Element.gameObject, tFocusTxtColor)
		UIFunction.SetImageSprite(BgImage, ItemFocusImage)
		
	else
		self:SetSubTitleTxtColor(Element.gameObject, tNormalTxtColor)
		UIFunction.SetImageSprite(BgImage, ItemUnFocusImg)
	end
end

function HuoDongCalenderItemCell:SetItemCellInfo(RowIndex)
	
	self.RowIndex = RowIndex + 1	
	for col = 1, 7 do 
		local HuoDong = self.m_CalenderMgr:GetElement(self.RowIndex, col)
		if nil ~= HuoDong then
			self:SetElementInfo(col, self.m_BtnControls[col], HuoDong)
		else
			self:SetElementInfo(col, self.m_BtnControls[col], nil)
		end
	end
end

function HuoDongCalenderItemCell:OnRecycle()
	self.selected_calback = nil
	for i = 1, 7 do 
		local button = self.m_BtnControls[i].gameObject:GetComponent(typeof(Button))
		button.onClick:RemoveListener(self.BtnCallBack[i])
	end
	
	UIControl.OnRecycle(self)
end

function HuoDongCalenderItemCell:SetSelectCallback(func_cb)
	self.selected_calback = func_cb
end

function HuoDongCalenderItemCell:SetSubTitleTxtColor(gameObj, color)
	local texts = gameObj:GetComponentsInChildren(typeof(Text))
	for i = 0 , texts.Length - 1 do 
		texts[i].color = color
	end
end

function HuoDongCalenderItemCell:OnDestroy()	
	self.selected_calback = nil
	UIControl.OnDestroy(self)
end

return HuoDongCalenderItemCell



