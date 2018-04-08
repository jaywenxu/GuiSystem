

local GoodsInfo = UIControl:new
{
	windowName 	= "GoodsInfo",
	
}
local this = GoodsInfo

function GoodsInfo:Init()
	
end

function GoodsInfo:Attach(obj)
	UIControl.Attach(self, obj)
	
end


-------------------------------------------------------------------
-- 清空
-------------------------------------------------------------------
function GoodsInfo:Clean()		
	self.Controls.m_GoodsNameText.text = ""
	self.Controls.m_GoodsDescText.text = ""
	self.Controls.m_GoodsEffectText.text = ""
	
end

function GoodsInfo:SetActive(b)
	self.Controls.m_GoodsNameText.gameObject:SetActive(b)
	self.Controls.m_GoodsDescText.gameObject:SetActive(b)
	self.Controls.m_GoodsEffectText.gameObject:SetActive(b)
	self.Controls.m_Image_GoodsBG.gameObject:SetActive(b)
	self.Controls.m_Image_GoodsIcon.gameObject:SetActive(b)
end

-------------------------------------------------------------------
-- 设置物品说明区
-- @param icon : 当前选中物品icon
-- @param index :
-- @param goodsName : 当前选中物品的名称
-- @param goodsDesc : 当前选中物品的描述
-------------------------------------------------------------------
function GoodsInfo:UpdateGoodsInfo(nType,index)
	
	-- 先清除数据
	self:Clean()
	
	local goods = IGame.PlazaClient:GetGoodsData(nType, index)
	local subGoods = IGame.PlazaClient:GetInfoByIndex(nType, index)
	
	if nil == goods or nil == subGoods then
		self:SetActive(false)
		return 
	end
	
	self:SetActive(true)
	
	if nil ~= index then 
		
		-- 设置物品背景
		local goodsType = subGoods.nSelectType
	
		if 1 == goodsType then  -- 装备						TODO
		--[[
			UIFunction.SetImageSprite(self.Controls.m_Image_GoodsIcon, AssetPath.TextureGUIPath..goods.lIconID1)
			
			
			local BaseLevel = goods.BaseLevel			-- 获取档次	
			local EquipQuality = goods.BaseLevel	    -- 获取品阶
		
			if nil == BaseLevel or nil == EquipQuality then 
				print("ChipItemCell:SetIcon")
				return 
			end
		
		
			if 1 == EquipQuality then 	-- 
				UIFunction.SetImageSprite(self.Controls.m_Image_GoodsBG , AssetPath_EquipColor[1])
			elseif 2 == EquipQuality then 	
			
				if BaseLevel < 5 then 
					UIFunction.SetImageSprite(self.Controls.m_Image_GoodsBG , AssetPath_EquipColor["2_4"])
				else
					UIFunction.SetImageSprite(self.Controls.m_Image_GoodsBG , AssetPath_EquipColor["2_5"])
				end
			
			
			elseif 3 == EquipQuality then 
				if BaseLevel < 6 then 
					UIFunction.SetImageSprite(self.Controls.m_Image_GoodsBG , AssetPath_EquipColor["3_5"])
				else
					UIFunction.SetImageSprite(self.Controls.m_Image_GoodsBG , AssetPath_EquipColor["3_6"])
				end
			
			elseif 4 == EquipQuality then 	
				if BaseLevel < 7 then 
					UIFunction.SetImageSprite(self.Controls.m_Image_GoodsBG , AssetPath_EquipColor["4_6"])
				else
					UIFunction.SetImageSprite(self.Controls.m_Image_GoodsBG , AssetPath_EquipColor["4_7"])
				end
			
			end--]]
		
		elseif 2 == goodsType then -- 物品
			UIFunction.SetImageSprite(self.Controls.m_Image_GoodsIcon , AssetPath.TextureGUIPath..goods.lIconID1)	
			local goodsBgPath = goods.lIconID2
			UIFunction.SetImageSprite(self.Controls.m_Image_GoodsBG , AssetPath.TextureGUIPath..goodsBgPath)	
		end
	end
	
	local buyLevel = subGoods.nBuyLevel
	
	local pHero = GetHero()
	if not pHero then
		return
	end
	
	local curLevel = pHero:GetNumProp(CREATURE_PROP_LEVEL)
	
	if curLevel < buyLevel[1] then
		self.Controls.m_BuyLevelText.gameObject:SetActive(true)
		self.Controls.m_BuyLevelText.text = buyLevel[1].."~"..buyLevel[2]
	else
		self.Controls.m_BuyLevelText.gameObject:SetActive(false)
	end
	
	self.Controls.m_BuyLevelText.text = buyLevel[1].."~"..buyLevel[2]
	
	self.Controls.m_GoodsLevelLimitText.text = ""
	if goods.nShowType == 0 then
		self.Controls.m_GoodsHaveNumText.text = ""
		local szEffectText = goods.subDesc1 or ""
		if szEffectText ~= "" and goods.subDesc2 then
			szEffectText = szEffectText .. "\n"..goods.subDesc2
		end
		self.Controls.m_GoodsEffectText.text = szEffectText
	else
		self.Controls.m_GoodsEffectText.text = ""
		self.Controls.m_GoodsHaveNumText.text = string.format("拥有<color=#10A41B>%d</color>个", GameHelp:GetHeroGoodsNum(goods.lGoodsID))
		local pGoodsScheme = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goods.lGoodsID)
		if pGoodsScheme and pGoodsScheme.lAllowLevel > 0 then
			local szLimitLevel = pGoodsScheme.lAllowLevel.."级"
			if GameHelp:GetHeroLevel() < pGoodsScheme.lAllowLevel then
				szLimitLevel = string.format("<color=#e4595a>%d级</color>", pGoodsScheme.lAllowLevel)
			end
			self.Controls.m_GoodsLevelLimitText.text = szLimitLevel
		end
	end
	
	self.Controls.m_GoodsNameText.text = string.format("<color=#%s>%s</color>",AssetPath_GoodsQualityColor[goods.lBaseLevel],goods.szName) or ""
	self.Controls.m_GoodsDescText.text = goods.szDesc or ""
	self.Controls.m_GoodsDescText.text = string.gsub(goods.szDesc,"\\n", '\n') --goods.szDesc
	--self.Controls.m_GoodsDescText.text = string.gsub(self.Controls.m_GoodsDescText.text,"\\", '')
	return true
end	



return this