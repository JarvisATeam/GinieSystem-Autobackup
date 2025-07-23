#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, time, logging
from datetime import datetime
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.action_chains import ActionChains

ROOT = os.path.expanduser("~/GinieSystem/Agents/tiktok_poster")
ASSETS = os.path.join(ROOT, "assets")
TEMP = os.path.join(ROOT, "temp")
LOGS = os.path.join(ROOT, "logs")
COOKIES = os.path.join(ROOT, "cookies")
CAPTION_FILE = os.path.join(ASSETS, "caption.txt")

log_file = os.path.join(LOGS, f"poster_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log")
logging.basicConfig(filename=log_file, level=logging.INFO, format="%(asctime)s | %(message)s")

def hent_filer():
    bilder = sorted([f for f in os.listdir(ASSETS) if f.lower().endswith((".jpg", ".jpeg", ".png"))])
    lyd = [f for f in os.listdir(ASSETS) if f.lower().endswith((".mp3", ".wav", ".m4a"))]
    return bilder, lyd[0] if lyd else None

def autopost():
    bilder, lydfil = hent_filer()
    if not bilder or not lydfil:
        logging.warning("⛔ Mangler bilder eller lydfil – avbryter.")
        return

    logging.info("📦 Innhold funnet – starter Chrome...")
    chrome_opts = Options()
    chrome_opts.add_argument("--start-maximized")
    chrome_opts.add_argument("--user-data-dir=" + os.path.join(COOKIES))
    chrome_opts.add_argument("--disable-blink-features=AutomationControlled")
    driver = webdriver.Chrome(options=chrome_opts)

    try:
        driver.get("https://www.tiktok.com/upload")
        time.sleep(10)

        upload_input = driver.find_element(By.XPATH, "//input[@type='file']")
        video_path = os.path.join(TEMP, "final_video.mp4")
        if not os.path.exists(video_path):
            logging.error("❌ final_video.mp4 mangler.")
            return
        upload_input.send_keys(video_path)
        time.sleep(10)

        if os.path.exists(CAPTION_FILE):
            with open(CAPTION_FILE) as f:
                caption = f.read().strip()
            caption_input = driver.find_element(By.XPATH, "//div[contains(@class,'public-DraftEditor-content')]")
            caption_input.click()
            ActionChains(driver).send_keys(caption).perform()
            time.sleep(2)

        post_knapp = driver.find_element(By.XPATH, "//button[.//text()='Post']")
        post_knapp.click()
        logging.info("✅ Video postet.")
        time.sleep(10)

    except Exception as e:
        logging.error(f"❌ FEIL: {e}")
    finally:
        driver.quit()

if __name__ == "__main__":
    logging.info("🟢 Starter auto-post.")
    autopost()
