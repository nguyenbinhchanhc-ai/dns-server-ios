//
//  ServerManagementView.swift
//  DNSGuard
//
//  Created for iOS Local DNS Optimizer.
//  Server Pool Manager with continuous real-time latency monitoring,
//  stability ranking, and custom server addition.
//

import SwiftUI

struct ServerManagementView: View {
    @ObservedObject var prober = ContinuousDNSProber.shared
    @ObservedObject var profileServer = ProfileServer.shared
    
    @State private var showingAddSheet = false
    @State private var newName = ""
    @State private var newIP = ""
    @State private var newDoH = ""
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Tình trạng đo liên tục (Live Monitor)")) {
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(prober.isProbingActive ? Color.green : Color.gray)
                                .frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(prober.isProbingActive ? "Đang liên tục kiểm tra (Mỗi 3.5s)" : "Đang tạm dừng")
                                    .fontWeight(.semibold)
                                Text("Tổng số lần kiểm tra: \(prober.totalProbesCompleted)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            prober.isProbingActive.toggle()
                            if prober.isProbingActive {
                                prober.startContinuousProbing()
                            } else {
                                prober.stopContinuousProbing()
                            }
                        }) {
                            Text(prober.isProbingActive ? "Tạm dừng" : "Bật lại")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(prober.isProbingActive ? .orange : .blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(
                    header: Text("Bảng xếp hạng máy chủ DNS thời gian thực"),
                    footer: Text("Hệ thống tự động phân tích RTT và tỷ lệ ổn định để đưa máy chủ tốt nhất lên vị trí ưu tiên.")
                ) {
                    ForEach(prober.benchmarks.sorted(by: { $0.latencyMs < $1.latencyMs })) { server in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(latencyColor(server.latencyMs))
                                .frame(width: 10, height: 10)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(server.name)
                                        .fontWeight(.semibold)
                                    if server.isFastest {
                                        Text("FASTEST")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.15))
                                            .foregroundColor(.green)
                                            .cornerRadius(4)
                                    }
                                }
                                Text("\(server.ip) • Ổn định \(server.stabilityScore)%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "%.1f ms", server.latencyMs))
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(latencyColor(server.latencyMs))
                                
                                Text(server.status)
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Tải Profile Riêng Theo Từng Máy Chủ")) {
                    Button(action: {
                        profileServer.openProfileInSafari()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Cài Profile tổ hợp tối ưu (Cloudflare + Google DoH)")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Máy chủ DNS")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                addServerSheet
            }
        }
    }
    
    private var addServerSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Thông tin máy chủ mới")) {
                    TextField("Tên máy chủ (vd: OpenDNS, NextDNS)", text: $newName)
                    TextField("Địa chỉ IPv4", text: $newIP)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("URL DoH (Tùy chọn)", text: $newDoH)
                        .keyboardType(.URL)
                }
            }
            .navigationTitle("Thêm máy chủ DNS")
            .navigationBarItems(
                leading: Button("Hủy") { showingAddSheet = false },
                trailing: Button("Thêm") {
                    guard !newName.isEmpty, !newIP.isEmpty else { return }
                    let newBenchmark = LiveServerBenchmark(
                        name: newName,
                        ip: newIP,
                        dohURL: newDoH.isEmpty ? "https://dns.google/dns-query" : newDoH,
                        latencyMs: 30.0
                    )
                    prober.benchmarks.append(newBenchmark)
                    newName = ""
                    newIP = ""
                    newDoH = ""
                    showingAddSheet = false
                }
                .disabled(newName.isEmpty || newIP.isEmpty)
            )
        }
    }
    
    private func latencyColor(_ ms: Double) -> Color {
        if ms < 18 { return .green }
        if ms < 35 { return .orange }
        return .red
    }
}
