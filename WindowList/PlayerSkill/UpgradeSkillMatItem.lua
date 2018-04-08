--/******************************************************************
---** 文件名:	UpgradeSkillMatItem.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-07
--** 版  本:	1.0
--** 描  述:	玩家技能窗口-升级材料图标
--** 应  用:  
--******************************************************************/

local UpgradeSkillMatItem = UIControl:new
{
	windowName 	= "UpgradeSkillMatItem",
	
	m_MatCfgId = 0,		-- 材料对应的配置表id:number
	m_NeedItemNum = 0,	-- 升级需要的材料数量:number
}

function UpgradeSkillMatItem:Attach(obj)
	
	UIControl.Attach(self,obj)
	
	self.onItemClick = function() self:OnItemClick() end
	self.Controls.m_ButtonMatItem.onClick:AddListener(self.onItemClick)
	
end

-- 更新图标
-- @matCfgId:材料的配置表id:number
-- @needItemNum:升级需要的材料数量:number
-- @matNameUseDefaultColor:材料名称是否使用默认的颜色的标识:boolean
function UpgradeSkillMatItem:UpdateItem(matCfgId, needItemNum, matNameUseDefaultColor)

	local hero = GetHero()
	if not hero then
		return
	end
	
	local packetPart = hero:GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	
	local leechScheme = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, matCfgId)
	if not leechScheme then
		return
	end

	self.m_MatCfgId = matCfgId
	self.m_NeedItemNum = needItemNum
	
	local haveMatNum = packetPart:GetGoodNum(matCfgId)
	local imagePath = AssetPath.TextureGUIPath..leechScheme.lIconID1
	local qualityPath = AssetPath.TextureGUIPath..leechScheme.lIconID2
	
	-- 物品数量
	if haveMatNum >= needItemNum then
   
		self.Controls.m_TextMatNum.color = UIFunction.ConverRichColorToColor("044A58")
		self.Controls.m_TfLessMatNode.gameObject:SetActive(false)
	else 	
	    haveMatNum = string.format("<color=#E4595AFF>%d</color>",haveMatNum)
		--self.Controls.m_TextMatNum.color = UIFunction.ConverRichColorToColor("F80404")
		self.Controls.m_TfLessMatNode.gameObject:SetActive(true)
	end

	-- 材料名字是用物品品质颜色
	if not matNameUseDefaultColor then
		self.Controls.m_TextMatName.color = UIFunction.GetQualityColor(leechScheme.lBaseLevel)
	end
	
	self.Controls.m_TextMatNum.text = string.format("%s/%s", haveMatNum, tostring(needItemNum))
	self.Controls.m_TextMatName.text = leechScheme.szName --  UIFunction.GetQualityName(leechScheme.szName, leechScheme.lBaseLevel)
	UIFunction.SetImageSprite(self.Controls.m_ImageMatQuality, qualityPath)
	UIFunction.SetImageSprite(self.Controls.m_ImageMatIcon, imagePath )	
	
end

-- 图标的点击行为
function UpgradeSkillMatItem:OnItemClick()
	
	local hero = GetHero()
	if not hero then
		return
	end
	
	local packetPart = hero:GetEntityPart(ENTITYPART_PERSON_PACKET)
	if not packetPart then
		return
	end
	
	local haveMatNum = packetPart:GetGoodNum(self.m_MatCfgId)
	if haveMatNum >= self.m_NeedItemNum then
		local subInfo = {
			bShowBtnType	= 0, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
			Pos = Vector3.New(0,0,0)   ,	-- 源预设
		}
        UIManager.GoodsTooltipsWindow:SetGoodsInfo(self.m_MatCfgId, subInfo )
	else
		local subInfo = {
			bShowBtnType	= 2, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
			Pos = Vector3.New(0,0,0) ,	-- 源预设
		}
		UIManager.GoodsTooltipsWindow:SetGoodsInfo(self.m_MatCfgId, subInfo )
	end
	
end


function UpgradeSkillMatItem:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function UpgradeSkillMatItem:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function UpgradeSkillMatItem:CleanData()
	
	self.Controls.m_ButtonMatItem.onClick:RemoveListener(self.onItemClick)
	self.onItemClick = nil
		
end

return UpgradeSkillMatItem
