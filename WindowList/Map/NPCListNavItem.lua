--场景地图NPCListNavItem组件
------------------------------------------------------------
local NPCListNavItem = UIControl:new
{
	windowName = "NPCListNavItem" ,
	m_Navigation = nil,	--导航信息项
}

------------------------------------------------------------
-- 初始化
function NPCListNavItem:Attach( obj )
	UIControl.Attach(self,obj)
	
	self:AddListener(self.Controls.m_ItemBtn, "onClick", self.OnBtnItemClicked, self)

	return self
end

------------------------------------------------------------
-- 回收自身
function NPCListNavItem:RecycleItem()
	if self.transform == nil then
		return
	end
	rkt.GResources.RecycleGameObject(self.transform.gameObject)
end


function NPCListNavItem:SetSelectImageActive(state)
	self.Controls.m_selectImage.gameObject:SetActive(state)
	self.Controls.m_selectName.gameObject:SetActive(state)
	self.Controls.m_name.gameObject:SetActive( not state)
end

------------------------------------------------------------
-- 初始化数据
function NPCListNavItem:InitItem(navigation)
	self.Controls.m_NameTxt.text = navigation.szShortCutName
	self.Controls.m_selectText.text = navigation.szShortCutName
	self.m_Navigation = navigation
	self.Controls.m_selectImage.gameObject:SetActive(false)
	self.Controls.m_selectName.gameObject:SetActive(false)
end

------------------------------------------------------------
--监听点击回调，去往指定npc，与npc对话
function NPCListNavItem:OnBtnItemClicked()
	local sceneWdt = UIManager.SceneMapWindow:GetSceneWidget()
	if sceneWdt then
		sceneWdt:GotoChatWithNpc(self.m_Navigation,self)
		self:SetSelectImageActive(true)
	end
end


----------------------------------------API-----------------------------------------

-- 创建一个Item
function NPCListNavItem.CreateItem(data, parentTf)
	--异步加载NPC列表项
	local item = NPCListNavItem:new()
	rkt.GResources.FetchGameObjectAsync(GuiAssetList.NPCListItem,
		function (path , obj , ud)
		if nil == obj then
			print("Failed to Load the object")
			return
		else
			obj.transform:SetParent(parentTf,false)

			item:Attach(obj)

			item:InitItem(data)
		end
	end,
	nil, AssetLoadPriority.GuiNormal )
	
	return item
end

------------------------------------------------------------
return NPCListNavItem
