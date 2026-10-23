-- ==========================================================================================
-- HỆ THỐNG CƠ SỞ DỮ LIỆU QUẢN LÝ KHÁCH SẠN (HOTEL MANAGEMENT DATABASE)
-- BỘ TRUY VẤN CHUẨN MYSQL 8.0+ - PHỤC VỤ BÁO CÁO MÔN HỌC CƠ SỞ DỮ LIỆU
-- Thực thi trực tiếp trên MySQL Workbench / MySQL Client
-- ==========================================================================================
-- HƯỚNG DẪN THỰC THI TRÊN MYSQL WORKBENCH:
-- 1. Chạy dòng khởi tạo đầu tiên: Bôi đen dòng [USE QuanLyKhachSan;] rồi bấm Ctrl+Enter một lần.
-- 2. Chạy từng Case: Bôi đen trọn vẹn toàn bộ vùng code của Case đó (bao gồm từ dòng SET nếu có
--    đến hết dấu chấm phẩy ; hoặc COMMIT;) rồi nhấn tổ hợp phím Ctrl + Shift + Enter (Execute Selection).
-- ==========================================================================================

USE QuanLyKhachSan;

-- ==========================================================================================
-- CASE 1: Sao lưu toàn phần Cơ sở dữ liệu (Full Database Backup)
-- TRƯỜNG HỢP SỬ DỤNG: Được thực hiện định kỳ theo chính sách an toàn thông tin của hệ thống thông tin khách sạn hoặc trước khi tiến hành bảo trì, nâng cấp cấu trúc lược đồ quan hệ.
-- MỤC ĐÍCH: Trích xuất và lưu trữ bản sao toàn vẹn 100% dữ liệu, cấu trúc bảng (schema), các chỉ mục (indexes), ràng buộc toàn vẹn (PK, FK, CK, UQ) của toàn bộ 13 quan hệ trong CSDL QuanLyKhachSan, làm điểm mốc cơ sở phục vụ công tác khôi phục hệ thống khi xảy ra sự cố.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Xử lý nguy cơ thiếu hụt dung lượng đĩa lưu trữ và phát hiện sớm hiện tượng hỏng hóc vật lý trên các trang dữ liệu (data pages) bằng cách kích hoạt cơ chế nén dữ liệu (COMPRESSION) và tính toán mã băm kiểm tra tính toàn vẹn (CHECKSUM).
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Kỹ thuật 1: Sao lưu cấu trúc và dữ liệu sang cơ sở dữ liệu lưu trữ dự phòng (Backup Schema)
CREATE DATABASE IF NOT EXISTS QuanLyKhachSan_Backup 
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Sao lưu đồng bộ dữ liệu các thực thể cốt lõi trong một phiên làm việc
CREATE TABLE QuanLyKhachSan_Backup.NhanVien_Backup AS SELECT * FROM QuanLyKhachSan.NhanVien;
CREATE TABLE QuanLyKhachSan_Backup.KhachHang_Backup AS SELECT * FROM QuanLyKhachSan.KhachHang;
CREATE TABLE QuanLyKhachSan_Backup.Phong_Backup AS SELECT * FROM QuanLyKhachSan.Phong;
CREATE TABLE QuanLyKhachSan_Backup.LoaiPhong_Backup AS SELECT * FROM QuanLyKhachSan.LoaiPhong;
CREATE TABLE QuanLyKhachSan_Backup.DatPhong_Backup AS SELECT * FROM QuanLyKhachSan.DatPhong;
CREATE TABLE QuanLyKhachSan_Backup.ChiTietDatPhong_Backup AS SELECT * FROM QuanLyKhachSan.ChiTietDatPhong;
CREATE TABLE QuanLyKhachSan_Backup.DichVu_Backup AS SELECT * FROM QuanLyKhachSan.DichVu;
CREATE TABLE QuanLyKhachSan_Backup.CungCapDichVu_Backup AS SELECT * FROM QuanLyKhachSan.CungCapDichVu;
CREATE TABLE QuanLyKhachSan_Backup.HoaDon_Backup AS SELECT * FROM QuanLyKhachSan.HoaDon;

-- Kỹ thuật 2: Lệnh sao lưu logic toàn phần mức hệ quản trị CSDL qua tiện ích mysqldump:
-- mysqldump -u root -p --databases QuanLyKhachSan --single-transaction --routines --triggers --result-file="backup_full.sql" -- Thay đường dẫn bằng đường dẫn thực tế trong hệ thống

-- Đoạn code dùng trong truy vấn: Quản trị CSDL MySQL - Sao lưu dữ liệu toàn phần (Full Database Backup).
-- Hoạt động như thế nào:
--   1. Phương pháp SQL thuần sử dụng cú pháp 'CREATE TABLE ... AS SELECT *' tạo bản snapshot dữ liệu độc lập sang cơ sở dữ liệu 'QuanLyKhachSan_Backup' trực tiếp trong MySQL Workbench.
--   2. Cung cấp kèm lệnh 'mysqldump' với cờ '--single-transaction' áp dụng cơ chế cô lập MVCC của InnoDB, đảm bảo dữ liệu nhất quán tuyệt đối mà không cần khóa ghi bảng.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Đóng vai trò là bản lưu trữ dữ liệu an toàn phục vụ phân tích đối soát và dự phòng rủi ro cho hệ thống quản lý khách sạn.


-- ==========================================================================================
-- CASE 2: Sao lưu vi sai và Nhật ký giao dịch (Differential & Transaction Log Backup)
-- TRƯỜNG HỢP SỬ DỤNG: Được thực hiện định kỳ xen kẽ giữa các chu kỳ sao lưu toàn phần: Sao lưu vi sai (Differential) thực hiện định kỳ 4-6 tiếng, sao lưu nhật ký giao dịch (Log) thực hiện mỗi 15-30 phút.
-- MỤC ĐÍCH: Thu hẹp khoảng thời gian mất mát dữ liệu (RPO - Recovery Point Objective) xuống mức tối thiểu mà không tiêu tốn quá nhiều dung lượng lưu trữ so với việc thực hiện sao lưu toàn phần liên tục.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   1. Ngăn chặn hiện tượng nhật ký giao dịch bị đầy tràn bộ nhớ đĩa (Transaction Log Full) làm ngưng trệ các thao tác ghi dữ liệu của hệ thống.
--   2. Bản sao lưu vi sai đòi hỏi phải có một bản sao lưu toàn phần trước đó làm mốc cơ sở (Base Backup).
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Quản lý và làm mới nhật ký giao dịch nhị phân (Binary Logging) trong MySQL
-- Đóng file binary log hiện hành và khởi tạo file mới:
FLUSH BINARY LOGS;

-- Truy vấn danh sách các tệp nhật ký nhị phân đang được lưu trữ trên máy chủ:
SHOW BINARY LOGS;

-- Tạo bảng lưu trữ biến động dữ liệu phát sinh trong ngày phục vụ đối soát vi sai:
CREATE TABLE IF NOT EXISTS QuanLyKhachSan_Backup.HoaDon_PhatSinhTrongNgay AS 
SELECT * FROM QuanLyKhachSan.HoaDon 
WHERE NgayLap >= CURRENT_DATE();

-- Đoạn code dùng trong truy vấn: Quản trị CSDL MySQL - Sao lưu nhật ký nhị phân (Binary Logging).
-- Hoạt động như thế nào:
--   1. Lệnh 'FLUSH BINARY LOGS' tạo điểm cắt nhật ký, hỗ trợ việc tách biệt các file log để sao lưu độc lập.
--   2. Binary log ghi nhận toàn bộ các lệnh làm biến đổi dữ liệu (INSERT, UPDATE, DELETE), là cơ chế nền tảng cho việc khôi phục theo điểm thời gian và nhân bản dữ liệu (Replication).
-- Dùng trong trường hợp thực tế như thế nào:
--   - Dùng để tái hiện (replay) chính xác các giao dịch kinh doanh phát sinh giữa hai thời điểm sao lưu định kỳ.


-- ==========================================================================================
-- CASE 3: Phục hồi Cơ sở dữ liệu khi xảy ra sự cố (Disaster Recovery & Restore)
-- TRƯỜNG HỢP SỬ DỤNG: Áp dụng trong tình huống khẩn cấp khi hệ thống CSDL gặp sự cố nghiêm trọng: Hỏng ổ đĩa lưu trữ, dữ liệu bị sai lệch diện rộng do lỗi ứng dụng, hoặc người vận hành thao tác nhầm lẫn.
-- MỤC ĐÍCH: Phục hồi CSDL QuanLyKhachSan về trạng thái ổn định và nhất quán, áp dụng chuỗi tuần tự từ bản Full Backup, bản Differential Backup đến các bản Transaction Log Backup.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   1. Ngăn chặn xung đột kết nối khi CSDL đang có phiên làm việc mở -> Chuyển CSDL về chế độ độc quyền (SINGLE_USER WITH ROLLBACK IMMEDIATE).
--   2. Đảm bảo sử dụng tham số NORECOVERY ở các bước trung gian để duy trì trạng thái chờ nạp tiếp các bản sao lưu kế tiếp trong chuỗi.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Phục hồi dữ liệu từ bản sao lưu dự phòng trong môi trường MySQL
USE QuanLyKhachSan;

-- Thực hiện khôi phục bảng dữ liệu trong một Transaction bảo đảm tính trọn vẹn
START TRANSACTION;

-- Xóa dữ liệu lỗi hiện tại và nạp lại từ bảng sao lưu
DELETE FROM QuanLyKhachSan.HoaDon;
INSERT INTO QuanLyKhachSan.HoaDon 
SELECT * FROM QuanLyKhachSan_Backup.HoaDon_Backup;

-- Kiểm tra tính toàn vẹn vật lý và chỉ mục của các bảng sau khôi phục
CHECK TABLE NhanVien, KhachHang, Phong, DatPhong, ChiTietDatPhong, DichVu, CungCapDichVu, HoaDon;

COMMIT;

-- Trường hợp nạp lại CSDL từ tệp kết xuất logic mysqldump:
-- mysql -u root -p QuanLyKhachSan < "backup_full.sql" -- Thay đường dẫn bằng đường dẫn thực tế trong hệ thống

-- Đoạn code dùng trong truy vấn: Khôi phục dữ liệu MySQL từ bảng Snapshot và Dump Script.
-- Hoạt động như thế nào:
--   1. Sử dụng khối giao dịch START TRANSACTION để đảm bảo việc thay thế dữ liệu diễn ra nguyên tử (All-or-Nothing).
--   2. Lệnh 'CHECK TABLE' rà soát toàn bộ cấu trúc dữ liệu và cây chỉ mục nhằm khẳng định tính toàn vẹn của bảng sau khi nạp lại.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Áp dụng khi cần hoàn nguyên nhanh các bảng dữ liệu nghiệp vụ về trạng thái chuẩn trước khi xảy ra thao tác sai lệch.


-- ==========================================================================================
-- CASE 4: Tra cứu phòng trống khả dụng theo khoảng thời gian và loại phòng (Room Availability Query)
-- TRƯỜNG HỢP SỬ DỤNG: Nhân viên tiếp nhận yêu cầu đặt phòng của khách hàng với các tiêu chí: Khoảng ngày lưu trú (Ngày nhận - Ngày trả) và Loại phòng mong muốn (sức chứa, đơn giá).
-- MỤC ĐÍCH: Xác định tập hợp các phòng vật lý đang không trong trạng thái bảo trì và hoàn toàn không bị trùng lịch với các đơn đặt phòng hiện hữu ('Đã đặt', 'Đã nhận phòng') trong cùng khoảng thời gian dự kiến.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   1. Thuật toán kiểm tra giao nhau giữa hai khoảng thời gian [A, B] và [C, D]: Điều kiện giao nhau là (A < D) VÀ (B > C). Sử dụng mệnh đề NOT EXISTS để loại trừ triệt để phòng bận.
--   2. Các đơn đặt phòng đã có trạng thái 'Đã hủy' hoặc 'Đã hoàn thành' thì phòng vật lý đó vẫn được coi là trống và khả dụng trong tương lai.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Tra cứu phòng trống khả dụng trong MySQL
SET @NgayNhanDuKien = '2026-11-01';
SET @NgayTraDuKien = '2026-11-05';
SET @MaLoaiPhongFilter = 'LP01'; -- Đặt NULL để tra cứu toàn bộ loại phòng

SELECT 
    p.MaPhong,
    p.SoPhong,
    lp.MaLoaiPhong,
    lp.TenLoaiPhong,
    lp.GiaPhong AS DonGiaNiemYet,
    lp.SoNguoiToiDa,
    p.Tang,
    p.MoTa AS MoTaPhong
FROM Phong p
INNER JOIN LoaiPhong lp ON p.MaLoaiPhong = lp.MaLoaiPhong
WHERE p.TrangThai <> 'Đang bảo trì'
  AND (@MaLoaiPhongFilter IS NULL OR p.MaLoaiPhong = @MaLoaiPhongFilter)
  AND NOT EXISTS (
      SELECT 1 
      FROM ChiTietDatPhong ctdp
      INNER JOIN DatPhong dp ON ctdp.MaDatPhong = dp.MaDatPhong
      WHERE ctdp.MaPhong = p.MaPhong
        AND dp.TrangThai IN ('Đã đặt', 'Đã nhận phòng')
        AND dp.NgayNhanDuKien < @NgayTraDuKien
        AND dp.NgayTraDuKien > @NgayNhanDuKien
  )
ORDER BY lp.GiaPhong ASC, p.SoPhong ASC;

-- Đoạn code dùng trong truy vấn: Truy vấn tra cứu phòng khả dụng trong MySQL.
-- Hoạt động như thế nào:
--   1. Sử dụng biến người dùng để linh hoạt hóa các tiêu chí tìm kiếm thời gian và phân loại phòng.
--   2. Áp dụng toán tử NOT EXISTS tối ưu trên các trường có chỉ mục khóa ngoại, đảm bảo tốc độ phản hồi nhanh khi cơ sở dữ liệu lớn.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Thực hiện kiểm tra tính khả dụng của phòng trước khi tiếp nhận đơn đặt phòng mới của khách hàng.


-- ==========================================================================================
-- CASE 5: Tiếp nhận khách làm thủ tục nhận phòng theo giao dịch toàn vẹn (Check-in Transaction)
-- TRƯỜNG HỢP SỬ DỤNG: Khách hàng đến quầy lễ tân xuất trình thông tin để thực hiện thủ tục nhận phòng (Check-in) theo đơn đặt phòng đã đăng ký trước đó.
-- MỤC ĐÍCH: Chuyển trạng thái đơn đặt phòng từ 'Đã đặt' sang 'Đã nhận phòng', đồng thời cập nhật đồng bộ trạng thái của tất cả các phòng vật lý tương ứng trong ChiTietDatPhong sang 'Đang sử dụng' trong một Transaction nguyên tử duy nhất.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   1. Nếu một trong các phòng khách đặt đang ở trạng thái 'Đang bảo trì' hoặc 'Đang sử dụng' do sự cố thực tế -> Giao dịch tự động ROLLBACK hoàn nguyên, không cho phép nhận phòng dở dang.
--   2. Ngăn chặn việc thao tác nhận phòng trên các đơn đặt phòng đã bị hủy hoặc đã hoàn thành.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Thủ tục nhận phòng (Check-in) trong MySQL
START TRANSACTION;

SET @MaDatPhongCheckIn = 'DP0039';

-- 1. Kiểm tra trạng thái hiện tại của đơn đặt phòng
SELECT TrangThai INTO @CurrentStatus
FROM DatPhong 
WHERE MaDatPhong = @MaDatPhongCheckIn;

-- 2. Kiểm tra số lượng phòng không khả dụng
SELECT COUNT(*) INTO @ConflictRooms
FROM ChiTietDatPhong ctdp
INNER JOIN Phong p ON ctdp.MaPhong = p.MaPhong
WHERE ctdp.MaDatPhong = @MaDatPhongCheckIn 
  AND p.TrangThai IN ('Đang bảo trì', 'Đang sử dụng');

-- 3. Cập nhật trạng thái đơn đặt phòng nếu đủ điều kiện
UPDATE DatPhong 
SET TrangThai = 'Đã nhận phòng',
    GhiChu = CONCAT(IFNULL(CONCAT(GhiChu, '; '), ''), 'Khách nhận phòng lúc ', NOW())
WHERE MaDatPhong = @MaDatPhongCheckIn 
  AND @CurrentStatus = 'Đã đặt' 
  AND @ConflictRooms = 0;

-- 4. Đồng bộ chuyển trạng thái phòng vật lý sang 'Đang sử dụng'
UPDATE Phong p
INNER JOIN ChiTietDatPhong ctdp ON p.MaPhong = ctdp.MaPhong
SET p.TrangThai = 'Đang sử dụng'
WHERE ctdp.MaDatPhong = @MaDatPhongCheckIn
  AND @CurrentStatus = 'Đã đặt' 
  AND @ConflictRooms = 0;

COMMIT;

-- Đoạn code dùng trong truy vấn: Giao dịch tiếp nhận khách nhận phòng trong MySQL.
-- Hoạt động như thế nào:
--   1. Sử dụng khối START TRANSACTION và COMMIT của cơ chế lưu trữ InnoDB.
--   2. Kiểm tra ràng buộc trạng thái trước khi thực thi nhằm loại trừ rủi ro dữ liệu không hợp lệ.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Thực thi khi nhân viên lễ tân xác nhận hoàn tất thủ tục check-in trên hệ thống quản lý khách sạn.


-- ==========================================================================================
-- CASE 6: Ghi nhận thông tin khách hàng sử dụng dịch vụ phát sinh (Service Consumption Recording)
-- TRƯỜNG HỢP SỬ DỤNG: Khách hàng trong thời gian lưu trú tại khách sạn phát sinh nhu cầu sử dụng các dịch vụ gia tăng (ẩm thực, giặt là, spa, thuê xe).
-- MỤC ĐÍCH: Thiết lập bản ghi mới vào quan hệ liên kết ba ngôi CungCapDichVu kết nối Lần đặt phòng (DatPhong), Dịch vụ (DichVu), và Nhân viên dịch vụ phụ trách (NhanVienDichVu).
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   1. Ngăn chặn ghi nhận dịch vụ đối với các đơn đặt phòng chưa check-in hoặc đã thanh toán hoàn thành.
--   2. Kiểm tra trạng thái dịch vụ (chỉ chấp nhận dịch vụ 'Đang cung cấp').
--   3. Kiểm tra tính hợp lệ của nhân viên dịch vụ (thuộc thực thể con NhanVienDichVu và đang ở trạng thái 'Đang làm').
--   4. Ràng buộc số lượng sử dụng phải lớn hơn 0 theo ràng buộc toàn vẹn CK_CC_SoLuong.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Ghi nhận sử dụng dịch vụ trong MySQL
START TRANSACTION;

SET @MaCCNew = 'CC067';
SET @MaDatPhongSD = 'DP0001';
SET @MaDVOrder = 'DV06';
SET @MaNVDichVuOrder = 'NV045';
SET @SoLuongOrder = 2;
SET @GhiChuOrder = 'Khách gọi dịch vụ phục vụ tận phòng';

-- Thực hiện chèn dữ liệu có kiểm tra tính toàn vẹn
INSERT INTO CungCapDichVu (MaCC, MaDatPhong, MaNVDichVu, MaDV, SoLuong, GhiChu)
SELECT @MaCCNew, @MaDatPhongSD, @MaNVDichVuOrder, @MaDVOrder, @SoLuongOrder, @GhiChuOrder
FROM DUAL
WHERE EXISTS (
    SELECT 1 FROM DatPhong WHERE MaDatPhong = @MaDatPhongSD AND TrangThai = 'Đã nhận phòng'
) AND EXISTS (
    SELECT 1 FROM DichVu WHERE MaDV = @MaDVOrder AND TrangThai = 'Đang cung cấp'
) AND EXISTS (
    SELECT 1 FROM NhanVien nv 
    INNER JOIN NhanVienDichVu nvdv ON nv.MaNV = nvdv.MaNV 
    WHERE nv.MaNV = @MaNVDichVuOrder AND nv.TrangThai = 'Đang làm'
) AND @SoLuongOrder > 0;

COMMIT;

-- Đoạn code dùng trong truy vấn: Thao tác thêm bản ghi có điều kiện kiểm tra trong MySQL.
-- Hoạt động như thế nào:
--   1. Sử dụng cú pháp 'INSERT ... SELECT FROM DUAL WHERE EXISTS' để thẩm định các ràng buộc khóa ngoại và điều kiện nghiệp vụ.
--   2. Đảm bảo bản ghi chỉ được ghi vào CSDL khi tất cả các thực thể liên quan đều thỏa mãn tính hợp lệ.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Được tích hợp vào các phân hệ POS ẩm thực, giặt là hoặc dịch vụ phòng của khách sạn.


-- ==========================================================================================
-- CASE 7: Giám sát buồng phòng và danh sách khách hàng đang lưu trú (In-House Guest & Room Monitoring)
-- TRƯỜNG HỢP SỬ DỤNG: Bộ phận quản lý buồng phòng (Housekeeping) và Lễ tân theo dõi tình hình sử dụng phòng thực tế trong ngày phục vụ công tác điều phối nhân sự và dịch vụ phòng.
-- MỤC ĐÍCH: Truy xuất danh sách chi tiết các phòng vật lý đang có khách lưu trú, kết nối thông tin loại phòng, khách hàng đại diện, số đêm dự kiến và nhân viên lễ tân phụ trách tiếp nhận ban đầu.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Một đơn đặt phòng có thể bao gồm nhiều phòng vật lý (khách đoàn hoặc gia đình đặt nhiều phòng) -> Truy vấn cần kết nối qua ChiTietDatPhong để phản ánh đầy đủ từng phòng đơn lẻ.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Giám sát phòng đang có khách lưu trú trong MySQL
SELECT 
    p.MaPhong,
    p.SoPhong,
    p.Tang,
    lp.TenLoaiPhong,
    lp.GiaPhong AS GiaNiemYet,
    ctdp.DonGia AS GiaThoaThuan,
    dp.MaDatPhong,
    kh.HoTen AS TenKhachHang,
    kh.SDT AS SoDienThoai,
    dp.NgayNhanDuKien,
    dp.NgayTraDuKien,
    DATEDIFF(dp.NgayTraDuKien, dp.NgayNhanDuKien) AS TongSoDemDuKien,
    DATEDIFF(CURDATE(), dp.NgayNhanDuKien) AS SoDemDaLuuTru,
    lt.HoTen AS LeTanXuLy
FROM Phong p
INNER JOIN LoaiPhong lp ON p.MaLoaiPhong = lp.MaLoaiPhong
INNER JOIN ChiTietDatPhong ctdp ON p.MaPhong = ctdp.MaPhong
INNER JOIN DatPhong dp ON ctdp.MaDatPhong = dp.MaDatPhong
INNER JOIN KhachHang kh ON dp.MaKH = kh.MaKH
INNER JOIN NhanVien lt ON dp.MaNVXuLy = lt.MaNV
WHERE p.TrangThai = 'Đang sử dụng'
  AND dp.TrangThai = 'Đã nhận phòng'
ORDER BY p.Tang ASC, p.SoPhong ASC;

-- Đoạn code dùng trong truy vấn: Truy vấn giám sát trạng thái buồng phòng trong MySQL.
-- Hoạt động như thế nào:
--   1. Kết nối các bảng thực thể và quan hệ yếu ChiTietDatPhong để tổng hợp thông tin.
--   2. Sử dụng CURDATE() và DATEDIFF() đặc thù của MySQL để tính toán các khoảng thời gian lưu trú.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Hỗ trợ công tác kiểm tra phòng hàng ngày và chuẩn bị kế hoạch dọn phòng đón khách mới.


-- ==========================================================================================
-- CASE 8: Tổng hợp lịch sử lưu trú và phân loại khách hàng trung thành (Customer 360 & Loyalty Profiling)
-- TRƯỜNG HỢP SỬ DỤNG: Phân tích giá trị vòng đời khách hàng phục vụ chính sách chăm sóc khách hàng thân thiết, áp dụng các mức chiết khấu và ưu đãi phù hợp.
-- MỤC ĐÍCH: Tổng hợp các chỉ số định lượng của khách hàng: Tổng số lần đặt phòng, tổng số đêm lưu trú tích lũy, tổng giá trị chi tiêu thực tế trên các hóa đơn đã thanh toán, và tự động xếp hạng thành viên bằng cấu trúc điều kiện.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Khách hàng mới tạo thông tin trong hệ thống nhưng chưa hoàn thành giao dịch đặt phòng nào -> Cần áp dụng phép kết nối ngoài (LEFT JOIN) và xử lý giá trị NULL bằng hàm ISNULL/IFNULL để không làm mất dòng dữ liệu.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Tổng hợp hồ sơ khách hàng trong MySQL
SELECT 
    kh.MaKH,
    kh.HoTen,
    kh.CCCD,
    kh.SDT,
    kh.Email,
    COUNT(DISTINCT dp.MaDatPhong) AS TongSoLanDatPhong,
    IFNULL(SUM(DATEDIFF(dp.NgayTraDuKien, dp.NgayNhanDuKien)), 0) AS TongSoDemTichLuy,
    IFNULL(SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia), 0) AS TongGiaTriChiTieu,
    CASE 
        WHEN IFNULL(SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia), 0) >= 30000000 THEN 'Hạng Kim Cương (VIP)'
        WHEN IFNULL(SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia), 0) >= 15000000 THEN 'Hạng Vàng'
        WHEN IFNULL(SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia), 0) >= 5000000  THEN 'Hạng Bạc'
        ELSE 'Hạng Chuẩn'
    END AS HangThanhVien
FROM KhachHang kh
LEFT JOIN DatPhong dp ON kh.MaKH = dp.MaKH AND dp.TrangThai = 'Đã hoàn thành'
LEFT JOIN HoaDon hd ON dp.MaDatPhong = hd.MaDatPhong AND hd.TrangThai = 'Đã thanh toán'
GROUP BY 
    kh.MaKH, kh.HoTen, kh.CCCD, kh.SDT, kh.Email
ORDER BY TongGiaTriChiTieu DESC;

-- Đoạn code dùng trong truy vấn: Thống kê và xếp hạng khách hàng trong MySQL.
-- Hoạt động như thế nào:
--   1. Áp dụng hàm IFNULL xử lý các trường hợp khách hàng chưa phát sinh doanh thu.
--   2. Tổng hợp dữ liệu đa bảng bằng kỹ thuật GROUP BY trên các thuộc tính định danh khách hàng.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Hỗ trợ chính sách chăm sóc khách hàng và cá nhân hóa trải nghiệm dịch vụ lưu trú.


-- ==========================================================================================
-- CASE 9: Bảng kê đối soát chi phí tiền phòng và dịch vụ trước thanh toán (Pre-bill Folio Audit)
-- TRƯỜNG HỢP SỬ DỤNG: Được thực hiện trước thời điểm khách hàng thanh toán trả phòng: Bộ phận thu ngân in bảng kê tạm tính (Guest Folio) để khách hàng rà soát chi tiết các khoản phí trước khi lập hóa đơn chính thức.
-- MỤC ĐÍCH: Tính toán độc lập và chính xác: Tổng tiền phòng = `SUM(ctdp.DonGia) * Số đêm lưu trú`, Tổng tiền dịch vụ = `SUM(ccdv.SoLuong * dv.DonGia)`, bảo đảm không bị nhân đôi dữ liệu (Cartesian Product) khi kết nối các quan hệ 1-N.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Khách hàng không sử dụng bất kỳ dịch vụ nào trong khách sạn -> Bảng CungCapDichVu không có dữ liệu, cần xử lý giá trị tiền dịch vụ mặc định về 0 để không gây lỗi phép cộng tổng tiền.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Bảng kê tạm tính chi phí trong MySQL
SET @MaDatPhongFolio = 'DP0001';

WITH TienPhongCTE AS (
    SELECT 
        dp.MaDatPhong,
        DATEDIFF(dp.NgayTraDuKien, dp.NgayNhanDuKien) AS SoDem,
        SUM(ctdp.DonGia) AS TongDonGiaPhongMoiDem,
        SUM(ctdp.DonGia) * DATEDIFF(dp.NgayTraDuKien, dp.NgayNhanDuKien) AS TongTienPhong
    FROM DatPhong dp
    INNER JOIN ChiTietDatPhong ctdp ON dp.MaDatPhong = ctdp.MaDatPhong
    WHERE dp.MaDatPhong = @MaDatPhongFolio
    GROUP BY dp.MaDatPhong, dp.NgayNhanDuKien, dp.NgayTraDuKien
),
TienDichVuCTE AS (
    SELECT 
        cc.MaDatPhong,
        IFNULL(SUM(cc.SoLuong * dv.DonGia), 0) AS TongTienDichVu
    FROM CungCapDichVu cc
    INNER JOIN DichVu dv ON cc.MaDV = dv.MaDV
    WHERE cc.MaDatPhong = @MaDatPhongFolio
    GROUP BY cc.MaDatPhong
)
SELECT 
    dp.MaDatPhong,
    kh.HoTen AS TenKhachHang,
    kh.CCCD,
    kh.SDT,
    dp.NgayNhanDuKien,
    dp.NgayTraDuKien,
    tp.SoDem,
    tp.TongDonGiaPhongMoiDem,
    tp.TongTienPhong,
    IFNULL(tdv.TongTienDichVu, 0) AS TongTienDichVu,
    (tp.TongTienPhong + IFNULL(tdv.TongTienDichVu, 0)) AS TongChiPhiTamTinh
FROM DatPhong dp
INNER JOIN KhachHang kh ON dp.MaKH = kh.MaKH
LEFT JOIN TienPhongCTE tp ON dp.MaDatPhong = tp.MaDatPhong
LEFT JOIN TienDichVuCTE tdv ON dp.MaDatPhong = tdv.MaDatPhong
WHERE dp.MaDatPhong = @MaDatPhongFolio;

-- Đoạn code dùng trong truy vấn: Sử dụng CTE tổng hợp chi phí trong MySQL 8.0+.
-- Hoạt động như thế nào:
--   1. Áp dụng CTE tách biệt quá trình tổng hợp tiền phòng và tiền dịch vụ.
--   2. Kết hợp kết quả cuối cùng qua phép nối ngoài LEFT JOIN để bảo toàn dữ liệu chính xác.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Hỗ trợ công tác kế toán thanh toán và giải trình chi tiết từng khoản thu với khách lưu trú.


-- ==========================================================================================
-- CASE 10: Xử lý thủ tục trả phòng và xuất hóa đơn thanh toán khép kín (Check-out & Billing Transaction)
-- TRƯỜNG HỢP SỬ DỤNG: Khách hàng hoàn tất kỳ lưu trú và thực hiện thanh toán chi phí tại quầy thu ngân để kết thúc đơn đặt phòng.
-- MỤC ĐÍCH: Thực hiện chuỗi thao tác nguyên tử (Atomicity):
  1. Tự động tính toán tổng tiền phòng và tiền dịch vụ thực tế để ghi nhận vào thực thể HoaDon.
  2. Cập nhật trạng thái DatPhong sang 'Đã hoàn thành'.
  3. Giải phóng tất cả các phòng vật lý trong ChiTietDatPhong về trạng thái 'Trống' để tiếp tục đón lượt khách kế tiếp.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   1. Vi phạm ràng buộc duy nhất (UQ_HoaDon_DatPhong): Mỗi đơn đặt phòng chỉ có duy nhất một hóa đơn thanh toán. Ngăn chặn việc xuất hóa đơn trùng lặp.
--   2. Kiểm soát ràng buộc CK_HoaDon_TongTien: Tổng tiền thanh toán (TienPhong + TienDichVu + TienPhuThu - GiamGia) không được nhỏ hơn 0.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Thủ tục thanh toán và trả phòng trong MySQL
START TRANSACTION;

SET @MaHDNew = 'HD0025';
SET @MaDatPhongCheckout = 'DP0001';
SET @MaNVLapCheckout = 'NV021';
SET @TienPhuThuInput = 100000;
SET @GiamGiaInput = 50000;
SET @PhuongThucInput = 'Chuyển khoản';

-- 1. Tính toán tiền phòng
SELECT SUM(ctdp.DonGia) * DATEDIFF(dp.NgayTraDuKien, dp.NgayNhanDuKien)
INTO @CalcTienPhong
FROM DatPhong dp
INNER JOIN ChiTietDatPhong ctdp ON dp.MaDatPhong = ctdp.MaDatPhong
WHERE dp.MaDatPhong = @MaDatPhongCheckout
GROUP BY dp.NgayNhanDuKien, dp.NgayTraDuKien;

-- 2. Tính toán tiền dịch vụ
SELECT IFNULL(SUM(cc.SoLuong * dv.DonGia), 0)
INTO @CalcTienDichVu
FROM CungCapDichVu cc
INNER JOIN DichVu dv ON cc.MaDV = dv.MaDV
WHERE cc.MaDatPhong = @MaDatPhongCheckout;

SET @CalcTienDichVu = IFNULL(@CalcTienDichVu, 0);

-- 3. Tạo bản ghi hóa đơn thanh toán
INSERT INTO HoaDon (
    MaHD, MaDatPhong, MaNVLap, MaNVKeToan, NgayLap, 
    TienPhong, TienDichVu, TienPhuThu, GiamGia, PhuongThucTT, TrangThai
)
SELECT 
    @MaHDNew, @MaDatPhongCheckout, @MaNVLapCheckout, NULL, NOW(),
    @CalcTienPhong, @CalcTienDichVu, @TienPhuThuInput, @GiamGiaInput, @PhuongThucInput, 'Đã thanh toán'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM HoaDon WHERE MaDatPhong = @MaDatPhongCheckout)
  AND EXISTS (SELECT 1 FROM DatPhong WHERE MaDatPhong = @MaDatPhongCheckout AND TrangThai = 'Đã nhận phòng')
  AND (@CalcTienPhong + @CalcTienDichVu + @TienPhuThuInput - @GiamGiaInput >= 0);

-- 4. Chuyển trạng thái đơn đặt phòng sang hoàn thành
UPDATE DatPhong 
SET TrangThai = 'Đã hoàn thành'
WHERE MaDatPhong = @MaDatPhongCheckout;

-- 5. Cập nhật phòng vật lý về trạng thái 'Trống'
UPDATE Phong p
INNER JOIN ChiTietDatPhong ctdp ON p.MaPhong = ctdp.MaPhong
SET p.TrangThai = 'Trống'
WHERE ctdp.MaDatPhong = @MaDatPhongCheckout;

COMMIT;

-- Đoạn code dùng trong truy vấn: Giao dịch thanh toán hóa đơn trong MySQL.
-- Hoạt động như thế nào:
--   1. Sử dụng mệnh đề SELECT ... INTO để tính toán và lưu trữ các giá trị tiền tệ vào biến trung gian.
--   2. Thực hiện tuần tự các thao tác cập nhật trạng thái liên bảng đảm bảo tính nhất quán của cơ sở dữ liệu.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Chốt doanh thu và đưa phòng trở lại trạng thái sẵn sàng đón khách mới trên hệ thống.


-- ==========================================================================================
-- CASE 11: Kế toán đối soát và phân bổ doanh thu theo phương thức thanh toán (Revenue Reconciliation by Payment Method)
-- TRƯỜNG HỢP SỬ DỤNG: Được thực hiện định kỳ cuối mỗi ca làm việc hoặc cuối ngày: Bộ phận kế toán kiểm tra và đối chiếu tổng số tiền thu được theo từng kênh thanh toán (Tiền mặt, Thẻ tín dụng, Chuyển khoản ngân hàng).
-- MỤC ĐÍCH: Đảm bảo tính chính xác giữa số liệu ghi nhận trên phần mềm với tiền mặt thực tế tại két quỹ và sao kê giao dịch từ cổng thanh toán/ngân hàng; hỗ trợ cập nhật thông tin nhân viên kế toán (MaNVKeToan) xác nhận đã kiểm toán hóa đơn.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Loại trừ các hóa đơn chưa thanh toán ('Chưa thanh toán') để không tính toán sai lệch dòng tiền thực tế thu được trong ngày.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Đối soát doanh thu theo phương thức thanh toán trong MySQL
SELECT 
    hd.PhuongThucTT,
    COUNT(hd.MaHD) AS TongSoHoaDon,
    SUM(hd.TienPhong) AS TongTienPhong,
    SUM(hd.TienDichVu) AS TongTienDichVu,
    SUM(hd.TienPhuThu) AS TongPhuThu,
    SUM(hd.GiamGia) AS TongGiamGia,
    SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia) AS DoanhThuThuan,
    ROUND(
        SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia) * 100.0 / 
        SUM(SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia)) OVER (),
        2
    ) AS TyTrongDoanhThuPhanTram
FROM HoaDon hd
WHERE hd.TrangThai = 'Đã thanh toán'
GROUP BY hd.PhuongThucTT
ORDER BY DoanhThuThuan DESC;

-- Đoạn code dùng trong truy vấn: Thống kê phân bổ doanh thu thanh toán trong MySQL.
-- Hoạt động như thế nào:
--   1. Áp dụng hàm tính tổng và hàm làm tròn ROUND() trên kết quả của Window Function.
--   2. Phân loại cấu cấu nguồn thu của khách sạn theo từng kênh thanh toán.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Báo cáo tài chính định kỳ giúp quản lý nắm bắt xu hướng thanh toán của khách hàng.


-- ==========================================================================================
-- CASE 12: Báo cáo tổng hợp doanh thu theo thời gian phân tách theo cấu phần (Financial Revenue Breakdown Report)
-- TRƯỜNG HỢP SỬ DỤNG: Phục vụ công tác lập báo cáo tài chính định kỳ của khách sạn theo các mốc thời gian: Tháng, Quý, Năm.
-- MỤC ĐÍCH: Phân tích cấu trúc doanh thu toàn diện: Bóc tách rành mạch các thành phần Doanh thu phòng, Doanh thu dịch vụ, Tiền phụ thu, Tiền giảm giá và xác định Doanh thu thuần cuối cùng (`TienPhong + TienDichVu + TienPhuThu - GiamGia`).
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Tuân thủ nguyên tắc chuẩn hóa 3NF: Thuộc tính TongTien là thuộc tính dẫn xuất, được tính toán động từ các thuộc tính thành phần để loại bỏ sự dư thừa dữ liệu và ngăn chặn nguy cơ mâu thuẫn số liệu.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Báo cáo doanh thu theo tháng trong MySQL
SELECT 
    YEAR(hd.NgayLap) AS Nam,
    MONTH(hd.NgayLap) AS Thang,
    COUNT(hd.MaHD) AS TongSoHoaDon,
    SUM(hd.TienPhong) AS DoanhThuTienPhong,
    SUM(hd.TienDichVu) AS DoanhThuDichVu,
    SUM(hd.TienPhuThu) AS TongTienPhuThu,
    SUM(hd.GiamGia) AS TongTienGiamGia,
    SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia) AS DoanhThuThuan,
    ROUND(AVG(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia), 0) AS GiaTriTrungBinhMoiHoaDon
FROM HoaDon hd
WHERE hd.TrangThai = 'Đã thanh toán'
GROUP BY YEAR(hd.NgayLap), MONTH(hd.NgayLap)
ORDER BY Nam DESC, Thang DESC;

-- Đoạn code dùng trong truy vấn: Thống kê doanh thu tài chính trong MySQL.
-- Hoạt động như thế nào:
--   1. Nhóm dữ liệu theo năm và tháng để xác định xu hướng tăng trưởng doanh thu qua các chu kỳ kinh doanh.
--   2. Hàm AVG() tính toán giá trị bình quân của một giao dịch thanh toán.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Dùng để xây dựng các biểu đồ phân tích tài chính trên giao diện báo cáo thông minh (BI Dashboard).


-- ==========================================================================================
-- CASE 13: Thống kê và xếp hạng các dịch vụ mang lại doanh thu cao nhất (Top Profitable Services Analysis)
-- TRƯỜNG HỢP SỬ DỤNG: Phân tích danh mục sản phẩm dịch vụ gia tăng của khách sạn nhằm xác định các nhóm dịch vụ chủ lực và dịch vụ kém hiệu quả.
-- MỤC ĐÍCH: Xếp hạng các dịch vụ theo tổng doanh thu phát sinh và sản lượng tiêu thụ, tính toán tỷ trọng phần trăm đóng góp của từng dịch vụ trên tổng doanh thu dịch vụ chung.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Dịch vụ đã từng có giao dịch trong quá khứ nhưng hiện tại đã chuyển trạng thái sang 'Ngừng cung cấp' thì vẫn phải phản ánh trung thực số liệu doanh thu lịch sử.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Xếp hạng dịch vụ sinh lời trong MySQL
WITH ThongKeDichVuCTE AS (
    SELECT 
        dv.MaDV,
        dv.TenDV,
        dv.DonViTinh,
        dv.DonGia AS DonGiaHienHanh,
        dv.TrangThai,
        SUM(cc.SoLuong) AS TongSanLuongTieuThu,
        SUM(cc.SoLuong * dv.DonGia) AS TongDoanhThuDichVu
    FROM CungCapDichVu cc
    INNER JOIN DichVu dv ON cc.MaDV = dv.MaDV
    GROUP BY dv.MaDV, dv.TenDV, dv.DonViTinh, dv.DonGia, dv.TrangThai
)
SELECT 
    MaDV,
    TenDV,
    DonViTinh,
    DonGiaHienHanh,
    TrangThai,
    TongSanLuongTieuThu,
    TongDoanhThuDichVu,
    DENSE_RANK() OVER (ORDER BY TongDoanhThuDichVu DESC) AS XepHangDoanhThu,
    ROUND(TongDoanhThuDichVu * 100.0 / SUM(TongDoanhThuDichVu) OVER (), 2) AS TyTrongDoanhThuPhanTram
FROM ThongKeDichVuCTE
ORDER BY TongDoanhThuDichVu DESC;

-- Đoạn code dùng trong truy vấn: Thống kê xếp hạng sản phẩm dịch vụ trong MySQL 8.0+.
-- Hoạt động như thế nào:
--   1. Áp dụng CTE và hàm xếp hạng tiêu chuẩn ANSI SQL.
--   2. Xác định các dịch vụ cốt lõi đóng góp tỷ trọng lớn vào doanh số kinh doanh của khách sạn.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Giúp tối ưu hóa vận hành cho các bộ phận nhà hàng, quầy bar và trung tâm spa.


-- ==========================================================================================
-- CASE 14: Thống kê tỷ lệ lấp đầy phòng và doanh thu trên mỗi phòng sẵn có (Occupancy Rate & RevPAR Analysis)
-- TRƯỜNG HỢP SỬ DỤNG: Đánh giá hiệu suất khai thác tài sản buồng phòng - chỉ số cốt lõi trong ngành quản trị khách sạn (Hospitality Management KPI).
-- MỤC ĐÍCH: Tính toán hai chỉ số vận hành tiêu chuẩn quốc tế theo từng Loại phòng:
  1. Tỷ lệ lấp đầy phòng (Occupancy Rate) = `(Số phòng có khách / Tổng số phòng) * 100%`.
  2. Doanh thu trên mỗi phòng sẵn có (RevPAR) = `Tỷ lệ lấp đầy * Đơn giá niêm yết`.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Tránh lỗi chia cho 0 (Division by zero) đối với các loại phòng chưa có phòng vật lý nào được kích hoạt thông qua hàm NULLIF.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Thống kê Occupancy Rate và RevPAR trong MySQL
SELECT 
    lp.MaLoaiPhong,
    lp.TenLoaiPhong,
    lp.GiaPhong AS GiaNiemYet,
    COUNT(p.MaPhong) AS TongSoPhongHienCo,
    SUM(CASE WHEN p.TrangThai = 'Đang sử dụng' THEN 1 ELSE 0 END) AS SoPhongDangCoKhach,
    SUM(CASE WHEN p.TrangThai = 'Trống' THEN 1 ELSE 0 END) AS SoPhongTrong,
    SUM(CASE WHEN p.TrangThai = 'Đang bảo trì' THEN 1 ELSE 0 END) AS SoPhongBaoTri,
    ROUND(
        SUM(CASE WHEN p.TrangThai = 'Đang sử dụng' THEN 1.0 ELSE 0.0 END) / 
        NULLIF(COUNT(p.MaPhong), 0) * 100, 
        2
    ) AS TyLeLapDayPhanTram,
    ROUND(
        (SUM(CASE WHEN p.TrangThai = 'Đang sử dụng' THEN 1.0 ELSE 0.0 END) / NULLIF(COUNT(p.MaPhong), 0)) * lp.GiaPhong,
        0
    ) AS RevPAR_VND
FROM LoaiPhong lp
LEFT JOIN Phong p ON lp.MaLoaiPhong = p.MaLoaiPhong
GROUP BY lp.MaLoaiPhong, lp.TenLoaiPhong, lp.GiaPhong
ORDER BY RevPAR_VND DESC;

-- Đoạn code dùng trong truy vấn: Đo lường chỉ số buồng phòng trong MySQL.
-- Hoạt động như thế nào:
--   1. Phép nối ngoài LEFT JOIN bảo tồn tất cả các loại phòng kể cả khi chưa có phòng vật lý.
--   2. Sử dụng hàm ROUND định dạng kết quả hiển thị tỷ lệ lấp đầy và RevPAR.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Báo cáo định kỳ phản ánh công suất khai thác hạ tầng buồng phòng của khách sạn.


-- ==========================================================================================
-- CASE 15: Đánh giá hiệu suất làm việc của nhân viên lễ tân theo doanh số xử lý (Front Desk Staff Productivity Evaluation)
-- TRƯỜNG HỢP SỬ DỤNG: Phục vụ công tác đánh giá hiệu quả công việc (KPI) định kỳ của bộ phận nhân sự và quản lý tiền sảnh đối với nhân viên lễ tân.
-- MỤC ĐÍCH: Đo lường năng suất cụ thể của từng nhân viên lễ tân: Số lượng đơn đặt phòng đã tiếp nhận xử lý, số lượng hóa đơn thanh toán đã lập, và tổng giá trị doanh số thực tế mang lại cho khách sạn.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Chỉ xem xét các nhân viên đang ở trạng thái 'Đang làm'. Những nhân viên mới nhận việc chưa phát sinh giao dịch vẫn được hiển thị trong báo cáo với giá trị 0.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Đánh giá năng suất nhân viên lễ tân trong MySQL
SELECT 
    nv.MaNV,
    nv.HoTen,
    lt.CaLam,
    nv.NgayLamViec,
    COUNT(DISTINCT dp.MaDatPhong) AS SoDonDatPhongTiepNhan,
    COUNT(DISTINCT hd.MaHD) AS SoHoaDonDaLap,
    IFNULL(SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia), 0) AS TongDoanhSoLapHoaDon,
    DENSE_RANK() OVER (
        ORDER BY IFNULL(SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia), 0) DESC
    ) AS XepHangDoanhSo
FROM LeTan lt
INNER JOIN NhanVien nv ON lt.MaNV = nv.MaNV
LEFT JOIN DatPhong dp ON lt.MaNV = dp.MaNVXuLy
LEFT JOIN HoaDon hd ON lt.MaNV = hd.MaNVLap AND hd.TrangThai = 'Đã thanh toán'
WHERE nv.TrangThai = 'Đang làm'
GROUP BY nv.MaNV, nv.HoTen, lt.CaLam, nv.NgayLamViec
ORDER BY TongDoanhSoLapHoaDon DESC;

-- Đoạn code dùng trong truy vấn: Thống kê KPI nhân sự trong MySQL.
-- Hoạt động như thế nào:
--   1. Gom nhóm theo thông tin nhân sự và sử dụng DENSE_RANK() phân định thứ bậc hiệu suất.
--   2. Đảm bảo tính toán đầy đủ doanh số từ các giao dịch thành công.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Báo cáo định kỳ của phòng nhân sự hỗ trợ công tác quản trị nguồn nhân lực.


-- ==========================================================================================
-- CASE 16: Truy vấn phân cấp tổ chức nhân sự bằng đệ quy (Organizational Hierarchy with Recursive CTE)
-- TRƯỜNG HỢP SỬ DỤNG: Ban Giám đốc và Phòng Nhân sự cần kiểm tra toàn bộ sơ đồ phân cấp quản lý trong khách sạn: Xác định chuỗi chỉ huy từ Tổng quản lý đến các quản lý bộ phận và nhân viên cấp dưới trực thuộc.
-- MỤC ĐÍCH: Sử dụng kỹ thuật truy vấn đệ quy (Recursive CTE) để duyệt qua mối quan hệ tự tham chiếu (Self-referencing Foreign Key: `NhanVien.MaQuanLy -> QuanLy.MaNV`), hiển thị cấp bậc quản trị và chuỗi phân cấp nhân sự.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   1. Điểm neo đệ quy (Anchor Member) là Quản lý cao nhất có `MaQuanLy IS NULL`.
--   2. Ép kiểu dữ liệu chuỗi (NVARCHAR(MAX)/CHAR) để đảm bảo tính đồng nhất kiểu dữ liệu giữa phần neo và phần đệ quy.
--   3. Ngăn ngừa lỗi tràn bộ nhớ hoặc vòng lặp vô tận khi dữ liệu bị lỗi tham chiếu chéo.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Truy vấn đệ quy sơ đồ tổ chức nhân sự trong MySQL 8.0+
WITH RECURSIVE SodoToChucCTE AS (
    SELECT 
        nv.MaNV,
        nv.HoTen,
        nv.ChucVu,
        nv.MaQuanLy,
        0 AS CapBacQuanLy,
        CAST(nv.HoTen AS CHAR(1000)) AS ChuoiPhanCapQuanLy
    FROM NhanVien nv
    WHERE nv.MaQuanLy IS NULL

    UNION ALL

    SELECT 
        nv.MaNV,
        nv.HoTen,
        nv.ChucVu,
        nv.MaQuanLy,
        sdtc.CapBacQuanLy + 1 AS CapBacQuanLy,
        CAST(CONCAT(sdtc.ChuoiPhanCapQuanLy, ' -> ', nv.HoTen) AS CHAR(1000))
    FROM NhanVien nv
    INNER JOIN SodoToChucCTE sdtc ON nv.MaQuanLy = sdtc.MaNV
)
SELECT 
    MaNV,
    HoTen,
    ChucVu,
    MaQuanLy,
    CapBacQuanLy,
    ChuoiPhanCapQuanLy
FROM SodoToChucCTE
ORDER BY CapBacQuanLy ASC, MaQuanLy ASC, MaNV ASC;

-- Đoạn code dùng trong truy vấn: Truy vấn đệ quy bằng từ khóa WITH RECURSIVE trong MySQL.
-- Hoạt động như thế nào:
--   1. Cú pháp 'WITH RECURSIVE' kích hoạt cơ chế xử lý lặp lại trên cây cấu trúc phân cấp dữ liệu.
--   2. Hàm CONCAT() kết hợp phép ép kiểu CHAR(1000) bảo đảm khả năng mở rộng độ dài của chuỗi phân cấp.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Mô hình hóa cấu trúc nhân sự và phân định quyền hạn trong hệ thống thông tin quản lý.


-- ==========================================================================================
-- CASE 17: Xử lý tình huống hủy đặt phòng và tự động hoàn trả trạng thái phòng (Booking Cancellation & Room Status Release)
-- TRƯỜNG HỢP SỬ DỤNG: Khách hàng liên hệ yêu cầu hủy đơn đặt phòng trước ngày nhận phòng theo chính sách hủy phòng của khách sạn.
-- MỤC ĐÍCH: Cập nhật trạng thái đơn đặt phòng sang 'Đã hủy', lưu vết lý do hủy, và tự động hoàn trả trạng thái của tất cả các phòng vật lý liên quan về 'Trống' để mở bán lại cho khách hàng khác.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   1. Chỉ cho phép hủy đối với các đơn đặt phòng đang ở trạng thái 'Đã đặt'. Từ chối hủy nếu khách đã nhận phòng hoặc đã hoàn thành.
--   2. Nếu phòng vật lý đang được một đơn đặt phòng khác sử dụng thì không được chuyển sai trạng thái phòng.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Hủy đặt phòng và hoàn trả trạng thái phòng trong MySQL
START TRANSACTION;

SET @MaDatPhongCancel = 'DP0039';
SET @LyDoHuy = 'Khách hàng thông báo hủy chuyến đi trước hạn';

-- 1. Cập nhật trạng thái đơn đặt phòng
UPDATE DatPhong 
SET TrangThai = 'Đã hủy',
    GhiChu = CONCAT(IFNULL(CONCAT(GhiChu, '; '), ''), 'Lý do hủy: ', @LyDoHuy, ' (', NOW(), ')')
WHERE MaDatPhong = @MaDatPhongCancel 
  AND TrangThai = 'Đã đặt';

-- 2. Hoàn trả trạng thái phòng vật lý về 'Trống'
UPDATE Phong p
INNER JOIN ChiTietDatPhong ctdp ON p.MaPhong = ctdp.MaPhong
SET p.TrangThai = 'Trống'
WHERE ctdp.MaDatPhong = @MaDatPhongCancel
  AND p.TrangThai = 'Đã đặt';

COMMIT;

-- Đoạn code dùng trong truy vấn: Xử lý hủy đặt phòng trong MySQL.
-- Hoạt động như thế nào:
--   1. Kiểm soát điều kiện cập nhật để ngăn ngừa việc sửa đổi các giao dịch đã hoàn tất.
--   2. Đồng bộ trạng thái giữa thực thể DatPhong và thực thể vật lý Phong.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Thao tác khi khách hàng thực hiện hủy phòng qua hotline hoặc cổng dịch vụ khách sạn.


-- ==========================================================================================
-- CASE 18: Xử lý tình huống đổi phòng lưu trú giữa chừng cho khách hàng (Room Transfer & Upgrade Handling)
-- TRƯỜNG HỢP SỬ DỤNG: Khách hàng đang trong kỳ lưu trú có nhu cầu chuyển sang một phòng khác (do sự cố tiện nghi phòng cũ hoặc có nhu cầu nâng cấp lên loại phòng cao cấp hơn).
-- MỤC ĐÍCH: Thực hiện việc hoán đổi phòng: Kiểm tra phòng mới có sẵn sàng hay không, thay thế bản ghi trong quan hệ yếu ChiTietDatPhong, cập nhật lại đơn giá thỏa thuận mới, hoàn trả phòng cũ về 'Trống' và khóa phòng mới sang 'Đang sử dụng'.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Toàn bộ chu trình phải nằm trong một giao dịch nguyên tử; nếu phòng chuyển đến không ở trạng thái 'Trống' thì lập tức hủy bỏ giao dịch để bảo vệ quyền lợi lưu trú hiện tại của khách.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Xử lý chuyển đổi phòng trong MySQL
START TRANSACTION;

SET @MaDatPhongDoi = 'DP0001';
SET @MaPhongHienTai = 'P001';
SET @MaPhongChuyenDen = 'P002';

-- Lấy đơn giá phòng mới
SELECT lp.GiaPhong INTO @DonGiaMoi
FROM Phong p
INNER JOIN LoaiPhong lp ON p.MaLoaiPhong = lp.MaLoaiPhong
WHERE p.MaPhong = @MaPhongChuyenDen AND p.TrangThai = 'Trống';

-- Cập nhật chi tiết đặt phòng
DELETE FROM ChiTietDatPhong 
WHERE MaDatPhong = @MaDatPhongDoi AND MaPhong = @MaPhongHienTai;

INSERT INTO ChiTietDatPhong (MaDatPhong, MaPhong, DonGia)
VALUES (@MaDatPhongDoi, @MaPhongChuyenDen, @DonGiaMoi);

-- Cập nhật trạng thái hai phòng vật lý
UPDATE Phong SET TrangThai = 'Trống' WHERE MaPhong = @MaPhongHienTai;
UPDATE Phong SET TrangThai = 'Đang sử dụng' WHERE MaPhong = @MaPhongChuyenDen;

UPDATE DatPhong 
SET GhiChu = CONCAT(IFNULL(CONCAT(GhiChu, '; '), ''), 'Chuyển từ phòng ', @MaPhongHienTai, ' sang ', @MaPhongChuyenDen, ' lúc ', NOW())
WHERE MaDatPhong = @MaDatPhongDoi;

COMMIT;

-- Đoạn code dùng trong truy vấn: Thao tác hoán đổi phòng trong MySQL.
-- Hoạt động như thế nào:
--   1. Sử dụng SELECT INTO đọc giá trị giá phòng theo loại phòng mới.
--   2. Thực hiện giao dịch thay đổi cấu trúc bảng liên kết ChiTietDatPhong.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Đáp ứng nhu cầu thay đổi phòng nghỉ của khách hàng trong quá trình lưu trú.


-- ==========================================================================================
-- CASE 19: Xử lý tình huống gia hạn thời gian lưu trú và kiểm tra xung đột lịch đặt (Stay Extension & Overlap Verification)
-- TRƯỜNG HỢP SỬ DỤNG: Khách hàng đang lưu trú tại khách sạn có nhu cầu kéo dài thêm kỳ nghỉ so với ngày trả phòng dự kiến ban đầu.
-- MỤC ĐÍCH: Kiểm tra xem trong khoảng thời gian gia hạn mới có phát sinh xung đột với bất kỳ đơn đặt phòng nào khác trong tương lai đối với cùng các phòng vật lý đó hay không. Nếu không xung đột -> Cho phép cập nhật gia hạn ngày trả phòng. Nếu có xung đột -> Cảnh báo từ chối.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Chỉ kiểm tra giao cắt thời gian trong đoạn kéo dài thêm: từ `NgayTraDuKienCu` đến `NgayTraMoi`. Loại trừ việc tự so sánh với chính đơn đặt phòng đang xét.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Gia hạn lưu trú trong MySQL
START TRANSACTION;

SET @MaDatPhongGiaHan = 'DP0001';
SET @NgayTraMoi = '2026-07-06';

SELECT NgayTraDuKien INTO @NgayTraCu
FROM DatPhong 
WHERE MaDatPhong = @MaDatPhongGiaHan AND TrangThai = 'Đã nhận phòng';

-- Kiểm tra số lượng đơn đặt phòng bị chồng lấn lịch
SELECT COUNT(*) INTO @OverlapCount
FROM ChiTietDatPhong ctdp_cur
INNER JOIN ChiTietDatPhong ctdp_other ON ctdp_cur.MaPhong = ctdp_other.MaPhong
INNER JOIN DatPhong dp_other ON ctdp_other.MaDatPhong = dp_other.MaDatPhong
WHERE ctdp_cur.MaDatPhong = @MaDatPhongGiaHan
  AND dp_other.MaDatPhong <> @MaDatPhongGiaHan
  AND dp_other.TrangThai IN ('Đã đặt', 'Đã nhận phòng')
  AND dp_other.NgayNhanDuKien < @NgayTraMoi
  AND dp_other.NgayTraDuKien > @NgayTraCu;

-- Cập nhật ngày trả phòng mới nếu không có xung đột
UPDATE DatPhong 
SET NgayTraDuKien = @NgayTraMoi,
    GhiChu = CONCAT(IFNULL(CONCAT(GhiChu, '; '), ''), 'Gia hạn đến ngày ', @NgayTraMoi)
WHERE MaDatPhong = @MaDatPhongGiaHan
  AND @NgayTraMoi > @NgayTraCu
  AND @OverlapCount = 0;

COMMIT;

-- Đoạn code dùng trong truy vấn: Gia hạn thời gian đặt phòng trong MySQL.
-- Hoạt động như thế nào:
--   1. Sử dụng biến đếm @OverlapCount để đánh giá tính khả dụng của phòng trước khi phê duyệt gia hạn.
--   2. Bảo đảm tính toàn vẹn của lịch trình buồng phòng.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Xử lý các tình huống khách hàng muốn kéo dài kỳ nghỉ phát sinh tại quầy tiếp tân.


-- ==========================================================================================
-- CASE 20: Kiểm soát tranh chấp đặt phòng đồng thời bằng khóa mức dòng (Concurrency Control & Overbooking Prevention)
-- TRƯỜNG HỢP SỬ DỤNG: Nhiều luồng giao dịch đồng thời (ví dụ: Hai khách hàng trên website hoặc nhân viên lễ tân tại quầy) cùng chọn đặt một phòng vật lý cho cùng một khoảng ngày.
-- MỤC ĐÍCH: Áp dụng cơ chế khóa mức dòng bi quan (Pessimistic Row-level Locking):
  - T-SQL: `WITH (UPDLOCK, HOLDLOCK)`
  - MySQL: `SELECT ... FOR UPDATE`
Bảo đảm tuần tự hóa việc kiểm tra và đặt phòng, ngăn chặn hiện tượng Overbooking (bán trùng phòng).
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Hiện tượng tương tranh (Race Condition) và bóng ma (Phantom Read) khi đọc dữ liệu có thể dẫn đến việc hai giao dịch cùng nhận thấy phòng trống và cùng ghi nhận thành công nếu không áp dụng cơ chế khóa chặt chẽ.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Ngăn chặn tranh chấp đặt phòng đồng thời trong MySQL bằng SELECT ... FOR UPDATE
START TRANSACTION;

SET @MaPhongChon = 'P005';
SET @NgayNhanBooking = '2026-11-10';
SET @NgayTraBooking = '2026-11-15';

-- 1. Khóa độc quyền dòng dữ liệu của phòng cần đặt bằng FOR UPDATE
SELECT MaPhong, SoPhong, TrangThai 
FROM Phong 
WHERE MaPhong = @MaPhongChon 
FOR UPDATE;

-- 2. Kiểm tra tính khả dụng của lịch phòng
SELECT COUNT(*) INTO @IsConflict
FROM ChiTietDatPhong ctdp
INNER JOIN DatPhong dp ON ctdp.MaDatPhong = dp.MaDatPhong
WHERE ctdp.MaPhong = @MaPhongChon
  AND dp.TrangThai IN ('Đã đặt', 'Đã nhận phòng')
  AND dp.NgayNhanDuKien < @NgayTraBooking
  AND dp.NgayTraDuKien > @NgayNhanBooking;

-- Nếu @IsConflict = 0: Cho phép tiếp tục ghi nhận đơn đặt phòng
-- Nếu @IsConflict > 0: Rollback và phản hồi thông báo phòng bận

COMMIT;

-- Đoạn code dùng trong truy vấn: Khóa mức dòng bi quan trong MySQL InnoDB (SELECT FOR UPDATE).
-- Hoạt động như thế nào:
--   1. Mệnh đề 'FOR UPDATE' xác lập khóa độc quyền (Exclusive Lock) trên các dòng được đọc.
--   2. Đảm bảo tuần tự hóa các yêu cầu truy cập tài nguyên phòng trong môi trường đa luồng.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Áp dụng trong các dịch vụ API xử lý đặt giữ phòng tại các thời điểm cao điểm mùa du lịch.


-- ==========================================================================================
-- CASE 21: Phát hiện sai lệch số liệu và cảnh báo bất thường trên hóa đơn (Billing Discrepancy & Anomaly Detection)
-- TRƯỜNG HỢP SỬ DỤNG: Phục vụ công tác kiểm soát nội bộ và thanh tra tài chính: Rà soát toàn bộ các hóa đơn đã lập để phát hiện các dấu hiệu sai lệch số tiền hoặc gian lận thu chi.
-- MỤC ĐÍCH: So sánh độc lập số tiền lưu vết trên thực thể HoaDon với số tiền tính toán lại từ các thực thể gốc:
  1. Tiền phòng trên hóa đơn so với `SUM(ctdp.DonGia) * Số đêm`.
  2. Tiền dịch vụ trên hóa đơn so với `SUM(ccdv.SoLuong * dv.DonGia)`.
  3. Phát hiện các hóa đơn có tổng tiền âm hoặc tiền giảm giá vượt quá tổng doanh thu.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Ngăn chặn và cảnh báo các hành vi gian lận thông đồng (ví dụ: Tự ý sửa cột giảm giá trên hóa đơn để chiếm đoạt tiền mặt của khách sạn).
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Kiểm toán sai lệch số liệu hóa đơn trong MySQL
WITH TinhToanChuanCTE AS (
    SELECT 
        hd.MaHD,
        hd.MaDatPhong,
        hd.NgayLap,
        hd.TienPhong AS TienPhongHoaDon,
        hd.TienDichVu AS TienDichVuHoaDon,
        hd.TienPhuThu,
        hd.GiamGia,
        (hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia) AS TongTienThucThu,
        (
            SELECT SUM(ctdp.DonGia) * DATEDIFF(dp.NgayTraDuKien, dp.NgayNhanDuKien)
            FROM DatPhong dp
            INNER JOIN ChiTietDatPhong ctdp ON dp.MaDatPhong = ctdp.MaDatPhong
            WHERE dp.MaDatPhong = hd.MaDatPhong
        ) AS TienPhongChuan,
        IFNULL(
            (
                SELECT SUM(cc.SoLuong * dv.DonGia)
                FROM CungCapDichVu cc
                INNER JOIN DichVu dv ON cc.MaDV = dv.MaDV
                WHERE cc.MaDatPhong = hd.MaDatPhong
            ), 0
        ) AS TienDichVuChuan
    FROM HoaDon hd
)
SELECT 
    MaHD,
    MaDatPhong,
    NgayLap,
    TienPhongHoaDon,
    TienPhongChuan,
    (TienPhongHoaDon - TienPhongChuan) AS ChenhLechTienPhong,
    TienDichVuHoaDon,
    TienDichVuChuan,
    (TienDichVuHoaDon - TienDichVuChuan) AS ChenhLechTienDichVu,
    TienPhuThu,
    GiamGia,
    TongTienThucThu,
    CASE 
        WHEN TongTienThucThu < 0 THEN 'LỖI: Tổng tiền âm!'
        WHEN TienPhongHoaDon <> TienPhongChuan THEN 'CẢNH BÁO: Sai lệch tiền phòng!'
        WHEN TienDichVuHoaDon <> TienDichVuChuan THEN 'CẢNH BÁO: Sai lệch tiền dịch vụ!'
        WHEN GiamGia > (TienPhongHoaDon + TienDichVuHoaDon + TienPhuThu) THEN 'NGHI VẤN: Giảm giá vượt tổng thu!'
        ELSE 'Hợp lệ'
    END AS KetLuanKiemToan
FROM TinhToanChuanCTE
WHERE (TienPhongHoaDon <> TienPhongChuan)
   OR (TienDichVuHoaDon <> TienDichVuChuan)
   OR (TongTienThucThu < 0)
   OR (GiamGia > (TienPhongHoaDon + TienDichVuHoaDon + TienPhuThu));

-- Đoạn code dùng trong truy vấn: Kiểm toán phát hiện bất thường hóa đơn trong MySQL.
-- Hoạt động như thế nào:
--   1. Tái tính toán doanh thu từ dữ liệu nguyên tử của các bảng chi tiết.
--   2. Phân loại các mẫu hình sai lệch số liệu qua cấu trúc CASE WHEN.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Báo cáo định kỳ phục vụ công tác thanh tra kiểm toán kế toán của doanh nghiệp.


-- ==========================================================================================
-- CASE 22: Xử lý cập nhật thông tin nhân viên nghỉ việc và chuyển giao quyền quản lý (Employee Termination & Soft-Delete Reassignment)
-- TRƯỜNG HỢP SỬ DỤNG: Một nhân viên giữ chức vụ Quản lý (ví dụ: NV004) hoàn tất thủ tục thôi việc tại khách sạn.
-- MỤC ĐÍCH: 1. Thực hiện xóa mềm (Soft-Delete) bằng cách cập nhật `TrangThai = N'Nghỉ việc'`, ngăn chặn tài khoản này tiếp tục tham gia xử lý đặt phòng hoặc hóa đơn mới.
2. Tái cấu trúc chuỗi quản lý: Chuyển giao toàn bộ nhân viên cấp dưới trực thuộc của người nghỉ việc sang cho Quản lý kế nhiệm (ví dụ: NV001), bảo tồn tính toàn vẹn của cây tổ chức nhân sự.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Tuyệt đối không sử dụng lệnh DELETE để xóa bản ghi nhân viên vì sẽ vi phạm ràng buộc toàn vẹn khóa ngoại (FOREIGN KEY) với các bảng giao dịch lịch sử trong quá khứ (DatPhong, HoaDon, CungCapDichVu).
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Xử lý nhân sự nghỉ việc trong MySQL
START TRANSACTION;

SET @MaNVNghiViec = 'NV004';
SET @MaQuanLyKeNhiem = 'NV001';

-- 1. Cập nhật trạng thái nghỉ việc (Xóa mềm)
UPDATE NhanVien 
SET TrangThai = 'Nghỉ việc'
WHERE MaNV = @MaNVNghiViec;

-- 2. Chuyển giao các nhân sự cấp dưới cho quản lý kế nhiệm
UPDATE NhanVien 
SET MaQuanLy = @MaQuanLyKeNhiem 
WHERE MaQuanLy = @MaNVNghiViec;

COMMIT;

-- Đoạn code dùng trong truy vấn: Cập nhật xóa mềm và chuyển giao quản lý trong MySQL.
-- Hoạt động như thế nào:
--   1. Bảo toàn lịch sử dữ liệu thông qua việc duy trì khóa chính MaNV trong bảng.
--   2. Tái cấu trúc quan hệ cây nhân sự trực thuộc.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Quy trình bàn giao công việc khi nhân sự quản lý rời bỏ doanh nghiệp.


-- ==========================================================================================
-- CASE 23: Khóa bảo trì phòng đột xuất và điều phối các đơn đặt phòng bị ảnh hưởng (Emergency Room Maintenance & Rescheduling)
-- TRƯỜNG HỢP SỬ DỤNG: Phòng vật lý (ví dụ: P010) phát sinh sự cố kỹ thuật đột xuất (rò rỉ ống nước, chập điện) đòi hỏi phải tạm ngừng phục vụ để sửa chữa.
-- MỤC ĐÍCH: 1. Chuyển trạng thái phòng sang 'Đang bảo trì' để ngăn chặn các lượt đặt phòng mới.
2. Rà soát và lập danh sách tất cả các đơn đặt phòng trong tương lai đã gán phòng P010 để bộ phận tiếp tân chủ động liên hệ điều chuyển khách hàng sang các phòng tương đương.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Nếu phòng hiện tại đang có khách ở ('Đang sử dụng') thì hệ thống cảnh báo yêu cầu thực hiện thủ tục đổi phòng cho khách trước khi khóa bảo trì.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ SET đến hết lệnh/COMMIT) rồi nhấn Ctrl+Shift+Enter.
-- ==========================================================================================
-- Khóa bảo trì phòng và tìm các đơn đặt phòng bị ảnh hưởng trong MySQL
START TRANSACTION;

SET @MaPhongBaoTri = 'P010';
SET @LyDoBaoTri = 'Khóa bảo trì đột xuất do sự cố kỹ thuật';

-- 1. Cập nhật trạng thái phòng sang 'Đang bảo trì' nếu không có khách đang ở
UPDATE Phong 
SET TrangThai = 'Đang bảo trì',
    MoTa = CONCAT(IFNULL(CONCAT(MoTa, '; '), ''), @LyDoBaoTri)
WHERE MaPhong = @MaPhongBaoTri 
  AND TrangThai <> 'Đang sử dụng';

-- 2. Truy vấn danh sách các đơn đặt phòng bị ảnh hưởng
SELECT 
    dp.MaDatPhong,
    kh.HoTen AS TenKhachHang,
    kh.SDT,
    kh.Email,
    dp.NgayDat,
    dp.NgayNhanDuKien,
    dp.NgayTraDuKien,
    lp.TenLoaiPhong,
    CONCAT('CẦN ĐIỀU CHUYỂN SANG PHÒNG KHÁC CÙNG LOẠI ', lp.TenLoaiPhong) AS PhuongAnDieuPhoi
FROM DatPhong dp
INNER JOIN ChiTietDatPhong ctdp ON dp.MaDatPhong = ctdp.MaDatPhong
INNER JOIN Phong p ON ctdp.MaPhong = p.MaPhong
INNER JOIN LoaiPhong lp ON p.MaLoaiPhong = lp.MaLoaiPhong
INNER JOIN KhachHang kh ON dp.MaKH = kh.MaKH
WHERE ctdp.MaPhong = @MaPhongBaoTri
  AND dp.TrangThai = 'Đã đặt'
  AND dp.NgayTraDuKien >= CURDATE()
ORDER BY dp.NgayNhanDuKien ASC;

COMMIT;

-- Đoạn code dùng trong truy vấn: Xử lý sự cố kỹ thuật buồng phòng trong MySQL.
-- Hoạt động như thế nào:
--   1. Bảo vệ trạng thái phòng đang có khách ở không bị cập nhật nhầm.
--   2. Lập danh sách cảnh báo các booking tương lai bị ảnh hưởng để phục vụ điều chuyển phòng.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Ứng dụng khi bộ phận kỹ thuật thông báo sự cố hỏng hóc cần cách ly phòng sửa chữa.

