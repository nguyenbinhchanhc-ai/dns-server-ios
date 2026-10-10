//
//  LogsView.swift
//  DNSGuard
//
//  Created for iOS Local DNS Optimizer.
//  Persistent DNS Query & Packet Repair Inspector with local storage integration,
//  domain search, high-density realtime streaming, and comprehensive 4-tier repair badges.
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
        case repaired = "Tự sửa lỗi"
        case cached = "RAM Cache"
        case racing = "Đua tốc độ"
    }
    
    var filteredLogs: [DNSQueryLog] {
        var logs = storage.queryLogs
        
        switch selectedFilter {
        case .all:
            break
        case .repaired:
            logs = logs.filter { $0.isRepaired }
        case .cached:
            logs = logs.filter { $0.isCached }
        case .racing:
            logs = logs.filter { $0.strategy == "Racing Turbo" }
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
                
                // Filter Segmented Control
                Picker("Bộ lọc", selection: $selectedFilter) {
                    ForEach(LogFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                Divider()
                
                if filteredLogs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: selectedFilter == .repaired ? "wrench.and.screwdriver.fill" : "tray.fill")
                            .font(.system(size: 48))
                            .foregroundColor(selectedFilter == .repaired ? .green.opacity(0.7) : .secondary.opacity(0.6))
                        
                        Text(selectedFilter == .all ? "Chưa có nhật ký truy vấn nào" : "Không có nhật ký nào trong mục '\(selectedFilter.rawValue)'")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Nhấn nút bên dưới để tạo ngay các truy vấn DNS và kiểm tra cơ chế tự sửa gói tin.")
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
                if log.isCached {
                    Label("RAM L1 Cache Hit", systemImage: "memorychip.fill")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                } else {
                    Label(log.serverUsed, systemImage: "server.rack")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let strat = log.strategy, strat != "L1 Ultra Fast" {
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
