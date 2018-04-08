-----------------------------------------------------------------------------------------
-- author by fcc
-- 任务奖励格子
-----------------------------------------------------------------------------------------
local TaskPrizeGridCell = UIControl:new
{
	windowName = "TaskPrizeGridCell",
	m_prizeId,
	m_goodId,
}

function TaskPrizeGridCell:Attach( obj )
	UIControl.Attach(self,obj)
	self.callback_OnSelectChanged = function(on) self:OnSelectChanged(on) end
	self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))
    self.Controls.ItemToggle.onValueChanged:AddListener( self.callback_OnSelectChanged  ) 
	
	return self
end

function TaskPrizeGridCell:OnSelectChanged( on )
	if self.m_goodId then
		local subInfo = {
			bShowBtnType	= 0, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
			ScrTrans = self.Controls.m_itembg,	-- 源预设
		}
        UIManager.GoodsTooltipsWindow:SetGoodsInfo(self.m_goodId, subInfo )
		return
	end
	
	if not self.m_prizeId then
		return
	end
	
	local info = IGame.TaskSick:GetPrizeGoodsInfo(self.m_prizeId)
	if not info then
		return
	end
	local goodId = info.goodsID
	if not goodId then
		return
	end
	
	--先判断是不是药品
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodId)
	local imagePath
	-- 如果是药品
	if schemeInfo then
		local subInfo = {
			bShowBtnType	= 0, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
			ScrTrans = self.Controls.m_itembg,	-- 源预设
		}
		UIManager.GoodsTooltipsWindow:Show(true)
        UIManager.GoodsTooltipsWindow:SetGoodsInfo(goodId, subInfo )
		return
	end
	
	--判断是不是装备
	schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, goodId)
	-- 如果是装备
	if schemeInfo then
		local vector3 = self.transform.position
		local equipInfo = {}
		equipInfo[1] = "EQUIP"
		equipInfo[2] = info.goodsID
		equipInfo[3] = info.equipLevel
		equipInfo[4] = info.bindFlag
		equipInfo[5] = 0
		equipInfo[6] = info.propType
		equipInfo[7] = info.normalReinLevel
		equipInfo[8] = info.attachReinLevel

        local subInfo = {
    		bShowBtn		= 0,
    		bShowCompare	= false,
    		bRightBtnType   = 0,
        }

		UIManager.EquipTooltipsWindow:Show(true)
        UIManager.EquipTooltipsWindow:SetInfo(equipInfo,subInfo)
		return
	end
end

-- 设置奖励信息 根据奖励ID来设置
-- 奖励ID taskprize.csv
function TaskPrizeGridCell:SetPrizeInfo( prizeId)
	self.m_prizeId = prizeId
	local info = IGame.TaskSick:GetPrizeGoodsInfo(prizeId)
	if not info then
		return
	end
	local goodId = info.goodsID
	local num = info.nNum
	if num <= 1 then
		num = ""
	end
	if not goodId then
		return
	end
	--先判断是不是药品
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodId)
	local imagePath
	-- 如果是药品
	if schemeInfo then
		imagePath = AssetPath.TextureGUIPath..schemeInfo.lIconID1
		UIFunction.SetImageSprite( self.Controls.m_item , imagePath )
		-- 设置物品的背景框
		local imageBgPath = AssetPath_GoodsColor[tonumber(schemeInfo.lBaseLevel)]
		UIFunction.SetImageSprite( self.Controls.m_itemBG , imageBgPath )
		-- 设置物品数量
		self.Controls.m_num.text = num
		return
	end
	
	--判断是不是装备
	schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, goodId)
	-- 如果是装备
	if schemeInfo then
		imagePath = AssetPath.TextureGUIPath .. schemeInfo.IconIDNormal
		UIFunction.SetImageSprite( self.Controls.m_item , imagePath )
		-- 设置装备的背景框
		local info = IGame.TaskSick:GetPrizeGoodsInfo(self.m_prizeId)
		if info then
			local nQuality  = info.equipLevel
			local nAdditionalPropNum = table.getn( info.propType )
			local imageBgPath =  self:GetIconBgPath(nQuality, nAdditionalPropNum)
			UIFunction.SetImageSprite( self.Controls.m_itemBG , imageBgPath )
		end
		-- 设置物品数量
		self.Controls.m_num.text = num
		return
	end
	
end

-- 设置奖励信息，经验、银币、银两
function TaskPrizeGridCell:SetPrizeInfoEx( goodId,num )
	num = NumToWan(num)
	
	--先判断是不是药品
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodId)
	local imagePath
	-- 如果是药品
	if schemeInfo then
		imagePath = AssetPath.TextureGUIPath..schemeInfo.lIconID1
		UIFunction.SetImageSprite( self.Controls.m_item , imagePath )
		-- 设置物品的背景框
		local imageBgPath = AssetPath_GoodsColor[tonumber(schemeInfo.lBaseLevel)]
		UIFunction.SetImageSprite( self.Controls.m_itemBG , imageBgPath )
		-- 设置物品数量
        self.m_goodId = goodId
		self.Controls.m_num.text = num
		return
	end
	
end

-- 设置药品奖励信息
function TaskPrizeGridCell:SetPrizeExEx( goodId, num )
	if num <= 1 then
		num = ""
	end
	if not goodId then
		return
	end
	self.m_goodId = goodId
	--先判断是不是药品
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodId)
	local imagePath
	-- 如果是药品
	if schemeInfo then
		imagePath = AssetPath.TextureGUIPath..schemeInfo.lIconID1
		UIFunction.SetImageSprite( self.Controls.m_item , imagePath )
		-- 设置物品的背景框
		local imageBgPath = AssetPath_GoodsColor[tonumber(schemeInfo.lBaseLevel)]
		UIFunction.SetImageSprite( self.Controls.m_itemBG , imageBgPath )
		-- 设置物品数量
		self.Controls.m_num.text = num
		return
	end	
end

function TaskPrizeGridCell:GetIconBgPath(nQuality, nAdditionalPropNum)
	if  nQuality == 2 then
	if nAdditionalPropNum <= 4 then 
		nAdditionalPropNum = 4
	else 
		nAdditionalPropNum = 5
	end
	elseif nQuality == 3 then 
		if nAdditionalPropNum <= 5 then 
			nAdditionalPropNum = 5
		else 
			nAdditionalPropNum = 6
		end
	elseif nQuality == 4 then
		if nAdditionalPropNum <= 6 then 
			nAdditionalPropNum = 6
		else 
			nAdditionalPropNum = 7
		end	 
	end
	
	if nQuality == 1 then 
		imageBgPath = AssetPath_EquipColor[nQuality]
	else 
		imageBgPath = AssetPath_EquipColor[nQuality.."_"..nAdditionalPropNum]
	end
	
	return imageBgPath
end

function TaskPrizeGridCell:OnRecycle()
	self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callback_OnSelectChanged )
end

return TaskPrizeGridCell
