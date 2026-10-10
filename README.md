# DNSGuard: iOS Local DNS VPN & Optimizer App (.ipa)

Ứng dụng iOS cao cấp sử dụng cơ chế **Local Packet Tunnel (VPN ảo ngay trên thiết bị qua Apple `NetworkExtension`)** để đánh chặn và điều phối 100% lưu lượng truy vấn DNS toàn hệ thống qua các máy chủ DNS tối ưu nhất, tích hợp cân bằng tải, bộ nhớ đệm tăng tốc siêu tốc (< 0.5 ms) và **cơ chế tự sửa các gói tin lỗi (Autonomous Packet Self-Healing)**.

---

## 🚀 Tính năng cốt lõi

### 1. Mạng ảo VPN nội bộ trên máy (`NEPacketTunnelProvider`)
- Tạo giao diện mạng ảo TUN nội bộ (`10.8.0.2/24`) với cổng DNS Gateway ảo `10.8.0.1:53`.
- **Split-Tunneling**: Chỉ định tuyến truy vấn DNS qua Tunnel; toàn bộ băng thông lưu lượng tải trang (HTTP/HTTPS/Video) chạy trực tiếp qua Wi-Fi / 4G / 5G với tốc độ nguyên bản không bị suy hao.

### 2. Điều phối & Cân bằng tải đa máy chủ (Load Balancer)
- **Pool máy chủ**: Cloudflare (`1.1.1.1`, `1.0.0.1`), Google (`8.8.8.8`, `8.8.4.4`), Quad9 (`9.9.9.9`), AdGuard (`94.140.14.14`), và máy chủ tùy chỉnh (NextDNS, OpenDNS,...).
- **Thuật toán thông minh**:
  - **Racing Mode (Đua tốc độ)**: Gửi đồng thời truy vấn đến top 3 máy chủ nhanh nhất; nhận câu trả lời hợp lệ đầu tiên và hủy yêu cầu trễ, giảm triệt để Tail Latency.
  - **Weighted Latency (EWMA)**: Đo lường độ trễ động theo hàm mũ, dồn tải tự động vào server có phản hồi nhanh nhất theo từng mạng Wi-Fi/Di động.
  - **Fastest Mode & Round Robin**: Định tuyến linh hoạt theo cấu hình người dùng.
  - **Circuit Breaker**: Tự động ngắt server bị mất kết nối hoặc quá 3 lần lỗi liên tiếp.

### 3. Tăng tốc độ xử lý vượt trội (< 0.5 ms)
- **High-Speed LRU Cache (In-Memory)**: Lưu trữ trong RAM thiết bị lên đến 4096 bản ghi DNS phổ biến.
- **Dynamic TTL Countdown**: Tự động giảm TTL theo thời gian thực trước khi phản hồi về máy, đảm bảo dữ liệu luôn chính xác mà không tốn công truy vấn ra Internet.

### 4. Cơ chế tự sửa các gói tin lỗi (Packet Self-Healing)
- **Tự sửa Checksum IPv4 & UDP (RFC 1071 / RFC 768 / RFC 791)**: Phát hiện và tính toán lại checksum một phần bù (one's complement) khi gói tin bị đảo bit hoặc suy hao trên đường truyền.
- **Khắc phục cắt cụt gói tin (TC Truncation Recovery)**: Khi server UDP trả về cờ `TC=1` (gói tin > 512 bytes), bộ điều phối tự động fallback sang DoH (DNS over HTTPS) hoặc TCP để lấy toàn vẹn dữ liệu, xóa cờ cắt cụt và tái tạo gói tin đầy đủ cho ứng dụng.
- **Chống Loop Pointer Attack**: Ngăn ngừa tấn công vòng lặp đệ quy trong nén nhãn tên miền RFC 1035.

---

## 📦 Cấu trúc thư mục dự án

```
ios-dns-vpn-app/
├── DNSGuard.ipa                       # File cài đặt iOS IPA hoàn chỉnh
├── DNSGuard.xcodeproj/                # Dự án Xcode (project.pbxproj)
├── DNSGuard/                          # Ứng dụng giao diện SwiftUI
│   ├── App/DNSGuardApp.swift
│   ├── Services/
│   │   ├── VPNManager.swift           # Quản lý NETunnelProviderManager
│   │   └── SharedDataManager.swift    # Đồng bộ IPC App Group
│   ├── Views/
│   │   ├── DashboardView.swift        # Màn hình chính & công tắc VPN
│   │   ├── ServerManagementView.swift # Quản lý & kiểm tra ping server
│   │   ├── LogsView.swift             # Giám sát truy vấn & gói tin tự sửa
│   │   ├── SettingsView.swift         # Cài đặt thuật toán & cache
│   │   └── ContentView.swift          # Tab navigation
│   ├── Models/
│   └── Resources/ (Info.plist, DNSGuard.entitlements)
├── DNSGuardTunnel/                    # NetworkExtension Target
│   ├── PacketTunnelProvider.swift     # Xử lý TUN packet flow
│   ├── Engine/
│   │   ├── DNSEngine.swift            # Điều phối trung tâm
│   │   ├── DNSPacketParser.swift      # Binary RFC 1035 parser/serializer
│   │   ├── PacketRepairer.swift       # Tự sửa lỗi Checksum & cắt cụt
│   │   ├── DNSCache.swift             # Cache LRU trong bộ nhớ
│   │   ├── DNSLoadBalancer.swift      # Cân bằng tải & Circuit Breaker
│   │   └── DNSUpstreamDispatcher.swift# UDP + DoH async racing
│   └── Resources/ (Info.plist, DNSGuardTunnel.entitlements)
├── Shared/AppGroupConstants.swift     # Hằng số chung
└── Scripts/
    ├── build_ipa.py                   # Script tạo file .ipa độc lập
    └── test_engine.py                 # Bộ kiểm thử tự động
```

---

## 📲 Hướng dẫn cài đặt file `.ipa` lên iPhone / iPad

Bạn có thể cài đặt trực tiếp file `DNSGuard.ipa` vào thiết bị iOS bằng bất kỳ phương thức nào dưới đây:

### Cách 1: Cài đặt qua TrollStore (Khuyên dùng - Không cần chứng chỉ)
1. Gửi file `DNSGuard.ipa` vào iPhone (qua AirDrop, Telegram, Google Drive, hoặc iCloud).
2. Mở file trong ứng dụng **TrollStore** -> Chọn **Install**.
3. Ứng dụng sẽ có đầy đủ quyền NetworkExtension vĩnh viễn mà không bao giờ bị thu hồi (revoke).

### Cách 2: Cài đặt qua AltStore / SideStore
1. Mở **AltStore** trên máy tính hoặc trên iPhone.
2. Nhấn vào dấu `+` ở góc trên tab My Apps -> Chọn `DNSGuard.ipa`.
3. Đăng nhập Apple ID để ký chứng chỉ 7 ngày và sử dụng.

### Cách 3: Cài đặt qua Sideloadly / 3uTools (Windows & macOS)
1. Kết nối iPhone với máy tính qua cáp USB.
2. Mở Sideloadly, kéo thả file `DNSGuard.ipa` vào giao diện.
3. Nhập Apple ID và nhấn **Start**.

### Cách 4: Biên dịch trực tiếp qua Xcode (Dành cho Lập trình viên)
1. Mở thư mục dự án `DNSGuard.xcodeproj` bằng Xcode trên macOS.
2. Chọn Developer Team trong mục Signing & Capabilities.
3. Chọn thiết bị iPhone đích và nhấn **Run** (Command + R).
