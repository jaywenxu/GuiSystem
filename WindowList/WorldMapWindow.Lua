--世界地图组件
------------------------------------------------------------
local WorldMapItem = require("GuiSystem.WindowList.Map.WorldMapItem")    --加载sceneItem模块
------------------------------------------------------------
local WorldMapWindow = UIWindow:new
{
	 windowName = "WorldMapWindow" ,
	 m_MapItems = {}	,						--世界地图item列表
}
------------------------------------------------------------
function WorldMapWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self:InitUI()
end
------------------------------------------------------------
------------------------------------------------------------
function WorldMapWindow:InitUI()
	self:AddListener( self.unityBehaviour , "onEnable" , self.OnEnable , self )
    self:AddListener( self.Controls.m_BackButton , "onClick" , self.OnBackButtonClick, self )
    self:AddListener( self.Controls.m_ClanMapButton , "onClick" , self.OnSocietyButtonClick , self )

    self:setWorldMapIcons()
end
------------------------------------------------------------
function WorldMapWindow:setWorldMapIcons()
	local transform = self.Controls.m_MapBgTf
	local worldMapCsv = IGame.rktScheme:GetSchemeTable(WORLDMAP_CSV) or {}
	for k, v in pairs(worldMapCsv) do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.WorldMapItem,
			function (path , obj , ud)
				if nil ~= obj then
					obj.transform:SetParent(transform, false)
					local pos = Vector2.New(tonumber(v.worldMapPos[1]),tonumber(v.worldMapPos[2])) 
					obj.transform.localPosition = pos
					local item = WorldMapItem:new({})
					item:Attach( obj )
                    item:SetData( v )
					table.insert(self.m_MapItems, item)
				end
			end,
		nil, AssetLoadPriority.GuiNormal )
	end
end
------------------------------------------------------------
--当前组件启动时调用
function WorldMapWindow:OnEnable() 
	for k, item in ipairs(self.m_MapItems) do
		if item.unityBehaviour ~= nil then
			item:Refresh()
		end
	end	
end
------------------------------------------------------------
function WorldMapWindow:OnBackButtonClick() 
	self:Hide()
end
------------------------------------------------------------
--帮会地图按钮
function WorldMapWindow:OnSocietyButtonClick() 
	self:Hide()
	IGame.ClanClient:RequestEnterEctype()
end
------------------------------------------------------------
function WorldMapWindow:OnDestroy()
    UIWindow.OnDestroy(self)
    self.m_MapItems = {}
end
------------------------------------------------------------
return WorldMapWindow

