
--******************************************************************
--** 文件名:	DailySignInWdt.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	herder
--** 日  期:	2017-7-31
--** 版  本:	1.0
--** 描  述:	每日签到
--** 应  用:  
--******************************************************************

require("Client.WelfareClient.WelfareClientDef")

local DailySignInWdt = UIControl:new
{
	windowName = "DailySignInWdt",
	m_DSClient = nil,
}

function DailySignInWdt:Attach(obj)
	UIControl.Attach(self, obj)
	self:InitData()
	
	self:InitUI()
	
	self:SubscribeEvts()	
	
	self:SetBottomInfo()
end

function DailySignInWdt:InitUI()
	local maxDay = self.m_DSClient:GetSignInDataCnt()
	if maxDay < 1 then
		maxDay = 31
	end
	
	for i=1, 31 do
		local cellObj = self.Controls.m_Grid.transform:Find("Cell (".. tostring(i-1) ..")").gameObject
		local btnObj = cellObj.transform:Find("Button"):GetComponent(typeof(Button))
		btnObj.onClick:AddListener(function(on) self:OnSignIn(i, on) end)
		if i <= maxDay then
			cellObj:SetActive(true)
		else
			cellObj:SetActive(false)
		end
	end
	--self.Controls.m_DecButton.onClick:AddListener(function(on) self:OnDecButton() end)
end

function DailySignInWdt:Show()
	UIControl.Show(self)
	
	-- 设置一下位置
	local today = self.m_DSClient:GetToday()
	if today > 18 then
		local obj = self.Controls.m_Rect.gameObject:GetComponent("ScrollRect")
		obj.verticalNormalizedPosition = 0
	end
end

function DailySignInWdt:SetBottomInfo()
	local accCnt = self.m_DSClient.m_signInCnt
	local surplusTimes = self.m_DSClient.m_remainTimes
	local controls = self.Controls
	controls.m_AccCnt.text = "<color=#AF4131>" .. accCnt .."</color>天"
	controls.m_SurplusTimes.text = "<color=#AF4131>" .. surplusTimes.."</color>次"
end

function DailySignInWdt:InitData()
	GameHelp.PostServerRequest("RequestDailySignInData()")
	self.m_DSClient = IGame.WelfareClient:GetDailySignInClient()
end

function DailySignInWdt:SubscribeEvts()
	self.m_UpdateDateCB = function (_, _, _, evtData) self:OnUpdateDateEvt(evtData) end
	rktEventEngine.SubscribeExecute( EVENT_UPDATE_DAILYSIGNIN_DATA , SOURCE_TYPE_WELFARE, 0, self.m_UpdateDateCB )
end

function DailySignInWdt:UnSubscribeEvts()
	rktEventEngine.UnSubscribeExecute( EVENT_UPDATE_DAILYSIGNIN_DATA , SOURCE_TYPE_WELFARE, 0, self.m_UpdateDateCB )
	self.m_UpdateDateCB = nil
end

function DailySignInWdt:OnDecButton()
	UIManager.CommonGuideWindow:ShowWindow(26)
end

function DailySignInWdt:OnUpdateDateEvt()
	self.m_DSClient = IGame.WelfareClient:GetDailySignInClient()	
	local maxDay = self.m_DSClient:GetSignInDataCnt()
	for i=1, maxDay do
		local cellObj = self.Controls.m_Grid.transform:Find("Cell (".. tostring(i-1) ..")").gameObject
		cellObj:SetActive(true)
		self:SetCellData(i)
	end
	for i=maxDay+1, 31 do
		local cellObj = self.Controls.m_Grid.transform:Find("Cell (".. tostring(i-1) ..")").gameObject
		cellObj:SetActive(false)
	end
	-- 日期位置
	self:Show()
	
	self:SetBottomInfo()
end

function DailySignInWdt:SetCellData(idx)
	local cellData = self.m_DSClient:GetSignInDataObj(idx)
	if cellData == nil then
		uerror("[DailySignInWdt:SetCellData] cellData == nil")
		return
	end
	local cellObj = self.Controls.m_Grid.transform:Find("Cell (".. tostring(idx-1) ..")").gameObject
	local controls = {}
	local imageObj = cellObj.transform:Find("Button/GameObject/Image").gameObject
	controls.m_Cnt = cellObj.transform:Find("Button/GameObject/Cnt_text"):GetComponent(typeof(Text))
	controls.m_Frame = imageObj.transform:Find("Frame"):GetComponent(typeof(Image))
	controls.m_Icon = imageObj.transform:Find("Icon"):GetComponent(typeof(Image))
	controls.m_Select = imageObj.transform:Find("Select").gameObject
	controls.m_Gou = imageObj.transform:Find("Gou").gameObject
	controls.m_Buqian = imageObj.transform:Find("Buqian").gameObject
	controls.m_Zhezhao = imageObj.transform:Find("Zhezhao").gameObject
	
	local goodsData = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, cellData.reward_id)
	if nil == goodsData then
		print("[DailySignInWdt:SetCellData]物品无法找到！ ID: "..cellData.reward_id)
		return
	end
	
	-- 道具图标
	local IconPath = AssetPath.TextureGUIPath..goodsData.lIconID1
	UIFunction.SetImageSprite(controls.m_Icon, IconPath)
	-- 设置物品的背景框
	local imageBgPath = AssetPath_GoodsColor[tonumber(goodsData.lBaseLevel)]
	UIFunction.SetImageSprite(controls.m_Frame, imageBgPath)
	-- 道具数量
	controls.m_Cnt.text = cellData.reward_num
	
	controls.m_Select.gameObject:SetActive(false)
	controls.m_Gou.gameObject:SetActive(false)
	controls.m_Buqian.gameObject:SetActive(false)
	controls.m_Zhezhao.gameObject:SetActive(false)
	
	if cellData.state == WelfareClientDef.DS_STATE.RESIGN then
		controls.m_Buqian.gameObject:SetActive(true)
		controls.m_Zhezhao.gameObject:SetActive(true)
		return
	elseif cellData.state == WelfareClientDef.DS_STATE.MISSSIGN then
		controls.m_Zhezhao.gameObject:SetActive(true)
		return
	elseif cellData.state == WelfareClientDef.DS_STATE.ALSIGN then
		controls.m_Gou.gameObject:SetActive(true)
		controls.m_Zhezhao.gameObject:SetActive(true)
	end	
	
	--当天六点前都算前一天 
	local today = self.m_DSClient:GetToday()
	if today == idx then
		controls.m_Select.gameObject:SetActive(true)
	end
end

function DailySignInWdt:OnSignIn(day, on)
	local cellData = self.m_DSClient:GetSignInDataObj(day)
	if cellData.state == WelfareClientDef.DS_STATE.RESIGN then
		-- 补签 弹框
		local confirmCallBack = function ( )
			GameHelp.PostServerRequest("RequestSignIn("..day..")")
		end
		local data = 
		{
			content = "是否消耗一次次数补签？",
			confirmCallBack = confirmCallBack,
		}
		UIManager.ConfirmPopWindow:ShowDiglog(data)	
	elseif cellData.state == WelfareClientDef.DS_STATE.CANSIGN then 
		GameHelp.PostServerRequest("RequestSignIn("..day..")")
	else
		-- 不能签到和不能补签的显示tips
		self:ShowRewardTips(day, cellData.reward_id)
	end
end

function DailySignInWdt:ShowRewardTips(day, goodsId)
	local cellTrs = self.Controls.m_Grid.transform:Find("Cell (".. tostring(day-1) ..")").transform
	local subInfo = {
		bShowBtnType	= 0, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
		--ScrTrans = cellTrs,		-- 源预设
		Pos = Vector3.New(-10,72,0),
	}
	UIManager.GoodsTooltipsWindow:SetGoodsInfo(goodsId, subInfo )
end

function DailySignInWdt:OnDestroy()
	self:UnSubscribeEvts()
end

return DailySignInWdt