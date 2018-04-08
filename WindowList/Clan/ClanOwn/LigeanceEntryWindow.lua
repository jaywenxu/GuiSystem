-- 领地战战斗入口窗口
-- @Author: XieXiaoMei
-- @Date:   2017-04-12 20:46:57
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-30 12:22:48

local LigeanceEntryWindow = UIWindow:new
{
	windowName        = "LigeanceEntryWindow",

	m_CellList = {},	

	m_AuctionList = {},	
	m_WarListUpCallback = nil,

	m_EventHandler = {},
	
	bNeedLoad = false,
}


require("GuiSystem.WindowList.Clan.ClanSysDef")
local LigeanceEntryCell = require(ClanSysDef.ClanOwnPath .. "LigeanceEntryCell")

------------------------------------------------------------
-- 初始化
function LigeanceEntryWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	local controls = self.Controls
	controls.m_BasePnlBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))

	self:SubscribeEvts()
	
	if self.bNeedLoad then
		self.bNeedLoad = false
		self:OnWarListUpEvt()
	end
end

------------------------------------------------------------
-- 显示窗口
function LigeanceEntryWindow:ShowWindow()
	UIWindow.Show(self, true)
	self:OnWarListUpEvt()
end

------------------------------------------------------------
-- 界面销毁
function LigeanceEntryWindow:OnDestroy()
	self:UnSubscribeEvts()

	self:DestroyCells()

	UIWindow.OnDestroy(self)

	table_release(self) 
end

------------------------------------------------------------
--
function LigeanceEntryWindow:SubscribeEvts()
	-- 请求帮派列表
	self.m_EventHandler[EVENT_LIGE_WAR_LIST_UP]  = self.OnWarListUpEvt
	for eventID, handler in pairs(self.m_EventHandler) do
		rktEventEngine.SubscribeExecute( eventID, 0, 0, handler, self)
	end
end 

------------------------------------------------------------
function LigeanceEntryWindow:UnSubscribeEvts()

	for eventID, handler in pairs(self.m_EventHandler) do
		rktEventEngine.UnSubscribeExecute( eventID, 0, 0, handler, self)
	end
	self.m_EventHandler = {}
end

------------------------------------------------------------
-- 战斗列表更新事件回调
function LigeanceEntryWindow:OnWarListUpEvt()
	print("OnWarListUpEvt")

	if not self:isShow() then
		self.bNeedLoad = true
		return
	end
	self:CreateCells()
end

------------------------------------------------------------
-- 创建元素
function LigeanceEntryWindow:CreateCells()

	local warList = IGame.Ligeance:GetWarList() or {}
	local data = nil
	for n = 1, #warList do
		data = warList[n]
		local cell = self.m_CellList[data.nID]
		if not cell then
			self:CreateCell(data)
		else
			cell:SetData(data)
		end
	end 
end

------------------------------------------------------------
-- 创建元素
function LigeanceEntryWindow:CreateCell(data)
	rkt.GResources.FetchGameObjectAsync( GuiAssetList.ClanLigeance.LigeanceEntryCell , 
   	function( path , obj , ud )
		if nil ~= obj then
			obj.transform:SetParent(self.Controls.m_Content, false)
		
			local cell = LigeanceEntryCell:new({})
			cell:Attach(obj)
			cell:SetData(data)

			self.m_CellList[data.nID] = cell
		end
	end, nil, AssetLoadPriority.GuiNormal )
end

------------------------------------------------------------
-- 销毁时间段元素
function LigeanceEntryWindow:DestroyCells()
	for i, v in pairs(self.m_CellList) do
		v:Recycle() --回收
	end
	self.m_CellList = {}
end


------------------------------------------------------------
-- 关闭按钮回调
function LigeanceEntryWindow:OnBtnCloseClicked()
	self:Hide()
end

return LigeanceEntryWindow