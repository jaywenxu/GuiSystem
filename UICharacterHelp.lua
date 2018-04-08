--===========================================================
-- @author : 许文杰
-- @time   : 2017/3/18
-- @desc   : 界面角色显示类 （注意，canvas 需要设置为 space-camera模式）
--===========================================================
UICharacterHelp = CObject:new
{
    m_GameObject = nil  ,     -- 当前对象挂载的GameObject，需要显示的内容它下面
    m_Parameter = nil   ,     -- 显示参数
	m_uid = -1 ,				--模型唯一ID
}

-------------------------------------------------------------
function UICharacterHelp:gameObject()
    return self.m_GameObject
end

-------------------------------------------------------------
-- 创建一个相机
--[[  参数格式如下:
param = {
    layer = "" , -- 角色所在层
    Name = "" ,  --角色实例名字	
    Position = Vector3.New( 1000 , 1000 , 0 ) ,
	localScale    = Vector3.New( 300 , 300 , 300 ) , 因为使用canvas去绘制模型
	MoldeID = 0,			--模型ID
	ParentTrs = nil		--父节点
	targetUID = nil  -- 此为拷贝的对象，若没有则不需填
	UID =-1
	rotate =Vector3.New(0,180,0) --模型旋转角度
	entityClass =  tEntity_Class_Monster 角色类型
	animalName = ""
	changeStandAni =false
	nVocation = nil --角色职业
	callBack = nil 
	formInfo =nil, --外观信息
}
--]]
-------------------------------------------------------------
-------------------------------------------------------------
function UICharacterHelp:Create( param )
	
	--财哥说服务器ID不会与客户端ID重复，为了一些背包传送的特殊重复，加段代码删除
	local entityViewOld =  rkt.EntityView.GetEntityView(param.UID)
	if nil ~= entityViewOld then 
		entityViewOld:Destroy()
	end
	
	if nil ~= self.m_GameObject then
	   UnityEngine.Object.Destroy( self.m_GameObject )
		self.m_GameObject = nil
    end

    self.m_Parameter = param
	self.setWeaponTimer = function() self :SetWeapon()end
    self.m_GameObject = GameObject.New(param.Name or "Unname")
    self.m_GameObject.layer = LayerMask.NameToLayer(param.layer)
    self.m_GameObject.transform.position = param.Position
	self.m_GameObject.transform.localScale = param.localScale
	self.m_GameObject.transform.localEulerAngles = param.rotate
	UnityEngine.Object.DontDestroyOnLoad(self.m_GameObject)
	if nil ~= param.ParentTrs then  
		self.m_GameObject.transform:SetParent(param.ParentTrs,false)
	end
	self.m_uid = param.UID
	local pPos = Vector3.zero
	
	local entityView = IGame.EntityFactory:CreateEntityView( param.entityClass, param.MoldeID, param.UID, pPos , GUIENTITY_VIEW_PARTS , param.layer) 
	if not entityView then
	--根据ID将角色创建出来
		return false
		
	end
	entityView.transform:SetParent(self.m_GameObject.transform,false)
	entityView.transform.localRotation = Vector3.zero
	local body = entityView:GetBodyPart( EntityBodyPart.Skeleton)
	if body == nil then
        self.callback_OnEntityPartAttached = handler( self , self.OnEntityPartAttached )
		entityView:RegisterEvent(EntityViewEvent.OnEntityPartAttached, self.callback_OnEntityPartAttached)
	else
		self:ModelLoadCallBack()
	end
	
	if self.m_Parameter.nVocation ~= nil then
		local nVocation = self.m_Parameter.nVocation
		local formatData
		local bodyID, FaceID, HairID, HairColor
		if param.formInfo == nil then 
			local defaultRecord = IGame.rktScheme:GetSchemeInfo(APPEARDEFAULT_CSV, nVocation)
			local weaponAppearInfo = IGame.rktScheme:GetSchemeInfo(APPEARANCE_CSV, defaultRecord.weaponAppearID)
			local pBodyMeshAppearInfo = IGame.rktScheme:GetSchemeInfo(APPEARANCE_CSV, defaultRecord.nBodyMeshAppearID)
			local FaceMeshAppearInfo = IGame.rktScheme:GetSchemeInfo(APPEARANCE_CSV, defaultRecord.FaceMeshAppearID)
			local pHairMeshAppearInfo = IGame.rktScheme:GetSchemeInfo(APPEARANCE_CSV, defaultRecord.nHairMeshAppearID)
			self.WeapAppearID = defaultRecord.weaponAppearID
			bodyID = pBodyMeshAppearInfo.nResID
			FaceID = FaceMeshAppearInfo.nResID
			HairID = pHairMeshAppearInfo.nResID
			if pHairMeshAppearInfo and pHairMeshAppearInfo.nColorList then
				HairColor = pHairMeshAppearInfo.nColorList[1]
			end
			
			if HairColor then
				if HairColor > 0 then			--修改过发色
					local color = Color.New()
					color:FromHexadecimal(HairColor)
					local colorVec3 = Vector3.New(color.r,color.g,color.b)
					entityView:SetVector3(EntityPropertyID.HairColor, colorVec3)
				end
						
			end
			rktTimer.SetTimer(self.setWeaponTimer,100,1,"")
			IGame.EntityFactory:SetPartMesh(entityView,EntityBodyPart.BodyMesh,bodyID,true)
			IGame.EntityFactory:SetPartMesh(entityView,EntityBodyPart.FaceMesh,FaceID,true)
			IGame.EntityFactory:SetPartMesh(entityView,EntityBodyPart.HairMesh,HairID,true)
		else
		  IGame.EntityFactory:UpdateActorForm(entityView,param.formInfo,true)
		end
	end
	if param.targetUID then
		UICharacterHelp:CopyCharacter(UID,param.targetUID)
	end
    return true
end
------------------------------------------------

function UICharacterHelp:SetWeapon()
	local entityView = rkt.EntityView.GetEntityView( self.m_uid )
	
	if nil == entityView or not self.WeapAppearID then 
		return
	end
	local resInfo = IGame.rktScheme:GetSchemeInfo(APPEARANCE_CSV, self.WeapAppearID)
	if not resInfo then
		return 
	end
	-- 左手武器
	if resInfo.nLeftWeapResID and  resInfo.nLeftWeapResID  > 0 then
		IGame.EntityFactory:SetWeapon(entityView,resInfo.nLeftWeapResID,false,true)
	end
	-- 右手武器
	if resInfo.nRightWeapResID and  resInfo.nRightWeapResID  > 0 then
		IGame.EntityFactory:SetWeapon(entityView,resInfo.nRightWeapResID,true,true)
	end
end

function UICharacterHelp:OnEntityPartAttached( args )
    if nil ~= args and nil ~= self.callback_OnEntityPartAttached and args:GetInteger("bodyPart") == EntityBodyPart.Skeleton then
        local entityView = rkt.EntityView.GetEntityView( args:GetString( "EntityId" , "" ) )
        if nil ~= entityView then
    	    entityView:UnregisterEvent(EntityViewEvent.OnEntityPartAttached, self.callback_OnEntityPartAttached)
        end
        self:ModelLoadCallBack()
    end
end

function UICharacterHelp:ModelLoadCallBack()
	--self.m_Parameter
	local standName = self.m_Parameter.animalName or  "stand"
	local entityView = rkt.EntityView.GetEntityView( self.m_uid )
    if nil == entityView then
        return
    end
	entityView:SetString( EntityPropertyID.StandAnim ,standName )	
	local effectContext = rkt.EntitySkillEffectContext.New()
	effectContext.BodyPart = EntityBodyPart.Skeleton
	effectContext.AnimName = standName
	effectContext.RevertToStandAnim = true

	if  self.m_Parameter.callBack ~=nil then
		self.m_Parameter.callBack()
	end
end

-------------------------------------------------------------
-- 销毁当前显示对象
-------------------------------------------------------------
function UICharacterHelp:Destroy()
    if nil ~= self.m_GameObject then
		local entityView =  rkt.EntityView.GetEntityView(self.m_uid)
		if nil ~= entityView then 
			entityView:Destroy()
		end
        UnityEngine.Object.Destroy( self.m_GameObject )
		self.WeapAppearID = nil
        self.m_GameObject = nil
    end
	
end
-------------------------------------------------------------

--播放角色动作
function UICharacterHelp:PlayAni(AniID)
	
	local entityView = IGame.EntityFactory.GetEntityView(self.m_uid)
	
	if nil == entityView then 
		return
	end 
	
	local skillViewCfg = IGame.rktScheme:GetSchemeInfo(SKILLVIEW_CSV, AniID)
	if skillViewCfg and self.entityView then
		-- todo: 调用动作、光效接口
		local effectContext = rkt.EntitySkillEffectContext.New()
		effectContext.BodyPart = EntityBodyPart.Skeleton
        GameHelp.FillSkillViewContext( effectContext , skillViewCfg )
		entityView:PlayExhibit(effectContext)
	end
end



function UICharacterHelp:CopyCharacter(uid,targetUID)
		local pPos = Vector3.zero

		local parts = 
		{
			EntityLogicPart.AvatarPart ,
			EntityLogicPart.AnimatorPart ,
			EntityLogicPart.EffectPart ,
		}

		local properties = 
		{
			EntityPropertyID.StandAnim ,
			EntityPropertyID.WingStandAnim ,
			EntityPropertyID.EntityType ,
		}
		
		if not uid and not targetUID then 
			return
		end
	

		rkt.EntityView.CopyEntityView( uid , targetUID , properties , parts )
end