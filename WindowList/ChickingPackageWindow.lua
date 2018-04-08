-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    许文杰
-- 日  期:    2018-1-05
-- 版  本:    2.0
-- 描  述:    吃鸡背包
-------------------------------------------------------------------
local ChickingPackageWindow= UIWindow:new
{	
	
	
}

--打开界面刷新窗口
function ChickingPackageWindow:RefreshWindow()
end

function ChickingPackageWindow:OnAttach(obj)
	UIWindow.OnAttach(self,obj)
end


function ChickingPackageWindow:OnDestroy()
	
end


return ChickingPackageWindow