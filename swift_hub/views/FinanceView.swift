//
//  FinanceView.swift
//  Looker
//
//  Created by Daniel Muck on 11/9/25.
//

import SwiftUI
import SwiftData

struct FinanceView: View {
    var body: some View {
        FinanceTabsView()
            .tabItem {
                Label("Finance", systemImage: "dollarsign.circle.fill")
        }
    }
}

// MARK: - Finance Tabs
private struct FinanceTabsView: View {
    var body: some View {
        TabView {
            // Dashboard
            FinanceDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "rectangle.grid.2x2.fill")
                }

            // Daily
            FinanceDailyView()
                .tabItem {
                    Label("Daily", systemImage: "sun.max.fill")
                }

            // Weekly
            FinanceWeeklyView()
                .tabItem {
                    Label("Weekly", systemImage: "calendar")
                }

            // Monthly
            FinanceMonthlyView()
                .tabItem {
                    Label("Monthly", systemImage: "calendar.circle")
                }

            // Annual
            FinanceAnnualView()
                .tabItem {
                    Label("Annual", systemImage: "calendar.badge.clock")
                }
        }
    }
}

// MARK: - Placeholder Views
private struct FinanceDashboardView: View {
    var body: some View {
        Text("Finance Dashboard")
        
    }
}

private struct FinanceDailyView: View {
    var body: some View { Text("Daily Finance") }
}

private struct FinanceWeeklyView: View {
    @Environment(\.modelContext) private var modelContext

    // Current week boundaries (Sunday start to Saturday end)
    @State private var weekStart: Date = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
    
    private var sundayStart: Date {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: weekStart)
        // In Gregorian, 1 = Sunday. Shift back to Sunday.
        let daysFromSunday = (weekday + 6) % 7
        return cal.startOfDay(for: cal.date(byAdding: .day, value: -daysFromSunday, to: weekStart) ?? weekStart)
    }
    
    private var saturdayEnd: Date {
        let cal = Calendar.current
        let saturday = cal.date(byAdding: .day, value: 6, to: sundayStart) ?? sundayStart
        // End of day Saturday
        let comps = DateComponents(hour: 23, minute: 59, second: 59)
        return cal.date(bySettingHour: comps.hour!, minute: comps.minute!, second: comps.second!, of: saturday) ?? saturday
    }

    // Query all transactions for the week; filter in-memory by date range to be explicit
    @Query(sort: [SortDescriptor<Txn>(\.date, order: .forward)]) private var allTxns: [Txn]

    private var weekTxns: [Txn] {
        allTxns.filter { $0.date >= sundayStart && $0.date <= saturdayEnd }
    }

    private var groupedByDay: [(date: Date, txns: [Txn], total: Double)] {
        let cal = Calendar.current
        // Build all seven days Sunday..Saturday
        let days: [Date] = (0...6).compactMap { cal.date(byAdding: .day, value: $0, to: sundayStart) }
        return days.map { day in
            let start = cal.startOfDay(for: day)
            let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
            let txns = weekTxns.filter { $0.date >= start && $0.date < end }
            let total = txns.reduce(0.0) { partial, t in
                partial + (t.expense ? -t.amount : t.amount)
            }
            return (date: day, txns: txns, total: total)
        }
    }

    private var weekTotals: (income: Double, expenses: Double, net: Double) {
        let income = weekTxns.filter { !$0.expense }.reduce(0.0) { $0 + $1.amount }
        let expenses = weekTxns.filter { $0.expense }.reduce(0.0) { $0 + $1.amount }
        return (income, expenses, income - expenses)
    }

    private let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        return f
    }()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Week header with navigation
                weekHeader
                
                List {
                    ForEach(groupedByDay, id: \.date) { dayGroup in
                        Section(header: Text(sectionTitle(for: dayGroup.date))) {
                            if dayGroup.txns.isEmpty {
                                Text("No transactions")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(dayGroup.txns) { txn in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(txn.desc)
                                                .font(.body)
                                            Text(shortDateTime(txn.date))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(formattedCurrency(txn.expense ? -txn.amount : txn.amount))
                                            .fontWeight(.semibold)
                                            .foregroundStyle(txn.expense ? .red : .green)
                                    }
                                }
                            }
                            HStack {
                                Text("Day Total")
                                Spacer()
                                Text(formattedCurrency(dayGroup.total))
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                .listStyle(.automatic)

                // Week totals footer
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Income")
                        Spacer()
                        Text(formattedCurrency(weekTotals.income))
                            .foregroundStyle(.green)
                    }
                    HStack {
                        Text("Expenses")
                        Spacer()
                        Text(formattedCurrency(-weekTotals.expenses))
                            .foregroundStyle(.red)
                    }
                    Divider()
                    HStack {
                        Text("Net")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(formattedCurrency(weekTotals.net))
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(.thinMaterial)
            }
            .navigationTitle("Weekly")
            .toolbar { toolbarContent }
        }
    }

    private var weekHeader: some View {
        HStack {
            Button { shiftWeek(by: -1) } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(weekRangeTitle)
                .font(.headline)
            Spacer()
            Button { shiftWeek(by: 1) } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.clear)
    }

    private var weekRangeTitle: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return "\(df.string(from: sundayStart)) – \(df.string(from: saturdayEnd))"
    }

    private func shiftWeek(by offset: Int) {
        if let newStart = Calendar.current.date(byAdding: .day, value: offset * 7, to: sundayStart) {
            weekStart = newStart
        }
    }

    private func sectionTitle(for date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEEE MMM d"
        return df.string(from: date)
    }

    private func shortDateTime(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .short
        return df.string(from: date)
    }

    private func formattedCurrency(_ value: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            NavigationLink {
                AddTxnForm()
            } label: {
                Image(systemName: "plus.circle.fill")
            }
        }
    }
}

private struct FinanceMonthlyView: View {
    var body: some View { Text("Monthly Finance") }
}

private struct FinanceAnnualView: View {
    var body: some View { Text("Annual Finance") }
}

// MARK: - Add Transaction Form
private struct AddTxnForm: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var desc: String = ""
    @State private var amountString: String = ""
    @State private var date: Date = Date()
    @State private var interval: TxnInterval = .none
    @State private var expense: Bool = false

    var body: some View {
        Form {
            Section("Details") {
                TextField("Description", text: $desc)
                TextField("Amount", text: $amountString)
                Toggle("Expense", isOn: $expense)
                DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                Picker("Interval", selection: $interval) {
                    ForEach(TxnInterval.allCases, id: \.self) { interval in
                        Text(interval.rawValue.capitalized).tag(interval)
                    }
                }
            }
            Section {
                Button("Save") { save() }
                    .disabled(!canSave)
            }
        }
        .navigationTitle("Add Transaction")
    }

    private var canSave: Bool {
        guard !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return Double(amountString.replacingOccurrences(of: ",", with: ".")) != nil
    }

    private func save() {
        let normalized = amountString.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(normalized) else { return }
        let txn = Txn(id: UUID(), amount: amount, date: date, desc: desc, expense: expense)
        modelContext.insert(txn)
        do {
            try modelContext.save()
        } catch {
            // Handle error as needed; for now we ignore and dismiss
        }
        dismiss()
    }
}

