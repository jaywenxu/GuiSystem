-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    zjc
-- 日  期:    2017-05-04
-- 描  述:    花费
-------------------------------------------------------------------


------------------------------------------------------------
local ChipExpenseInfo = UIControl:new
{
	windowName 	= "ChipExpenseInfo",
	
	------------------------------------------------------------
	-- 暂时只支持货币
	------------------------------------------------------------
	m_nType		= 0,				-- 货币类型
	m_price		= 0,				-- 单价
	m_nGoodsID	= 0,				-- 是否有物品id
	m_nCount	= 0,				-- 购买的数量
	m_index     = 0,                -- 记录item的索引
	m_Enough	= true,
}

local ConsumeTypeName = {
	"物品",
	"银两",
	"钻石",
	"银币",
	"经验",
	"战功",
	"侠义度",
	"声望",
	"竞技积分",
	"论剑积分",
	"帮会工资",
}

local this = ChipExpenseInfo
------------------------------------------------------------

function ChipExpenseInfo:Init()
	self:CallBackInit()
end

-------------------------------------------------------------------
-- 设置Icon	
-------------------------------------------------------------------
function ChipExpenseInfo:Attach(obj)
	UIControl.Attach(self,obj)
	
	-- 数量+ 按钮事件
	self.callback_AddBtnClick = function() self:OnAddButtonClick() end
	self.Controls.m_Button_Add.onClick:AddListener(self.callback_AddBtnClick)
	
	-- 数量- 按钮事件
	self.callback_SubBtnClick = function() self:OnSubButtonClick() end
	self.Controls.m_Button_Sub.onClick:AddListener(self.callback_SubBtnClick)
	
	-- 获得- 按钮事件
	self.callback_SubBtnClick = function() self:OnAddBtnClick() end
	self.Controls.m_AddBtnHave.onClick:AddListener(self.callback_SubBtnClick)
	
	
	-- 兑换按钮事件
	self.callback_Trade = function() self:OnTradeBtnClick() end
	self.Controls.m_Button_Trade = self.Controls.m_Trade:GetComponent(typeof(ColdButton))
	self.Controls.m_Button_Trade.onClick:AddListener(self.callback_Trade)
	
	-- 当InputField值被改变时
	self.callback_OnValueChange = function() self:OnValueChanged() end
	self.Controls.m_Input_Value:GetComponent(typeof(InputField)).onValueChanged:AddListener(self.callback_OnValueChange)
	--self.Controls.m_Input_Value:GetComponent(typeof(InputField))
	-- 初始化
	self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text  = tostring(self.m_DefaultCount)
	
	-- 打开输入界面按钮事件
	self.callback_InputBtnClick = function() self:OnInputButtonClick() end
	self.Controls.m_InputButton.onClick:AddListener(self.callback_InputBtnClick)
	self.callback_UpdateNum = function(num) self:UpdateNum(num) end
	self:SubscribeEvent()
	return self
end

-------------------------------------------------------------------
-- 销毁窗口
-------------------------------------------------------------------
function ChipExpenseInfo:OnDestroy()
	self:UnSubscribeEvent()
	UIWindow.OnDestroy(self)
end

-------------------------------------------------------------------
-- 所有归零
-------------------------------------------------------------------
function ChipExpenseInfo:Clean()
	
	self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text  = 0
	self.Controls.m_Text_Consume.text = 0
	self.m_nType		= 0				-- 货币类型
	self.m_price		= 0				-- 单价
	self.m_nGoodsID		= 0				-- 是否有物品id
	self.m_nCount		= 0				-- 购买的数量
end

-------------------------------------------------------------------
-- 设置消费物品的图标
function ChipExpenseInfo:SetStuffItemIcon(szIconPath)
	UIFunction.SetImageSprite(self.Controls.m_Image_Expense, szIconPath)
	UIFunction.SetImageSprite(self.Controls.m_Image_Own, szIconPath)
end

-- 设置当前物品的货币类型及单价信息
function ChipExpenseInfo:SetChipStuff(tStuff)
	
	if not tStuff or not tStuff.nType or not tStuff.nValue then
		return
	end
	self.m_nType = tStuff.nType
	self.m_price = tStuff.nValue
	
	if 1 == self.m_nType then   		-- 物品
		self.m_nGoodsID = tStuff.nGoodsID
	end
	
	local szIconPath = GameHelp:GetCurrencyIcon(tStuff.nType, tStuff.nGoodsID)
	if not IsNilOrEmpty(szIconPath) then
		self:SetStuffItemIcon(szIconPath)
	end
end

-------------------------------------------------------------------
-- 设置默认购买数量
-------------------------------------------------------------------
function ChipExpenseInfo:UpdateExchangeCount()
	self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text  = tostring(self.m_nCount)
end

-- 角色当前的物品数量
function ChipExpenseInfo:GetOwnStuffData()
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return 0
	end
	local pRecordPart = IGame.EntityClient:GetHeroEntityPart(ENTITYPART_PERSON_RECORD)
	if not pRecordPart then
		return 0
	end
    --if self.m_index == 0 then
	--	self.m_index = 1
	--end

	--local bUseUnBind = IGame.ChipExchangeClient:GetuseUnBindByIndex(self.m_index)
	local nType = self.m_nType
	local nValue = 0
	if 1 == nType then   		-- 物品
	    local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
		if packetPart and packetPart:IsLoad() then
			nValue = packetPart:GetGoodNum(self.m_nGoodsID)
		end
	elseif 2 == nType then 		-- 银两
		nValue = pHero:GetYinLiangNum()	
	elseif 3 == nType then 		-- 钻石
		nValue = pHero:GetActorYuanBao()			
	elseif 4 == nType then		-- 银币
		nValue = pHero:GetYinBiNum()
	elseif 5 == nType then 		-- 经验
	    nValue = pHero:GetNumProp(CREATURE_PROP_EXP)
	elseif 6 == nType then 		-- 战功	
		nValue = pRecordPart:GetRecordValue(ERecordSubID_ZhanGong)
	elseif 7 == nType then      -- 侠义度
		nValue = pRecordPart:GetRecordValue(ERecordSubID_XiaYi)
	elseif 8 == nType then      -- 声望
		nValue = pRecordPart:GetRecordValue(ERecordSubID_ShengWang)
	elseif 9 == nType then      -- 竞技积分
		nValue = pRecordPart:GetRecordValue(ERecordSubID_JingJi)	
	elseif 10 == nType then     -- 论剑积分
		nValue = pRecordPart:GetRecordValue(ERecordSubID_LunJian)
	elseif 11 == nType then     -- 帮会工资
		 nValue = pRecordPart:GetRecordValue(ERecordSubID_ClanSalary)
	end	
	return nValue
end

-------------------------------------------------------------------
-- 设置 拥有 数据
-- @param  nType : 要显示的货币类型  
-------------------------------------------------------------------
function ChipExpenseInfo:UpdateOwnInfoData()
	local nValue = self:GetOwnStuffData()
	self:SetExpenseOwnData(nValue)
end

--　拥有数量
function ChipExpenseInfo:SetExpenseOwnData(nValue)
	
	local nTotalValue = tonumber(self.m_price) * tonumber(self.m_nCount)
		-- 金额超出拥有数量则显示红色
	if nTotalValue > nValue then 
		self.Controls.m_Text_Total.text = "<color=#e4595a>" .. tostring(nValue) .. "</color>"
		self.m_Enough = false
	else
		self.Controls.m_Text_Total.text =tostring(nValue)
		self.m_Enough = true
	end
end

-- 刷新购买的物品信息，数量*单价
function ChipExpenseInfo:UpdateExchangeInfo()
	if not self.m_price or not self.m_nCount then
		return 
	end
	local ZeKou = GameHelp:GetChipDaZhe(self.m_nType)
	local nTotalValue = tonumber(self.m_price) * tonumber(self.m_nCount) * ZeKou
	local nValue = self:GetOwnStuffData()
	-- 特殊处理,银两不足时显示
	if self.m_nType == 4 then
		if self:UpdateSpecialExchangeInfo(nTotalValue) then
			return
		end
	end
	self.Controls.m_Text_Consume.text = tostring(nTotalValue)
	self:UpdateOwnInfoData()
end

-- 特殊处理一下，银币不足使用银两购买
function ChipExpenseInfo:UpdateSpecialExchangeInfo(nTotalValue)
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return false
	end
	local yinliang = pHero:GetYinLiangNum()
    local yinbi = pHero:GetYinBiNum()
    self.Controls.m_Text_Consume.text = tostring(nTotalValue)
	if yinbi < nTotalValue and yinliang >= nTotalValue then
		local szIconPath = GameHelp:GetCurrencyIcon(2, 0)
		if not IsNilOrEmpty(szIconPath) then
			self:SetStuffItemIcon(szIconPath)
		end
		self:SetExpenseOwnData(yinliang)
	else
		local szIconPath = GameHelp:GetCurrencyIcon(4, 0)
		if not IsNilOrEmpty(szIconPath) then
			self:SetStuffItemIcon(szIconPath)
		end
		self:SetExpenseOwnData(yinbi)
		return false
	end
    return true
end
-------------------------------------------------------------------
-- 刷新购买数量信息\单价
-------------------------------------------------------------------
function ChipExpenseInfo:UpdateExpenseInfo()
	if not self:isLoaded() then
		return
	end
	self:UpdateOwnInfoData()
	self:UpdateExchangeCount()
	self:UpdateExchangeInfo()
	self:UpdateButtonStatus()
end

function ChipExpenseInfo:UpdateExpenseChangedInfo()
	self:UpdateExchangeCount()
	self:UpdateExchangeInfo()
end

function ChipExpenseInfo:SetExchangeIndex(index)
	self.m_index = index
end

function ChipExpenseInfo:isLoaded()
	return self.transform ~= nil
end

-------------------------------------------------------------------
-- 更新兑换消费信息等
-------------------------------------------------------------------
function ChipExpenseInfo:UpdateExchangeExpenseInfo(index)
	if not self:isLoaded() then
		return
	end
	-- 清除消耗
	self:Clean()
	
	local defaultNum = IGame.ChipExchangeClient:GetDefaultNumByIndex(index)
	local tStuff = IGame.ChipExchangeClient:GetChipGoodsStuff(index)
	
	if not tStuff  then
		return
	end
	
    if defaultNum == 0 then 
		defaultNum = 1
	end
	self.m_index = index
	self.m_nCount = tonumber(defaultNum)
	self:SetChipStuff(tStuff)
	-- 刷新消耗
	self:UpdateExpenseInfo()
	local nExchMaxNum = IGame.ChipExchangeClient:GetExchMaxNumByIndex(index)
	if nExchMaxNum > 0 then
		self:SetTradeBtnGrayState(false)
	else
		self:SetTradeBtnGrayState(true)
	end
	return true
end


-------------------------------------------------------------------
-- 设置购买数量
-------------------------------------------------------------------
function ChipExpenseInfo:SetExchangeBuyCount(nNum)
	
	self.m_nCount = tonumber(nNum)
end

-- 控件修改变化
function ChipExpenseInfo:OnValueChanged()
	
	local nCount = self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text or 1
	self:SetExchangeBuyCount(nCount)
	-- 刷新消耗
	self:UpdateExpenseChangedInfo()
end

-------------------------------------------------------------------
-- 点击增加数量按钮	
-------------------------------------------------------------------
function ChipExpenseInfo:OnAddButtonClick()
	
	local nCount = self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text or 1
	local nExchMaxNum = IGame.ChipExchangeClient:GetExchMaxNumByIndex(self.m_index)
	nCount = tonumber(nCount) + 1
	if nCount > 1 then
		UIFunction.SetImgComsGray(self.Controls.m_Button_Sub.gameObject, false)
		self.Controls.m_Button_Sub.interactable = true
	end
	if nCount >= nExchMaxNum then
		if nExchMaxNum == 0 then 
			nExchMaxNum = 1
		end
		nCount = nExchMaxNum
        UIFunction.SetImgComsGray(self.Controls.m_Button_Add.gameObject,true)
		self.Controls.m_Button_Add.interactable = false
	else 
		UIFunction.SetImgComsGray(self.Controls.m_Button_Add.gameObject,false)
		self.Controls.m_Button_Add.interactable = true		
	end
	self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text = tostring(nCount)
end

-------------------------------------------------------------------
-- 点击减少数量按钮	
-------------------------------------------------------------------
function ChipExpenseInfo:OnSubButtonClick()	
	
	local nCount = self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text or 1
	local nNewCount = tonumber(nCount) - 1
	local nExchMaxNum = IGame.ChipExchangeClient:GetExchMaxNumByIndex(self.m_index)
	if nNewCount < nExchMaxNum then
		UIFunction.SetImgComsGray(self.Controls.m_Button_Add.gameObject,false)
		self.Controls.m_Button_Add.interactable = true 
	end
	
	-- 至少保留一个
	if nNewCount <= 1 then
		nNewCount = 1
		UIFunction.SetImgComsGray(self.Controls.m_Button_Sub.gameObject, true)
		self.Controls.m_Button_Sub.interactable = false
	else 
		UIFunction.SetImgComsGray(self.Controls.m_Button_Sub.gameObject, false)
		self.Controls.m_Button_Sub.interactable = true				
	end
	
	
	self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text = tostring(nNewCount)
end

--点击增加物品按钮
function ChipExpenseInfo:OnAddBtnClick()
	local nType = self.m_nType
	local nGoodID = 0
	if 1 == nType then
		nGoodID = self.m_nGoodsID
	elseif 2 == nType then 		-- 银两
		UIManager.ShopWindow:OpenShop(2415)
		return
	elseif 3 == nType then 		-- 钻石
		UIManager.ShopWindow:ShowShopWindow(UIManager.ShopWindow.tabName.emDeposit)
		return
	elseif 4 == nType then		-- 银币
		UIManager.ShopWindow:OpenShop(2415)
		return
	elseif 5 == nType then 		-- 经验
	    nGoodID = 9001
	elseif 6 == nType then 		-- 战功	
	    nGoodID = 9010
	elseif 7 == nType then      -- 侠义度
	    nGoodID = 9017
	elseif 8 == nType then      -- 声望
	    nGoodID = 9018
	elseif 9 == nType then      -- 竞技积分
	    nGoodID = 9019
	elseif 10 == nType then     -- 论剑积分
	    nGoodID = 9020
	elseif 11 == nType then     -- 帮会工资
	    nGoodID = 9016
	end	
	
	if self.m_GoodsID ~= 0 then
		local subInfo = {
			bShowBtnType	= 2, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
			--ScrTrans = self.transform,	-- 源预设
		}
		UIManager.GoodsTooltipsWindow:SetGoodsInfo(nGoodID, subInfo )
	end
end

-------------------------------------------------------------------
-- 获取 是否绑定
-------------------------------------------------------------------	
function ChipExpenseInfo:GetuseUnBind()
	return IGame.ChipExchangeClient:GetuseUnBindByIndex(self.m_index)
end
-------------------------------------------------------------------
-- 获取 奖励id
-------------------------------------------------------------------		
function ChipExpenseInfo:GetPrizeid()
	
	return IGame.ChipExchangeClient:GetPrizeidByIndex(self.m_index)
end 
	
-------------------------------------------------------------------
-- 点击兑换按钮
-------------------------------------------------------------------
function ChipExpenseInfo:OnTradeBtnClick()
	--self:SetHintVisible(true)
	local npcID		= self.m_ChipExchangeWidget:GetCurExchangeNpcID()
	local exchID 	= IGame.ChipExchangeClient:GetExchidByIndex(self.m_index)
	-- 物品品阶
	local prizeid   = self:GetPrizeid()
	-- 是否只允许非绑资源
	local useUnBind = self:GetuseUnBind()
	local num 		= self:GetInputFieldNum()
	
	if 0 == num then 
		return 
	end
	local nType, nValue = IGame.ChipExchangeClient:GetGoodsStuffByIndex(self.m_selectItemIndex)

    if nType == 4 then 
		local totalNum = num * nValue
		local pHero = IGame.EntityClient:GetHero()
		if not pHero then
			return
		end
		local nYinBiNum = pHero:GetYinBiNum()
		local nYinLiangNum = pHero:GetYinLiangNum()
		if nYinBiNum < totalNum then
			if nYinLiangNum < totalNum then 
                IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "银币和银两不足，无法购买")
			else 
				self.Controls.m_ChipConfirmWidget.gameObject:SetActive(true)
			end
		else
			GameHelp.PostServerRequest("RequestChipExchange("..exchID..","..prizeid..","..num..","..useUnBind..","..npcID..","..npcID..")")
		end
	else
        local szTips = ConsumeTypeName[self.m_nType]
		if not self.m_Enough and szTips then
            if self.m_nType == 1 then
                local pGoodsInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, self.m_nGoodsID)
                if nil ~= pGoodsInfo then
                    szTips = pGoodsInfo.szName
                end  
            end
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, szTips.."不足，无法购买")
			return
		end
		GameHelp.PostServerRequest("RequestChipExchange("..exchID..","..prizeid..","..num..","..useUnBind..","..npcID..","..npcID..")")
	end
	
end
function ChipExpenseInfo:UpdateButtonStatus()
	local nExchMaxNum = IGame.ChipExchangeClient:GetExchMaxNumByIndex(self.m_index)
	if nExchMaxNum <= 1 then
		UIFunction.SetImgComsGray(self.Controls.m_Button_Add.gameObject, true)
	    self.Controls.m_Button_Add.interactable = false 
	else 
	    UIFunction.SetImgComsGray(self.Controls.m_Button_Add.gameObject,false)
	    self.Controls.m_Button_Add.interactable = true
	end

	
	UIFunction.SetImgComsGray(self.Controls.m_Button_Sub.gameObject, true)
	self.Controls.m_Button_Sub.interactable = false
end

-------------------------------------------------------------------
-- 获取输入框的值	
-------------------------------------------------------------------
function ChipExpenseInfo:GetInputFieldNum()
	local num = self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text
	if nil == num then 
		return 0
	end
	
	return tonumber(num)
end	

-- 点击输入按钮，响应打开输入数字界面
function ChipExpenseInfo:OnInputButtonClick() 
	local exchMaxNum = IGame.ChipExchangeClient:GetExchMaxNumByIndex(self.m_index)
	local nLimitExchange = IGame.ChipExchangeClient:isLimitExchange(self.m_index)
	local num = self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text
	local numTable = {
	    ["inputNum"] = num,
		["minNum"]   = 1,
		["maxNum"]   = exchMaxNum, 
		["bLimitExchange"] = nLimitExchange
	}
	local otherInfoTable = {
		["inputTransform"] =  self.Controls.m_InputButtonBg,
	    ["bDefaultPos"] = 0,
	    ["callback_UpdateNum"] = self.callback_UpdateNum
	}
	
	UIManager.NumericKeypadWindow:ShowWindow(numTable, otherInfoTable)
end

function ChipExpenseInfo:UpdateNum(num)
	local nExchMaxNum = IGame.ChipExchangeClient:GetExchMaxNumByIndex(self.m_index)
	if num > 1 then
		UIFunction.SetImgComsGray(self.Controls.m_Button_Sub.gameObject, false)
		self.Controls.m_Button_Sub.interactable = true
	else 
	    UIFunction.SetImgComsGray(self.Controls.m_Button_Sub.gameObject, true)
		self.Controls.m_Button_Sub.interactable = false
	end
	if num >= nExchMaxNum then
		if nExchMaxNum == 0 then 
			nExchMaxNum = 1
		end

        UIFunction.SetImgComsGray(self.Controls.m_Button_Add.gameObject,true)
		self.Controls.m_Button_Add.interactable = false
	else 
		UIFunction.SetImgComsGray(self.Controls.m_Button_Add.gameObject,false)
		self.Controls.m_Button_Add.interactable = true		
	end
	self.Controls.m_Input_Value:GetComponent(typeof(InputField)).text = num
end

function ChipExpenseInfo:SetTradeBtnGrayState(on)
	if not self:isLoaded() then
		return
	end
	UIFunction.SetImgComsGray(self.Controls.m_Button_Trade.gameObject,on)
	self.Controls.m_Button_Trade.interactable = not on
end

-- 更新货币数值
function ChipExpenseInfo:RefreshRecordData(eventData)
	self:UpdateExpenseInfo()
end


function ChipExpenseInfo:CallBackInit()
	self.callback_OnCurrencyUpdate  = function() self:UpdateOwnInfoData() end
	self.callBackRefreshRecordData = function(event, srctype, srcid, eventData) self:RefreshRecordData(eventData) end
end

function ChipExpenseInfo:SubscribeEvent()
    rktEventEngine.SubscribeExecute( EVENT_CION_YUANBAO , SOURCE_TYPE_COIN ,  0, self.callback_OnCurrencyUpdate)
	rktEventEngine.SubscribeExecute( EVENT_CION_YINLIANG , SOURCE_TYPE_COIN , 0 , self.callback_OnCurrencyUpdate)
	rktEventEngine.SubscribeExecute( EVENT_CION_YINBI , SOURCE_TYPE_COIN , 0 , self.callback_OnCurrencyUpdate)
	rktEventEngine.SubscribeExecute( EVENT_SYNC_PERSON_RECORD_DATA,SOURCE_TYPE_PERSON,0,self.callBackRefreshRecordData)
end

function ChipExpenseInfo:UnSubscribeEvent()
	rktEventEngine.UnSubscribeExecute( EVENT_CION_YUANBAO , SOURCE_TYPE_COIN , 0, self.callback_OnCurrencyUpdate)
	rktEventEngine.UnSubscribeExecute( EVENT_CION_YINLIANG , SOURCE_TYPE_COIN , 0 , self.callback_OnCurrencyUpdate)
	rktEventEngine.UnSubscribeExecute( EVENT_CION_YINBI , SOURCE_TYPE_COIN , 0 , self.callback_OnCurrencyUpdate)
	rktEventEngine.UnSubscribeExecute( EVENT_SYNC_PERSON_RECORD_DATA,SOURCE_TYPE_PERSON,0,self.callBackRefreshRecordData)
end



return this



