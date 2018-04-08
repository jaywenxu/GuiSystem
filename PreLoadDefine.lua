--===========================================================
-- @author : 许文杰
-- @time   : 2017/7/6
-- @desc   : 预加载ID定义
--           ID值必需与配置表中的值保持一致
--===========================================================
--进入游戏前需要确保加载的资源
ENTER_GAME_AG0_SURE_PRELOADRESOURCE=
{
	
}
-------------------------------------------------------------
-- 常驻内存永不卸载,不含ENTER_GAME_AFTER_PRE_LOAD_WAIT_RELEASE中的定义
-- 只进行ReleaseWaitTime设置，不强制要求加载
PERSISTENT_ASSET_PATH_LIST = 
{
	GuiAssetList.BackgroundTextureShaderPath,
    GuiAssetList.BackgroundSpriteShaderPath,
	GuiAssetList.GuiRootPrefabPath .. GuiAssetList.PanelPath.LoadingWindow ,
    GuiAssetList.GuiRootPrefabPath .. GuiAssetList.PanelPath.ShadeImageWindow ,
}
-------------------------------------------------------------
rkt.GResources.SetReleaseWaitTime(PERSISTENT_ASSET_PATH_LIST,ReleaseWaitTime.RELEASE_WAIT_PERSISTENT)
-------------------------------------------------------------
--进入游戏后就会进行预加载
ENTER_GAME_AFTER_PRE_LOAD_WAIT_RELEASE=
{
	{
		Path = GuiAssetList.GuiRootPrefabPath .. GuiAssetList.PanelPath.InputOperateWindow,
		Priority = AssetLoadPriority.PreLoadGui,
		RelaseType = ReleaseWaitTime.RELEASE_WAIT_PERSISTENT,
		Type = typeof(GameObject)
	},

	{
		Path = GuiAssetList.GuiRootPrefabPath .. GuiAssetList.PanelPath.MainLeftCenterWindow,
		Priority = AssetLoadPriority.PreLoadGui,
		RelaseType = ReleaseWaitTime.RELEASE_WAIT_PERSISTENT,
		Type = typeof(GameObject)
	},

	{
		Path = GuiAssetList.GuiRootPrefabPath .. GuiAssetList.PanelPath.MainLeftTopWindow,
		Priority = AssetLoadPriority.PreLoadGui,
		RelaseType = ReleaseWaitTime.RELEASE_WAIT_PERSISTENT,
		Type = typeof(GameObject)
	},

	{
		Path = GuiAssetList.GuiRootPrefabPath .. GuiAssetList.PanelPath.MainLeftCenterWindow,
		Priority = AssetLoadPriority.PreLoadGui,
		RelaseType = ReleaseWaitTime.RELEASE_WAIT_PERSISTENT,
		Type = typeof(GameObject)
	},

	{
		Path = GuiAssetList.GuiRootPrefabPath .. GuiAssetList.PanelPath.MainLeftBottomWindow,
		Priority = AssetLoadPriority.PreLoadGui,
		RelaseType = ReleaseWaitTime.RELEASE_WAIT_PERSISTENT,
		Type = typeof(GameObject)
	},

	{
		Path = GuiAssetList.GuiRootPrefabPath .. GuiAssetList.PanelPath.MainRightTopWindow , 
		Priority = AssetLoadPriority.PreLoadGui,
		RelaseType = ReleaseWaitTime.RELEASE_WAIT_PERSISTENT,
		Type = typeof(GameObject)
	},

	{
		Path = GuiAssetList.GuiRootPrefabPath .. GuiAssetList.PanelPath.MainMidBottomWindow , 
		Priority = AssetLoadPriority.PreLoadGui,
		RelaseType = ReleaseWaitTime.RELEASE_WAIT_PERSISTENT,
		Type = typeof(GameObject)
	},

	{
		Path = GuiAssetList.GuiRootPrefabPath .. GuiAssetList.PanelPath.MainRightBottomWindow , 
		Priority = AssetLoadPriority.PreLoadGui,
		RelaseType = ReleaseWaitTime.RELEASE_WAIT_PERSISTENT,
		Type = typeof(GameObject)
	},

	{
		Path = GuiAssetList.GuiRootPrefabPath .. GuiAssetList.PanelPath.NameTitleWindow , 
		Priority = AssetLoadPriority.PreLoadGui,
		RelaseType = ReleaseWaitTime.RELEASE_WAIT_PERSISTENT,
		Type = typeof(GameObject)
	},

	{
		Path = GuiAssetList.GuiRootPrefabPath .. GuiAssetList.PanelPath.MiniMapWindow , 
		Priority = AssetLoadPriority.PreLoadGui,
		RelaseType = ReleaseWaitTime.RELEASE_WAIT_PERSISTENT,
		Type = typeof(GameObject)
	},

	{
		Path = GuiAssetList.GuiRootPrefabPath .. GuiAssetList.PanelPath.SpeechNoticeWindow, 
		Priority = AssetLoadPriority.PreLoadGui,
		RelaseType = ReleaseWaitTime.RELEASE_WAIT_DEFAULT,
		Type = typeof(GameObject)
	},

	{
		Path = GuiAssetList.BackgroundTextureShaderPath,
		Priority = AssetLoadPriority.PreLoadGui,
		RelaseType = ReleaseWaitTime.RELEASE_WAIT_PERSISTENT,
		Type =  typeof(UnityEngine.Shader),
	},

	{
		Path= GuiAssetList.GuiRootPrefabPath .. GuiAssetList.PanelPath.PackWindow,
		Priority = AssetLoadPriority.PreLoadGui,
		RelaseType = ReleaseWaitTime.RELEASE_WAIT_PERSISTENT,
		Type = typeof(GameObject)
	},

	{
		Path = GuiAssetList.CommonWindow,
		Priority = AssetLoadPriority.PreLoadGui-10,
		RelaseType = ReleaseWaitTime.RELEASE_WAIT_PERSISTENT,
		Type = typeof(GameObject)
	},

	{
		Path = GuiAssetList.PackageItemCell,
		Priority = AssetLoadPriority.PreLoadGui,
		RelaseType = ReleaseWaitTime.RELEASE_WAIT_PERSISTENT,
		Type = typeof(GameObject)
	}

}

--打开相应界面需要预加载资源的界面ID
OPENUI_AFTER_PRELOADRESOURCE = 
{
	UI_FORGE_PATH =
	{
		"Assets/IGSoft_Resources/Projects/Prefabs/UI_effect/ef_QHCG.prefab",
	} --打造
	
}