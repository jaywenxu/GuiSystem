
-- GuiSystem module init file

require( "GuiSystem.UIEventContainer" )
require( "GuiSystem.GuiAssetList" )
require( "GuiSystem.GuiEntityIdDefine" )
require( "GuiSystem.GuiWindowList" )
require( "GuiSystem.UIControl" )
require( "GuiSystem.UIWindow" )
require( "GuiSystem.UIManager" )
require( "GuiSystem.UIFunction" )
require( "GuiSystem.UILoader" )
require( "GuiSystem.UILogicAPI" )
require( "GuiSystem.RichTextHelp" )
require( "GuiSystem.UICharacterHelp" )
require("GuiSystem.PreLoadMgr" )
require("GuiSystem.PreLoadDefine")
require("GuiSystem.SysRedDotsMgr") -- 系统红点管理
require("GuiSystem.EffectHelp")


-- 编辑器模式下才加载灰盒测试
if UnityEngine.Application.isEditor then
	require("GrayBoxTest.GrayBoxTestLoader")
end
