-- 飘血的几种类型
BloodTypeEnume =
{	
	NoneHurtBlood = "", --未知的飘血类型
	SelfHurtBlood = "SelfHurtBlood", --自己英雄受伤的飘血类型
	SelfDoubleHurtBlood = "SelfDoubleHurtBlood", --自己受到的暴击伤害
	FightAddBloodCell = "FightAddBloodCell", --自己加血
	FlutterGetExpCell ="FlutterGetExpCell",	--获得经验
	DuckCell = "DuckCell",					--闪避		
	FlutterLevelUp = "FlutterLevelUp",		--升级
	MonsterHurtBloodCell = "MonsterHurtBloodCell", --敌方受到伤害
	MonsterDuckCell = "MonsterDuckCell", --敌方闪避
	MonsterDoubleHurtBloodCell = "MonsterDoubleHurtBloodCell", -- 敌方暴击
	FightValUpCell = "FightValUpCell",							--提升战斗力
	Immune = "Immune",--免疫
	Resistance = "Resistance" --抵抗
	
}

--飘血文本在inspector下的路径
BloodCellPath = 
{
	NoneHurtBlood = "", --未知的飘血类型
	SelfHurtBlood = "XAxis/YAxis/Text", --自己英雄受伤的飘血类型
	SelfDoubleHurtBlood = "XAxis/YAxis/Text", --自己受到的暴击伤害
	FightAddBloodCell = "XAxis/YAxis/Text", --自己加血
	FlutterGetExpCell = "XAxis/YAxis/Text",	--获得经验
	DuckCell = "XAxis/YAxis/Text",					--闪避		
	FlutterLevelUp = "XAxis/YAxis/Text",		--升级
	MonsterHurtBloodCell = "XAxis/YAxis/Text", --敌方受到伤害
	MonsterDuckCell = "XAxis/YAxis/Text", --敌方闪避
	MonsterDoubleHurtBloodCell = "XAxis/YAxis/Text", -- 敌方暴击
	FightValUpCell = "XAxis/YAxis/Text"							--提升战斗力
}

--默认的飘血配置
BloodCfgVector ={
	NoneHurtBlood = Vector3.New(0,0.2,0), --未知的飘血类型
	SelfHurtBlood = Vector3.New(0,0.2,0), --自己英雄受伤的飘血类型
	SelfDoubleHurtBlood = Vector3.New(0,0.2,0), --自己受到的暴击伤害
	FightAddBloodCell = Vector3.New(0,0.2,0), --自己加血
	FlutterGetExpCell = Vector3.New(0,0.2,0),	--获得经验
	DuckCell = Vector3.New(0,0.2,0),					--闪避		
	FlutterLevelUp = Vector3.New(0,0.2,0),		--升级
	MonsterHurtBloodCell = Vector3.New(0,0.2,0), --敌方受到伤害
	MonsterDuckCell = Vector3.New(0,0.2,0), --敌方闪避
	MonsterDoubleHurtBloodCell = Vector3.New(0,0.2,0), --敌方暴击
	FightValUpCell = Vector3.New(0,0.2,0),				--提升战斗力
	Immune = Vector3.New(0,0.2,0),	--免疫
	Resistance = Vector3.New(0,0.2,0), --抵抗
}

--飘血间隔时间(ms)
BloodCdTime = {
	NoneHurtBlood = 0,
	SelfHurtBlood = 120,
	SelfDoubleHurtBlood = 120,
	FightAddBloodCell = 120,
	FlutterGetExpCell = 120,
	DuckCell = 120,
	FlutterLevelUp = 120,
	MonsterHurtBloodCell = 120,
	MonsterDuckCell = 120,
	MonsterDoubleHurtBloodCell = 120,
	FightValUpCell = 120,
	Immune = 120,
	Resistance = 120,
	
	
}
