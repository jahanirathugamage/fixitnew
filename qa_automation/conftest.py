import pytest
from appium import webdriver
from appium.options.android import UiAutomator2Options

APPIUM_URL = "http://127.0.0.1:4723"
DEVICE_NAME = "emulator-5554"  # update if adb shows different
APK_PATH = r"C:\Studies\fixitnew\build\app\outputs\flutter-apk\app-debug.apk"

@pytest.fixture
def driver():
    opts = UiAutomator2Options()
    opts.platform_name = "Android"
    opts.automation_name = "UiAutomator2"
    opts.device_name = DEVICE_NAME
    opts.auto_grant_permissions = True
    # opts.no_reset = True
    opts.no_reset = False
    opts.full_reset = False

    opts.new_command_timeout = 180

    opts.app = APK_PATH
    opts.app_wait_activity = "*"

    d = webdriver.Remote(APPIUM_URL, options=opts)
    yield d
    d.quit()
