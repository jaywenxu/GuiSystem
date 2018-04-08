--CommonConsumeGoodWidget.lua----------------------------------------------------------
-- 包裹格子,不要通过 UIManager 访问
-- 复用类 通用物品格子类
------------------------------------------------------------
local CommonGoodCellClass = require( "GuiSystem.WindowList.CommonWindow.CommonGoodCell" )

local CommonConsumeGoodWidget = UIControl:new
{
    windowName = "CommonConsumeGoodWidget" ,
	m_GoodID = nil,			-- 物品ID
	m_ConsumeNum = nil,		-- 消耗数量
	m_ConsumeEnough = false,
}

local mName = "【消耗物品】，"
local zero = int64.new("0")
------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function CommonConsumeGoodWidget:Attach( obj )
	UIControl.Attach(self,obj)
	self.CommonGoodCell = CommonGoodCellClass:new()
	self.CommonGoodCell:Attach(self.Controls.m_CommonGoodCell.gameObject)
	--Add 按钮
    self.Controls.m_AddGoodBtn.onClick:AddListener(function() self:OnAddGoodBtnClick() end)
    return self
end

-- Add 按钮
function CommonConsumeGoodWidget:OnAddGoodBtnClick()
	local subInfo = {
		bShowBtnType	= 2, 	--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
	}
    UIManager.GoodsTooltipsWindow:SetGoodsInfo(self.m_GoodID,subInfo)
end

-- 设置物品ID
function CommonConsumeGoodWidget:SetGoodID(GoodID,ConsumeNum)
	if not GoodID or not ConsumeNum then
		return
	end
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, GoodID)
	if not schemeInfo then
		print("找不到物品配置，物品ID=", GoodID)
		return
	end
	self.m_GoodID = GoodID
	self.m_ConsumeNum = ConsumeNum
	self.CommonGoodCell:SetLeechdomItemInfo(GoodID)
	self.Controls.m_StuffName.text = GameHelp.GetLeechdomColorName(GoodID)
	local GoodNum = packetPart:GetGoodNum(GoodID) or 0
	if GoodNum >= ConsumeNum then
		self.m_ConsumeEnough = true
		self.Controls.m_StuffNum.text = GoodNum .."/"..ConsumeNum
		self.Controls.m_AddGoodBtn.gameObject:SetActive(false)
	else
		self.m_ConsumeEnough = false
		self.Controls.m_StuffNum.text = "<color=red>"..GoodNum.."</color>" .."/"..ConsumeNum
		self.Controls.m_AddGoodBtn.gameObject:SetActive(true)
	end
end



------------------------------------------------------------
return CommonConsumeGoodWidget




