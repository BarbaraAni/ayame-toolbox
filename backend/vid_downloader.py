from flask import Flask, request, jsonify
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup
from urllib.parse import urlparse, urlunparse
import json
import time
import re
import os
import yt_dlp
import requests

def clean_smule_url(url):
    print(f"[INFO] clean_smule_url (input): {url}")
    match = re.match(r"(https://www\.smule\.com/recording/[^/]+/\d+_\d+)", url)
    if match:
        cleaned = match.group(1)
        print(f"[INFO] clean_smule_url (output): {cleaned}")
        return cleaned
    return url  # fallback

def download_youtube(url, file_format="mp4", startAt=None, endAt=None):
    try:
        ydl_opts = {
            "outtmpl": "downloads/%(playlist_title)s/%(title)s.%(ext)s",
            "format": "bestaudio/best" if file_format == "mp3" else "bestvideo+bestaudio",
            "noplaylist": False,
            "nocheckcertificate": True,
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
        headers = {"User-Agent": "Mozilla/5.0"}
        response = requests.get(url, headers=headers)
        if response.status_code != 200:
            return {"error": f"Failed to fetch page: HTTP {response.status_code}"}

        soup = BeautifulSoup(response.text, "html.parser")
        script_tags = soup.find_all("script")

        m4a_url = None
        title = "smule_download"

        # Try to find the m4a link in a script
        for tag in script_tags:
            if tag.string and ".m4a" in tag.string:
                m = re.search(r'https://[^"]+\.m4a', tag.string)
                if m:
                    m4a_url = m.group(0)
                    break

        # Fallback: try rendered .mp4
        if not m4a_url:
            m = re.search(r'https://[^"]+rendered[^"]+\.mp4', response.text)
            if m:
                m4a_url = m.group(0)

        # Title from <title> tag
        title_tag = soup.find("title")
        if title_tag:
            title = title_tag.text.strip().replace(" ", "_")

        if not m4a_url:
            return {"error": "No .m4a or .mp4 stream found in HTML."}

        # Download
        filename = f"downloads/smule/{title}.m4a"
        os.makedirs(os.path.dirname(filename), exist_ok=True)

        print(f"[INFO] Downloading: {filename}")
        with requests.get(m4a_url, stream=True) as r:
            with open(filename, "wb") as f:
                for chunk in r.iter_content(chunk_size=8192):
                    f.write(chunk)

        return {"message": f"Downloaded: {filename}"}

    except Exception as e:
        return {"error": f"Smule download error: {str(e)}"}

def download_media(url, file_format="mp3", startAt=None, endAt=None):
    if "youtube.com" in url or "youtu.be" in url:
        return download_youtube(url, file_format, startAt, endAt)
    elif "smule.com" in url:
        return download_smule(url, file_format)
    else:
        return {"error": "Unsupported URL/platform."}
