-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    方称称
-- 日  期:    2017/06/09
-- 版  本:    1.0
-- 描  述:    货运任务窗口格子
-------------------------------------------------------------------

local FreightTaskGridCell = UIControl:new
{
	windowName = "FreightTaskGridCell",
	m_num = 1,					-- 第几个格子
	m_parent = nil,
	m_data = nil,  				-- { gridId = ,goodId = , num = , bangong = , yinliang = , exp = , factor = , isCollect = , monsterId = , mapId = , x = , y = z, state = }
	m_state = 0,				-- 1:完成  0：未完成 2:求助中
	m_goodIconImgPath = nil,
	m_goodFrameImgPath = nil,
	m_goodName,
	m_needNum = 0,
	m_ownNum = 0,
}
--m_CompleteIcon
function FreightTaskGridCell:Attach(obj)
	UIControl.Attach(self,obj)
	self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))
	self.Controls.ItemToggle.onValueChanged:AddListener( function(on) self:OnSelectChanged(on) end  ) 
	return self
end

function FreightTaskGridCell:SetParentWindow(parent)
	self.m_parent = parent
end

-- isHelpWindow:是否是帮助者界面
function FreightTaskGridCell:SetGridData(info,isHelpWindow)
	if info == nil then
		return
	end
	self.m_data = info
	self.m_num = info.gridId
	if self.m_data.goodId == nil then
		return
	end
	
	local goodId = self.m_data.goodId
	--先判断是不是药品
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodId)
	self.m_goodName = GameHelp.GetLeechdomColorName(goodId)
	local imagePath
	-- 如果是药品
	if schemeInfo then
		imagePath = AssetPath.TextureGUIPath..schemeInfo.lIconID1
		self.m_goodIconImgPath = imagePath
		UIFunction.SetImageSprite( self.Controls.m_goodIcon , imagePath )
		-- 设置物品的背景框
		local imageBgPath = AssetPath_GoodsColor[tonumber(schemeInfo.lBaseLevel)]
		self.m_goodFrameImgPath = imageBgPath
		UIFunction.SetImageSprite( self.Controls.m_bg , imageBgPath )
		self.m_state = self.m_data.state
		self.Controls.m_CompleteIcon.gameObject:SetActive(false)
		self.Controls.m_RedDot.gameObject:SetActive(false)
		local hero = GetHero()
		local packetPart = hero:GetEntityPart(ENTITYPART_PERSON_PACKET)
		local ownNum = packetPart:GetGoodNum(goodId)
		self.m_ownNum = ownNum
		self.m_needNum = self.m_data.num
		if isHelpWindow then	-- 如果是帮助填装者界面
			if self.m_data.state == 2 then   -- 如果该填充未完成
                self:SetCellGray(false)
				self.Controls.ItemToggle.interactable = true
				self.Controls.m_text.text = "<color=#10a41b>求助中</color>"  -- 设置物品数量
			elseif self.m_data.state == 0 then
				self:SetCellGray(true)
				self.Controls.ItemToggle.interactable = false
				self.Controls.m_text.text = "<color=#597993>未填装</color>"
			else -- 如果该填充完成
                self:SetCellGray(true)
				self.Controls.m_CompleteIcon.gameObject:SetActive(true)
				self.Controls.ItemToggle.interactable = false
				self.Controls.m_text.text = "<color=#597993>已填装</color>"
			end			
		else -- 如果是正常界面
            self:SetCellGray(false)
			self.Controls.ItemToggle.interactable = true
			if self.m_data.state ~= 1 then   -- 如果该填充未完成
				if ownNum < self.m_needNum then
					self.Controls.m_text.text = "<color=#E4595A>" .. ownNum .. "/" .. self.m_needNum .. "</color>"  -- 设置物品数量
				else
					self.Controls.m_RedDot.gameObject:SetActive(true)
					self.Controls.m_text.text = "<color=#597993>" .. ownNum .. "/" .. self.m_needNum .. "</color>"  -- 设置物品数量
				end
			else -- 如果该填充完成
				self.Controls.m_text.text = "<color=#597993>已填装</color>"
				self.Controls.m_CompleteIcon.gameObject:SetActive(true)
			end
		end
	end
	
end

function FreightTaskGridCell:SetCellGray(flag)
    -- 仅将物品图标，品质框，勾置灰
    UIFunction.SetImgComsGray(self.Controls.m_goodIcon, flag)
    UIFunction.SetImgComsGray(self.Controls.m_bg, flag)
    UIFunction.SetImgComsGray(self.Controls.m_CompleteIcon, flag)
end

function FreightTaskGridCell:OnSelectChanged( on )
	--uerror("FreightTaskGridCell:OnSelectChanged:")
	if on == false then
		return
	end
	self.m_parent:GridOnClick(self.m_num,self.m_goodIconImgPath,self.m_goodFrameImgPath,self.m_state,self.m_needNum,self.m_ownNum,self.m_goodName)
end

function FreightTaskGridCell:SetSelect( on )
	--uerror("FreightTaskGridCell:SetSelect:")
	self.Controls.ItemToggle.isOn = on
end

function FreightTaskGridCell:OnRecycle()
	
end

return FreightTaskGridCell