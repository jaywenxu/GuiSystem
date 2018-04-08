
local ChipGoodsInfo = UIControl:new
{
	windowName 	= "ChipGoodsInfo",
	
}

local this = ChipGoodsInfo

function ChipGoodsInfo:Init()
	
end

function ChipGoodsInfo:Attach(obj)
	UIControl.Attach(self, obj)
	
end

function ChipGoodsInfo:isLoaded()
	return self.transform ~= nil
end

-------------------------------------------------------------------
-- 清空
-------------------------------------------------------------------
function ChipGoodsInfo:Clean()	
	self.Controls.m_GoodsNameText.text = ""
	self.Controls.m_GoodsDescText.text = ""
	self.Controls.m_GoodsEffectText.text = ""
	self.Controls.m_ExterGoodsDescText.text = ""
end

-------------------------------------------------------------------
-- 设置物品说明区
-- @param icon : 当前选中物品icon
-- @param index :
-- @param goodsName : 当前选中物品的名称
-- @param goodsDesc : 当前选中物品的描述
-------------------------------------------------------------------
function ChipGoodsInfo:UpdateExchangeGoodsInfo(index)
	if not self:isLoaded() then
		return
	end
	-- 先清除数据
	self:Clean()
	
	local goodsName,subDesc1,subDesc2 = IGame.ChipExchangeClient:GetGoodsName(index)
	local goodsDesc, showType, goodsID = IGame.ChipExchangeClient:GetGoodsDesc(index)	
	local icon 		= IGame.ChipExchangeClient:GetGoodsIcon(index)	
	local nameColor =nil
	if nil ~= icon then 
		icon = AssetPath.TextureGUIPath.. icon
		UIFunction.SetImageSprite(self.Controls.m_Image_GoodsIcon, icon)
	end
	
	local ChipType
	if nil ~= index then 
		
		-- 设置物品背景
		ChipType = IGame.ChipExchangeClient:GetChipTypeByIndex(index)

		if 1 == ChipType then  -- 装备
		
			local BaseLevel = IGame.ChipExchangeClient:GetGoodsBaseLevel(index)			-- 获取档次	
			
			local EquipQuality = IGame.ChipExchangeClient:GetEquipQualityByIndex(index)	-- 获取品阶
			
			nameColor = DColorDef.getNameColor(1,BaseLevel,EquipQuality)
			
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
			
			end
		
		elseif 2 == ChipType then -- 物品
		
			local goodsBgPath = IGame.ChipExchangeClient:GetGoodsBaseLevel(index)
			local level  = IGame.ChipExchangeClient:GetGoodsBaseRealLevel(index)
			nameColor = DColorDef.getNameColor(0,level)
			UIFunction.SetImageSprite(self.Controls.m_Image_GoodsBG , AssetPath.TextureGUIPath..goodsBgPath)	
		end
	end

	self.Controls.m_GoodsCountText.text = ""
	self.Controls.m_GoodsLevelLimitText.text = ""
	self.Controls.m_GoodsEffectText.text = ""
	self.Controls.m_ExterGoodsDescText.text = IGame.ChipExchangeClient:GetChipGoodsExterDesc(index)
	if 1 == ChipType then
		local szEffectText = subDesc1 or ""
		if szEffectText ~= "" and subDesc2 then
			szEffectText = szEffectText .. "\n"..subDesc2
		end
		self.Controls.m_GoodsEffectText.text = szEffectText
	elseif 2 == ChipType then				--物品
		if showType == 0 then				--显示描述
			local szEffectText = subDesc1 or ""
			if szEffectText ~= "" and subDesc2 then
				szEffectText = szEffectText .. "\n"..subDesc2
			end
			self.Controls.m_GoodsEffectText.text = szEffectText
		elseif showType == 1 then			--显示数量
		
			self.Controls.m_GoodsCountText.text = string.format("拥有<color=#10A41Bff>%d</color>个", GameHelp:GetHeroGoodsNum(goodsID))
			local pGoodsScheme = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodsID)
			if pGoodsScheme and pGoodsScheme.lAllowLevel > 0 then
				local szLimitLevel = pGoodsScheme.lAllowLevel.."级"
				if GameHelp:GetHeroLevel() < pGoodsScheme.lAllowLevel then
					szLimitLevel = string.format("<color=#e4595a>%d级</color>", pGoodsScheme.lAllowLevel)
				end
				self.Controls.m_GoodsLevelLimitText.text = szLimitLevel
			end
		end
	end
	
	self.Controls.m_GoodsNameText.text =string.format("<color=#%s>%s</color>", nameColor or "597993FF" ,  goodsName or "") 
	
	self.Controls.m_GoodsDescText.text = goodsDesc or ""
	
	self.Controls.m_GoodsDescText.text = string.gsub(self.Controls.m_GoodsDescText.text,"\\n", '\n')
	--self.Controls.m_GoodsDescText.text = string.gsub(self.Controls.m_GoodsDescText.text,"\\", '')
	
	return true
end	

return this