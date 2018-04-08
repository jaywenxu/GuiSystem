-------------------------------------------------------------------
-- @Author: XieXiaoMei
-- @Date:   2017-05-26 13:05:00
-- @Vers:	1.0
-- @Desc:	自动吃药系统
-------------------------------------------------------------------

local MedicineWidget = UIControl:new
{
	windowName = "MedicineWidget",

	m_MedicineCells = {},
	m_BloodPoolCells = {},

	m_EventHandler = {},

	m_MediciningVal = 0,

	m_MedicCount = 0,
	
	m_BloodPoolDrug = {},
}

local this = MedicineWidget
local MedicineCell = require("GuiSystem.WindowList.Settings.MedicineCell")

------------------------------------------------------------------------------
function MedicineWidget:Attach( obj )
	UIControl.Attach(self, obj)
	
	local controls = self.Controls
	
	local medicinesSlider = controls.m_MedicineSlider:GetComponent(typeof(Slider))
	medicinesSlider.minValue = 1
	medicinesSlider.maxValue = 99
	medicinesSlider.onValueChanged:AddListener(handler(self, self.OnSldMedicineChanged))
	controls.medicinesSlider = medicinesSlider

	local bloodPoolSlider = controls.m_BloodPoolSlider:GetComponent(typeof(Slider))
	controls.bloodPoolSlider = bloodPoolSlider
	
	self:AddListener( self.unityBehaviour , "onEnable" , self.OnEnable , self )
	self:AddListener( self.unityBehaviour , "onDisable" , self.OnDisable , self )

	self:SubscribeExec()
	
	self.m_BloodPoolDrug = IGame.AutoSystemManager.m_AutoSystemUseDrag:GetBloodPoolDrugTable()

	self:RefreshUI()

	self:OnSldMedicineChanged(GetMedicineThreshold())
	self:SetFreezeTime()
end

------------------------------------------------------------------------------
function MedicineWidget:SubscribeExec()

	self.m_EventHandler[EVENT_SKEP_ADD_GOODS] = {srctype = SOURCE_TYPE_SKEP, handler = self.RefreshUI}
	self.m_EventHandler[EVENT_SKEP_REMOVE_GOODS] = {srctype = SOURCE_TYPE_SKEP, handler = self.RefreshUI}
	self.m_EventHandler[EVENT_ENTITY_UPDATEPROP] = {srctype = SOURCE_TYPE_PERSON, handler = self.InitBloodPoolSlider}

	for evtID, v in pairs(self.m_EventHandler) do
		rktEventEngine.SubscribeExecute(evtID, v.srctype, 0, v.handler, self)
	end
end

------------------------------------------------------------------------------
function MedicineWidget:UnsubscribeExec()
	for evtID, v in pairs(self.m_EventHandler) do
		rktEventEngine.UnSubscribeExecute(evtID, v.srctype, 0, v.handler, self)
	end
	self.m_EventHandler = {}
end

------------------------------------------------------------------------------
function MedicineWidget:OnDestroy()
	self:UnsubscribeExec()

	self:DestroyDrugCells("m_MedicineCells")
	self:DestroyDrugCells("m_BloodPoolCells")

	UIControl.OnDestroy(self)

	table_release(self)
end

------------------------------------------------------------------------------
function MedicineWidget:OnEnable()
	self:SubscribeExec()

	self:RefreshUI()
end

------------------------------------------------------------------------------
function MedicineWidget:OnDisable()
	self:UnsubscribeExec()
end

------------------------------------------------------------------------------
function MedicineWidget:RefreshUI()
	if not self:isShow() then
		return
	end

	self:InitMedicines()

	self:InitBloodPool()
end

------------------------------------------------------------------------------
-- 初始化药品栏
function MedicineWidget:InitMedicines()
	local controls = self.Controls
	
	local drugs = IGame.AutoSystemManager.m_AutoSystemUseDrag:GetAutoUseDrugTable()

	if self.m_MedicCount ~= #drugs then -- 药品表数量不同需重新创建药品及排序
		self:DestroyDrugCells("m_MedicineCells")
	end
	self.m_MedicCount = #drugs

	local new_drugs = {}
	for i, drug in ipairs(drugs) do
		drug.num = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET):GetGoodNum(drug.nGoodsID)
		table.insert(new_drugs, drug)
	end

	local parentTf = controls.m_MedicContent
	for i, drug in ipairs(new_drugs) do

		local extraData =
		{
			bIsMedicine = true,
			bRecommend = i == 1,
			uid = drug.uid,
			num = drug.num,
		}		
		
		local goodsID = drug.nGoodsID
		local cell = self.m_MedicineCells[goodsID]
		if cell then
			cell:RefreshNums(extraData)
		else
			self:CreateDrugCell(goodsID, parentTf, self.m_MedicineCells, extraData)
		end
	end
end

------------------------------------------------------------------------------
-- 设置药品进度值
function MedicineWidget:OnSldMedicineChanged(value)
	self.m_MediciningVal = value

	self.Controls.medicinesSlider.value = value
	self.Controls.m_MediPercentTxt.text = string.format("战斗状态下，血量低于%d%%时自动使用", value)
end

-- 设置冷却时间
function MedicineWidget:SetFreezeTime()
	local oneID = 0
	local drugs = IGame.AutoSystemManager.m_AutoSystemUseDrag:GetAutoUseDrugTable()
	for k, v in pairs(drugs) do
		if 0 == v.nSpecific then
			oneID = v.nGoodsID
		end
	end
	
	if 0 == oneID then
		return
	end
	
	local FreezeTime = 0
	local pFreezeScheme = IGame.rktScheme:GetSchemeInfo(FREEZE_CSV, 2, oneID)
	if pFreezeScheme then
		FreezeTime = math.floor(pFreezeScheme.Time / 1000)
	end
	
	self.Controls.m_FreezeTxt.text = "药品冷却时间为" .. FreezeTime .. "秒"
end

------------------------------------------------------------------------------
-- 初始化血池 
function MedicineWidget:InitBloodPool()

	local controls = self.Controls

	self:InitBloodPoolSlider()

	local drugsInfo = self.m_BloodPoolDrug

	local new_drugs = {}
	for i, drug in ipairs(drugsInfo) do
		
		local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
		drug.num = packetPart:GetGoodNum(drug.nGoodsID) 
		drug.uid = packetPart:GetGoodsUIDByGoodsID(drug.nGoodsID)
		table.insert(new_drugs, drug)
	end

	table.sort(new_drugs, 
		function (a, b)
			if a.num > 0 and b.num > 0 then
				return a.nHP > b.nHP 
			end
			
			if a.num == 0 and b.num == 0 then
				return a.nHP > b.nHP 
			end
			
			return a.num > b.num
		end)
		
	-- 判断列表顺序是否改变了，如果改变重载UI
	local count = #new_drugs
	for i = 1, count do
		if new_drugs[i].nGoodsID ~= drugsInfo[i].nGoodsID then
			self:DestroyDrugCells("m_BloodPoolCells")
			self.m_BloodPoolDrug = new_drugs
			break
		end
	end

	local parentTf = controls.m_BloPoContent
	for i, drug in ipairs(new_drugs) do
		local extraData = 
		{
			bIsMedicine = false,
			uid = drug.uid,
			num = drug.num,
		}

		local goodsID = drug.nGoodsID
		local cell = self.m_BloodPoolCells[goodsID]
		if cell then
			cell:RefreshNums(extraData)
		else
			self:CreateDrugCell(goodsID, parentTf, self.m_BloodPoolCells, extraData)
		end
	end
end


------------------------------------------------------------------------------
-- 初始化血池进度
function MedicineWidget:InitBloodPoolSlider()
	if not self:isShow() then
		return
	end

	local controls = self.Controls

	local value, maxVal = IGame.AutoSystemManager.m_AutoSystemUseDrag:GetBloodPoolHP()
	controls.bloodPoolSlider.maxValue = maxVal
	controls.bloodPoolSlider.minValue = 0
	
	controls.bloodPoolSlider.value = value
	
	controls.m_BloodPercentTxt.text = string.format("%d/%d", value, maxVal)
end


------------------------------------------------------------------------------
-- 创建药品元素 
function MedicineWidget:CreateDrugCell(goodsID,parentTf, cellList, extraData)
	rkt.GResources.FetchGameObjectAsync( GuiAssetList.MedicineCell , 
   	function( path , obj , ud )
		if nil ~= obj then
			obj.transform:SetParent(parentTf, false)
		
			local cell = MedicineCell:new({})
			cell:Attach(obj)

			local goodsCfg = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, goodsID)
			cell:SetData(goodsCfg, extraData)
			
			cellList[goodsID] = cell
		end
	end, nil, AssetLoadPriority.GuiNormal )
end

------------------------------------------------------------------------------
-- 销毁药品元素表
function MedicineWidget:DestroyDrugCells(cellListName)
	for i, v in pairs(self[cellListName]) do
		v:RecycleItem() --回收
	end
	self[cellListName] = {}
end

------------------------------------------------------------------------------
-- 保存自动吃药阈值
function MedicineWidget:SaveMedicSettings()
	SetMedicineThreshold(self.m_MediciningVal)
end

------------------------------------------------------------------------------

return MedicineWidget

