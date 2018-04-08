-- @author	邓元豪
-- @desc	小地图窗口
-- @date	2017.03.20
------------------------------------------------------------
local MiniMapWindow = UIWindow:new
{
	windowName = "MiniMapWindow" ,
}
------------------------------------------------------------
function MiniMapWindow:Init()
	self.MiniMapWidget = require("GuiSystem.WindowList.MainHUD.MiniMapWidget"):new()    --加载小地图模块
end
------------------------------------------------------------
function MiniMapWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj,UIManager._MainHUDLayer)
	self.MiniMapWidget:Attach(self.Controls.miniMap.gameObject )
	return self
end

--刷新单个
function MiniMapWindow:RefreshIconByEntity(entity)
	if self.MiniMapWidget == nil or not self:isLoaded() or entity == nil then 
		return
	end
	self.MiniMapWidget:RefreshIconByEntityInfo(entity)
end

--刷新角色打点图标
function MiniMapWindow:RefreshPerSonIcon()
	if not self:isLoaded() then
		return
	end
	self.MiniMapWidget:RefreshPersonIcon()
end

--刷新怪物打点图标
function MiniMapWindow:RefreshMonsterIcon()
	if not self:isLoaded() then
		return
	end
	self.MiniMapWidget:RefreshMonsterIcon()
end


------------------------------------------------------------
function MiniMapWindow:GetMiniMapWdt()
	return self.MiniMapWidget
end

------------------------------------------------------------
function MiniMapWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------
return MiniMapWindow