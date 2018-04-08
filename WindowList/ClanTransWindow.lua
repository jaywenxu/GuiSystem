
--*******************************************************************
--** 文件名:	AddClanGoodsWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-07-27
--** 版  本:	1.0
--** 描  述:	帮会押运窗口
--** 应  用:  
--*******************************************************************

local ClanTransWindow = UIWindow:new
{
	windowName = "ClanTransWindow",
    m_bGetON = nil, -- 是否是上车
}

function ClanTransWindow:OnAttach(obj)
	UIWindow.OnAttach(self, obj, UIManager._MainHUDLayer)	
    
	self.Controls.m_GetOFF.onClick:AddListener(handler(self, self.OnBtnClick))
    
    self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))
   
    self:RefreshUI()
end

function ClanTransWindow:OnEnable()
    self:RefreshUI()
end

function ClanTransWindow:RefreshUI()
    
    local Txt = ""
    if not self.m_bGetON then
        Txt = "下车"
    else
        Txt = "上车"
    end
    
    self.Controls.m_BtnTxt.text = Txt
end

function ClanTransWindow:OnBtnClick()
    if not self.m_bGetON then
        self:OnGetOFF()
    else
        self:OnGetON()
    end
end

function ClanTransWindow:OnGetOFF()
    
	local pHero = GetHero()
	if pHero and pHero:IsMoving() then
		pHero:StopMove()
	end
    
	GameHelp.PostServerRequest("RequestCT_GoodsCarGetOFF()")
end

function ClanTransWindow:OnGetON()
    
	GameHelp.PostServerRequest("RequestCT_GoodsCarGetON()")
end

function ClanTransWindow:Show(bGetOn, bringTop)
    
    self.m_bGetON = bGetOn or false
    
    if self:isShow() then
        self:RefreshUI()
        return   
    end
    
    UIWindow.Show(self, bringTop)   
end

return ClanTransWindow














