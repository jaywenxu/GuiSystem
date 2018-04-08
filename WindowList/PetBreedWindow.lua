--------------------------灵兽繁殖独立界面 ----------------------------

local PetBreedWindow = UIWindow:new
{
	windowName 	= "PetBreedWindow",
	
	m_PetIconCache = {},
	
	CurPage = -1,     						--当前界面类型 1-单人繁殖， 2-双人繁殖， 3-正在繁殖 4-繁殖完成
	LoadedShow = false,						--标记加载完显示
}

function PetBreedWindow:Init()
	self.PetBreedSetPage = require("GuiSystem.WindowList.Pet.Breed.PetBreedSetPage"):new()
	self.PetBreedingPage = require("GuiSystem.WindowList.Pet.Breed.PetBreedingPage"):new()
	self.PetNewPetPage   = require("GuiSystem.WindowList.Pet.PetNewPet.PetNewPetWidget"):new()
end

local titleImagePath = AssetPath.TextureGUIPath.."Shop/store_shangcheng_biaoti.png"
function PetBreedWindow:OnAttach(obj)
	UIWindow.OnAttach(self,obj)
	
	self.PetBreedSetPage = require("GuiSystem.WindowList.Pet.Breed.PetBreedSetPage"):new()
	self.PetBreedingPage = require("GuiSystem.WindowList.Pet.Breed.PetBreedingPage"):new()
	self.PetNewPetPage   = require("GuiSystem.WindowList.Pet.PetNewPet.PetNewPetWidget"):new()

	self.PetBreedSetPage:Attach(self.Controls.m_PetBreedSet.gameObject)
	self.PetBreedingPage:Attach(self.Controls.m_PetBreeding.gameObject)
	self.PetNewPetPage:Attach(self.Controls.m_PetNewPet.gameObject)

	self.CloseWindowCB = function() self:CloseWin() end

	if self.needShowBreeding then
		self:LateInitShow(self.CurPage, self.CurLucky)
	end
	

	self.Controls.m_CloseBtn.onClick:AddListener(self.CloseWindowCB)

    self.LuckyTipCB = function() self:ShowLuckyValueTip() end 
    self.Controls.m_btnLuckyTip.onClick:AddListener(self.LuckyTipCB)
    
    self.OnHideLuckyTip = function() self:HideLuckyTip() end 
    self.Controls.m_CloseTipBtn.onClick:AddListener(self.OnHideLuckyTip)
    
    self.Controls.m_ZheZhaoTipBtn.onClick:AddListener(self.OnHideLuckyTip)
end

function PetBreedWindow:Show( bringTop )
	UIWindow.Show(self, bringTop)
end

function PetBreedWindow:Hide(destory)
	self.CurPage = -1
	
	if self.PetBreedSetPage:isShow() then
		self.PetBreedSetPage:Hide()
	end
	self:ClearCache()
	
	rktEventEngine.FireEvent(EVENT_PET_CLOSEBREEDWIN, SOURCE_TYPE_PET, 0)
	UIWindow.Hide(self, destory)
end

function PetBreedWindow:Destory()
	self.CurPage = -1
	self:ClearCache()
	UIWindow.Destory(self)
end
------------------------------------------------------------------------------------------
--打开单人or双人繁殖界面
function PetBreedWindow:OpenWindow(defaultPage,lucky_var)
	self.CurPage = defaultPage
	self.CurLucky = lucky_var

	if self:isLoaded() then
		self:LateInitShow(self.CurPage,lucky_var)
	end
	self.needShowBreeding = true
	self:Show()
end

--打开正在繁殖界面
function PetBreedWindow:OpenBreedingPage(rest_time, nPetID, cur_get_count, total_count)
	self.CurPage = 3
	
	self.resTime = rest_time
	self.ingPetID = nPetID
	self.ingCurCount = cur_get_count
	self.ingTotalCount = total_count
	
	if self:isLoaded() then
		self:LateInitShow(self.CurPage)
	else
		self.needShowBreeding = true
	end
	
	self:Show()
end

--打开繁殖结束
function PetBreedWindow:OpenBreedFinishPage(nPetID, cur_get_count, total_count)
	self.CurPage = 4
	
	self.finishPetID = nPetID
	self.finishCurCount = cur_get_count
	self.finishTotalCount = total_count
	
	if self:isLoaded() then
		self:LateInitShow(self.CurPage)
	else
		self.needShowBreeding = true
	end
	
	self:Show()
end

function PetBreedWindow:ClearCache()
	self.resTime = nil
	self.ingPetID = nil
	self.ingCurCount = nil
	self.ingTotalCount = nil
	
	self.finishPetID = nil
	self.finishCurCount = nil
	self.finishTotalCount = nil
end

--异步加载完后，设置显示
function PetBreedWindow:LateInitShow(subPage, lucky_var)
	if subPage == 1 or subPage == 2 then 
		self.PetBreedSetPage:SetType(self.CurPage, lucky_var)
		self.PetBreedSetPage:Show()
		self.PetBreedingPage:Hide()
	elseif subPage == 3 then
		self.PetBreedingPage:SetState(3, self.ingPetID, self.ingCurCount, self.ingTotalCount, self.resTime)
		self.PetBreedSetPage:Hide()
		self.PetBreedingPage:OpenBreedingPage()
	elseif subPage == 4 then
		self.PetBreedingPage:SetState(4, self.finishPetID, self.finishCurCount, self.finishTotalCount, 0)
		self.PetBreedSetPage:Hide()
		self.PetBreedingPage:Hide()
		self.PetNewPetPage:SetData(self.finishCurCount, self.finishTotalCount)
		self.PetNewPetPage:Show()
	else
		self.PetBreedSetPage:Hide()
		self.PetBreedingPage:Hide()

	end
end

--关闭界面，本window
function PetBreedWindow:CloseWin()
	if self.CurPage == 1 then
		--GameHelp.PostServerRequest("RequestClosePetSingleBreedUI()")
	elseif self.CurPage == 2 then
		GameHelp.PostServerRequest("RequestClosePetTeamBreedUI()")
	end
	self:Hide()
end

--关闭界面
function PetBreedWindow:CloseWindow(page)
	if page == 1 then
		--GameHelp.PostServerRequest("RequestClosePetSingleBreedUI()")
	elseif page == 2 then
		GameHelp.PostServerRequest("RequestClosePetTeamBreedUI()")
	end
	self:Hide()
end

-- 显示幸运值提示
function PetBreedWindow:ShowLuckyValueTip()
    
    self.Controls.m_LuckyTipContext.text = gPetCfg.PetLuckyDesc
    self.Controls.m_LuckyTip.gameObject:SetActive(true)
end

-- 隐藏幸运值提示
function PetBreedWindow:HideLuckyTip()
    
    self.Controls.m_LuckyTip.gameObject:SetActive(false)
end

return PetBreedWindow