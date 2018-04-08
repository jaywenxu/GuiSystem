--******************************************************************
--** 文件名:	WeekLoginReward.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-06-01
--** 版  本:	1.0
--** 描  述:	七天登录礼包单天奖励
--** 应  用:  
--******************************************************************

local RewardItemClass = require("GuiSystem.WindowList.HuoDong.HuoDongRewardItem")

local WeekLoginReward = UIControl:new
{
	windowName = "WeekLoginReward",
    m_CurIdx   = 0
}

function WeekLoginReward:Attach(obj)
	UIControl.Attach(self, obj)

    self:InitGoodsCtrl()
    
    self.m_OnRecvBtnClick = handler(self, self.OnRecvBtnClick)
	self.Controls.m_RecvBtn.onClick:AddListener(self.m_OnRecvBtnClick)
        
end

function WeekLoginReward:SetGoodsInfo()
    local behav = self.Controls.m_Reward:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
    
	local item = behav.LuaObject
	if not item then
		uerror("RewardBackItem:SetGoodsCellInfo item为空")
		return
	end
	
	local tData = IGame.WeekLoginClient:GetDayObj(self.m_CurIdx)
	if not tData then
		return
	end
    
    if not tData.Reward then
        return
    end
	
	item:SetItemCellInfo(tData.Reward)
end

function WeekLoginReward:InitGoodsCtrl()
    local item = RewardItemClass:new({})
    item:Attach(self.Controls.m_Reward.gameObject)
end

function WeekLoginReward:SetStatusUnLock()
    local path = GuiAssetList.GuiRootTexturePath.."Welfare/Welfare_denglon_mo.png"
    UIFunction.SetImageSprite(self.Controls.m_RewardBg, path)
    
    self.Controls.m_Daytxt.gameObject:SetActive(true)
    self.Controls.m_StatusImg.gameObject:SetActive(false)
    self.Controls.m_GouxuanImg.gameObject:SetActive(false)
    self.Controls.m_RecvBtn.gameObject:SetActive(false)
end

function WeekLoginReward:SetStatusUnRecv()
    local path = GuiAssetList.GuiRootTexturePath.."Welfare/Welfare_denglon_xuan.png"
    UIFunction.SetImageSprite(self.Controls.m_RewardBg, path)
    
    self.Controls.m_Daytxt.gameObject:SetActive(false)
    self.Controls.m_StatusImg.gameObject:SetActive(true)
    self.Controls.m_GouxuanImg.gameObject:SetActive(false)
    self.Controls.m_RecvBtn.gameObject:SetActive(true)
end

function WeekLoginReward:SetStatusRecved()
    local path = GuiAssetList.GuiRootTexturePath.."Welfare/Welfare_denglon_mo.png"
    UIFunction.SetImageSprite(self.Controls.m_RewardBg, path)
    
    self.Controls.m_Daytxt.gameObject:SetActive(true)
    self.Controls.m_StatusImg.gameObject:SetActive(false)
    self.Controls.m_GouxuanImg.gameObject:SetActive(true)
    self.Controls.m_RecvBtn.gameObject:SetActive(false)
end

function WeekLoginReward:SetStatus(nStatus)
    local tProcessFunc = 
    {
        [0] = function() self:SetStatusUnLock() end,
        [1] = function() self:SetStatusUnRecv() end,
        [2] = function() self:SetStatusRecved() end,
    }
    
    if not tProcessFunc[nStatus] then
        return
    end
    
    tProcessFunc[nStatus]()
end

function WeekLoginReward:SetItemInfo(idx)
    self.m_CurIdx = idx
    local tData = IGame.WeekLoginClient:GetDayObj(idx)
    if not tData then
        return
    end
    
    self:SetGoodsInfo()
    
    self:SetStatus(tData.nStatus)
end

function WeekLoginReward:OnRecvBtnClick()
    IGame.WeekLoginClient:GetRewardRsq(self.m_CurIdx)
end

return WeekLoginReward