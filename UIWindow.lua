
------------------------------------------------------------
--  UI窗口逻辑面板基类
--  提供显示隐藏的基本函数
--  与 UIManager 加载配合，在 OnAttach 函数中与 C# 中 UIWindowBehaviour 组件进行挂载
--  Unity3D 对象异步加载，场景切换时可能被卸载，所以暴露给外部的接口需要做 Unity3D 对象不存在的判断，并进行逻辑上的异步处理
------------------------------------------------------------
UIWindow = UIEventContainer:new
{
	Controls = {}     ,       -- 所有的控件都放在这里
	transform = nil   ,       -- OnAttach 函数设置挂载的GameObject.transform
	windowName = nil  ,       -- 模块名称
    unityBehaviour = nil ,    -- UIWindowBehaviour
    m_showLoadedBringTop = nil ,   -- 显示函数传入加载成功后需要提到上层显示标记
    m_fullScreen = false ,    -- 是否全屏界面,默认为false,只能通过SetFullScreen在OnAttach里面设置
}
------------------------------------------------------------
-- 模型加载时调用的，只会加载一次
function UIWindow:Init()
end
------------------------------------------------------------
-- Unity3D 对象加载成功后，进行挂载的函数
-- UIWindowBehaviour 中引用的对象这里被自动关联
-- layer , 窗体所在的层,逻辑窗口可自行设置,不传默认为 UIManager._WindowLayer
function UIWindow:OnAttach( obj , layer )
	if nil == obj then
		return
	end
	UIManager.AttachToLayer( obj , layer or UIManager._WindowLayer )
	self.transform = obj.gameObject.transform
    if self.m_showLoadedBringTop then
        self.transform:SetAsLastSibling()
    end
    self.m_showLoadedBringTop = nil
	self.unityBehaviour = UIWindowBehaviour.Get(obj,self)
    self.unityBehaviour:FillLuaControlList(
		function( name , control )
			self.Controls[name] = control
		end)
	self:SubscribeWinExecute()
end
-----------------------------------------------------------
-- 设置窗体为全屏界面，如果窗体正处于Showing状态则立即触发全屏遮蔽
function UIWindow:SetFullScreen()
    self.m_fullScreen = true
    if nil == self.m_callback_GuiCoverScene then
        self.m_callback_GuiCoverScene = function() rktMainCamera.GuiCoverScene( self.windowName ) end
    end
    if nil == self.m_callback_GuiUnCoverScene then
        self.m_callback_GuiUnCoverScene = function() rktMainCamera.GuiUnCoverScene( self.windowName ) end
    end
    self.unityBehaviour.onEnable:RemoveListener( self.m_callback_GuiCoverScene )
    self.unityBehaviour.onEnable:AddListener( self.m_callback_GuiCoverScene )
    self.unityBehaviour.onDisable:RemoveListener( self.m_callback_GuiUnCoverScene )
    self.unityBehaviour.onDisable:AddListener( self.m_callback_GuiUnCoverScene )
    if self:isShow() then
        rktMainCamera.GuiCoverScene( self.windowName )
    end
end
-----------------------------------------------------------
--若需要自动加CommonWindow就调用这段代码
function UIWindow:AddCommonWindowToThisWindow(showMoneyWidget,titleNamePath, closeCallBack,BgImagePath,loadCallBack,hideState)
	local Common_Window = nil
	if self.windowName == UIManager.PackWindow.windowName then 
		Common_Window = GuiAssetList.CommonWindowPack 
	else
		Common_Window = GuiAssetList.CommonWindow
	end
	rkt.GResources.FetchGameObjectAsync( Common_Window ,
		function ( path , obj , ud )
			if nil ==obj then   -- 判断U3D对象是否已经被销毁
				return
			end
			local item = UIManager.CommonWindow:new({})
			self.CommonWindowWidget = item
			item:SetWindowName(self.windowName)
			item:Attach(obj)
			item.transform:SetParent(self.transform,false)
			item.transform:SetAsFirstSibling()
			item.transform.gameObject:SetActive(true)
			item:ShowMoneyWidget(showMoneyWidget)
			item:SetName(titleNamePath)
			item:SetBackGround(BgImagePath)
			item:HideBottom(hideState or false)
            if loadCallBack ~= nil then 
               loadCallBack() -- 设置为全屏界面
            end
            
			item.closeCallback = closeCallBack
		end,"", AssetLoadPriority.GuiNormal -10 )
end
--------------------------------------------------------
-- 判断Unity3D对象是否被加载
function UIWindow:isLoaded()
	return not tolua.isnull( self.transform )
end
------------------------------------------------------------
-- 判断当前窗体是否显示
function UIWindow:isShow()
	if tolua.isnull( self.transform ) then
		return false
	end
	return self.transform.gameObject.activeInHierarchy
end
------------------------------------------------------------
-- 显示窗体 >>> 这个接口只能覆盖,不能重载 <<<
-- bringTop 将窗口显示在最上层
function UIWindow:Show( bringTop )
    UIManager.RemoveWaittingDestroyWindow( self.windowName )
	if self:isShow() then
        if bringTop then
            self.transform:SetAsLastSibling()
        end
        self.m_showLoadedBringTop = nil
		return
	end
    self.m_showLoadedBringTop = bringTop
	self:_showWindow()
end
------------------------------------------------------------
-- 隐藏窗体
function UIWindow:Hide( destroy )
    if nil == self.transform then
        return
    end
	self:UnSubscribeWinExecute()
	self.transform.gameObject:SetActive(false)
	if destroy then
		self:Destroy()
    else
        UIManager.AddWaittingDestroyWindow( self.windowName )
	end
end
------------------------------------------------------------
-- 主动销毁
function UIWindow:Destroy()
	-- 注销事件
	self:UnSubscribeWinExecute()
    if self.m_fullScreen then
        rktMainCamera.GuiUnCoverScene( self.windowName )
    end
	if nil ~= self.transform then
		UnityEngine.Object.Destroy(self.transform.gameObject)
	else
		if self.OnDestroy then
			self:OnDestroy()
		end
		
		self.Controls = {}
		self.transform = nil
	    self.unityBehaviour = nil
	end
end
------------------------------------------------------------
-- 被动销毁
function UIWindow:OnDestroy()
    UIManager.RemoveWaittingDestroyWindow( self.windowName )
    if self.m_fullScreen then
        rktMainCamera.GuiUnCoverScene( self.windowName )
    end
	-- 注销事件
	if self.UnSubscribeWinExecute then
		self:UnSubscribeWinExecute()
	end
    self:ClearAllListeners()
	self.Controls = {}
	self.transform = nil
    self.unityBehaviour = nil
end
------------------------------------------------------------
--  简单的实现，窗体的异步加载
--  子类需要自己实现逻辑需要的效果
function UIWindow:_showWindow()  -- private
	if not self:isLoaded() then
		UIManager.CreateWindow( self.windowName )
		return
	end
	self.transform.gameObject:SetActive(true)
    if self.m_showLoadedBringTop then
        self.transform:SetAsLastSibling()
    end
    self.m_showLoadedBringTop = nil
	self:SubscribeWinExecute()
end
------------------------------------------------------------
-- 把窗体拉到最上层
function UIWindow:BringTop()
    if not self:isShow() then
        return
    end
    self.transform:SetAsLastSibling()
end

------------------------------------------------------------
-- 注册窗口响应事件
function UIWindow:SubscribeWinExecute()
	
end

------------------------------------------------------------
-- 注销窗口响应事件
function UIWindow:UnSubscribeWinExecute()
	
end
------------------------------------------------------------