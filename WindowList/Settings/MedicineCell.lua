-------------------------------------------------------------------
-- @Author: XieXiaoMei
-- @Date:   2017-08-11 16:18:57
-- @Vers:	1.0
-- @Desc:	自动吃药药品元素
-------------------------------------------------------------------

local MedicineCell = UIControl:new
{
	windowName      = "MedicineCell",

	m_GoodsID 		= 0,

	m_UseLevel 		= 0,

	m_UID 			= 0,	

	m_CellBaseColors = {},
	
	m_NeedBuy 		= false				-- 是否需要购买
}

-- 元素底颜色十六进制定义
local CellBaseColorHexs = 
{
	Normal = "0xffffffff",
	Gray = "0xB0B0AEB0",
}

------------------------------------------------------------------------------
function MedicineCell:Attach( obj )
	UIControl.Attach(self,obj)

	self:AddListener( self.Controls.m_UseBtn , "onClick" , self.OnBtnUseClicked , self )
    self:AddListener( self.Controls.m_BuyBtn , "onClick" , self.OnBtnBuyClicked , self )
	
	for k, v in pairs(CellBaseColorHexs) do
		local color = Color:New()
		color:FromHexadecimal(v, "as")
		self.m_CellBaseColors[k] = color
	end
end

------------------------------------------------------------------------------
function MedicineCell:OnDestroy()
	UIControl.OnDestroy(self)

	self.m_BtnCallback = nil

	table_release(self)
end

------------------------------------------------------------------------------
-- 设置数据
-- @ goodsCfg 	: 商品配置表
-- @ num 		: 数量
-- @ btnData 	: 按钮数据
-- {
-- 		visible : 是否显示
-- 		btnTxt  : 按钮文字
-- 		callback: 按钮回调
-- }
function MedicineCell:SetData(goodsCfg, extraData)
	local controls = self.Controls

	-- 物品图标
	local imagePath = AssetPath.TextureGUIPath..goodsCfg.lIconID1
	UIFunction.SetImageSprite( controls.m_IconImg , imagePath )

	-- 物品边框
	local imageBgPath = AssetPath.TextureGUIPath..goodsCfg.lIconID2
	UIFunction.SetImageSprite( controls.m_QualityImg , imageBgPath )

	controls.m_NameTxt.text = goodsCfg.szName

	controls.m_DescTxt.text = goodsCfg.szDesc

	self.m_GoodsID = goodsCfg.lGoodsID

	self.m_UseLevel = goodsCfg.lAllowLevel

	self.m_UID = extraData.uid

	self:RefreshNums(extraData)
end

------------------------------------------------------------------------------
-- 刷新数量
function MedicineCell:RefreshNums(extraData)
	local controls = self.Controls

	local bIsMedicine = extraData.bIsMedicine
	local youxian = false
	if bIsMedicine then
		if extraData.bRecommend then
			youxian = true
		end

		if self.m_UseLevel > GetHero():GetNumProp(CREATURE_PROP_LEVEL) then
			controls.m_LevelTxt.text = string.format("<color=#E4595AFF>%d级</color>", self.m_UseLevel)
		else
			controls.m_LevelTxt.text = string.format("<color=#10A41BFF>%d级</color>", self.m_UseLevel)
		end

	end
	controls.m_LevelImg.gameObject:SetActive(youxian)
	controls.m_LevelTxt.gameObject:SetActive(bIsMedicine)
	
	local str = ""
	local bHasNum = extraData.num > 0
	if bHasNum then
		str = extraData.num
	end
	controls.m_NumberTxt.text = str

	controls.m_IconMaskImg.gameObject:SetActive(not bHasNum)
	
	controls.m_AddImg.gameObject:SetActive(not bHasNum)
	
	self.m_NeedBuy = not bHasNum
	
	controls.m_UseBtn.gameObject:SetActive(not bIsMedicine and bHasNum)

end

------------------------------------------------------------------------------
-- 操作按钮回调
function MedicineCell:OnBtnBuyClicked()
	local subInfo = {
		bShowBtnType	= 2, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
		ScrTrans = self.transform,	-- 源预设
	}
    UIManager.GoodsTooltipsWindow:SetGoodsInfo(self.m_GoodsID, subInfo )
end

------------------------------------------------------------------------------
-- 操作按钮回调
function MedicineCell:OnBtnUseClicked()
	IGame.SkepClient:RequestUseItem(self.m_UID)
end

------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- 回收元素
function MedicineCell:RecycleItem()
	rkt.GResources.RecycleGameObject(self.transform.gameObject)

	self.m_BtnCallback = nil
end

------------------------------------------------------------------------------

return MedicineCell
