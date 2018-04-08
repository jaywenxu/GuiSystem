-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017/02/19
-- 版  本:    1.0
-- 描  述:    系统消息窗口
-------------------------------------------------------------------

local TipsActorAboveWindow = UIWindow:new
{
	windowName		= "TipsActorAboveWindow",
	m_TimeHander	= nil,
	m_TimerRunning	= false,
	m_WaitShow	= false,
	LiveTime		= 3000,
	TextList        = {} ,
	m_DelayHander	= nil ,
	m_TimeCnt		= 0,
}

------------------------------------------------------------
function TipsActorAboveWindow:Init()
	self.m_TimeHander = function() self:OnTimer() end
end
------------------------------------------------------------
function TipsActorAboveWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj,UIManager._SpecialTopLayer)
	if self.m_WaitShow then
		self:Popfront()
	end
	
    return self
end
------------------------------------------------------------
-- 窗口销毁
function TipsActorAboveWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

------------------------------------------------------------
--设置内容
function TipsActorAboveWindow:InsertTipsCell(txt)
	local duration = 0.5
	rkt.GResources.FetchGameObjectAsync( GuiAssetList.TipsActorAboveCell , 
		function( path ,  obj , ud )
			if nil == obj then
				return
			end
			obj.transform:SetParent( self.transform , false )
			obj.transform.localPosition = Vector3.New(0,0,0)
			obj.transform:DOKill(false)
			if table.getn(self.TextList) >= 0 then
					local count = self.transform.childCount
					if count >= 1 then
						for i=1,count do
							local tipsCell = self.transform:GetChild(i-1)
							tipsCell.gameObject.transform:DOKill(false)
							UIFunction.DOTweenLocalMOVEY(tipsCell.gameObject,duration,65)
						end
					end
			end
			obj.transform:Find("Text"):GetComponent(typeof(Text)).text = txt
		end , "" , AssetLoadPriority.GuiNormal )
end

------------------------------------------------------------
--定时器回调函数
function TipsActorAboveWindow:OnTimer()
	if not self:isLoaded() then
		return
	end
	self.m_TimeCnt = self.m_TimeCnt + 1
	if self.m_TimeCnt < 50 then
		return
	end
	self.m_TimeCnt = 0
	local ListCnt = table.getn(self.TextList)
	if ListCnt > 0 then
		self:Popfront()
	elseif ListCnt == 0 and self.transform.childCount == 0 then
		self.m_TimerRunning = false
		rktTimer.KillTimer( self.m_TimeHander )
	end
end

------------------------------------------------------------
-- 添加新的tpis消息到列表
function TipsActorAboveWindow:AddSystemTips(text)
	local CntTmp = 0
	for key,v in ipairs(self.TextList) do
		if text == v then
			CntTmp = CntTmp + 1
		end
		if CntTmp > 3 then
			return
		end
	end
	table.insert( self.TextList , text )
	if not self.m_WaitShow and self.m_TimerRunning == false then
		self.m_WaitShow = true
		self.m_TimerRunning = true
		self:Show(true)
		self:Popfront()
		rktTimer.SetTimer(self.m_TimeHander, 10, -1, "TipsActorAboveWindow:SetTimer")
	end
end

------------------------------------------------------------
-- 将最前面一条pop出来，加入队列
function TipsActorAboveWindow:Popfront()

	if not self:isLoaded() then
		self.m_WaitShow = true
		return
	end
	self.m_WaitShow = false
	local nCount = self.transform.childCount
	if nCount >= 4 then
		for i=0,nCount-4 do
			local firstCell = self.transform:GetChild(i)
			rkt.GResources.RecycleGameObject(firstCell.gameObject)
		end
		return
	end
	if table.getn(self.TextList) <= 0 then
		return
	end
	self:InsertTipsCell( self.TextList[1] )
	table.remove(self.TextList,1)
end

return TipsActorAboveWindow