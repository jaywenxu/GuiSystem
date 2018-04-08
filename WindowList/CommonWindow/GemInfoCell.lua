------------------------------------------------------------
-- ForgeWindow 的子窗口,不要通过 UIManager 访问
-- 包裹栏宝石信息格子
------------------------------------------------------------

local CommonGoodCellClass = require( "GuiSystem.WindowList.CommonWindow.CommonGoodCell" )

local titleImagePath_Normal		= AssetPath.TextureGUIPath.."Strength/stronger_baoti_qianghua_1.png"
local titleImagePath_PCT		= AssetPath.TextureGUIPath.."Strength/stronger_baoti_fujiaqianghua_1.png"

local GemInfoCell = UIControl:new
{
	windowName = "GemInfoCell",
	m_Seq = 0,
	m_CellInfo = {},
	--m_CallBackFunc = "",
	m_CallBack_OnCellClick = nil,
	m_select = nil,
	onItemCellSelected = "",
}

local this = GemInfoCell   -- 方便书写
local zero = int64.new("0")

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function GemInfoCell:Attach( obj )
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
function GemInfoCell:OnCellClick()
	if not self.m_CallBack_OnCellClick then
		return
	end
	self.m_CallBack_OnCellClick(self.m_CellInfo)
end

function GemInfoCell:SetCellClickCallBack(cb)
	self.m_CallBack_OnCellClick = cb
end

------------------------------------------------------------
-- 选中时候的回调
function GemInfoCell:OnSelectChanged( on )
	self.m_select = on
	if nil ~= self.onItemCellSelected and "" ~= self.onItemCellSelected then
		self.onItemCellSelected( self , on )
	end
end

------------------------------------------------------------
function GemInfoCell:SetItemCellSelectedCallback( cb )
	self.onItemCellSelected = cb
end

------------------------------------------------------------
function GemInfoCell:SetToggleGroup( toggleGroup )
    self.Controls.ItemToggle.group = toggleGroup
end

-- 
function GemInfoCell:SetCellInfo(CellInfo)
	--print("GemInfoCell:SetCellInfo -------- CellInfo \n"..tostringEx(CellInfo))
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
	
	self.Controls.m_GemName.text = GameHelp.GetLeechdomColorName(CellInfo.nGoodID)
	self.Controls.m_GemProp.text = GameHelp.PropertyName[nGemPropID].." <color=#FF7800FF>+"..nGemPropNum.."</color>"
    
    if CellInfo.TuiJian then
        self.Controls.m_TuiJianRedDot.gameObject:SetActive(true)
    else
        self.Controls.m_TuiJianRedDot.gameObject:SetActive(false)
    end
end

function GemInfoCell:SetCellGoodID(nGoodID,nGemNumText)
	if not nGoodID then
		self:Hide()
		return
	end
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

function GemInfoCell:SetCellSeq(Seq)
	self.m_Seq = Seq
end

------------------------------------------------------------
function GemInfoCell:OnRecycle()
	self.onItemCellSelected = nil
	self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callback_OnSelectChanged )
	self.Controls.GoodCell:OnRecycle()
	UIControl.OnRecycle(self)
end

------------------------------------------------------------
function GemInfoCell:OnDestroy()
	self.onItemCellSelected = nil
	if self.Controls.ItemToggle then
		self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callback_OnSelectChanged )
	end
	self.Controls.GoodCell:OnDestroy()
	UIControl.OnDestroy(self)
end

function GemInfoCell:SetFocus(on)
	self.Controls.ItemToggle.isOn = on
end

function GemInfoCell:GetFocus()
	return self.Controls.ItemToggle.isOn
end

function GemInfoCell:SetChildsText(ChildName,Txt)
	self.Controls["m_"..ChildName].transform.parent.gameObject:SetActive(not IsNilOrEmpty(Txt))
	self.Controls["m_"..ChildName].text = Txt
end

return this