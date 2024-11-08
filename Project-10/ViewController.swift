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
        
        let imageName = UUID().uuidString
        let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
        
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: imagePath)
        }
        
        let person = Person(name: "Unknown", image: imageName)
        people.append(person)
        collectionView.reloadData()
        
        dismiss(animated: true)
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
    }
}

extension ViewController: DetailViewControllerDelegate {
    func didDeletePerson(at indexPath: IndexPath) {
        deletePerson(at: indexPath)
    }
}
