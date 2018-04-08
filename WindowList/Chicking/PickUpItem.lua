
--雪域求生拾取物品item类

local PickUpItem = UIControl:new {
	windowName = "PickUpItem",
	m_index  = 0,
	m_itemInfo = nil,
}

function PickUpItem:Attach(obj)
	UIControl.Attach(self,obj)
	self.Controls.m_pickUpBtn.onClick:AddListener(function() self:OnClickPickUp() end)
end

--拾取物品
function PickUpItem:OnClickPickUp()
	GameHelp.PostServerRequest("RequestPubgPickGood(2,"..tostringEx(self.m_UID)..","..self.m_index..")")
end

function PickUpItem:RefreshUI(itemInfo,index,nUID)
	self.m_index = index
	self.m_itemInfo = itemInfo
	self.m_UID = nUID
	-- 实体并没有广播到客户端，因此需要根据服务器发送的数据来显示
	
	if itemInfo.nType == 1 then 
		local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, itemInfo.nGoodID)
		if schemeInfo == nil then 
			return
		end
		self.Controls.itemName.text = GameHelp.GetLeechdomColorName(itemInfo.nGoodID)
		local imagePath = AssetPath.TextureGUIPath..schemeInfo.lIconID1
		UIFunction.SetImageSprite( self.Controls.iconBg , imagePath )
		
		local imageBgPath = AssetPath.TextureGUIPath..schemeInfo.lIconID2
		UIFunction.SetImageSprite( self.Controls.icon , imageBgPath )
			
	else
		local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, itemInfo.nGoodID)
		if not schemeInfo then
			print("找不到物品配置，物品ID=", itemInfo.nGoodID)
			return
		end
		self.Controls.itemName.text = schemeInfo.szName
		local imagePath = AssetPath.TextureGUIPath .. schemeInfo.IconIDNormal
		UIFunction.SetImageSprite( self.Controls.icon , imagePath )
	end

end

return PickUpItem