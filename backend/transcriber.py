from flask import request, jsonify
import whisper
import os
from moviepy.editor import VideoFileClip

UPLOAD_FOLDER = 'uploads'

def transcribe_audio():
    print("\n[INFO] /transcribe endpoint called.")

    if 'file' not in request.files:
        return jsonify({"error": "No file part in the request"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No file selected for uploading"}), 400

    file_path = os.path.join(UPLOAD_FOLDER, file.filename)
    file.save(file_path)
    print(f"[INFO] File saved at: {file_path}")

    # Handle audio extraction if it's a video file
    if file.filename.endswith(('.mp4', '.mkv')):
        try:
            print("[INFO] Extracting audio from video file...")
            audio_path = file_path.replace('.mp4', '.mp3').replace('.mkv', '.mp3')
            clip = VideoFileClip(file_path)
            clip.audio.write_audiofile(audio_path)
        except Exception as e:
            return jsonify({"error": f"Failed to extract audio: {e}"}), 500
    else:
        audio_path = file_path

    # Transcribe audio
    try:
        print("[INFO] Loading Whisper model...")
        model = whisper.load_model('base')
        result_ja = model.transcribe(audio_path, language='ja')
        result_en = model.transcribe(audio_path, language='en')
        result_de = model.transcribe(audio_path, language='de')
        result = model.transcribe(audio_path)

        transcription_ja = ". ".join(segment['text'] for segment in result_ja['segments'])
        transcription_en = ". ".join(segment['text'] for segment in result_en['segments'])
        transcription_de = ". ".join(segment['text'] for segment in result_de['segments'])
        transcription = ". ".join(segment['text'] for segment in result['segments'])

        return jsonify({
            "transcription JP": transcription_ja,
            "transcription EN": transcription_en,
            "transcription DE": transcription_de,
            "transcription": transcription
        })
    except Exception as e:
        return jsonify({"error": f"Transcription failed: {e}"}), 500
