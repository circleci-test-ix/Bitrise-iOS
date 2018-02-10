//
//  ViewController.swift
//  BitriseClient
//
//  Created by Toshihiro Suzuki on 2017/12/19.
//  Copyright © 2017 toshi0383. All rights reserved.
//

import Continuum
import UIKit

// TODO: doc
final class ChildHitTestStackView: UIStackView {

    var targetChildToHitTest: UIView?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let view = targetChildToHitTest {
            if let hit = view.hitTest(convert(point, to: view), with: event) {
                return hit
            }
        }

        for view in subviews {
            if let hit = view.hitTest(convert(point, to: view), with: event) {
                return hit
            }
        }

        // IMPORTANT: Perform hitTest for myself at last.
        if let hit = super.hitTest(point, with: event) {
            return hit
        }

        return nil
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let workflowIDs: [WorkflowID] = Config.workflowIDs

    @IBOutlet private weak var rootStackView: ChildHitTestStackView!

    @IBOutlet private weak var gitObjectInputView: GitObjectInputView! {
        didSet {
            gitObjectInputView.layer.zPosition = 1.0
        }
    }

    @IBOutlet private weak var apiTokenTextfield: UITextField!
    @IBOutlet private weak var tableView: UITableView!

    private let store = LogicStore()
    private let bag = ContinuumBag()

    // MARK: LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Tell rootStackView the hitTest target.
        rootStackView.isUserInteractionEnabled = true
        rootStackView.targetChildToHitTest = gitObjectInputView

        tableView.reloadData()

        apiTokenTextfield.text = store.apiToken

        let keypath: ReferenceWritableKeyPath<LogicStore, GitObject> = \.gitObject
        notificationCenter.continuum
            .observe(gitObjectInputView.newInput, bindTo: store, keypath)
            .disposed(by: bag)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        gitObjectInputView.resignFirstResponder()
    }

    // MARK: IBAction

    @IBAction private func triggerButton() {

        gitObjectInputView.resignFirstResponder()
        apiTokenTextfield.resignFirstResponder()

        if let text = apiTokenTextfield.text, !text.isEmpty {
            store.apiToken = text
        }

        guard let req = store.urlRequest() else {
            alert("ERROR: リクエストを生成できませんでした.")
            return
        }

        let task = URLSession.shared.dataTask(with: req) { [weak self] (data, res, err) in

            guard let me = self else { return }
            if let res = res as? HTTPURLResponse {
                print(res.statusCode)
                print(res.allHeaderFields)
            }

            if let err = err {
                me.alert(err.localizedDescription)
                return
            }

            guard (res as? HTTPURLResponse)?.statusCode == 201 else {
                me.alert("失敗")
                return
            }

            let str: String = {
                if let data = data {
                    return String(data: data, encoding: .utf8) ?? ""
                } else {
                    return ""
                }
            }()

            me.alert("成功\n\(str)")
        }

        task.resume()
    }

    // MARK: UITableViewDataSource & UITableViewDelegate

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workflowIDs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = workflowIDs[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        store.workflowID = workflowIDs[indexPath.row]
    }

    // MARK: Utilities

    private func alert(_ message: String) {
        DispatchQueue.main.async {
            let vc = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            vc.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(vc, animated: true, completion: nil)
        }
    }
}