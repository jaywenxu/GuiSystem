--KillWindow.lua------------------------------------------------------------
-- 版  权:	(C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:	何荣德
-- 日  期:	2017.12.28
-- 版  本:	1.0
-- 描  述:	杀敌窗口
-------------------------------------------------------------------

local KillWindow = UIWindow:new
{
	windowName  = "KillWindow",

    m_tMessageQueue = {},
    
    m_tCurShowGObj = {},
    m_timeCallBack = nil,
}

gSerialChopIconPath = {
    [1] = "Fight/Fight_dashatesha.png",
    [2] = "Fight/Fight_yaoguaishalu.png",
    [3] = "Fight/Fight_zhuzaizhanchang.png",
    [4] = "Fight/Fight_rutongshenyiban.png",
    [5] = "Fight/Fight_chaoshen.png",
}

function KillWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
    
    self:ShowUI()
end

function KillWindow:Show()
    UIWindow.Show(self)
    
    if not self:isLoaded() then
        return
    end
    self:ShowUI()
end

function KillWindow:ShowUI()
    self:PopQueueMsg()
    self.m_timeCallBack = function() self:OnTimer() end
    rktTimer.SetTimer(self.m_timeCallBack, 1000, -1, "KillWindow:OnTimer")
end

function KillWindow:PopQueueMsg()
    local msg = self.m_tMessageQueue[1]
    if msg.nType == 1 then
        -- 击杀
        self:ShowBeatDown(msg.szActorName, msg.nFaceId)
    elseif msg.nType == 2 then
        -- 连斩
        self:ShowSerialChop(msg.szMudActorName, msg.nChopNum, msg.nChopTipsID)
    end
    table.remove(self.m_tMessageQueue, 1)
end

-- 添加击败提示
function KillWindow:AddBeatDownTips(szActorName, nFaceId)
    local msg = {}
    msg.nType = 1
    msg.szActorName = szActorName
    msg.nFaceId = nFaceId
    table.insert(self.m_tMessageQueue, msg)
    if not self.m_timeCallBack then
        self:Show()
    end
end

-- 添加连斩提示
function KillWindow:AddSerialChopTips(szMudActorName, nChopNum, nChopTipsID) 
    local msg = {}
    msg.nType = 2
    msg.szMudActorName = szMudActorName
    msg.nChopNum = nChopNum
    msg.nChopTipsID = nChopTipsID
    table.insert(self.m_tMessageQueue, msg)
    if not self.m_timeCallBack then
        self:Show()
    end
end

-- 显示击败
function KillWindow:ShowBeatDown(szActorName, nFaceId)    
    -- 玩家名称
    self.Controls.m_ActorName.text = "你"
    self.Controls.m_DieActorName.text = szActorName
    
    -- 这个地方暂不考虑1s内异常加载没完成的情况
    local callBack = function()  
            local pGameObject = self.Controls.m_ShowBeatDown.gameObject
            pGameObject:SetActive(true)
            table.insert(self.m_tCurShowGObj, pGameObject)
            
            pGameObject = self.Controls.m_ShowBeatDown.transform:Find("KillHead")
            local TweenAnim = pGameObject:GetComponent(typeof(DG.Tweening.DOTweenAnimation))
            TweenAnim:DORestart(true)
        end
        
    -- 玩家头像
    UIFunction.SetHeadImage(self.Controls.m_DieHeadIcon, nFaceId, callBack)
end

-- 显示连斩
function KillWindow:ShowSerialChop(szMudActorName, nChopNum, nChopTipsID)
    if not gSerialChopIconPath[nChopTipsID] then
        return
    end
    
    self.Controls.m_ActorName.text = szMudActorName
    
    local pGameObject = self.Controls["m_ShowSerialChop" .. nChopTipsID].gameObject
	
	local ChopNum = pGameObject.transform:Find("ChopNum"):GetComponent(typeof(Text))
	ChopNum.text = nChopNum
	
    pGameObject:SetActive(true)
    table.insert(self.m_tCurShowGObj, pGameObject)
    
    local TweenAnim = pGameObject:GetComponent(typeof(DG.Tweening.DOTweenAnimation))
    TweenAnim:DORestart(true) 
end

-- 隐藏连胜或者连斩或者击杀的时候判断一下当前是否需要隐藏
function KillWindow:Hide() 
	if self.m_timeCallBack then
        rktTimer.KillTimer(self.m_timeCallBack)
        self.m_timeCallBack = nil
    end
    UIWindow.Hide(self)
end

function KillWindow:OnTimer()
    if self.m_tCurShowGObj then
        for k, v in pairs(self.m_tCurShowGObj) do
            v:SetActive(false)
        end
        self.m_tCurShowGObj = {}
    end
    
    if #self.m_tMessageQueue ~= 0 then
        self:PopQueueMsg()
    else
        self:Hide()
    end
end

-- 击杀消息到达
function KillWindow:OnKillTipsArrived(nType, szMsg)
    -- todo herder
    if nType == InfoPos_ActorAbove then
        local tMsg = split_string(szMsg, ';')
        local szName = tMsg[1]
    
        -- 连斩广播
        local pHero = GetHero()
        if not pHero then
            return
        end
        
        local actorName = pHero:GetName()
        if szName == actorName then
           szName = "你" 
        end
        
        local nChopNum = tonumber(tMsg[2])
        self:ShowSerialChop(szName, nChopNum)
    end
end

return KillWindow