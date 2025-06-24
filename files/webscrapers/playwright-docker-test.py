import asyncio
import requests
import os
from dotenv import load_dotenv

load_dotenv()

# URLs to test
URL = "https://rsm-shiny-02.ucsd.edu/selenium/"
URL_AUTH = "https://rsm-shiny-02.ucsd.edu/selenium_auth/"


async def test_playwright_docker():
    """Docker-based Playwright test - connects to remote Playwright browser like Selenium"""
    print("=== Playwright Docker Results ===")
    
    try:
        from playwright.async_api import async_playwright
        
        # Try different endpoints like Selenium does
        endpoints = [
            "ws://127.0.0.1:9222"
        ]
        
        browser = None
        for endpoint in endpoints:
            try:
                # Check if HTTP endpoint is available first
                http_endpoint = endpoint.replace("ws://", "http://")
                print(f"Trying endpoint: {http_endpoint}")
                response = requests.get(f"{http_endpoint}/json/version", timeout=2)
                print(f"Response status: {response.status_code}")
                if response.status_code == 200:
                    # Get the actual WebSocket URL from the response
                    version_info = response.json()
                    ws_url = version_info.get("webSocketDebuggerUrl")
                    if ws_url:
                        print(f"Connecting to CDP at: {ws_url}")
                        p = await async_playwright().start()
                        # Connect to existing browser via the full WebSocket URL
                        browser = await p.chromium.connect_over_cdp(ws_url)
                        print("Successfully connected!")
                        break
            except Exception as e:
                print(f"Failed {endpoint}: {e}")
                continue
        
        if not browser:
            print("❌ No Playwright browser container available. Start with:")
            print("   docker build -f Dockerfile.playwright -t playwright-browser .")
            print("   docker run --name playwright-browser --network rsm-docker -d -p 9222:9222 playwright-browser")
            return
            
        # Use the connected browser
        page = await browser.new_page()
        
        await page.goto(URL)
        
        title = await page.title()
        button_exists = await page.locator("#showText").count() > 0
        
        if button_exists:
            await page.click("#showText")
            await page.wait_for_timeout(1000)
        
        dynamic_text = await page.text_content("#dynamicText")
        
        print(f"Title found by Docker Playwright: {title}")
        print(f"Button found by Docker Playwright: {button_exists}")
        print(f"Dynamic text after click: {dynamic_text}")
        
        await page.close()
        await browser.close()
        await p.stop()
        
    except Exception as e:
        print(f"❌ Error: {e}")


async def test_authentication_docker():
    """Docker-based authentication test - connects to remote Playwright browser like Selenium"""
    print("=== Playwright Docker Authentication ===")

    username = os.getenv("SELENIUM_USERNAME")
    password = os.getenv("SELENIUM_PASSWORD")

    if not username or not password:
        print("Missing credentials in .env file - skipping authentication test")
        return

    try:
        from playwright.async_api import async_playwright
        
        # Try different endpoints like Selenium does
        endpoints = [
            "ws://127.0.0.1:9222"
        ]
        
        browser = None
        for endpoint in endpoints:
            try:
                # Check if HTTP endpoint is available first
                http_endpoint = endpoint.replace("ws://", "http://")
                print(f"Trying endpoint: {http_endpoint}")
                response = requests.get(f"{http_endpoint}/json/version", timeout=2)
                print(f"Response status: {response.status_code}")
                if response.status_code == 200:
                    # Get the actual WebSocket URL from the response
                    version_info = response.json()
                    ws_url = version_info.get("webSocketDebuggerUrl")
                    if ws_url:
                        print(f"Connecting to CDP at: {ws_url}")
                        p = await async_playwright().start()
                        # Connect to existing browser via the full WebSocket URL
                        browser = await p.chromium.connect_over_cdp(ws_url)
                        print("Successfully connected!")
                        break
            except Exception as e:
                print(f"Failed {endpoint}: {e}")
                continue
        
        if not browser:
            print("❌ No Playwright browser container available. Start with:")
            print("   docker build -f Dockerfile.playwright -t playwright-browser .")
            print("   docker run --name playwright-browser --network rsm-docker -d -p 9222:9222 playwright-browser")
            return
            
        # Use the connected browser
        page = await browser.new_page()
        
        await page.goto(URL_AUTH)
        await page.wait_for_load_state("networkidle")
        
        username_field = page.locator(
            'input[name="username"], input[type="text"], #username'
        )
        password_field = page.locator(
            'input[name="password"], input[type="password"], #password'
        )
        submit_button = page.locator(
            'input[type="submit"], button[type="submit"], button:has-text("Login"), button:has-text("Sign in")'
        )
        
        if await username_field.count() > 0:
            await username_field.first.fill(username)
        if await password_field.count() > 0:
            await password_field.first.fill(password)
        if await submit_button.count() > 0:
            await submit_button.first.click()
            await page.wait_for_load_state("networkidle")
        
        show_text_button = page.locator("#showText")
        if await show_text_button.count() > 0:
            await show_text_button.click()
            await page.wait_for_timeout(1000)
        
        button_exists = await page.locator("#showText").count() > 0
        try:
            dynamic_text = await page.text_content("#dynamicText")
        except Exception:
            dynamic_text = ""
        
        print("✅ Success!")
        print(f"🔘 Button found: {button_exists}")
        print(f"📝 Dynamic text: '{dynamic_text}'")
        
        await page.close()
        await browser.close()
        await p.stop()
        
    except Exception as e:
        print(f"❌ Error: {e}")


async def test_playwright_simple():
    """Simple local Playwright test using standard patterns"""
    print("=== Simple Playwright Results ===")

    try:
        from playwright.async_api import async_playwright

        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            page = await browser.new_page()

            await page.goto(URL)

            title = await page.title()
            button_exists = await page.locator("#showText").count() > 0

            if button_exists:
                await page.click("#showText")
                await page.wait_for_timeout(1000)

            dynamic_text = await page.text_content("#dynamicText")

            print(f"Title found by Simple Playwright: {title}")
            print(f"Button found by Simple Playwright: {button_exists}")
            print(f"Dynamic text after click: {dynamic_text}")

            await browser.close()

    except ImportError:
        print("❌ Playwright not installed. Install with: pip install playwright")
        print("   Then run: playwright install")
    except Exception as e:
        print(f"❌ Error: {e}")


async def test_authentication_simple():
    """Simple local authentication test using standard Playwright patterns"""
    print("=== Simple Playwright Authentication ===")

    username = os.getenv("SELENIUM_USERNAME")
    password = os.getenv("SELENIUM_PASSWORD")

    if not username or not password:
        print("Missing credentials in .env file - skipping authentication test")
        return

    try:
        from playwright.async_api import async_playwright

        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            page = await browser.new_page()

            await page.goto(URL_AUTH)
            await page.wait_for_load_state("networkidle")

            username_field = page.locator(
                'input[name="username"], input[type="text"], #username'
            )
            password_field = page.locator(
                'input[name="password"], input[type="password"], #password'
            )
            submit_button = page.locator(
                'input[type="submit"], button[type="submit"], button:has-text("Login"), button:has-text("Sign in")'
            )

            if await username_field.count() > 0:
                await username_field.first.fill(username)
            if await password_field.count() > 0:
                await password_field.first.fill(password)

            if await submit_button.count() > 0:
                await submit_button.first.click()
                await page.wait_for_load_state("networkidle")

            show_text_button = page.locator("#showText")
            if await show_text_button.count() > 0:
                await show_text_button.click()
                await page.wait_for_timeout(1000)

            button_exists = await page.locator("#showText").count() > 0
            try:
                dynamic_text = await page.text_content("#dynamicText")
            except Exception:
                dynamic_text = ""

            print("✅ Success!")
            print(f"🔘 Button found: {button_exists}")
            print(f"📝 Dynamic text: '{dynamic_text}'")

            await browser.close()

    except ImportError:
        print("❌ Playwright not installed. Install with: pip install playwright")
        print("   Then run: playwright install")
    except Exception as e:
        print(f"❌ Error: {e}")


async def main():
    """Run both Docker and simple Playwright tests"""
    print("Running Playwright tests...\n")

    print("=" * 50)
    print("DOCKER CONTAINER VERSIONS")
    print("=" * 50)

    await test_playwright_docker()
    print()

    await test_authentication_docker()
    print()

    print("=" * 50)
    print("LOCAL INSTALLATION VERSIONS")
    print("=" * 50)

    await test_playwright_simple()
    print()

    await test_authentication_simple()


if __name__ == "__main__":
    asyncio.run(main())
