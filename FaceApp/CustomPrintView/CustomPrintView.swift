//
//  CustomPrintView.swift
//  FaceApp
//
//  Created by tBug on 27.10.24..
//

import UIKit

protocol CustomPrintViewAbstract: AnyObject {
    func log(_ message: String)
    func clearLog()
}

class CustomPrintView: ViewWithNib, CustomPrintViewAbstract {
     private var scrollView: UIScrollView!
     private var stackView: UIStackView!
     private let maxAllowedLabels = 25

     override init(frame: CGRect) {
         super.init(frame: frame)
         setupConsoleView()
     }

     required init?(coder: NSCoder) {
         super.init(coder: coder)
         setupConsoleView()
     }

     // MARK: -  Setup the console view with a scroll view and stack view
     private func setupConsoleView() {
         scrollView = UIScrollView()
         scrollView.translatesAutoresizingMaskIntoConstraints = false
         addSubview(scrollView)

         stackView = UIStackView()
         stackView.axis = .vertical
         stackView.alignment = .fill
         stackView.distribution = .equalSpacing
         stackView.spacing = 4
         stackView.translatesAutoresizingMaskIntoConstraints = false

         // Add stack view to scroll view
         scrollView.addSubview(stackView)

         NSLayoutConstraint.activate([
             scrollView.topAnchor.constraint(equalTo: topAnchor),
             scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
             scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
             scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
             
             stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
             stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
             stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
             stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
             stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
         ])

         backgroundColor = .black
         layer.cornerRadius = 8
         clipsToBounds = true
     }

     //MARK: - Log a message to the console
     func log(_ message: String) {
         if stackView.arrangedSubviews.count >= maxAllowedLabels {
             // Clear all labels from the stack view
             clearLog()
         }
         
         let logLabel = UILabel()
         logLabel.text = message
         logLabel.textColor = .white
         logLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
         logLabel.numberOfLines = 0

         stackView.addArrangedSubview(logLabel)
         scrollToBottom()
     }

     // MARK: -  Remove all log messages from the stack view
    func clearLog() {
         for view in stackView.arrangedSubviews {
             stackView.removeArrangedSubview(view)
             view.removeFromSuperview()
         }
     }

     // MARK: - Scroll to the bottom of the scroll view
     private func scrollToBottom() {
         DispatchQueue.main.async {
             let bottomOffset = CGPoint(x: 0, y: self.scrollView.contentSize.height - self.scrollView.bounds.size.height)
             self.scrollView.setContentOffset(bottomOffset, animated: true)
         }
     }
}
