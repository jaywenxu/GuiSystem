--*******************************************************************
--** 文件名:	GongGaoWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	周加财
--** 日  期:	2017-11-24
--** 版  本:	1.0
--** 描  述:	公告信息
--** 应  用:  
--*******************************************************************

local GonggaoItem = UIControl:new
{
	windowName = "GonggaoItem",
	m_CurRuleID = 0,
}

function GonggaoItem:Attach(obj)
	UIControl.Attach(self, obj)
	return self
end

function GonggaoItem:SetItemInfo(TxtData)
	local controls = self.Controls
	controls.m_Title.text = tostring("  "..TxtData.title)
	local szConnext = TxtData.content or ""		
	local Content = string_unescape_newline(szConnext)
	controls.m_Content.text = tostring(Content)
end

-------------------------------------------------------
local GongGaoWindow = UIWindow:new
{
	windowName  = "GongGaoWindow",
	m_GonggaoList = {},
}

function GongGaoWindow:Init()
end

function GongGaoWindow:OnAttach(obj)
	UIWindow.OnAttach(self, obj)	
	
	local controls = self.Controls
	
	controls.m_Close.onClick:AddListener(handler(self, self.OnCloseBtnClick))
    self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))	
	-- controls.m_CloseBg.onClick:AddListener(handler(self, self.OnCloseBtnClick))
	controls.m_QueDingBtn.onClick:AddListener(handler(self, self.OnCloseBtnClick))
	self:InitData()
	self:CreateItemList()
end

function GongGaoWindow:SetItemInfo(idx, listCell)
	local behav = listCell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	local item = behav.LuaObject
	if item == nil then
		return
	end
	
	if nil ~= item and item.windowName == "GonggaoItem" then 
		item:SetItemInfo(self.m_GonggaoList[idx])
	end
end

function GongGaoWindow:CreateItemList()
	
	local callback = function(path , obj , index)
		local idx = tonumber(index)
		obj.transform:SetParent(self.Controls.m_GonggaoGrid.transform, false)
		local item = GonggaoItem:new({})
		item:Attach(obj)			
		item:SetItemInfo(self.m_GonggaoList[idx])
	end
	
	local nObjCount = self.Controls.m_GonggaoGrid.transform.childCount
	
	local nItemCount = table_count(self.m_GonggaoList)
	
	if nItemCount <= nObjCount then
		for i = 1, nItemCount do 
			-- 刷新
			local listCell = self.Controls.m_GonggaoGrid:GetChild(i-1)
			listCell.gameObject:SetActive(true)
			self:SetItemInfo(i, listCell)	
		end
		
		for i = nItemCount + 1, nObjCount do 
			-- 隐藏
			local listCell = self.Controls.m_GonggaoGrid:GetChild(i-1)
			listCell.gameObject:SetActive(false)
		end
	else
		for i = 1, nObjCount do 
			-- 刷新
			local listCell = self.Controls.m_GonggaoGrid:GetChild(i-1)
			listCell.gameObject:SetActive(true)
			self:SetItemInfo(i, listCell)	
		end

		for i = nObjCount + 1, nItemCount do 
			-- 创建
			rkt.GResources.FetchGameObjectAsync(GuiAssetList.Login.GonggaoItem , callback, i, AssetLoadPriority.GuiNormal )
		end
	end
end

function GongGaoWindow:InitData()
	
	self.m_GonggaoList = {}
	local tmpTable = IGame.HttpController:GetAnnouncements()
	if not tmpTable then
		return
	end
	copy_table( self.m_GonggaoList, tmpTable )
end

function GongGaoWindow:ShowWindow()
	UIWindow.Show(self,true)
end

function GongGaoWindow:OnEnable()
	self:InitData()
	self:CreateItemList()
end

function GongGaoWindow:OnCloseBtnClick()
	self:Hide()
end

function GongGaoWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

return GongGaoWindow



