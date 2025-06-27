from flask import Flask, request, jsonify
from bs4 import BeautifulSoup
import yt_dlp
import requests
import subprocess
import os

def download_media(url, file_format="mp3", startAt=None, endAt=None):
    if "youtube.com" in url or "youtu.be" in url:
        return download_youtube(url, file_format, startAt, endAt)
    else:
        return {"error": "Unsupported URL/platform."}

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
