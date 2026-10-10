//
//  LogsView.swift
//  DNSGuard
//
//  Created for iOS Local DNS VPN & Optimizer.
//  Real-time DNS Query & Packet Repair Inspector.
//

import SwiftUI

struct LogsView: View {
    @State private var selectedFilter: LogFilter = .all
    @State private var sampleLogs: [DNSQueryLog] = [
        DNSQueryLog(domain: "gateway.icloud.com", recordType: "HTTPS", serverUsed: "Cache", latencyMs: 0.3, isCached: true),
        DNSQueryLog(domain: "api.apple-cloudkit.com", recordType: "A", serverUsed: "Cloudflare (1.1.1.1)", latencyMs: 12.4, isRepaired: true, repairReason: "IPv4 Checksum Auto-Repaired"),
        DNSQueryLog(domain: "dns.quad9.net", recordType: "AAAA", serverUsed: "Quad9 (9.9.9.9)", latencyMs: 22.1),
        DNSQueryLog(domain: "cdn.jsdelivr.net", recordType: "A", serverUsed: "Google (8.8.8.8)", latencyMs: 17.5),
        DNSQueryLog(domain: "large-txt-record.org", recordType: "TXT", serverUsed: "Cloudflare (1.1.1.1)", latencyMs: 34.0, isRepaired: true, repairReason: "TC Truncation Healed (Fetched via DoH)"),
        DNSQueryLog(domain: "safebrowsing.googleapis.com", recordType: "A", serverUsed: "Cache", latencyMs: 0.2, isCached: true),
        DNSQueryLog(domain: "vnexpress.net", recordType: "A", serverUsed: "Cloudflare (1.1.1.1)", latencyMs: 14.2),
        DNSQueryLog(domain: "corrupt-checksum.test.com", recordType: "A", serverUsed: "AdGuard", latencyMs: 29.8, isRepaired: true, repairReason: "UDP Checksum Recalculated & Fixed")
    ]
    
    enum LogFilter: String, CaseIterable {
        case all = "Tất cả"
        case repaired = "Tự sửa lỗi"
        case cached = "Cache Hits"
    }
    
    var filteredLogs: [DNSQueryLog] {
        switch selectedFilter {
        case .all: return sampleLogs
        case .repaired: return sampleLogs.filter { $0.isRepaired }
        case .cached: return sampleLogs.filter { $0.isCached }
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
                                    Label("Cache Hit", systemImage: "bolt.fill")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                } else {
                                    Label(log.serverUsed, systemImage: "server.rack")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(String(format: "%.1f ms", log.latencyMs))
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(log.latencyMs < 5 ? .green : .secondary)
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
            .navigationTitle("Nhật ký truy vấn")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { sampleLogs.removeAll() }) {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
}
