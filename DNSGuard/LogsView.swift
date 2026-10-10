//
//  LogsView.swift
//  DNSGuard
//
//  Created for iOS Local DNS Optimizer.
//  Persistent DNS Query & Packet Repair Inspector with local storage integration,
//  domain search, high-density realtime streaming, QoS Priority Filter (P0-P3),
//  and Color-Tagged Server & Priority Badges.
//

import SwiftUI

struct LogsView: View {
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var prober = ContinuousDNSProber.shared
    
    @State private var selectedFilter: LogFilter = .all
    @State private var searchText: String = ""
    @State private var showingClearAlert = false
    
    enum LogFilter: String, CaseIterable {
        case all = "Tất cả"
        case p0 = "P0 Khẩn cấp"
        case p1 = "P1 Ưu tiên"
        case p2 = "P2 Chuẩn"
        case p3 = "P3 Lọc rác"
        case repaired = "Vá lỗi"
    }
    
    var filteredLogs: [DNSQueryLog] {
        var logs = storage.queryLogs
        
        switch selectedFilter {
        case .all:
            break
        case .p0:
            logs = logs.filter { $0.priorityTier == "P0" }
        case .p1:
            logs = logs.filter { $0.priorityTier == "P1" }
        case .p2:
            logs = logs.filter { $0.priorityTier == "P2" }
        case .p3:
            logs = logs.filter { $0.priorityTier == "P3" }
        case .repaired:
            logs = logs.filter { $0.isRepaired }
        }
        
        if !searchText.isEmpty {
            logs = logs.filter { $0.domain.localizedCaseInsensitiveContains(searchText) }
        }
        
        return logs
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // Realtime Stream Indicator & High-Burst Action
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color.green.opacity(0.5), lineWidth: 2)
                                    .scaleEffect(1.4)
                            )
                        Text("REALTIME LIVE")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.green)
                        Text("(\(String(format: "%.1f", prober.liveQPS)) QPS)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text("\(filteredLogs.count) bản ghi • \(storage.repairedPackets) vá lỗi")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        prober.runBatchTestQueries(count: 8)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                            Text("Bắn 8 Query")
                        }
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 6)
                
                // QoS Priority & Status Filter Segmented Control
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(LogFilter.allCases, id: \.self) { filter in
                            Button(action: {
                                selectedFilter = filter
                            }) {
                                Text(filter.rawValue)
                                    .font(.caption2)
                                    .fontWeight(selectedFilter == filter ? .bold : .medium)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(selectedFilter == filter ? Color.blue : Color(.secondarySystemFill))
                                    .foregroundColor(selectedFilter == filter ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                Divider()
                
                if filteredLogs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: selectedFilter == .repaired ? "wrench.and.screwdriver.fill" : "tray.fill")
                            .font(.system(size: 48))
                            .foregroundColor(selectedFilter == .repaired ? .green.opacity(0.7) : .secondary.opacity(0.6))
                        
                        Text(selectedFilter == .all ? "Chưa có nhật ký truy vấn nào" : "Không có nhật ký nào trong mục '\(selectedFilter.rawValue)'")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Nhấn nút bên dưới để tạo ngay các truy vấn DNS đa mức ưu tiên QoS.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button(action: {
                            prober.runBatchTestQueries(count: 10)
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Chạy Test 10 Truy Vấn Ngay")
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredLogs) { log in
                            logRow(log: log)
                                .padding(.vertical, 3)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Nhật ký truy vấn")
            .searchable(text: $searchText, prompt: "Tìm kiếm tên miền (vd: apple, google, vnecdn)...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            prober.runBatchTestQueries(count: 15)
                        }) {
                            Label("Bắn Đợt Bùng Nổ 15 Query", systemImage: "bolt.shield")
                        }
                        
                        Button(action: {
                            storage.seedRealisticLogs()
                        }) {
                            Label("Khôi phục nhật ký mẫu", systemImage: "arrow.clockwise")
                        }
                        
                        Button(role: .destructive, action: {
                            showingClearAlert = true
                        }) {
                            Label("Xóa toàn bộ nhật ký", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Xác nhận xóa nhật ký", isPresented: $showingClearAlert) {
                Button("Xóa tất cả", role: .destructive) {
                    storage.queryLogs.removeAll()
                    storage.saveToDisk()
                }
                Button("Hủy", role: .cancel) { }
            } message: {
                Text("Toàn bộ lịch sử các truy vấn DNS sẽ bị xóa khỏi bộ nhớ.")
            }
        }
    }
    
    private func logRow(log: DNSQueryLog) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // Priority Badge (P0, P1, P2, P3)
                Text(log.priorityTier)
                    .font(.system(size: 9, weight: .black))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color(hex: log.priorityColorHex).opacity(0.18))
                    .foregroundColor(Color(hex: log.priorityColorHex))
                    .cornerRadius(4)
                
                Text(log.domain)
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                Spacer()
                
                Text(log.recordType)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
            
            HStack(spacing: 8) {
                // Server Badge with Server Color Tagging
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: log.serverColorHex))
                        .frame(width: 6, height: 6)
                    Text(log.serverUsed)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: log.serverColorHex))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(hex: log.serverColorHex).opacity(0.12))
                .cornerRadius(5)
                
                if let strat = log.strategy, strat != "L1 Fast-Path" {
                    Text("• \(strat)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(String(format: "%.2f ms", log.latencyMs))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(log.latencyMs < 1.0 ? .green : (log.latencyMs < 20.0 ? .blue : .orange))
            }
            
            HStack(spacing: 8) {
                if let ip = log.resolvedIP {
                    Text("IP: \(ip)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(formatDate(log.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            
            if let reason = log.repairReason {
                HStack(spacing: 6) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                    Text("ĐÃ TỰ VÁ LỖI: \(reason)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                    Spacer()
                    Text("LÀNH LẶN 100%")
                        .font(.system(size: 8, weight: .black))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(3)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.08))
                .cornerRadius(6)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
