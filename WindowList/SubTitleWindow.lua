
--/*******************************************************************
--** 文件名:	EntityFactory.lua
--** 版  权:	(C) 深圳冰川网络技术有限公司
--** 创建人:	许文杰
--** 日  期:	2017/06/14
--** 版  本:	1.0
--** 描  述:	
--** 应  用:    剧情对话界面旁白等
--********************************************************************/

local AsideClass = require("GuiSystem.WindowList.SubTitle.AsideClassWidget") --  旁白
local EntityBubble = require("GuiSystem.WindowList.SubTitle.EntityBubbleWidget") --角色头顶泡泡
local BottomText = require("GuiSystem.WindowList.SubTitle.BottomTextWidget") --底部文字
local CenterTextClass = require("GuiSystem.WindowList.SubTitle.CentextWidget") --中间文字
------------------------------------------------------------
local SubTitleType=
{
	BottomTextType    =   0 ,  
	EntityBubbleType  =   1 ,  
	AsideTextType     =   2 ,
	CenterTextType    =3,   
	None = 3,
}

local ShowSunTitleAni =
{
	NORMAL_TYPE = 0,	--正常模式
	PRINT_WORD_TYPE =1,	--打字模式
}

--[[	cell = {
		[contents] = ""
		[attachTrs] = ""
		[offset] = ""
	}]----]]

local SubTitleWindow = UIWindow:new
{
	windowName = "SubTitleWindow" ,
	m_needShow =false,
	m_allContent = {},
		
}


function SubTitleWindow:OnAttach(obj)
	
	UIWindow.OnAttach(self,obj,UIManager._OperaLayer)
	if self.m_needShow == true then 
		for k,v in pairs(self.m_allContent) do 
			if k == SubTitleType.BottomTextType or SubTitleType.CenterTextType then 
				if isTableEmpty(v) ==false then 
					self:ShowContent(v,k)
				end
				
			else
				for n,m in pairs(v) do 
					if m.contents ~= nil then 
						if isTableEmpty(m) ==false then 
							self:ShowContent(m,k)
						end
						
					end 
					
				end
			end
			
			
		end
		
	end
end

--[[
--根据显示内容的模式显示内容
function SubTitleWindow:ShowContentByMode(Context,Content,ContentMode)
	if ContentMode == ShowSunTitleAni.NORMAL_TYPE then
		
	elseif  ContentMode == ShowSunTitleAni.NORMAL_TYPE then 
		Context.text = Content
		
	end
	
end--]]


function SubTitleWindow:ShowTitleWindow(content,titleType,showContentMode,printIndexTime,callBack,attachTrs,offset,camera)
	UIWindow.Show(self,true)
	local cellInfo= nil
	if titleType == SubTitleType.BottomTextType or titleType == SubTitleType.CenterTextType  then 
		self.m_allContent[titleType]={}
		self.m_allContent[titleType].contents=content
		self.m_allContent[titleType].callBack=callBack
		self.m_allContent[titleType].contentMode=showContentMode
		self.m_allContent[titleType].indexTime= printIndexTime

		cellInfo = self.m_allContent[titleType]
	else
		local cell = {
				contents = content,
				attachTrs = attachTrs,
				offsets = offset,
				callbacks = callBack,
				cameras = camera,
				contentMode= showContentMode,
				indexTime = printIndexTime,
			}
		if self.m_allContent[titleType][attachTrs] == nil then 
			self.m_allContent[titleType][attachTrs] = {}
			
			table.insert(self.m_allContent[titleType][attachTrs],cell)
		else
			self.m_allContent[titleType][attachTrs] = cell
		end
		cellInfo =cell
	end
	
	if self:isLoaded() then 
		self.m_needShow=false
		self:ShowContent(cellInfo,titleType)
	else
		self.m_needShow =true
	end
	
end

function SubTitleWindow:RemoveTitleWindow(titleType,attachTrs)
	if titleType == SubTitleType.BottomTextType or titleType ==  CenterTextType then 
		attachTrs = 0
		rkt.GResources.RecycleGameObject(self.m_allContent[titleType].obj)
		self.m_allContent[titleType].obj =nil
	else
		self.m_allContent[titleType][attachTrs].obj =nil
		rkt.GResources.RecycleGameObject(self.m_allContent[titleType][attachTrs].obj)
	end
end	
	
function SubTitleWindow:ShowContent(cellInfo,titleType)
	local path = ""
	local class = ""
	if titleType == SubTitleType.AsideTextType then 
		path = GuiAssetList.SubTitleCell.AsideCell
		class = AsideClass:new()
	elseif titleType == SubTitleType.BottomTextType then 
		path = GuiAssetList.SubTitleCell.BottomTextCell
		class = BottomText:new()
	elseif titleType == SubTitleType.EntityBubbleType then  
		path = GuiAssetList.SubTitleCell.BubbleTextCell
		class = EntityBubble:new()
	else
		path = GuiAssetList.SubTitleCell.CenterTextCell
		class = CenterTextClass:new()
	end
	local cell =nil 
	
	if titleType == SubTitleType.EntityBubbleType or titleType == SubTitleType.AsideTextType then 
		if self.m_allContent[titleType][attachTrs] == nil then 
			return
		
		end
		cell = self.m_allContent[titleType][attachTrs]
	else
		cell = self.m_allContent[titleType]
	end
	
	if cell == nil then 
		return
	end
	
	if nil == cell.obj then 
		rkt.GResources.FetchGameObjectAsync(path,function ( path , obj , ud )
				if nil == obj then   -- 判断U3D对象是否已经被销毁
					return
				end
				obj.transform:SetParent(self.transform,false)
				obj:SetActive(true)
				cell.obj = obj
				local itemClass = class:new({})
				class:Attach(obj)
				class:RefreshUI(cellInfo)
			end , nil , AssetLoadPriority.GuiNormal )
	else
		local objCell = self.m_allContent[titleType][attachTrs].obj
		local behav = objCell:GetComponent(typeof(UIWindowBehaviour))
		if nil ~= behav then
			local item = behav.LuaObject	
			item:RefreshUI(cellInfo)
		end
	end

end
	
return SubTitleWindow

