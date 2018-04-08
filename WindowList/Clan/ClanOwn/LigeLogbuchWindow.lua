-- 领地竞拍、战况窗口
-- @Author: XieXiaoMei
-- @Date:   2017-04-12 20:46:57
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-30 12:24:52

local LigeLogbuchWindow = UIWindow:new
{
	windowName              = "LigeLogbuchWindow",
	
	m_CellList              = {},	-- 元素列表
		
	m_AuctionDataUpCallback = nil, 	-- 竞拍数据更新回调

	m_State = -1,

	m_EventHandler = {}
}

local LigeLogbuchCell = require(ClanSysDef.ClanOwnPath .. "LigeLogbuchCell")

-- 标题图片
local TitleImgPngs = 
{
	DeclareWar = "Ligeance_xuanzhan_biaoti.png",
	Fighting = "Ligeance_zhankuang_biaoti.png",
}
-------------------------------------------------------
-- 界面初始化
function LigeLogbuchWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	local controls = self.Controls
	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))

	self.m_State = IGame.Ligeance:GetState(0)
	
	self:SubscribeEvts()

	IGame.Ligeance:ShowAuction()
end

-- 监听事件
function LigeLogbuchWindow:SubscribeEvts()
	-- 请求帮派列表
	self.m_EventHandler[EVENT_LIGE_AUCITON_DATA_UP] = LigeLogbuchWindow.OnAuctionDataUpEvt
	
	for eventId, handler in pairs(self.m_EventHandler) do
		rktEventEngine.SubscribeExecute(eventId , 0, 0, handler, self)	
	end
end 

------------------------------------------------------------
-- 取消监听事件
function LigeLogbuchWindow:UnSubscribeEvts()
	for eventId, handler in pairs(self.m_EventHandler) do
		rktEventEngine.UnSubscribeExecute(eventId , 0, 0, handler)	
	end
	self.m_EventHandler = {}
end

-------------------------------------------------------
-- 界面销毁
function LigeLogbuchWindow:OnDestroy()
	self:UnSubscribeEvts()

	UIWindow.OnDestroy(self)

	table_release(self) 
end

function LigeLogbuchWindow:Show(bringTop)
	UIWindow.Show(self, bringTop)
	
	if not self:isLoaded() then
		return
	end

	IGame.Ligeance:ShowAuction()
	
	if self.m_State ~= IGame.Ligeance:GetState(0) then
		self:RefreshUI()
	end
end

function LigeLogbuchWindow:RefreshUI()
	local s1 = "胜方旗帜"
	local s2 = "宣战帮会"
	local s3 = "战况"
	local height = 114
	local titlePng = TitleImgPngs.Fighting
	local state = IGame.Ligeance:GetState(0)
	
	if state == eLigeance_State_Auction then
		s1 = "宣战金额"
		s2 = "帮会数量"
		s3 = "操作"
		titlePng = TitleImgPngs.DeclareWar
		height = 94.5
	end

	local controls = self.Controls
	controls.m_MoneyTitleTxt.text = s1
	controls.m_DeclClanTitleTxt.text = s2
	controls.m_RightTxt.text = s3
	local nLayout = controls.m_Content:GetComponent(typeof(GridLayoutGroup))
	nLayout.cellSize.y = height

	UIFunction.SetImageSprite( controls.m_TitleImg , ClanSysDef.LigeanceTexturePath .. titlePng)
end

-------------------------------------------------------
-- 竞拍数据更新事件
function LigeLogbuchWindow:OnAuctionDataUpEvt()
	local canAttacks = IGame.Ligeance:GetLigeanceData()

	for id, data in pairs(canAttacks) do
		if not self.m_CellList[id] then
			self:CreateCell(id, data)
		else
			self:ReloadCell(id, data)
		end
	end 
	self:RefreshUI()
end

-------------------------------------------------------
-- 创建元素
function LigeLogbuchWindow:CreateCell(id, data)
	rkt.GResources.FetchGameObjectAsync( GuiAssetList.ClanLigeance.LigeLogbuchCell , 
   	function( path , obj , ud )
		if nil ~= obj then
			obj.transform:SetParent(self.Controls.m_Content, false)
			obj.name = "LigeLogbuchCell-"..id
		
			local cell = LigeLogbuchCell:new({})
			cell:Attach(obj)
			cell:SetData(data)

			self.m_CellList[id] = cell
		end
	end, nil, AssetLoadPriority.GuiNormal )
end

-------------------------------------------------------
-- 重加载元素
function LigeLogbuchWindow:ReloadCell(id, data)
	local cell = self.m_CellList[id]
	cell:SetData(data)
end

-------------------------------------------------------
-- 销毁全部元素
function LigeLogbuchWindow:DestroyCells()
	for i, v in pairs(self.m_CellList) do
		v:Recycle() --回收
	end
	self.m_CellList = {}
end

-------------------------------------------------------
-- 关闭按钮事件
function LigeLogbuchWindow:OnBtnCloseClicked()
	self:Hide()
end

-------------------------------------------------------

return LigeLogbuchWindow