--/******************************************************************
--** 文件名:    FuMoTouItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-07-11
--** 版  本:    1.0
--** 描  述:    伏魔骰窗口-点数奖励图标
--** 应  用:  
--******************************************************************/

require("GuiSystem.WindowList.FuMoTou.FuMoTouWindowTool")

local FuMoTouItem = UIControl:new
{
    windowName = "FuMoTouItem",
    m_index= 1,
}

function FuMoTouItem:Attach(obj)
	
    UIControl.Attach(self,obj)
	
end

function FuMoTouItem:SetIndex(index)
    self.m_index = index
end


-- 更新图标
-- @point:点数:number
-- @fuMoTouCfg:伏魔骰配置:gFuMoTaCfg.monsters
function FuMoTouItem:UpdateItem(point, fuMoTouCfg)
	
	local monsterScheme = IGame.rktScheme:GetSchemeInfo(MONSTER_CSV, fuMoTouCfg.id)
	if not monsterScheme then
		return
	end
	
	local dropScheme = FuMoTouWindowTool.CalcTheBestDropScheme(fuMoTouCfg)
	
	--[[local hero = GetHero()
	if not hero then
		return
	end
	
	local heroLevel = hero:GetNumProp(CREATURE_PROP_LEVEL)
	local dropScheme = nil
	
	-- 计算最合适的掉落配置
	for k,v in pairs(fuMoTouCfg.drop) do
		if heroLevel >= v.minLevel and heroLevel <= v.maxLevel then
			dropScheme = v
			break
		elseif(dropScheme == nil and heroLevel < v.minLevel) or (dropScheme == nil and heroLevel > v.maxLevel) then
			dropScheme = v
		end
		
		if dropScheme ~= nil then
			if (heroLevel < dropScheme.minLevel and v.minLevel < dropScheme.minLevel) or 
			(heroLevel > dropScheme.maxLevel and v.maxLevel < dropScheme.maxLevel) then
				dropScheme = v
			end
		end
	end--]]
	
	if not dropScheme then
		return
	end
	
	local dropAwardStr = ""
	for k,v in pairs(dropScheme.items) do
		local dropAwardScheme = gFuMoTouDropCfg[v]
		local color = gFuMoTouColorCfg[dropAwardScheme.color]
		if dropAwardScheme then
			local str = string.format("<color=%s>%s</color>",color,dropAwardScheme.text)
            if not IsNilOrEmpty(dropAwardStr) then 
                dropAwardStr = dropAwardStr..","
            end
			dropAwardStr = dropAwardStr .. str
		end
	end
	local monsterNameColor = gFuMoTouColorCfg[fuMoTouCfg.nameColor]
	local MonsterName = string.format("<color=%s>%s</color>",monsterNameColor,monsterScheme.szName)
	self.Controls.m_TextPoint.text = string.format("%d点", point)
	self.Controls.m_TextMonsterName.text = MonsterName
	self.Controls.m_TextAward.text = dropAwardStr
    local IconPath = AssetPath.TextureGUIPath..fuMoTouCfg.typeIcon
	UIFunction.SetImageSprite(self.Controls.m_TypeIcon, IconPath)
    if  self.m_index %2 == 0 then 
        self.Controls.m_bg.gameObject:SetActive(false)  
	else
       self.Controls.m_bg.gameObject:SetActive(true)   
    end
end


return FuMoTouItem