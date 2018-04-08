
local MaterialGoodsInfo = UIControl:new
{
	windowName 	= "MaterialGoodsInfo",
	m_goodsId   = 0,
}
local TypeName = {"合成","分解"}
local this = MaterialGoodsInfo
local zero = int64.new("0")

function MaterialGoodsInfo:Attach(obj)
	UIControl.Attach(self, obj)
	
	self.callback_OnInputBtnClick = function() self:OnInputBtnClick() end
	self.Controls.m_InputButton.onClick:AddListener(self.callback_OnInputBtnClick)
	
	self.callback_OnSubBtnClick = function() self:OnSubBtnClick() end
	self.Controls.m_SubBtn.onClick:AddListener(self.callback_OnSubBtnClick) 
	
	self.callback_OnPlusBtnClick = function() self:OnPlusBtnClick() end
	self.Controls.m_PlusBtn.onClick:AddListener(self.callback_OnPlusBtnClick)
	
	self.callback_OnMaxBtnClick = function() self:OnMaxBtnClick() end
	self.Controls.m_MaxBtn.onClick:AddListener(self.callback_OnMaxBtnClick) 
	
    self.callback_OnComposeBtnClick = function() self:OnComposeBtnClick() end
	self.Controls.m_ComposeBtn.onClick:AddListener(self.callback_OnComposeBtnClick)
	
    self.callback_OnGrayGetBtnClick = function() self:OnGrayGetBtnClick() end
	self.Controls.m_GrayGetBtn.onClick:AddListener(self.callback_OnGrayGetBtnClick)
	
	self.callback_UpdateNum = function(num) self:UpdateNum(num) end
	
end

-------------------------------------------------------------------
-- 清空
-------------------------------------------------------------------
function MaterialGoodsInfo:Clean()		
	self.Controls.m_MaterialGoodsName.text = ""
	self.Controls.m_MaterialNum.text = ""
	self.Controls.m_TargetGoodsName.text = ""
	
end

-------------------------------------------------------------------
-- 设置物品说明区
-- @param icon : 当前选中物品icon
-- @param index :
-- @param goodsName : 当前选中物品的名称
-- @param goodsDesc : 当前选中物品的描述
-------------------------------------------------------------------
function MaterialGoodsInfo:UpdateMaterialGoodsInfo(itemIndex)

	-- 先清除数据
	self:Clean()
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart or not packetPart:IsLoad() then
		return
	end
	
	local nType = UIManager.MaterialComposeWindow:GetType()
	self.Controls.m_HeChengName.gameObject:SetActive(nType == 1) 
	self.Controls.m_FenJieName.gameObject:SetActive(not (nType == 1) )
	self.Controls.m_TitleComposeNum.text = TypeName[nType].."数量"
	
	local tFilterGoods = UIManager.MaterialComposeWindow:GetFilterGoodsList()
	self.m_goodsId = tFilterGoods[itemIndex]
	-- 读物品表
	local schemeInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, self.m_goodsId)
	
	-- 读材料合成表
	local MaterialComposeInfo = IGame.rktScheme:GetSchemeInfo(MATERIALCOMPOSE_CSV, self.m_goodsId, nType)
	if not schemeInfo or not MaterialComposeInfo then
		return
	end
	local materialColor = self:GetGoodsNameColor(schemeInfo.lBaseLevel)
	-- 物品名称
	self.Controls.m_MaterialGoodsName.text = "<color=".. materialColor .. ">" .. schemeInfo.szName .. "</color>" or ""
	
	-- 物品图片
	local imagePath = AssetPath.TextureGUIPath..schemeInfo.lIconID1
	UIFunction.SetImageSprite( self.Controls.m_MaterialGoodsImg , imagePath ) 
	-- 物品边框
	local imageBgPath = AssetPath.TextureGUIPath..schemeInfo.lIconID2
	UIFunction.SetImageSprite( self.Controls.m_MaterialBorderImg , imageBgPath ) 
	--拥有的数量
	local totalNum = packetPart:GetGoodNum(self.m_goodsId)
	self.totalNum  = totalNum
	--需要材料数量
	local needNum  = MaterialComposeInfo.nNeedNum
	self.needNum   = needNum
	if totalNum < needNum then -- 判断数量
		self.Controls.m_MaterialNum.text = "<color=red>"..totalNum.."</color>/"..needNum.." "
		self.Controls.m_GrayGetBtn.gameObject:SetActive(true)
	else 
		self.Controls.m_MaterialNum.text = totalNum.."/"..needNum
		self.Controls.m_GrayGetBtn.gameObject:SetActive(false)
	end
	
	local targetGoodsId = MaterialComposeInfo.lResGoodsID
	local targetGoodsInfo = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, targetGoodsId)
	
	if targetGoodsInfo then 
		local targetColor = self:GetGoodsNameColor(targetGoodsInfo.lBaseLevel)
		self.Controls.m_TargetGoodsName.text = "<color=".. targetColor .. ">" .. targetGoodsInfo.szName .. "</color>" or ""
		-- 合成物品图片
		local imagePath = AssetPath.TextureGUIPath..targetGoodsInfo.lIconID1
		UIFunction.SetImageSprite( self.Controls.m_TargetGoodsImg , imagePath ) 
		-- 合成物品边框
		local imageBgPath = AssetPath.TextureGUIPath..targetGoodsInfo.lIconID2
		UIFunction.SetImageSprite( self.Controls.m_TargetBorderImg , imageBgPath ) 
	end
	
	self.Controls.m_InputValue:GetComponent(typeof(InputField)).text = 1
	--UIFunction.SetImgComsGray(self.Controls.m_SubBtn.gameObject, true)
	self.Controls.m_SubBtn.interactable = false
	
	local maxNum = math.floor(self.totalNum / self.needNum) 
	if maxNum <= 1 then 
		--UIFunction.SetImgComsGray(self.Controls.m_PlusBtn.gameObject,true)
		self.Controls.m_PlusBtn.interactable = false
	else 
		--UIFunction.SetImgComsGray(self.Controls.m_PlusBtn.gameObject,false)
		self.Controls.m_PlusBtn.interactable = true
	end
	self:OnInPutTextChanged()
	return true
end	

function MaterialGoodsInfo:GetGoodsNameColor(baseLevel)
	local color = ""
	if baseLevel == 1 then
		color = "#f6e5c7" 
	elseif baseLevel == 2 then
		color = "#078301" 
	elseif baseLevel == 3 then
		color = "#0052c5" 
	elseif baseLevel == 4 then
		color = "#b708bd"	
	else 
		color = "#e80505"	
	end
	
	return color
end

function MaterialGoodsInfo:OnInputBtnClick() 
	local num = 1
	local maxNum = math.floor(self.totalNum / self.needNum) 
	
	local numTable = {
	    ["inputNum"] = num,
		["minNum"]   = 1,
		["maxNum"]   = maxNum, 
		["bLimitExchange"] = 0
	}
	local otherInfoTable = {
		["inputTransform"] = self.Controls.m_InputButtonBg,
	    ["bDefaultPos"] = 0,
	    ["callback_UpdateNum"] = self.callback_UpdateNum
	}
	--otherInfoTable.callback_UpdateNum = self.callback_UpdateNum
	UIManager.NumericKeypadWindow:ShowWindow(numTable, otherInfoTable)
end

function MaterialGoodsInfo:OnSubBtnClick() 
	local inputText = self.Controls.m_InputValue:GetComponent(typeof(InputField)).text
	local InputNum = tonumber(inputText)
	if not InputNum or InputNum < 0 then
		return
	end
	InputNum = InputNum - 1
	self.Controls.m_InputValue:GetComponent(typeof(InputField)).text = InputNum
	self:OnInPutTextChanged()
end

function MaterialGoodsInfo:OnPlusBtnClick() 
    local inputText = self.Controls.m_InputValue:GetComponent(typeof(InputField)).text
	local InputNum = tonumber(inputText)
	if not InputNum or InputNum < 0 then
		return
	end
	InputNum = InputNum + 1
	self.Controls.m_InputValue:GetComponent(typeof(InputField)).text = InputNum 
	self:OnInPutTextChanged()
end

function MaterialGoodsInfo:OnMaxBtnClick()
    local inputText = self.Controls.m_InputValue:GetComponent(typeof(InputField)).text
	local InputNum = tonumber(inputText)
	if not InputNum or InputNum < 0 then
		return
	end
	
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart or not packetPart:IsLoad() then
		return
	end
	
	local nOldNum = InputNum
	local nNewNum = 0
	--拥有的数量
	local totalNum = packetPart:GetGoodNum(self.m_goodsId)
	local nType = UIManager.MaterialComposeWindow:GetType()
	if nType == 1 then
		-- 读材料合成表
		local MaterialComposeInfo = IGame.rktScheme:GetSchemeInfo(MATERIALCOMPOSE_CSV, self.m_goodsId, nType)
		if not MaterialComposeInfo then
			return
		end
		nNewNum = math.floor(totalNum/MaterialComposeInfo.nNeedNum)
	else
		nNewNum = totalNum
	end
	if nNewNum == 0 then
		nNewNum = 1
	end
	if nNewNum == nOldNum then
		return
	end
	self.Controls.m_InputValue:GetComponent(typeof(InputField)).text = nNewNum
	self:OnInPutTextChanged()
end

function MaterialGoodsInfo:UpdateNum(num)
	if not num or type(num) ~= "number" then
		return
	end
    local inputText = self.Controls.m_InputValue:GetComponent(typeof(InputField)).text
	local InputNum = tonumber(inputText)
	if not InputNum or InputNum < 0 then
		return
	end
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart or not packetPart:IsLoad() then
		return
	end
	
	local nOldNum = InputNum
	local nNewNum = num
	local nMaxNum = 0
	--拥有的数量
	local totalNum = packetPart:GetGoodNum(self.m_goodsId)
	local nType = UIManager.MaterialComposeWindow:GetType()
	if nType == 1 then
		-- 读材料合成表
		local MaterialComposeInfo = IGame.rktScheme:GetSchemeInfo(MATERIALCOMPOSE_CSV, self.m_goodsId, nType)
		if not MaterialComposeInfo then
			return
		end
		nMaxNum = math.floor(totalNum/MaterialComposeInfo.lResGoodsNum)
		
	else
		nMaxNum = totalNum
	end
	if nNewNum > nMaxNum then
		nNewNum = nMaxNum
	end
	if nNewNum < 1 then
		nNewNum = 1
	end
	if nNewNum == nOldNum then
		return
	end
	self.Controls.m_InputValue:GetComponent(typeof(InputField)).text = nNewNum
	self:OnInPutTextChanged()
end

-- 合成或分解的数量有变化
function MaterialGoodsInfo:OnInPutTextChanged()
	local inputText = self.Controls.m_InputValue:GetComponent(typeof(InputField)).text
	local InputNum = tonumber(inputText)
	if not InputNum or  InputNum < 0 then
		return
	end
	local packetPart = GetHero():GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart or not packetPart:IsLoad() then
		return
	end
	
	--拥有的数量
	local totalNum = packetPart:GetGoodNum(self.m_goodsId)
	
	local nType = UIManager.MaterialComposeWindow:GetType()
	
	-- 读材料合成表
	local MaterialComposeInfo = IGame.rktScheme:GetSchemeInfo(MATERIALCOMPOSE_CSV, self.m_goodsId, nType)
	if not MaterialComposeInfo then
		return
	end
	local nMaxNum = 0
	if nType == 1 then
		nMaxNum = math.floor(totalNum/MaterialComposeInfo.nNeedNum)
		local needNum = InputNum*MaterialComposeInfo.nNeedNum
		if totalNum < needNum then
			self.Controls.m_MaterialNum.text = "<color=red>"..totalNum.."</color>/"..needNum.." " 
		else 
			self.Controls.m_MaterialNum.text = totalNum.."/"..needNum 
		end
		self.Controls.m_TargetNum.text = InputNum
	else
		nMaxNum = totalNum
		if totalNum < InputNum then
			self.Controls.m_MaterialNum.text = "<color=red>"..totalNum.."</color>/"..InputNum.." " 
		else 
			self.Controls.m_MaterialNum.text = totalNum.."/"..InputNum 
		end
		self.Controls.m_TargetNum.text = InputNum*MaterialComposeInfo.lResGoodsNum
	end
	
	self.Controls.m_SubBtn.interactable = true
	UIFunction.SetImgComsGray(self.Controls.m_SubBtn.gameObject,false)
	self.Controls.m_PlusBtn.interactable = true
	UIFunction.SetImgComsGray(self.Controls.m_PlusBtn.gameObject,false)
	if InputNum <= 1 then
		self.Controls.m_SubBtn.interactable = false
		UIFunction.SetImgComsGray(self.Controls.m_SubBtn.gameObject,true)
	end
	if InputNum >= nMaxNum then
		self.Controls.m_PlusBtn.interactable = false
		UIFunction.SetImgComsGray(self.Controls.m_PlusBtn.gameObject,true)
	end
end

function MaterialGoodsInfo:OnComposeBtnClick()
	local inputNum =  self.Controls.m_InputValue:GetComponent(typeof(InputField)).text

	local nType = UIManager.MaterialComposeWindow:GetType()
	if self.m_goodsId ~= zero and self.totalNum ~= 0 and inputNum ~= 0 then
		GameHelp.PostServerRequest("RequestMaterialCompose("..tostring(self.m_goodsId)..","..nType..","..inputNum..")")
	else
		print("【材料合成】uid错误或拥有总量为0或者输入数量为0")
	end
end

function MaterialGoodsInfo:OnGrayGetBtnClick()
	local subInfo = {
		bShowBtnType	= 2, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
	}
	UIManager.GoodsTooltipsWindow:SetGoodsInfo(self.m_goodsId, subInfo )
end

return this