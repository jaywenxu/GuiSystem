--/******************************************************************
--** 文件名:	DressCellItem.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	郝伟(751711994@qq.com)
--** 日  期:	2017-12-25
--** 版  本:	1.0
--** 描  述:	外观窗口-时装条目
--** 应  用:  
--******************************************************************/

local DressCellItem = UIControl:new
{
	windowName = "DressCellItem",
	
	m_OnToggleChangeCB = nil,							--toggle改变回调
	
	m_nType = 0, 										--当前分类
	m_index = 0, 										--当前是第几个
	m_DressID = 0,										--当前的时装ID
}

function DressCellItem:Attach(obj)
	UIControl.Attach(self,obj)
	
	-- 事件绑定
	self:SubscribeEvent()
end

-- 窗口销毁
function DressCellItem:OnDestroy()
    -- 移除事件的绑定
    self:UnSubscribeEvent()
	
    UIControl.OnDestroy(self)
end


-- 事件绑定
function DressCellItem:SubscribeEvent()
	--注册点击事件
	self.callback_OnSelectChanged = function(on) self:OnSelectChanged(on) end
	self.Controls.m_Toggle.onValueChanged:AddListener(self.callback_OnSelectChanged)
end

-- 移除事件的绑定
function DressCellItem:UnSubscribeEvent()
	
end

-- 显示窗口
function DressCellItem:ShowWindow()
	
	UIControl.Show(self)

end

-- 隐藏窗口
function DressCellItem:HideWindow()
	
	UIControl.Hide(self, false)
	
end
-----------------------------------------------------------------
--设置icon 
function DressCellItem:SetIcon(nPath)
	if nPath and nPath ~= "" then 
		UIFunction.SetImageSprite(self.Controls.m_DressIcon,AssetPath.TextureGUIPath..nPath, function()
			self.Controls.m_DressIcon:SetNativeSize()
			self:Show()
		end)
	end
end

--设置锁
function DressCellItem:SetLock(nLock)
	if nLock == nil then return end
	self.Controls.m_LockImg.gameObject:SetActive(nLock)
end

--设置toggle组
function DressCellItem:SetToggleGroup(nGroup)
	self.Controls.m_Toggle.group = nGroup
end

--设置选中回调
function DressCellItem:SetSelectCallback(func_cb)
	self.m_OnToggleChangeCB = func_cb
end

--toggle改变事件回调
function DressCellItem:OnSelectChanged(on)
	self.Controls.m_Select.gameObject:SetActive(on)
	if on and self.m_OnToggleChangeCB ~= nil then
		self.m_OnToggleChangeCB(self)
	end
end

--设置焦点
function DressCellItem:SetFocus(on)
	self.Controls.m_Toggle.isOn = on
end

--设置信息
function DressCellItem:SetItemCellInfo(nType, index)
	self.m_nType = nType
	self.m_index = index
	
	local item = IGame.AppearanceClient:GetItemInfoBy(nType,index)					--当前数据
	if not item then return end
	self.m_DressID = item.nAppearID
	self:SetIcon(item.nIconPath)
end

return DressCellItem