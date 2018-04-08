
--******************************************************************
--** 文件名:	HuoDongWindowDef.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-12-11
--** 版  本:	1.0
--** 描  述:	活动界面变量定义
--** 应  用:  
--******************************************************************

HuoDongWinDef = {}

HuoDongWinDef.Item = 
{
	Activity_All = 1,    -- 全部活动
	Activity_Pre = 2,    -- 预告活动
	Activity_Active = 3, -- 活跃度活动
	Activity_Qiyu = 4,   -- 奇遇任务
}

HuoDongWinDef.WdtLuaFiles = 
{
	[HuoDongWinDef.Item.Activity_All] = "GuiSystem.WindowList.HuoDong.ActivityList.HuoDongListManager",
	[HuoDongWinDef.Item.Activity_Active] = "GuiSystem.WindowList.HuoDong.ActivityDegree.ActivityDegreeWdt",
	[HuoDongWinDef.Item.Activity_Qiyu] = "GuiSystem.WindowList.HuoDong.QiyuSystem.QiyuWdt",
}
