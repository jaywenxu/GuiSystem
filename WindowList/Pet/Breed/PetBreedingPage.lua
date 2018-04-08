---------------------------灵兽系统繁殖界面---------------------------------------
local PetBreedingPage = UIControl:new
{
	windowName = "PetBreedingPage",
	m_RemindSecondTime = 0,
}

function PetBreedingPage:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.DanClickCB = function() self:OnDanClick() end
	self.updateTimerFunc = function() self:UpdateTime() end
	
	self:RegisterEvent()
end

function PetBreedingPage:Show()
	UIControl.Show(self)
end

function PetBreedingPage:Hide( destroy )
	rktTimer.KillTimer( self.updateTimerFunc )
	UIControl.Hide(self, destroy)
end

function PetBreedingPage:IsShow()
	UIControl.IsShow(self)
end

function PetBreedingPage:OnDestroy()
	rktTimer.KillTimer( self.updateTimerFunc )
	UIControl.OnDestroy(self)
end

------------------------------------事件注册----------------------------------------------------------
function PetBreedingPage:RegisterEvent()
	self.Controls.m_DanBtn.onClick:AddListener(self.DanClickCB)
end

--点击蛋 事件
function PetBreedingPage:OnDanClick()
	if self.CurType == 3 then				--倒计时没有结束
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "孵化未完成！")
		return
	elseif self.CurType == 4 then

	end
end
----------------------------------------------------------------------------------------------------------
--设置一些值
function PetBreedingPage:SetState(nType, petID, curCount, totalCount, nRemainSecondTime)
	self.CurType = nType
	self.petID = petID
	self.curCount = curCount
	self.totalCount = totalCount 
	self.remainTime = nRemainSecondTime
end

--打开繁殖界面
function PetBreedingPage:OpenBreedingPage()
	self:Show()
	self:ShowBreedingPage(self.CurType)
end
--打开本界面   nRemainTime-剩余时间
function PetBreedingPage:ShowBreedingPage(nType)
	if nType == 3 then				--正在繁殖
		self.Controls.m_HuoDeText.text = string.format("倒计时结束后，点击灵兽蛋可获得%d只二代灵兽",self.totalCount)
		self.Controls.m_TopParent.gameObject:SetActive(true)
		
		--倒计时定时器， 精确计时
		self.m_RemindSecondTime = self.remainTime 
		self.Controls.m_DaoJiShiText.text = self:SecondTimeToString(self.m_RemindSecondTime)
		rktTimer.KillTimer( self.updateTimerFunc )
		self.CurTickCount = luaGetTickCount()
		rktTimer.SetTimer( self.updateTimerFunc, 120, -1, "PetBreedingPage:UpdateTime")
	elseif nType == 4 then			--繁殖结束
		self.Controls.m_HuoDeText.text = string.format("繁殖完成，点击灵兽蛋可获得%d只二代灵兽", self.totalCount - self.curCount)
		self.Controls.m_TopParent.gameObject:SetActive(false)
	end
end


--更新倒计时
function PetBreedingPage:UpdateTime()
	local now = luaGetTickCount()
	if now - self.CurTickCount>= 1000 then
		self.CurTickCount = now
		self.m_RemindSecondTime = self.m_RemindSecondTime - 1
	end
	
	self.Controls.m_DaoJiShiText.text = self:SecondTimeToString(self.m_RemindSecondTime)
	
	if self.m_RemindSecondTime <= 0 then
		self.Controls.m_TopParent.gameObject:SetActive(false)
		UIManager.PetBreedWindow:OpenBreedFinishPage(self.petID,self.curCount,self.totalCount)
		rktTimer.KillTimer( self.updateTimerFunc )
	end
end

--将秒转化为显示格式 00:00,  参数为秒
function PetBreedingPage:SecondTimeToString(nSecond)
	if not nSecond or nSecond < 0 then
		return "00:00"
	end
	
	local min = math.floor(nSecond/60)
	if min == 0 then
		min = "00"
	end
	local sec = nSecond%60
	min = string.format("%02d",min)
	sec = string.format("%02d",sec)
	return min .. ":" .. sec
end

return PetBreedingPage