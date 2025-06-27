from flask import Flask, request, jsonify
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.service import Service
from bs4 import BeautifulSoup
import json
import time
import re
import os
import yt_dlp
import requests

app = Flask(__name__)

def download_youtube(url, file_format="mp4", startAt=None, endAt=None):
    try:
        ydl_opts = {
            "outtmpl": "downloads/%(playlist_title)s/%(title)s.%(ext)s",
            "format": "bestaudio/best" if file_format == "mp3" else "bestvideo+bestaudio",
            "noplaylist": False,
        }

        if startAt and endAt:
            ydl_opts["playlist_items"] = f"{startAt}-{endAt}"
        elif startAt:
            ydl_opts["playlist_items"] = f"{startAt}-"

        if file_format == "mp3":
            ydl_opts["postprocessors"] = [{
                "key": "FFmpegExtractAudio",
                "preferredcodec": "mp3",
                "preferredquality": "192",
            }]

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=True)
            return {"message": f"Downloaded: {info['title']}"}
    except Exception as e:
        return {"error": f"YouTube error: {e}"}

def download_smule(url):
    try:
        options = Options()
        options.add_argument('--headless')
        options.add_argument('--disable-gpu')
        options.add_argument('--log-level=3')

        service = Service(ChromeDriverManager().install())
        driver = webdriver.Chrome(service=service, options=options)

        print(f"[INFO] Fetching Smule page: {url}")
        driver.get(url)
        time.sleep(5)
        html = driver.page_source
        driver.quit()

        soup = BeautifulSoup(html, "html.parser")
        script_tags = soup.find_all("script", {"type": "application/ld+json"})

        m3u8_url = None
        for tag in script_tags:
            try:
                data = json.loads(tag.string)
                if isinstance(data, dict) and "contentUrl" in data and data["contentUrl"].endswith(".m3u8"):
                    m3u8_url = data["contentUrl"]
                    break
            except Exception:
                continue

        if not m3u8_url:
            return {"error": "No .m3u8 stream found in Smule JSON data."}

        # Titel extrahieren
        title_tag = soup.find("title")
        title = title_tag.text.strip().replace(" ", "_") if title_tag else "smule_download"
        filename = f"downloads/smule/{title}.mp4"
        os.makedirs(os.path.dirname(filename), exist_ok=True)

        print(f"[INFO] Downloading stream to {filename}")
        os.system(f'ffmpeg -y -i "{m3u8_url}" -c copy "{filename}"')

        return {"message": f"Downloaded: {filename}"}

    except Exception as e:
        return {"error": f"Smule error: {str(e)}"}

def download_media(url, file_format="mp4", startAt=None, endAt=None):
    if "youtube.com" in url or "youtu.be" in url:
        return download_youtube(url, file_format, startAt, endAt)
    elif "smule.com" in url:
        return download_smule(url)
    else:
        return {"error": "Unsupported URL/platform."}
