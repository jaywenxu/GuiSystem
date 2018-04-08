--/******************************************************************
--** 文件名:    BaiTanBuyLevelItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-26
--** 版  本:    1.0
--** 描  述:    摆摊购买窗口-等级下拉菜单-等级图标
--** 应  用:  
--******************************************************************/

local BaiTanBuyLevelItem = UIControl:new
{
    windowName = "BaiTanBuyLevelItem",
	
	m_LevelData = nil,		-- 图标对应的等级数据:SearchSmallTypeLevelData
}

function BaiTanBuyLevelItem:Attach(obj)
	
    UIControl.Attach(self,obj)
	
	self.onItemClick = function() self:OnItemClick() end
	self.Controls.m_ButtonItem.onClick:AddListener(self.onItemClick)
	
end

-- 更新图标
-- @levelData:等级段数据:SearchSmallTypeLevelData
function BaiTanBuyLevelItem:UpdateItem(levelData)
	
    self.transform.gameObject:SetActive(true)
	
	self.m_LevelData = levelData
	
	self.Controls.m_TextLevelDesc.text = string.format("%d~%d级", levelData.m_LeftLevel, levelData.m_RightLevel)
	
end

function BaiTanBuyLevelItem:OnItemClick()
	
	rktEventEngine.FireExecute(MSG_MODULEID_EXCHANGE, SOURCE_TYPE_SYSTEM, EXCAHNGE_UI_EVENT_LEVEL_ITEM_CLICK, self.m_LevelData.m_LevelId)
	
end

function BaiTanBuyLevelItem:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function BaiTanBuyLevelItem:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function BaiTanBuyLevelItem:CleanData()
	
	self.Controls.m_ButtonItem.onClick:RemoveListener(self.onItemClick )
	self.onItemClick = nil
	
end

return BaiTanBuyLevelItem