
--******************************************************************
--** 文件名:	RewardBackItem.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-06-01
--** 版  本:	1.0
--** 描  述:	奖励回收单元
--** 应  用:  
--******************************************************************
require("GuiSystem.WindowList.Welfare.WelfareDef")

local RewardGoodsClass = require("GuiSystem.WindowList.Welfare.RewardBack.RewardBackGoods")
local tNormalTxtColor  = Color.New(0.117,0.353,0.408,1)
local tRedTxtColor = Color.New(1, 0, 0, 1)
local MAX_GOODS_NUM = 4

local RewardBackItem = UIControl:new
{
	windowName = "RewardBackItem",
	m_SelectedCallback = nil,
	m_GainBtnCallback  = nil,
	m_toggle = nil,
	m_CurOption = 0,
	m_CurIndex  = 0,
	m_RbManager = nil,
}

function RewardBackItem:Init()
	
end

function RewardBackItem:Attach(obj)
	UIControl.Attach(self, obj)
    self.m_toggle = self.transform:GetComponent(typeof(Toggle))
	self.TlgValueChange = handler(self, self.OnSelectChanged)
    self.m_toggle.onValueChanged:AddListener(self.TlgValueChange)
	
	self.GainBtnCallback = function() self:OnGainBtnClick() end
	self.Controls.m_Gain.onClick:AddListener(self.GainBtnCallback)

	self.m_RbManager = IGame.WelfareClient:GetRewardBackManager()
	
	self:InitGoodsList()
end

function RewardBackItem:InitGoodsList()
	
	local tReward = 
	{
		self.Controls.m_Reward1,
		self.Controls.m_Reward2,
		self.Controls.m_Reward3,
		self.Controls.m_Reward4,
	}
	
	for i = 1, MAX_GOODS_NUM do
		local item = RewardGoodsClass:new({})
		item:Attach(tReward[i].gameObject)
	end
end

function RewardBackItem:SetGoodsCellInfo(idx, listCell)
	local behav = listCell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	local item = behav.LuaObject
	if not item then
		uerror("RewardBackItem:SetGoodsCellInfo item为空")
		return
	end
	
	local Goods = self.m_RbManager:GetRewardObj(self.m_CurOption, self.m_CurIndex, idx)
	if not Goods then
		return
	end
	
	item:SetRewardInfo(Goods)
end

function RewardBackItem:RefreshRewardList()
	local tReward = 
	{
		self.Controls.m_Reward1,
		self.Controls.m_Reward2,
		self.Controls.m_Reward3,
		self.Controls.m_Reward4,
	}
	
	local nGoodsCount = self.m_RbManager:GetRewardCnt(self.m_CurOption, self.m_CurIndex)
	for i = 1, MAX_GOODS_NUM do
		if i <= nGoodsCount then
			-- 刷新
			tReward[i].gameObject:SetActive(true)
			self:SetGoodsCellInfo(i, tReward[i])	
		else
			-- 隐藏
			tReward[i].gameObject:SetActive(false)
		end
	end
end

function RewardBackItem:GetMoneyInfo()
    local nHave = 0
    local nCost = 0
	local nImgPath = ""

    local tRecycle = self.m_RbManager:GetRecycleCfg(self.m_CurIndex)
    if not tRecycle then
        return nHave, nCost, nImgPath
    end

    if self.m_CurOption == RB_OPTION.PERFECT then
        nHave = GetHero():GetActorYuanBao()
        nCost = tRecycle.PerfectCost
        nImgPath = RB_CostIconPath.YUANBAO
    else
        local nCurYinbiNum = GetHero():GetYinBiNum()
        local nCurYinLiangNum = GetHero():GetYinLiangNum()
        nCost = tRecycle.NormalCost
        
        if nCurYinbiNum >= nCost then
            nHave = GetHero():GetYinBiNum()
            nImgPath = RB_CostIconPath.YINBI
        else
            if nCurYinLiangNum >= nCost then
                nHave = GetHero():GetYinLiangNum()
                nImgPath = RB_CostIconPath.YINLIANG
            else
                nHave = GetHero():GetYinBiNum()
                nImgPath = RB_CostIconPath.YINBI
            end
        end
    end
    
    return nHave, nCost, nImgPath
end

function RewardBackItem:SetItemInfo(option, idx)

	self.m_CurOption = option
	self.m_CurIndex  = idx
	
	local tRecycle = self.m_RbManager:GetRecycleCfg(idx)
	if not tRecycle then
		return
	end
    
    local nHave, nCost, ImgPath = self:GetMoneyInfo()
	
	local controls = self.Controls
	controls.m_Name.text = tostring(tRecycle.Name)
	controls.m_Times.text = tostring(self.m_RbManager:GetRecycleTimes(idx))
	UIFunction.SetImageSprite(controls.m_CostIcon, ImgPath)
	controls.m_Cost.text = tostring(nCost)
    
    if nHave < nCost then
        controls.m_Cost.color = tRedTxtColor
    else
        controls.m_Cost.color = tNormalTxtColor
    end
    
    -- 刷新奖励列表
	self:RefreshRewardList()
end

function RewardBackItem:SetToggleGroup(group)
	self.m_toggle.group = toggleGroup
end

function RewardBackItem:SetSelectedCallback(func_cb)
	self.m_SelectedCallback = func_cb
end

function RewardBackItem:SetGainBtnCallbak(func_cb)
	self.m_GainBtnCallback = func_cb
end

function RewardBackItem:OnSelectChanged(on)
	if nil ~= self.m_SelectedCallback then
		self.m_SelectedCallback(on)
	end
end

function RewardBackItem:OnGainBtnClick()
	
	if nil ~= self.m_GainBtnCallback then
		self.m_GainBtnCallback(self.m_CurIndex)
	end	
end

function RewardBackItem:RewardGoodsRecycle()
	local tReward = 
	{
		self.Controls.m_Reward1,
		self.Controls.m_Reward2,
		self.Controls.m_Reward3,
		self.Controls.m_Reward4,
	}
	
	for i = 1, MAX_GOODS_NUM do
		local behav = tReward[i]:GetComponent(typeof(UIWindowBehaviour))
		if behav and behav.LuaObject then
			local item = behav.LuaObject
			item:OnRecycle()
		end
	end
end

function RewardBackItem:OnRecycle()
	self.Controls.m_Gain.onClick:RemoveListener(self.GainBtnCallback)
	self.m_toggle.onValueChanged:RemoveListener(self.TlgValueChange)
	self.m_SelectedCallback = nil
	
	-- Recycle Reward Cell
	self:RewardGoodsRecycle()
	
	table_release(self)
	UIControl.OnRecycle(self)
end

function RewardBackItem:OnDestroy()
	
	UIControl.OnDestroy(self)
end

return RewardBackItem