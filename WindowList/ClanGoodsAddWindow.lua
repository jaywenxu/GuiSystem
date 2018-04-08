
--/******************************************************************
---** 文件名:	AddClanGoodsWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-02-22
--** 版  本:	1.0
--** 描  述:	补充物资窗口
--** 应  用:  
--******************************************************************/


local ClanGoodsAddWindow = UIWindow:new
{
	windowName = "ClanGoodsAddWindow",
	m_CurTimes = 0,
	m_MaxTimes = 0,
	m_LimitTimes = 0,
	m_UnitPrice = 0,
}

function ClanGoodsAddWindow:OnAttach(obj)
	UIWindow.OnAttach(self, obj)
	
	local controls = self.Controls
	controls.m_SubBtn.onClick:AddListener(handler(self, self.OnSubBtnClicked))
	controls.m_AddBtn.onClick:AddListener(handler(self, self.OnAddBtnClicked))
	controls.m_Cancle.onClick:AddListener(handler(self, self.OnCancleBtnClicked))
	controls.m_OK.onClick:AddListener(handler(self, self.OnOKBtnClicked))
	controls.m_Input.onClick:AddListener(handler(self, self.OnInputClick))
	
	self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable)) 

	self:SubscribeEvt()
	
	self:InitData()
	
end

function ClanGoodsAddWindow:SetContent()
	
	local controls = self.Controls

	local nCost = self.m_CurTimes * self.m_UnitPrice
	
	controls.m_MaxTimes.text   = tostring(self.m_MaxTimes)
	controls.m_CostValue.text  = tostring(nCost)
	controls.m_InputValue.text = tostring(self.m_CurTimes)
	
	--TODO: 按钮置灰
	local gameObj = controls.m_SubBtn.gameObject
	local bGray = self.m_CurTimes <= 0
	UIFunction.SetImgComsGray(gameObj , bGray)
	UIFunction.SetButtonClickState(gameObj,not bGray)	

	gameObj = controls.m_AddBtn.gameObject
	bGray = self.m_CurTimes >= self.m_MaxTimes
	UIFunction.SetImgComsGray(gameObj , bGray)
	UIFunction.SetButtonClickState(gameObj, not bGray)	 
	
end

function ClanGoodsAddWindow:InitData()
	
	self:SetContent()
	GameHelp.PostSocialRequest("RequestClanTrans_ConfirmAddGoods()")
end

function ClanGoodsAddWindow:SubscribeEvt()
	
	-- 补充物资信息
	rktEventEngine.SubscribeExecute(EVENT_CLAN_TRANS_ADDGOODS_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.UpdateGoodsInfo , self )	
	
	-- 押运数据更新
	rktEventEngine.SubscribeExecute(EVENT_CLAN_TRANS_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.UpdateGoodsNum , self )	
end

function ClanGoodsAddWindow:UnSubscribeEvt()
	
	rktEventEngine.UnSubscribeExecute(EVENT_CLAN_TRANS_ADDGOODS_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.UpdateGoodsInfo , self )
	
	rktEventEngine.UnSubscribeExecute(EVENT_CLAN_TRANS_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.UpdateGoodsNum , self )
end

-- 物资信息更新
function ClanGoodsAddWindow:UpdateGoodsInfo(_, _, _, eventData)
	
	self.m_LimitTimes = eventData.nMaxAddNum
	self.m_MaxTimes = self.m_LimitTimes - eventData.nGoodsNum
	self.m_CurTimes = self.m_MaxTimes
	
	self.m_UnitPrice = eventData.nGoodsUnitPrice
	
	self:SetContent()
end

-- 物资数量更新
function ClanGoodsAddWindow:UpdateGoodsNum(_, _, _, eventData)
	if 0 == self.m_MaxTimes then
		return
	end
	
	self.m_MaxTimes = self.m_LimitTimes - eventData.GoodsNum
	if self.m_MaxTimes >= self.m_CurTimes then
		return		
	end
	
	self.m_CurTimes = self.m_MaxTimes
	self:SetContent()
end

function ClanGoodsAddWindow:OnEnable()
	self:InitData()
end

function ClanGoodsAddWindow:OnSubBtnClicked()
	local nNum = self.m_CurTimes
	if nNum <= 0 then
		return
	end
	
	nNum = nNum - 1
	self.m_CurTimes = nNum
	self:SetContent()
end

function ClanGoodsAddWindow:OnAddBtnClicked()
	local nNum = self.m_CurTimes
	if nNum >= self.m_MaxTimes then
		return
	end
	
	nNum = nNum + 1
	self.m_CurTimes = nNum
	self:SetContent()
end

function ClanGoodsAddWindow:OnCancleBtnClicked()
	self:Hide()
end

function ClanGoodsAddWindow:OnOKBtnClicked()
	GameHelp.PostServerRequest("RequestClanTrans_AddGoods("..self.m_CurTimes..")")
	self:Hide()
end

function ClanGoodsAddWindow:OnInputClick()
	
	if self.m_MaxTimes <= 0 then
		return
	end
	
	local txt = self.Controls.m_InputValue
	
	local numTable = {
	    ["inputNum"] = tonumber(txt.text),
		["minNum"]   = 0,
		["maxNum"]   = self.m_MaxTimes, 
		["bLimitExchange"] = 0
	}
	local otherInfoTable = {
		["inputTransform"] = txt.transform,
	    ["bDefaultPos"] = 1,
	    ["callback_UpdateNum"] = function (num)
			self.m_CurTimes = tonumber(num)
			self:SetContent()
	    end
	}
	UIManager.NumericKeypadWindow:ShowWindow(numTable, otherInfoTable) -- 打开小键盘
end

function ClanGoodsAddWindow:Show(bringTop)
	
	UIWindow.Show(self, bringTop)
end

function ClanGoodsAddWindow:OnDestroy()
	
	self:UnSubscribeEvt()
end

return ClanGoodsAddWindow



