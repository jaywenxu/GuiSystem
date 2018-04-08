-- 服务器选择界面
-- @Author: XieXiaoMei
-- @Date:   2017-06-07 14:38:44
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-27 11:16:45

local 	ServerSelectWindow = UIWindow:new
{
	windowName      = "ServerSelectWindow",
	
	m_ServersUpdateCallback = nil, --数据更新回调

	m_ServerList = {}, --服务器列表

	m_AreaCellList = {},		--大区元素表
	m_ServerCellList = {},		--服务器元素表
	m_LastLoginCellList = {},	--最近登录的元素表

	m_SelServer = nil,	--选中的服务器
	m_SelAreaIdx = 0,	--选中的大区索引

	m_Recommend = {		--推荐服务器
		areaIdx = 0,
		serID = 0
	},
}


------------------------------------------------------------
function ServerSelectWindow:Init()
end

------------------------------------------------------------

-- 附加初始化
function ServerSelectWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	local controls = self.Controls
	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))

	controls.serversTglGroup = controls.m_ServerListTf:GetComponent(typeof(ToggleGroup))	
	controls.areaTglGroup = controls.m_AreaListTf:GetComponent(typeof(ToggleGroup))	

	self.m_ServersUpdateCallback = handler(self, self.RefreshUI)
	rktEventEngine.SubscribeExecute(EVENT_REQUEST_SERVERLIST_SUCCEED, 0, 0, self.m_ServersUpdateCallback)
	
	self:RefreshUI()
end

------------------------------------------------------------

-- 销毁窗口
function ServerSelectWindow:OnDestroy()
	rktEventEngine.UnSubscribeExecute( EVENT_REQUEST_SERVERLIST_SUCCEED , 0 , 0 , self.m_ServersUpdateCallback )
	self.m_ServersUpdateCallback = nil

	self:DestroyAllCells()

	UIWindow.OnDestroy(self)

	table_release(self)
end

------------------------------------------------------------

-- 刷新界面
function ServerSelectWindow:RefreshUI()
	self:DestroyAllCells()

	self.m_ServerList = IGame.HttpController.GetServerList()

	local server = IGame.HttpController:GetRecommendServer()
	if server then
		self.m_Recommend.areaIdx = server.areaIdx
		self.m_Recommend.serID = server.serverID
	end

	self:LoadAreaCells()
	
	self:LoadLoginedCells()
end

------------------------------------------------------------

-- 加载服务器大区元素
function ServerSelectWindow:LoadAreaCells()
	self:DestroyCells("m_AreaCellList")

	local areaListTf = self.Controls.m_AreaListTf
	local num = table_count(self.m_ServerList)
	local loadedNum = 0
	for i, v in pairs(self.m_ServerList) do
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.AreaCell , 
		   	function( path , obj , ud )
				if nil == obj then   -- 判断U3D对象是否已经被销毁
					rkt.GResources.RecycleGameObject(obj)
					return
				end

				obj.transform:SetParent(areaListTf, false)
				
				local item = {}
				item.go = obj

				local tgl = obj.transform:GetComponent(typeof(Toggle))	
				tgl.onValueChanged:AddListener(function (on)
					obj.transform:Find("Selected").gameObject:SetActive(on)
					if not on then return end
					self.m_SelAreaIdx = v.index
					self:LoadServerCells()
				end)
				tgl.group = self.Controls.areaTglGroup
--				tgl.isOn =  self.m_Recommend.areaIdx == v.index
				
				item.index = v.index
				item.tgl = tgl

				local txt = obj.transform:Find("Text"):GetComponent(typeof(Text))
				txt.text = v.name

				local SelectTxt = obj.transform:Find("Selected/SelectText"):GetComponent(typeof(Text))
				SelectTxt.text = v.name

				item.txt = txt

				self.m_AreaCellList[v.index] = item
				loadedNum = loadedNum + 1
				if loadedNum == num then
					for i, data in pairs(self.m_AreaCellList) do
						if data.index == self.m_Recommend.areaIdx then
							data.tgl.isOn = true
							return
						end
					end
				end
			end,
		nil, AssetLoadPriority.GuiNormal )
	end
end

 
------------------------------------------------------------

-- 加载最近登陆的服务器元素
function ServerSelectWindow:LoadLoginedCells()
	self:DestroyCells("m_LastLoginCellList")
	
	local server = IGame.HttpController:GetLastLoginedServer()
	if isTableEmpty(server) then
		print("the saved last server is nil")
		return
	end

	self:CreateServerCell(self.Controls.m_LoginedServersTf, server, self.m_LastLoginCellList)
end

------------------------------------------------------------

-- 加载大区服务器元素
function ServerSelectWindow:LoadServerCells()
	self:DestroyCells("m_ServerCellList")

	local parentTf = self.Controls.m_ServerListTf
	local serverList = self.m_ServerList[self.m_SelAreaIdx]
	if serverList and serverList.servers then
		for i, v in ipairs(serverList.servers) do
			self:CreateServerCell(parentTf, v, self.m_ServerCellList)
		end
	end
	
end

------------------------------------------------------------

-- 加载服务器大区元素
function ServerSelectWindow:CreateServerCell(parentTf, data, cellList)
	
	rkt.GResources.FetchGameObjectAsync( GuiAssetList.ServerCell , 
   	function( path , obj , ud )
		if nil == obj then   -- 判断U3D对象是否已经被销毁
			rkt.GResources.RecycleGameObject(obj)			
			return
		end
		obj.transform:SetParent(parentTf, false)
		
		local item = {}
		item.go = obj

		local tgl = obj.transform:GetComponent(typeof(Toggle))	
		if self.m_Recommend.areaIdx == self.m_SelAreaIdx then
			if self.m_Recommend.serID == data.serverID then
				tgl.isOn = true
				self.m_SelServer = data
				obj.transform:Find("Selected").gameObject:SetActive(false)
				obj.transform:Find("Selected").gameObject:SetActive(true)
			end
		end
		
		tgl.onValueChanged:AddListener(function (on)
			obj.transform:Find("Selected").gameObject:SetActive(on)
			if not on then return end

			self.m_SelServer = data

			self:OnBtnCloseClicked()
		end)
		
		tgl.group = self.Controls.serversTglGroup

		item.tgl = tgl

		local txt = obj.transform:Find("Text"):GetComponent(typeof(Text))
		txt.text = data.serverName
		
		local SelectTxt = obj.transform:Find("Selected/SelectText"):GetComponent(typeof(Text))
		SelectTxt.text = data.serverName
		
		item.txt = txt

		cellList[data.serverID] = item
	end, nil, AssetLoadPriority.GuiNormal )
end

------------------------------------------------------------

-- 删除界面所有元素
function ServerSelectWindow:DestroyAllCells()
	self:DestroyCells("m_LastLoginCellList")
	self:DestroyCells("m_AreaCellList")
	self:DestroyCells("m_ServerCellList")
end

------------------------------------------------------------

-- 销毁时间段元素
function ServerSelectWindow:DestroyCells(listName)
	for i, v in pairs(self[listName]) do
		self:RecycleCell(v)
	end
	self[listName] = {}
end

------------------------------------------------------------

-- 回收元素
function ServerSelectWindow:RecycleCell(cell)
	cell.tgl.onValueChanged:RemoveAllListeners() --TODO:暂时先清除全部toggle控件的全部回调，换新界面再重构处理
	cell.tgl.gameObject.transform:Find("Selected").gameObject:SetActive(false)
	cell.tgl.isOn = false
	rkt.GResources.RecycleGameObject(cell.go)
end

------------------------------------------------------------

--  关闭按钮回调
function ServerSelectWindow:OnBtnCloseClicked()
	UIManager.LoginWindow:SetSelectedServer(self.m_SelServer)

	self:Hide()
end


return ServerSelectWindow