
local PetModelDisPlayClass = require( "GuiSystem.WindowList.Pet.PetModelDisplay" )
---------------------------灵兽系统获得新灵兽界面---------------------------------------
local PetNewPetWidget = UIControl:new
{
	windowName = "PetNewPetWidget",
}

function PetNewPetWidget:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.LingQuBtnCB = function() self:LingQuBtnCallBack() end
	self.Controls.m_LingQuBtn.onClick:AddListener(self.LingQuBtnCB)
	--关闭灵兽界面事件监听
	self.ClosePetWindowCB = function() self:OnClosePetBreedWindow() end
	--rktEventEngine.SubscribeExecute(EVENT_PET_CLOSEBREEDWIN, SOURCE_TYPE_PET, 0, self.ClosePetWindowCB)
	
	self.OpenCB = function() self:Show() end
	--rktEventEngine.SubscribeExecute(EVENT_PET_OPENNEWPETPAGE, SOURCE_TYPE_PET, 0)
	
	--监听打开本界面的事件
	self.ShowNewPetWidgetCB = function(_,_,_,nID,nPetName) self:ShowNewPetWidget(nID, nPetName) end
	rktEventEngine.SubscribeExecute(EVENT_PET_SHOWNEWPET_WIDGET, SOURCE_TYPE_PET, 0, self.ShowNewPetWidgetCB)
	
end

function PetNewPetWidget:Hide(destroy)
	
	UIControl.Hide(self, destroy)
end

function PetNewPetWidget:Destroy()
	rktEventEngine.UnSubscribeExecute(EVENT_PET_CLOSEBREEDWIN, SOURCE_TYPE_PET, 0, self.ClosePetWindowCB)
	--rktEventEngine.UnSubscribeExecute(EVENT_PET_OPENNEWPETPAGE, SOURCE_TYPE_PET, 0)
	UIControl.Destroy(self)
end

--
function PetNewPetWidget:SetData(curCount, totalCount)
	self.curCount = curCount
	self.totalCount = totalCount
	self.Controls.m_TipText.text = string.format("可领取次数%d/%d", totalCount - curCount, totalCount)
end

--点击领取按钮
function PetNewPetWidget:LingQuBtnCallBack()
	if self.curCount < self.totalCount then
		GameHelp.PostServerRequest("RequestGetPetEgg()")
		self:Hide()
	end
	self:Hide()
end

--关闭灵兽界面
function PetNewPetWidget:OnClosePetBreedWindow()
	self:Hide()
end

return PetNewPetWidget