-- 功能性逻辑窗口的背景
-- 处理关闭事件回调
-- 金币购买等
------------------------------------------------------------
local CommonWindow = UIControl:new
{
	windowName = "CommonWindow" ,
    closeCallback = nil ,
	uid = 0,
	bSubscribeEvent = false,
	m_haveDoEnable =false
}

--背包界面打开时播放的音效
local PACK_WINDOW_UI_OPEN_AUDIO = "openbag.mp3"

--其他界面打开时播放的音效
local OTHER_WINDOW_UI_OPEN_AUDIO = "openwindow.mp3"
------------------------------------------------------------
function CommonWindow:Init()
end
------------------------------------------------------------
--m_TweenContainer : Common_Container_Widget (UnityEngine.RectTransform)
--m_BackGroundButton : Common_Bg_Widget (UnityEngine.UI.Button)
--m_CloseButton : Common_Close_Widget (UnityEngine.UI.Button)
--m_Tween : Common_Container_Widget (UnityEngine.RectTransform)
--m_MoneyWidget : Common_Money_Widget (UnityEngine.RectTransform)
------------------------------------------------------------
function CommonWindow:Attach( obj )
	UIControl.Attach(self,obj)
	self.Controls.m_nameImage.gameObject:SetActive(false)
    self.callback_CloseButtonClick = function() self:OnCloseButtonClick() end
    self.Controls.m_CloseButton.onClick:AddListener( self.callback_CloseButtonClick )
	self:AddListener(self.Controls.m_addDiamondBtn,"onClick",handler(self,self.OnClickAddDiamond),self)
	self:AddListener(self.Controls.m_addYinLiangBtn,"onClick",handler(self,self.OnClickAddYinLiang),self)
	self:AddListener(self.Controls.n_addYinBiBtn,"onClick",handler(self,self.OnClickAddYinBi),self)
	
	self.callback_OnYuanBaoUpdate = function(event, srctype, srcid, msg) self:OnExecuteUpdateYunaBao(event, srctype, srcid, msg) end
	self.callback_OnYinLiangUpdate = function(event, srctype, srcid, msg) self:OnExecuteUpdateYinLiang(event, srctype, srcid, msg) end
	self.callback_OnYinBiUpdate = function(event, srctype, srcid, msg) self:OnExecuteUpdateYinBi(event, srctype, srcid, msg) end
	
	-- 角色已经加载
	if IGame.EntityClient:GetHero() then
		self:SubscribeEvent()
	end
	self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))
	self.unityBehaviour.onDisable:AddListener(handler(self, self.OnDisable))
	self:OnEnable()
	return self
end

------------------------------------------------------------
function CommonWindow:OnDestroy()
    self.closeCallback = nil
	m_haveDoEnable =false
    self.Controls.m_CloseButton.onClick:RemoveListener( self.callback_CloseButtonClick )
	if self.bSubscribeEvent then
		rktEventEngine.UnSubscribeExecute( EVENT_CION_YUANBAO , SOURCE_TYPE_COIN , 0 , self.callback_OnYuanBaoUpdate)
		rktEventEngine.UnSubscribeExecute( EVENT_CION_YINLIANG , SOURCE_TYPE_COIN , 0 , self.callback_OnYinLiangUpdate)
		rktEventEngine.UnSubscribeExecute( EVENT_CION_YINBI , SOURCE_TYPE_COIN , 0 , self.callback_OnYinBiUpdate)
	end	
	UIControl.OnDestroy(self)
end

-- 注册事件
function CommonWindow:SubscribeEvent()
	
	if self.bSubscribeEvent then
		return
	end
	-- self.uid = GetHero():GetUID()
	rktEventEngine.SubscribeExecute( EVENT_CION_YUANBAO , SOURCE_TYPE_COIN ,  0, self.callback_OnYuanBaoUpdate)
	rktEventEngine.SubscribeExecute( EVENT_CION_YINLIANG , SOURCE_TYPE_COIN , 0 , self.callback_OnYinLiangUpdate)
	rktEventEngine.SubscribeExecute( EVENT_CION_YINBI , SOURCE_TYPE_COIN , 0 , self.callback_OnYinBiUpdate)
	self.bSubscribeEvent = true
end

-- 播放音效
function CommonWindow:PlayOpenSound()
	if self.m_windowName == UIManager.PackWindow.windName then 
	
		SoundHelp.PlayMusicByAudioPath(PACK_WINDOW_UI_OPEN_AUDIO)
	else
		SoundHelp.PlayMusicByAudioPath(OTHER_WINDOW_UI_OPEN_AUDIO)
	end
end

--停止播放音效
function CommonWindow:StopOpendSound()
end

function CommonWindow:OnEnable()
	if self.m_haveDoEnable == false then 
		self:RefreshMoneyWidget()
	--	self:PlayOpenSound()
		self.m_haveDoEnable = true
	end

end

function CommonWindow:OnDisable()
	self.m_haveDoEnable = false
end
------------------------------------------------------------
function CommonWindow:OnCloseButtonClick()
    if nil ~= self.closeCallback then
        self.closeCallback()
    end
end
------------------------------------------------------------
function CommonWindow:SetCloseButtonCallback( callback )
    self.closeCallback = callback
end

------------------------------------------------------------
function CommonWindow:ShowMoneyWidget( show )
    self.Controls.m_MoneyWidget.gameObject:SetActive(show)
	self:RefreshMoneyWidget()
end

function CommonWindow:HideBottom(state)
	self.Controls.m_bottom:SetParent(self.transform.parent,false)
	self.Controls.m_bottom:SetAsLastSibling()
	self.Controls.m_bottom.gameObject:SetActive(not state)
end


------------------------------------------------------------
function CommonWindow:RefreshMoneyWidget()
	if not self:isShow() then
		return
	end
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end
	local Diamond	= GameHelp:GetMoneyTextColor(pHero:GetActorYuanBao())
	local YinLiang	= GameHelp:GetMoneyTextColor(pHero:GetYinLiangNum())
	local YinBi		= GameHelp:GetMoneyTextColor(pHero:GetYinBiNum())
	self.Controls.m_DiamondText.text = Diamond
	self.Controls.m_GoldText.text = YinLiang
	self.Controls.m_BindGoldText.text = YinBi
end

------------------------------------------------------------
function CommonWindow:SetName(titleImagePath)
	UIFunction.SetImageSprite(self.Controls.m_nameImage,titleImagePath,function() CommonWindow:SetNameTitleNativeSize(self) end)
end

function CommonWindow:SetWindowName(windowName)
	self.m_windowName = windowName
end

function CommonWindow:SetBackGround(BGImagePath)
	if BGImagePath == nil then
		return
	end
	
	self.m_BgImage = self.Controls.m_BgImage:GetComponent(typeof(RawImage))
	UIFunction.SetRawImageSprite(self.m_BgImage, BGImagePath, function() CommonWindow:SetNameTitleNativeSize(self) end)
end

function CommonWindow:SetNameTitleNativeSize(self)
	if self.Controls.m_nameImage ~= nil then 
		self.Controls.m_nameImage:SetNativeSize()
	end
	self.Controls.m_nameImage.gameObject:SetActive(true)
	if self.m_BgImage ~= nil then
		 self.Controls.m_BgImage.sizeDelta = Vector2.New(1920,1080)
	end
end

--挂载
function CommonWindow:SetParentAndShow()
	local canvas = UIManager.FindMainCanvas()
	self.transform:SetParent( canvas.transform ,false)
	self.transform.gameObject:SetActive(false)
end

-- 执行钻石刷新
function CommonWindow:OnExecuteUpdateYunaBao(event, srctype, srcid, msg)
	if not self:isShow() then
		return
	end
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end
	
	self.Controls.m_DiamondText.text =GameHelp:GetMoneyTextColor(pHero:GetActorYuanBao()) 
	
end
-- 执行银两刷新
function CommonWindow:OnExecuteUpdateYinLiang(event, srctype, srcid, msg)
	
	if not self:isShow() then
		return
	end
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end
	self.Controls.m_GoldText.text = GameHelp:GetMoneyTextColor( pHero:GetYinLiangNum())
end
-- 执行银币刷新
function CommonWindow:OnExecuteUpdateYinBi(event, srctype, srcid, msg)
	
	if not self:isShow() then
		return
	end
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end

	self.Controls.m_BindGoldText.text =GameHelp:GetMoneyTextColor( pHero:GetYinBiNum())
end


--点击增加钻石按钮
function CommonWindow:OnClickAddDiamond()

	UIManager.ShopWindow:ShowShopWindow(gShopWindowPage.Deposit)
end

--点击增加银两
function CommonWindow:OnClickAddYinLiang()
	UIManager.ShopWindow:OpenShop(2415)
end

--点击增加银币
function CommonWindow:OnClickAddYinBi()
	UIManager.ShopWindow:OpenShop(2415)
end

return CommonWindow
