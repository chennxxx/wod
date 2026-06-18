import SwiftData
import SwiftUI

struct SkillDetailView: View {
    let skill: SkillDefinition

    @Query private var allStatuses: [SkillStatus]
    @Query private var allEntries: [SkillTrainingEntry]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddSheet = false

    private var statusMap: [String: SkillStatus] { allStatuses.indexedBySkillId }

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
                    statusSection
                    myDataSection
                    if !prereqSkills.isEmpty {
                        chainSection
                    }
                    if !entries.isEmpty {
                        trainingHistorySection
                    }
                    introSection
                    stepsSection
                    if let points = skill.keyPoints, !points.isEmpty {
                        keyPointsSection(points)
                    }
                    scalingSection
                }
                .padding(.horizontal, WTSpacing.lg)
                .padding(.bottom, WTSpacing.xl)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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

            ZStack {
                Circle()
                    .strokeBorder(Color.wtPrimary, lineWidth: 2)
                    .frame(width: 52, height: 52)
                Image(systemName: "play.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.wtPrimary)
                    .offset(x: 2)
            }

            VStack {
                Spacer()
                HStack {
                    Text("视频 · 即将上线")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.wtTextSecondary)
                    Spacer()
                }
            }
            .padding(WTSpacing.md)
        }
        .frame(height: 200)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: WTSpacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: WTSpacing.sm) {
                Text(skill.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.wtTextPrimary)
                TierBars(tier: skill.tier)
            }
        }
    }

    // MARK: 前置动作练习

    private var prereqSkills: [SkillDefinition] {
        skill.prerequisites.compactMap { SkillLibrary.skillById[$0] }
    }

    private var chainSection: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            SkillSubSectionHeader(title: "前置动作练习")

            VStack(spacing: 0) {
                ForEach(Array(prereqSkills.enumerated()), id: \.element.id) { index, prereq in
                    NavigationLink(destination: SkillDetailView(skill: prereq)) {
                        SkillStatusRow(skill: prereq, status: statusMap[prereq.id]?.status ?? .unmarked)
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

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            SkillSubSectionHeader(title: "我的状态")

            HStack(spacing: WTSpacing.sm) {
                StatusButton(title: "✓ 已掌握", isSelected: masteryStatus == .mastered, selectedColor: Color.wtPrimary) {
                    setStatus(.mastered)
                }
                StatusButton(title: "◐ 进行中", isSelected: masteryStatus == .inProgress, selectedColor: Color.wtInProgress) {
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
            SkillSubSectionHeader(title: "我的数据")

            HStack(spacing: WTSpacing.sm) {
                DataCell(label: "个人纪录", value: bestEntry?.formattedValue ?? "—")
                DataCell(label: "练习次数", value: entries.isEmpty ? "—" : "\(entries.count)")
                DataCell(label: "上次练", value: lastPracticedText)
            }

            Button { showAddSheet = true } label: {
                HStack(spacing: WTSpacing.xs) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                    Text("记录一次")
                        .font(WTFont.bodyBold)
                }
                .foregroundStyle(Color.wtPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .selectableChip(isOn: true)
            }
            .buttonStyle(.plain)
            .padding(.top, WTSpacing.xs)
        }
    }

    private var trainingHistorySection: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            SkillSubSectionHeader(title: "最近记录")

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

    private var introSection: some View {
        textSection(title: "动作简介", text: skill.intro)
    }

    private var stepsSection: some View {
        textSection(title: "动作步骤", text: skill.steps)
    }

    private func keyPointsSection(_ points: String) -> some View {
        textSection(title: "要点与注意", text: points)
    }

    private var scalingSection: some View {
        textSection(title: "降阶替代", text: skill.scaling)
    }

    private func textSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            SkillSubSectionHeader(title: title)
            Text(text)
                .font(WTFont.body)
                .foregroundStyle(Color.wtTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
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
                .foregroundStyle(isSelected ? selectedColor : Color.wtTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .selectableChip(isOn: isSelected, tint: selectedColor, cornerRadius: WTRadius.sm)
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
                .font(WTFont.mono(17, weight: .bold))
                .foregroundStyle(Color.wtTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
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
        .presentationDetents([.large])
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
