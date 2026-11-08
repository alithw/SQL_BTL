-- ==========================================================================================
-- HỆ THỐNG CƠ SỞ DỮ LIỆU QUẢN LÝ KHÁCH SẠN (HOTEL MANAGEMENT DATABASE)
-- BỘ TRUY VẤN CHUẨN MICROSOFT SQL SERVER (T-SQL) - PHỤC VỤ BÁO CÁO MÔN HỌC CƠ SỞ DỮ LIỆU
-- Thực thi trực tiếp trên SQL Server Management Studio (SSMS)
-- ==========================================================================================
-- HƯỚNG DẪN THỰC THI TRÊN SSMS:
-- 1. Chạy dòng khởi tạo đầu tiên: Bôi đen dòng [USE QuanLyKhachSan; GO] rồi bấm F5 một lần duy nhất.
-- 2. Chạy từng Case: Bôi đen trọn vẹn toàn bộ vùng code của Case đó (bao gồm từ dòng DECLARE nếu có
--    đến hết lệnh SELECT / COMMIT hoặc GO) rồi nhấn phím F5 (hoặc nút Execute trên thanh công cụ).
-- ==========================================================================================

USE QuanLyKhachSan;
GO

-- ==========================================================================================
-- CASE 1: Sao lưu toàn phần Cơ sở dữ liệu (Full Database Backup)
-- TRƯỜNG HỢP SỬ DỤNG: Được thực hiện định kỳ theo chính sách an toàn thông tin của hệ thống thông tin khách sạn hoặc trước khi tiến hành bảo trì, nâng cấp cấu trúc lược đồ quan hệ.
-- MỤC ĐÍCH: Trích xuất và lưu trữ bản sao toàn vẹn 100% dữ liệu, cấu trúc bảng (schema), các chỉ mục (indexes), ràng buộc toàn vẹn (PK, FK, CK, UQ) của toàn bộ 13 quan hệ trong CSDL QuanLyKhachSan, làm điểm mốc cơ sở phục vụ công tác khôi phục hệ thống khi xảy ra sự cố.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Xử lý nguy cơ thiếu hụt dung lượng đĩa lưu trữ và phát hiện sớm hiện tượng hỏng hóc vật lý trên các trang dữ liệu (data pages) bằng cách kích hoạt cơ chế nén dữ liệu (COMPRESSION) và tính toán mã băm kiểm tra tính toàn vẹn (CHECKSUM).
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Sao lưu toàn phần CSDL QuanLyKhachSan với cơ chế nén và kiểm tra mã băm trang dữ liệu
BACKUP DATABASE QuanLyKhachSan
TO DISK = N'C:\Backup\QuanLyKhachSan_Full.bak' -- Thay đường dẫn bằng đường dẫn thực tế trong hệ thống
WITH 
    FORMAT,                         -- Khởi tạo file sao lưu mới, ghi đè header cũ
    INIT,                           -- Ghi đè lên mọi tập hợp sao lưu trước đó trong file
    NAME = N'QuanLyKhachSan-Full Database Backup',
    COMPRESSION,                    -- Nén dữ liệu giảm kích thước file và giảm thiểu chi phí I/O
    STATS = 10,                     -- Báo cáo tiến độ hoàn thành sau mỗi 10%
    CHECKSUM;                       -- Kiểm tra tính toàn vẹn của trang dữ liệu trước khi sao lưu
GO

-- Đoạn code dùng trong truy vấn: Quản trị CSDL - Sao lưu toàn phần (Full Database Backup).
-- Hoạt động như thế nào:
--   1. Sử dụng lệnh 'BACKUP DATABASE' chụp lại toàn bộ tệp dữ liệu vật lý (.mdf) và phần nhật ký giao dịch (.ldf) đang hoạt động.
--   2. Tùy chọn COMPRESSION tối ưu hóa tài nguyên lưu trữ và rút ngắn thời gian sao lưu.
--   3. Tùy chọn CHECKSUM bảo đảm dữ liệu ghi ra file sao lưu không bị suy hao hoặc lỗi bit vật lý.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Tạo bản snapshot định kỳ của hệ thống quản lý khách sạn để đáp ứng mục tiêu thời gian khôi phục (RTO) và hạn chế rủi ro mất mát dữ liệu (RPO).


-- ==========================================================================================
-- CASE 2: Sao lưu vi sai và Nhật ký giao dịch (Differential & Transaction Log Backup)
-- TRƯỜNG HỢP SỬ DỤNG: Được thực hiện định kỳ xen kẽ giữa các chu kỳ sao lưu toàn phần: Sao lưu vi sai (Differential) thực hiện định kỳ 4-6 tiếng, sao lưu nhật ký giao dịch (Log) thực hiện mỗi 15-30 phút.
-- MỤC ĐÍCH: Thu hẹp khoảng thời gian mất mát dữ liệu (RPO - Recovery Point Objective) xuống mức tối thiểu mà không tiêu tốn quá nhiều dung lượng lưu trữ so với việc thực hiện sao lưu toàn phần liên tục.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   1. Ngăn chặn hiện tượng nhật ký giao dịch bị đầy tràn bộ nhớ đĩa (Transaction Log Full) làm ngưng trệ các thao tác ghi dữ liệu của hệ thống.
--   2. Bản sao lưu vi sai đòi hỏi phải có một bản sao lưu toàn phần trước đó làm mốc cơ sở (Base Backup).
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Đảm bảo CSDL hoạt động ở chế độ khôi phục đầy đủ (FULL recovery model)
USE master;
GO
ALTER DATABASE QuanLyKhachSan SET RECOVERY FULL;
GO

-- 1. Sao lưu vi sai: Chỉ lưu trữ các trang dữ liệu có sự thay đổi kể từ lần Full Backup gần nhất
BACKUP DATABASE QuanLyKhachSan
TO DISK = N'C:\Backup\QuanLyKhachSan_Diff.bak' -- Thay đường dẫn bằng đường dẫn thực tế trong hệ thống
WITH 
    DIFFERENTIAL,                   -- Xác định loại sao lưu vi sai
    INIT,
    NAME = N'QuanLyKhachSan-Differential Backup',
    COMPRESSION,
    STATS = 25;
GO

-- 2. Sao lưu nhật ký giao dịch: Lưu lại toàn bộ các giao dịch đã được commit để phục hồi theo điểm thời gian
BACKUP LOG QuanLyKhachSan
TO DISK = N'C:\Backup\QuanLyKhachSan_Log.trn' -- Thay đường dẫn bằng đường dẫn thực tế trong hệ thống
WITH 
    NOINIT,                         -- Nối tiếp vào chuỗi log hiện có
    NAME = N'QuanLyKhachSan-Transaction Log Backup',
    COMPRESSION,
    STATS = 25;
GO

-- Đoạn code dùng trong truy vấn: Quản trị CSDL - Sao lưu vi sai và Nhật ký giao dịch (Differential & Log Backup).
-- Hoạt động như thế nào:
--   1. Tham số 'DIFFERENTIAL' quét bản đồ bit DCM (Differential Changed Map) để trích xuất duy nhất các khối dữ liệu bị biến động.
--   2. 'BACKUP LOG' ghi lại các bản ghi nhật ký giao dịch và giải phóng không gian của các Virtual Log Files không còn hoạt động để tái sử dụng.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Cho phép quản trị viên khôi phục dữ liệu về đúng thời điểm trước khi xảy ra sự cố hỏng hóc hoặc thao tác sai của người dùng (Point-in-Time Recovery).


-- ==========================================================================================
-- CASE 3: Phục hồi Cơ sở dữ liệu khi xảy ra sự cố (Disaster Recovery & Restore)
-- TRƯỜNG HỢP SỬ DỤNG: Áp dụng trong tình huống khẩn cấp khi hệ thống CSDL gặp sự cố nghiêm trọng: Hỏng ổ đĩa lưu trữ, dữ liệu bị sai lệch diện rộng do lỗi ứng dụng, hoặc người vận hành thao tác nhầm lẫn.
-- MỤC ĐÍCH: Phục hồi CSDL QuanLyKhachSan về trạng thái ổn định và nhất quán, áp dụng chuỗi tuần tự từ bản Full Backup, bản Differential Backup đến các bản Transaction Log Backup.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   1. Ngăn chặn xung đột kết nối khi CSDL đang có phiên làm việc mở -> Chuyển CSDL về chế độ độc quyền (SINGLE_USER WITH ROLLBACK IMMEDIATE).
--   2. Đảm bảo sử dụng tham số NORECOVERY ở các bước trung gian để duy trì trạng thái chờ nạp tiếp các bản sao lưu kế tiếp trong chuỗi.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
USE master;
GO

-- Bước 1: Ngắt tất cả các kết nối hiện hành và khóa CSDL ở chế độ độc quyền
IF DB_ID(N'QuanLyKhachSan') IS NOT NULL
BEGIN
    ALTER DATABASE QuanLyKhachSan SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
END;
GO

-- Bước 2: Phục hồi bản sao lưu toàn phần (Full) với cờ NORECOVERY
RESTORE DATABASE QuanLyKhachSan
FROM DISK = N'C:\Backup\QuanLyKhachSan_Full.bak' -- Thay đường dẫn bằng đường dẫn thực tế trong hệ thống
WITH 
    FILE = 1,
    NORECOVERY,                     -- Giữ CSDL ở trạng thái nạp tiếp, chưa mở phiên truy cập
    REPLACE,                        -- Ghi đè CSDL hiện hữu nếu đã tồn tại
    STATS = 25;
GO

-- Bước 3: Phục hồi bản sao lưu vi sai (Differential) gần nhất
RESTORE DATABASE QuanLyKhachSan
FROM DISK = N'C:\Backup\QuanLyKhachSan_Diff.bak' -- Thay đường dẫn bằng đường dẫn thực tế trong hệ thống
WITH 
    FILE = 1,
    NORECOVERY,
    STATS = 25;
GO

-- Bước 4: Phục hồi bản nhật ký giao dịch (Log) và đưa CSDL về trạng thái hoạt động (RECOVERY)
RESTORE LOG QuanLyKhachSan
FROM DISK = N'C:\Backup\QuanLyKhachSan_Log.trn' -- Thay đường dẫn bằng đường dẫn thực tế trong hệ thống
WITH 
    FILE = 1,
    RECOVERY,                       -- Hoàn tất chuỗi phục hồi, thực hiện pha Redo/Undo và đưa CSDL trực tuyến
    STATS = 25;
GO

-- Bước 5: Mở lại CSDL ở chế độ đa người dùng
ALTER DATABASE QuanLyKhachSan SET MULTI_USER;
GO

-- Đoạn code dùng trong truy vấn: Quản trị CSDL - Phục hồi hệ thống sau sự cố (Disaster Recovery).
-- Hoạt động như thế nào:
--   1. 'SINGLE_USER' cưỡng chế hủy bỏ toàn bộ các tiến trình đang truy xuất vào database.
--   2. Cờ NORECOVERY trì hoãn pha Rollback của CSDL để có thể tiếp tục nạp các tệp sao lưu vi sai và log.
--   3. Cờ RECOVERY ở bước cuối cùng đưa CSDL về trạng thái nhất quán và mở cổng truy cập bình thường.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Khôi phục hoạt động của CSDL trên máy chủ dự phòng hoặc khôi phục dữ liệu sau khi xảy ra sự cố hỏng hóc hệ thống vật lý.


USE QuanLyKhachSan;
GO

-- ==========================================================================================
-- CASE 4: Tra cứu phòng trống khả dụng theo khoảng thời gian và loại phòng (Room Availability Query)
-- TRƯỜNG HỢP SỬ DỤNG: Nhân viên tiếp nhận yêu cầu đặt phòng của khách hàng với các tiêu chí: Khoảng ngày lưu trú (Ngày nhận - Ngày trả) và Loại phòng mong muốn (sức chứa, đơn giá).
-- MỤC ĐÍCH: Xác định tập hợp các phòng vật lý đang không trong trạng thái bảo trì và hoàn toàn không bị trùng lịch với các đơn đặt phòng hiện hữu ('Đã đặt', 'Đã nhận phòng') trong cùng khoảng thời gian dự kiến.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   1. Thuật toán kiểm tra giao nhau giữa hai khoảng thời gian [A, B] và [C, D]: Điều kiện giao nhau là (A < D) VÀ (B > C). Sử dụng mệnh đề NOT EXISTS để loại trừ triệt để phòng bận.
--   2. Các đơn đặt phòng đã có trạng thái 'Đã hủy' hoặc 'Đã hoàn thành' thì phòng vật lý đó vẫn được coi là trống và khả dụng trong tương lai.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Khai báo tham số tìm kiếm phòng trống
DECLARE @NgayNhanDuKien DATE = '2026-11-01';
DECLARE @NgayTraDuKien DATE = '2026-11-05';
DECLARE @MaLoaiPhongFilter VARCHAR(10) = 'LP01'; -- Đặt NULL để tra cứu trên tất cả loại phòng

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
WHERE p.TrangThai <> N'Đang bảo trì'                     -- Loại trừ các phòng đang sửa chữa kỹ thuật
  AND (@MaLoaiPhongFilter IS NULL OR p.MaLoaiPhong = @MaLoaiPhongFilter)
  AND NOT EXISTS (
      -- Loại trừ các phòng có lịch đặt trùng với khoảng thời gian tra cứu
      SELECT 1 
      FROM ChiTietDatPhong ctdp
      INNER JOIN DatPhong dp ON ctdp.MaDatPhong = dp.MaDatPhong
      WHERE ctdp.MaPhong = p.MaPhong
        AND dp.TrangThai IN (N'Đã đặt', N'Đã nhận phòng')
        AND dp.NgayNhanDuKien < @NgayTraDuKien          -- Giao điểm: Bắt đầu trước khi kết thúc
        AND dp.NgayTraDuKien > @NgayNhanDuKien           -- Giao điểm: Kết thúc sau khi bắt đầu
  )
ORDER BY lp.GiaPhong ASC, p.SoPhong ASC;
GO

-- Đoạn code dùng trong truy vấn: Truy vấn dữ liệu có điều kiện (DQL) - Tra cứu phòng trống khả dụng.
-- Hoạt động như thế nào:
--   1. Kết nối bảng Phong và LoaiPhong qua khóa ngoại MaLoaiPhong để lấy thông tin đơn giá và sức chứa tối đa.
--   2. Mệnh đề NOT EXISTS kết hợp tương quan (Correlated Subquery) quét bảng ChiTietDatPhong và DatPhong để loại bỏ các phòng có lịch chồng lấn thời gian.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Cung cấp dữ liệu tức thời cho chức năng tìm kiếm phòng trống trên giao diện phần mềm quản trị khách sạn và hệ thống đặt phòng trực tuyến.


-- ==========================================================================================
-- CASE 5: Tiếp nhận khách làm thủ tục nhận phòng theo giao dịch toàn vẹn (Check-in Transaction)
-- TRƯỜNG HỢP SỬ DỤNG: Khách hàng đến quầy lễ tân xuất trình thông tin để thực hiện thủ tục nhận phòng (Check-in) theo đơn đặt phòng đã đăng ký trước đó.
-- MỤC ĐÍCH: Chuyển trạng thái đơn đặt phòng từ 'Đã đặt' sang 'Đã nhận phòng', đồng thời cập nhật đồng bộ trạng thái của tất cả các phòng vật lý tương ứng trong ChiTietDatPhong sang 'Đang sử dụng' trong một Transaction nguyên tử duy nhất.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   1. Nếu một trong các phòng khách đặt đang ở trạng thái 'Đang bảo trì' hoặc 'Đang sử dụng' do sự cố thực tế -> Giao dịch tự động ROLLBACK hoàn nguyên, không cho phép nhận phòng dở dang.
--   2. Ngăn chặn việc thao tác nhận phòng trên các đơn đặt phòng đã bị hủy hoặc đã hoàn thành.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Giao dịch nhận phòng đảm bảo tính toàn vẹn ACID
BEGIN TRANSACTION;
BEGIN TRY
    -- 1. THAM SỐ ĐẦU VÀO THỰC TẾ: Tiếp nhận mã đơn đặt phòng của khách tại quầy
    -- Nhập mã đơn cụ thể (VD: 'DP0029'). Để NULL nếu muốn hệ thống tự động chọn đơn 'Đã đặt' gần nhất.
    DECLARE @MaDatPhongCheckIn VARCHAR(10) = 'DP0029';

    -- 2. CHẾ ĐỘ TỰ ĐỘNG (CHỈ CHẠY KHI ĐỂ NULL ĐỂ HỖ TRỢ DEMO NHANH):
    IF @MaDatPhongCheckIn IS NULL
    BEGIN
        SELECT TOP 1 @MaDatPhongCheckIn = MaDatPhong 
        FROM DatPhong 
        WHERE TrangThai = N'Đã đặt'
        ORDER BY NgayNhanDuKien ASC;
    END;

    -- 1. Kiểm tra tính hợp lệ của đơn đặt phòng
    IF NOT EXISTS (
        SELECT 1 FROM DatPhong 
        WHERE MaDatPhong = @MaDatPhongCheckIn AND TrangThai = N'Đã đặt'
    )
    BEGIN
        THROW 50001, N'Lỗi nghiệp vụ: Đơn đặt phòng không tồn tại hoặc không ở trạng thái [Đã đặt] để làm thủ tục nhận phòng!', 1;
    END;

    -- 2. Kiểm tra tính khả dụng thực tế của tất cả các phòng thuộc đơn đặt phòng
    IF EXISTS (
        SELECT 1 
        FROM ChiTietDatPhong ctdp
        INNER JOIN Phong p ON ctdp.MaPhong = p.MaPhong
        WHERE ctdp.MaDatPhong = @MaDatPhongCheckIn 
          AND p.TrangThai IN (N'Đang bảo trì', N'Đang sử dụng')
    )
    BEGIN
        THROW 50002, N'Lỗi nghiệp vụ: Một số phòng trong đơn đặt hiện không sẵn sàng (Đang bảo trì hoặc Đang có khách khác ở)!', 1;
    END;

    -- 3. Cập nhật trạng thái đơn đặt phòng
    UPDATE DatPhong 
    SET TrangThai = N'Đã nhận phòng',
        GhiChu = ISNULL(GhiChu + N'; ', N'') + N'Khách nhận phòng lúc ' + CONVERT(NVARCHAR(20), GETDATE(), 120)
    WHERE MaDatPhong = @MaDatPhongCheckIn;

    -- 4. Cập nhật trạng thái phòng vật lý sang 'Đang sử dụng'
    UPDATE p
    SET p.TrangThai = N'Đang sử dụng'
    FROM Phong p
    INNER JOIN ChiTietDatPhong ctdp ON p.MaPhong = ctdp.MaPhong
    WHERE ctdp.MaDatPhong = @MaDatPhongCheckIn;

    COMMIT TRANSACTION;
    PRINT N'Thủ tục nhận phòng cho đơn ' + @MaDatPhongCheckIn + N' đã thực hiện thành công!';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH;
GO

-- Đoạn code dùng trong truy vấn: Thao tác cập nhật dữ liệu đa bảng trong Transaction (TCL & DML).
-- Hoạt động như thế nào:
--   1. Sử dụng khối BEGIN TRANSACTION kết hợp cấu trúc bẫy lỗi TRY...CATCH bảo đảm tính nguyên tử (Atomicity) và tính cô lập (Isolation).
--   2. Kiểm tra các tiền điều kiện nghiệp vụ thông qua lệnh THROW trước khi tiến hành cập nhật dữ liệu.
--   3. Đồng bộ hóa việc chuyển đổi trạng thái giữa bảng cha DatPhong và bảng con Phong.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Đảm bảo tính nhất quán dữ liệu giữa hồ sơ đặt phòng và tình trạng thực tế của buồng phòng tại thời điểm khách nhận chìa khóa.


-- ==========================================================================================
-- CASE 6: Ghi nhận thông tin khách hàng sử dụng dịch vụ phát sinh (Service Consumption Recording)
-- TRƯỜNG HỢP SỬ DỤNG: Khách hàng trong thời gian lưu trú tại khách sạn phát sinh nhu cầu sử dụng các dịch vụ gia tăng (ẩm thực, giặt là, spa, thuê xe).
-- MỤC ĐÍCH: Thiết lập bản ghi mới vào quan hệ liên kết ba ngôi CungCapDichVu kết nối Lần đặt phòng (DatPhong), Dịch vụ (DichVu), và Nhân viên dịch vụ phụ trách (NhanVienDichVu).
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   1. Ngăn chặn ghi nhận dịch vụ đối với các đơn đặt phòng chưa check-in hoặc đã thanh toán hoàn thành.
--   2. Kiểm tra trạng thái dịch vụ (chỉ chấp nhận dịch vụ 'Đang cung cấp').
--   3. Kiểm tra tính hợp lệ của nhân viên dịch vụ (thuộc thực thể con NhanVienDichVu và đang ở trạng thái 'Đang làm').
--   4. Ràng buộc số lượng sử dụng phải lớn hơn 0 theo ràng buộc toàn vẹn CK_CC_SoLuong.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Ghi nhận sử dụng dịch vụ cho đơn đặt phòng đang lưu trú
BEGIN TRANSACTION;
BEGIN TRY
    -- 1. THÔNG TIN KHÁCH HÀNG CHỌN (Khách có thể gọi cùng 1 dịch vụ nhiều lần trong kỳ nghỉ):
    DECLARE @MaDatPhongSD VARCHAR(10) = 'DP0028';                       -- Đơn đặt phòng của khách đang lưu trú (để NULL để auto chọn)
    DECLARE @MaDVOrder VARCHAR(10) = 'DV06';                            -- Khách chọn dịch vụ (Ví dụ: DV06 - Giặt hấp cao cấp)
    DECLARE @SoLuongOrder INT = 2;                                      -- Khách chọn số lượng sử dụng
    DECLARE @GhiChuOrder NVARCHAR(200) = N'Khách gọi dịch vụ phục vụ tận phòng'; -- Ghi chú yêu cầu của khách

    -- 2. CHẾ ĐỘ TỰ ĐỘNG (CHỈ CHẠY KHI ĐỂ NULL):
    IF @MaDatPhongSD IS NULL
    BEGIN
        SELECT TOP 1 @MaDatPhongSD = MaDatPhong 
        FROM DatPhong 
        WHERE TrangThai = N'Đã nhận phòng' 
        ORDER BY NgayNhanDuKien ASC;
    END;

    -- 3. THÔNG TIN HỆ THỐNG TỰ ĐỘNG ĐIỀU PHỐI (AUTO):

    -- Tự động điều phối nhân viên bộ phận dịch vụ đang làm việc
    DECLARE @MaNVDichVuOrder VARCHAR(10);
    SELECT TOP 1 @MaNVDichVuOrder = nv.MaNV 
    FROM NhanVien nv 
    INNER JOIN NhanVienDichVu nvdv ON nv.MaNV = nvdv.MaNV 
    WHERE nv.TrangThai = N'Đang làm' 
    ORDER BY nv.MaNV ASC;

    -- Tự động sinh mã cung cấp dịch vụ tiếp theo (VD: CC068 -> CC069)
    DECLARE @MaCCNew VARCHAR(10);
    SELECT @MaCCNew = 'CC' + RIGHT('000' + CAST(ISNULL(MAX(CAST(SUBSTRING(MaCC, 3, 10) AS INT)), 0) + 1 AS VARCHAR(10)), 3)
    FROM CungCapDichVu;

    -- 1. Kiểm tra đơn đặt phòng phải đang ở trạng thái 'Đã nhận phòng'
    IF NOT EXISTS (
        SELECT 1 FROM DatPhong 
        WHERE MaDatPhong = @MaDatPhongSD AND TrangThai = N'Đã nhận phòng'
    )
    BEGIN
        THROW 50003, N'Lỗi nghiệp vụ: Đặt phòng không ở trạng thái [Đã nhận phòng] (chưa check-in hoặc đã trả phòng)!', 1;
    END;

    -- 2. Kiểm tra dịch vụ có đang kinh doanh hay không
    IF NOT EXISTS (
        SELECT 1 FROM DichVu 
        WHERE MaDV = @MaDVOrder AND TrangThai = N'Đang cung cấp'
    )
    BEGIN
        THROW 50004, N'Lỗi nghiệp vụ: Dịch vụ này hiện đang ở trạng thái [Ngừng cung cấp]!', 1;
    END;

    -- 3. Kiểm tra nhân viên có thuộc bộ phận dịch vụ và đang làm việc hay không
    IF NOT EXISTS (
        SELECT 1 
        FROM NhanVien nv
        INNER JOIN NhanVienDichVu nvdv ON nv.MaNV = nvdv.MaNV
        WHERE nv.MaNV = @MaNVDichVuOrder AND nv.TrangThai = N'Đang làm'
    )
    BEGIN
        THROW 50005, N'Lỗi nghiệp vụ: Nhân viên thực hiện không thuộc bộ phận dịch vụ hoặc đã nghỉ việc!', 1;
    END;

    -- 4. Kiểm tra ràng buộc miền giá trị của số lượng
    IF (@SoLuongOrder <= 0)
    BEGIN
        THROW 50006, N'Lỗi nghiệp vụ: Số lượng dịch vụ sử dụng phải lớn hơn 0!', 1;
    END;

    -- 5. Thực hiện thêm bản ghi cung cấp dịch vụ
    INSERT INTO CungCapDichVu (MaCC, MaDatPhong, MaNVDichVu, MaDV, SoLuong, GhiChu)
    VALUES (@MaCCNew, @MaDatPhongSD, @MaNVDichVuOrder, @MaDVOrder, @SoLuongOrder, @GhiChuOrder);

    COMMIT TRANSACTION;
    PRINT N'Ghi nhận dịch vụ ' + @MaDVOrder + N' cho đơn đặt ' + @MaDatPhongSD + N' thành công!';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrMsg, 16, 1);
END CATCH;
GO

-- Đoạn code dùng trong truy vấn: Thao tác bổ sung dữ liệu (INSERT) có kiểm tra ràng buộc toàn vẹn.
-- Hoạt động như thế nào:
--   1. Rà soát đồng thời 4 ràng buộc toàn vẹn logic trước khi thực thi lệnh INSERT.
--   2. Thiết lập liên kết ba ngôi giữa thực thể sự kiện DatPhong, thực thể danh mục DichVu và thực thể con NhanVienDichVu.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Ghi nhận các chi phí dịch vụ phát sinh vào hồ sơ lưu trú của khách để phục vụ đối soát và thanh toán tổng hợp khi trả phòng.


-- ==========================================================================================
-- CASE 7: Giám sát buồng phòng và danh sách khách hàng đang lưu trú (In-House Guest & Room Monitoring)
-- TRƯỜNG HỢP SỬ DỤNG: Bộ phận quản lý buồng phòng (Housekeeping) và Lễ tân theo dõi tình hình sử dụng phòng thực tế trong ngày phục vụ công tác điều phối nhân sự và dịch vụ phòng.
-- MỤC ĐÍCH: Truy xuất danh sách chi tiết các phòng vật lý đang có khách lưu trú, kết nối thông tin loại phòng, khách hàng đại diện, số đêm dự kiến và nhân viên lễ tân phụ trách tiếp nhận ban đầu.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Một đơn đặt phòng có thể bao gồm nhiều phòng vật lý (khách đoàn hoặc gia đình đặt nhiều phòng) -> Truy vấn cần kết nối qua ChiTietDatPhong để phản ánh đầy đủ từng phòng đơn lẻ.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Truy vấn danh sách phòng đang có khách lưu trú và chi tiết hồ sơ đặt phòng
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
    DATEDIFF(DAY, dp.NgayNhanDuKien, dp.NgayTraDuKien) AS TongSoDemDuKien,
    DATEDIFF(DAY, dp.NgayNhanDuKien, CAST(GETDATE() AS DATE)) AS SoDemDaLuuTru,
    lt.HoTen AS LeTanXuLy
FROM Phong p
INNER JOIN LoaiPhong lp ON p.MaLoaiPhong = lp.MaLoaiPhong
INNER JOIN ChiTietDatPhong ctdp ON p.MaPhong = ctdp.MaPhong
INNER JOIN DatPhong dp ON ctdp.MaDatPhong = dp.MaDatPhong
INNER JOIN KhachHang kh ON dp.MaKH = kh.MaKH
INNER JOIN NhanVien lt ON dp.MaNVXuLy = lt.MaNV
WHERE p.TrangThai = N'Đang sử dụng'
  AND dp.TrangThai = N'Đã nhận phòng'
ORDER BY p.Tang ASC, p.SoPhong ASC;
GO

-- Đoạn code dùng trong truy vấn: Truy vấn kết nối đa bảng (Multi-table INNER JOIN).
-- Hoạt động như thế nào:
--   1. Thực hiện phép kết nối trong (INNER JOIN) trên 6 quan hệ: Phong, LoaiPhong, ChiTietDatPhong, DatPhong, KhachHang và NhanVien.
--   2. Sử dụng hàm DATEDIFF tính toán số đêm lưu trú thực tế so với thời điểm hiện tại của hệ thống.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Cung cấp dữ liệu trực quan cho màn hình giám sát buồng phòng (Room Status Board) của khách sạn.


-- ==========================================================================================
-- CASE 8: Tổng hợp lịch sử lưu trú và phân loại khách hàng trung thành (Customer 360 & Loyalty Profiling)
-- TRƯỜNG HỢP SỬ DỤNG: Phân tích giá trị vòng đời khách hàng phục vụ chính sách chăm sóc khách hàng thân thiết, áp dụng các mức chiết khấu và ưu đãi phù hợp.
-- MỤC ĐÍCH: Tổng hợp các chỉ số định lượng của khách hàng: Tổng số lần đặt phòng, tổng số đêm lưu trú tích lũy, tổng giá trị chi tiêu thực tế trên các hóa đơn đã thanh toán, và tự động xếp hạng thành viên bằng cấu trúc điều kiện.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Khách hàng mới tạo thông tin trong hệ thống nhưng chưa hoàn thành giao dịch đặt phòng nào -> Cần áp dụng phép kết nối ngoài (LEFT JOIN) và xử lý giá trị NULL bằng hàm ISNULL/IFNULL để không làm mất dòng dữ liệu.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Tổng hợp hồ sơ khách hàng và phân hạng thành viên thân thiết
SELECT 
    kh.MaKH,
    kh.HoTen,
    kh.CCCD,
    kh.SDT,
    kh.Email,
    COUNT(DISTINCT dp.MaDatPhong) AS TongSoLanDatPhong,
    ISNULL(SUM(DATEDIFF(DAY, dp.NgayNhanDuKien, dp.NgayTraDuKien)), 0) AS TongSoDemTichLuy,
    ISNULL(SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia), 0) AS TongGiaTriChiTieu,
    CASE 
        WHEN ISNULL(SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia), 0) >= 30000000 THEN N'Hạng Kim Cương (VIP)'
        WHEN ISNULL(SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia), 0) >= 15000000 THEN N'Hạng Vàng'
        WHEN ISNULL(SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia), 0) >= 5000000  THEN N'Hạng Bạc'
        ELSE N'Hạng Chuẩn'
    END AS HangThanhVien
FROM KhachHang kh
LEFT JOIN DatPhong dp ON kh.MaKH = dp.MaKH AND dp.TrangThai = N'Đã hoàn thành'
LEFT JOIN HoaDon hd ON dp.MaDatPhong = hd.MaDatPhong AND hd.TrangThai = N'Đã thanh toán'
GROUP BY 
    kh.MaKH, kh.HoTen, kh.CCCD, kh.SDT, kh.Email
ORDER BY TongGiaTriChiTieu DESC;
GO

-- Đoạn code dùng trong truy vấn: Truy vấn gom nhóm kết hợp phép nối ngoài (LEFT JOIN, GROUP BY, Aggregate Functions).
-- Hoạt động như thế nào:
--   1. Sử dụng LEFT JOIN để giữ lại toàn bộ tập thực thể KhachHang.
--   2. Hàm COUNT(DISTINCT dp.MaDatPhong) loại trừ các bản ghi trùng lặp khi gom nhóm.
--   3. Biểu thức CASE WHEN phân cấp định lượng khách hàng thành các nhóm thành viên theo tiêu chí tổng doanh thu mang lại.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Cung cấp dữ liệu phân khúc khách hàng cho bộ phận kinh doanh và tiếp thị triển khai các chương trình khách hàng thân thiết.


-- ==========================================================================================
-- CASE 9: Bảng kê đối soát chi phí tiền phòng và dịch vụ trước thanh toán (Pre-bill Folio Audit)
-- TRƯỜNG HỢP SỬ DỤNG: Được thực hiện trước thời điểm khách hàng thanh toán trả phòng: Bộ phận thu ngân in bảng kê tạm tính (Guest Folio) để khách hàng rà soát chi tiết các khoản phí trước khi lập hóa đơn chính thức.
-- MỤC ĐÍCH: Tính toán độc lập và chính xác: Tổng tiền phòng = `SUM(ctdp.DonGia) * Số đêm lưu trú`, Tổng tiền dịch vụ = `SUM(ccdv.SoLuong * dv.DonGia)`, bảo đảm không bị nhân đôi dữ liệu (Cartesian Product) khi kết nối các quan hệ 1-N.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Khách hàng không sử dụng bất kỳ dịch vụ nào trong khách sạn -> Bảng CungCapDichVu không có dữ liệu, cần xử lý giá trị tiền dịch vụ mặc định về 0 để không gây lỗi phép cộng tổng tiền.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Bảng kê tạm tính chi phí lưu trú và dịch vụ trước khi lập hóa đơn
-- 1. THAM SỐ ĐẦU VÀO THỰC TẾ: Tiếp nhận mã đơn đặt phòng của khách yêu cầu xuất bảng kê (để NULL để auto chọn)
DECLARE @MaDatPhongFolio VARCHAR(10) = 'DP0028';

-- 2. CHẾ ĐỘ TỰ ĐỘNG (CHỈ CHẠY KHI ĐỂ NULL):
IF @MaDatPhongFolio IS NULL
BEGIN
    SELECT TOP 1 @MaDatPhongFolio = MaDatPhong 
    FROM DatPhong 
    WHERE TrangThai = N'Đã nhận phòng'
    ORDER BY NgayNhanDuKien ASC;
END;

WITH TienPhongCTE AS (
    -- Tính tiền phòng dựa trên đơn giá chốt trong hợp đồng đặt phòng và số đêm lưu trú
    SELECT 
        dp.MaDatPhong,
        DATEDIFF(DAY, dp.NgayNhanDuKien, dp.NgayTraDuKien) AS SoDem,
        SUM(ctdp.DonGia) AS TongDonGiaPhongMoiDem,
        SUM(ctdp.DonGia) * DATEDIFF(DAY, dp.NgayNhanDuKien, dp.NgayTraDuKien) AS TongTienPhong
    FROM DatPhong dp
    INNER JOIN ChiTietDatPhong ctdp ON dp.MaDatPhong = ctdp.MaDatPhong
    WHERE dp.MaDatPhong = @MaDatPhongFolio
    GROUP BY dp.MaDatPhong, dp.NgayNhanDuKien, dp.NgayTraDuKien
),
TienDichVuCTE AS (
    -- Tính tiền các dịch vụ khách hàng đã sử dụng
    SELECT 
        cc.MaDatPhong,
        ISNULL(SUM(cc.SoLuong * dv.DonGia), 0) AS TongTienDichVu
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
    ISNULL(tdv.TongTienDichVu, 0) AS TongTienDichVu,
    (tp.TongTienPhong + ISNULL(tdv.TongTienDichVu, 0)) AS TongChiPhiTamTinh
FROM DatPhong dp
INNER JOIN KhachHang kh ON dp.MaKH = kh.MaKH
LEFT JOIN TienPhongCTE tp ON dp.MaDatPhong = tp.MaDatPhong
LEFT JOIN TienDichVuCTE tdv ON dp.MaDatPhong = tdv.MaDatPhong
WHERE dp.MaDatPhong = @MaDatPhongFolio;
GO

-- Đoạn code dùng trong truy vấn: Truy vấn sử dụng bảng tạm CTE (Common Table Expression).
-- Hoạt động như thế nào:
--   1. Xây dựng 2 biểu thức bảng tạm độc lập 'TienPhongCTE' và 'TienDichVuCTE' để tính toán riêng rẽ các cấu phần chi phí.
--   2. Tránh hiện tượng bùng nổ bản ghi (Fan-out problem) khi JOIN đồng thời hai quan hệ một-nhiều vào một câu truy vấn đơn lẻ.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Cung cấp cơ sở đối soát minh bạch giữa khách hàng và bộ phận thu ngân trước khi chốt số liệu vào hóa đơn tài chính.


-- ==========================================================================================
-- CASE 10: Xử lý thủ tục trả phòng và xuất hóa đơn thanh toán khép kín (Check-out & Billing Transaction)
-- TRƯỜNG HỢP SỬ DỤNG: Khách hàng hoàn tất kỳ lưu trú và thực hiện thanh toán chi phí tại quầy thu ngân để kết thúc đơn đặt phòng.
-- MỤC ĐÍCH: Thực hiện chuỗi thao tác nguyên tử (Atomicity):
--   1. Tự động tính toán tổng tiền phòng và tiền dịch vụ thực tế để ghi nhận vào thực thể HoaDon.
--   2. Cập nhật trạng thái DatPhong sang 'Đã hoàn thành'.
--   3. Giải phóng tất cả các phòng vật lý trong ChiTietDatPhong về trạng thái 'Trống' để tiếp tục đón lượt khách kế tiếp.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   1. Vi phạm ràng buộc duy nhất (UQ_HoaDon_DatPhong): Mỗi đơn đặt phòng chỉ có duy nhất một hóa đơn thanh toán. Ngăn chặn việc xuất hóa đơn trùng lặp.
--   2. Kiểm soát ràng buộc CK_HoaDon_TongTien: Tổng tiền thanh toán (TienPhong + TienDichVu + TienPhuThu - GiamGia) không được nhỏ hơn 0.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Giao dịch trả phòng, quyết toán và xuất hóa đơn thanh toán
BEGIN TRANSACTION;
BEGIN TRY
    -- 1. THAM SỐ ĐẦU VÀO THỰC TẾ: Lễ tân tiếp nhận yêu cầu trả phòng của khách (để NULL để auto chọn)
    DECLARE @MaDatPhongCheckout VARCHAR(10) = 'DP0028';
    DECLARE @PhuongThucInput NVARCHAR(20) = N'Chuyển khoản';
    DECLARE @TienPhuThuInput DECIMAL(15,0) = 100000;
    DECLARE @GiamGiaInput DECIMAL(15,0) = 50000;

    -- 2. CHẾ ĐỘ TỰ ĐỘNG (CHỈ CHẠY KHI ĐỂ NULL):
    IF @MaDatPhongCheckout IS NULL
    BEGIN
        SELECT TOP 1 @MaDatPhongCheckout = dp.MaDatPhong 
        FROM DatPhong dp
        WHERE dp.TrangThai = N'Đã nhận phòng'
          AND NOT EXISTS (SELECT 1 FROM HoaDon hd WHERE hd.MaDatPhong = dp.MaDatPhong)
        ORDER BY dp.NgayNhanDuKien ASC;
    END;

    -- 3. HỆ THỐNG TỰ ĐỘNG ĐIỀU PHỐI (AUTO):
    -- Tự động điều phối nhân viên lễ tân đang làm việc lập hóa đơn
    DECLARE @MaNVLapCheckout VARCHAR(10);
    SELECT TOP 1 @MaNVLapCheckout = nv.MaNV 
    FROM NhanVien nv
    INNER JOIN LeTan lt ON nv.MaNV = lt.MaNV
    WHERE nv.TrangThai = N'Đang làm'
    ORDER BY nv.MaNV ASC;

    -- Tự động sinh mã hóa đơn tiếp theo (VD: HD0025 -> HD0026)
    DECLARE @MaHDNew VARCHAR(10);
    SELECT @MaHDNew = 'HD' + RIGHT('0000' + CAST(ISNULL(MAX(CAST(SUBSTRING(MaHD, 3, 10) AS INT)), 0) + 1 AS VARCHAR(10)), 4)
    FROM HoaDon;

    -- 1. Kiểm tra đơn đặt phòng phải đang ở trạng thái 'Đã nhận phòng'
    IF NOT EXISTS (
        SELECT 1 FROM DatPhong 
        WHERE MaDatPhong = @MaDatPhongCheckout AND TrangThai = N'Đã nhận phòng'
    )
    BEGIN
        THROW 50010, N'Lỗi nghiệp vụ: Đặt phòng không tồn tại hoặc chưa nhận phòng (không thể lập hóa đơn)!', 1;
    END;

    -- 2. Kiểm tra ràng buộc duy nhất: Đặt phòng chưa từng phát sinh hóa đơn
    IF EXISTS (SELECT 1 FROM HoaDon WHERE MaDatPhong = @MaDatPhongCheckout)
    BEGIN
        THROW 50011, N'Lỗi nghiệp vụ: Đặt phòng này đã được lập hóa đơn thanh toán trước đó!', 1;
    END;

    -- 3. Tự động tính toán tiền phòng thực tế
    DECLARE @CalcTienPhong DECIMAL(15,0);
    SELECT @CalcTienPhong = SUM(ctdp.DonGia) * DATEDIFF(DAY, dp.NgayNhanDuKien, dp.NgayTraDuKien)
    FROM DatPhong dp
    INNER JOIN ChiTietDatPhong ctdp ON dp.MaDatPhong = ctdp.MaDatPhong
    WHERE dp.MaDatPhong = @MaDatPhongCheckout
    GROUP BY dp.NgayNhanDuKien, dp.NgayTraDuKien;

    -- 4. Tự động tính toán tiền dịch vụ thực tế
    DECLARE @CalcTienDichVu DECIMAL(15,0);
    SELECT @CalcTienDichVu = ISNULL(SUM(cc.SoLuong * dv.DonGia), 0)
    FROM CungCapDichVu cc
    INNER JOIN DichVu dv ON cc.MaDV = dv.MaDV
    WHERE cc.MaDatPhong = @MaDatPhongCheckout;

    SET @CalcTienDichVu = ISNULL(@CalcTienDichVu, 0);

    -- 5. Kiểm tra ràng buộc miền giá trị của tổng tiền
    IF (@CalcTienPhong + @CalcTienDichVu + @TienPhuThuInput - @GiamGiaInput < 0)
    BEGIN
        THROW 50012, N'Lỗi nghiệp vụ: Tổng tiền thanh toán sau giảm giá không được phép nhỏ hơn 0!', 1;
    END;

    -- 6. Tạo hóa đơn thanh toán
    INSERT INTO HoaDon (
        MaHD, MaDatPhong, MaNVLap, MaNVKeToan, NgayLap, 
        TienPhong, TienDichVu, TienPhuThu, GiamGia, PhuongThucTT, TrangThai
    )
    VALUES (
        @MaHDNew, @MaDatPhongCheckout, @MaNVLapCheckout, NULL, GETDATE(),
        @CalcTienPhong, @CalcTienDichVu, @TienPhuThuInput, @GiamGiaInput, @PhuongThucInput, N'Đã thanh toán'
    );

    -- 7. Cập nhật trạng thái đặt phòng thành 'Đã hoàn thành'
    UPDATE DatPhong 
    SET TrangThai = N'Đã hoàn thành'
    WHERE MaDatPhong = @MaDatPhongCheckout;

    -- 8. Hoàn trả trạng thái các phòng vật lý về 'Trống'
    UPDATE p
    SET p.TrangThai = N'Trống'
    FROM Phong p
    INNER JOIN ChiTietDatPhong ctdp ON p.MaPhong = ctdp.MaPhong
    WHERE ctdp.MaDatPhong = @MaDatPhongCheckout;

    COMMIT TRANSACTION;
    PRINT N'Giao dịch trả phòng và xuất hóa đơn ' + @MaHDNew + N' hoàn tất thành công!';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @ErrMsgCheckout NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrMsgCheckout, 16, 1);
END CATCH;
GO

-- Đoạn code dùng trong truy vấn: Giao dịch thanh toán và cập nhật trạng thái hệ thống khép kín.
-- Hoạt động như thế nào:
--   1. Tự động tính toán số tiền trực tiếp từ các thực thể gốc ChiTietDatPhong và CungCapDichVu để đảm bảo tính toàn vẹn 3NF.
--   2. Khóa giao dịch thực hiện liên hoàn 3 hành động: Ghi nhận hóa đơn, hoàn tất đặt phòng, giải phóng phòng trống.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Là quy trình cốt lõi tại quầy thu ngân khi khách hàng rời khách sạn, kết thúc chu trình phục vụ.


-- ==========================================================================================
-- CASE 11: Kế toán đối soát và phân bổ doanh thu theo phương thức thanh toán (Revenue Reconciliation by Payment Method)
-- TRƯỜNG HỢP SỬ DỤNG: Được thực hiện định kỳ cuối mỗi ca làm việc hoặc cuối ngày: Bộ phận kế toán kiểm tra và đối chiếu tổng số tiền thu được theo từng kênh thanh toán (Tiền mặt, Thẻ tín dụng, Chuyển khoản ngân hàng).
-- MỤC ĐÍCH: Đảm bảo tính chính xác giữa số liệu ghi nhận trên phần mềm với tiền mặt thực tế tại két quỹ và sao kê giao dịch từ cổng thanh toán/ngân hàng; hỗ trợ cập nhật thông tin nhân viên kế toán (MaNVKeToan) xác nhận đã kiểm toán hóa đơn.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Loại trừ các hóa đơn chưa thanh toán ('Chưa thanh toán') để không tính toán sai lệch dòng tiền thực tế thu được trong ngày.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Báo cáo đối soát doanh thu phân bổ theo phương thức thanh toán
SELECT 
    hd.PhuongThucTT,
    COUNT(hd.MaHD) AS TongSoHoaDon,
    SUM(hd.TienPhong) AS TongTienPhong,
    SUM(hd.TienDichVu) AS TongTienDichVu,
    SUM(hd.TienPhuThu) AS TongPhuThu,
    SUM(hd.GiamGia) AS TongGiamGia,
    SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia) AS DoanhThuThuan,
    -- Tỷ trọng phần trăm đóng góp của từng phương thức thanh toán
    CAST(
        SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia) * 100.0 / 
        SUM(SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia)) OVER () 
        AS DECIMAL(5,2)
    ) AS TyTrongDoanhThuPhanTram
FROM HoaDon hd
WHERE hd.TrangThai = N'Đã thanh toán'
GROUP BY hd.PhuongThucTT
ORDER BY DoanhThuThuan DESC;
GO

-- Đoạn code dùng trong truy vấn: Thống kê tổng hợp kết hợp hàm cửa sổ (GROUP BY & Window Functions).
-- Hoạt động như thế nào:
--   1. Gom nhóm theo trường PhuongThucTT để phân loại dòng tiền.
--   2. Sử dụng hàm cửa sổ `SUM(...) OVER ()` tính tổng doanh thu toàn phần trên tập kết quả để suy ra tỷ trọng phần trăm trực tiếp trong một câu truy vấn duy nhất.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Phục vụ công tác quyết toán ca và đối chiếu chênh lệch giữa sổ sách kế toán và chứng từ ngân hàng.


-- ==========================================================================================
-- CASE 12: Báo cáo tổng hợp doanh thu theo thời gian phân tách theo cấu phần (Financial Revenue Breakdown Report)
-- TRƯỜNG HỢP SỬ DỤNG: Phục vụ công tác lập báo cáo tài chính định kỳ của khách sạn theo các mốc thời gian: Tháng, Quý, Năm.
-- MỤC ĐÍCH: Phân tích cấu trúc doanh thu toàn diện: Bóc tách rành mạch các thành phần Doanh thu phòng, Doanh thu dịch vụ, Tiền phụ thu, Tiền giảm giá và xác định Doanh thu thuần cuối cùng (`TienPhong + TienDichVu + TienPhuThu - GiamGia`).
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Tuân thủ nguyên tắc chuẩn hóa 3NF: Thuộc tính TongTien là thuộc tính dẫn xuất, được tính toán động từ các thuộc tính thành phần để loại bỏ sự dư thừa dữ liệu và ngăn chặn nguy cơ mâu thuẫn số liệu.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Báo cáo tổng hợp doanh thu theo tháng và năm
SELECT 
    YEAR(hd.NgayLap) AS Nam,
    MONTH(hd.NgayLap) AS Thang,
    COUNT(hd.MaHD) AS TongSoHoaDon,
    SUM(hd.TienPhong) AS DoanhThuTienPhong,
    SUM(hd.TienDichVu) AS DoanhThuDichVu,
    SUM(hd.TienPhuThu) AS TongTienPhuThu,
    SUM(hd.GiamGia) AS TongTienGiamGia,
    SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia) AS DoanhThuThuan,
    AVG(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia) AS GiaTriTrungBinhMoiHoaDon
FROM HoaDon hd
WHERE hd.TrangThai = N'Đã thanh toán'
GROUP BY YEAR(hd.NgayLap), MONTH(hd.NgayLap)
ORDER BY Nam DESC, Thang DESC;
GO

-- Đoạn code dùng trong truy vấn: Báo cáo tài chính quản trị (Financial Reporting Query).
-- Hoạt động như thế nào:
--   1. Trích xuất thành phần năm và tháng từ cột NgayLap bằng các hàm ngày tháng YEAR() và MONTH().
--   2. Tính toán chính xác doanh thu thuần dựa trên nguyên lý cộng dồn các khoản thu và trừ đi các khoản chiết khấu.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Cung cấp số liệu chính thức phục vụ báo cáo kết quả hoạt động kinh doanh cho Ban Giám đốc khách sạn.


-- ==========================================================================================
-- CASE 13: Thống kê và xếp hạng các dịch vụ mang lại doanh thu cao nhất (Top Profitable Services Analysis)
-- TRƯỜNG HỢP SỬ DỤNG: Phân tích danh mục sản phẩm dịch vụ gia tăng của khách sạn nhằm xác định các nhóm dịch vụ chủ lực và dịch vụ kém hiệu quả.
-- MỤC ĐÍCH: Xếp hạng các dịch vụ theo tổng doanh thu phát sinh và sản lượng tiêu thụ, tính toán tỷ trọng phần trăm đóng góp của từng dịch vụ trên tổng doanh thu dịch vụ chung.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Dịch vụ đã từng có giao dịch trong quá khứ nhưng hiện tại đã chuyển trạng thái sang 'Ngừng cung cấp' thì vẫn phải phản ánh trung thực số liệu doanh thu lịch sử.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Xếp hạng dịch vụ sinh lời cao nhất kèm tỷ trọng doanh thu
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
    CAST(TongDoanhThuDichVu * 100.0 / SUM(TongDoanhThuDichVu) OVER () AS DECIMAL(5,2)) AS TyTrongDoanhThuPhanTram
FROM ThongKeDichVuCTE
ORDER BY TongDoanhThuDichVu DESC;
GO

-- Đoạn code dùng trong truy vấn: Phân tích danh mục dịch vụ kết hợp hàm xếp hạng (DENSE_RANK & Window Function).
-- Hoạt động như thế nào:
--   1. Bảng tạm CTE tính toán tổng sản lượng và tổng doanh thu theo từng mã dịch vụ.
--   2. Hàm DENSE_RANK() xếp hạng không ngắt quãng các dịch vụ có doanh thu cao nhất.
--   3. Hàm SUM() OVER () tính tổng ngân sách toàn bộ dịch vụ để làm mẫu số tính tỷ trọng phần trăm.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Cung cấp căn cứ cho nhà quản lý điều chỉnh chiến lược nhập hàng, định giá dịch vụ và xây dựng các gói combo khuyến mãi.


-- ==========================================================================================
-- CASE 14: Thống kê tỷ lệ lấp đầy phòng và doanh thu trên mỗi phòng sẵn có (Occupancy Rate & RevPAR Analysis)
-- TRƯỜNG HỢP SỬ DỤNG: Đánh giá hiệu suất khai thác tài sản buồng phòng - chỉ số cốt lõi trong ngành quản trị khách sạn (Hospitality Management KPI).
-- MỤC ĐÍCH: Tính toán hai chỉ số vận hành tiêu chuẩn quốc tế theo từng Loại phòng:
--   1. Tỷ lệ lấp đầy phòng (Occupancy Rate) = `(Số phòng có khách / Tổng số phòng) * 100%`.
--   2. Doanh thu trên mỗi phòng sẵn có (RevPAR) = `Tỷ lệ lấp đầy * Đơn giá niêm yết`.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Tránh lỗi chia cho 0 (Division by zero) đối với các loại phòng chưa có phòng vật lý nào được kích hoạt thông qua hàm NULLIF.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Đánh giá chỉ số vận hành buồng phòng: Tỷ lệ lấp đầy (Occupancy) và RevPAR
SELECT 
    lp.MaLoaiPhong,
    lp.TenLoaiPhong,
    lp.GiaPhong AS GiaNiemYet,
    COUNT(p.MaPhong) AS TongSoPhongHienCo,
    SUM(CASE WHEN p.TrangThai = N'Đang sử dụng' THEN 1 ELSE 0 END) AS SoPhongDangCoKhach,
    SUM(CASE WHEN p.TrangThai = N'Trống' THEN 1 ELSE 0 END) AS SoPhongTrong,
    SUM(CASE WHEN p.TrangThai = N'Đang bảo trì' THEN 1 ELSE 0 END) AS SoPhongBaoTri,
    -- Tỷ lệ lấp đầy phòng (%)
    CAST(
        SUM(CASE WHEN p.TrangThai = N'Đang sử dụng' THEN 1.0 ELSE 0.0 END) / 
        NULLIF(COUNT(p.MaPhong), 0) * 100 
        AS DECIMAL(5,2)
    ) AS TyLeLapDayPhanTram,
    -- Chỉ số doanh thu trên mỗi phòng sẵn có (RevPAR)
    CAST(
        (SUM(CASE WHEN p.TrangThai = N'Đang sử dụng' THEN 1.0 ELSE 0.0 END) / NULLIF(COUNT(p.MaPhong), 0)) * lp.GiaPhong 
        AS DECIMAL(15,0)
    ) AS RevPAR_VND
FROM LoaiPhong lp
LEFT JOIN Phong p ON lp.MaLoaiPhong = p.MaLoaiPhong
GROUP BY lp.MaLoaiPhong, lp.TenLoaiPhong, lp.GiaPhong
ORDER BY RevPAR_VND DESC;
GO

-- Đoạn code dùng trong truy vấn: Thống kê hiệu suất vận hành (KPI Analytics Query).
-- Hoạt động như thế nào:
--   1. Sử dụng kỹ thuật đếm có điều kiện với biểu thức `SUM(CASE WHEN ... THEN 1 ELSE 0 END)`.
--   2. Hàm NULLIF(COUNT(p.MaPhong), 0) triệt tiêu hoàn toàn rủi ro chia cho 0 trong tính toán số học.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Cung cấp chỉ số vận hành để nhà quản lý thực hiện chiến lược định giá phòng linh hoạt (Revenue Management).


-- ==========================================================================================
-- CASE 15: Đánh giá hiệu suất làm việc của nhân viên lễ tân theo doanh số xử lý (Front Desk Staff Productivity Evaluation)
-- TRƯỜNG HỢP SỬ DỤNG: Phục vụ công tác đánh giá hiệu quả công việc (KPI) định kỳ của bộ phận nhân sự và quản lý tiền sảnh đối với nhân viên lễ tân.
-- MỤC ĐÍCH: Đo lường năng suất cụ thể của từng nhân viên lễ tân: Số lượng đơn đặt phòng đã tiếp nhận xử lý, số lượng hóa đơn thanh toán đã lập, và tổng giá trị doanh số thực tế mang lại cho khách sạn.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Chỉ xem xét các nhân viên đang ở trạng thái 'Đang làm'. Những nhân viên mới nhận việc chưa phát sinh giao dịch vẫn được hiển thị trong báo cáo với giá trị 0.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Đánh giá hiệu suất làm việc của nhân viên bộ phận Lễ tân
SELECT 
    nv.MaNV,
    nv.HoTen,
    lt.CaLam,
    nv.NgayLamViec,
    COUNT(DISTINCT dp.MaDatPhong) AS SoDonDatPhongTiepNhan,
    COUNT(DISTINCT hd.MaHD) AS SoHoaDonDaLap,
    ISNULL(SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia), 0) AS TongDoanhSoLapHoaDon,
    DENSE_RANK() OVER (
        ORDER BY ISNULL(SUM(hd.TienPhong + hd.TienDichVu + hd.TienPhuThu - hd.GiamGia), 0) DESC
    ) AS XepHangDoanhSo
FROM LeTan lt
INNER JOIN NhanVien nv ON lt.MaNV = nv.MaNV
LEFT JOIN DatPhong dp ON lt.MaNV = dp.MaNVXuLy
LEFT JOIN HoaDon hd ON lt.MaNV = hd.MaNVLap AND hd.TrangThai = N'Đã thanh toán'
WHERE nv.TrangThai = N'Đang làm'
GROUP BY nv.MaNV, nv.HoTen, lt.CaLam, nv.NgayLamViec
ORDER BY TongDoanhSoLapHoaDon DESC;
GO

-- Đoạn code dùng trong truy vấn: Đánh giá hiệu suất nhân sự (Productivity Analytics Query).
-- Hoạt động như thế nào:
--   1. Kết nối quan hệ con LeTan với quan hệ cha NhanVien dựa trên khóa chính/khóa ngoại MaNV.
--   2. Thực hiện LEFT JOIN sang DatPhong và HoaDon để thống kê khối lượng giao dịch đã xử lý.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Cung cấp căn cứ định lượng phục vụ công tác bình xét thi đua, khen thưởng và tính lương năng suất cho nhân viên.


-- ==========================================================================================
-- CASE 16: Truy vấn phân cấp tổ chức nhân sự bằng đệ quy (Organizational Hierarchy with Recursive CTE)
-- TRƯỜNG HỢP SỬ DỤNG: Ban Giám đốc và Phòng Nhân sự cần kiểm tra toàn bộ sơ đồ phân cấp quản lý trong khách sạn: Xác định chuỗi chỉ huy từ Tổng quản lý đến các quản lý bộ phận và nhân viên cấp dưới trực thuộc.
-- MỤC ĐÍCH: Sử dụng kỹ thuật truy vấn đệ quy (Recursive CTE) để duyệt qua mối quan hệ tự tham chiếu (Self-referencing Foreign Key: `NhanVien.MaQuanLy -> QuanLy.MaNV`), hiển thị cấp bậc quản trị và chuỗi phân cấp nhân sự.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   1. Điểm neo đệ quy (Anchor Member) là Quản lý cao nhất có `MaQuanLy IS NULL`.
--   2. Ép kiểu dữ liệu chuỗi (NVARCHAR(MAX)/CHAR) để đảm bảo tính đồng nhất kiểu dữ liệu giữa phần neo và phần đệ quy.
--   3. Ngăn ngừa lỗi tràn bộ nhớ hoặc vòng lặp vô tận khi dữ liệu bị lỗi tham chiếu chéo.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Truy vấn đệ quy xây dựng sơ đồ hình cây phân cấp tổ chức nhân sự
WITH SodoToChucCTE AS (
    -- Điểm neo (Anchor): Quản lý cấp cao nhất không có cấp trên quản lý trực tiếp
    SELECT 
        nv.MaNV,
        nv.HoTen,
        nv.ChucVu,
        nv.MaQuanLy,
        0 AS CapBacQuanLy,
        CAST(nv.HoTen AS NVARCHAR(MAX)) AS ChuoiPhanCapQuanLy
    FROM NhanVien nv
    WHERE nv.MaQuanLy IS NULL

    UNION ALL

    -- Phần đệ quy (Recursive): Nhân viên cấp dưới báo cáo trực tiếp cho cấp trên
    SELECT 
        nv.MaNV,
        nv.HoTen,
        nv.ChucVu,
        nv.MaQuanLy,
        sdtc.CapBacQuanLy + 1 AS CapBacQuanLy,
        CAST(sdtc.ChuoiPhanCapQuanLy + N' -> ' + nv.HoTen AS NVARCHAR(MAX))
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
GO

-- Đoạn code dùng trong truy vấn: Truy vấn đệ quy (Recursive Common Table Expression).
-- Hoạt động như thế nào:
--   1. Khởi tạo tập bản ghi cơ sở (Anchor Member) với điều kiện `MaQuanLy IS NULL` có cấp bậc 0.
--   2. Sử dụng UNION ALL để lặp đệ quy, kết nối trường MaQuanLy của nhân viên với MaNV của cấp quản lý đã duyệt ở bước trước.
--   3. Xây dựng chuỗi văn bản phân cấp trực quan mô tả đường dẫn báo cáo công việc.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Hiển thị sơ đồ cơ cấu tổ chức và hỗ trợ thiết lập quy trình phê duyệt phân cấp trong doanh nghiệp.


-- ==========================================================================================
-- CASE 17: Xử lý tình huống hủy đặt phòng và tự động hoàn trả trạng thái phòng (Booking Cancellation & Room Status Release)
-- TRƯỜNG HỢP SỬ DỤNG: Khách hàng liên hệ yêu cầu hủy đơn đặt phòng trước ngày nhận phòng theo chính sách hủy phòng của khách sạn.
-- MỤC ĐÍCH: Cập nhật trạng thái đơn đặt phòng sang 'Đã hủy', lưu vết lý do hủy, và tự động hoàn trả trạng thái của tất cả các phòng vật lý liên quan về 'Trống' để mở bán lại cho khách hàng khác.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   1. Chỉ cho phép hủy đối với các đơn đặt phòng đang ở trạng thái 'Đã đặt'. Từ chối hủy nếu khách đã nhận phòng hoặc đã hoàn thành.
--   2. Nếu phòng vật lý đang được một đơn đặt phòng khác sử dụng thì không được chuyển sai trạng thái phòng.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Xử lý nghiệp vụ Hủy đặt phòng đảm bảo an toàn trạng thái phòng
BEGIN TRANSACTION;
BEGIN TRY
    -- 1. THAM SỐ ĐẦU VÀO THỰC TẾ: Khách hàng liên hệ yêu cầu hủy đơn đặt phòng (để NULL để auto chọn)
    DECLARE @MaDatPhongCancel VARCHAR(10) = 'DP0040';
    DECLARE @LyDoHuy NVARCHAR(200) = N'Khách hàng thông báo hủy chuyến đi trước hạn';

    -- 2. CHẾ ĐỘ TỰ ĐỘNG (CHỈ CHẠY KHI ĐỂ NULL):
    IF @MaDatPhongCancel IS NULL
    BEGIN
        SELECT TOP 1 @MaDatPhongCancel = MaDatPhong 
        FROM DatPhong 
        WHERE TrangThai = N'Đã đặt'
        ORDER BY NgayDat DESC;
    END;

    -- 1. Kiểm tra trạng thái hợp lệ của đơn đặt phòng
    IF NOT EXISTS (
        SELECT 1 FROM DatPhong 
        WHERE MaDatPhong = @MaDatPhongCancel AND TrangThai = N'Đã đặt'
    )
    BEGIN
        THROW 50020, N'Lỗi nghiệp vụ: Chỉ có thể hủy đơn đặt phòng khi đang ở trạng thái [Đã đặt]!', 1;
    END;

    -- 2. Cập nhật trạng thái đơn đặt phòng sang 'Đã hủy'
    UPDATE DatPhong 
    SET TrangThai = N'Đã hủy',
        GhiChu = ISNULL(GhiChu + N'; ', N'') + N'Lý do hủy: ' + @LyDoHuy + N' (' + CONVERT(NVARCHAR(20), GETDATE(), 120) + N')'
    WHERE MaDatPhong = @MaDatPhongCancel;

    -- 3. Hoàn trả trạng thái phòng vật lý về 'Trống'
    UPDATE p
    SET p.TrangThai = N'Trống'
    FROM Phong p
    INNER JOIN ChiTietDatPhong ctdp ON p.MaPhong = ctdp.MaPhong
    WHERE ctdp.MaDatPhong = @MaDatPhongCancel
      AND p.TrangThai = N'Đã đặt';

    COMMIT TRANSACTION;
    PRINT N'Đã hoàn tất thủ tục hủy đặt phòng ' + @MaDatPhongCancel + N' và giải phóng phòng thành công!';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @ErrMsgCancel NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrMsgCancel, 16, 1);
END CATCH;
GO

-- Đoạn code dùng trong truy vấn: Xử lý ngoại lệ và hoàn trả trạng thái dữ liệu (Exception Handling).
-- Hoạt động như thế nào:
--   1. Sử dụng bẫy lỗi để bảo vệ trạng thái của các đơn đặt phòng đã nhận phòng không bị can thiệp sai quy trình.
--   2. Cập nhật giải phóng phòng có điều kiện nhằm bảo đảm phòng vật lý chỉ được chuyển về 'Trống' khi không có đơn đặt khác đang khai thác.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Giúp tối ưu hóa công suất khai thác phòng, nhanh chóng đưa phòng trở lại danh sách khả dụng để đón khách mới.


-- ==========================================================================================
-- CASE 18: Xử lý tình huống đổi phòng lưu trú giữa chừng cho khách hàng (Room Transfer & Upgrade Handling)
-- TRƯỜNG HỢP SỬ DỤNG: Khách hàng đang trong kỳ lưu trú có nhu cầu chuyển sang một phòng khác (do sự cố tiện nghi phòng cũ hoặc có nhu cầu nâng cấp lên loại phòng cao cấp hơn).
-- MỤC ĐÍCH: Thực hiện việc hoán đổi phòng: Kiểm tra phòng mới có sẵn sàng hay không, thay thế bản ghi trong quan hệ yếu ChiTietDatPhong, cập nhật lại đơn giá thỏa thuận mới, hoàn trả phòng cũ về 'Trống' và khóa phòng mới sang 'Đang sử dụng'.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Toàn bộ chu trình phải nằm trong một giao dịch nguyên tử; nếu phòng chuyển đến không ở trạng thái 'Trống' thì lập tức hủy bỏ giao dịch để bảo vệ quyền lợi lưu trú hiện tại của khách.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Xử lý nghiệp vụ chuyển phòng lưu trú giữa chừng cho khách hàng
BEGIN TRANSACTION;
BEGIN TRY
    -- 1. THAM SỐ ĐẦU VÀO THỰC TẾ: Khách hàng đang lưu trú yêu cầu chuyển sang phòng mới (để NULL để auto chọn)
    DECLARE @MaDatPhongDoi VARCHAR(10) = 'DP0028';
    DECLARE @MaPhongChuyenDen VARCHAR(10) = 'P001';

    -- 2. CHẾ ĐỘ TỰ ĐỘNG (CHỈ CHẠY KHI ĐỂ NULL):
    IF @MaDatPhongDoi IS NULL
    BEGIN
        SELECT TOP 1 @MaDatPhongDoi = MaDatPhong 
        FROM DatPhong 
        WHERE TrangThai = N'Đã nhận phòng'
        ORDER BY NgayNhanDuKien ASC;
    END;

    -- Lấy phòng hiện tại của đơn đặt phòng
    DECLARE @MaPhongHienTai VARCHAR(10);
    SELECT TOP 1 @MaPhongHienTai = ctdp.MaPhong
    FROM ChiTietDatPhong ctdp
    WHERE ctdp.MaDatPhong = @MaDatPhongDoi;

    IF @MaPhongChuyenDen IS NULL
    BEGIN
        SELECT TOP 1 @MaPhongChuyenDen = MaPhong 
        FROM Phong 
        WHERE TrangThai = N'Trống' AND MaPhong <> @MaPhongHienTai
        ORDER BY MaPhong ASC;
    END;

    -- 1. Kiểm tra phòng mới có đang thực sự ở trạng thái 'Trống' hay không
    IF NOT EXISTS (SELECT 1 FROM Phong WHERE MaPhong = @MaPhongChuyenDen AND TrangThai = N'Trống')
    BEGIN
        THROW 50030, N'Lỗi nghiệp vụ: Phòng mới được chọn hiện không ở trạng thái [Trống] để chuyển đến!', 1;
    END;

    -- 2. Lấy đơn giá niêm yết của loại phòng mới để làm đơn giá thỏa thuận
    DECLARE @DonGiaPhongMoi DECIMAL(15,0);
    SELECT @DonGiaPhongMoi = lp.GiaPhong
    FROM Phong p
    INNER JOIN LoaiPhong lp ON p.MaLoaiPhong = lp.MaLoaiPhong
    WHERE p.MaPhong = @MaPhongChuyenDen;

    -- 3. Cập nhật chi tiết đặt phòng: Xóa liên kết phòng cũ và thêm liên kết phòng mới
    DELETE FROM ChiTietDatPhong 
    WHERE MaDatPhong = @MaDatPhongDoi AND MaPhong = @MaPhongHienTai;

    INSERT INTO ChiTietDatPhong (MaDatPhong, MaPhong, DonGia)
    VALUES (@MaDatPhongDoi, @MaPhongChuyenDen, @DonGiaPhongMoi);

    -- 4. Hoàn trả phòng cũ về trạng thái 'Trống'
    UPDATE Phong SET TrangThai = N'Trống' WHERE MaPhong = @MaPhongHienTai;

    -- 5. Đổi trạng thái phòng mới sang 'Đang sử dụng'
    UPDATE Phong SET TrangThai = N'Đang sử dụng' WHERE MaPhong = @MaPhongChuyenDen;

    -- 6. Ghi vết kiểm toán vào đơn đặt phòng
    UPDATE DatPhong 
    SET GhiChu = ISNULL(GhiChu + N'; ', N'') + N'Chuyển từ phòng ' + @MaPhongHienTai + N' sang ' + @MaPhongChuyenDen + N' (' + CONVERT(NVARCHAR(20), GETDATE(), 120) + N')'
    WHERE MaDatPhong = @MaDatPhongDoi;

    COMMIT TRANSACTION;
    PRINT N'Đã hoàn tất việc chuyển phòng từ ' + @MaPhongHienTai + N' sang ' + @MaPhongChuyenDen + N' thành công!';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @ErrMsgDoi NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrMsgDoi, 16, 1);
END CATCH;
GO

-- Đoạn code dùng trong truy vấn: Xử lý biến động quan hệ yếu (Weak Entity Manipulation in Transaction).
-- Hoạt động như thế nào:
--   1. Khóa và kiểm tra trạng thái của phòng đích trước khi tiến hành hoán đổi.
--   2. Cập nhật lại bản ghi của quan hệ phụ thuộc ChiTietDatPhong bảo đảm phản ánh đúng đơn giá phòng mới.
--   3. Đồng bộ hóa việc chuyển đổi trạng thái của cả hai thực thể phòng vật lý.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Áp dụng khi lễ tân thực hiện nghiệp vụ đổi phòng (Room Move) hoặc nâng hạng phòng (Room Upgrade) cho khách.


-- ==========================================================================================
-- CASE 19: Xử lý tình huống gia hạn thời gian lưu trú và kiểm tra xung đột lịch đặt (Stay Extension & Overlap Verification)
-- TRƯỜNG HỢP SỬ DỤNG: Khách hàng đang lưu trú tại khách sạn có nhu cầu kéo dài thêm kỳ nghỉ so với ngày trả phòng dự kiến ban đầu.
-- MỤC ĐÍCH: Kiểm tra xem trong khoảng thời gian gia hạn mới có phát sinh xung đột với bất kỳ đơn đặt phòng nào khác trong tương lai đối với cùng các phòng vật lý đó hay không. Nếu không xung đột -> Cho phép cập nhật gia hạn ngày trả phòng. Nếu có xung đột -> Cảnh báo từ chối.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Chỉ kiểm tra giao cắt thời gian trong đoạn kéo dài thêm: từ `NgayTraDuKienCu` đến `NgayTraMoi`. Loại trừ việc tự so sánh với chính đơn đặt phòng đang xét.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Xử lý gia hạn thời gian lưu trú có kiểm tra xung đột lịch đặt tương lai
BEGIN TRANSACTION;
BEGIN TRY
    -- 1. THAM SỐ ĐẦU VÀO THỰC TẾ: Khách hàng yêu cầu gia hạn thêm số ngày lưu trú (để NULL để auto chọn)
    DECLARE @MaDatPhongGiaHan VARCHAR(10) = 'DP0028';
    DECLARE @SoNgayGiaHanThem INT = 2;

    -- 2. CHẾ ĐỘ TỰ ĐỘNG (CHỈ CHẠY KHI ĐỂ NULL):
    IF @MaDatPhongGiaHan IS NULL
    BEGIN
        SELECT TOP 1 @MaDatPhongGiaHan = MaDatPhong 
        FROM DatPhong 
        WHERE TrangThai = N'Đã nhận phòng'
        ORDER BY NgayNhanDuKien ASC;
    END;

    -- Tự động tính ngày trả mới từ ngày trả cũ cộng thêm số ngày gia hạn
    DECLARE @NgayTraCu DATE;
    SELECT @NgayTraCu = NgayTraDuKien 
    FROM DatPhong 
    WHERE MaDatPhong = @MaDatPhongGiaHan;

    DECLARE @NgayTraMoi DATE = DATEADD(DAY, @SoNgayGiaHanThem, @NgayTraCu);

    IF (@NgayTraCu IS NULL)
    BEGIN
        THROW 50040, N'Lỗi nghiệp vụ: Đơn đặt phòng không tồn tại hoặc khách chưa nhận phòng!', 1;
    END;

    IF (@NgayTraMoi <= @NgayTraCu)
    BEGIN
        THROW 50041, N'Lỗi nghiệp vụ: Ngày trả phòng mới phải sau ngày trả phòng hiện tại!', 1;
    END;

    -- Kiểm tra phòng có bị đơn đặt phòng khác đặt trước trong khoảng thời gian gia hạn không
    IF EXISTS (
        SELECT 1 
        FROM ChiTietDatPhong ctdp_cur
        INNER JOIN ChiTietDatPhong ctdp_other ON ctdp_cur.MaPhong = ctdp_other.MaPhong
        INNER JOIN DatPhong dp_other ON ctdp_other.MaDatPhong = dp_other.MaDatPhong
        WHERE ctdp_cur.MaDatPhong = @MaDatPhongGiaHan
          AND dp_other.MaDatPhong <> @MaDatPhongGiaHan
          AND dp_other.TrangThai IN (N'Đã đặt', N'Đã nhận phòng')
          AND dp_other.NgayNhanDuKien < @NgayTraMoi
          AND dp_other.NgayTraDuKien > @NgayTraCu
    )
    BEGIN
        THROW 50042, N'Lỗi nghiệp vụ: Không thể gia hạn vì phòng đã có khách hàng khác đặt trước trong khoảng thời gian tới!', 1;
    END;

    -- Cập nhật ngày trả phòng dự kiến mới
    UPDATE DatPhong 
    SET NgayTraDuKien = @NgayTraMoi,
        GhiChu = ISNULL(GhiChu + N'; ', N'') + N'Gia hạn lưu trú đến ngày ' + CONVERT(NVARCHAR(10), @NgayTraMoi, 120)
    WHERE MaDatPhong = @MaDatPhongGiaHan;

    COMMIT TRANSACTION;
    PRINT N'Gia hạn thời gian lưu trú cho đơn ' + @MaDatPhongGiaHan + N' thành công!';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @ErrMsgGH NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrMsgGH, 16, 1);
END CATCH;
GO

-- Đoạn code dùng trong truy vấn: Kiểm tra xung đột logic thời gian nâng cao (Interval Overlap Verification).
-- Hoạt động như thế nào:
--   1. Tự kết nối (Self-join) bảng ChiTietDatPhong để tìm tất cả các đơn đặt phòng khác có chung phòng vật lý.
--   2. Kiểm định điều kiện không chồng lấn lịch đặt trên đoạn thời gian kéo dài (@NgayTraCu -> @NgayTraMoi).
-- Dùng trong trường hợp thực tế như thế nào:
--   - Đảm bảo tính khả thi khi khách hàng muốn ở thêm mà không làm ảnh hưởng đến kế hoạch đón các lượt khách tiếp theo.


-- ==========================================================================================
-- CASE 20: Kiểm soát tranh chấp đặt phòng đồng thời bằng khóa mức dòng (Concurrency Control & Overbooking Prevention)
-- TRƯỜNG HỢP SỬ DỤNG: Nhiều luồng giao dịch đồng thời (ví dụ: Hai khách hàng trên website hoặc nhân viên lễ tân tại quầy) cùng chọn đặt một phòng vật lý cho cùng một khoảng ngày.
-- MỤC ĐÍCH: Áp dụng cơ chế khóa mức dòng bi quan (Pessimistic Row-level Locking):
--   - T-SQL: `WITH (UPDLOCK, HOLDLOCK)`
--   - MySQL: `SELECT ... FOR UPDATE`
--   Bảo đảm tuần tự hóa việc kiểm tra và đặt phòng, ngăn chặn hiện tượng Overbooking (bán trùng phòng).
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Hiện tượng tương tranh (Race Condition) và bóng ma (Phantom Read) khi đọc dữ liệu có thể dẫn đến việc hai giao dịch cùng nhận thấy phòng trống và cùng ghi nhận thành công nếu không áp dụng cơ chế khóa chặt chẽ.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Kiểm soát tranh chấp đặt phòng đồng thời bằng cơ chế khóa bi quan
BEGIN TRANSACTION;
BEGIN TRY
    -- 1. THAM SỐ ĐẦU VÀO THỰC TẾ: Khách hàng/Lễ tân chọn phòng và khoảng thời gian cần giữ chỗ (để NULL để auto chọn)
    DECLARE @MaPhongChon VARCHAR(10) = 'P005';
    DECLARE @NgayNhanBooking DATE = '2026-11-10';
    DECLARE @NgayTraBooking DATE = '2026-11-15';

    -- 2. CHẾ ĐỘ TỰ ĐỘNG (CHỈ CHẠY KHI ĐỂ NULL):
    IF @MaPhongChon IS NULL
    BEGIN
        SELECT TOP 1 @MaPhongChon = MaPhong 
        FROM Phong 
        WHERE TrangThai <> N'Đang bảo trì'
        ORDER BY MaPhong ASC;
    END;

    -- 1. Khóa bản ghi phòng bằng gợi ý UPDLOCK và HOLDLOCK để ngăn chặn các phiên khác sửa đổi
    SELECT MaPhong, SoPhong, TrangThai 
    FROM Phong WITH (UPDLOCK, HOLDLOCK)
    WHERE MaPhong = @MaPhongChon;

    -- 2. Kiểm tra xung đột lịch đặt phòng
    IF EXISTS (
        SELECT 1 
        FROM ChiTietDatPhong ctdp
        INNER JOIN DatPhong dp ON ctdp.MaDatPhong = dp.MaDatPhong
        WHERE ctdp.MaPhong = @MaPhongChon
          AND dp.TrangThai IN (N'Đã đặt', N'Đã nhận phòng')
          AND dp.NgayNhanDuKien < @NgayTraBooking
          AND dp.NgayTraDuKien > @NgayNhanBooking
    )
    BEGIN
        THROW 50050, N'Lỗi tranh chấp: Phòng này đã được một giao dịch khác giữ chỗ trước đó!', 1;
    END;

    -- 3. Tiếp tục các thao tác chèn đơn đặt phòng an toàn trong khối giao dịch
    PRINT N'Phòng ' + @MaPhongChon + N' đã được khóa giữ chỗ an toàn!';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @ErrMsgLock NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrMsgLock, 16, 1);
END CATCH;
GO

-- Đoạn code dùng trong truy vấn: Kiểm soát giao dịch tương tranh (Concurrency Control with Table Hints).
-- Hoạt động như thế nào:
--   1. Gợi ý khóa 'UPDLOCK' thông báo ý định cập nhật và 'HOLDLOCK' duy trì khóa Serializability xuyên suốt transaction.
--   2. Mọi giao dịch khác cố gắng kiểm tra phòng P005 sẽ bị đưa vào hàng đợi chờ (Lock Wait) cho đến khi giao dịch hiện hành kết thúc.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Cần thiết cho các hệ thống đặt phòng trực tuyến chịu tải lớn nhằm loại bỏ rủi ro bán trùng phòng cho hai khách hàng khác nhau.


-- ==========================================================================================
-- CASE 21: Phát hiện sai lệch số liệu và cảnh báo bất thường trên hóa đơn (Billing Discrepancy & Anomaly Detection)
-- TRƯỜNG HỢP SỬ DỤNG: Phục vụ công tác kiểm soát nội bộ và thanh tra tài chính: Rà soát toàn bộ các hóa đơn đã lập để phát hiện các dấu hiệu sai lệch số tiền hoặc gian lận thu chi.
-- MỤC ĐÍCH: So sánh độc lập số tiền lưu vết trên thực thể HoaDon với số tiền tính toán lại từ các thực thể gốc:
--   1. Tiền phòng trên hóa đơn so với `SUM(ctdp.DonGia) * Số đêm`.
--   2. Tiền dịch vụ trên hóa đơn so với `SUM(ccdv.SoLuong * dv.DonGia)`.
--   3. Phát hiện các hóa đơn có tổng tiền âm hoặc tiền giảm giá vượt quá tổng doanh thu.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Ngăn chặn và cảnh báo các hành vi gian lận thông đồng (ví dụ: Tự ý sửa cột giảm giá trên hóa đơn để chiếm đoạt tiền mặt của khách sạn).
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Truy vấn kiểm toán phát hiện sai lệch số liệu trên hóa đơn
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
        -- Tính toán lại tiền phòng chuẩn từ ChiTietDatPhong
        (
            SELECT SUM(ctdp.DonGia * DATEDIFF(DAY, dp.NgayNhanDuKien, dp.NgayTraDuKien))
            FROM DatPhong dp
            INNER JOIN ChiTietDatPhong ctdp ON dp.MaDatPhong = ctdp.MaDatPhong
            WHERE dp.MaDatPhong = hd.MaDatPhong
        ) AS TienPhongChuan,
        -- Tính toán lại tiền dịch vụ chuẩn từ CungCapDichVu
        ISNULL(
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
        WHEN TongTienThucThu < 0 THEN N'LỖI: Tổng tiền âm!'
        WHEN TienPhongHoaDon <> TienPhongChuan THEN N'CẢNH BÁO: Sai lệch tiền phòng!'
        WHEN TienDichVuHoaDon <> TienDichVuChuan THEN N'CẢNH BÁO: Sai lệch tiền dịch vụ!'
        WHEN GiamGia > (TienPhongHoaDon + TienDichVuHoaDon + TienPhuThu) THEN N'NGHI VẤN: Giảm giá vượt tổng thu!'
        ELSE N'Hợp lệ'
    END AS KetLuanKiemToan
FROM TinhToanChuanCTE
WHERE (TienPhongHoaDon <> TienPhongChuan)
   OR (TienDichVuHoaDon <> TienDichVuChuan)
   OR (TongTienThucThu < 0)
   OR (GiamGia > (TienPhongHoaDon + TienDichVuHoaDon + TienPhuThu));
GO

-- Đoạn code dùng trong truy vấn: Kiểm toán dữ liệu và phát hiện bất thường (Data Auditing Query).
-- Hoạt động như thế nào:
--   1. Sử dụng CTE tính toán đối chiếu chéo số tiền từ các bảng chi tiết với dữ liệu tổng hợp trên bảng HoaDon.
--   2. Lọc ra danh sách các trường hợp có độ chênh lệch khác 0 để phục vụ công tác thanh tra.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Giúp kiểm toán viên nội bộ phát hiện các sai sót phần mềm hoặc hành vi biển thủ tài chính trong khách sạn.


-- ==========================================================================================
-- CASE 22: Xử lý cập nhật thông tin nhân viên nghỉ việc và chuyển giao quyền quản lý (Employee Termination & Soft-Delete Reassignment)
-- TRƯỜNG HỢP SỬ DỤNG: Một nhân viên giữ chức vụ Quản lý (ví dụ: NV004) hoàn tất thủ tục thôi việc tại khách sạn.
-- MỤC ĐÍCH: 1. Thực hiện xóa mềm (Soft-Delete) bằng cách cập nhật `TrangThai = N'Nghỉ việc'`, ngăn chặn tài khoản này tiếp tục tham gia xử lý đặt phòng hoặc hóa đơn mới.
--   2. Tái cấu trúc chuỗi quản lý: Chuyển giao toàn bộ nhân viên cấp dưới trực thuộc của người nghỉ việc sang cho Quản lý kế nhiệm (ví dụ: NV001), bảo tồn tính toàn vẹn của cây tổ chức nhân sự.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Tuyệt đối không sử dụng lệnh DELETE để xóa bản ghi nhân viên vì sẽ vi phạm ràng buộc toàn vẹn khóa ngoại (FOREIGN KEY) với các bảng giao dịch lịch sử trong quá khứ (DatPhong, HoaDon, CungCapDichVu).
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Xử lý an toàn khi Quản lý nghỉ việc và chuyển giao nhân sự trực thuộc
BEGIN TRANSACTION;
BEGIN TRY
    -- 1. THAM SỐ ĐẦU VÀO THỰC TẾ: Ban Quản lý phê duyệt Quản lý thôi việc và chỉ định Quản lý kế nhiệm (để NULL để auto chọn)
    DECLARE @MaNVNghiViec VARCHAR(10) = 'NV020';
    DECLARE @MaQuanLyKeNhiem VARCHAR(10) = 'NV001';

    -- 2. CHẾ ĐỘ TỰ ĐỘNG (CHỈ CHẠY KHI ĐỂ NULL):
    IF @MaNVNghiViec IS NULL
    BEGIN
        SELECT TOP 1 @MaNVNghiViec = ql.MaNV
        FROM QuanLy ql
        INNER JOIN NhanVien nv ON ql.MaNV = nv.MaQuanLy
        WHERE nv.TrangThai = N'Đang làm'
        ORDER BY ql.MaNV DESC;
    END;

    IF @MaQuanLyKeNhiem IS NULL
    BEGIN
        SELECT TOP 1 @MaQuanLyKeNhiem = ql.MaNV 
        FROM QuanLy ql
        INNER JOIN NhanVien nv ON ql.MaNV = nv.MaNV
        WHERE ql.MaNV <> @MaNVNghiViec AND nv.TrangThai = N'Đang làm'
        ORDER BY ql.MaNV ASC;
    END;

    -- 1. Kiểm tra tính hợp lệ của Quản lý kế nhiệm
    IF NOT EXISTS (
        SELECT 1 
        FROM QuanLy ql
        INNER JOIN NhanVien nv ON ql.MaNV = nv.MaNV
        WHERE ql.MaNV = @MaQuanLyKeNhiem AND nv.TrangThai = N'Đang làm'
    )
    BEGIN
        THROW 50060, N'Lỗi nghiệp vụ: Quản lý kế nhiệm không hợp lệ hoặc đã nghỉ việc!', 1;
    END;

    -- 2. Cập nhật trạng thái xóa mềm (Soft-Delete) cho nhân viên nghỉ việc
    UPDATE NhanVien 
    SET TrangThai = N'Nghỉ việc'
    WHERE MaNV = @MaNVNghiViec;

    -- 3. Chuyển giao toàn bộ nhân viên cấp dưới sang Quản lý kế nhiệm
    UPDATE NhanVien 
    SET MaQuanLy = @MaQuanLyKeNhiem 
    WHERE MaQuanLy = @MaNVNghiViec;

    COMMIT TRANSACTION;
    PRINT N'Đã hoàn tất cập nhật trạng thái nghỉ việc và chuyển giao nhân sự thành công!';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @ErrMsgNV NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrMsgNV, 16, 1);
END CATCH;
GO

-- Đoạn code dùng trong truy vấn: Xử lý toàn vẹn dữ liệu nhân sự (Soft-Delete & Foreign Key Reassignment).
-- Hoạt động như thế nào:
--   1. Áp dụng chuẩn thiết kế Soft-Delete bảo vệ toàn vẹn lịch sử giao dịch kế toán và phòng tránh lỗi vi phạm khóa ngoại.
--   2. Cập nhật lại thuộc tính tự tham chiếu MaQuanLy trên bảng NhanVien để bảo tồn tính liên tục của cấu trúc phân cấp.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Áp dụng khi phòng Nhân sự thực hiện thủ tục thôi việc và chuyển giao nhân sự trên hệ thống ERP khách sạn.


-- ==========================================================================================
-- CASE 23: Khóa bảo trì phòng đột xuất và điều phối các đơn đặt phòng bị ảnh hưởng (Emergency Room Maintenance & Rescheduling)
-- TRƯỜNG HỢP SỬ DỤNG: Phòng vật lý (ví dụ: P010) phát sinh sự cố kỹ thuật đột xuất (rò rỉ ống nước, chập điện) đòi hỏi phải tạm ngừng phục vụ để sửa chữa.
-- MỤC ĐÍCH: 1. Chuyển trạng thái phòng sang 'Đang bảo trì' để ngăn chặn các lượt đặt phòng mới.
--   2. Rà soát và lập danh sách tất cả các đơn đặt phòng trong tương lai đã gán phòng P010 để bộ phận tiếp tân chủ động liên hệ điều chuyển khách hàng sang các phòng tương đương.
-- TÌNH HUỐNG NGOẠI LỆ (EDGE CASE):
--   Nếu phòng hiện tại đang có khách ở ('Đang sử dụng') thì hệ thống cảnh báo yêu cầu thực hiện thủ tục đổi phòng cho khách trước khi khóa bảo trì.
-- THAO TÁC CHẠY: Bôi đen trọn vẹn khối code dưới đây (từ DECLARE đến GO) rồi nhấn F5.
-- ==========================================================================================
-- Khóa bảo trì phòng khẩn cấp và tìm kiếm các đơn đặt phòng tương lai bị ảnh hưởng
BEGIN TRANSACTION;
BEGIN TRY
    -- 1. THAM SỐ ĐẦU VÀO THỰC TẾ: Bộ phận kỹ thuật báo cáo phòng sự cố và lý do bảo trì (để NULL để auto chọn)
    DECLARE @MaPhongBaoTri VARCHAR(10) = 'P001';
    DECLARE @LyDoBaoTri NVARCHAR(200) = N'Khóa bảo trì đột xuất do sự cố rò rỉ đường ống nước';

    -- 2. CHẾ ĐỘ TỰ ĐỘNG (CHỈ CHẠY KHI ĐỂ NULL):
    IF @MaPhongBaoTri IS NULL
    BEGIN
        SELECT TOP 1 @MaPhongBaoTri = MaPhong 
        FROM Phong 
        WHERE TrangThai = N'Trống'
        ORDER BY MaPhong ASC;
    END;

    -- 1. Kiểm tra trạng thái hiện tại: Ngăn chặn khóa phòng nếu đang có khách lưu trú
    IF EXISTS (SELECT 1 FROM Phong WHERE MaPhong = @MaPhongBaoTri AND TrangThai = N'Đang sử dụng')
    BEGIN
        THROW 50070, N'Cảnh báo nghiệp vụ: Phòng hiện đang có khách ở! Phải thực hiện chuyển phòng cho khách trước khi khóa bảo trì.', 1;
    END;

    -- 2. Cập nhật trạng thái phòng sang 'Đang bảo trì'
    UPDATE Phong 
    SET TrangThai = N'Đang bảo trì',
        MoTa = ISNULL(MoTa + N'; ', N'') + @LyDoBaoTri
    WHERE MaPhong = @MaPhongBaoTri;

    -- 3. Rà soát danh sách các đơn đặt phòng tương lai đã gán phòng này
    SELECT 
        dp.MaDatPhong,
        kh.HoTen AS TenKhachHang,
        kh.SDT,
        kh.Email,
        dp.NgayDat,
        dp.NgayNhanDuKien,
        dp.NgayTraDuKien,
        lp.TenLoaiPhong,
        N'CẦN ĐIỀU CHUYỂN SANG PHÒNG KHÁC CÙNG LOẠI ' + lp.TenLoaiPhong AS PhuongAnDieuPhoi
    FROM DatPhong dp
    INNER JOIN ChiTietDatPhong ctdp ON dp.MaDatPhong = ctdp.MaDatPhong
    INNER JOIN Phong p ON ctdp.MaPhong = p.MaPhong
    INNER JOIN LoaiPhong lp ON p.MaLoaiPhong = lp.MaLoaiPhong
    INNER JOIN KhachHang kh ON dp.MaKH = kh.MaKH
    WHERE ctdp.MaPhong = @MaPhongBaoTri
      AND dp.TrangThai = N'Đã đặt'
      AND dp.NgayTraDuKien >= CAST(GETDATE() AS DATE)
    ORDER BY dp.NgayNhanDuKien ASC;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @ErrMsgBT NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrMsgBT, 16, 1);
END CATCH;
GO

-- Đoạn code dùng trong truy vấn: Xử lý sự cố buồng phòng và rà soát tác động (Impact Analysis Query).
-- Hoạt động như thế nào:
--   1. Khóa trạng thái phòng 'Đang bảo trì' bảo đảm loại trừ phòng khỏi danh sách phòng trống.
--   2. Quét toàn bộ các đơn đặt phòng tương lai có liên kết tới phòng bị sự cố để cung cấp danh sách điều phối dự phòng.
-- Dùng trong trường hợp thực tế như thế nào:
--   - Giúp bộ phận lễ tân chủ động xử lý tình huống phát sinh, duy trì chất lượng dịch vụ khách hàng.

