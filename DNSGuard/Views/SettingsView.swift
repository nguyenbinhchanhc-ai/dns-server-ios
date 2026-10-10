//
//  SettingsView.swift
//  DNSGuard
//
//  Created for iOS Local DNS Optimizer.
//  Settings for RAM cache acceleration, continuous probing, and persistent data reset.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var ramCache = RAMCacheAccelerator.shared
    @ObservedObject var profileServer = ProfileServer.shared
    
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Native Profile Installation
                Section(
                    header: Text("Hồ sơ DNS Native (Apple DoH)"),
                    footer: Text("Cài đặt hồ sơ trực tiếp vào iOS Settings giúp bạn sử dụng DNS tối ưu 100% thời gian mà không bị lỗi cấp quyền VPN.")
                ) {
                    Button(action: {
                        profileServer.openProfileInSafari()
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.doc.fill")
                                .foregroundColor(.blue)
                            Text("Mở cài đặt Profile qua Safari")
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                // MARK: - RAM Cache Acceleration
                Section(
                    header: Text("Tăng tốc bằng RAM thiết bị (L1 In-Memory Cache)"),
                    footer: Text("Sử dụng bộ nhớ RAM thật của iPhone để lưu các tên miền thường dùng, giúp tốc độ phản hồi đạt mức dưới 0.2ms.")
                ) {
                    Toggle("Bật cơ chế tăng tốc RAM", isOn: $ramCache.isRAMAcceleratorEnabled)
                    
                    HStack {
                        Text("Dung lượng RAM đang dùng")
                        Spacer()
                        Text(String(format: "%.1f MB", ramCache.estimatedRAMUsageMB))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Tốc độ RAM L1")
                        Spacer()
                        Text(String(format: "%.2f ms", ramCache.averageRAMLookupTimeMs))
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    Button("Làm mới bộ nhớ RAM L1") {
                        ramCache.clearRAMCache()
                        ramCache.preloadPopularDomainsIntoRAM()
                    }
                }
                
                // MARK: - Persistent Storage & Reset Data
                Section(
                    header: Text("Lưu trữ dữ liệu trên máy"),
                    footer: Text("Mọi số liệu truy vấn và đo đạc được lưu trong ổ nhớ máy, không bị mất khi đóng app. Bạn có thể xóa bất cứ lúc nào.")
                ) {
                    HStack {
                        Text("Tổng truy vấn đã lưu")
                        Spacer()
                        Text("\(storage.totalQueries)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Ngày bắt đầu ghi nhận")
                        Spacer()
                        Text(storage.installedDate, style: .date)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(role: .destructive, action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                            Text("Reset Dữ Liệu về 0")
                        }
                        .foregroundColor(.red)
                    }
                }
                
                // MARK: - App Version
                Section(header: Text("Thông tin ứng dụng")) {
                    HStack {
                        Text("Phiên bản")
                        Spacer()
                        Text("2.0.0 (Native DoH + RAM Engine)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Kiến trúc")
                        Spacer()
                        Text("Apple DoH + Local RAM Cache")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Cài đặt")
            .alert("Xác nhận Reset Dữ Liệu", isPresented: $showingResetAlert) {
                Button("Xóa & Reset", role: .destructive) {
                    storage.resetAllData()
                }
                Button("Hủy", role: .cancel) { }
            } message: {
                Text("Toàn bộ số lượng truy vấn, thời gian tăng tốc và lịch sử đã lưu trên máy sẽ trở về 0.")
            }
        }
    }
}
