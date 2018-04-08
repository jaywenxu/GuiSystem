--/******************************************************************
---** 文件名:	RobberCell.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	何荣德
--** 日  期:	2017-12-19
--** 版  本:	1.0
--** 描  述:	缉拿大盗cell
--** 应  用:  
--******************************************************************/

local RobberCell = UIControl:new
{
	windowName = "RobberCell",
    m_nCurIndex = 0,
    m_bSuo = false
}

function RobberCell:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.callback_OnSelectChanged = function(on) self:OnSelectChanged(on) end
    self.Controls.m_itemToggle = self.transform:GetComponent(typeof(Toggle))
    self.Controls.m_itemToggle.onValueChanged:AddListener(self.callback_OnSelectChanged)
	
	return self
end

function RobberCell:SetFocus(bFocus)
	if nil == bFocus then
		return
	end
	
	self.Controls.m_itemToggle.isOn = bFocus
end

function RobberCell:IsSuo()
    return self.m_bSuo
end

function RobberCell:OnSelectChanged(on)
	if not on then
		return
	end
	
	if nil ~= self.selected_callback then
		self.selected_callback(self.m_nCurIndex)
	end
    
    if self:IsSuo() then
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "当前文明等级暂未开放") 
    end
end

function RobberCell:SetToggleGroup(tTlgGroup)
	self.Controls.m_itemToggle.group = tTlgGroup
end

function RobberCell:SetSelectedCallback(func)
    self.selected_callback = func
end

function RobberCell:SetCellInfo(idx)
    local robberInfo = gArrestRobberCfg.tRobberList[idx]
	if not robberInfo then
		uerror("[RobberCell:SetCellInfo]: robberInfo=nil", idx)
		return
	end
    
    local IconPath = AssetPath.TextureGUIPath .. robberInfo.icon
	UIFunction.SetImageSprite(self.Controls.m_Icon, IconPath)
    
    self.Controls.m_Text.text = robberInfo.level .."级"	
	self.m_nCurIndex = idx
    
    local pHero = GetHero()
    if not pHero then
        return
    end
    local level = pHero:GetNumProp(CREATURE_PROP_LEVEL)
    if robberInfo.minLv <= level and robberInfo.maxLv >= level then
        self.Controls.m_TuiJian.gameObject:SetActive(true)
        self:SetFocus(true)
    else
        self.Controls.m_TuiJian.gameObject:SetActive(false)
        self:SetFocus(false)
    end
    
    self.m_bSuo = false
    local nCivilGrade = IGame.ResAdjustClient:GetLvCivilGrade()
    if robberInfo.civilGrade > nCivilGrade then
        self.m_bSuo = true
    end
    self.Controls.m_Suo.gameObject:SetActive(self.m_bSuo)   
end

function RobberCell:OnRecycle()
    self.Controls.m_itemToggle.onValueChanged:RemoveListener(self.callback_OnSelectChanged)
	UIControl.OnRecycle(self)
end

return RobberCell



