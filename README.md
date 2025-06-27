# 🎧 Ayame Toolbox Backend

This backend powers the **Ayame Toolbox**, handling audio and video transcription with optional AI-generated summaries.

---

## 🚀 **Setup and Startup Instructions**

### Backend Server Startup using PowerShell-Script:
open new Terminal as Windows Powershell and execute 
```powershell
.\backend\start_backend.ps1
```
from
```powershell
PS F:\Coding\1_Private_Project\ayame_toolbox> .\backend\start_backend.ps1
```

## OR Manual Startup:
### 1. **Open a PowerShell Terminal**
Start by opening **PowerShell**.

### 2. **Navigate to the Backend Directory**
```powershell
cd F:\Coding\1_Private_Project\ayame_toolbox\backend
```

### 3. **Activate the Virtual Environment**
Ensure you're in the project directory, then activate the Python virtual environment:

```powershell
venv\Scripts\activate
```

Note: If the virtual environment isn't set up, create one with: (not needed in this case)

```powershell
python -m venv venv
```

### 4. **Install Dependencies (if necessary)**
If there are new dependencies or you're setting up the project for the first time:

```powershell
pip install -r requirements.txt
```

### 5. **Start the Backend Server**
Launch the backend application:

```powershell
python app.py
```

### 6. **Update Dependencies (if new ones are installed)**
If you've added new dependencies during development:

```powershell
pip freeze > requirements.txt
```

## 🛠️ **Testing the Backend**
After starting the backend, you can test the API with tools like:

Curl:
```powershell
curl -X POST -F "file=@C:\path\to\your\audiofile.wav" http://127.0.0.1:5000/transcribe
```
```powershell
curl -X POST -F "file=@C:\Users\banis\OneDrive\Dokumente\Audioaufzeichnungen\Multi Lingual language transcription test.wav" http://127.0.0.1:5000/transcribe
```
```powershell
curl -X POST -H "Content-Type: application/json" -d '{"url": "https://www.youtube.com/watch?v=bGci1ixhveI&list=WL&index=2&t=6305s", "format": "mp4"}'
```
```powershell
curl -X POST -H "Content-Type: application/json" -d "{"url": "https://www.smule.com/recording/example"}" http://127.0.0.1:5000/download
```
Postman: Create a POST request to http://127.0.0.1:5000/transcribe with form-data and attach an audio file.

## 📚 Dependencies
The backend relies on:

- Flask
- Whisper by OpenAI
- MoviePy
- OpenAI API
- Flask-CORS
- Python-dotenv

Ensure all dependencies are installed with:

```powershell
pip install -r requirements.txt
```

## 🐛 Troubleshooting
- Environment Activation Issue: Ensure you’re in the correct directory before activating the virtual environment.
- Missing Dependencies: Run pip install -r requirements.txt.
- FFmpeg Missing: Ensure FFmpeg is installed and added to your system's PATH.

## 📄 License
This project is licensed under the MIT License.

### 🎯 You're ready to transcribe! Enjoy using Ayame Toolbox Backend! 🚀

# 🎧 Ayame Toolbox Frontend

tbd

# 🎧 Smule Downloads
- add all urls that you want to download to cypress/data/smule_urls.txt with new lines inbetween
- in dev tools console, run the following command - then copy to smule_urls.txt and replace all \n with enters
- ```powershell 
    [...document.querySelectorAll('a[href*="/recording/"]')]
    .map(a => a.href)
    .filter((v, i, a) => a.indexOf(v) === i)  // remove duplicates
    .join('\n')
    ```
- run cypress
- ```powershell 
  npx cypress run --e2e --spec 'cypress/e2e/smule_download_sownloader.cy.js'
  ```
- run removeMetadata.ps1 script
- ```powershell 
  powershell -NoProfile -ExecutionPolicy Bypass -Command "cd cypress; ./removeMetadata.ps1"
  ```
- files appear in F:\Musik\Smule\safetyNet



# .MD Format Tipps

- [x] Playlist as mp3s download
- [x] einzelne Videos als mp3/mp4 download
- [x] Smule Download
- [ ] Smule Playlist Support (TBD)
- [x] remove all metadata in cypress/downloads folder

| Name    | Age | Role       |
|---------|-----|------------|
| Alice   | 24  | Developer  |
| Bob     | 30  | Designer   |
| Charlie | 28  | PM         |

This is ~~strikethrough~~ text.

> This is a block quote.  
> It can span multiple lines.

@username: Mention users.  
#123: Reference issues or pull requests.  
https://github.com/user/repo: Link to repositories.

Hello, GitHub! :smile: :rocket:  
[^1]: This is the footnote.

> New line is two spaces at the end of the line.


### Request Format
> {  
>   "url": "https://www.youtube.com/watch?v=example",  
>   "format": "mp3",         // Optional: "mp3" (default), "mp4"  
>   "startAt": 1,            // Optional: Start index for YouTube playlists  
>   "endAt": 5               // Optional: End index for YouTube playlists  
> }

