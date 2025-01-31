import os.signpost
import APIKit
import Foundation

public struct AppsBuildsRequest: BitriseAPIRequest {

    public typealias Response = JSON

    public let path: String

    private let limit: Int
    private let next: String?

    public let spid: Any? = {
        if #available(iOS 12.0, *) {
            return OSSignpostID(log: .network)
        } else {
            return nil
        }
    }()

    public var queryParameters: [String : Any]? {
        var params: [String: Any] = ["limit": limit]

        if let next = next {
            params["next"] = next
        }

        return params
    }

    public init(appSlug: String, limit: Int = 50, next: String? = nil) {
        self.path = "/apps/\(appSlug)/builds"
        self.limit = limit
        self.next = next
    }
}

public struct AppsBuilds: Equatable {

    public let data: [Build]

    public struct Build: Hashable, Equatable {
        public static func compareContent(_ a: AppsBuilds.Build, _ b: AppsBuilds.Build) -> Bool {
            return a == b
        }

        public typealias Slug = String

        public let abort_reason: String?
        public let branch: String?
        public let build_number: Int
        public let commit_hash: String?
        public let commit_message: String?
        public let commit_view_url: String?
        public let environment_prepare_finished_at: Date?
        public let finished_at: Date?
        public let is_on_hold: Bool
        public let original_build_params: [String: Any]
        public let pull_request_id: Int?
        public let pull_request_target_branch: String?
        public let pull_request_view_url: String?
        public let slug: Slug
        public let stack_config_type: String?
        public let stack_identifier: String?
        public let started_on_worker_at: Date?
        public let status: Status
        public let status_text: String
        public let tag: String?
        public let triggered_at: Date
        public let triggered_by: String?
        public let triggered_workflow: String

        public init(
            abort_reason: String?,
            branch: String?,
            build_number: Int,
            commit_hash: String?,
            commit_message: String?,
            commit_view_url: String?,
            environment_prepare_finished_at: Date?,
            finished_at: Date?,
            is_on_hold: Bool,
            original_build_params: [String: Any],
            pull_request_id: Int?,
            pull_request_target_branch: String?,
            pull_request_view_url: String?,
            slug: Slug,
            stack_config_type: String?,
            stack_identifier: String?,
            started_on_worker_at: Date?,
            status: Status,
            status_text: String,
            tag: String?,
            triggered_at: Date,
            triggered_by: String?,
            triggered_workflow: String
            ) {
            self.abort_reason = abort_reason
            self.branch = branch
            self.build_number = build_number
            self.commit_hash = commit_hash
            self.commit_message = commit_message
            self.commit_view_url = commit_view_url
            self.environment_prepare_finished_at = environment_prepare_finished_at
            self.finished_at = finished_at
            self.is_on_hold = is_on_hold
            self.original_build_params = original_build_params
            self.pull_request_id = pull_request_id
            self.pull_request_target_branch = pull_request_target_branch
            self.pull_request_view_url = pull_request_view_url
            self.slug = slug
            self.stack_config_type = stack_config_type
            self.stack_identifier = stack_identifier
            self.started_on_worker_at = started_on_worker_at
            self.status = status
            self.status_text = status_text
            self.tag = tag
            self.triggered_at = triggered_at
            self.triggered_by = triggered_by
            self.triggered_workflow = triggered_workflow

        }
    }

    public let paging: Paging
}

extension AppsBuilds {
    public init(from json: JSON) {
        let dataJSONs = json["data"] as! [JSON]
        self.data = dataJSONs.map(Build.init)
        let pagingJSON = json["paging"] as! JSON
        self.paging = Paging(from: pagingJSON)
    }
}

extension AppsBuilds.Build {
    public static func ==(_ lhs: AppsBuilds.Build, _ rhs: AppsBuilds.Build) -> Bool {
        return lhs.slug == rhs.slug
    }

    public enum Status: Int, Decodable {
        case notFinished = 0
        case finished = 1
        case error = 2
        case aborted = 3
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(build_number)
        _ = hasher.finalize()
    }

    public init(from json: JSON) {
        func decodeDate(from string: String?) -> Date? {
            guard let string = string else { return nil }
            return dateFormatter.date(from: string)
        }

        self.abort_reason = json["abort_reason"] as? String
        self.branch = json["branch"] as? String
        self.commit_hash = json["commit_hash"] as? String
        self.commit_message = json["commit_message"] as? String
        self.commit_view_url = json["commit_view_url"] as? String
        self.environment_prepare_finished_at = decodeDate(from: json["environment_prepare_finished_at"] as? String)
        self.finished_at = decodeDate(from: json["finished_at"] as? String)
        self.pull_request_id = json["pull_request_id"] as? Int
        self.pull_request_target_branch = json["pull_request_target_branch"] as? String
        self.pull_request_view_url = json["pull_request_view_url"] as? String
        self.stack_config_type = json["stack_config_type"] as? String
        self.stack_identifier = json["stack_identifier"] as? String
        self.started_on_worker_at = decodeDate(from: json["started_on_worker_at"] as? String)
        self.tag = json["tag"] as? String
        self.triggered_by = json["triggered_by"] as? String
        self.build_number = json["build_number"] as! Int
        self.is_on_hold = json["is_on_hold"] as! Bool
        self.original_build_params = json["original_build_params"] as! JSON
        self.slug = json["slug"] as! Slug
        self.status = Status(rawValue: json["status"] as! Int)!
        self.status_text = json["status_text"] as! String
        self.triggered_at = decodeDate(from: json["triggered_at"] as? String)!
        self.triggered_workflow = json["triggered_workflow"] as! String
    }
}
