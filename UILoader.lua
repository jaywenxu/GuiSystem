--******************************************************************
-- 这个文件只能由客户端编辑
--/******************************************************************
---** 文件名:	UILoader.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	
--** 日  期:	2017-01-07
--** 版  本:	1.0
--** 描  述:	UI系统
--** 应  用:  	用于UI的加载、卸载、初始化逻辑
--******************************************************************


UILoader = {

}
local this = UILoader
--------------------------------------------------------------------------
-- 预加载登录状态的窗体
function UILoader.PreloadLoginWindows()
    local type_GameObject = typeof(GameObject)
	rkt.GResources.LoadAsync( GuiAssetList.GuiRootPrefabPath .. GuiAssetList.PanelPath.LoadingWindow , type_GameObject , nil , "" ,AssetLoadPriority.GuiNormal)
	rkt.GResources.LoadAsync( GuiAssetList.GuiRootPrefabPath .. GuiAssetList.PanelPath.SelectRoleWindow , type_GameObject , nil , "" ,AssetLoadPriority.GuiNormal)
--	rkt.GResources.LoadAsync( GuiAssetList.GuiRootPrefabPath .. GuiAssetList.PanelPath.ShadeImageWindow , type_GameObject , nil , "" ,AssetLoadPriority.GuiNormal)


end
--------------------------------------------------------------------------
-- 销毁登录状态的窗体
function UILoader.DestroyLoginWindows()
    UIManager.DestroyHideWindowsInLayer( UIManager._WindowLayer )

end
--------------------------------------------------------------------------
-- 预加载运行状态的窗体
function UILoader.PreloadRunningWindows()
   PreLoadMgr.PreLoadEnterGame()
end
--------------------------------------------------------------------------
-- 销毁运行状态的窗体
function UILoader.DestroyRunningWindows(wantGotoState)
    if wantGotoState == GameStateType.Login then  -- 从运行态切换到登录态，销毁所有窗口
        UIManager.DestroyAllWindowsInLayer( UIManager._WindowLayer )
        UIManager.DestroyAllWindowsInLayer( UIManager._MainHUDLayer )
        UIManager.DestroyAllWindowsInLayer( UIManager._InputEventLayer )
        UIManager.DestroyAllWindowsInLayer( UIManager._BackgroundLayer )
        UIManager.DestroyAllWindowsInLayer( UIManager._SpecialTopLayer )
        UIManager.DestroyAllWindowsInLayer( UIManager._OperaLayer )
        UIManager.DestroyAllWindowsInLayer( UIManager._NGUILayer )
    elseif wantGotoState == GameStateType.Running then
        UIManager.DestroyHideWindowsInLayer( UIManager._BackgroundLayer )
        UIManager.DestroyHideWindowsInLayer( UIManager._WindowLayer )
        UIManager.DestroyHideWindowsInLayer( UIManager._SpecialTopLayer )
        UIManager.DestroyAllWindowsInLayer( UIManager._OperaLayer )
    end
end
--------------------------------------------------------------------------
function UILoader.ShowRunningWindows()
--	UIManager.ShadeImageWindow:Show()
    UIManager.NameTitleWindow:Show()
	UIManager.MainLeftTopWindow:Show()
	UIManager.MainLeftCenterWindow:Show()
	UIManager.MainLeftBottomWindow:Show()
	UIManager.MainMidBottomWindow:Show()
    UIManager.MainRightTopWindow:Show()
    UIManager.InputOperateWindow:Show()
    UIManager.MainRightBottomWindow:Show(true)
    UIManager.MainRightBottomWindow:RefreshRedDot()
	UIManager.MiniMapWindow:Show()
	UIManager.SpeechNoticeWindow:Show()
	UIManager.FightBloodWindow:Show()
end
--------------------------------------------------------------------------
function UILoader.OnBeforeExitGameState(event , srctype , srcid , stateType )
    if stateType == GameStateType.Login then
		UILoader.DestroyLoginWindows()
    elseif stateType == GameStateType.Running then
		UILoader.DestroyRunningWindows( IGame.GameStateManager:GetWantGotoState() )
    end
end
--------------------------------------------------------------------------
local function printLoginStateLoadedLuaFiles()
    local paths = {}
    local modules = { "Client" , "Common" , "GuiSystem" , "Lua_CeHua" , "Render" }
    for k , v in pairs(package.loaded) do
        for i , p  in ipairs(modules) do
            if 1 == string.find( k , p ) then
                table.insert( paths , k )
                break
            end
        end
    end
    print( '登录阶段已加载的模块:\n' .. table.concat( paths , '\n' ) )
end
--------------------------------------------------------------------------
function UILoader.OnAfterEnterGameState(event , srctype , srcid , stateType )
    if stateType == GameStateType.Loading then
        local wantGotoState = IGame.GameStateManager:GetWantGotoState()
        if wantGotoState == GameStateType.Login then
            UILoader.PreloadLoginWindows()
        elseif wantGotoState == GameStateType.Running then
            --printLoginStateLoadedLuaFiles()
            UILoader.PreloadRunningWindows()
        end
    elseif stateType == GameStateType.Running then
        UILoader.ShowRunningWindows()
		IGame.SceneClient:StartEnterMapStoryID()

		
    end
end
--------------------------------------------------------------------------
function UILoader:Initalize()
	rktEventEngine.SubscribeExecute( EVENT_BEFORE_EXIT_GAMESTATE , 0 , 0 , UILoader.OnBeforeExitGameState )
    rktEventEngine.SubscribeExecute( EVENT_AFTER_ENTER_GAMESTATE , 0 , 0 , UILoader.OnAfterEnterGameState )
end

function UILoader:Release()
	rktEventEngine.UnSubscribeExecute( EVENT_BEFORE_EXIT_GAMESTATE , 0 , 0 , UILoader.OnBeforeExitGameState )
    rktEventEngine.UnSubscribeExecute( EVENT_AFTER_ENTER_GAMESTATE , 0 , 0 , UILoader.OnAfterEnterGameState )
end

UILoader:Initalize()
