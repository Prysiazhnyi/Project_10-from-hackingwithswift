//
//  DetailsViewController.swift
//  Project-10
//
//  Created by Serhii Prysiazhnyi on 08.11.2024.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    
    var people = [Person]()
    var selectPath: URL?
    var indexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(reName))
        updateTitle()
    }
    
    func updateTitle() {
        
        guard let indexPath = indexPath else { return }
        let person = people[indexPath.item]
        
        title = "This is \(person.name)"
        navigationItem.largeTitleDisplayMode = .never
        if let path = selectPath {
            imageView.image = UIImage(contentsOfFile: path.path)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.hidesBarsOnTap = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.hidesBarsOnTap = false
    }
    
    @objc func reName() {
        
        guard let indexPath = indexPath, indexPath.item < people.count else { return }
        let person = people[indexPath.item]
        let ac = UIAlertController(title: "Rename person", message: nil, preferredStyle: .alert)
        ac.addTextField()
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak self, weak ac] _ in
            guard let newName = ac?.textFields?[0].text else { return }
            if !newName.isEmpty {
                person.name = newName
                self?.people[indexPath.item] = person
                self?.updateTitle()
                print("This new name \(newName)")
            }
        })
        present(ac, animated: true)
    }
}
