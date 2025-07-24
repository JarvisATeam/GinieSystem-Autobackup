import os, time, logging
from datetime import datetime
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains

ROOT = os.path.expanduser("~/GinieSystem/Agents/tiktok_poster")
ASSETS = os.path.join(ROOT, "assets")
TEMP = os.path.join(ROOT, "temp")
LOGS = os.path.join(ROOT, "logs")
COOKIES = os.path.join(ROOT, "cookies")
CAPTION = os.path.join(ASSETS, "caption.txt")
VIDEO = os.path.join(TEMP, "final_video.mp4")

logfile = os.path.join(LOGS, f"log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log")
logging.basicConfig(filename=logfile, level=logging.INFO)

def autopost():
    if not os.path.exists(VIDEO):
        logging.warning("🚫 Mangler video."); return

    opts = Options()
    opts.add_argument("--user-data-dir=" + COOKIES)
    opts.add_argument("--window-position=2000,2000")
    opts.add_argument("--disable-blink-features=AutomationControlled")
    driver = webdriver.Chrome(options=opts)

    try:
        driver.get("https://www.tiktok.com/upload")
        time.sleep(10)
        driver.find_element(By.XPATH, "//input[@type='file']").send_keys(VIDEO)
        time.sleep(8)
        if os.path.exists(CAPTION):
            with open(CAPTION) as f:
                caption = f.read().strip()
            ActionChains(driver).click(driver.find_element(By.CLASS_NAME, "public-DraftEditor-content")).send_keys(caption).perform()
        driver.find_element(By.XPATH, "//button[contains(.,'Post')]").click()
        logging.info("✅ Video postet.")
        time.sleep(5)
    except Exception as e:
        logging.error(f"❌ FEIL: {e}")
    finally:
        driver.quit()

if __name__ == "__main__":
    autopost()
