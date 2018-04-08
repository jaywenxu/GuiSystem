-- 领地战战况Cell
-- @Author: XieXiaoMei
-- @Date:   2017-04-12 16:43:41
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-19 11:02:02

------------------------------------------------------------
local LigeLogbuchCell = UIControl:new
{
	windowName  = "LigeLogbuchCell",
	
	m_Data      = nil,	-- 领地数据
	m_Auction   = nil,	-- 竞拍数据
	
	m_AuctionOp = {		-- 竞拍操作数据
		idx         = 0, -- eLigeance_Auction_Main：主   eLigeance_Auction_Two：次
		op          = 0, -- 0:撤销  1:进攻
	},

	m_OpBtnClickCallBack = nil,

	m_LigeName = "",
}
local this = LigeLogbuchCell

local OperaBtnPngs  =
{
	Attack = "Common_frame/Common_button_er_huang.png",
	Revoke =  "Common_frame/Common_button_er_lv.png"
}
------------------------------------------------------------
-- 初始化
function LigeLogbuchCell:Attach(obj)
	UIControl.Attach(self,obj)

	self.m_OpBtnClickCallBack = handler(self, self.OnBtnOperClicked)
	self.Controls.m_OperaBtn.onClick:AddListener(self.m_OpBtnClickCallBack)
	self.m_Layout = self.transform:GetComponent(typeof(LayoutElement))
end

------------------------------------------------------------
-- 设置数据
function LigeLogbuchCell:SetData(data)
	local state = IGame.Ligeance:GetState(data.nID)
	local controls = self.Controls

	local ligeCfg = IGame.rktScheme:GetSchemeInfo(LIGEANCE_CSV, data.nID)
	if not ligeCfg then
		cLog("本地配置不能为空 id:".. data.nID, "red")
		return
	end

	self.m_LigeName  = ligeCfg.szName

	controls.m_NameTxt.text  = ligeCfg.szName
	controls.m_TypeTxt.text = ligeCfg.szLevelName
	controls.m_OwnerTxt.text = data.szClanName == "" and "无" or data.szClanName
	
	local declWarState = ""
	local declWarMoney = ""
	local declWarClans = ""
	local bShowOpGo = false
	local bShowWinerFlag = false
	local bShowMoneyImg = false
	local opBtnImgFile = OperaBtnPngs.Attack
	local color = UIFunction.ConverRichColorToColor("5D7C96")
	-- local
	if state == eLigeance_State_Auction then -- 宣战期
		controls.m_WarText.gameObject:SetActive(false)
		bShowMoneyImg = true

		self.m_AuctionOp = {}
		local bCanAttack = IGame.Ligeance:IsCanAttack(data.nID) --是否可以攻打
		bShowOpGo = bCanAttack
		if bCanAttack then
			
			self.m_Auction  = IGame.Ligeance:SeekSelfAuction(data.nID)
			if self.m_Auction then --已竞拍
				local bIsMainAtta = self.m_Auction[1] == eLigeance_Auction_Main 
				declWarState = bIsMainAtta and "撤销(主)" or "撤销(次)"
				declWarMoney = NumToWan(self.m_Auction[2].nMoney)

				self.m_AuctionOp.idx = self.m_Auction[1]
				self.m_AuctionOp.op = 0

				opBtnImgFile = OperaBtnPngs.Revoke

			else -- 未竞拍
				local flag = IGame.Ligeance:GetNoAuctionFlag()
				if flag ~= nil then 
					declWarState = flag == eLigeance_Auction_Main and "进攻(主)" or "进攻(次)"

					self.m_AuctionOp.idx = flag
					self.m_AuctionOp.op = 1
				else
					bShowOpGo = false
				end
			end
			declWarClans = data.nAuctionClanNum < 1 and "无" or data.nAuctionClanNum
		end
	else
		if self.m_Layout then
			self.m_Layout.preferredHeight = 114
		end
		declWarClans = data.szEnemyName1 or ""
		if not IsNilOrEmpty(data.szEnemyName2) then
			declWarClans = string.format("%s\n%s", declWarClans , data.szEnemyName2)
		end

		if state == eLigeance_State_WarReady then --备战期
			bShowWinerFlag = false
			declWarState = "未开始"
		else  --战争中
			if state == eLigeance_State_Normal then -- 战争结束
				declWarState = "结束"

				if data.nBannerID > 0 then
					-- 设置已拥有的帮会的旗帜
					local imgPath = ClanSysDef.LigeanceTexturePath .. ClanSysDef.LigeanceFlagPngs[data.nBannerID]
	 				UIFunction.SetImageSprite(controls.m_WinerFlagImg, imgPath)

	 				controls.m_WinerFlagTxt.text = data.szBanerName

	 				bShowWinerFlag = true
				end

			elseif state == eLigeance_State_War then -- 战争中
				declWarState = "进行中..."
				color = UIFunction.ConverRichColorToColor("FF7800")
			end
		end
		controls.m_WarText.gameObject:SetActive(true)
		controls.m_WarText.text = declWarState
		controls.m_WarText.color = color 
	end


	controls.m_DeclarersTxt.text = declWarClans
	controls.m_DeclaMoneyTxt.text = declWarMoney
	controls.m_StateTxt.text = declWarState

	controls.m_OperaBtn.gameObject:SetActive(bShowOpGo)

	controls.m_WinerFlag.gameObject:SetActive(bShowWinerFlag)

	controls.m_ClanCoinImg.gameObject:SetActive(bShowMoneyImg)

	UIFunction.SetImageSprite(controls.m_OpBtnImg, GuiAssetList.GuiRootTexturePath .. opBtnImgFile)
	
	self.m_Data = data
end

------------------------------------------------------------
-- 自身销毁
function LigeLogbuchCell:OnDestroy()
	UIControl.OnDestroy(self)

	table_release(self) 
end

------------------------------------------------------------
-- 回收自身
function LigeLogbuchCell:Recycle()

	self.Controls.m_OperaBtn.onClick:RemoveListener(self.m_OpBtnClickCallBack)

	rkt.GResources.RecycleGameObject(self.transform.gameObject)

	table_release(self) 
end

------------------------------------------------------------
-- 操作按钮回调
function LigeLogbuchCell:OnBtnOperClicked()
	if isTableEmpty(self.m_AuctionOp) then
		return
	end

	if self.m_Auction then  -- 撤销
		local data = 
		{
			content = string.format("你将撤销对%s领地的宣战，需要扣除宣战资金的10%%费用，是否确定撤销？", self.m_LigeName),
			confirmCallBack = function ()
				IGame.Ligeance:RequestAuction(self.m_Data.nID, self.m_AuctionOp.idx, self.m_AuctionOp.op, "")
			end,
		}	
		UIManager.ConfirmPopWindow:ShowDiglog(data)
	else
		-- 宣战：打开宣战输入面板
		local t = {nID = self.m_Data.nID, nIndex = self.m_AuctionOp.idx, nAdd = self.m_AuctionOp.op} 
		UIManager.DeclareWarInputWindow:ShowWindow(t, true)
	end


end

------------------------------------------------------------

return this

