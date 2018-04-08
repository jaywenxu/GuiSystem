--/******************************************************************
---** 文件名:	BeginCookWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	何水大(765865368@qq.com)
--** 日  期:	2017-11-21
--** 版  本:	1.0
--** 描  述:	玩家技能窗口——生活技能——烹饪界面——烹饪数量选择界面
--** 应  用:  
--******************************************************************/

local LifeSkillNormalGoodsItem = require("GuiSystem.WindowList.PlayerSkill.LifeSkillNormalGoodsItem")

local BeginCookWidget = UIControl:new
{
	windowName = "BeginCookWidget",
	m_CookGoodsID = 0, -- 烹饪物品ID
	m_CookCostGoodsID = 0, -- 素材ID
	m_CookGoodsItem = nil, -- 烹饪物品Item
	m_CurrentNum = 0, -- 当前烹饪数量
	m_MaxNum = 0, -- 当前能烹饪的最大数量
}

function BeginCookWidget:Attach(obj)
    UIControl.Attach(self, obj)
	
	local controls = self.Controls
	
	self.callback_ButtonCook = function() self:OnCookClick() end
	controls.m_ButtonCook.onClick:AddListener(self.callback_ButtonCook)
	
	self.callback_AddNum = function() self:OnAddNumClick() end
	controls.m_ButtonAddNum.onClick:AddListener(self.callback_AddNum)
	
	self.callback_SubNum = function() self:OnSubNumClick() end
	controls.m_ButtonSubNum.onClick:AddListener(self.callback_SubNum)
	
	self.callback_Num = function() self:OnSetNum() end
	controls.m_ButtonNum.onClick:AddListener(self.callback_Num)
	
	self.callback_Close = function() self:OnCloseClick() end
	controls.m_ButtonClose.onClick:AddListener(self.callback_Close)
	
	self.callback_CloseMask = function() self:OnCloseMaskClick() end
	controls.m_ButtonCloseMask.onClick:AddListener(self.callback_CloseMask)
	
	self.m_CookGoodsItem = LifeSkillNormalGoodsItem:new()
	self.m_CookGoodsItem:Attach(controls.m_CookGoodsItem.gameObject)
end

function BeginCookWidget:ShowUI(goodsID, costGoodsID)
	self.m_CookGoodsID = goodsID
	self.m_CookCostGoodsID = costGoodsID
	local goodsCfg = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodsID)
	local cookCfg = IGame.rktScheme:GetSchemeInfo(LIFESKILLCOOK_CSV, goodsID)
	local bills = stringToTable(cookCfg.CostGoods)
	local costNum = bills[costGoodsID]
	if not costNum or 0 == costNum then
		uerror("LifeSkillCook.csv 配置错误！物品ID：" .. goodsID)
		return
	end
	
	-- 烹饪物品名字
	local cookColor = DColorDef.getNameColor(0, goodsCfg.lBaseLevel)
	self.Controls.m_TextName.text = string.format("<color=#%s>" .. goodsCfg.szName .. "</color>", cookColor)
	
	self.m_CookGoodsItem:UpdateItem(goodsID)
	
	local haveNum = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET):GetGoodNum(costGoodsID)
	self.m_MaxNum = math.floor(haveNum / costNum)
	
	self:SetNum(1)
	self:Show()
end

-- 添加烹饪数量
function BeginCookWidget:OnAddNumClick()
	if self.m_CurrentNum >= self.m_MaxNum then
		return 
	end
	
	self.m_CurrentNum = self.m_CurrentNum + 1
	self:SetNum(self.m_CurrentNum)
end

-- 减少烹饪数量
function BeginCookWidget:OnSubNumClick()
	if self.m_CurrentNum <= 1 then
		return 
	end
	
	self.m_CurrentNum = self.m_CurrentNum - 1
	self:SetNum(self.m_CurrentNum)
end

-- 开始烹饪
function BeginCookWidget:OnCookClick()
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return
	end
	
	-- 战斗状态判断
	local pPKModePart = pHero:GetEntityPart(ENTITYPART_PERSON_PKMODE)
	if not pPKModePart then
		return
	end
	
	if pPKModePart:GetPKState() == EPK_Person_Battle then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "战斗状态下无法进行生产")
		return
	end
	
	-- 死亡状态
	if pHero:IsDead() then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "死亡状态下无法进行生产")
		return
	end
	
	IGame.LifeSkillClient:OnRequestCook(self.m_CookGoodsID, self.m_CookCostGoodsID, self.m_CurrentNum)
	self:Hide()
end

-- 关闭窗口
function BeginCookWidget:OnCloseClick()
	self:Hide(false)
end

-- 关闭窗口
function BeginCookWidget:OnCloseMaskClick()
	self:Hide(false)
end

function BeginCookWidget:OnDestroy()
	
	local controls = self.Controls
	
	controls.m_ButtonCook.onClick:RemoveListener(self.callback_ButtonCook)
	self.callback_ButtonCook = nil
	
	controls.m_ButtonAddNum.onClick:RemoveListener(self.callback_AddNum)
	self.callback_AddNum = nil

	controls.m_ButtonSubNum.onClick:RemoveListener(self.callback_SubNum)
	self.callback_SubNum = nil

	controls.m_ButtonNum.onClick:RemoveListener(self.callback_Num)
	self.callback_Num = nil

	controls.m_ButtonClose.onClick:RemoveListener(self.callback_Close)
	self.callback_Close = nil

	controls.m_ButtonCloseMask.onClick:RemoveListener(self.callback_CloseMask)
	self.callback_CloseMask = nil
	
	UIControl.OnDestroy(self)
end

-- 烹饪数量小键盘
function BeginCookWidget:OnSetNum()
	
	local onUpdateChange = function(num) 
		self:SetNum(num)
	end
	
	local numTable = {
	    ["inputNum"] = 1,
		["minNum"] = 1,
		["maxNum"] =  self.m_MaxNum,
		["bLimitExchange"] = 0
	}
	
	local otherInfoTable = {
		["inputTransform"] = self.Controls.m_ButtonNum.transform,
	    ["bDefaultPos"] = 1,
	    ["callback_UpdateNum"] = onUpdateChange
	}
	
	UIManager.NumericKeypadWindow:ShowWindow(numTable, otherInfoTable)
end

-- 设置烹饪数量
function BeginCookWidget:SetNum(num)
	local controls = self.Controls
	self.m_CurrentNum = num
	controls.m_TextNum.text = tostringEx(num)

	UIFunction.SetImageGray(controls.m_imgSubNum, num <= 1)
	UIFunction.SetImageGray(controls.m_imgAddNum, num >= self.m_MaxNum)
end


return BeginCookWidget