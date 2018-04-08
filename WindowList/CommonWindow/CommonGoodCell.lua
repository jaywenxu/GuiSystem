------------------------------------------------------------
-- 包裹格子,不要通过 UIManager 访问
-- 复用类 通用物品格子类
-- 请以下面格式来弄你的Cell ，或者用CommonGoodCell
--[[
CommonGoodCell
  MainBg
  NullEquipIcon
  Item
    QualityBg
	GoodIcoBg
  Select  选中标识图片
  BindIcon  绑定标志
  Count 数量
  PuttedOn "已装备"
  UpGrade 升级
  ForgeFull 打造已满
]]
------------------------------------------------------------

local CommonGoodCell = UIControl:new
{
    windowName = "CommonGoodCell" ,
	onItemCellSelected = nil  ,   --  选中回调
	onItemCellPointClick = nil,  -- 单击回调
	onItemCellPointDoubleClick = nil, --双击回调
	goodsUID = 0, -- 当前格子里的物品UID
	m_GoodID = 0, -- 当前格子里的物品UID
	m_select =false,
	m_UserData = nil,
	doubleClickTimer = nil,
	m_CanUpGrade = false,
}

local mName = "【包裹格子】，"
local zero = int64.new("0")
------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function CommonGoodCell:Attach( obj )
	UIControl.Attach(self,obj)
	if self.transform:Find("MainBg") then
		self.Controls.m_MainBgCtrl = self.transform:Find("MainBg")
		self.Controls.m_MainBg = self.transform:Find("MainBg"):GetComponent(typeof(Image))
	end
	if self.transform:Find("NullEquipIcon") then
        self.Controls.m_NullEquipCtrl = self.transform:Find("NullEquipIcon")
		self.Controls.m_NullEquipIcon = self.transform:Find("NullEquipIcon"):GetComponent(typeof(Image))
	end
	self.Controls.m_GoodIcoBg = self.transform:Find("Item/GoodIcoBg"):GetComponent(typeof(Image))
	self.Controls.m_QualityBg = self.transform:Find("Item/QualityBg"):GetComponent(typeof(Image))
	if self.transform:Find("BindIcon") then
		self.Controls.m_BindIcon = self.transform:Find("BindIcon"):GetComponent(typeof(Image))
	end
	if self.transform:Find("Count") then
		self.Controls.m_Count = self.transform:Find("Count"):GetComponent(typeof(Text))
	end
	
	self.Controls.m_Select = self.transform:Find("Select"):GetComponent(typeof(Image))
	if self.transform:Find("PuttedOn") then
		self.Controls.m_PuttedOn = self.transform:Find("PuttedOn"):GetComponent(typeof(Image))
	end
	if self.transform:Find("UpGrade") then
		self.Controls.m_UpGrade = self.transform:Find("UpGrade"):GetComponent(typeof(Image))
	end
	
	if self.transform:Find("ForgeFull") then
		self.Controls.m_ForgeFull = self.transform:Find("ForgeFull"):GetComponent(typeof(Image))
	end

	if self.transform:Find("BottomText") then
		self.Controls.m_BottomText = self.transform:Find("BottomText"):GetComponent(typeof(Text))
	end

	self:ChildSetActive("GoodIcoBg",false)
	self:ChildSetActive("QualityBg",false)
	self:ChildSetActive("BindIcon",false)
	self:ChildSetActive("Count",false)
	self:ChildSetActive("Select",false)
	self:ChildSetActive("PuttedOn",false)
	self:ChildSetActive("UpGrade",false)
	self:ChildSetActive("ForgeFull",false)
	
	-- 注册Toggle事件
    self.callback_OnSelectChanged = function( on ) self:OnSelectChanged(on) end
    self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))
    self.Controls.ItemToggle.onValueChanged:AddListener( self.callback_OnSelectChanged  )
	-- 注册点击事件
	self.OnClickCell = function (eventData) self:OnPointClickCell(eventData) end
	UIFunction.AddEventTriggerListener( self.Controls.m_MainBgCtrl, EventTriggerType.PointerClick, self.OnClickCell)
    -- 无装备时，点击响应函数
    UIFunction.AddEventTriggerListener( self.Controls.m_NullEquipCtrl, EventTriggerType.PointerClick, self.OnClickCell)
	
	self.goodsUID = 0
    return self
end

------------------------------------------------------------
function CommonGoodCell:OnPointClickCell( eventData)
	if eventData.clickCount == 2 then 
		self.doubleClickTimer = false
		if nil ~= self.onItemCellPointDoubleClick then 
			self.onItemCellPointDoubleClick(self)
		end
	else 
		self.doubleClickTimer = true
		rktTimer.SetTimer(function() self:onPointClick() end, 300, 1, "CommonGoodCell:OnPointClickCell")
	end
end

function CommonGoodCell:onPointClick()
	if self.doubleClickTimer then 
		if nil ~= self.onItemCellPointClick then 
			self.onItemCellPointClick(self)
		end
	end
end


function CommonGoodCell:SetItemCellPointerClickCallback(cb)
	self.onItemCellPointClick = cb
end

function CommonGoodCell:SetItemCellPointerDoubleClickCallback(cb)
	self.onItemCellPointDoubleClick = cb
end

------------------------------------------------------------
function CommonGoodCell:SetSelect( on )
    self.Controls.ItemToggle.isOn = on
end

------------------------------------------------------------
function CommonGoodCell:SetToggleGroup( toggleGroup )
    self.Controls.ItemToggle.group = toggleGroup
end

------------------------------------------------------------
function CommonGoodCell:SetUserData( UserData )
    self.m_UserData = UserData
end

------------------------------------------------------------
-- 设置子窗口显示状态
function CommonGoodCell:ChildSetActive( ChildName, ActiveFlg )
	if not self.Controls["m_"..ChildName] then
		return
	end
	self.Controls["m_"..ChildName].gameObject:SetActive(ActiveFlg)
end

------------------------------------------------------------
-- 选中时候的回调
function CommonGoodCell:OnSelectChanged( on )
	self.m_select = on
	if nil ~= self.onItemCellSelected then
		self.onItemCellSelected( self , on )
	end
end

------------------------------------------------------------
-- EquipID 为零时清空物品信息
function CommonGoodCell:SetEquipItemInfo(EquipID,nQuality,nProNum)
	if not EquipID or EquipID == 0 then
		self.Controls.m_GoodIcoBg.gameObject:SetActive(false)
		self.Controls.m_QualityBg.gameObject:SetActive(false)
		return
	end
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, EquipID)
	if not schemeInfo then
		uerror(mName.."找不到装备配置，装备ID=", EquipID)
		return
	end
	self.m_GoodID = EquipID
	   -- 头像图片
	local imagePath = AssetPath.TextureGUIPath..schemeInfo.IconIDNormal
	UIFunction.SetImageSprite( self.Controls.m_GoodIcoBg , imagePath )
	
	local imageBgPath = self:GetIconBgPath(nQuality, nProNum)
	UIFunction.SetImageSprite( self.Controls.m_QualityBg , imageBgPath )
	
	self.Controls.m_GoodIcoBg.gameObject:SetActive(true)
	self.Controls.m_QualityBg.gameObject:SetActive(true)
end

------------------------------------------------------------
-- GoodID 为零时清空物品信息
function CommonGoodCell:SetLeechdomItemInfo(GoodID)
	if not GoodID or GoodID == 0 then
		self.Controls.m_GoodIcoBg.gameObject:SetActive(false)
		self.Controls.m_QualityBg.gameObject:SetActive(false)
		return
	end
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, GoodID)
	if not schemeInfo then
		print(mName.."找不到物品配置，物品ID=", GoodID)
		return
	end
	self.m_GoodID = GoodID
	local imagePath = AssetPath.TextureGUIPath..schemeInfo.lIconID1
	UIFunction.SetImageSprite( self.Controls.m_GoodIcoBg , imagePath )
	local imageBgPath = AssetPath_GoodsColor[tonumber(schemeInfo.lBaseLevel)]
	UIFunction.SetImageSprite( self.Controls.m_QualityBg , imageBgPath )	
	self.Controls.m_GoodIcoBg.gameObject:SetActive(true)
	self.Controls.m_QualityBg.gameObject:SetActive(true)
end

------------------------------------------------------------
-- uidGoods 为零时清空物品信息
function CommonGoodCell:SetItemInfo(uidGoods)
	uidGoods = uidGoods or zero
	self.goodsUID = uidGoods
	local entity = IGame.EntityClient:Get(uidGoods)
	if entity and EntityClass:IsGoods(entity:GetEntityClass()) then
		local nGoodsID = entity:GetNumProp(GOODS_PROP_GOODSID)
		self.m_GoodID = nGoodsID
		if EntityClass:IsLeechdom(entity:GetEntityClass()) then
			local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, nGoodsID)
			if not schemeInfo then
				print(mName.."找不到物品配置，物品ID=", nGoodsID)
				return
			end

			local imagePath = AssetPath.TextureGUIPath..schemeInfo.lIconID1
			UIFunction.SetImageSprite( self.Controls.m_GoodIcoBg , imagePath )
			
			local imageBgPath = AssetPath_GoodsColor[tonumber(schemeInfo.lBaseLevel)]
			UIFunction.SetImageSprite( self.Controls.m_QualityBg , imageBgPath )
			
			self.Controls.m_GoodIcoBg.gameObject:SetActive(true)
			self.Controls.m_QualityBg.gameObject:SetActive(true)
			local totalNum = entity:GetNumProp(GOODS_PROP_QTY)
			local noBindNum = entity:GetNumProp(GOODS_PROP_NO_BIND_QTY)
			
			-- self.Controls.m_Count.text = totalNum.."（"..noBindNum.."）"
			self.Controls.m_Count.text = GetValuable(tonumber(totalNum) > 1, totalNum, "")
			self.Controls.m_Count.gameObject:SetActive(true)
			if lua_NumberAndTest(entity:GetNumProp(GOODS_PROP_BIND) , tGoods_BindFlag_Hold) then
				--self.Controls.m_BindIcon.gameObject:SetActive(true)
			else
				self.Controls.m_BindIcon.gameObject:SetActive(false)
			end
		else
			local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, nGoodsID)
			if not schemeInfo then
				print(mName.."找不到物品配置，物品ID=", nGoodsID)
				return
			end
			
			local nQuality  = entity:GetNumProp(EQUIP_PROP_QUALITY)
			local nAdditionalPropNum = entity:GetAdditionalPropNum()
	        
			
			-- 武学书
			if schemeInfo.GoodsSubClass == EQUIPMENT_SUBCLASS_BATTLEBOOK then
				local battleBookInfo = entity:GetBattleBookProp()
				if battleBookInfo then
					nQuality = battleBookInfo.quality or 1
				end
				
				nAdditionalPropNum = 0
				local battleBookScheme = IGame.rktScheme:GetSchemeInfo(BATTLE_BOOK_UPGRADE_CSV, cfgId, battleBookInfo.level)
				if battleBookScheme then
					for i,v in pairs(battleBookScheme.Property) do
						nAdditionalPropNum = nAdditionalPropNum + 1
					end
				end
			end
			
			local imagePath = AssetPath.TextureGUIPath .. schemeInfo.IconIDNormal
			local imageBgPath =  self:GetIconBgPath(nQuality, nAdditionalPropNum)
			
			UIFunction.SetImageSprite( self.Controls.m_QualityBg , imageBgPath )
			UIFunction.SetImageSprite( self.Controls.m_GoodIcoBg , imagePath )
			self.Controls.m_GoodIcoBg.gameObject:SetActive(true)
			self.Controls.m_QualityBg.gameObject:SetActive(true)
			local totalNum = entity:GetNumProp(GOODS_PROP_QTY)
			self.Controls.m_Count.text = GetValuable(tonumber(totalNum) > 1, totalNum, "")
			if lua_NumberAndTest(entity:GetNumProp(GOODS_PROP_BIND) , tGoods_BindFlag_Hold) then
				--self.Controls.m_BindIcon.gameObject:SetActive(true)
			else
				self.Controls.m_BindIcon.gameObject:SetActive(false)
			end
		end
	else
		self.m_GoodID = 0
		self.Controls.m_GoodIcoBg.sprite = nil
		self.Controls.m_GoodIcoBg.gameObject:SetActive(false)
		self.Controls.m_QualityBg.gameObject:SetActive(false)
		self.Controls.m_Count.text = ""
		self.Controls.m_Count.gameObject:SetActive(false)
		self.Controls.m_BindIcon.gameObject:SetActive(false)
	end
end

function CommonGoodCell:SetNullEquipBg(place)
	if AssetPath_NullEquipIcon[place] then
		UIFunction.SetImageSprite( self.Controls.m_NullEquipIcon , AssetPath_NullEquipIcon[place] )
		self.Controls.m_NullEquipIcon:SetNativeSize()
	end
end

function CommonGoodCell:SetNullEquipIconImg(ImagePath)
    local funcCallBack = function () self:SetNullEquipIcon_CallBack() end
	UIFunction.SetImageSprite( self.Controls.m_NullEquipIcon , ImagePath, funcCallBack)
    
    self:ChildSetActive("NullEquipIcon",true)
end

function CommonGoodCell:SetItemGoodIcon(ImagePath)
    UIFunction.SetImageSprite( self.Controls.m_GoodIcoBg , ImagePath )
	self.Controls.m_GoodIcoBg.gameObject:SetActive(true)
end

function CommonGoodCell:SetNullEquipIcon_CallBack()
    self.Controls.m_NullEquipIcon:SetNativeSize()
end

function CommonGoodCell:GetIconBgPath(nQuality, nAdditionalPropNum)
	if  nQuality == 2 then
	if nAdditionalPropNum <= 4 then 
		nAdditionalPropNum = 4
	else 
		nAdditionalPropNum = 5
	end
	elseif nQuality == 3 then 
		if nAdditionalPropNum <= 5 then 
			nAdditionalPropNum = 5
		else 
			nAdditionalPropNum = 6
		end
	elseif nQuality == 4 then
		if nAdditionalPropNum <= 6 then 
			nAdditionalPropNum = 6
		else 
			nAdditionalPropNum = 7
		end	 
	end
	
	if nQuality == 1 then 
		imageBgPath = AssetPath_EquipColor[nQuality]
	else 
		imageBgPath = AssetPath_EquipColor[nQuality.."_"..nAdditionalPropNum]
	end
	
	return imageBgPath
end

------------------------------------------------------------
function CommonGoodCell:SetItemCellSelectedCallback( cb )
	self.onItemCellSelected = cb
end

------------------------------------------------------------
function CommonGoodCell:OnRecycle()
	self.onItemCellSelected = nil
	if self.callback_OnSelectChanged then
		self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callback_OnSelectChanged )
	end
	self.callback_OnSelectChanged = nil
	self.goodsUID = 0
	self.m_GoodID = 0
	UIControl.OnRecycle(self)
end

------------------------------------------------------------
function CommonGoodCell:OnDestroy()
	self.onItemCellSelected = nil
	if self.callback_OnSelectChanged then
		self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callback_OnSelectChanged )
	end
	self.callback_OnSelectChanged = nil
	self.goodsUID = 0
	self.m_GoodID = 0
	UIControl.OnDestroy(self)
end

------------------------------------------------------------
function CommonGoodCell:GetGoodsUID()
	return self.goodsUID
end

------------------------------------------------------------
function CommonGoodCell:ClearGoodsInfo()
	self.Controls.m_GoodIcoBg.sprite = nil
	self.Controls.m_GoodIcoBg.gameObject:SetActive(false)
	self.Controls.m_QualityBg.gameObject:SetActive(false)
	self.Controls.m_Count.text = ""
	self.Controls.m_Count.gameObject:SetActive(false)
	self.Controls.m_BindIcon.gameObject:SetActive(false)
end

------------------------------------------------------------
function CommonGoodCell:SetPuttedOn(Flg)
	self.Controls.m_PuttedOn.gameObject:SetActive(Flg)
end

------------------------------------------------------------
function CommonGoodCell:SetBottomText(BottomText)
	self.Controls.m_BottomText.text = BottomText
end

------------------------------------------------------------
function CommonGoodCell:SetCountText(CountText)
	self.Controls.m_Count.text = CountText
end

------------------------------------------------------------
function CommonGoodCell:SetUpGradeFlg(UpGradeFlg)
	self.m_CanUpGrade = UpGradeFlg
	self:ChildSetActive("UpGrade",UpGradeFlg)
end


------------------------------------------------------------
return CommonGoodCell




