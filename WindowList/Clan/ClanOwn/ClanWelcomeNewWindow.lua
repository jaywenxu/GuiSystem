-- 帮派欢迎新人界面
-- @Author: XieXiaoMei
-- @Date:   2017-04-18 09:36:19
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-07 09:25:21
local ClanWelcomeNewWindow = UIWindow:new
{
	windowName          = "ClanWelcomeNewWindow",
	
	m_SelGiveTglIdx     = 0,
	m_WelcomDataUpCallBack = nil,
	m_OrationMaxLen     = 0,
}

local DefualtFixedCoin = 1		--默认固定金额
local DefualtMaxCoin   = 10000  --默认最大金额

local GiveCoinTglNamePref     = "m_GiveTgl"		--toggle名称前缀
local GiveCoinTglMarkNamePref = "m_TglMarkImg"  --toggle选中图名称前缀

------------------------------------------------------------
function ClanWelcomeNewWindow:Init()
end

function ClanWelcomeNewWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	self:InitUI()

	self:SubscribeEvts()

	self:UpdateLeftInputCnt()

	self:SetGiveCoinTgls()
end


function ClanWelcomeNewWindow:OnDestroy()
	UIWindow.OnDestroy(self)
	
	self:UnSubscribeEvts()

	table_release(self)
end


function ClanWelcomeNewWindow:Show(bringTop)
	UIWindow.Show(self, bringTop)

	if not self:isLoaded() then
		return
	end

	self:SetGiveCoinTgls()
end

function ClanWelcomeNewWindow:InitUI()
	local controls = self.Controls
	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_ConfirmBtn.onClick:AddListener(handler(self, self.OnBtnConfirmClicked))
	controls.m_FixedInputBtn.onClick:AddListener(handler(self, self.OnBtnFixedInputClicked))
	controls.m_RandInputBtn.onClick:AddListener(handler(self, self.OnBtnRandInputClicked))
	controls.m_BackBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))

 	local inputField = controls.m_OrationInput:GetComponent(typeof(InputField))
	inputField.onValueChanged:AddListener(handler(self, self.UpdateLeftInputCnt))
 	controls.orationInput = inputField

 	self.m_OrationMaxLen = inputField.characterLimit

 	local coinTlgs = {}
 	for i=1, 3 do 
 		local tglName = GiveCoinTglNamePref .. i
 		local tgl = controls[tglName]
		tgl.onValueChanged:AddListener(function (on)
			self:OnGiveCoinTglChanged(i, on)
		end)
		table.insert(coinTlgs, tgl)
	end
	controls.coinTlgs = coinTlgs
end

function ClanWelcomeNewWindow:SubscribeEvts()
	-- 请求帮派列表
	self.m_WelcomDataUpCallBack = handler(self, self.SetGiveCoinTgls)
	rktEventEngine.SubscribeExecute( EVENT_CLAN_WELCOMEDATA_UPDATE, SOURCE_TYPE_CLAN, 0, self.m_WelcomDataUpCallBack )
end

function ClanWelcomeNewWindow:UnSubscribeEvts()
	rktEventEngine.UnSubscribeExecute( EVENT_CLAN_WELCOMEDATA_UPDATE , SOURCE_TYPE_CLAN, 0, self.m_WelcomDataUpCallBack )
	self.m_WelcomDataUpCallBack = nil
end

--设置礼物tgls金额
function ClanWelcomeNewWindow:SetGiveCoinTgls()
	local memberObj = IGame.ClanClient:GetMemberInfo()
	local welcomData = memberObj:GetWelcomeData()
	print("welcomData:",tableToString(welcomData))

	local controls = self.Controls

	controls.orationInput.text = welcomData.szContent

	local flags = {
		welcomData.dwMoney < 1, 	--啥也不给
		welcomData.dwMoney > 0 and not welcomData.bRandom, --固定金额
		welcomData.dwMoney > 0 and welcomData.bRandom, --随机金额
	}

	for i,tgl in ipairs(controls.coinTlgs) do
		tgl.isOn = flags[i]
		self:OnGiveCoinTglChanged(i, flags[i])
	end

	local coin = flags[2] and welcomData.dwMoney or DefualtFixedCoin
	-- controls.fixedCoinInput.text = coin
	controls.m_FixedCoinTxt.text = coin

	coin = flags[3] and welcomData.dwMoney or DefualtMaxCoin
	-- controls.randomCoinInput.text = coin
	controls.m_RandCoinTxt.text = coin
end

-- 迎新礼物toggle按下回调
function ClanWelcomeNewWindow:OnGiveCoinTglChanged(idx, on)
	print(tostring(idx), tostring(on))

	local markName = GiveCoinTglMarkNamePref .. idx
	local tglMarkImg = self.Controls[markName]
	tglMarkImg.enabled = on

	if on then
		self.m_SelGiveTglIdx = idx
	end
end

-- 更新剩余输入字数
function ClanWelcomeNewWindow:UpdateLeftInputCnt()
	local controls = self.Controls
	local inputLen = controls.orationInput:GetInputWordsLength()
	local leftLen = self.m_OrationMaxLen - inputLen
	controls.m_OrationLeftTxt.text = string.format("还可编辑%d字",  math.floor(leftLen * 0.5)) 
end

-- 关闭按钮事件回调
function ClanWelcomeNewWindow:OnBtnCloseClicked()
	self:Hide()
end

function ClanWelcomeNewWindow:OnBtnFixedInputClicked()
	local txt = self.Controls.m_FixedCoinTxt
	self:OpenNumericKeypad(txt)
end

function ClanWelcomeNewWindow:OnBtnRandInputClicked()
	local txt = self.Controls.m_RandCoinTxt
	
	self:OpenNumericKeypad(txt)
end

-- 打开小键盘
function ClanWelcomeNewWindow:OpenNumericKeypad(txtCom)
	local numTable = {
	    ["inputNum"] = tonumber(txtCom.text),
		["minNum"]   = DefualtFixedCoin,
		["maxNum"]   = DefualtMaxCoin, 
		["bLimitExchange"] = 0
	}
	local otherInfoTable = {
		["inputTransform"] = txtCom.transform,
	    ["bDefaultPos"] = 0,
	    ["callback_UpdateNum"] = function (num)
	    	txtCom.text = num
	    end
	}
	UIManager.NumericKeypadWindow:ShowWindow(numTable, otherInfoTable) 
end

-- 确定按钮事件回调
function ClanWelcomeNewWindow:OnBtnConfirmClicked()

	local IsInputCoinsValid = function (txtCom) --检查输入金额是否有效
		local coin = tonumber(txtCom.text)
		local s = ""
		if coin < 1 then
			s = "迎新礼物最少给1银两"
		elseif coin > DefualtMaxCoin then
			s = "迎新礼物最多给10000银两"
		else
			return true, coin
		end

		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, s)
		return false, coin
	end

	local controls = self.Controls
	local idx = self.m_SelGiveTglIdx
	local coin = 0
	local bRandomCoin = false
	local bInputValid = true

	if idx == 1 then
		coin = 0
	elseif idx == 2 then
		bInputValid, coin = IsInputCoinsValid(controls.m_FixedCoinTxt)
	elseif idx == 3 then
		bInputValid, coin = IsInputCoinsValid(controls.m_RandCoinTxt)
		bRandomCoin = true
	end

	if not bInputValid then
		return
	end

	print("coin:", coin, " isRandom:", tostring(bRandomCoin))

	local orationTxt = controls.orationInput.text
	IGame.ClanClient:SetWelcomeRequest(orationTxt, coin, bRandomCoin)
	self:OnBtnCloseClicked()
end

return ClanWelcomeNewWindow
------------------------------------------------------------

