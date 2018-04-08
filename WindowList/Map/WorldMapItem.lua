 --每个WorldMapItem代表了unity中世界地图的一个场景按钮
------------------------------------------------------------
local WorldMapItem = UIControl:new
{
	windowName = "WorldMapItem" ,

	m_MapID = 0,
	m_LimitLv = 0,
}
------------------------------------------------------------
function WorldMapItem:Attach( obj )
	UIControl.Attach(self,obj)
end

function WorldMapItem:SetData( data )
    local controls = self.Controls
    local iconPath = AssetPath.TextureGUIPath .. data.iconPath
	UIFunction.SetImageSprite( controls.m_IconImg , iconPath, function ()
		controls.m_IconImg:SetNativeSize()
	end)

	local str = data.szMapName
	if data.szLableName == "主城" then
		str = string.format("%s(%s)", data.szMapName, data.szLableName)
	elseif not IsNilOrEmpty(data.szLableName) then
		str = string.format("%s-%s", data.szMapName, data.szLableName)
	end
	--controls.m_NameTxt.text = str

    self:AddListener( controls.m_IconBtn , "onClick" , self.OnButtonClick , self )
	
	self.m_MapID = data.nMapID
	self.m_LimitLv = data.nLimitLevel
	self:Refresh(str)

end
------------------------------------------------------------
function WorldMapItem:OnDestroy()
	UIControl.OnDestroy(self)
end

------------------------------------------------------------
--场景按钮按下
function WorldMapItem:OnButtonClick()
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end

	local entityView = pHero:GetEntityView()
	if not entityView then
		return
	end
	
	-- 传功状态
	if GameHelp.IsChuangGong() then
		IGame.ChatClient:addSystemTips(TipType_Operate,InfoPos_ActorUnder, "传功过程中禁止进行该操作")
		return
	end
	
	-- 条件检测
	if not self:CanVisit() then
		IGame.ChatClient:addSystemTips(TipType_Operate,InfoPos_ActorUnder, "等级不够，不能访问此场景")
		return
	end

	local curMapID = IGame.EntityClient:GetMapID()
	if curMapID ~= self.m_MapID then
		self:ConfirmEnterMap()
	else
		IGame.ChatClient:addSystemTips(TipType_Operate,InfoPos_ActorUnder, "已在该场景中")
	end

end

function WorldMapItem:ConfirmEnterMap()
    local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end

	local entityView = pHero:GetEntityView()
	if not entityView then
		return
	end
    -- 先停下来
    if pHero:IsMoving() then
        entityView:Move( EntityFollowMode.None , { pHero:GetPosition() , entityView.forward } , true )
        pHero:StopMove()
    end
    
    local str = "RequestWorldMapTransport("..self.m_MapID..")"
    GameHelp.PostServerRequest(str)
    
    UIManager.WorldMapWindow:Hide()
    UIManager.SceneMapWindow:Hide()
end

------------------------------------------------------------
--是否可以访问此场景
function WorldMapItem:CanVisit()
	--访问玩家当前等级，如果地图等级超过了玩家等级，则不能访问
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return false
	end
	local playerLv = pHero:GetNumProp(CREATURE_PROP_LEVEL)
	
	-- 检测等级限制
	if playerLv < self.m_LimitLv then
		return false
	end
	
	return true
end

------------------------------------------------------------
--根据玩家当前等级更新图标
function WorldMapItem:Refresh(str)
	local bCanVisit = self:CanVisit()

	local go = self.transform.gameObject 
	UIFunction.SetComsAndChildrenGray(go, not bCanVisit)

	local controls = self.Controls
	if bCanVisit then 
		controls.m_NameTxt.text = string.format("<color=#DBE6EAFF>%s</color>", str)
	else
		controls.m_NameTxt.text = string.format("<color=#889595FF>%s</color>", str)
	end

	local isInScene = IGame.EntityClient:GetMapID() == self.m_MapID
	controls.m_InSceneImg.gameObject:SetActive(isInScene)
end
------------------------------------------------------------
return WorldMapItem