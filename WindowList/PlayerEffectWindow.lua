--------------------------------------------------------------
-- 版  权:	(C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:	许文杰
-- 日  期:	2017.12.5
-- 版  本:	1.0
-- 描  述:	播放特效窗口，一些特殊特效，无关联系统UI
-------------------------------------------------------------------

local PlayerEffectWindow = UIWindow:new
{
	windowName  = "PlayerEffectWindow",	
	m_effectInfo = nil,
	m_tActiveEffect = {},
}

function PlayerEffectWindow:OnAttach(obj)
	UIWindow.OnAttach(self,obj)
	self:realShowEffect(self.m_effectInfo)
end


--根据路劲播放特效
--[[effectInfo=
{
	effectName = "",	-- 特效名字，用于开关
	effectPath = nil, --特效路径
	effectTime = 2f, --特效时间
	playerOverBack = nil, --播放完成回调
}]]--
function PlayerEffectWindow:PlayShowEffect(effectInfo)

	if nil == effectInfo or IsNilOrEmpty(effectInfo.effectPath) then 
		uerror("effectInfo is nil ")
		return
	end
	self.m_effectInfo=effectInfo
	self:Show(true)
	self:realShowEffect(effectInfo)
	
end

function PlayerEffectWindow:realShowEffect(effectInfo)
	if not self:isLoaded() then
		return
	end
	
	rkt.GResources.FetchGameObjectAsync(effectInfo.effectPath,
	function ( path , obj , ud )
		if nil == obj then   -- 判断U3D对象是否已经被销毁
			return
		end
		
		obj.transform:SetParent(self.transform,false)
		obj:SetActive(true)
		
		local timeCallBack = function() 
			if nil == obj then   -- 判断U3D对象是否已经被销毁
				return
			end
			
			if effectInfo.playerOverBack~= nil then 
				effectInfo.playerOverBack()
			end
			
			self:HideEffect(effectInfo.effectName)
		end
		self.m_tActiveEffect[effectInfo.effectName] = {obj = obj, callBack = timeCallBack}
		
		rktTimer.SetTimer(timeCallBack, effectInfo.effectTime*1000, 1, "")
	end, "" , AssetLoadPriority.GuiNormal)
end

function PlayerEffectWindow:HideEffect(szEffectName)
	local effect = self.m_tActiveEffect[szEffectName]
	if not effect then
		return
	end
	
	self.m_tActiveEffect[szEffectName] = nil
	effect.obj:SetActive(false)
	rkt.GResources.RecycleGameObject( effect.obj ) 
	rktTimer.KillTimer(effect.callBack)
	
	if #self.m_tActiveEffect == 0 then
		self:Hide()
	end
end

return PlayerEffectWindow
------------------------------------------------------------

