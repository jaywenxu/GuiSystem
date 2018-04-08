
local PetItemClass = require("GuiSystem.WindowList.Pet.PetIconItem")
---------------------------灵兽系统繁殖界面---------------------------------------
local PetBreedWidget = UIControl:new
{
	windowName = "PetBreedWidget",
	
	m_PetIconCache = {}, 				--缓存灵兽脚本
	
	m_RightItemChache = nil,			--缓存右边对应的iconItem
}

function PetBreedWidget:Attach(obj)
	UIControl.Attach(self,obj)
	

	
	
	--异步加载繁殖设置界面
	rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetBreedSetPage ,
		function ( path , obj , ud )
			if nil ==obj then   -- 判断U3D对象是否已经被销毁
				return
			end
			obj.transform:SetParent(self.Controls.m_PetBreedSetParent,false)
			self.PetBreedSetPage:Attach(obj)
			self.LoadedSetPage = true
		end , nil , AssetLoadPriority.GuiNormal )
		
		
	
	self.ToggleGroup = self.Controls.m_ToggleGroup.gameObject:GetComponent(typeof(ToggleGroup))
	self.PetIconClickCB = function(nID, item) self:OnPetIconClick(nID, item) end
	
	self.BreedLockCB = function() self:OnBreedLock() end
	rktEventEngine.SubscribeExecute(EVENT_PET_BREEDlOCK, SOURCE_TYPE_PET, 0, self.BreedLockCB)
	
	self.BreedUnLockCB = function() self:OnBreedUnLock() end
	rktEventEngine.SubscribeExecute(EVENT_PET_BREEDUNlOCK, SOURCE_TYPE_PET, 0, self.BreedUnLockCB)

	self.LateShowCB = function() self:LateShow() end
	
	
	--服务器发的修改左边显示灵兽回调
	self.MsgChangeLeftPetCB = function(_,_,_,nID) self:OnMsgChangeLeftPet(nID) end
	--服务器下发锁定左边灵兽
	self.MsgLockLeftPetCB = function() self:OnMsgLockLeftPet() end
end

--设置显示界面,是否正在繁殖
function PetBreedWidget:Show()
	UIControl.Show(self)

	--判断该显示哪个界面    1-设置界面， 2-正在繁殖
	


	if self.LoadedSetPage and self.LoadedBreedingPage then
		
	else
		--异步加载完再显示, 判断哪个界面,  
		self.needToShow = 1
		rktTimer.SetTimer(self.LateShowCB, 60, -1, "PetBreedWidget:LateShow()")
	end
end

function PetBreedWidget:Hide( destroy )
	if self.PetBreedSetPage:isShow() then
		self.PetBreedSetPage:Hide(destroy)
	elseif self.PetBreedingPage:isShow() then
		self.PetBreedingPage:Hide(destroy)
	end
	
	self.teamBreeding = false
	
	UIControl.Hide(self, destroy)
end

function PetBreedWidget:OnDestroy()
	rktEventEngine.UnSubscribeExecute(EVENT_PET_BREEDlOCK, SOURCE_TYPE_PET, 0, self.BreedLockCB)	
	rktEventEngine.UnSubscribeExecute(EVENT_PET_BREEDUNlOCK, SOURCE_TYPE_PET, 0, self.BreedUnLockCB)	
	
	self.LoadedSetPage = false
	self.LoadedBreedingPage = false
	
	UIControl.OnDestroy(self)
end
------------------------------------------------------------------------------------------------------
--加载完显示界面
function PetBreedWidget:LateShow()
	if self.LoadedSetPage and self.LoadedBreedingPage then
		--加载完了显示
		if self.needToShow == 1 then
			self.PetBreedSetPage:Show()
			self.needToShow = 0
		elseif self.needToShow == 2 then
			self.PetBreedingPage:ShowBreedingPage(3000)						--剩余时间todo
			self.needToShow = 0
		end
		rktTimer.KillTimer(self.LateShowCB)
	end
end

--初始化灵兽列表
function PetBreedWidget:InitPetListView()
	local tableNum = #self.m_PetIconCache
	if tableNum > 0 then
		for i, data in pairs(self.m_PetIconCache) do
			data:Destroy()
		end
	end
	self.m_PetIconCache = {}
	
	--从model中获取灵兽Table
	local petList = IGame.PetClient:GetCurPetTable()
	if not petList then return end
	local count = #petList
	
	for	i = 1,count do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetIconItem,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_PetListParent, false)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = PetItemClass:new({})
			item:Attach(obj)
			item:SetToggleGroup(self.ToggleGroup)
			item:SetShowSelectedEffect(false)
			item:SetFocus(false)
			item:SetChangeState(true)
--			local iconPath = "Icon_Item/wuqi1.png"
			local isFighting = false
			local level = 10
			local uid = petList[i]
			local petID = IGame.PetClient:GetIDByUID(uid)
			item:InitState(petID, iconPath, level, false, self.PetIconClickCB,uid)
			
			table.insert(self.m_PetIconCache,i,item)	
		end , i , AssetLoadPriority.GuiNormal )
	end
end

--icon点击事件
function PetBreedWidget:OnPetIconClick(nID,item)
	if IGame.PetClient:IsBreeding() then
		return
	end
	
	if not self.teamBreeding then						--双方正在繁殖，不做条件检测
		--繁殖条件判断
		if not self:CheckBreed() then
			return
		end
	end
	
	
	if self.PetBreedSetPage.RightLock then 
		return
	end
	
	if self.m_RightItemChache and nID == self.m_RightItemChache.m_ID then 
		return
	end
	
	if self.m_RightItemChache then
		self.m_RightItemChache:SetSelectedImgState(false)
	end
	
	self.m_RightItemChache = item
	item:SetSelectedImgState(true)
	
	self.PetBreedSetPage:SetRightView(nID)
	--发送修改显示请求
	
end

--繁殖条件检测   返回 false - 不能繁殖， 
function PetBreedWidget:CheckBreed()
	--队伍检测
	local myTeam = IGame.TeamClient:GetTeam()
	if nil == myTeam then 
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "两人组队才能进行灵兽繁殖")
		return false
	else
		if #myTeam.m_listMemberInfo ~= 2 then
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "两人组队才能进行灵兽繁殖")
			return false
		end
	end
	
	--地图检测
	local myMapID = IGame.EntityClient:GetMapID()
	local teammateMapID = myMapID				--TODO
	
	if myMapID ~= teammateMapID then
		return false
	end
	
	--对方是否有正在繁殖的灵兽检测
	
	--
	
end


---------------------服务器回包响应----------------------

--接受到服务器发送的改变左侧的消息
function PetBreedWidget:OnMsgChangeLeftPet(nUID)
	self.PetBreedSetPage:SetLeftView(nUID)
end

--接受到服务器发送的确认左侧的消息
function PetBreedWidget:OnMsgLockLeftPet()
	self.PetBreedSetPage:LockLeftView()
end


--锁定回调
function PetBreedWidget:OnBreedLock()
	for i, data in pairs(self.m_PetIconCache) do
		data:SetInteractable(false)
	end
end

--解锁回调
function PetBreedWidget:OnBreedUnLock()
	for i, data in pairs(self.m_PetIconCache) do
		data:SetInteractable(true)
	end
end

return PetBreedWidget
