
UIManager = {}
local this = UIManager
------------------------------------------------------------------
-- 窗体层定义
this._BackgroundLayer = "BackgroundLayer"       --  背景层，在所有逻辑面板下方需要显示的控件或窗体
this._InputEventLayer = "InputEventLayer"       --  输入事件层，用来处理场景点击，摇杆等等输入事件
this._MainHUDLayer = "MainHUDLayer"             --  主界面层，
this._WindowLayer = "WindowLayer"               --  逻辑面板层，所有逻辑面板显示的层
this._SpecialTopLayer = "SpecialTopLayer"       --  顶层，在所有逻辑面板上方需要显示的控件或窗体
this._NGUILayer = "NGUILayer"                   --  NGUI窗体层
this._OperaLayer = "OperaLayer"					-- 剧情对话层
this._TestLayer = "TestLayer"					--测试层
------------------------------------------------------------------
this.WaittingDestroyList = {}                   -- 等待销毁的窗体列表
------------------------------------------------------------------
function UIManager.Initalize()
	
	rktEventEngine.SubscribeExecute(EVENT_FULL_SCREEN_GUI_COVERD_SCENE , 0 , 0 , UIManager.ShowFullScreenWindow)
end
------------------------------------------------------------------
-- 查找UI相机
function UIManager.FindUICamera()
    return GameObject.Find("/UGuiSystem"):GetComponent(typeof(Camera))
end
------------------------------------------------------------------
-- 查找主画布
function UIManager.FindMainCanvas()
	return GameObject.Find("/UGuiSystem/MainCanvas")
end
------------------------------------------------------------------
-- 显示界面层
function UIManager.ShowLayer( layer )
	local canvas = this.FindMainCanvas()
    canvas.transform:Find( layer ).gameObject:SetActive( true )
end

-- 隐藏界面层
function UIManager.HideLayer( layer )
	local canvas = this.FindMainCanvas()
    canvas.transform:Find( layer ).gameObject:SetActive( false )
end
------------------------------------------------------------------

--查找NGUI摄像机
function UIManager.FindNguiMainCamera()
	return UIManager.FindNguiMainCameraObj():GetComponent(typeof(Camera))
end
------------------------------------------------------------------

function UIManager.FindNguiLayer()
	return UIManager.FindNguiRoot().transform:Find("NGUICamera/NGUIPanelLayer")
end

--查找NGUIRoot
function UIManager.FindNguiRoot()  
    -- 这个对象不能设置Active为false,否则GameObject.Find无法找到
	return GameObject.Find("/NGUI Root")
end
---------------------------------------------------------------------

--查找NGUI摄像机
function UIManager.FindNguiMainCameraObj()
	return UIManager.FindNguiRoot().transform:Find("NGUICamera").gameObject
end
------------------------------------------------------------------

--把窗口放到NGUI面板下面
function UIManager.AttachToNguiLayer(window_obj)
	local root = UIManager.FindNguiLayer()
	if nil ~= root then 
		window_obj.transform:SetParent(root, false )
	end
	
end
----------------------------------------------------------------------

-- 将窗口对象挂载到某一层
-- layer 为窗体层 的名称
function UIManager.AttachToLayer( window_obj , layer )
    if layer == this._NGUILayer then
        this.AttachToNguiLayer( window_obj )
        return
    end
	local canvas = this.FindMainCanvas()

	window_obj.transform:SetParent( canvas.transform:Find( layer ) , false )
end
------------------------------------------------------------------
-- 销毁某一层的所有窗体
function UIManager.DestroyAllWindowsInLayer( layer )
	local canvas = this.FindMainCanvas()
	local window_layer = nil
	if layer == this._NGUILayer then 
		window_layer = UIManager.FindNguiLayer()
	else
		window_layer = canvas.transform:Find( layer )
	end

	
    if nil ~= window_layer then
        CoreUtility.DestroyChildren( window_layer.gameObject , false )
        return
    end

    if layer == this._NGUILayer then
    end
end

--获得某一层
function UIManager.FindUguiLayer(layer)
	local canvas = this.FindMainCanvas()
	local window_layer = canvas.transform:Find( layer )
	return window_layer
end

------------------------------------------------------------------
function UIManager.DestroyHideWindowsInLayer( layer )
	local canvas = this.FindMainCanvas()
	local window_layer = canvas.transform:Find( layer )
    if nil ~= window_layer then
        CoreUtility.DestroyChildren( window_layer.gameObject , true )
        return
    end

    if layer == this._NGUILayer then
    end
end
------------------------------------------------------------------
-- C# 中 UIWindowBehaviour 调用的
function UIManager.OnWindowRecycle( window )
    if nil == window then
        return
    end
    if nil ~= window.OnRecycle then
        window:OnRecycle()
    else
        uerror( "UIManager.OnWindowRecycle , the window not has 'OnRecycle' function." )
    end
end
------------------------------------------------------------------
-- C# 中 UIWindowBehaviour 调用的
function UIManager.OnWindowDestroy( window )
	if nil ~= window and nil ~= window.OnDestroy then
		window:OnDestroy()
	end
end
------------------------------------------------------------------
-- 创建窗体面板，创建成功后调用逻辑类的 OnAttach 接口。
-- 窗体默认挂载在 "WindowLayer" 中，如果有需要逻辑类自行调整顺序和层
function UIManager.CreateWindow( winName , layer )
    if nil == winName then
        return false
    end
	local assetPath = GuiAssetList.PanelPath[winName]
	if nil == assetPath then
		return false
	end
	assetPath = GuiAssetList.GuiRootPrefabPath .. assetPath
    local window = UIManager[winName]
    if window.loadingUnityGameObject then
        -- load window multi times
        return false
    end
    window.loadingUnityGameObject = true
	rkt.GResources.FetchGameObjectAsync( assetPath ,
		function( path , window_obj , userData )
            window.loadingUnityGameObject = nil
			if nil == window_obj then
				Debugger.LogError("instantiate window GameObject failed : " .. winName .. " , at path : " .. assetPath )
				return
			end
            local assetRef = rkt.AssetRefComponent.Get( window_obj , typeof(GameObject) )
            assetRef.canRecycle = false
			--window_obj.name = winName
			window:OnAttach( window_obj )
		end
	, winName , AssetLoadPriority.GuiNormal - 20 )
	return true
end
------------------------------------------------------------------
-- 显示、隐藏主界面
function UIManager.ShowHudWindow( bShow )
    if bShow then
        UIManager.ShowLayer( UIManager._InputEventLayer )
        UIManager.ShowLayer( UIManager._MainHUDLayer )
        UIManager.ShowLayer( UIManager._WindowLayer )
    else
        UIManager.HideLayer( UIManager._InputEventLayer )
        UIManager.HideLayer( UIManager._MainHUDLayer )
        UIManager.HideLayer( UIManager._WindowLayer )
    end
end


--显示隐藏所有的界面
function UIManager.ShowAllUILayer( bShow )
	UIManager.FindNguiLayer().gameObject:SetActive(bShow)
	if bShow then
        UIManager.ShowLayer( UIManager._InputEventLayer )
        UIManager.ShowLayer( UIManager._MainHUDLayer )
        UIManager.ShowLayer( UIManager._WindowLayer )
		UIManager.ShowLayer( UIManager._SpecialTopLayer )
		
    else
        UIManager.HideLayer( UIManager._InputEventLayer )
        UIManager.HideLayer( UIManager._MainHUDLayer )
        UIManager.HideLayer( UIManager._WindowLayer )
		UIManager.HideLayer( UIManager._SpecialTopLayer )
    end
end


--显示全屏界面一些不必要的界面隐藏
function UIManager.ShowFullScreenWindow(event, srctype, srcid, eventData)
	if  eventData == false then 
		UIManager.FightBloodWindow:Show()
		UIManager.NameTitleWindow:Show()
		UIManager.ShowLayer( UIManager._MainHUDLayer )
		UIManager.ShowLayer( UIManager._InputEventLayer )
	else
		UIManager.FightBloodWindow:Hide()
		UIManager.NameTitleWindow:Hide()
		UIManager.HideLayer( UIManager._MainHUDLayer )
		UIManager.HideLayer( UIManager._InputEventLayer )
	end
end
------------------------------------------------------------------
function UIManager.AddWaittingDestroyWindow( winName )
    local delTime = this.WaittingDestroyList[winName]
    if nil ~= delTime then
        return
    end

    if nil ~= GuiDontDestroyOnHideList[winName] then
        return
    end

    this.WaittingDestroyList[winName] = CoreUtility.Now + 1.0   -- 关闭后20秒没人用就销毁
    rktTimer.SetTimer( UIManager.CheckWaittingDestroyWindows , 1000 , -1 , "UIManager.CheckWaittingDestroyWindows" )
end
------------------------------------------------------------------
function UIManager.RemoveWaittingDestroyWindow( winName )
    this.WaittingDestroyList[winName] = nil
    if nil == _G.next( this.WaittingDestroyList ) then
        rktTimer.KillTimer( UIManager.CheckWaittingDestroyWindows )
    end
end
------------------------------------------------------------------
function UIManager.ClearWaittingDestroyWindow( winName )
    this.WaittingDestroyList = {}
    rktTimer.KillTimer( UIManager.CheckWaittingDestroyWindows )
end
------------------------------------------------------------------
function UIManager.CheckWaittingDestroyWindows()
    local now = CoreUtility.Now
    for win_name , end_time in pairs(this.WaittingDestroyList) do
        if now > end_time then
            this.WaittingDestroyList[win_name] = nil
            local window = UIManager[win_name]
            if nil ~= window and window:isLoaded() and not window:isShow() then
                window:Destroy()
            end
        end
    end
    if nil == _G.next(this.WaittingDestroyList) then
        rktTimer.KillTimer( UIManager.CheckWaittingDestroyWindows )
    end
end
------------------------------------------------------------------

------------------------------------------------------------------
--关闭指定层的窗口 add xwj
function UIManager.CloseWindowByLayer(layer)
	local layerTrs = UIManager.FindUguiLayer(layer)
	if layerTrs == nil then 
		uerror(tostring(layer) .. "is not exist")
		return
	end
	local childCount = layerTrs.childCount
	local childTrs=nil
	local childWindowBehavior = nil
	local childLuaObject = nil
	for i =1 , childCount do 
		childTrs = layerTrs:GetChild(i-1)
		if childTrs ~=nil then 
			childWindowBehavior = childTrs:GetComponent(typeof(UIWindowBehaviour))
			if nil ~= childWindowBehavior then
				childLuaObject = childWindowBehavior.LuaObject
				if childLuaObject ~= nil then 
					if childLuaObject.Hide ~= nil and childLuaObject.windowName ~= nil then 
						childLuaObject:Hide()
					end
				end
			end
		end
	end
end

------------------------------------------------------------------

local mt = {}
------------------------------------------------------------------
-- 窗口模块延迟加载实现
-- 加载完成后强制调用 Init 函数
mt.__index = function( t , key )
	--print( "find ui module : " .. key .. debug.traceback())
	if type(key) ~= "string" then
		error("UI module name must be a 'string'")
	end

	local modulePath = GuiWindowList[key]
	if nil == modulePath then
		error("can't find '" .. tostring(key) .. "' in GuiWindowList")
	end

	local window = require(modulePath)
	if type(window) ~= "table" then
		error("UI module must be return as a 'table'")
	end
	if nil == window.Init or type(window.Init) ~= "function" then
		error("can't find 'Init' function in UI module '" .. modulePath .. "'")
	end
	rawset( t , key , window )
	window:Init()
	return window
end

------------------------------------------------------------------
-- 防止写入
mt.__newindex = function( t , key , value )
	error("don't add field to UIManager")
end
------------------------------------------------------------------
setmetatable( UIManager , mt )

UIManager.Initalize()	