------------------------------------------------------------
-- PlayerWindow 的子窗口,不要通过 UIManager 访问
-- 角色界面属性窗口
------------------------------------------------------------

local PlayerPropertyWidget = UIControl:new
{
	windowName = "PlayerPropertyWidget",
	tabName = {
		emBasic = 1,
		emDetail = 2,
		emMax = 3,
	},
	
	curTab = 1,	
}

local this = PlayerPropertyWidget   -- 方便书写

-- 详细属性面板 属性模块的名字顺序
local DetailPropNameList = {
	[1] = "基础属性",
	[2] = "战    斗",
	[3] = "五    行",
	[4] = "控    制",
	[5] = "其    他",
}
------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function PlayerPropertyWidget:Attach( obj )
	UIControl.Attach(self,obj)

	self.Controls.m_ExpInfoBtn.onClick:AddListener(function() self:OnButtonExpClick() end)
	-- 注册强化选项卡事件
	for i = 1, 2 do
		self.Controls["m_PropertyTypeTog"..i].onValueChanged:AddListener(function(on) self:OnToggleChanged(on, i) end)
	end

	local hero = GetHero()
	if not hero then
		uerror("【PlayerPropertyWidget】加载人物角色的时候，Hero 为空")
		return
	end

	local Vocation = hero:GetNumProp(CREATURE_PROP_VOCATION)
	--local BasePropList = BasePropMap[Vocation]
	for i = 1, 10 do
		local BaseValueCellTrans = self.Controls.m_BaseValueGrid.transform:Find("BaseValueCell ("..i..")")
		self.Controls["m_BaseValueCellImage"..i] = BaseValueCellTrans:Find("ValueImage"):GetComponent(typeof(Image))
		self.Controls["m_BaseValueCellName"..i] = BaseValueCellTrans:Find("ValueName"):GetComponent(typeof(Text))
		self.Controls["m_BaseValueCellText"..i] = BaseValueCellTrans:Find("ValueText"):GetComponent(typeof(Text))
	end

	local DetailPropList = DetailPropMap[Vocation]
	for GropKey,GropInfo in pairs(DetailPropList) do
		local GropTrans = self.Controls.m_DetailPropertyRect.transform:Find("GropPanelValue ("..GropKey..")")
		self.Controls["m_GropPanelName"..GropKey] = GropTrans:Find("TitlePanel/TittleBG/Text"):GetComponent(typeof(Text))
		self.Controls["m_GropPanelName"..GropKey].text = DetailPropNameList[GropKey]
		--uerror("GropKey"..GropKey)
		for key,PropID in pairs(GropInfo) do
			--uerror("key"..key)
			local DetailValueCellTrans = GropTrans:Find("Grid/ValueCell ("..key..")")
			self.Controls["m_DetailValueName"..GropKey.."_"..key] = DetailValueCellTrans:Find("ValueName"):GetComponent(typeof(Text))
			self.Controls["m_DetailValue"..GropKey.."_"..key] = DetailValueCellTrans:Find("Value"):GetComponent(typeof(Text))
		end
	end
	
--[[	self.BasicPropertyWidget = UIControl:new()
	self.BasicPropertyWidget:Attach(self.transform:Find("BasicProperty").gameObject)
	self.DetailPropertyWidget = UIControl:new()
	self.DetailPropertyWidget:Attach(self.transform:Find("DetailProperty").gameObject)--]]
	
	self.Controls.m_LifeSlider = self.Controls.m_LifeSliderCtrl.transform:GetComponent(typeof(Slider))
	self.Controls.m_SliderValueHP = self.Controls.m_LifeSliderCtrl.transform:Find("Background/Fill Area/ValueHP"):GetComponent(typeof(Text))
	self.Controls.m_ExpSlider = self.Controls.m_ExpSliderCtrl.transform:GetComponent(typeof(Slider))
	self.Controls.m_SliderValueEXP = self.Controls.m_ExpSliderCtrl.transform:Find("Background/Fill Area/ValueEXP"):GetComponent(typeof(Text))
	
	return self
end

function PlayerPropertyWidget:OnDestroy()
	UIControl.OnDestroy(self)	
	--table_release(self)
	self.curTab = 1
end

function PlayerPropertyWidget:OnRecycle()
	UIControl.OnRecycle(self)	
	--table_release(self)
	self.curTab = 1
end

------------------------------------------------------------

-- 刷新数据
function PlayerPropertyWidget:Refresh(Tab)
	if not self.transform then
		return
	end
	if Tab then
		self.curTab = Tab
	end
	self:RefreshHeadInfo()
	self:RefreshPropertyWindow()
end

-- exp按钮
function PlayerPropertyWidget:OnButtonExpClick()
	UIManager.ResAdjustWindow:Show(true)
end

-- 刷新经验、血量等
function PlayerPropertyWidget:RefreshHeadInfo()
	if not self.transform then
		return
	end
	local hero = GetHero()
	if not hero then
		return
	end
	--self.Controls.m_Power.text = "综合战力："..hero:GetNumProp(CREATURE_PROP_POWER)
	
	local curHP = hero:GetNumProp(CREATURE_PROP_CUR_HP)
	local maxHP = hero:GetNumProp(CREATURE_PROP_MAX_HP)
	self.Controls.m_SliderValueHP.text = curHP.." / "..maxHP
	self.Controls.m_LifeSlider.value = curHP / maxHP
	
	local curExp = hero:GetNumProp(CREATURE_PROP_EXP)
	local nextExp = 9999
	local scheme = IGame.rktScheme:GetSchemeInfo(UPGRADE_CSV, hero:GetNumProp(CREATURE_PROP_LEVEL))
	if scheme then
		nextExp = scheme.NextExp
	end

	self.Controls.m_SliderValueEXP.text = curExp.." / "..nextExp
	self.Controls.m_ExpSlider.value = curExp / nextExp
end

-- 属性标签
function PlayerPropertyWidget:OnToggleChanged(on, tabName)
	if not on then
		return
	end
	
	if self.curTab == tabName then -- 相同标签不用响应
		return
	end
	
	self.curTab = tabName
	
	self:Refresh(tabName)
end

-- 刷新子窗口
function PlayerPropertyWidget:RefreshPropertyWindow()
	if self.curTab == self.tabName.emBasic then
		self.Controls.m_PropertyPanelBG.transform:Find("BasicPropertyPanel").gameObject:SetActive(true)
		self.Controls.m_PropertyPanelBG.transform:Find("DetailPropertyPanel").gameObject:SetActive(false)
		self:RefreshBasicProperty()
	elseif self.curTab == self.tabName.emDetail then
		self.Controls.m_PropertyPanelBG.transform:Find("BasicPropertyPanel").gameObject:SetActive(false)
		self.Controls.m_PropertyPanelBG.transform:Find("DetailPropertyPanel").gameObject:SetActive(true)
		self:RefreshDetailProperty()
	end
end

-- 刷新基本属性
function PlayerPropertyWidget:RefreshBasicProperty()
	local hero = GetHero()
	if not hero then
		return
	end
	local Vocation = hero:GetNumProp(CREATURE_PROP_VOCATION)
	local Lucky = hero:GetNumProp(CREATURE_PROP_CUR_LUCKY)
	local LuckyPer = Lucky*66/100
	self.Controls.m_LuckyValue.text = Lucky
	self.Controls.m_LuckyDes.text	= "（紫装/鬼装掉率提升"..LuckyPer.."%）"
	self:SetForceScore(hero:GetNumProp(CREATURE_PROP_POWER))
	
	local BasePropList = BasePropMap[Vocation]
	local IconPath = {
		[PLAYER_PROP_ID_XIUWEI]		= AssetPath.TextureGUIPath.."Character/Character_a_xiuwei.png",
		[PLAYER_PROP_ID_XIULIAN]	= AssetPath.TextureGUIPath.."Character/Character_a_xiulian.png",
		
		[CREATURE_PROP_CUR_P_A]		= AssetPath.TextureGUIPath.."Character/Character_a_wuligj.png",
		[CREATURE_PROP_CUR_M_A]		= AssetPath.TextureGUIPath.."Character/Character_a_wuligj.png",
		
		[CREATURE_PROP_CUR_A_A]		= AssetPath.TextureGUIPath.."Character/Character_a_jingj.png",
		[CREATURE_PROP_CUR_B_A]		= AssetPath.TextureGUIPath.."Character/Character_a_jingj.png",
		[CREATURE_PROP_CUR_C_A]		= AssetPath.TextureGUIPath.."Character/Character_a_jingj.png",
		[CREATURE_PROP_CUR_D_A]		= AssetPath.TextureGUIPath.."Character/Character_a_jingj.png",
		[CREATURE_PROP_CUR_E_A]		= AssetPath.TextureGUIPath.."Character/Character_a_jingj.png",
		
		[CREATURE_PROP_CUR_A_D]		= AssetPath.TextureGUIPath.."Character/Character_a_hushijk.png",
		[CREATURE_PROP_CUR_B_D]		= AssetPath.TextureGUIPath.."Character/Character_a_hushijk.png",
		[CREATURE_PROP_CUR_C_D]		= AssetPath.TextureGUIPath.."Character/Character_a_hushijk.png",
		[CREATURE_PROP_CUR_D_D]		= AssetPath.TextureGUIPath.."Character/Character_a_hushijk.png",
		[CREATURE_PROP_CUR_E_D]		= AssetPath.TextureGUIPath.."Character/Character_a_hushijk.png",
		
		[CREATURE_PROP_CUR_A_IGNORE]		= AssetPath.TextureGUIPath.."Character/Character_a_hushijk.png",
		[CREATURE_PROP_CUR_B_IGNORE]		= AssetPath.TextureGUIPath.."Character/Character_a_hushijk.png",
		[CREATURE_PROP_CUR_C_IGNORE]		= AssetPath.TextureGUIPath.."Character/Character_a_hushijk.png",
		[CREATURE_PROP_CUR_D_IGNORE]		= AssetPath.TextureGUIPath.."Character/Character_a_hushijk.png",
		[CREATURE_PROP_CUR_E_IGNORE]		= AssetPath.TextureGUIPath.."Character/Character_a_hushijk.png",
		
		[CREATURE_PROP_CUR_P_D]		= AssetPath.TextureGUIPath.."Character/Character_a_wulify.png",
		[CREATURE_PROP_CUR_M_D]		= AssetPath.TextureGUIPath.."Character/Character_a_fashufy.png",
		[CREATURE_PROP_CUR_PRESENT]	= AssetPath.TextureGUIPath.."Character/Character_a_mingzhong.png",
		[CREATURE_PROP_CUR_HEDGE]	= AssetPath.TextureGUIPath.."Character/Character_a_duoshan.png",
		[CREATURE_PROP_CUR_FATAL]	= AssetPath.TextureGUIPath.."Character/Character_a_zhimingyj.png",
	}
	for i = 1, 10 do		UIFunction.SetImageSprite(self.Controls["m_BaseValueCellImage"..i],IconPath[BasePropList[i]])	-- 设置图标
		self.Controls["m_BaseValueCellName"..i].text = self:GetPropName(BasePropList[i])
		self.Controls["m_BaseValueCellText"..i].text = self:GetPropValue(BasePropList[i])
	end
end

-- 设置战力
function PlayerPropertyWidget:SetForceScore(Score)
	self.Controls.m_ForceScore.text = tostring(Score)
end

-- 刷新详细属性
function PlayerPropertyWidget:RefreshDetailProperty()
	local hero = GetHero()
	if not hero then
		return
	end
	local Vocation = hero:GetNumProp(CREATURE_PROP_VOCATION)
	local DetailPropList = DetailPropMap[Vocation]
	for GropKey,GropInfo in pairs(DetailPropList) do
		local GropTrans = self.Controls.m_DetailPropertyRect.transform:Find("GropPanelValue ("..GropKey..")")
		for key,PropID in pairs(GropInfo) do
			local DetailValueCellTrans = GropTrans:Find("Grid/ValueCell ("..key..")")
			self.Controls["m_DetailValueName"..GropKey.."_"..key].text = self:GetPropName(PropID)
			local PropValue = self:GetPropValue(PropID)
			local szPropValue = ""
			if PerPropMap[PropID] == 1 then
				szPropValue = math.floor(PropValue/100).."%"
			else
				szPropValue = PropValue
			end
			self.Controls["m_DetailValue"..GropKey.."_"..key].text = szPropValue
		end
	end
	--[[
	local controls = self.DetailPropertyWidget.Controls
	
	-- 刷新5个面板
	for n = 1, 5 do
		local controlMap = self.propControlMap["Panel"..n]
		for i,v in pairs(controlMap) do
			
			controls["m_Prop"..n.."_"..i].text = GameHelp.PropertyName[v].."："..hero:GetNumProp(v)
		end
	end--]]
end

local PropName = {
	[PLAYER_PROP_ID_XIUWEI]		= "修为",
	[PLAYER_PROP_ID_XIULIAN]	= "修炼",
	[PLAYER_PROP_ID_PK]			= "      PK值",
	[CREATURE_PROP_VIM]			= "活力",
	[CREATURE_PROP_CUR_MONSTER_ENHANCE]		= "怪物伤害加成",
}

function PlayerPropertyWidget:GetPropName(PropID)
	if PropName[PropID] then
		return PropName[PropID]
	else
		return GameHelp.PropertyName[PropID]
	end
end

-- 其他模块相关属性
local OtherModuleProp =
{
	[PLAYER_PROP_ID_XIUWEI] = true,
	[PLAYER_PROP_ID_XIULIAN] = true,
	[PLAYER_PROP_ID_PK]	= true,
}

function PlayerPropertyWidget:GetPropValue(PropID)
	local hero = GetHero()
	if not hero then
		return 0
	end
	
	if OtherModuleProp[PropID] then
		return self:GetOtherModuleProp(PropID)
	else
		return hero:GetNumProp(PropID)
	end
end

function PlayerPropertyWidget:GetOtherModuleProp(PropID)
	if not OtherModuleProp[PropID] then
		return 0
	end
	
	if PropID == PLAYER_PROP_ID_XIUWEI then
		local studySkillPart = GetHero():GetEntityPart(ENTITYPART_PERSON_STUDYSKILL)
		if not studySkillPart then
			return 0
		end
		
		return studySkillPart:GetXiuWei()
	elseif PropID == PLAYER_PROP_ID_XIULIAN then
		-- 还没做，是帮会技能相关的
		return 0
	elseif PropID == PLAYER_PROP_ID_PK then
		-- 目前的设计里没有PK值了
		return 0
	end
end

return this