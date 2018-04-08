-- boss血条窗口
------------------------------------------------------------
local path = AssetPath.TextureGUIPath.."BossHp/"
local interval = 30

local BossHPWindow = UIWindow:new
{
	windowName = "BossHPWindow",
	uidBoss = 0,
	curHP = 0,
	preHP = 0,
	maxHP = 0,
	baseHP = 0,
	count = 0,
	preFrontIndex = 0,
	frontIndex = 0,
	preBackIndex = 0,
	backIndex  = 0,
	preFrontCount = 0,
	preBackCount = 0,
	animCurAmount = 0,
	animEndAmount = 0,
	
	imageAssets = {
		["purple"] = "Boss_zise.png",
		["yellow"] = "Boss_lvse.png",
		["orange"] = "Boss_chengse.png",
		["blue"] = "Boss_lanse.png",
		["red"] = "Boss_hongse.png",
	},
	
	imageOrder = {
		["purple"] = "blue",
		["blue"] = "orange",
		["orange"] = "yellow",
		["yellow"] = "red",
		["red"] = "purple",
	},
	
	imageIndex = {
		[1] = "purple",
		[2] = "blue",
		[3] = "orange",
		[4] = "yellow",
		[5] = "red",
	},
}
------------------------------------------------------------
function BossHPWindow:Init()
	self.callback_AnimateSingleBar = function() self:Animate_SingleBar() end
	self.callback_AnimateMultiBar = function() self:Animate_MultiBar() end
end
------------------------------------------------------------
function BossHPWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.transform:SetAsFirstSibling()
	
	
    self:Update(self.uidBoss, self.curHP, self.maxHP)
	self:Refresh()
    
    -- 副本里有这么一种情况：角色在副本里下线再上线时，会有这么一个过程：
    -- 1、登录流程先把角色登录进场景，坐标是上次副本里下线的坐标，此时boss可能在人物旁边，boss就会进入人物九宫格，就会show boss血条
    -- 2、某些副本在人物上线时会把人物拉到入口处，这时boss又会出人物九宫格，就会销毁boss，就会hide boss血条
    -- 3、上面的步骤1和2之间间隔非常短，相当于先show boss血条，然后立即hide boss血条。而hide时，boss血条可能还在异步加载资源，这就会
    --    导致hide失败，于是boss血条最终会显示出来。表现上就是人物登录进副本后，周围没有boss，但是boss血条有显示出来。
    -- 4、综上，做个判断，如果资源加载完时，发现boss不存在，则隐藏
    local entity = IGame.EntityClient:Get(self.uidBoss)
    if entity == nil then
        self:Hide()
    end
    
	return self
end

--
function BossHPWindow:Show(bringTop)
	self.isOpen = UIManager.MainRightTopWindow.m_switchState
	if self.isOpen then
		rktEventEngine.FireExecute(EVENT_BOSSHP_SHOWORHIDE, SOURCE_TYPE_SYSTEM, 0,false)	
	end
	UIWindow.Show(self,true)
end

function BossHPWindow:Hide(destory)
	if self.isOpen then
		rktEventEngine.FireExecute(EVENT_BOSSHP_SHOWORHIDE, SOURCE_TYPE_SYSTEM, 0,true)
	end
	
	self.uidBoss = 0
	UIWindow.Hide(self, destory)
end
------------------------------------------------------------
function BossHPWindow:OnDestroy()
	self.MaxCount = 1
	self.uidBoss = 0
	UIWindow.OnDestroy(self)
end
------------------------------------------------------------
function BossHPWindow:SetOwner(uidBoss, curHP, maxHP, level)
	self.uidBoss = uidBoss
	self.curHP = curHP
	self.maxHP = maxHP
	
	local scheme = IGame.rktScheme:GetSchemeInfo(BOSSHPBAR_CSV, level)
	if not scheme then
		uerror("BossHPWindow:SetOwner, could not find scheme, level = "..level)
		self.baseHP = 1000
	else
		self.baseHP = scheme.HPBase
	end
	
	-- 血管条数, 向上取整，保证每管血是满的
	local count = math.ceil(maxHP / self.baseHP)
	if count == 0 then
		count = 1
	end
	-- 血管基数
	self.baseHP = maxHP / count
	self.count =  math.ceil(curHP/self.baseHP)
end

-- 初始化颜色位置
function BossHPWindow:SetColorPos()
    self.frontIndex = 0
	self.backIndex  = 0
end
------------------------------------------------------------
function BossHPWindow:Update(uid, curHP, maxHP)
	if tostring(uid) ~= tostring(self.uidBoss) then
		return
	end
	
	if curHP <= 0 then 
		curHP = 0
	end

    if not self:isLoaded() then
		self.curHP = curHP
        return
    end
	
	if curHP == maxHP then -- 满血还原1
		self.Controls.m_Front.fillAmount = 1
		self.Controls.m_Mark.gameObject:SetActive(false)
	elseif curHP == 0 then
		self.Controls.m_Mark.gameObject:SetActive(false)
	else
		self.Controls.m_Mark.gameObject:SetActive(true)
	end

	local deltaHP = math.abs(self.curHP - curHP)
	if deltaHP == 0 then
		return
	end
	-- 计算填充的血量,以前的血量
	local curAmount = self:CalcFillAmount(self.curHP)
	local curBarHP = self.baseHP * curAmount
	self.animCurAmount = curAmount
	-- 现在的血量
	local targetAmount = self:CalcFillAmount(curHP)
	local targetBarHP = self.baseHP * targetAmount
	self.animEndAmount = targetAmount
	-- 计算当前血条量
	local count = math.ceil(curHP / self.baseHP)
	if count == 0 then 
		count = 1
	end 
	self.Controls.m_Count.text = "X"..tostring(count)
	self.curHP = curHP
	-- 第一种情况：掉血量少于一管血
	if deltaHP < self.baseHP and targetBarHP < curBarHP then
		self.Controls.m_White.gameObject:SetActive(true)
		self.Controls.m_White.fillAmount = self.animCurAmount
		self:SetFrontImage(self.curHP)
		self:SetBackImage(self.curHP) 
				
		rktTimer.KillTimer(self.callback_AnimateSingleBar)
		rktTimer.SetTimer(self.callback_AnimateSingleBar, interval, -1, "BossHPWindow:Update")
	else -- 第二种情况，当前一管血掉完，还要掉下一管血
	    -- 当前一管血掉完

		self:SetFrontImage(self.curHP)
		self:SetBackImage(self.curHP)
		if count > 1 then
			-- 大于一管血时恢复底色为1
			self.animCurAmount = 1
		end 
		
		self.Controls.m_White.fillAmount = self.animCurAmount 

		rktTimer.KillTimer(self.callback_AnimateSingleBar)
		rktTimer.SetTimer(self.callback_AnimateSingleBar, interval, -1, "BossHPWindow:Update")

	end
end
------------------------------------------------------------
function BossHPWindow:CalcFillAmount(curHP)
	local targetAmount = curHP / self.baseHP
	local ratio = targetAmount - math.floor(targetAmount)
	if curHP == 0 then 
		return 0 
	else 
		if ratio == 0 then 
			if curHP < self.curHP then
				return 0 
			else 
				return 1 
			end
			
		else 
			return ratio
		end
	end
end
------------------------------------------------------------
function BossHPWindow:Refresh()
    if not self:isLoaded() then
        return
    end

	self:SetFrontImage(self.curHP)
	self:SetBackImage(self.curHP)
	self.Controls.m_Back.gameObject:SetActive(true)
	self.Controls.m_White.fillAmount = 0
	local boss = IGame.EntityClient:Get(self.uidBoss)
	if boss then
		self.Controls.m_Name.text = boss:GetName()
		local levelText = boss:GetNumProp(CREATURE_PROP_LEVEL)
		levelText = levelText
		self.Controls.m_Level.text = levelText
		self.Controls.m_Count.text = "X"..self.count
	end
end
------------------------------------------------------------
function BossHPWindow:SetFrontImage(curHP)
	local colorPos = "front"
	local color = self:CalcCurColor(curHP, colorPos)
	local asset = path..self.imageAssets[color]
	UIFunction.SetImageSprite(self.Controls.m_Front, asset)
	
	local ratio = self:CalcFillAmount(curHP)
	self.Controls.m_Front.fillAmount = ratio
	
	if ratio <= 0.02 then
		ratio = 0.02
	end
	
	if ratio >= 0.98 then
		ratio = 0.98
	end
	
	self.Controls.m_FrontSlider:GetComponent(typeof(Slider)).value = ratio
end
------------------------------------------------------------
function BossHPWindow:SetBackImage(curHP)
	local colorPos = "back"
	local color = self:CalcCurColor(curHP, colorPos)
	local nextColor =  self.imageOrder[color]

	if curHP <= self.baseHP then
		nextColor = nil
	end
	if nextColor ~= nil then
		local asset = path..self.imageAssets[nextColor]
		UIFunction.SetImageSprite(self.Controls.m_Back, asset)
	else
		self.Controls.m_Back.gameObject:SetActive(false)
	end
end
------------------------------------------------------------
function BossHPWindow:CalcCurColor(curHP, colorPos)
	-- 颜色索引值
	local total = table.getn(self.imageIndex)
	local curIndex = 1
	-- 计算当前血管数
	local curCount = math.ceil(curHP / self.baseHP)
	if self.count > 5 then
		if curCount <= 5 then
			if curCount == 0 then 
				curIndex = 5
			else 
				curIndex = total - curCount + 1
			end
		else 
			if colorPos == "front" then 
				-- 前景色
			    if curHP == self.maxHP then 
					self.frontIndex = 1
				else 
					if curCount == self.preFrontCount then 
						self.frontIndex = self.preFrontIndex
					else 
						self.frontIndex = self.frontIndex + 1
						if self.frontIndex > total  then 
							self.frontIndex = 1
						end
					end
				end 

				self.preFrontIndex = self.frontIndex
				curIndex = self.frontIndex
				self.preFrontCount = curCount
			else 
				-- 背景色
				if curHP == self.maxHP then 
					self.backIndex = 1
				else 
					if curCount == self.preBackCount then 
						self.backIndex = self.preBackIndex
					else 
						self.backIndex = self.backIndex + 1
						if self.backIndex > total  then 
							self.backIndex = 1
						end
					end
				end 
				self.preBackIndex = self.backIndex
				curIndex = self.backIndex
				self.preBackCount = curCount
			end	

		end

	else
		-- 最后一条血时为红色
		if curCount == 0 then 
			curIndex = 5
		else 
			curIndex = total - curCount + 1
		end
	end
	
	return self.imageIndex[curIndex] or "purple"
end
------------------------------------------------------------
function BossHPWindow:Animate_SingleBar()
	self.animCurAmount = self.animCurAmount - 0.03
	if self.animCurAmount <= self.animEndAmount then
		self.animCurAmount = self.animEndAmount
		rktTimer.KillTimer(self.callback_AnimateSingleBar)
		if self.curHP <= 0 then 
			self.Controls.m_White.fillAmount = 0
			self.Controls.m_Front.fillAmount = 0
			self.Controls.m_FrontSlider:GetComponent(typeof(Slider)).value = 0
			self.Controls.m_Back.gameObject:SetActive(false)
			self:Hide() 
			self.Controls.m_Back.gameObject:SetActive(true)
		    UIManager.MainRightTopWindow:SetPosterStatus(true)
		end
	end
	
	self.Controls.m_White.fillAmount = self.animCurAmount
end
------------------------------------------------------------
function BossHPWindow:Animate_MultiBar()
	self.animCurAmount = self.animCurAmount - 0.03
	if self.animCurAmount <= self.animEndAmount then
		self.animCurAmount = self.animEndAmount
		rktTimer.KillTimer(self.callback_AnimateSingleBar)
	end
	
	self.Controls.m_White.fillAmount = self.animCurAmount
end

-- 当前血条是不是该怪物的血条
------------------------------------------------------------
function BossHPWindow:IsOwnerBossHp(uid)
	if not self:isShow() then
		return false
	end
	if tostringEx(uid) == tostringEx(self.uidBoss) then
		return true
	end
	return false
end

return BossHPWindow
