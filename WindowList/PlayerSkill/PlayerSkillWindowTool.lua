--/******************************************************************
---** 文件名:	PlayerSkillWindowTool.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-03
--** 版  本:	1.0
--** 描  述:	技能界面用到的通用的接口，
--				没定义到ui工具接口里面，是因为大家习惯不一样
--** 应  用:  
--******************************************************************/

PlayerSkillWindowTool = {}

local WUXUE_BOOK_SLOT_IMG_KONG = "Skills/skills_wuxue_kong.png"		-- 空
local WUXUE_BOOK_SLOT_IMG_LV = "Skills/skills_wuxue_lv.png"			-- 绿
local WUXUE_BOOK_SLOT_IMG_LAN = "Skills/skills_wuxue_lan.png"			-- 蓝
local WUXUE_BOOK_SLOT_IMG_ZI = "Skills/skills_wuxue_zi.png"			-- 紫
local WUXUE_BOOK_SLOT_IMG_HUANG = "Skills/skills_wuxue_huang.png"		-- 黄


-- 设置页签的选中状态
-- @button:开关组件 MonoBehavior
-- @on:是否选中的标识 boolean
function PlayerSkillWindowTool.SetTabSelectedState(tab, on)
	
	tab.transform:Find("GameObject/Image_On").gameObject:SetActive(on)
	tab.transform:Find("GameObject/Image_Off").gameObject:SetActive(not on)
	
end

-- 设置武学书格子
-- @bookSlot:武学格子:Image
-- @quality:格子武学书对应的品质:number
function PlayerSkillWindowTool.SetWuXueBookSlot(bookSlot, quality)
	
	if quality == 0 then
		UIFunction.SetImageSprite(bookSlot, AssetPath.TextureGUIPath..WUXUE_BOOK_SLOT_IMG_KONG)
	elseif quality == 1 then
		UIFunction.SetImageSprite(bookSlot, AssetPath.TextureGUIPath..WUXUE_BOOK_SLOT_IMG_LV)
	elseif quality == 2 then
		UIFunction.SetImageSprite(bookSlot, AssetPath.TextureGUIPath..WUXUE_BOOK_SLOT_IMG_LAN)
	elseif quality == 3 then
		UIFunction.SetImageSprite(bookSlot, AssetPath.TextureGUIPath..WUXUE_BOOK_SLOT_IMG_ZI)
	else
		UIFunction.SetImageSprite(bookSlot, AssetPath.TextureGUIPath..WUXUE_BOOK_SLOT_IMG_HUANG)
	end
	
end
