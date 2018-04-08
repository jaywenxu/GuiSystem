

local DragonFunctionModuleCellClass = require("GuiSystem.WindowList.DragonBall.DragonFunctionModuleCell")    --加载模块
local DragonFunctionItemCellClass = require("GuiSystem.WindowList.DragonBall.DragonFunctionItemCell")    --加载branchingItem模块
local DragonParamCellClass = require("GuiSystem.WindowList.DragonBall.DragonParamCell")    -- 参数模块

------------------------------------------------------------
local DragonBallWindow = UIWindow:new
{
	windowName = "DragonBallWindow" ,
	m_curHtml = nil,
    m_curDesc = nil,
	m_functionList = {},
	m_curFunction = "",
	m_curParamList = {}
}
------------------------------------------------------------
function DragonBallWindow:Init()

end
------------------------------------------------------------
function DragonBallWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	
	-- 返回主菜单
	self.calbackBackButtonClick = function() self:OnBackButtonClick() end
	self.Controls.BackButton.onClick:AddListener( self.calbackBackButtonClick )
	
	-- 发送按钮
	self.calbackSendButtonClick = function() self:OnSendButtonClick() end
	self.Controls.SendButton.onClick:AddListener( self.calbackSendButtonClick )
	
	-- 关闭按钮
	self.calbackCloseButtonClick = function() self:OnCloseButtonClick() end
	self.Controls.CloseButton.onClick:AddListener( self.calbackCloseButtonClick )

    if nil ~= self.m_curHtml then
        if nil ~= self.m_curDesc then
            self:UpdateFunctions( self.m_curDesc , self.m_curHtml )
        else
            self:UpdateModuleFunction( self.m_curHtml )
        end
    end
end
------------------------------------------------------------
function DragonBallWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------

-- 返回主菜单
function DragonBallWindow:OnBackButtonClick()
	GameHelp.PostServerRequest("RequestSupperStone_GoBackMenu()")
end

-- 发送
function DragonBallWindow:OnSendButtonClick()
	
	if IsNilOrEmpty(self.m_curFunction) then
		return
	end
	local szFun = self.m_curFunction.."("
	local nIndex = 1
	for i, cellItem in pairs(self.m_curParamList) do
		
		if nIndex ~= 1 then
			szFun = szFun.. ","
		end
		
		local number = tonumber(cellItem:GetParamText())
		if not number then
			szFun = szFun.."\'"..tostringEx(cellItem:GetParamText()).."\'"
		else
			szFun = szFun..cellItem:GetParamText()
		end
		nIndex = nIndex + 1
	end
	szFun = szFun.. ")"
	GameHelp.PostServerRequest(szFun)
end

-- 关闭
function DragonBallWindow:OnCloseButtonClick()
	self:Hide()
end

-- 更新模块
function DragonBallWindow:UpdateModuleFunction(szHtml)
	self:UpdateModuleFunctionEx(szHtml)
end

-- 回收模块功能对象
function DragonBallWindow:RecycleModuleObject()
	
	-- 控件对象是否存在
	if not self.Controls.functionListGroups or not self.Controls.functionListGroups.transform  then
		return
	end
	
	local nCount = self.Controls.functionListGroups.transform.childCount
	if nCount <= 0 then
		return
	end
	
	local tmpTable = {}
	for i = 1, nCount, 1 do
		table.insert(tmpTable, self.Controls.functionListGroups.transform:GetChild(i-1).gameObject)
	end
	for i, v in pairs(tmpTable) do
		rkt.GResources.RecycleGameObject(v)
	end
end

-- 回收函数功能对象
function DragonBallWindow:RecycleFunctionObject()
	
	-- 控件对象是否存在
	if not self.Controls.funGroups or not self.Controls.funGroups.transform  then
		return
	end
	
	local nCount = self.Controls.funGroups.transform.childCount
	if nCount <= 0 then
		return
	end
	
	local tmpTable = {}
	for i = 1, nCount, 1 do
		table.insert(tmpTable, self.Controls.funGroups.transform:GetChild(i-1).gameObject)
	end
	for i, v in pairs(tmpTable) do
		rkt.GResources.RecycleGameObject(v)
	end
end


-- 回收参数对象
function DragonBallWindow:RecycleParamObject()
	
	-- 控件对象是否存在
	if not self.Controls.paramGroups or not self.Controls.paramGroups.transform  then
		return
	end
	
	local nCount = self.Controls.paramGroups.transform.childCount
	if nCount <= 0 then
		return
	end
	
	local tmpTable = {}
	for i = 1, nCount, 1 do
		table.insert(tmpTable, self.Controls.paramGroups.transform:GetChild(i-1).gameObject)
	end
	for i, v in pairs(tmpTable) do
		rkt.GResources.RecycleGameObject(v)
	end
end

-- 解析模块参数列表
function DragonBallWindow:ParasModuleList(szHtml) 
	local ss, matchList = lua_GetStrAndMatchSubList(szHtml,"<li>","</li>")
	if not matchList or type(matchList) ~= 'table' then
		return nil
	end
	local moduleList = {}
	for i,v in pairs(matchList) do
		local szTmp, tmpfunc = lua_GetMatchSubStr( v,"<a href=",">" )
		local szTemp,tmpName = lua_GetMatchSubStr( v,"<DBC>","</DBC>" )
		if tmpfunc and tmpName then
			local item = 
			{
				szfunc = tmpfunc,
				moduleName = tmpName,
			}
			table.insert(moduleList,item)
		end
	end
	return moduleList
end

-- 回收
function DragonBallWindow:UpdateModuleFunctionEx(szHtml)

	if not self:isLoaded() then
        self.m_curHtml = szHtml
        return
    end

	-- 回收
	self:RecycleModuleObject()
	self:RecycleFunctionObject()
	self:RecycleParamObject()
	self.Controls.scrollrect.verticalNormalizedPosition =1
	-- 设置描述信息
	self.Controls.DescText.text = ""
	self.m_curFunction  = ""
	
	local tmpModuleList = self:ParasModuleList(szHtml) 
	if not tmpModuleList then
		return
	end
	
	for i, v in pairs(tmpModuleList) do
		local pToggleGroup = self.Controls.functionListGroups.transform:GetComponent(typeof(ToggleGroup))
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.DragonFunctionModuleCell,
		function ( path , obj , ud )
		if nil == self.Controls.functionListGroups.transform.gameObject then   -- 判断U3D对象是否已经被销毁
			rkt.GResources.RecycleGameObject(obj)
			return
		end
		obj.transform:SetParent(self.Controls.functionListGroups.transform,false)
		local itemtask = DragonFunctionModuleCellClass:new({})
		itemtask:Attach(obj)
		itemtask:SetToggleGroup( pToggleGroup )
		itemtask:SetItemInfo(v.szfunc, v.moduleName)
		end , nil , AssetLoadPriority.GuiNormal )
	end
end

-- 解析函数方法和参数
function DragonBallWindow:ParamFunctionList(szHtml)
	
	local ss, matchList = lua_GetStrAndMatchSubList(szHtml,"<li>","</li>")
	if not matchList or type(matchList) ~= 'table' then
		return nil
	end
	
	local functionList = {}
	for i,v in pairs(matchList) do
		
		local xx, szTitle = lua_GetMatchSubStr( v,"<Title>","</Title>" )
		local szTmp, tmpfunc = lua_GetMatchSubStr( v,"<a href=",">" )
		local szTemp,tmpParamList = lua_GetStrAndMatchSubList( szTmp,"<DBC>","</DBC>" )
		local item = 
		{
			szfunc = tmpfunc,
			szTitle = szTitle,
			paramList = tmpParamList,
		}
		table.insert(functionList,item)
	end
	return functionList
end

-- 更新功能方法
function DragonBallWindow:UpdateFunctions(szDesc, szHtml)
	if not self:isLoaded() then
        self.m_curHtml = szHtml
        self.m_curDesc = szDesc
        return
    end
	-- 回收方法和参数
	self:RecycleFunctionObject()
	self:RecycleParamObject()
	
	-- 设置描述信息
	self.Controls.DescText.text = szDesc or ""
	
	local functionList = self:ParamFunctionList(szHtml)
	if not functionList then
		return
	end
	
	for i, v in pairs(functionList) do
		local pToggleGroup = self.Controls.funGroups.transform:GetComponent(typeof(ToggleGroup))
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.DragonFunctionItemCell ,
		function ( path , obj , ud )
		if nil == self.Controls.funGroups.transform.gameObject then   -- 判断U3D对象是否已经被销毁
			rkt.GResources.RecycleGameObject(obj)
			return
		end
		obj.transform:SetParent(self.Controls.funGroups.transform,false)
		local itemtask = DragonFunctionItemCellClass:new({})
		itemtask:Attach(obj)
		itemtask:SetToggleGroup( pToggleGroup )
		itemtask:SetItemInfo(v.szfunc,v.szTitle, v.paramList)
		end , nil , AssetLoadPriority.GuiNormal )
	end
end


function DragonBallWindow:SetCurFunctionParam(szfun, paramList)
	
	self:RecycleParamObject()
	
	local paramTransform = self.Controls.paramGroups.transform
	if not paramTransform then
		return
	end
	self.m_curParamList = {}
	self.m_curFunction = szfun
	
	for i,v in pairs(paramList) do
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.DragonParamCell ,
		function ( path , obj , ud )
		if nil == paramTransform.gameObject then   -- 判断U3D对象是否已经被销毁
			rkt.GResources.RecycleGameObject(obj)
			return
		end
		obj.transform:SetParent(paramTransform,false)
		local item = DragonParamCellClass:new({})
		item:Attach(obj)
		item:SetItemInfo(v)
		table.insert(self.m_curParamList,item)
		end , nil , AssetLoadPriority.GuiNormal )
	end
end

-- 查找物品列表
function DragonBallWindow:FindItems(szGoodsName)
	if not self:isShow() then
		return
	end
	if IsNilOrEmpty(szGoodsName) then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "输入物品名字为空！")
		return
	end
	local itemGoods = {}
	local tmpTable = IGame.rktScheme:GetSchemeTable( LEECHDOM_CSV )
	for i = 0, CsvRowCount(tmpTable)-1 do
        local item = CsvRow(tmpTable,i)
		local pos = string.find(item.szName,szGoodsName)
		if pos and pos > 0  then
			itemGoods[item.lGoodsID] = item.szName
		end
	end
	local itemEquip = {}
	tmpTable = IGame.rktScheme:GetSchemeTable( EQUIP_CSV )
	for i, item in pairs(tmpTable) do
		local pos = string.find(item.szName,szGoodsName)
		if pos and pos > 0  then
			itemEquip[item.GoodsID] = item.szName
		end
	end
	if table_count(itemGoods) <= 0 and table_count(itemEquip) <= 0 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "找不到该物品,查找名："..szGoodsName)
		return
	end
	local szDesc = ""
	if table_count(itemGoods) > 0 then
		szDesc = "物品列表："
		for itemid, itemName in pairs(itemGoods) do
			szDesc = szDesc .. "\n" .. itemName .. ": "..itemid
		end
	end
	if table_count(itemEquip) > 0 then
		if not IsNilOrEmpty(szDesc) then
			szDesc = szDesc .."\n"
		end
		szDesc = szDesc.."装备物品列表："
		for itemid, itemName in pairs(itemEquip) do
			szDesc = szDesc .. "\n" .. itemName .. ": "..itemid
		end
	end
	self.Controls.DescText.text = szDesc
end

return DragonBallWindow
