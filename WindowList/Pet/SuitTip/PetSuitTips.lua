------------------------------灵兽界面灵兽item------------------------------------
local PetSuitTextItemClass = require( "GuiSystem.WindowList.Pet.SuitTip.PetSuitTextItem" )
local PetSuitTips = UIControl:new
{
	windowName = "PetSuitTips",
	m_SuitItemCache = {},				--tipItem脚本缓存
	
	m_UID = nil, 						--缓存的灵兽UID
}
local this = PetSuitTips

function PetSuitTips:Attach(obj)
	UIControl.Attach(self,obj)	

	--订阅显示tips事件
	self.ShowTipsCB = function(_,_,_,uid) self:ShowSuitTips(uid) end
	rktEventEngine.SubscribeExecute(EVENT_PET_OPENSUITTIPS,SOURCE_TYPE_PET, 0, self.ShowTipsCB)
	
	--[[self.OnClickBg = function() self:Hide() end
	self.Controls.m_BGMaskBtn.onClick:AddListener(self.OnClickBg)--]]
	
	UIFunction.AddEventTriggerListener(self.Controls.m_BGMask , EventTriggerType.PointerClick , function( eventData ) self:OnMaskClick(eventData) end )
	
	self:InitView()
	return self
end

------------------------------------------------------------
--
function PetSuitTips:OnDestroy()
	self.m_SuitItemCache = {}
	rktEventEngine.UnSubscribeExecute(EVENT_PET_OPENSUITTIPS,SOURCE_TYPE_PET, 0,self.ShowTipsCB)
	UIControl.OnDestroy(self)
end

--背景点击，射线穿透
function PetSuitTips:OnMaskClick(eventData)
	self:Hide()
	rkt.UIAndTextHelpTools.PassThroughPointerClickEvent( eventData )
end

--显示套装属性tips
function PetSuitTips:ShowSuitTips(uid)
	self.m_UID = uid
	local skillTable = IGame.PetClient:GetSkillTable(uid)
	local allRecords = IGame.rktScheme:GetSchemeTable(PET_CSV)
	
	if not skillTable or not allRecords then return end	
	
	local num, idList = IGame.PetClient:GetSuitNumAndID(uid)
	local count = #idList
	for i, data in pairs(self.m_SuitItemCache) do
		data:SetUID(uid)
		local highLight = false
		for j = 1,count do 
			if idList[j] == data.m_Index then
				highLight = true
				break
			end
		end
		data:SetTipText(highLight)
	end
	self:Show()
end

--初始化显示view
function PetSuitTips:InitView()
	local suitTable = IGame.rktScheme:GetSchemeTable(PETSKILLSUIT_CSV)
	if not suitTable then return end
	local tableNum =table_count(suitTable)
	local loadedNum = 0
	for i,data in pairs(suitTable) do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.PetSuitTextItem ,
		function ( path , obj , ud )
			obj.transform:SetParent(self.Controls.m_ListParent)
			obj.transform.localScale = Vector3.New(1,1,1)
			local item = PetSuitTextItemClass:new({})
			item:Attach(obj)
			item:SetData(uid, data.SuitID)
			table.insert(self.m_SuitItemCache,i,item)
			loadedNum = loadedNum + 1
			if loadedNum == tableNum then
				self:SetSibling()
			end
			
		end , i , AssetLoadPriority.GuiNormal )
	end
end

--tipItem排序
function PetSuitTips:SetSibling()
	for i, data in pairs(self.m_SuitItemCache) do
		data.transform:SetSiblingIndex(data.m_Index)
	end
end

--检测是否满足该条件, 不满足返回false,满足返回true,suitRecord
function PetSuitTips:CheckFatisfy(uid,index)
	local record = IGame.rktScheme:GetSchemeInfo(PETSKILLSUIT_CSV, index)
	if not record then return false end
	local skillTable = IGame.PetClient:GetSkillTable()
	local skillNum = 0						--等级满足个数
	local qualityNum = 0					--品质满足个数
	for i, data in pairs(skillTable) do
		if data.skill_id > 0 then
			local skillRecord = IGame.PetClient:GetSkillRecordByIDAndLevel(data.skill_id, data.skill_lv)
			if data.lv >=  record.SkillLv then
				skillNum = skillNum + 1
			end
			if skillRecord.SkillQuality >= record.SkillQuality then
				qualityNum = qualityNum + 1
			end
		end
	end
	if skillNum < record.SkillNum or qualityNum < record.QualityNum then
		return false
	end
	return true,record
end

return this