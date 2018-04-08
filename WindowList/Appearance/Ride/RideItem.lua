--/******************************************************************
--** 文件名:    RideItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    何水大(765865368@qq.com)
--** 日  期:    2017-12-08
--** 版  本:    1.0
--** 描  述:    坐骑列表Item
--** 应  用:  
--******************************************************************/

-- 坐骑获得途径
local RideGetType = 
{
	System = 0, -- 系统送的
	Tame = 1, -- 驯马
	Buy = 2, -- 购买
}

local RideItem = UIControl:new
{
    windowName = "RideItem",
	m_group = nil,
	m_RideID = 0, -- 坐骑ID
}

function RideItem:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	self.onItemClick = function(isOn) self:OnItemClick(isOn) end
	
	local controls = self.Controls
	controls.m_toggle.group = self.m_group
	controls.m_toggle.onValueChanged:AddListener(self.onItemClick )
	
	self:SubscribeEvent()
	
end

-- 事件绑定
function RideItem:SubscribeEvent()
	
end

-- 移除事件的绑定
function RideItem:UnSubscribeEvent()
	
end

function RideItem:UpdateItem(rideID)
	local ridePart = IGame.RideClient:GetHeroRidePart()
    if not ridePart then
        return
    end
	
	local rideInfo = ridePart:GetRidelInfo()
	if not rideInfo then
		return
	end
	
	local scheme = IGame.rktScheme:GetSchemeInfo(RIDE_CSV, rideID)
	if not scheme then
		uerror("【坐骑系统】RideItem:UpdateItem，坐骑ID不存在，id:" .. rideID)
		return
	end

	self.m_RideID = rideID
	local controls = self.Controls
	local isHave = table_indexof_match(rideInfo.m_SkinTable, function( v ) return rideID == v.m_SerialNO end)
	
	-- 已经拥有坐骑
	if isHave then
		controls.m_Got.gameObject:SetActive(true)
		controls.m_NotGot.gameObject:SetActive(false)
		controls.m_CanCatch.gameObject:SetActive(false)
	else
		controls.m_Got.gameObject:SetActive(false)
		
		-- 判断坐骑能不能捕捉
		if scheme.GetType == RideGetType.Tame then
			local skillLevel = -1
			local hero = GetHero() 
			if hero then 
				local skillPart = hero:GetEntityPart(ENTITYPART_PERSON_LIFESKILL)
				if skillPart then
					skillLevel = skillPart:GetLifeSkillLevel(emTame)
				end
			end
			
			local tameCfg = IGame.rktScheme:GetSchemeTable(LIFESKILLTAME_CSV)
			local canTame = false
			for k, v in pairs(tameCfg) do
				if rideID == v.ID then
					canTame = skillLevel >= v.Level
					break
				end
			end
			
			controls.m_NotGot.gameObject:SetActive(not canTame)
			controls.m_CanCatch.gameObject:SetActive(canTame)
		else
			controls.m_NotGot.gameObject:SetActive(true)
			controls.m_CanCatch.gameObject:SetActive(false)
		end
	end
	
	controls.m_TextName.text = scheme.Name
	
	for i = 1, 5 do
		controls["m_Star" .. i].gameObject:SetActive(false)
	end
	
	local quality = scheme.Quality
	for i = 1, quality do
		controls["m_Star" .. i].gameObject:SetActive(true)
	end
	
	-- m_ImageQualityIcon
	UIFunction.SetImageSprite(controls.m_ImageRideIcon, AssetPath.TextureGUIPath..scheme.HeadIcon)
	
	-- 当前坐骑
	controls.m_ImgCurrentRide.gameObject:SetActive(rideInfo.m_SerialNoUsing == rideID)
end

function RideItem:OnItemClick(state)
	if state == true then 
		rktEventEngine.FireExecute(ENTITYPART_CREATURE_RIDE, SOURCE_TYPE_SYSTEM, RIDE_UI_EVENT_RIDE_ITEM_CLICK, self.m_RideID)
	end

end


function RideItem:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	local toggle = self.Controls.m_toggle
	toggle.group = nil
	toggle.isOn = false
	
	UIControl.OnRecycle(self)
	
end

function RideItem:OnDestroy()
	self:UnSubscribeEvent()
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end


function RideItem:SetGroup(group)
	self.m_group = group
end

-- 清除数据
function RideItem:CleanData()

	self.Controls.m_toggle.onValueChanged:RemoveListener(self.onItemClick )
	self.onItemClick = nil
	
end

-- 设置焦点
function RideItem:SetFocus(on)
	self.Controls.m_toggle.isOn = on
end

return RideItem