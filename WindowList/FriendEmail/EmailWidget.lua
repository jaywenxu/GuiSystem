-- 邮件系统窗口
-- @Author: XieXiaoMei
-- @Date:   2017-05-12 09:55:45
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-30 17:42:38

-- 功能备忘:
-- 1.有附件的邮件领取后会自动删除，领取也是删除操作;无附件的读后要手动删除
-- 2.最新日期的邮件，默认排序在最顶部

local EmailWidget = UIControl:new
{
	windowName = "EmailWidget",
	m_AppxItem1s = {},
	m_EmailList = {},
	m_SelEmailIdx = 1, --当前选择邮件

	m_MailPart = nil,

	m_EmailItems = {},

	m_FirstEnter = true,

	m_EventHandler = {}
}


local this = EmailWidget
local EmailCeil = require( "GuiSystem.WindowList.FriendEmail.EmailCeil" )

function EmailWidget:Attach( obj )
	UIControl.Attach(self, obj)	
	
	self:InitUI()
	
	self.m_MailPart = IGame.MailClient.GetEmailPart()

	self:SubscribeEvts()
end


function EmailWidget:OnDestroy()
	self:UnSubscribeEvts()
	
	UIControl.OnDestroy(self)
	
	self.m_AppxItem1s = {}
	self.m_EmailList = {}
	self.m_MailPart = nil
	self.m_EmailItems = {}

	self.m_FirstEnter = true
end

function EmailWidget:Show()
	UIControl.Show(self)

	self:RefreshUI()
end

function EmailWidget:InitUI()
	local controls = self.Controls
	
	local scrollView  = controls.m_EmailList
	local listView = scrollView:GetComponent(typeof(EnhanceDynamicSizeListView))
	listView.onGetCellView:AddListener(handler(self, self.OnGetCellView))
	listView.onCellViewVisiable:AddListener(handler(self, self.OnCellRefreshVisible))
	controls.listView = listView
	
	local listScroller = scrollView:GetComponent(typeof(EnhancedScroller))
	controls.listScroller = listScroller

	controls.listTglGroup  = controls.m_ViewPort:GetComponent(typeof(ToggleGroup))
	
	controls.m_RmvAllBtn.onClick:AddListener(handler(self, self.OnBtnRmvAllClicked))
	controls.m_GetRmvBtn.onClick:AddListener(handler(self, self.OnBtnGetRmvClicked))
	
	for i=1, 5 do
		self.m_AppxItem1s[i] =  controls["m_AppxItem" .. i ]
	end
	
	self:ResetEmailDesc()
end


function EmailWidget:RefreshUI()
	--申请邮件列表
	self.m_MailPart:OpenMailBox()
end

function EmailWidget:SubscribeEvts()
	if isTableEmpty(self.m_EventHandler) then
		self.m_EventHandler = 
		{
			[EVENT_MAIL_UPDATE_MAILLIST] = EmailWidget.ReloadMailListUI,
			[EVENT_MAIL_DELETE_MAIL]     = EmailWidget.OnDeletedMallEvt,
			[EVENT_MAIL_DELETE_ALL_MAIL] = EmailWidget.ReloadMailListUI,
			-- [EVENT_MAIL_NOTIFY]          = EmailWidget.OnNotify,
			[EVENT_MAIL_UPDATE_MAILINFO] = EmailWidget.UpdateMail,
			[EVENT_MAIL_RELOAD_UI]       = EmailWidget.ReloadMailListUI,
		}
	end

	for eventId, handler in pairs(self.m_EventHandler) do
		rktEventEngine.SubscribeExecute(eventId , SOURCE_TYPE_EMAIL, 0, handler, self)	
	end
end

function EmailWidget:UnSubscribeEvts()
	for eventId, handler in pairs(self.m_EventHandler) do
		rktEventEngine.UnSubscribeExecute(eventId , SOURCE_TYPE_EMAIL, 0, handler, self)	
	end
end

-- 删除一封邮件事件
function EmailWidget:OnDeletedMallEvt()
	if not self:isShow() then
		return
	end

	if self.m_SelEmailIdx > #self.m_EmailList then
		self.m_SelEmailIdx = 1
	end

	self:ReloadMailListUI()
end

-- 刷新邮件列表
function EmailWidget:ReloadMailListUI()
	if not self:isShow() then
		return
	end

	self.m_EmailList = self.m_MailPart:GetMailIDList()
	
	local controls = self.Controls
	self.Controls.listTglGroup:SetAllTogglesOff()

	local listView = self.Controls.listView
	local emailsCnt = #self.m_EmailList
	
	listView:SetCellCount( emailsCnt , false )
	
	for i=1, emailsCnt do
		self.Controls.listView:SetCellHeight(130, i-1)
	end
	
	if not self.m_FirstEnter then -- 非第一次进入，保持原先位置不变，只刷新当前界面活动的元素
		self.Controls.listScroller:Resize(true)	
		self.Controls.listScroller:RefreshActiveCellViews()

	elseif self.m_FirstEnter and emailsCnt > 0 then -- 第一次进入，ReloadData操作默认位置为顶部
		self.m_FirstEnter = false
		self.Controls.listScroller:ReloadData()
		
		self:SelectEmailCell(self.m_SelEmailIdx)
	end
	
	if emailsCnt < 1 then
		self:ResetEmailDesc() --
	end

	controls.m_EmptyWarn.gameObject:SetActive(emailsCnt < 1)
	
	-- UIManager.FriendEmailWindow:RefreshRedDot()
end


-- EnhancedListView 一行被“创建”时的回调
function EmailWidget:OnGetCellView( goCell )	
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	listcell.onRefreshCellView = handler( self , self.OnCellRefreshVisible)
	self:CreateCellItems(listcell)
end

-- EnhancedListView 一行强制刷新时的回调
function EmailWidget:OnCellRefreshVisible( goCell )
	local listcell = goCell:GetComponent(typeof(EnhancedListViewCell))
	self:RefreshCellItems(listcell)
end


-- 创建条目
function EmailWidget:CreateCellItems( listcell )
	local item = EmailCeil:new({})
	item:Attach(listcell.gameObject)
	item:SetToggleGroup(self.Controls.listTglGroup)
	item:SetSelectCallback(handler(self, self.OnItemCellSelected))
	
	local idx = listcell.dataIndex + 1
	self.m_EmailItems[idx] = item
end

-- 选中某封邮件
function EmailWidget:SelectEmailCell(idx)
	if self.m_EmailList[idx] and self.m_EmailItems[idx] then
		self.m_EmailItems[idx]:SetToggleIsOn(true)
		self:OnItemCellSelected(idx)
	end
end

--- 刷新列表
function EmailWidget:RefreshCellItems( listcell )
	local behav = listcell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	
	local item = behav.LuaObject

	local idx = listcell.dataIndex + 1
	if item.windowName == "EmailCeil" and self.m_EmailList[idx] ~= nil then
		
		item:SetCellData(idx, self.m_EmailList[idx])

		if idx == self.m_SelEmailIdx then
			self:OnItemCellSelected(idx)
		end
		item:SetToggleIsOn(idx == self.m_SelEmailIdx)
	end
end

-- 邮件选中事件
function EmailWidget:OnItemCellSelected(idx)
	local data = self.m_EmailList[idx]
	if data == nil then
		self.m_SelEmailIdx = 0
		return
	end
	
	self.m_SelEmailIdx = idx
	
	--标记为已读
	if not data.bIsRead then
		data.bIsRead = true
		self:PostReadMailRequest(data.nMailID)
		self.m_MailPart:CheckEmailWarnings()
	end
	
	
	self:SetSelEmailDesc(idx)
end

-- 设置选中的邮件详细信息
function EmailWidget:SetSelEmailDesc(idx)
	local data = self.m_EmailList[idx]
	if data == nil then
		self.m_SelEmailIdx = 0
		return
	end
	
	local controls = self.Controls
	local szContext,FunText,maxHeight = RichTextHelp.AsysSerText(data.szContext,Chat_Emoji_High)
	controls.m_ContentTxt.gameObject:SetActive(false)
	controls.m_ContentTxt.text = szContext
	controls.m_ContentTxt.gameObject:SetActive(true)
	controls.m_SenderTxt.text = "发送人：" .. data.szSenderName
	controls.m_DateTxt.text = TimerToStringYMD(data.nReceiveTime, 2)
	
	controls.m_GetRmvBtn.gameObject:SetActive(true)
	
	local bHasPlusData = data.bHasPlusData
	-- controls.m_AppxTitle.gameObject:SetActive(bHasPlusData)
	
	controls.m_GetImg.gameObject:SetActive(bHasPlusData)
	controls.m_RmvImg.gameObject:SetActive(not bHasPlusData)

	--显示了几个附件
	local realGoods = 0
	
	--[[emCoinType_YuanBao,                     // 钻石
    emCoinType_Game_BindYuanBao,            // 游戏产出的钻石
    emCoinType_Value_BindYuanBao,           // 增值产出的钻石
	emCoinType_Game_YinLiang,        	    // 游戏产出的银两
	emCoinType_Value_YinLiang,     	        // 增值产出的银两
    emCoinType_Game_YinBi,          	    // 游戏产出的银币
    emCoinType_Value_YinBi,       	        // 增值产出的银币--]]
	
	local moneyID = nil
	--金钱
	if data.nPlusMoneyA > 0 or data.nPlusMoneyX > 0 then
		--钻石
		realGoods = realGoods + 1
		if data.byMoneyType == emCoinType_Value_YuanBao or data.byMoneyType == emCoinType_Game_YuanBao then
			moneyID = 9002
		end
		--银两
		if data.byMoneyType == emCoinType_Game_YinLiang or data.byMoneyType == emCoinType_Value_YinLiang then
			moneyID = 9003
		end
		--银币
		if data.byMoneyType == emCoinType_Game_YinBi or data.byMoneyType == emCoinType_Value_YinBi then
			moneyID = 9004
		end
		-- 帮贡
		if data.byMoneyType == emCoinType_ClanContribute then
			moneyID = 9005
		end
		-- 帮会工资
		if data.byMoneyType == emCoinType_ClanSalary then
			moneyID = 9016
		end
		-- 战功
		if data.byMoneyType == emCoinType_ZhanGong then
			moneyID = 9010
		end
		-- 论剑积分
		if data.byMoneyType == emCoinType_LunJian then
			moneyID = 9020
		end
		
		local itemBtn = self.m_AppxItem1s[realGoods]
		local FindAndSetImgSprite = function (imgName, imgFilePath)
			local img = itemBtn.transform:Find(imgName):GetComponent(typeof(Image))
			UIFunction.SetImageSprite(img, imgFilePath)
		end
		local moneyScheme = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, moneyID)
		local imgFilePath = AssetPath.TextureGUIPath..moneyScheme.lIconID1
		FindAndSetImgSprite("IconImg", imgFilePath)			
		imgFilePath = AssetPath.TextureGUIPath .. moneyScheme.lIconID2
		FindAndSetImgSprite("QualityImg", imgFilePath)
		
		local numTxt = itemBtn.transform:Find("NumText"):GetComponent(typeof(Text))
		numTxt.text = NumToWan(data.nPlusMoneyA + data.nPlusMoneyX)
		numTxt.gameObject:SetActive(true)
		
		itemBtn.onClick:RemoveAllListeners()
		itemBtn.gameObject:SetActive(true)
		itemBtn.onClick:AddListener(function ()
			self:ShowAttrGoodsTips(moneyID)
		end)
	end
	
	--经验
	if data.nPlusExp > 0 then	
		realGoods = realGoods + 1
		local itemBtn = self.m_AppxItem1s[realGoods]
		local FindAndSetImgSprite = function (imgName, imgFilePath)
			local img = itemBtn.transform:Find(imgName):GetComponent(typeof(Image))
			UIFunction.SetImageSprite(img, imgFilePath)
		end
		local goodsID = 9001
		local moneyScheme = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodsID)
		local imgFilePath = AssetPath.TextureGUIPath..moneyScheme.lIconID1
		FindAndSetImgSprite("IconImg", imgFilePath)			
		imgFilePath = AssetPath.TextureGUIPath .. moneyScheme.lIconID2
		FindAndSetImgSprite("QualityImg", imgFilePath)
		local numTxt = itemBtn.transform:Find("NumText"):GetComponent(typeof(Text))
		numTxt.text = NumToWan(data.nPlusExp)
		numTxt.gameObject:SetActive(true)
		itemBtn.gameObject:SetActive(true)

		itemBtn.onClick:RemoveAllListeners()
		itemBtn.onClick:AddListener(function ()
			self:ShowAttrGoodsTips(goodsID)
		end)
		
	end
	
	for i=1, data.nPlusGoodsNum do
		
		local itemBtn = self.m_AppxItem1s[realGoods+1]
		--itemBtn.gameObject:SetActive(false)
		
		local appxItem = data.uidGoodsList[i]
		if appxItem ~= nil then
			local entity = IGame.EntityClient:Get(appxItem)
			if entity then
				local FindAndSetImgSprite = function (imgName, imgFilePath)
					local img = itemBtn.transform:Find(imgName):GetComponent(typeof(Image))
					UIFunction.SetImageSprite(img, imgFilePath)
				end
				
				local goodsID = entity:GetNumProp(GOODS_PROP_GOODSID)
				
				local nEntityClass = entity:GetEntityClass()
				local schemeInfo = nil
				
				--装备
				if EntityClass:IsEquipment(nEntityClass) then
					schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, goodsID)
					if not schemeInfo then
						print("找不到物品配置，物品ID=", goodsID)
						return
					end
					
					local imgFilePath = AssetPath.TextureGUIPath..schemeInfo.IconIDNormal
					FindAndSetImgSprite("IconImg", imgFilePath)
				
					local nQuality  = entity:GetNumProp(EQUIP_PROP_QUALITY)
					local nAdditionalPropNum = entity:GetAdditionalPropNum()
					local imageBgPath =  self:GetIconBgPath(nQuality, nAdditionalPropNum)

					FindAndSetImgSprite("QualityImg", imageBgPath)
					
				--物品
				elseif EntityClass:IsLeechdom(nEntityClass) then
					schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodsID)
					if not schemeInfo then
						print("找不到物品配置，物品ID=", goodsID)
						return
					end
					
					local imgFilePath = AssetPath.TextureGUIPath..schemeInfo.lIconID1
					FindAndSetImgSprite("IconImg", imgFilePath)
				
					imgFilePath = AssetPath.TextureGUIPath .. schemeInfo.lIconID2
					FindAndSetImgSprite("QualityImg", imgFilePath)
				
				end
				
				--附件数量
				local goodsNum = entity:GetNumProp(GOODS_PROP_QTY)
				
				local numTxt = itemBtn.transform:Find("NumText"):GetComponent(typeof(Text))
				numTxt.text = goodsNum
				if goodsNum < 2 then
					numTxt.gameObject:SetActive(false)
				else
					numTxt.gameObject:SetActive(true)
				end
				
				itemBtn.onClick:RemoveAllListeners()
				itemBtn.onClick:AddListener(function ()
					self:ShowAppxGoodsTips(entity, goodsID)
				end)
				
				itemBtn.gameObject:SetActive(true)
							
				realGoods = realGoods + 1
				
				--最多显示5个附件
				if realGoods >= 5 then
					break
				end
				
			end
		end
	end
	
	--隐藏没有附件的格子
	for i = 1, 5 do
		if i > realGoods then
			self.m_AppxItem1s[i].gameObject:SetActive(false)
		end
	end
end

-- 显示属性商品信息tips
function EmailWidget:ShowAttrGoodsTips(goodsID)
	local subInfo = {
		bShowBtnType	= 0, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
		ScrTrans = self.transform,	-- 源预设
	}
    UIManager.GoodsTooltipsWindow:SetGoodsInfo(goodsID, subInfo )
end

-- 显示附件商品信息tips
function EmailWidget:ShowAppxGoodsTips(entity, goodsID)
	
	if not entity then 
		return
	end
	local entityClass = entity:GetEntityClass()
	if EntityClass:IsEquipment(entityClass) then
        local subInfo = {
        	bShowBtn		= 0,
        }
		UIManager.EquipTooltipsWindow:Show(true)
        UIManager.EquipTooltipsWindow:SetEntity(entity, subInfo)
	else
		local subInfo = {
			bShowBtnType	= 0, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
		}
		UIManager.GoodsTooltipsWindow:Show(true)
        UIManager.GoodsTooltipsWindow:SetGoodsInfo(goodsID, subInfo )
	end
	
end

-- 删除按钮事件
function EmailWidget:OnBtnRmvAllClicked()
	if #self.m_EmailList < 1 or not self.m_MailPart:IsHasNotPlusEmail() then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "没有可删除的邮件！")
		return
	end
	
	local data = {
		content = "一键删除将清空所有邮件（有附件的邮件不会清除），是否确认？",
		confirmCallBack = function ()
			self.m_MailPart:RemoveAllMailQequest()
		end
	}
	UIManager.ConfirmPopWindow:ShowDiglog(data)
end

--读取一封邮件
function EmailWidget:PostReadMailRequest(nMailID)
	self.m_MailPart:ReadMailQequest(nMailID)
end


-- 获取删除按钮事件
function EmailWidget:OnBtnGetRmvClicked()
	
	local data = self.m_EmailList[self.m_SelEmailIdx]
	
	if data == nil then
		self.m_SelEmailIdx = 0
		return
	end
	
	if data.bHasPlusData then
		self.m_MailPart:TakePlusQequest(data.nMailID)
	else
		self.m_MailPart:RemoveMailQequest(data.nMailID)
	end
	
end

--/ purpose: 更新一封邮件，没有则添加
--@ param  : SMailData结构指针
function EmailWidget:UpdateMail()
	if not self:isShow() then
		return
	end

	self:SetSelEmailDesc(self.m_SelEmailIdx)
end

function EmailWidget:ResetEmailDesc()
	
	local controls = self.Controls
	controls.m_ContentTxt.gameObject:SetActive(false)
	controls.m_ContentTxt.text = ""
	controls.m_ContentTxt.gameObject:SetActive(true)
	controls.m_SenderTxt.text = ""
	controls.m_DateTxt.text = ""

	self.Controls.m_GetRmvBtn.gameObject:SetActive(false)
		
	for i,v in ipairs(self.m_AppxItem1s) do
		v.gameObject:SetActive(false)
	end
	
end

function EmailWidget:OnNotify()
	if not self:isShow() then
		return
	end

	UIManager.FriendEmailWindow:RefreshRedDot()
end

-- 获取icon路径
function EmailWidget:GetIconBgPath(nQuality, nAdditionalPropNum)
	if  nQuality == 2 then
		if nAdditionalPropNum <= 4 then 
			nAdditionalPropNum = 4
		else 
			nAdditionalPropNum = 5
		end
	elseif nQuality == 3 then 
		if nAdditionalPropNum <= 5 then 
			nAdditionalPropNum = 5
		else 
			nAdditionalPropNum = 6
		end
	elseif nQuality == 4 then
		if nAdditionalPropNum <= 6 then 
			nAdditionalPropNum = 6
		else 
			nAdditionalPropNum = 7
		end	 
	end
	
	if nQuality == 1 then 
		imageBgPath = AssetPath_EquipColor[nQuality]
	else 
		imageBgPath = AssetPath_EquipColor[nQuality.."_"..nAdditionalPropNum]
	end
	
	return imageBgPath
end

return EmailWidget