from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def go_to_email_login_if_needed(driver, timeout=10):
    wait = WebDriverWait(driver, timeout)

    # If the Welcome button exists, click it.
    try:
        btn = wait.until(EC.element_to_be_clickable((By.ACCESSIBILITY_ID, "Login with Email")))
        btn.click()
        return "welcome_clicked"
    except Exception:
        # Otherwise assume we are already on the email/password screen
        return "already_on_login"
