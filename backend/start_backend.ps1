# PowerShell Script to Start the Backend 🚀

# Navigate to the backend directory
Write-Host "Navigating to backend directory..."
cd F:\Coding\1_Private_Project\ayame_toolbox\backend

# Activate the virtual environment
Write-Host "Activating virtual environment..."
venv\Scripts\activate

# Check if requirements need to be installed
if (Test-Path "requirements.txt") {
    Write-Host "Installing dependencies..."
    pip install -r requirements.txt
} else {
    Write-Host "requirements.txt not found! Skipping dependencies installation."
}

# Start the backend server
Write-Host "Starting the backend server..."
python app.py
