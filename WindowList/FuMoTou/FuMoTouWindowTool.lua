--/******************************************************************
--** 文件名:    FuMoTouWindowTool.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-07-18
--** 版  本:    1.0
--** 描  述:    伏魔骰骰窗口一些可以共用的方法
--** 应  用:  
--******************************************************************/

FuMoTouWindowTool = {}

-- 计算最合适的掉落配置
-- @pointCfg:伏魔骰点数配置:gFuMoTaCfg.monsters
-- return:掉落配置:gFuMoTaCfg.gFuMoTaDropCfg
function FuMoTouWindowTool.CalcTheBestDropScheme(pointCfg)
	
	local hero = GetHero()
	if not hero then
		return
	end
	
	local heroLevel = hero:GetNumProp(CREATURE_PROP_LEVEL)
	local dropScheme = nil
	
	-- 计算最合适的掉落配置
	for k,v in pairs(pointCfg.drop) do
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
	end
	
	return dropScheme
	
end
