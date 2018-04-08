-------------------------------------------------------------------
-- @Author: XieXiaoMei
-- @Date:   2017-08-07 11:52:33
-- @Vers:	1.0
-- @Desc:	场景地图NPC打点元素
-------------------------------------------------------------------

local NPCIconItem = UIControl:new
{
	windowName      = "NPCIconItem",

	m_Width = 0,
	m_Height = 0,

	m_Navigation = nil,
}

------------------------------------------------------------
-- 初始化
function NPCIconItem:Attach( obj )
	UIControl.Attach(self,obj)

	local rect = self.transform:GetComponent(typeof(RectTransform)).rect
	self.m_Width = rect.width
	self.m_Height = rect.height

	local bntRayCast = self.transform:GetComponent("NoDrawingRayCast")
	bntRayCast.raycastTarget = true
	self.Controls.bntRayCast = bntRayCast

	self.DotweenAnim = self.Controls.m_IconImg:GetComponent(typeof(DG.Tweening.DOTweenAnimation))

	self:AddListener(self.Controls.m_IconBtn, "onClick", self.OnBtnIconClicked, self)
end

------------------------------------------------------------
-- 回收自身
function NPCIconItem:RecycleItem()
	if self:isLoaded() then
		rkt.GResources.RecycleGameObject( self.transform.gameObject )
	end
end

------------------------------------------------------------
-- 初始化静态NPC点
function NPCIconItem:InitStaticNpc(data)
	local ctrls = self.Controls

	local nType = data.nType
	local nameTxt = ctrls.m_NameTxt
	nameTxt.text = data.szName
	
	if nType == 1 then
		nameTxt.color = Color.yellow
	
	elseif nType == 2 then
		nameTxt.color = Color.New(0.62,0.125,0.94,1)
	
	elseif nType == 3 then
		nameTxt.color = Color.white
	
	elseif nType == 4 then
		--nameTxt.color = Color.New(0,0,1,1)
	end
	
	ctrls.m_HpTxt.gameObject:SetActive(false)
	self.m_Navigation = data

	if data.SceneMapIcon then
		if data.SceneMapIcon ~= "" then
			UIFunction.SetImageSprite( ctrls.m_IconImg , AssetPath.MapTexturePath .. data.SceneMapIcon)
			return
		end
	end
	
	local spritePath = AssetPath.MapTexturePath
	UIFunction.SetImageSprite( ctrls.m_IconImg , spritePath.."map_dian_NPC.png" )
	

end

------------------------------------------------------------
-- 初始化动态实体点
function NPCIconItem:InitDynamicEnt(data)
	local mapEntityPosCfg =  IGame.rktScheme:GetSchemeInfo(MAPENTITYPOS_CSV, data.nMapEntityPosID)
	if isTableEmpty(mapEntityPosCfg) then
		uerror("mapEntityPosCfg can not equaty nil!")

		self:RecycleItem()
		return
	end

	local ctrls = self.Controls


	 
	-- 是否显示血量
	bFlag = mapEntityPosCfg.nShowHp == 0
	if bFlag then
		ctrls.m_HpTxt.gameObject:SetActive(false) 
	else
		ctrls.m_HpTxt.gameObject:SetActive(true) 
		if mapEntityPosCfg.nShowHp ==1 then 
			ctrls.m_HpTxt.transform:SetParent(self.Controls.m_topPos)
			ctrls.m_HpTxt.transform.localPosition =Vector3.New(0,0,0)
			ctrls.m_HpTxt.text = string.format("%s/%s", data.nHP, data.nHPMax)
		elseif mapEntityPosCfg.nShowHp ==2 then 
			ctrls.m_HpTxt.transform:SetParent(self.Controls.m_bottomPos)
			ctrls.m_HpTxt.transform.localPosition =Vector3.New(0,0,0)
			ctrls.m_HpTxt.text = string.format("%s/%s", data.nHP, data.nHPMax)
		elseif mapEntityPosCfg.nShowHp ==3 then 		
			local hpPer =  data.nHP / data.nHPMax
			local hpPerStr = string.format("%0.2f", hpPer)	
			ctrls.m_HpTxt.transform:SetParent(self.Controls.m_topPos)
			ctrls.m_HpTxt.transform.localPosition = Vector3.New(0,0,0)
			ctrls.m_HpTxt.text = tostring(tonumber(hpPerStr)*100) .. "%"
			ctrls.m_HpTxt.transform:SetAsLastSibling()
		elseif mapEntityPosCfg.nShowHp == 4 then 		
			local hpPer =  data.nHP / data.nHPMax
			local hpPerStr = string.format("%0.2f", hpPer)	
			ctrls.m_HpTxt.transform:SetParent(self.Controls.m_bottomPos)
			ctrls.m_HpTxt.transform.localPosition = Vector3.New(0,0,0)
			ctrls.m_HpTxt.text = tostring(tonumber(hpPerStr)*100) .. "%"
			ctrls.m_HpTxt.transform:SetAsLastSibling()
		end
	
	end
	
		-- 是否显示名字
	local bFlag = mapEntityPosCfg.nShowName == 0
	if bFlag then
		ctrls.m_NameTxt.gameObject:SetActive(false)
	else
		ctrls.m_NameTxt.gameObject:SetActive(true)
		if mapEntityPosCfg.nShowName ==1 then 
			ctrls.m_NameTxt.transform:SetParent(self.Controls.m_topPos)
			ctrls.m_NameTxt.transform.localPosition = Vector3.New(0,0,0)
			ctrls.m_NameTxt.transform:SetAsFirstSibling()
		else
			ctrls.m_NameTxt.transform:SetParent(self.Controls.m_bottomPos)
			ctrls.m_NameTxt.transform.localPosition = Vector3.New(0,0,0)
			ctrls.m_NameTxt.transform:SetAsFirstSibling()
		end
		ctrls.m_NameTxt.text = data.szName
	end
	
	-- icon
	local iconImg = ctrls.m_IconImg
	local imgFilePath = GuiAssetList.GuiRootTexturePath .. mapEntityPosCfg.ICON --显示ICON
		UIFunction.SetImageSprite( iconImg , imgFilePath, function ()
			local w =  tonumber(mapEntityPosCfg.ptSize[1])
			local h =  tonumber(mapEntityPosCfg.ptSize[2])
			if w < 1 or h < 1 then   -- 设置原生尺寸或自定义尺寸
				iconImg:SetNativeSize()
			else
				iconImg.sizeDelta = Vector2.New(w, h)
			end
			
			--是否闪烁
			if mapEntityPosCfg.nFlicker == 1 then			--闪烁
				self.DotweenAnim.duration = mapEntityPosCfg.nFlickerTime
				self.DotweenAnim.endValueFloat = mapEntityPosCfg.nMinAlpha
				self.DotweenAnim.tween:Rewind()
				self.DotweenAnim.tween:Kill()
				if self.DotweenAnim.isValid then
					self.DotweenAnim:CreateTween();
					self.DotweenAnim.tween:Play();
				end
			end
		end)
		
	self.Controls.bntRayCast.raycastTarget = false --不要点击事件
end

------------------------------------------------------------
-- 更新item的位置
function NPCIconItem:UpdateItemPos(pos)
	if not self:isLoaded() then
		return
	end
	
	local position = Vector3.New(pos.x - self.m_Width * 0.5,pos.y - self.m_Height * 0.5,0)
	self.transform.localPosition = position
end


------------------------------------------------------------
-- 监听点击回调
-- NPC列表按钮按下，去往指定npc，与npc对话
function NPCIconItem:OnBtnIconClicked()
	local sceneWdt = UIManager.SceneMapWindow:GetSceneWidget()
	if sceneWdt then
		sceneWdt:GotoChatWithNpc(self.m_Navigation)
	end
end


------------------------------------API----------------------------------------------
--创建一个地图点Image Item
function NPCIconItem.CreateItem(parentTf, data, pos, isDynamic)
	local item = NPCIconItem:new()
	
	rkt.GResources.FetchGameObjectAsync(GuiAssetList.NPCMapCell,
	function (path , obj , ud)
		if nil == obj then
			print("Failed to Load the object")
			return
		end

		obj.transform:SetParent(parentTf, false)
		item:Attach(obj)
		item:UpdateItemPos(pos)

		if isDynamic then
			item:InitDynamicEnt(data)
		else
			item:InitStaticNpc(data)
		end
	end, nil, AssetLoadPriority.GuiNormal )

	return item
end


return NPCIconItem

