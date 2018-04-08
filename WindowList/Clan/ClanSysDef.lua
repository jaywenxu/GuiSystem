-- 帮派前端系统宏定义
-- @Author: XieXiaoMei
-- @Date:   2017-04-17 11:20:00
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-25 17:33:51

ClanSysDef = {}

ClanSysDef.FormalState = emClanState_Formal 		-- 正式状态，正式帮派数据
ClanSysDef.InformalState = emClanState_Informal 	-- 非正式状态，非正式帮派数据

ClanSysDef.ClanBaseReq = emClanRequestClanBaseData 	-- 帮派基础数据请求


-- 路径
local ClanRootPath = "GuiSystem.WindowList.Clan."
ClanSysDef.ClanNonePath = ClanRootPath .. "ClanNone."
ClanSysDef.ClanOwnPath = ClanRootPath .. "ClanOwn."
ClanSysDef.ClanBuildingPath = ClanRootPath .. "ClanBuilding."

-- 帮派标题图片路径
ClanSysDef.TitleImgFilePath = AssetPath.TextureGUIPath.."Clan/Clan_banghui.png"

-- 帮会未拥有界面tabs
ClanSysDef.ClanNoneTabs = 
{
	Join     = 1,
	Create   = 2,
	Response = 3,
}

-- 帮会拥有界面tabs
ClanSysDef.ClanOwnTabs = 
{
	Info     = 1,
	Members  = 2,
	Build    = 3,
	Activity = 4,
}

-- 帮会职位对应服务器枚举
local clanPositions =
{
	Host    = emClanIdentity_Shaikh,
	SubHost = emClanIdentity_Underboss,
	Elder   = emClanIdentity_Elder,
	Peterxs = emClanIdentity_DepartmentManager,
	Elite   = emClanIdentity_Elite,
	Mass    = emClanIdentity_Member,
	Captain = emClanIdentity_Captain,
}
ClanSysDef.ClanPositions = clanPositions

-- 帮会职位中文
ClanSysDef.ClanPositionStrs = 
{	
	[clanPositions.Mass]    = "帮众",
	[clanPositions.Elite]   = "精英",
	[clanPositions.Peterxs] = "堂主",
	[clanPositions.Elder]   = "长老",
	[clanPositions.SubHost] = "副帮主",
	[clanPositions.Host]    = "帮主",
	[clanPositions.Captain]    = "帮会统战",
}


-- 职位当前数量
ClanSysDef.PosCurCntPropIDs = 
{	
	[clanPositions.Captain]    = emClanProp_CaptainNum,
	[clanPositions.Mass]    = emClanProp_CurMassesNum,
	[clanPositions.Elite]   = emClanProp_CurEliteNum,
	[clanPositions.Peterxs] = emClanProp_CurDMNum,
	[clanPositions.Elder]   = emClanProp_CurElderNum,
	[clanPositions.SubHost] = emClanProp_CurUnderBossNum,
	-- [clanPositions.Host]    = -1,
}


-- 帮会成员排序标志
ClanSysDef.MemberSortTypes = 
{
	Title      = emClamMemberSort_Title ,						-- 头衔排序
	Name       = emClanMemberSort_Name ,						-- 名字排序
	Position   = emClanMemberSort_Identity,						-- 职位排序
	Level      = emClanMemberSort_Level,						-- 等级排序
	Job        = emClanMemberSort_Vocation,						-- 职业排序
	Contribute = emClanMemberSort_Contribute,					-- 贡献排序
	Online     = emClanMemberSort_Online,						-- 在线排序
	Force      = emClamMemberSort_Force,                        -- 战力排序
}

ClanSysDef.ClanListRefreCnt = 20 		--列表每次刷新数量
ClanSysDef.SettingsDefaultLvl = 20 		--设置默认为20级
ClanSysDef.NoVocationLimitCode = 127 	--不限制职业

ClanSysDef.DescSortMode = "Desc" 	--descend降序排序
ClanSysDef.AsceSortMode = "Asc" 	--ascending升序排序

ClanSysDef.LigeanceTexturePath = GuiAssetList.GuiRootTexturePath .. "Ligeance/"
ClanSysDef.LigeanceFlagPngs = --领地旗帜图片资源表
{
	[1] = "Ligeance_qi_jin.png",
	[2] = "Ligeance_qi_lv_1.png",
	[3] = "Ligeance_qi_lv_2.png",
	[4] = "Ligeance_qi_zi.png",
	[5] = "Ligeance_qi_shenlan.png",
	[6] = "Ligeance_qi_hong.png",
	[7] = "Ligeance_qi_lan.png",	
	[8] = "Ligeance_qi_hei.png",	
}

-- 根据帮会等级获取最大成员数量
function ClanSysDef.GetMaxMemberCnt(level)
	local levelConfig = IGame.ClanClient:GetLevelInfo(level)
	if levelConfig ~= nil then
		return levelConfig.nMaxMemberCount
	else
		return 300
	end
end