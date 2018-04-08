--/******************************************************************
--** 文件名:    LifeSkillNormalGoodsItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    何水大(765865368@qq.com)
--** 日  期:    2017-11-14
--** 版  本:    1.0
--** 描  述:    生活技能普通物品的图标脚本，主要用来更新物品信息和显示tips
--** 应  用:  
--******************************************************************/

local LifeSkillNormalGoodsItem = UIControl:new
{
    windowName = "LifeSkillNormalGoodsItem",
	m_goodsID = 0, -- 物品ID
}

function LifeSkillNormalGoodsItem:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	self.onItemClick = function() self:OnItemClick() end
	self.Controls.m_ClickBtn.onClick:AddListener(self.onItemClick )

	
end

-- 更新物品信息
-- @goodsID:物品ID
function LifeSkillNormalGoodsItem:UpdateItem(goodsID, lock)
	self.m_goodsID = goodsID
	
	local goodsScheme = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodsID)
	if not goodsScheme then
		uerror("没有找到物品配置id: " .. goodsID )
		return
	end
	
	UIFunction.SetImageSprite(self.Controls.m_GoodsIcon, AssetPath.TextureGUIPath..goodsScheme.lIconID1)
	UIFunction.SetImageSprite(self.Controls.m_QualityIcon, AssetPath.TextureGUIPath..goodsScheme.lIconID2)
	
	if lock then
		self.Controls.m_Lock.gameObject:SetActive(true)
	else
		self.Controls.m_Lock.gameObject:SetActive(false)
	end
end

-- 技能图标的点行为
function LifeSkillNormalGoodsItem:OnItemClick()
	local subInfo = {
		bShowBtnType	= 0, 	--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
		bBottomBtnType	= 1,
		ScrTrans = self.transform,	-- 源预设
	}
	UIManager.GoodsTooltipsWindow:SetGoodsInfo(self.m_goodsID, subInfo ) 
end

function LifeSkillNormalGoodsItem:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end


function LifeSkillNormalGoodsItem:SetGroup(group)
	self.m_group = group
end

-- 清除数据
function LifeSkillNormalGoodsItem:CleanData()

	self.Controls.m_ClickBtn.onClick:RemoveListener(self.onItemClick )
	self.onItemClick = nil
	
end

return LifeSkillNormalGoodsItem