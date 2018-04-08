-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2017 - All Rights Reserved
-- 创建人:    许文杰
-- 日  期:    2017/03/20
-- 版  本:    1.0
-- 描  述:    游戏加载界面
-------------------------------------------------------------------
local LoadingWindow = UIWindow:new
{
	windowName = "LoadingWindow",
	progressText = 0, --加载进度
	needShow = true , 
    needFireShownEvent = false , -- OnAttach时，是否需要触发显示事件
}
local this = LoadingWindow	-- 方便书写
------------------------------------------------------------
function LoadingWindow:Init()
end
------------------------------------------------------------
function LoadingWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	local mainCanvas = UIManager.FindMainCanvas()
	obj.transform:SetParent(mainCanvas.transform)
	obj.transform:SetAsLastSibling()
	self.progressText = self.Controls.progress:GetComponent(typeof(Slider))
	if nil ~= self.progressText  then 
		self.progressText.value = 0.0
		if self.needShow == false then 
			self.progressText.value = 1.0
			self:Hide()
            return
		end
	end
 --   self:SetFullScreen()
    if self:isShow() and self.needFireShownEvent then
        self:FireShownEvent()
        self.needFireShownEvent = false
    end
	self:ShowTips()
end
------------------------------------------------------------
function LoadingWindow:updatePercent()
	if not self:isLoaded() then
		return
	end

	if self.progressText.value < 0.95 then
		local newProgress =self.progressText.value + Time.fixedDeltaTime*4;
        if rktSceneManager.m_maxStep > 0 then
            newProgress = rktSceneManager.m_progress / rktSceneManager.m_maxStep;
            --print("loading progress:"..rktSceneManager.m_MainSceneAsync.progress)
        end
		self.progressText.value = newProgress	
		self.Controls.m_PerCent.text =tostring(math.ceil(self.progressText.value*100).."%") 
	 end
	 -- 已经加载完成了，开始构建场景
	 if rktSceneManager.m_MainSceneAsync then
		self.progressText.value = 1
		self.Controls.m_PerCent.text = "100%"
	 end
end
------------------------------------------------------------
function LoadingWindow:DelayHide()
    if self:isLoaded() then
		self.progressText.value = 1.0
		self.Controls.m_PerCent.text = tostring("100%") 
	end
	rktTimer.SetTimer( function() self:Hide() end , 100 , 1 , nil )
end
------------------------------------------------------------
function LoadingWindow:Show(bringTop)
	--初始化
	if not tolua.isnull( self.progressText ) then
		self.progressText.value=0.0
		self.Controls.m_PerCent.text = tostring("0%") 
	
	end

    self.needFireShownEvent = false
	self.needShow = true
	UIWindow.Show(self,bringTop)
	if self:isLoaded() then 
		self:ShowTips()
	end
	rktTimer.SetTimer(slot(self.updatePercent,self),100,-1 , "LoadingWindow:updatePercent")
    if self:isShow() then
        self:FireShownEvent()
    else
        self.needFireShownEvent = true
    end
end

--显示Tips
function LoadingWindow:ShowTips()
	local tipsTable = IGame.rktScheme:GetSchemeTable(LOADINGTIPS_CSV)
	if tipsTable == nil  then 
		return
	end
	
	local tableCount = table_count(tipsTable) 
	if tableCount == 0 then 
		return
	end
	local index = math.random(1,tableCount)

	local info = IGame.rktScheme:GetSchemeInfo(LOADINGTIPS_CSV,index)
	if info == nil then 
		return
	end

	self.Controls.m_Tips.text = info.TipsDec or ""
	
end
------------------------------------------------------------
function LoadingWindow:Hide()
    self.needFireShownEvent = false
	UIWindow.Hide(self,true)
	self.needShow = false
	rktTimer.KillTimer(slot(self.updatePercent,self))
end
------------------------------------------------------------
function LoadingWindow:FireShownEvent()
    rktTimer.SetTimer( 
        function() 
            if not UIManager.LoadingWindow:isShow() then
                return
            end
            rktEventEngine.FireExecute( EVENT_LOADINGWINDOW_SHOW , 0 , 0 )
        end , 30 , 1 , "" )
end
------------------------------------------------------------
return this
------------------------------------------------------------
