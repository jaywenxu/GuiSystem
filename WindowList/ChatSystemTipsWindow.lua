-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017/02/19
-- 版  本:    1.0
-- 描  述:    系统消息窗口
-------------------------------------------------------------------

local ChatSystemTipsWindow = UIWindow:new
{
	windowName		= "ChatSystemTipsWindow",
	m_TimeHander	= nil,
	m_TimerRunning	= false,
	m_Running		= false,
	LiveTime		= 3000,
	TextList        = {} ,
	m_TimeCnt 		= 0,
	m_LastTime		= 0,
}

local Cell_High = 65
------------------------------------------------------------
function ChatSystemTipsWindow:Init()
	self.m_TimeHander = function() self:OnTimer() end
end
------------------------------------------------------------
function ChatSystemTipsWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj,UIManager._SpecialTopLayer)
	
    return self
end
------------------------------------------------------------
-- 窗口销毁
function ChatSystemTipsWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

------------------------------------------------------------
--设置内容
function ChatSystemTipsWindow:InsertTipsCell(txt)
	local duration = 0.5
	rkt.GResources.FetchGameObjectAsync( GuiAssetList.ChatSystemTipsCell , 
		function( path ,  obj , ud )
			if nil == obj then
				return
			end
			obj.transform:SetParent( self.transform , false )
			self.m_Running = true
			obj.transform.localPosition = Vector3.New(0,0,-800)
			obj.transform:DOKill(false)
			UIFunction.DOTweenLocalMOVEY(obj,duration,Cell_High,
				function (obj)
					self.m_Running = false
					--如果列表有待显示消息
					if table.getn(self.TextList) >= 0 then
						local count = self.transform.childCount
						if count >= 1 then
							for i=1,count do
								local tipsCell = self.transform:GetChild(i-1)
								tipsCell.gameObject.transform:DOKill(false)
								UIFunction.DOTweenLocalMOVEY(tipsCell.gameObject,duration,Cell_High)
							end
						end
					end
				end)
			local anims = obj:GetComponentsInChildren(typeof(DG.Tweening.DOTweenAnimation))
			for i = 0 , anims.Length -1 do
				anims[i]:DORestartById(2)
			end
			obj.transform:Find("Text"):GetComponent(typeof(Text)).text = txt
		end , "" , AssetLoadPriority.GuiNormal )
end

------------------------------------------------------------
--定时器回调函数
function ChatSystemTipsWindow:OnTimer()
	if not self:isLoaded() then
		return
	end

	if luaGetTickCount() - self.m_LastTime < 500 then
		return
	end
	
	self.m_TimeCnt = 0
	if self.m_Running == true then
		return
	end
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
function ChatSystemTipsWindow:AddSystemTips(text)
	table.insert( self.TextList , text )
	if not self.m_WaitShow and not self.m_TimerRunning then
		self.m_TimerRunning = true
		self.m_WaitShow = true
		self:Show(true)
		self.m_TimeCnt = 50
		rktTimer.SetTimer(self.m_TimeHander, 10, -1, "ChatSystemTipsWindow:SetTimer")
	end
end

------------------------------------------------------------
-- 将最前面一条pop出来，加入队列
function ChatSystemTipsWindow:Popfront()
	if not self:isLoaded() then
		self.m_WaitShow = true
		return
	end
	self.m_WaitShow = false
	if self.m_Running == false then
		local count = 0
		if self:isLoaded() then
			count = self.transform.childCount
			if count >= 3 then
				local firstCell = self.transform:GetChild(count-3)
				local anims = firstCell.gameObject:GetComponentsInChildren(typeof(DG.Tweening.DOTweenAnimation))
				for i = 0 , anims.Length -1 do
					anims[i]:DORestartById(1)
				end
			end
--[[			if count >= 5 then
				for i=0,count-5 do
					local firstCell = self.transform:GetChild(i)
					rkt.GResources.RecycleGameObject(firstCell.gameObject)
				end
				return
			end--]]
		end
		if table.getn(self.TextList) <= 0 then
			return
		end
		self.m_LastTime = luaGetTickCount()
		self:InsertTipsCell( self.TextList[1] )
		table.remove(self.TextList,1)
	end
end

return ChatSystemTipsWindow