------------------------------------------------------------
-- 创建名字顶部单元,不要通过 UIManager 访问
--ADD 许文杰
------------------------------------------------------------

local NameTitleCell = UIControl:new
{
    windowName = "NameTitleCell" ,
	m_item = nil,
	m_cellInfo = nil,
	m_headCell= nil,
	m_textObjArr = {
	[1] = nil ,
	[2] =nil,
	[3] = nil,
	m_campSprite = nil,
	}
}

local this = NameTitleCell  

function NameTitleCell:Attach(obj)
	UIControl.Attach(self,obj)
	self.Controls.nameTrs = self.transform:Find("UITable/NameText")
	if nil ~= self.Controls.nameTrs then 
		self.Controls.nameObj = self.Controls.nameTrs.gameObject
		self.Controls.nameText = self.transform:Find("UITable/NameText"):GetComponent(typeof(UILabel))
	end
	self.m_textObjArr[1] = 	self.Controls.nameTrs
	
	self.Controls.achiveObj = self.transform:Find("UITable/AchieveTitle")
	if nil ~= self.Controls.achiveObj  then 
		self.Controls.AchiceTitText = self.Controls.achiveObj :GetComponent(typeof(UILabel))
		self.Controls.achiveObj.gameObject:SetActive(false)
	end

	self.m_textObjArr[3] = self.Controls.achiveObj
	self.Controls.familyObj = self.transform:Find("UITable/NameFamily")
	if nil ~= self.Controls.familyObj  then 
		self.Controls.FamilyText = self.Controls.familyObj :GetComponent(typeof(UILabel))
		self.Controls.familyObj.gameObject:SetActive(false)
	end
	self.HpObj = self.transform:Find("UITable/Hpbar")
	if self.HpObj ~= nil then 
		self.HpBg = self.HpObj:GetComponent(typeof(UI2DSprite))
		self.HpImage = self.transform:Find("UITable/Hpbar/Handle"):GetComponent(typeof(UI2DSprite))
	end
	self.CampObj =  self.transform:Find("UITable/CampSprite")
	if self.CampObj  ~= nil then 
		self.m_campSprite =self.CampObj:GetComponent(typeof(UI2DSprite))
	end
	self.HeadCellParent = self.transform:Find("UITable/NameText")
	self.AutoFindWayObj = self.transform:Find("UITable/AutoFindWay")
	local tabel = self.transform:Find("UITable")
	self.UITable = tabel:GetComponent(typeof(UITable))
	
	self.m_textObjArr[2] = self.Controls.familyObj
	if self.UITable ~= nil then 
		self.UITable.onReposition= function() self:ActiveHeadLight() end
	end
	
end

function NameTitleCell:Init(cellInfo)
	self.m_cellInfo = cellInfo
	local worldPosToScreen = UIWorldPositionToScreen.Get(self.transform.gameObject)
    worldPosToScreen.UICamera = UIManager.FindNguiMainCamera()
    worldPosToScreen.EntityId = cellInfo.Logic.uid
	--[[-- 除了主角，默认隐藏血条
	if uid ~= tostring(GetHero():GetUID()) then
		render.HpBar:SetActive(false)
	end
	--]]
	local entityView= rkt.EntityView.GetEntityView(cellInfo.Logic.uid)
	local heroHeight = 0
	if nil ~= entityView then
		heroHeight = entityView:GetFloat(EntityPropertyID.EntityHeight)
	end
	
	if cellInfo.Logic.height ~= nil then 
		worldPosToScreen.WorldOffset = Vector3.New( 0 , cellInfo.Logic.height , 0 )
	else
		local offsetY = heroHeight + 0.3
		worldPosToScreen.WorldOffset = Vector3.New( 0 , offsetY, 0 )
	end

  
	self:RefreshStyle(cellInfo.Logic.nameType,cellInfo.Logic.RedName,cellInfo.Logic.bHPred)	
	self:RefreshTitle( cellInfo.Logic.Name,not cellInfo.Logic.NameState)
	self:RefreshFamilyName(cellInfo.Logic.FamilyName)
	self:RefreshAchiveName(cellInfo.Logic.AchiveName)
	self:RefreshCamp(cellInfo.Logic.CampPath)
	self:SetAutoFindWay(cellInfo.Logic.autoFindWayState)
	local needHide = self:CheckHpNeedHide(cellInfo)
	
	if false == needHide then 
		self:RefreshHp(cellInfo.Logic.CurHp,cellInfo.Logic.MaxHp)
	end
	self.transform.localPosition = Vector3.New(5000,0,0)
	self.transform.gameObject:SetActive(true)
	self:RefreshHeadCell(cellInfo.Logic.headInfo)
	self:ResetPosition()
end

--设置自动寻路
function NameTitleCell:SetAutoFindWay(state)
	if self.AutoFindWayObj ~= nil then 
		self.AutoFindWayObj.gameObject:SetActive(state)
		self:ResetPosition()
	end
end


function NameTitleCell:RefreshHeight()
	if self.m_cellInfo ~=nil then 
		local worldPosToScreen = UIWorldPositionToScreen.Get(self.transform.gameObject)
		local entityView= rkt.EntityView.GetEntityView(self.m_cellInfo.Logic.uid)
		
		local heroHeight = 0
		if nil ~= entityView then
			heroHeight = entityView:GetFloat(EntityPropertyID.EntityHeight)
		end
		local offsetY=0
		if self.m_cellInfo.Logic.height~= nil then 
			offsetY = self.m_cellInfo.Logic.height
		else
			 offsetY = heroHeight + 0.3
		end
		
		worldPosToScreen.WorldOffset = Vector3.New( 0 , offsetY , 0 )
	end
end


--设置高度
function NameTitleCell:SetHeight(height)
	if self.m_cellInfo ~=nil then 
		local worldPosToScreen = UIWorldPositionToScreen.Get(self.transform.gameObject)
		worldPosToScreen.WorldOffset = Vector3.New( 0 , height , 0 )
	end
end


function NameTitleCell:RefreshCamp(path)
	if 	self.m_campSprite ~= nil and not IsNilOrEmpty(path) then 
		UIFunction.SetNGUISprite(self.m_campSprite,path,function()
			if self.m_campSprite ~= nil then 
				self.m_campSprite:MakePixelPerfect()  
			end	
		end)
		self.CampObj.gameObject:SetActive(true)
		
	else
		if self.CampObj ~= nil then 
			self.CampObj.gameObject:SetActive(false)
		end
	end 
	self:ResetPosition()
end

function NameTitleCell:ResetPosition()
	if self.light ~= nil then 
		self.light.gameObject:SetActive(false)
	end

	if self.UITable~= nil then 
		self.UITable.repositionNow = true
	end
	
end

function NameTitleCell:CleanObj()
	self.UITable =nil
	self.m_headCell  = nil
	self.light = nil
	self.HpBg =nil
	self.HpImage =nil
	self.m_campSprite =nil
	self.CampObj = nil
end

function NameTitleCell:RefreshHeadCell(Info)
	if Info == nil then 
		if self.m_headCell ~= nil then 
			rkt.GResources.RecycleGameObject(self.m_headCell)
			 self.m_headCell  = nil
		end
	else
		if self.m_headCell== nil then 
			rkt.GResources.FetchGameObjectAsync(GuiAssetList.HeadTitleCell.NguiHeadTitleCell,
			function ( path , obj , ud )
				if nil ==obj then   -- 判断U3D对象是否已经被销毁
					return
				end
				if self.transform == nil then 
					rkt.GResources.RecycleGameObject(obj)
					return
				end
				obj.transform.localPosition = Vector3.New(0,0,0)
				obj.transform:SetParent(self.HeadCellParent,false)
				self.m_headCell = obj
				if self.m_headCell~=nil then
					self.m_headCell:SetActive(true)
				end
				self:RefreshHeadCellObj(self.m_headCell,Info,self.HeadCellParent)
			end , nil , AssetLoadPriority.GuiNormal )
		else
			self:RefreshHeadCellObj(self.m_headCell,Info,self.HeadCellParent)
		end
	
	end

end

function NameTitleCell:ActiveHeadLight()
	if self.light ~= nil then 
		self.light.gameObject:SetActive(true)
	end
	
	
--	self.transform.gameObject:SetActive(true)--]]
end

function NameTitleCell:OnDestroy()
	if self.m_headCell ~= nil then 
		UnityEngine.Object.Destroy(self.m_headCell)
	end
	self:CleanObj()
	UIControl.OnDestroy(self)
end

function NameTitleCell:OnRecycle()

	if self.m_headCell ~= nil then 
		rkt.GResources.RecycleGameObject(self.m_headCell)
	end

	UIControl.OnRecycle(self)
	self:CleanObj()
	
end

function NameTitleCell:RefreshHeadCellObj(obj,Info,parent)
	if obj == nil then 
		return
	end
	local sprite  = obj:GetComponent(typeof(UI2DSprite))
	local anchor = obj:GetComponent(typeof(UIAnchor))	
	if sprite ~=nil then 
		local path = GuiAssetList.GuiRootTexturePath.."HeadTitleIcon/"..Info.Path
		UIFunction.SetNGUISprite(sprite,path)
		local LightSpriteObj = obj.transform:Find("AchiveTitleLight") 
		self.light = LightSpriteObj
		if LightSpriteObj ~= nil then 
			local LightSprite = LightSpriteObj:GetComponent(typeof(UI2DSprite))
			local color =Color.New(0,0,0,0)
			color:FromHexadecimal( Info.color , 'A' )
			LightSprite.color = color
			local tweenAlpha =LightSpriteObj:GetComponent(typeof(TweenAlpha))
			tweenAlpha.to = Info.alphaVal
		
		end
	end
	if anchor ~= nil then 
		anchor.uiCamera = UIManager.FindNguiMainCamera()
		anchor.container = parent.gameObject
		anchor.enabled =false
		anchor.enabled =true
	end
	rktTimer.SetTimer(function()self:ResetPosition()end,50,1,"" )
end


function NameTitleCell:RefreshTitle(name,hideName)
	if nil ~= self.Controls.nameText and name~= nil then 
		local realName = string.gsub(name, "\\n", "\n");
		self.Controls.nameText.text = realName
		if IsNilOrEmpty(name) then 
			self.Controls.nameObj:SetActive(false)
		else
		
			self.Controls.nameObj:SetActive(not hideName)
		end
		
		self:ResetPosition()
	end
	
end

--index为移位记录
function NameTitleCell:ShowName(index)
	local bit = 1
	local cout =table.getn(self.m_textObjArr)
	for k,v in pairs(self.m_textObjArr) do
		local number = lua_Rshift(1,k-1)
		local indexText = lua_NumberOrTo(index, number)
		if nil ~= self.m_textObjArr[k] then 
			self.m_textObjArr[k].gameObject:SetActive(indexText == 1)
		end
	end
	self:ResetPosition()
end


function NameTitleCell:RefreshFamilyName(name)
	
	if nil ~= self.Controls.FamilyText and name~= nil then 
		if IsNilOrEmpty(name) then 
			self.Controls.familyObj.gameObject:SetActive(false)
		else
			self.Controls.familyObj.gameObject:SetActive(true)
		end
		self:ResetPosition()
		self.Controls.FamilyText.text = name
	end
end

function NameTitleCell:RefreshAchiveName(name)
	if nil ~= self.Controls.AchiceTitText and name ~=nil then 
		if IsNilOrEmpty(name) then 
			self.Controls.achiveObj.gameObject:SetActive(false)
		else
			self.Controls.achiveObj.gameObject:SetActive(true)
		end
		
		self.Controls.AchiceTitText.text = name
		self:ResetPosition()
	end
end

function NameTitleCell:ShowHp(state)
	local handleObj = self.transform:Find("UITable/Hpbar")
	if nil ~= handleObj then 
		handleObj.gameObject:SetActive(state)
		self:ResetPosition()
	end
	
end

function NameTitleCell:RefreshHp(CurHp,MaxHp)
	if  MaxHp == nil or nil == CurHp then 
		return 
	end
	CurHp = Mathf.Max(CurHp,0)
	local handleObj = self.transform:Find("UITable/Hpbar/Handle")
	if handleObj == nil then 
		return
	end
	local slider = handleObj:GetComponent(typeof(UI2DSprite))
	if nil == slider then 
		return 
	end
	if MaxHp == 0 then 
		slider.fillAmount = 0
	else
		
	if self.m_cellInfo.Logic.nameType == NameTitleType.NameType_MyHero or self.m_cellInfo.Logic.nameType == NameTitleType.NameType_OtherHero then 
		slider.fillAmount = CurHp/MaxHp
	elseif self.m_cellInfo.Logic.nameType == NameTitleType.NameType_Npc then 	
		slider.fillAmount = CurHp/MaxHp
	else
		slider.fillAmount = CurHp/MaxHp
	end
		
	end

end


function NameTitleCell:CheckHpNeedHide(cellInfo)
	if self.m_cellInfo.Logic.nameType == NameTitleType.NameType_Equipment or
	self.m_cellInfo.Logic.nameType == NameTitleType.NameType_Leedchdom or
	self.m_cellInfo.Logic.nameType == NameTitleType.NameType_GoodsMoney or 
	self.m_cellInfo.Logic.nameType == NameTitleType.NameType_Npc  or
	self.m_cellInfo.Logic.MaxHp == nil or 
	self.m_cellInfo.Logic.MaxHp < 0  or self.m_cellInfo.Logic.HpState == false then
		self:ShowHp(false)
		return true
	else
		self:ShowHp(true)
		return false
	end 
	
end

function NameTitleCell:RefreshStyle(Type,IsRed,bHPred)
	if nil ~= self.Controls.nameText then 
		if NameStyleCfg[Type] == nil then 
			uerror("this name type is nil")
			return
		end

		if IsRed ~= nil and IsRed == 1 then 
			self.Controls.nameText.color = NAMEColor.OtherCanAttkHeroRed
		elseif IsRed ~= nil and IsRed == 2 then 
			self.Controls.nameText.color = NAMEColor.OtherCanAttkHeroGreen
		else
			self.Controls.nameText.color = NameStyleCfg[Type].nameColor
		end
		
		self.Controls.nameText.fontSize = NameStyleCfg[Type].fontsize
		if NameStyleCfg[Type].effectType  ~= nil then 
			self.Controls.nameText.effectStyle = NameStyleCfg[Type].effectType 
		end


		if NameStyleCfg[Type].effectType ~= UILabel.Effect.None then 
			if NameStyleCfg[Type].oulineColor ~= nil then 
				self.Controls.nameText.effectColor = NameStyleCfg[Type].oulineColor
			end
		
			if NameStyleCfg[Type].outline ~= nil then 	
				self.Controls.nameText.effectDistance =  NameStyleCfg[Type].outline
			end

		end

	end

	if Type == NameTitleType.NameType_MyHero or Type == NameTitleType.NameType_OtherHero 
	or Type == NameTitleType.NameType_OtherCanAtkHero then 
		if nil ~= self.Controls.FamilyText then 
			self.Controls.FamilyText.color = NameStyleCfg[Type].FamilyNameColor
			self.Controls.FamilyText.fontSize = NameStyleCfg[Type].FamilyFontSize
			self.Controls.FamilyText.effectStyle =  NameStyleCfg[Type].FamilyEffectType
			if NameStyleCfg[Type].FamilyEffectType ~= UILabel.Effect.None then 
				self.Controls.FamilyText.effectColor = NameStyleCfg[Type].outlineFamilyColor
				self.Controls.FamilyText.effectDistance =  NameStyleCfg[Type].FamilyOutline
			end
		end
		if nil ~= self.Controls.AchiceTitText then 
			self.Controls.AchiceTitText.color = NameStyleCfg[Type].AchiveNameColor
			self.Controls.AchiceTitText.fontSize = NameStyleCfg[Type].AchiveFontSize
			self.Controls.AchiceTitText.effectStyle =  NameStyleCfg[Type].AchiveEffectType
			if NameStyleCfg[Type].AchiveEffectType ~= UILabel.Effect.None then 
				self.Controls.AchiceTitText.effectColor = NameStyleCfg[Type].outlineAchiveColor
				self.Controls.AchiceTitText.effectDistance =  NameStyleCfg[Type].AchiveOutLine
			end


		end
	end
	if self.HpObj and not IsNilOrEmpty(NameStyleCfg[Type].HpBgImagePath) then 
		UIFunction.SetNGUISprite(self.HpBg,NameStyleCfg[Type].HpBgImagePath)
		
		if bHPred == nil then
			bHPred = NameStyleCfg[Type].bHPred
		end
		
		if bHPred then
			UIFunction.SetNGUISprite(self.HpImage,NameStyleCfg[Type].HpImagePathRed)
		else
			UIFunction.SetNGUISprite(self.HpImage,NameStyleCfg[Type].HpImagePath)
		end
	end
	self:ResetPosition()
	
end

function NameTitleCell:SetNameStyle()
	
end

function NameTitleCell:SetHpStyle()
	
end

return this