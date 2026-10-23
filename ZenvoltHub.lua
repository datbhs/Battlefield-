--[[
╔══════════════════════════════════════════════════════════════════╗
║      ⚡  ZENVOLT HUB  ·  Roblox Luau  ·  tối ưu cho điện thoại     ║
╚══════════════════════════════════════════════════════════════════╝

ĐẶT Ở ĐÂU
  LocalScript  →  StarterPlayer ▸ StarterPlayerScripts

HƯỚNG DẪN NHANH
  1. Chạm nút tia sét ⚡ để mở / ẩn bảng. Kéo nút ⚡ để đổi vị trí.
  2. Kéo thanh tiêu đề để di chuyển bảng.  "—" thu nhỏ,  "✕" ẩn bảng.
  3. Tab "Di chuyển": Bay, Xuyên vật thể, Tốc độ chạy, Độ cao nhảy.
     Khi Bay bật, hai nút ▲ ▼ xuất hiện ở cạnh phải màn hình (giữ để lên/xuống).
  4. Tab "ESP": hiển thị tên, khoảng cách, viền sáng; chỉnh màu và phạm vi.
  5. Tab "Người chơi": chọn mục tiêu → chọn một chế độ. "DỪNG NGAY" dừng tức thì.
  6. Tab "Cài đặt": màu giao diện, animation, kích thước, trạng thái, khôi phục.
  Trên PC: RightShift ẩn/hiện bảng, Space = bay lên, LeftCtrl = bay xuống.

PHẠM VI & GIỚI HẠN
  • Dùng trong game của bạn hoặc môi trường kiểm thử được phép.
  • Script chạy phía client và chỉ điều khiển NHÂN VẬT CỦA BẠN. Nó không (và
    không thể) sửa nhân vật hay dữ liệu của người chơi khác.
  • Bay / Xuyên vật thể / Tốc độ / Nhảy chỉ có hiệu lực nếu máy chủ của game
    không reset lại các giá trị đó (ví dụ anti-cheat phía server).
  • Tab "Người chơi" (di chuyển nhân vật của bạn quanh mục tiêu) chỉ mở khi
    chạy trong Studio, hoặc khi chủ game bật thuộc tính  ZenvoltChoPhep = true
    trên ReplicatedStorage (hoặc Workspace) bằng một Script phía server.
]]

---------------------------------------------------------------------
-- 1. DỊCH VỤ
---------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	warn("[Zenvolt Hub] Script phải chạy dưới dạng LocalScript (phía client).")
	return
end
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

---------------------------------------------------------------------
-- 2. CẤU HÌNH & MÀU SẮC
---------------------------------------------------------------------
local CAU_HINH = {
	TEN_GUI = "ZenvoltHub",
	RONG = 420,
	CAO = 310,
	THUOC_TINH_CHO_PHEP = "ZenvoltChoPhep",
	PHIM_LEN = Enum.KeyCode.Space,
	PHIM_XUONG = Enum.KeyCode.LeftControl,
	PHIM_AN_HIEN = Enum.KeyCode.RightShift,
}

local MAU_MAC_DINH = {
	Color3.fromRGB(168, 85, 247), -- tím neon
	Color3.fromRGB(236, 72, 153), -- hồng neon
	Color3.fromRGB(34, 211, 238), -- cyan neon
}
local NEN_THE = Color3.fromRGB(26, 21, 46)
local NEN_THE_SANG = Color3.fromRGB(38, 31, 66)
local VIEN_THE = Color3.fromRGB(70, 58, 112)
local CHU_SANG = Color3.fromRGB(242, 238, 255)
local CHU_MO = Color3.fromRGB(165, 155, 196)
local MAU_TOT = Color3.fromRGB(74, 222, 128)
local MAU_XAU = Color3.fromRGB(248, 113, 113)
local MAU_CB = Color3.fromRGB(251, 191, 36)
local FONT = Enum.Font.SourceSansSemibold -- hỗ trợ đầy đủ dấu tiếng Việt
local FONT_DAM = Enum.Font.SourceSansBold

-- Gỡ bản cũ nếu chạy lại script
do
	local cu = PlayerGui:FindFirstChild(CAU_HINH.TEN_GUI)
	if cu then
		cu:Destroy()
		task.wait(0.3)
	end
end

---------------------------------------------------------------------
-- 3. TIỆN ÍCH CƠ BẢN
---------------------------------------------------------------------
local function tao(lop, tt)
	local o = Instance.new(lop)
	if o:IsA("GuiObject") then
		o.BorderSizePixel = 0
		if lop == "TextLabel" then
			o.BackgroundTransparency = 1
		elseif lop == "TextButton" then
			o.AutoButtonColor = false
			o.Text = ""
		end
	end
	local cha = nil
	if tt then
		for k, v in pairs(tt) do
			if k == "Parent" then
				cha = v
			else
				o[k] = v
			end
		end
	end
	if cha then o.Parent = cha end
	return o
end

local function bo(cha, r)
	return tao("UICorner", { CornerRadius = UDim.new(0, r), Parent = cha })
end

local function vienMo(cha, mau, doDay, doTrong)
	return tao("UIStroke", {
		Color = mau,
		Thickness = doDay or 1,
		Transparency = doTrong or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = cha,
	})
end

local function taoMaid()
	local m = { ds = {} }
	function m:Them(v)
		self.ds[#self.ds + 1] = v
		return v
	end
	function m:Don()
		local ds = self.ds
		self.ds = {}
		for _, v in ipairs(ds) do
			local kieu = typeof(v)
			if kieu == "RBXScriptConnection" then
				v:Disconnect()
			elseif kieu == "Instance" then
				v:Destroy()
			elseif kieu == "function" then
				pcall(v)
			end
		end
	end
	return m
end
local Maid = taoMaid() -- sống đến khi gỡ hub
local MaidNV = taoMaid() -- theo nhân vật hiện tại

local demThuTu = setmetatable({}, { __mode = "k" })
local function layThuTu(cha)
	demThuTu[cha] = (demThuTu[cha] or 0) + 1
	return demThuTu[cha]
end

local function thoatRT(s)
	s = s:gsub("&", "&amp;")
	s = s:gsub("<", "&lt;")
	s = s:gsub(">", "&gt;")
	return s
end

local function dinhDangSo(v, thapPhan)
	if thapPhan and thapPhan > 0 then
		return string.format("%." .. thapPhan .. "f", v)
	end
	return string.format("%d", math.floor(v + 0.5))
end

---------------------------------------------------------------------
-- 4. TRẠNG THÁI CHUNG
---------------------------------------------------------------------
local TT = {
	Bay = { Bat = false, TocDo = 60 },
	Noclip = { Bat = false },
	TocDoChay = { TuyChinh = nil },
	Nhay = { TuyChinh = nil },
	ESP = {
		Bat = false,
		Ten = true,
		KhoangCach = true,
		VienSang = true,
		PhamVi = 1000,
		Mau = Color3.fromRGB(34, 211, 238),
	},
	CongCu = { MucTieu = nil, CheDo = nil, KhoangCach = 6, BanKinh = 10, TocDo = 2 },
	CaiDat = { HoatAnh = true, TyLe = 1 },
}

local DaHuy = false
-- Các hàm giao diện được gán lại ở phần UI (khai báo trước để logic gọi được)
local thongBao = function() end
local dongBoUI = function() end
local capNhatBangTrangThai = function() end
local capNhatNhanCongCu = function() end
local dungCongCu, tatBay

-- Chủ đề màu + animation
local ChuDe = { Mau = MAU_MAC_DINH, DS = {} }

local function chuoiMau(m)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, m[1]),
		ColorSequenceKeypoint.new(0.5, m[2]),
		ColorSequenceKeypoint.new(1, m[3]),
	})
end

local function dangKyChuDe(fn)
	ChuDe.DS[#ChuDe.DS + 1] = fn
	fn(ChuDe.Mau)
end

local function datChuDe(m)
	ChuDe.Mau = m
	for _, fn in ipairs(ChuDe.DS) do
		pcall(fn, m)
	end
end

local function tween(dt, giay, thuocTinh, kieu, huong)
	if not TT.CaiDat.HoatAnh or giay <= 0 then
		for k, v in pairs(thuocTinh) do
			dt[k] = v
		end
		return nil
	end
	local tw = TweenService:Create(
		dt,
		TweenInfo.new(giay, kieu or Enum.EasingStyle.Quad, huong or Enum.EasingDirection.Out),
		thuocTinh
	)
	tw:Play()
	return tw
end

local VoHan = {}
local function phatVoHan(m)
	if m.Tween then m.Tween:Cancel() end
	m.DT[m.ThuocTinh] = m.Dau
	m.Tween = TweenService:Create(
		m.DT,
		TweenInfo.new(m.Giay, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, m.DoiXung),
		{ [m.ThuocTinh] = m.Cuoi }
	)
	m.Tween:Play()
end
local function dungVoHan(m)
	if m.Tween then
		m.Tween:Cancel()
		m.Tween = nil
	end
	m.DT[m.ThuocTinh] = m.Tinh
end
local function dangKyVoHan(dt, thuocTinh, dau, cuoi, giay, doiXung, tinh)
	local m = { DT = dt, ThuocTinh = thuocTinh, Dau = dau, Cuoi = cuoi, Giay = giay, DoiXung = doiXung or false, Tinh = tinh }
	VoHan[#VoHan + 1] = m
	if TT.CaiDat.HoatAnh then phatVoHan(m) else dungVoHan(m) end
end
local function datHoatAnh(bat)
	TT.CaiDat.HoatAnh = bat
	for _, m in ipairs(VoHan) do
		if bat then phatVoHan(m) else dungVoHan(m) end
	end
end

-- Viền neon: UIStroke + UIGradient xoay liên tục
local function vienNeon(cha, doDay, doTrong)
	local st = vienMo(cha, Color3.new(1, 1, 1), doDay, doTrong)
	local gr = tao("UIGradient", { Parent = st })
	dangKyChuDe(function(m) gr.Color = chuoiMau(m) end)
	dangKyVoHan(gr, "Rotation", 0, 360, 5, false, 45)
	return st, gr
end

---------------------------------------------------------------------
-- 5. NHÂN VẬT
---------------------------------------------------------------------
local function layNhanVatCua(nguoi)
	local char = nguoi and nguoi.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hum and hrp and hrp:IsA("BasePart") then
		return char, hum, hrp
	end
	return nil
end

local function laySong(nguoi)
	local char, hum, hrp = layNhanVatCua(nguoi)
	if char and hum.Health > 0 then
		return char, hum, hrp
	end
	return nil
end

-- Giá trị gốc của nhân vật hiện tại (ghi lại mỗi lần hồi sinh)
local MacDinhNV = { TocDo = 16, UseJumpPower = true, JumpPower = 50, JumpHeight = 7.2 }
local function ghiMacDinh(hum)
	MacDinhNV.TocDo = hum.WalkSpeed
	MacDinhNV.UseJumpPower = hum.UseJumpPower
	MacDinhNV.JumpPower = hum.JumpPower
	MacDinhNV.JumpHeight = hum.JumpHeight
end
local function jumpPowerMacDinh()
	if MacDinhNV.UseJumpPower then return MacDinhNV.JumpPower end
	return math.sqrt(2 * Workspace.Gravity * MacDinhNV.JumpHeight)
end

---------------------------------------------------------------------
-- 6. VA CHẠM DÙNG CHUNG (Noclip + công cụ người chơi)
--    Nhiều chức năng có thể "xin" tắt va chạm; chỉ khôi phục khi không
--    còn ai cần. Có thoát kẹt trước khi khôi phục.
---------------------------------------------------------------------
local VaCham = { YeuCau = {}, DaLuu = {}, BoPhan = {}, Buoc = nil, ThemKN = nil, NhanVat = nil, ViTriGoc = nil }

local function themBoPhan(d)
	if d:IsA("BasePart") then VaCham.BoPhan[d] = true end
end

local function buocVaCham()
	local daLuu, boPhan = VaCham.DaLuu, VaCham.BoPhan
	for part in pairs(boPhan) do
		if part.Parent then
			if daLuu[part] == nil then daLuu[part] = part.CanCollide end
			if part.CanCollide then part.CanCollide = false end
		else
			boPhan[part] = nil
			daLuu[part] = nil
		end
	end
end

function VaCham.gan(char)
	if VaCham.ThemKN then
		VaCham.ThemKN:Disconnect()
		VaCham.ThemKN = nil
	end
	VaCham.NhanVat = char
	VaCham.BoPhan = {}
	VaCham.DaLuu = {} -- bộ phận của nhân vật cũ đã bị huỷ
	if char then
		for _, d in ipairs(char:GetDescendants()) do themBoPhan(d) end
		VaCham.ThemKN = char.DescendantAdded:Connect(themBoPhan)
	end
end

local function coChong(char, cf, size)
	local ds = { char }
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then ds[#ds + 1] = p.Character end
	end
	local tham = OverlapParams.new()
	tham.FilterType = Enum.RaycastFilterType.Exclude
	tham.FilterDescendantsInstances = ds
	tham.RespectCanCollide = true
	tham.MaxParts = 1
	return #Workspace:GetPartBoundsInBox(cf, size, tham) > 0
end

-- Nếu nhân vật đang nằm trong vật thể: đẩy lên chỗ trống gần nhất. true = đã di chuyển.
local function thoatKet(char)
	local ok, cf, size = pcall(function() return char:GetBoundingBox() end)
	if not ok or not cf then return false end
	size = size * 0.8
	if not coChong(char, cf, size) then return false end
	for i = 1, 120 do
		if not coChong(char, cf + Vector3.new(0, i * 2, 0), size) then
			char:PivotTo(char:GetPivot() + Vector3.new(0, i * 2, 0))
			return true
		end
	end
	if VaCham.ViTriGoc then
		char:PivotTo(VaCham.ViTriGoc)
		return true
	end
	return false
end

function VaCham.yeuCau(ten)
	if next(VaCham.YeuCau) == nil then
		local _, _, hrp = layNhanVatCua(LocalPlayer)
		VaCham.ViTriGoc = hrp and hrp.CFrame or nil
	end
	VaCham.YeuCau[ten] = true
	if not VaCham.Buoc then
		VaCham.Buoc = RunService.Stepped:Connect(buocVaCham)
	end
end

function VaCham.khoiPhuc()
	for part, goc in pairs(VaCham.DaLuu) do
		if part.Parent then part.CanCollide = goc end
	end
	VaCham.DaLuu = {}
end

-- Trả về true nếu nhân vật phải được đẩy ra khỏi vật thể
function VaCham.huy(ten)
	if not VaCham.YeuCau[ten] then return false end
	VaCham.YeuCau[ten] = nil
	if next(VaCham.YeuCau) ~= nil then return false end
	if VaCham.Buoc then
		VaCham.Buoc:Disconnect()
		VaCham.Buoc = nil
	end
	local daDay = false
	local char = VaCham.NhanVat
	if char and char.Parent then
		local ok, kq = pcall(thoatKet, char)
		daDay = ok and kq or false
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end
	end
	VaCham.khoiPhuc()
	return daDay
end

local function batNoclip()
	TT.Noclip.Bat = true
	VaCham.yeuCau("Noclip")
	dongBoUI()
	thongBao("Đã bật Xuyên vật thể", "thanh_cong")
end

local function tatNoclip(imLang)
	local daDay = VaCham.huy("Noclip")
	TT.Noclip.Bat = false
	dongBoUI()
	if not imLang then
		if daDay then
			thongBao("Đã tắt Xuyên vật thể — bạn đang trong vật thể nên được đẩy ra chỗ trống", "canh_bao")
		else
			thongBao("Đã tắt Xuyên vật thể — va chạm đã khôi phục", "thong_tin")
		end
	end
end

---------------------------------------------------------------------
-- 7. BAY (LinearVelocity + AlignOrientation, bay theo hướng camera)
---------------------------------------------------------------------
local Bay = { Vat = {}, Ket = nil, Van = Vector3.zero, NutLen = false, NutXuong = false, PhimLen = false, PhimXuong = false }

local boDieuKhien = nil -- ControlModule của Roblox (đọc cần điều khiển trên điện thoại)
task.spawn(function()
	local ok, kq = pcall(function()
		local ps = LocalPlayer:WaitForChild("PlayerScripts", 10)
		local pm = ps and ps:WaitForChild("PlayerModule", 10)
		if pm then return require(pm):GetControls() end
		return nil
	end)
	if ok and kq then boDieuKhien = kq end
end)

-- Trả về (phải, tiến) trong khoảng -1..1
local function layVecDieuKhien(hum, camCF)
	if boDieuKhien then
		local ok, v = pcall(function() return boDieuKhien:GetMoveVector() end)
		if ok and typeof(v) == "Vector3" then
			return v.X, -v.Z
		end
	end
	local md = hum.MoveDirection
	if md.Magnitude < 0.01 then return 0, 0 end
	local nhin = camCF.LookVector
	local phang = Vector3.new(nhin.X, 0, nhin.Z)
	if phang.Magnitude < 0.01 then return 0, 0 end
	phang = phang.Unit
	local phai = Vector3.new(-phang.Z, 0, phang.X)
	return md:Dot(phai), md:Dot(phang)
end

local function donVatLyBay()
	if Bay.Ket then
		Bay.Ket:Disconnect()
		Bay.Ket = nil
	end
	for _, o in ipairs(Bay.Vat) do
		if o and o.Parent then o:Destroy() end
	end
	Bay.Vat = {}
	Bay.Van = Vector3.zero
end

-- Dừng bay: huỷ ràng buộc + trả nhân vật về trạng thái bình thường
local function dungVatLyBay()
	donVatLyBay()
	local _, hum, hrp = layNhanVatCua(LocalPlayer)
	if hum then
		hum.PlatformStand = false
		if hum.Health > 0 then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
	end
	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end
end

local function capNhatBay(dt)
	local _, hum, hrp = laySong(LocalPlayer)
	if not hum then return end
	local lv, ao = Bay.Vat[2], Bay.Vat[3]
	if not (lv and lv.Parent and ao and ao.Parent) then
		-- Đối tượng bị game xoá → tạo lại
		Bay.TaoLai()
		return
	end
	local cam = Workspace.CurrentCamera
	if not cam then return end
	if not hum.PlatformStand then hum.PlatformStand = true end
	local camCF = cam.CFrame
	local nhin, phai = camCF.LookVector, camCF.RightVector
	local x, z = layVecDieuKhien(hum, camCF)
	local huong = phai * x + nhin * z
	local doc = 0
	if Bay.NutLen or Bay.PhimLen then doc = doc + 1 end
	if Bay.NutXuong or Bay.PhimXuong then doc = doc - 1 end
	huong = huong + Vector3.new(0, doc, 0)
	if huong.Magnitude > 1 then huong = huong.Unit end
	Bay.Van = Bay.Van:Lerp(huong * TT.Bay.TocDo, math.clamp(dt * 12, 0, 1))
	lv.VectorVelocity = Bay.Van
	local phang = Vector3.new(nhin.X, 0, nhin.Z)
	if phang.Magnitude > 0.01 then
		ao.CFrame = CFrame.lookAt(Vector3.zero, phang.Unit)
	end
end

local function batVatLyBay()
	local _, hum, hrp = laySong(LocalPlayer)
	if not hum then return false end
	donVatLyBay()
	if hum.SeatPart then hum.Sit = false end
	local att = Instance.new("Attachment")
	att.Name = "ZV_BayAtt"
	att.Parent = hrp
	local lv = Instance.new("LinearVelocity")
	lv.Name = "ZV_BayLV"
	lv.Attachment0 = att
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.MaxForce = math.huge
	lv.VectorVelocity = Vector3.zero
	lv.Parent = hrp
	local ao = Instance.new("AlignOrientation")
	ao.Name = "ZV_BayAO"
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.RigidityEnabled = false
	ao.MaxTorque = math.huge
	ao.MaxAngularVelocity = math.huge
	ao.Responsiveness = 30
	local nhin = hrp.CFrame.LookVector
	local phang = Vector3.new(nhin.X, 0, nhin.Z)
	if phang.Magnitude < 0.01 then phang = Vector3.new(0, 0, -1) end
	ao.CFrame = CFrame.lookAt(Vector3.zero, phang.Unit)
	ao.Parent = hrp
	hum.PlatformStand = true
	Bay.Vat = { att, lv, ao }
	Bay.Ket = RunService.Heartbeat:Connect(capNhatBay)
	return true
end
Bay.TaoLai = batVatLyBay

tatBay = function(imLang)
	TT.Bay.Bat = false
	Bay.NutLen, Bay.NutXuong = false, false
	dungVatLyBay()
	dongBoUI()
	if not imLang then thongBao("Đã tắt Bay — nhân vật trở lại bình thường", "thong_tin") end
end

local function batBay()
	local _, hum = laySong(LocalPlayer)
	if not hum then
		thongBao("Nhân vật chưa sẵn sàng — thử lại sau khi hồi sinh", "canh_bao")
		dongBoUI()
		return
	end
	if TT.CongCu.CheDo then dungCongCu(true) end
	TT.Bay.Bat = true
	batVatLyBay()
	dongBoUI()
	thongBao("Đã bật Bay — giữ ▲ ▼ để lên/xuống", "thanh_cong")
end

---------------------------------------------------------------------
-- 8. TỐC ĐỘ CHẠY & ĐỘ CAO NHẢY
---------------------------------------------------------------------
local function apDungTocDoNhay()
	local _, hum = layNhanVatCua(LocalPlayer)
	if not hum then return end
	local tocDo = TT.TocDoChay.TuyChinh
	if tocDo and math.abs(hum.WalkSpeed - tocDo) > 0.01 then
		hum.WalkSpeed = tocDo
	end
	local nhay = TT.Nhay.TuyChinh
	if nhay and not TT.Bay.Bat then -- khi đang Bay thì không đụng vào thông số nhảy
		if not hum.UseJumpPower then hum.UseJumpPower = true end
		if math.abs(hum.JumpPower - nhay) > 0.01 then hum.JumpPower = nhay end
	end
end

-- Vòng duy trì nhẹ (4 lần/giây) chỉ chạy khi có giá trị tuỳ chỉnh,
-- để chống game tự đặt lại tốc độ/nhảy
local DuyTri = { Ket = nil, Tich = 0 }
local function capNhatVongDuyTri()
	local can = TT.TocDoChay.TuyChinh ~= nil or TT.Nhay.TuyChinh ~= nil
	if can and not DuyTri.Ket then
		DuyTri.Tich = 0
		DuyTri.Ket = RunService.Heartbeat:Connect(function(dt)
			DuyTri.Tich = DuyTri.Tich + dt
			if DuyTri.Tich >= 0.25 then
				DuyTri.Tich = 0
				apDungTocDoNhay()
			end
		end)
	elseif not can and DuyTri.Ket then
		DuyTri.Ket:Disconnect()
		DuyTri.Ket = nil
	end
end

local function datTocDo(v)
	TT.TocDoChay.TuyChinh = v
	apDungTocDoNhay()
	capNhatVongDuyTri()
end
local function datLaiTocDo()
	TT.TocDoChay.TuyChinh = nil
	local _, hum = layNhanVatCua(LocalPlayer)
	if hum then hum.WalkSpeed = MacDinhNV.TocDo end
	capNhatVongDuyTri()
end
local function datNhay(v)
	TT.Nhay.TuyChinh = v
	apDungTocDoNhay()
	capNhatVongDuyTri()
end
local function datLaiNhay()
	TT.Nhay.TuyChinh = nil
	local _, hum = layNhanVatCua(LocalPlayer)
	if hum then
		hum.UseJumpPower = MacDinhNV.UseJumpPower
		hum.JumpPower = MacDinhNV.JumpPower
		hum.JumpHeight = MacDinhNV.JumpHeight
	end
	capNhatVongDuyTri()
end

---------------------------------------------------------------------
-- 9. ESP (BillboardGui + Highlight, chỉ tồn tại trên client của bạn)
---------------------------------------------------------------------
local ESP = { Muc = {}, KN = nil, Tich = 0 }

local function xoaESPNguoi(nguoi)
	local m = ESP.Muc[nguoi]
	if not m then return end
	ESP.Muc[nguoi] = nil
	for _, c in ipairs(m.Ket) do c:Disconnect() end
	m.Don()
end

local function taoESPNguoi(nguoi)
	if nguoi == LocalPlayer or ESP.Muc[nguoi] or not TT.ESP.Bat then return end
	local m = { Ket = {}, Gui = nil, Nhan = nil, Hl = nil }
	ESP.Muc[nguoi] = m

	local function don()
		if m.Gui then
			m.Gui:Destroy()
			m.Gui, m.Nhan = nil, nil
		end
		if m.Hl then
			m.Hl:Destroy()
			m.Hl = nil
		end
	end
	m.Don = don

	local function xayDung(char)
		don()
		if not char then return end
		task.spawn(function()
			local dau = char:WaitForChild("Head", 10)
			local goc = char:WaitForChild("HumanoidRootPart", 10)
			local neo = dau or goc
			if not neo or ESP.Muc[nguoi] ~= m or nguoi.Character ~= char then return end
			don()
			local bg = tao("BillboardGui", {
				Name = "ZV_ESP",
				Adornee = neo,
				AlwaysOnTop = true,
				Size = UDim2.fromOffset(190, 36),
				StudsOffset = Vector3.new(0, dau and 2.4 or 3.4, 0),
				LightInfluence = 0,
				Enabled = false,
				Parent = neo,
			})
			local nhan = tao("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				Font = FONT_DAM,
				TextSize = 15,
				TextColor3 = TT.ESP.Mau,
				TextStrokeTransparency = 0.3,
				TextStrokeColor3 = Color3.new(0, 0, 0),
				TextYAlignment = Enum.TextYAlignment.Bottom,
				Text = "",
				Parent = bg,
			})
			local hl = tao("Highlight", {
				Adornee = char,
				FillColor = TT.ESP.Mau,
				OutlineColor = TT.ESP.Mau,
				FillTransparency = 0.82,
				OutlineTransparency = 0,
				DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
				Enabled = false,
				Parent = char,
			})
			m.Gui, m.Nhan, m.Hl = bg, nhan, hl
		end)
	end

	m.Ket[#m.Ket + 1] = nguoi.CharacterAdded:Connect(xayDung)
	m.Ket[#m.Ket + 1] = nguoi.CharacterRemoving:Connect(don)
	if nguoi.Character then xayDung(nguoi.Character) end
end

local function capNhatESP()
	local cam = Workspace.CurrentCamera
	local _, _, hrpToi = layNhanVatCua(LocalPlayer)
	local goc = hrpToi and hrpToi.Position or (cam and cam.CFrame.Position) or Vector3.zero
	local gan = {}
	for nguoi, m in pairs(ESP.Muc) do
		if m.Hl then m.Hl.Enabled = false end
		local bg = m.Gui
		if bg then
			local char = nguoi.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local kc = hrp and (hrp.Position - goc).Magnitude or math.huge
			local hien = hrp ~= nil and kc <= TT.ESP.PhamVi and (hum == nil or hum.Health > 0)
			bg.Enabled = hien and (TT.ESP.Ten or TT.ESP.KhoangCach)
			if hien then
				local dong = {}
				if TT.ESP.Ten then
					local ten = nguoi.DisplayName
					if ten ~= nguoi.Name then ten = ten .. " (@" .. nguoi.Name .. ")" end
					dong[#dong + 1] = ten
				end
				if TT.ESP.KhoangCach then
					dong[#dong + 1] = "[" .. dinhDangSo(kc) .. " stud]"
				end
				m.Nhan.Text = table.concat(dong, "\n")
				gan[#gan + 1] = { m, kc }
			end
		end
	end
	-- Roblox chỉ vẽ tối đa ~31 Highlight cùng lúc → ưu tiên người gần nhất
	table.sort(gan, function(a, b) return a[2] < b[2] end)
	for i, it in ipairs(gan) do
		if it[1].Hl then it[1].Hl.Enabled = TT.ESP.VienSang and i <= 30 end
	end
end

local function capNhatMauESP()
	for _, m in pairs(ESP.Muc) do
		if m.Nhan then m.Nhan.TextColor3 = TT.ESP.Mau end
		if m.Hl then
			m.Hl.FillColor = TT.ESP.Mau
			m.Hl.OutlineColor = TT.ESP.Mau
		end
	end
end

local function batESP(bat)
	if bat == TT.ESP.Bat then return end
	TT.ESP.Bat = bat
	if bat then
		for _, p in ipairs(Players:GetPlayers()) do taoESPNguoi(p) end
		ESP.Tich = 0
		ESP.KN = {
			Players.PlayerAdded:Connect(taoESPNguoi),
			Players.PlayerRemoving:Connect(xoaESPNguoi),
			RunService.Heartbeat:Connect(function(dt)
				ESP.Tich = ESP.Tich + dt
				if ESP.Tich >= 0.15 then
					ESP.Tich = 0
					capNhatESP()
				end
			end),
		}
		thongBao("Đã bật ESP", "thanh_cong")
	else
		if ESP.KN then
			for _, c in ipairs(ESP.KN) do c:Disconnect() end
			ESP.KN = nil
		end
		local ds = {}
		for p in pairs(ESP.Muc) do ds[#ds + 1] = p end
		for _, p in ipairs(ds) do xoaESPNguoi(p) end
		thongBao("Đã tắt ESP — đã dọn các đối tượng hiển thị", "thong_tin")
	end
	dongBoUI()
end

---------------------------------------------------------------------
-- 10. CÔNG CỤ NGƯỜI CHƠI (di chuyển NHÂN VẬT CỦA BẠN quanh mục tiêu)
---------------------------------------------------------------------
local CongCu = { Ket = nil, Goc = 0, TrangThai = "" }
local TEN_CHE_DO = {
	TheoDoi = "Theo dõi",
	VongTron = "Vòng tròn",
	PhiaSau = "Đứng phía sau",
	BenDuoi = "Định vị bên dưới",
}

local function kiemTraChoPhep()
	if RunService:IsStudio() then return true end
	local ten = CAU_HINH.THUOC_TINH_CHO_PHEP
	if ReplicatedStorage:GetAttribute(ten) == true then return true end
	if Workspace:GetAttribute(ten) == true then return true end
	return false
end

local function datTrangThaiCongCu(chu)
	if CongCu.TrangThai ~= chu then
		CongCu.TrangThai = chu
		capNhatNhanCongCu()
	end
end

local function buocCongCu(dt)
	local cheDo, mt = TT.CongCu.CheDo, TT.CongCu.MucTieu
	if not cheDo or not mt then return end
	local _, mHum, mHrp = laySong(LocalPlayer)
	if not mHrp then
		datTrangThaiCongCu("Đang chờ bạn hồi sinh…")
		return
	end
	if mHum.SeatPart then
		datTrangThaiCongCu("Bạn đang ngồi trên ghế — tạm dừng")
		return
	end
	local _, _, tHrp = laySong(mt)
	if not tHrp then
		datTrangThaiCongCu("Mục tiêu đang chết/hồi sinh — đang chờ…")
		return
	end
	datTrangThaiCongCu("Đang chạy: " .. TEN_CHE_DO[cheDo])

	local tCF = tHrp.CFrame
	local tPos = tCF.Position
	local tNhin = Vector3.new(tCF.LookVector.X, 0, tCF.LookVector.Z)
	if tNhin.Magnitude < 0.01 then tNhin = Vector3.new(0, 0, -1) else tNhin = tNhin.Unit end
	local mPos = mHrp.Position
	local dich, huongNhin

	if cheDo == "TheoDoi" then
		local lech = Vector3.new(mPos.X - tPos.X, 0, mPos.Z - tPos.Z)
		local h = lech.Magnitude > 0.1 and lech.Unit or -tNhin
		local mong = Vector3.new(tPos.X + h.X * TT.CongCu.KhoangCach, tPos.Y, tPos.Z + h.Z * TT.CongCu.KhoangCach)
		dich = mPos:Lerp(mong, 1 - math.exp(-TT.CongCu.TocDo * 1.5 * dt))
		huongNhin = Vector3.new(tPos.X, dich.Y, tPos.Z)
	elseif cheDo == "VongTron" then
		CongCu.Goc = (CongCu.Goc + TT.CongCu.TocDo * dt) % (2 * math.pi)
		local r = TT.CongCu.BanKinh
		dich = Vector3.new(tPos.X + math.cos(CongCu.Goc) * r, tPos.Y, tPos.Z + math.sin(CongCu.Goc) * r)
		huongNhin = Vector3.new(tPos.X, dich.Y, tPos.Z)
	elseif cheDo == "PhiaSau" then
		local mong = tPos - tNhin * TT.CongCu.KhoangCach
		dich = mPos:Lerp(mong, 1 - math.exp(-25 * dt))
		huongNhin = dich + tNhin
	else -- BenDuoi
		local mong = tPos - Vector3.new(0, TT.CongCu.KhoangCach, 0)
		dich = mPos:Lerp(mong, 1 - math.exp(-25 * dt))
		huongNhin = dich + tNhin
	end

	if (huongNhin - dich).Magnitude < 0.01 then huongNhin = dich + Vector3.new(0, 0, -1) end
	mHrp.CFrame = CFrame.lookAt(dich, huongNhin)
	mHrp.AssemblyLinearVelocity = Vector3.zero
	mHrp.AssemblyAngularVelocity = Vector3.zero
end

dungCongCu = function(imLang)
	local dangChay = TT.CongCu.CheDo ~= nil
	TT.CongCu.CheDo = nil
	if CongCu.Ket then
		CongCu.Ket:Disconnect()
		CongCu.Ket = nil
	end
	local daDay = VaCham.huy("CongCu")
	CongCu.TrangThai = ""
	local _, _, hrp = layNhanVatCua(LocalPlayer)
	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end
	dongBoUI()
	if dangChay and not imLang then
		thongBao("Đã dừng công cụ người chơi" .. (daDay and " — bạn được đẩy ra chỗ trống" or ""), "thong_tin")
	end
end

local function goc(a, b)
	return math.atan2(a.Z - b.Z, a.X - b.X)
end

local function datCheDoCongCu(cheDo)
	if TT.CongCu.CheDo == cheDo then
		dungCongCu(false)
		return
	end
	if not kiemTraChoPhep() then
		thongBao("Công cụ đang khóa: chỉ chạy trong Studio hoặc khi chủ game bật " .. CAU_HINH.THUOC_TINH_CHO_PHEP, "canh_bao")
		dongBoUI()
		return
	end
	local mt = TT.CongCu.MucTieu
	if not mt or mt.Parent ~= Players then
		thongBao("Hãy chọn một người chơi trong danh sách trước", "canh_bao")
		dongBoUI()
		return
	end
	local _, _, hrp = laySong(LocalPlayer)
	if not hrp then
		thongBao("Nhân vật của bạn chưa sẵn sàng", "canh_bao")
		dongBoUI()
		return
	end
	if TT.Bay.Bat then tatBay(true) end
	local moiBatDau = TT.CongCu.CheDo == nil
	TT.CongCu.CheDo = cheDo
	local _, _, tHrp = laySong(mt)
	if tHrp then CongCu.Goc = goc(hrp.Position, tHrp.Position) end
	if moiBatDau then
		VaCham.yeuCau("CongCu")
		CongCu.Ket = RunService.Heartbeat:Connect(buocCongCu)
	end
	dongBoUI()
	thongBao("Đã bật: " .. TEN_CHE_DO[cheDo], "thanh_cong")
end

local lamMoiDanhSach = function() end

local function datMucTieu(nguoi)
	TT.CongCu.MucTieu = nguoi
	if TT.CongCu.CheDo then
		local _, _, hrp = laySong(LocalPlayer)
		local _, _, tHrp = laySong(nguoi)
		if hrp and tHrp then CongCu.Goc = goc(hrp.Position, tHrp.Position) end
	end
	lamMoiDanhSach()
	dongBoUI()
end

local function khiNguoiRoi(nguoi)
	if TT.CongCu.MucTieu == nguoi then
		local dangChay = TT.CongCu.CheDo ~= nil
		TT.CongCu.MucTieu = nil
		if dangChay then dungCongCu(true) end
		thongBao(nguoi.DisplayName .. " đã thoát game" .. (dangChay and " — công cụ đã tự dừng" or ""), "canh_bao")
	end
	lamMoiDanhSach(nguoi)
	dongBoUI()
end

---------------------------------------------------------------------
-- 11. TẮT TẤT CẢ / DỌN DẸP
---------------------------------------------------------------------
local function tatTatCa(imLang)
	if TT.Bay.Bat then tatBay(true) end
	if TT.Noclip.Bat then tatNoclip(true) end
	if TT.CongCu.CheDo then dungCongCu(true) end
	if TT.ESP.Bat then batESP(false) end
	datLaiTocDo()
	datLaiNhay()
	dongBoUI()
	if not imLang then thongBao("Đã tắt tất cả chức năng", "thanh_cong") end
end

local function donDepTatCa()
	if DaHuy then return end
	pcall(tatTatCa, true)
	DaHuy = true
	pcall(donVatLyBay)
	if DuyTri.Ket then DuyTri.Ket:Disconnect() DuyTri.Ket = nil end
	if CongCu.Ket then CongCu.Ket:Disconnect() CongCu.Ket = nil end
	if ESP.KN then
		for _, c in ipairs(ESP.KN) do c:Disconnect() end
		ESP.KN = nil
	end
	if VaCham.Buoc then VaCham.Buoc:Disconnect() VaCham.Buoc = nil end
	if VaCham.ThemKN then VaCham.ThemKN:Disconnect() VaCham.ThemKN = nil end
	VaCham.khoiPhuc()
	for _, m in ipairs(VoHan) do
		if m.Tween then m.Tween:Cancel() end
	end
	MaidNV:Don()
	Maid:Don()
end

---------------------------------------------------------------------
-- 12. GIAO DIỆN — KHUNG CHÍNH
---------------------------------------------------------------------
local gui = tao("ScreenGui", {
	Name = CAU_HINH.TEN_GUI,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
	DisplayOrder = 1000,
})
pcall(function() gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets end)
gui.Parent = PlayerGui

local function kichThuocManHinh()
	local s = gui.AbsoluteSize
	if s.X < 50 or s.Y < 50 then
		local cam = Workspace.CurrentCamera
		if cam then s = cam.ViewportSize end
	end
	return s
end

-- Giữ đối tượng (anchor bất kỳ) nằm trong màn hình
local function kepManHinh(muc)
	local vp = kichThuocManHinh()
	local kt, neo, p = muc.AbsoluteSize, muc.AnchorPoint, muc.Position
	local bien = 4
	local trai = p.X.Offset - neo.X * kt.X
	local tren = p.Y.Offset - neo.Y * kt.Y
	local toiX, toiY = vp.X - kt.X - bien, vp.Y - kt.Y - bien
	if toiX < bien then trai = (vp.X - kt.X) / 2 else trai = math.clamp(trai, bien, toiX) end
	if toiY < bien then tren = (vp.Y - kt.Y) / 2 else tren = math.clamp(tren, bien, toiY) end
	muc.Position = UDim2.fromOffset(trai + neo.X * kt.X, tren + neo.Y * kt.Y)
end

local W, H = CAU_HINH.RONG, CAU_HINH.CAO
local khung = tao("Frame", {
	Name = "Khung",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromOffset(300, 30),
	Size = UDim2.fromOffset(W, H),
	BackgroundTransparency = 1,
	Parent = gui,
})
local uiScaleNguoiDung = tao("UIScale", { Scale = 1, Parent = khung })
local khungGoc = tao("Frame", {
	Name = "Goc",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Parent = khung,
})
local uiScaleMo = tao("UIScale", { Scale = 1, Parent = khungGoc })

-- Quầng sáng neon phía sau
do
	local quang = tao("Frame", {
		Name = "Quang",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 10, 1, 10),
		BackgroundTransparency = 1,
		ZIndex = 0,
		Parent = khungGoc,
	})
	bo(quang, 18)
	vienNeon(quang, 6, 0.8)
end

local cuaSo = tao("Frame", {
	Name = "CuaSo",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ClipsDescendants = true,
	Active = true,
	ZIndex = 1,
	Parent = khungGoc,
})
bo(cuaSo, 12)
vienNeon(cuaSo, 2, 0)
tao("UIGradient", {
	Rotation = 90,
	Color = ColorSequence.new(Color3.fromRGB(30, 21, 58), Color3.fromRGB(10, 8, 20)),
	Parent = cuaSo,
})

-- Lớp sét (phía sau nội dung)
local lopSet = tao("Frame", {
	Name = "LopSet",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	ZIndex = 2,
	Parent = cuaSo,
})

-- Thanh tiêu đề
local thanhTieuDe = tao("Frame", {
	Name = "TieuDe",
	Size = UDim2.new(1, 0, 0, 38),
	BackgroundColor3 = Color3.fromRGB(22, 16, 42),
	BackgroundTransparency = 0.25,
	Active = true,
	ZIndex = 4,
	Parent = cuaSo,
})
do
	local duong = tao("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.35,
		Parent = thanhTieuDe,
	})
	local gd = tao("UIGradient", { Parent = duong })
	dangKyChuDe(function(m) gd.Color = chuoiMau(m) end)
	local nhan = tao("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -96, 1, 0),
		Font = FONT_DAM,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "⚡ Zenvolt Hub",
		Parent = thanhTieuDe,
	})
	local gn = tao("UIGradient", { Parent = nhan })
	dangKyChuDe(function(m) gn.Color = chuoiMau(m) end)
	dangKyVoHan(gn, "Offset", Vector2.new(-0.6, 0), Vector2.new(0.6, 0), 2.5, true, Vector2.zero)
end

local function taoNutTieuDe(chu, x)
	local b = tao("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, x, 0.5, 0),
		Size = UDim2.fromOffset(32, 26),
		BackgroundColor3 = NEN_THE_SANG,
		Font = FONT_DAM,
		TextSize = 18,
		TextColor3 = CHU_SANG,
		Text = chu,
		Parent = thanhTieuDe,
	})
	bo(b, 7)
	return b
end
local nutDong = taoNutTieuDe("✕", -8)
local nutThuNho = taoNutTieuDe("—", -44)

local thanhTab = tao("Frame", {
	Name = "ThanhTab",
	Position = UDim2.fromOffset(8, 44),
	Size = UDim2.new(1, -16, 0, 34),
	BackgroundTransparency = 1,
	ZIndex = 4,
	Parent = cuaSo,
})
tao("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 4),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = thanhTab,
})

local noiDung = tao("Frame", {
	Name = "NoiDung",
	Position = UDim2.fromOffset(0, 82),
	Size = UDim2.new(1, 0, 1, -86),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	ZIndex = 3,
	Parent = cuaSo,
})

---------------------------------------------------------------------
-- 13. GIAO DIỆN — THÀNH PHẦN DÙNG CHUNG
---------------------------------------------------------------------
local congTacDS, thanhKeoDS, nutCheDoDS = {}, {}, {}

-- Kéo thả (thanh trượt, chọn màu): một bộ điều phối duy nhất cho cả hệ thống
local Keo = { Hien = nil, Input = nil }
Maid:Them(UserInputService.InputChanged:Connect(function(input)
	local h = Keo.Hien
	if h and (input == Keo.Input or input.UserInputType == Enum.UserInputType.MouseMovement) then
		h.Cap(input.Position.X)
	end
end))
Maid:Them(UserInputService.InputEnded:Connect(function(input)
	if Keo.Hien and (input == Keo.Input or input.UserInputType == Enum.UserInputType.MouseButton1) then
		local h = Keo.Hien
		Keo.Hien, Keo.Input = nil, nil
		h.Xong()
	end
end))

local function ganKeo(vung, khiKeo)
	vung.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if Keo.Hien then Keo.Hien.Xong() end
		local trang = vung:FindFirstAncestorOfClass("ScrollingFrame")
		if trang then trang.ScrollingEnabled = false end -- không cuộn trang khi đang kéo
		Keo.Hien = {
			Cap = khiKeo,
			Xong = function()
				if trang then trang.ScrollingEnabled = true end
			end,
		}
		Keo.Input = input
		khiKeo(input.Position.X)
	end)
end

-- Kéo cửa sổ / nút nổi. khiBam chỉ chạy khi chạm mà không kéo.
local function lamKeoTha(tayCam, muc, khiBam)
	local dang, input0, p0, v0, daKeo = false, nil, nil, nil, false
	tayCam.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dang, input0, p0, v0, daKeo = true, input, input.Position, muc.Position, false
		end
	end)
	Maid:Them(UserInputService.InputChanged:Connect(function(input)
		if dang and (input == input0 or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = input.Position - p0
			if d.Magnitude > 6 then daKeo = true end
			if daKeo then
				muc.Position = UDim2.fromOffset(v0.X.Offset + d.X, v0.Y.Offset + d.Y)
				kepManHinh(muc)
			end
		end
	end))
	Maid:Them(UserInputService.InputEnded:Connect(function(input)
		if dang and (input == input0 or input.UserInputType == Enum.UserInputType.MouseButton1) then
			dang = false
			if not daKeo and khiBam then khiBam() end
		end
	end))
end

local function taoTrang()
	local sf = tao("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = MAU_MAC_DINH[1],
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Active = true,
		Visible = false,
		Parent = noiDung,
	})
	tao("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = sf })
	tao("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 10),
		Parent = sf,
	})
	dangKyChuDe(function(m) sf.ScrollBarImageColor3 = m[1] end)
	return sf
end

local function taoTieuDeMuc(cha, chu)
	local f = tao("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		LayoutOrder = layThuTu(cha),
		Parent = cha,
	})
	local nhan = tao("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		Font = FONT_DAM,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.new(1, 1, 1),
		Text = chu,
		Parent = f,
	})
	local gn = tao("UIGradient", { Parent = nhan })
	dangKyChuDe(function(m) gn.Color = chuoiMau(m) end)
	local duong = tao("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = f,
	})
	bo(duong, 1)
	local gd = tao("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }),
		Parent = duong,
	})
	dangKyChuDe(function(m) gd.Color = chuoiMau(m) end)
	return f
end

local function taoNhan(cha, chu, mau)
	local l = tao("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = FONT,
		TextSize = 15,
		TextColor3 = mau or CHU_MO,
		TextWrapped = true,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = chu,
		LayoutOrder = layThuTu(cha),
		Parent = cha,
	})
	tao("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), Parent = l })
	return l
end

-- Công tắc: tc = { Ten, MoTa?, Doc = function() -> bool, Ghi = function(bool) }
local function taoCongTac(cha, tc)
	local cao = tc.MoTa and 52 or 42
	local hang = tao("Frame", {
		Size = UDim2.new(1, 0, 0, cao),
		BackgroundColor3 = NEN_THE,
		LayoutOrder = layThuTu(cha),
		Parent = cha,
	})
	bo(hang, 9)
	vienMo(hang, VIEN_THE, 1, 0.3)
	tao("TextLabel", {
		Position = UDim2.fromOffset(12, tc.MoTa and 6 or 0),
		Size = UDim2.new(1, -76, 0, tc.MoTa and 22 or cao),
		Font = FONT_DAM,
		TextSize = 18,
		TextColor3 = CHU_SANG,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = tc.Ten,
		Parent = hang,
	})
	if tc.MoTa then
		tao("TextLabel", {
			Position = UDim2.fromOffset(12, 28),
			Size = UDim2.new(1, -76, 0, 18),
			Font = FONT,
			TextSize = 14,
			TextColor3 = CHU_MO,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = tc.MoTa,
			Parent = hang,
		})
	end
	local ray = tao("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(46, 24),
		BackgroundColor3 = Color3.fromRGB(55, 48, 88),
		Parent = hang,
	})
	bo(ray, 12)
	local nut = tao("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = Color3.fromRGB(205, 200, 228),
		Parent = ray,
	})
	bo(nut, 9)
	local bam = tao("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5, Parent = hang })

	local mauBat = ChuDe.Mau[1]
	local htai = nil
	local dt = {}
	function dt.Cap(nhanh)
		local bat = tc.Doc() and true or false
		if htai == bat and not nhanh then return end
		htai = bat
		local gian = nhanh and 0 or 0.16
		tween(ray, gian, { BackgroundColor3 = bat and mauBat or Color3.fromRGB(55, 48, 88) })
		tween(nut, gian, {
			Position = bat and UDim2.new(0, 25, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = bat and Color3.new(1, 1, 1) or Color3.fromRGB(205, 200, 228),
		})
	end
	dangKyChuDe(function(m)
		mauBat = m[1]
		if htai then ray.BackgroundColor3 = mauBat end
	end)
	bam.Activated:Connect(function()
		tc.Ghi(not tc.Doc())
		dongBoUI()
	end)
	congTacDS[#congTacDS + 1] = dt
	dt.Cap(true)
	return dt
end

-- Thanh kéo: tc = { Ten, Min, Max, Buoc, Doc, Ghi, DinhDang?, DatLai? }
local function taoThanhKeo(cha, tc)
	local coDL = tc.DatLai ~= nil
	local hang = tao("Frame", {
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundColor3 = NEN_THE,
		LayoutOrder = layThuTu(cha),
		Parent = cha,
	})
	bo(hang, 9)
	vienMo(hang, VIEN_THE, 1, 0.3)
	tao("TextLabel", {
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.fromOffset(140, 22),
		Font = FONT_DAM,
		TextSize = 18,
		TextColor3 = CHU_SANG,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = tc.Ten,
		Parent = hang,
	})
	local nhanGT = tao("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, coDL and -46 or -12, 0, 6),
		Size = UDim2.fromOffset(200, 22),
		Font = FONT_DAM,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = ChuDe.Mau[3],
		Text = "",
		Parent = hang,
	})
	dangKyChuDe(function(m) nhanGT.TextColor3 = m[3] end)

	if coDL then
		local nutDL = tao("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -8, 0, 5),
			Size = UDim2.fromOffset(32, 24),
			BackgroundColor3 = NEN_THE_SANG,
			Font = FONT_DAM,
			TextSize = 17,
			TextColor3 = CHU_SANG,
			Text = "↺",
			Parent = hang,
		})
		bo(nutDL, 7)
		nutDL.Activated:Connect(function()
			tc.DatLai()
			dongBoUI()
			thongBao("Đã đặt lại về mặc định: " .. tc.Ten, "thong_tin")
		end)
	end

	local vung = tao("TextButton", {
		Position = UDim2.fromOffset(12, 32),
		Size = UDim2.new(1, -24, 0, 28),
		BackgroundTransparency = 1,
		Parent = hang,
	})
	local ray = tao("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 8),
		BackgroundColor3 = Color3.fromRGB(50, 43, 82),
		Parent = vung,
	})
	bo(ray, 4)
	local dien = tao("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = ray })
	bo(dien, 4)
	local gDien = tao("UIGradient", { Parent = dien })
	dangKyChuDe(function(m) gDien.Color = ColorSequence.new(m[1], m[3]) end)
	local nut = tao("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 2,
		Parent = ray,
	})
	bo(nut, 9)
	local stNut = vienMo(nut, ChuDe.Mau[1], 2, 0)
	dangKyChuDe(function(m) stNut.Color = m[1] end)

	local function theoX(x)
		local ti = math.clamp((x - ray.AbsolutePosition.X) / math.max(ray.AbsoluteSize.X, 1), 0, 1)
		local b = tc.Buoc or 1
		local v = math.floor((tc.Min + ti * (tc.Max - tc.Min)) / b + 0.5) * b
		return math.clamp(v, tc.Min, tc.Max)
	end

	local dt = {}
	function dt.Cap()
		local v = tc.Doc()
		local ti = math.clamp((v - tc.Min) / (tc.Max - tc.Min), 0, 1)
		dien.Size = UDim2.fromScale(ti, 1)
		nut.Position = UDim2.fromScale(ti, 0.5)
		nhanGT.Text = tc.DinhDang and tc.DinhDang(v) or tostring(v)
	end
	ganKeo(vung, function(x)
		tc.Ghi(theoX(x))
		dt.Cap()
		capNhatBangTrangThai()
	end)
	thanhKeoDS[#thanhKeoDS + 1] = dt
	dt.Cap()
	return dt
end

-- Nút có nền gradient tuỳ chọn (chữ luôn rõ, không bị gradient nhuộm màu)
local function taoNutKep(cha, tc)
	local nut = tao("TextButton", {
		Size = tc.Size,
		LayoutOrder = tc.LayoutOrder or layThuTu(cha),
		BackgroundTransparency = 1,
		ZIndex = tc.ZIndex or 1,
		Parent = cha,
	})
	local nen = tao("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = NEN_THE_SANG, Parent = nut })
	bo(nen, tc.BoGoc or 9)
	local gr = tao("UIGradient", { Enabled = false, Parent = nen })
	dangKyChuDe(function(m) gr.Color = ColorSequence.new(m[1], m[2]) end)
	local st = vienMo(nen, VIEN_THE, 1, 0.2)
	local chu = tao("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		Font = FONT_DAM,
		TextSize = tc.CoChu or 17,
		TextColor3 = CHU_SANG,
		Text = tc.Chu,
		ZIndex = 2,
		Parent = nut,
	})
	local k = { Nut = nut, Nen = nen, Chu = chu, Gr = gr, St = st }
	function k.DatChon(chon)
		gr.Enabled = chon
		nen.BackgroundColor3 = chon and Color3.new(1, 1, 1) or NEN_THE_SANG
		st.Transparency = chon and 1 or 0.2
		chu.TextColor3 = chon and Color3.new(1, 1, 1) or CHU_SANG
	end
	return k
end

-- Nút hành động. kieu: "chinh" (gradient) | "nguy" (đỏ) | nil (tối)
local function taoNut(cha, chu, khiBam, kieu)
	local k = taoNutKep(cha, { Size = UDim2.new(1, 0, 0, 40), Chu = chu })
	if kieu == "chinh" then
		k.DatChon(true)
	elseif kieu == "nguy" then
		k.Nen.BackgroundColor3 = Color3.fromRGB(176, 44, 70)
		k.St.Transparency = 1
	end
	local function nhan(i)
		return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
	end
	k.Nut.InputBegan:Connect(function(i)
		if nhan(i) then tween(k.Nen, 0.08, { BackgroundTransparency = 0.3 }) end
	end)
	k.Nut.InputEnded:Connect(function(i)
		if nhan(i) then tween(k.Nen, 0.12, { BackgroundTransparency = 0 }) end
	end)
	k.Nut.Activated:Connect(khiBam)
	return k
end

local MAU_CHON = {
	Color3.fromRGB(168, 85, 247),
	Color3.fromRGB(236, 72, 153),
	Color3.fromRGB(34, 211, 238),
	Color3.fromRGB(74, 222, 128),
	Color3.fromRGB(250, 204, 21),
	Color3.fromRGB(251, 146, 60),
	Color3.fromRGB(248, 113, 113),
	Color3.fromRGB(255, 255, 255),
}

-- Chọn màu: tc = { Ten, Doc = function() -> Color3, Ghi = function(Color3|nil), CoMacDinh? }
local function taoChonMau(cha, tc)
	local hang = tao("Frame", {
		Size = UDim2.new(1, 0, 0, 102),
		BackgroundColor3 = NEN_THE,
		LayoutOrder = layThuTu(cha),
		Parent = cha,
	})
	bo(hang, 9)
	vienMo(hang, VIEN_THE, 1, 0.3)
	tao("TextLabel", {
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -24, 0, 22),
		Font = FONT_DAM,
		TextSize = 18,
		TextColor3 = CHU_SANG,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = tc.Ten,
		Parent = hang,
	})
	local hangMau = tao("Frame", {
		Position = UDim2.fromOffset(12, 32),
		Size = UDim2.new(1, -24, 0, 28),
		BackgroundTransparency = 1,
		Parent = hang,
	})
	tao("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = hangMau,
	})
	if tc.CoMacDinh then
		local m = tao("TextButton", {
			LayoutOrder = 0,
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = hangMau,
		})
		bo(m, 14)
		tao("UIGradient", { Color = chuoiMau(MAU_MAC_DINH), Rotation = 45, Parent = m })
		vienMo(m, CHU_SANG, 1.5, 0.2)
		m.Activated:Connect(function()
			tc.Ghi(nil)
			dongBoUI()
		end)
	end
	for i, c in ipairs(MAU_CHON) do
		local m = tao("TextButton", {
			LayoutOrder = i,
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = c,
			Parent = hangMau,
		})
		bo(m, 14)
		vienMo(m, CHU_SANG, 1.5, 0.5)
		m.Activated:Connect(function()
			tc.Ghi(c)
			dongBoUI()
		end)
	end

	-- Thanh chọn sắc độ (cầu vồng)
	local vung = tao("TextButton", {
		Position = UDim2.fromOffset(12, 66),
		Size = UDim2.new(1, -24, 0, 28),
		BackgroundTransparency = 1,
		Parent = hang,
	})
	local ray = tao("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = vung,
	})
	bo(ray, 5)
	local diem = {}
	for i = 0, 6 do
		diem[#diem + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((i / 6) % 1, 0.8, 1))
	end
	tao("UIGradient", { Color = ColorSequence.new(diem), Parent = ray })
	local nut = tao("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 2,
		Parent = ray,
	})
	bo(nut, 9)
	vienMo(nut, Color3.fromRGB(20, 16, 36), 2, 0)

	local dt = {}
	function dt.Cap()
		local h = tc.Doc():ToHSV()
		nut.Position = UDim2.fromScale(h, 0.5)
	end
	ganKeo(vung, function(x)
		local ti = math.clamp((x - ray.AbsolutePosition.X) / math.max(ray.AbsoluteSize.X, 1), 0, 1)
		tc.Ghi(Color3.fromHSV(ti, 0.78, 1))
		nut.Position = UDim2.fromScale(ti, 0.5)
	end)
	thanhKeoDS[#thanhKeoDS + 1] = dt
	dt.Cap()
	return dt
end

local function taoNutCheDo(cha, chu, id)
	local k = taoNutKep(cha, { Size = UDim2.fromOffset(100, 38), Chu = chu })
	local dt = {}
	function dt.Cap() k.DatChon(TT.CongCu.CheDo == id) end
	k.Nut.Activated:Connect(function() datCheDoCongCu(id) end)
	nutCheDoDS[#nutCheDoDS + 1] = dt
	dt.Cap()
	return k
end

---------------------------------------------------------------------
-- 14. TAB & TRANG
---------------------------------------------------------------------
local DS_TAB = {
	{ id = "DiChuyen", ten = "🚀 Di chuyển" },
	{ id = "ESP", ten = "🔍 ESP" },
	{ id = "NguoiChoi", ten = "🎯 Người chơi" },
	{ id = "CaiDat", ten = "🔧 Cài đặt" },
}
local trang, nutTab = {}, {}
local chonTab

for i, t in ipairs(DS_TAB) do
	local k = taoNutKep(thanhTab, {
		Size = UDim2.new(0.25, -3, 1, 0),
		LayoutOrder = i,
		Chu = t.ten,
		CoChu = 16,
		BoGoc = 8,
		ZIndex = 4,
	})
	nutTab[t.id] = k
	trang[t.id] = taoTrang()
	k.Nut.Activated:Connect(function() chonTab(t.id) end)
end

chonTab = function(id)
	for _, t in ipairs(DS_TAB) do
		local chon = t.id == id
		trang[t.id].Visible = chon
		nutTab[t.id].DatChon(chon)
	end
	if id == "NguoiChoi" then
		lamMoiDanhSach()
		dongBoUI()
	end
end

local nhanTrangThai, nhanBanner, nhanMucTieu, nhanCheDo

-- ===== TAB DI CHUYỂN =====
do
	local p = trang.DiChuyen
	taoTieuDeMuc(p, "⚡ Bay")
	taoCongTac(p, {
		Ten = "Bay",
		MoTa = "Bay theo hướng camera · nút ▲ ▼ ở cạnh phải",
		Doc = function() return TT.Bay.Bat end,
		Ghi = function(v)
			if v then batBay() else tatBay(false) end
		end,
	})
	taoThanhKeo(p, {
		Ten = "Tốc độ bay",
		Min = 10,
		Max = 300,
		Buoc = 5,
		Doc = function() return TT.Bay.TocDo end,
		Ghi = function(v) TT.Bay.TocDo = v end,
		DinhDang = function(v) return dinhDangSo(v) end,
		DatLai = function() TT.Bay.TocDo = 60 end,
	})
	taoTieuDeMuc(p, "👻 Xuyên vật thể")
	taoCongTac(p, {
		Ten = "Xuyên vật thể",
		MoTa = "Đi xuyên tường để kiểm thử va chạm",
		Doc = function() return TT.Noclip.Bat end,
		Ghi = function(v)
			if v then batNoclip() else tatNoclip(false) end
		end,
	})
	taoTieuDeMuc(p, "🏃 Tốc độ chạy")
	taoThanhKeo(p, {
		Ten = "Tốc độ chạy",
		Min = 4,
		Max = 250,
		Buoc = 1,
		Doc = function() return TT.TocDoChay.TuyChinh or MacDinhNV.TocDo end,
		Ghi = datTocDo,
		DinhDang = function(v) return dinhDangSo(v) .. "  ·  gốc " .. dinhDangSo(MacDinhNV.TocDo) end,
		DatLai = datLaiTocDo,
	})
	taoTieuDeMuc(p, "⏫ Độ cao nhảy")
	taoThanhKeo(p, {
		Ten = "Độ cao nhảy",
		Min = 0,
		Max = 300,
		Buoc = 1,
		Doc = function() return TT.Nhay.TuyChinh or jumpPowerMacDinh() end,
		Ghi = datNhay,
		DinhDang = function(v) return dinhDangSo(v) .. "  ·  gốc " .. dinhDangSo(jumpPowerMacDinh()) end,
		DatLai = datLaiNhay,
	})
end

-- ===== TAB ESP =====
do
	local p = trang.ESP
	taoTieuDeMuc(p, "🔍 Hiển thị người chơi")
	taoCongTac(p, {
		Ten = "Bật ESP",
		MoTa = "Chỉ hiện trên màn hình của bạn",
		Doc = function() return TT.ESP.Bat end,
		Ghi = batESP,
	})
	taoCongTac(p, {
		Ten = "Hiển thị tên",
		Doc = function() return TT.ESP.Ten end,
		Ghi = function(v) TT.ESP.Ten = v end,
	})
	taoCongTac(p, {
		Ten = "Hiển thị khoảng cách",
		Doc = function() return TT.ESP.KhoangCach end,
		Ghi = function(v) TT.ESP.KhoangCach = v end,
	})
	taoCongTac(p, {
		Ten = "Viền sáng",
		MoTa = "Tối đa 30 người gần nhất",
		Doc = function() return TT.ESP.VienSang end,
		Ghi = function(v) TT.ESP.VienSang = v end,
	})
	taoThanhKeo(p, {
		Ten = "Phạm vi hiển thị",
		Min = 50,
		Max = 3000,
		Buoc = 50,
		Doc = function() return TT.ESP.PhamVi end,
		Ghi = function(v) TT.ESP.PhamVi = v end,
		DinhDang = function(v) return dinhDangSo(v) .. " stud" end,
		DatLai = function() TT.ESP.PhamVi = 1000 end,
	})
	taoChonMau(p, {
		Ten = "Màu ESP",
		Doc = function() return TT.ESP.Mau end,
		Ghi = function(c)
			TT.ESP.Mau = c
			capNhatMauESP()
		end,
	})
end

-- ===== TAB NGƯỜI CHƠI =====
local khungDS, hopTim
local tuKhoa = ""
do
	local p = trang.NguoiChoi
	taoTieuDeMuc(p, "🎯 Công cụ người chơi")
	nhanBanner = taoNhan(p, "", CHU_MO)
	nhanMucTieu = taoNhan(p, "", CHU_SANG)
	nhanCheDo = taoNhan(p, "", CHU_MO)
	taoNut(p, "⛔ DỪNG NGAY", function() dungCongCu(false) end, "nguy")

	local luoi = tao("Frame", {
		Size = UDim2.new(1, 0, 0, 82),
		BackgroundTransparency = 1,
		LayoutOrder = layThuTu(p),
		Parent = p,
	})
	tao("UIGridLayout", {
		CellSize = UDim2.new(0.5, -3, 0, 38),
		CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = luoi,
	})
	taoNutCheDo(luoi, "Theo dõi", "TheoDoi")
	taoNutCheDo(luoi, "Vòng tròn", "VongTron")
	taoNutCheDo(luoi, "Phía sau", "PhiaSau")
	taoNutCheDo(luoi, "Bên dưới", "BenDuoi")

	taoThanhKeo(p, {
		Ten = "Khoảng cách",
		Min = 2,
		Max = 30,
		Buoc = 1,
		Doc = function() return TT.CongCu.KhoangCach end,
		Ghi = function(v) TT.CongCu.KhoangCach = v end,
		DinhDang = function(v) return dinhDangSo(v) .. " stud" end,
		DatLai = function() TT.CongCu.KhoangCach = 6 end,
	})
	taoThanhKeo(p, {
		Ten = "Bán kính vòng tròn",
		Min = 3,
		Max = 40,
		Buoc = 1,
		Doc = function() return TT.CongCu.BanKinh end,
		Ghi = function(v) TT.CongCu.BanKinh = v end,
		DinhDang = function(v) return dinhDangSo(v) .. " stud" end,
		DatLai = function() TT.CongCu.BanKinh = 10 end,
	})
	taoThanhKeo(p, {
		Ten = "Tốc độ di chuyển",
		Min = 0.5,
		Max = 10,
		Buoc = 0.5,
		Doc = function() return TT.CongCu.TocDo end,
		Ghi = function(v) TT.CongCu.TocDo = v end,
		DinhDang = function(v) return dinhDangSo(v, 1) end,
		DatLai = function() TT.CongCu.TocDo = 2 end,
	})

	taoTieuDeMuc(p, "👥 Danh sách người chơi")
	hopTim = tao("TextBox", {
		LayoutOrder = layThuTu(p),
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = NEN_THE,
		Font = FONT,
		TextSize = 16,
		TextColor3 = CHU_SANG,
		PlaceholderText = "🔍 Tìm người chơi…",
		PlaceholderColor3 = CHU_MO,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
		Parent = p,
	})
	bo(hopTim, 8)
	vienMo(hopTim, VIEN_THE, 1, 0.3)
	tao("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = hopTim })
	khungDS = tao("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = layThuTu(p),
		Parent = p,
	})
	tao("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = khungDS })
end

lamMoiDanhSach = function(boQua)
	if DaHuy or not khungDS then return end
	for _, c in ipairs(khungDS:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	local ds = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p ~= boQua then ds[#ds + 1] = p end
	end
	table.sort(ds, function(a, b) return string.lower(a.DisplayName) < string.lower(b.DisplayName) end)
	local dem = 0
	for _, p in ipairs(ds) do
		local ten = p.DisplayName .. "  (@" .. p.Name .. ")"
		if tuKhoa == "" or string.find(string.lower(ten), tuKhoa, 1, true) then
			dem = dem + 1
			local chon = TT.CongCu.MucTieu == p
			local nut = tao("TextButton", {
				LayoutOrder = dem,
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundColor3 = chon and NEN_THE_SANG or NEN_THE,
				Font = FONT_DAM,
				TextSize = 16,
				TextColor3 = chon and Color3.new(1, 1, 1) or CHU_SANG,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = (chon and "🎯 " or "") .. ten,
				Parent = khungDS,
			})
			bo(nut, 8)
			tao("UIPadding", { PaddingLeft = UDim.new(0, 12), Parent = nut })
			vienMo(nut, chon and ChuDe.Mau[1] or VIEN_THE, chon and 2 or 1, chon and 0 or 0.4)
			nut.Activated:Connect(function() datMucTieu(p) end)
		end
	end
	if dem == 0 then
		tao("TextLabel", {
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 30),
			Font = FONT,
			TextSize = 15,
			TextColor3 = CHU_MO,
			Text = tuKhoa ~= "" and "Không tìm thấy người chơi phù hợp" or "Chưa có người chơi nào khác trong máy chủ",
			Parent = khungDS,
		})
	end
end
hopTim:GetPropertyChangedSignal("Text"):Connect(function()
	tuKhoa = string.lower(hopTim.Text)
	lamMoiDanhSach()
end)

-- ===== TAB CÀI ĐẶT =====
local capNhatTyLe
local khoiPhucCaiDat
local goBo
do
	local p = trang.CaiDat
	taoTieuDeMuc(p, "🔧 Giao diện")
	taoChonMau(p, {
		Ten = "Màu giao diện",
		CoMacDinh = true,
		Doc = function() return ChuDe.Mau[1] end,
		Ghi = function(c)
			if c == nil then
				datChuDe(MAU_MAC_DINH)
			else
				local function lech(col, d)
					local h, s, v = col:ToHSV()
					return Color3.fromHSV((h + d) % 1, math.clamp(s, 0.45, 1), math.max(v, 0.85))
				end
				datChuDe({ c, lech(c, 0.17), lech(c, -0.23) })
			end
		end,
	})
	taoCongTac(p, {
		Ten = "Hiệu ứng động (animation)",
		MoTa = "Sét, viền chuyển màu, chuyển cảnh",
		Doc = function() return TT.CaiDat.HoatAnh end,
		Ghi = datHoatAnh,
	})
	taoThanhKeo(p, {
		Ten = "Kích thước giao diện",
		Min = 0.7,
		Max = 1.3,
		Buoc = 0.05,
		Doc = function() return TT.CaiDat.TyLe end,
		Ghi = function(v)
			TT.CaiDat.TyLe = v
			capNhatTyLe()
		end,
		DinhDang = function(v) return dinhDangSo(v * 100) .. "%" end,
		DatLai = function()
			TT.CaiDat.TyLe = 1
			capNhatTyLe()
		end,
	})

	taoTieuDeMuc(p, "📊 Trạng thái hoạt động")
	local the = tao("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = NEN_THE,
		LayoutOrder = layThuTu(p),
		Parent = p,
	})
	bo(the, 9)
	vienMo(the, VIEN_THE, 1, 0.3)
	tao("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = the,
	})
	nhanTrangThai = tao("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = FONT,
		TextSize = 16,
		TextColor3 = CHU_SANG,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		RichText = true,
		Text = "",
		Parent = the,
	})

	taoTieuDeMuc(p, "🧰 Hành động")
	taoNut(p, "Tắt tất cả chức năng", function() tatTatCa(false) end)
	taoNut(p, "Khôi phục cài đặt mặc định", function() khoiPhucCaiDat() end, "chinh")
	local lanBamGoBo = 0
	taoNut(p, "Gỡ Zenvolt Hub", function()
		if os.clock() - lanBamGoBo < 3 then
			goBo()
		else
			lanBamGoBo = os.clock()
			thongBao("Bấm “Gỡ Zenvolt Hub” thêm lần nữa trong 3 giây để xác nhận", "canh_bao")
		end
	end, "nguy")

	taoTieuDeMuc(p, "📖 Hướng dẫn nhanh")
	taoNhan(
		p,
		"• Chạm <b>⚡</b> để mở/ẩn bảng; kéo <b>⚡</b> hoặc thanh tiêu đề để di chuyển.\n"
			.. "• <b>Bay</b>: bật công tắc, đẩy cần điều khiển theo hướng camera; giữ <b>▲ ▼</b> để lên/xuống.\n"
			.. "• <b>Người chơi</b>: chọn mục tiêu rồi chọn chế độ; <b>DỪNG NGAY</b> dừng tức thì.\n"
			.. "• Nếu game có anti-cheat phía server, một số giá trị có thể bị game đặt lại.",
		CHU_MO
	)
end

---------------------------------------------------------------------
-- 15. ĐỒNG BỘ GIAO DIỆN VỚI TRẠNG THÁI
---------------------------------------------------------------------
local bangBay -- khung nút ▲ ▼

local function capNhatBanner()
	if not nhanBanner then return end
	if kiemTraChoPhep() then
		nhanBanner.Text = '<font color="#4ade80">✅ Đã mở khóa.</font> Môi trường được phép — công cụ hoạt động. Công cụ chỉ di chuyển nhân vật của bạn.'
	else
		nhanBanner.Text = '<font color="#fbbf24">🔒 Đang khóa.</font> Chỉ chạy trong Studio hoặc khi chủ game bật thuộc tính <b>'
			.. CAU_HINH.THUOC_TINH_CHO_PHEP
			.. '</b> = true (trên ReplicatedStorage hoặc Workspace) bằng Script phía server.'
	end
end

capNhatNhanCongCu = function()
	if DaHuy or not nhanMucTieu then return end
	local mt = TT.CongCu.MucTieu
	local ten = mt and thoatRT(mt.DisplayName .. " (@" .. mt.Name .. ")") or "chưa chọn"
	nhanMucTieu.Text = "🎯 Mục tiêu: <b>" .. ten .. "</b>"
	local cd = TT.CongCu.CheDo
	if cd then
		nhanCheDo.Text = (CongCu.TrangThai ~= "" and CongCu.TrangThai or ("Đang chạy: " .. TEN_CHE_DO[cd]))
	else
		nhanCheDo.Text = "Trạng thái: đang dừng"
	end
end

capNhatBangTrangThai = function()
	if DaHuy or not nhanTrangThai then return end
	local function bat(b)
		return b and '<font color="#4ade80">BẬT</font>' or '<font color="#8b85a8">TẮT</font>'
	end
	local function so(v) return '<font color="#22d3ee">' .. dinhDangSo(v) .. "</font>" end
	local soNguoi = 0
	for _ in pairs(ESP.Muc) do soNguoi = soNguoi + 1 end
	local cd = TT.CongCu.CheDo
	local dong = {
		"⚡ Bay: " .. bat(TT.Bay.Bat) .. (TT.Bay.Bat and ("  ·  tốc độ " .. so(TT.Bay.TocDo)) or ""),
		"👻 Xuyên vật thể: " .. bat(TT.Noclip.Bat),
		"🏃 Tốc độ chạy: " .. (TT.TocDoChay.TuyChinh and so(TT.TocDoChay.TuyChinh) or "mặc định"),
		"⏫ Độ cao nhảy: " .. (TT.Nhay.TuyChinh and so(TT.Nhay.TuyChinh) or "mặc định"),
		"🔍 ESP: " .. bat(TT.ESP.Bat) .. (TT.ESP.Bat and ("  ·  " .. soNguoi .. " người") or ""),
		"🎯 Công cụ người chơi: "
			.. (cd and ('<font color="#4ade80">' .. TEN_CHE_DO[cd] .. "</font>") or '<font color="#8b85a8">dừng</font>'),
	}
	nhanTrangThai.Text = table.concat(dong, "\n")
end

dongBoUI = function()
	if DaHuy then return end
	for _, ct in ipairs(congTacDS) do ct.Cap(false) end
	for _, tk in ipairs(thanhKeoDS) do tk.Cap() end
	for _, nm in ipairs(nutCheDoDS) do nm.Cap() end
	if bangBay then bangBay.Visible = TT.Bay.Bat end
	capNhatBanner()
	capNhatNhanCongCu()
	capNhatBangTrangThai()
end

---------------------------------------------------------------------
-- 16. THÔNG BÁO (toast)
---------------------------------------------------------------------
local khungTB = tao("Frame", {
	Name = "ThongBao",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 12),
	Size = UDim2.fromOffset(310, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	ZIndex = 50,
	Parent = gui,
})
tao("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 6),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Parent = khungTB,
})
local demTB = 0
local MAU_TB = { thanh_cong = MAU_TOT, loi = MAU_XAU, canh_bao = MAU_CB }

thongBao = function(noiDung, loai)
	if DaHuy then return end
	local mau = MAU_TB[loai or ""] or ChuDe.Mau[3]
	demTB = demTB + 1
	local the = tao("Frame", {
		LayoutOrder = demTB,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(18, 14, 34),
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = khungTB,
	})
	bo(the, 10)
	local st = vienMo(the, mau, 1.5, 1)
	tao("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = the,
	})
	local nhan = tao("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = FONT_DAM,
		TextSize = 16,
		TextColor3 = CHU_SANG,
		TextTransparency = 1,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = noiDung,
		ZIndex = 51,
		Parent = the,
	})
	tween(the, 0.18, { BackgroundTransparency = 0.08 })
	tween(st, 0.18, { Transparency = 0.1 })
	tween(nhan, 0.18, { TextTransparency = 0 })

	local ds = {}
	for _, c in ipairs(khungTB:GetChildren()) do
		if c:IsA("Frame") then ds[#ds + 1] = c end
	end
	table.sort(ds, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
	while #ds > 4 do
		table.remove(ds, 1):Destroy()
	end

	task.delay(2.8, function()
		if the.Parent then
			tween(the, 0.25, { BackgroundTransparency = 1 })
			tween(st, 0.25, { Transparency = 1 })
			tween(nhan, 0.25, { TextTransparency = 1 })
			task.delay(0.3, function()
				if the.Parent then the:Destroy() end
			end)
		end
	end)
end

---------------------------------------------------------------------
-- 17. MỞ / ĐÓNG / THU NHỎ / KÍCH THƯỚC
---------------------------------------------------------------------
local DaMo, DangThuNho = true, false

local function datMoCua(bat)
	if bat == DaMo then return end
	DaMo = bat
	if bat then
		khung.Visible = true
		uiScaleMo.Scale = 0.88
		tween(uiScaleMo, 0.22, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		task.defer(kepManHinh, khung)
	else
		tween(uiScaleMo, 0.15, { Scale = 0.88 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.16, function()
			if not DaMo then khung.Visible = false end
		end)
	end
end

local function datThuNho(thu)
	DangThuNho = thu
	nutThuNho.Text = thu and "+" or "—"
	if not thu then
		thanhTab.Visible = true
		noiDung.Visible = true
	end
	tween(khung, 0.2, { Size = UDim2.fromOffset(W, thu and 38 or H) })
	if thu then
		task.delay(0.22, function()
			if DangThuNho then
				thanhTab.Visible = false
				noiDung.Visible = false
			end
		end)
	end
	task.delay(0.25, function() kepManHinh(khung) end)
end

capNhatTyLe = function()
	local vp = kichThuocManHinh()
	local vua = math.min((vp.X - 12) / W, (vp.Y - 12) / H)
	local co = math.clamp(math.min(1, vua) * TT.CaiDat.TyLe, 0.45, math.max(0.45, vua))
	uiScaleNguoiDung.Scale = co
	task.defer(kepManHinh, khung)
end

nutDong.Activated:Connect(function()
	datMoCua(false)
	thongBao("Đã ẩn bảng — chạm ⚡ để mở lại", "thong_tin")
end)
nutThuNho.Activated:Connect(function() datThuNho(not DangThuNho) end)
lamKeoTha(thanhTieuDe, khung)

---------------------------------------------------------------------
-- 18. NÚT NỔI ⚡ & NÚT BAY LÊN/XUỐNG
---------------------------------------------------------------------
local nutNoi = tao("Frame", {
	Name = "NutNoi",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(60, 140),
	Size = UDim2.fromOffset(52, 52),
	BackgroundColor3 = Color3.fromRGB(18, 13, 34),
	Active = true,
	ZIndex = 20,
	Parent = gui,
})
bo(nutNoi, 26)
vienNeon(nutNoi, 2.5, 0)
tao("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	Font = FONT_DAM,
	TextSize = 28,
	TextColor3 = Color3.new(1, 1, 1),
	Text = "⚡",
	ZIndex = 21,
	Parent = nutNoi,
})
do -- vòng sáng lan toả quanh nút
	local vong = tao("Frame", {
		Name = "VongSang",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(52, 52),
		BackgroundTransparency = 1,
		ZIndex = 19,
		Parent = nutNoi,
	})
	bo(vong, 40)
	local st = vienMo(vong, ChuDe.Mau[3], 2, 0.2)
	dangKyChuDe(function(m) st.Color = m[3] end)
	dangKyVoHan(vong, "Size", UDim2.fromOffset(52, 52), UDim2.fromOffset(84, 84), 1.8, false, UDim2.fromOffset(52, 52))
	dangKyVoHan(st, "Transparency", 0.2, 1, 1.8, false, 1)
end
lamKeoTha(nutNoi, nutNoi, function() datMoCua(not DaMo) end)

bangBay = tao("Frame", {
	Name = "BangBay",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0.5, 20),
	Size = UDim2.fromOffset(60, 130),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 15,
	Parent = gui,
})
do
	local function taoNutGiu(chu, y, khiDoi)
		local n = tao("TextButton", {
			Position = UDim2.fromOffset(0, y),
			Size = UDim2.fromOffset(60, 60),
			BackgroundColor3 = Color3.fromRGB(20, 15, 38),
			BackgroundTransparency = 0.1,
			Font = FONT_DAM,
			TextSize = 26,
			TextColor3 = CHU_SANG,
			Text = chu,
			ZIndex = 16,
			Parent = bangBay,
		})
		bo(n, 30)
		vienNeon(n, 2, 0)
		local dangGiu = nil
		n.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dangGiu = i
				khiDoi(true)
			end
		end)
		Maid:Them(UserInputService.InputEnded:Connect(function(i)
			if dangGiu and (i == dangGiu or i.UserInputType == Enum.UserInputType.MouseButton1) then
				dangGiu = nil
				khiDoi(false)
			end
		end))
	end
	taoNutGiu("▲", 0, function(v) Bay.NutLen = v end)
	taoNutGiu("▼", 70, function(v) Bay.NutXuong = v end)
end

---------------------------------------------------------------------
-- 19. HIỆU ỨNG SẤM SÉT
---------------------------------------------------------------------
local function doanSet(cha, a, b, doDay, mau, doTrong)
	local d = b - a
	return tao("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2),
		Size = UDim2.fromOffset(d.Magnitude + 1.5, doDay),
		Rotation = math.deg(math.atan2(d.Y, d.X)),
		BackgroundColor3 = mau,
		BackgroundTransparency = doTrong,
		Parent = cha,
	})
end

local function taoTiaSet()
	if DaHuy or not TT.CaiDat.HoatAnh or not DaMo or DangThuNho then return end
	local nhom = tao("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = lopSet })
	local x = math.random(24, W - 24)
	local yCuoi = math.random(120, H - 30)
	local n = math.random(6, 9)
	local diem = { Vector2.new(x, 0) }
	for i = 1, n do
		x = math.clamp(x + math.random(-28, 28), 6, W - 6)
		diem[#diem + 1] = Vector2.new(x, yCuoi * i / n)
	end
	local mauLoi = Color3.fromRGB(236, 244, 255)
	local mauQuang = ChuDe.Mau[3]
	local mauPhu = ChuDe.Mau[1]
	local doan = {}
	for i = 1, #diem - 1 do
		doan[#doan + 1] = doanSet(nhom, diem[i], diem[i + 1], 8, mauQuang, 0.8)
		doan[#doan + 1] = doanSet(nhom, diem[i], diem[i + 1], 2, mauLoi, 0.05)
	end
	-- nhánh phụ
	local k = math.random(2, #diem - 2)
	local p0 = diem[k]
	local huong = (math.random() < 0.5) and -1 or 1
	for _ = 1, 3 do
		local p1 = Vector2.new(math.clamp(p0.X + huong * math.random(10, 24), 6, W - 6), p0.Y + math.random(14, 26))
		doan[#doan + 1] = doanSet(nhom, p0, p1, 5, mauPhu, 0.85)
		doan[#doan + 1] = doanSet(nhom, p0, p1, 1.5, mauLoi, 0.2)
		p0 = p1
	end
	doan[#doan + 1] = tao("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = mauQuang,
		BackgroundTransparency = 0.9,
		Parent = nhom,
	})
	for _, f in ipairs(doan) do
		tween(f, 0.45, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
	task.delay(0.55, function() nhom:Destroy() end)
end

task.spawn(function()
	task.wait(0.8)
	pcall(taoTiaSet)
	while not DaHuy do
		task.wait(math.random(30, 70) / 10)
		if DaHuy then break end
		pcall(taoTiaSet)
	end
end)

---------------------------------------------------------------------
-- 20. GỠ HUB, KHÔI PHỤC CÀI ĐẶT
---------------------------------------------------------------------
khoiPhucCaiDat = function()
	TT.CaiDat.TyLe = 1
	datHoatAnh(true)
	datChuDe(MAU_MAC_DINH)
	capNhatTyLe()
	dongBoUI()
	thongBao("Đã khôi phục cài đặt mặc định", "thanh_cong")
end

goBo = function()
	gui:Destroy() -- sự kiện Destroying bên dưới sẽ dọn dẹp toàn bộ
end

---------------------------------------------------------------------
-- 21. KẾT NỐI SỰ KIỆN & KHỞI ĐỘNG
---------------------------------------------------------------------
-- Phím tắt (PC)
Maid:Them(UserInputService.InputBegan:Connect(function(input, daXuLy)
	if daXuLy then return end
	local ph = input.KeyCode
	if ph == CAU_HINH.PHIM_LEN then
		Bay.PhimLen = true
	elseif ph == CAU_HINH.PHIM_XUONG then
		Bay.PhimXuong = true
	elseif ph == CAU_HINH.PHIM_AN_HIEN then
		datMoCua(not DaMo)
	end
end))
Maid:Them(UserInputService.InputEnded:Connect(function(input)
	local ph = input.KeyCode
	if ph == CAU_HINH.PHIM_LEN then
		Bay.PhimLen = false
	elseif ph == CAU_HINH.PHIM_XUONG then
		Bay.PhimXuong = false
	end
end))

-- Danh sách người chơi + mục tiêu rời game
Maid:Them(Players.PlayerAdded:Connect(function() lamMoiDanhSach() end))
Maid:Them(Players.PlayerRemoving:Connect(khiNguoiRoi))

-- Nhân vật mới (hồi sinh / reset)
local function khiNhanVatMoi(char)
	MaidNV:Don()
	VaCham.gan(char)
	task.spawn(function()
		local hum = char:WaitForChild("Humanoid", 15)
		local hrp = char:WaitForChild("HumanoidRootPart", 15)
		if DaHuy or LocalPlayer.Character ~= char or not hum or not hrp then return end
		ghiMacDinh(hum)
		apDungTocDoNhay()
		capNhatVongDuyTri()
		MaidNV:Them(hum.Died:Connect(function()
			if TT.Bay.Bat then dungVatLyBay() end -- giữ công tắc, tự bay lại khi hồi sinh
		end))
		if TT.Bay.Bat then batVatLyBay() end
		dongBoUI()
	end)
end
Maid:Them(LocalPlayer.CharacterAdded:Connect(khiNhanVatMoi))
Maid:Them(LocalPlayer.CharacterRemoving:Connect(function()
	if TT.Bay.Bat then donVatLyBay() end
end))

-- Kích thước / xoay màn hình
Maid:Them(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	capNhatTyLe()
	kepManHinh(nutNoi)
end))
Maid:Them(khung:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	kepManHinh(khung)
end))

gui.Destroying:Connect(donDepTatCa)

-- Vị trí ban đầu
do
	local vp = kichThuocManHinh()
	khung.Position = UDim2.fromOffset(vp.X / 2, math.max(8, (vp.Y - H) / 2))
	nutNoi.Position = UDim2.fromOffset(vp.X - 44, vp.Y * 0.32)
end
chonTab("DiChuyen")
capNhatTyLe()
if LocalPlayer.Character then khiNhanVatMoi(LocalPlayer.Character) end
lamMoiDanhSach()
dongBoUI()
thongBao("Chào mừng đến Zenvolt Hub — chạm ⚡ để ẩn/hiện bảng", "thanh_cong")
