
| Comando de Git | Ejemplo de uso                                         | Descripción en español                                                    |
| -------------- | ------------------------------------------------------ | ------------------------------------------------------------------------- |
| `git init`     | `git init nuevorepo`                                   | Inicializa un nuevo repositorio de Git en el directorio actual            |
| `git clone`    | `git clone https://github.com/usuario/repositorio.git` | Clona un repositorio de Git existente en un nuevo directorio local        |
| `git add`      | `git add archivo.txt`                                  | Agrega un archivo al área de preparación para el próximo commit           |
| `git commit`   | `git commit -m "Mensaje del commit"`                   | Realiza un commit de los archivos agregados al área de preparación        |
| `git push`     | `git push origin main`                                 | Envía los commits al repositorio remoto                                   |
| `git pull`     | `git pull origin main`                                 | Trae los cambios del repositorio remoto al repositorio local              |
| `git log`      | `git log --oneline`                                    | Muestra la historia de commits en el repositorio                          |
| `git checkout` | `git checkout <commit-hash>`                           | Crea una nueva rama o cambia a una rama existente en un commit específico |
| `git tag`      | `git tag -a v1.0 -m "Versión 1.0"`                     | Crea una nueva etiqueta en un commit específico                           |
| `git show`     | `git show v1.0`                                        | Muestra los detalles de un commit o etiqueta específica                   |



1. Create a new local repository:


```
mkdir new_repo
cd new_repo
git init
```

2. Create a new file in the local repository, for example, a README.md file:

`echo "# new_repo" >> README.md`

3. Add the files in your new local repository. This stages them for the first commit:



`git add .`

4. Commit the files that you've staged in your local repository:



`git commit -m "First commit"`

5. Create a new repository on GitHub. To avoid errors, do not initialize the new repository with README, license, or gitignore files. You can add these files after your project has been pushed to GitHub.
    
6. In the top of your repository on GitHub, click the "Code" button to copy the remote repository URL.
    
7. Link the local repository to the remote repository on GitHub:
    



`git remote add origin <REMOTE_URL>`

8. Verify that the remote repository URL is set correctly:



`git remote -v`

9. Push the changes in your local repository to GitHub:



`git push -u origin main`

If your default branch is not named "main," replace "main" with the name of your default branch. For more information, see "About branches."

To update the remote repository with the latest changes from your local repository, you can use the `git push` command. Here are the steps:

1. Make sure you have committed all the changes in your local repository:


```
git add . 
git commit -m "Commit message"
```

2. Push the changes to the remote repository:


`git push origin main`

