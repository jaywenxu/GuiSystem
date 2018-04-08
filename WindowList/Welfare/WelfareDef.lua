
--******************************************************************
--** 文件名:	WelfareDef.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-06-01
--** 版  本:	1.0
--** 描  述:	福利界面变量定义
--** 应  用:  
--******************************************************************

WelfareDef = {}

WelfareDef.ItemId =
{
	QTDL = 1,  --七天登录
	SJLB = 4,  --升级礼包
	JLZH = 6,  --奖励找回
	MRQD = 7,  --每日签到
}

WelfareDef.WdtLuaFiles = 
{
	[WelfareDef.ItemId.JLZH] = "GuiSystem.WindowList.Welfare.RewardBack.RewardBackWdt",
	[WelfareDef.ItemId.MRQD] = "GuiSystem.WindowList.Welfare.DailySignIn.DailySignInWdt",
	[WelfareDef.ItemId.SJLB] = "GuiSystem.WindowList.Welfare.UpgradePackage.UpgradePackageWdt",
    [WelfareDef.ItemId.QTDL] = "GuiSystem.WindowList.Welfare.WeekLogin.WeekLoginWdt",

}

RB_OPTION = {
	PERFECT = 1,   -- 完美找回
	NORMAL  = 2,   -- 普通找回
}

RB_CostIconPath = 
{
	YUANBAO  = GuiAssetList.GuiRootTexturePath.."Common_frame/Common_xh_baoshi.png",
	YINBI    = GuiAssetList.GuiRootTexturePath.."Common_frame/Common_xh_yinbi.png",
    YINLIANG = GuiAssetList.GuiRootTexturePath.."Common_frame/Common_xh_yuanbao.png",
}





