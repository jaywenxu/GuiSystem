
local NameItemCellClass = require( "GuiSystem.WindowList.NameTitle.NameTitleCell" )
------------------------------------------------------------
local NameTitleWindow = UIWindow:new
{
	windowName = "NameTitleWindow" ,
    NameTitleList = {} ,

	
}
local ADD_NAME_MAX_DISTANCE = 20
-----------------------------------------------------
--[[ 名称列表中存的信息,示例如下
key = tostring(entityId)
NameTitleItem = 
{
    Logic = -- 逻辑部分
    {
        Name = "" ,
        CurHp = 0 ,
        MaxHp = 100 ,
        Titles =   -- 称号部分,Npc没有
        {
            { Title = "" , visiable = false } ,
        }
		nameType = NameTitleType.NameType_None
		TitCell = nil,	--顶部脚本
		FamilyName = "",
		AchiveName = "",
		NameState = false,
		HpState =false,
    },
	Render=
	{
		CellObject = nil,		
	}
	
}
--]]
--
------------------------------------------------------------
function NameTitleWindow:Init()

end
------------------------------------------------------------
function NameTitleWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj,UIManager._NGUILayer)

    for k , item in pairs(self.NameTitleList) do
        if nil == item.Render.CellObject then
			if GuiAssetList.NpcNameTitleCell[item.Logic.nameType] ~= nil then 
				rkt.GResources.FetchGameObjectAsync( GuiAssetList.NpcNameTitleCell[item.Logic.nameType] , NameTitleWindow.OnNameTitleCellLoaded , k , AssetLoadPriority.GuiNormal )
			end
            
        end
    end
	self.CheckNameShowFun = function() self:CheckNeedRemoveName() end
	--开启名字区域显示定时器
	rktTimer.SetTimer(self.CheckNameShowFun,500,-1,"name check need Hide")
    return self
end
------------------------------------------------------------
function NameTitleWindow:_showWindow()
   --[[ for k , item in pairs(self.NameTitleList) do
        if nil ~= item.Render.CellObject then
            rkt.GResources.RecycleGameObject(item.Render.CellObject)
        end
    end--]]
	UIWindow._showWindow(self)
end
------------------------------------------------------------
function NameTitleWindow:OnDestroy()
	 for k , item in pairs(self.NameTitleList) do
		UnityEngine.Object.Destroy(item.Render.CellObject)
		if item.Logic.TitCell ~= nil then 
			item.Logic.TitCell:CleanObj()
		end
		
		item.Render.CellObject = nil
    end
	rktTimer.KillTimer(self.CheckNameShowFun,1000,-1,"name check need Hide")
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------
function NameTitleWindow.OnNameTitleCellLoaded( path , obj , uid )
    if nil == obj then
        return
    end
    local item = NameTitleWindow.NameTitleList[uid]
	
    if nil == item or NameTitleWindow.transform ==nil or item.Render.CellObject ~=nil  then
		
        rkt.GResources.RecycleGameObject(obj)
        return
    end
	item.Render.CellObject = obj
	local cell = item.Logic.TitCell
	if nil == cell then 
		cell = NameItemCellClass:new({})
		item.Logic.TitCell = cell
	end
	obj:SetActive(false)
	cell:Attach(obj)
    -- 初始化渲染部分
    obj.transform:SetParent( NameTitleWindow.transform , false )
	NameTitleWindow:CheckNameNeedShowByUid(item.Logic.uid,item.Render.CellObject)
	cell:Init(item)

	
end

--判断此ID实例是否在配置的范围内
function NameTitleWindow:CheckCanAddName(entityId)
	if IsNilOrEmpty(entityId)  then 
		return false
	end
	local pHero = IGame.EntityClient:GetHero()
	if pHero == nil then
		uerror("pHero nil")
		return false
	end
	local ptSrc = pHero:GetPosition()
	local entity= rkt.EntityView.GetEntityView(entityId)
	if IsNilOrEmpty(entity) then 
		return false
	end
	local targetPos = entity.position
	if Vector3.Distance( ptSrc , targetPos) < ADD_NAME_MAX_DISTANCE then
		return true
	end
	return false
end

--获取名字的最大高度（泡泡需要）
function NameTitleWindow:GetNameMaxHeight(uid)
	local key =  tostring(uid)
	local item = self.NameTitleList[key]
	if  item == nil then
		return 0
	end
	local height = 0
	if item.Logic.HpState == true then 
		height  = height+0.5
	end
	
	if item.Logic.NameState == true and not IsNilOrEmpty(item.Logic.Name) then 
		height = height+0.5
	end
	
	if not IsNilOrEmpty(item.Logic.FamilyName) then 
		height = height+0.5
	end
	
	if not IsNilOrEmpty(item.Logic.CampPath) then 
		height = height+0.5
	end
	return height
end

-- 角色头顶名称是否创建
function NameTitleWindow:IsLoadedNameCellItem(entityId)
	local item = self.NameTitleList[tostring(entityId)]
	if item then
		return true
	end
	return false
end


function NameTitleWindow:ShowNameState(entityid,Index)
	local item = self.NameTitleList[tostring(entityId)]
	if item ~= nil and item.Logic~=nil then
		if item.Render.CellObject == nil then 
			--rkt.GResources.FetchGameObjectAsync( GuiAssetList.NpcNameTitleCell[item.Logic.nameType] , NameTitleWindow.OnNameTitleCellLoaded , entityid , AssetLoadPriority.GuiNormal )
		else
			item.Logic.TitCell:ShowName(Index)
		end
	
	end
end

------------------------------------------------------------
function NameTitleWindow:ShowHpBar(entityId,State)
    local item = self.NameTitleList[tostring(entityId)]
	if item ~= nil and item.Logic~=nil then 
		item.Logic.HpState = State
		if item.Render.CellObject == nil then 
			--rkt.GResources.FetchGameObjectAsync( GuiAssetList.NpcNameTitleCell[item.Logic.nameType] , NameTitleWindow.OnNameTitleCellLoaded , entityid , AssetLoadPriority.GuiNormal )
		else
			item.Logic.TitCell:ShowHp(State)
		end
		
	end
end
------------------------------------------------------------
function NameTitleWindow:ShowName(entityId,state)
	local item = self.NameTitleList[tostring(entityId)]
	if item ~= nil and  item.Logic ~=nil  then
		item.Logic.NameState = state
		if item.Render.CellObject == nil then 
			--rkt.GResources.FetchGameObjectAsync( GuiAssetList.NpcNameTitleCell[item.Logic.nameType] , NameTitleWindow.OnNameTitleCellLoaded , entityid , AssetLoadPriority.GuiNormal )
		else
			item.Render.CellObject:SetActive(state)
		end
	end
end

--设置自己名字
function NameTitleWindow:RefreshTitle(entityId,name)
	local key = tostring(entityId)
	local item = self.NameTitleList[key] 
	
	if nil == item then
		item = {}
        item.Logic = 
        {
            Name = "" ,
			NameState = true,
			HpState = true,
        }
		item.Logic.uid = toint64(key)
		item.Logic.Name = name
        self.NameTitleList[key] = item
		return
	end
	self.NameTitleList[key].Logic.Name = name
    if self.NameTitleList[key].Logic.TitCell == nil then
        return
    end
	self.NameTitleList[key].Logic.TitCell:RefreshTitle(name)
end

------------------------------------------------------------
--检查需要移除的名字
function NameTitleWindow:CheckNeedRemoveName()
	for k , item in pairs(self.NameTitleList) do
		if item ~= nil then 
			if item.Render ~= nil and item.Render.CellObject~= nil then 
				self:CheckNameNeedShowByUid(item.Logic.uid,item.Render.CellObject)
			end
		end
    end
end

--根据UID检查是否需要显示名字
function NameTitleWindow:CheckNameNeedShowByUid(uid,obj)
	local key = tostring(uid)
	local entity = rkt.EntityView.GetEntityView(key)
	local hero = GetHero()
	local uid = hero:GetUID()
	if nil == obj then
		return
	end
	if tostring(uid) ~= key then 
		if entity == nil then 
			self:RemoveNameTitle(uid)
		else
			local tableObj = obj.transform:GetChild(0)
			if tableObj == nil then 
				return
			end
			if not self:CheckCanAddName(key) then 
				tableObj.gameObject:SetActive(false)
			else
				tableObj.gameObject:SetActive(true)
			end
		end
	else
		self:ShowNameObj(obj,true)
	end
end

function NameTitleWindow:ShowNameObj(obj,state)
	local tableObj = obj.transform:GetChild(0)
	if tableObj == nil then 
		return
	end
	tableObj.gameObject:SetActive(state)
end

--设置家族名字
function NameTitleWindow:SetNameFamilyTitle(entityId,name)
	local key = tostring(entityId)
	local item = self.NameTitleList[key] 
	if nil == item then
		item = {}
        item.Logic = 
        {
          
			FamilyName = "",

        }
		item.Render ={}
		item.Logic.uid = toint64(key)
		item.Logic.FamilyName = name
        self.NameTitleList[key] = item
		return
	end
	item.Logic.FamilyName = name
    if self.NameTitleList[key].Logic.TitCell == nil or item.Render.CellObject == nil then
        return
    end
	self.NameTitleList[key].Logic.TitCell:RefreshFamilyName(name)
end


--设置自动寻路
function NameTitleWindow:SetAutoFindWay(entityId,state)
	local key = tostring(entityId)
	local item = self.NameTitleList[key] 
	if nil == item then
		item = {}
        item.Logic = 
        {
          
			FamilyName = "",

        }
		item.Render ={}
		item.Logic.uid = toint64(key)
		item.autoFindWayState = state
        self.NameTitleList[key] = item
		return
	end
	item.Logic.autoFindWayState = state
    if self.NameTitleList[key].Logic.TitCell == nil or item.Render.CellObject == nil then
        return
    end
	self.NameTitleList[key].Logic.TitCell:SetAutoFindWay(state)
end



--刷新头衔
function NameTitleWindow:RefreshHeadTitle(entityId,Info)
	local key = tostring(entityId)
	local item = self.NameTitleList[key] 
	if not item then
		local item = {}
        item.Logic = 
        {

			headInfo = nil,
        }
		item.Render ={}
		item.Logic.uid = toint64(key)
		item.Logic.headInfo = Info
        self.NameTitleList[key] = item
		return
	end
	item.Logic.headInfo = Info
    if self.NameTitleList[key].Logic.TitCell == nil then
        return
    end
	self.NameTitleList[key].Logic.TitCell:RefreshHeadCell(Info)
end

--刷新头衔
function NameTitleWindow:RefreshNameHeight(entityId)
	local key = tostring(entityId)
	local item = self.NameTitleList[key] 
	if not item then
		return
	end

    if self.NameTitleList[key].Logic.TitCell == nil then
        return
    end
	self.NameTitleList[key].Logic.TitCell:RefreshHeight()
end

--刷新高度
function NameTitleWindow:SetNameHeight(entityId,relHeight)
	local key = tostring(entityId)
	local item = self.NameTitleList[key] 
	if not item then
		local item = {}
        item.Logic = 
        {

			height = relHeight,
        }
		item.Render ={}
		item.Logic.uid = toint64(key)
        self.NameTitleList[key] = item
		return
	end
    if self.NameTitleList[key].Logic.TitCell == nil then
        return
    end
	self.NameTitleList[key].Logic.TitCell:SetHeight(relHeight)
end


--nameType: NameTitleType
--bHPred：血条颜色 false绿色，true红色
function NameTitleWindow:RefreshType(entityId,bHPred,nNameType)

	local key = tostring(entityId)
	local item = self.NameTitleList[key]
	if not item then
		local item = {}
		if nNameType == nil then 
			return
		end
        item.Logic = 
        {
			nameType = nNameType or "",
			uid = toint64(key),
			bHPred = bHPred,
        }
		item.Render ={}
        self.NameTitleList[key] = item
		return
	end
	item.Logic.bHPred = bHPred
	local nameType = nNameType or item.Logic.nameType 
    if self.NameTitleList[key].Logic.TitCell == nil or item.Render.CellObject == nil then
        return
    end
	self.NameTitleList[key].Logic.TitCell:RefreshStyle(nameType,nil,bHPred)
end

--设置成就名字
function NameTitleWindow:SetAchiveTitle(entityId,name)
	local key = tostring(entityId)
	local item = self.NameTitleList[key]
	if not item then
		local item = {}
        item.Logic = 
        {

			AchiveName = "",

        }
		item.Render ={}
		item.Logic.uid = toint64(key)
		item.Logic.AchiveName = name
        self.NameTitleList[key] = item
		return
	end
	self.NameTitleList[key].Logic.AchiveName = name
    if self.NameTitleList[key].Logic.TitCell == nil or item.Render.CellObject == nil then
        return
    end
	self.NameTitleList[key].Logic.TitCell:RefreshAchiveName(name)
end

--设置阵营路径
function NameTitleWindow:SetCampPath(entityId,path)
	local key = tostring(entityId)
	local item = self.NameTitleList[key]
    if not item then
		item = {}
        item.Logic = 
        {

        }
		item.Render ={}
		item.Logic.uid = toint64(key)
		item.Logic.CampPath = path
        self.NameTitleList[key] = item
        return
    end
	
	item.Logic.CampPath = path
	if self.NameTitleList[key].Logic.TitCell == nil or item.Render.CellObject == nil then
        return
    end

	self.NameTitleList[key].Logic.TitCell:RefreshCamp(path)
end



--[[nameInfo = {
entityID = 0,
name = "",
FamilyName = "",
AchiveName = "",
nameType = NameTitleType.NameType_None
CurrentHp="",
MaxHp = "",
CampPath="",
headInfo=”“
}]]
function NameTitleWindow:AddNameTitleInfo(nameInfo)
	if nameInfo == nil then 
		return 
	end 
    local key = tostring(nameInfo.entityID)
	--检查是否在有效距离
	if not self:CheckCanAddName(key) then 
		return 
	end
	
    local item = self.NameTitleList[key]
    if nil == item then
        item = {}
        item.Logic = 
        {
            Name = "" ,
            CurHp = 0 ,
            MaxHp = 0 ,
			FamilyName = "",
			AchiveName = "",
			headInfo = nil,
			NameState = true,
			HpState = true,
        }
		item.Render ={}
        self.NameTitleList[key] = item
    end
    item.Logic.Name = nameInfo.name
	item.Logic.nameType = nameInfo.nameType
	item.Logic.CurHp = nameInfo.CurrentHp
	item.Logic.MaxHp = nameInfo.MaxHp
	item.Logic.FamilyName = nameInfo.FamilyName
	item.Logic.AchiveName = nameInfo.AchiveName
	item.Logic.CampPath = nameInfo.CampPath
	item.Logic.headInfo = nameInfo.HeadInfo
	item.Logic.uid = toint64(key)
    if not self:isLoaded() then
        return
    end
    if nil == self.NameTitleList[key].Logic.TitCell then
        rkt.GResources.FetchGameObjectAsync( GuiAssetList.NpcNameTitleCell[nameInfo.nameType] ,NameTitleWindow.OnNameTitleCellLoaded , key , AssetLoadPriority.GuiNormal )
    else
        self.NameTitleList[key].Logic.TitCell:Init(item)
    end
end


--HeadInfo 参数结构如下
--[[HeadInfo ={

Path="",
color="",
alphaVal= val,

}
--]]

function NameTitleWindow:AddNameTitle( entityId , name,NameType,CurrentHp,HeroMaxHp,FamilyName,AchiveName,CampPath,HeadInfo)
	local entityView = rkt.EntityView.GetEntityView(entityId)
	if not entityView then
		return
	end
    local key = tostring(entityId)
    local item = self.NameTitleList[key]
		--检查是否在有效距离

    if nil == item then
        item = {}
        item.Logic = 
        {
            Name = "" ,
            CurHp = 0 ,
            MaxHp = 0 ,
			FamilyName = "",
			AchiveName = "",
			headInfo = nil,
			
			NameState = true,
			HpState = true,
		
        }
		item.Render ={}
        self.NameTitleList[key] = item
    end
    item.Logic.Name = name
	item.Logic.nameType = NameType
	item.Logic.CurHp = CurrentHp
	item.Logic.MaxHp = HeroMaxHp
	item.Logic.FamilyName = FamilyName
	item.Logic.AchiveName = AchiveName 
	item.Logic.CampPath = CampPath
	item.Logic.headInfo = HeadInfo
	item.Logic.uid = toint64(key)
    if not self:isLoaded() then
        return
    end
    if nil == self.NameTitleList[key].Logic.TitCell then
        rkt.GResources.FetchGameObjectAsync( GuiAssetList.NpcNameTitleCell[NameType] ,NameTitleWindow.OnNameTitleCellLoaded , key , AssetLoadPriority.GuiNormal )
    else
        self.NameTitleList[key].Logic.TitCell:Init(item)
    end
end

------------------------------------------------------------
function NameTitleWindow:SetHpValue( entityId , curHp , maxHp )
    local key = tostring(entityId)
	local item = self.NameTitleList[key]
	if not item then
		return
	end
	item.Logic.CurHp = curHp
    item.Logic.MaxHp = maxHp
    if item.Logic.TitCell == nil then
        return
    end
	if item.Render.CellObject == nil then 
		return
	end
	item.Logic.TitCell:RefreshHp(curHp,maxHp)
end
------------------------------------------------------------
function NameTitleWindow:RemoveNameTitle( entityId , info )
    local key = tostring(entityId)
    local item = self.NameTitleList[key]
    if nil == item  then
	--	print("server is error ，need remove entityid not exist".. tostring(entityId))
        return
    end
	if item.Render.CellObject == nil then 
		self.NameTitleList[key] = nil
		return
	end
	if item.Logic.TitCell.m_headCell ~= nil then 
		item.Logic.TitCell.m_headCell:SetActive(false)
		rkt.GResources.RecycleGameObject(item.Logic.TitCell.m_headCell)
	end
	
	--为了下次不要直接显示出来
	item.Logic.TitCell.transform.gameObject:SetActive(false)
	rkt.GResources.RecycleGameObject(item.Logic.TitCell.transform.gameObject)
	self.NameTitleList[key] = nil
end

------------------------------------------------------------
function NameTitleWindow:RemoveAll()
	for i, item in pairs(self.NameTitleList) do
		if item.Logic.TitCell and item.Render.CellObject then
			if item.Logic.TitCell.m_headCell ~= nil then 
				item.Logic.TitCell.m_headCell:SetActive(false)
				rkt.GResources.RecycleGameObject(item.Logic.TitCell.m_headCell)
			end
			--为了下次不要直接显示出来
			item.Logic.TitCell.transform.gameObject:SetActive(false)
			rkt.GResources.RecycleGameObject(item.Logic.TitCell.transform.gameObject)
		end
	end
	self.NameTitleList = {}
end
------------------------------------------------------------
return NameTitleWindow
