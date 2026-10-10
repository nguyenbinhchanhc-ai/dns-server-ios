//
//  SettingsView.swift
//  DNSGuard
//
//  Created for iOS Local DNS VPN & Optimizer.
//  Settings: Load balancing algorithm, cache policies, and error self-healing switches.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager = SharedDataManager.shared
    
    @State private var autoRepairIPChecksum = true
    @State private var autoRepairUDPChecksum = true
    @State private var autoHealTruncated = true
    @State private var filterMalformedPackets = true
    @State private var cacheCapacity = 4096.0
    @State private var showingPurgeAlert = false
    @State private var purgeConfirmed = false
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Load Balancing Strategy
                Section(header: Text("Thuật toán điều phối & Cân bằng tải"), footer: Text("Chế độ Racing sẽ gửi song song truy vấn đến 3 server nhanh nhất và lấy ngay kết quả đầu tiên để triệt tiêu độ trễ mạng.")) {
                    Picker("Chiến lược", selection: Binding(
                        get: { dataManager.currentStrategy },
                        set: { dataManager.updateStrategy($0) }
                    )) {
                        ForEach(LoadBalancingStrategy.allCases, id: \.self) { strat in
                            Text(strat.rawValue).tag(strat)
                        }
                    }
                }
                
                // MARK: - Packet Self-Healing
                Section(header: Text("Cơ chế tự sửa gói tin lỗi (Self-Healing)"), footer: Text("Khi phát hiện gói tin DNS hoặc IP/UDP bị sai lệch checksum hay bị cắt cụt do đường truyền suy hao, hệ thống sẽ tự động tính toán lại RFC 1071 và chuyển hướng TCP/DoH để tái tạo gói tin hoàn chỉnh.")) {
                    Toggle("Tự động sửa Checksum IPv4", isOn: $autoRepairIPChecksum)
                    Toggle("Tự động sửa Checksum UDP & Pseudo-Header", isOn: $autoRepairUDPChecksum)
                    Toggle("Tự phục hồi gói tin cắt cụt (TC Truncated)", isOn: $autoHealTruncated)
                    Toggle("Lọc và chặn gói DNS dị dạng / Loop Attack", isOn: $filterMalformedPackets)
                }
                
                // MARK: - In-Memory Cache
                Section(header: Text("Tăng tốc bộ nhớ đệm (LRU In-Memory Cache)"), footer: Text("Lưu tạm thời câu trả lời DNS trong RAM điện thoại với TTL đếm ngược. Các truy vấn lặp lại được phản hồi ngay trong < 0.5 ms.")) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Dung lượng bộ nhớ")
                            Spacer()
                            Text("\(Int(cacheCapacity)) mục")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $cacheCapacity, in: 512...8192, step: 512)
                    }
                    
                    Button(role: .destructive, action: { showingPurgeAlert = true }) {
                        HStack {
                            Image(systemName: "trash.circle")
                            Text("Xóa toàn bộ Cache hiện tại")
                        }
                    }
                }
                
                // MARK: - Tunnel Details
                Section(header: Text("Thông tin mạng ảo (Tunnel Details)")) {
                    HStack {
                        Text("Cấu trúc VPN")
                        Spacer()
                        Text("On-Device Local Loopback")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Virtual TUN IP")
                        Spacer()
                        Text("10.8.0.2")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Virtual DNS Gateway")
                        Spacer()
                        Text("10.8.0.1:53")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Network Extension")
                        Spacer()
                        Text("NEPacketTunnelProvider")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Về ứng dụng")) {
                    HStack {
                        Text("Phiên bản")
                        Spacer()
                        Text("1.0.0 (Build 2026.1)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Bản quyền")
                        Spacer()
                        Text("Antigravity Engine")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Cài đặt")
            .alert(isPresented: $showingPurgeAlert) {
                Alert(
                    title: Text("Xác nhận xóa Cache"),
                    message: Text("Toàn bộ bảng ghi DNS đã cache trong RAM sẽ được giải phóng."),
                    primaryButton: .destructive(Text("Xóa Cache")) {
                        purgeConfirmed = true
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}
