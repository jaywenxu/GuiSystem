-------------------------------------------------------------------
-- @Author: XieXiaoMei
-- @Date:   2017-08-07 11:10:00
-- @Vers:	1.0
-- @Desc:	领地战据点信息界面
-------------------------------------------------------------------

local LigeOccupiesWdt = UIControl:new {
	windowName = "LigeOccupiesWdt",

	m_CellList = {}
}

-------------------------------------------------------------------
function LigeOccupiesWdt:Attach(obj)
	UIControl.Attach(self,obj)


	local controls =self.self.Controls
	for i=1, 3 do
		local cell = self.transform:Find("LigeOccupyCell" .. i)
		controls["cell"..i] = cell
	end

	controls.m_BasePnlBtn.onClick:AddListener(handler(self, self.OnBtnBasePnlClicked))
end

-------------------------------------------------------------------
function LigeOccupiesWdt:OnDestroy()
	UIControl.OnDestroy(self)

	self:DestroyCells()
end

-------------------------------------------------------------------
function LigeOccupiesWdt:Show()
	UIControl.Show(self)

	local warInfo = IGame.LigeanceEctype:GetWarInfo()
	for i, v in ipairs(warInfo) do
		self:SetCellData("cell"..i, v)
	end
end

-------------------------------------------------------
-- 设置元素数据
function LigeOccupiesWdt:SetCellData(cellTf, data)
	local ligeaceNameTxt = cellTf:Find("LigeaceName"):GetComponent(typeof(Text))
	ligeaceNameTxt.text = 1

	local occupyClanTxt = cellTf:Find("OccupyClan"):GetComponent(typeof(Text))
	occupyClanTxt.text = 2

	local takeFlagPeoTxt = cellTf:Find("TakeFlagPeople"):GetComponent(typeof(Text))
	takeFlagPeoTxt.text = 3
end

-------------------------------------------------------------------
function LigeOccupiesWdt:OnBtnBasePnlClicked()
	self:Hide()
end

-------------------------------------------------------------------

return LigeOccupiesWdt
