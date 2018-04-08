--*****************************************************************
--** 文件名:	DamageRankWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-12-22
--** 版  本:	1.0
--** 描  述:	Boss伤害统计窗口
--** 应  用:  
--******************************************************************

local DamageRankClass = require("GuiSystem.WindowList.HuoDong.Boss.DamageRankItem")

local DamageRankWindow = UIWindow:new
{
	windowName	= "DamageRankWindow",
	m_CurMonsterUID = 0,
}

function DamageRankWindow:OnAttach(obj)
	UIWindow.OnAttach(self, obj, UIManager._MainHUDLayer)	
    
    self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))

	self:CreateTimer()
    
    self:RefreshUI()
end

function DamageRankWindow:SubscribeWinExecute()
	self.m_OnDamageListUpdate = handler(self, self.OnDamageListUpdate)
	rktEventEngine.SubscribeExecute(EVENT_BOSS_DAMAGE_LIST_UPDATE, SOURCE_TYPE_MONSTER, 0, self.m_OnDamageListUpdate)
end

function DamageRankWindow:UnSubscribeWinExecute()
	rktEventEngine.UnSubscribeExecute(EVENT_BOSS_DAMAGE_LIST_UPDATE, SOURCE_TYPE_MONSTER, 0, self.m_OnDamageListUpdate)
	self.m_OnDamageListUpdate = nil
end

function DamageRankWindow:OnEnable()
    self:RefreshUI()
end

function DamageRankWindow:RefreshUI()
    local pCreature = IGame.EntityClient:GetCreature(self.m_CurMonsterUID)
    local nStaticID = pCreature:GetNumProp(CREATURE_MONSTER_MONSTERID)
    
    local tMonsterConfig = IGame.rktScheme:GetSchemeInfo(MONSTER_CSV, nStaticID)
	if not tMonsterConfig then
		print("[BossWdt:SwitchModel]: 找不到Boss配置", nStaticID)
		return
	end
    
    self.Controls.m_BossName.text = "["..tMonsterConfig.szName.."] 伤害统计"
end

function DamageRankWindow:SetItemInfo(i, obj)
	if not obj.gameObject then
		return
	end
	
	local behav = obj:GetComponent(typeof(UIWindowBehaviour))
	if nil == behav then
		return
	end
	
	local item = behav.LuaObject
	if not item then
		return
	end
			
	item:SetItemInfo(i)	
end

function DamageRankWindow:RefreshRankList()
	local nRankCnt = IGame.DamageRankClient:GetDamageCnt()
	local nCurObjCnt = self.Controls.m_RankList.transform.childCount
	
	local callback = function( path , obj , index) 	
        if not self.transform then
			rkt.GResources.RecycleGameObject(obj)
			return
		end
		
		if self.Controls.m_RankList.transform.childCount >= nRankCnt then
			rkt.GResources.RecycleGameObject(obj)
			return
		end
        
		obj.transform:SetParent(self.Controls.m_RankList.transform, false)
		local item = DamageRankClass:new()
		item:Attach(obj)	
		item:SetItemInfo(tonumber(index))
	end
	
	if nRankCnt <=  nCurObjCnt then
		for i = 1, nRankCnt do 
			-- 刷新
			local listCell = self.Controls.m_RankList:GetChild(i-1)
			listCell.gameObject:SetActive(true)
			self:SetItemInfo(i, listCell)	
		end
		
		for i = nRankCnt + 1, nCurObjCnt do 
			-- 隐藏
			local listCell = self.Controls.m_RankList:GetChild(i-1)
			listCell.gameObject:SetActive(false)
		end
	else
		for i = nCurObjCnt + 1, nRankCnt do
			rkt.GResources.FetchGameObjectAsync(GuiAssetList.DamageRank.DamageRankItem , callback,  i , AssetLoadPriority.GuiNormal)
		end
	end
end

function DamageRankWindow:OnDamageListUpdate()
	self:RefreshRankList()
end

function DamageRankWindow:Show(bTop, nMonsterUID)
	self.m_CurMonsterUID  = nMonsterUID
    if self:isShow() then
        self:RefreshUI()
    end
    
	UIWindow.Show(self, bTop)
end

function DamageRankWindow:CreateTimer()	
	self.m_TimerCallBack = handler(self, self.OnRefreshTimer)
	rktTimer.SetTimer(self.m_TimerCallBack, 1000, -1, "Damage Rank")
end

function DamageRankWindow:DestoryTimer()
	if self.m_TimerCallBack then
		rktTimer.KillTimer(self.m_TimerCallBack)
		self.m_TimerCallBack = nil
	end
end

function DamageRankWindow:OnRefreshTimer()
	IGame.DamageRankClient:DamageDataRsq(self.m_CurMonsterUID)
end

function DamageRankWindow:OnDestroy()
	self:DestoryTimer()
	self.m_CurMonsterUID = 0
end

return DamageRankWindow
