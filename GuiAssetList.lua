
GuiAssetList = {}
local this = GuiAssetList


-- GUI预设根目录
this.GuiRootPrefabPath = "Assets/AssetFolder/GUIAsset/Prefabs/"
-- GUI贴图根目录
this.GuiRootTexturePath = "Assets/AssetFolder/GUIAsset/Textures/"
-- GUI材质根目录
this.GuiRootMaterialPath = "Assets/AssetFolder/GUIAsset/Materials/"
--音效根目录
this.GuiRootAudioPath = "Assets/AssetFolder/Audios/GuiAudio/" 

-- GUI模块 = GUI预设相对路径
this.PanelPath = 
{
    LoginWindow 					= "Windows/Login_Window.prefab",
	RegisterWindow 					= "Windows/Register_Window.prefab",
    PackWindow						= "Windows/Pack_Window.prefab",
	SelectRoleWindow				= "Windows/SelectRole_Window.prefab",
	CreateRoleWindow				= "Windows/CreateRole_Window.prefab",
	MakeFaceWindow					= "Windows/MakeFace_Window.prefab",
	MainLeftTopWindow				= "Windows/MainLeftTop_Window.prefab",					-- 主界面左边上部窗口
	MainLeftCenterWindow			= "Windows/MainLeftCenter_Window.prefab",				-- 主界面左边中间窗口
	MainLeftBottomWindow			= "Windows/MainLeftBottom_Window.prefab",				-- 主界面左边下部窗口
	MainMidBottomWindow				= "Windows/MainMidBottom_Window.prefab",				-- 主界面中间下部窗口
	MainRightTopWindow				= "Windows/MainRightTop_Window.prefab",					-- 主界面右边上部窗口
	MainRightBottomWindow			= "Windows/MainRightBottom_Window.prefab",				-- 主界面右边下部窗口
    NameTitleWindow 				= "Windows/NameTitleWindow.prefab" ,
	MaterialComposeWindow       	= "Windows/MaterialCompose_Window.prefab",				-- 材料合成窗口
	WareRenameWindow            	= "Windows/WareRename_Window.prefab",					-- 仓库重命名窗口
	NumericKeypadWindow         	= "Windows/NumericKeypad_Window.prefab",				-- 数字小键盘
	RoleViewWindow              	= "Windows/RoleView_Window.prefab",						-- 查看角色窗口
	HeadTitleWindow             	= "Windows/HeadTitle_Window.prefab",					-- 头衔系统窗口
	WildHangupWindow             	= "Windows/WildHangup_Window.prefab",					-- 野外杀怪窗口
	TipsWindow                  	= "Windows/Tips_Window.prefab",
	EquipTooltipsWindow 			= "Windows/EquipTooltips_Window.prefab",				-- 装备tips窗口
	GoodsTooltipsWindow 			= "Windows/GoodsTooltips_Window.prefab",				-- 物品tips窗口
	PlayerWindow 					= "Windows/Player_Window.prefab",
	DidaWindow						= "Windows/Dida_Window.prefab",							-- 消息滴答窗口
	ChatSystemTipsWindow			= "Windows/ChatSystemTips_Window.prefab",				-- 系统消息窗口
	TipsActorUnderWindow			= "Windows/TipsActorUnder_Window.prefab",				-- 系统消息窗口_下
	TipsActorAboveWindow			= "Windows/TipsActorAbove_Window.prefab",				-- 系统消息窗口_上
	ChatWindow						= "Windows/Chat_Window.prefab",							-- 频道聊天窗口
	SpeechNoticeWindow				= "Windows/SpeechNotice_Window.prefab",					-- 语音状态显示窗口
	NotificationBottomWindow		= "Windows/NotificationBottom_Window.prefab",			-- 公告信息窗口
	NotificationBattleWindow		= "Windows/NotificationBattle_Window.prefab",			-- 战斗信息窗口
	ChatSettingWindow				= "Windows/ChatSetting_Window.prefab",					-- 聊天设置窗口
	ChatHistoryWindow				= "Windows/ChatHistory_Window.prefab",					-- 聊天历史窗口
	TiShiBattleUpWindow				= "Windows/TiShiBattleUp_Window.prefab",				-- 战力值增加窗口
	FightBloodWindow 				= "Windows/FightBlood_Window.prefab",					-- 飘血窗口
	DialogModelWindow 				= "Windows/DialogModel_Window.prefab",					-- 任务情景对白dialog ，需要显示模型
	DialogScenarioWindow 			= "Windows/DialogScenario_Window.prefab",				-- 剧情对话弹窗
	SceneMapWindow 					= "Windows/SceneMap_Window.prefab",         			-- 场景地图窗口
    WorldMapWindow                  = "Windows/WorldMap_Window.prefab",         			-- 世界地图窗口
    InputOperateWindow 				= "Windows/InputOperate_Window.prefab",					-- 输入事件层窗口
	NarratorWindow	 				= "Windows/Narrator_Window.prefab",						-- 旁白窗口
	ItemUseWindow		 			= "Windows/ItemUse_Window.prefab",						-- 使用物品窗口
	SpecialItemUseWindow		 	= "Windows/Special_ItemUse_Window.prefab",				-- 特殊使用物品窗口(比如寻宝图)
	MainTaskWindow		 			= "Windows/MainTask_Window.prefab",						-- 任务窗口
	HuoDongWindow					= "Windows/HuoDongWindow.prefab",						-- 活动主窗口
	CommonGuideWindow				= "Windows/CommonGuideWindow.prefab",					-- 活动详细信息窗口
	HuoDongPushWindow				= "Windows/HuoDongPushWindow.prefab",					-- 活动推送设置窗口
	HuoDongCalenderWindow			= "Windows/HuoDongCalenderWindow.prefab",				-- 活动日历窗口
	ShopWindow						= "Windows/ShopWindow.prefab",							-- 商城主窗口
	PetWindow						= "Windows/PetWindow.prefab",							-- 灵兽窗口
	PetLookWindow					= "Windows/PetLookWindow.prefab",						-- 查看灵兽窗口
	PetBreedWindow					= "Windows/PetBreedWindow.prefab",						-- 灵兽窗口
	SpeakerWindow					= "Windows/Speaker_Window.prefab",						-- 喇叭窗口
	SpeakerSendWindow				= "Windows/SpeakerSend_Window.prefab",					-- 喇叭发送窗口
	MiniMapWindow					= "Windows/Minimap_Window.prefab",						-- 小地图窗口
	LoadingWindow					= "Windows/LoadingWindow.prefab",						-- Loading窗口
	ProgressBarWindow				= "Windows/ProgressBar_Window.prefab",					-- 进度条窗口
	ForgeWindow						= "Windows/Forge_Window.prefab",						-- 打造窗口
	TeamWindow						= "Windows/MainTeam_Window.prefab",						-- 组队主窗口
	TeamGoalsWindow					= "Windows/TeamGoals_Window.prefab",					-- 组队目标窗口
	ContextMenuWindow				= "Windows/ContextMenu_Window.prefab",					-- 他人角色菜单窗口
	DragonBallWindow				= "Windows/DragonBall_Window.prefab",					-- 七龙珠窗口
	TeamInviteFriendsWindow	    	= "Windows/InviteFriends_Window.prefab",				-- 组队系统邀请玩家窗口
	TeamTalkWindow					= "Windows/TeamTalk_Window.prefab",						-- 组队系统中喊话窗口
	TeamTalkHistoryWindow 			= "Windows/TeamTalkHistory_Window.prefab",				-- 最对系统喊话历史记录窗口
	RichTextWindow					= "Windows/RichText_Window.prefab",						-- 富文本窗口
	TeamApplyListWindow				= "Windows/TeamApplyList_Window.prefab",				-- 组队申请列表窗口
	TeamShowPanelWindow				= "Windows/TeamShowPanel_Window.prefab",				-- 组队显示窗口
	ReliveWindow					= "Windows/Relive_Window.prefab",						-- 复活窗口
	TeamShowPanelLeaderClickWindow	= "Windows/TeamShowPanelLeaderClick_Window.prefab",		-- 主界面点击队长头像出来的点击菜单窗口 
	TeamShowPanelMemberClickWindow	= "Windows/TeamShowPanelMemberClick_Window.prefab",  	-- 主界面点击队员头像出来的点击菜单窗口 
	ClanNoneWindow					= "Windows/ClanNoneWindow.prefab",						-- 帮会(未拥有)窗口
	ClanOwnWindow					= "Windows/ClanOwnWindow.prefab",						-- 帮会(已拥有)窗口
	ClanCourseWindow				= "Clan/ClanOwn/ClanCourseWindow.prefab",				-- 帮会历程窗口
	ClanApplyListWindow				= "Clan/ClanOwn/ApplyListWindow.prefab",				-- 帮会申请列表窗口
	ClanWelcomeNewWindow			= "Clan/ClanOwn/WelcomeNewWindow.prefab",				-- 帮会欢迎新人窗口
	ClanSettingsWindow				= "Clan/ClanOwn/ClanSettingsWindow.prefab",				-- 帮会设置窗口
	ClanPositionChgWindow			= "Clan/ClanOwn/PositionChangeWindow.prefab",			-- 帮会职位变更窗口
	ClanNameMdfWindow				= "Clan/ClanOwn/ClanNameModifyWindow.prefab",			-- 帮派名称修改窗口
	ClanDeclareMdfWindow			= "Clan/ClanOwn/DeclareModifyWindow.prefab",			-- 帮派声明修改窗口
	ClanMassMsgWindow				= "Clan/ClanOwn/MassMsgWindow.prefab",					-- 帮会群发消息窗口
	WelcomePopWindow				= "Clan/ClanOwn/WelcomePopWindow.prefab",				-- 帮会群发消息窗口
	CommonNoticeWindow				= "Windows/CommonNotice_Window.prefab",  				-- 通用提示信息窗口
	ShadeImageWindow				= "Windows/ShadeImageWindow.prefab",					-- 主界面的背景遮罩
	ChipExchangeWindow				= "Windows/ChipExchange_Window.prefab",					-- 通用商城
	ConfirmPopWindow				= "Windows/ConfirmPopWindow.prefab",					-- 确认弹出框
	InputPopWindow					= "Windows/InputPopWindow.prefab",						-- 输入确认弹出框
	BossHPWindow					= "Windows/BossHP_Window.prefab",						-- Boss血条
	TaskTargetDirIconWindow			= "Windows/TaskTargetDirIconWindow.prefab",				-- 任务目标朝向窗口
	SkillReliveWindow				= "Windows/SkillReliveWindow.prefab",					-- 技能复活窗口
	FriendEmailWindow				= "Windows/FriendEmailWindow.prefab",					-- 好友邮件窗口
	TeamInvitedRespondWindow		= "Windows/InvitedRespond_Window.prefab",				-- 组队邀请相应窗口
	CommonRespondWindow             = "Windows/InvitedRespond_Window.prefab",
	CommonPrizeWindow				= "Windows/CommonPrize_Window.prefab",					-- 任务奖励界面窗口
	SettingsWindow					= "Windows/SettingsWindow.prefab",						-- 设置界面
	BuffTooltipsWindow				= "Windows/BuffTooltips_Window.prefab",					-- Buff信息窗口
	EctypeTimerWindow				= "Ectype/EctypeTimer_Window.prefab",					-- 副本时间倒计时窗口
	WelfareWindow                   = "Windows/WelfareWindow.prefab",						-- 福利窗口
	EctypeTreeWindow				= "Ectype/EctypeTree_Window.prefab",					-- 九天连宫副本生长树窗口
	PlayerSkillWindow				= "Windows/PlayerSkillWindow.prefab",					-- 玩家技能窗口
	LiuPaiSkillTipWindow			= "Windows/LiuPaiSkillTipWindow.prefab",				-- 流派技能提示弹窗
	LoungeWindow					= "Windows/LoungeWindow.prefab",						-- 休息室窗口
	JingJieDetailWindow				= "Windows/JingJieDetailWindow.prefab",					-- 境界详情窗口
	WuXueDetailWindow				= "Windows/WuXueDetailWindow.prefab",					-- 武学详情窗口
	FreightTaskWindow				= "Windows/FreightTask_Window.prefab",					-- 货运任务窗口
	ExchangeWindow					= "Windows/ExchangeWindow.prefab",						-- 贸易窗口
	HGLYWindow						= "Windows/HGLYWindow.prefab",							-- 贸易窗口
	HGLYRankWindow					= "HuoGongLiangYing/HGLYRankWindow.prefab",				-- 贸易窗口
	SubTitleWindow  				= "Windows/SubTitleWindow.prefab",						-- 剧情旁白窗口
	GemConvertWindow				= "Windows/GemConvert_Window.prefab",					-- 宝石转换窗口
	ExchangeSearchWindow			= "Windows/ExchangeSearchWindow.prefab",				-- 交易搜索窗口
	MenPaiIconWindow				= "Windows/MainMenPaiIcon_Window.prefab",				-- 门派入侵ICON窗口
	MenPaiWindow					= "HuoDongMenPai/MenPaiWindow.prefab",					-- 门派入侵窗口
	ExchangeBuyConfirmWindow		= "Windows/ExchangeBuyConfirmWindow.prefab",			-- 摆摊购买确认窗口
	PeachFeastWindow                = "Windows/PeachFeastWindow.prefab",        			-- 蟠桃盛宴窗口
	PeachFeastRankWindow            = "Windows/PeachFeastRankWindow.prefab",    			-- 蟠桃盛宴排行榜窗口
	ExchangePutGoodsWindow			= "Windows/ExchangePutGoodsWindow.prefab",				-- 交易物上架窗口
	ExchangeHistoryWindow			= "Windows/ExchangeHistoryWindow.prefab",				-- 交易历史查看窗口
    AuctionRecordWindow              = "Windows/AuctionRecordWindow.prefab",                 -- 拍卖日志记录窗口
	FuMoTouPlayWindow				= "Windows/FuMoTouPlayWindow.prefab",					-- 伏魔骰投掷界面
	FuMoTouWindow 					= "Windows/FuMoTouWindow.prefab",						-- 伏魔骰界面
	FuMoTouResultWindow				= "Windows/FuMoTouResultWindow.prefab",					-- 伏魔骰结果界面
	LigeFlagEditWindow				= "Clan/ClanLigeance/LigeFlagEditWindow.prefab",		-- 帮会领地旗帜编辑窗口
	LigeLogbuchWindow				= "Clan/ClanLigeance/LigeLogbuchWindow.prefab",			-- 帮会领地战入口窗口
	DeclareWarInputWindow			= "Clan/ClanLigeance/DeclareWarInputWindow.prefab",		-- 帮会领地宣战输入窗口
	LigeanceEntryWindow				= "Clan/ClanLigeance/LigeanceEntryWindow.prefab",		-- 帮会领地战战斗入口窗口
	ServerSelectWindow				= "Windows/ServerSelectWindow.prefab",					-- 选服窗口
	ResAdjustWindow					= "Windows/ResAdjustWindow.prefab",						-- 等级封印窗口
	LigeanceFightWindow				= "Clan/ClanLigeance/LigeanceFightWindow.prefab",		-- 领地战战斗窗口
	LigeBalanceWindow				= "Clan/ClanLigeance/LigeBalanceWindow.prefab",			-- 领地战战斗窗口
	ClanTransWindow                 = "Windows/ClanTransWindow.prefab",						-- 帮会押运补充物资接口
	ClanGoodsAddWindow              = "Windows/ClanGoodsAddWindow.prefab",					-- 帮会押运补充物资接口
	BusinessWindow					= "Windows/BusinessWindow.prefab",						-- 跑商窗口
	GaoChangFightWindow				= "Windows/GaoChangFightWindow.prefab",					-- 高昌密道战斗窗口
	RedPacketWindow					= "Windows/RedPacket_Window.prefab",					-- 红包窗口
	RedPacketDetailWindow			= "Windows/RedPacketDetailWindow.prefab",				-- 红包详细信息窗口
	SceneRoleInfoWindow             = "Windows/SceneRoleInfoWindow.prefab",	    			-- 查看场景人物信息窗口
	ClanShrineWindow				= "Clan/ClanBuilding/ClanShrineWindow.prefab",			-- 帮会主殿窗口
	ClanAcademyWindow				= "Clan/ClanBuilding/ClanAcademyWindow.prefab",			-- 帮会研究院窗口
	ClanWelfareWindow				= "Clan/ClanBuilding/ClanWelfareWindow.prefab",			-- 帮会福利殿窗口
	ClanPresbyterWindow				= "Clan/ClanBuilding/ClanPresbyterWindow.prefab",	    -- 帮会长老院窗口
	ClanWarfareWindow				= "Clan/ClanBuilding/ClanWarfareWindow.prefab",			-- 帮会战争坊窗口
	--ClanTresonWindow				= "Clan/ClanBuilding/ClanTresonWindow.prefab",			-- 帮会珍宝阁窗口
	HeadTalkBubbleWindow            = "Windows/HeadTalkBubbleWindow.prefab",				-- 头顶泡泡
	FollowConfirmWindow             = "Windows/FollowConfirmWindow.prefab",					-- 召唤跟随响应窗口
	ExtendedConfirmWindow           = "Windows/ExtendedConfirmWindow.prefab",				-- 宝石确认窗口
	MainRedPacketWindow             = "Windows/MainRedPacketWindow.prefab",					-- 红包窗口
	WulinHeroWindow             	= "Windows/WulinHeroWindow.prefab",						-- 武林英雄（华山论剑）窗口
	XiaKeXingBagWindow             	= "Windows/XiaKeXingBag_Window.prefab",					-- 侠客行点赞礼包窗口
	QingGongStrengthWindow          = "Windows/QingGongStrength_Window.prefab",	    		-- 轻功气力值窗口
	UserAgreementWindow				= "Windows/UserAgreementWindow.prefab",	    			-- 用户协议窗口
	GongGaoWindow					= "Windows/GongGaoWindow.prefab",	    				-- 公告窗口
	CommonConfirmWindow				= "Windows/CommonConfirmWindow.prefab",	    			-- 带勾选不在提示确认窗口

    EntryConfigWindow               = "Windows/EntryConfigWindow.prefab",                   -- 入口配置窗口
	HeadTitleUpGradeSuccessWindow   = "Windows/HeadTitleUpGradeSuccessWindow.prefab",	    -- 头衔晋级成功窗口
	PlayerEffectWindow              = "Windows/PlayerEffectWindow.prefab",					-- 播放特效的窗口
	AppearanceWindow				= "Windows/AppearanceWindow.prefab",					-- 外观窗口
	BossWindow                      = "Windows/BossWindow.prefab",                          -- 首领活动窗口
	BabelWnd						= "Windows/BabelWnd.prefab",							-- 通天塔界面
	BabelEndWnd						= "Windows/BabelEndWnd.prefab",							-- 通天塔结算界面
	SublineWindow                   = "Windows/SublineWindow.prefab",                       -- 分线窗口
    ArrestRobberWindow              = "Windows/ArrestRobberWindow.prefab",                  -- 缉拿大盗窗口
    JRBattleRankWindow				= "JiaRenBattle/JRBattleRankWindow.prefab",				-- 假人战场排行榜窗口
    JRBattleTimerWindow             = "JiaRenBattle/JRBattleTimerWindow.prefab",            -- 假人战场倒计时窗口
    DamageRankWindow                = "Windows/DamageRankWindow.prefab",                    -- 伤害统计窗口
	TitleWindow						= "Windows/MainTitle_Window.prefab",					-- 称号主窗口	
	WulinHeroFightResultWindow		= "Windows/WulinHeroFightResultWindow.prefab",			-- 武林英雄副本结算界面	
	LoadingStateWindow				= "Windows/LoadingStateWindow.prefab",					-- 登录状态界面	
	TameWindow						= "Windows/TameWindow.prefab",							-- 驯马窗口
	KillWindow				        = "Windows/KillWindow.prefab",					        -- 杀敌窗口（击败，连斩提示）
    SerialWinWindow                 = "Windows/SerialWinWindow.prefab",                     -- 连胜窗口 
	--雪域求生系统窗口
	SurvivalMatchWindow 			= "Windows/SurvivalMatchWindow.prefab",					-- 雪域求生报名界面	
	PickUpItemWindow                = "Windows/PickUpItemWindow.prefab"	,					--雪域求生捡起物品界面
    BatchUseItemWindow 				= "Windows/BatchUseItemWindow.prefab",					-- 物品批量使用界面	
	ChickingPackageWindow           = "Windows/ChickingPackageWindow.prefab",				--吃鸡的背包窗口
	PickUpItemWindow                = "Windows/PickUpItemWindow.prefab"	,					-- 雪域求生捡起物品界面
    BatchUseItemWindow 				= "Windows/BatchUseItemWindow.prefab",					-- 物品批量使用界面
	ChickingMatchWindow				= "Chicking/ChickingMatchWindow.prefab",				-- 通用匹配界面

	RankCompetitionWindow			= "Windows/RankCompetitionWindow.prefab",				-- 3v3武林大会进入界面
	RankCompetition3V3Window		= "Windows/RankCompetition3V3Window.prefab",				-- 3v3武林大会界面
	RankCompeteOutcomeWindow		= "Windows/RankCompeteOutcomeWindow.prefab",				-- 3v3结算界面
}

-- 飘血提示
this.FightBloodCell =
{	
	--自己
	SelfHurtBlood = this.GuiRootPrefabPath .. "Components/BloodTitle/SelfHurtBloodCell.prefab",
	SelfDoubleHurtBlood = this.GuiRootPrefabPath .. "Components/BloodTitle/SelfDoubleHurtBloodCell.prefab",
	FightAddBloodCell = 	this.GuiRootPrefabPath .. "Components/BloodTitle/FightAddBloodCell.prefab",
	FlutterGetExpCell = this.GuiRootPrefabPath .. "Components/BloodTitle/FlutterGetExpCell.prefab",	--获得经验
	DuckCell = this.GuiRootPrefabPath .. "Components/BloodTitle/DuckCell.prefab",					--闪避		
	FlutterLevelUp = this.GuiRootPrefabPath .. "Components/BloodTitle/FlutterLevelUp.prefab",		--升级
	--敌方
	MonsterHurtBloodCell = this.GuiRootPrefabPath .. "Components/BloodTitle/MonsterHurtBloodCell.prefab", --敌方受到伤害
	MonsterDuckCell = this.GuiRootPrefabPath .. "Components/BloodTitle/MonsterDuckCell.prefab", --敌方闪避
	MonsterDoubleHurtBloodCell = this.GuiRootPrefabPath .. "Components/BloodTitle/MonsterDoubleHurtBloodCell.prefab", -- 敌方暴击

	FightValUpCell = this.GuiRootPrefabPath .. "Components/BloodTitle/FightValUpCell.prefab",				
	Immune = this.GuiRootPrefabPath .. "Components/BloodTitle/Immune.prefab",--免疫，
	Resistance = this.GuiRootPrefabPath .. "Components/BloodTitle/Resistance.prefab" -- 抵抗
}

this.selectRoleBgPath = this.GuiRootPrefabPath .."SelectRole/SelectRoleSceBg.prefab"

-- 角色界面
this.Player = 
{
	PlayerEquipWidget = this.GuiRootPrefabPath .. "Player/Player_Equip_Wight.prefab",	-- 
	PlayerModelWidget = this.GuiRootPrefabPath .. "Player/Player_Model_Wight.prefab",	-- 
	PlayerPropertyWidget = this.GuiRootPrefabPath .. "Player/PlayerPropertyWight.prefab",	-- 
}

-- 打造界面
this.Forge = 
{
	ForgeEquipWidget	= this.GuiRootPrefabPath .. "Forge/Forge_Equip_Widget.prefab",		-- 
	ForgeSmeltWidget	= this.GuiRootPrefabPath .. "Forge/Forge_Smelt_Widget.prefab",		-- 
	ForgeShuffleWidget	= this.GuiRootPrefabPath .. "Forge/Forge_Shuffle_Widget.prefab",	-- 
	ForgeSettingWidget	= this.GuiRootPrefabPath .. "Forge/Forge_Setting_Widget.prefab",	-- 
	ForgeConpoundWidget	= this.GuiRootPrefabPath .. "Forge/Forge_Conpound_Widget.prefab",	--

    CanSetGemTypeItem   = this.GuiRootPrefabPath .. "Forge/CanSetGemTypeItem.prefab",       -- 【镶嵌】可镶嵌宝石类别
    GemInfoCell         = this.GuiRootPrefabPath .. "Forge/GemInfoCell.prefab",             -- 宝石属性信息
    
    
}

this.BackgroundTextureShaderPath = "Assets/AssetFolder/Shader/UI/Background-Texture.shader"
this.BackgroundSpriteShaderPath = "Assets/AssetFolder/Shader/UI/Background-Sprite.shader"

-- 玩家技能界面
this.PlayerSkill = 
{
	PlayerSkillUpgradeWidget = this.GuiRootPrefabPath .. "PlayerSkill/PlayerSkillUpgradeWidget.prefab",	-- 升级窗口
	PlayerLiuPaiSkillWidget = this.GuiRootPrefabPath .. "PlayerSkill/PlayerLiuPaiSkillWidget.prefab",	-- 流派窗口
	PlayerWuXueSkillWidget = this.GuiRootPrefabPath .. "PlayerSkill/PlayerWuXueSkillWidget.prefab",		-- 武学窗口
	PlayerOtherSkillWidget = this.GuiRootPrefabPath .. "PlayerSkill/PlayerOtherSkillWidget.prefab",		-- 其他窗口
	WuXueBookItem = this.GuiRootPrefabPath .. "PlayerSkill/WuXueBookItem.prefab",						-- 武学书图标
	UpgradeWuXueItem = this.GuiRootPrefabPath .. "PlayerSkill/UpgradeWuXueItem.prefab",					-- 技能升级界面的武学图标
}

-- 贸易界面
this.Exchange = 
{
	ExchangeBaiTanWidget = this.GuiRootPrefabPath .. "Exchange/ExchangeBaiTanWidget.prefab",				-- 摆摊窗口
	ExchangePaiMaiWidget = this.GuiRootPrefabPath .. "Exchange/ExchangePaiMaiWidget.prefab",				-- 拍卖窗口
	BaiTanBuyWidget = this.GuiRootPrefabPath .. "Exchange/BaiTanBuyWidget.prefab",							-- 拍卖购买窗口
	BaiTanSellWidget = this.GuiRootPrefabPath .. "Exchange/BaiTanSellWidget.prefab",						-- 拍卖出售窗口
	BaiTanBuyBigTypeItem = this.GuiRootPrefabPath .. "Exchange/BaiTanBuyBigTypeItem.prefab",				-- 拍卖窗口搜索部件的大类型图标
	BaiTanBuySmallTypeItem = this.GuiRootPrefabPath .. "Exchange/BaiTanBuySmallTypeItem.prefab",			-- 拍卖窗口搜索部件的小类型图标
	BaiTanBuyGoodsIntroItem = this.GuiRootPrefabPath .. "Exchange/BaiTanBuyGoodsIntroItem.prefab",			-- 拍卖窗口商品介绍部件的介绍图标
	BaiTanBuyGoodsItem = this.GuiRootPrefabPath .. "Exchange/BaiTanBuyGoodsItem.prefab",					-- 拍卖窗口商品购买部件的商品图标
	BaiTanSellBagItem = this.GuiRootPrefabPath .. "Exchange/BaiTanSellBagItem.prefab",					-- 购买窗口商品购买部件的商品图标
    
    AuctionGoodsListCell = this.GuiRootPrefabPath.."Exchange/AuctionGoodsListCell.prefab",	                -- 竞品Item
    AuctionClassListCell = this.GuiRootPrefabPath.."Exchange/AuctionClassListCell.prefab",                  -- 竞拍类型
    AuctionSubClassItem  = this.GuiRootPrefabPath.."Exchange/AuctionSubClassItem.prefab",                   -- 竞拍类型子Item
    AuctionRecordItem     = this.GuiRootPrefabPath.."ExchangeHistory/AuctionRecordItem.prefab",             -- 竞品日志item
}

--职业图标
this.gProfessionIcon = 
{
	[PERSON_VOCATION_ZHENWU] = this.GuiRootTexturePath.."Common_frame/Common_zhiye_zhenwu.png" ,
	[PERSON_VOCATION_XUANZONG] = this.GuiRootTexturePath.."Common_frame/Common_zhiye_xuanzong.png",
	[PERSON_VOCATION_LINGXIN] = this.GuiRootTexturePath.."Common_frame/Common_zhiye_lingxin.png",
	[PERSON_VOCATION_TIANYU] =this.GuiRootTexturePath.."Common_frame/Common_zhiye_tianyu.png",
}

--武学品质框
this.WuxueQualityBg =
{
	this.GuiRootTexturePath.."Skills/Skills_wuxuedi_lv.png",
	this.GuiRootTexturePath.."Skills/Skills_wuxuedi_lan.png",
	this.GuiRootTexturePath.."Skills/Skills_wuxuedi_zi.png",
	this.GuiRootTexturePath.."Skills/Skills_wuxuedi_chen.png",
}

-- 背包格子路径
this.PackageItemCell = this.GuiRootPrefabPath .. "Package/PersonPack_SkepGoods_Cell.prefab"
-- 滴答Cell路径
this.DidaItemCell = this.GuiRootPrefabPath .. "Dida/Dida_Item_Cell.prefab"

-- 公共界面
this.Login = 
{
	GonggaoItem = this.GuiRootPrefabPath .. "Login/GonggaoItem.prefab"
}

-- 活动界面
this.HuoDong = 
{
	GuideItem = this.GuiRootPrefabPath .. "HuoDong/GuideItem.prefab"
}

-- 活动Cell路径
this.HuoDongItemCell = this.GuiRootPrefabPath .. "HuoDong/QuanTianCell.prefab"
this.HuoDongPushItemCell = this.GuiRootPrefabPath .. "HuoDong/HuoDongPush_Cell.prefab"
this.HuoDongCalenderItemCell = this.GuiRootPrefabPath .. "HuoDong/HuoDongCalenderItem.prefab"
this.HuoDongRewardItem = this.GuiRootPrefabPath .. "HuoDong/RewardItem.prefab"
this.ActiveTaskItem = this.GuiRootPrefabPath .. "HuoDong/ActiveTaskItem.prefab"

-- 聊天Cell路径
this.ChatItemCell = this.GuiRootPrefabPath .. "Chat/ChatElementScrollerCell.prefab"

-- 福利界面
this.Welfare = 
{
	WelfareMenuItem = this.GuiRootPrefabPath .. "Welfare/WelfareMenuItem.prefab",
	RewardBackItem = this.GuiRootPrefabPath .. "Welfare/RewardBackItem.prefab",
}

this.SubTitleCell = 
{
	AsideCell = this.GuiRootPrefabPath .. "Components/SubTitle/AsideCell.prefab",
	BottomTextCell = this.GuiRootPrefabPath .. "Components/SubTitle/BottomTextCell.prefab",
	BubbleTextCell = this.GuiRootPrefabPath .. "Components/SubTitle/BubbleTextCell.prefab",
	CenterTextCell = this.GuiRootPrefabPath .. "Components/SubTitle/CenterCell.prefab",

}

--头顶称号预设
this.HeadTitleCell = {
	NguiHeadTitleCell = this.GuiRootPrefabPath .. "Components/NameTitle/NguiHeadTitle.prefab",
	UguiHeadTitleCell = this.GuiRootPrefabPath .. "Components/NameTitle/UguiHeadTitle.prefab"
}

-- Npc头顶名字
this.NpcNameTitleCell = 
{
	[1] = this.GuiRootPrefabPath .. "Components/NameTitle/MyHeroTitleCell.prefab",
	[2] = this.GuiRootPrefabPath .. "Components/NameTitle/MyHeroTitleCell.prefab",
	[3] =this.GuiRootPrefabPath .. "Components/NameTitle/MyHeroTitleCell.prefab",
	[4] = this.GuiRootPrefabPath .. "Components/NameTitle/MyHeroTitleCell.prefab",
	[5] = this.GuiRootPrefabPath .. "Components/NameTitle/MyHeroTitleCell.prefab",
	[6] = this.GuiRootPrefabPath .. "Components/NameTitle/MyHeroTitleCell.prefab",
	[7] =this.GuiRootPrefabPath .. "Components/NameTitle/MyHeroTitleCell.prefab",
	[8] = this.GuiRootPrefabPath .. "Components/NameTitle/MyHeroTitleCell.prefab",
	[9] = this.GuiRootPrefabPath .. "Components/NameTitle/MyHeroTitleCell.prefab",
	[10] = this.GuiRootPrefabPath .. "Components/NameTitle/MyHeroTitleCell.prefab",
	[11] = this.GuiRootPrefabPath .. "Components/NameTitle/ItemTitleCell.prefab",
	[12] = this.GuiRootPrefabPath .. "Components/NameTitle/ItemTitleCell.prefab",
	[13] = this.GuiRootPrefabPath .. "Components/NameTitle/ItemTitleCell.prefab",
}

-- 创建角色
this.CreateRoleCell = this.GuiRootPrefabPath .. "SelectRole/CreateRole_Cell.prefab"
-- 选择角色
this.SelectRoleCell = this.GuiRootPrefabPath .. "SelectRole/SelectRole_Cell.prefab"
--  消息提示
this.ChatSystemTipsCell = this.GuiRootPrefabPath .. "Chat/ChatSystemTips_Cell.prefab"
--  消息提示
this.TipsActorAboveCell = this.GuiRootPrefabPath .. "Chat/TipsActorAbove_Cell.prefab"


-- 世界地图item
this.WorldMapItem = this.GuiRootPrefabPath .. "Map/WorldMapItem.prefab"
-- 小地图NPC角色
this.NpcMinimapCell = this.GuiRootPrefabPath .. "Map/NPCMinimapCell.prefab"
-- 场景地图NPC角色
this.NPCMapCell = this.GuiRootPrefabPath .. "Map/NPCMapCell.prefab"
-- 场景地图NPC列表项
this.NPCListItem = this.GuiRootPrefabPath .. "Map/NPCListItem.prefab"


--组队窗体的角色显示项
this.MyTeamRoleCell = this.GuiRootPrefabPath .. "TeamNew/RoleItem.prefab"
--组队窗体的喊话历史消息项
this.MyTeamHistoryListCell = this.GuiRootPrefabPath .. "TeamNew/TeamTalkHistoryCell.prefab"
--组队窗体的申请列表项
this.TeamApplyListCell = this.GuiRootPrefabPath .. "TeamNew/ApplyListItem.prefab"
--组队目标申请列表项
this.TeamGoalActiveCell = this.GuiRootPrefabPath .. "TeamNew/TeamGoalActiveCell.prefab"
--队伍自动匹配图片
this.TeamAutoMatchSprite = this.GuiRootTexturePath .. "Common_button_text/Common_button_zhidoumipei.png"
--队伍自动匹配图片
this.TeamDisAutoMatchSprite = this.GuiRootTexturePath .. "Team/team_quxiaopipe.png"
--我的队伍
this.MyTeamWidget =this.GuiRootPrefabPath .. "TeamNew/MyTeam_Widget.prefab"
--附近队伍
this.NearTeamWidget = this.GuiRootPrefabPath .. "TeamNew/NearbyTeam_Widget.prefab"
--队伍平台
this.TeamPlatFormWidge = this.GuiRootPrefabPath .. "TeamNew/Teamplatform_Widget.prefab"


-- 任务相关
this.MainTaskListToggleCell =  this.GuiRootPrefabPath .. "MainTask/MainTask_MainTaskListToggle.prefab"
this.MainTaskListCell =  this.GuiRootPrefabPath .. "MainTask/MainTask_MainTaskList.prefab"
this.MainTaskListElementCell =  this.GuiRootPrefabPath .. "MainTask/MainTask_MainWinTaskElementToggle.prefab"
this.TaskTrackerElementCell =  this.GuiRootPrefabPath .. "MainTask/TaskTrackerElement.prefab"

-- 对话相关

this.DialogTopicListCell =  this.GuiRootPrefabPath .. "Dialog/DialogTopicToggle_Cell.prefab"
--通用窗口
this.CommonWindow        = this.GuiRootPrefabPath .. "Windows/Common_Window.prefab"
--通用窗口
this.CommonWindowPack        = this.GuiRootPrefabPath .. "Windows/Common_WindowPack.prefab"
--通用的遮罩
this.ShadeImage         = this.GuiRootPrefabPath .. "Windows/ShadeImage.prefab"

-- 七龙珠
this.DragonFunctionModuleCell   = this.GuiRootPrefabPath .. "DragonBall/DragonFunctionModuleCell.prefab"
this.DragonFunctionItemCell     = this.GuiRootPrefabPath .. "DragonBall/DragonFunctionItemCell.prefab"
this.DragonParamCell            = this.GuiRootPrefabPath .. "DragonBall/DragonParamCell.prefab"

--富文本物品Cell
this.RichTextGoodsCell         = this.GuiRootPrefabPath .. "Chat/RichTextGoods_Cell.prefab"

-- 聊天栏灵兽cell
this.RichTextPetCell 		= this.GuiRootPrefabPath.."Chat/RichTextPet_Cell.prefab"

--通用商店
this.ChipExchangeWidget	=  this.GuiRootPrefabPath .. "ChipExchange/ChipExchangeWidget.prefab"
this.ChipItemCell	=  this.GuiRootPrefabPath .. "ChipExchange/ChipItem.prefab"

--通用物品cell
this.CommonGoodCell	=  this.GuiRootPrefabPath .. "Common/CommonGoodCell.prefab"

--商城
this.GoodsItemCell 	=  this.GuiRootPrefabPath .. "Shop/GoodsItem.prefab"

--时装
this.DressItemCell	= this.GuiRootPrefabPath .. "Shop/DressItemCell.prefab"

--发色
this.HairColorItem 	= this.GuiRootPrefabPath .. "Shop/HairColorItem.prefab"

--材料合成Cell 
this.MaterialItemCell = this.GuiRootPrefabPath .. "MaterialCompose/MaterialItem.prefab"

this.LoungeCell = this.GuiRootPrefabPath .. "Lounge/LoungeCell.prefab"

this.HGLYRankCell = this.GuiRootPrefabPath .. "HuoGongLiangYing/HGLYRankCell.prefab"

-- 门派入侵Cell
this.MenPaiCell = this.GuiRootPrefabPath .. "HuoDongMenPai/MenPaiCell.prefab"

--灵兽相关Item
this.PetTuJianWidget = this.GuiRootPrefabPath .. "Pet/PetTuJianWidget.prefab"
this.PetNewPetWidget = this.GuiRootPrefabPath .. "Pet/PetNewPetWidget.prefab"
this.PetInheritWidget = this.GuiRootPrefabPath .. "Pet/PetInheritWidget.prefab"
this.PetDeploymentWidget = this.GuiRootPrefabPath .. "Pet/PetDeploymentWidget.prefab"
this.PetBreedSetPage = this.GuiRootPrefabPath .. "Pet/PetBreedSetPage.prefab"
this.PetBreedingPage = this.GuiRootPrefabPath .. "Pet/PetBreedingPage.prefab"
this.PetBreedWidget = this.GuiRootPrefabPath .. "Pet/PetBreedWidget.prefab"
this.PetSkillSuitTip = this.GuiRootPrefabPath .. "Pet/PetSkillSuitTip.prefab"

this.PetIconItem = this.GuiRootPrefabPath .. "Pet/PetIconItem.prefab"
this.PetSkillItem = this.GuiRootPrefabPath .. "Pet/PetSkillItem.prefab"
this.PetPropertyItem = this.GuiRootPrefabPath .. "Pet/PetPropertyItem.prefab"
this.PetPropSliderItem = this.GuiRootPrefabPath .. "Pet/PetPropSliderItem.prefab"
this.PetExpUseItem = this.GuiRootPrefabPath .. "Pet/PetExpUseItem.prefab"
this.PetXiLianItem = this.GuiRootPrefabPath .. "Pet/PetXiLianItem.prefab"
this.PetSuitTextItem = this.GuiRootPrefabPath .. "Pet/PetSuitTextItem.prefab"
--灵兽资质item
this.ZiZhiSliderItem = this.GuiRootPrefabPath .. "Pet/ZiZhiSliderItem.prefab"
--灵兽阵法
this.PetZhenFaIcon = this.GuiRootPrefabPath .. "Pet/PetZhenFaIcon.prefab"
--灵兽阵灵槽
this.PetZhenLingSlot = this.GuiRootPrefabPath .. "Pet/PetZhenLingSlot.prefab"
--升级物品item
this.PetGoodsItem = this.GuiRootPrefabPath .. "Pet/PetGoodsItem.prefab"
--学习升级技能界面
this.PetSkillLearn = this.GuiRootPrefabPath .. "Pet/PetSkillLearnWidget.prefab"
--阵法属性item
this.PetZhenFaProp = this.GuiRootPrefabPath .. "Pet/PetZhenFaProp.prefab"

--灵兽图鉴item
this.PetHuanHuaItem = this.GuiRootPrefabPath .. "Pet/PetHuanHuaItem.prefab"

this.MainActivityItem = GuiAssetList.GuiRootPrefabPath .. "MainHUD/MainActivityItem.prefab"
this.MainSysEntryItem = GuiAssetList.GuiRootPrefabPath .. "MainHUD/MainSysEntryItem.prefab"

this.ServerCell = GuiAssetList.GuiRootPrefabPath .. "Login/ServerCell.prefab"
this.AreaCell = GuiAssetList.GuiRootPrefabPath .. "Login/AreaCell.prefab"

this.Clan = -- 帮会
{
	ClanCreateWdt = GuiAssetList.GuiRootPrefabPath .. "Clan/ClanNone/ClanCreateWidget.prefab",
	ClanJoinWdt = GuiAssetList.GuiRootPrefabPath .. "Clan/ClanNone/ClanJoinWidget.prefab",
	ClanResponseWdt = GuiAssetList.GuiRootPrefabPath .. "Clan/ClanNone/ClanResponseWidget.prefab",
	
	ClanInfoWdt = GuiAssetList.GuiRootPrefabPath .. "Clan/ClanOwn/ClanInfoWidget.prefab",
	ClanLigeanceWdt = GuiAssetList.GuiRootPrefabPath .. "Clan/ClanLigeance/ClanLigeanceWdt.prefab",
	ClanMembersWdt = GuiAssetList.GuiRootPrefabPath .. "Clan/ClanOwn/ClanMembersWdt.prefab",
	
	ClanBuildingWdt = GuiAssetList.GuiRootPrefabPath .. "Clan/ClanBuilding/ClanBuildingWdt.prefab",
}

this.ClanLigeance = -- 帮会领地战
{
	LigeLogbuchCell = GuiAssetList.GuiRootPrefabPath .. "Clan/ClanLigeance/LigeLogbuchCell.prefab",
	LigeanceEntryCell = GuiAssetList.GuiRootPrefabPath .. "Clan/ClanLigeance/LigeanceEntryCell.prefab",
	LigeBalceLogCell = GuiAssetList.GuiRootPrefabPath .. "Clan/ClanLigeance/LigeBalanceLogbuchCell.prefab",
}

this.ClanBuilding = -- 帮会建筑
{
	ClanSkillCell = GuiAssetList.GuiRootPrefabPath .. "Clan/ClanBuilding/ClanSkillCell.prefab",
	ClanWageCell = GuiAssetList.GuiRootPrefabPath .. "Clan/ClanBuilding/ClanWageCell.prefab",
	ClanPresbyterScheduleCell = GuiAssetList.GuiRootPrefabPath .. "Clan/ClanBuilding/ClanPresbyterScheduleCell.prefab",
	ClanPresbyterActivityCell = GuiAssetList.GuiRootPrefabPath .. "Clan/ClanBuilding/ClanPresbyterActivityCell.prefab",
	ClanWeaponCell = GuiAssetList.GuiRootPrefabPath .. "Clan/ClanBuilding/ClanWeaponCell.prefab",
}

this.Adventure =  -- 奇遇系统
{
	AdventureTypeItem = GuiAssetList.GuiRootPrefabPath .. "HuoDong/AdventureTypeItem.prefab",
	AdventureTaskItem = GuiAssetList.GuiRootPrefabPath .. "HuoDong/AdventureTaskItem.prefab",
}

this.MedicineCell = GuiAssetList.GuiRootPrefabPath .. "Settings/MedicineCell.prefab"

this.BusinessItem = this.GuiRootPrefabPath .. "Business/BusinessItem.prefab"
this.BubbleCell =  GuiAssetList.GuiRootPrefabPath .. "Bubble/BubbleCell.prefab"
this.RichTextFunnyWordCell = this.GuiRootPrefabPath .. "Chat/RichTextFunnyWord_Cell.prefab"
this.RedPacketItem = this.GuiRootPrefabPath .. "RedPacket/RedPacketItem.prefab"

-- 生活技能
this.LifeSkills = 
{
	LifeSkillItem = this.GuiRootPrefabPath .. "PlayerSkill/LifeSkillItem.prefab",
	PlayerLifeSkillWidget = this.GuiRootPrefabPath .. "PlayerSkill/PlayerLifeSkillWidget.prefab",
	TypeCookGoodsItem = this.GuiRootPrefabPath .. "PlayerSkill/TypeCookGoodsItem.prefab",
}

-- 外观
this.Appearance = 
{
	DressWidget = this.GuiRootPrefabPath .. "Appearance/DressWidget.prefab",
	RideWidget = this.GuiRootPrefabPath .. "Appearance/RideWidget.prefab",
	DressCellItem = this.GuiRootPrefabPath .."Appearance/DressCellItem.prefab",
	DressSaveItem = this.GuiRootPrefabPath .."Appearance/DressSaveItem.prefab",
}

-- 分线
this.Subline = 
{
	SublineItem = this.GuiRootPrefabPath .. "Subline/SublineItem.prefab",
}
-- 缉拿大盗
this.RobberCell = this.GuiRootPrefabPath .. "ArrestRobber/RobberCell.prefab" 

-- 假人战场
this.JRBattleRankCell = this.GuiRootPrefabPath .. "JiaRenBattle/JRBattleRankCell.prefab"

-- 伤害统计窗口
this.DamageRank = 
{
	DamageRankItem = this.GuiRootPrefabPath .. "HuoDong/DamageRankItem.prefab",
}

--雪域求生预设
this.ChickingItem=
{

	PickUpItem = this.GuiRootPrefabPath .. "Chicking/PickUpItem.prefab",
	

}