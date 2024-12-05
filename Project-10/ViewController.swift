//
//  ViewController.swift
//  Project-10
//
//  Created by Serhii Prysiazhnyi on 08.11.2024.
//

import UIKit

class ViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var people = [Person]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target:self, action: #selector(addNewPerson))
        loadPeopleFromKeychain()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return people.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Person", for: indexPath) as? PersonCell else {
            fatalError("Unable to dequeue PersonCell.")
        }
        
        let person = people[indexPath.item]
        
        cell.name.text = person.name
        
        let path = getDocumentsDirectory().appendingPathComponent(person.image)
        cell.imageView.image = UIImage(contentsOfFile: path.path)
        
        cell.imageView.layer.borderColor = UIColor(white: 0, alpha: 0.3).cgColor
        cell.imageView.layer.borderWidth = 2
        cell.imageView.layer.cornerRadius = 3
        cell.layer.cornerRadius = 7
        
        return cell
    }
    
    @objc func addNewPerson() {
        let picker = UIImagePickerController()
        
        // Проверяем, доступна ли камера на устройстве
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            // Показываем выбор между камерой и галереей
            let alertController = UIAlertController(title: "Выберите источник", message: nil, preferredStyle: .actionSheet)
            
            // Камера
            alertController.addAction(UIAlertAction(title: "Камера", style: .default, handler: { _ in
                self.presentImagePicker(with: .camera)
            }))
            
            // Фотогалерея
            alertController.addAction(UIAlertAction(title: "Фотогалерея", style: .default, handler: { _ in
                self.presentImagePicker(with: .photoLibrary)
            }))
            
            // Отмена
            alertController.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            
            // Отображаем диалоговое окно
            present(alertController, animated: true)
        } else {
            picker.sourceType = .photoLibrary // Если камера недоступна, используем фотогалерею
        }
        
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func presentImagePicker(with sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        
        // Генерация уникального имени для фото
        let imageName = UUID().uuidString
        let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
        
        // Сохранение изображения в файловую систему
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: imagePath)
        }
        
        // Создание нового объекта Person
        let person = Person(name: "Unknown", image: imageName)
        people.append(person)
        collectionView.reloadData()
        
        // Закрытие пикера
        dismiss(animated: true)
        
        // Открываем диалог для переименования
        newName(for: person)
        
        savePeopleToKeychain()  // сохраняем
    }
    
    func newName(for person: Person) {
        let ac = UIAlertController(title: "Enter name person", message: nil, preferredStyle: .alert)
        ac.addTextField { textField in
            textField.text = person.name // Изначально показываем "Unknown"
        }
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let newName = ac.textFields?[0].text, !newName.isEmpty else { return }
            
            // Обновляем имя пользователя
            person.name = newName
            self?.collectionView.reloadData() // Перезагружаем коллекцию для отображения нового имени
            self?.savePeopleToKeychain()
        })
        
        present(ac, animated: true)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let person = people[indexPath.item]
        
        if let vc = storyboard?.instantiateViewController(withIdentifier: "Detail") as? DetailViewController {
            
            vc.selectPath = getDocumentsDirectory().appendingPathComponent(person.image)
            vc.people = people  // Передаем массив people
            vc.indexPath = indexPath  // Передаем выбранный indexPath
            vc.delegate = self  // Устанавливаем делегата для обновлений
            print(person.name)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc func deletePerson(at indexPath: IndexPath) {
        // Удаляем элемент из массива
        people.remove(at: indexPath.item)
        collectionView.deleteItems(at: [indexPath])
        savePeopleToKeychain()
    }
    
    func loadPeopleFromKeychain() {
        if let data = KeychainWrapper.standard.data(forKey: "SecretMessage") {
            do {
                let decoder = JSONDecoder()
                people = try decoder.decode([Person].self, from: data) // Восстанавливаем массив людей
                collectionView.reloadData()
                print("load \(data)")
            } catch {
                print("Failed to decode people: \(error)")
            }
        }
    }
    
    func savePeopleToKeychain() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(people) // Преобразуем массив людей в Data
            KeychainWrapper.standard.set(data, forKey: "SecretMessage") // Сохраняем в Keychain
            //title = "Nothing to see here"
            print("save \(data)")
        } catch {
            print("Failed to encode people: \(error)")
        }
    }
}

extension ViewController: DetailViewControllerDelegate {
    func didDeletePerson(at indexPath: IndexPath) {
        deletePerson(at: indexPath)
        savePeopleToKeychain()
    }
}
