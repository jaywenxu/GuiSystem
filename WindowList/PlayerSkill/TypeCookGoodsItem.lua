--/******************************************************************
--** 文件名:    TypeCookGoodsItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    何水大(765865368@qq.com)
--** 日  期:    2017-11-16
--** 版  本:    1.0
--** 描  述:    生活技能--烹饪类型Item
--** 应  用:  
--******************************************************************/
local LifeSkillCookGoodsItem = require("GuiSystem.WindowList.PlayerSkill.LifeSkillCookGoodsItem")
local MAX_COOKGOODS_NUM = 8
local TypeCookGoodsItem = UIControl:new
{
    windowName = "TypeCookGoodsItem",
	m_goodsItem = {},
	m_goodsCount = 0,
	m_config = {},
	m_group = nil,
}

function TypeCookGoodsItem:Attach(obj)
    UIControl.Attach(self,obj)
	local controls = self.Controls
	for i = 1, MAX_COOKGOODS_NUM do
		local item = LifeSkillCookGoodsItem:new() 
		self.m_goodsItem[i] = item
		item:SetGroup(self.m_group)
		item:Attach(controls["m_Goods" .. i].gameObject)
	end
	
end

function TypeCookGoodsItem:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function TypeCookGoodsItem:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function TypeCookGoodsItem:CleanData()

end

-- bFirst, 初始化时选中第一个物品
function TypeCookGoodsItem:SetData(type, bFirst)
	local Cfg = IGame.rktScheme:GetSchemeTable(LIFESKILLCOOK_CSV)
	self.m_config = Cfg
	local isSetName = false
	
	-- 获得烹饪物品并排序
	local goodsInfo = {}
	for _, oneCfg in pairs (Cfg) do
		if oneCfg.Type == type then
			if not isSetName then
				self.Controls.m_TypeName.text = oneCfg.TypeName
				isSetName = true
			end

			table.insert(goodsInfo, oneCfg.ID)
		end
	end
	
	table.sort(goodsInfo)
	
	for _, nID in pairs (goodsInfo) do	
		local count = self.m_goodsCount + 1
		if count > MAX_COOKGOODS_NUM then
			return
		end
			
		self.m_goodsItem[count]:UpdateItem(nID)
		if bFirst and self.m_goodsItem[count]:IsTuiJian()  then
			self.m_goodsItem[count]:SetFocus(true)
			bFirst = false
		end
		self.m_goodsItem[count]:Show()
		self.m_goodsCount = count
	end
	
end

function TypeCookGoodsItem:SetGroup(group)
	self.m_group = group
end

return TypeCookGoodsItem