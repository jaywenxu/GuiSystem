--*****************************************************************
--** 文件名:	BossItem.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-12-11
--** 版  本:	1.0
--** 描  述:	首领信息
--** 应  用:  
--******************************************************************

local BossItem = UIControl:new
{
	windowName	= "BossItem",
	m_SelectCallback = nil,
	m_nCurIndex = 0,
}

function BossItem:Attach(obj)
	UIControl.Attach(self, obj)
	
	self.m_SelectCB = function(on) self:OnToggleChange(on) end
	self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))
    self.Controls.ItemToggle.onValueChanged:AddListener(self.m_SelectCB)
end

function BossItem:SetToggleGroup(tTlgGroup)
	self.Controls.ItemToggle.group = tTlgGroup
end

function BossItem:SetSelectCB(tFunc_cb)
	self.m_SelectCallback = tFunc_cb
end

function BossItem:SetItemCellInfo(idx)
	local tBoss = IGame.RobberBossClient:GetBossObj(idx)
	if not tBoss then
		print("[BossItem:SetItemCellInfo]: 找不到Boss数据", idx)
		return
	end
	
	local tBossConfig = IGame.rktScheme:GetSchemeInfo(ROBBERBOSS_CSV, tBoss.nBossID)
	if not tBossConfig then
		print("[BossItem:SetItemCellInfo]: 找不到Boss配置", tBoss.nBossID)
		return
	end
	
	self.m_nCurIndex = idx
	
	local controls = self.Controls
	
	--TODO: 设置名字
	controls.m_BossName.text = tostring(tBossConfig.BossName)
	
	--TODO: 设置头像
	UIFunction.SetImageSprite(controls.m_HeadImg, AssetPath.TextureGUIPath..tBossConfig.HeadImg)
	
	--TODO: 设置星级
	self:SetStar(tBossConfig.StarLevel)
end

function BossItem:SetStar(nStarNum)
	local controls = self.Controls
	local tStart = 
	{
		controls.m_Star1,
		controls.m_Star2,
		controls.m_Star3,
		controls.m_Star4,
		controls.m_Star5,
	}
	
	for i = 1, #tStart do
		if i <= nStarNum then
			tStart[i].gameObject:SetActive(true)
		else
			tStart[i].gameObject:SetActive(false)
		end
	end
end

function BossItem:SetFocus(bFocus)
	if nil == bFocus then
		return
	end
	
	self.Controls.ItemToggle.isOn = bFocus
end

function BossItem:OnToggleChange(on)
	if not on then
		return
	end
	
	if self.m_SelectCallback then
		self.m_SelectCallback(self.m_nCurIndex)
	end
end

function BossItem:OnRecycle()
	self.Controls.ItemToggle.onValueChanged:RemoveListener(self.m_SelectCB)
	
    self.Controls.ItemToggle.group = nil
	self.Controls.ItemToggle.isOn  = false
	
    self.m_SelectCallback = nil

	UIControl.OnRecycle(self)
end

return BossItem