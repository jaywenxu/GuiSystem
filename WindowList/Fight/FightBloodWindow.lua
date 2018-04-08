--/******************************************************************
---** 文件名:	FightBloodWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	许文杰
--** 日  期:	2017-03-03
--** 版  本:	1.0
--** 描  述:	战斗飘血窗口
--** 应  用:  
--******************************************************************/


local FightBloodWindow = UIWindow:new
{
	windowName = "FightBloodWindow" ,
	heroBloodList = {} ,
	playBloodList ={},
	

}
 local show = false

------------------------------------------------------------
--[[ 飘血列表中存的信息,示例如下
heroBloodListItem = 
{
	local entityID = ""
	local bloodItemList ={}
}
--]]
------------------------------------------------------------

------------------------------------------------------------
--[[ 飘血列表中存的信息,示例如下
key = tostring(entityId)
bloodItemList = 
{
    Logic = -- 逻辑部分
    {
        bloodHpNum = "" ,
        BloodColor = 0 ,
		flutterTime = 1, 飘血时间长度
		flutterOffset=2
		bloodActor = nil,            以角色为世界坐标
    }
    Render = -- 渲染部分
    {
        CellObject = nil  , -- UnityEngine.GameObject
        BloodText = nil ,    -- UnityEngine.UI.Text
		DOTweenAnis = 
		{
		},   -- DG.Tweening.DOTween
        ...
    }
}
--]]
------------------------------------------------------------

function FightBloodWindow:Init()
	require("GuiSystem.WindowList.Fight.FightBloodDefine")
end

function FightBloodWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj,UIManager._BackgroundLayer)
	for uid,uidItem in pairs(self.heroBloodList) do 
		for k , typeItem in pairs(uidItem) do
			for i,item in pairs(typeItem) do 
				if nil == item.Render.CellObject then
					rkt.GResources.FetchGameObjectAsync( GuiAssetList.FightBloodCell[item.Logic.BloodType] , function(path,obj,ud)		
						FightBloodWindow:OnFightBloodCellLoaded(path,obj,item) end

				, nil, AssetLoadPriority.GuiNormal )
				end
			end
		end
	end
    return self
end
------------------------------------------------------------
function FightBloodWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------


--飘血Cell加载完后的回调
------------------------------------------------------------
function FightBloodWindow:OnFightBloodCellLoaded(path , obj , item )
	if nil == obj then

		return
	end
	 
    if nil == item or nil ~= item.Render.CellObject then
		rkt.GResources.RecycleGameObject(obj)
    end
	if item.Logic.BloodType == BloodTypeEnume.FlutterGetExpCell  then
		obj.transform:SetParent( UIManager.FindUguiLayer(UIManager._SpecialTopLayer) , false )
		obj.transform:SetAsLastSibling()
	else
			-- 初始化渲染部分
		obj.transform:SetParent( FightBloodWindow.transform , false )
	end

	item.Render.CellObject= obj
	local worldPosToScreen = UIWorldPositionToScreen.Get(obj)
	self.worldScreen = worldPosToScreen
	worldPosToScreen.UICamera = UIManager.FindUICamera()
	local entityView = rkt.EntityView.GetEntityView(item.Logic.Uid)
	
	if entityView == nil then 
		rkt.GResources.RecycleGameObject(obj)
		return
	end
	
    worldPosToScreen.Position = entityView.transform.position
	local heroHeight = 0
	heroHeight = entityView:GetFloat(EntityPropertyID.EntityHeight)
	
	local heroVector = Vector3.New(0.0,heroHeight,0.0)
	-- 初始化逻辑部分
	
	worldPosToScreen.WorldOffset = heroVector+BloodCfgVector[item.Logic.BloodType]
	local hpText = obj.transform:Find(BloodCellPath[item.Logic.BloodType]):GetComponent(typeof(Text))
	
	if nil ~= hpText then
		if item.Logic.BloodType == BloodTypeEnume.SelfDoubleHurtBlood or item.Logic.BloodType == BloodTypeEnume.MonsterDoubleHurtBloodCell then
			hpText.text = "致命"..item.Logic.Hp
		elseif item.Logic.BloodType == BloodTypeEnume.FlutterGetExpCell  then
			hpText.text = "经验+"..item.Logic.Hp
		elseif item.Logic.BloodType == BloodTypeEnume.FightAddBloodCell  then
			hpText.text = "+"..item.Logic.Hp
		else
			hpText.text = item.Logic.Hp
		end
	end
	
	if self.heroBloodList[item.Logic.Uid] == nil then 
		return
	end
	local typeInfo =self.heroBloodList[item.Logic.Uid][item.Logic.BloodType] 
	if typeInfo == nil then 

		return
	end
	
	local cout = table.getn(typeInfo)
	if self.playBloodList == nil or self.playBloodList[item.Logic.Uid]== nil or self.playBloodList[item.Logic.Uid][item.Logic.BloodType] == nil
	  or table.getn(self.playBloodList[item.Logic.Uid][item.Logic.BloodType]) == 0 then 
		if self.playBloodList[item.Logic.Uid] == nil then 
			self.playBloodList[item.Logic.Uid] ={}
		end
		if 	self.playBloodList[item.Logic.Uid][item.Logic.BloodType] == nil then 
			self.playBloodList[item.Logic.Uid][item.Logic.BloodType]={}
		end
		table.insert(self.playBloodList[item.Logic.Uid][item.Logic.BloodType],item)
		FightBloodWindow:ShowDotweenAni(item,false)

	else
		table.insert(self.playBloodList[item.Logic.Uid][item.Logic.BloodType],item)

	end
	
end


function FightBloodWindow:RecycleGameobject(obj)
	rkt.GResources.RecycleGameObject(obj)
end

function FightBloodWindow:ShowDotweenAni(item,needRemove)
	if 	self.m_canShow == false then 
		return
	end
	local bloodType = item.Logic.BloodType
	local bloodUid =  item.Logic.Uid
	local obj = item.Render.CellObject
	local anims = obj:GetComponentsInChildren(typeof(DG.Tweening.DOTweenAnimation))
	local timeLength = 0
	for i = 0 , anims.Length -1 do
		anims[i]:DORestart(false)
		timeLength = Mathf.Max(anims[i].duration)
	end
	if self.playBloodList[bloodUid] == nil or self.playBloodList[bloodUid][bloodType] == nil then 
		return
	end
	
	if needRemove == true then 
		table.remove(self.playBloodList[bloodUid][bloodType],1)
		table.remove(self.heroBloodList[bloodUid][bloodType],1)
	end
	
	rktTimer.SetTimer(function() self:RecycleGameobject(obj) end,timeLength*1000,1,"")
		
	if table.getn(self.playBloodList[bloodUid][bloodType]) == 1 then
		rktTimer.SetTimer(function()self:Remove(item) end,BloodCdTime[bloodType],1,"" )	
		return
	end
	local cout = #self.playBloodList[bloodUid][bloodType]
	
	for k=1 , cout do
		local RemainItem = self.playBloodList[bloodUid][bloodType][k]
		if RemainItem == nil then 
			return
		end
		if k ~= 1 then
			rktTimer.SetTimer(function()self:ShowDotweenAni(RemainItem,true) end,BloodCdTime[bloodType],1,"" )
			break
		end 
		

    end

end
------------------------------------------------------------

function FightBloodWindow:Remove(item)
	if item == nil or  item.Logic.Uid==nil or item.Logic.BloodType == nil or self.playBloodList[item.Logic.Uid] == nil then 
		return
	end
	table.remove(self.playBloodList[item.Logic.Uid][item.Logic.BloodType],1)
	table.remove(self.heroBloodList[item.Logic.Uid][item.Logic.BloodType],1)
	if table.getn(self.playBloodList[item.Logic.Uid][item.Logic.BloodType]) > 0 then
		self:ShowDotweenAni(self.playBloodList[item.Logic.Uid][item.Logic.BloodType][1],false)
	end
end

function FightBloodWindow:RemoveAll()
	for uid,uidItem in pairs(self.playBloodList) do 
		for k , typeItem in pairs(uidItem) do
			for i,item in pairs(typeItem) do 
				if nil ~= item.Render.CellObject then
					rkt.GResources.RecycleGameObject(item.Render.CellObject)
				end
			end
		end
	end
	self.playBloodList={}
	self.heroBloodList={}
	self.m_canShow = false
end


--外部接口战斗时飘血用
------------------------------------------------------------
function FightBloodWindow:AddBloodItem(hp ,uid,bloodType)
	--判断掉血生物是否存在
	local actor = IGame.EntityClient:GetCreature(tostring(uid))
	if nil == actor then
		return
	end
	self.m_canShow = true
	local actorBloodItem = {}
	actorBloodItem.entityID = uid
	actorBloodItem.Logic = 
	{
		Hp = hp,
		BloodType = bloodType,
		Uid = uid
	}
	actorBloodItem.Render = 
	{
		CellObject =nil
	}

	if self.heroBloodList[uid] == nil then 
		self.heroBloodList[uid] ={}
	end
	if 	self.heroBloodList[uid][bloodType] == nil then 
		self.heroBloodList[uid][bloodType]={}

		self.heroBloodList[uid][bloodType]={}
	end
	table.insert(self.heroBloodList[uid][bloodType],actorBloodItem)
	local index = table.getn(self.heroBloodList[uid][bloodType])
	local path = GuiAssetList.FightBloodCell[bloodType]
	if nil == path then
		return
	end
	
	if not self:isLoaded() then
		return
	end

	rkt.GResources.FetchGameObjectAsync(path , 
		function(path,obj,userData)		
			self:OnFightBloodCellLoaded(path,obj,actorBloodItem)
		end, nil, AssetLoadPriority.GuiNormal )

end
------------------------------------------------------------


return FightBloodWindow

