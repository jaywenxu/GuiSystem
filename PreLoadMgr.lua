--******************************************************************
-- 这个文件只能由客户端编辑
--/******************************************************************
---** 文件名:	PreLoadMgr.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	
--** 日  期:	2017-07-06
--** 版  本:	1.0
--** 描  述:	
--** 应  用:  	用于解决异步加载导致界面表现延迟的问题
--******************************************************************

PreLoadMgr =
{
	m_prePveLoadTable=
	{
		storyList={},
		jumpList ={},
		otherResourceList={},
		monsterList ={},
	}
	
}
---------------------------------------------------------------------
local this = PreLoadMgr
---------------------------------------------------------------------
--针对副本预加载
function PreLoadMgr.PreLoadPveResource(mapID)
	this.m_prePvpResourceLoaded = false
	local scheme = IGame.rktScheme:GetSchemeInfo(ASYNCHRESOURCE_CSV, mapID)
	if nil == scheme then 
		this.m_prePveResourceLoaded = true
	else
		--先清空
		this.m_prePveLoadTable=
		{
			storyList={},
			jumpList ={},
			otherResourceList={},
			monsterList ={},
		}
		--加载剧情
		local count = table.getn(scheme.storyList)
		for i=1,count do 
			this.m_prePveLoadTable.storyList[i] =false
			PreLoadMgr.PreLoadOperaPrefabByID(scheme.storyList[i],i,ReleaseWaitTime.RELEASE_WAIT_LEVELUNLOAD)
		end
		--加载跳跃动作
		count = table.getn(scheme.sceneJumpList)
		for i=1,count do 
			this.m_prePveLoadTable.jumpList[i] = false
			PreLoadMgr.PreLoadJumpResourceByID(scheme.sceneJumpList[i],i,ReleaseWaitTime.RELEASE_WAIT_LEVELUNLOAD)
		end
		
		--加载其他资源
		count = table.getn(scheme.szRes)
		for i=1,count do 
			this.m_prePveLoadTable.monsterList[i] = false
			PreLoadMgr.PreLoadResourceByPath(scheme.monsterList[i],i,ReleaseWaitTime.RELEASE_WAIT_LEVELUNLOAD)
		end
		
		--加载怪物模型
		count = table.getn(scheme.monsterList)
		for i=1,count do 
			this.m_prePveLoadTable.monsterList[i] = false
			PreLoadMgr.PreLoadMonsterByID(scheme.monsterList[i],i,ReleaseWaitTime.RELEASE_WAIT_LEVELUNLOAD )
		end
		
	end
	
end
---------------------------------------------------------------------
--根据剧情ID加载资源
function PreLoadMgr.PreLoadOperaPrefabByID(operaID,index,releaseType)
	local scheme = IGame.rktScheme:GetSchemeInfo(STORY_CSV,operaID)
	local releaseArr ={}
	if nil == scheme then 
		this.m_prePveLoadTable.storyList[index] =true
	else
		local resourcePath = AssetPath.OperaPrefabPath..scheme.path
		table.insert(releaseArr,resourcePath)
		rkt.GResources.LoadAsync(resourcePath,typeof(GameObject),
		function(path,obj,ud)
			this.m_prePveLoadTable.storyList[index] =true
            if nil ~= obj then
                local trigger = obj:GetComponent(typeof(CinemaDirector.CutsceneTrigger))
                if nil ~= trigger then
                    trigger:Preload()
                end
            end
		end ,index,AssetLoadPriority.OperaNormal)
		rkt.GResources.SetReleaseWaitTime(releaseArr,releaseType)
	end
end
---------------------------------------------------------------------
--预加载怪物资源
function PreLoadMgr.PreLoadMonsterByID(monstID,index,releaseType)
    releaseType = releaseType or 0
	local monsterSche = IGame.rktScheme:GetSchemeInfo(MONSTER_CSV, monstID)
	if nil == monsterSche then 
		this.m_prePveLoadTable.monsterList[index] = true
        return
	end

	--加载怪物模型
	local scheme =  IGame.rktScheme:GetSchemeInfo(CONFIGRESOURCE, monsterSche.lResID)
	if scheme == nil then 
		this.m_prePveLoadTable.monsterList[index] = true
        return
	end

	--加载模型（只加载低模）
	rkt.GResources.LoadAsync(scheme.szModel,typeof(GameObject),function(path,obj,ud)
		this.m_prePveLoadTable.monsterList[index] =true
		end ,index,AssetLoadPriority.EntityNormal)

	local otherRes = {}
	--加载左手武器
	table.insert(otherRes ,scheme.LeftWeaponResID )
	-- 加载右手武器
	table.insert(otherRes ,scheme.RightWeaponResID )
	--加载脸部模型 
	table.insert(otherRes ,scheme.FaceMeshResID )
    --加载头发模型
	table.insert(otherRes ,scheme.HairMeshResID )
	--加载身体模型
	table.insert(otherRes,scheme.BodyMeshResID )

	local count = table.getn(otherRes)

	for i=1,count do 
		local pSchemeInfo = IGame.rktScheme:GetSchemeInfo(CONFIGRESOURCE, otherRes[i])
		if not pSchemeInfo or IsNilOrEmpty(pSchemeInfo.szModel) then
			return
		end
		rkt.GResources.LoadAsync(pSchemeInfo.szModel,typeof(GameObject),function(path,obj,ud)
			this.m_prePveLoadTable.monsterList[index] = true
			end ,index,AssetLoadPriority.EntityNormal)
	end

    --加载技能
    if IsNilOrEmpty(scheme.szEventFile) then
        return
    end
    for i = 1 , 4 do
        local skill_id_level = monsterSche["lUsableSkill" .. i]
        if nil ~= skill_id_level and 0 ~= skill_id_level then
            local skill_id , skill_lev = math.floor( skill_id_level / 1000 , skill_lev % 1000 )
            PreloadHelp.PreloadSkill( scheme.szEventFile , skill_id , skill_lev , releaseType )
        end
    end
end
---------------------------------------------------------------------
--预加载跳跃资源
function PreLoadMgr.PreLoadJumpResourceByID(jumpID,index)
	local scheme = IGame.rktScheme:GetSchemeInfo(SCENE_JUMP_PATH_CSV,jumpID)
	if nil == scheme then 
		this.m_prePveLoadTable.jumpList[index] =true 
	else
		local resourcePath = scheme.AnimatorControllerPath
		rkt.GResources.LoadAsync(resourcePath,typeof(GameObject),
		function(path,obj,ud)
			this.m_prePveLoadTable.jumpList[index] =true
		end ,index,AssetLoadPriority.OperaNormal)
	end
end

--预加载其他资源
function PreLoadMgr.PreLoadResourceByPath(path,index)
	rkt.GResources.LoadAsync(path,typeof(GameObject),function(path,obj,ud)
		this.m_prePveLoadTable.otherResourceList[index] =true
	end,index,AssetLoadPriority.CommonNormal)
end

--副本资源预加载检测
function PreLoadMgr.CheckPvePreResourseLoadOver()
	--检查剧情是否加载完成
	local operaCount = this.m_prePveLoadTable.storyList
	for i =1,operaCount do 
		if false == this.m_prePveLoadTable.storyList[i] then 
			return false
		end
	end
	--检查跳跃资源是否加载完成
	
	--检查怪物资源是否加载完成
end

--针对界面特效的预加载
function PreLoadMgr.PreLoadUIEffect(Info)
	for k,v in pairs(Info) do
		rkt.GResources.LoadAsync(v,typeof(UnityEngine.Object),nil,"",AssetLoadPriority.PreLoadGuiEffect)
	end
end


--[[
	RELEASE_WAIT_DEFAULT = 30, -- 默认30s
	RELEASE_WAIT_PERSISTENT  = -1, -- 持久存在不会被释放
	RELEASE_WAIT_LEVELUNLOAD = -2,  -- 关卡卸载时释放--]]
-- 进入游戏及预加载的资源，加载后根据配置的释放
function PreLoadMgr.PreLoadEnterGame()
	local foreverRelaease ={}
	local sceRelease = {}
	local timeRelease ={}
	for k,v in pairs(ENTER_GAME_AFTER_PRE_LOAD_WAIT_RELEASE) do 
		rkt.GResources.LoadAsync(v.Path,typeof(UnityEngine.Object),nil,"",v.Priority)
		if v.RelaseType == ReleaseWaitTime.RELEASE_WAIT_DEFAULT then
			table.insert(timeRelease,v.Path)
		elseif v.RelaseType == ReleaseWaitTime.RELEASE_WAIT_PERSISTENT then
			table.insert(foreverRelaease,v.Path)
		elseif v.RelaseType == ReleaseWaitTime.RELEASE_WAIT_LEVELUNLOAD then
			table.insert(sceRelease,v.Path)
		end
	
	end
	rkt.GResources.SetReleaseWaitTime(foreverRelaease,ReleaseWaitTime.RELEASE_WAIT_PERSISTENT)
	rkt.GResources.SetReleaseWaitTime(sceRelease,ReleaseWaitTime.RELEASE_WAIT_LEVELUNLOAD)
	rkt.GResources.SetReleaseWaitTime(timeRelease,ReleaseWaitTime.RELEASE_WAIT_DEFAULT)
end


--预加载任务的剧情资源
function PreLoadMgr.PreLoadTaskOpera(taskID)
	local mapID = IGame.EntityClient:GetMapID()
	local scheme = IGame.rktScheme:GetSchemeInfo(ASYNCHRESOURCE_CSV, mapID,taskID)
	local count = table.getn(scheme)
	for i=1,count do 
		rkt.GResources.LoadAsync(scheme.storyList[i],typeof(GameObject),
            function( path , obj , ud )
                if nil ~= obj then
                    local trigger = obj:GetComponent(typeof(CinemaDirector.CutsceneTrigger))
                    if nil ~= trigger then
                        trigger:Preload()
                    end
                end
            end,"",AssetLoadPriority.PreLoadOpera)
	end
	
end

