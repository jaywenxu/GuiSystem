-- 主界面活动按钮item
-- @Author: XieXiaoMei
-- @Date:   2017-06-30 17:36:02
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-16 17:02:04

------------------------------------------------------------
local MainActivityItem = UIControl:new
{
	windowName      = "MainActivityItem",
	
	m_ActID         = 0,	
	m_CDTime        = 0,
	m_TimerCallback = nil,
	m_ClickCallBack = nil,
}

local this = MainActivityItem

------------------------------------------------------------
function MainActivityItem:Attach(obj)
	UIControl.Attach(self,obj)
    
    self.m_TimerCallback = handler(self, self.OnTimerUpdate)

    self:AddListener( self.Controls.m_IconBtn , "onClick" , self.OnBtnIconClicked , self )

	return self
end

------------------------------------------------------------
function MainActivityItem:OnDestroy()
	UIControl.OnDestroy(self)

	self:StopTimer()
	self.m_ClickCallBack = nil
	self.m_ActID = 0
	self.m_CDTime = 0
end

------------------------------------------------------------
function MainActivityItem:RecycleItem()
	rkt.GResources.RecycleGameObject(self.transform.gameObject)
end

------------------------------------------------------------
function MainActivityItem:OnRecycle()
	self:StopTimer()
	self.m_ClickCallBack = nil
	self.m_ActID = 0
	self.m_CDTime = 0
	UIControl.OnRecycle(self)
end


------------------------------------------------------------
-- 设置Item数据
-- 	@param	data = {
--			actID,		-- 活动ID，用于显示icon图片
--  		callback,	-- 点击回调函数
--  		cdTime,		-- 剩余秒数,大于0则显示倒计时
--  		text,		-- 描述，不显示倒计时则传此参数
--		}
function MainActivityItem:SetData(data)
	self:StopTimer()	
	self.m_ActID   = data.actID
	self.m_ClickCallBack = data.callback
	self.m_CDTime = data.cdTime	
	self.m_data = data
	self:RefreshUI()	

end

function MainActivityItem:RefreshUI()
	if self.transform == nil then 
		return
	end
	local actWndCfg = IGame.rktScheme:GetSchemeInfo(ACTIVITYWINDOW_CSV, self.m_ActID)
	if not isTableEmpty(actWndCfg) then
		local iconPath = GuiAssetList.GuiRootTexturePath .. actWndCfg.IconID
		UIFunction.SetImageSprite(self.Controls.m_IconImg, iconPath, function ()
			self.Controls.m_IconImg:SetNativeSize()
		end)
		local iconNamePath = GuiAssetList.GuiRootTexturePath .. actWndCfg.IconNamePath
		if IsNilOrEmpty(actWndCfg.IconNamePath) then 
			self.Controls.m_IconNameImg.gameObject:SetActive(false)
		else
			self.Controls.m_IconNameImg.gameObject:SetActive(true)
			UIFunction.SetImageSprite(self.Controls.m_IconNameImg, iconNamePath, function ()
			self.Controls.m_IconNameImg:SetNativeSize()
			end)
		end
		
	end
	
	local str = ""
	
	if self.m_CDTime ~= nil and self.m_CDTime > 0 then	
		str = GetCDTime(self.m_CDTime, 3, 2)
		rktTimer.SetTimer(self.m_TimerCallback, 1000, -1, "activity item time down")
	else
		str = self.m_data.text or ""
	end
	self.Controls.m_TimerTxt.text = str
	if IsNilOrEmpty(str) then  
		self.Controls.m_TimeBg.gameObject:SetActive(false)
	else
		self.Controls.m_TimeBg.gameObject:SetActive(true)
	end
	
	if self.m_CDTime == 0 and not self.m_data.text then
		self.Controls.m_TimeBg.gameObject:SetActive(false)
	else
		self.Controls.m_TimeBg.gameObject:SetActive(true)
	end
end

------------------------------------------------------------
-- 
function MainActivityItem:OnBtnIconClicked()
	if self.m_ClickCallBack then
		self.m_ClickCallBack()
	end
end

------------------------------------------------------------
-- 倒计时更新函数
function MainActivityItem:OnTimerUpdate()
	self.m_CDTime = self.m_CDTime - 1
	if self.m_CDTime < 0 then
		self:StopTimer(true)
		return
	end

	self.Controls.m_TimerTxt.text = GetCDTime(self.m_CDTime, 3, 2)
end

------------------------------------------------------------
-- 停止倒计时timer
-- @param isHide 	:  	是否隐藏（删除）
function MainActivityItem:StopTimer(isHide)
	rktTimer.KillTimer(self.m_TimerCallback)

	if isHide then
		self:Hide(true)
	end
end

------------------------------------------------------------
-- 获取活动ID
function MainActivityItem:GetActID()
	return self.m_ActID
end

------------------------------------------------------------
-- item是否存在
function MainActivityItem:IsExsit()
	return self.transform ~= nil
end
------------------------------------------------------------
------------------------------------------------------------
------------------------------------------------------------
-- 创建一个活动Item
-- @param parentTf	:  父节点transform		
-- @param data 		:  data数据
function MainActivityItem.CreateItem(parentTf, data)
	local item = this:new()

	item:SetData(data)
	rkt.GResources.FetchGameObjectAsync( GuiAssetList.MainActivityItem , 
        function( path , obj , ud )
            if nil == obj then 
				uerror("prefab is nil ")
				return
			end
			if nil == parentTf or item.m_ActID == 0 then 
				rkt.GResources.RecycleGameObject(obj)
				return
			end

			obj.transform:SetParent(parentTf, false) 
			
			item:Attach(obj)
			item:RefreshUI()
        end , nil , AssetLoadPriority.GuiNormal)
	
	return item
end


return this



