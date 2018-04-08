-------ChatPetCell.lua-----------------------------------
-- @author	Jack Miao
-- @desc	聊天栏灵兽Cell
-- @date	2017.11.6
------------------------------------------------------------

local PetItemClass = require("GuiSystem.WindowList.Pet.PetIconItem")
local ChatPetCell = UIControl:new
{
    windowName = "ChatPetCell" ,

	petUID = 0, 						-- 当前格子里的宠物UID
}

-- 序列化关联的对象
function ChatPetCell:Attach( obj ) -- 序列化关联的对象
	
	UIControl.Attach(self,obj)
	
	self.PetItem = PetItemClass:new()	
	self.PetItem:Attach(self.Controls.m_PetIconItem.gameObject)
	
	self.Controls.m_petName.text = ""
	self.Controls.m_petPower.text = ""
	
    self.callback_OnSelectChanged = function( on ) self:OnSelectChanged(on) end
    self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))
    self.Controls.ItemToggle.onValueChanged:AddListener( self.callback_OnSelectChanged  )		
	
    self.callback_clickpeticon = function(ID, item) self:OnClickPetIcon(ID, item) end 
    
	self.petUID = 0
    return self
end

-- 选中toggle回调
function ChatPetCell:OnSelectChanged(on) -- 选中toggle回调
	self.m_select = on
	if nil ~= self.onItemCellSelected then
		self.onItemCellSelected( self , on )
	end	
end 

-- 选中灵兽icon回调
function ChatPetCell:OnClickPetIcon(ID, item)
    
    if not item or not item.m_UID then return end 
    
	local uid = item.m_UID
	local entity = IGame.EntityClient:Get(uid)	
	if entity == nil or not EntityClass:IsPet(entity:GetEntityClass()) then return end 
	
	-- 显示tips
	local petInfoStr = CompositeInfoByUID(uid)
	local InPutString = "<herf><color=green><"..entity:GetName().."></color><fun>"
	InPutString = InPutString.."ShowEntityTips("..petInfoStr..")</fun></herf>"
	UIManager.RichTextWindow:InsertRichText(entity:GetName(),InPutString,false) 
end 

-- 设置toggle组
function ChatPetCell:SetToggleGroup( toggleGroup )
    self.Controls.ItemToggle.group = toggleGroup
end

-- 回调函数
function ChatPetCell:SetItemCellSelectedCallback( cb ) -- 回调函数
	self.onItemCellSelected = cb
end

-- 设置灵兽数据信息
function ChatPetCell:SetPetInfo(pet_uid) -- 设置灵兽数据信息
	
	if not pet_uid then return end 
	
	local pPet = IGame.EntityClient:Get(pet_uid)
	if pPet == nil or not EntityClass:IsPet(pPet:GetEntityClass()) then 
		return 
	end
	
	local record = IGame.PetClient:GetRecordByID(pPet:GetNumProp(CREATURE_PET_PETID))
	if record == nil then return end 
	
	self.petUID = pet_uid
	self.PetItem:SetTuJian(false)	
	self.PetItem:InitState(pPet:GetNumProp(CREATURE_PET_PETID), pPet:GetPetIconPath(), pPet:GetNumProp(CREATURE_PROP_LEVEL), false, self.callback_clickpeticon, pet_uid, false)
	self.PetItem:SetQuality(record.Type)
	self.PetItem:SetCoolShow(false)

	local record = IGame.PetClient:GetRecordByID(pPet:GetNumProp(CREATURE_PET_PETID))
	if record then 
		self.Controls.m_petName.text = "<color=#" .. AssetPath_PetQualityColor[record.Type] .. ">" .. pPet:GetName() .. "</color>"
	else
		self.Controls.m_petName.text  = pPet:GetName()
	end

	self.Controls.m_petPower.text = "战斗力："..pPet:GetNumProp(CREATURE_PROP_POWER)
end

-- 回收
function ChatPetCell:OnRecycle() -- 回收

	self.petUID = 0
	self.Controls.m_petName.text = ""
	self.Controls.m_petPower.text = ""
	
	UIControl.OnRecycle(self)
end

-- 销毁
function ChatPetCell:OnDestroy() -- 销毁

	self.petUID = 0
	self.Controls.m_petName.text = ""
	self.Controls.m_petPower.text = ""	

	UIControl.OnDestroy(self)
end

-- 获取灵兽UID
function ChatPetCell:GetPetUID()
	
	return self.petUID
end

return ChatPetCell




