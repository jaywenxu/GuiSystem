-- 帮派领地战界面
-- @Author: XieXiaoMei
-- @Date:   2017-07-11 17:13:19
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-07 19:57:00

local ClanLigeanceWdt = UIControl:new
{
	windowName               = "ClanLigeanceWdt",

	m_LigeanceData           = {},	-- 领地数据
	
	m_LigeanceDescWdt        = nil, -- 领地描述子窗口

	m_ResetTimestamp = 0,

	m_EventHandler = {},

	m_ClanID = 0,
	
	m_HitedEnable = false,
	
	m_BackBtnCallback = nil,
	
	m_bInit = false,	-- 是否初始化
}

local LigeanceDescWdtFile = ClanSysDef.ClanOwnPath .. "LigeanceDescWdt"  --领地描述子窗口路径
local Ligeance = IGame.Ligeance

-- 领地攻击或防守图片
local AttackFlagPngs = 
{
	Attack = "Ligeance_gonji_2.png",  --攻击图片标志名称
	Defence = "Ligeance_shouhu_2.png",  --防守图片标志名称
}

-- 宣战操作按钮图片
local OperaBtnPngs =  
{
	DeclareWar = "Ligeance_xuanzhan.png",
	Logbutch = "Ligeance_zhankuang.png",
}

------------------------------------------------------------
-- 初始化
function ClanLigeanceWdt:Attach( obj )
	UIControl.Attach(self,obj)

	self:SubControlExecute()
	self:InitUI()

	self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))

	self.m_ClanID = GetHero():GetNumProp(CREATURE_PROP_CLANID)
	
	if not self.m_HitedEnable then
		self:OnEnable()
	end
	
	self.transform.parent:SetAsLastSibling()
end

------------------------------------------------------------
-- 初始化UI
function ClanLigeanceWdt:InitUI()
	local controls = self.Controls

	local  seekFlagComs = function (go) -- 查找旗帜组件
		local flag = {}
		flag.img = go:GetComponent(typeof(Image))
		flag.txt = go.transform:Find("Text"):GetComponent(typeof(Text))
		flag.go = go
		return flag
	end

	local cities = {} 
	local parentTf = controls.m_Cities
	for id=1, 14 do
		local cityTf = parentTf:Find("City" .. id).transform

		local cityBtn = cityTf:Find("CityBtn"):GetComponent(typeof(Button))
		cityBtn.onClick:AddListener(function ()
			self:OnBtnCityClicked(id, cityTf)
		end)

		local flagGo = cityTf.transform:Find("Flag").gameObject
		flagGo:SetActive(false)
		controls["cityflag" .. id] = seekFlagComs(flagGo) --cityflag1

		local attackFlagGo = cityTf.transform:Find("AttackFlag").gameObject
		controls["cityAttaflag" .. id] = attackFlagGo:GetComponent(typeof(Image)) --cityAttaflag1
		attackFlagGo:SetActive(false)
	end

	controls.clanFlag = seekFlagComs(controls.m_MyClanFlag.gameObject)

	controls.m_CreateFlagBtn.onClick:AddListener(handler(self, self.OnBtnCreateFlagClicked))
	controls.m_DeclareWarBtn.onClick:AddListener(handler(self, self.OnBtnDeclareWarClicked))
	controls.m_TouchBgBtn.onClick:AddListener(handler(self, self.OnBtnTouchBgClicked))
	controls.m_BackBtn.onClick:AddListener(handler(self, self.OnBtnBackClicked))
	controls.m_FlgBtn.onClick:AddListener(handler(self, self.OnBtnFlagClicked))
	controls.m_LigeanseDescWdt.gameObject:SetActive(false)
end

------------------------------------------------------------
--  界面显示
function ClanLigeanceWdt:OnEnable()
	self.m_HitedEnable = true
	Ligeance:Show()
	print("ClanLigeanceWdt:OnEnable")
end

------------------------------------------------------------
-- 界面销毁
function ClanLigeanceWdt:OnDestroy()
	UIControl.OnDestroy(self)

	table_release(self) 
end

------------------------------------------------------------
-- 监听事件
function ClanLigeanceWdt:SubControlExecute()
	
	if self.bInit then
		return
	end
	self.bInit = true
	
	-- 请求帮派列表
	self.m_EventHandler[EVENT_LIGEANCE_DATA_UP] = ClanLigeanceWdt.OnLigeanceDataUpEvt
	self.m_EventHandler[EVENT_LIGE_FLAG_SET_RET] = ClanLigeanceWdt.OnClanFlagSetRetEvt
	self.m_EventHandler[EVENT_LIGE_RESET_TIME_UP] = ClanLigeanceWdt.OnResetTimeUpEvt
	
	for eventId, handler in pairs(self.m_EventHandler) do
		rktEventEngine.SubscribeExecute(eventId , 0, 0, handler, self)	
	end

end 

function ClanLigeanceWdt:OnResetTimeUpEvt()
	cLog("ClanLigeanceWdt:OnResetTimeUpEvt", "green")

	local resetTimestamp = Ligeance:GetResetTime()
	if self.m_ResetTimestamp == resetTimestamp then
		return
	end

	local leftTime = resetTimestamp - IGame.EntityClient:GetZoneServerTime()
	if leftTime < 0 then
		return
	end

	self.m_ResetTimestamp =  resetTimestamp

	local controls = self.Controls

	local s, tm = GetCDTime(leftTime)
	controls.m_LeftDayTxt.text = "<color=#C67744FF>" .. (tm["天"] or 0).."</color>天"
	controls.m_LeftHourTxt.text = "<color=#C67744FF>" .. (tm["小时"] or 0).."</color>小时"
end

------------------------------------------------------------
-- 取消监听事件
function ClanLigeanceWdt:UnSubControlExecute()
	for eventId, handler in pairs(self.m_EventHandler) do
		rktEventEngine.UnSubscribeExecute(eventId , 0, 0, handler, self)	
	end
	self.m_EventHandler = {}
end

------------------------------------------------------------
-- 刷新界面
function ClanLigeanceWdt:RefreshUI()
	local controls = self.Controls
	local state = Ligeance:GetState(0)
	local imgPath = OperaBtnPngs.Logbutch

	for i, v in ipairs(self.m_LigeanceData) do
		local bHasOwner = v.nClanID ~= 0

		local flag = controls["cityflag" .. v.nID]
			
		local bHasFlag = false
		if bHasOwner and ClanSysDef.LigeanceFlagPngs[v.nBannerID] then
			local imgPath = ClanSysDef.LigeanceTexturePath .. ClanSysDef.LigeanceFlagPngs[v.nBannerID]
			UIFunction.SetImageSprite(flag.img, imgPath )
			
			flag.txt.text = v.szBanerName
			bHasFlag = true
		end
		flag.go:SetActive(bHasFlag)

		-- 宣战期：领地已经宣战标记
		if state == eLigeance_State_Auction then
			local auction = Ligeance:SeekSelfAuction(v.nID)
			if auction then
				print(v.nID.."领地已经宣战") -- Todo :领地显示宣战图标
			end

			imgPath = OperaBtnPngs.DeclareWar
		elseif state == eLigeance_State_War then-- 战争期 :显示可以攻打的领地

			if v.nEnemy1 == self.m_ClanID or v.nEnemy2 == self.m_ClanID then
				print(v.nID.."领地可以攻打") --TODO: show the flag of can attack 
			end
		end
	end

	self:ShowClanFlag() -- 
	
	UIFunction.SetImageSprite(controls.m_OpBtnImg, ClanSysDef.LigeanceTexturePath .. imgPath)
end

------------------------------------------------------------
-- 显示旗帜
function ClanLigeanceWdt:ShowClanFlag()
	local clan = IGame.ClanClient:GetClan()
	local flagID = clan:GetNumProp(emClanProp_PuLigeanBanner)
	local bHasFlag  = flagID > 0

	local controls = self.Controls	
	controls.m_CreateFlagBtn.gameObject:SetActive(not bHasFlag)
	controls.m_MyClanFlag.gameObject:SetActive(bHasFlag)

	if bHasFlag then 
		local clanFlag = controls.clanFlag
		local imgPath = ClanSysDef.LigeanceTexturePath .. ClanSysDef.LigeanceFlagPngs[flagID]
		UIFunction.SetImageSprite(clanFlag.img, imgPath )
		clanFlag.txt.text = clan:GetStringProp(emClanBannerName)
	end
end

-------------------------------------------------------------------------
-- 领地数据更新事件回调
function ClanLigeanceWdt:OnLigeanceDataUpEvt(_, _, _, data)
	cLog("OnLigeanceDataUpEvt", "green")

	self.m_LigeanceData = Ligeance:GetLigeanceData()

	self:RefreshUI()
end

------------------------------------------------------------
-- 帮会旗帜设置返回
function ClanLigeanceWdt:OnClanFlagSetRetEvt(_, _, _, data)
	cLog("OnClanFlagSetRetEvt", "green")

	UIManager.LigeFlagEditWindow:Hide()

	self:ShowClanFlag()
end

-------------------------------------------------------------------------
-- 城池按钮点击回调
function ClanLigeanceWdt:OnBtnCityClicked(id, cityBtnTf)
	if isTableEmpty(self.m_LigeanceData[id]) then
		cLog("无领地数据", "red")
		return
	end
	
	if not self.m_LigeanceDescWdt then -- 领地描述窗口
		self.m_LigeanceDescWdt = require(LigeanceDescWdtFile):new()
		self.m_LigeanceDescWdt:Attach(self.Controls.m_LigeanseDescWdt.gameObject)
	end

	self.m_LigeanceDescWdt:ShowTips(self.m_LigeanceData[id], cityBtnTf)
end

------------------------------------------------------------
-- 创建旗帜按钮点击回调
function ClanLigeanceWdt:OnBtnCreateFlagClicked()
	UIManager.LigeFlagEditWindow:Show(true)
end

-- 已有帮会旗帜点击
function ClanLigeanceWdt:OnBtnFlagClicked()
	IGame.ChatClient:addSystemTips(TipType_Operate,InfoPos_ActorUnder,"战旗已确定，不能更改！" )
end

------------------------------------------------------------
-- 宣战按钮点击回调
function ClanLigeanceWdt:OnBtnDeclareWarClicked()

	local flagID = IGame.ClanClient:GetClan():GetNumProp(emClanProp_PuLigeanBanner)
	if flagID < 1 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder,"请先创建帮会战旗！" )
	else
		UIManager.LigeLogbuchWindow:Show(true)
	end
end

------------------------------------------------------------
-- 触屏背景图片点击回调
function ClanLigeanceWdt:OnBtnTouchBgClicked()
	if self.m_LigeanceDescWdt then --关闭领地描述窗口
		self.m_LigeanceDescWdt:HideTips()
	end
end
------------------------------------------------------------
-- 点击返回
function ClanLigeanceWdt:OnBtnBackClicked()
	if self.m_BackBtnCallback then --关闭领地描述窗口
		self.m_BackBtnCallback()
	end
end
-------------------------------------------------------------------------
function ClanLigeanceWdt:Show()
    UIControl.Show(self)
    if UIManager.LigeLogbuchWindow:isShow() then
        UIManager.LigeLogbuchWindow:BringTop()
    end
end
-------------------------------------------------------------------------
function ClanLigeanceWdt:SetBackBtnCallback(func_cb)
	self.m_BackBtnCallback = func_cb
end

return ClanLigeanceWdt
