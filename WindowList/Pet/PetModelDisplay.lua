
-----------------------------灵兽模型展示----------------------------
local PetModelDisplay = UIControl:new
{ 
    windowName = "PetModelDisplay",
	m_dis = nil,
	m_showAniOver = false,
	UID = 60,						--灵兽默认UID
	m_modelPosition = Vector3.zero
}

local this = PetModelDisplay


local petShowModelCfg = require("GuiSystem.WindowList.Pet.PetModelShowDefine")


function PetModelDisplay:Attach( obj )
	UIControl.Attach(self,obj)
	
	if nil ~=self.Controls.m_PetRawImage then 
		self.Controls.PetRawImage = self.Controls.m_PetRawImage:GetComponent(typeof(RawImage))
	end

	self.callbackTimerPlayShowShowAniOver = function()self:TimerPlayShowShowAniOver() end
	self.callback_OnEntityPartAttached = handler( self , self.OnEntityPartAttached )
	
	self.DragModelCB = function(eventData) self:DragModel(eventData) end
	
	-- 注册模型事件    				放在用的地方注册
	UIFunction.AddEventTriggerListener(self.Controls.DragItem,EventTriggerType.Drag,function(eventData) self:DragModel(eventData) end)
	--[[UIFunction.AddEventTriggerListener(self.Controls.PetRawImage,EventTriggerType.PointerClick,function(eventData) self:OnClickModel(eventData) end)--]]
end

-------------------------------------------------------------展示模型-----------------------------------------------------------------------
--设置UID
function PetModelDisplay:SetUID(nUID)
	self.UID = nUID
end

--设置Pet资源ID
function PetModelDisplay:SetResID(nID)
	self.ResID = nID
end

--设置模型位置
function PetModelDisplay:SetModePosition(pos)
	self.m_modelPosition = pos
end

--创建背景
function PetModelDisplay:CreatBg(creat,index)
	index = index or 0
	if creat == true then 
		local entityView = rkt.EntityView.GetEntityView(self.UID )
		if nil == self.Controls.PetRawImage or entityView ~= nil then 
			return
		end
		local param = petShowModelCfg.BgParamArr[index]
		param.CamPosition = PET_MODEL_CAMERA_POS[1]
		param.CameraRotate = PET_MODEL_CAMERA_ROTATE[1]
				--目前只需要显示两个模型
		param.Position = Vector3.New( self.UID * 50 , 1000 , 0 )
		local dis = rktObjectDisplayInGUI:new()

		self.m_dis = dis
		local success = dis:Create(param)
		UnityEngine.Object.DontDestroyOnLoad(dis.m_GameObject)
		if true == success  then
			dis:AttachRawImage(self.Controls.PetRawImage,true)
		end
	else
		if nil ~= self.m_dis then
			self.m_dis:Destroy()
			self.m_dis = nil
		end
	end
end

--展示英雄模型
function  PetModelDisplay:ShowPetModel(show,index)
	self:CreatBg(show,index)
	self:CreatModel(show)
end

function PetModelDisplay:OnEntityPartAttached( args )
    if nil ~= args and nil ~= self.callback_OnEntityPartAttached and args:GetInteger("bodyPart") == EntityBodyPart.Skeleton then
        local entityView = rkt.EntityView.GetEntityView( args:GetString( "EntityId" , "" ) )
        if nil ~= entityView then
    	    entityView:UnregisterEvent(EntityViewEvent.OnEntityPartAttached, self.callback_OnEntityPartAttached)
        end
        self:modelLoadCallBack()
    end
end

--创建模型
function PetModelDisplay:CreatModel(creat,parent)
	if true == creat then 
		local pPos = Vector3.zero
		local entityView = rkt.EntityView.CreateEntityView(self.UID, GUIENTITY_VIEW_PARTS, pPos , UNITY_LAYER_NAME.EntityGUI )
		if not entityView then
			return nil
		end

		--动作设置相关,,,,,     暂时不考虑灵兽的动作			TODO	
		--[[entityView:SetString( EntityPropertyID.StandAnim , PET_MODEL_SHOW_ANI )
		
		local body = entityView:GetBodyPart(EntityBodyPart.Skeleton)
		if body == nil then 
			entityView:RegisterEvent(EntityViewEvent.OnEntityPartAttached, self.callback_OnEntityPartAttached)
		else
			self:modelLoadCallBack()
		end--]]
		
		local realParent = parent or self.m_dis.m_GameObject.transform
		entityView.transform:SetParent(realParent,false)
		entityView.transform.localPosition = self.m_modelPosition
		return entityView	
	else
		local entityView = rkt.EntityView.GetEntityView(self.UID)
		if nil ~= entityView then
			entityView:Destroy()
		end
		
	end
	
end

--设置实体位置
function PetModelDisplay:SetEntityPos(pos)
	local entityView = rkt.EntityView.GetEntityView(self.UID)
	if entityView then
		entityView.transform.localPosition = pos
	end
end

--更换显示灵兽    nResID- 资源ID
function PetModelDisplay:ChangePet(nResID)
	local entityView = rkt.EntityView.GetEntityView(self.UID)
	IGame.EntityFactory:SetSkeleton(entityView, nResID, true)
end

--是否已经初始化过 
function PetModelDisplay:HaveInit()
	local entityView = rkt.EntityView.GetEntityView(self.UID)
	if entityView == nil then
		return false
	else
		return true
	end
end

-------------------------------------------------------------------------------------------------------------------------------------------
--拖拽模型
function  PetModelDisplay:DragModel(eventData)
	local entityView = rkt.EntityView.GetEntityView(self.UID)
	if nil ~= entityView then
		entityView.transform:Rotate(-Vector3.up *eventData.delta.x * 30.0 * Time.deltaTime, UnityEngine.Space.Self);
	end
end

--点击模型
function PetModelDisplay:OnClickModel(eventData)
	local pressPosition =  eventData.pressPosition
	local CurrentPosition =  eventData.position
	local entityView = rkt.EntityView.GetEntityView(self.UID)
	if nil == entityView then 
		return
	end
	local X = math.abs(pressPosition.x - CurrentPosition.x)
	local Y = math.abs(pressPosition.y - CurrentPosition.y)
	if  X > 0.1 or Y >0.1 then 
		return
	end
	if self.m_showAniOver == false then 	
		return
	end
	entityView:SetString( EntityPropertyID.StandAnim ,PET_MODEL_SHOW_ANI )	
	local effectContext = rkt.EntitySkillEffectContext.New()
	effectContext.BodyPart = EntityBodyPart.Skeleton
	effectContext.AnimName = PLAYER_ROLE_ONCLICK_ANI							-----灵兽点击的动画名称					TODO
	effectContext.RevertToStandAnim = true
	entityView:PlayExhibit(effectContext)
	self.m_showAniOver  =false

	--如果有多动作
	rktTimer.SetTimer(self.callbackTimerPlayShowShowAniOver ,PET_MODEL_ANI2_TIME,1,"")
end


function PetModelDisplay:TimerPlayShowShowAniOver()
	self.m_showAniOver =true
end

function PetModelDisplay:modelLoadCallBack()
	rktTimer.SetTimer(function() PetModelDisplay:PlayShowStandAni() end,100,1,"")
	self.m_showAniOver = true		
end

function PetModelDisplay:PlayShowStandAni()	
	local entityView = rkt.EntityView.GetEntityView(self.UID)
	if entityView == nil then
		return
	end
	entityView:SetString( EntityPropertyID.StandAnim ,PET_MODEL_SHOW_ANI )	
	local effectContext = rkt.EntitySkillEffectContext.New()
	effectContext.BodyPart = EntityBodyPart.Skeleton
	effectContext.AnimName = PET_MODEL_SHOW_ANI
	effectContext.RevertToStandAnim = true
	entityView:PlayExhibit(effectContext)

end

return this

