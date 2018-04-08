--/******************************************************************
--** 文件名:    RideGoodsItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    何水大(765865368@qq.com)
--** 日  期:    2017-12-09
--** 版  本:    1.0
--** 描  述:    生活技能坐骑物品对应的Item
--** 应  用:  
--******************************************************************/

local RideGoodsItem = UIControl:new
{
    windowName = "RideGoodsItem",
	m_RideID = 0, -- 坐骑ID
	m_group = nil,
	m_goodsID = 0,
}

function RideGoodsItem:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	local controls = self.Controls
	self.onItemClick = function(isOn) self:OnItemClick(isOn) end
	controls.m_toggle.group = self.m_group
	controls.m_toggle.onValueChanged:AddListener(self.onItemClick )
end

-- 更新物品信息
function RideGoodsItem:UpdateItem(rideID, lock)
	local scheme = IGame.rktScheme:GetSchemeInfo(RIDE_CSV, rideID)
	if not scheme then
		uerror("RideGoodsItem:UpdateItem，坐骑ID不存在，id:" .. rideID)
		return
	end
	
	local curCfg = IGame.rktScheme:GetSchemeInfo(LIFESKILLTAME_CSV, rideID)
	if not curCfg then
		uerror("驯马配置文件LifeSkillTame.csv 配置错误，马匹ID：" .. rideID)
		return false
	end
	
	local goodsID = curCfg.GoodsID
	local goodScheme = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodsID)
	if not goodScheme then
		uerror("RideGoodsItem:UpdateItem，物品配置错误，ID:" .. goodsID)
		return false
	end
	
	self.m_RideID = rideID
	self.m_goodsID = goodsID
	
	UIFunction.SetImageSprite(self.Controls.m_GoodsIcon, AssetPath.TextureGUIPath..goodScheme.lIconID1)
	UIFunction.SetImageSprite(self.Controls.m_QualityIcon, AssetPath.TextureGUIPath..goodScheme.lIconID2)
	
	if lock then
		self.Controls.m_Lock.gameObject:SetActive(true)
	else
		self.Controls.m_Lock.gameObject:SetActive(false)
	end

end

-- 技能图标的点行为
function RideGoodsItem:OnItemClick()
	local eventData = {rideID = self.m_RideID}
	rktEventEngine.FireExecute(MSG_MODULEID_LIFESKILL, SOURCE_TYPE_SYSTEM, SKILL_UI_EVENT_LIFESKILL_RIDESELECT, eventData)
	
	if self.first then
		self.first = false
		return
	end
	
	local subInfo = {
		bShowBtnType	= 0, 	--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
		bBottomBtnType	= 1,
		ScrTrans = self.transform,	-- 源预设
	}
	UIManager.GoodsTooltipsWindow:SetGoodsInfo(self.m_goodsID, subInfo ) 
end

function RideGoodsItem:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end


function RideGoodsItem:SetGroup(group)
	self.m_group = group
end

-- 清除数据
function RideGoodsItem:CleanData()

	self.Controls.m_toggle.onValueChanged:RemoveListener(self.onItemClick )
	self.onItemClick = nil
	
end

-- 设置焦点
function RideGoodsItem:SetFocus(on, first)
	self.first = first
	self.Controls.m_toggle.isOn = on
end

return RideGoodsItem