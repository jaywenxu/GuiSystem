------------------------------------------------------------
-- PlayerWindow 的子窗口,不要通过 UIManager 访问
-- 装备界面包裹窗口
------------------------------------------------------------

local PlayerModelWidget = UIControl:new
{
	windowName = "PlayerModelWidget",
	Currenthead = nil,
}

local this = PlayerModelWidget   -- 方便书写

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function PlayerModelWidget:Attach( obj )
	UIControl.Attach(self,obj)
	
	self.Controls.m_DuiHuanBtn.onClick:AddListener(function() self:OnDuiHuanBtnClick() end)
	return self
end

------------------------------------------------------------
function PlayerModelWidget:OnDestroy()
	self.Currenthead  = nil
	UIControl.OnDestroy(self)
end
------------------------------------------------------------

-- 兑换按钮
function PlayerModelWidget:OnDuiHuanBtnClick()
	IGame.ChipExchangeClient:OpenChipExchangeShop(1)
	UIManager.PlayerWindow:callback_OnCloseButtonClick()
end

-- 设置ID
function PlayerModelWidget:SetID(id)
	self.Controls.m_ID.text = "序列号："..tostring(id)
end

-- 设置帮会名
function PlayerModelWidget:SetClanName(name)
	self.Controls.m_ClanName.text = tostring(name)
end

-- 设置职业
function PlayerModelWidget:SetVocation(voc)
	self.Controls.m_Vocation.text = GameHelp.GetVocationName(voc)
end

-- 设置等级
function PlayerModelWidget:SetLevel(level)
	self.Controls.m_Level.text = tostring(level).."级"
end

-- 设置战力
function PlayerModelWidget:SetForceScore(Score)
	--self.Controls.m_ForceScore.text = tostring(Score)
end

function PlayerModelWidget:UpdateHeadTitle()
	local pTitlePart = GetHeroEntityPart(ENTITYPART_PERSON_TITLE)
	if not pTitlePart then
		return
	end
	local curHeadTitleID = pTitlePart:GetHeadTitleID()
	local pCurHeadTitleInfo = IGame.rktScheme:GetSchemeInfo(HEADTITLE_CSV,curHeadTitleID)
	if not pCurHeadTitleInfo then
		self.Controls.m_HeadTitle.gameObject:SetActive(false)
		self:NameObjectActiveChange(false)
		return
	else
		self.Controls.m_HeadTitle.gameObject:SetActive(true)
		self:NameObjectActiveChange(true)
	end
	local info =
	{
		Path= pCurHeadTitleInfo.szIconPath,
		color = pCurHeadTitleInfo.szColor,
		alphaVal = pCurHeadTitleInfo.nLight
	}
	if self.Currenthead == nil then 
		self.Currenthead = UIFunction.SetHeadTitle(self.Controls.m_HeadTitle,info)
	else
		self.Currenthead:RefreshHead(info)
	end
end

-- 显示或隐藏某一个控件
function PlayerModelWidget:NameObjectActiveChange(bActive)
	self.Controls.m_Name.gameObject:SetActive(bActive)
	self.Controls.m_NotTitleName.gameObject:SetActive(not bActive)
end

-- 刷新数据
function PlayerModelWidget:Refresh()
	
	if not self:isLoaded() then
		return
	end
	local hero = GetHero()
	if not hero then
		return
	end

	local szName = hero:GetName()
	self.Controls.m_Name.text = tostring(szName)
	self.Controls.m_NotTitleName.text = tostring(szName)
	self:SetID(hero:GetNumProp(CREATURE_PROP_PDBID))
	--[[if hero:GetNumProp(CREATURE_PROP_CLANID) > 0 then
		self.Controls.m_ClanName.gameObject:SetActive(true)
	else
		self.Controls.m_ClanName.gameObject:SetActive(false)
	end--]]
	
	--self:SetVocation(hero:GetNumProp(CREATURE_PROP_VOCATION))
	self:SetLevel(hero:GetNumProp(CREATURE_PROP_LEVEL))
	self:SetForceScore(hero:GetNumProp(CREATURE_PROP_POWER))
	self:UpdateHeadTitle()
end

return this