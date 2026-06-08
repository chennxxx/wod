import SwiftData
import SwiftUI

struct SkillDetailView: View {
    let skill: SkillDefinition

    @Query private var allStatuses: [SkillStatus]
    @Query private var allEntries: [SkillTrainingEntry]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddSheet = false

    private var statusMap: [String: SkillStatus] {
        Dictionary(uniqueKeysWithValues: allStatuses.map { ($0.skillId, $0) })
    }

    private var statusEntry: SkillStatus? {
        statusMap[skill.id]
    }

    private var masteryStatus: SkillMasteryStatus {
        statusEntry?.status ?? .unmarked
    }

    private var entries: [SkillTrainingEntry] {
        allEntries.filter { $0.skillId == skill.id }
            .sorted { $0.date > $1.date }
    }

    private var bestEntry: SkillTrainingEntry? {
        entries.max { $0.value < $1.value }
    }

    private func setStatus(_ newStatus: SkillMasteryStatus) {
        if let entry = statusEntry {
            entry.status = newStatus
        } else {
            let entry = SkillStatus(skillId: skill.id, status: newStatus)
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }

    var body: some View {
        ZStack {
            Color.wtBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: WTSpacing.lg) {
                    videoPlaceholder
                    titleSection
                    if !skill.prerequisites.isEmpty {
                        prerequisitesSection
                    }
                    statusSection
                    myDataSection
                    if !entries.isEmpty {
                        trainingHistorySection
                    }
                    coachingPoints
                }
                .padding(.horizontal, WTSpacing.lg)
                .padding(.bottom, WTSpacing.xl)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(skill.englishName.uppercased())
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.wtTextSecondary)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddTrainingEntrySheet(skillId: skill.id)
        }
    }

    // MARK: - Sections

    private var videoPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: WTRadius.lg)
                .fill(Color.wtSurface)
                .frame(height: 200)

            VStack(spacing: WTSpacing.sm) {
                ZStack {
                    Circle()
                        .strokeBorder(Color.wtPrimary, lineWidth: 2)
                        .frame(width: 52, height: 52)
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.wtPrimary)
                        .offset(x: 2)
                }
                Text("即将上线 · Coming Soon")
                    .font(WTFont.micro)
                    .foregroundStyle(Color.wtTextSecondary)
            }
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            Text(skill.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.wtTextPrimary)
            Text(skill.englishName)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.wtTextSecondary)

            HStack(spacing: WTSpacing.xs) {
                TierBadge(tier: skill.tier)
                Text(skill.tier.description)
                    .font(WTFont.micro)
                    .foregroundStyle(Color.wtTextSecondary)
            }
        }
    }

    private var prerequisitesSection: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            HStack(spacing: WTSpacing.xs) {
                Text("前置动作")
                    .font(WTFont.micro)
                    .foregroundStyle(Color.wtTextSecondary)
                if let unlock = skill.unlockCondition {
                    Text("·")
                        .font(WTFont.micro)
                        .foregroundStyle(Color.wtTextDisabled)
                    Text(unlock)
                        .font(WTFont.micro)
                        .foregroundStyle(Color.wtTextDisabled)
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(prereqSkills.enumerated()), id: \.element.id) { index, prereq in
                    let prereqStatus = statusMap[prereq.id]?.status ?? .unmarked
                    NavigationLink(destination: SkillDetailView(skill: prereq)) {
                        PrereqRow(skill: prereq, status: prereqStatus)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if index < prereqSkills.count - 1 {
                        Divider().background(Color.wtSurface2).padding(.leading, WTSpacing.md)
                    }
                }
            }
            .background(Color.wtSurface)
            .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
        }
    }

    private var prereqSkills: [SkillDefinition] {
        skill.prerequisites.compactMap { SkillLibrary.skillById[$0] }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            Text("我的状态 · 点击切换")
                .font(WTFont.micro)
                .foregroundStyle(Color.wtTextSecondary)

            HStack(spacing: WTSpacing.sm) {
                StatusButton(title: "✓ 已掌握", isSelected: masteryStatus == .mastered, selectedColor: Color.wtPrimary) {
                    setStatus(.mastered)
                }
                StatusButton(title: "◐ 进行中", isSelected: masteryStatus == .inProgress, selectedColor: Color(hex: "#5E81F4")) {
                    setStatus(.inProgress)
                }
                StatusButton(title: "○ 想学", isSelected: masteryStatus == .wantToLearn, selectedColor: Color.wtTextSecondary) {
                    setStatus(.wantToLearn)
                }
            }
        }
    }

    private var myDataSection: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            HStack {
                Text("我的数据")
                    .font(WTFont.micro)
                    .foregroundStyle(Color.wtTextSecondary)
                Spacer()
                Button("记录一次") { showAddSheet = true }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.wtPrimary)
            }

            HStack(spacing: WTSpacing.sm) {
                DataCell(label: "个人纪录", value: bestEntry?.formattedValue ?? "—")
                DataCell(label: "上次练", value: lastPracticedText)
            }
        }
    }

    private var trainingHistorySection: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            Text("训练记录")
                .font(WTFont.micro)
                .foregroundStyle(Color.wtTextSecondary)

            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.persistentModelID) { index, entry in
                    TrainingEntryRow(entry: entry, onDelete: { deleteEntry(entry) })
                    if index < entries.count - 1 {
                        Divider().background(Color.wtSurface2).padding(.leading, WTSpacing.md)
                    }
                }
            }
            .background(Color.wtSurface)
            .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
        }
    }

    private var coachingPoints: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            Text("动作要领")
                .font(WTFont.micro)
                .foregroundStyle(Color.wtTextSecondary)

            VStack(alignment: .leading, spacing: WTSpacing.md) {
                CoachingPoint(index: 1, text: "标准动作说明待补充——可在此填写动作要领、常见错误与进阶提示。")
            }
            .padding(WTSpacing.md)
            .background(Color.wtSurface)
            .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
        }
    }

    // MARK: - Helpers

    private var lastPracticedText: String {
        guard let date = entries.first?.date else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }

    private func deleteEntry(_ entry: SkillTrainingEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }
}

// MARK: - Training Entry Row

private struct TrainingEntryRow: View {
    let entry: SkillTrainingEntry
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Text(formattedDate)
                .font(WTFont.caption)
                .foregroundStyle(Color.wtTextSecondary)
                .frame(width: 52, alignment: .leading)

            Text(entry.formattedValue)
                .font(WTFont.bodyBold)
                .foregroundStyle(Color.wtTextPrimary)

            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.wtTextDisabled)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, WTSpacing.md)
        .padding(.vertical, 10)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: entry.date)
    }
}

// MARK: - Sub-views

private struct StatusButton: View {
    let title: String
    let isSelected: Bool
    let selectedColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? (selectedColor == Color.wtTextSecondary ? Color.wtTextPrimary : Color.black) : Color.wtTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(isSelected ? selectedColor : Color.wtSurface)
                .clipShape(RoundedRectangle(cornerRadius: WTRadius.sm))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct DataCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: WTSpacing.xs) {
            Text(value)
                .font(WTFont.bodyBold)
                .foregroundStyle(Color.wtTextPrimary)
            Text(label)
                .font(WTFont.micro)
                .foregroundStyle(Color.wtTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, WTSpacing.md)
        .background(Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
    }
}

private struct CoachingPoint: View {
    let index: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: WTSpacing.sm) {
            Text(String(format: "%02d", index))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.wtPrimary)
            Text(text)
                .font(WTFont.caption)
                .foregroundStyle(Color.wtTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Prereq Row

private struct PrereqRow: View {
    let skill: SkillDefinition
    let status: SkillMasteryStatus

    private var statusIcon: (name: String, color: Color) {
        switch status {
        case .mastered:    ("checkmark.circle.fill", Color.wtPrimary)
        case .inProgress:  ("moon.fill",             Color(hex: "#5E81F4"))
        case .wantToLearn: ("circle",                Color.wtTextSecondary)
        case .unmarked:    ("circle",                Color.wtTextDisabled)
        }
    }

    var body: some View {
        HStack(spacing: WTSpacing.sm) {
            Image(systemName: statusIcon.name)
                .font(.system(size: 18))
                .foregroundStyle(statusIcon.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    TierBadge(tier: skill.tier)
                    Text(skill.name)
                        .font(WTFont.body)
                        .foregroundStyle(Color.wtTextPrimary)
                }
                Text(skill.englishName)
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.wtTextSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.wtTextDisabled)
        }
        .padding(.horizontal, WTSpacing.md)
        .padding(.vertical, 10)
    }
}

// MARK: - Add Training Entry Sheet

private struct AddTrainingEntrySheet: View {
    let skillId: String

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var valueText: String = ""
    @State private var unit: String = "kg"
    @State private var date: Date = Date()
    @State private var showCalendar: Bool = false
    @State private var notes: String = ""
    @FocusState private var valueFocused: Bool

    private let units = ["kg", "lb", "reps", "seconds"]

    private var canSave: Bool {
        !valueText.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(valueText.replacingOccurrences(of: ",", with: ".")) != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.wtBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: WTSpacing.lg) {
                        // 成绩输入
                        VStack(alignment: .leading, spacing: WTSpacing.sm) {
                            Label("成绩", systemImage: "trophy")
                                .font(WTFont.micro)
                                .foregroundStyle(Color.wtTextSecondary)

                            VStack(alignment: .leading, spacing: WTSpacing.sm) {
                                TextField("0", text: $valueText)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.wtTextPrimary)
                                    .focused($valueFocused)

                                // 单位选择 chips
                                HStack(spacing: 6) {
                                    ForEach(units, id: \.self) { u in
                                        Button(u) { unit = u }
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(unit == u ? Color.black : Color.wtTextSecondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(unit == u ? Color.wtPrimary : Color.wtSurface2)
                                            .clipShape(Capsule())
                                            .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(WTSpacing.md)
                            .background(Color.wtSurface)
                            .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
                        }

                        // 日期选择
                        VStack(alignment: .leading, spacing: WTSpacing.sm) {
                            Label("日期", systemImage: "calendar")
                                .font(WTFont.micro)
                                .foregroundStyle(Color.wtTextSecondary)

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showCalendar.toggle()
                                }
                            } label: {
                                HStack {
                                    Text(formattedDate)
                                        .font(WTFont.bodyBold)
                                        .foregroundStyle(Color.wtTextPrimary)
                                    Spacer()
                                    Image(systemName: showCalendar ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Color.wtTextSecondary)
                                }
                                .padding(WTSpacing.md)
                                .background(Color.wtSurface)
                                .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if showCalendar {
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .tint(Color.wtPrimary)
                                    .background(Color.wtSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
                                    .onChange(of: date) { _, _ in
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showCalendar = false
                                        }
                                    }
                            }
                        }

                        // 备注
                        VStack(alignment: .leading, spacing: WTSpacing.sm) {
                            Label("备注（可选）", systemImage: "text.bubble")
                                .font(WTFont.micro)
                                .foregroundStyle(Color.wtTextSecondary)

                            TextField("今天的感受、重量来源等", text: $notes, axis: .vertical)
                                .lineLimit(2...4)
                                .font(WTFont.body)
                                .foregroundStyle(Color.wtTextPrimary)
                                .padding(WTSpacing.md)
                                .background(Color.wtSurface)
                                .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
                        }

                        // 保存按钮
                        Button {
                            save()
                        } label: {
                            Text("保存记录")
                                .font(WTFont.bodyBold)
                                .foregroundStyle(canSave ? Color.black : Color.wtTextDisabled)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(canSave ? Color.wtPrimary : Color.wtSurface)
                                .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSave)
                    }
                    .padding(WTSpacing.lg)
                }
            }
            .navigationTitle("记录一次")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(Color.wtTextSecondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(showCalendar)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                valueFocused = true
            }
        }
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale(identifier: "zh_CN")
        return f.string(from: date)
    }

    private func save() {
        guard let value = Double(valueText.replacingOccurrences(of: ",", with: ".")) else { return }
        let entry = SkillTrainingEntry(skillId: skillId, date: date, value: value, unit: unit, notes: notes.isEmpty ? nil : notes)
        modelContext.insert(entry)
        try? modelContext.save()
        dismiss()
    }
}
