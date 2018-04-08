--*******************************************************************
--** 文件名:	CommonGuideWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-02-22
--** 版  本:	1.0
--** 描  述:	活动规则介绍
--** 应  用:  
--*******************************************************************

local GuideItem = UIControl:new
{
	windowName = "GuideItem",
	m_CurRuleID = 0,
}

function GuideItem:Attach(obj)
	UIControl.Attach(self, obj)
	return self
end

function GuideItem:SetItemInfo(TxtData)
	local controls = self.Controls
	controls.m_Title.text = tostring("  "..TxtData.Title)
			
	local Content = string_unescape_newline(TxtData.Content)
	controls.m_Content.text = tostring(Content)
end

-------------------------------------------------------
local CommonGuideWindow = UIWindow:new
{
	windowName  = "CommonGuideWindow",
	m_GuideList = {},
	m_CurHuoDongID = 0,
}

function CommonGuideWindow:Init()
end

function CommonGuideWindow:OnAttach(obj)
	UIWindow.OnAttach(self, obj)	
	
	local controls = self.Controls
	
	controls.m_Close.onClick:AddListener(handler(self, self.OnCloseBtnClick))
    self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))	
	controls.m_CloseBg.onClick:AddListener(handler(self, self.OnCloseBtnClick))
	self:InitData()
	self:CreateItemList()
end

function CommonGuideWindow:SetItemInfo(idx, listCell)
	local behav = listCell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	local item = behav.LuaObject
	if item == nil then
		return
	end
	
	if nil ~= item and item.windowName == "GuideItem" then 
		item:SetItemInfo(self.m_GuideList[idx])
	end
end

function CommonGuideWindow:CreateItemList()
	
	local callback = function(path , obj , index)
		local idx = tonumber(index)
		obj.transform:SetParent(self.Controls.m_GuideGrid.transform, false)
		local item = GuideItem:new({})
		item:Attach(obj)			
		item:SetItemInfo(self.m_GuideList[idx])
	end
	
	local nObjCount = self.Controls.m_GuideGrid.transform.childCount
	local nItemCount = table_count(self.m_GuideList)
	
	if nItemCount <= nObjCount then
		for i = 1, nItemCount do 
			-- 刷新
			local listCell = self.Controls.m_GuideGrid:GetChild(i-1)
			listCell.gameObject:SetActive(true)
			self:SetItemInfo(i, listCell)	
		end
		
		for i = nItemCount + 1, nObjCount do 
			-- 隐藏
			local listCell = self.Controls.m_GuideGrid:GetChild(i-1)
			listCell.gameObject:SetActive(false)
		end
	else
		for i = 1, nObjCount do 
			-- 刷新
			local listCell = self.Controls.m_GuideGrid:GetChild(i-1)
			listCell.gameObject:SetActive(true)
			self:SetItemInfo(i, listCell)	
		end

		for i = nObjCount + 1, nItemCount do 
			-- 创建
			rkt.GResources.FetchGameObjectAsync(GuiAssetList.HuoDong.GuideItem , callback, i, AssetLoadPriority.GuiNormal )
		end
	end
end

function CommonGuideWindow:InitData()
	
	self.m_GuideList = {}

	local DataCfg = IGame.rktScheme:GetSchemeInfo(COMMONGUIDE_CSV, self.m_CurRuleID)
	if nil == DataCfg then
		print("找不到描述配置", self.m_CurRuleID)
		return
	end
	
	local Title = split_string(DataCfg.RuleTitle,";",tostring)
	local Content = split_string(DataCfg.RuleContent,";",tostring)		
	
	for i = 1, table_count(Title) do
		local ItemData = {}	
		ItemData.Title = Title[i]
		ItemData.Content = Content[i]
		if Title[i] ~= nil and Content[i]~= nil then
			table.insert(self.m_GuideList, ItemData)
		end 
	end
end

function CommonGuideWindow:ShowWindow(RuleID)
	
	self.m_CurRuleID = RuleID
	
	UIWindow.Show(self,true)
end

function CommonGuideWindow:OnEnable()
	self:InitData()
	self:CreateItemList()
end

function CommonGuideWindow:OnCloseBtnClick()
	self:Hide()
end

function CommonGuideWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

return CommonGuideWindow



