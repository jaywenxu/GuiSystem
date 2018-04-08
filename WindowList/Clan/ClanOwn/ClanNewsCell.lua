-- 帮派新闻Cell
-- @Author: XieXiaoMei
-- @Date:   2017-04-12 16:43:41
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-10 10:41:08

------------------------------------------------------------
local ClanNewsCell = UIControl:new
{
	windowName = "ClanNewsCell",
    m_FuncTxt = {},
	m_CellIdx = 0, 
}
------------------------------------------------------------

function ClanNewsCell:Attach(obj)
	UIControl.Attach(self, obj)
    
    self.Controls.RichText = self.Controls.m_DescTxt.transform:GetComponent(typeof(rkt.RichText))

    self.m_TxtClick = function(text, beginIndex, endIndex) 
                        self:RichTxtClick(beginIndex, endIndex, self.m_FuncTxt) 
                    end
                    
    self.Controls.RichText.onClick:AddListener(self.m_TxtClick)
end

function ClanNewsCell:SetCellData(idx)
	self.m_CellIdx = idx

    local tNewsList = IGame.ClanClient:GetClan():GetNewsList()
    
	local tNewsdata = tNewsList[idx]
    if not tNewsdata then
        return
    end
		
	local dateTab = os.date("*t", tNewsdata.nTime)
	local weekday = GetChWeekDay(os.date("%w", tNewsdata.nTime))
	
    local Content, FuncTxt = RichTextHelp.AsysSerText(tNewsdata.szCoutext, 32)
	self.Controls.RichText.text = " · " .. Content
    self.m_FuncTxt = FuncTxt
        
    local dateTxt = self.Controls.m_DateTxt
	if not isTableEmpty(dateTab) then
		dateTxt.text = string.format("%s（%d/%d）", weekday, dateTab.month, dateTab.day)
		dateTxt.gameObject:SetActive(tNewsdata.showDate)
	else
		dateTxt.gameObject:SetActive(false)
	end
end

function ClanNewsCell:RichTxtClick(beginIndex, endIndex, FuncTxt)
    RichTextHelp.OnClickAsysSerText(beginIndex,endIndex, FuncTxt)
end

function ClanNewsCell:OnDestroy()
    self.m_CellIdx = 0

	UIControl.OnDestroy(self)
end

function ClanNewsCell:OnRecycle()
    
    self.m_CellIdx = 0

    self.Controls.RichText.onClick:RemoveListener(self.m_TxtClick)

	UIControl.OnRecycle(self)
end

return ClanNewsCell



