-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    许文杰
-- 日  期:    2018-1-05
-- 版  本:    2.0
-- 描  述:    吃鸡背包Item
-------------------------------------------------------------------
local ChickingPackageItem= UIControl:new
{

}


function ChickingPackageItem:Attach(obj)
	UIControl.Attach(self,obj)
end


--打开界面刷新数据
function ChickingPackageItem:Refresh()
	
end


function ChickingPackageItem:OnDestroy()

end


return ChickingPackageItem