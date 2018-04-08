-- 提示窗口
------------------------------------------------------------
local WildHangupWindow = UIWindow:new
{
	windowName = "WildHangupWindow",
}
local CommonWildCellMax = 8
------------------------------------------------------------
function WildHangupWindow:Init()

end
------------------------------------------------------------
function WildHangupWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.Controls.m_Close.onClick:AddListener(function() self:OnBtnCloseClick() end)
	
	for i = 1, CommonWildCellMax do
		self.Controls["m_CA"..i.."Btn"].onClick:AddListener(function() self:MoveToMap("common", i) end)
	end
	self.Controls.m_DangerBtn.onClick:AddListener(function() self:MoveToMap("danger", 1) end)
	self.Controls.m_FastTeamBtn.onClick:AddListener(function() self:OnFastTeamBtnClick() end)
	UIFunction.AddEventTriggerListener( self.Controls.m_CloseButton , EventTriggerType.PointerClick , function( eventData ) self:OnCloseButtonClick(eventData) end )
	self.Controls.Scroll = self.Controls.m_itemList:GetComponent(typeof(UnityEngine.UI.ScrollRect)) 
    self:SetMapInfo()
end
------------------------------------------------------------
function WildHangupWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------

function WildHangupWindow:SetMapInfo()
    if not self:isLoaded() then
        return
    end
	-- 设置危险挂机区地图名
    if gWildHangupCfg.DangerArea[1] then    
        self.Controls.m_DangerAreaName.text = gWildHangupCfg.DangerArea[1].name        
    else 
        uerror("[WildHangupWindow]请策划重新配置危险区：1" )
    end
	local heroLevel = GetHero():GetNumProp(CREATURE_PROP_LEVEL)
	local nTableCount = table_count(gWildHangupCfg.CommonArea)
	local toIndex = 1
	for i = 1, CommonWildCellMax do
		if i <= nTableCount then
			local level_min,level_max, name = GetWildHangupInfo(i)
			if level_min ~= nil and level_max ~= nil and name ~= "" then
				self.Controls["m_MapName"..i].text = name
				self.Controls["m_Level"..i].text = level_min.."-"..level_max.."级"
			else 
				uerror("[WildHangupWindow]请策划重新配置普通区：" .. i)
			end
			-- 推荐功能
			if tonumber(heroLevel) >= tonumber(level_min) and tonumber(heroLevel) <= tonumber(level_max) then
				self.Controls["m_Tuijian"..i].gameObject:SetActive(true)
				toIndex = i
			else
				self.Controls["m_Tuijian"..i].gameObject:SetActive(false)
			end
			self.Controls["m_cell"..i].gameObject:SetActive(true)
		else
			self.Controls["m_cell"..i].gameObject:SetActive(false)
		end
	end
	if self.Controls.Scroll == nil then
		self.Controls.Scroll = self.Controls.m_itemList:GetComponent(typeof(UnityEngine.UI.ScrollRect)) 
	end
	local nValue = 0
	if nTableCount > 3 then
		nValue = ((toIndex-1)*(384+7.2))/((nTableCount-3)*(384+7.2))
	end
	if nValue > 1 then
		nValue = 1.0
	end
	self.Controls.Scroll.horizontalNormalizedPosition = nValue

	GameHelp.PostServerRequest("RequestLevelAndKillNum()")
end

function WildHangupWindow:SetLevelAndKillNum(nMonsterLevel, nKillNum, nMaxMonsterNum)
	if not self:isLoaded() or not self:isShow() then
		return
	end
	local ratio = nKillNum/nMaxMonsterNum
	self.Controls.m_KillNum:GetComponent(typeof(Slider)).value = ratio
	self.Controls.m_LeftMonsterNum.text = nKillNum.."/"..nMaxMonsterNum
	
	self.Controls.m_DangerLevel.text = nMonsterLevel.."级"
end

function WildHangupWindow:MoveToMap(mapType, mapIndex)
	
	if mapType == "danger" then
		self:MoveToDangerHangupMap(mapIndex)
	elseif mapType == "common" then
		self:MoveToCommonHangupMap(mapIndex)
	end
end

-- 进入危险挂机地图
function WildHangupWindow:MoveToDangerHangupMap(mapIndex)
	
	if not gWildHangupCfg.DangerArea[mapIndex] then
		return 
	end 
	local nCurMapID = IGame.EntityClient:GetMapID()
	local mapID = gWildHangupCfg.DangerArea[mapIndex]["mapid"]
	if nCurMapID == mapID then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你已经在当前地图中") 
	end
	local heroLevel = GetHero():GetNumProp(CREATURE_PROP_LEVEL)
	local pWorldMapInfo = IGame.rktScheme:GetSchemeInfo(WORLDMAP_CSV,mapID)
	if not pWorldMapInfo then
		uerror("危险挂机地图配置不在世界地图里面")
		return
	end
	if pWorldMapInfo.nLimitLevel and tonumber(heroLevel) < tonumber(pWorldMapInfo.nLimitLevel) then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你没有达到"..pWorldMapInfo.nLimitLevel.."级，无法进入该地图！")
		return
	end
	GameHelp.PostServerRequest( "RequestWildHangupTransport("..gWildHangupCfg.DangerArea[mapIndex]["areaindex"]..")" )
	self:Hide()		
end

-- 进入普通挂机地图
function WildHangupWindow:MoveToCommonHangupMap(mapIndex)
	
	local pCommonArea = gWildHangupCfg.CommonArea[mapIndex]
	if not pCommonArea or not pCommonArea["mapid"] 
		or not pCommonArea["level_min"] or not pCommonArea["level_max"] then
		uerror("进入普通挂机地图，获取配置错误 序号：".. mapIndex)
		return
	end
	
	local nCurMapID = IGame.EntityClient:GetMapID()
	local mapID = pCommonArea["mapid"]
	if nCurMapID == mapID then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你已经在当前地图中") 
	end
	local heroLevel = GetHero():GetNumProp(CREATURE_PROP_LEVEL)
    local pWorldMapInfo = IGame.rktScheme:GetSchemeInfo(WORLDMAP_CSV,mapID)
	if not pWorldMapInfo then
		uerror("普通挂机地图配置不在世界地图里面")
		return
	end
    if pWorldMapInfo.nLimitLevel and tonumber(heroLevel) < tonumber(pWorldMapInfo.nLimitLevel) then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你没有达到"..pWorldMapInfo.nLimitLevel.."级，无法进入该地图！")
		return
	end
	local nLimitLv = pCommonArea["level_min"]
	if tonumber(heroLevel) < tonumber(nLimitLv) then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你没有达到"..nLimitLv.."级，无法进入该地图！")
		return
	end
	GameHelp.PostServerRequest( "RequestWildHangupTransport("..pCommonArea["areaindex"]..")" )
	self:Hide()		
end

function WildHangupWindow:OnFastTeamBtnClick()
    UIManager.TeamWindow:GotoActivetyByID(18)
end

-- 关闭按钮
function WildHangupWindow:OnBtnCloseClick()
    self:Hide()
end

function WildHangupWindow:OnCloseButtonClick(eventData)
end

return WildHangupWindow