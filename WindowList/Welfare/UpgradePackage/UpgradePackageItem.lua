
--******************************************************************
--** 文件名:	UpgradePackageItem.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-06-01
--** 版  本:	1.0
--** 描  述:	奖励回收
--** 应  用:  
--******************************************************************

local RewardItemClass = require("GuiSystem.WindowList.HuoDong.HuoDongRewardItem")

local UpgradePackageItem = UIControl:new
{
	windowName = "UpgradePackageItem",
    m_CurIndex = 0,
}

function UpgradePackageItem:Attach(obj)
	UIControl.Attach(self, obj)
    
    self:InitRewardList()
    
	self.m_OnRecvBtnClick = handler(self, self.OnRecvBtnClick)
	self.Controls.m_RecvBtn.onClick:AddListener(self.m_OnRecvBtnClick)
end

function UpgradePackageItem:InitRewardList()
   	local tReward = 
	{
		self.Controls.m_Reward1,
		self.Controls.m_Reward2,
		self.Controls.m_Reward3,
		self.Controls.m_Reward4,
		self.Controls.m_Reward5,
	}
	
	for i = 1, #tReward do
		local item = RewardItemClass:new({})
		item:Attach(tReward[i].gameObject)
	end
end

function UpgradePackageItem:SetGoodsCellInfo(idx, listCell)
	local behav = listCell:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	local item = behav.LuaObject
	if not item then
		uerror("RewardBackItem:SetGoodsCellInfo item为空")
		return
	end
	
	local Goods = IGame.UpgradePackageClient:GetRewardObj(self.m_CurIndex, idx)
	if not Goods then
		return
	end
	
	item:SetItemCellInfo(Goods)
end

function UpgradePackageItem:OnRecvBtnClick()
   IGame.UpgradePackageClient:RecvPackageRsq(self.m_CurIndex)
end

function UpgradePackageItem:RefreshRewardList()
    local tReward = 
	{
		self.Controls.m_Reward1,
		self.Controls.m_Reward2,
		self.Controls.m_Reward3,
		self.Controls.m_Reward4,
		self.Controls.m_Reward5,
	}
	
	local nGoodsCount = IGame.UpgradePackageClient:GetRewardCnt(self.m_CurIndex)
	for i = 1, #tReward do
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

function UpgradePackageItem:SetBtnStatus(nStatus)
    local tButton = self.Controls.m_RecvBtn
    if nStatus == 2 then
        tButton.gameObject:SetActive(false)
        self.Controls.m_RecvedImg.gameObject:SetActive(true)
        return
    end
    
    self.Controls.m_RecvedImg.gameObject:SetActive(false)
    tButton.gameObject:SetActive(true)
    
    local bEnable = (nStatus == 1)
    local callback = function()
		UIFunction.SetComsAndChildrenGray(tButton , not bEnable)
		UIFunction.SetButtonClickState(tButton, bEnable)
	end
	
	UIFunction.SetComsAndChildrenGray(tButton , not bEnable, callback)
end

function UpgradePackageItem:SetCellInfo(idx)
    
    self.m_CurIndex = idx
    
    local tData = IGame.UpgradePackageClient:GetUpgradeObj(self.m_CurIndex)
    if not tData then
        return
    end
        
    --等级标题
    local controls = self.Controls
    controls.m_LevelTxt.text = tData.nLevel.."级领取"
    
    --按钮状态
    self:SetBtnStatus(tData.nStatus)
    
    -- 刷新奖励列表
	self:RefreshRewardList()
end

function UpgradePackageItem:RecycleRewardCtrl()
    local tReward = 
	{
		self.Controls.m_Reward1,
		self.Controls.m_Reward2,
		self.Controls.m_Reward3,
		self.Controls.m_Reward4,
		self.Controls.m_Reward5,
	}
    
    for i = 1, #tReward do
        local behav = tReward[i]:GetComponent(typeof(UIWindowBehaviour))
        if behav and behav.LuaObject then
            local item = behav.LuaObject
            item:OnRecycle()
        end
    end
end

function UpgradePackageItem:OnRecycle()
    
    self:RecycleRewardCtrl()
    
    self.Controls.m_RecvBtn.onClick:RemoveListener(self.m_OnRecvBtnClick )

    UIControl.OnRecycle(self)
end

return UpgradePackageItem