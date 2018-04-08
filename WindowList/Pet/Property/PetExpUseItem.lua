
---------------------------灵兽系统 - 经验物品使用界面--------------------------------------

local PetExpUseItem = UIControl:new
{
	windowName = "PetExpUseItem",
	
	m_Index = -1,
	m_GoodsID = -1,
	m_PetUID = nil,
	
	m_Inteval = 200,				--连续使用间隔
	
	m_HaveNum = 0,					--背包中一共有多少个物品
	
	m_TotalNum = 0,					--本次点击一共使用多少个物品
	
	m_FirstPointDown = true,  		--是否是第一次执行
	
	m_NeedShowGetGoods = false,		--是否点击显示获取

	m_CanUse = true,				--是否可以发消息
}

function PetExpUseItem:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.PointerDownCB = function( eventData ) self:OnPointerDown(eventData) end
	self.PointerUpCB = function( eventData ) self:OnPointerUp(eventData) end 
	
	UIFunction.AddEventTriggerListener( self.transform , EventTriggerType.PointerDown , self.PointerDownCB )
	UIFunction.AddEventTriggerListener( self.transform , EventTriggerType.PointerUp , self.PointerUpCB)
	
	self.StartUse = false
	self.StartUseCB = function() self:SetStartUse() end
	self.ContinueUseCB = function() self:ContinueUse() end
	
	self.OnMsgCB = function() self:OnUseExpItem() end
end

function PetExpUseItem:Show()
	rktEventEngine.SubscribeExecute(EVENT_PET_BASEPROP, SOURCE_TYPE_PET, 0, self.OnMsgCB)
	UIControl.Show(self)
end

function PetExpUseItem:Hide(destroy)
	rktEventEngine.UnSubscribeExecute(EVENT_PET_BASEPROP, SOURCE_TYPE_PET, 0, self.OnMsgCB)
	self.m_CanUse = true
	UIControl.Hide(self, destroy)
end

function PetExpUseItem:OnDestroy()
	UIFunction.RemoveEventTriggerListener(self.transform, EventTriggerType.PointerDown , self.PointerDownCB)
	UIFunction.RemoveEventTriggerListener(self.transform , EventTriggerType.PointerUp , self.PointerUpCB)
	rktTimer.KillTimer(self.ContinueUseCB)
	self.m_CanUse = true
	UIControl.OnDestroy(self)
end

--点击长按
function PetExpUseItem:OnPointerDown( eventData )
	if self.m_FirstPointDown and self.m_CanUse then
		self:UseExpItem(self.m_GoodsID)
		self.StartUse = true

		rktTimer.SetTimer(self.ContinueUseCB, self.m_Inteval, -1, "PetExpUseItem:ContinueUse")
		self.m_FirstPointDown = false
	end
	
	if self.m_NeedShowGetGoods and self.m_HaveNum <= 0 then
		self.m_NeedShowGetGoods = false					--控制执行次数
		--数量不够，弹出获取物品界面
		if self.m_GoodsID ~= 0 then
			local subInfo = {
				bShowBtnType	= 2, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
			}
			UIManager.GoodsTooltipsWindow:SetGoodsInfo(self.m_GoodsID, subInfo )

			--发送关闭使用EXP物品界面
			rktEventEngine.FireExecute(EVENT_PET_CLOSEXPGOODS_WIDGET, SOURCE_TYPE_PET, 0)	
		end
	end
end

--按钮抬起
function PetExpUseItem:OnPointerUp( eventData )
	self.m_FirstPointDown = true
	if self.m_HaveNum <= 0 then
		self.m_NeedShowGetGoods = true
	end
	self.StartUse = false
	rktTimer.KillTimer(self.ContinueUseCB)

end

--使用物品,,    通知界面更新，发送使用请求,,    此为客户端模拟使用
function PetExpUseItem:UseExpItem(nGoodsID)
	if self.m_CanUse then
		GameHelp.PostServerRequest("RequestUseItemAddPetExp("..tostring(self.m_PetUID).. "," .. nGoodsID ..")")	
	end
	self.m_CanUse = false
end

--服务器回包， 使用物品了
function PetExpUseItem:OnUseExpItem()
	rktEventEngine.FireExecute(EVENT_PET_USEXPGOODS, SOURCE_TYPE_PET, 0, self.m_PetUID)	
	self.m_HaveNum = GameHelp:GetHeroPacketGoodsNum(self.m_GoodsID)
	self.m_CanUse = true
	self:UpdateRemainGoodsNum(self.m_HaveNum)
end

--开始连续使用物品
function PetExpUseItem:SetStartUse()
	self.StartUse = true
	rktTimer.KillTimer(self.StartUseCB)
end

--连续使用物品
function PetExpUseItem:ContinueUse()
	if self.StartUse then
		self:UseExpItem(self.m_GoodsID)
	end
end


--设置第几个， 索引
function PetExpUseItem:SetIndex(nIndex, nGoodsID, uid)
	self.m_Index = nIndex
	self.m_PetUID = uid
	
	--完成物品ID的缓存
	self.m_GoodsID = nGoodsID

	--设置背包中一共有多少个 物品
	self.m_HaveNum = self:GetGoodsNum(nGoodsID)
	
	if self.m_HaveNum <= 0 then
		self.m_NeedShowGetGoods = true
	end
	
	self:UpdateRemainGoodsNum(self.m_HaveNum)
	
	--初始化icon  和   品质
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, nGoodsID)
	if not schemeInfo then
		print(mName.."找不到物品配置，物品ID=", nGoodsID)
		return
	end
	
	local imagePath = AssetPath.TextureGUIPath..schemeInfo.lIconID1
	UIFunction.SetImageSprite( self.Controls.m_GoodsIcon , imagePath )
	local imageBgPath = AssetPath_GoodsColor[tonumber(schemeInfo.lBaseLevel)]
	UIFunction.SetImageSprite( self.Controls.m_GoodsQuality , imageBgPath )

	self.Controls.m_GoodsName.text = "<color=#" .. AssetPath_GoodsQualityColor[schemeInfo.lBaseLevel] .. ">" .. schemeInfo.szName .. "</color>"
	self.Controls.m_GoodsEffect.text = schemeInfo.szDesc
end

--更新剩余数量view
function PetExpUseItem:UpdateRemainGoodsNum(nNum)
	if self:isShow() then
		if nNum and nNum <= 0 then
			nNum = "<color=red>0</color>"
			self:SetHuoQuActive(true)
		else
			self:SetHuoQuActive(false)
		end
		
		self.Controls.m_RemainNum.text = nNum
	end
end

--获得物品数量
function PetExpUseItem:GetGoodsNum(nGoodsID)
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		uerror("packetPart is nil")
		return
	end
	
	local haveNum = packetPart:GetGoodNum(nGoodsID)
	return haveNum
end

function PetExpUseItem:SetHuoQuActive(nShow)
	if self:isShow() then
		self.Controls.m_HuoQu.gameObject:SetActive(nShow)
	end
end

return PetExpUseItem