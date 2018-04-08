------------------------------------------------------------
-- ForgeWindow 的子窗口,不要通过 UIManager 访问
-- 装备子窗口
------------------------------------------------------------

local CommonGoodCellClass = require( "GuiSystem.WindowList.CommonWindow.CommonGoodCell" )

local titleImagePath_Normal		= AssetPath.TextureGUIPath.."Strength/stronger_baoti_qianghua_1.png"
local titleImagePath_PCT		= AssetPath.TextureGUIPath.."Strength/stronger_baoti_fujiaqianghua_1.png"
local GamKongBG		= AssetPath.TextureGUIPath.."Common_Frame/Common_kongge.png"
local GamHaveBG		= AssetPath.TextureGUIPath.."CommonTips/Tips_icon_2.png"
local EquipCellWidget = UIControl:new
{
	windowName = "EquipCellWidget",
	m_EquipUID = nil,
	m_Index = nil,
	m_CallBack_OnCellClick = nil,
	onItemCellSelected = "",
}

local this = EquipCellWidget   -- 方便书写
local zero = int64.new("0")

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function EquipCellWidget:Attach( obj )
	UIControl.Attach(self,obj)
	
	-- 注册点击函数
    self.callback_OnCellClick = function( on ) self:OnCellClick() end
    self.Controls.CellBtn = self.transform:GetComponent(typeof(Button))
	if self.Controls.CellBtn then
		self.Controls.CellBtn.onClick:AddListener( self.callback_OnCellClick  )
	end

	self.Controls.GoodCell = CommonGoodCellClass:new()
	self.Controls.GoodCell:Attach(self.Controls.m_GoodCell.gameObject)
	for i=1,6 do
		self.Controls["m_GamBG"..(i)] = self.transform:Find("BG".."/Cell ("..tostring(i)..")")
		self.Controls["m_GamBGImg"..(i)] = self.Controls["m_GamBG"..(i)]:GetComponent(typeof(Image))
		self.Controls["m_GamImg"..(i)] = self.transform:Find("BG".."/Cell ("..tostring(i)..")/image"):GetComponent(typeof(Image))
	end
	-- 注册Toggle事件
	self.callback_OnSelectChanged = function( on ) self:OnSelectChanged(on) end
    self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))
	if self.Controls.ItemToggle then
		self.Controls.ItemToggle.onValueChanged:AddListener( self.callback_OnSelectChanged  )
	end
    
	return self
end

-- 
function EquipCellWidget:OnCellClick()
	if not self.m_CallBack_OnCellClick then
		return
	end
	self.m_CallBack_OnCellClick(self)
end

function EquipCellWidget:SetCellClickCallBack(cb)
	self.m_CallBack_OnCellClick = cb
end

------------------------------------------------------------
-- 选中时候的回调
function EquipCellWidget:OnSelectChanged( on )
	if nil ~= self.onItemCellSelected then
		self.onItemCellSelected( self , on )
	end
end

------------------------------------------------------------
function EquipCellWidget:SetItemCellSelectedCallback( cb )
	self.onItemCellSelected = cb
end

function EquipCellWidget:SetFocus(on)
	self.Controls.ItemToggle.isOn = on
end

function EquipCellWidget:GetFocus()
	return self.Controls.ItemToggle.isOn
end

function EquipCellWidget:SetUID(EquipUID,index)
	
	if not EquipUID or EquipUID == 0 or EquipUID == zero then
		self:Hide()
		return
	end
	self.m_EquipUID = EquipUID
	self.Controls.GoodCell:SetItemInfo(EquipUID)
	local entity = IGame.EntityClient:Get(EquipUID)
	if not entity then
		return
	end
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(EQUIP_CSV, entity:GetNumProp(GOODS_PROP_GOODSID))
	if not schemeInfo then
		return
	end
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end
	local HoleProp = forgePart:GetHoleProp(index)
	if not HoleProp then
		return
	end
	local tGemInfo = HoleProp.GemInfo
	local ForgeType = UIManager.ForgeWindow.m_CurForgeType
	local EquipColor = GameHelp.GetEquipNameColor(entity:GetNumProp(EQUIP_PROP_QUALITY), entity:GetAdditionalPropNum())
	local EquipName = schemeInfo.szName
	local SmeltLv = ""
	if ForgeType == 1 then	-- 强化
		local nType = UIManager.ForgeWindow.ForgeSmeltWidget.m_CurSmeltType
		if nType == 1 and HoleProp.bySmeltLv > 0 then
			SmeltLv = "+"..(HoleProp.bySmeltLv)
		elseif HoleProp.byPCTSmeltLv > 0 then
			SmeltLv = "附+"..(HoleProp.byPCTSmeltLv)
		end
	end
	local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)	-- 获取职业
	self.Controls.m_EquipName.text = "<color=#"..EquipColor..">"..EquipName.."  "..SmeltLv.."</color>" 
	if ForgeType == 2 then
		self.Controls.m_BG.gameObject:SetActive(true)
		self.Controls.m_EquipProp.gameObject:SetActive(false)
		for i=1,6 do
			local GemPlaceScheme = IGame.rktScheme:GetSchemeInfo(EQUIPSETTING_CSV , nVocation, index, i-1)
								or IGame.rktScheme:GetSchemeInfo(EQUIPSETTING_CSV , 10000, index, i-1)
			
			local nNeedHeroLv = GemPlaceScheme.nHeroLV or 0
			local HeroLevel = GameHelp:GetHeroLevel()
			if tGemInfo and tGemInfo[i] and tGemInfo[i].nGemID == 0 then
				if nNeedHeroLv > HeroLevel then
					self.Controls["m_GamBG"..(i)].gameObject:SetActive(false)
				else
					self.Controls["m_GamBG"..(i)].gameObject:SetActive(true)
					self.Controls["m_GamImg"..(i)].gameObject:SetActive(false)
					UIFunction.SetImageSprite( self.Controls["m_GamBGImg"..(i)] , GamKongBG )
				end
				--UIFunction.SetImageSprite( self.Controls["m_GamImg"..(i)] , GamKongBG )
			else
				local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, tGemInfo[i].nGemID)
				if not schemeInfo then
					print(mName.."找不到物品配置，物品ID=", tGemInfo[i].nGemID)
					return
				end

				local imagePath = AssetPath.TextureGUIPath..schemeInfo.lIconID1
				UIFunction.SetImageSprite( self.Controls["m_GamImg"..(i)] , imagePath )
				
				local imageBgPath = AssetPath_GoodsColor[tonumber(schemeInfo.lBaseLevel)]
				UIFunction.SetImageSprite( self.Controls["m_GamBGImg"..(i)] , imageBgPath )
				self.Controls["m_GamBG"..(i)].gameObject:SetActive(true)
				self.Controls["m_GamImg"..(i)].gameObject:SetActive(true)
			end
		end
	else
		self.Controls.m_BG.gameObject:SetActive(false)
		self.Controls.m_EquipProp.gameObject:SetActive(true)
		local equipScore = entity:ComputeEquipScore()
		local placeScore = math.floor(equipScore/10)
		self.Controls.m_EquipProp.text = "评分："..(placeScore)
	end
	
end

function EquipCellWidget:SetRedDotState(State)
	self.Controls.m_RedDot.gameObject:SetActive(State)
end

function EquipCellWidget:ChildSetActive( ChildName, ActiveFlg )
	self.Controls.GoodCell:ChildSetActive( ChildName, ActiveFlg )
end


return this