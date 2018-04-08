
-----------------------发色配置界面--------------------------

local HairColorItemClass = require("GuiSystem.WindowList.Shop.Dress.HairColorItem")
local HeroDisplayWidgetClass = require("GuiSystem.WindowList.Shop.Dress.HeroDisplayWidget")


local HairColorConfigWidget = UIControl:new {
	windowName = "HairColorConfigWidget",
	
	m_Index = 0,		--当前选中的发色索引
	m_ColorInt = 0, 	--当前选中发色十进制值
	
	m_HairColorItemTable = {},
	m_FirstColorLuaScript = nil,
	
	m_DefaultColorNum = 0,
	
	m_CacheIndex = 0,
	m_AppID = 0,					--当前外观ID
	m_FirstInit = true,
	
	m_AppIndex = 0,					--当前外观组的ID
	m_SubIndex = 0,					--当前子发饰组ID
	
	m_ConfirmState = 1,				--确认按钮状态， 1-创建发色， 2-获取材料
}

function HairColorConfigWidget:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.m_FirstInit = true
	
	self.HairColorSlider = self.Controls.m_HairColorSliderTrans:GetComponent(typeof(Slider))
	self.ColorIntensitySlider = self.Controls.m_ColorIntensitySliderTrans:GetComponent(typeof(Slider))
	self.SaturationSlider = self.Controls.m_SaturationColorSliderTrans:GetComponent(typeof(Slider))
	
	 UIFunction.AddEventTriggerListener(self.Controls.m_MaskCtl , EventTriggerType.PointerClick , function( eventData ) self:OnMaskClick(eventData) end )
	
	self.Controls.HairColorToggleGroup = self.Controls.m_ColorList:GetComponent(typeof(ToggleGroup))
	
	self.OnHairColorSelectedCB = function(nIndex,nColorNum,nColor) self:OnHairColorSelected(nIndex,nColorNum,nColor) end
	
	self.OnCreateColorConfirm = function() self:OnCreateColorConfirmCb() end
	
	--初始化Slider对应的值，和当前的发色匹配
	self:InitSliderValue()
	--控件事件注册
	self:RegisterEvent()
end

--重写父类Show方法，完成打开初始化操作
function HairColorConfigWidget:Show()
	UIControl.Show(self)
	self.FirstInit = true
	--删除，增加发色服务器返回事件订阅
	self.RefreshHairColorItem = function() self:InitView(self.m_AppIndex,self.m_SubIndex) end
	rktEventEngine.SubscribeExecute(EVENT_APPEAR_UPDATE_RAPPEAR, SOURCE_TYPE_APPEAR, 0, self.RefreshHairColorItem)
	
	self.ChangeHairColorCB = function(event,arg1,arg2,arg3,_nID, _nColorNum) self:RefreshHairColor(_nID, _nColorNum) end
	rktEventEngine.SubscribeExecute(EVENT_APPEAR_EQUIP_APPEAR, SOURCE_TYPE_APPEAR, 0, self.ChangeHairColorCB)
	
	self.Controls.m_BottomBG.gameObject:SetActive(false)
	self.ShowBottomBG = false

--	self:RefreshConfirmBtnState()
	
	self:InitSliderValue()
end

--重写父类影藏方法
function HairColorConfigWidget:Hide(destory)
	UIControl.Hide(self)
	
--[[	local heroAppInfo = IGame.AppearanceClient:GetHeroCurAppearInfo()
	local curRecord = IGame.AppearanceClient:GetHairRecordByIndex(self.m_AppIndex, self.m_SubIndex)
	if heroAppInfo.nHairID == curRecord.nAppearID then 
		
	end--]]
	rktEventEngine.UnSubscribeExecute(EVENT_APPEAR_UPDATE_RAPPEAR, SOURCE_TYPE_APPEAR, 0, self.RefreshHairColorItem)
end

function HairColorConfigWidget:OnDestroy()
	self.GradientCom = nil
	UIControl.OnDestroy(self)
end 


--界面初始化,控件值初始值设置
function HairColorConfigWidget:InitView(nIndex, nSubIndex)
	self.m_CacheIndex = 0
	self:InitHairColor(nIndex, nSubIndex)
end

function HairColorConfigWidget:RegisterEvent()
	--保存button点击事件
	self.callback_OnSaveBtnClick = function() self:OnSaveBtnClick() end
	self.Controls.m_SaveBtn.onClick:AddListener(self.callback_OnSaveBtnClick)
	
	--关闭button点击事件
	self.callback_OnCloseBtnClick = function() self:OnCloseBtnClick() end
	self.Controls.m_CloseBtn.onClick:AddListener(self.callback_OnCloseBtnClick)
	
	--自制发色button点击事件
	self.callback_OnConfigColorBtnClick = function() self:OnConfigColorBtnClick() end
	self.Controls.m_ConfigColorBtn.onClick:AddListener(self.callback_OnConfigColorBtnClick)
	
	--删除Btn点击回调
	self.callback_OnDeleteColorBtnClick = function() self:OnDeleteColorBtnClick() end
	self.Controls.m_DeleteColorBtn.onClick:AddListener(self.callback_OnDeleteColorBtnClick)
	
	--发色滑动条滑动事件
	self.callback_OnColorSliderChange	= function() self:OnHairColorChanged() end
	self.HairColorSlider.onValueChanged:AddListener(self.callback_OnColorSliderChange)
	
	--纯度滑动条滑动事件
	self.callback_OnSaturationSliderChange	= function() self:OnSaturationColorSliderChanged() end
	self.SaturationSlider.onValueChanged:AddListener(self.callback_OnSaturationSliderChange)
	
	--亮度滑动条滑动事件
	self.callback_OnColorIntensitySliderChange	= function() self:OnColorIntensityChanged() end
	self.ColorIntensitySlider.onValueChanged:AddListener(self.callback_OnColorIntensitySliderChange)
end

--刷新确认按钮状态
function HairColorConfigWidget:RefreshConfirmBtnState()
	if self:HaveEnoughGoods(2039,3) then
		--设置确认按钮状态信息
		self.Controls.m_ConfirmBtnText.text = "创建发色"
		self.m_ConfirmState = 1
	else
		self.Controls.m_ConfirmBtnText.text = "获取材料"
		self.m_ConfirmState = 2
	end
end

--初始化发色Item列表
function HairColorConfigWidget:InitHairColor(nIndex, nSubIndex)
	self.m_AppIndex = nIndex
	self.m_SubIndex = nSubIndex
	
	local scriptNum = table.getn(self.m_HairColorItemTable)
	if scriptNum > 0 then
		for i, data in pairs(self.m_HairColorItemTable) do
			data:Destroy()
		end
	end
	self.m_HairColorItemTable = {}
	
	local record = IGame.AppearanceClient:GetHairRecordByIndex(nIndex,nSubIndex)		--读取对应的表中数据
	self.m_AppID = record.nAppearID
	local defaultColorTable, customColorTable = IGame.AppearanceClient:GetHairColorTableByIndex(nIndex,nSubIndex)
	local allIntColorTable = IGame.AppearanceClient:GetAllHairColorNumber(nIndex,nSubIndex)
	local curInfoTable = IGame.AppearanceClient:GetHeroCurAppearInfo()
	
	local defautNum = table.getn(defaultColorTable)
	local customNum = table.getn(customColorTable)
	
	self.m_DefaultColorNum = defautNum
	local totalNum = defautNum + customNum 
	local loadedNum = 0
	for i = 1,totalNum,1 do						--测试用数据,从model中读取
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.HairColorItem ,
		function ( path , obj , ud )

			obj.transform:SetParent(self.Controls.m_ColorList, false)
			
			local item = HairColorItemClass:new({})
			item:Attach(obj)
			item:SetToggleGroup(self.Controls.HairColorToggleGroup)
--			item:SetIndex(i)
			item:SetSelectCallback(HairColorConfigWidget.OnHairColorSelected)
			
			
			--选中默认值
			--[[if curInfoTable.nColor == allIntColorTable[i] then
				item:SetFocus(true)
			end--]]
			
			local custom = true
			local color			
			
			if i <= defautNum then
				custom = false
				color = defaultColorTable[i]
			else
				if customNum > 0 then
					color = customColorTable[i - defautNum]
				end
			end
			self.m_CacheIndex = self.m_CacheIndex + 1
			
			local colorVec = Color:New()
			colorVec:FromHexadecimal(color)
			
			item:SetColorNum(allIntColorTable[i])
			item:InitState(i, false, colorVec, custom, self.OnHairColorSelectedCB)		--从model中获取的数据初始化 		TODO
			table.insert(self.m_HairColorItemTable,i,item)
			loadedNum = loadedNum + 1
			if loadedNum == totalNum then
				if not self.FirstInit then 
					local n = table.getn(self.m_HairColorItemTable)
					self.m_HairColorItemTable[n]:SetFocus(true)
				else
					self.m_HairColorItemTable[1]:SetFocus(true)
				end
				self:RefreshConfirmBtnState()
			end
		end , i , AssetLoadPriority.GuiNormal )
	end
	
	--[[if not self.FirstInit then 
		local n = table.getn(self.m_HairColorItemTable)
		self.m_HairColorItemTable[n]:SetFocus(true)
	else
		self.m_HairColorItemTable[1]:SetFocus(true)
	end
	self:RefreshConfirmBtnState()--]]
end

--选中发色回调
function HairColorConfigWidget:OnHairColorSelected(nIndex,nColorNum,nColor)
	self.m_Index = nIndex
	self.m_ColorInt = nColorNum
	local record = IGame.AppearanceClient:GetHairRecordByIndex(self.m_AppIndex, self.m_SubIndex)		--读取对应的表中数据
	local heroInfo = IGame.AppearanceClient:GetHeroCurAppearInfo()
	if record.nAppearID == heroInfo.nHairID then
		if not self.FirstInit then
		--发送修改发色请求
			IGame.AppearanceClient:EquipAppear(record.nAppearID,nColorNum)
		end
	else
		local color = Color:New()
		color:FromHexadecimal(nColorNum)
		local colorVec3 = Vector3.New(color.r,color.g,color.b)
		HeroDisplayWidgetClass:ChangeHairColor(colorVec3)
	end
	self.FirstInit = false
end

--刷新发色
function HairColorConfigWidget:RefreshHairColor(_nID,_nColorNum)
	local color = Color:New()
	color:FromHexadecimal(_nColorNum)
	local colorVec3 = Vector3.New(color.r,color.g,color.b)
	
	HeroDisplayWidgetClass:ChangeHairColor(colorVec3)	
end

--保存按钮点击回调
function HairColorConfigWidget:OnSaveBtnClick()
	if self.Controls.m_ColorList.childCount >= 6 then
		UIManager.TipsActorUnderWindow:AddSystemTips("暂定6个，不能再创建了哦")
		return 
	end
	
	if self.m_ConfirmState == 1 then 
		local data = {
			content = "是否消耗3个染色果创建发色?",
			confirmCallBack = self.OnCreateColorConfirm,
		}
		UIManager.ConfirmPopWindow:ShowDiglog(data)
	else
		local subInfo = {
			bShowBtnType	= 2, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
		}
        UIManager.GoodsTooltipsWindow:SetGoodsInfo(2039, subInfo )
	end
end

function HairColorConfigWidget:OnCreateColorConfirmCb()
	local allColorNumTable = IGame.AppearanceClient:GetAllHairColorNumber(self.m_AppIndex,self.m_SubIndex)
	
	if not self:HaveEnoughGoods(2039,3) then
		UIManager.TipsActorUnderWindow:AddSystemTips("彩果数量不足3个,无法创建")
		return 
	end
	
	--向服务器发送创建发色请求
	local Vec3 = Vector3.New(self.HairColorSlider.value,self.SaturationSlider.value, self.ColorIntensitySlider.value)
	local color =  Color.HSVToRGB(Vec3.x, Vec3.y, Vec3.z)
	local colorNum = color:ToHexadecimal()
	
	for	i,data in pairs(allColorNumTable) do
		if colorNum == data then
			UIManager.TipsActorUnderWindow:AddSystemTips("已有颜色不能重复创建！")
			return
		end
	end
	IGame.AppearanceClient:AddAppearColor(self.m_AppID, colorNum)
end

--判断背包是否有足够的物品
function HairColorConfigWidget:HaveEnoughGoods(nGoodsID,num)
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return false
	end	
	local packetPart = pHero:GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return false
	end

	local haveNum = packetPart:GetGoodNum(nGoodsID)
	
	if haveNum >= num then
		return true
	else
		return false
	end
end

--删除发色回调
function HairColorConfigWidget:DeleteColorCallBack()
	
end

--HSV色彩空间转换到RGB空间
function HairColorConfigWidget:HSVTORGB(nVec3)
	local color = Color.HSVToRGB(nVec3.x, nVec3.y, nVec3.z)
	return color
end

--关闭按钮点击回调
function HairColorConfigWidget:OnCloseBtnClick()
	self:Hide()

	--发送关闭事件
	rktEventEngine.FireExecute(EVENT_APPEAR_CLOSE_HAIRCONFIG, 0 , 0)--SOURCE_TYPE_APPEAR

	--如果当前的发型ID和玩家装备的ID不同就还原
	local heroInfo = IGame.AppearanceClient:GetHeroCurAppearInfo()
	local record = IGame.AppearanceClient:GetHairRecordByIndex(self.m_AppIndex,self.m_SubIndex)		--读取对应的表中数据
	if heroInfo.nHairID ~= record.nAppearID then
		local entityView = rkt.EntityView.GetEntityView(GUI_ENTITY_ID_DRESS)
		if not entityView then return end
		IGame.EntityFactory:SetPartMesh(entityView,EntityBodyPart.HairMesh,heroInfo.nHairID,true)
		local colorNum = heroInfo.nColor
		local color = Color:New()
		color:FromHexadecimal(colorNum)
		local colorVec3 = Vector3.New(color.r,color.g,color.b)
		HeroDisplayWidgetClass:ChangeHairColor(colorVec3)
	end
end

--自制发色点击回调
function HairColorConfigWidget:OnConfigColorBtnClick()
	local show = not self.ShowBottomBG
	self.Controls.m_BottomBG.gameObject:SetActive(show)
	self.ShowBottomBG = show
end

--删除按钮
function HairColorConfigWidget.OnDeleteColorBtnClick()
	if HairColorConfigWidget.m_Index <= HairColorConfigWidget.m_DefaultColorNum then
		UIManager.TipsActorUnderWindow:AddSystemTips("默认的不能删除哦！")
		return
	else
		local data = {
			content = "确认删除此发色?",
			confirmCallBack = HairColorConfigWidget.OnConfirmCb,
		}
		UIManager.ConfirmPopWindow:ShowDiglog(data)
	end
	
end


--删除发色时确认界面，确认按钮回调
function HairColorConfigWidget.OnConfirmCb()
	IGame.AppearanceClient:DelAppearColor(HairColorConfigWidget.m_AppID,HairColorConfigWidget.m_ColorInt)
end

--初始化滑动条值，和默认选取的发色匹配
function HairColorConfigWidget:InitSliderValue()
	self.SaturationSlider.value = 0.5
	self.ColorIntensitySlider.value = 0.5
	self.HairColorSlider.value = 0.5
end


--发色Slider改变回调
function HairColorConfigWidget:OnHairColorChanged()
	local vec3 = Vector3.New(self.HairColorSlider.value,self.SaturationSlider.value, self.ColorIntensitySlider.value)
	local Vec3SpriteColor = Vector3.New(self.HairColorSlider.value,1,1)
	self:SetSaturationSpriteColor(Vec3SpriteColor)
	
	local color = Color.HSVToRGB(self.HairColorSlider.value,self.SaturationSlider.value, self.ColorIntensitySlider.value)
	local colorVec3 = Vector3.New(color.r, color.g, color.b)
	HeroDisplayWidgetClass:ChangeHairColor(colorVec3)
end

--纯度改变回调
function HairColorConfigWidget:OnSaturationColorSliderChanged()
	local vec3 = Vector3.New(self.HairColorSlider.value,self.SaturationSlider.value, self.ColorIntensitySlider.value)
	local color = Color.HSVToRGB(self.HairColorSlider.value,self.SaturationSlider.value, self.ColorIntensitySlider.value)
		local colorVec3 = Vector3.New(color.r, color.g, color.b)
	HeroDisplayWidgetClass:ChangeHairColor(colorVec3)
end

--亮度改变回调
function HairColorConfigWidget:OnColorIntensityChanged()
	local vec3 = Vector3.New(self.HairColorSlider.value,self.SaturationSlider.value, self.ColorIntensitySlider.value)
	local color = Color.HSVToRGB(self.HairColorSlider.value,self.SaturationSlider.value, self.ColorIntensitySlider.value)
	local colorVec3 = Vector3.New(color.r, color.g, color.b)
	HeroDisplayWidgetClass:ChangeHairColor(colorVec3)
end

--设置纯度图片
function HairColorConfigWidget:SetSaturationSpriteColor(nVec3)
	if self.GradientCom == nil then
		self.GradientCom = self.Controls.m_SaturationColorBackGround.gameObject:GetComponent(typeof(UiEffect.GradientColor))
	end
	local nColor = Color.HSVToRGB(nVec3.x, nVec3.y, nVec3.z)
	if nColor then
		self.GradientCom.colorRight = nColor
	end
end


--点击BGMask回调，预留接口，等文档出来后根据需求 设定						TODO
function HairColorConfigWidget:OnMaskClick(eventData)
	--self:Hide()
	rkt.UIAndTextHelpTools.PassThroughPointerClickEvent( eventData )			--设置射线穿透，点击是否贯穿到下一个控件
end

return HairColorConfigWidget