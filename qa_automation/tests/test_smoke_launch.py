def test_app_launches(driver):
    assert driver.session_id is not None
