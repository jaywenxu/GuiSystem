------------------------------------------------------------
--  UI逻辑控件或子窗体基类,和UIWindow不同没有异步加载
--  需要使用者在逻辑中主动挂载
------------------------------------------------------------
UIControl = UIEventContainer:new
{
	Controls = {}     ,       -- 所有的控件都放在这里
    unityBehaviour = nil ,    -- UIWindowBehaviour
	transform = nil   ,       -- Attach 函数设置挂载的GameObject.transform
	windowName = nil  ,       -- 模块名称
}
------------------------------------------------------------
-- 挂载函数，UIWindowBehaviour 中引用的对象这里被自动关联
function UIControl:Attach( obj )
    if nil == self.windowName then
        error("UIControl's derived class's windowName is nil")
    end
	if nil == obj then
		return
	end
	self.transform = obj.gameObject.transform
	self.unityBehaviour = UIWindowBehaviour.Get(obj,self)
    self.unityBehaviour:FillLuaControlList(
		function( name , control )
			self.Controls[name] = control
		end)
	self:SubControlExecute()
end
------------------------------------------------------------
-- 判断控件是否加载
function UIControl:isLoaded()
	if nil == self.transform then
		return false
	end
	return true
end
------------------------------------------------------------
-- 判断控件是否显示
function UIControl:isShow()
	if nil == self.transform then
		return false
	end
	return self.transform.gameObject.activeInHierarchy
end
------------------------------------------------------------
-- 显示控件
function UIControl:Show()
	if self:isShow() then
		return
	end
    self.transform.gameObject:SetActive(true)
end
------------------------------------------------------------
-- 隐藏控件
function UIControl:Hide( destroy )
    if nil == self.transform then
        return
    end
    if destroy then
        self:Destroy()
    else
	    self.transform.gameObject:SetActive(false)
    end
end
------------------------------------------------------------
-- 主动销毁
function UIControl:Destroy()
	self:UnSubControlExecute()
	if nil ~= self.transform then
		UnityEngine.Object.Destroy(self.transform.gameObject)
	else
		self:OnDestroy()
	end
end
------------------------------------------------------------
-- 回收事件
function UIControl:OnRecycle()
	self:UnSubControlExecute()
    self:RemoveAllListeners()
	self.Controls = {}
	self.transform = nil
    self.unityBehaviour = nil
end
------------------------------------------------------------
-- 被动销毁
function UIControl:OnDestroy()
	if self.UnSubControlExecute then
		self:UnSubControlExecute()
	end
    self:ClearAllListeners()
	self.Controls = {}
	self.transform = nil
    self.unityBehaviour = nil
end
------------------------------------------------------------
-- 注册控件事件
function UIControl:SubControlExecute()

end
------------------------------------------------------------
-- 注销控件事件
function UIControl:UnSubControlExecute()

end
------------------------------------------------------------