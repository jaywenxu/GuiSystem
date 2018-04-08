------------------------------------------------------------
-- ForgeWindow 的子窗口,不要通过 UIManager 访问
-- 包裹栏宝石信息格子
------------------------------------------------------------

local CommonGoodCellClass = require( "GuiSystem.WindowList.CommonWindow.CommonGoodCell" )

local titleImagePath_Normal		= AssetPath.TextureGUIPath.."Strength/stronger_baoti_qianghua_1.png"
local titleImagePath_PCT		= AssetPath.TextureGUIPath.."Strength/stronger_baoti_fujiaqianghua_1.png"

local PackageGemInfoCell = UIControl:new
{
	windowName = "PackageGemInfoCell",
	m_CellInfo = {},
	--m_CallBackFunc = "",
	m_CallBack_OnCellClick = nil,
	m_select = nil,
	onItemCellSelected = "",
}

local this = PackageGemInfoCell   -- 方便书写
local zero = int64.new("0")

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function PackageGemInfoCell:Attach( obj )
	UIControl.Attach(self,obj)
	
	-- 注册点击函数
    self.callback_OnCellClick = function( on ) self:OnCellClick() end
    self.Controls.CellBtn = self.transform:GetComponent(typeof(Button))
	if self.Controls.CellBtn then
		self.Controls.CellBtn.onClick:AddListener( self.callback_OnCellClick  )
	end

	self.Controls.GoodCell = CommonGoodCellClass:new()
	self.Controls.GoodCell:Attach(self.Controls.m_GoodCell.gameObject)
	
	-- 注册Toggle事件
	self.callback_OnSelectChanged = function( on ) self:OnSelectChanged(on) end
    self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))
	if self.Controls.ItemToggle then
		self.Controls.ItemToggle.onValueChanged:AddListener( self.callback_OnSelectChanged  )
	end
    
	return self
end

-- 
function PackageGemInfoCell:OnCellClick()
	if not self.m_CallBack_OnCellClick then
		return
	end
	self.m_CallBack_OnCellClick(self.m_CellInfo)
end

function PackageGemInfoCell:SetCellClickCallBack(cb)
	self.m_CallBack_OnCellClick = cb
end

------------------------------------------------------------
-- 选中时候的回调
function PackageGemInfoCell:OnSelectChanged( on )
	self.m_select = on
	if nil ~= self.onItemCellSelected then
		self.onItemCellSelected( self , on )
	end
end

------------------------------------------------------------
function PackageGemInfoCell:SetItemCellSelectedCallback( cb )
	self.onItemCellSelected = cb
end

-- 
function PackageGemInfoCell:SetCellInfo(CellInfo,nMaxLv)
	if not CellInfo or type(CellInfo) ~= "table" then
		self:Hide()
		return
	end
	self.m_CellInfo = CellInfo
	self:Show()
	--self.Controls.GoodCell:SetLeechdomItemInfo(CellInfo.nGoodID)
	self.Controls.GoodCell:SetItemInfo(CellInfo.nGoodUID)
	
	local pGoodsInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, CellInfo.nGoodID)
	if not pGoodsInfo then
		self:Hide()
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
	
	local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)	-- 获取职业
	local pGemPropScheme = forgePart.m_SettingCfgCenter:GetGemProp( CellInfo.nGoodID, nVocation)
	if not pGemPropScheme then
		self:Hide()
		return
	end
	
	local nGemPropID = pGemPropScheme.nPropID
	local nGemPropNum = pGemPropScheme.nPropNum
	local lBaseLevel = pGoodsInfo.lBaseLevel
	self.Controls.m_GemName.text = GameHelp.GetLeechdomColorName(CellInfo.nGoodID)
	self.Controls.m_GemProp.text = GameHelp.PropertyName[nGemPropID].."<color=#ff7800>+"..nGemPropNum.."</color>"
	if CellInfo.TuiJian and nMaxLv == CellInfo.nGemLv then
		self.Controls.m_TuiJian.gameObject:SetActive(true)
	else
		self.Controls.m_TuiJian.gameObject:SetActive(false)
	end
end



function PackageGemInfoCell:SetTuiJian(nFlg)
	self.Controls.m_TuiJian.gameObject:SetActive(nFlg)
end

function PackageGemInfoCell:SetCellGoodID(nGoodID,nGemNumText)
	self.m_CellInfo.nGoodID = nGoodID
	self:Show()
	self.Controls.GoodCell:SetLeechdomItemInfo(nGoodID)
	self.Controls.GoodCell:SetCountText(nGemNumText)
	local pGoodsInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, nGoodID)
	if not pGoodsInfo then
		self:Hide()
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
	
	local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)	-- 获取职业
	local pGemPropScheme = forgePart.m_SettingCfgCenter:GetGemProp( nGoodID, nVocation)
	if not pGemPropScheme then
		self:Hide()
		return
	end
	
	local nGemPropID = pGemPropScheme.nPropID
	local nGemPropNum = pGemPropScheme.nPropNum
	
	self.Controls.m_GemName.text = GameHelp.GetLeechdomColorName(nGoodID)
	self.Controls.m_GemProp.text = GameHelp.PropertyName[nGemPropID].." <color=#FF7800FF>+"..nGemPropNum.."</color>"
end


function PackageGemInfoCell:SetFocus(on)
	self.Controls.ItemToggle.isOn = on
end

function PackageGemInfoCell:GetFocus()
	return self.Controls.ItemToggle.isOn
end


return this