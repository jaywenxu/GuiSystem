-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017/04/01
-- 版  本:    1.0
-- 描  述:    富文本窗口
-------------------------------------------------------------------

local RichTextWindow = UIWindow:new
{
	windowName = "RichTextWindow",
	m_InitWidgetType = 1,
	m_CurWidgetType = nil,
	m_callBack_Module = nil,
	m_IndexedVisibleTgls = {}, -- 指定要显示的toggles
}


local this = RichTextWindow					-- 方便书写
local zero = int64.new("0")
local emojiStr = "<quad size=50 width=1 emoji=#%s/>"

-- toggle类型
local ToggleTypes =
{
	["表情"] = 1,
	["宠物"] = 2,
	["定位"] = 3,
	["物品"] = 4,
	["摆摊"] = 5,
	["红包"] = 6,
--	["文字表情"] = 7,
}

------------------------------------------------------------
function RichTextWindow:Init()
	self.RichTextEmojiWidget =  require("GuiSystem.WindowList.Chat.RichText.RichTextEmojiWidget")
	self.RichTextGoodsWidget =  require("GuiSystem.WindowList.Chat.RichText.RichTextGoodsWidget")
	self.RichTextExchangeWidget =  require("GuiSystem.WindowList.Chat.RichText.RichTextExchangeWidget")
	self.RichTextFunnyWordWidget =  require("GuiSystem.WindowList.Chat.RichText.RichTextFunnyWordWidget")
	self.RichTextPetWidget		= require("GuiSystem.WindowList.Chat.RichText.RichTextPetWidget")
	self:InitCallbacks()
end
------------------------------------------------------------
function RichTextWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	
	self.RichTextEmojiWidget:Attach(self.Controls.RichTextEmojiWidget.gameObject)
	self.RichTextGoodsWidget:Attach(self.Controls.RichTextGoodsWidget.gameObject)
	self.RichTextExchangeWidget:Attach(self.Controls.RichTextExchangeWidget.gameObject)
	self.RichTextFunnyWordWidget:Attach(self.Controls.RichTextFunnyWordWidget.gameObject)
	self.RichTextPetWidget:Attach(self.Controls.RichTextPetWidget.gameObject)
	RichTextWindow:InistiateEmojiFace()
	-- 注册富文本选项卡事件
	for i = 1, 7 do
		self.Controls["m_ToggleCell"..i] = self.Controls.m_RichTogBG:Find("Toggle ("..i..")")
		--self.Controls["m_ToggleCellBG"..i] = self.Controls.m_RichTogBG:Find("Toggle ("..i..")/Background")
		self.Controls["m_ToggleCellBG"..i] = self.Controls["m_ToggleCell"..i]:Find("Background")
		self.Controls["m_ToggleCellBG"..i].gameObject:SetActive(false)
		self.Controls["m_Tog"..i] = self.Controls["m_ToggleCell"..i]:GetComponent(typeof(Toggle))
		self.Controls["m_Tog"..i].onValueChanged:AddListener(function(on) self:OnToggleClick(on, i) end)
	end
	
	self.Controls["m_ToggleCellBG1"].gameObject:SetActive(true)
	--关闭窗口按钮
    self.Controls.m_MaskBtn.onClick:AddListener(function() self:OnBtnCloseClick() end)

	self.m_CurWidgetType = self.m_CurWidgetType or self.m_InitWidgetType
	self.Controls["m_Tog"..self.m_CurWidgetType].isOn = true
	self:ShowType(self.m_CurWidgetType)
	self:SubscribeEvent()
	self:VisibleToggles()
	--RichTextWindow.RichTextGoodsWidget:RefrashWidget()
	
	rktEventEngine.FireExecute(EVENT_CHAT_OPENRICHTEXTWINDOW, SOURCE_TYPE_SYSTEM, 0)
    return self
end

function RichTextWindow:OnBtnCloseClick()
	self.m_CurWidgetType = 1
	self.m_callBack_Module = nil
	self:Hide()
end

--------实例化表情
function RichTextWindow:InistiateEmojiFace()
	local emojiBtn=nil
	local emojiObj = self.Controls.RichTextEmoji
	local index =""
	local richText = nil
	
	emojiBtn = emojiObj:GetComponent(typeof(Button))
	if nil == emojiBtn then
		return
	end
	emojiBtn.onClick:AddListener(function() self:OnClickFace("010") end)
	for i=11, 73 do
		-- newEmojiObj 这个变量要在这循环里声明
		local newEmojiObj = rkt.GResources.InstantiateGameObject(emojiObj.gameObject)
		newEmojiObj.transform:SetParent(emojiObj.parent,false)
		index = string.format("0%s",i)
		--print( "<color=green> 表情index："..index.."</color>")
		newEmojiObj.name = index
		richText = newEmojiObj:GetComponent(typeof(Text))
		richText.text = string.format(emojiStr,index)
		emojiBtn = newEmojiObj:GetComponent(typeof(Button))
		if nil == emojiBtn then
			return
		end
		emojiBtn.onClick:AddListener(function() self:OnClickFace(newEmojiObj.name) end)
	end
end

--点击表情
function RichTextWindow:OnClickFace(text)
	if not text then
		return
	end
	if self.m_callBack_Module then
		self.m_callBack_Module:InsertInputText("#"..text)
	end
end

------------------------------------------------------------
--窗口显示
function RichTextWindow:ShowWindow()
	UIWindow.ShowWindow(self)
end

function RichTextWindow:Hide(destory)
	rktEventEngine.FireExecute(EVENT_CHAT_CLOSERICHTEXTWINDOW, SOURCE_TYPE_SYSTEM, 0)
	UIWindow.Hide(self, destory)
end

------------------------------------------------------------
-- 窗口销毁
function RichTextWindow:OnDestroy()
	self.m_CurWidgetType = nil
	self:UnsubscribeEvent()
	self.m_IndexedVisibleTgls = {}
	UIWindow.OnDestroy(self)
end

function RichTextWindow:SetCWidgetType(WidgetType)
	self.m_CurWidgetType = WidgetType
end

------------------------------------------------------------
-- 点击富文本选项卡
function RichTextWindow:OnToggleClick(on, index)
	if not self:isLoaded() then
		return
	end
	if not on then
		self.Controls["m_ToggleCellBG"..index].gameObject:SetActive(false)
		return
	end

	self.Controls["m_ToggleCellBG"..index].gameObject:SetActive(true)
	if index == self.m_CurWidgetType then -- 相同标签不用响应
		return
	end
	
	self.m_CurWidgetType = index
	self:ShowType(index)
end

function RichTextWindow.ShowEmoji()
	UIManager.RichTextWindow.Controls.RichTextEmojiWidget.gameObject:SetActive(true)
end

function RichTextWindow.HideEmoji()
	UIManager.RichTextWindow.Controls.RichTextEmojiWidget.gameObject:SetActive(false)
end

function RichTextWindow.ShowPetWidget()
	UIManager.RichTextWindow.Controls.RichTextPetWidget.gameObject:SetActive(true)
end

function RichTextWindow.HidePetWidget()
	UIManager.RichTextWindow.Controls.RichTextPetWidget.gameObject:SetActive(false)
end

function RichTextWindow.ShowGoodsWidget()
	UIManager.RichTextWindow.RichTextGoodsWidget:RefrashWidget()
	UIManager.RichTextWindow.Controls.RichTextGoodsWidget.gameObject:SetActive(true)
end

function RichTextWindow.HideGoodsWidget()
	UIManager.RichTextWindow.Controls.RichTextGoodsWidget.gameObject:SetActive(false)
end

function RichTextWindow.ShowExchangeWidget()
	IGame.ExchangeClient:RequestPlayerStallData(false)
	
	UIManager.RichTextWindow.Controls.RichTextExchangeWidget.gameObject:SetActive(true)
end

function RichTextWindow.HideExchangeWidget()
	UIManager.RichTextWindow.Controls.RichTextExchangeWidget.gameObject:SetActive(false)
end

function RichTextWindow.ShowRedPacketWidget()
	local type = 1
	local CurShowChannel = UIManager.ChatWindow:GetCurShowChannel()
	if ChatChannel_Tribe == CurShowChannel then
		type = 2
	elseif ChatChannel_Team == CurShowChannel then
		type = 3
	end
	UIManager.RedPacketWindow:OpenPanel(type)
	RichTextWindow:Hide()
end
-- 
function RichTextWindow.HideRedPacketWidget()
end

function RichTextWindow.ShowFunnyWordWidget()
	UIManager.RichTextWindow.RichTextFunnyWordWidget:RefrashWidget()
	UIManager.RichTextWindow.Controls.RichTextFunnyWordWidget.gameObject:SetActive(true)
end

function RichTextWindow.HideFunnyWordWidget()
	UIManager.RichTextWindow.Controls.RichTextFunnyWordWidget.gameObject:SetActive(false)
end

function RichTextWindow.ShowLocation()
	local pHero = IGame.EntityClient:GetHero()
	if pHero == nil then
		return
	end
	local pos = pHero:GetPosition()
	-- CommonApi:moveto(mapid, x, y, z, distance)

	local mapID = IGame.EntityClient:GetMapID()

	--加载MapInfo.csv文件，获取当前场景地图配置信息
	local mapInfo = IGame.rktScheme:GetSchemeInfo(MAPINFO_CSV, mapID )				--获取对应mapID的地图信息
	local name = mapInfo.szName														--当前地图名称
	local x = math.floor(pos.x)
	local y = math.floor(pos.y)
	local z = math.floor(pos.z)
	local InPutString = "<herf><color="..Chat_MapLocaltion_Color..">"..name.."<"..x.."，"..z.."></color><fun>"
	InPutString = InPutString.."ZC_moveto("..mapID..","..x..","..y..","..z..",3)</fun></herf>"
	
	if RichTextWindow.m_callBack_Module then
		RichTextWindow.m_callBack_Module:InsertRichText(x.."，"..z , InPutString, true)
	end
	RichTextWindow:Hide()
end

function RichTextWindow.HideLocation()
end

local RichTextTypeShowOrHide = {
	[1] = {ShowFunc = RichTextWindow.ShowEmoji,				HideFunc = RichTextWindow.HideEmoji},
	[2] = {ShowFunc = RichTextWindow.ShowPetWidget,			HideFunc = RichTextWindow.HidePetWidget},
	[3] = {ShowFunc = RichTextWindow.ShowLocation,			HideFunc = RichTextWindow.HideLocation},
	[4] = {ShowFunc = RichTextWindow.ShowGoodsWidget,		HideFunc = RichTextWindow.HideGoodsWidget},
	[5] = {ShowFunc = RichTextWindow.ShowExchangeWidget,	HideFunc = RichTextWindow.HideExchangeWidget},
	[6] = {ShowFunc = RichTextWindow.ShowRedPacketWidget,	HideFunc = RichTextWindow.HideRedPacketWidget},
	[7] = {ShowFunc = RichTextWindow.ShowFunnyWordWidget,	HideFunc = RichTextWindow.HideFunnyWordWidget},
	--[3] = {ShowFunc = RichTextWindow.ShowRecast,	HideFunc = RichTextWindow.HideRecast},
}

function RichTextWindow:ShowType(index)
	if not self:isLoaded() then
		DelayExecuteEx( 10,function ()
			self:ShowType(index)
		end)
		return
	end
--	cLog("RichTextWindow:ShowType "..tostringEx(index))
	for i=1,7 do 
		if RichTextTypeShowOrHide[i] then
			if i == index then
				RichTextTypeShowOrHide[i].ShowFunc()
			else
				RichTextTypeShowOrHide[i].HideFunc()
			end
		end
	end
end

function RichTextWindow:CheckModule(callBack_Module)
	local ModuleName = ""
	if not callBack_Module.windowName then
		uerror("你调的模块没有名字")
		return false
	end
	ModuleName = callBack_Module.windowName
	local NeedFun = {
		"InsertInputText",
		"InsertRichText",
	}
	for key,v in ipairs(NeedFun) do
		if not callBack_Module[v] then
			uerror(ModuleName.." 模块咩有实现函数 "..v)
			return false
		end
	end
	return true
end

------------------------------------------------------------
--窗口显示or隐藏
function RichTextWindow:ShowOrHide(callBack_Module)
	if not self:CheckModule(callBack_Module) then
		return
	end
	self.m_callBack_Module = callBack_Module
	if not self:isShow()then
		self.m_CurWidgetType = self.m_CurWidgetType or self.m_InitWidgetType
		self:Show(true)
		self:ShowType(self.m_CurWidgetType)
		self:VisibleToggles()
		if self:isLoaded() then 
			rktEventEngine.FireExecute(EVENT_CHAT_OPENRICHTEXTWINDOW, SOURCE_TYPE_SYSTEM, 0)
		end
	else
		rktEventEngine.FireExecute(EVENT_CHAT_CLOSERICHTEXTWINDOW, SOURCE_TYPE_SYSTEM, 0)
		self:Hide()
	end
end

function RichTextWindow:InsertInputText(txt)
	if not self.m_callBack_Module then
		return
	end
	if self.m_callBack_Module.InsertInputText then
		self.m_callBack_Module:InsertInputText(txt)
	else
		local ModuleName = self.m_callBack_Module.windowName or "未知模块"
		uerror(ModuleName.." 模块未实现函数 InsertInputText，调用失败")
	end
end

function RichTextWindow:InsertRichText(ShowText,RichText,CanRepeatFlg)
	if not self.m_callBack_Module then
		return
	end
	if self.m_callBack_Module.InsertRichText then
		self.m_callBack_Module:InsertRichText(ShowText,RichText,CanRepeatFlg)
	else
		local ModuleName = self.m_callBack_Module.windowName or "未知模块"
		uerror(ModuleName.." 模块未实现函数 InsertRichText，调用失败")
	end
end

function RichTextWindow:SetInputText(txt)
	if not self.m_callBack_Module then
		return
	end
	if self.m_callBack_Module.SetInputText then
		self.m_callBack_Module:SetInputText(txt)
	else
		local ModuleName = self.m_callBack_Module.windowName or "未知模块"
		uerror(ModuleName.." 模块未实现函数 SetInputText，调用失败")
	end
end

------------------------------------------------------------
-- 显示指定的toggle
-- @ param tglTypeKeys 	: 指定的ToggleTypes里的key数组，比如：{"表情", "文字表情"}
function RichTextWindow:SetTogglesVisible(tglTypeKeys)
	for _, key in pairs(tglTypeKeys) do
		local tType = ToggleTypes[key]
		if tType then
			self.m_IndexedVisibleTgls[tType] = true
		end
	end
end

-- 显示/隐藏toggle
function RichTextWindow:VisibleToggles()
	if not self:isLoaded() then
		return
	end
	local bIdxVisible = #self.m_IndexedVisibleTgls > 0
	for i=1, 7 do
		local tgl = self.Controls["m_Tog"..i]
		--cLog("显示/隐藏toggle "..tostringEx(i))
		if self.m_IndexedVisibleTgls[i] then
			tgl.gameObject:SetActive(true)
		else
			tgl.gameObject:SetActive(not bIdxVisible)
		end
	end
end

-- 摆摊数据返回事件
function RichTextWindow:OnPlayerStallData()
	if not self:isShow()then
		return
	end
	UIManager.RichTextWindow.RichTextExchangeWidget:RefrashWidget()
end

-- 订阅事件
function RichTextWindow:SubscribeEvent()
	rktEventEngine.SubscribeExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCHANGE_NET_EVENT_ON_PLAYER_STALL_DATA, self.callback_OnPlayerStallData)
	--rktEventEngine.SubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
end

-- 取消订阅事件
function RichTextWindow:UnsubscribeEvent()
	rktEventEngine.UnSubscribeExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCHANGE_NET_EVENT_ON_PLAYER_STALL_DATA, self.callback_OnPlayerStallData)
	--rktEventEngine.UnSubscribeExecute(EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
end

-- 初始化全局回调函数
function RichTextWindow:InitCallbacks()
	self.callback_OnPlayerStallData = function(event, srctype, srcid, eventdata) self:OnPlayerStallData(eventdata) end
	--self.callback_OnEventRemoveGoods = function(event, srctype, srcid, eventdata) self:OnEventRemoveGoods(eventdata) end
end

return RichTextWindow







