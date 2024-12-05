//
//  DetailsViewController.swift
//  Project-10
//
//  Created by Serhii Prysiazhnyi on 08.11.2024.
//

import UIKit

protocol DetailViewControllerDelegate: AnyObject {
    func didDeletePerson(at indexPath: IndexPath)
    func savePeopleToKeychain()
}

class DetailViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    
    var people = [Person]()
    var selectPath: URL?
    var indexPath: IndexPath?
    weak var delegate: DetailViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(reName))
        updateTitle()
    }
    
    func updateTitle() {
        
        guard let indexPath = indexPath else { return }
        let person = people[indexPath.item]
        
        title = "\(person.name)"
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
        
        // Создаем UIAlertController для выбора действия (редактировать или удалить)
        let actionSheet = UIAlertController(title: "Choose an action", message: nil, preferredStyle: .actionSheet)
        
        // Добавляем кнопку для редактирования
        actionSheet.addAction(UIAlertAction(title: "Edit", style: .default) { [weak self] _ in
            // Если выбрано редактирование, показываем диалог для ввода нового имени
            let ac = UIAlertController(title: "Rename person", message: nil, preferredStyle: .alert)
            ac.addTextField { textField in
                textField.text = person.name // Примерно инициализируем текстом текущего имени
            }
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak self, weak ac] _ in
                guard let newName = ac?.textFields?[0].text, !newName.isEmpty else { return }
                person.name = newName
                self?.people[indexPath.item] = person
                self?.updateTitle() // Обновляем заголовок или другой интерфейс
                self?.delegate?.savePeopleToKeychain()
                print("This new name \(newName)")
            })
            self?.present(ac, animated: true)
        })
        
        // Добавляем кнопку для удаления
        actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            // Если выбрано удаление, удаляем запись из массива
            if let indexPath = self?.indexPath {
                self?.delegate?.didDeletePerson(at: indexPath)
                self?.navigationController?.popViewController(animated: true)
            }
            print("Person deleted")
            // Возвращаемся на предыдущий экран
            self?.navigationController?.popViewController(animated: true)
        })
        
        // Добавляем кнопку для отмены
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Показываем Action Sheet
        present(actionSheet, animated: true)
    }
}
