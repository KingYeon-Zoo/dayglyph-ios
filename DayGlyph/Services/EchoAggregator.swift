import Foundation

nonisolated enum EchoAggregator {
    static func dueActions(
        from actions: [ActionInstance],
        responses: [ActionResponse],
        at date: Date = .now
    ) -> [ActionInstance] {
        let answered = Set(responses.map(\.actionInstanceId))
        return actions
            .filter {
                $0.state == .completed
                    && $0.followUpAt.map { $0 <= date } == true
                    && !answered.contains($0.id)
            }
            .sorted { ($0.followUpAt ?? $0.createdAt) < ($1.followUpAt ?? $1.createdAt) }
    }

    static func pendingActions(
        from actions: [ActionInstance],
        responses: [ActionResponse],
        at date: Date = .now
    ) -> [ActionInstance] {
        let answered = Set(responses.map(\.actionInstanceId))
        return actions
            .filter {
                $0.state == .completed
                    && $0.followUpAt.map { $0 > date } == true
                    && !answered.contains($0.id)
            }
            .sorted { ($0.followUpAt ?? .distantFuture) < ($1.followUpAt ?? .distantFuture) }
    }

    static func insights(
        from actions: [ActionInstance],
        responses: [ActionResponse]
    ) -> [EchoInsight] {
        let actionByID = Dictionary(uniqueKeysWithValues: actions.map { ($0.id, $0) })
        let grouped = Dictionary(grouping: responses.compactMap { response -> (MicroActionCategory, ActionResponse)? in
            guard let category = actionByID[response.actionInstanceId]?.category,
                  response.kind != nil else { return nil }
            return (category, response)
        }, by: { $0.0 })

        return grouped.compactMap { category, values in
            guard values.count >= 3 else { return nil }
            let dates = values.map { $0.1.createdAt }.sorted()
            let distribution = Dictionary(grouping: values.compactMap { $0.1.kind }, by: { $0 })
                .mapValues(\.count)
            return EchoInsight(
                category: category,
                sampleCount: values.count,
                startedAt: dates.first ?? .now,
                endedAt: dates.last ?? .now,
                distribution: distribution,
                summary: "在过去 \(values.count) 次「\(category.title)」记录中，你留下了不同的行动感受。"
            )
        }
        .sorted { $0.sampleCount > $1.sampleCount }
    }
}
