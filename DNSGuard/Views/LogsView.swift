//
//  LogsView.swift
//  DNSGuard
//
//  Created for iOS Local DNS Optimizer.
//  Persistent DNS Query & Packet Repair Inspector with local storage integration.
//

import SwiftUI

struct LogsView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedFilter: LogFilter = .all
    
    enum LogFilter: String, CaseIterable {
        case all = "Tất cả"
        case repaired = "Tự sửa lỗi"
        case cached = "RAM Cache"
    }
    
    var filteredLogs: [DNSQueryLog] {
        switch selectedFilter {
        case .all: return storage.queryLogs
        case .repaired: return storage.queryLogs.filter { $0.isRepaired }
        case .cached: return storage.queryLogs.filter { $0.isCached }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Bộ lọc", selection: $selectedFilter) {
                    ForEach(LogFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if filteredLogs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("Chưa có nhật ký truy vấn nào")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredLogs) { log in
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
                                        Label("RAM Cache Hit", systemImage: "memorychip.fill")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    } else {
                                        Label(log.serverUsed, systemImage: "server.rack")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(String(format: "%.2f ms", log.latencyMs))
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(log.latencyMs < 1 ? .green : .secondary)
                                }
                                
                                if let reason = log.repairReason {
                                    HStack(spacing: 4) {
                                        Image(systemName: "wrench.fill")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                        Text(reason)
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(.green)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(4)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Nhật ký truy vấn")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        storage.queryLogs.removeAll()
                        storage.saveToDisk()
                    }) {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
}
