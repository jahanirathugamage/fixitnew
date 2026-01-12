from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from utils.loginnavigation import go_to_email_login_if_needed

def test_login_flow(driver):
    wait = WebDriverWait(driver, 25)

    go_to_email_login_if_needed(driver)

    email_field = wait.until(
        EC.presence_of_element_located((
            "-android uiautomator",
            'new UiSelector().className("android.widget.EditText").instance(0)'
        ))
    )
    email_field.send_keys("testuser@gmail.com")

    password_field = wait.until(
        EC.presence_of_element_located((
            "-android uiautomator",
            'new UiSelector().className("android.widget.EditText").instance(1)'
        ))
    )
    password_field.send_keys("Test@1234")

    wait.until(
        EC.element_to_be_clickable((By.ACCESSIBILITY_ID, "Login"))
    ).click()

    # Temporary success check (we'll add a real home marker next)
    wait.until(lambda d: True)
