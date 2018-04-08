-- 宣战输入窗口
-- @Author: XieXiaoMei
-- @Date:   2017-04-12 20:46:57
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-26 16:32:54

local DeclareWarInputWindow = UIWindow:new
{
	windowName  = "DeclareWarInputWindow",
	
	m_ClanMoney = 0,   --本帮金钱
	
	m_Auction   = nil,  --竞拍数据

	m_LeastAuctionCost   = 0,  --最少竞拍资金
}

------------------------------------------------------------
-- 初始化
function DeclareWarInputWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	self:InitUI()

	self:RefreshUI()
end

------------------------------------------------------------
-- 显示窗口
function DeclareWarInputWindow:InitUI()
	local controls = self.Controls

	local inputField = controls.m_InputField:GetComponent(typeof(InputField))
 	controls.inputField = inputField
	
	controls.m_AddBtn.onClick:AddListener(handler(self, self.OnBtnAddClicked))
	controls.m_SubBtn.onClick:AddListener(handler(self, self.OnBtnSubClicked))

	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_CancelBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_ConfirmBtn.onClick:AddListener(handler(self, self.OnBtnConfirmClicked))

	controls.inputField.text = 0

	-- 请求帮派列表
	self.m_DeclaWarOpRetCallback = handler(self, self.OnDeclaWarOpRetEvt)
	rktEventEngine.SubscribeExecute( EVENT_LIGE_DECLARE_WAR_OP_RET, 0, 0, self.m_DeclaWarOpRetCallback)
end


------------------------------------------------------------
-- 显示窗口
function DeclareWarInputWindow:ShowWindow(data,  bringTop)
	UIWindow.Show(self, bringTop)

	self.m_Auction = data

	if not self:isLoaded() then
		return 
	end

	self:RefreshUI()
end

------------------------------------------------------------
-- 刷新窗口
function DeclareWarInputWindow:RefreshUI()
	local controls = self.Controls

	local ligeCfg = IGame.rktScheme:GetSchemeInfo(LIGEANCE_CSV, self.m_Auction.nID)
	if not ligeCfg then
		cLog("本地配置不能为空 id:".. self.m_Auction.nID, "red")
		return
	end

	local desc = string.format("进攻%s：", ligeCfg.szName) 
	controls.m_DescTxt.text = desc

	self.m_LeastAuctionCost = ligeCfg.nLeastAuctionMoney
	controls.m_LeastCostTxt.text = string.format("：%d万", self.m_LeastAuctionCost)
	controls.inputField.text = ligeCfg.nLeastAuctionMoney

	self.m_ClanMoney = IGame.ClanClient:GetClanData(emClanProp_Funds)
end

------------------------------------------------------------
-- 显示窗口
function DeclareWarInputWindow:OnDestroy()
	rktEventEngine.UnSubscribeExecute( EVENT_LIGE_DECLARE_WAR_OP_RET , 0, 0, self.m_DeclaWarOpRetCallback)
	self.m_DeclaWarOpRetCallback = nil

	UIWindow.OnDestroy(self)

	table_release(self) 
end

------------------------------------------------------------
-- 显示窗口
function DeclareWarInputWindow:OnDeclaWarOpRetEvt(_, _, _, ret)
	cLog("DeclareWarInputWindow:OnDeclaWarOpRetEvt", "green")
	
	local s = "竞拍成功"
	if ret == 1 then
		s = "取消竞拍成功"
	end
	IGame.ChatClient:addSystemTips(TipType_Operate,InfoPos_ActorUnder, s)

	self:Hide()
end

------------------------------------------------------------
-- 输入减一按钮回调
function DeclareWarInputWindow:OnBtnSubClicked()
	local inputField = self.Controls.inputField
	local money = tonumber(inputField.text) or 0

	money = money - 1
	money = math.max(self.m_LeastAuctionCost, money)
	
	inputField.text = money
end

------------------------------------------------------------
-- 输入增一按钮回调
function DeclareWarInputWindow:OnBtnAddClicked()
	local inputField = self.Controls.inputField
	local money = tonumber(inputField.text) or 0
	money = money + 1
	money =  money * 10000 > self.m_ClanMoney and math.floor(self.m_ClanMoney/10000) or money
	inputField.text = money
end

------------------------------------------------------------
-- 确认按钮事件
function DeclareWarInputWindow:OnBtnConfirmClicked()
	local txt = self.Controls.m_InputedTxt.text
	if IsNilOrEmpty(txt) then
		IGame.ChatClient:addSystemTips(TipType_Operate,InfoPos_ActorUnder,"帮会资金不能为空" )
		return 
	end

	local money =  tonumber(txt) or 0 -- 输入显示单位为万
	if money * 10000 > self.m_ClanMoney then 
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder,"帮会资金不足" )
		return
	end

	if money < self.m_LeastAuctionCost then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "不能低于最少竞拍资金")
		return
	end

	local data = self.m_Auction
	IGame.Ligeance:RequestAuction(data.nID, data.nIndex, data.nAdd, money * 10000) --此单位为个位数
end

------------------------------------------------------------
-- 关闭按钮事件
function DeclareWarInputWindow:OnBtnCloseClicked()
	self:Hide()
end

------------------------------------------------------------
return DeclareWarInputWindow
