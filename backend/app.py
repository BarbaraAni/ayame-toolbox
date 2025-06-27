from flask import Flask, request, jsonify  # Ensure 'request' is imported
from flask_cors import CORS
from transcriber import transcribe_audio
from vid_downloader import download_media
import os
# from openai import OpenAI, RateLimitError
# from dotenv import load_dotenv
# from openai._exceptions import RateLimitError
# import time

# # Load environment variables for OpenAI API key
# load_dotenv()
# api_key = os.getenv('OPENAI_API_KEY')

# if api_key:
#     print("[INFO] OpenAI API key loaded successfully.")
# else:
#     print("[ERROR] OpenAI API key not found! Check your .env file.")

# # Initialize OpenAI client with the API key
# client = OpenAI(api_key=api_key)

app = Flask(__name__)
CORS(app)  # Enable CORS for communication with React frontend

UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Default route for root path
@app.route('/')
def home():
    return "<h1>Welcome to the Transcription Toolbox API!</h1><p>Use the /transcribe endpoint to upload audio or video files.</p>"

@app.route('/transcribe', methods=['POST'])
def transcribe():
    return transcribe_audio()


@app.route('/download', methods=['POST'])
def download():
    data = request.get_json()

    url = data.get("url")

    format_choice = data.get("format", "mp4").lower()
    allowed_formats = {"mp3", "mp4"}
    if format_choice not in allowed_formats:
        return jsonify({"error": f"Invalid format: {format_choice}. Allowed: {', '.join(allowed_formats)}"})

    startAt = int(data.get("startAt")) if data.get("startAt") else None
    endAt = int(data.get("endAt")) if data.get("endAt") else None

    return jsonify(download_media(url, format_choice, startAt, endAt))

if __name__ == '__main__':
    print("[INFO] Starting Flask server...")
    app.run(debug=True, use_reloader=False)


