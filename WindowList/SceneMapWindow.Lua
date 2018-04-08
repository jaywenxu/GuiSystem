--场景地图的组件
------------------------------------------------------------
require("rkt.MapControl")
------------------------------------------------------------
local SceneMapWindow = UIWindow:new
{
	windowName = "SceneMapWindow" ,

	m_safetyCircleInfo = nil,
	m_dangerCircleInfo = nil,
}
------------------------------------------------------------
function SceneMapWindow:Init()
    self.SceneMapWidget = require("GuiSystem.WindowList.Map.SceneMapWidget"):new()
end
------------------------------------------------------------
function SceneMapWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
    self:AddListener( self.Controls.CloseButton , "onClick" , self.OnClosingButtonClick , self )
    self:AddListener( self.Controls.m_WorldMapButton , "onClick" , self.OnWorldMapButtonClick , self )
    self:AddListener( self.Controls.SocietyButton , "onClick" , self.OnSocietyButtonClick , self )
		
	self:RealDrawAllCircle()
	self.SceneMapWidget:Attach( self.Controls.m_SceneMapWidget.gameObject )
end
------------------------------------------------------------
function SceneMapWindow:OnDestroy()
	UIWindow.OnDestroy(self)
	self.m_safetyCircleInfo = nil
	self.m_dangerCircleInfo = nil
	
end
------------------------------------------------------------
function SceneMapWindow:Show(bringTop)
    UIWindow.Show(self,bringTop)
    IGame.MapEntityPos:RequestUpdatePoint()
end
------------------------------------------------------------
--场景地图关闭按钮
function SceneMapWindow:OnClosingButtonClick()
	self:Hide()
	
end
------------------------------------------------------------
function SceneMapWindow:OnWorldMapButtonClick()
	UIManager.WorldMapWindow:Show(true)
end

--画圈参数
--deMO:
--self.SceneMapWidget:DrawCircle(true,3,UIFunction.ConverRichColorToColor("FF0000"),Vector3.New(421.0, 248.0, 599.0),200,60)
--[[CircleInfo=
{
	isSafety =true,
	isShow = true，
	DrwaLineWidth = 3,
	LineColor =UIFunction.ConverRichColorToColor("FF0000"),
	Position =Vector3.New(421.0, 248.0, 599.0) ,
	Radius = 200,
	PointNum = 60
}]]--
--画圈的外部接口
function SceneMapWindow:DrawMapCircle(CircleInfo)
	if CircleInfo.isSafety then 
		self.m_safetyCircleInfo = CircleInfo
		
	else
		self.m_dangerCircleInfo = CircleInfo
	end
	
	self:RealDrawAllCircle()
end

function SceneMapWindow:RealDrawAllCircle()
	if self:isLoaded() and self.SceneMapWidget ~= nil then 
		if self.m_safetyCircleInfo ~= nil then 
			self.SceneMapWidget:DrawCircle(self.m_safetyCircleInfo.isShow,
			self.m_safetyCircleInfo.isSafety,self.m_safetyCircleInfo.DrwaLineWidth,
			self.m_safetyCircleInfo.LineColor,self.m_safetyCircleInfo.Position,
			self.m_safetyCircleInfo.Radius,self.m_safetyCircleInfo.PointNum)
		end
		if self.m_dangerCircleInfo ~= nil then 
			self.SceneMapWidget:DrawCircle(self.m_dangerCircleInfo.isShow,
			self.m_dangerCircleInfo.isSafety,self.m_dangerCircleInfo.DrwaLineWidth,
			self.m_dangerCircleInfo.LineColor,self.m_dangerCircleInfo.Position,
			self.m_dangerCircleInfo.Radius,self.m_dangerCircleInfo.PointNum)
		end
	end
end


--帮会地图按钮
function SceneMapWindow:OnSocietyButtonClick() 
	self:Hide()
	IGame.ClanClient:RequestEnterEctype()
end

------------------------------------------------------------
function SceneMapWindow:GetSceneWidget()
    return self.SceneMapWidget
end
------------------------------------------------------------
return SceneMapWindow
