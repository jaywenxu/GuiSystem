-- 帮会建筑主界面的建筑Item
-- @Author: LiaoJunXi
-- @Date:   2017-08-31 12:25:45
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-26 12:50:45

------------ BlackBoard -------------
local ClanBuildingItem = UIControl:new
{
	windowName         = "ClanBuildingItem",
	
	m_OnToggleItemCallback = nil,
	m_SelectedCallback = nil
}
-------------------------------------

-------------------- 公用重载的方法 --------------------
local this = ClanBuildingItem

function ClanBuildingItem:Attach( obj )
	UIControl.Attach(self, obj)

	-- 点击
	self.m_OnToggleItemCallback = function(on) self:OnSelectChanged(on) end
	self.Controls.toggle.onValueChanged:AddListener(self.m_OnToggleItemCallback)
end

function ClanBuildingItem:OnRecycle()
	if self.m_OnToggleItemCallback then
		self.Controls.toggle.onValueChanged:RemoveListener(self.m_OnToggleItemCallback)
	end
	--self.m_OnToggleItemCallback = nil
	self.m_SelectedCallback = nil

	UIControl.OnRecycle(self)
	table_release(self)
end

function ClanBuildingItem:OnDestroy()
	if self.m_OnToggleItemCallback then
		self.Controls.toggle.onValueChanged:RemoveListener(self.m_OnToggleItemCallback)
	end
	self.m_OnToggleItemCallback = nil
	self.m_SelectedCallback = nil
	
	UIControl.OnDestroy(self)
	table_release(self)
end
---------------------------------------------------------

------------ 设置程序间交互的方法 ------------
-- 设置选中回调
function ClanBuildingItem:SetSelectCallback( func_cb )
	self.m_SelectedCallback = func_cb
end
-----------------------------------------------

---------- 设置界面交互的方法 ----------
-- 点击Ceil
function ClanBuildingItem:OnSelectChanged(on)
	if self.m_SelectedCallback and on then
		self.m_SelectedCallback()
	end
end
----------------------------------------

---------- 设置界面显示 ----------
function ClanBuildingItem:SetItemContent(data)
	if not data then return end
	if not data.m_Visible then 
		self:Hide() 
		return 
	else
		self:Show()
	end
	
	local controls = self.Controls
	controls.m_LevTxt.text = GetValuable(data.m_Unlock, data.nLevel .. "级", "<color=#e4595a>未解锁</color>")
	if data.m_IsMaxLev then
		controls.m_LevTxt.text = data.nLevel .. "级(已满)"
		local nLevBgRect = controls.m_LevBG:GetComponent(typeof(RectTransform)) 
		nLevBgRect.sizeDelta = Vector2.New(228,nLevBgRect.sizeDelta.y)
	end
	
	if not IsNilOrEmpty(data.m_LevCfg.Icon) then	
		UIFunction.SetImageSprite(self.Controls.m_IconImg, 
		GuiAssetList.GuiRootTexturePath .. data.m_LevCfg.Icon)
	end
	
	UIFunction.SetImageGray(self.Controls.m_IconImg, not data.m_Unlock)
	UIFunction.SetImageGray(self.Controls.m_NameImg, not data.m_Unlock)
end
-----------------------------------

return ClanBuildingItem