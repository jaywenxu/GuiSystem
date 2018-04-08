
-----------------------------灵兽阵真灵附体技能页面------------------------------


local PetGoodsItem = UIControl:new
{
	windowName = "PetGoodsItem",
	
	iconBtn_callback = nil, 		

	m_GoodsID = -1,								--缓存物品ID
	m_Num = 0, 									--当前显示数量
	m_Index = -1,								--索引
}



function PetGoodsItem:Attach(obj)
	UIControl.Attach(self,obj)
	self.BtnClickCB = function() self:OnIconBtnClick() end
	self.Controls.m_Btn.onClick:AddListener(self.BtnClickCB)
end

function PetGoodsItem:Show()
	UIControl.Show(self)
end

function PetGoodsItem:Hide( destroy )
	UIControl.Hide(self, destroy)
end

function PetGoodsItem:OnDestroy()
	iconBtn_callback = nil

	UIControl.OnDestroy(self)
end
------------------------------------------------------------------------------------------------------------------
function PetGoodsItem:SetIndex(index)
	self.m_Index = index
end

--设置选中状态
function PetGoodsItem:SetSelected(nSelect)
	self.Controls.m_Select.gameObject:SetActive(nSelect)
end

--刷新物品剩余数量
function PetGoodsItem:RefreshGoodsNum(show)
	if self.m_GoodsID <= 0 then 
		return
	end
	if not show then
		self.Controls.m_GoodsNumText.text = ""
		return
	end
	local num = GameHelp:GetHeroPacketGoodsNum(self.m_GoodsID)
	self.m_Num = num
	self.Controls.m_GoodsNumText.text = tostring(num)
end

--检测是否需要显示获取途径界面
function PetGoodsItem:CheckShowHowToGet()
	local haveNum =  GameHelp:GetHeroPacketGoodsNum(self.m_GoodsID)
	if haveNum >= self.m_Num then 
		return false
	elseif haveNum < self.m_Num then
		return true
	end
end

--设置物品数量
function PetGoodsItem:SetGoodsNum(num)
	self.m_Num = num
	self.Controls.m_GoodsNumText.text = tostring(num)
end

--设置ID
function PetGoodsItem:SetID(goodsID)
	self.m_GoodsID = goodsID
	local record = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodsID)
	if not record then return end
	UIFunction.SetImageSprite(self.Controls.m_PetGoodsIcon, AssetPath.TextureGUIPath .. record.lIconID1)
	UIFunction.SetImageSprite(self.Controls.m_PetGoodsBG, AssetPath.TextureGUIPath .. record.lIconID2)
end

--设置回调事件
function PetGoodsItem:SetClickCB(click_cb)
	self.iconBtn_callback = click_cb
end

--点击附体按钮回调事件
function PetGoodsItem:OnIconBtnClick()
	if self.iconBtn_callback ~= nil then
		self.iconBtn_callback(self)
	end
end

return PetGoodsItem