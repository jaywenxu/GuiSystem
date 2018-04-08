--BabelWnd.lua------------------------------------------------------------
-- 版  权:	(C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:	聂敏隆
-- 日  期:	2017.10.23
-- 版  本:	1.0
-- 描  述:	通天塔主界面
------------------------------------------------------------------------------

local BabelWnd = UIWindow:new
{
	windowName = "BabelWnd",
	strTitlePath = AssetPath.TextureGUIPath.."Tower/tower_tontianta.png",
	
	ImgFloorN = AssetPath.TextureGUIPath.."Tower/tower_zuodi.png",
	ImgFloorH = AssetPath.TextureGUIPath.."Tower/tower_zuodi_2.png",
	
	nRankFloor = 4, -- 每阶显示4层
	
	tFloorPos = 
	{
		Vector3.New(350,-340,-800),
		Vector3.New(-365,-130,-800),
		Vector3.New(330,80,-800),
		Vector3.New(-355,300,-800),
	},
}

function BabelWnd:OnAttach(obj)

	UIWindow.OnAttach(self,obj)
	
	UIWindow.AddCommonWindowToThisWindow(self,true,self.strTitlePath, function() self:OnBtnClose() end,nil,function() self:SetFullScreen() end,true)
    
    self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))

	self.Controls.m_BtnEnter.onClick:AddListener(handler(self, self.OnBtnEnter))
	self.Controls.m_BtnRank.onClick:AddListener(handler(self, self.OnBtnRank))
	self.Controls.m_BtnProp.onClick:AddListener(handler(self, self.OnBtnProp))
	self.Controls.m_BtnHideProp.onClick:AddListener(handler(self, self.OnBtnHideProp))
				
	self:SubscribeEvent()
	
	self:FreshUI()
end

function BabelWnd:OnEnable()
	self:FreshUI()
end

function BabelWnd:OnBtnClose()
	self:HideModel()
	self:Hide()
end

-- 窗口销毁
function BabelWnd:OnDestroy()
	self:OnBtnClose()
	self:UnSubscribeEvent()
	UIWindow.OnDestroy(self)
end

function BabelWnd:SubscribeEvent()
	self.pOnEventShowMain = handler(self, self.OnEventShowMain)
	rktEventEngine.SubscribeExecute(EVENT_BABEL_SHOWMAIN, 0, 0, self.pOnEventShowMain)
end

function BabelWnd:UnSubscribeEvent()
	rktEventEngine.UnSubscribeExecute(EVENT_BABEL_SHOWMAIN, 0, 0, self.pOnEventShowMain)
end

function BabelWnd:OnEventShowMain()
	self:FreshUI()
end

-- 刷新界面显示
function BabelWnd:FreshUI()

	self:OnBtnHideProp()
	
	local nFloor = IGame.BabelEctype:GetFloor()
	
	local bLast = false
	local tCfg = IGame.rktScheme:GetSchemeInfo(BABEL_CSV, nFloor+1)
	if not tCfg then
		bLast = true
	end

	local nRank = math.floor(nFloor/self.nRankFloor) 
	if not bLast then
		nRank = nRank + 1
		nFloor = nFloor % self.nRankFloor
	else
		nFloor = self.nRankFloor
		self:ShowModel(nFloor)
	end
	
	local tControls = self.Controls
	
	local bShowClear = false
	local bShowLight = false
	local bShowGray = false

	for n = 1, self.nRankFloor do
		bShowClear = false
		bShowLight = false
		bShowGray = false
		
		if n <= nFloor then
			bShowClear = true
			bShowLight = true
			UIFunction.SetImageSprite(tControls["m_Floor"..n].transform:GetComponent(typeof(Image)), self.ImgFloorN)
			
		elseif n == nFloor + 1 then
			bShowLight = true
			UIFunction.SetImageSprite(tControls["m_Floor"..n].transform:GetComponent(typeof(Image)), self.ImgFloorH)
			self:ShowModel(n)
		else 
			bShowGray = true
			UIFunction.SetImageSprite(tControls["m_Floor"..n].transform:GetComponent(typeof(Image)), self.ImgFloorN)
		end
		
		UIFunction.SetImageGray(tControls["m_Floor"..n], bShowGray)
		tControls["m_ImgFloor"..n].gameObject:SetActive(bShowClear)
		
		if n > 1 then
			tControls["m_Light"..n].gameObject:SetActive(bShowLight)
		end
		
		tControls["m_TextFloor"..n].text = nRank.."阶"..n.."层"
	end
	
	local nNextFloor = IGame.BabelEctype:GetFloor() 

	if not bLast then
		nNextFloor = nNextFloor + 1
	end
	self:FreshRightInfo(nNextFloor, bLast)
end

-- 刷新右边信息显示
function BabelWnd:FreshRightInfo(nFloor, bLast)
	
	local tCfg = IGame.rktScheme:GetSchemeInfo(BABEL_CSV, nFloor)
	if not tCfg then
		uerror("【通天塔】显示右边信息，失败，找不到配置"..nFloor)
		return
	end
	
	local tCfgPrize = IGame.rktScheme:GetSchemeInfo(BABEL_PRIZE_CSV, tCfg.nPrizeID)
	if tCfg.nPrizeID > 0 and not tCfgPrize then
		uerror("【通天塔】显示右边信息，失败，找不到配置"..tCfg.nPrizeID)
		return
	end
	
	local tControls = self.Controls
	
	tControls.m_TextExp.text = tCfgPrize.nExp
	tControls.m_TextMoney.text = tCfgPrize.nMoney
	
	tControls.m_TextTitle.text = tCfg.strName
	tControls.m_TextTitleRight.text = IGame.BabelEctype:GetRankTitle(nFloor)
	
	local pHero = GetHero()
	local nPower = pHero:GetNumProp(CREATURE_PROP_POWER)	
	local strPower = "推荐战力： "..nPower.."/"
	if nPower < tCfg.nPower then
		strPower = strPower.."<color=#DD1717>"..tCfg.nPower.."</color>"
	else
		strPower = strPower.."<color=#10A41C>"..tCfg.nPower.."</color>"
	end
	
	tControls.m_TextPower.text = strPower
	tControls.m_TextLevel.text = "开放等级："..tCfg.nLevel.."级"
	
	local bCanClick = true
	if bLast then
		bCanClick = false
	end
	tControls.m_BtnEnter.interactable = bCanClick
	
	-- 显示本层奖励
	local nFloorNow = IGame.BabelEctype:GetFloor()
	local nRank = math.floor(nFloorNow/self.nRankFloor) + 1
	if bLast then
		nRank = nRank - 1 
	end
	local nFloorPrize = nRank * self.nRankFloor 
	
	tCfg = IGame.rktScheme:GetSchemeInfo(BABEL_CSV, nFloorPrize)
	if not tCfg then
		uerror("【通天塔】显示奖励信息，失败，找不到配置"..nFloorPrize)
		return
	end
	
	local tString = split_string(tCfg.strFloor, ";")
	for n = 1, 3 do
		tControls["m_TextPrize"..n].text = tString[n] or ""
		tControls["m_TextPrizeLeft"..n].text = tString[n] or ""
	end
	
	-- 总属性显示上一层的
	local nFloorProp = math.floor(nFloorNow/self.nRankFloor) * self.nRankFloor 
	tCfg = IGame.rktScheme:GetSchemeInfo(BABEL_CSV, nFloorProp)

	local tAllProp = {}
	if tCfg then
		tAllProp = split_string(tCfg.strProp, ";")
	end
	
	for n = 1, 7 do
		tControls["m_TextProp"..n].text = tAllProp[n] or ""
	end
end

-- 点击进入按钮
function BabelWnd:OnBtnEnter()
	self:Hide()
	IGame.BabelEctype:RequestEnter()
end

-- 点击排行榜按钮
function BabelWnd:OnBtnRank()
	IGame.BabelEctype:RequestRank()
end

-- 显示总属性
function BabelWnd:OnBtnProp()
	self.Controls.m_AllProp.gameObject:SetActive(true)
end

-- 隐藏总属性
function BabelWnd:OnBtnHideProp()
	self.Controls.m_AllProp.gameObject:SetActive(false)
end

-- 显示主角模型
function BabelWnd:ShowModel(nFloor)
	
	if self.UICharacterHelp ~= nil then 
		self.UICharacterHelp:Destroy()
		self.UICharacterHelp = nil
	end

	local pHero = GetHero()
	if not pHero then
		return
	end
	
	local nVoc = pHero:GetNumProp(CREATURE_PROP_VOCATION)
	self.Controls.m_ActorView.transform.localPosition = self.tFloorPos[nFloor]
	
	local tData = 
	{
		entityClass = tEntity_Class_Person,
		layer = UNITY_LAYER_NAME.UI, 								
		Name = "EntityModel",  								
		Position = Vector3.New(0,0,0),
		localScale = Vector3.New(80,80,80), 		
		rotate = Vector3.New(0,180,0),
		MoldeID = gEntityVocationRes[nVoc],								
		ParentTrs = self.Controls.m_ActorView.transform,			
		targetUID = nil,  								
		UID = GUI_ENTITY_ID_BABEL,
		nVocation = nVoc,
		formInfo = pHero:GetFromData(),
	}

	self.UICharacterHelp = UICharacterHelp:new()
	self.UICharacterHelp:Create(tData)
end

-- 隐藏主角模型
function BabelWnd:HideModel()
	
	if self.UICharacterHelp then 
		self.UICharacterHelp:Destroy()
		self.UICharacterHelp = nil
	end
end

return BabelWnd



