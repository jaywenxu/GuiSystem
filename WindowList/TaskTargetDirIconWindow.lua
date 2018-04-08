--任务目标朝向窗口
------------------------------------------------------------
local TaskTargetDirIconWindow = UIWindow:new
{
	windowName = "TaskTargetDirIconWindow" ,
	m_RepeatInterval = 200,						--重复时间间隔
	m_RepeatUpdatePosInterval = 20,				--更新位置时间间隔
	m_OneDivideRepeatInterval = 0,
	m_Angle = 0,								--旋转角度
	m_TargetPoint = nil,						--目标点
	m_Player = nil,								--玩家
	m_SceneCamera = nil,						--场景相机
	
	m_HideDistance = 15,							--距离怪物15米隐藏导航
}
------------------------------------------------------------
function TaskTargetDirIconWindow:SetTarget(targetPos)
	if targetPos == nil then
		return
	end
	self.m_TargetPoint = targetPos
end
------------------------------------------------------------
function TaskTargetDirIconWindow:SetTargetByUID(targetUID)
	if targetUID == nil then
		return
	end
	
end
------------------------------------------------------------
function TaskTargetDirIconWindow:SetPlayer()
	local pHero = IGame.EntityClient:GetHero()
	if pHero == nil then
		return 
	end
	self.m_Player =  pHero:GetEntityView().transform.gameObject
end
------------------------------------------------------------
--世界坐标朝向转换为UI朝向
function TaskTargetDirIconWindow:WorldTargetToUIRotation(target, player)
	if target == nil or player == nil or player.transform.gameObject == nil then
		return 0
	end
	
	if self.m_SceneCamera == nil then
		return 0
	end
	
	local dir = target - player.transform.position
	local corssVector = Vector3.Cross(player.transform.forward, dir)
	local angle = 0
	if corssVector.y > 0 then
		angle = 0 - Vector3.Angle(player.transform.forward, dir)
	else
		angle = Vector3.Angle(player.transform.forward, dir)
	end

	angle = angle + (self.m_SceneCamera.transform.localEulerAngles.y - player.transform.localEulerAngles.y)
	
	if angle > 360 or angle < -360 then
		angle = angle % 360
	end
	
	return angle
end
------------------------------------------------------------
function TaskTargetDirIconWindow:UpdateAngle()
	local pHero = IGame.EntityClient:GetHero()
	if pHero == nil then
		return 
	end
	self.m_Player =  pHero:GetEntityView().transform.gameObject
	if self.m_Player == nil then
		local pHero = IGame.EntityClient:GetHero()
		if pHero == nil then
			return 
		end
		self.m_Player =  pHero:GetEntityView().transform.gameObject
	end
	if self.Controls.m_RotateCenter == nil then
		return
	end
	if self.Controls.m_DirectionImage == nil then
		return
	end
	if self.m_TargetPoint == nil or self.m_Player == nil   then
		return
	end
	if self.m_SceneCamera == nil then
		return
	end

	if self.transform:GetSiblingIndex() ~= 0 then
		self.transform:SetSiblingIndex(0)
	end
	
	self.m_Angle = self:WorldTargetToUIRotation(self.m_TargetPoint, self.m_Player)
	local vec = Vector3.New(0,0,self.m_Angle)
    local offset = Mathf.DeltaAngle( self.Controls.m_DirectionImage.localEulerAngles.z , vec.z )
	
	if(Mathf.Abs(offset) > 30) then
		--uerror("--------"..offset)
		self.Controls.m_DirectionImage.localEulerAngles = vec
		self.Controls.m_RotateCenter.localEulerAngles = vec
	else
		UIFunction.DOTweenLocalRotate(self.Controls.m_DirectionImage.gameObject, vec, self.m_OneDivideRepeatInterval)
		UIFunction.DOTweenLocalRotate(self.Controls.m_RotateCenter.gameObject, vec, self.m_OneDivideRepeatInterval)
	end
end
------------------------------------------------------------
function TaskTargetDirIconWindow:UpdatePosition() 
	if self.Controls.m_RotatePosition == nil then
		return
	end
	if self.Controls.m_Icon == nil then
		return
	end	
	self.Controls.m_Icon.transform.position = self.Controls.m_RotatePosition.transform.position
end
------------------------------------------------------------
function TaskTargetDirIconWindow:Init()
	
end
------------------------------------------------------------
function TaskTargetDirIconWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	--self.m_TargetPoint =  GameObject.Find("Cube")
	self.m_OneDivideRepeatInterval = self.m_RepeatInterval / 1000
	
	self.callbackOnEnable = function() self:OnEnable() end
	self.unityBehaviour.onEnable:AddListener(self.callbackOnEnable)	

	self.HideWindow = function() self:HideWindows() end
	self.callbackOnDisable = function() self:OnDisable() end
	self.unityBehaviour.onDisable:AddListener(self.callbackOnDisable)	
	
	self.SetAngleFastImm = function() self:SetAngle() end
	rktEventEngine.SubscribeExecute( EVENT_CAMERA_CONTROLLER_UPDATE , SOURCE_TYPE_SYSTEM , 0 , self.SetAngleFastImm)
	
	self.LateShowWindow = function() self:LateShowImage() end	
	if not self.DisTanceCheckCB then
		self.DisTanceCheckCB = function() self:CheckDistance() end
	end
	
	self:OnEnable() 

	self:ShowImage()
end

function TaskTargetDirIconWindow:Show(bringTop )
	UIWindow.Show(self,bringTop)
	if not self.DisTanceCheckCB then
		self.DisTanceCheckCB = function() self:CheckDistance() end
	end
	self.isHiding = false
	--开始位置检测，小于5秒就渐变隐藏
	rktTimer.SetTimer(self.DisTanceCheckCB, 40, -1, "TaskTargetDirIconWindow:CheckDistance")
--	rktTimer.SetTimer(function() self:CheckDistance() end, 40, -1, "TaskTargetDirIconWindow:CheckDistance")
end

function TaskTargetDirIconWindow:HideWindows()
	self:Hide(true)
end

--距离检测
function TaskTargetDirIconWindow:CheckDistance()
	if not self.m_TargetPoint or not self.m_Player then 
		return
	end
	local distance = Vector3.Distance(self.m_Player.transform.position, self.m_TargetPoint)
	if distance <= self.m_HideDistance and not self.isHiding then
		self:FadeHide()
		rktTimer.KillTimer( self.DisTanceCheckCB)	
	end
end

function TaskTargetDirIconWindow:SetAngle()
	self.FastSetAngle = function() self:SetAngleFast() end
	rktTimer.SetTimer(self.FastSetAngle, 40, 1, "TaskTargetDirIconWindow:SetTimer")	
end
	
function TaskTargetDirIconWindow:SetAngleFast()
	local pHero = IGame.EntityClient:GetHero()
	if pHero == nil then
		return 
	end
	self.m_Player =  pHero:GetEntityView().transform.gameObject
	if self.m_Player  == nil then 
		return
	end
	self.m_Angle = self:WorldTargetToUIRotation(self.m_TargetPoint, self.m_Player)
	local vec = Vector3.New(0,0,self.m_Angle)
	
	if nil ~= self.Controls.m_DirectionImage then 
		self.Controls.m_DirectionImage.localEulerAngles = vec
	end
	if nil ~= self.Controls.m_RotateCenter then 
		self.Controls.m_RotateCenter.localEulerAngles = vec
	end
	
end
	

------------------------------------------------------------
function TaskTargetDirIconWindow:OnDestroy()
	
	rktTimer.KillTimer( self.m_AngleUpdateTimeHandler )	
	rktTimer.KillTimer( self.m_PositionUpdateTimeHandler )	
	rktTimer.KillTimer(self.FastSetAngle)
	rktEventEngine.UnSubscribeExecute( EVENT_CAMERA_CONTROLLER_UPDATE , SOURCE_TYPE_SYSTEM , 0 , self.SetAngleFastImm)
	rktTimer.KillTimer( self.tempUpdateAngle )	

	self.m_TargetPoint = nil						
	self.m_Player = nil								
	self.m_SceneCamera = nil						

	--self.unityBehaviour.onDisable:RemoveListener(self.callbackOnDisable)	
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------
function TaskTargetDirIconWindow:OnEnable() 
	self:SetPlayer()
	--print("aaaaaaaaaaaa "..self.transform:GetSiblingIndex())
	self.m_SceneCamera =  GameObject.Find("MainCameraController")
	self.transform:SetSiblingIndex(0)
	
	--设置定时器计算角度朝向
	self.m_AngleUpdateTimeHandler = function() self:UpdateAngle() end			--刷新npc icon
	
	rktTimer.SetTimer(self.m_AngleUpdateTimeHandler, self.m_RepeatInterval, -1, "TaskTargetDirIconWindow:SetTimer")		
		
	--设置定时器更新Icon位置
	self.m_PositionUpdateTimeHandler = function() self:UpdatePosition() end
	rktTimer.SetTimer(self.m_PositionUpdateTimeHandler, self.m_RepeatUpdatePosInterval, -1, "TaskTargetDirIconWindow:SetTimer")	
end


------------------------------------------------------------
function TaskTargetDirIconWindow:FadeHide()
	if self.isHiding then return end
	self.isHiding = true
	local anims = self.transform:GetComponentsInChildren(typeof(DG.Tweening.DOTweenAnimation))
	for	i = 0, anims.Length - 1 do
		anims[i]:DORestart(false)
	end
	rktTimer.SetTimer(self.HideWindow, 1000,1,"HideDirIconWindow")
end

function TaskTargetDirIconWindow:ShowImage()
    if not self:isLoaded() then
        return
    end

	local arrow = self.Controls.m_DirImage
	local bg = self.Controls.m_BgImage
	arrow.color = Color.New(arrow.color.r,arrow.color.g,arrow.color.b,1)		--还原透明度
	bg.color = Color.New(bg.color.r,bg.color.g,bg.color.b,1)
--	rktTimer.SetTimer(self.LateShowWindow,3000,1,"TaskTargetDirIconWindow:LateShowImage")
end

function TaskTargetDirIconWindow:LateShowImage()
	local arrow = self.Controls.m_DirImage
	local bg = self.Controls.m_BgImage
	arrow.color = Color.New(arrow.color.r,arrow.color.g,arrow.color.b,1)		--还原透明度
	bg.color = Color.New(bg.color.r,bg.color.g,bg.color.b,1)
end

------------------------------------------------------------
function TaskTargetDirIconWindow:OnDisable()
	self.transform:SetSiblingIndex(0)
	rktTimer.KillTimer( self.m_AngleUpdateTimeHandler )	
	rktTimer.KillTimer( self.m_PositionUpdateTimeHandler )
	rktTimer.KillTimer( self.tempUpdateAngle )	
	rktTimer.KillTimer( self.HideWindow )
	rktTimer.KillTimer( self.DisTanceCheckCB )		
end
------------------------------------------------------------
return TaskTargetDirIconWindow