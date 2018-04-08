--******************************************************************
--** 文件名:	RewardItem.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-06-02
--** 版  本:	1.0
--** 描  述:	奖励回收奖励道具
--** 应  用:  
--******************************************************************


local RewardBackGoods = UIControl:new
{
	windowName = "RewardBackGoods",
	m_GoodsID = 0,
}

function RewardBackGoods:Attach(obj)
	UIControl.Attach(self,obj)
	
	self.ClickCallback = function(...) self:OnSelectChanged(...) end
	self.Controls.m_btn.onClick:AddListener(self.ClickCallback)			
end

function RewardBackGoods:GetExpValue(Rate)
	
	local nLevel = GetHero():GetNumProp(CREATURE_PROP_LEVEL)
	local Prize = IGame.rktScheme:GetSchemeInfo(PRIZESTANDARD_CSV, nLevel)
	if nil == Prize then
		print("奖励数值没有配置！ Level: "..nLevel)
		return
	end
    
    local nValue = Prize.Exp * Rate / 10000
   
    local nDecimal = nValue % 1
    local nInteger = nValue - nDecimal
    	
    if nInteger < 1 then
        return "1万"
    end
    
    if nDecimal >= 0.1 then
		return tostring(math.floor(nValue*10)*0.1).."万"
    else
		return nInteger.."万"
    end
end

function RewardBackGoods:SetRewardInfo(Goods)
	
	self.m_GoodsID = Goods.ID
	
	-- 设置Icon
	local GoodsData = IGame.rktScheme:GetSchemeInfo(LEECHDOM_CSV, Goods.ID)
	if nil == GoodsData then
		print("物品无法找到！ ID: "..Goods.ID)
		return
	end
	local IconPath = AssetPath.TextureGUIPath..GoodsData.lIconID1
	UIFunction.SetImageSprite(self.Controls.m_Icon , IconPath)	
    
    local KuanPath = AssetPath.TextureGUIPath..GoodsData.lIconID2
	UIFunction.SetImageSprite(self.Controls.m_Kuan , KuanPath)	

	
	-- 设置数量
	if Goods.ID == 9001 then
		self.Controls.m_Count.text = tostring(self:GetExpValue(Goods.Num))
		return
	end
	
	if Goods.Num <= 1 then
		self.Controls.m_Count.text = tostring("")
	else
		self.Controls.m_Count.text = tostring(Goods.Num)
	end
end

function RewardBackGoods:OnSelectChanged(on)
	local subInfo = {
		bShowBtnType	= 0, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
		ScrTrans = self.transform,	-- 源预设
	}
	UIManager.GoodsTooltipsWindow:SetGoodsInfo(self.m_GoodsID, subInfo )
end

function RewardBackGoods:OnRecycle()
	
	self.Controls.m_btn.onClick:RemoveListener(self.ClickCallback)
	self.ClickCallback = nil
	
	UIControl.OnRecycle(self)
end

return RewardBackGoods