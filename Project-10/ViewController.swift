//
//  ViewController.swift
//  Project-10
//
//  Created by Serhii Prysiazhnyi on 08.11.2024.
//

import LocalAuthentication
import UIKit

class ViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var people = [Person]()
    
    let correctPassword = "1234" // Здесь укажите ваш пароль
    var attemptEnterPassword = 0
    var countWordPassword = 4
    
    var isUnlocked = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        authenticateClient()
        
        if isUnlocked == false {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(authenticateClient))
        } else {
            navigationItem.rightBarButtonItem = nil // Кнопка скрыта по умолчанию
        }
        
        navigationItem.leftBarButtonItem = nil
        clearKeychainIfFirstLaunch()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isUnlocked ? people.count : 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard isUnlocked else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BlockedCell", for: indexPath)
            cell.contentView.subviews.forEach { $0.removeFromSuperview() } // Видаляємо всі елементи
            let label = UILabel(frame: cell.bounds)
            label.text = "Дані заблоковані"
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            label.textColor = .gray
            cell.contentView.addSubview(label)
            return cell
        }
        
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
            let alertController = UIAlertController(title: "Виберіть джерело", message: nil, preferredStyle: .actionSheet)
            
            // Камера
            alertController.addAction(UIAlertAction(title: "Камера", style: .default, handler: { _ in
                self.presentImagePicker(with: .camera)
            }))
            
            // Фотогалерея
            alertController.addAction(UIAlertAction(title: "Фотогалерея", style: .default, handler: { _ in
                self.presentImagePicker(with: .photoLibrary)
            }))
            
            // Отмена
            alertController.addAction(UIAlertAction(title: "Скасування", style: .cancel))
            
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
        let ac = UIAlertController(title: "Введіть ім'я особи", message: nil, preferredStyle: .alert)
        ac.addTextField { textField in
            textField.text = person.name // Изначально показываем "Unknown"
        }
        
        ac.addAction(UIAlertAction(title: "Відмінити", style: .cancel))
        
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
        // Получаем объект Person
        let person = people[indexPath.item]
        
        // Получаем путь к изображению
        let imagePath = getDocumentsDirectory().appendingPathComponent(person.image)
        
        // Удаляем изображение с диска
        do {
            try FileManager.default.removeItem(at: imagePath)
        } catch {
            print("Ошибка при удалении изображения: \(error)")
        }
        
        // Удаляем элемент из массива
        people.remove(at: indexPath.item)
        collectionView.deleteItems(at: [indexPath])
        
        // Обновляем данные в Keychain
        savePeopleToKeychain()
    }
    
    func loadPeopleFromKeychain() {
        if let data = KeychainWrapper.standard.data(forKey: "SecretMessage") {
            do {
                let decoder = JSONDecoder()
                people = try decoder.decode([Person].self, from: data) // Восстанавливаем массив людей
                isUnlocked = true // Устанавливаем флаг разблокировки
                collectionView.reloadData()
                navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(block))
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
    
   @objc func authenticateClient() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Визначте себе!"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [weak self] success, authenticationError in
                
                DispatchQueue.main.async {
                    if success {
                        self?.loadPeopleFromKeychain()
                        self?.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target:self, action: #selector(self?.addNewPerson))
                        self?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self?.block))
                        self?.isUnlocked = true
                    } else {
                        // error
                        let ac = UIAlertController(title: "Помилка автентифікації", message: "Вас не вдалося перевірити; спробуйте ще раз.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                            self?.showPasswordAlert()
                        })
                        self?.present(ac, animated: true)
                    }
                }
            }
        } else {
            // no biometry
            let ac = UIAlertController(title: "Біометрія недоступна", message: "Ваш пристрій не налаштовано для біометричної автентифікації.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
        }
    }
    
    func showPasswordAlert() {
        if self.attemptEnterPassword < 2 {
            let alertController = UIAlertController(title: "Введіть пароль", message: "Біометрія не розпізнана, введіть пароль вручну.", preferredStyle: .alert)
            
            // Сохраняем ссылку на кнопку для последующего обновления состояния
            var confirmAction: UIAlertAction!
            
            // Добавляем текстовое поле
            alertController.addTextField { textField in
                textField.placeholder = "Пароль"
                textField.isSecureTextEntry = true
                
                // Добавляем наблюдателя за изменением текста
                NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: .main) { _ in
                    // Обновляем состояние кнопки, когда текст изменяется
                    if let text = textField.text, text.count >= 4 {
                        confirmAction.isEnabled = true
                    } else {
                        confirmAction.isEnabled = false
                    }
                }
            }
            
            // Создаём кнопку "Login"
            confirmAction = UIAlertAction(title: "Розблакувати", style: .default) { _ in
                if let password = alertController.textFields?.first?.text {
                    self.validatePassword(password)
                    NotificationCenter.default.removeObserver(self, name: UITextField.textDidChangeNotification, object: nil)
                }
            }
            
            // Изначально кнопка "Login" отключена
            confirmAction.isEnabled = false
            
            // Создаём кнопку "Cancel"
            let cancelAction = UIAlertAction(title: "Відмінити", style: .cancel, handler: nil)
            NotificationCenter.default.removeObserver(self, name: UITextField.textDidChangeNotification, object: nil)
            alertController.addAction(confirmAction)
            alertController.addAction(cancelAction)
            
            // Отображаем UIAlertController
            self.present(alertController, animated: true, completion: nil)
        } else {
            attemptEnterPassword = 0
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(authenticateClient))
        }
    }
    
    func validatePassword(_ password: String) {
        attemptEnterPassword += 1
        if password == correctPassword {
            loadPeopleFromKeychain()
            print("Пароль верный! Авторизация успешна.")
        } else {
            print("Пароль неверный. Попробуйте снова.")
            showPasswordAlert()
        }
    }
    
    @objc func block() {
        
        savePeopleToKeychain()
        isUnlocked = false
        collectionView.reloadData()
        // Скрываем кнопку
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(authenticateClient))
        navigationItem.leftBarButtonItem = nil
    }
    
    func clearKeychainIfFirstLaunch() {
        let isFirstLaunchKey = "isFirstLaunch"
        
        if !UserDefaults.standard.bool(forKey: isFirstLaunchKey) {
            // Первый запуск после установки
            KeychainWrapper.standard.removeAllKeys() // Удаляем все данные из Keychain
            UserDefaults.standard.set(true, forKey: isFirstLaunchKey) // Сохраняем состояние
            UserDefaults.standard.synchronize()
            print("Keychain очищен при первом запуске.")
        }
    }
}

extension ViewController: DetailViewControllerDelegate {
    func didDeletePerson(at indexPath: IndexPath) {
        deletePerson(at: indexPath)
        savePeopleToKeychain()
    }
}
