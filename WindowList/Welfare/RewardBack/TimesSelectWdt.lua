
--******************************************************************
--** 文件名:	TimesSelectWdt.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-06-02
--** 版  本:	1.0
--** 描  述:	回收次数选择
--** 应  用:  
--******************************************************************
require("GuiSystem.WindowList.Welfare.WelfareDef")

local tNormoalColor = Color.New(0.36, 0.48, 0.6)
local tWarningColor = Color.New(1, 0, 0)

local RB_COST_TYPE = 
{
    ZUANSHI = 1,
    YINGBI  = 2,
    YINGLIANG = 3,
}

local TimesSelectWdt = UIControl:new
{
	windowName = "TimesSelectWdt",
	m_RbManager = nil,
	m_CurOption = 0,
	m_CurIndex  = 0,
	m_CurTimes  = 0,
	m_MaxTimes  = 0,
	m_CostType  = 0, --当前消耗类型
}

function TimesSelectWdt:Attach(obj)
	UIControl.Attach(self, obj)
	
	local controls = self.Controls
	
	controls.m_SubBtn.onClick:AddListener(handler(self, self.OnSubBtnClicked))
	controls.m_AddBtn.onClick:AddListener(handler(self, self.OnAddBtnClicked))
	controls.m_Cancle.onClick:AddListener(handler(self, self.OnCancleBtnClicked))
	controls.m_OK.onClick:AddListener(handler(self, self.OnOKBtnClicked))
	controls.m_Input.onClick:AddListener(handler(self, self.OnBtnInputClicked))
	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnCloseClick))
	
	self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable)) 
	self.unityBehaviour.onDisable:AddListener(handler(self, self.OnDisable)) 
	
	self.m_RbManager = IGame.WelfareClient:GetRewardBackManager()	
	self:SetWdtInfo()
	
	return self	
end

function TimesSelectWdt:OnEnable()
	self:SetWdtInfo()
end

function TimesSelectWdt:OnDisable()
	self.m_CurOption = 0
	self.m_CurIndex  = 0
end

function TimesSelectWdt:SetCurState(option, idx)
	self.m_CurOption = option
	self.m_CurIndex  = idx
end

function TimesSelectWdt:GetMoneyInfo()
    local nCost = 0
    local nHave = 0
    local nImgPath = ""
    
    local Recycle = self.m_RbManager:GetRecycleCfg(self.m_CurIndex)
	if nil == Recycle then
        return nHave, nCost, nImgPath
	end

    if self.m_CurOption == RB_OPTION.PERFECT then
        nHave = GetHero():GetActorYuanBao()
        nCost = Recycle.PerfectCost * self.m_CurTimes
        nImgPath = RB_CostIconPath.YUANBAO
	else
        local nYinBiNum = GetHero():GetYinBiNum()
        local nYinLiangNum = GetHero():GetYinLiangNum()
        nCost = Recycle.NormalCost * self.m_CurTimes
        
        if nYinBiNum >= nCost then
            nHave = GetHero():GetYinBiNum()
            nImgPath = RB_CostIconPath.YINBI
        else
            if nYinLiangNum >= nCost then
                nHave = GetHero():GetYinLiangNum()
                nImgPath = RB_CostIconPath.YINLIANG
            else
                nHave = GetHero():GetYinBiNum()
                nImgPath = RB_CostIconPath.YINBI
            end
        end
	end
    
    return nHave, nCost, nImgPath
end

function TimesSelectWdt:SetMoneyInfo()
    local nHave, nCost, nImgPath = self:GetMoneyInfo()
    
    local controls = self.Controls
    UIFunction.SetImageSprite(controls.m_CostIcon, nImgPath)
    
	local CostTxt = controls.m_CostValue
    
	CostTxt.text = tostring(nCost)
	if nHave < nCost then
		CostTxt.color = tWarningColor
	else
		CostTxt.color = tNormoalColor
	end   
end

function TimesSelectWdt:SetWdtInfo()
	
	local tRecycle = self.m_RbManager:GetRecycleCfg(self.m_CurIndex)
	if nil == tRecycle then
		return
	end
	local nTimes = self.m_RbManager:GetRecycleTimes(self.m_CurIndex)
	local controls = self.Controls
	controls.m_ItemName.text = tostring(tRecycle.Name)
	controls.m_MaxTimes.text = tostring(nTimes)
	
    self:SetMoneyInfo()
    
	self.m_CurTimes = nTimes
	self.m_MaxTimes = nTimes
	
	self:SetCostContent()
end

function TimesSelectWdt:SetCostContent()
	
    self:SetMoneyInfo()
    
    local controls = self.Controls
	controls.m_InputValue.text = tostring(self.m_CurTimes)
	
	--TODO: 按钮置灰操作
	local gameObj = controls.m_SubBtn.gameObject
	local bGray = self.m_CurTimes <= 0
	UIFunction.SetImgComsGray( gameObj , bGray )
	UIFunction.SetButtonClickState(gameObj, not bGray)	

	gameObj = controls.m_AddBtn.gameObject
	bGray = self.m_CurTimes >= self.m_MaxTimes
	UIFunction.SetImgComsGray( gameObj , bGray )
	UIFunction.SetButtonClickState(gameObj, not bGray)	
end

function TimesSelectWdt:OnSubBtnClicked()
	local nNum = self.m_CurTimes
	if 0 == nNum then
		return
	end
	
	nNum = nNum - 1
	self.m_CurTimes = nNum
	self:SetCostContent()
end

function TimesSelectWdt:OnAddBtnClicked()
	local nNum = self.m_CurTimes
	if nNum == self.m_MaxTimes then
		return
	end
	
	nNum = nNum + 1
	self.m_CurTimes = nNum
	self:SetCostContent()
end

function TimesSelectWdt:OnCancleBtnClicked()
	self:Hide()
end

function TimesSelectWdt:CheckCond(tRecycle)
        
	if not tRecycle then
        return false, "无法找回"
	end

    if self.m_CurOption == RB_OPTION.PERFECT then
        local nHave = GetHero():GetActorYuanBao()
        local nCost = tRecycle.PerfectCost * self.m_CurTimes
        if nHave < nCost then
            return false, "钻石不足"
        else
            return true, ""
        end
    else
        local nYinBiNum = GetHero():GetYinBiNum()
        local nYinLiangNum = GetHero():GetYinLiangNum()
        local nCost = tRecycle.NormalCost * self.m_CurTimes
        if nYinBiNum < nCost and nYinLiangNum < nCost then
            return false, "银币不足"
        else
            return true, ""
        end	
    end	
end

function TimesSelectWdt:OnOKBtnClicked()

    local tRecycle = self.m_RbManager:GetRecycleCfg(self.m_CurIndex)
	if not tRecycle then
        return
	end

    local bRet, szTips = self:CheckCond(tRecycle)
	
	if not bRet then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, szTips)
		return
	end
	
	local MsgData = {}
	MsgData.Option = self.m_CurOption
	MsgData.ID     = tRecycle.ID
	MsgData.Type   = tRecycle.Type
	MsgData.Times  = self.m_CurTimes
	
	GameHelp.PostServerRequest("RequestGetBackReward("..tableToString(MsgData)..")")
    
	self:Hide()
end

function TimesSelectWdt:OnBtnInputClicked() 
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
			self:SetCostContent()
	    end
	}
	UIManager.NumericKeypadWindow:ShowWindow(numTable, otherInfoTable) -- 打开小键盘
end

function TimesSelectWdt:OnCloseClick()
    self:Hide()
end

return TimesSelectWdt


