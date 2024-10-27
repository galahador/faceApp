//
//  CustomPrintView.swift
//  FaceApp
//
//  Created by tBug on 27.10.24..
//

import UIKit

class CustomPrintView: ViewWithNib {
    
    // Scroll view to enable scrolling through logs
     private var scrollView: UIScrollView!
     
     // Stack view to hold log messages
     private var stackView: UIStackView!

     // Maximum allowed number of labels before clearing
     private let maxAllowedLabels = 25

     override init(frame: CGRect) {
         super.init(frame: frame)
         setupConsoleView()
     }

     required init?(coder: NSCoder) {
         super.init(coder: coder)
         setupConsoleView()
     }

     // Setup the console view with a scroll view and stack view
     private func setupConsoleView() {
         // Initialize the scroll view
         scrollView = UIScrollView()
         scrollView.translatesAutoresizingMaskIntoConstraints = false
         addSubview(scrollView)

         // Initialize the stack view
         stackView = UIStackView()
         stackView.axis = .vertical
         stackView.alignment = .fill
         stackView.distribution = .equalSpacing
         stackView.spacing = 4
         stackView.translatesAutoresizingMaskIntoConstraints = false

         // Add stack view to scroll view
         scrollView.addSubview(stackView)

         // Set constraints for scroll view and stack view
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

         // Style the console view
         backgroundColor = .black
         layer.cornerRadius = 8
         clipsToBounds = true
     }

     // Log a message to the console
     func log(_ message: String) {
         // Check if the number of labels exceeds the max limit
         if stackView.arrangedSubviews.count >= maxAllowedLabels {
             // Clear all labels from the stack view
             clearLog()
         }
         
         // Create a new label for the log message
         let logLabel = UILabel()
         logLabel.text = message
         logLabel.textColor = .white
         logLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
         logLabel.numberOfLines = 0

         // Add the new log label to the stack view
         stackView.addArrangedSubview(logLabel)

         // Scroll to the bottom to show the latest message
         scrollToBottom()
     }

     // Remove all log messages from the stack view
    func clearLog() {
         for view in stackView.arrangedSubviews {
             stackView.removeArrangedSubview(view)
             view.removeFromSuperview()
         }
     }

     // Scroll to the bottom of the scroll view
     private func scrollToBottom() {
         DispatchQueue.main.async {
             let bottomOffset = CGPoint(x: 0, y: self.scrollView.contentSize.height - self.scrollView.bounds.size.height)
             self.scrollView.setContentOffset(bottomOffset, animated: true)
         }
     }
}
