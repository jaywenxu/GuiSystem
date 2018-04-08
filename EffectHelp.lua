
-- 特效操作
------------------------------------------------------------------------------
EffectHelp = {
	chickEffect ={},等等
}

--根据路劲播放特效
--[[effectInfo=
{
	effectPath = ef_boss_diqing@skill_4_1, --特效路径
	effectTime = 2f, --特效时间
	playerOverBack = nil, --播放完成回调
	playRadius = 5,
	selfRadius = 3.4,
	centerPoint = Vector3.New(0,0,0)
	tag = "default" --唯一标记
	
}]]--
function EffectHelp.PlayChickingEffect(effectInfo)
	if effectInfo == nil or effectInfo.tag == nil then 
	
		return
	end
	if effectInfo.effectPath == nil then 
		effectInfo.effectPath = "Assets/IGSoft_Resources/Projects/Prefabs/boss_diqing/ef_boss_diqing@skill_4_1.prefab"
	end
	if EffectHelp.chickEffect[effectInfo.tag] ~= nil then 
		EffectHelp.chickEffect[effectInfo.tag].transform.localPosition = effectInfo.centerPoint
		local scale = effectInfo.playRadius/effectInfo.selfRadius
		EffectHelp.chickEffect[effectInfo.tag].transform.localScale = Vector3.New(scale,scale,scale)
		
	else
		rkt.GResources.FetchGameObjectAsync(effectInfo.effectPath,
		function ( path , obj , ud )
			if nil == obj then   -- 判断U3D对象是否已经被销毁
				return
			end
			
			if EffectHelp.chickEffect[effectInfo.tag] ~= nil then 
				obj = EffectHelp.chickEffect[effectInfo.tag]
			end
		
			obj.transform.localPosition = effectInfo.centerPoint
			local scale = effectInfo.playRadius/effectInfo.selfRadius
			obj.transform.localScale = Vector3.New(scale,scale,scale)
			obj:SetActive(true)
			EffectHelp.chickEffect[effectInfo.tag] = obj
			
			if effectInfo.effectTime ~= nil then 
				rktTimer.SetTimer(
				function() 
					obj:SetActive(false)
					rkt.GResources.RecycleGameObject( obj ) 
					if effectInfo.playerOverBack~= nil then 
						effectInfo.playerOverBack()
					end
				end,effectInfo.effectTime*1000,1,"")
			end

		end, "" , AssetLoadPriority.GuiNormal)
	end

end


function EffectHelp.ClearChickingEffect(tag)
	if nil ~= EffectHelp.chickEffect[tag] then 
		rkt.GResources.RecycleGameObject(chickEffect)
		EffectHelp.chickEffect[tag]= nil
	end
end