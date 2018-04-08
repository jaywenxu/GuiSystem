-- 设置-战斗窗口
-- @Author: XieXiaoMei
-- @Date:   2017-05-23 19:45:00
-- @Last Modified by:   HaoWei
-- @Last Modified time: 2017-08-25 15:16:41

local FightWidget = UIControl:new
{
	windowName = "FightWidget",
}

local this = FightWidget

----------------------------------------------------------------
function FightWidget:Attach( obj )
	UIControl.Attach(self, obj)
	self.assistOperateWidget = require("GuiSystem.WindowList.Settings.AssistOperateWidget"):new()
	self.assistOperateWidget:Attach(self.Controls.m_AssistOperateTrans.gameObject)
	
	self:InitUI()
end

--显示界面， 并完成初始化
function FightWidget:Show()
	self.Setting = self:GetAllSetting()
	UIControl.Show(self)
	self:SetView()
end

--影藏界面，并完成设置
function FightWidget:Hide()
	--保存
	--self:SaveSetting()					--toggle改变的时候已经设置
	self:CheckChange()						--检测是否发生设置修改
	UIControl.Hide(self)
end

function FightWidget:OnDestroy()
	self:CheckChange()						--检测是否发生设置修改
	
	UIControl.OnDestroy(self)

	table_release(self)
end

function FightWidget:InitUI()
	local controls = self.Controls

	self.skillReleaseTgl = {
		controls.m_SimpleRelease,
		controls.m_PrecitionRelease,
	}

	self.attackTarTgl = {
		controls.m_HPMin,
		controls.m_DistanceMin,
	}
	
	self.attackTypeTgl = {
		controls.m_PlayerToggle,
		controls.m_MonsterToggle,
	}
	
	--控件事件注册
	for i, tgl in pairs(self.skillReleaseTgl) do
		tgl.onValueChanged:AddListener(function (on)
			self:OnTglSkillsModeChanged(i, on)
		end)
	end
	
	for i, tgl in pairs(self.attackTarTgl) do
		tgl.onValueChanged:AddListener(function (on)
			self:OnTglAttackTarChanged(i, on)
		end)
	end
	
	for i, tgl in pairs(self.attackTypeTgl) do
		tgl.onValueChanged:AddListener(function(on)
			self:OnTglAttackTypeChanged(i, on)
		end)
	end
	
	controls.m_AutoAttackToggle.onValueChanged:AddListener(function() self:OnAutoAttackChanged() end)
	self.OnAssisOperateBtnClickCB = function() self:OnAssisOperateBtnClick() end
	self.Controls.m_AssistOperaBtn.onClick:AddListener(self.OnAssisOperateBtnClickCB)
end

--设置界面，值
function FightWidget:SetView()
	local skillReleaseIdx = PlayerPrefs.GetInt("SkillRelease", 1)			--默认选中第1个, 2-第二个
	local attackTargetIdx = PlayerPrefs.GetInt("AttackTarget", 1)			--   1-第一个， 2- 第二个
	local attackTypeIdx = PlayerPrefs.GetInt("AttackType", 1)				--  1-第一个， 2- 第二个
	local autoAttack = PlayerPrefs_GetBool("AutoAttack",true)				--默认开启为true
	
	self.skillReleaseTgl[skillReleaseIdx].isOn = true
	self.attackTarTgl[attackTargetIdx].isOn = true
	self.attackTypeTgl[attackTypeIdx].isOn = true

	self.Controls.m_AutoAttackToggle.isOn = autoAttack

	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)								-- 获取职业
	if nVocation == 1 then 																	--灵心
		self.Controls.m_AssistOperaBtn.gameObject:SetActive(true)
	else
		self.Controls.m_AssistOperaBtn.gameObject:SetActive(false)
	end
end

--获取所有轮盘设置,  这里只获取影响轮盘的
function FightWidget:GetAllSetting()
	local retTable = {}
	local skillRelease = PlayerPrefs.GetInt("SkillRelease", 1)
	local cure = PlayerPrefs_GetBool("CureShowCureHeadIcon", false)	
	local rex = PlayerPrefs_GetBool("ResShowHeadIcon", false)
	table.insert(retTable, skillRelease)
	table.insert(retTable, cure)
	table.insert(retTable, rex)
	return retTable
end

--检测是否发生修改
function FightWidget:CheckChange()
	local curSetting = self:GetAllSetting()
	for i,data in pairs(self.Setting) do
		if data ~= curSetting[i] then
			rktEventEngine.FireEvent(EVENT_SETTING_CHANGESETTING, SOURCE_TYPE_SYSTEM, 0)
		end
	end
end

--关闭界面的时候去设置
function FightWidget:SaveSetting()
	if self.skillReleaseTgl[1].isOn then
		PlayerPrefs.SetInt("SkillRelease", 1)
	else
		PlayerPrefs.SetInt("SkillRelease", 2)
	end
	
	if self.attackTarTgl[1].isOn then
		PlayerPrefs.SetInt("AttackTarget", 1)
	else
		PlayerPrefs.SetInt("AttackTarget", 2)
	end
	
	if self.attackTypeTgl[1].isOn then
		PlayerPrefs.SetInt("AttackType", 1)
	else
		PlayerPrefs.SetInt("AttackType", 2)
	end
	
	if self.Controls.m_AutoAttackToggle.isOn then
		PlayerPrefs_SetBool("AutoAttack",true)
	else
		PlayerPrefs_SetBool("AutoAttack",false)
	end
end
-----------------------------------------------------
--控件选中改变事件, 暂时不需要， 扩展预留
function FightWidget:OnTglSkillsModeChanged(idx, on)
	if self.skillReleaseTgl[1].isOn then
		PlayerPrefs.SetInt("SkillRelease", 1)
	else
		PlayerPrefs.SetInt("SkillRelease", 2)
	end
end

function FightWidget:OnTglAttackTarChanged(idx, on)
	if self.attackTarTgl[1].isOn then
		PlayerPrefs.SetInt("AttackTarget", 1)
	else
		PlayerPrefs.SetInt("AttackTarget", 2)
	end
end

function FightWidget:OnTglAttackTypeChanged(idx, on)
	if self.attackTypeTgl[1].isOn then
		PlayerPrefs.SetInt("AttackType", 1)
	else
		PlayerPrefs.SetInt("AttackType", 2)
	end
end

function FightWidget:OnAutoAttackChanged()
	if self.Controls.m_AutoAttackToggle.isOn then
		PlayerPrefs_SetBool("AutoAttack",true)
	else
		PlayerPrefs_SetBool("AutoAttack",false)
	end
end
----------------------------------------------------
--辅助操作
function FightWidget:OnAssisOperateBtnClick()
	self.assistOperateWidget:OpenAssistWidget()
end


return FightWidget