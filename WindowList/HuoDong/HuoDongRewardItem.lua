--/******************************************************************
---** 文件名:	HuoDongWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-03-16
--** 版  本:	1.0
--** 描  述:	活动奖励单元
--** 应  用:  
--******************************************************************/

GOODSLABEL = 
{
	Personal = 1,  -- 个人
	Auction  = 2,  -- 拍卖
}

local LabelPath = 
{
	[GOODSLABEL.Personal] = AssetPath.TextureGUIPath.."Activity/Activity_icon_geren.png",
	[GOODSLABEL.Auction] = AssetPath.TextureGUIPath.."Activity/Activity_icon_paimai.png",
}

local VirtualGoodID = 
{
	YINBI = 9004,
	EXP   = 9001,
}

local HuoDongRewardItem = UIControl:new
{
	windowName = "HuoDongRewardItem",
	m_CurGoodsID = 0,
	m_ShowExpNum = true,
}

function HuoDongRewardItem:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.ClickCallback = function(on) self:OnSelectChanged(on) end
	self.Controls.m_btn.onClick:AddListener(self.ClickCallback)
	
	return self
end

function HuoDongRewardItem:OnSelectChanged(on)
	
	UIManager.GoodsTooltipsWindow:Show(true)
	local subInfo = {
		bShowBtnType	= 0, 	--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
		bBottomBtnType	= 1,
		ScrTrans = self.transform,	-- 源预设
	}
	UIManager.GoodsTooltipsWindow:SetGoodsInfo(self.m_CurGoodsID, subInfo )
end

function HuoDongRewardItem:SetIlleglItem()
	local controls = self.Controls
	controls.m_Icon.sprite = nil
end

function HuoDongRewardItem:SetExpItemNum(Item)
	
	if not self.m_ShowExpNum then
		self.Controls.m_Count.text = ""
		return
	end
	
	local nLevel = GetHero():GetNumProp(CREATURE_PROP_LEVEL)
	local Prize = IGame.rktScheme:GetSchemeInfo(PRIZESTANDARD_CSV, nLevel)
	
	if nil == Prize then
		print("奖励数值没有配置！ Level: "..nLevel)
		return
	end
	
	local nNum = math.floor(Prize.Exp * Item.Num/10000)
	local Txt = ((nNum == 0) and "1万") or (nNum.."万")
	self.Controls.m_Count.text = tostring(Txt)
end

function HuoDongRewardItem:SetItemNum(Item)
	
	if Item.ID == VirtualGoodID.EXP then
		self:SetExpItemNum(Item)
		return
	end
	
	if Item.Num <= 1 then
		self.Controls.m_Count.text = tostring("")
	elseif Item.Num >= 10000 then
		local Num = math.floor(Item.Num/10000)
		self.Controls.m_Count.text = tostring(Num.."万")
	else
		self.Controls.m_Count.text = tostring(Item.Num)
	end
end

function HuoDongRewardItem:SetLabelInfo(tGoods)
	if not tGoods.Label then
		self.Controls.m_LabelImg.gameObject:SetActive(false)
		return
	end
	
	local Path = LabelPath[tGoods.Label]
	if not Path then
		self.Controls.m_LabelImg.gameObject:SetActive(false)
		return
	end
	
	UIFunction.SetImageSprite(self.Controls.m_LabelImg, Path)
	self.Controls.m_LabelImg.gameObject:SetActive(true)
end

function HuoDongRewardItem:SetItemOption(op)
	if not op then
		return
	end
	
	self.m_ShowExpNum = ((nil == op.bShowExpNum) and true) or op.bShowExpNum
end

--[[ 设置物品图标信息
@tGoods: 物品信息
@op    : 选项
{
    bShowExpNum:  显示经验数值, 默认为true
}
--]]
function HuoDongRewardItem:SetItemCellInfo(tGoods, op)
	
	self.m_CurGoodsID = tGoods.ID
	self:SetItemOption(op)
	
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, tGoods.ID)
	if not schemeInfo then
		self:SetIlleglItem()
		return
	end
	
	-- 设置物品图标	
	local IconPath = AssetPath.TextureGUIPath..schemeInfo.lIconID1
	UIFunction.SetImageSprite(self.Controls.m_Icon , IconPath)
	
	-- 设置边框图标
	local KuanPath = AssetPath.TextureGUIPath..schemeInfo.lIconID2
	UIFunction.SetImageSprite(self.Controls.m_Kuan , KuanPath)	
	
	-- 设置标识
	self:SetLabelInfo(tGoods)
	
	-- 设置数量
	self:SetItemNum(tGoods)
end

function HuoDongRewardItem:OnRecycle()
	self.Controls.m_btn.onClick:RemoveListener(self.ClickCallback)
	self.ClickCallback = nil
	
	UIControl.OnRecycle(self)
end

return HuoDongRewardItem



