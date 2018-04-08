------------------------------------------------------------
-- ForgeWindow 的子窗口,不要通过 UIManager 访问
-- 包裹栏宝石信息格子
------------------------------------------------------------

local CommonGoodCellClass = require( "GuiSystem.WindowList.CommonWindow.CommonGoodCell" )

local CellState_Suo		= AssetPath.TextureGUIPath.."Common_frame/Common_suo_1.png"
local CellState_Kong		= AssetPath.TextureGUIPath.."Common_frame/Common_jiahao_1.png"

local ForgeGemInfoCell = UIControl:new
{
	windowName = "ForgeGemInfoCell",
	onItemCellSelected = nil,   -- 选中回调
	m_CellInfo = {},
	m_index = 1,
    m_select = false,           -- 选中状态
}

local this = ForgeGemInfoCell   -- 方便书写
local zero = int64.new("0")
local KONG_CELL_TEXT = "点击右侧宝石进行镶嵌"
------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function ForgeGemInfoCell:Attach( obj )
	UIControl.Attach(self,obj)
	
	-- 注册Toggle选中函数
    self.callback_OnSelectChanged = function( on ) self:OnSelectChanged(on) end
    self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))
    self.Controls.ItemToggle.onValueChanged:AddListener( self.callback_OnSelectChanged  )
	
	-- 注册点击函数
    self.callback_OnRemoveBtnClick = function( on ) self:OnRemoveBtnClick() end
    self.Controls.m_RemoveBtn.onClick:AddListener( self.callback_OnRemoveBtnClick  )
	
	
	self.Controls.GoodCell = CommonGoodCellClass:new()
	self.Controls.GoodCell:Attach(self.Controls.m_GoodCell.gameObject)
    self.callback_OnGoodCellClick = function( GoodCell ) self:OnGoodCellClick(GoodCell) end
	self.Controls.GoodCell:SetItemCellSelectedCallback(self.callback_OnGoodCellClick)
	
	self:CellInit()
	
	return self
end

function ForgeGemInfoCell:CellInit()
	self.Controls.GoodCell:ChildSetActive( "MainBg", false )
	self.Controls.GoodCell:ChildSetActive("GoodIcoBg",false)
	self.Controls.GoodCell:ChildSetActive("QualityBg",false)
	self.Controls.GoodCell:SetUpGradeFlg(false)
	self.Controls.GoodCell:SetNullEquipIconImg(CellState_Suo)
	self.Controls.m_GemName.gameObject:SetActive(false)
	self.Controls.m_GemProp.gameObject:SetActive(false)
	self.Controls.m_RemoveBtn.gameObject:SetActive(false)
	self.Controls.m_DesText.gameObject:SetActive(true)
	self.Controls.m_DesText.text = KONG_CELL_TEXT
end

------------------------------------------------------------
function ForgeGemInfoCell:SetItemCellSelectedCallback( cb )
	self.onItemCellSelected = cb
end

function ForgeGemInfoCell:OnGoodCellClick(GoodCell)
	if not GoodCell or not GoodCell.m_CanUpGrade then
		return
	end
	local nGoodID = GoodCell.m_GoodID
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	local forgePart = GetHero():GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end

	local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)	-- 获取职业
	local pGemPropScheme = forgePart.m_SettingCfgCenter:GetGemProp( nGoodID, nVocation)
	if not pGemPropScheme then
		self:CellInit()
		return
	end
	local pNextGemPropScheme = forgePart.m_SettingCfgCenter:GetGemProp( nGoodID+1, nVocation)
	if not pNextGemPropScheme then
		return
	end
	local nSetGemLv = pGemPropScheme.nGemLv or 0
	local nNeedNum = 1
	if nSetGemLv == 1 then
		nNeedNum = 2
	end
	local UpFlg,ConsumeInfo = forgePart:GetConsumeDiamondInfo(nGoodID,nNeedNum)
	if UpFlg ~= true then
		return
	end
	local InfoTable = {}
	InfoTable.NowLv = "当前："..pGemPropScheme.nGemLv.."级"
	InfoTable.NextLv = "下一级："..(pGemPropScheme.nGemLv+1).."级"
	InfoTable.NowProp = GameHelp.PropertyName[pGemPropScheme.nPropID].."+"..pGemPropScheme.nPropNum
	InfoTable.NextProp = GameHelp.PropertyName[pNextGemPropScheme.nPropID].."+"..pNextGemPropScheme.nPropNum
	InfoTable.Text = "自动将背包宝石合成"..nNeedNum.."颗"..pGemPropScheme.nGemLv.."级宝石"
--[[	local LableUp = ""
	LableUp = LableUp..pGemPropScheme.nGemLv.."级："..GameHelp.PropertyName[pGemPropScheme.nPropID].."+"..pGemPropScheme.nPropNum
	LableUp = LableUp.."    "..pNextGemPropScheme.nGemLv.."级："..GameHelp.PropertyName[pNextGemPropScheme.nPropID].."+"..pNextGemPropScheme.nPropNum
--]]	
--[[	local LableBottom = ""
	for i=1,table_count(ConsumeInfo) do
		local GemInfo = ConsumeInfo[i]
		if GemInfo then
			local nGemID = GemInfo.nGoodID
			local nKouNum = GemInfo.nKouNum
			local pGoodsInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, nGemID)
			if pGoodsInfo then
				local szShowGemInfo = string.format("%-17s", (pGoodsInfo.szName or "未知名字"))
				LableBottom = LableBottom..szShowGemInfo.."×"..nKouNum
				LableBottom = string.format("%-23s",LableBottom)
				if math.fmod(i,3) == 0 then
					LableBottom = LableBottom.."\n"
				else
					LableBottom = LableBottom.." "
				end
			end
		end
	end--]]

	local callback_func = function() 
			self:OnUpGradeGem(GoodCell)
		end
	UIManager.ExtendedConfirmWindow:ShowWindow(InfoTable,callback_func)
end
function ForgeGemInfoCell:OnUpGradeGem(GoodCell)
---	cLog("OnUpGradeGem"..self.m_index,"red")
	if not GoodCell or not GoodCell.m_CanUpGrade then
		return
	end
	local nGoodID = GoodCell.m_GoodID
	local pHero = GetHero()
	if pHero == nil then
		return
	end
	
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	local forgePart = GetHero():GetEntityPart(ENTITYPART_PERSON_FORGE)
	if not forgePart then
		return
	end

	local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)	-- 获取职业
	local pGemPropScheme = forgePart.m_SettingCfgCenter:GetGemProp( nGoodID, nVocation)
	if not pGemPropScheme then
		self:CellInit()
		return
	end
	local nSetGemLv = pGemPropScheme.nGemLv or 0
	local nNeedNum = 1
	if nSetGemLv == 1 then
		nNeedNum = 2
	end
	local UpFlg,ConsumeInfo = forgePart:GetConsumeDiamondInfo(nGoodID,nNeedNum)
	if UpFlg ~= true then
		return
	end
	local CurEquipCell = UIManager.ForgeWindow:GetSelsctEquipPlace()
	GameHelp.PostServerRequest("RequestForgeUpGradeGem("..CurEquipCell..","..tostringEx(self.m_index - 1)..","..tostringEx(ConsumeInfo)..")")
end

function ForgeGemInfoCell:OnRemoveBtnClick()
	local CurEquipCell = UIManager.ForgeWindow:GetSelsctEquipPlace()
	GameHelp.PostServerRequest("RequestForgeOutSetGem("..CurEquipCell..","..tostringEx(self.m_index - 1)..")")
end

------------------------------------------------------------
function ForgeGemInfoCell:OnRecycle()
	self.onItemCellSelected = nil
	self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callback_OnSelectChanged )
	self.goodsUID = 0
	self.m_GoodID = 0
end

------------------------------------------------------------
function ForgeGemInfoCell:OnDestroy()
	self.onItemCellSelected = nil
	self.Controls.ItemToggle.onValueChanged:RemoveListener( self.callback_OnSelectChanged )
	self.goodsUID = 0
	self.m_GoodID = 0
	UIControl.OnDestroy(self)
end

-- 选中时候的回调
function ForgeGemInfoCell:OnSelectChanged( on )
	self.m_select = on
	if nil ~= self.onItemCellSelected then
		self.onItemCellSelected( self , on )
	end
end

function ForgeGemInfoCell:SetSelect(on)
	self.Controls.ItemToggle.isOn = on
end

function ForgeGemInfoCell:IsSelected()
    return self.m_select
end
------------------------------------------------------------
function ForgeGemInfoCell:SetItemCellSelectedCallback( cb )
	self.onItemCellSelected = cb
end

function ForgeGemInfoCell:SetInsex(index)
	self.m_index = index
end

function ForgeGemInfoCell:SetGem(nGemID)
	if not nGemID then
		self:CellInit()
		return
	end
	
	if nGemID == 0 then
		self:CellInit()
		self.Controls.GoodCell:SetNullEquipIconImg(CellState_Kong)
		return
	end
	
	local pGoodsInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, nGemID)
	if not pGoodsInfo then
		self:CellInit()
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
	local pGemPropScheme = forgePart.m_SettingCfgCenter:GetGemProp( nGemID, nVocation)
	if not pGemPropScheme then
		self:CellInit()
		return
	end
	
	local nGemPropID = pGemPropScheme.nPropID
	local nGemPropNum = pGemPropScheme.nPropNum
	
	self.Controls.m_GemName.text = GameHelp.GetLeechdomColorName(nGemID)
	self.Controls.m_GemProp.text = GameHelp.PropertyName[nGemPropID] .. " <color=#FF7800>+"..nGemPropNum.."</color>"
	self.Controls.m_GemName.gameObject:SetActive(true)
	self.Controls.m_GemProp.gameObject:SetActive(true)
	self.Controls.m_RemoveBtn.gameObject:SetActive(true)
	self.Controls.m_DesText.gameObject:SetActive(false)
	self.Controls.GoodCell:SetLeechdomItemInfo(nGemID)
end

function ForgeGemInfoCell:SetUpGradeFlg(UpGradeFlg)
	if UpGradeFlg.UpFlg == true then
		self.Controls.GoodCell:SetUpGradeFlg(true)
	else
		self.Controls.GoodCell:SetUpGradeFlg(false)
	end
	
	if UpGradeFlg.CanSetFlg == true then
		self.Controls.m_RedDot.gameObject:SetActive(true)
	else
		self.Controls.m_RedDot.gameObject:SetActive(false)
	end
end


return this