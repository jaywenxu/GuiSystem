-- @Author: LiaoJunXi
-- @Date:   2017-12-25 12:16:21
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-29 12:08:26

local RankCompeteBattlerCell = UIControl:new
{
	windowName         = "RankCompeteBattlerCell",
}

-------------------------------------------------------------
function RankCompeteBattlerCell:Attach( obj )
	UIControl.Attach(self, obj)
end

function RankCompeteBattlerCell:SetCellData(idx, data)
	if not data then return end
	local controls = self.Controls

	controls.m_TitleTxt.text = ""
	if UIFunction.SetCellHeadTitle(data.m_btHeadTitleID, controls.m_Title, controls) then
		local pos = Vector3.New(131, 30, 0)
		controls.m_NameTxt.transform.localPosition = pos
	else
		local pos = Vector3.New(37, 30, 0)
		controls.m_NameTxt.transform.localPosition = pos
	end
	controls.m_NameTxt.text = data.m_name
	controls.m_LevTxt.text = data.m_level.."级"
	
	UIFunction.SetHeadImage(controls.m_Avatar,data.m_faceID)
	local nWindow = UIManager.FriendEmailWindow
	UIFunction.SetImageGray(controls.m_Avatar, data.m_btOnline ~= 1)
	controls.m_OnlineState = GetValuable(data.m_btOnline == 1, "", "掉线...")
end

function RankCompeteBattlerCell:OnRecycle()
	UIControl.OnRecycle(self)
	table_release(self)
end

function RankCompeteBattlerCell:OnDestroy()
	UIControl.OnDestroy(self)
	table_release(self)
end

return RankCompeteBattlerCell