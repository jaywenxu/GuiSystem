-- 帮派创建子界面
-- @Author: XieXiaoMei
-- @Date:   2017-04-08 14:29:15
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-07 19:55:55

local tNormalTxtColor   = Color.New(1, 1, 1)
local tWarningTxtColor  = Color.New(1,0, 0)

local ClanCreateWdt = UIControl:new {
	windowName = "ClanCreateWdt",

	m_OnCreateSuccCallBack = nil,

	m_IsCreating = false,
}

function ClanCreateWdt:Attach(obj)
	UIControl.Attach(self,obj)

	self:InitUI()
end

function ClanCreateWdt:SetCostTxt()
	
	local controls = self.Controls
	local getClanConfig = handler(IGame.ClanClient, IGame.ClanClient.GetClanConfig)
	
	-- 消耗金钱
	local ncost = tonumber(getClanConfig(CLAN_CONFIG.CREATE_MONEY))
	local nHeroYL = tonumber(IGame.EntityClient:GetHero():GetYinLiangNum())
	
	controls.m_CostCoinTxt.text = tostring(ncost)
    controls.m_OwnCoinTxt.text = tostring(nHeroYL)

	if ncost > nHeroYL then
        controls.m_OwnCoinTxt.color = tWarningTxtColor
    else
        controls.m_OwnCoinTxt.color = tNormalTxtColor
    end
end

function ClanCreateWdt:InitUI()
	local controls = self.Controls

	controls.m_CreateClanBtn.onClick:AddListener(handler(self, self.OnBtnCreateClicked))
	controls.m_AddCoinBtn.onClick:AddListener(handler(self, self.OnBtnAddCoinClicked))
	self.unityBehaviour.onEnable:AddListener(handler(self,self.OnEnable))

	local inputField = controls.m_NameInput:GetComponent(typeof(InputField))
	controls.nameInput = inputField

	inputField = controls.m_DeclareInput:GetComponent(typeof(InputField))
	controls.declareInput = inputField

	local getClanConfig = handler(IGame.ClanClient, IGame.ClanClient.GetClanConfig)

	-- 创建条件
	local value = getClanConfig(CLAN_CONFIG.CREATE_CONDITION)
	controls.m_ConditionTxt.text = string_unescape_newline(value)

	-- 创建流程
	value = getClanConfig(CLAN_CONFIG.CREATE_PROCESS)
	controls.m_ProcessTxt.text = string_unescape_newline(value)
	
	self:SetCostTxt()

end

function ClanCreateWdt:RefreshUI()
	self:SetCostTxt()
end

function ClanCreateWdt:OnEnable()
	self:RefreshUI()
end

function ClanCreateWdt:OnDestroy()
	UIControl.OnDestroy(self)

	table_release(self) 
end

function ClanCreateWdt:SubControlExecute()
	self.m_OnCreateSuccCallBack = handler(self, self.OnClanCreateSuccEvt)
	rktEventEngine.SubscribeExecute( EVENT_CLAN_CREATE, SOURCE_TYPE_CLAN, 0, self.m_OnCreateSuccCallBack )
    
    self.m_OnYingLiangUpdate = handler(self, self.OnYingLiangUpdate)
	rktEventEngine.SubscribeExecute( EVENT_CION_YINLIANG , SOURCE_TYPE_COIN , 0 , self.m_OnYingLiangUpdate)

end

function ClanCreateWdt:UnSubControlExecute()
	rktEventEngine.UnSubscribeExecute( EVENT_CLAN_CREATE , SOURCE_TYPE_CLAN, 0, self.m_OnCreateSuccCallBack )
	self.m_OnCreateSuccCallBack = nil
    
    rktEventEngine.UnSubscribeExecute( EVENT_CION_YINLIANG , SOURCE_TYPE_COIN , 0 , self.m_OnYingLiangUpdate)
    self.m_OnYingLiangUpdate = nil
end

function ClanCreateWdt:OnYingLiangUpdate()
    self:SetCostTxt()
end

-- 创建帮会弹窗拦截
function ClanCreateWdt:ConfirmCreate()
	local controls = self.Controls
	
	local confirmCallBack = function()
		local name = controls.nameInput.text
		local declare = StringFilter.Filter( controls.declareInput.text, "*" )
		print("confirmCallBack.name="..name..",declare="..declare)
		IGame.ClanClient:CreateClanRequest(name, declare)
		
		controls.nameInput.text = ""
		controls.declareInput.text = ""
	end

	local cancelCallBack = function ()
		self.m_IsCreating = false
	end
	
	local getClanConfig = handler(IGame.ClanClient, IGame.ClanClient.GetClanConfig)
	local nNum = getClanConfig(CLAN_CONFIG.REPONSE_COUNT)
	local nLevel = getClanConfig(CLAN_CONFIG.REPONSE_LEVEL)
	local nLastTime = tonumber(getClanConfig(CLAN_CONFIG.REPONSE_DURATION))/3600
	
	local content = "申请创建帮会后, 在"..nLastTime.."小时内得到"..nNum.."个"..nLevel.."级以上的人响应才能创建成功, 否则创建失败, 失败后费用不返还, 确定要创建帮会吗?"
	
	local data = {
		content = content,
		confirmCallBack = confirmCallBack,
		cancelCallBack = cancelCallBack,
	}
	
	UIManager.ConfirmPopWindow:ShowDiglog(data)

	self.m_IsCreating = true
end

-- 是否在创建帮会当中
function ClanCreateWdt:IsClanCreateing()
	return self.m_IsCreating
end

-- 创建帮会按钮事件
function ClanCreateWdt:OnBtnCreateClicked()
	
	local controls = self.Controls
	local name = controls.nameInput.text

	-- 检查帮会名字是否合法
	if not IGame.ClanClient:CheckClanName(name) then
		return
	end
	
	-- 检查宣言是否合法
	local declare = controls.declareInput.text
	if StringFilter.FilterKeyWord(declare) then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "帮会宣言含有屏蔽字，请重新输入！") 
		return
	end
		
	--是否可以创建帮会的判断
	local bCanCreate = IGame.ClanClient:CanCreateClan()
	if not bCanCreate then 
		return
	end
	
	self:ConfirmCreate()
end

-- 添加金币按钮事件
function ClanCreateWdt:OnBtnAddCoinClicked()
	UIManager.ShopWindow:OpenShop(2415)
end

-- 帮会创建成功事件
function ClanCreateWdt:OnClanCreateSuccEvt(_, _, _, evtData)
	print("<color=green> --------- OnCreateClanEvt 帮派创建成功！！！</color>")

	local tabIdx = ClanSysDef.ClanNoneTabs.Response
	UIManager.ClanNoneWindow:OnTogglesChanged(tabIdx, true)	
end

return ClanCreateWdt
